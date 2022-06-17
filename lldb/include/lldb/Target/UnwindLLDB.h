//===-- UnwindLLDB.h --------------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLDB_TARGET_UNWINDLLDB_H
#define LLDB_TARGET_UNWINDLLDB_H

#include <string>
#include <vector>

#include "lldb/Utility/Capability.h"
#include "lldb/Utility/RegisterValue.h"
#include "lldb/Symbol/FuncUnwinders.h"
#include "lldb/Symbol/SymbolContext.h"
#include "lldb/Symbol/UnwindPlan.h"
#include "lldb/Target/ABI.h"
#include "lldb/Target/RegisterContext.h"
#include "lldb/Target/Unwind.h"
#include "lldb/Utility/ConstString.h"
#include "lldb/Utility/Status.h"
#include "lldb/lldb-public.h"

namespace lldb_private {

class RegisterContextUnwind;

// Canonical frame address. Its type can be either a plain linear address or an
// address capability, for example, on AArch64.
class FrameAddressLLDB {
public:
  enum FrameAddressType { eFrameAddressPlain, eFrameAddressCapability };

  explicit FrameAddressLLDB(lldb::addr_t addr = LLDB_INVALID_ADDRESS)
      : m_type(eFrameAddressPlain), m_value(addr) {}
  explicit FrameAddressLLDB(const Capability &cap)
      : m_type(eFrameAddressCapability), m_value(cap) {}
  FrameAddressLLDB(const Thread &thread, const RegisterValue &reg_value,
                   int64_t offset = 0);
  FrameAddressLLDB(const FrameAddressLLDB &other) : m_value(0) { Copy(other); }
  ~FrameAddressLLDB() { Destroy(); }

  FrameAddressLLDB &operator=(const FrameAddressLLDB &other);
  bool operator==(const FrameAddressLLDB &other) const;

  FrameAddressType GetType() const { return m_type; }
  lldb::addr_t GetAddress() const;
  const Capability &GetCapability() const;
  std::string GetAsString() const;

  // Obtain a register value from the CFA.
  bool GetCFARegisterValue(const RegisterInfo &reg_info, int64_t offset,
                           RegisterValue &reg_value, Status &error) const;

private:
  union Value {
    lldb::addr_t address;
    Capability capability;

    // FrameAddressLLDB takes care about proper construction and destruction.
    Value() {}
    Value(lldb::addr_t addr) : address(addr) {}
    Value(const Capability &cap) : capability(cap) {}
    ~Value() {}
  };

  void Destroy();
  void Copy(const FrameAddressLLDB &other);

  FrameAddressType m_type;
  Value m_value;
};

// Location information describing where a register was stored.
class RegisterLocationLLDB {
public:
  enum RegisterLocationType {
    // Register was not preserved by a callee.
    eRegisterNotSaved,
    // Register is saved at a specific word of the target memory
    // (target_memory_location).
    eRegisterSavedAtMemoryLocation,
    // Register is available in a (possibly other) register (register_number).
    eRegisterInRegister,
    // Register is saved at a word in LLDB's address space.
    eRegisterSavedAtHostMemoryLocation,
    // Register value was computed (and is in inferred_value).
    eRegisterValueInferred,
    // Register value is in a live (stack frame #0) register.
    eRegisterInLiveRegisterContext
  };

  RegisterLocationLLDB()
      : m_type(eRegisterNotSaved),
        m_overlay_register_number(LLDB_INVALID_REGNUM) {}
  RegisterLocationLLDB(const RegisterLocationLLDB &other) { Copy(other); }
  ~RegisterLocationLLDB() { Destroy(); }

  RegisterLocationLLDB &operator=(const RegisterLocationLLDB &other);

  void SetNotSaved();
  void SetSavedAtMemoryLocation(lldb::addr_t addr);
  void SetInRegister(uint32_t lldb_regnum);
  void SetSavedAtHostMemoryLocation(void *addr);
  void SetValueInferred(const RegisterValue &value);
  void SetInLiveRegisterContext(uint32_t lldb_regnum);
  void SetRegisterOverlay(bool is_zero_frame, uint32_t base_regnum,
                          uint32_t overlay_regnum);
  void SetInRegisterType(RegisterLocationType type, uint32_t lldb_regnum);

  RegisterLocationType GetType() const { return m_type; }

  lldb::addr_t GetTargetMemoryLocation() const;
  uint32_t GetRegisterNumber() const;
  void *GetHostMemoryLocation() const;
  const RegisterValue &GetInferredValue() const;

  uint32_t GetOverlayRegisterNumber() const {
    return m_overlay_register_number;
  }
  void SetOverlayRegisterNumber(uint32_t overlay_register_number) {
    m_overlay_register_number = overlay_register_number;
  }

private:
  union Location {
    lldb::addr_t target_memory_location;
    uint32_t register_number; // In eRegisterKindLLDB register numbering system.
    void *host_memory_location;

