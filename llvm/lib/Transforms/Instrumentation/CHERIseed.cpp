//===-- CHERIseed.cpp - software implementation of CHERI Semantics---------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// This is an experimental pass implementation for CHERIseed.
///
/// What is CHERIseed?
///
///  CHERIseed is a software-only implementation of CHERI C/C++ Semantics.
///  Its main purpose is to assist with porting existing code to support
///  capability-aware platforms without requiring capability-aware hardware.
///  CHERIseed works by instrumenting code and transforming LLVM IR that has
///  been generated for a capability-aware platform.
///
///  Because CHERIseed is only a software-only implementation of CHERI C/C++
///  semantics it can't and doesn't aim to provide same level of CHERI-based
///  security or performance as a hardware implementation of CHERI. Some
///  features, which are generally available across hardware implementations of
///  CHERI, might be unavailable in CHERIseed.
///
///  Nonetheless, the aim is to provide step-by-step approach to introducing
///  CHERI C/C++ compatibility into an existing code base, and enable
///  experimentation with the benefits of the most important aspects of
///  capability semantics.
///
/// Implementation details
///
///  A capability is defined as follows (in C++ notation):
///
///    struct cap_t {
///      uint64_t value;
///      uint64_t metadata;
///    } __attribute__((aligned(16)));
///
///  This is necessary because originally lowering LLVM IR CHERI builtins relies
///  on having 128-bit capability registers, which are not available on
///  capability-unaware hardware. Therefore, CHERIseed has to change the calling
///  convention so that pointers are replaced with a pointer to a capability
///  holding the target address, as well as 64 bits of metadata.
///
//===----------------------------------------------------------------------===//

#include "llvm/Transforms/Instrumentation/CHERIseed.h"
#include "llvm/ADT/APInt.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Argument.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/Use.h"
#include "llvm/IR/Value.h"
#include "llvm/InitializePasses.h"
#include "llvm/Pass.h"
#include "llvm/Support/AtomicOrdering.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/ModuleUtils.h"
#include <algorithm>
#include <functional>
#include <string>
#include <utility>

using namespace llvm;

// These permissions bits are used as the arguments for compiler_rt function
// __cheriseed_check_access as a platform independent representation.
//
// All calls to other compiler_rt functions that are accessible via intrinsics
// to the user should use the platform specific permissions bits defined in
// cheriintrin.h
//
// These constants are duplicated in:
//   compiler-rt/lib/cheriseed/cheriseed_abi_defs.h
// so any changes should be reflected there.
namespace cheriseed {
namespace abi {
enum permissions : unsigned int {
  LOAD = (1 << 0),
  STORE = (1 << 1),
  EXECUTE = (1 << 2),
  LOAD_CAP = (1 << 3),
  STORE_CAP = (1 << 4)
};
} // namespace abi
} // namespace cheriseed

#define PASS_ARG "cheriseed"
#define PASS_NAME "CHERIseed: software-only capability support."
#define DEBUG_TYPE PASS_ARG

static cl::opt<bool>
    ClDebugTypeMap("cheriseed-debug-type-map",
                   cl::desc("Print debug messages when mapping Types"),
                   cl::Hidden, cl::init(false));

static cl::opt<bool>
    ClDebugValueMap("cheriseed-debug-value-map",
                    cl::desc("Print debug messages when mapping Values"),
                    cl::Hidden, cl::init(false));

static cl::opt<bool>
    ClDebugFunctionMap("cheriseed-debug-function-map",
                       cl::desc("Print debug messages when mapping Functions"),
                       cl::Hidden, cl::init(false));

static cl::opt<bool> ClDebugBasicBlocks(
    "cheriseed-debug-basic-blocks",
    cl::desc("Print debug messages about input and output BasicBlocks"),
    cl::Hidden, cl::init(false));

static cl::opt<bool> ClDebugAll("cheriseed-debug-all",
                                cl::desc("Turn on all available debug prints"),
                                cl::Hidden, cl::init(false));

static cl::opt<bool> ClNoInlineAsm("cheriseed-no-inline-asm",
                                   cl::desc("Turn off warning for inline asm"),
                                   cl::Hidden, cl::init(false));

namespace {

/// The address space which capabilities use.
static constexpr unsigned kCapabilityAS = 200;
/// Prefix to use in every CHERIseed-related names.
static constexpr char kPrefix[] = "__cheriseed_";
/// The suffix to add to renamed symbols.
static constexpr char kDeferredGlobalPrefix[] = "__cheriseed_deferred_global_";
/// Function attribute to indicate which function a function is mapped to.
static constexpr char kRenamedFnAttribute[] = "cheriseed-rename";
/// Attribute marking objects that should not be processed by the pass.
static constexpr char kInternalAttribute[] = "cheriseed-internal";
/// Attribute to link a global to its accessor function.
static constexpr char kAccessorAttribute[] = "cheriseed-accessor";
/// The suffix to add to renamed symbols.
static constexpr char kTakeNameSuffix[] = ".old";
/// Initializer section
static constexpr char kInitializerSection[] = "__cheriseed_initializers";

/// Returns true if Type \Ty is a capability, otherwise false.
/// For example:
///   i8* --> false
///   i8 addrspace(200)* --> true
///   i8 addrspace(200)** --> false
///   i8 ()* --> false
///   i8 () addrspace(200)* --> true
static bool IsCapability(Type *Ty) {
  PointerType *PTy = dyn_cast<PointerType>(Ty);
  return (PTy && (PTy->getAddressSpace() == kCapabilityAS));
}

/// Returns true if Type \Ty is a pointer to a capability, otherwise false.
/// For example:
///   i8* --> false
///   i8 addrspace(200)* --> false
///   i8 addrspace(200)** --> true
static bool IsPointerToCapability(Type *Ty) {
  PointerType *PTy = dyn_cast<PointerType>(Ty);
  return (PTy && IsCapability(PTy->getElementType()));
}
/// Removes some attributes which are not compatible with capability
/// representation.
static void SanitizeAttributes(AttrBuilder &AB, bool ReturnsCap) {
  if (ReturnsCap)
    AB.removeAttribute(Attribute::Returned);
  AB.removeAttribute(Attribute::Dereferenceable);
  AB.removeAttribute(Attribute::DereferenceableOrNull);
  // Not removing 'byval' here, see elsewhere.
}

/// Converts an atomic ordering to the corresponding ABI value.
static unsigned OrderingToABI(AtomicOrdering Ordering) {
  // C ABI ordering is very stable, it is not expected to ever change.
  return static_cast<int>(toCABI(Ordering));
}

/// Converts an atomic read-modify-write operation to the corresponding ABI
/// value.
static unsigned AtomicRMWOpToABI(AtomicRMWInst::BinOp Op) {
  return static_cast<int>(Op);
}

/// Returns true if \p GV should be instrumented.
static bool ShouldInstrumentGlobal(GlobalVariable *GV) {
  if (GV->hasAttribute(kInternalAttribute))
    return false;

  StringRef GVName = GV->getName();
  if ((GVName == "llvm.global_ctors") || (GVName == "llvm.global_dtors") ||
      (GVName == "llvm.used") || (GVName == "llvm.compiler.used"))
    return false;

  // If there is no metadata attached, the global is always instrumented.
  MDNode *MD = GV->getMetadata("cheriseed");
  if (!MD)
    return true;

  // The global is not instrumented if there is "no_sanitize" metadata.
  for (const auto &Op : MD->operands())
    if (MDString *MDStr = dyn_cast<MDString>(Op.get()))
      if (MDStr->getString() == "no_sanitize")
        return false;

  // Otherwise the global is instrumented.
  return true;
}

/// Returns true if \p Ty has a capability in it's layout, either direct or
/// indirect, otherwise false. The return value is also true if there is a
/// function involved.
///
/// \param Ty The Type whose layout is to be checked.
///
/// \returns True if \p Ty contains either a capability of a function somehow.
bool ShouldMapType(Type *Ty) {
  assert(Ty && "Ty must be non-null");

  SmallVector<Type *, 8> Types;
  SmallSet<const Type *, 8> VisitedTypes;

  Types.push_back(Ty);

  do {
    Type *Ty = Types.pop_back_val();

    // Break cycles by ensuring we do not visit the same type twice.
    if (VisitedTypes.count(Ty) == 1)
      continue;
    VisitedTypes.insert(Ty);

    switch (Ty->getTypeID()) {
    case Type::TypeID::StructTyID:
      // Opaque structures have no members, there is nothing to do here.
      // However, some code (mapGlobalVariable) might rely on 'ShouldMapType()'
      // to figure out if calling an accessor is necessary or not.
      if (cast<StructType>(Ty)->isOpaque())
        return true;
      for (Type *E : cast<StructType>(Ty)->elements())
        Types.push_back(E);
      break;
    case Type::TypeID::ArrayTyID:
      Types.push_back(cast<ArrayType>(Ty)->getElementType());
      break;
    case Type::TypeID::PointerTyID: {
      PointerType *PTy = cast<PointerType>(Ty);
      if (IsCapability(PTy))
        return true;
      Types.push_back(PTy->getElementType());
    } break;
    case Type::TypeID::FixedVectorTyID:
    case Type::TypeID::ScalableVectorTyID:
      Types.push_back(cast<VectorType>(Ty)->getElementType());
      break;
    case Type::TypeID::FunctionTyID:
      // The pass always re-creates functions, which are mapped.
      return true;
    default:
      break;
    }
  } while (!Types.empty());

  return false;
}

/// Returns true if \p V aliases \p A.
static bool IsAliasOf(const Value *V, const Value *A) {
  if (!isa<GlobalAlias>(V))
    return false;

  const User *U = cast<User>(cast<GlobalAlias>(V)->getAliasee());
  if (U == A)
    return true;

  for (const Value *Op : U->operands()) {
    if (Op == A)
      return true;
    // Don't recurse into another GlobalAlias.
    if (isa<GlobalAlias>(Op))
      return false;
    if (IsAliasOf(Op, A))
      return true;
  }

  return false;
}

/// Helper struct which collects formatting of all possible debug prints.
struct DebugPrint final {
  /// RAII object to print a Module in debug builds.
  struct ScopedModuleVisit final {
    explicit ScopedModuleVisit(Module &M) {
      LLVM_DEBUG(dbgs() << M.getName() << " {\n");
    }
    ~ScopedModuleVisit() { LLVM_DEBUG(dbgs() << "} // end of module\n"); }
  }; // end of struct ScopedModuleVisit

  /// RAII object to print a Function in debug builds.
  struct ScopedFunctionVisit final {
    explicit ScopedFunctionVisit(Function &F)
        : isDeclaration(F.isDeclaration()) {
      std::string Repr;
      llvm::raw_string_ostream stream{Repr};
      stream << "\n";
      F.getReturnType()->print(stream, false, true);
      stream << " @" << F.getName() << "(";
      for (auto it = F.arg_begin(), it_end = F.arg_end(); it != it_end;) {
        stream << *it;
        ++it;
        if (it != it_end)
          stream << ", ";
      }
      stream << (isDeclaration ? ") (declaration)" : ") {");
      LLVM_DEBUG(dbgs() << Repr << "\n");
    }
    ~ScopedFunctionVisit() {
      LLVM_DEBUG(dbgs() << (isDeclaration ? "" : "} // end of function\n"));
    }

  protected:
    bool isDeclaration;
  }; // end of struct ScopedFunctionVisit

  /// RAII object to print a BasicBlock in debug builds.
  struct ScopedBasicBlockVisit final {
    explicit ScopedBasicBlockVisit(BasicBlock &BB, bool IsInput) {
      if (!ClDebugBasicBlocks && !ClDebugAll)
        return;
      if (IsInput)
        LLVM_DEBUG(dbgs() << kSepS << BB << kSepS << "\n");
      else
        LLVM_DEBUG(dbgs() << kSepE << BB << kSepE << "\n");
    }
#ifndef NDEBUG
    static constexpr char const *kSepS = ">>>>>";
    static constexpr char const *kSepE = "<<<<<";
#endif
  }; // end of struct ScopedBasicBlockVisit

  /// RAII object to print a Value in debug builds.
  struct ScopedValueVisit final {
    explicit ScopedValueVisit(Value &I) {
      LLVM_DEBUG(dbgs() << "  " << Format(&I) << "\n");
    }
    ~ScopedValueVisit() { LLVM_DEBUG(dbgs() << "\n"); }
  }; // end of struct ScopedValueVisit

  /// Prints a debug message about start of mapping a Value.
  ///
  /// \param Key Pointer to a Value which is being mapped.
  static void StartMapValue(Value *Value) {
    if (!ClDebugValueMap && !ClDebugAll)
      return;
    if (isa<BasicBlock>(Value))
      return;
    if (isa<Function>(Value))
      return;
    LLVM_DEBUG(dbgs() << "    |- Mapping " << Format(Value) << '\n');
  }

  /// Prints a debug message about a mapping of Function pairs.
  ///
  /// \param Name Some identifier to associate this print with a container.
  /// \param Key Pointer to a Function which is used as a key in the pair.
  /// \param Value Pointer to a Function which is used as a value in the pair.
  template <typename N>
  static void Map(N &&Name, Function *Key, Function *Value) {
    if (!ClDebugFunctionMap && !ClDebugAll)
      return;
    Map(Key->getName(), Value->getName(), std::forward<N>(Name));
  }

  /// Prints a debug message about a mapping of Value pairs.
  ///
  /// \param Name Some identifier to associate this print with a container.
  /// \param Key Pointer to a Value which is used as a key in the pair.
  /// \param Value Pointer to a Value which is used as a value in the pair.
  template <typename N> static void Map(N &&Name, Value *Key, Value *Value) {
    if (!ClDebugValueMap && !ClDebugAll)
      return;
    if (isa<BasicBlock>(Key))
      return;
    Map(Format(Key), Format(Value), std::forward<N>(Name));
  }

  /// Prints a debug message about a mapping of Type pairs.
  ///
  /// \param Name Some identifier to associate this print with a container.
  /// \param Key Pointer to a Type which is used as a key in the pair.
  /// \param Value Pointer to a Type which is used as a value in the pair.
  template <typename N> static void Map(N &&Name, Type *Key, Type *Value) {
    if (!ClDebugTypeMap && !ClDebugAll)
      return;
    Map(Format(Key), Format(Value), std::forward<N>(Name));
  }

  /// Prints a debug message when running a visitor function.
  template <typename K> static void Visitor(K &&Kind) {
    LLVM_DEBUG(dbgs() << "    |- " << std::forward<K>(Kind) << '\n');
  }

  /// Prints the point where deferred Values are to be processed.
  static void BeginProcessDeferred() {
    LLVM_DEBUG(dbgs() << "Deferred values:\n\n");
  }

  /// Formats an object by removing some leading whitespaces.
  ///
  /// \param Object A pointer to an object to format.
  /// \returns An std::string representation of the object.
  template <typename O> static std::string Format(O *Object) {
    if (!Object)
      return "<none>";
    std::string Repr;
    llvm::raw_string_ostream(Repr) << *Object;
    return StringRef(Repr).trim().str();
  }

  /// Prints a Value.
  ///
  /// \param V Value to print.
  /// \returns The input Value \p V.
  static Value *Emit(Value *V) {
    LLVM_DEBUG(dbgs() << "    " << Format(V) << '\n');
    return V;
  }

  /// Prints a no-op.
  static void EmitNoop() { LLVM_DEBUG(dbgs() << "    no-op" << '\n'); }

private:
  template <typename N, typename T>
  static void Map(T &&Key, T &&Value, N &&Name) {
    LLVM_DEBUG(dbgs() << "    |- " << std::forward<N>(Name) << ": "
                      << std::forward<T>(Key) << " ---> "
                      << std::forward<T>(Value) << '\n');
  }
}; // end of struct DebugPrint

/// A simple key-value map.
///
/// This template class provides a convenient to put a key-value pair into
/// the map or to retrieve a value associated with a key. This implementation
/// uses a vector because it's assumed that last mapped Values are accessed
/// more likely.
/// TODO: when time comes see if using an std::map is any faster.
template <typename T, size_t S = 64> struct SimpleMap {
  /// Shorthand to refer to the type the map stores.
  using ElementType = std::pair<T *, T *>;

  SimpleMap(std::string Name) : Name(Name) { Map.reserve(S); }

  /// Removes all elements from the map.
  void clear() {
    Map.clear();
    Map.reserve(S);
  }

  /// Inserts a key-value pair into the map.
  ///
  /// Typical usage:
  /// \code
  ///   SimpleMap<Type> SM{"Map"};
  ///   // Add to the map
  ///   SM.insert(KeyTy, ValueTy);
  /// \endcode
  ///
  /// \param Key The key.
  /// \param Value The value associated with the key.
  void insert(T *Key, T *Value) {
    DebugPrint::Map(Name, Key, Value);
    Map.push_back(ElementType(Key, Value));
  }

  /// Retrieves a value associated with a key from the map.
  ///
  /// If the \p Key is not found in the map, \p Key is returned.
  ///
  /// Typical usage:
  /// \code
  ///   SimpleMap<Type> SM{"Map"};
  ///   ...
  ///   // Retrieve from the map
  ///   Type * VTy = SM.get(KeyTy);
  /// \endcode
  ///
  /// \param Key The key.
  ///
  /// \returns The value associated with \p Key.
  T *get(T *Key) const {
    auto it = std::find_if(
        Map.crbegin(), Map.crend(),
        [&Key](const ElementType &element) { return element.first == Key; });
    return (it != Map.rend()) ? it->second : nullptr;
  }

  /// Iterates through the internal collection of mapped key-value pairs.
  ///
  /// \param Closure A lambda which is called for every key-value pair.
  void for_each(std::function<void(T *, T *)> Closure) const {
    for (const ElementType &E : Map)
      Closure(E.first, E.second);
  }

protected:
  /// The backing store of key-value pairs.
  std::vector<ElementType> Map;
  /// Custom name of this map.
  const std::string Name;
}; // end of struct SimpleMap

/// The core implementation of CHERIseed Pass.
///
/// Contains the implementation of all the IR transformations
/// CHERIseed Pass has to perform.
struct CHERIseed final : public InstVisitor<CHERIseed, Value *> {

  /// Shorthand for the base class, used to call its visitors.
  using Base = InstVisitor<CHERIseed, Value *>;

  /// Available runtime calls which are frequently emitted by the sanitizer.
  enum class RtKind {
    ADDRESS_GET,
    ADDRESS_SET,
    CHECK_ACCESS,
    CMPXCHG_CAP,
    CMPXCHG_CAP_HYBRID,
    COPY_CAP_WITH_OFFSET,
    DDC_GET,
    LOAD_CAP,
    LOAD_CAP_ATOMIC,
    LOAD_CAP_HYBRID,
    LOAD_CAP_HYBRID_ATOMIC,
    PCC_GET,
    PERMS_AND,
    RMW_CAP,
    RMW_CAP_HYBRID,
    STACK_CAP_INIT,
    STORE_CAP,
    STORE_CAP_ATOMIC,
    STORE_CAP_HYBRID,
    STORE_CAP_HYBRID_ATOMIC,
    THREAD_POINTER,
  };

  /// Holds the per-function context when visiting a function.
  struct VisitorContext final {
    VisitorContext() { reset(); }

    /// Resets this instance.
    void reset() {
      IRB = nullptr;
      BB = nullptr;
      AllocaIP = nullptr;
      F = nullptr;
      ReturnsCapability = false;
      ValueMap.clear();
    }

    /// Inserts a (Value, Value) pair into the Value map.
    ///
    /// \param V The Value used as the key.
    /// \param NV The replacement Value associated with \p V.
    void insert(Value *V, Value *NV) { ValueMap.insert(V, NV); }

