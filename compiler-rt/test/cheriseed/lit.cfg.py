# -*- Python -*-

import os

# Setup config name.
config.name = 'CHERIseed' + config.name_suffix

# Setup source root.
config.test_source_root = os.path.dirname(__file__)

# Setup default compiler flags.
clang_cheriseed_cflags = (["-fsanitize=cheriseed"] + [config.target_cflags] + config.debug_info_flags)
clang_cheriseed_cxxflags = config.cxx_mode_flags + clang_cheriseed_cflags

def build_invocation(compile_flags):
  return " " + " ".join([config.clang] + compile_flags) + " "

config.substitutions.append( ("%clang_cheriseed ", build_invocation(clang_cheriseed_cflags)) )
config.substitutions.append( ("%clangxx_cheriseed ", build_invocation(clang_cheriseed_cxxflags)) )

# Default test suffixes.
config.suffixes = ['.c', '.cpp']

# CHERIseed tests are currently supported on Linux only.
if config.host_os not in ['Linux']:
  config.unsupported = True
