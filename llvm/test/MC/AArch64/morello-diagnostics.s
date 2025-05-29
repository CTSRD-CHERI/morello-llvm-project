// RUN: not llvm-mc -triple aarch64-none-linux-gnu -mattr=+neon,+c64 < %s 2> %t
// RUN: FileCheck --check-prefix=CHECK-ERROR < %t %s
// RUN: not llvm-mc -triple aarch64-none-linux-gnu -mattr=+neon,+c64,+morello < %s 2> %t
// RUN: FileCheck --check-prefix=CHECK-ERROR < %t %s

         ld1 {x3}, [x2]
         ld1 {v4}, [c0]
         ld1 {v32.16b}, [c0]
         ld1 {v15.8h}, [c32]
// CHECK-ERROR: error: vector register expected
// CHECK-ERROR:        ld1 {x3}, [x2]
// CHECK-ERROR:             ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:        ld1 {v4}, [c0]
// CHECK-ERROR:             ^
// CHECK-ERROR: error: vector register expected
// CHECK-ERROR:        ld1 {v32.16b}, [c0]
// CHECK-ERROR:             ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:        ld1 {v15.8h}, [c32]
// CHECK-ERROR:                       ^

         ld1 {v0.16b, v2.16b}, [c0]
         ld1 {v0.8h, v1.8h, v2.8h, v3.8h, v4.8h}, [c0]
         ld1 v0.8b, v1.8b}, [c0]
         ld1 {v0.8h-v4.8h}, [c0]
         ld1 {v1.8h-v1.8h}, [c0]
         ld1 {v15.8h-v17.4h}, [c24]
         ld1 {v0.8b-v2.8b, [c0]
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:        ld1 {v0.16b, v2.16b}, [c0]
// CHECK-ERROR:                     ^
// CHECK-ERROR: error: invalid number of vectors
// CHECK-ERROR:        ld1 {v0.8h, v1.8h, v2.8h, v3.8h, v4.8h}, [c0]
// CHECK-ERROR:                                         ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:        ld1 v0.8b, v1.8b}, [c0]
// CHECK-ERROR:            ^
// CHECK-ERROR: error: invalid number of vectors
// CHECK-ERROR:        ld1 {v0.8h-v4.8h}, [c0]
// CHECK-ERROR:                   ^
// CHECK-ERROR: error: invalid number of vectors
// CHECK-ERROR:        ld1 {v1.8h-v1.8h}, [c0]
// CHECK-ERROR:                   ^
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:        ld1 {v15.8h-v17.4h}, [c24]
// CHECK-ERROR:                        ^
// CHECK-ERROR: error: '}' expected
// CHECK-ERROR:        ld1 {v0.8b-v2.8b, [c0]
// CHECK-ERROR:                        ^

         ld2 {v15.8h, v16.4h}, [c24]
         ld2 {v0.8b, v2.8b}, [c0]
         ld2 {v15.4h, v16.4h, v17.4h}, [c32]
         ld2 {v15.8h-v16.4h}, [c24]
         ld2 {v0.2d-v2.2d}, [c0]
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:        ld2 {v15.8h, v16.4h}, [c24]
// CHECK-ERROR:                     ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:        ld2 {v0.8b, v2.8b}, [c0]
// CHECK-ERROR:                    ^
// CHECK-ERROR:        ld2 {v15.4h, v16.4h, v17.4h}, [c32]
// CHECK-ERROR:            ^
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:        ld2 {v15.8h-v16.4h}, [c24]
// CHECK-ERROR:                        ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:        ld2 {v0.2d-v2.2d}, [c0]
// CHECK-ERROR:            ^

         ld3 {v15.8h, v16.8h, v17.4h}, [c24]
         ld3 {v0.8b, v1,8b, v2.8b, v3.8b}, [c0]
         ld3 {v0.8b, v2.8b, v3.8b}, [c0]
         ld3 {v15.8h-v17.4h}, [c24]
         ld3 {v31.4s-v2.4s}, [csp]
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:        ld3 {v15.8h, v16.8h, v17.4h}, [c24]
// CHECK-ERROR:                             ^
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:        ld3 {v0.8b, v1,8b, v2.8b, v3.8b}, [c0]
// CHECK-ERROR:                    ^
// CHECK-ERROR: error: registers must have the same sequential stride
// CHECK-ERROR:        ld3 {v0.8b, v2.8b, v3.8b}, [c0]
// CHECK-ERROR:                    ^
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:        ld3 {v15.8h-v17.4h}, [c24]
// CHECK-ERROR:                        ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:        ld3 {v31.4s-v2.4s}, [csp]
// CHECK-ERROR:            ^

         ld4 {v15.8h, v16.8h, v17.4h, v18.8h}, [c24]
         ld4 {v0.8b, v2.8b, v3.8b, v4.8b}, [c0]
         ld4 {v15.4h, v16.4h, v17.4h, v18.4h, v19.4h}, [c31]
         ld4 {v15.8h-v18.4h}, [c24]
         ld4 {v31.2s-v1.2s}, [c31]
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:        ld4 {v15.8h, v16.8h, v17.4h, v18.8h}, [c24]
// CHECK-ERROR:                             ^
// CHECK-ERROR: error: registers must have the same sequential stride
// CHECK-ERROR:        ld4 {v0.8b, v2.8b, v3.8b, v4.8b}, [c0]
// CHECK-ERROR:                    ^
// CHECK-ERROR: error: invalid number of vectors
// CHECK-ERROR:        ld4 {v15.4h, v16.4h, v17.4h, v18.4h, v19.4h}, [c31]
// CHECK-ERROR:                                             ^
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:        ld4 {v15.8h-v18.4h}, [c24]
// CHECK-ERROR:                        ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:        ld4 {v31.2s-v1.2s}, [c31]
// CHECK-ERROR:            ^

         st1 {x3}, [x2]
         st1 {v4}, [c0]
         st1 {v32.16b}, [c0]
         st1 {v15.8h}, [c32]
// CHECK-ERROR: error: vector register expected
// CHECK-ERROR:        st1 {x3}, [x2]
// CHECK-ERROR:             ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:        st1 {v4}, [c0]
// CHECK-ERROR:             ^
// CHECK-ERROR: error: vector register expected
// CHECK-ERROR:        st1 {v32.16b}, [c0]
// CHECK-ERROR:             ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:        st1 {v15.8h}, [c32]
// CHECK-ERROR:                       ^

         st1 {v0.16b, v2.16b}, [c0]
         st1 {v0.8h, v1.8h, v2.8h, v3.8h, v4.8h}, [c0]
         st1 v0.8b, v1.8b}, [c0]
         st1 {v0.8h-v4.8h}, [c0]
         st1 {v1.8h-v1.8h}, [c0]
         st1 {v15.8h-v17.4h}, [c24]
         st1 {v0.8b-v2.8b, [c0]
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:        st1 {v0.16b, v2.16b}, [c0]
// CHECK-ERROR:                     ^
// CHECK-ERROR: error: invalid number of vectors
// CHECK-ERROR:        st1 {v0.8h, v1.8h, v2.8h, v3.8h, v4.8h}, [c0]
// CHECK-ERROR:                                         ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:        st1 v0.8b, v1.8b}, [c0]
// CHECK-ERROR:            ^
// CHECK-ERROR: error: invalid number of vectors
// CHECK-ERROR:        st1 {v0.8h-v4.8h}, [c0]
// CHECK-ERROR:                   ^
// CHECK-ERROR: error: invalid number of vectors
// CHECK-ERROR:        st1 {v1.8h-v1.8h}, [c0]
// CHECK-ERROR:                   ^
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:        st1 {v15.8h-v17.4h}, [c24]
// CHECK-ERROR:                        ^
// CHECK-ERROR: error: '}' expected
// CHECK-ERROR:        st1 {v0.8b-v2.8b, [c0]
// CHECK-ERROR:                        ^

         st2 {v15.8h, v16.4h}, [c24]
         st2 {v0.8b, v2.8b}, [c0]
         st2 {v15.4h, v16.4h, v17.4h}, [x30]
         st2 {v15.8h-v16.4h}, [c24]
         st2 {v0.2d-v2.2d}, [c0]
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:        st2 {v15.8h, v16.4h}, [c24]
// CHECK-ERROR:                     ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:        st2 {v0.8b, v2.8b}, [c0]
// CHECK-ERROR:                    ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:        st2 {v15.4h, v16.4h, v17.4h}, [x30]
// CHECK-ERROR:            ^
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:        st2 {v15.8h-v16.4h}, [c24]
// CHECK-ERROR:                        ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:        st2 {v0.2d-v2.2d}, [c0]
// CHECK-ERROR:            ^

         st3 {v15.8h, v16.8h, v17.4h}, [c24]
         st3 {v0.8b, v1,8b, v2.8b, v3.8b}, [c0]
         st3 {v0.8b, v2.8b, v3.8b}, [c0]
         st3 {v15.8h-v17.4h}, [c24]
         st3 {v31.4s-v2.4s}, [csp]
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:        st3 {v15.8h, v16.8h, v17.4h}, [c24]
// CHECK-ERROR:                             ^
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:        st3 {v0.8b, v1,8b, v2.8b, v3.8b}, [c0]
// CHECK-ERROR:                    ^
// CHECK-ERROR: error: registers must have the same sequential stride
// CHECK-ERROR:        st3 {v0.8b, v2.8b, v3.8b}, [c0]
// CHECK-ERROR:                    ^
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:        st3 {v15.8h-v17.4h}, [c24]
// CHECK-ERROR:                        ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:        st3 {v31.4s-v2.4s}, [csp]
// CHECK-ERROR:            ^

         st4 {v15.8h, v16.8h, v17.4h, v18.8h}, [c24]
         st4 {v0.8b, v2.8b, v3.8b, v4.8b}, [c0]
         st4 {v15.4h, v16.4h, v17.4h, v18.4h, v19.4h}, [c31]
         st4 {v15.8h-v18.4h}, [c24]
         st4 {v31.2s-v1.2s}, [c31]
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:        st4 {v15.8h, v16.8h, v17.4h, v18.8h}, [c24]
// CHECK-ERROR:                             ^
// CHECK-ERROR: error: registers must have the same sequential stride
// CHECK-ERROR:        st4 {v0.8b, v2.8b, v3.8b, v4.8b}, [c0]
// CHECK-ERROR:                    ^
// CHECK-ERROR: error: invalid number of vectors
// CHECK-ERROR:        st4 {v15.4h, v16.4h, v17.4h, v18.4h, v19.4h}, [c31]
// CHECK-ERROR:                                             ^
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:        st4 {v15.8h-v18.4h}, [c24]
// CHECK-ERROR:                        ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:        st4 {v31.2s-v1.2s}, [c31]
// CHECK-ERROR:            ^

//----------------------------------------------------------------------
// Vector post-index load/store multiple N-element structure
// (class SIMD lselem-post)
//----------------------------------------------------------------------
         ld1 {v0.16b}, [c0], #8
         ld1 {v0.8h, v1.16h}, [c0], x1
         ld1 {v0.8b, v1.8b, v2.8b, v3.8b}, [c0], #24
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR:          ld1 {v0.16b}, [c0], #8
// CHECK-ERROR:                              ^
// CHECK-ERROR: error: invalid vector kind qualifier
// CHECK-ERROR:          ld1 {v0.8h, v1.16h}, [c0], x1
// CHECK-ERROR:                      ^
// CHECK-ERROR:  error: invalid operand for instruction
// CHECK-ERROR:          ld1 {v0.8b, v1.8b, v2.8b, v3.8b}, [c0], #24
// CHECK-ERROR:                                                  ^

         ld2 {v0.16b, v1.16b}, [c0], #16
         ld3 {v5.2s, v6.2s, v7.2s}, [x1], #48
         ld4 {v31.2d, v0.2d, v1.2d, v2.1d}, [x3], x1
// CHECK-ERROR:  error: invalid operand for instruction
// CHECK-ERROR:          ld2 {v0.16b, v1.16b}, [c0], #16
// CHECK-ERROR:                                      ^
// CHECK-ERROR:  error: invalid operand for instruction
// CHECK-ERROR:          ld3 {v5.2s, v6.2s, v7.2s}, [x1], #48
// CHECK-ERROR:                                           ^
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:          ld4 {v31.2d, v0.2d, v1.2d, v2.1d}, [x3], x1
// CHECK-ERROR:                                     ^

         st1 {v0.16b}, [c0], #8
         st1 {v0.8h, v1.16h}, [c0], x1
         st1 {v0.8b, v1.8b, v2.8b, v3.8b}, [c0], #24
// CHECK-ERROR:  error: invalid operand for instruction
// CHECK-ERROR:          st1 {v0.16b}, [c0], #8
// CHECK-ERROR:                              ^
// CHECK-ERROR: error: invalid vector kind qualifier
// CHECK-ERROR:          st1 {v0.8h, v1.16h}, [c0], x1
// CHECK-ERROR:                      ^
// CHECK-ERROR:  error: invalid operand for instruction
// CHECK-ERROR:          st1 {v0.8b, v1.8b, v2.8b, v3.8b}, [c0], #24
                                                 ^

         st2 {v0.16b, v1.16b}, [c0], #16
         st3 {v5.2s, v6.2s, v7.2s}, [x1], #48
         st4 {v31.2d, v0.2d, v1.2d, v2.1d}, [x3], x1
// CHECK-ERROR:  error: invalid operand for instruction
// CHECK-ERROR:          st2 {v0.16b, v1.16b}, [c0], #16
// CHECK-ERROR:                                      ^
// CHECK-ERROR:  error: invalid operand for instruction
// CHECK-ERROR:          st3 {v5.2s, v6.2s, v7.2s}, [x1], #48
// CHECK-ERROR:                                           ^
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR:          st4 {v31.2d, v0.2d, v1.2d, v2.1d}, [x3], x1
// CHECK-ERROR:                                     ^

//------------------------------------------------------------------------------
// Load single N-element structure to all lanes of N consecutive
// registers (N = 1,2,3,4)
//------------------------------------------------------------------------------
         ld1r {x1}, [c0]
         ld2r {v31.4s, v0.2s}, [csp]
         ld3r {v0.8b, v1.8b, v2.8b, v3.8b}, [c0]
         ld4r {v31.2s, v0.2s, v1.2d, v2.2s}, [csp]
// CHECK-ERROR: error: vector register expected
// CHECK-ERROR: ld1r {x1}, [c0]
// CHECK-ERROR:       ^
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR: ld2r {v31.4s, v0.2s}, [csp]
// CHECK-ERROR:               ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR: ld3r {v0.8b, v1.8b, v2.8b, v3.8b}, [c0]
// CHECK-ERROR:      ^
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR: ld4r {v31.2s, v0.2s, v1.2d, v2.2s}, [csp]
// CHECK-ERROR:                      ^

//------------------------------------------------------------------------------
// Load/Store single N-element structure to/from one lane of N consecutive
// registers (N = 1, 2,3,4)
//------------------------------------------------------------------------------
         ld1 {v0.b}[16], [c0]
         ld2 {v15.h, v16.h}[8], [c24]
         ld3 {v31.s, v0.s, v1.s}[-1], [csp]
         ld4 {v0.d, v1.d, v2.d, v3.d}[2], [c0]
// CHECK-ERROR: vector lane must be an integer in range
// CHECK-ERROR: ld1 {v0.b}[16], [c0]
// CHECK-ERROR:            ^
// CHECK-ERROR: vector lane must be an integer in range
// CHECK-ERROR: ld2 {v15.h, v16.h}[8], [c24]
// CHECK-ERROR:                    ^
// CHECK-ERROR: error: vector lane must be an integer in range
// CHECK-ERROR: ld3 {v31.s, v0.s, v1.s}[-1], [csp]
// CHECK-ERROR:                         ^
// CHECK-ERROR: vector lane must be an integer in range
// CHECK-ERROR: ld4 {v0.d, v1.d, v2.d, v3.d}[2], [c0]
// CHECK-ERROR:                              ^

         st1 {v0.d}[16], [c0]
         st2 {v31.s, v0.s}[3], [8]
         st3 {v15.h, v16.h, v17.h}[-1], [c24]
         st4 {v0.d, v1.d, v2.d, v3.d}[2], [c0]
// CHECK-ERROR: vector lane must be an integer in range
// CHECK-ERROR: st1 {v0.d}[16], [c0]
// CHECK-ERROR:            ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR: st2 {v31.s, v0.s}[3], [8]
// CHECK-ERROR:                        ^
// CHECK-ERROR: error: vector lane must be an integer in range
// CHECK-ERROR: st3 {v15.h, v16.h, v17.h}[-1], [c24]
// CHECK-ERROR:                           ^
// CHECK-ERROR: vector lane must be an integer in range
// CHECK-ERROR: st4 {v0.d, v1.d, v2.d, v3.d}[2], [c0]
// CHECK-ERROR:                              ^

//------------------------------------------------------------------------------
// Post-index of load single N-element structure to all lanes of N consecutive
// registers (N = 1,2,3,4)
//------------------------------------------------------------------------------
         ld1r {v15.8h}, [c24], #5
         ld2r {v0.2d, v1.2d}, [c0], #7
         ld3r {v15.4h, v16.4h, v17.4h}, [c24], #1
         ld4r {v31.1d, v0.1d, v1.1d, v2.1d}, [csp], sp
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR: ld1r {v15.8h}, [c24], #5
// CHECK-ERROR:                       ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR: ld2r {v0.2d, v1.2d}, [c0], #7
// CHECK-ERROR:                            ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR: ld3r {v15.4h, v16.4h, v17.4h}, [c24], #1
// CHECK-ERROR:                                       ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR: ld4r {v31.1d, v0.1d, v1.1d, v2.1d}, [csp], sp
// CHECK-ERROR:                                           ^

//------------------------------------------------------------------------------
// Post-index of Load/Store single N-element structure to/from one lane of N
// consecutive registers (N = 1, 2,3,4)
//------------------------------------------------------------------------------
         ld1 {v0.b}[0], [c0], #2
         ld2 {v15.h, v16.h}[0], [c24], #3
         ld3 {v31.s, v0.s, v1.d}[0], [csp], x9
         ld4 {v0.d, v1.d, v2.d, v3.d}[1], [c0], #24
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR: ld1 {v0.b}[0], [c0], #2
// CHECK-ERROR:                      ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR: ld2 {v15.h, v16.h}[0], [c24], #3
// CHECK-ERROR:                               ^
// CHECK-ERROR: error: mismatched register size suffix
// CHECK-ERROR: ld3 {v31.s, v0.s, v1.d}[0], [csp], x9
// CHECK-ERROR:                      ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR: ld4 {v0.d, v1.d, v2.d, v3.d}[1], [c0], #24
// CHECK-ERROR:                                        ^

         st1 {v0.d}[0], [c0], #7
         st2 {v31.s, v0.s}[0], [csp], #6
         st3 {v15.h, v16.h, v17.h}[0], [c24], #8
         st4 {v0.b, v1.b, v2.b, v3.b}[1], [c0], #1
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR: st1 {v0.d}[0], [c0], #7
// CHECK-ERROR:                      ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR: st2 {v31.s, v0.s}[0], [csp], #6
// CHECK-ERROR:                             ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR: st3 {v15.h, v16.h, v17.h}[0], [c24], #8
// CHECK-ERROR:                                      ^
// CHECK-ERROR: error: invalid operand for instruction
// CHECK-ERROR: st4 {v0.b, v1.b, v2.b, v3.b}[1], [c0], #1
// CHECK-ERROR:                                        ^
