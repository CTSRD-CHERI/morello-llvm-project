//===-- UnwindLLDB.cpp ----------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "lldb/Target/UnwindLLDB.h"
#include "lldb/Core/Module.h"
#include "lldb/Symbol/FuncUnwinders.h"
#include "lldb/Symbol/Function.h"
#include "lldb/Symbol/UnwindPlan.h"
#include "lldb/Target/ABI.h"
#include "lldb/Target/Process.h"
#include "lldb/Target/RegisterContext.h"
#include "lldb/Target/RegisterContextUnwind.h"
#include "lldb/Target/Target.h"
#include "lldb/Target/Thread.h"
#include "lldb/Utility/Log.h"
#include "llvm/Support/FormatVariadic.h"

using namespace lldb;
using namespace lldb_private;

FrameAddressLLDB::FrameAddressLLDB(const Thread &thread,
                                   const RegisterValue &reg_value,
                                   int64_t offset) {
  if (reg_value.GetType() == RegisterValue::eTypeCapability128) {
    // Capability frame address.
    m_type = eFrameAddressCapability;
    CapabilityType capability_type =
        thread.GetProcess()->GetTarget().GetArchitecture().GetCapabilityType();
    new (&m_value.capability)
        Capability(reg_value.GetAsCapability(capability_type) + offset);
  } else {
    // Plain linear frame address.
    m_type = eFrameAddressPlain;
    m_value.address = reg_value.GetAsUInt64(LLDB_INVALID_ADDRESS);
    if (m_value.address != LLDB_INVALID_ADDRESS)
      m_value.address += offset;
  }
}

FrameAddressLLDB &FrameAddressLLDB::operator=(const FrameAddressLLDB &other) {
  if (this == &other)
    return *this;

  Destroy();
  Copy(other);
  return *this;
}

bool FrameAddressLLDB::operator==(const FrameAddressLLDB &other) const {
  if (m_type != other.m_type)
    return false;

  switch (m_type) {
  case eFrameAddressPlain:
    return m_value.address == other.m_value.address;
  case eFrameAddressCapability:
    return m_value.capability == other.m_value.capability;
  }
  return false;
}

addr_t FrameAddressLLDB::GetAddress() const {
  switch (m_type) {
  case eFrameAddressPlain:
    return m_value.address;
  case eFrameAddressCapability:
    return m_value.capability.GetAddress();
  }
  return LLDB_INVALID_ADDRESS;
}

const Capability &FrameAddressLLDB::GetCapability() const {
  assert(m_type == eFrameAddressCapability);
  return m_value.capability;
}

bool FrameAddressLLDB::GetCFARegisterValue(const RegisterInfo &reg_info,
                                           int64_t offset,
                                           RegisterValue &reg_value,
                                           Status &error) const {
  switch (m_type) {
  case eFrameAddressPlain:
    if (m_value.address == LLDB_INVALID_ADDRESS) {
      error.SetErrorString("CFA is an invalid address");
      return false;
    }

    // Check that the register has a sensible type to hold the canonical frame
    // address and construct the register value.
    switch (reg_info.encoding) {
    case eEncodingInvalid:
    case eEncodingSint:
    case eEncodingIEEE754:
    case eEncodingVector:
    case eEncodingCapability:
      error.SetErrorStringWithFormat(
          "register value for %s cannot be constructed from a plain linear CFA",
          reg_info.name);
      return false;
    case eEncodingUint:
      reg_value.SetUInt(m_value.address, reg_info.byte_size);
      return true;
    }
  case eFrameAddressCapability:
    return m_value.capability.GetCFARegisterValue(reg_info, offset, reg_value,
                                                  error);
  }
  error.SetErrorString("CFA has an invalid type");
  return false;
}

std::string FrameAddressLLDB::GetAsString() const {
  switch (m_type) {
  case eFrameAddressPlain:
    return llvm::formatv("{0:x}", m_value.address).str();
  case eFrameAddressCapability:
    return llvm::formatv("{0}", m_value.capability).str();
  }
  return "invalid type";
}

void FrameAddressLLDB::Destroy()
{
  switch (m_type) {
  case eFrameAddressPlain:
    break;
  case eFrameAddressCapability:
    m_value.capability.~Capability();
    break;
  }
}

