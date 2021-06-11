//===--- AArch64BareMetal.cpp - AArch64 Bare-Metal Tool Chain ---*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "AArch64BareMetal.h"
#include "Arch/AArch64.h"
#include "CommonArgs.h"
#include "clang/Driver/Compilation.h"
#include "clang/Driver/DriverDiagnostic.h"
#include "clang/Driver/Driver.h"
#include "clang/Driver/Options.h"
#include "llvm/Option/ArgList.h"

#include "llvm/Support/Path.h"

using namespace clang::driver;
using namespace clang::driver::toolchains;
using namespace clang::driver::tools::aarch64;
using namespace clang;
using namespace llvm::opt;

bool AArch64BareMetalToolChain::isPICDefault() const { return false; }
bool AArch64BareMetalToolChain::isPIEDefault() const { return false; }
bool AArch64BareMetalToolChain::isPICDefaultForced() const { return false; }
bool AArch64BareMetalToolChain::IsIntegratedAssemblerDefault() const {
  return true;
}
bool AArch64BareMetalToolChain::IsUnwindTablesDefault(
    const llvm::opt::ArgList &Args) const {
  return false;
}
bool AArch64BareMetalToolChain::SupportsProfiling() const { return false; }
std::string
AArch64BareMetalToolChain::getThreadModel() const {
  return "single";
}
bool AArch64BareMetalToolChain::isThreadModelSupported(
    const StringRef Model) const {
  return false;
}

AArch64BareMetalToolChain::~AArch64BareMetalToolChain() {}

std::string getVariantName(bool PureCap, bool A64C, bool C64, bool IsDesc) {
  if (IsDesc)
    return "aarch64-none-elf+morello+c64+purecap+desc";

  if (PureCap)
    return "aarch64-none-elf+morello+c64+purecap";

  if (A64C)
    return "aarch64-none-elf+morello+a64c";

  return "aarch64-none-elf";
}

static const char *getLinkerName(const Driver &D, const ArgList &Args) {
  if (Args.hasArg(options::OPT_fuse_ld_EQ) ) {
    StringRef Ld = Args.getLastArgValue(options::OPT_fuse_ld_EQ);

    if (Ld.endswith_lower("lld"))
      return "ld.lld";
    if (Ld.endswith_lower("bfd"))
      return "aarch64-none-elf-ld.bfd";
    D.Diag(diag::err_drv_unsupported_linker) << Ld;
  }

  // By default, use the lld linker.
  return "ld.lld";
}

AArch64BareMetalToolChain::AArch64BareMetalToolChain(const Driver &D,
                                                     const llvm::Triple &Triple,
                                                     const ArgList &Args)
    : ToolChain(D, Triple, Args),
      SysRoot(llvm::sys::path::parent_path(D.getInstalledDir())),
      Linker(getLinkerName(D, Args)) {
  // Our linker is expected to be found in our install dir.
  bool ReducedCaps;
  bool IsDesc;
  getMorelloMode(D, Triple, Args, A64C, C64, PureCap, ReducedCaps, IsDesc);
  Variant = getVariantName(PureCap, A64C, C64, IsDesc);
  getProgramPaths().push_back(D.getInstalledDir());
}

std::string AArch64BareMetalToolChain::getVariantDir() const {
  return SysRoot + "/" + Variant;
}

std::string AArch64BareMetalToolChain::getStdLibDir() const {
  return getVariantDir() + "/lib";
}

std::string
AArch64BareMetalToolChain::getGNUMarch(const llvm::opt::ArgList &Args) const {
  if (C64)
    return "armv8-a+c64";

  if (A64C)
    return "armv8-a+a64c";

  return "armv8-a";
}

Tool *AArch64BareMetalToolChain::buildLinker() const {
  return new tools::aarch64::Linker(*this, Linker);
}

Tool *AArch64BareMetalToolChain::buildAssembler() const {
  return new tools::aarch64::Assembler(*this, "aarch64-none-elf-as");
}

void AArch64BareMetalToolChain::AddClangSystemIncludeArgs(
    const ArgList &DriverArgs, ArgStringList &CC1Args) const {
  if (!DriverArgs.hasArg(options::OPT_nostdinc))
    addSystemInclude(DriverArgs, CC1Args, SysRoot + "/" + Variant + "/include");
}

ToolChain::CXXStdlibType
AArch64BareMetalToolChain::GetDefaultCXXStdlibType() const {
  return ToolChain::CST_Libcxx;
}

