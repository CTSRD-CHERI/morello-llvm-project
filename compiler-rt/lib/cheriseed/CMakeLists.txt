include_directories(..)

add_compiler_rt_component(cheriseed)

set(CHERISEED_SOURCES
  cheriseed.cpp
  cheriseed_errors.cpp
  cheriseed_libc.cpp
  cheriseed_shadow_memory.cpp)

set(CHERISEED_RELOCATION_SOURCES
  cheriseed_relocation.cpp)

set(CHERISEED_CFLAGS ${SANITIZER_COMMON_CFLAGS})
append_rtti_flag(OFF CHERISEED_CFLAGS)
# Be very strict
list(APPEND CHERISEED_CFLAGS -Wconversion)
list(APPEND CHERISEED_CFLAGS -Werror)

foreach(arch ${CHERISEED_SUPPORTED_ARCH})
  add_compiler_rt_runtime(clang_rt.cheriseed
    STATIC
    ARCHS ${arch}
    SOURCES ${CHERISEED_SOURCES}
    OBJECT_LIBS RTSanitizerCommon
                RTSanitizerCommonNoLibc
    LINK_LIBS cheri-compressed-cap-upstream
    CFLAGS ${CHERISEED_CFLAGS}
    PARENT_TARGET cheriseed)
  list(APPEND CHERISEED_RUNTIME_LIBRARIES clang_rt.cheriseed-${arch})

  add_compiler_rt_runtime(clang_rt.cheriseed-relocation
    STATIC
    ARCHS ${arch}
    SOURCES ${CHERISEED_RELOCATION_SOURCES}
    CFLAGS ${CHERISEED_CFLAGS}
    PARENT_TARGET cheriseed)
  list(APPEND CHERISEED_RUNTIME_LIBRARIES clang_rt.cheriseed-relocation-${arch})
endforeach()

add_subdirectory(benchmarks)
if(COMPILER_RT_INCLUDE_TESTS)
  add_subdirectory(tests)
endif()