void FrameAddressLLDB::Copy(const FrameAddressLLDB &other) {
  m_type = other.m_type;
  switch (m_type) {
  case eFrameAddressPlain:
    m_value.address = other.m_value.address;
    break;
  case eFrameAddressCapability:
    new (&m_value.capability) Capability(other.m_value.capability);
    break;
  }
}

RegisterLocationLLDB &RegisterLocationLLDB::
operator=(const RegisterLocationLLDB &other) {
  if (this == &other)
    return *this;

  Destroy();
  Copy(other);
  return *this;
}

void RegisterLocationLLDB::SetNotSaved() {
  Destroy();

  m_type = eRegisterNotSaved;
}

void RegisterLocationLLDB::SetSavedAtMemoryLocation(lldb::addr_t addr) {
  Destroy();

  m_type = eRegisterSavedAtMemoryLocation;
  m_location.target_memory_location = addr;
  m_overlay_register_number = LLDB_INVALID_REGNUM;
}

void RegisterLocationLLDB::SetInRegister(uint32_t lldb_regnum) {
  Destroy();

  m_type = eRegisterInRegister;
  m_location.register_number = lldb_regnum;
  m_overlay_register_number = LLDB_INVALID_REGNUM;
}

void RegisterLocationLLDB::SetSavedAtHostMemoryLocation(void *addr) {
  Destroy();

  m_type = eRegisterSavedAtMemoryLocation;
  m_location.host_memory_location = addr;
  m_overlay_register_number = LLDB_INVALID_REGNUM;
}

void RegisterLocationLLDB::SetValueInferred(const RegisterValue &value) {
  Destroy();

  m_type = eRegisterValueInferred;
  new (&m_location.inferred_value) RegisterValue(value);
  m_overlay_register_number = LLDB_INVALID_REGNUM;
}

void RegisterLocationLLDB::SetInLiveRegisterContext(uint32_t lldb_regnum) {
  Destroy();

  m_type = eRegisterInLiveRegisterContext;
  m_location.register_number = lldb_regnum;
  m_overlay_register_number = LLDB_INVALID_REGNUM;
}

void RegisterLocationLLDB::SetRegisterOverlay(bool is_zero_frame,
                                              uint32_t base_regnum,
                                              uint32_t overlay_regnum) {
  Destroy();

  m_type = is_zero_frame ? eRegisterInLiveRegisterContext : eRegisterInRegister;
  m_location.register_number = base_regnum;
  m_overlay_register_number = overlay_regnum;
}

void RegisterLocationLLDB::SetInRegisterType(RegisterLocationType type,
                                             uint32_t lldb_regnum) {
  assert(type == eRegisterInRegister || type == eRegisterInLiveRegisterContext);
  Destroy();

  m_type = type;
  m_location.register_number = lldb_regnum;
  m_overlay_register_number = LLDB_INVALID_REGNUM;
}

lldb::addr_t RegisterLocationLLDB::GetTargetMemoryLocation() const {
  assert(m_type == eRegisterSavedAtMemoryLocation);
  return m_location.target_memory_location;
}

uint32_t RegisterLocationLLDB::GetRegisterNumber() const {
  assert(m_type == eRegisterInRegister ||
         m_type == eRegisterInLiveRegisterContext);
  return m_location.register_number;
}

void *RegisterLocationLLDB::GetHostMemoryLocation() const {
  assert(m_type == eRegisterSavedAtHostMemoryLocation);
  return m_location.host_memory_location;
}

const RegisterValue &RegisterLocationLLDB::GetInferredValue() const {
  assert(m_type == eRegisterValueInferred);
  return m_location.inferred_value;
}

void RegisterLocationLLDB::Destroy() {
  switch (m_type) {
  case eRegisterNotSaved:
  case eRegisterSavedAtMemoryLocation:
  case eRegisterInRegister:
  case eRegisterSavedAtHostMemoryLocation:
  case eRegisterInLiveRegisterContext:
    break;
  case eRegisterValueInferred:
    m_location.inferred_value.~RegisterValue();
    break;
  }
}