    // eRegisterValueInferred - e.g. stack pointer == cfa + offset.
    RegisterValue inferred_value;

    // RegisterLocationLLDB takes care about proper construction and
    // destruction.
    Location() {}
    ~Location() {}
  };

  void Destroy();
  void Copy(const RegisterLocationLLDB &other);

  RegisterLocationType m_type;
  Location m_location;

  // Register number used to additionally overlay the restored value. If not
  // equal to LLDB_INVALID_REGNUM, caller's value can be restored by first using
  // the recorded location information to obtain the base value and then
  // overlaying it with the caller's value of the overlay register. For
  // instance, this allows to specify on AArch64 that register CLR is overlayed
  // by LR. The tag and attributes in CLR come from the recorded location
  // information and the address is set to caller's LR.
  uint32_t m_overlay_register_number;
};

class UnwindLLDB : public lldb_private::Unwind {
public:
  UnwindLLDB(lldb_private::Thread &thread);

  ~UnwindLLDB() override = default;

  enum RegisterSearchResult {
    eRegisterFound = 0,
    eRegisterNotFound,
    eRegisterIsVolatile
  };

protected:
  friend class lldb_private::RegisterContextUnwind;

  void DoClear() override {
    m_frames.clear();
    m_candidate_frame.reset();
    m_unwind_complete = false;
  }

  uint32_t DoGetFrameCount() override;

  bool DoGetFrameInfoAtIndex(uint32_t frame_idx, lldb::addr_t &cfa,
                             lldb::addr_t &start_pc,
                             bool &behaves_like_zeroth_frame) override;

  lldb::RegisterContextSP
  DoCreateRegisterContextForFrame(lldb_private::StackFrame *frame) override;

  typedef std::shared_ptr<RegisterContextUnwind> RegisterContextLLDBSP;

  // Needed to retrieve the "next" frame (e.g. frame 2 needs to retrieve frame
  // 1's RegisterContextUnwind)
  // The RegisterContext for frame_num must already exist or this returns an
  // empty shared pointer.
  RegisterContextLLDBSP GetRegisterContextForFrameNum(uint32_t frame_num);

  // Iterate over the RegisterContextUnwind's in our m_frames vector, look for
  // the first one that has a saved location for this reg.
  bool SearchForSavedLocationForRegister(uint32_t lldb_regnum,
                                         ABI::FrameState caller_frame_state,
                                         RegisterLocationLLDB &regloc,
                                         uint32_t starting_frame_num,
                                         bool pc_register);

  /// Provide the list of user-specified trap handler functions
  ///
  /// The Platform is one source of trap handler function names; that
  /// may be augmented via a setting.  The setting needs to be converted
  /// into an array of ConstStrings before it can be used - we only want
  /// to do that once per thread so it's here in the UnwindLLDB object.
  ///
  /// \return
  ///     Vector of ConstStrings of trap handler function names.  May be
  ///     empty.
  const std::vector<ConstString> &GetUserSpecifiedTrapHandlerFunctionNames() {
    return m_user_supplied_trap_handler_functions;
  }

private:
  struct Cursor {
    lldb::addr_t start_pc =
        LLDB_INVALID_ADDRESS; // The start address of the function/symbol for
                              // this frame - current pc if unknown
    FrameAddressLLDB cfa;  // The canonical frame address for this stack frame
    lldb_private::SymbolContext sctx; // A symbol context we'll contribute to &
                                      // provide to the StackFrame creation
    RegisterContextLLDBSP
        reg_ctx_lldb_sp; // These are all RegisterContextUnwind's

    Cursor() = default;

  private:
    Cursor(const Cursor &) = delete;
    const Cursor &operator=(const Cursor &) = delete;
  };

  typedef std::shared_ptr<Cursor> CursorSP;
  std::vector<CursorSP> m_frames;
  CursorSP m_candidate_frame;
  bool m_unwind_complete; // If this is true, we've enumerated all the frames in
                          // the stack, and m_frames.size() is the
  // number of frames, etc.  Otherwise we've only gone as far as directly asked,
  // and m_frames.size()
  // is how far we've currently gone.

  std::vector<ConstString> m_user_supplied_trap_handler_functions;

  // Check if Full UnwindPlan of First frame is valid or not.
  // If not then try Fallback UnwindPlan of the frame. If Fallback
  // UnwindPlan succeeds then update the Full UnwindPlan with the
  // Fallback UnwindPlan.
  void UpdateUnwindPlanForFirstFrameIfInvalid(ABI *abi);

  CursorSP GetOneMoreFrame(ABI *abi);

  bool AddOneMoreFrame(ABI *abi);

  bool AddFirstFrame();

  // For UnwindLLDB only
  UnwindLLDB(const UnwindLLDB &) = delete;
  const UnwindLLDB &operator=(const UnwindLLDB &) = delete;
};

} // namespace lldb_private

#endif // LLDB_TARGET_UNWINDLLDB_H
