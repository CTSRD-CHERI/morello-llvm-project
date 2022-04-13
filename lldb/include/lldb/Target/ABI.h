//===-- ABI.h ---------------------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLDB_TARGET_ABI_H
#define LLDB_TARGET_ABI_H

#include "lldb/Core/PluginInterface.h"
#include "lldb/Symbol/UnwindPlan.h"
#include "lldb/Target/DynamicRegisterInfo.h"
#include "lldb/Utility/Status.h"
#include "lldb/lldb-private.h"

#include "llvm/ADT/ArrayRef.h"
#include "llvm/MC/MCRegisterInfo.h"

namespace llvm {
class Type;
}

namespace lldb_private {

class TypeSystemClang;

class ABI : public PluginInterface {
public:
  enum FrameState {
    eFrameStateSimple,    // None/single frame state.
    eFrameStateExecutive, // Executive state.
    eFrameStateRestricted // Restricted state.
  };

  struct CallArgument {
    enum eType {
      HostPointer = 0, /* pointer to host data */
      TargetValue,     /* value is on the target or literal */
    };
    eType type;  /* value of eType */
    size_t size; /* size in bytes of this argument */

    lldb::addr_t value;                 /* literal value */
    std::unique_ptr<uint8_t[]> data_up; /* host data pointer */
  };

  ~ABI() override;

  virtual size_t GetRedZoneSize() const = 0;

  virtual bool PrepareTrivialCall(lldb_private::Thread &thread, lldb::addr_t sp,
                                  lldb::addr_t functionAddress,
                                  lldb::addr_t returnAddress,
                                  llvm::ArrayRef<lldb::addr_t> args) const = 0;

  // Prepare trivial call used from ThreadPlanFunctionCallUsingABI
  // AD:
  //  . Because i don't want to change other ABI's this is not declared pure
  //  virtual.
  //    The dummy implementation will simply fail.  Only HexagonABI will
  //    currently
  //    use this method.
  //  . Two PrepareTrivialCall's is not good design so perhaps this should be
  //  combined.
  //
  virtual bool PrepareTrivialCall(lldb_private::Thread &thread, lldb::addr_t sp,
                                  lldb::addr_t functionAddress,
                                  lldb::addr_t returnAddress,
                                  llvm::Type &prototype,
                                  llvm::ArrayRef<CallArgument> args) const;

  virtual bool GetArgumentValues(Thread &thread, ValueList &values) const = 0;

  lldb::ValueObjectSP GetReturnValueObject(Thread &thread, CompilerType &type,
                                           bool persistent = true) const;

  // specialized to work with llvm IR types
  lldb::ValueObjectSP GetReturnValueObject(Thread &thread, llvm::Type &type,
                                           bool persistent = true) const;

  // Set the Return value object in the current frame as though a function with
  virtual Status SetReturnValueObject(lldb::StackFrameSP &frame_sp,
                                      lldb::ValueObjectSP &new_value) = 0;

protected:
  // This is the method the ABI will call to actually calculate the return
  // value. Don't put it in a persistent value object, that will be done by the
  // ABI::GetReturnValueObject.
  virtual lldb::ValueObjectSP
  GetReturnValueObjectImpl(Thread &thread, CompilerType &ast_type) const = 0;

  // specialized to work with llvm IR types
  virtual lldb::ValueObjectSP
  GetReturnValueObjectImpl(Thread &thread, llvm::Type &ir_type) const;

  /// Request to get a Process shared pointer.
  ///
  /// This ABI object may not have been created with a Process object,
  /// or the Process object may no longer be alive.  Be sure to handle
  /// the case where the shared pointer returned does not have an
  /// object inside it.
  lldb::ProcessSP GetProcessSP() const { return m_process_wp.lock(); }

public:
  virtual bool CreateFunctionEntryUnwindPlan(UnwindPlan &unwind_plan) = 0;

  virtual bool CreateDefaultUnwindPlan(UnwindPlan &unwind_plan) = 0;

  virtual bool RegisterIsVolatile(RegisterContext &reg_ctx,
                                  const RegisterInfo *reg_info,
                                  FrameState frame_state,
                                  const UnwindPlan *unwind_plan) = 0;

  virtual bool GetFallbackRegisterLocation(
      RegisterContext &reg_ctx, const RegisterInfo *reg_info,
      FrameState frame_state, const UnwindPlan *unwind_plan,
      lldb::RegisterKind &unwind_registerkind,
      UnwindPlan::Row::RegisterLocation &unwind_regloc);

  //------------------------------------------------------------------
  /// Get a register that aliases and extends a specified base
  /// register.
  ///
  /// The unwinder can use this information to obtain a value of the
  /// original register from the extended one.
  ///
  /// @param[in] reg_ctx
  ///     A frame that is being unwound.
  ///
  /// @param[in] lldb_regnum
  ///     A register number of the base register in the
  ///     eRegisterKindLLDB scheme.
  ///
  /// @return
  ///     The first (smallest) extended register, or
  ///     LLDB_INVALID_REGNUM if no such register exists.
  //------------------------------------------------------------------
  virtual uint32_t GetExtendedRegisterForUnwind(RegisterContext &reg_ctx,
                                                uint32_t lldb_regnum) const;