void RegisterLocationLLDB::Copy(const RegisterLocationLLDB &other) {
  m_type = other.m_type;
  switch (m_type) {
  case eRegisterNotSaved:
    break;
  case eRegisterSavedAtMemoryLocation:
    m_location.target_memory_location = other.m_location.target_memory_location;
    break;
  case eRegisterInRegister:
  case eRegisterInLiveRegisterContext:
    m_location.register_number = other.m_location.register_number;
    break;
  case eRegisterSavedAtHostMemoryLocation:
    m_location.host_memory_location = other.m_location.host_memory_location;
    break;
  case eRegisterValueInferred:
    new (&m_location.inferred_value)
        RegisterValue(other.m_location.inferred_value);
    break;
  }
  m_overlay_register_number = other.m_overlay_register_number;
}

UnwindLLDB::UnwindLLDB(Thread &thread)
    : Unwind(thread), m_frames(), m_unwind_complete(false),
      m_user_supplied_trap_handler_functions() {
  ProcessSP process_sp(thread.GetProcess());
  if (process_sp) {
    Args args;
    process_sp->GetTarget().GetUserSpecifiedTrapHandlerNames(args);
    size_t count = args.GetArgumentCount();
    for (size_t i = 0; i < count; i++) {
      const char *func_name = args.GetArgumentAtIndex(i);
      m_user_supplied_trap_handler_functions.push_back(ConstString(func_name));
    }
  }
}

uint32_t UnwindLLDB::DoGetFrameCount() {
  if (!m_unwind_complete) {
//#define DEBUG_FRAME_SPEED 1
#if DEBUG_FRAME_SPEED
#define FRAME_COUNT 10000
    using namespace std::chrono;
    auto time_value = steady_clock::now();
#endif
    if (!AddFirstFrame())
      return 0;

    ProcessSP process_sp(m_thread.GetProcess());
    ABI *abi = process_sp ? process_sp->GetABI().get() : nullptr;

    while (AddOneMoreFrame(abi)) {
#if DEBUG_FRAME_SPEED
      if ((m_frames.size() % FRAME_COUNT) == 0) {
        const auto now = steady_clock::now();
        const auto delta_t = now - time_value;
        printf("%u frames in %.9f ms (%g frames/sec)\n", FRAME_COUNT,
               duration<double, std::milli>(delta_t).count(),
               (float)FRAME_COUNT / duration<double>(delta_t).count());
        time_value = now;
      }
#endif
    }
  }
  return m_frames.size();
}

bool UnwindLLDB::AddFirstFrame() {
  if (m_frames.size() > 0)
    return true;

  ProcessSP process_sp(m_thread.GetProcess());
  ABI *abi = process_sp ? process_sp->GetABI().get() : nullptr;

  // First, set up the 0th (initial) frame
  CursorSP first_cursor_sp(new Cursor());
  RegisterContextLLDBSP reg_ctx_sp(new RegisterContextUnwind(
      m_thread, RegisterContextLLDBSP(), first_cursor_sp->sctx, 0, *this));
  if (reg_ctx_sp.get() == nullptr)
    goto unwind_done;

  if (!reg_ctx_sp->IsValid())
    goto unwind_done;

  if (!reg_ctx_sp->GetCFA(first_cursor_sp->cfa))
    goto unwind_done;

  if (!reg_ctx_sp->ReadPC(first_cursor_sp->start_pc))
    goto unwind_done;

  // Everything checks out, so release the auto pointer value and let the
  // cursor own it in its shared pointer
  first_cursor_sp->reg_ctx_lldb_sp = reg_ctx_sp;
  m_frames.push_back(first_cursor_sp);

  // Update the Full Unwind Plan for this frame if not valid
  UpdateUnwindPlanForFirstFrameIfInvalid(abi);

  return true;

unwind_done:
  Log *log = GetLog(LLDBLog::Unwind);
  if (log) {
    LLDB_LOGF(log, "th%d Unwind of this thread is complete.",
              m_thread.GetIndexID());
  }
  m_unwind_complete = true;
  return false;
}