    /// Retrieves the replacement Value of a Value from the Value map.
    ///
    /// \param V The Value to lookup.
    /// \returns Pointer to the replacement Value of \p V.
    Value *get(Value *V) const { return ValueMap.get(V); }

    /// Map of Values.
    SimpleMap<Value> ValueMap{"VM"};
    /// Pointer to an IRBuilder instance or nullptr.
    IRBuilder<> *IRB;
    /// Pointer to the currently developed BasicBlock.
    BasicBlock *BB;
    /// Insertion point where it is safe to add a new AllocaInst to the
    /// function.
    Instruction *AllocaIP;
    /// Pointer to the Function which is being developed.
    Function *F;
    /// True if the currently processed function returns a capability.
    bool ReturnsCapability;
  }; // end of struct VisitorContext

  /// RAII object which holds the actual insertion point information of a
  /// context. When an instance is destructed, it restores the previously
  /// saved insertion point. This helper also restores the original BasicBlock
  /// for the context.
  struct ContextInsertPointGuard final {
    explicit ContextInsertPointGuard(VisitorContext &VC)
        : VC(VC), BB(VC.BB), IPG(*VC.IRB) {}

    ~ContextInsertPointGuard() { VC.BB = BB; }

    /// Reference to a VisitorContext.
    VisitorContext &VC;
    /// Pointer to the original BasicBlock of the context.
    BasicBlock *BB;
    // RAII object that stores the current insertion point and restores it
    // when the object is destroyed. This includes the debug location.
    IRBuilderBase::InsertPointGuard IPG;
  }; // end of struct ContextInsertPointGuard

  /// This struct helps in building new initializers for GlobalValues.
  struct ConstantUse final {
    explicit ConstantUse(Use &U, size_t Depth) : UseSite(U), Depth(Depth) {}

    /// Returns true if trying to get GEP indices makes sense.
    bool canHaveGEPIndices() const {
      return !UseSite->getType()->isAggregateType() &&
             !UseSite->getType()->isVectorTy() && (Depth > 0);
    }

    /// Reference to the Use of this Constant.
    const Use &UseSite;
    /// Structural depth of nestedness of this Constant.
    const size_t Depth;
  };

  /// Shorthand for function call argument values.
  struct CallContext final {
    SmallVector<Value *, 8> Args;
    AttributeList Attrs;
  };

  CHERIseed(Module &M)
      : M(M), InputDL(M.getDataLayout()),
        DL(sanitizeDataLayout(M.getDataLayout())), Ctx(M.getContext()),
        VoidTy(Type::getVoidTy(Ctx)), Int8Ty(Type::getInt8Ty(Ctx)),
        Int8PtrTy(Int8Ty->getPointerTo()), AddrSizeTy(Type::getInt64Ty(Ctx)),
        IsPureCap(InputDL.getGlobalsAddressSpace() == kCapabilityAS) {
    // Change DL for the current Module to the sanitized one.
    M.setDataLayout(DL);
    // Use i128 to enforce 128-bit alignment. This is achieved by using
    // the appropriate DataLayout string.
    // %__cheriseed_cap_t = type { i128 }
    CapTy =
        StructType::create(Ctx, {Type::getInt128Ty(Ctx)}, "__cheriseed_cap_t");
    CapTy->setMinimumAlignment(Align(16));
    CapPtrTy = CapTy->getPointerTo();
    CapPermsTy = Type::getInt32Ty(Ctx);
    Type *InitializerFuncTy = PointerType::get(FunctionType::get(VoidTy, false),
                                               DL.getProgramAddressSpace());
    InitializerTy = StructType::create(
        Ctx,
        {AddrSizeTy, AddrSizeTy, AddrSizeTy, CapPermsTy, InitializerFuncTy},
        "__cheriseed_initializer_t");
  }

  /// Visits the module this pass is associated with.
  void run() {
    auto _ = DebugPrint::ScopedModuleVisit(M);
    // Visit the Globals.
    visitGlobals();
    // Visit the functions.
    InstVisitor::visit(M);
    stripDeadValues();
    stripAttributes();
  }

  // Visitor functions. See description of InstVisitor for further details.
  void visit(Function &F) {
    if (F.hasFnAttribute(kInternalAttribute))
      return;
    auto _ = DebugPrint::ScopedFunctionVisit(F);
    if (F.isDeclaration())
      return;
    // The pass might turn PHINode constant expression arguments into regular
    // instructions which need to be moved to their predecessor block.
    // Therefore, it is important to break critical edges.
    SplitAllCriticalEdges(F);
    // Reset the context before visiting a new Function.
    IRBuilder<> IRB{Ctx};
    VC.reset();
    VC.IRB = &IRB;
    // Clone the original function but change its prototype, if required.
    // The pass does this upfront because capabilities can appear anywhere
    // within the function's body.
    VC.F = mapFunction(&F);
    // The pass inserts an indirect return argument
    // if the function returns a capability.
    VC.ReturnsCapability = IsCapability(F.getReturnType());
    const size_t offset = VC.ReturnsCapability ? 1 : 0;
    for (size_t idx = 0, max_idx = F.arg_size(); idx < max_idx; ++idx)
      VC.insert(F.getArg(idx), VC.F->getArg(idx + offset));
    // Visit instructions within F.
    InstVisitor::visit(F.begin(), F.end());
    // Process instructions which were deferred to be resolved after visiting
    // all the instructions in F.
    DebugPrint::BeginProcessDeferred();
    visitDeferredPHINodes(F);
    visitDeferredValues();
    // Delete the body of the original function to remove references it holds.
    F.deleteBody();
  }

  void visit(BasicBlock &BB) {
    auto _ = DebugPrint::ScopedBasicBlockVisit(BB, true);
    BasicBlock *NBB = cast<BasicBlock>(mapValue(&BB));
    // If this BasicBlock was cached in advance, move it after the current one.
    if (VC.BB)
      NBB->moveAfter(VC.BB);
    VC.BB = NBB;
    VC.IRB->SetInsertPoint(VC.BB);
    InstVisitor::visit(BB.begin(), BB.end());
    _ = DebugPrint::ScopedBasicBlockVisit(*VC.BB, false);
  }

  void visit(Instruction &I) {
    auto _ = DebugPrint::ScopedValueVisit(I);
    VC.IRB->SetCurrentDebugLocation(I.getDebugLoc());
    Value *V = InstVisitor::visit(I);
    // Some instructions have no associated mapped Values.
    if (!V)
      return;
    VC.insert(&I, V);
    // Inherit name of the instruction, if there is no such specified.
    if (I.hasName() && !V->hasName())
      V->setName(I.getName());
  }

  Value *visitAddrSpaceCastInst(AddrSpaceCastInst &I);
  Value *visitAllocaInst(AllocaInst &A);
  Value *visitAtomicCmpXchgInst(AtomicCmpXchgInst &I);
  Value *visitAtomicRMWInst(AtomicRMWInst &I);
  Value *visitBitCastInst(BitCastInst &I);
  Value *visitCallInst(CallInst &I);
  Value *visitGetElementPtrInst(GetElementPtrInst &I);
  Value *visitICmpInst(ICmpInst &I);
  Value *visitInstruction(Instruction &I);
  Value *visitIntrinsicInst(IntrinsicInst &I);
  Value *visitIntToPtrInst(IntToPtrInst &I);
  Value *visitLoadInst(LoadInst &I);
  Value *visitPHINode(PHINode &I);
  Value *visitPtrToIntInst(PtrToIntInst &I);
  Value *visitStoreInst(StoreInst &I);
  Value *visitReturnInst(ReturnInst &I);
  Value *visitVAStartInst(VAStartInst &I);
  Value *visitVACopyInst(VACopyInst &I);
  Value *visitVAEndInst(VAEndInst &I);

  // Custom visitors which are not part of InstVisitor<>.
  Value *visitCallInlineAsm(CallInst &I);
  Value *visitCHERIIntrinsicInst(IntrinsicInst &I);
  Value *visitMemoryIntrinsicInst(IntrinsicInst &I);

  // Visitors of deferred instructions.
  void visitDeferredPHINodes(Function &F);
  void visitDeferredValues();

  // Visitor for Globals
  void visitGlobals();

protected:
  /// Alignment of a capability.
  static constexpr size_t kCapabilityAlignment = 16;

  /// Returns the storage size of an arbitrary Type.
  ///
  /// This function should not be called with non-sized types.
  ///
  /// \param Ty The type whose storage size is to be returned.
  ///
  /// \returns The storage size of \p Ty.
  unsigned getTypeStoreSize(Type *Ty);

  /// Takes the name of an object.
  ///
  /// This function is typically used on Values and Types.
  ///
  /// \param From The object whose name is to be taken away.
  /// \param To The object which gets the name of \p From.
  template <typename T, typename V = T> void takeName(T *From, V *To);

  /// Template function which maps a Type to another Type.
  ///
  /// Some types should be replaced by the sanitizer. This function is a
  /// convenient way to both map a Type and retrieve its mapped Type.
  ///
  /// For example, if \p Ty is 'i8 addrspace(200)*' the first call
  /// mapType(Ty) will look up the mapped type of \p Ty, which is
  /// __cheriseed_cap_t, and returns the mapped type. Any subsequent calls
  /// with the same type will return a cached value of the mapped type.
  ///
  /// \param Ty The input Type to map.
  /// \param IsArgTy If true, maps types for arguments. This means that
  ///        a capability, such as 'i8 addrspace(200)*' is mapped to
  ///        '__cheriseed_cap_t*' instead of '__cheriseed_cap_t'.
  ///
  /// \returns The Type associated with \p Ty.
  template <typename T = Type> T *mapType(Type *Ty, bool IsArgTy = true);

  /// This is the same as the template version. Don't use this directly.
  Type *mapTypeImpl(Type *Ty);

  /// Defer resolution of an unknown Value.
  ///
  /// \param V The input Value to defer.
  /// \param Replacement Function to return a temporary replacement, if one is
  /// not found.
  ///
  /// \returns The deferred value associated with \p V.
  template <typename T>
  T *deferValueResolution(T *V, std::function<T *()> Replacement);

  /// Maps a Function to another Function.
  ///
  /// This function is to be used when mapping functions directly. When mapping
  /// Values, use `mapValue()`.
  ///
  /// \param F The input Function to map.
  ///
  /// \returns The Function associated with \p F.
  Function *mapFunction(Function *F);

  /// Maps a Value to another Value.
  ///
  /// \param V The input Value to map.
  ///
  /// \returns The Value associated with \p V.
  Value *mapValue(Value *V);

  /// Helper structure to collect all GEP indices of a GlobalVariable which
  /// require runtime initialization.
  ///
  /// An example:
  /// @foo = global { %struct.S addrspace(200)* @bar }
  ///
  /// GlobalInitializerAnalysis can be used to collect pieces of information
  /// which refer to an operand in a GlobalVariable's initializer. Such info
  /// is necessary to emit runtime initialization sequences. When visiting
  /// 'foo' above, 'entries()' would return a list containing an entry which
  /// marks the GEP indices where '%struct.S addrspace(200)* @bar' appears:
  /// [0, 0]. It may or may not, depending on what '%struct.S', record that
  /// the accessor function of '@bar' is to be called.
  ///
  /// It is also possible that a ConstantExpr requires runtime initialization.
  /// Such expressions are address-space casts, for example. In such cases
  /// the recursive algorithm does not know if there is anything "wrong" with
  /// any of a ContantExpr's operands until all of them are visited. Should
  /// any of them require runtime init, it would set the rollback flag meaning
  /// that the very first parent with a GEP indice is the point of runtime
  /// initialization. For example:
  ///
  /// @foo = global i8* addrspacecast (i8 addrspace(200)* @bar to i8*)
  ///
  /// In this case only the 'addrspacecast' has a GEP indice, but the algorithm
  /// only realizes that it has to be runtime evaluated once it visits the
  /// operands. When visiting 'i8 addrspace(200)* @bar', it indicates rollback
  /// and so the whole address space cast would be runtime evaluated. Note that
  /// it might be required that '@bar' has an accessor function which is to be
  /// called independently of the AS cast.
  struct GlobalInitializerAnalysis {
    /// Entry stored by the analysis.
    struct Entry {
      Entry(Value *V, SmallVector<Value *, 8> Indices)
          : V(V), Indices(Indices) {}
      Value *const V;
      const SmallVector<Value *, 8> Indices;
    };

    using EntryList = SmallVector<Entry, 4>;
    using GlobalValueList = SmallVector<GlobalValue *, 4>;
    using iterator = Entry *;

    /// A scope for visiting an arbitrary operand in a GlobalVariable's
    /// initializer.
    struct Scope final {
      Scope(GlobalInitializerAnalysis &Analysis, Use &U)
          : Analysis(Analysis), U(U) {
        if (U.getUser()->getType()->isAggregateType()) {
          Analysis.ParentIndices.push_back(getIndexForUse(U));
          HasIndex = true;
        } else if (isa<GlobalValue>(U.getUser())) {
          HasIndex = true;
        } else {
          HasIndex = false;
        }
      }

      ~Scope() {
        if (U.getUser()->getType()->isAggregateType())
          Analysis.ParentIndices.pop_back();
        if (HasIndex)
          Analysis.Rollback = false;
      }

      /// Sets that the current Use must result in calling its accessor.
      void mustCallAccessor() {
        Analysis.GlobalValues.push_back(cast<GlobalValue>(U));
      }

      /// Sets that the current Use requires run-time processing.
      void mustInitializeRuntime() {
        if (HasIndex)
          Analysis.Entries.emplace_back(U, Analysis.ParentIndices);
        Analysis.Rollback = !HasIndex;
      }

      /// Returns if the analysis requested a rollback at some point.
      bool needsRollback() const { return Analysis.Rollback; }

    protected:
      GlobalInitializerAnalysis &Analysis;
      Use &U;
      bool HasIndex;
    };

    GlobalInitializerAnalysis(GlobalVariable *GV) : Rollback(false) {
      Initializer = GV->hasInitializer() ? GV->getInitializer() : nullptr;
      // The initializer is "operand 0", store it if needed.
      if (Initializer)
        ParentIndices.push_back(getIndexForUse(GV->getOperandUse(0)));
    }

    /// Returns an analysis scope for a use of a Value.
    Scope visit(Use &U) { return Scope(*this, U); }

    /// Returns the list of GlobalValues which were collected.
    const GlobalValueList &globals() const { return GlobalValues; }

    /// Returns the list of analysis entries which were collected.
    const EntryList &entries() const { return Entries; }

    /// Returns true if this GlobalVariable calls other accessor functions.
    bool callsAccessors() const { return !globals().empty(); }

    /// Returns true if this GlobalVariable needs runtime initialization.
    bool needsRuntimeInitialization() const { return !entries().empty(); }

    /// Returns true if this GlobalVariable is an aggregate type.
    bool isAggregateType() const {
      assert(Initializer && "Don't have initializer!");
      return Initializer->getType()->isAggregateType();
    }

    /// Returns the GEP index for a specific Use. This is not a list of indices.
    static ConstantInt *getIndexForUse(Use &U) {
      return ConstantInt::get((U.getUser()->getType()->isArrayTy()
                                   ? Type::getInt64Ty(U->getContext())
                                   : Type::getInt32Ty(U->getContext())),
                              U.getOperandNo());
    }

  protected:
    /// Initializer of the analyzed GlobalVariable, or nullptr.
    Constant *Initializer;
    /// List of GEP indices pointing to capabilities which
    /// can not be initialized static-link time.
    EntryList Entries;
    /// List of indices of the parent.
    SmallVector<Value *, 8> ParentIndices;
    /// List of GlobalVariables which appear in a GlobalVariable's initializer
    /// and need their accessors to be called.
    GlobalValueList GlobalValues;
    /// Indicates that an analysis scope, which has no index, requested that
    /// it must be runtime initialized. This means that the analysis should
    /// mark the first parent with index as runtime-initializeable.
    bool Rollback;
  };

  /// Maps the Constant initializer of a GlobalVariable.
  ///
  /// This function visits all operands of a GlobalVariable's initializer.
  /// It records if a specific operand has to be runtime-initialized in
  /// \p Analysis. Typically capabilities are the ones which must be processed
  /// runtime. It also records if an aliased GlobalVariable's accessor function
  /// has to be called. See more details at GlobalInitializerAnalysis.
  ///
  /// Note: this cannot be the part of 'mapValue()', which is for handling
  /// Values in Instructions.
  ///
  /// \param U Reference to the use of the Constant initializer.
  /// \param Analysis Reference to a GlobalInitializerAnalysis to be filled-in.
  ///
  /// \returns The mapped Constant.
  Constant *mapGlobalInitializer(Use &U, GlobalInitializerAnalysis &Analysis);

  /// Maps operands and type of an Instruction.
  ///
  /// \param V The input Instruction to map.
  ///
  /// \returns The Instruction associated with \p V.
  Instruction *mapInstruction(Instruction &I);

  /// Maps a GlobalVariable to another Value.
  /// Generates the accessor function if the global is modified by CHERIseed.
  ///
  /// \param GV The input GlobalVariable to map.
  /// \returns The pointer to the tuple containing data for global
  /// initialization if used or else nullptr.
  Constant *mapGlobalVariable(GlobalVariable *GV);

  /// Maps a GlobalAlias to another Value.
  ///
  /// \param GA The input GlobalAlias to map.
  void mapGlobalAlias(GlobalAlias *GA);

  /// Similar to Module::getOrInsertFunction(), but creates an accessor
  /// function for a global variable.
  ///
  /// \param GV The GlobalVariable to associate the function with.
  /// \returns A FunctionCallee wrapper for the requested function.
  Function *getOrInsertAccessorFunction(GlobalVariable *GV);

  /// Similar to Module::getOrInsertFunction(), but handles a case where the
  /// pass inserts a new function because of a library call. The named call
  /// might or might not exist at the time of request.
  ///
  /// \param Name Name of the function to return.
  /// \param FTy Type of the function to return.
  /// \param Attrs Attributes for the function if creation is necessary.
  /// \returns A FunctionCallee wrapper for the requested function.
  FunctionCallee getOrInsertLibraryCall(StringRef Name, FunctionType *FTy,
                                        AttributeList Attrs);

  /// Creates a new FunctionType based on an existing one.
  ///
  /// A FunctionType might require transformations, such as changes to the
  /// parameter types, amending to the parameter list or changing the return
  /// value.
  ///
  /// \param FTy FunctionType to transform.
  ///
  /// \returns A FunctionType derived from \p FTy.
  FunctionType *createFunctionType(FunctionType *FTy);

  /// Prepares arguments for a function call.
  ///
  /// Input arguments of a function call are subject to changes due to the
  /// transformation of the input IR. The input arguments are replaced with
  /// their mapped equivalents.
  ///
  /// \param I The call instruction.
  ///
  /// \returns The new call arguments and attributes.
  CallContext prepareCallArgs(CallInst &I);

  /// Creates the CHERIseed representation of a function.
  ///
  /// This function derives a new function based on \p F. The goal is to get
  /// rid of all addrspace(200) occurrences. The new function inherits many
  /// properties of the original one, including its name, metadata, comdat, etc.
  ///
  /// \param F Pointer to a Function.
  ///
  /// \returns CHERIseed representation of the original function with empty
  /// body.
  Function *replaceFunction(Function *F);

  /// Creates a runtime call.
  ///
  /// Note that this function does not map arguments.
  ///
  /// \param CallName Name of the runtime call to create.
  /// \param FTy FunctionType of the runtime call.
  /// \param Args Arguments to the call.
  ///
  /// \returns Pointer to the resulting CallInst.
  CallInst *createRtCall(const StringRef CallName, FunctionType *FTy,
                         ArrayRef<Value *> Args) {
    return createRtCall(CallName, "", FTy, Args);
  }

