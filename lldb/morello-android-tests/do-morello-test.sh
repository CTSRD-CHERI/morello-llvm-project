#!/bin/bash

# This script assumes we already have an FVP model running and the test binary
# compiled at a path derived from the ANDROID_ROOT (see below). It also assumes
# that lldb-server has already been copied to the model.

# We can't use -u here because build/envsetup.sh has unbound variables.
set -ef -o pipefail

cleanup=""
trap 'eval " ${cleanup}"' EXIT

function run_on_exit() {
  # Add a command to the trap handler.
  if [[ -z "${cleanup}" ]]; then
    cleanup="$1"
  else
    cleanup="${cleanup}; $1"
  fi
}

# Process parameters and environment variables.
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <path-to-lldb-commands-file>" >&2
  exit 2
fi

test_file=$1

# This is an environment variable which should be pointing to the root of the
# android development tree.
if ! test -d "${ANDROID_ROOT}"; then
  echo "Error: Invalid ANDROID_ROOT: ${ANDROID_ROOT}" >&2
  exit 2
fi

if test -z "${ADB_PORT}"; then
  echo "Error: Please set the ADB_PORT environment variable" >&2
  exit 2
fi

if test -z "${LLDB_SERVER}"; then
  echo "Error: Please set the LLDB_SERVER environment variable" >&2
  exit 2
fi

if test -z "${LLDB_SERVER_PORT}"; then
  echo "Error: Please set the LLDB_SERVER_PORT environment variable" >&2
  exit 2
fi

if ! test -f "${LLDB_EXECUTABLE}"; then
  echo "Error: Invalid LLDB_EXECUTABLE: ${LLDB_EXECUTABLE}" >&2
  exit 5
fi

if ! test -f "${FILECHECK_EXECUTABLE}"; then
  echo "Error: Invalid FILECHECK_EXECUTABLE: ${FILECHECK_EXECUTABLE}" >&2
  exit 5
fi

# Setup the environment so that we can use adb.
cd ${ANDROID_ROOT}
source build/envsetup.sh
lunch morello_fvp_nano-eng

adb connect 127.0.0.1:${ADB_PORT}

# The test_file is a path to an "APP.test" file, where APP is used as the
# name of the binary and associated directories everywhere else.
app=$(basename -s .test ${test_file})

push_path="/data/nativetestc64/${app}"
build_path="${OUT}${push_path}" # $OUT is set by `lunch`

if ! test -f "${build_path}/${app}"; then
  echo "Error: Couldn't find binary at ${build_path}/${app}" >&2
  exit 5
fi

# Copy the binary to the model.
adb push "${build_path}" "${push_path}"
run_on_exit 'adb shell rm -rf ${push_path}'

remote_exe="${push_path}/${app}"

# The path where the binary with debug symbols is put by the android build
# system.
symbols_dir="${OUT}/symbols"
local_exe="${symbols_dir}${remote_exe}"
if ! test -f "${local_exe}"; then
  echo "Error: Couldn't find binary with debug symbols ${local_exe}" >&2
  exit 5
fi

# Forward port for lldb-server.
adb forward tcp:"${LLDB_SERVER_PORT}" tcp:"${LLDB_SERVER_PORT}"

# Start lldb-server on the model.
if ! adb shell test -f "${LLDB_SERVER}"; then
  echo "Error: Couldn't find lldb-server on the device at ${LLDB_SERVER}" >&2
  exit 5
fi

# FIXME: Enable logging only when requested by the user.
log_channels='posix all:gdb-remote all:lldb all'
log_platform='/data/local/tmp/lldb-server-platform.log'
log_gdbserver='/data/local/tmp/lldb-server-gdbserver.log'
env="LLDB_DEBUGSERVER_LOG_FILE='${log_gdbserver}' LLDB_SERVER_LOG_CHANNELS='${log_channels}'"
adb shell "$env ${LLDB_SERVER} platform --listen *:${LLDB_SERVER_PORT} --log-file ${log_platform}" &
# Wait a bit to make sure it started
sleep 10

startup_commands=lldb-startup.cmds
{
  echo "settings set platform.use-module-cache false"
  echo "settings set target.auto-install-main-executable false"
  echo "settings set plugin.process.gdb-remote.packet-timeout 300"
  echo "settings set interpreter.echo-comment-commands false"
  echo "platform select remote-android"
  echo "platform connect connect://localhost:${LLDB_SERVER_PORT}"
  echo "target create -r ${remote_exe} ${local_exe}"
  echo "target modules search-path add / ${symbols_dir}"
} >"${startup_commands}"
run_on_exit 'rm -f ${startup_commands}'

${LLDB_EXECUTABLE} --batch --no-lldbinit \
  -s "${startup_commands}" \
  -s "${test_file}" \
  | "${FILECHECK_EXECUTABLE}" "${test_file}"