UnwindLLDB::CursorSP UnwindLLDB::GetOneMoreFrame(ABI *abi) {
  assert(m_frames.size() != 0 &&
         "Get one more frame called with empty frame list");

  // If we've already gotten to the end of the stack, don't bother to try
  // again...
  if (m_unwind_complete)
    return nullptr;

  Log *log = GetLog(LLDBLog::Unwind);

  CursorSP prev_frame = m_frames.back();
  uint32_t cur_idx = m_frames.size();

  CursorSP cursor_sp(new Cursor());
  RegisterContextLLDBSP reg_ctx_sp(new RegisterContextUnwind(
      m_thread, prev_frame->reg_ctx_lldb_sp, cursor_sp->sctx, cur_idx, *this));

  uint64_t max_stack_depth = m_thread.GetMaxBacktraceDepth();

  // We want to detect an unwind that cycles erroneously and stop backtracing.
  // Don't want this maximum unwind limit to be too low -- if you have a
  // backtrace with an "infinitely recursing" bug, it will crash when the stack
  // blows out and the first 35,000 frames are uninteresting - it's the top
  // most 5 frames that you actually care about.  So you can't just cap the
  // unwind at 10,000 or something. Realistically anything over around 200,000
  // is going to blow out the stack space. If we're still unwinding at that
  // point, we're probably never going to finish.
  if (cur_idx >= max_stack_depth) {
    LLDB_LOGF(log,
              "%*sFrame %d unwound too many frames, assuming unwind has "
              "gone astray, stopping.",
              cur_idx < 100 ? cur_idx : 100, "", cur_idx);
    return nullptr;
  }

  if (reg_ctx_sp.get() == nullptr) {
    // If the RegisterContextUnwind has a fallback UnwindPlan, it will switch to
    // that and return true.  Subsequent calls to TryFallbackUnwindPlan() will
    // return false.
    if (prev_frame->reg_ctx_lldb_sp->TryFallbackUnwindPlan()) {
      // TryFallbackUnwindPlan for prev_frame succeeded and updated
      // reg_ctx_lldb_sp field of prev_frame. However, cfa field of prev_frame
      // still needs to be updated. Hence updating it.
      if (!(prev_frame->reg_ctx_lldb_sp->GetCFA(prev_frame->cfa)))
        return nullptr;

      return GetOneMoreFrame(abi);
    }

    LLDB_LOGF(log, "%*sFrame %d did not get a RegisterContext, stopping.",
              cur_idx < 100 ? cur_idx : 100, "", cur_idx);
    return nullptr;
  }

  if (!reg_ctx_sp->IsValid()) {
    // We failed to get a valid RegisterContext. See if the regctx below this
    // on the stack has a fallback unwind plan it can use. Subsequent calls to
    // TryFallbackUnwindPlan() will return false.
    if (prev_frame->reg_ctx_lldb_sp->TryFallbackUnwindPlan()) {
      // TryFallbackUnwindPlan for prev_frame succeeded and updated
      // reg_ctx_lldb_sp field of prev_frame. However, cfa field of prev_frame
      // still needs to be updated. Hence updating it.
      if (!(prev_frame->reg_ctx_lldb_sp->GetCFA(prev_frame->cfa)))
        return nullptr;

      return GetOneMoreFrame(abi);
    }

    LLDB_LOGF(log,
              "%*sFrame %d invalid RegisterContext for this frame, "
              "stopping stack walk",
              cur_idx < 100 ? cur_idx : 100, "", cur_idx);
    return nullptr;
  }
  if (!reg_ctx_sp->GetCFA(cursor_sp->cfa)) {
    // If the RegisterContextUnwind has a fallback UnwindPlan, it will switch to
    // that and return true.  Subsequent calls to TryFallbackUnwindPlan() will
    // return false.
    if (prev_frame->reg_ctx_lldb_sp->TryFallbackUnwindPlan()) {
      // TryFallbackUnwindPlan for prev_frame succeeded and updated
      // reg_ctx_lldb_sp field of prev_frame. However, cfa field of prev_frame
      // still needs to be updated. Hence updating it.
      if (!(prev_frame->reg_ctx_lldb_sp->GetCFA(prev_frame->cfa)))
        return nullptr;

      return GetOneMoreFrame(abi);
    }

    LLDB_LOGF(log,
              "%*sFrame %d did not get CFA for this frame, stopping stack walk",
              cur_idx < 100 ? cur_idx : 100, "", cur_idx);
    return nullptr;
  }
  if (abi && !abi->CallFrameAddressIsValid(cursor_sp->cfa.GetAddress())) {
    // On Mac OS X, the _sigtramp asynchronous signal trampoline frame may not
    // have its (constructed) CFA aligned correctly -- don't do the abi
    // alignment check for these.
    if (!reg_ctx_sp->IsTrapHandlerFrame()) {
      // See if we can find a fallback unwind plan for THIS frame.  It may be
      // that the UnwindPlan we're using for THIS frame was bad and gave us a
      // bad CFA. If that's not it, then see if we can change the UnwindPlan
      // for the frame below us ("NEXT") -- see if using that other UnwindPlan
      // gets us a better unwind state.
      if (!reg_ctx_sp->TryFallbackUnwindPlan() ||
          !reg_ctx_sp->GetCFA(cursor_sp->cfa) ||
          !abi->CallFrameAddressIsValid(cursor_sp->cfa.GetAddress())) {
        if (prev_frame->reg_ctx_lldb_sp->TryFallbackUnwindPlan()) {
          // TryFallbackUnwindPlan for prev_frame succeeded and updated
          // reg_ctx_lldb_sp field of prev_frame. However, cfa field of
          // prev_frame still needs to be updated. Hence updating it.
          if (!(prev_frame->reg_ctx_lldb_sp->GetCFA(prev_frame->cfa)))
            return nullptr;

          return GetOneMoreFrame(abi);
        }

        LLDB_LOGF(log,
                  "%*sFrame %d did not get a valid CFA for this frame, "
                  "stopping stack walk",
                  cur_idx < 100 ? cur_idx : 100, "", cur_idx);
        return nullptr;
      } else {
        LLDB_LOGF(log,
                  "%*sFrame %d had a bad CFA value but we switched the "
                  "UnwindPlan being used and got one that looks more "
                  "realistic.",
                  cur_idx < 100 ? cur_idx : 100, "", cur_idx);
      }
    }
  }
  if (!reg_ctx_sp->ReadPC(cursor_sp->start_pc)) {
    // If the RegisterContextUnwind has a fallback UnwindPlan, it will switch to
    // that and return true.  Subsequent calls to TryFallbackUnwindPlan() will
    // return false.
    if (prev_frame->reg_ctx_lldb_sp->TryFallbackUnwindPlan()) {
      // TryFallbackUnwindPlan for prev_frame succeeded and updated
      // reg_ctx_lldb_sp field of prev_frame. However, cfa field of prev_frame
      // still needs to be updated. Hence updating it.
      if (!(prev_frame->reg_ctx_lldb_sp->GetCFA(prev_frame->cfa)))
        return nullptr;

      return GetOneMoreFrame(abi);
    }

    LLDB_LOGF(log,
              "%*sFrame %d did not get PC for this frame, stopping stack walk",
              cur_idx < 100 ? cur_idx : 100, "", cur_idx);
    return nullptr;
  }
  if (abi && !abi->CodeAddressIsValid(cursor_sp->start_pc)) {
    // If the RegisterContextUnwind has a fallback UnwindPlan, it will switch to
    // that and return true.  Subsequent calls to TryFallbackUnwindPlan() will
    // return false.
    if (prev_frame->reg_ctx_lldb_sp->TryFallbackUnwindPlan()) {
      // TryFallbackUnwindPlan for prev_frame succeeded and updated
      // reg_ctx_lldb_sp field of prev_frame. However, cfa field of prev_frame
      // still needs to be updated. Hence updating it.
      if (!(prev_frame->reg_ctx_lldb_sp->GetCFA(prev_frame->cfa)))
        return nullptr;

      return GetOneMoreFrame(abi);
    }

    LLDB_LOGF(log, "%*sFrame %d did not get a valid PC, stopping stack walk",
              cur_idx < 100 ? cur_idx : 100, "", cur_idx);
    return nullptr;
  }
  // Infinite loop where the current cursor is the same as the previous one...
  if (prev_frame->start_pc == cursor_sp->start_pc &&
      prev_frame->cfa.GetAddress() == cursor_sp->cfa.GetAddress()) {
    LLDB_LOGF(log,
              "th%d pc of this frame is the same as the previous frame and "
              "CFAs for both frames are identical -- stopping unwind",
              m_thread.GetIndexID());
    return nullptr;
  }

  cursor_sp->reg_ctx_lldb_sp = reg_ctx_sp;
  return cursor_sp;
}

