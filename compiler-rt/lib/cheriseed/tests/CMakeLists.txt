# Testing targets for CHERIseed
#
# Currently we are only doing non-instrumented tests, meaning that they are testing
# the APIs and functionality of the compiler runtime library without running a full
# instrumented pass with -fsanitize.

set(CHERISEED_UNITTEST_HEADERS
  cheriseed_test_config.h
  cheriseed_test_utils.h)

get_property(CHERI_COMPRESSED_CAP_INTERFACE_DIRECTORY
       TARGET cheri-compressed-cap-upstream
       PROPERTY INTERFACE_INCLUDE_DIRECTORIES)

set(CHERISEED_UNITTEST_COMMON_CFLAGS
  ${COMPILER_RT_UNITTEST_CFLAGS}
  ${COMPILER_RT_GTEST_CFLAGS}
  -I${COMPILER_RT_SOURCE_DIR}/include
  -I${COMPILER_RT_SOURCE_DIR}/lib
  -I${COMPILER_RT_SOURCE_DIR}/lib/cheriseed
  -I${CHERI_COMPRESSED_CAP_INTERFACE_DIRECTORY}
  -I${LLVM_MAIN_SRC_DIR}/include/
  -fno-rtti
  -Wno-non-virtual-dtor
  )

set(CHERISEED_NOINST_TEST_SOURCES
  ${COMPILER_RT_GTEST_SOURCE}
  cheriseed_api_violations.cpp
  cheriseed_api.cpp
  cheriseed_atomic_tests.cpp
  cheriseed_check_address.cpp
  cheriseed_check_global_inits.cpp
  cheriseed_check_shadow_memory.cpp
  cheriseed_check_tag.cpp
  cheriseed_check_unaligned.cpp
  cheriseed_check.cpp
  cheriseed_dynamic_configuration.cpp
  cheriseed_environment.cpp
  cheriseed_options_tests.cpp
  cheriseed_test_main.cpp)

set(CHERISEED_UNITTEST_COMMON_LINK_FLAGS
  ${COMPILER_RT_UNITTEST_LINK_FLAGS}
  --driver-mode=g++)

set(CHERISEED_UNITTEST_NOINST_LINK_FLAGS ${CHERISEED_UNITTEST_COMMON_LINK_FLAGS})

append_list_if(COMPILER_RT_HAS_LIBDL -ldl CHERISEED_UNITTEST_NOINST_LINK_FLAGS)
append_list_if(COMPILER_RT_HAS_LIBPTHREAD -pthread CHERISEED_UNITTEST_NOINST_LINK_FLAGS)

add_custom_target(CHERIseedUnitTests)
set_target_properties(CHERIseedUnitTests PROPERTIES FOLDER "Compiler-RT Tests")

function(add_cheriseed_tests arch test_runtime kind)
  string(TOUPPER ${kind} kind_upper)

  set(CHERIseedTestObjects)
  generate_compiler_rt_tests(CHERIseedTestObjects
      CHERIseedUnitTests "CHERIseed-${arch}-${kind}-Test" ${arch}
      COMPILE_DEPS ${CHERISEED_UNITTEST_HEADERS}
      DEPS gtest cheriseed cheri-compressed-cap-upstream
      CFLAGS ${CHERISEED_UNITTEST_COMMON_CFLAGS}
      LINK_FLAGS ${CHERISEED_UNITTEST_${kind_upper}_LINK_FLAGS}
      SOURCES ${CHERISEED_${kind_upper}_TEST_SOURCES}
      RUNTIME ${test_runtime})
endfunction()

if(COMPILER_RT_CAN_EXECUTE_TESTS AND NOT ANDROID)
  set(CHERISEED_TEST_ARCH ${CHERISEED_SUPPORTED_ARCH})

  foreach(arch ${CHERISEED_TEST_ARCH})
    # Add static cheriseed runtime that will be linked with uninstrumented tests.
    set(CHERISEED_TEST_RUNTIME RTCHERIseedTest.${arch})

    set(CHERISEED_TEST_RUNTIME_OBJECTS
        $<TARGET_OBJECTS:clang_rt.cheriseed-${arch}>
        $<TARGET_OBJECTS:RTSanitizerCommon.${arch}>
        $<TARGET_OBJECTS:RTSanitizerCommonNoLibc.${arch}>)

    add_library(${CHERISEED_TEST_RUNTIME} STATIC ${CHERISEED_TEST_RUNTIME_OBJECTS})
    set_target_properties(${CHERISEED_TEST_RUNTIME} PROPERTIES
      ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
      FOLDER "Compiler-RT Runtime Tests")

    # Uninstrumented tests.
    add_cheriseed_tests(${arch} ${CHERISEED_TEST_RUNTIME} "NoInst")
  endforeach()
endif()