  /// Creates a runtime call.
  ///
  /// Note that this function does not map arguments.
  ///
  /// \param CallName Name of the runtime call to create.
  /// \param Name Name of the new instruction.
  /// \param FTy FunctionType of the runtime call.
  /// \param Args Arguments to the call.
  ///
  /// \returns Pointer to the resulting CallInst.
  CallInst *createRtCall(const StringRef CallName, const StringRef Name,
                         FunctionType *FTy, ArrayRef<Value *> Args);

  /// Creates a runtime call.
  ///
  /// Note that this function does not map arguments.
  ///
  /// \param Kind Kind of the call to create.
  /// \param Args Parameter pack of argument values to the call.
  ///
  /// \returns Pointer to the resulting CallInst.
  template <typename... V> CallInst *createRtCall(RtKind Kind, V *...Args) {
    return createRtCall<V...>(Kind, "", Args...);
  }

  /// Creates a runtime call.
  ///
  /// Note that this function does not map arguments.
  ///
  /// \param Kind Kind of the call to create.
  /// \param Name Name of the new instruction.
  /// \param Args Parameter pack of argument values to the call.
  ///
  /// \returns Pointer to the resulting CallInst.
  template <typename... V>
  CallInst *createRtCall(RtKind Kind, const StringRef Name, V *...Args);

  /// Creates a new alloca on stack.
  ///
  /// \param Ty The Type to allocate.
  /// \param Name Name of the new allocation.
  ///
  /// \returns Pointer to the resulting Value.
  AllocaInst *createAlloca(Type *Ty, const Twine &Name = "");

  /// Creates a new alloca on stack.
  ///
  /// \param Ty The Type to allocate.
  /// \param ArraySize Size of the array or nullptr.
  /// \param Align Alignment of the alloca.
  /// \param Name Name of the new allocation.
  ///
  /// \returns Pointer to the resulting Value.
  AllocaInst *createAlloca(Type *Ty, Value *ArraySize, Align Align,
                           const Twine &Name);

  /// Derives a pointer from a capability.
  ///
  /// Such conversion might be necessary in hybrid code or when dealing with
  /// complex loads and stores.
  ///
  /// \param Cap The capability from which to create a pointer.
  /// \param PtrTy Type of the pointer to create.
  ///
  /// \returns Pointer to the resulting Value.
  Value *createCapToPtr(Value *Cap, Type *PtrTy);

  /// Derives a capability from a pointer using DDC.
  ///
  /// Such conversion might be necessary in hybrid code.
  ///
  /// \param Addr The original pointer.
  /// \param Out If set, this is the output capability, otherwise it is \p Addr.
  /// \param FromPCC If true, the function derives from PCC,
  /// otherwise it derives from DDC.
  ///
  /// \returns Pointer to the resulting Value.
  Value *createPtrToCap(Value *Addr, Value *Out = nullptr,
                        bool FromPCC = false);

  /// Creates a capability to a Value on the stack.
  ///
  /// \param V The Value to reference with the new capability.
  /// \param Size Length of the capability to create. If \p V is nullptr Size
  /// is also set to 0. If nullptr size is derived from the type of \p V.
  /// \param Name The base name to use for new instructions.
  /// \param InEntryBlock If true, create the new instruction in the entry
  /// block.
  ///
  /// \returns Pointer to the resulting Value.
  Value *createShadowCapOnStack(Value *V, Value *Size, StringRef Name,
                                bool InEntryBlock);

  /// Creates a capability to an alloca.
  ///
  /// \param Alloca Pointer to the AllocaInst.
  /// \param InEntryBlock If true, create the new instruction in the entry
  /// block.
  ///
  /// \returns Pointer to the resulting Value.
  Value *createCapToAlloca(AllocaInst *Alloca, bool InEntryBlock);

  /// Performs an access check and returns a pointer derived from a capability.
  ///
  /// \param Cap The capability to check and from which to create a pointer.
  /// \param PtrTy Type of the pointer to create.
  /// \param Size Size of the access to be made.
  /// \param PermsReq BitMask of required permissions for the check.
  ///
  /// \returns Pointer to the resulting Value.
  Value *createCapAccessCheck(Value *Cap, Type *Ty, unsigned Size,
                              unsigned PermsReq);

  /// Removes Values which are left behind during the transformations and
  /// are no longer used.
  void stripDeadValues();

  /// Removes attributes inserted by the pass. These attributes are only
  /// useful while processing the input IR.
  void stripAttributes();

  /// Sanitizes the input DataLayout.
  ///
  /// The pass should ignore capability address spaces during its operation.
  ///
  /// \param DL Input DataLayout
  ///
  /// \returns A sanitized DataLayout which then can be used by the pass.
  static DataLayout sanitizeDataLayout(const DataLayout &DL);

  /// The Module being instrumented by the pass.
  Module &M;
  /// The input DataLayout.
  DataLayout InputDL;
  /// The current DataLayout.
  DataLayout DL;
  /// The current context.
  LLVMContext &Ctx;
  /// Shorthand for 'void'.
  Type *VoidTy;
  /// Shorthand for 'i8'.
  Type *Int8Ty;
  /// Shorthand for 'i8*'.
  PointerType *Int8PtrTy;
  /// Shorthand for '%__cheriseed_cap_t'.
  StructType *CapTy;
  /// Shorthand for '%__cheriseed_cap_t*'.
  PointerType *CapPtrTy;
  /// Type used for passing capability permissions.
  Type *CapPermsTy;
  /// Shorthand for 'i64', used where passing addresses.
  Type *AddrSizeTy;
  /// Shorthand for '%__cheriseed_initializer_t'.
  StructType *InitializerTy;
  /// A map used to map input Type-s.
  SimpleMap<Type> TypeMap{"TM"};
  /// A map used to map global Value-s per Module.
  SimpleMap<GlobalValue> GlobalMap{"GVM"};
  /// A map used to map Function-s per Module.
  SimpleMap<Function> FunctionMap{"FM"};
  /// A vector tracking library calls inserted by the pass.
  SmallVector<Function *, 16> LibraryCalls;
  /// Context for the currently visited Function is stored in a separate
  /// struct to emphasise that this is a per-function data.
  VisitorContext VC;
  /// Map of values whose resolution is deferred.
  ///
  /// Because the pass traverses BasicBlock as they appear in the IR and
  /// not according to CFG, there are cases where a Value is yet unknown.
  /// These values will be resolved at the end.
  SimpleMap<Value> DeferredValueMap{"DVM"};
  /// True if this is Pure-Cap ABI, otherwise false.
  const bool IsPureCap;
}; // end of struct CHERIseed

/// Legacy module pass for cheriseed instrumentation
///
/// This pass instruments an input IR which possibly contains capabilities.
/// The IR is transformed in a way so that addrspace(200) annotations get
/// eliminated and calls to CHERIseed's runtime are inserted to resemble
/// the behavior of capabilities but on an architecture which does not
/// natively support such.
struct CHERIseedSanitizerLegacyPass final : ModulePass {
  // Pass identification, replacement for typeid
  static char ID;

  CHERIseedSanitizerLegacyPass() : ModulePass(ID) {
    initializeCHERIseedSanitizerLegacyPassPass(
        *PassRegistry::getPassRegistry());
  }

  StringRef getPassName() const override {
    return "CHERIseedSanitizerLegacyPass";
  };

  bool runOnModule(Module &M) override;
}; // end of struct CHERIseedSanitizerLegacyPass

} // end of anonymous namespace

bool CHERIseedSanitizerLegacyPass::runOnModule(Module &M) {
  CHERIseed(M).run();
  // This pass always transforms the input IR.
  return true;
}

char CHERIseedSanitizerLegacyPass::ID = 0;

PreservedAnalyses CHERIseedSanitizerPass::run(Module &M,
                                              ModuleAnalysisManager &MAM) {
  CHERIseed(M).run();
  // TODO: Can we specifically select the outdated ones?
  // Mark every analysis as outdated
  return PreservedAnalyses::none();
}

Value *CHERIseed::visitAddrSpaceCastInst(AddrSpaceCastInst &I) {
  DebugPrint::Visitor("AddrSpaceCast");
  Type *DstTy = mapType(I.getDestTy());
  // At least one of the operands should be a pointer to a capability.
  assert(((mapType(I.getSrcTy()) == CapPtrTy) || (DstTy == CapPtrTy)) &&
         "Should not happen");
  if (IsCapability(I.getSrcTy()))
    return createCapToPtr(mapValue(I.getPointerOperand()), DstTy);
  return createPtrToCap(mapValue(I.getPointerOperand()));
}

Value *CHERIseed::visitAllocaInst(AllocaInst &I) {
  DebugPrint::Visitor("AllocaInst");
  // If alloca allocates a capability on stack then allocate __cheriseed_cap_t:
  //   %2 = alloca i8 addrspace(200)*, align 16
  // is turned into
  //   %2 = alloca %__cheriseed_cap_t, align 16
  // Not using 'createAllocaCap(CapTy)' because we would like to create
  // the AllocaInst in place and not in the EntryBlock.
  AllocaInst *NI =
      VC.IRB->CreateAlloca(mapType(I.getAllocatedType(), /* IsArgTy */ false),
                           mapValue(I.getArraySize()));
  NI->setAlignment(std::max(Align(I.getAlignment()),
                            DL.getPrefTypeAlign(NI->getAllocatedType())));
  if (I.hasName())
    NI->setName(I.getName());
  DebugPrint::Emit(NI);
  if (!IsCapability(I.getType()))
    return NI;

  // In pure-cap, create a shadow capability that will control the access
  // to the original alloca'd variable.
  return createCapToAlloca(NI, /* InEntryBlock */ false);
}

Value *CHERIseed::visitAtomicCmpXchgInst(AtomicCmpXchgInst &I) {
  DebugPrint::Visitor("AtomicCmpXchgInst");
  Value *Base = I.getPointerOperand();
  PointerType *BaseTy = cast<PointerType>(Base->getType());
  bool HasCapabilityBase = IsCapability(BaseTy);
  bool IsCapabilityOperation = IsCapability(I.getNewValOperand()->getType());

  // Fall back to default visitor if there is no capability involved.
  if (!HasCapabilityBase && !IsCapabilityOperation)
    return Base::visitAtomicCmpXchgInst(I);

  // Mapped operands
  Value *MBase = mapValue(Base);
  Value *MCmp = mapValue(I.getCompareOperand());
  Value *MNew = mapValue(I.getNewValOperand());

  // Compare-exchange a capability.
  if (IsCapabilityOperation) {
    Constant *SuccessOrdering =
        ConstantInt::get(Int8Ty, OrderingToABI(I.getSuccessOrdering()));
    Constant *FailureOrdering =
        ConstantInt::get(Int8Ty, OrderingToABI(I.getFailureOrdering()));
    Value *AllocaOrigCap = createAlloca(CapTy);
    DebugPrint::Emit(AllocaOrigCap);
    return createRtCall(
        HasCapabilityBase ? RtKind::CMPXCHG_CAP : RtKind::CMPXCHG_CAP_HYBRID,
        MBase, MCmp, MNew, AllocaOrigCap, SuccessOrdering, FailureOrdering);
  }

  // Compare-exchange some other type through a capability.
  Type *MNewTy = MNew->getType();
  Value *NBase = createCapAccessCheck(
      MBase, MNewTy->getPointerTo(), getTypeStoreSize(MNewTy),
      cheriseed::abi::permissions::LOAD | cheriseed::abi::permissions::STORE);
  Value *NI = VC.IRB->CreateAtomicCmpXchg(
      NBase, MCmp, MNew, I.getAlign(), I.getSuccessOrdering(),
      I.getFailureOrdering(), I.getSyncScopeID());
  DebugPrint::Emit(NI);
  return NI;
}

Value *CHERIseed::visitAtomicRMWInst(AtomicRMWInst &I) {
  DebugPrint::Visitor("AtomicRMWInst");
  Value *Base = I.getPointerOperand();
  PointerType *BaseTy = cast<PointerType>(Base->getType());
  bool HasCapabilityBase = IsCapability(BaseTy);
  bool IsCapabilityOperation = IsCapability(I.getValOperand()->getType());

  // Fall back to default visitor if there is no capability involved.
  if (!HasCapabilityBase && !IsCapabilityOperation)
    return Base::visitAtomicRMWInst(I);

  // Mapped operands
  Value *MAddr = mapValue(Base);
  Value *MVal = mapValue(I.getValOperand());

  // Read-modify-write a capability.
  if (IsCapabilityOperation) {
    Constant *Op = ConstantInt::get(Int8Ty, AtomicRMWOpToABI(I.getOperation()));
    Constant *Ordering =
        ConstantInt::get(Int8Ty, OrderingToABI(I.getOrdering()));
    Value *AllocCap = createAlloca(CapTy);
    return createRtCall(HasCapabilityBase ? RtKind::RMW_CAP
                                          : RtKind::RMW_CAP_HYBRID,
                        MAddr, MVal, AllocCap, Op, Ordering);
  }

  // Otherwise, do a regular atomic operation through a capability.
  Type *MValTy = MVal->getType();
  Value *NBase = createCapAccessCheck(
      MAddr, MValTy->getPointerTo(), getTypeStoreSize(MValTy),
      cheriseed::abi::permissions::LOAD | cheriseed::abi::permissions::STORE);
  Value *NI = VC.IRB->CreateAtomicRMW(I.getOperation(), NBase, MVal,
                                      I.getAlign(), I.getOrdering());
  DebugPrint::Emit(NI);
  return NI;
}

Value *CHERIseed::visitBitCastInst(BitCastInst &I) {
  DebugPrint::Visitor("BitCast");
  if (!IsCapability(I.getDestTy()))
    return Base::visitBitCastInst(I);
  // Capability to capability casts are no-ops.
  Value *MV = mapValue(I.getOperand(0));
  DebugPrint::EmitNoop();
  return MV;
}

Value *CHERIseed::visitCallInst(CallInst &I) {
  DebugPrint::Visitor("CallInst");

  Value *CalledOP = I.getCalledOperand();
  if (isa<InlineAsm>(CalledOP))
    return visitCallInlineAsm(I);

  // Prepare call arguments, this is common for all cases below.
  CallContext Ctx = prepareCallArgs(I);
  FunctionType *FTy = mapType<FunctionType>(I.getFunctionType());
  Value *Callee;
  if (Function *F = dyn_cast<Function>(CalledOP)) {
    // Direct function call
    Callee = mapFunction(F);
  } else if (Argument *A = dyn_cast<Argument>(CalledOP)) {
    // Indirect call via a formal argument.
    Callee = mapValue(A);
  } else if (Instruction *CI = dyn_cast<Instruction>(CalledOP)) {
    Callee = mapValue(CI);
  } else if (ConstantExpr *CE = dyn_cast<ConstantExpr>(CalledOP)) {
    // This case is very similar to the case when CalledOP is an Instruction.
    // It's kept separate but could potentially be merged with that other case.
    Callee = mapValue(CE);
  } else if (isa<GlobalAlias>(CalledOP)) {
    // Call via an alias.
    // Not using mapValue here because it inserts an unwanted call.
    Callee = GlobalMap.get(cast<GlobalAlias>(CalledOP));
  } else {
    errs() << "visitCallInst: " << I << "\n";
    llvm_unreachable("Unexpected case");
  }

  if (Callee->getType() == CapPtrTy)
    Callee = createCapAccessCheck(Callee, FTy->getPointerTo(), 0,
                                  cheriseed::abi::permissions::LOAD |
                                      cheriseed::abi::permissions::EXECUTE);
  CallInst *NV = VC.IRB->CreateCall(FTy, Callee, Ctx.Args);
  NV->setAttributes(Ctx.Attrs);
  // FIXME: clone other properties when we CreateCall? Elsewhere too.
  DebugPrint::Emit(NV);
  return NV;
}

Value *CHERIseed::visitGetElementPtrInst(GetElementPtrInst &I) {
  DebugPrint::Visitor("GEP");
  if (I.getPointerAddressSpace() != kCapabilityAS) {
    SmallVector<Value *, 4> Indices;
    for (auto &Idx : I.indices())
      Indices.push_back(mapValue(Idx));

    Value *GEP;
    if (I.isInBounds())
      GEP = VC.IRB->CreateInBoundsGEP(
          mapType(I.getSourceElementType(), /* IsArgTy */ false),
          mapValue(I.getPointerOperand()), Indices);
    else
      GEP = VC.IRB->CreateGEP(
          mapType(I.getSourceElementType(), /* IsArgTy */ false),
          mapValue(I.getPointerOperand()), Indices);
    return DebugPrint::Emit(GEP);
  }

  if (I.hasAllConstantIndices()) {
    APInt GepOffset(DL.getIndexTypeSizeInBits(I.getType()), 0);
    bool Result = I.accumulateConstantOffset(InputDL, GepOffset);
    (void)Result;
    assert(Result && "Should not happen");
    Value *Offset = ConstantInt::get(AddrSizeTy, GepOffset);
    Value *AllocCap = createAlloca(CapTy);
    return createRtCall(RtKind::COPY_CAP_WITH_OFFSET, AllocCap,
                        mapValue(I.getPointerOperand()), Offset);
  }

  if (I.hasIndices()) {
    Type *SourceType = llvm::PointerType::getUnqual(
        mapType(I.getPointerOperandType()->getPointerElementType()));

    if (IsCapability(I.getSourceElementType()))
      SourceType = CapPtrTy;

    // Intermediate pointer of target type that will be used by the GEP.
    Value *CapAddr =
        createRtCall(RtKind::ADDRESS_GET, mapValue(I.getPointerOperand()));
    Value *Ptr = VC.IRB->CreateIntToPtr(CapAddr, SourceType);
    DebugPrint::Emit(Ptr);

    // Retrieve all indices of the GEP in order to re-construct it with a
    // different source pointer in the new function.
    SmallVector<Value *, 4> GEPIndices;
    for (const auto &Idx : I.indices())
      GEPIndices.push_back(mapValue(Idx));

    Value *NI =
        VC.IRB->CreateGEP(SourceType->getPointerElementType(), Ptr, GEPIndices);
    // Note: not expecting a GetElementPtrConstantExpr here.
    cast<GetElementPtrInst>(NI)->setIsInBounds(I.isInBounds());
    DebugPrint::Emit(NI);

    // This cap replaces the output of the GEP.
    Value *AllocCap = createAlloca(CapTy);
    Value *PtrToInt = DebugPrint::Emit(VC.IRB->CreatePtrToInt(NI, AddrSizeTy));
    return createRtCall(RtKind::ADDRESS_SET, AllocCap,
                        mapValue(I.getPointerOperand()), PtrToInt);
  }

  llvm_unreachable("GEP: not implemented case");
}

Value *CHERIseed::visitICmpInst(ICmpInst &I) {
  DebugPrint::Visitor("ICmpInst");
  Value *LHS = I.getOperand(0);
  // We assume a well-formed IR: if LHS is a capability then RHS is that too.
  if (!IsCapability(LHS->getType()))
    return Base::visitICmpInst(I);

  Value *RHS = I.getOperand(1);
  Value *LHSAddr;
  Value *RHSAddr;

  // Need to handle comparison to null.
  if (!isa<ConstantPointerNull>(LHS))
    LHSAddr = createRtCall(RtKind::ADDRESS_GET, mapValue(LHS));
  else
    LHSAddr = ConstantData::getNullValue(AddrSizeTy);

  // Need to handle comparison to null.
  if (!isa<ConstantPointerNull>(RHS))
    RHSAddr = createRtCall(RtKind::ADDRESS_GET, mapValue(RHS));
  else
    RHSAddr = ConstantData::getNullValue(AddrSizeTy);

  return DebugPrint::Emit(
      VC.IRB->CreateICmp(I.getPredicate(), LHSAddr, RHSAddr));
}