void UnwindLLDB::UpdateUnwindPlanForFirstFrameIfInvalid(ABI *abi) {
  // This function is called for First Frame only.
  assert(m_frames.size() == 1 && "No. of cursor frames are not 1");

  bool old_m_unwind_complete = m_unwind_complete;
  CursorSP old_m_candidate_frame = m_candidate_frame;

  // Try to unwind 2 more frames using the Unwinder. It uses Full UnwindPlan
  // and if Full UnwindPlan fails, then uses FallBack UnwindPlan. Also update
  // the cfa of Frame 0 (if required).
  AddOneMoreFrame(abi);

  // Remove all the frames added by above function as the purpose of using
  // above function was just to check whether Unwinder of Frame 0 works or not.
  for (uint32_t i = 1; i < m_frames.size(); i++)
    m_frames.pop_back();

  // Restore status after calling AddOneMoreFrame
  m_unwind_complete = old_m_unwind_complete;
  m_candidate_frame = old_m_candidate_frame;
}

bool UnwindLLDB::AddOneMoreFrame(ABI *abi) {
  Log *log = GetLog(LLDBLog::Unwind);

  // Frame zero is a little different
  if (m_frames.empty())
    return false;

  // If we've already gotten to the end of the stack, don't bother to try
  // again...
  if (m_unwind_complete)
    return false;

  CursorSP new_frame = m_candidate_frame;
  if (new_frame == nullptr)
    new_frame = GetOneMoreFrame(abi);

  if (new_frame == nullptr) {
    LLDB_LOGF(log, "th%d Unwind of this thread is complete.",
              m_thread.GetIndexID());
    m_unwind_complete = true;
    return false;
  }

  m_frames.push_back(new_frame);

  // If we can get one more frame further then accept that we get back a
  // correct frame.
  m_candidate_frame = GetOneMoreFrame(abi);
  if (m_candidate_frame)
    return true;

  // We can't go further from the frame returned by GetOneMore frame. Lets try
  // to get a different frame with using the fallback unwind plan.
  if (!m_frames[m_frames.size() - 2]
           ->reg_ctx_lldb_sp->TryFallbackUnwindPlan()) {
    // We don't have a valid fallback unwind plan. Accept the frame as it is.
    // This is a valid situation when we are at the bottom of the stack.
    return true;
  }

  // Remove the possibly incorrect frame from the frame list and try to add a
  // different one with the newly selected fallback unwind plan.
  m_frames.pop_back();
  CursorSP new_frame_v2 = GetOneMoreFrame(abi);
  if (new_frame_v2 == nullptr) {
    // We haven't got a new frame from the fallback unwind plan. Accept the
    // frame from the original unwind plan. This is a valid situation when we
    // are at the bottom of the stack.
    m_frames.push_back(new_frame);
    return true;
  }

  // Push the new frame to the list and try to continue from this frame. If we
  // can get a new frame then accept it as the correct one.
  m_frames.push_back(new_frame_v2);
  m_candidate_frame = GetOneMoreFrame(abi);
  if (m_candidate_frame) {
    // If control reached here then TryFallbackUnwindPlan had succeeded for
    // Cursor::m_frames[m_frames.size() - 2]. It also succeeded to Unwind next
    // 2 frames i.e. m_frames[m_frames.size() - 1] and a frame after that. For
    // Cursor::m_frames[m_frames.size() - 2], reg_ctx_lldb_sp field was already
    // updated during TryFallbackUnwindPlan call above. However, cfa field
    // still needs to be updated. Hence updating it here and then returning.
    return m_frames[m_frames.size() - 2]->reg_ctx_lldb_sp->GetCFA(
        m_frames[m_frames.size() - 2]->cfa);
  }

  // The new frame hasn't helped in unwinding. Fall back to the original one as
  // the default unwind plan is usually more reliable then the fallback one.
  m_frames.pop_back();
  m_frames.push_back(new_frame);
  return true;
}