ToolChain::CXXStdlibType
AArch64BareMetalToolChain::GetCXXStdlibType(const ArgList &Args) const {
  if (Arg *A = Args.getLastArg(options::OPT_stdlib_EQ)) {
    StringRef Value = A->getValue();
    if (Value != "libc++")
      getDriver().Diag(diag::err_drv_invalid_stdlib_name)
          << A->getAsString(Args);
  }

  return ToolChain::CST_Libcxx;
}

void AArch64BareMetalToolChain::AddClangCXXStdlibIncludeArgs(
    const ArgList &DriverArgs, ArgStringList &CC1Args) const {
  if (DriverArgs.hasArg(options::OPT_nostdlibinc) ||
      DriverArgs.hasArg(options::OPT_nostdincxx))
    return;

  // Only our bundled C++ library (libc++) is supported for now. Check for the
  // -stdlib= flag and consume it. And emit an error if the user did not supply
  // the expected value.
  GetCXXStdlibType(DriverArgs);
  addSystemInclude(DriverArgs, CC1Args, SysRoot + "/" + Variant + "/include/c++/v1");
}

void AArch64BareMetalToolChain::AddCXXStdlibLibArgs(
    const ArgList &Args, ArgStringList &CmdArgs) const {
  // Check for -stdlib= flags. We only support libc++ but this consumes the arg
  // if the value is libc++, and emits an error for other values.
  GetCXXStdlibType(Args);
  CmdArgs.push_back("-lc++");
  CmdArgs.push_back("-lc++abi");
  CmdArgs.push_back("-lunwind");
}

ToolChain::RuntimeLibType
AArch64BareMetalToolChain::GetRuntimeLibType(const ArgList &Args) const {
  if (Arg *A = Args.getLastArg(options::OPT_rtlib_EQ)) {
    StringRef Value = A->getValue();
    if (Value != "compiler-rt")
      getDriver().Diag(diag::err_drv_invalid_rtlib_name)
          << A->getAsString(Args);
  }

  return ToolChain::RLT_CompilerRT;
}

void AArch64BareMetalToolChain::addClangTargetOptions(
    const ArgList &DriverArgs, ArgStringList &CC1Args,
    Action::OffloadKind DeviceOffloadKind) const {
  CC1Args.push_back("-isysroot");
  CC1Args.push_back(DriverArgs.MakeArgString(SysRoot));

  if (!DriverArgs.hasFlag(options::OPT_fuse_init_array,
                         options::OPT_fno_use_init_array, true))
    CC1Args.push_back("-fno-use-init-array");
}