  //------------------------------------------------------------------
  /// Get a promordial register that aliases a given register and has
  /// a requested size.
  ///
  /// @param[in] reg_ctx
  ///     A frame that is being unwound.
  ///
  /// @param[in] lldb_regnum
  ///     A register number of the extended register in the
  ///     eRegisterKindLLDB scheme.
  ///
  /// @return
  ///     The alias register that has the requested size, or
  ///     LLDB_INVALID_REGNUM if no such register exists.
  //------------------------------------------------------------------
  virtual uint32_t GetPrimordialRegisterForUnwind(RegisterContext &reg_ctx,
                                                  uint32_t lldb_regnum,
                                                  uint32_t byte_size) const;

  //------------------------------------------------------------------
  /// Get a return address register that should be searched for by the
  /// unwinder to obtain a value of a program counter register when
  /// the code uses a specified RA register.
  ///
  /// @param[in] reg_ctx
  ///     A frame that is being unwound.
  ///
  /// @param[in] pc_lldb_regnum
  ///     A register number of the program counter register in the
  ///     eRegisterKindLLDB scheme.
  ///
  /// @param[in] ra_lldb_regnum
  ///     A register number of the input return address register in
  ///     the eRegisterKindLLDB scheme.
  ///
  /// @return
  ///     The output return address register that should be searched
  ///     for by the unwinder, or LLDB_INVALID_REGNUM in case of an
  ///     error or if no such register exists.
  //------------------------------------------------------------------
  virtual uint32_t GetReturnRegisterForUnwind(RegisterContext &reg_ctx,
                                              uint32_t pc_lldb_regnum,
                                              uint32_t ra_lldb_regnum) const;

  //------------------------------------------------------------------
  /// Get a frame state from a specified register context.
  ///
  /// @param[in] reg_ctx
  ///     A frame for which the state should be determined.
  ///
  /// @param[out] state
  ///     The resulting frame state.
  ///
  /// @return
  ///     \b true on success, \b false otherwise.
  //------------------------------------------------------------------
  virtual bool GetFrameState(RegisterContext &reg_ctx, FrameState &state) const;

  //------------------------------------------------------------------
  /// Determine for a location of which register a callee frame should
  /// be asked when searching for caller's register.
  ///
  /// This allows to handle a situation when a register with one name
  /// is different in the caller and callee. For instance, if a caller
  /// on AArch64 is in the executive state and needs to ask the callee
  /// frame for a location of its (caller's) CSP register, the ABI
  /// will translate this register to specifically CSP_EL0. This is
  /// required because simple CSP could map either to CSP_EL0 or RCSP_EL0
  /// in the callee depending on its own state.
  ///
  /// @param[in] reg_ctx
  ///     A frame that is being unwound.
  ///
  /// @param[in] lldb_regnum
  ///     A register number of the original caller register in the
  ///     eRegisterKindLLDB scheme.
  ///
  /// @param[in] caller_frame_state
  ///     The caller frame state.
  ///
  /// @param[out] search_lldb_regnum
  ///     A register number of the resulting register that a callee
  ///     should be asked for, in the eRegisterKindLLDB scheme.
  ///
  /// @return
  ///     \b true on success, \b false otherwise.
  //------------------------------------------------------------------
  virtual bool GetCalleeRegisterToSearch(RegisterContext &reg_ctx,
                                         uint32_t lldb_regnum,
                                         FrameState caller_frame_state,
                                         uint32_t &search_lldb_regnum) const;

  // Should take a look at a call frame address (CFA) which is just the stack
  // pointer value upon entry to a function. ABIs usually impose alignment
  // restrictions (4, 8 or 16 byte aligned), and zero is usually not allowed.
  // This function should return true if "cfa" is valid call frame address for
  // the ABI, and false otherwise. This is used by the generic stack frame
  // unwinding code to help determine when a stack ends.
  virtual bool CallFrameAddressIsValid(lldb::addr_t cfa) = 0;

  // Validates a possible PC value and returns true if an opcode can be at
  // "pc".
  virtual bool CodeAddressIsValid(lldb::addr_t pc) = 0;

  /// Some targets might use bits in a code address to indicate a mode switch.
  /// ARM uses bit zero to signify a code address is thumb, so any ARM ABI
  /// plug-ins would strip those bits.
  /// @{
  virtual lldb::addr_t FixCodeAddress(lldb::addr_t pc) { return pc; }
  virtual lldb::addr_t FixDataAddress(lldb::addr_t pc) { return pc; }
  /// @}

