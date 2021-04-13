//===-- LinuxSigInfo.cpp ----------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "LinuxSigInfo.h"

// C Includes
// C++ Includes
// Other libraries and framework includes
// Project includes
#include "Plugins/TypeSystem/Clang/TypeSystemClang.h"

using namespace lldb;
using namespace lldb_private;

CompilerType GetLinuxSigInfoCompilerType(TypeSystemClang &ast_ctx,
                                         llvm::StringRef type_name) {
  // Basic types and typedefs.
  CompilerType void_type = ast_ctx.GetBasicType(eBasicTypeVoid);
  CompilerType short_type = ast_ctx.GetBasicType(eBasicTypeShort);
  CompilerType int_type = ast_ctx.GetBasicType(eBasicTypeInt);
  CompilerType long_type = ast_ctx.GetBasicType(eBasicTypeLong);
  CompilerType uint_type = ast_ctx.GetBasicType(eBasicTypeUnsignedInt);

  CompilerType s32_type =
      ast_ctx.GetBuiltinTypeForEncodingAndBitSize(eEncodingSint, 32);
  CompilerType u32_type =
      ast_ctx.GetBuiltinTypeForEncodingAndBitSize(eEncodingUint, 32);

  CompilerType void_ptr_type = void_type.GetPointerType();

  CompilerType pid_t_type =
      ast_ctx.CreateTypedefType(s32_type, "__pid_t", CompilerDeclContext(), 0);
  CompilerType uid_t_type =
      ast_ctx.CreateTypedefType(u32_type, "__uid_t", CompilerDeclContext(), 0);
  CompilerType clock_t_type = ast_ctx.CreateTypedefType(
      long_type, "__clock_t", CompilerDeclContext(), 0);

  // Anonymous kill struct.
  CompilerType kill_type = ast_ctx.CreateRecordType(
      nullptr, OptionalClangModuleID(), eAccessPublic, llvm::StringRef(),
      clang::TTK_Struct, eLanguageTypeC);
  TypeSystemClang::StartTagDeclarationDefinition(kill_type);
  TypeSystemClang::AddFieldToRecordType(kill_type, "pid", pid_t_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(kill_type, "uid", uid_t_type,
                                        eAccessPublic, 0);
  TypeSystemClang::CompleteTagDeclarationDefinition(kill_type);

  // Sigval union and sigval_t typedef.
  CompilerType sigval_type =
      ast_ctx.CreateRecordType(nullptr, OptionalClangModuleID(), eAccessPublic,
                               "sigval", clang::TTK_Union, eLanguageTypeC);
  TypeSystemClang::StartTagDeclarationDefinition(sigval_type);
  TypeSystemClang::AddFieldToRecordType(sigval_type, "sival_int", int_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(sigval_type, "sival_ptr", void_ptr_type,
                                        eAccessPublic, 0);
  TypeSystemClang::CompleteTagDeclarationDefinition(sigval_type);

  CompilerType sigval_t_type = ast_ctx.CreateTypedefType(
      sigval_type, "sigval_t", CompilerDeclContext(), 0);

  // Anonymous timer struct.
  CompilerType timer_type = ast_ctx.CreateRecordType(
      nullptr, OptionalClangModuleID(), eAccessPublic, llvm::StringRef(),
      clang::TTK_Struct, eLanguageTypeC);
  TypeSystemClang::StartTagDeclarationDefinition(timer_type);
  TypeSystemClang::AddFieldToRecordType(timer_type, "tid", int_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(timer_type, "overrun", int_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(timer_type, "sigval", sigval_t_type,
                                        eAccessPublic, 0);
  TypeSystemClang::CompleteTagDeclarationDefinition(timer_type);

  // Anonymous rt struct.
  CompilerType rt_type = ast_ctx.CreateRecordType(
      nullptr, OptionalClangModuleID(), eAccessPublic, llvm::StringRef(),
      clang::TTK_Struct, eLanguageTypeC);
  TypeSystemClang::StartTagDeclarationDefinition(rt_type);
  TypeSystemClang::AddFieldToRecordType(rt_type, "pid", pid_t_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(rt_type, "uid", uid_t_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(rt_type, "sigval", sigval_t_type,
                                        eAccessPublic, 0);
  TypeSystemClang::CompleteTagDeclarationDefinition(rt_type);

  // Anonymous sigchld struct.
  CompilerType sigchld_type = ast_ctx.CreateRecordType(
      nullptr, OptionalClangModuleID(), eAccessPublic, llvm::StringRef(),
      clang::TTK_Struct, eLanguageTypeC);
  TypeSystemClang::StartTagDeclarationDefinition(sigchld_type);
  TypeSystemClang::AddFieldToRecordType(sigchld_type, "pid", pid_t_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(sigchld_type, "uid", uid_t_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(sigchld_type, "status", int_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(sigchld_type, "utime", clock_t_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(sigchld_type, "stime", clock_t_type,
                                        eAccessPublic, 0);
  TypeSystemClang::CompleteTagDeclarationDefinition(sigchld_type);

  // Anonymous addr_bnd struct.
  CompilerType addr_bnd_type = ast_ctx.CreateRecordType(
      nullptr, OptionalClangModuleID(), eAccessPublic, llvm::StringRef(),
      clang::TTK_Struct, eLanguageTypeC);
  TypeSystemClang::StartTagDeclarationDefinition(addr_bnd_type);
  TypeSystemClang::AddFieldToRecordType(addr_bnd_type, "lower", void_ptr_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(addr_bnd_type, "upper", void_ptr_type,
                                        eAccessPublic, 0);
  TypeSystemClang::CompleteTagDeclarationDefinition(addr_bnd_type);

  // Anonymous sigfault_extra union.
  CompilerType sigfault_extra_type = ast_ctx.CreateRecordType(
      nullptr, OptionalClangModuleID(), eAccessPublic, llvm::StringRef(),
      clang::TTK_Union, eLanguageTypeC);
  TypeSystemClang::StartTagDeclarationDefinition(sigfault_extra_type);
  TypeSystemClang::AddFieldToRecordType(sigfault_extra_type, "addr_bnd",
                                        addr_bnd_type, eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(sigfault_extra_type, "pkey", u32_type,
                                        eAccessPublic, 0);
  TypeSystemClang::CompleteTagDeclarationDefinition(sigfault_extra_type);

  // Anonymous sigfault struct.
  CompilerType sigfault_type = ast_ctx.CreateRecordType(
      nullptr, OptionalClangModuleID(), eAccessPublic, llvm::StringRef(),
      clang::TTK_Struct, eLanguageTypeC);
  TypeSystemClang::StartTagDeclarationDefinition(sigfault_type);
  TypeSystemClang::AddFieldToRecordType(sigfault_type, "addr", void_ptr_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(sigfault_type, "addr_lsb", short_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(sigfault_type, "extra",
                                        sigfault_extra_type, eAccessPublic, 0);
  TypeSystemClang::CompleteTagDeclarationDefinition(sigfault_type);

  // Anonymous sigpoll struct.
  CompilerType sigpoll_type = ast_ctx.CreateRecordType(
      nullptr, OptionalClangModuleID(), eAccessPublic, llvm::StringRef(),
      clang::TTK_Struct, eLanguageTypeC);
  TypeSystemClang::StartTagDeclarationDefinition(sigpoll_type);
  TypeSystemClang::AddFieldToRecordType(sigpoll_type, "band", long_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(sigpoll_type, "fd", int_type,
                                        eAccessPublic, 0);
  TypeSystemClang::CompleteTagDeclarationDefinition(sigpoll_type);

  // Anonymous sigsys struct.
  CompilerType sigsys_type = ast_ctx.CreateRecordType(
      nullptr, OptionalClangModuleID(), eAccessPublic, llvm::StringRef(),
      clang::TTK_Struct, eLanguageTypeC);
  TypeSystemClang::StartTagDeclarationDefinition(sigsys_type);
  TypeSystemClang::AddFieldToRecordType(sigsys_type, "call_addr",
                                        void_ptr_type, eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(sigsys_type, "syscall", int_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(sigsys_type, "arch", uint_type,
                                        eAccessPublic, 0);
  TypeSystemClang::CompleteTagDeclarationDefinition(sigsys_type);

  // Anonymous sifields union.
  CompilerType sifields_type = ast_ctx.CreateRecordType(
      nullptr, OptionalClangModuleID(), eAccessPublic, llvm::StringRef(),
      clang::TTK_Union, eLanguageTypeC);
  TypeSystemClang::StartTagDeclarationDefinition(sifields_type);
  TypeSystemClang::AddFieldToRecordType(sifields_type, "kill", kill_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(sifields_type, "timer", timer_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(sifields_type, "rt", rt_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(sifields_type, "sigchld", sigchld_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(sifields_type, "sigfault",
                                        sigfault_type, eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(sifields_type, "sigpoll", sigpoll_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(sifields_type, "sigsys", sigsys_type,
                                        eAccessPublic, 0);
  TypeSystemClang::CompleteTagDeclarationDefinition(sifields_type);

  // Siginfo struct.
  CompilerType siginfo_type = ast_ctx.CreateRecordType(
      nullptr, OptionalClangModuleID(), eAccessPublic, type_name.str().c_str(),
      clang::TTK_Struct, eLanguageTypeC);
  TypeSystemClang::StartTagDeclarationDefinition(siginfo_type);
  TypeSystemClang::AddFieldToRecordType(siginfo_type, "si_signo", int_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(siginfo_type, "si_errno", int_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(siginfo_type, "si_code", int_type,
                                        eAccessPublic, 0);
  TypeSystemClang::AddFieldToRecordType(siginfo_type, "si_fields",
                                        sifields_type, eAccessPublic, 0);
  TypeSystemClang::CompleteTagDeclarationDefinition(siginfo_type);

  return siginfo_type;
}
