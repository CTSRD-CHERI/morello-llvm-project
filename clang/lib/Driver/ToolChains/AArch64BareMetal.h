//===--- AArch64BareMetal.h - AArch64 Bare-Metal Tool Chain -----*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_LIB_DRIVER_TOOLCHAINS_AARCH64_BAREMETAL_H
#define LLVM_CLANG_LIB_DRIVER_TOOLCHAINS_AARCH64_BAREMETAL_H

#include "Gnu.h"
#include "clang/Driver/Tool.h"
#include "clang/Driver/ToolChain.h"

namespace clang {
namespace driver {
namespace tools {
namespace aarch64 {

class LLVM_LIBRARY_VISIBILITY Linker : public Tool {
public:
  Linker(const ToolChain &TC, const char *Name)
      : Tool("aarch64::Linker", Name, TC), LinkerName(Name) {}

  bool hasIntegratedCPP() const override { return false; }
  bool isLinkJob() const override { return true; }

  void ConstructJob(Compilation &C, const JobAction &JA,
                    const InputInfo &Output, const InputInfoList &Inputs,
                    const llvm::opt::ArgList &TCArgs,
                    const char *LinkingOutput) const override;
private:
  const std::string LinkerName;
};
class LLVM_LIBRARY_VISIBILITY Assembler : public Tool {
public:
  Assembler(const ToolChain &TC, const char *Name)
      : Tool("aarch64::Assembler", Name, TC), AssemblerName(Name) {}

  bool hasIntegratedCPP() const override { return false; }

  void ConstructJob(Compilation &C, const JobAction &JA,
                    const InputInfo &Output, const InputInfoList &Inputs,
                    const llvm::opt::ArgList &TCArgs,
                    const char *LinkingOutput) const override;
private:
  const std::string AssemblerName;
};

} // end namespace aarch64
} // end namespace tools

namespace toolchains {

class LLVM_LIBRARY_VISIBILITY AArch64BareMetalToolChain : public ToolChain {
public:
  AArch64BareMetalToolChain(const Driver &D, const llvm::Triple &T,
                            const llvm::opt::ArgList &Args);
  ~AArch64BareMetalToolChain() override;

  bool isPICDefault() const override;
  bool isPIEDefault(const llvm::opt::ArgList &Args) const override;
  bool isPICDefaultForced() const override;
  bool IsIntegratedAssemblerDefault() const override;
  UnwindTableLevel
  getDefaultUnwindTableLevel(const llvm::opt::ArgList &Args) const override;
  bool SupportsProfiling() const override;
  std::string getThreadModel() const override;
  bool isThreadModelSupported(const StringRef Model) const override;

  void
  AddClangSystemIncludeArgs(const llvm::opt::ArgList &DriverArgs,
                            llvm::opt::ArgStringList &CC1Args) const override;
  CXXStdlibType GetDefaultCXXStdlibType() const override;
  CXXStdlibType GetCXXStdlibType(const llvm::opt::ArgList &Args) const override;
  void AddClangCXXStdlibIncludeArgs(
      const llvm::opt::ArgList &DriverArgs,
      llvm::opt::ArgStringList &CC1Args) const override;
  void AddCXXStdlibLibArgs(const llvm::opt::ArgList &Args,
                           llvm::opt::ArgStringList &CmdArgs) const override;
  RuntimeLibType GetRuntimeLibType(const llvm::opt::ArgList &Args) const override;
  void addClangTargetOptions(const llvm::opt::ArgList &DriverArgs,
                             llvm::opt::ArgStringList &CC1Args,
                             Action::OffloadKind DeviceOffloadKind) const override;

  std::string getStdLibDir() const;
  std::string getVariantDir() const;
  std::string getGNUMarch(const llvm::opt::ArgList &Args) const;

  bool A64C = false;
  bool C64 = false;
  bool PureCap = false;

protected:
  Tool *buildLinker() const override;
  Tool *buildAssembler() const override;

private:
  const std::string SysRoot;
  const char *Linker;
  std::string Variant;
};


} // end namespace toolchains
} // end namespace driver
} // end namespace clang

#endif // LLVM_CLANG_LIB_DRIVER_TOOLCHAINS_AARCH64_BAREMETAL_H