bool UnwindLLDB::DoGetFrameInfoAtIndex(uint32_t idx, addr_t &cfa, addr_t &pc,
                                       bool &behaves_like_zeroth_frame) {
  if (m_frames.size() == 0) {
    if (!AddFirstFrame())
      return false;
  }

  ProcessSP process_sp(m_thread.GetProcess());
  ABI *abi = process_sp ? process_sp->GetABI().get() : nullptr;

  while (idx >= m_frames.size() && AddOneMoreFrame(abi))
    ;

  if (idx < m_frames.size()) {
    cfa = m_frames[idx]->cfa.GetAddress();
    pc = m_frames[idx]->start_pc;
    if (idx == 0) {
      // Frame zero always behaves like it.
      behaves_like_zeroth_frame = true;
    } else if (m_frames[idx - 1]->reg_ctx_lldb_sp->IsTrapHandlerFrame()) {
      // This could be an asynchronous signal, thus the
      // pc might point to the interrupted instruction rather
      // than a post-call instruction
      behaves_like_zeroth_frame = true;
    } else if (m_frames[idx]->reg_ctx_lldb_sp->IsTrapHandlerFrame()) {
      // This frame may result from signal processing installing
      // a pointer to the first byte of a signal-return trampoline
      // in the return address slot of the frame below, so this
      // too behaves like the zeroth frame (i.e. the pc might not
      // be pointing just past a call in it)
      behaves_like_zeroth_frame = true;
    } else if (m_frames[idx]->reg_ctx_lldb_sp->BehavesLikeZerothFrame()) {
      behaves_like_zeroth_frame = true;
    } else {
      behaves_like_zeroth_frame = false;
    }
    return true;
  }
  return false;
}