  /// Use this method when you do not know, or do not care what kind of address
  /// you are fixing. On platforms where there would be a difference between the
  /// two types, it will pick the safest option.
  ///
  /// Its purpose is to signal that no specific choice was made and provide an
  /// alternative to randomly picking FixCode/FixData address. Which could break
  /// platforms where there is a difference (only Arm Thumb at this time).
  virtual lldb::addr_t FixAnyAddress(lldb::addr_t pc) {
    // On Arm Thumb fixing a code address zeroes the bottom bit, so FixData is
    // the safe choice. On any other platform (so far) code and data addresses
    // are fixed in the same way.
    return FixDataAddress(pc);
  }

  llvm::MCRegisterInfo &GetMCRegisterInfo() { return *m_mc_register_info_up; }

  virtual void
  AugmentRegisterInfo(std::vector<DynamicRegisterInfo::Register> &regs) = 0;

  virtual bool GetPointerReturnRegister(const char *&name) { return false; }

  //------------------------------------------------------------------
  /// Create a siginfo value from specified data.
  ///
  /// @param[in] target
  ///     A target used to resolve the siginfo type.
  ///
  /// @param[in] data
  ///     A data extractor that contains the raw siginfo bytes. The
  ///     information is stored in an ABI-specific way.
  ///
  /// @param[out] error
  ///     An error descriptor if the method failed to construct the
  ///     siginfo value.
  ///
  /// @return
  ///     The shared pointer to the resulting siginfo value which can
  ///     contain nullptr if the value could not be constructed.
  //------------------------------------------------------------------
  virtual lldb::ValueObjectSP
  CreateSigInfoValueObject(Target &target, const lldb::DataBufferSP &data_sp,
                           Status &error) const;

  static lldb::ABISP FindPlugin(lldb::ProcessSP process_sp, const ArchSpec &arch);

  //------------------------------------------------------------------
  /// Get a name for a frame state.
  ///
  /// @param[in] frame_state
  ///     The frame state.
  ///
  /// @return
  ///     The human-readable name for \a frame_state.
  //------------------------------------------------------------------
  static const char *GetFrameStateAsCString(FrameState frame_state);

protected:
  ABI(lldb::ProcessSP process_sp, std::unique_ptr<llvm::MCRegisterInfo> info_up)
      : m_process_wp(process_sp), m_mc_register_info_up(std::move(info_up)) {
    assert(m_mc_register_info_up && "ABI must have MCRegisterInfo");
  }

  /// Utility function to construct a MCRegisterInfo using the ArchSpec triple.
  /// Plugins wishing to customize the construction can construct the
  /// MCRegisterInfo themselves.
  static std::unique_ptr<llvm::MCRegisterInfo>
  MakeMCRegisterInfo(const ArchSpec &arch);

  lldb::ProcessWP m_process_wp;
  std::unique_ptr<llvm::MCRegisterInfo> m_mc_register_info_up;

  //------------------------------------------------------------------
  /// Create a siginfo compiler type for a target ABI.
  ///
  /// @param[in] target
  ///     A target used to resolve the siginfo type.
  ///
  /// @param[in] ast_ctx
  ///     An AST context to use for defining the structure.
  ///
  /// @param[in] type_name
  ///     A name of the resulting type.
  ///
  /// @return
  ///     The siginfo compiler type.
  //------------------------------------------------------------------
  virtual CompilerType GetSigInfoCompilerType(const Target &target,
                                              TypeSystemClang &ast_ctx,
                                              llvm::StringRef type_name) const;

  virtual lldb::addr_t FixCodeAddress(lldb::addr_t pc, lldb::addr_t mask) {
    return pc;
  }

private:
  ABI(const ABI &) = delete;
  const ABI &operator=(const ABI &) = delete;
};

class RegInfoBasedABI : public ABI {
public:
  void AugmentRegisterInfo(
      std::vector<DynamicRegisterInfo::Register> &regs) override;

protected:
  using ABI::ABI;

  bool GetRegisterInfoByName(llvm::StringRef name, RegisterInfo &info);

  virtual const RegisterInfo *GetRegisterInfoArray(uint32_t &count) = 0;
};

class MCBasedABI : public ABI {
public:
  void AugmentRegisterInfo(
      std::vector<DynamicRegisterInfo::Register> &regs) override;

  /// If the register name is of the form "<from_prefix>[<number>]" then change
  /// the name to "<to_prefix>[<number>]". Otherwise, leave the name unchanged.
  static void MapRegisterName(std::string &reg, llvm::StringRef from_prefix,
                              llvm::StringRef to_prefix);

protected:
  using ABI::ABI;

  /// Return eh_frame and dwarf numbers for the given register.
  virtual std::pair<uint32_t, uint32_t> GetEHAndDWARFNums(llvm::StringRef reg);

  /// Return the generic number of the given register.
  virtual uint32_t GetGenericNum(llvm::StringRef reg) = 0;

  /// For the given (capitalized) lldb register name, return the name of this
  /// register in the MCRegisterInfo struct.
  virtual std::string GetMCName(std::string reg) { return reg; }
};

} // namespace lldb_private

#endif // LLDB_TARGET_ABI_H
