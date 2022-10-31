# Benchmarks for CHERIseed
#
# Usage:
#   1. Build the target "CHERIseedBenchmarks.<arch>"
#   2. Locate the output binary in the build directory under
#      projects/compiler-rt/lib/cheriseed/benchmarks/CHERIseedBenchmarks.<arch>
#      and simply run it.

get_property(CHERI_COMPRESSED_CAP_INTERFACE_DIRECTORY
       TARGET cheri-compressed-cap-upstream
       PROPERTY INTERFACE_INCLUDE_DIRECTORIES)

set(CHERISEED_BENCHMARK_CFLAGS
    -I${COMPILER_RT_SOURCE_DIR}/include/
    -I${COMPILER_RT_SOURCE_DIR}/lib/cheriseed/
    -I${COMPILER_RT_SOURCE_DIR}/lib/cheriseed/tests/
    -I${CHERI_COMPRESSED_CAP_INTERFACE_DIRECTORY}
)
string(REPLACE ";" " " CHERISEED_BENCHMARK_CFLAGS " ${CHERISEED_BENCHMARK_CFLAGS}")

set(CHERISEED_BENCHMARK_SOURCES
    cheriseed_api_benchmark.cpp
    cheriseed_benchmark_main.cpp
)

foreach(arch ${CHERISEED_SUPPORTED_ARCH})
    add_benchmark(CHERIseedBenchmarks.${arch}
                  ${CHERISEED_BENCHMARK_SOURCES}
                  $<TARGET_OBJECTS:clang_rt.cheriseed-${arch}>
                  $<TARGET_OBJECTS:RTSanitizerCommon.${arch}>
                  $<TARGET_OBJECTS:RTSanitizerCommonNoLibc.${arch}>)

    set_property(TARGET CHERIseedBenchmarks.${arch} APPEND_STRING PROPERTY
                 COMPILE_FLAGS "${CHERISEED_BENCHMARK_CFLAGS}")
endforeach()