lldb::RegisterContextSP
UnwindLLDB::DoCreateRegisterContextForFrame(StackFrame *frame) {
  lldb::RegisterContextSP reg_ctx_sp;
  uint32_t idx = frame->GetConcreteFrameIndex();

  if (idx == 0) {
    return m_thread.GetRegisterContext();
  }

  if (m_frames.size() == 0) {
    if (!AddFirstFrame())
      return reg_ctx_sp;
  }

  ProcessSP process_sp(m_thread.GetProcess());
  ABI *abi = process_sp ? process_sp->GetABI().get() : nullptr;

  while (idx >= m_frames.size()) {
    if (!AddOneMoreFrame(abi))
      break;
  }

  const uint32_t num_frames = m_frames.size();
  if (idx < num_frames) {
    Cursor *frame_cursor = m_frames[idx].get();
    reg_ctx_sp = frame_cursor->reg_ctx_lldb_sp;
  }
  return reg_ctx_sp;
}

UnwindLLDB::RegisterContextLLDBSP
UnwindLLDB::GetRegisterContextForFrameNum(uint32_t frame_num) {
  RegisterContextLLDBSP reg_ctx_sp;
  if (frame_num < m_frames.size())
    reg_ctx_sp = m_frames[frame_num]->reg_ctx_lldb_sp;
  return reg_ctx_sp;
}