Value *CHERIseed::visitInstruction(Instruction &I) {
  DebugPrint::Visitor("Instruction");
  Instruction *NI = mapInstruction(I);
  VC.IRB->Insert(NI);
  DebugPrint::Emit(NI);
  return NI;
}

Value *CHERIseed::visitIntrinsicInst(IntrinsicInst &I) {
  DebugPrint::Visitor("IntrinsicInst");
  StringRef Name = I.getCalledFunction()->getName();
  if (Name.startswith("llvm.cheri."))
    return visitCHERIIntrinsicInst(I);
  if (I.mayReadOrWriteMemory())
    return visitMemoryIntrinsicInst(I);

  Value *NI;
  switch (I.getIntrinsicID()) {
  default:
    return Base::visitIntrinsicInst(I);
  // FIXME: fix these.
  case Intrinsic::dbg_value:
  case Intrinsic::dbg_declare:
  case Intrinsic::dbg_addr:
  case Intrinsic::dbg_label:
    return nullptr;
  case Intrinsic::frameaddress:
  case Intrinsic::returnaddress: {
    // Handle @llvm.{frameaddress, returnaddress}.p0i8() the default way.
    if (!IsCapability(I.getType())) {
      NI = Base::visitIntrinsicInst(I);
      break;
    }
    // Handle @llvm.{frameaddress, returnaddress}.p200i8
    AllocaInst *AllocCap = createAlloca(CapTy);
    Value *Intrinsic = VC.IRB->CreateCall(
        Intrinsic::getDeclaration(&M, I.getIntrinsicID(), Int8PtrTy),
        mapValue(I.getArgOperand(0)));
    Value *Addr = VC.IRB->CreatePtrToInt(Intrinsic, AddrSizeTy);
    NI = createRtCall(RtKind::COPY_CAP_WITH_OFFSET, AllocCap,
                      ConstantPointerNull::get(CapPtrTy), Addr);
  } break;
  case Intrinsic::thread_pointer:
    // Handle @llvm.thread.pointer.p0i8() the default way.
    if (!IsCapability(I.getType())) {
      NI = Base::visitIntrinsicInst(I);
    } else {
      AllocaInst *AllocCap = createAlloca(CapTy);
      NI = createRtCall(RtKind::THREAD_POINTER, AllocCap);
    }
    break;
  }

  assert(NI && "Value was not handled");
  DebugPrint::Emit(NI);
  return NI;
}

Value *CHERIseed::visitIntToPtrInst(IntToPtrInst &I) {
  DebugPrint::Visitor("IntToPtr");
  if (I.getAddressSpace() != kCapabilityAS)
    return Base::visitIntToPtrInst(I);

  Value *AllocCap = createAlloca(CapTy);
  Value *IntV = mapValue(I.getOperand(0));
  if (IntV->getType() != AddrSizeTy) {
    IntV = VC.IRB->CreateZExt(IntV, AddrSizeTy);
    DebugPrint::Emit(IntV);
  }
  // We need to derive the new capability from nullcap with a call like this:
  //   __cheriseed_copy_cap_with_offset(nullptr, &cap, VA);
  // The reason is that 'inttoptr' should never create a valid capability.
  // There are builtins and addrspacecast to do that.
  return createRtCall(RtKind::COPY_CAP_WITH_OFFSET, AllocCap,
                      Constant::getNullValue(CapPtrTy), IntV);
}

Value *CHERIseed::visitLoadInst(LoadInst &I) {
  DebugPrint::Visitor("LoadInst");

  Type *PtrTy = I.getPointerOperandType();
  bool HasCapabilityBase = IsCapability(PtrTy);
  // If the base pointer is neither a capability nor a pointer to a capability
  // it is safe to visit the instruction using the default visitor.
  if (!HasCapabilityBase && !IsPointerToCapability(PtrTy))
    return Base::visitLoadInst(I);

  Type *ValTy = I.getType();
  Value *NAddr = mapValue(I.getPointerOperand());

  // Handle loads of capabilities.
  if (IsCapability(ValTy)) {
    AllocaInst *AllocCap = createAlloca(CapTy);
    if (!I.isAtomic())
      return createRtCall(HasCapabilityBase ? RtKind::LOAD_CAP
                                            : RtKind::LOAD_CAP_HYBRID,
                          NAddr, AllocCap);
    Constant *CABIOrdering =
        ConstantInt::get(Int8Ty, (int)toCABI(I.getOrdering()));
    return createRtCall(HasCapabilityBase ? RtKind::LOAD_CAP_ATOMIC
                                          : RtKind::LOAD_CAP_HYBRID_ATOMIC,
                        AllocCap, NAddr, CABIOrdering);
  }

  // Handle any other loads.
  const unsigned StoreSize = getTypeStoreSize(ValTy);
  Type *NValTy = mapType(ValTy->getPointerTo());
  Value *Ptr = createCapAccessCheck(NAddr, NValTy, StoreSize,
                                    cheriseed::abi::permissions::LOAD);
  LoadInst *NI = VC.IRB->CreateLoad(mapType(ValTy), Ptr, I.isVolatile());
  NI->setOrdering(I.getOrdering());
  NI->setAlignment(I.getAlign());
  DebugPrint::Emit(NI);
  return NI;
}

Value *CHERIseed::visitPHINode(PHINode &I) {
  // Not using 'mapValue()' here because we need to check if this is the
  // first occurrence of this instruction. If 'mapvalue()' was used it would
  // abort the compilation because it does not map PHINodes.
  assert(!VC.get(&I) && "PHINode visited twice");
  DebugPrint::Visitor("PHINode (deferred)");
  // Emit a temporary PHINode without operands which will get fully resolved
  // once all the BasicBlocks in the function got visited.
  return DebugPrint::Emit(VC.IRB->CreatePHI(mapType(I.getType()), 0));
}

Value *CHERIseed::visitPtrToIntInst(PtrToIntInst &I) {
  DebugPrint::Visitor("PtrToInt");
  Value *Ptr = I.getPointerOperand();
  Type *PtrTy = Ptr->getType();
  if (IsCapability(PtrTy))
    return createRtCall(RtKind::ADDRESS_GET, mapValue(Ptr));
  return Base::visitPtrToIntInst(I);
}

Value *CHERIseed::visitStoreInst(StoreInst &I) {
  DebugPrint::Visitor("StoreInst");

  Type *PtrTy = I.getPointerOperandType();
  bool HasCapabilityBase = IsCapability(PtrTy);
  // If the base pointer is neither a capability nor a pointer to a capability
  // it is safe to visit the instruction using the default visitor.
  if (!HasCapabilityBase && !IsPointerToCapability(PtrTy))
    return Base::visitStoreInst(I);

  Type *ValTy = I.getValueOperand()->getType();
  Value *NAddr = mapValue(I.getPointerOperand());
  Value *MV = mapValue(I.getValueOperand());

  // Handle stores of capabilities.
  if (IsCapability(ValTy)) {
    if (!I.isAtomic())
      return createRtCall(HasCapabilityBase ? RtKind::STORE_CAP
                                            : RtKind::STORE_CAP_HYBRID,
                          NAddr, MV);
    Constant *CABIOrdering =
        ConstantInt::get(Int8Ty, (int)toCABI(I.getOrdering()));
    return createRtCall(HasCapabilityBase ? RtKind::STORE_CAP_ATOMIC
                                          : RtKind::STORE_CAP_HYBRID_ATOMIC,
                        NAddr, MV, CABIOrdering);
  }

  // Handle any other stores.
  unsigned StoreSize = getTypeStoreSize(ValTy);
  Type *NValTy = mapType(ValTy->getPointerTo());
  Value *Ptr = createCapAccessCheck(NAddr, NValTy, StoreSize,
                                    cheriseed::abi::permissions::STORE);
  StoreInst *NI = VC.IRB->CreateStore(MV, Ptr, I.isVolatile());
  NI->setOrdering(I.getOrdering());
  NI->setAlignment(I.getAlign());
  DebugPrint::Emit(NI);
  // Do not map store instructions, it is not necessary.
  // Original store instructions should have no return value.
  return nullptr;
}

Value *CHERIseed::visitReturnInst(ReturnInst &I) {
  DebugPrint::Visitor("ReturnInst");
  if (!VC.ReturnsCapability)
    return Base::visitReturnInst(I);
  // The first argument is used always to return on stack.
  createRtCall(RtKind::COPY_CAP_WITH_OFFSET, VC.F->getArg(0),
               mapValue(I.getReturnValue()), ConstantInt::get(AddrSizeTy, 0));
  Value *Ret = VC.IRB->CreateRet(VC.F->getArg(0));
  DebugPrint::Emit(Ret);
  return Ret;
}

Value *CHERIseed::visitVAStartInst(VAStartInst &I) {
  DebugPrint::Visitor("VAStartInst");
  if (!IsCapability(I.getArgList()->getType()))
    return Base::visitVAStartInst(I);
  Value *VASlotCap = VC.F->getArg(VC.F->arg_size() - 1);
  Value *VAListCap = mapValue(I.getArgList());
  createRtCall(RtKind::STORE_CAP, VAListCap, VASlotCap);
  return nullptr;
}

Value *CHERIseed::visitVACopyInst(VACopyInst &I) {
  DebugPrint::Visitor("VACopyInst");
  if (!IsCapability(I.getDest()->getType()))
    return Base::visitVACopyInst(I);
  Value *MSrc = mapValue(I.getSrc());
  Value *MDst = mapValue(I.getDest());
  Value *AllocaCap = createAlloca(CapTy);
  Value *VAList = createRtCall(RtKind::LOAD_CAP, MSrc, AllocaCap);
  createRtCall(RtKind::STORE_CAP, MDst, VAList);
  return nullptr;
}

Value *CHERIseed::visitVAEndInst(VAEndInst &I) {
  DebugPrint::Visitor("VAEndInst");
  if (!IsCapability(I.getArgList()->getType()))
    return Base::visitVAEndInst(I);
  Value *VAListShadowCap = mapValue(I.getArgList());
  Value *VAList =
      createCapAccessCheck(VAListShadowCap, CapPtrTy, kCapabilityAlignment, 0);
  // FIXME: Replace with TAG_CLEAR once tags are supported
  createRtCall(RtKind::PERMS_AND, VAList, VAList,
               ConstantInt::getNullValue(AddrSizeTy));
  return nullptr;
}

Value *CHERIseed::visitCallInlineAsm(CallInst &I) {
  DebugPrint::Visitor("CallInlineAsm");

  InlineAsm *IA = cast<InlineAsm>(I.getCalledOperand());
  auto AsmStr = IA->getAsmString();
  const bool IsEmpty = StringRef(AsmStr).trim().empty();

  // Returns a placeholder instruction so that dependent mappings don't break.
  const auto CreatePlaceHolder = [&]() -> Value * {
    Type *RetTy = mapType(I.getType());
    if (RetTy != VoidTy)
      return VC.IRB->CreateBitCast(Constant::getNullValue(RetTy), RetTy);
    return nullptr;
  };

  SmallVector<Value *, 8> Args;
  for (auto &Arg : I.args()) {
    // Support compiler barriers
    // If there is no actual asm in the inline assembly routine, allow
    // passing capabilities to it.
    if ((CapPtrTy == mapType(Arg->getType())) && !IsEmpty) {
      Ctx.diagnose(
          DiagnosticInfoInlineAsm(I,
                                  "Inline assembly with capability operand is "
                                  "not supported with '-fsanitize=cheriseed'.",
                                  DiagnosticSeverity::DS_Error));
      return CreatePlaceHolder();
    }
    Args.push_back(mapValue(Arg));
  }

  // Verify that the new FunctionType matches the constraints.
  FunctionType *NFTy = mapType<FunctionType>(IA->getFunctionType());
  if (!InlineAsm::Verify(NFTy, IA->getConstraintString())) {
    Ctx.diagnose(DiagnosticInfoInlineAsm(
        I, "This inline assembly is not supported with '-fsanitize=cheriseed'.",
        DiagnosticSeverity::DS_Error));
    return CreatePlaceHolder();
  }

  if (!IsEmpty && !ClNoInlineAsm)
    Ctx.diagnose(DiagnosticInfoInlineAsm(
        I,
        "Inline assembly is potentially broken with '-fsanitize=cheriseed'. \n"
        "Please consider using some higher-level languages, if possible.",
        DiagnosticSeverity::DS_Warning));

  InlineAsm *NIA = InlineAsm::get(
      NFTy, IA->getAsmString(), IA->getConstraintString(), IA->hasSideEffects(),
      IA->isAlignStack(), IA->getDialect());
  CallInst *NI = VC.IRB->CreateCall(NIA, Args);
  // FIXME: clone other properties when we CreateCall? Elsewhere too.
  return DebugPrint::Emit(NI);
}

Value *CHERIseed::visitCHERIIntrinsicInst(IntrinsicInst &I) {
  DebugPrint::Visitor("CHERIIntrinsicInst");
  Function *F = I.getCalledFunction();
  StringRef RtNameEnd;

  switch (I.getIntrinsicID()) {
  default:
    errs() << "visitCHERIIntrinsicInst: " << I.getCalledFunction()->getName()
           << "\n";
    llvm_unreachable("Unhandled CHERI intrinsic");
    break;
  case Intrinsic::cheri_cap_address_get:
  case Intrinsic::cheri_cap_address_set:
  case Intrinsic::cheri_cap_base_get:
  case Intrinsic::cheri_cap_bounds_set:
  case Intrinsic::cheri_cap_bounds_set_exact:
  case Intrinsic::cheri_cap_build:
  case Intrinsic::cheri_cap_conditional_seal:
  case Intrinsic::cheri_cap_copy_from_high:
  case Intrinsic::cheri_cap_copy_to_high:
  case Intrinsic::cheri_cap_diff:
  case Intrinsic::cheri_cap_equal_exact:
  case Intrinsic::cheri_cap_flags_get:
  case Intrinsic::cheri_cap_flags_set:
  case Intrinsic::cheri_cap_length_get:
  case Intrinsic::cheri_cap_offset_get:
  case Intrinsic::cheri_cap_offset_set:
  case Intrinsic::cheri_cap_perms_and:
  case Intrinsic::cheri_cap_perms_check:
  case Intrinsic::cheri_cap_perms_get:
  case Intrinsic::cheri_cap_seal:
  case Intrinsic::cheri_cap_seal_entry:
  case Intrinsic::cheri_cap_sealed_get:
  case Intrinsic::cheri_cap_subset_test:
  case Intrinsic::cheri_cap_tag_clear:
  case Intrinsic::cheri_cap_tag_get:
  case Intrinsic::cheri_cap_to_pointer:
  case Intrinsic::cheri_cap_type_check:
  case Intrinsic::cheri_cap_type_copy:
  case Intrinsic::cheri_cap_type_get:
  case Intrinsic::cheri_cap_unseal:
    RtNameEnd =
        F->getName().drop_front(sizeof("llvm.cheri.cap.") - 1).rtrim(".i64");
    break;
  case Intrinsic::cheri_cap_from_pointer:
  case Intrinsic::cheri_cap_from_pointer_nonnull_zero:
    // These two are semantically equivalent to 'address_set' in CHERIseed.
    RtNameEnd = "address_set";
    break;
  case Intrinsic::cheri_cap_load_tags:
    RtNameEnd = F->getName()
                    .drop_front(sizeof("llvm.cheri.cap.") - 1)
                    .rtrim(".i64.p200i8");
    break;
  case Intrinsic::cheri_stack_cap_get:
    RtNameEnd = "stack_cap_get";
    break;
  case Intrinsic::cheri_bounded_stack_cap:
  case Intrinsic::cheri_ddc_get:
  case Intrinsic::cheri_pcc_get:
  case Intrinsic::cheri_representable_alignment_mask:
  case Intrinsic::cheri_round_representable_length:
    RtNameEnd =
        F->getName().drop_front(sizeof("llvm.cheri.") - 1).rtrim(".i64");
    break;
  }

  // Apply some cosmetics to the name.
  std::string RtName = RtNameEnd.str();
  std::replace(RtName.begin(), RtName.end(), '.', '_');
  // Build the new call.
  FunctionType *FTy = mapType<FunctionType>(F->getFunctionType());
  CallContext Ctx = prepareCallArgs(I);
  return createRtCall(RtName, FTy, Ctx.Args);
}

