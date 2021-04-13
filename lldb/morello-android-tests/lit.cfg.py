# -*- Python -*-

import os
import platform
import re
import shutil
import site
import subprocess
import sys

import lit.formats

site.addsitedir(os.path.dirname(__file__))

# name: The name of this test suite.
config.name = 'lldb-morello-android'

# The path to the script that runs each test.
do_morello_test = shutil.which(
        'do-morello-test.sh',
        path=os.path.dirname(os.path.realpath(__file__)))

# testFormat: The test format to use to interpret tests.
config.test_format = lit.formats.ShTest(
        # These are actually all the commands we run, since it's not interesting
        # at this point to have custom RUN lines for each test.
        preamble_commands=[
            do_morello_test + " %s"
            ])

def require_param(name):
    if not name in lit_config.params:
        sys.exit("No value for {}, use --param to specify".format(name))

require_param('ANDROID_ROOT')
config.environment['ANDROID_ROOT'] = lit_config.params['ANDROID_ROOT']

require_param('ADB_PORT')
config.environment['ADB_PORT'] = lit_config.params['ADB_PORT']

require_param('LLDB_SERVER_PORT')
config.environment['LLDB_SERVER_PORT'] = lit_config.params['LLDB_SERVER_PORT']

require_param('LLDB_SERVER')
config.environment['LLDB_SERVER'] = lit_config.params['LLDB_SERVER']

require_param('LLVM_TOOLS_DIR')
llvm_tools_dir = lit_config.params['LLVM_TOOLS_DIR']

config.environment['LLDB_EXECUTABLE'] = shutil.which(
        'lldb', path=llvm_tools_dir)
if not config.environment['LLDB_EXECUTABLE']:
    sys.exit("Couldn't find lldb in {}".format(llvm_tools_dir))

config.environment['FILECHECK_EXECUTABLE'] = shutil.which(
        'FileCheck', path=llvm_tools_dir)
if not config.environment['FILECHECK_EXECUTABLE']:
    sys.exit("Couldn't find FileCheck in {}".format(llvm_tools_dir))

# suffixes: A list of file extensions to treat as test files. This is overriden
# by individual lit.local.cfg files in the test subdirectories.
config.suffixes = ['.test']

# excludes: A list of directories to exclude from the testsuite. The 'Inputs'
# subdirectories contain auxiliary inputs for various tests in their parent
# directories.
config.excludes = ['Inputs', 'CMakeLists.txt', 'README', 'LICENSE.txt']

# test_source_root: The root path where tests are located.
config.test_source_root = os.path.dirname(__file__)

# Set a default per-test timeout of 10 minutes. Setting a timeout per test
# requires that killProcessAndChildren() is supported on the platform and
# lit complains if the value is set but it is not supported.
supported, errormsg = lit_config.maxIndividualTestTimeIsSupported
if supported:
    lit_config.maxIndividualTestTime = 600
else:
    lit_config.warning("Could not set a default per-test timeout. " + errormsg)