bool UnwindLLDB::SearchForSavedLocationForRegister(
    uint32_t lldb_regnum, ABI::FrameState caller_frame_state,
    lldb_private::RegisterLocationLLDB &regloc, uint32_t starting_frame_num,
    bool pc_reg) {
  int64_t frame_num = starting_frame_num;
  if (static_cast<size_t>(frame_num) >= m_frames.size())
    return false;

  // Never interrogate more than one level while looking for the saved pc
  // value. If the value isn't saved by frame_num, none of the frames lower on
  // the stack will have a useful value.
  if (pc_reg) {
    UnwindLLDB::RegisterSearchResult result;
    result = m_frames[frame_num]->reg_ctx_lldb_sp->SavedLocationForRegister(
        lldb_regnum, regloc);
    return result == UnwindLLDB::RegisterSearchResult::eRegisterFound;
  }

  Log *log = GetLog(LLDBLog::Unwind);
  ProcessSP process_sp(m_thread.GetProcess());
  const ABI *abi = process_sp ? process_sp->GetABI().get() : nullptr;
  uint32_t overlay_register_number = LLDB_INVALID_REGNUM;
  const RegisterInfo *overlay_reg_info = nullptr;
  while (frame_num >= 0) {
    // Determine for a location of which register the callee should be asked
    // when searching for the caller's register.
    if (abi != nullptr) {
      uint32_t search_lldb_regnum;
      if (!abi->GetCalleeRegisterToSearch(
              *m_frames[frame_num]->reg_ctx_lldb_sp.get(), lldb_regnum,
              caller_frame_state, search_lldb_regnum)) {
        if (log)
          log->Printf("th%d failed to determine for a location of which "
                      "register to ask a callee when searching for caller's "
                      "register %d and the caller being in %s",
                      m_thread.GetIndexID(), lldb_regnum,
                      abi->GetFrameStateAsCString(caller_frame_state));
        return false;
      }
      if (search_lldb_regnum != lldb_regnum) {
        if (log)
          log->Printf("th%d asking a callee for a saved location of register "
                      "%d when searching for caller's register %d and the "
                      "caller being in %s",
                      m_thread.GetIndexID(), search_lldb_regnum, lldb_regnum,
                      abi->GetFrameStateAsCString(caller_frame_state));
        lldb_regnum = search_lldb_regnum;
      }
    }

    UnwindLLDB::RegisterSearchResult result;
    result = m_frames[frame_num]->reg_ctx_lldb_sp->SavedLocationForRegister(
        lldb_regnum, regloc);

    // Handle overlay register value.
    const RegisterInfo *new_overlay_reg_info = nullptr;
    if (result == UnwindLLDB::RegisterSearchResult::eRegisterFound &&
        regloc.GetOverlayRegisterNumber() != LLDB_INVALID_REGNUM) {
      new_overlay_reg_info =
          m_frames[frame_num]->reg_ctx_lldb_sp->GetRegisterInfo(
              eRegisterKindLLDB, regloc.GetOverlayRegisterNumber());
      if (new_overlay_reg_info == nullptr)
        return false;
    }

    if (overlay_register_number == LLDB_INVALID_REGNUM) {
      assert(overlay_reg_info == nullptr);
      if (new_overlay_reg_info != nullptr) {
        overlay_register_number = regloc.GetOverlayRegisterNumber();
        overlay_reg_info = new_overlay_reg_info;
      }
    } else {
      assert(overlay_reg_info != nullptr);
      if (new_overlay_reg_info != nullptr) {
        // An overlay register is already used by an upper frame but this frame
        // requires its use too. Since the unwinder is not fully recursive where
        // register values in intermediate frames would be completely
        // reconstructed, any use of an additional overlay register in an
        // intermediate frame can be accepted only if bits set by this overlay
        // operation are overwritten by the overlay in the upper frame. Overlays
        // for one extended register typically all use primordial registers of
        // the same size, so this restriction does not create any problem in
        // practice.
        if (new_overlay_reg_info->byte_size > overlay_reg_info->byte_size)
          return false;
      }

      // Update the location with the previously determined overlay register.
      regloc.SetOverlayRegisterNumber(overlay_register_number);
    }

    // We descended down to the live register context aka stack frame 0 and are
    // reading the value out of a live register.
    if (result == UnwindLLDB::RegisterSearchResult::eRegisterFound &&
        regloc.GetType() ==
            RegisterLocationLLDB::eRegisterInLiveRegisterContext) {
      return true;
    }

    // If we have unwind instructions saying that register N is saved in
    // register M in the middle of the stack (and N can equal M here, meaning
    // the register was not used in this function), then change the register
    // number we're looking for to M and keep looking for a concrete  location
    // down the stack, or an actual value from a live RegisterContext at frame
    // 0.
    if (result == UnwindLLDB::RegisterSearchResult::eRegisterFound &&
        regloc.GetType() == RegisterLocationLLDB::eRegisterInRegister &&
        frame_num > 0) {
      result = UnwindLLDB::RegisterSearchResult::eRegisterNotFound;
      lldb_regnum = regloc.GetRegisterNumber();
    }

    if (result == UnwindLLDB::RegisterSearchResult::eRegisterFound)
      return true;
    if (result == UnwindLLDB::RegisterSearchResult::eRegisterIsVolatile)
      return false;

    caller_frame_state = m_frames[frame_num]->reg_ctx_lldb_sp->GetFrameState();
    frame_num--;
  }
  return false;
}