Value *CHERIseed::visitMemoryIntrinsicInst(IntrinsicInst &I) {
  DebugPrint::Visitor("MemoryIntrinsicInst");

  CallInst *NI;
  switch (I.getIntrinsicID()) {
  default:
    LLVM_DEBUG(dbgs() << "Fallback for " << I.getCalledFunction()->getName()
                      << "\n");
    return Base::visitIntrinsicInst(I);
  // FIXME: implement for the original value and the shadow cap too.
  case Intrinsic::lifetime_start:
  case Intrinsic::lifetime_end:
    return nullptr;
  case Intrinsic::memcpy:
  case Intrinsic::memcpy_inline: {
    // Call library memcpy(). The reason for this is that memcpy intrinsics
    // might get inlined by the compiler. In fact, memcpy_inline is always
    // inlined. However, tag management may require that all stores are visible
    // to it, therefore the library call.
    CallContext Ctx = prepareCallArgs(I);
    FunctionCallee FC;
    // Always call 'memcpy' in Pure-cap.
    // If this is a capability-based copy in hybrid, call 'memcpy_c'.
    bool IsHybridC = !IsPureCap && IsCapability(I.getArgOperand(0)->getType());
    if (IsPureCap || IsHybridC) {
      FunctionType *FTy = FunctionType::get(
          CapPtrTy, {CapPtrTy, CapPtrTy, CapPtrTy, AddrSizeTy}, false);
      FC = getOrInsertLibraryCall(IsPureCap ? "memcpy" : "memcpy_c", FTy, {});
      // Memcpy returns a capability. It should be equal to the first
      // operand. Use that to make up the required number of arguments.
      Ctx.Args.insert(Ctx.Args.begin(), Ctx.Args[0]);
      // drop_back(): The last argument, 'isvolatile', is not interesting
      // because the library call is always volatile. This is true for all
      // similar lines below.
      NI = VC.IRB->CreateCall(FC, ArrayRef<Value *>(Ctx.Args).drop_back());
      NI->addParamAttr(0, Attribute::Returned);
      break;
    }
    // Otherwise, simply call 'memcpy' in hybrid.
    FunctionType *FTy =
        FunctionType::get(Int8PtrTy, {Int8PtrTy, Int8PtrTy, AddrSizeTy}, false);
    FC = getOrInsertLibraryCall("memcpy", FTy, {});
    NI = VC.IRB->CreateCall(FC, ArrayRef<Value *>(Ctx.Args).drop_back());
    NI->setAttributes(Ctx.Attrs);
  } break;
  case Intrinsic::memmove: {
    // Note: same comments apply as for 'memcpy' above.
    CallContext Ctx = prepareCallArgs(I);
    FunctionCallee FC;
    bool IsHybridC = !IsPureCap && IsCapability(I.getArgOperand(0)->getType());
    if (IsPureCap || IsHybridC) {
      FunctionType *FTy = FunctionType::get(
          CapPtrTy, {CapPtrTy, CapPtrTy, CapPtrTy, AddrSizeTy}, false);
      FC = getOrInsertLibraryCall(IsPureCap ? "memmove" : "memmove_c", FTy, {});
      Ctx.Args.insert(Ctx.Args.begin(), Ctx.Args[0]);
      NI = VC.IRB->CreateCall(FC, ArrayRef<Value *>(Ctx.Args).drop_back());
      NI->addParamAttr(0, Attribute::Returned);
      break;
    }
    FunctionType *FTy =
        FunctionType::get(Int8PtrTy, {Int8PtrTy, Int8PtrTy, AddrSizeTy}, false);
    FC = getOrInsertLibraryCall("memmove", FTy, {});
    NI = VC.IRB->CreateCall(FC, ArrayRef<Value *>(Ctx.Args).drop_back());
    NI->setAttributes(Ctx.Attrs);
  } break;
  case Intrinsic::memset: {
    // Note: same comments apply as for 'memcpy' above.
    CallContext Ctx = prepareCallArgs(I);
    FunctionCallee FC;
    Type *I32Ty = Type::getInt32Ty(this->Ctx);
    // Input is 'i8' but the signature of the libcall expects 'i32'.
    Value *C = VC.IRB->CreateZExt(Ctx.Args[1], I32Ty);
    DebugPrint::Emit(C);
    bool IsHybridC = !IsPureCap && IsCapability(I.getArgOperand(0)->getType());
    if (IsPureCap || IsHybridC) {
      FunctionType *FTy = FunctionType::get(
          CapPtrTy, {CapPtrTy, CapPtrTy, I32Ty, AddrSizeTy}, false);
      FC = getOrInsertLibraryCall(IsPureCap ? "memset" : "memset_c", FTy, {});
      NI = VC.IRB->CreateCall(FC, {Ctx.Args[0], Ctx.Args[0], C, Ctx.Args[2]});
      NI->addParamAttr(0, Attribute::Returned);
      break;
    }
    FunctionType *FTy =
        FunctionType::get(Int8PtrTy, {Int8PtrTy, I32Ty, AddrSizeTy}, false);
    FC = getOrInsertLibraryCall("memset", FTy, {});
    NI = VC.IRB->CreateCall(FC, {Ctx.Args[0], C, Ctx.Args[2]});
    NI->setAttributes(Ctx.Attrs);
  } break;
  case Intrinsic::stackrestore: {
    // Handle @llvm.stackrestore.p0i8 the default way.
    if (!IsCapability(I.getArgOperand(0)->getType())) {
      NI = cast<CallInst>(Base::visitIntrinsicInst(I));
      break;
    }
    // Handle @llvm.stackrestore.p200i8
    CallContext Ctx = prepareCallArgs(I);
    Value *StackAddr = createCapToPtr(Ctx.Args[0], Int8PtrTy);
    NI = VC.IRB->CreateCall(
        Intrinsic::getDeclaration(&M, I.getIntrinsicID(), Int8PtrTy),
        StackAddr);
  } break;
  case Intrinsic::stacksave: {
    // Handle @llvm.stacksave.p0i8() the default way.
    if (!IsCapability(I.getType())) {
      NI = cast<CallInst>(Base::visitIntrinsicInst(I));
      break;
    }
    // Handle @llvm.stacksave.p200i8
    AllocaInst *AllocCap = createAlloca(CapTy);
    Value *Stack = VC.IRB->CreateCall(
        Intrinsic::getDeclaration(&M, I.getIntrinsicID(), Int8PtrTy));
    Value *StackAddr = VC.IRB->CreatePtrToInt(Stack, AddrSizeTy);
    NI = createRtCall(RtKind::COPY_CAP_WITH_OFFSET, AllocCap,
                      ConstantPointerNull::get(CapPtrTy), StackAddr);
  } break;
  case Intrinsic::prefetch: {
    // Handle @llvm.prefetch.p0i8() the default way.
    if (!IsCapability(I.getArgOperand(0)->getType())) {
      NI = cast<CallInst>(Base::visitIntrinsicInst(I));
      break;
    }
    // Handle @llvm.prefetch.p200i8() the default way.
    // What we want here is to prefetch the memory pointed to by the capability.
    Value *I8Ptr = createCapToPtr(mapValue(I.getOperand(0)), Int8PtrTy);
    NI = VC.IRB->CreateCall(
        Intrinsic::getDeclaration(&M, I.getIntrinsicID(), Int8PtrTy),
        {I8Ptr, mapValue(I.getOperand(1)), mapValue(I.getOperand(2)),
         mapValue(I.getOperand(3))});
    break;
  }
  }

  DebugPrint::Emit(NI);
  return NI;
}

void CHERIseed::visitDeferredPHINodes(Function &F) {
  // While visiting this PHINodes, it might happen that multiple instructions
  // are to be inserted. We need to insert all of these instructions before
  // the new PHINode and into a separate predecessor BasicBlock, and not at
  // the end of the current BasicBlock. Have to save the insertion point and
  // restore it later.
  ContextInsertPointGuard _(VC);
  // Visit all PHINodes in all BasicBlocks.
  // Save copies of returned capabilities to process once all the PHI nodes are
  // visited. This is because a PHI node might use another PHI node's Value.
  SmallVector<Instruction *, 8> PHICopies;
  for (BasicBlock &BB : F) {
    for (PHINode &I : BB.phis()) {
      auto _ = DebugPrint::ScopedValueVisit(I);
      DebugPrint::Visitor("PHINode");
      PHINode *PHI = cast<PHINode>(VC.get(&I));
      assert(PHI && "PHINode must have been mapped by now.");
      for (unsigned idx = 0, max_idx = I.getNumIncomingValues(); idx < max_idx;
           ++idx) {
        BasicBlock *IBB = I.getIncomingBlock(idx);
        // The mapped incoming BasicBlock.
        BasicBlock *MIBB = cast<BasicBlock>(mapValue(IBB));
        // Set the insertion point to point at the predecessor block.
        VC.BB = MIBB;
        VC.IRB->SetInsertPoint(VC.BB->getTerminator());
        // The mapped incoming value which may get split into several
        // instructions at this point. The new instructions, if any, will get
        // emitted into VC.BB.
        Value *NIV = mapValue(I.getIncomingValue(idx));
        // Use the mapped BasicBlock for the incoming Value.
        PHI->addIncoming(NIV, MIBB);
      }
      // Print in a nice way in debug builds.
      LLVM_DEBUG(VC.insert(&I, PHI));
      // If the PHINode returns a capability, it must be copied and the
      // copy is to be used onwards, otherwise the phi's output value might
      // get corrupted because of possible aliasing.
      if (!IsCapability(I.getType()))
        continue;
      Value *AllocaCap = createAlloca(CapTy);
      VC.BB = PHI->getParent();
      VC.IRB->SetInsertPoint(&*VC.BB->getFirstInsertionPt());
      std::string RtName = PHI->hasName() ? PHI->getName().str() + ".cpy" : "";
      Instruction *PHICopy =
          createRtCall(RtKind::COPY_CAP_WITH_OFFSET, RtName, AllocaCap, PHI,
                       ConstantInt::getNullValue(AddrSizeTy));
      PHICopies.push_back(PHICopy);
    }
  }

  // Finally, replace values of PHI nodes with their copies.
  for (Instruction *PHICopy : PHICopies) {
    Value *OriginalPHI = PHICopy->getOperand(1);
    OriginalPHI->replaceUsesWithIf(
        PHICopy, [&](Use &U) -> bool { return (U.getUser() != PHICopy); });
  }
}

void CHERIseed::visitDeferredValues() {
  // DV: Deferred Value
  // PV: Placeholder Value
  // MV: Mapped Value
  DeferredValueMap.for_each([&](Value *DV, Value *PV) {
    // Try to map the value, it should succeed now.
    Value *MV;
    if (GlobalValue *GV = dyn_cast<GlobalValue>(DV)) {
      MV = GlobalMap.get(GV);
      // Special case: must to call the global's accessor.
      if (GlobalValue *MGV = dyn_cast<GlobalValue>(MV)) {
        if ((PV->getType() == CapPtrTy) &&
            MGV->getValueType()->isFunctionTy()) {
          CallInst *CI =
              CallInst::Create(cast<FunctionType>(MGV->getValueType()), MGV);
          Instruction *I = cast<Instruction>(PV);
          assert(I->getParent() && "Expected parent");
          CI->insertBefore(I);
          MV = CI;
        }
      }
    } else {
      MV = VC.ValueMap.get(DV);
    }
    // Pretty-print the new change.
    DebugPrint::Map("Resolve", PV, MV);
    if (LLVM_UNLIKELY(!MV)) {
      errs() << "visitDeferredValues:"
             << "\n";
      errs() << "DV:" << *DV << "\n";
      errs() << "PV:" << *PV << "\n";
      llvm_unreachable("Failed to map Value");
    }
    // Now try to delete this temporary value.
    PV->replaceAllUsesWith(MV);
    cast<User>(PV)->dropAllReferences();
    if (Constant *C = dyn_cast<Constant>(PV))
      if (!isa<GlobalVariable>(C))
        C->destroyConstant();
    // Erase from parent
    if (GlobalValue *GV = dyn_cast<GlobalValue>(PV)) {
      GV->eraseFromParent();
    } else if (BasicBlock *BB = dyn_cast<BasicBlock>(PV)) {
      BB->eraseFromParent();
    } else if (Instruction *I = dyn_cast<Instruction>(PV)) {
      if (I->getParent())
        I->eraseFromParent();
      else
        I->deleteValue();
    } else {
      PV->deleteValue();
    }
  });
  // Clear the map, all Values were visited.
  DeferredValueMap.clear();
}

void CHERIseed::visitGlobals() {
  // Store every global to be mapped afterwards, as not to invalidate the
  // iterator.
  SmallVector<GlobalValue *, 8> Globals;
  // A vector to store global initializer section tuples.
  SmallVector<Constant *, 16> GlobalInitsSectionTuples;
  // Map global variables.
  for (GlobalValue &GV : M.globals())
    Globals.push_back(&GV);
  for (GlobalValue *GV : Globals) {
    auto _ = DebugPrint::ScopedValueVisit(*GV);
    if (Constant *C = mapGlobalVariable(cast<GlobalVariable>(GV)))
      GlobalInitsSectionTuples.push_back(C);
  }

  if (!GlobalInitsSectionTuples.empty()) {
    // Create a variable with section attribute '__cheriseed_initializers'
    // containing all data for global initialization.
    ArrayType *ArrayOfGlobalInitSectionTy =
        ArrayType::get(InitializerTy, GlobalInitsSectionTuples.size());
    GlobalVariable *GlobalInits = new GlobalVariable(
        M, ArrayOfGlobalInitSectionTy, /* isConstant */ false,
        GlobalVariable::InternalLinkage,
        ConstantArray::get(ArrayOfGlobalInitSectionTy,
                           GlobalInitsSectionTuples),
        Twine(kPrefix) + "inits_" + sys::path::stem(M.getModuleIdentifier()));
    GlobalInits->setSection(kInitializerSection);
    GlobalInits->setAlignment(Align(8));
    // Append to llvm.compiler.used so that so that during linking this variable
    // remains in scope.
    appendToCompilerUsed(M, GlobalInits);
  }

  // Map global aliases.
  Globals.clear();
  // We need to sort aliases to avoid use-before-mapped cases.
  // If an alias A aliases alias B, then A should come later
  // in the processing.
  M.getAliasList().sort(
      // Returns false, if Left is smaller than Right.
      [](const GlobalAlias &Right, const GlobalAlias &Left) -> bool {
        // If an alias doesn't alias another alias,
        // it is always smaller than anything else.
        if (IsAliasOf(&Left, &Right))
          return true;
        if (IsAliasOf(&Right, &Left))
          return false;
        // In all other cases we fall back to sort by names.
        return Left.getName() > Right.getName();
      });
  for (GlobalValue &GV : M.aliases())
    Globals.push_back(&GV);
  for (GlobalValue *GV : Globals) {
    auto _ = DebugPrint::ScopedValueVisit(*GV);
    mapGlobalAlias(cast<GlobalAlias>(GV));
  }
  // There might be deferred values after mapping globals, process them now.
  DebugPrint::BeginProcessDeferred();
  visitDeferredValues();
}

unsigned CHERIseed::getTypeStoreSize(Type *Ty) {
  assert(Ty->isSized() && "Type is not sized!");
  return InputDL.getTypeStoreSize(Ty);
}

template <typename T, typename V> void CHERIseed::takeName(T *From, V *To) {
  std::string Name = From->getName().str();
  From->setName(Name + kTakeNameSuffix);
  To->setName(Name);
}

template <typename T> T *CHERIseed::mapType(Type *Ty, bool IsArgTy) {
  if (IsArgTy && IsCapability(Ty))
    return cast<T>(CapPtrTy);
  return cast<T>(mapTypeImpl(Ty));
}

Type *CHERIseed::mapTypeImpl(Type *Ty) {
  Type *NTy = TypeMap.get(Ty);
  if (NTy)
    return NTy;

  if (FunctionType *FTy = dyn_cast<FunctionType>(Ty)) {
    Type *NTy = createFunctionType(FTy);
    TypeMap.insert(Ty, NTy);
    return NTy;
  }

  if (PointerType *PTy = dyn_cast<PointerType>(Ty)) {
    // ... addrspace(200)* --> __cheriseed_cap_t
    // ... addrspace(200)** --> __cheriseed_cap_t*
    Type *NTy;
    if (IsCapability(PTy))
      NTy = CapTy;
    else if (IsPointerToCapability(PTy))
      NTy = CapPtrTy;
    else
      NTy = mapTypeImpl(PTy->getElementType())->getPointerTo();
    TypeMap.insert(Ty, NTy);
    return NTy;
  }

  if (!ShouldMapType(Ty)) {
    TypeMap.insert(Ty, Ty);
    return Ty;
  }

  if (StructType *STy = dyn_cast<StructType>(Ty)) {
    // Create an opaque type first and map immediately.
    // This is required to handle 'type A = { A* }' cases.
    StructType *NTy = StructType::create(Ctx);
    TypeMap.insert(Ty, NTy);
    // Map all members of the structure.
    SmallVector<Type *, 8> Fields;
    Fields.reserve(STy->getNumElements());
    for (Type *ETy : STy->elements())
      Fields.push_back(mapTypeImpl(ETy));
    // Finalize the body and name of the new structure.
    NTy->setBody(Fields);
    // Literal structs never have names.
    if (!STy->isLiteral())
      takeName(STy, NTy);
    return NTy;
  }

  if (ArrayType *ATy = dyn_cast<ArrayType>(Ty)) {
    Type *ETy = ATy->getElementType();
    Type *NTy = ArrayType::get(mapTypeImpl(ETy), ATy->getNumElements());
    TypeMap.insert(Ty, NTy);
    return NTy;
  }

  if (FixedVectorType *FVTy = dyn_cast<FixedVectorType>(Ty)) {
    Type *ETy = FVTy->getElementType();
    Type *NTy = FixedVectorType::get(mapTypeImpl(ETy), FVTy->getNumElements());
    TypeMap.insert(Ty, NTy);
    return NTy;
  }

  if (ScalableVectorType *SVTy = dyn_cast<ScalableVectorType>(Ty)) {
    Type *ETy = SVTy->getElementType();
    Type *NTy =
        ScalableVectorType::get(mapTypeImpl(ETy), SVTy->getMinNumElements());
    TypeMap.insert(Ty, NTy);
    return NTy;
  }

  // By default, map a type to itself. These are tokens, metadata, void, etc.
  TypeMap.insert(Ty, Ty);
  return Ty;
}

template <typename T>
T *CHERIseed::deferValueResolution(T *V, std::function<T *()> Replacement) {
  T *TV = cast_or_null<T>(DeferredValueMap.get(V));
  if (TV)
    return TV;
  // Do not insert into the Function: 'visitDeferredValues()' will not try
  // to erase this from its parent.
  TV = Replacement();
  DeferredValueMap.insert(V, TV);
  return TV;
}

Constant *CHERIseed::mapGlobalInitializer(Use &U,
                                          GlobalInitializerAnalysis &Analysis) {
  auto AnalysisScope = Analysis.visit(U);

  // ConstantAggregate types
  if (auto *C = dyn_cast<ConstantArray>(U)) {
    SmallVector<Constant *, 8> Ops;
    for (Use &OpUse : C->operands())
      Ops.push_back(mapGlobalInitializer(OpUse, Analysis));
    return ConstantArray::get(
        mapType<ArrayType>(C->getType(), /* IsArgTy */ false), Ops);
  }
  if (auto *C = dyn_cast<ConstantStruct>(U)) {
    SmallVector<Constant *, 8> Ops;
    for (Use &OpUse : C->operands())
      Ops.push_back(mapGlobalInitializer(OpUse, Analysis));
    return ConstantStruct::get(
        mapType<StructType>(C->getType(), /* IsArgTy */ false), Ops);
  }
  if (auto *C = dyn_cast<ConstantVector>(U)) {
    SmallVector<Constant *, 8> Ops;
    for (Use &OpUse : C->operands())
      Ops.push_back(mapGlobalInitializer(OpUse, Analysis));
    return ConstantVector::get(Ops);
  }

  // ConstantData types
  if (isa<ConstantDataSequential>(U) || isa<ConstantFP>(U) ||
      isa<ConstantInt>(U) || isa<ConstantTokenNone>(U))
    return cast<Constant>(U);
  if (auto *C = dyn_cast<ConstantAggregateZero>(U))
    return ConstantAggregateZero::get(
        mapType(C->getType(), /* IsArgTy */ false));
  if (auto *C = dyn_cast<ConstantPointerNull>(U))
    return Constant::getNullValue(mapType(C->getType(), /* IsArgTy */ false));
  if (auto *C = dyn_cast<UndefValue>(U)) {
    if (IsCapability(C->getType()))
      return Constant::getNullValue(mapType(C->getType(), /* IsArgTy */ false));
    return UndefValue::get(mapType(C->getType(), /* IsArgTy */ false));
  }

  // ConstantExpr types
  if (auto *C = dyn_cast<ConstantExpr>(U)) {
    SmallVector<Constant *, 8> Ops;
    for (Use &OpUse : C->operands())
      Ops.push_back(mapGlobalInitializer(OpUse, Analysis));

    /// Somewhere either in this expression or in a contained expression a
    /// scope requested runtime initialization.
    if (AnalysisScope.needsRollback()) {
      AnalysisScope.mustInitializeRuntime();
      return Constant::getNullValue(mapType(C->getType(), /* IsArgTy */ false));
    }

    unsigned int OpCode = C->getOpcode();
    switch (OpCode) {
    case Instruction::FNeg:
      return ConstantExpr::getFNeg(Ops[0]);
    case Instruction::GetElementPtr: {
      // If this a GEP to capability address space, we can't handle
      // it in static initializers. Replace it with null value and handle it
      // later when mapping the GlobalValue.
      if (IsCapability(C->getType())) {
        AnalysisScope.mustInitializeRuntime();
        return Constant::getNullValue(CapTy);
      }
      GEPOperator *GEPOp = cast<GEPOperator>(C);
      ArrayRef<Constant *> OpsRef(Ops);
      return ConstantExpr::getGetElementPtr(
          mapType(GEPOp->getSourceElementType()), OpsRef[0], OpsRef.slice(1),
          GEPOp->isInBounds(), GEPOp->getInRangeIndex());
    }
    case Instruction::AddrSpaceCast:
    case Instruction::BitCast:
      // Can't handle cast to capability AS in static initializers. Replace it
      // with null value and handle it later when mapping the GlobalValue.
      if (IsCapability(C->getType())) {
        AnalysisScope.mustInitializeRuntime();
        return Constant::getNullValue(CapTy);
      }
      LLVM_FALLTHROUGH;
    case Instruction::Trunc:
    case Instruction::ZExt:
    case Instruction::SExt:
    case Instruction::FPTrunc:
    case Instruction::FPExt:
    case Instruction::UIToFP:
    case Instruction::SIToFP:
    case Instruction::FPToUI:
    case Instruction::FPToSI:
    case Instruction::PtrToInt:
    case Instruction::IntToPtr:
      return ConstantExpr::getCast(OpCode, Ops[0],
                                   mapType(C->getType(), /* IsArgTy */ false));
    case Instruction::ICmp:
    case Instruction::FCmp:
      return ConstantExpr::getCompare(C->getPredicate(), Ops[0], Ops[1]);
    case Instruction::Select:
      return ConstantExpr::getSelect(Ops[0], Ops[1], Ops[2]);
    case Instruction::ExtractElement:
      return ConstantExpr::getExtractElement(Ops[0], Ops[1]);
    case Instruction::InsertElement:
      return ConstantExpr::getInsertElement(Ops[0], Ops[1], Ops[3]);
    case Instruction::ShuffleVector:
      return ConstantExpr::getShuffleVector(Ops[0], Ops[1],
                                            C->getShuffleMask());
    case Instruction::ExtractValue:
      return ConstantExpr::getExtractValue(Ops[0], C->getIndices());
    case Instruction::InsertValue:
      return ConstantExpr::getInsertValue(Ops[0], Ops[1], C->getIndices());
    default: {
      assert(Instruction::isBinaryOp(OpCode) && "Expected binary operator");
      return ConstantExpr::get(OpCode, Ops[0], Ops[1],
                               C->getRawSubclassOptionalData());
    }
    }
  }

  // GlobalValue types
  if (auto *C = dyn_cast<Function>(U)) {
    if (C->getAddressSpace() != kCapabilityAS)
      return mapFunction(C);
    AnalysisScope.mustInitializeRuntime();
    return Constant::getNullValue(CapTy);
  }
  if (auto *C = dyn_cast<GlobalAlias>(U)) {
    // Do not resolve the alias. It is only possible in the accessor function.
    AnalysisScope.mustInitializeRuntime();
    return Constant::getNullValue(mapType(C->getType(), /* IsArgTy */ false));
  }
  if (auto *C = dyn_cast<GlobalVariable>(U)) {
    if (ShouldMapType(C->getValueType()) || IsCapability(C->getType()))
      AnalysisScope.mustCallAccessor();

    if (IsCapability(C->getType())) {
      // As globals are always accessed as pointers, if the original type is a
      // capability, we should replace it with __cheriseed_cap_t instead of
      // __cheriseed_cap_t*.
      AnalysisScope.mustInitializeRuntime();
      return Constant::getNullValue(CapTy);
    }

    Constant *MC = GlobalMap.get(C);
    if (MC)
      return MC;
    // This GlobalVariable is not yet resolved, defer its resolution.
    return deferValueResolution<Constant>(C, [&]() -> Constant * {
      GlobalVariable *GV = new GlobalVariable(
          M, mapType(C->getValueType()), C->isConstant(),
          GlobalValue::LinkageTypes::ExternalLinkage, nullptr);
      GV->setName(kDeferredGlobalPrefix + C->getName());
      return GV;
    });
  }

  LLVM_DEBUG(dbgs() << "mapGlobalInitializer: " << *U << "\n");
  llvm_unreachable("Not yet implemented");
}