void Linker::ConstructJob(Compilation &C, const JobAction &JA,
                                   const InputInfo &Output,
                                   const InputInfoList &Inputs,
                                   const ArgList &Args,
                                   const char *LinkingOutput) const {

  const toolchains::AArch64BareMetalToolChain &TC =
      static_cast<const toolchains::AArch64BareMetalToolChain &>(
          getToolChain());
  bool UsesLLD =
      Args.getLastArgValue(options::OPT_fuse_ld_EQ).endswith_lower("lld") ||
    LinkerName == "ld.lld";

  ArgStringList CmdArgs;

  CmdArgs.push_back("-o");
  CmdArgs.push_back(Output.getFilename());

  if (!UsesLLD) {
    // This must come before the ldscript
    std::string TextSegment = "0x80000000";
    for (Arg *A : Args) {
      if (A->getOption().matches(options::OPT_Wl_COMMA) &&
          A->getNumValues() == 2 &&
          A->getValue(0) == StringRef("-Ttext-segment")) {
        TextSegment = A->getValue(1);
      }
    }

    CmdArgs.push_back("-Ttext-segment");
    CmdArgs.push_back(Args.MakeArgString(TextSegment));
  } else {
    CmdArgs.push_back("-entry");
    CmdArgs.push_back("_start");

    // LLD does not support -Ttext-segment, the equivalent option is
    // --image-base=value this sets the initial value of the location counter.
    std::string ImageBase = "0x80000000";
    for (Arg *A : Args) {
      if (A->getOption().matches(options::OPT_Wl_COMMA) &&
          A->getNumValues() == 2 &&
          (A->getValue(0) == StringRef("--image-base") ||
           A->getValue(0) == StringRef("-image-base"))) {
        ImageBase = A->getValue(1);
      }
    }

    CmdArgs.push_back("--image-base");
    CmdArgs.push_back(Args.MakeArgString(ImageBase));
  }
  // Force the search path to the targetted variant library.
  CmdArgs.push_back("-L");
  CmdArgs.push_back(Args.MakeArgString(TC.getStdLibDir()));

  CmdArgs.push_back("--gc-sections");
  addMorelloLinkerFlags(Args, CmdArgs);

  bool UseStartfiles = !Args.hasArg(options::OPT_nostdlib, options::OPT_nostartfiles);
  if (UseStartfiles) {
    CmdArgs.push_back(Args.MakeArgString(TC.getStdLibDir() + "/rdimon-crt0.o"));
    CmdArgs.push_back(Args.MakeArgString(TC.getStdLibDir() + "/crti.o"));
    CmdArgs.push_back(Args.MakeArgString(TC.getStdLibDir() + "/cpu-init/rdimon-aem-el3.o"));
  }

  AddLinkerInputs(getToolChain(), Inputs, Args, CmdArgs, JA);

  if (!Args.hasArg(options::OPT_nostdlib, options::OPT_nodefaultlibs)) {
    if (C.getDriver().CCCIsCXX()) {
      CmdArgs.push_back("-lm");
      TC.AddCXXStdlibLibArgs(Args, CmdArgs);
    }

    CmdArgs.push_back("--start-group");
    CmdArgs.push_back("-lc");
    CmdArgs.push_back("-lrdimon");
    CmdArgs.push_back("--end-group");

    CmdArgs.push_back("-lclang_rt.builtins-aarch64");
  } else {
    // The user may have zapped all default libraries from the command line,
    // but still want some of them to be added explicitely from the command line.
    if (Args.hasArg(options::OPT_nodefaultlibs)) {
      // C library if forced so with -lc
      for (Arg *A : Args) {
        if (A->getOption().matches(options::OPT_l) &&
            strcmp(A->getValue(), "c") == 0) {
          CmdArgs.push_back("--start-group");
          CmdArgs.push_back("-lc");
          CmdArgs.push_back("-lrdimon");
          CmdArgs.push_back("--end-group");
          break;
        }
      }

      // compiler-rt if forced so with -rtlib=compiler-rt
      if (Args.hasArg(options::OPT_rtlib_EQ)) {
        ToolChain::RuntimeLibType RLT = TC.GetRuntimeLibType(Args);
        assert(RLT == ToolChain::RLT_CompilerRT);
        CmdArgs.push_back("-lclang_rt.builtins-aarch64");
      }
    }
  }

  if (UseStartfiles)
    CmdArgs.push_back(Args.MakeArgString(TC.getStdLibDir() + "/crtn.o"));

  const char *Linker = nullptr;
  if (Args.hasArg(options::OPT_fuse_ld_EQ)) {
    StringRef Ld = Args.getLastArgValue(options::OPT_fuse_ld_EQ);
    if (llvm::sys::path::is_absolute(Ld))
      Linker = Args.MakeArgString(TC.GetLinkerPath());
  }
  if (Linker == nullptr)
    Linker = Args.MakeArgString(TC.GetProgramPath(LinkerName.c_str()));
  C.addCommand(std::make_unique<Command>(JA, *this, Linker, CmdArgs, Inputs));
}

void Assembler::ConstructJob(Compilation &C, const JobAction &JA,
                                      const InputInfo &Output,
                                      const InputInfoList &Inputs,
                                      const llvm::opt::ArgList &Args,
                                      const char *LinkingOutput) const {
  const toolchains::AArch64BareMetalToolChain &TC =
      static_cast<const toolchains::AArch64BareMetalToolChain &>(
          getToolChain());

  ArgStringList CmdArgs;

  std::string GNUMarch="-march=" + TC.getGNUMarch(Args);
  CmdArgs.push_back(Args.MakeArgString(GNUMarch));

  CmdArgs.push_back("-o");
  CmdArgs.push_back(Output.getFilename());

  assert(Inputs.size() == 1 && "Unexpected number of inputs.");
  const InputInfo &Input = Inputs[0];
  assert(Input.isFilename() && "Invalid input.");
  CmdArgs.push_back(Input.getFilename());

  const char *Assembler = Args.MakeArgString(TC.GetProgramPath(AssemblerName.c_str()));
  C.addCommand(std::make_unique<Command>(JA, *this, Assembler, CmdArgs, Inputs));
}