Function *CHERIseed::mapFunction(Function *F) {
  Function *MF = FunctionMap.get(F);
  if (!MF) {
    MF = replaceFunction(F);
    FunctionMap.insert(F, MF);
  }
  return MF;
}

Value *CHERIseed::mapValue(Value *V) {
  Value *MV = VC.get(V);
  // ConstantExpr must always be mapped in-place, otherwise such an instruction
  // might not dominate all of its uses.
  if (MV && !isa<ConstantExpr>(V))
    return MV;
  DebugPrint::StartMapValue(V);

  if (isa<ConstantData>(V)) {
    Value *NV;
    // ConstantInt, ConstantFP and ConstantTokenNone can be used as-is.
    // ConstantDataSequential (ConstantDataArray and ConstantDataVector)
    // can only have "1/2/4/8-byte integer or float/double, and whose elements
    // are just simple data values".
    // See 'bool ConstantDataSequential::isElementTypeCompatible(Type *Ty);'
    // Therefore it is safe to use these as-is.
    if (isa<ConstantPointerNull>(V)) {
      NV = Constant::getNullValue(mapType(V->getType()));
    } else if (isa<UndefValue>(V)) {
      if (IsCapability(V->getType()))
        NV = Constant::getNullValue(mapType(V->getType()));
      else
        NV = UndefValue::get(mapType(V->getType()));
    } else if (isa<ConstantAggregateZero>(V)) {
      NV = ConstantAggregateZero::get(mapType(V->getType()));
    } else {
      assert((isa<ConstantInt>(V) || isa<ConstantFP>(V) ||
              isa<ConstantTokenNone>(V) || isa<ConstantDataSequential>(V)) &&
             "Unknown class derived from ConstantData");
      NV = V;
    }
    VC.insert(V, NV);
    return NV;
  }

  // Handle BasicBlocks within the currently processed Function.
  if (BasicBlock *BB = dyn_cast<BasicBlock>(V)) {
    BasicBlock *NBB = BasicBlock::Create(Ctx, BB->getName(), VC.F);
    VC.insert(BB, NBB);
    return NBB;
  }

  if (GlobalVariable *GV = dyn_cast<GlobalVariable>(V)) {
    GlobalValue *MGV = GlobalMap.get(GV);
    if (MGV) {
      // Not all globals have accessor functions.
      if (!ShouldInstrumentGlobal(GV)) {
        if (GV->getAddressSpace() == kCapabilityAS)
          return createPtrToCap(MGV);
        return MGV;
      }
      // Otherwise, try to insert a call to the accessor function.
      Function *Accessor = M.getFunction(
          GV->getAttribute(kAccessorAttribute).getValueAsString());
      // When mapping global aliases early in the pass, VC.BB is nullptr.
      // There is no need to insert any calls.
      if (!VC.BB)
        return Accessor;
      CallInst *CI = VC.IRB->CreateCall(FunctionCallee(Accessor), {});
      DebugPrint::Emit(CI);
      // FIXME: Mapping the newly created global creates an error in the
      // dominator graph. The mapped value may be used in a code path where it
      // isn't defined.
      // VC.insert(V, CI);
      return CI;
    }
  }

  if (GlobalAlias *GA = dyn_cast<GlobalAlias>(V)) {
    GlobalValue *MGA = GlobalMap.get(GA);
    assert(MGA && "All globals should be mapped by this point!");
    // When mapping global aliases early in the pass, VC.BB is nullptr.
    // There is no need to insert any calls.
    if (!VC.BB)
      return MGA;
    // Function aliases are to be returned similar to mapValue(Function).
    if (GA->getValueType()->isFunctionTy()) {
      if (GA->getAddressSpace() == kCapabilityAS) {
        Value *Addr = VC.IRB->CreateBitCast(MGA, Int8PtrTy);
        DebugPrint::Emit(Addr);
        return createPtrToCap(Addr, /* Out */ nullptr, /* FromPCC */ true);
      }
      return MGA;
    }
    // Call the accessor of the global being aliased, if any.
    FunctionType *FTy =
        dyn_cast_or_null<FunctionType>(MGA->getType()->getElementType());
    if (!FTy)
      return MGA;
    CallInst *CI = VC.IRB->CreateCall(FTy, MGA, {});
    return DebugPrint::Emit(CI);
  }

  if (ConstantExpr *CE = dyn_cast<ConstantExpr>(V)) {
    // A ConstantExpr has to be decomposed and then can be handled
    // just like any other Instruction.
    Instruction *CEI = CE->getAsInstruction();
    // Call visit() directly to avoid mapping of Values.
    Value *V = InstVisitor::visit(*CEI);
    // Must delete this parentless instruction otherwise
    // it would keep references to some dead Values.
    CEI->dropAllReferences();
    CEI->deleteValue();
    return V;
  }

  if (Function *F = dyn_cast<Function>(V)) {
    Function *MF = mapFunction(F);
    // Should derive a capability from PCC if 'F' is in AS200.
    if (VC.BB && (F->getAddressSpace() == kCapabilityAS)) {
      Value *Addr = VC.IRB->CreateBitCast(MF, Int8PtrTy);
      DebugPrint::Emit(Addr);
      return createPtrToCap(Addr, /* Out */ nullptr, /* FromPCC */ true);
    }
    return MF;
  }

  if (MetadataAsValue *MAV = dyn_cast<MetadataAsValue>(V)) {
    VC.insert(MAV, MAV);
    return MAV;
  }

  if (ConstantArray *CA = dyn_cast<ConstantArray>(V)) {
    ArrayType *MTy = mapType<ArrayType>(CA->getType());
    SmallVector<Constant *, 8> Ops;
    for (Use &U : CA->operands())
      Ops.push_back(cast<Constant>(mapValue(U)));
    Value *NCS = ConstantArray::get(MTy, {Ops});
    VC.insert(V, NCS);
    return NCS;
  }

  if (ConstantStruct *CS = dyn_cast<ConstantStruct>(V)) {
    StructType *MTy = mapType<StructType>(CS->getType());
    SmallVector<Constant *, 8> Ops;
    for (Use &U : CS->operands())
      Ops.push_back(cast<Constant>(mapValue(U)));
    Value *NCS = ConstantStruct::get(MTy, {Ops});
    VC.insert(V, NCS);
    return NCS;
  }

  if (ConstantVector *CV = dyn_cast<ConstantVector>(V)) {
    // FIXME: Vector of pointers might be hard to handle with CHERIseed.
    // Be very conservative and only support a few vector types.
    Type *ETy = CV->getType()->getElementType();
    if (!ETy->isIntegerTy() && !ETy->isFloatingPointTy()) {
      errs() << "mapValue: " << *CV << "\n";
      llvm_unreachable("Not yet implemented: constant vectors must contain "
                       "integer of floating point types.");
    }
    VC.insert(V, V);
    return V;
  }

  // Check that unexpected types don't fall through here.
  assert(!isa<InlineAsm>(V) && "InlineAsm is unexpected");

  // Defer unknown value for now.
  return deferValueResolution<Value>(V, [&]() -> Value * {
    Type *MTy = mapType(V->getType());
    Instruction *PV =
        BitCastInst::CreateBitOrPointerCast(Constant::getNullValue(MTy), MTy);
    assert(VC.BB && "Expected a BasicBlock");
    VC.BB->getInstList().push_back(PV);
    return PV;
  });
}

Instruction *CHERIseed::mapInstruction(Instruction &I) {
  Instruction *NI = I.clone();
  // This is crazy but just might work.
  NI->mutateType(mapType(I.getType()));
  // Replace arguments with the new ones.
  for (size_t idx = 0, max_idx = NI->getNumOperands(); idx < max_idx; ++idx)
    NI->setOperand(idx, mapValue(NI->getOperand(idx)));
  return NI;
}

Constant *CHERIseed::mapGlobalVariable(GlobalVariable *GV) {
  if (GV->hasAttribute(kInternalAttribute))
    return nullptr;
  // Note: ctors and dtors are handled a bit differently. The 3rd parameter
  // is an 'i8 addrspace(200)*' in Pure-cap: replace that with 'i8*'.
  // According to LLVM documentation, if the 3rd parameter is set, it must
  // point to a global variable or a function. In such a case the initializer
  // will only run if the associated data is not discarded.
  // For now, set the 3rd argument to null or assert if it is non-null.
  StringRef GVName = GV->getName();
  if ((GVName == "llvm.global_ctors") || (GVName == "llvm.global_dtors")) {
    // Recreate type: [ {i32, void ()*, i8* } ]
    // CHERIseed does not support capabilities here.
    FunctionType *FTy = FunctionType::get(VoidTy, false);
    StructType *STy = StructType::get(
        Ctx, {Type::getInt32Ty(Ctx), FTy->getPointerTo(), Int8PtrTy});
    ArrayType *ATy =
        ArrayType::get(STy, GV->getInitializer()->getNumOperands());
    // Create new initializer.
    Constant *Initializer;
    if (ConstantArray *CA = dyn_cast<ConstantArray>(GV->getInitializer())) {
      SmallVector<Constant *, 8> Elements;
      for (auto &Op : CA->operands()) {
        ConstantStruct *CS = cast<ConstantStruct>(Op);
        // FIXME: 3rd argument is not yet supported
        assert(isa<ConstantPointerNull>(CS->getOperand(2)) &&
               "Not yet supported");
        Constant *NCS = ConstantStruct::get(
            STy,
            {CS->getOperand(0), mapFunction(cast<Function>(CS->getOperand(1))),
             ConstantPointerNull::get(Int8PtrTy)});
        Elements.push_back(NCS);
      }
      Initializer = ConstantArray::get(ATy, ArrayRef<Constant *>(Elements));
    } else {
      Initializer = ConstantAggregateZero::get(ATy);
    }
    GlobalVariable *NGV =
        new GlobalVariable(M, ATy, false, GV->getLinkage(), Initializer);
    NGV->copyAttributesFrom(GV);
    takeName(GV, NGV);
    GlobalMap.insert(GV, NGV);
    return nullptr;
  }
  if ((GVName == "llvm.used") || (GVName == "llvm.compiler.used")) {
    // Recreate type: [ <N> x i8* ]
    ArrayType *ATy =
        ArrayType::get(Int8PtrTy, GV->getInitializer()->getNumOperands());
    // Create new initializer.
    ConstantArray *CA = dyn_cast<ConstantArray>(GV->getInitializer());
    SmallVector<Constant *, 8> Elements;
    for (auto &Op : CA->operands()) {
      // There are two options here:
      // 1) i8 [addrspace(200)]* %X
      // 2) i8 [addrspace(200)]* bitcast (i32 [addrspace(200)]* %X to i8
      // [addrspace(200)]*) If 'addrspace(200)' is present, there is an
      // extra address space cast.
      Constant *MaybeBitCast;
      if (AddrSpaceCastOperator *ASCast = dyn_cast<AddrSpaceCastOperator>(Op))
        // Ignore the address space cast
        MaybeBitCast = cast<Constant>(ASCast->getPointerOperand());
      else
        MaybeBitCast = cast<Constant>(Op.get());

      GlobalObject *GO;
      if (BitCastOperator *BC = dyn_cast<BitCastOperator>(MaybeBitCast))
        GO = cast<GlobalObject>(BC->getOperand(0));
      else
        GO = cast<GlobalObject>(MaybeBitCast);

      Constant *NV = nullptr;
      if (GlobalVariable *GV = dyn_cast<GlobalVariable>(GO))
        if (ShouldInstrumentGlobal(GV))
          NV = getOrInsertAccessorFunction(GV);
      if (!NV) {
        NV = cast<Constant>(mapValue(GO));
      }

      Elements.push_back(ConstantExpr::getBitCast(NV, Int8PtrTy));
    }
    Constant *Initializer =
        ConstantArray::get(ATy, ArrayRef<Constant *>(Elements));
    GlobalVariable *NGV =
        new GlobalVariable(M, ATy, false, GV->getLinkage(), Initializer);
    NGV->copyAttributesFrom(GV);
    takeName(GV, NGV);
    GlobalMap.insert(GV, NGV);
    return nullptr;
  }

  // Skip globals which are excluded from being instrumented.
  if (!ShouldInstrumentGlobal(GV)) {
    // Simply copy the global and use as-is.
    Type *NGVTy = mapType(GV->getValueType(), /* IsArgTy */ false);
    Constant *NGVI = nullptr;
    if (GV->hasInitializer())
      NGVI = GV->getInitializer();
    GlobalVariable *NGV =
        new GlobalVariable(M, NGVTy, false, GV->getLinkage(), NGVI);
    NGV->copyAttributesFrom(GV);
    takeName(GV, NGV);
    DebugPrint::Emit(NGV);
    GlobalMap.insert(GV, NGV);
    return nullptr;
  }

  // As globals are always accessed as pointers, if the original type is a
  // capability, we should replace it with __cheriseed_cap_t instead of
  // __cheriseed_cap_t*.
  Type *NGVTy = mapType(GV->getValueType(), /* IsArgTy */ false);
  // Initializer used in the declaration of the new global.
  Constant *NGVI = nullptr;
  // Create a new initializer while visiting all its operands.
  GlobalInitializerAnalysis Analysis(GV);
  if (GV->hasInitializer())
    NGVI = mapGlobalInitializer(GV->getOperandUse(0), Analysis);

  // New global variable, replaces the original in the default address space.
  bool IsConstant =
      Analysis.needsRuntimeInitialization() ? false : GV->isConstant();
  GlobalVariable *NGV =
      new GlobalVariable(M, NGVTy, IsConstant, GV->getLinkage(), NGVI);
  NGV->copyAttributesFrom(GV);
  // Make sure the alignment is correct for capabilities.
  if (NGVTy == CapTy)
    NGV->setAlignment(Align(kCapabilityAlignment));

  // Create the function through which this global will be accessed, its return
  // type is a pointer to the type of the global.
  Function *Accessor = getOrInsertAccessorFunction(GV);

  // If there are no initializers we assume the global is external and only
  // declare the accessor.
  if (!NGVI) {
    // There is no more need for the global's mapped declaration.
    NGV->dropAllReferences();
    NGV->eraseFromParent();
    // Map the global and return.
    GlobalMap.insert(GV, Accessor);
    auto _ = DebugPrint::ScopedFunctionVisit(*Accessor);
    return nullptr;
  }

  // Link the global to its accessor, which makes the output IR more readable.
  NGV->addAttribute(kAccessorAttribute, Accessor->getName());
  NGV->setName(kPrefix + std::string("global_") + Accessor->getName().str());
  DebugPrint::Emit(NGV);

  // The shadow capability through which all accesses will be made in Purecap.
  GlobalVariable *ShadowCapability = nullptr;
  if (IsCapability(GV->getType())) {
    // This is Purecap ABI, create the shadow capability to access the global.
    ShadowCapability = new GlobalVariable(
        M, CapTy, false, GV->getLinkage(),
        ConstantStruct::get(CapTy, Constant::getNullValue(CapTy)));
    ShadowCapability->setThreadLocal(GV->isThreadLocal());
    ShadowCapability->setName(kPrefix + std::string("shadow_capability_") +
                              Accessor->getName().str());
    ShadowCapability->setAlignment(Align(kCapabilityAlignment));
    // If the global is placed into a section, do something similar with its
    // shadow capability.
    if (NGV->hasSection())
      ShadowCapability->setSection(kPrefix + std::string("shadow_capability_") +
                                   NGV->getSection().str());
    DebugPrint::Emit(ShadowCapability);
    // The global should be accessed through the shadow capability, not
    // the one replacing the original global.
    GlobalMap.insert(GV, ShadowCapability);
  } else {
    GlobalMap.insert(GV, NGV);
  }

  IRBuilder<> IRB{Ctx};

  // Create the body of the accessor function
  VC.reset();
  VC.F = Accessor;
  VC.IRB = &IRB;
  VC.BB = BasicBlock::Create(VC.F->getContext(), "", VC.F);
  VC.IRB->SetInsertPoint(VC.BB);
  VC.IRB->CreateRet(ShadowCapability ? ShadowCapability : NGV);

  // Create Initializer function body
  Twine GlobalInitName =
      Twine(kPrefix) + "initializer_" + Twine(Accessor->getName());
  Function *GlobalInitializer = cast<Function>(
      M.getOrInsertFunction(GlobalInitName.str(), VoidTy).getCallee());
  GlobalInitializer->setLinkage(GlobalVariable::InternalLinkage);

  auto _ = DebugPrint::ScopedFunctionVisit(*GlobalInitializer);

  VC.reset();
  VC.F = mapFunction(GlobalInitializer);
  VC.IRB = &IRB;
  VC.BB = BasicBlock::Create(VC.F->getContext(), "", VC.F);
  VC.IRB->SetInsertPoint(VC.BB);

  if (Analysis.callsAccessors() || Analysis.needsRuntimeInitialization()) {
    // Some sanity checks
    if (!Analysis.isAggregateType())
      assert((Analysis.entries().size() <= 1) && "Expected at most one entry.");

    // Process initializations at specific GEP indices.
    for (auto &Entry : Analysis.entries()) {
      if (ConstantExpr *UsedCE = dyn_cast<ConstantExpr>(Entry.V)) {
        Value *V = mapValue(UsedCE);
        Value *GEP = VC.IRB->CreateInBoundsGEP(
            NGV->getType()->getScalarType()->getPointerElementType(), NGV,
            Entry.Indices);
        DebugPrint::Emit(GEP);
        if (GEP->getType() == CapPtrTy) {
          createRtCall(RtKind::COPY_CAP_WITH_OFFSET, GEP, V,
                       ConstantInt::getNullValue(AddrSizeTy));
        } else {
          Value *SI = VC.IRB->CreateStore(V, GEP, false);
          DebugPrint::Emit(SI);
        }
      } else if (GlobalVariable *UsedGV = dyn_cast<GlobalVariable>(Entry.V)) {
        // Need to call the accessor of the Value in this Use.
        Function *Accessor = getOrInsertAccessorFunction(UsedGV);
        std::string GEPName = "gep." + Accessor->getName().str();
        CallInst *CI = VC.IRB->CreateCall(Accessor, {}, GEPName);
        Value *GEP = VC.IRB->CreateInBoundsGEP(
            NGV->getType()->getScalarType()->getPointerElementType(), NGV,
            Entry.Indices, GEPName);
        // If this is a capability, then the accessor needs to initialize
        // the capability which points to this. Otherwise remove the GEP.
        if (GEP->getType() == CapPtrTy) {
          DebugPrint::Emit(GEP);
          createRtCall(RtKind::COPY_CAP_WITH_OFFSET, GEP, CI,
                       ConstantInt::getNullValue(AddrSizeTy));
        } else if (Instruction *GEPI = dyn_cast<Instruction>(GEP)) {
          GEPI->eraseFromParent();
        }

      } else if (GlobalAlias *InitGA = dyn_cast<GlobalAlias>(Entry.V)) {
        // An alias is always a call after transformation.
        // In hybrid, it returns a pointer to the original global.
        // In Pure-cap, it returns a pointer to the shadow capability.
        // Either way, the pointer to the original global is required here.
        // However, aliases are only resolved after mapping globals.
        FunctionType *FTy;
        Value *V = deferValueResolution<Value>(InitGA, [&]() -> Value * {
          Type *MTy = mapType(InitGA->getAliasee()->getType());
          FTy = FunctionType::get(MTy, false);
          MTy = FTy->getPointerTo();
          return new BitCastInst(Constant::getNullValue(MTy), MTy);
        });
        // Call the alias, it is a function.
        std::string CallName = "accessor.call." + InitGA->getName().str();
        CallInst *CI = VC.IRB->CreateCall(FTy, V, {}, CallName);
        DebugPrint::Emit(CI);
        // Get a GEP to point into the global variable.
        std::string GEPName = "gep." + InitGA->getName().str();
        Value *GEP = VC.IRB->CreateInBoundsGEP(
            NGV->getType()->getScalarType()->getPointerElementType(), NGV,
            Entry.Indices, GEPName);
        DebugPrint::Emit(GEP);
        // Initialize the global value.
        if (GEP->getType() == CapPtrTy) {
          createRtCall(RtKind::COPY_CAP_WITH_OFFSET, GEP, CI,
                       ConstantInt::getNullValue(AddrSizeTy));
        } else {
          Value *SI = VC.IRB->CreateStore(CI, GEP, false);
          DebugPrint::Emit(SI);
        }
      } else if (Function *F = dyn_cast<Function>(Entry.V)) {
        Value *GEP = VC.IRB->CreateInBoundsGEP(
            NGV->getType()->getScalarType()->getPointerElementType(), NGV,
            Entry.Indices, "");
        DebugPrint::Emit(GEP);
        assert((GEP->getType() == CapPtrTy) && "Expected capability type");
        createRtCall(RtKind::COPY_CAP_WITH_OFFSET, GEP, mapValue(F),
                     ConstantInt::getNullValue(AddrSizeTy));
      } else {
        errs() << "mapGlobalVariable: " << *Entry.V << "\n";
        errs() << "at GEP indices:\n";
        for (auto *A : Entry.Indices)
          errs() << *A << " ";
        errs() << "\n";
        llvm_unreachable("Not yet implemented");
      }
    }
  }

  VC.IRB->CreateRetVoid();

  const uint64_t BoundsSizeVal = alignTo(DL.getTypeSizeInBits(NGVTy), 8) / 8;
  // Determine which capabilities should be cleared on the shadow cap
  uint64_t ClearPermsVal = cheriseed::abi::EXECUTE;
  if (IsConstant)
    ClearPermsVal |= cheriseed::abi::STORE;

  Constant *Src = ShadowCapability
                      ? ConstantExpr::getPtrToInt(ShadowCapability, AddrSizeTy)
                      : Constant::getNullValue(AddrSizeTy);
  Constant *Addr = ShadowCapability ? ConstantExpr::getPtrToInt(NGV, AddrSizeTy)
                                    : Constant::getNullValue(AddrSizeTy);
  Type *InitializerFuncTy = PointerType::get(FunctionType::get(VoidTy, false),
                                             DL.getProgramAddressSpace());
  Constant *InitFunction = (VC.BB->size() > 1)
                               ? ConstantExpr::getPointerBitCastOrAddrSpaceCast(
                                     VC.F, InitializerFuncTy)
                               : Constant::getNullValue(InitializerFuncTy);
  Constant *BoundsSize = ShadowCapability
                             ? ConstantInt::get(AddrSizeTy, BoundsSizeVal)
                             : Constant::getNullValue(AddrSizeTy);
  Constant *ClearPerms = ShadowCapability
                             ? ConstantInt::get(CapPermsTy, ClearPermsVal)
                             : Constant::getNullValue(CapPermsTy);
  // Remove if function does nothing i.e, just has instruction 'ret void'.
  if (VC.BB->size() == 1)
    VC.F->eraseFromParent();
  VC.reset();

  if (!ShadowCapability &&
      (InitFunction == Constant::getNullValue(InitializerFuncTy)))
    return nullptr;
  return ConstantStruct::get(
      InitializerTy,
      ArrayRef<Constant *>({Src, Addr, BoundsSize, ClearPerms, InitFunction}));
}

void CHERIseed::mapGlobalAlias(GlobalAlias *GA) {
  GlobalAlias *NGA;
  // Allow bitcasts to appear in global aliases.
  // For example:
  //   @alias = alias void (...), bitcast (void ()* @aliasee to void (...)*)
  if (ConstantExpr *CE = dyn_cast<ConstantExpr>(GA->getAliasee())) {
    assert((CE->getOpcode() == Instruction::BitCast) && "Expected BitCast");
    assert(isa<FunctionType>(GA->getValueType()) && "Expected FunctionType");
    Function *F = mapFunction(cast<Function>(CE->getOperand(0)));
    Type *NTy = mapType(GA->getValueType());
    Constant *MV = ConstantExpr::getBitCast(F, NTy->getPointerTo(), false);
    NGA = GlobalAlias::create(NTy, DL.getGlobalsAddressSpace(),
                              GA->getLinkage(), "", MV, &M);
  } else if (Function *F = dyn_cast<Function>(GA->getAliasee())) {
    NGA = GlobalAlias::create(GA->getLinkage(), "", mapFunction(F));
  } else {
    // Lookup the aliasee, it should already be mapped.
    GlobalValue *MGV = cast<GlobalValue>(mapValue(GA->getAliasee()));
    NGA = GlobalAlias::create(GA->getLinkage(), "", MGV);
  }

  NGA->copyAttributesFrom(GA);
  takeName(GA, NGA);
  GlobalMap.insert(GA, NGA);
}

Function *CHERIseed::getOrInsertAccessorFunction(GlobalVariable *GV) {
  if (GV->hasAttribute(kAccessorAttribute))
    return M.getFunction(
        GV->getAttribute(kAccessorAttribute).getValueAsString());

  // Figure out the return type of the accessor.
  Type *GlobalTy = IsCapability(GV->getType())
                       ? CapTy
                       : mapType(GV->getValueType(), /* IsArgTy */ false);
  // Type of the accessor function.
  FunctionType *AccessorTy =
      FunctionType::get(GlobalTy->getPointerTo(), {}, false);
  // Create accessor function.
  FunctionCallee AccessorCall = M.getOrInsertFunction("", AccessorTy);
  Function *Accessor = cast<Function>(AccessorCall.getCallee());
  takeName(GV, Accessor);
  Accessor->addFnAttr(kInternalAttribute);
  Accessor->setLinkage(GV->getLinkage());
  // If the global variable is placed in a section, do the same with a pointer
  // to its accessor. This supports a very common pattern where symbols are
  // placed into a section and they are iterated using __start_* and __stop_*.
  if (GV->hasSection()) {
    Constant *BC = ConstantExpr::getBitCast(Accessor, Int8PtrTy);
    GlobalVariable *AGV =
        new GlobalVariable(M, Int8PtrTy, true, GV->getLinkage(), BC);
    AGV->setName(Accessor->getName() + "_" + GV->getSection());
    AGV->setSection(kPrefix + std::string("accessor_") +
                    GV->getSection().str());
    AGV->setAlignment(MaybeAlign(kCapabilityAlignment));
    // Add to llvm.compiler.used: no later optimizations should remove this.
    appendToCompilerUsed(M, AGV);
    // This global must not be processed.
    AGV->addAttribute(kInternalAttribute);
    // Since it is a global, register it.
    GlobalMap.insert(AGV, AGV);
  }
  // Link the global to its accessor.
  GV->addAttribute(kAccessorAttribute, Accessor->getName());

  return Accessor;
}

FunctionCallee CHERIseed::getOrInsertLibraryCall(StringRef Name,
                                                 FunctionType *FTy,
                                                 AttributeList Attrs) {
  // Try to lookup among the known library calls.
  for (Function *F : LibraryCalls)
    if (F->getName() == Name)
      return F;

  // Try to get an existing function first.
  Function *F = M.getFunction(Name);
  if (F) {
    if (!F->hasFnAttribute(kInternalAttribute))
      F = mapFunction(F);
    LibraryCalls.push_back(F);
    return F;
  }

  // This function does not yet exist.
  FunctionCallee FC = M.getOrInsertFunction(Name, FTy, Attrs);
  // getOrInsertFunction may return a bitcast on AS mismatch.
  F = cast<Function>(FC.getCallee());
  F->addFnAttr(kInternalAttribute);
  LibraryCalls.push_back(F);
  return F;
}

FunctionType *CHERIseed::createFunctionType(FunctionType *FTy) {
  Type *RetTy = FTy->getReturnType();
  SmallVector<Type *, 8> Params;

  if (IsCapability(RetTy))
    // Return the capability indirectly.
    Params.push_back(CapPtrTy);

  RetTy = mapType(RetTy);
  for (Type *Ty : FTy->params())
    Params.push_back(mapType(Ty));

  bool IsVarArg = !IsPureCap && FTy->isVarArg();
  if (IsPureCap && FTy->isVarArg())
    Params.push_back(CapPtrTy);

  return FunctionType::get(RetTy, Params, IsVarArg);
}

CHERIseed::CallContext CHERIseed::prepareCallArgs(CallInst &I) {
  // Prepare the context which will get returned.
  // There are some shorthands to access members and make code more clearer.
  CallContext CallCtx;
  auto &Args = CallCtx.Args;
  auto &Attrs = CallCtx.Attrs;

  // Only the pure-capability ABI uses on-stack variadic argument passing.
  const unsigned NumFixedArgs =
      IsPureCap ? I.getFunctionType()->getNumParams() : I.arg_size();

  // Get the original attributes of this CallInst.
  AttributeList AttrList = I.getAttributes();

  // Handle return attributes.
  // An extra argument might be inserted in which case there is an offset
  // between the two sets of attributes.
  const bool ReturnsCap = IsCapability(I.getFunctionType()->getReturnType());
  const unsigned IdxOffset = ReturnsCap ? 1 : 0;
  if (IdxOffset != 0) {
    // Build attributes for the extra argument we add to the call.
    // This is to return the capability on stack.
    AttrBuilder AB;
    AB.addAttribute(Attribute::Returned);
    AB.addAlignmentAttr(kCapabilityAlignment);
    Attrs = Attrs.addParamAttributes(Ctx, 0, AB);
    // Add the new argument to the list of arguments.
    Args.push_back(createAlloca(CapTy));
    // Remove incompatible return attributes.
    // For example, 'dereferenceable(<N>)' is no longer valid, if present.
    AttrBuilder RetAB(AttrList.getRetAttributes());
    SanitizeAttributes(RetAB, ReturnsCap);
    Attrs = Attrs.removeAttributes(Ctx, AttributeList::AttrIndex::ReturnIndex);
    Attrs =
        Attrs.addAttributes(Ctx, AttributeList::AttrIndex::ReturnIndex, RetAB);
  } else {
    // Simply inherit the original return arguments.
    Attrs = Attrs.addAttributes(Ctx, AttributeList::AttrIndex::ReturnIndex,
                                AttrList.getRetAttributes());
  }

  // Handle argument attributes one-by-one.
  unsigned OrigAttrIdx = 0;
  unsigned NewAttrIdx = IdxOffset;
  ArrayRef<Use> AllArgs(I.arg_begin(), I.arg_end());
  for (const Use &A : AllArgs.take_front(NumFixedArgs)) {
    // The mapped value
    Value *MA = mapValue(A);
    // Build attributes of the current attribute inheriting from the original
    // argument attributes.
    AttrBuilder AB(AttrList.getParamAttributes(OrigAttrIdx++));
    // Remove some attributes which are not compatible with capability
    // representation.
    if (IsCapability(A->getType()))
      SanitizeAttributes(AB, ReturnsCap);
    // Handle 'byval(<ty>)' attribute.
    if (AB.contains(Attribute::ByVal)) {
      // If there is a 'byval(<ty>)' attribute, this argument must be handled
      // a bit differently. We need to remove the attribute but extend the
      // caller to make a copy of the argument explicitly. This is in-line
      // with byval call semantics.
      if (IsCapability(A->getType())) {
        AB.removeAttribute(Attribute::ByVal);
        // 1. Create an allocation slot on the stack.
        //    It must go into the entry block.
        std::string AllocaName = std::string("byval_cpy");
        Type *ATy = mapType(cast<PointerType>(A->getType())->getElementType());
        AllocaInst *Alloca = createAlloca(ATy, AllocaName);
        DebugPrint::Emit(Alloca);
        // 2. Create a shadow capability to the new alloca slot.
        //    This will be used as an argument to the call.
        Value *AllocaCap = createCapToAlloca(Alloca, /* InEntryBlock */ true);

        // 3. Call memcpy to perform the copy to the allocated stack slot.
        // TODO: add alignment and dereferenceable maybe?
        Constant *AllocaSize = ConstantInt::get(
            AddrSizeTy, Alloca->getAllocationSizeInBits(DL).getValue() / 8);
        FunctionType *FTy = FunctionType::get(
            CapPtrTy, {CapPtrTy, CapPtrTy, CapPtrTy, AddrSizeTy}, false);
        FunctionCallee FC =
            getOrInsertLibraryCall(IsPureCap ? "memcpy" : "memcpy_c", FTy, {});
        CallInst *CI =
            VC.IRB->CreateCall(FC, {AllocaCap, AllocaCap, MA, AllocaSize});
        CI->addParamAttr(0, Attribute::Returned);
        DebugPrint::Emit(CI);
        // 4. Use the new stack slot, as returned by memcpy,
        //    as the argument to the call.
        MA = CI;
      }
      // If this is not a capability, simply forward the attribute.
      // Note that <ty> is optional.
      else if (AB.getByValType())
        AB.addByValAttr(cast<PointerType>(MA->getType())->getElementType());
    }
    // Add attributes.
    Attrs = Attrs.addParamAttributes(Ctx, NewAttrIdx++, AB);
    // Finally, add the argument to the list of arguments.
    Args.push_back(MA);
  }

  if (I.getFunctionType()->isVarArg() && IsPureCap) {
    const size_t SlotSize = kCapabilityAlignment;
    ArrayRef<Use> VarArgs = AllArgs.drop_front(NumFixedArgs);
    // Create stack slots for variadic arguments
    AllocaInst *Alloca = nullptr;
    Value *AllocaSize = ConstantInt::get(AddrSizeTy, VarArgs.size() * SlotSize);
    if (!VarArgs.empty())
      Alloca = createAlloca(Int8Ty, AllocaSize, Align(SlotSize), "va_slot");
    // Create a shadow capability pointing to the stack slot
    Value *VASlot = createShadowCapOnStack(Alloca, AllocaSize, "va_slot", true);
    // Copy variadic arguments into the stack slots
    IntegerType *IdxType = Type::getInt32Ty(I.getContext());
    unsigned Idx = 0;
    for (const Use &A : VarArgs) {
      Value *MA = mapValue(A.get());
      AttrBuilder AB(AttrList.getParamAttributes(OrigAttrIdx++));
      TypeSize Size = DL.getTypeAllocSize(MA->getType());
      Value *GEP = VC.IRB->CreateInBoundsGEP(
          Int8Ty, Alloca, ConstantInt::get(IdxType, Idx++ * SlotSize));
      DebugPrint::Emit(GEP);
      if (AB.contains(Attribute::ByVal) &&
          (DL.getTypeAllocSize(AB.getByValType())) <= SlotSize) {
        Type *ByValType = AB.getByValType();
        Value *BC = VC.IRB->CreateBitCast(GEP, ByValType->getPointerTo());
        DebugPrint::Emit(BC);
        Value *Ptr = createCapAccessCheck(MA, ByValType->getPointerTo(),
                                          getTypeStoreSize(ByValType),
                                          cheriseed::abi::permissions::LOAD);
        Value *Load =
            VC.IRB->CreateAlignedLoad(ByValType, Ptr, Align(SlotSize));
        DebugPrint::Emit(Load);
        Value *Store = VC.IRB->CreateAlignedStore(Load, BC, Align(SlotSize));
        DebugPrint::Emit(Store);
      } else if ((Size <= SlotSize) && !ShouldMapType(A->getType())) {
        // Clear the slot if the type being stored is smaller in size.
        // It does happen that the caller and callee use mismatched types,
        // such as 'syscall(1, (char)2);' and then the callee does
        // 'va_arg(lst, uintptr_t);'.
        if (Size < SlotSize) {
          Value *BC = VC.IRB->CreateBitCast(GEP, CapPtrTy);
          DebugPrint::Emit(BC);
          Value *Store = VC.IRB->CreateAlignedStore(
              ConstantAggregateZero::get(CapTy), BC, Align(SlotSize));
          DebugPrint::Emit(Store);
        }
        Value *BC = VC.IRB->CreateBitCast(GEP, MA->getType()->getPointerTo());
        DebugPrint::Emit(BC);
        Value *Store = VC.IRB->CreateAlignedStore(MA, BC, Align(SlotSize));
        DebugPrint::Emit(Store);
      } else if (IsCapability(A->getType())) {
        Value *BC = VC.IRB->CreateBitCast(GEP, MA->getType());
        DebugPrint::Emit(BC);
        createRtCall(RtKind::STORE_CAP_HYBRID, BC, MA);
      } else {
        llvm_unreachable("Not implemented vararg case");
      }
    }
    Args.push_back(VASlot);
  }

  return CallCtx;
}

Function *CHERIseed::replaceFunction(Function *F) {
  if (F->hasFnAttribute(kInternalAttribute))
    return F;

  if (F->hasFnAttribute(kRenamedFnAttribute))
    return M.getFunction(
        F->getFnAttribute(kRenamedFnAttribute).getValueAsString());

  // Create the new function and take the name of the original one.
  FunctionType *FTy = F->getFunctionType();
  FunctionType *NFTy = mapType<FunctionType>(FTy);
  Function *NF =
      Function::Create(NFTy, F->getLinkage(), DL.getProgramAddressSpace());
  takeName(F, NF);

  // Inherit argument names from the original function.
  {
    unsigned int Idx = IsCapability(F->getReturnType()) ? 1 : 0;
    for (Argument &A : F->args()) {
      if (A.hasName())
        NF->getArg(Idx)->setName(A.getName());
      ++Idx;
    }
  }
  NF->copyAttributesFrom(F);
  // Preserve DISubprogram metadata, if any.
  NF->setSubprogram(F->getSubprogram());

  // NF->copyAttributesFrom() copied parameter attributes as-is.
  // Fixup parameter attributes:
  //  - handle byval<ty> and
  //  - pull attributes to the "right" by one if the function returns a
  //    capability (when FtoNFOffset = 1).
  const AttributeList Attrs = F->getAttributes();
  AttributeList NAttrs = NF->getAttributes();
  const bool ReturnsCap = IsCapability(F->getReturnType());
  const unsigned FtoNFOffset = ReturnsCap ? 1 : 0;
  if (ReturnsCap) {
    AttrBuilder AB;
    AB.addAttribute(Attribute::Returned);
    AB.addAlignmentAttr(kCapabilityAlignment);
    // Remove the original param attributes and add the new ones.
    NAttrs = NAttrs.removeParamAttributes(Ctx, 0);
    NAttrs = NAttrs.addParamAttributes(Ctx, 0, AB);
    // Remove incompatible return attributes.
    // For example, 'dereferenceable(<N>)' is no longer valid, if present.
    AttrBuilder RetAB(Attrs.getRetAttributes());
    SanitizeAttributes(RetAB, ReturnsCap);
    NAttrs =
        NAttrs.removeAttributes(Ctx, AttributeList::AttrIndex::ReturnIndex);
    NAttrs =
        NAttrs.addAttributes(Ctx, AttributeList::AttrIndex::ReturnIndex, RetAB);
  }

  // Take attributes from the original function and add them properly to the
  // attributes of the new function.
  for (unsigned Idx = 0, MaxIdx = FTy->getNumParams(); Idx < MaxIdx; ++Idx) {
    AttrBuilder AB(Attrs.getParamAttributes(Idx));
    // Remove "returned": this is necessary because at a call site it would
    // otherwise be impossible to decide if we need an additional argument.
    // Consider this:
    //   %3 = tail call i8 addrspace(200)* %1(i8 addrspace(200)* %2)
    // Is %2 returned as %3? Or does this function return a capability?
    //
    // The calling convention is such that capabilities are returned indirectly,
    // forcing the pass to allocate new capabilities for 'returned' values too.
    // As a result the optimisation that the `returned` keyword offers is no
    // longer possible.
    if (ReturnsCap && AB.contains(Attribute::Returned))
      AB.removeAttribute(Attribute::Returned);
    // Remove some attributes which are not compatible with capability
    // representation.
    if (IsCapability(FTy->getParamType(Idx)))
      SanitizeAttributes(AB, ReturnsCap);
    // byval<Ty>: need to map to the pointed type of the argument.
    if (AB.contains(Attribute::ByVal)) {
      // If it is a capability though, remove this. Caller has to make a copy.
      // The semantics has changed and we need to emit an explicit copy of
      // the passed argument at the call site.
      if (IsCapability(FTy->getParamType(Idx)))
        AB.removeAttribute(Attribute::ByVal);
      // <ty> is optional
      else if (AB.getByValType())
        AB.addByValAttr(cast<PointerType>(NFTy->getParamType(Idx + FtoNFOffset))
                            ->getElementType());
    }

    // preallocated<Ty>: not yet supported
    if (AB.contains(Attribute::Preallocated))
      llvm_unreachable(
          "replaceFunction: preallocated attribute is not yet supported");

    // Remove the original param attributes and add the new ones.
    NAttrs = NAttrs.removeParamAttributes(Ctx, Idx + FtoNFOffset);
    NAttrs = NAttrs.addParamAttributes(Ctx, Idx + FtoNFOffset, AB);
  }

  // Finally, set new function attributes.
  NF->setAttributes(NAttrs);
  // Add some more attributes.
  NF->setComdat(F->getComdat());
  NF->addFnAttr(kInternalAttribute);
  M.getFunctionList().insert(F->getIterator(), NF);
  F->addFnAttr(kRenamedFnAttribute, NF->getName());

  return NF;
}

CallInst *CHERIseed::createRtCall(const StringRef CallName,
                                  const StringRef Name, FunctionType *FTy,
                                  ArrayRef<Value *> Args) {
  FunctionCallee FC = getOrInsertLibraryCall(kPrefix + CallName.str(), FTy, {});
  CallInst *CI = VC.IRB->CreateCall(FC, Args);
  CI->setName(Name);
  DebugPrint::Emit(CI);
  return CI;
}

template <typename... V>
CallInst *CHERIseed::createRtCall(RtKind Kind, const StringRef Name,
                                  V *...Args) {
  StringRef RtName;
  FunctionType *FTy;

  switch (Kind) {
  case RtKind::ADDRESS_GET:
    RtName = "address_get";
    FTy = FunctionType::get(AddrSizeTy, {CapPtrTy}, false);
    break;
  case RtKind::ADDRESS_SET:
    RtName = "address_set";
    FTy = FunctionType::get(CapPtrTy, {CapPtrTy, CapPtrTy, AddrSizeTy}, false);
    break;
  case RtKind::CHECK_ACCESS:
    RtName = "check_access";
    FTy = FunctionType::get(AddrSizeTy, {CapPtrTy, AddrSizeTy, CapPermsTy},
                            false);
    break;
  case RtKind::CMPXCHG_CAP:
    RtName = "cmpxchg_cap";
    FTy = FunctionType::get(
        StructType::get(Ctx, {CapPtrTy, Type::getInt1Ty(Ctx)}, false),
        {CapPtrTy, CapPtrTy, CapPtrTy, CapPtrTy, Int8Ty, Int8Ty}, false);
    break;
  case RtKind::CMPXCHG_CAP_HYBRID:
    RtName = "cmpxchg_cap_hybrid";
    FTy = FunctionType::get(
        StructType::get(Ctx, {CapPtrTy, Type::getInt1Ty(Ctx)}, false),
        {CapPtrTy, CapPtrTy, CapPtrTy, CapPtrTy, Int8Ty, Int8Ty}, false);
    break;
  case RtKind::COPY_CAP_WITH_OFFSET:
    RtName = "copy_cap_with_offset";
    FTy = FunctionType::get(CapPtrTy, {CapPtrTy, CapPtrTy, AddrSizeTy}, false);
    break;
  case RtKind::DDC_GET:
    RtName = "ddc_get";
    FTy = FunctionType::get(CapPtrTy, {CapPtrTy}, false);
    break;
  case RtKind::LOAD_CAP:
    RtName = "load_cap";
    FTy = FunctionType::get(CapPtrTy, {CapPtrTy, CapPtrTy}, false);
    break;
  case RtKind::LOAD_CAP_ATOMIC:
    RtName = "load_cap_atomic";
    FTy = FunctionType::get(CapPtrTy, {CapPtrTy, CapPtrTy, Int8Ty}, false);
    break;
  case RtKind::LOAD_CAP_HYBRID:
    RtName = "load_cap_hybrid";
    FTy = FunctionType::get(CapPtrTy, {CapPtrTy, CapPtrTy}, false);
    break;
  case RtKind::LOAD_CAP_HYBRID_ATOMIC:
    RtName = "load_cap_hybrid_atomic";
    FTy = FunctionType::get(CapPtrTy, {CapPtrTy, CapPtrTy, Int8Ty}, false);
    break;
  case RtKind::PCC_GET:
    RtName = "pcc_get";
    FTy = FunctionType::get(CapPtrTy, {CapPtrTy}, false);
    break;
  case RtKind::PERMS_AND:
    RtName = "perms_and";
    FTy = FunctionType::get(CapPtrTy, {CapPtrTy, CapPtrTy, AddrSizeTy}, false);
    break;
  case RtKind::RMW_CAP:
    RtName = "rmw_cap";
    FTy = FunctionType::get(
        CapPtrTy, {CapPtrTy, CapPtrTy, CapPtrTy, Int8Ty, Int8Ty}, false);
    break;
  case RtKind::RMW_CAP_HYBRID:
    RtName = "rmw_cap_hybrid";
    FTy = FunctionType::get(
        CapPtrTy, {CapPtrTy, CapPtrTy, CapPtrTy, Int8Ty, Int8Ty}, false);
    break;
  case RtKind::STACK_CAP_INIT:
    RtName = "stack_cap_init";
    FTy =
        FunctionType::get(CapPtrTy, {CapPtrTy, AddrSizeTy, AddrSizeTy}, false);
    break;
  case RtKind::STORE_CAP:
    RtName = "store_cap";
    FTy = FunctionType::get(VoidTy, {CapPtrTy, CapPtrTy}, false);
    break;
  case RtKind::STORE_CAP_ATOMIC:
    RtName = "store_cap_atomic";
    FTy = FunctionType::get(VoidTy, {CapPtrTy, CapPtrTy, Int8Ty}, false);
    break;
  case RtKind::STORE_CAP_HYBRID:
    RtName = "store_cap_hybrid";
    FTy = FunctionType::get(VoidTy, {CapPtrTy, CapPtrTy}, false);
    break;
  case RtKind::STORE_CAP_HYBRID_ATOMIC:
    RtName = "store_cap_hybrid_atomic";
    FTy = FunctionType::get(VoidTy, {CapPtrTy, CapPtrTy, Int8Ty}, false);
    break;
  case RtKind::THREAD_POINTER:
    RtName = "thread_pointer";
    FTy = FunctionType::get(CapPtrTy, {CapPtrTy}, false);
    break;
  }

  return createRtCall(RtName, Name, FTy, {Args...});
}

// Creates the following sequence:
//
// %2 = alloca <Ty>, align <guessed>
AllocaInst *CHERIseed::createAlloca(Type *Ty, const Twine &Name) {
  return createAlloca(Ty, nullptr, DL.getABITypeAlign(Ty), Name);
}

// Creates the following sequence:
//
// %2 = alloca <Ty>, align <Align>
AllocaInst *CHERIseed::createAlloca(Type *Ty, Value *ArraySize, Align Align,
                                    const Twine &Name) {
  AllocaInst *Alloca =
      new AllocaInst(Ty, DL.getAllocaAddrSpace(), ArraySize, Align);
  Alloca->setName(Name);

  if (!VC.AllocaIP) {
    VC.AllocaIP = new BitCastInst(Constant::getNullValue(Int8Ty), Int8Ty,
                                  "CHERIseed Alloca Insertion Point");
    BasicBlock &EntryBB = VC.F->getEntryBlock();
    if (EntryBB.empty()) {
      EntryBB.getInstList().push_back(VC.AllocaIP);
    } else {
      // Look for the last AllocaInst in the entry block.
      Instruction *IP = &*EntryBB.begin();
      for (Instruction &I : EntryBB)
        IP = isa<AllocaInst>(I) ? &I : IP;
      // The insertion point might be an AllocaInst, insert after.
      if (isa<AllocaInst>(IP))
        VC.AllocaIP->insertAfter(IP);
      else
        VC.AllocaIP->insertBefore(IP);
    }
    DebugPrint::Emit(VC.AllocaIP);
  }

  Alloca->insertAfter(VC.AllocaIP);
  VC.AllocaIP = Alloca;
  DebugPrint::Emit(Alloca);
  return Alloca;
}

// Creates the following sequence (i8* may vary):
//
// %2 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
// %3 = inttoptr i64 %2 to i8*
Value *CHERIseed::createCapToPtr(Value *Cap, Type *PtrTy) {
  Value *CapV = createRtCall(RtKind::ADDRESS_GET, Cap);
  return DebugPrint::Emit(VC.IRB->CreateIntToPtr(CapV, PtrTy));
}

// Creates the following sequence (i8* may vary, input is %p):
//
// %2 = alloca %__cheriseed_cap_t, align 16
// %3 = call void @__cheriseed_{ddc, pcc}_get(%__cheriseed_cap_t* %2)
// %4 = ptrtoint i8* %p to i64
// %5 = call void @__cheriseed_address_set(
//            %__cheriseed_cap_t* %3 /* cap_out */,
//            %__cheriseed_cap_t* %3 /* cap_in */,
//            i64 %4)
Value *CHERIseed::createPtrToCap(Value *Addr, Value *Out, bool FromPCC) {
  Value *AllocCap = createAlloca(CapTy);
  Value *Src =
      createRtCall(FromPCC ? RtKind::PCC_GET : RtKind::DDC_GET, AllocCap);
  Value *IntV = VC.IRB->CreatePtrToInt(Addr, AddrSizeTy);
  DebugPrint::Emit(IntV);
  Value *Cap = createRtCall(RtKind::ADDRESS_SET, Out ? Out : Src, Src, IntV);
  return Cap;
}

// Creates the following sequence:
//
// %1 = ptrtoint <typeof(V)> <V> to i64
// %2 = alloca %__cheriseed_cap_t, align 16
// %3 = tail call %__cheriseed_cap_t*
//      @__cheriseed_stack_cap_init(%__cheriseed_cap_t* %2, i64 %1, i64 <Size>)
//
// V must be a pointer type in the default address space, or nullptr. If V is
// nullptr, Size is ignored and is set to 0.
Value *CHERIseed::createShadowCapOnStack(Value *V, Value *Size, StringRef Name,
                                         bool InEntryBlock) {
  // Get the raw address of V, or '0'.
  Value *Addr;
  if (V) {
    Twine AddrName = !Name.empty() ? Name + std::string(".addr") : "";
    Addr = VC.IRB->CreatePtrToInt(V, AddrSizeTy, AddrName);
    DebugPrint::Emit(Addr);
    // If Size is nullptr derive the size from types available.
    if (!Size)
      Size = ConstantInt::get(
          AddrSizeTy,
          DL.getTypeAllocSize(V->getType()->getPointerElementType()));
  } else {
    Addr = ConstantInt::get(AddrSizeTy, 0);
    Size = Addr;
  }

  // Create shadow capability on the stack.
  AllocaInst *ShadowCap;
  Twine ShadowCapName = !Name.empty() ? Name + std::string(".shadow.cap") : "";
  if (InEntryBlock) {
    ShadowCap = createAlloca(CapTy, ShadowCapName);
  } else {
    ShadowCap = VC.IRB->CreateAlloca(CapTy, DL.getAllocaAddrSpace(),
                                     /* ArraySize */ nullptr, ShadowCapName);
    DebugPrint::Emit(ShadowCap);
  }

  // Finally, create an RT call to initialize the new capability on the stack.
  const std::string RtCallName = !Name.empty() ? Name.str() + ".cap" : "";
  return createRtCall(RtKind::STACK_CAP_INIT, RtCallName, ShadowCap, Addr,
                      Size);
}

// Creates the following sequence:
//
// [%m = mul i64 %c, C]
// %1 = ptrtoint <TY>* %0 to i64
// %2 = alloca %__cheriseed_cap_t, align 16
// %3 = tail call %__cheriseed_cap_t*
//      @__cheriseed_stack_cap_init(%__cheriseed_cap_t* %2, i64 %1, i64 <Size>)
//
// where %0 is
//    %0 = alloca <TY>, ...
//
// Size is automatically calculated using the AllocaInst. This might emit an
// additional Mul instruction, in which case Size is %m.
Value *CHERIseed::createCapToAlloca(AllocaInst *Alloca, bool InEntryBlock) {
  // This is very similar to 'AllocaInst::getAllocationSizeInBits()',
  // but returns a Value even if this is a variable sized array.
  Value *AllocaSize;
  const uint64_t AllocaTypeSize =
      DL.getTypeAllocSize(Alloca->getAllocatedType());
  if (ConstantInt *Size = dyn_cast<ConstantInt>(Alloca->getArraySize())) {
    AllocaSize =
        ConstantInt::get(AddrSizeTy, AllocaTypeSize * Size->getZExtValue());
  } else {
    AllocaSize = VC.IRB->CreateMul(
        Alloca->getArraySize(), ConstantInt::get(AddrSizeTy, AllocaTypeSize));
    if (Alloca->hasName())
      AllocaSize->setName(Alloca->getName() + std::string(".size"));
    DebugPrint::Emit(AllocaSize);
  }

  return createShadowCapOnStack(Alloca, AllocaSize, Alloca->getName(),
                                InEntryBlock);
}

// Creates the following sequence (i8* may vary):
//
// clang-format off
// %1 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %cap, i64 %size, i32 %mode)
// %2 = inttoptr i64 %1, i8*
// clang-format on
Value *CHERIseed::createCapAccessCheck(Value *Cap, Type *Ty, unsigned Size,
                                       unsigned PermsReq) {
  Value *Addr = createRtCall(RtKind::CHECK_ACCESS, Cap,
                             ConstantInt::get(AddrSizeTy, Size),
                             ConstantInt::get(CapPermsTy, PermsReq));
  Value *Ptr = VC.IRB->CreateIntToPtr(Addr, Ty);
  DebugPrint::Emit(Ptr);
  return Ptr;
}

void CHERIseed::stripDeadValues() {
  // Remove all globals which are no longer necessary.
  // The reason they are kept alive while the pass runs is to provide
  // better debug support. If these globals were removed earlier there
  // would be '<badref>'-s in the original input IR.
  GlobalMap.for_each([&](GlobalValue *GV, GlobalValue *MGV) {
    // If a global is used as-is, there is no need to remove anything.
    if (GV == MGV)
      return;
    GV->replaceAllUsesWith(UndefValue::get(GV->getType()));
    GV->eraseFromParent();
  });
  // Force erase mapped functions to make sure there are no uses left around.
  FunctionMap.for_each([&](Function *F, Function *) {
    F->replaceAllUsesWith(UndefValue::get(F->getType()));
    F->eraseFromParent();
  });
  // Erase remaining prototypes, such as intrinsics.
  for (Module::iterator I = M.begin(), E = M.end(); I != E;) {
    Function *F = &*I++;
    if (F->isDeclaration() && F->use_empty())
      F->eraseFromParent();
  }
}

void CHERIseed::stripAttributes() {
  if (ClDebugAll)
    return;

  // kRenamedFnAttribute is removed in stripDeadValues, only input functions
  // have that attribute.
  for (Function &F : M)
    F.removeFnAttr(kInternalAttribute);

  for (GlobalVariable &GV : M.globals()) {
    AttributeSet set = GV.getAttributes();
    set = set.removeAttribute(Ctx, kInternalAttribute);
    set = set.removeAttribute(Ctx, kAccessorAttribute);
    GV.setAttributes(set);
  }
}

/// Helper function to find and erase a substring from a string.
///
/// \param Str The string to get \p What erased from.
/// \param What The substring to find and erase from \p Str.
static void eraseFromString(std::string &Str, const std::string &What) {
  const size_t start_pos = Str.find(What);
  if (start_pos != std::string::npos)
    Str.erase(start_pos, What.length());
}

DataLayout CHERIseed::sanitizeDataLayout(const DataLayout &DL) {
  std::string DLStr = DL.getStringRepresentation();
  eraseFromString(DLStr, DataLayout::PF200_128);
  eraseFromString(DLStr, DataLayout::APG200);
  return DataLayout(DLStr);
}

ModulePass *llvm::createCHERIseedSanitizerLegacyPass() {
  return new CHERIseedSanitizerLegacyPass();
}

INITIALIZE_PASS(CHERIseedSanitizerLegacyPass, PASS_ARG, PASS_NAME, false, false)
