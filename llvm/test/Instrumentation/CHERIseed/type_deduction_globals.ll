; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

; CHECK-LABEL: %struct.s1 = type { %struct.s2* }
%struct.s1 = type { %struct.s2* }

; CHECK-LABEL: %struct.s2 = type { %struct.s1* }
%struct.s2 = type { %struct.s1* }

; CHECK: %struct.nocap = type { i8* }
%struct.nocap = type { i8* }

; CHECK: %struct.hascap = type { %__cheriseed_cap_t }
%struct.hascap = type { i8 addrspace(200)* }

; Make sure there is no infinite recursion in Type mapping.
; CHECK-NOT: @no_recurse.old
; CHECK-LABEL: @no_recurse = global %struct.s1 zeroinitializer, align 8
@no_recurse = global %struct.s1 zeroinitializer, align 8

; CHECK-NOT: @int.old
; CHECK:     @int = global i32 0, comdat, align 4
$int = comdat any
@int = global i32 0, comdat, align 4

; CHECK-NOT: @ext_int.old
; CHECK:     @ext_int = external global i32, align 4
@ext_int = external global i32, align 4

; CHECK-NOT: @ptr.old
; CHECK:     @ptr = global i32* null, align 8
@ptr = global i32* null, align 8

; CHECK-NOT: @ptr_array.old
; CHECK:     @ptr_array = global [1 x i32**] [i32** @ptr], align 8
@ptr_array = global [1 x i32**] [i32** @ptr], align 8

; CHECK-NOT: @ext_ptr.old
; CHECK:     @ext_ptr = external global i32*, align 8
@ext_ptr = external global i32*, align 8

; CHECK-NOT: @ptr_nocap.old
; CHECK:     @ptr_nocap = global %struct.nocap* null, align 8
@ptr_nocap = global %struct.nocap* null, align 8

; CHECK-NOT: @ptr_hascap.old
; CHECK:     @ptr_hascap = global %struct.hascap* null, align 8
@ptr_hascap = global %struct.hascap* null, align 8

; CHECK-NOT: @cap.old
; CHECK:     @cap = global %__cheriseed_cap_t zeroinitializer, align 16
@cap = global i32 addrspace(200)* null, align 16

; CHECK-NOT:  @cap_array.old
; CHECK:      @cap_array = global [3 x %__cheriseed_cap_t*] [
; CHECK-SAME:   %__cheriseed_cap_t* null, %__cheriseed_cap_t* @cap,
; CHECK-SAME:   %__cheriseed_cap_t* null], align 8
@cap_array = global [3 x i32 addrspace(200)**] [
  i32 addrspace(200)** null, i32 addrspace(200)** @cap,
  i32 addrspace(200)** null], align 8

; CHECK-NOT: @ext_cap.old
; CHECK:     @ext_cap = external global %__cheriseed_cap_t, align 16
@ext_cap = external global i32 addrspace(200)*, align 16

; CHECK-NOT: @ptr_to_cap_null.old
; CHECK:     @ptr_to_cap_null = global %__cheriseed_cap_t* null, align 8
@ptr_to_cap_null = global i32 addrspace(200)** null, align 8

; CHECK-NOT: @ptr_to_cap.old
; CHECK:     @ptr_to_cap = global %__cheriseed_cap_t* @cap, align 8
@ptr_to_cap = global i32 addrspace(200)** @cap, align 8

; CHECK-NOT: @ext_ptr_to_cap.old
; CHECK:     @ext_ptr_to_cap = external global %__cheriseed_cap_t*, align 8
@ext_ptr_to_cap = external global i32 addrspace(200)**, align 8

; CHECK-NOT: @cap_to_cap_null.old
; CHECK:     @cap_to_cap_null = global %__cheriseed_cap_t zeroinitializer, align 16
@cap_to_cap_null = global i32 addrspace(200)* addrspace(200)* null, align 16

; CHECK-NOT: @cap_to_cap.old
; CHECK:     @cap_to_cap = global %__cheriseed_cap_t zeroinitializer, align 16
@cap_to_cap = global i32 addrspace(200)* addrspace(200)* addrspacecast (
  i32 addrspace(200)** @cap to i32 addrspace(200)* addrspace(200)*), align 16

; CHECK-NOT: @ext_cap_to_cap.old
; CHECK:     @ext_cap_to_cap = external global %__cheriseed_cap_t, align 16
@ext_cap_to_cap = external global i32 addrspace(200)* addrspace(200)*, align 16

; CHECK-NOT: @int_as200.old
; CHECK:     @__cheriseed_shadowed_global_int_as200 = global i32 0, comdat($int_as200), align 4
; CHECK:     @int_as200 = global %__cheriseed_cap_t zeroinitializer, comdat, align 16
$int_as200 = comdat any
@int_as200 = addrspace(200) global i32 0, comdat, align 4

; CHECK-NOT: @ext_int_as200.old
; CHECK:     @ext_int_as200 = external global %__cheriseed_cap_t, align 16
@ext_int_as200 = external addrspace(200) global i32, align 4

; CHECK-NOT: @ptr_as200.old
; CHECK:     @__cheriseed_shadowed_global_ptr_as200 = global i32* null, align 8
; CHECK:     @ptr_as200 = global %__cheriseed_cap_t zeroinitializer, align 16
@ptr_as200 = addrspace(200) global i32* null, align 8

; CHECK-NOT: @ext_ptr_as200.old
; CHECK:     @ext_ptr_as200 = external global %__cheriseed_cap_t, align 16
@ext_ptr_as200 = external addrspace(200) global i32*, align 8

; CHECK-NOT: @cap_as200.old
; CHECK:     @__cheriseed_shadowed_global_cap_as200 = global %__cheriseed_cap_t zeroinitializer, align 16
; CHECK:     @cap_as200 = global %__cheriseed_cap_t zeroinitializer, align 16
@cap_as200 = addrspace(200) global i32 addrspace(200)* null, align 16

; CHECK-NOT: @ext_cap_as200.old
; CHECK:     @ext_cap_as200 = external global %__cheriseed_cap_t, align 16
@ext_cap_as200 = external addrspace(200) global i32 addrspace(200)*, align 16

; CHECK-NOT: @cap_to_cap_null_as200.old
; CHECK:     @__cheriseed_shadowed_global_cap_to_cap_null_as200 = global %__cheriseed_cap_t zeroinitializer, align 16
; CHECK:     @cap_to_cap_null_as200 = global %__cheriseed_cap_t zeroinitializer, align 16
@cap_to_cap_null_as200 = addrspace(200) global i32 addrspace(200)* addrspace(200)* null, align 16

; CHECK-NOT: @cap_to_cap_as200.old
; CHECK:     @__cheriseed_shadowed_global_cap_to_cap_as200 = global %__cheriseed_cap_t zeroinitializer, align 16
; CHECK:     @cap_to_cap_as200 = global %__cheriseed_cap_t zeroinitializer, align 16
@cap_to_cap_as200 = addrspace(200) global i32 addrspace(200)* addrspace(200)* @cap_as200, align 16

; CHECK-NOT: @ext_cap_to_cap_as200.old
; CHECK:     @ext_cap_to_cap_as200 = external global %__cheriseed_cap_t, align 16
@ext_cap_to_cap_as200 = external addrspace(200) global i32 addrspace(200)* addrspace(200)*, align 16

; ------------------------------------------------------------------------------
; Common helper struct definitions for more complex cases below.
; An 'i8' is often added as the last member of types purely so that the whole
; declaration is kept and is not truncated to 'zeroinitializer'.

%com.nocap.s = type { i8*, i8 }
%com.hascap.s = type { i8 addrspace(200)*, i8 }

; ------------------------------------------------------------------------------
; Test handling of pointers to Types without capabilities.

%case.1.s = type {
  %com.nocap.s,
  %com.nocap.s*,
  %com.nocap.s*
}
; CHECK-LABEL: @case.1 = global %case.1.s {
@case.1 = global %case.1.s {
; CHECK-SAME:  %com.nocap.s zeroinitializer,
  %com.nocap.s zeroinitializer,
; CHECK-SAME:  %com.nocap.s* null,
  %com.nocap.s* null,
; CHECK-SAME:  %com.nocap.s* @case.1.g }
  %com.nocap.s* @case.1.g
}
@case.1.g = global %com.nocap.s zeroinitializer

; ------------------------------------------------------------------------------
; Test handling of pointers to Types with capabilities.

%case.2.s = type {
  %com.hascap.s,
  %com.hascap.s*,
  %com.hascap.s*
}
; CHECK-LABEL: @case.2 = global %case.2.s {
@case.2 = global %case.2.s {
; CHECK-SAME:  %com.hascap.s zeroinitializer,
  %com.hascap.s zeroinitializer,
; CHECK-SAME:  %com.hascap.s* null,
  %com.hascap.s* null,
; CHECK-SAME:  %com.hascap.s* @case.2.g }
  %com.hascap.s* @case.2.g
}

@case.2.g = global %com.hascap.s zeroinitializer

; ------------------------------------------------------------------------------
; Test handling of capabilities to Types without capabilities.

%case.3.s = type {
  %com.nocap.s addrspace(200)*,
  %com.nocap.s addrspace(200)*,
  i8
}
; CHECK-LABEL: @__cheriseed_shadowed_global_case.3 = global %case.3.s {
$case.3 = comdat any
@case.3 = addrspace(200) global %case.3.s {
; CHECK-SAME:  %__cheriseed_cap_t zeroinitializer,
  %com.nocap.s addrspace(200)* null,
; CHECK-SAME:  %__cheriseed_cap_t zeroinitializer,
  %com.nocap.s addrspace(200)* @case.3.g,
; CHECK-SAME:  i8 3 }, comdat
  i8 3
}, comdat
@case.3.g = addrspace(200) global %com.nocap.s zeroinitializer

; ------------------------------------------------------------------------------
; Test handling of capabilities to Types with capabilities.

%case.4.s = type {
  %com.hascap.s addrspace(200)*,
  %com.hascap.s addrspace(200)*,
  i8
}
; CHECK-LABEL: @__cheriseed_shadowed_global_case.4 = global %case.4.s {
@case.4 = addrspace(200) global %case.4.s {
; CHECK-SAME:  %__cheriseed_cap_t zeroinitializer,
  %com.hascap.s addrspace(200)* null,
; CHECK-SAME:  %__cheriseed_cap_t zeroinitializer,
  %com.hascap.s addrspace(200)* @case.4.g,
; CHECK-SAME:  i8 4 }
  i8 4
}
@case.4.g = addrspace(200) global %com.hascap.s zeroinitializer

; ------------------------------------------------------------------------------
; Test handling of nested structs.

%case.5.s = type {
  %com.nocap.s,
  %com.hascap.s
}
; CHECK-LABEL: @case.5 = global %case.5.s {
@case.5 = global %case.5.s {
; CHECK-SAME:  %com.nocap.s {
  %com.nocap.s {
; CHECK-SAME:  i8* @case.5.g1
    i8* @case.5.g1,
; CHECK-SAME:  i8 1 },
    i8 1
  },
; CHECK-SAME:  %com.hascap.s {
  %com.hascap.s {
; CHECK-SAME:  %__cheriseed_cap_t zeroinitializer,
    i8 addrspace(200)* @case.5.g2,
; CHECK-SAME:  i8 2 }
    i8 2
  }
}

@case.5.g1 = global i8 3
@case.5.g2 = addrspace(200) global i8 5

; ------------------------------------------------------------------------------
; Test addrspacecast

%case.6.s = type { i8, i8 addrspace(200)*}

; CHECK-LABEL: @case.6 = global %case.6.s {
@case.6 = global %case.6.s {
; CHECK-SAME:  i8 1,
  i8 1,
; CHECK-SAME:  %__cheriseed_cap_t zeroinitializer }
  i8 addrspace(200)* addrspacecast (i8* @case.6.g to i8 addrspace(200)*)
}

@case.6.g = global i8 6

; ------------------------------------------------------------------------------
; Test bitcast

; CHECK-LABEL: @case.7 = global %com.nocap.s {
@case.7 = global %com.nocap.s {
; CHECK-SAME:  i8* bitcast (i32* @case.7.g to i8*),
  i8* bitcast (i32* @case.7.g to i8*),
; CHECK-SAME:  i8 1 }
  i8 1
}
@case.7.g = global i32 7

; ------------------------------------------------------------------------------
; Test pointers and capabilitites to functions.

%case.8.s = type {
  void ()*,
  void ()*,
  void () addrspace(200)*,
  void () addrspace(200)*
}
; CHECK-LABEL: @case.8 = global %case.8.s {
@case.8 = global %case.8.s {
; CHECK-SAME:  void ()* null,
  void ()* null,
; CHECK-SAME:  void ()* @case.8.f.1,
  void ()* @case.8.f.1,
; CHECK-SAME:  %__cheriseed_cap_t zeroinitializer,
  void () addrspace(200)* null,
; CHECK-SAME:  %__cheriseed_cap_t zeroinitializer }
  void () addrspace(200)* @case.8.f.2
}
declare void @case.8.f.1();
declare void @case.8.f.2() addrspace(200);

; ------------------------------------------------------------------------------
; Test ArrayType

%case.9.s = type {
  [2 x i8*],
  [2 x i8 addrspace(200)*]
}
; CHECK-LABEL: @case.9 = global %case.9.s {
@case.9 = global %case.9.s {
; CHECK-SAME:  [2 x i8*] [i8* null, i8* @case.9.g1]
  [2 x i8*] [i8* null, i8* @case.9.g1],
; CHECK-SAME:  [2 x %__cheriseed_cap_t] zeroinitializer }
  [2 x i8 addrspace(200)*] [i8 addrspace(200)* null, i8 addrspace(200)* @case.9.g2]
}

@case.9.g1 = global i8 9
@case.9.g2 = addrspace(200) global i8 10

; ------------------------------------------------------------------------------
; Test VectorType

%case.10.s = type {
  <2 x i8*>
; FIXME: CHERIseed
; This is not yet possible, when replaced with __cheriseed_cap_t it results
; in an error.
;  <2 x i8 addrspace(200)*>
}
; CHECK-LABEL: @case.10 = global %case.10.s {
@case.10 = global %case.10.s {
; CHECK-SAME:  <2 x i8*> <i8* null, i8* @case.10.g> }
  <2 x i8*> <i8* null, i8* @case.10.g>
;  <2 x i8 addrspace(200)*> zeroinitializer
}
@case.10.g = global i8 10

; ------------------------------------------------------------------------------
; Test ArrayType in Pure-cap

@case.11.g1 = addrspace(200) global [2 x i64] zeroinitializer, align 8
; CHECK-LABEL: @__cheriseed_shadowed_global_case.11 = global %__cheriseed_cap_t zeroinitializer, align 16
@case.11 = addrspace(200) global i64 addrspace(200)* getelementptr inbounds (
  [2 x i64], [2 x i64] addrspace(200)* @case.11.g1, i64 0, i64 1), align 8

; ------------------------------------------------------------------------------
; Test alias use

%case.12.s = type { i8* }
; CHECK-LABEL: @case.12 = global %case.12.s { i8* @case.12.a }
@case.12 = global %case.12.s {
  i8* @case.12.a
}

@case.12.g = global i8 11
@case.12.a = alias i8, i8* @case.12.g

; ------------------------------------------------------------------------------
; Test alias use 2

@case.13.g = global i8 11
; CHECK-LABEL: @case.13 = global i8* @case.13.a
@case.13 = global i8* @case.13.a
@case.13.a = alias i8, i8* @case.13.g

; ------------------------------------------------------------------------------
; Yet another global case

@case.14.g = addrspace(200) global i32 addrspace(200)* null, align 16
; CHECK-LABEL: @__cheriseed_shadowed_global_case.14 = global %__cheriseed_cap_t zeroinitializer, align 16
@case.14 = addrspace(200) global i8 addrspace(200)* bitcast (
  i32 addrspace(200)* addrspace(200)* @case.14.g to i8 addrspace(200)*), align 16

; ------------------------------------------------------------------------------
; Test bitcast 1.

%case.15.s = type { i32, i8 addrspace(200)* }
@case.15.g = global { i32, i8 addrspace(200)* } { i32 42, i8 addrspace(200)* null }
; CHECK-LABEL: @case.15 = constant %case.15.s* bitcast (%{{[0-9]+}}* @case.15.g to %case.15.s*)
@case.15 = constant %case.15.s* bitcast ({ i32, i8 addrspace(200)* }* @case.15.g to %case.15.s*)

; ------------------------------------------------------------------------------
; Test bitcast 2.

%case.16.s = type { i8 addrspace(200)* }
@case.16.g = global %case.16.s { i8 addrspace(200)* null }
; CHECK-LABEL: @case.16 = global i8* bitcast (%case.16.s* @case.16.g to i8*)
@case.16 = global i8* bitcast (%case.16.s* @case.16.g to i8*)

; ------------------------------------------------------------------------------
; Test bitcast 3.

%case.17.s1 = type { i8 addrspace(200)* }
%case.17.s2 = type { i8* }
@case.17.g = global %case.17.s1 { i8 addrspace(200)* null }
; CHECK-LABEL: @case.17 = global %case.17.s2 { i8* bitcast (%case.17.s1* @case.17.g to i8*) }
@case.17 = global %case.17.s2 { i8* bitcast (%case.17.s1* @case.17.g to i8*) }

; ------------------------------------------------------------------------------
; Test bitcast 4.

@case.18.g = global i32 42
; CHECK-LABEL: @case.18 = global { i8, i8* } { i8 1, i8* bitcast (i32* @case.18.g to i8*) }
@case.18 = global { i8, i8* } { i8 1, i8* bitcast (i32* @case.18.g to i8*) }

; ------------------------------------------------------------------------------
; Regression test for nested ConstantExpr values.

; CHECK-LABEL: @case.19 = global %__cheriseed_cap_t zeroinitializer, align 16
@case.19 = addrspace(200) global i32 addrspace(200)* addrspace(200)* bitcast (
  i8 addrspace(200)* getelementptr (i8, i8 addrspace(200)* bitcast (
    [1 x i32 addrspace(200)*] addrspace(200)* @case.19.g1 to i8 addrspace(200)*), i64 112)
    to i32 addrspace(200)* addrspace(200)*), align 16
@case.19.g1 = addrspace(200) global [1 x i32 addrspace(200)*] [i32 addrspace(200)* @case.19.g2], align 16
@case.19.g2 = addrspace(200) global i32 1, align 4

; ------------------------------------------------------------------------------
; Regression for inttoptr cast. This happens in C++ vtables, for instance.

; CHECK-LABEL: @case.20 = global %__cheriseed_cap_t zeroinitializer, align 16
@case.20 = global i8 addrspace(200)*  inttoptr (i64 32 to i8 addrspace(200)*)

; ------------------------------------------------------------------------------
; Regression for global constant where 'constant' should be preserved.

%case.21.s = type { i8 addrspace(200)* }

; CHECK-LABEL: @__cheriseed_shadowed_global_case.21 = constant %case.21.s zeroinitializer
@case.21 = addrspace(200) constant %case.21.s { i8 addrspace(200)* null }

; ------------------------------------------------------------------------------
; Regression for global constant where 'constant' should be removed.

%case.22.s = type { i8 addrspace(200)* }

; CHECK-LABEL: @__cheriseed_shadowed_global_case.22 = global %case.22.s zeroinitializer
@case.22 = addrspace(200) constant %case.22.s { i8 addrspace(200)* @case.22.g }

@case.22.g = addrspace(200) global i8 0

; ------------------------------------------------------------------------------

; Checking for Global Initializer variable.

; CHECK-LABEL: @"__cheriseed_inits_<stdin>" = internal global [27 x %__cheriseed_initializer_t] [
; CHECK-SAME:    {
; CHECK-SAME:      i64 0, i64 0, i64 0, i32 0, void ()* @__cheriseed_initializer_cap_to_cap
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @int_as200 to i64),
; CHECK-SAME:      i64 ptrtoint (i32* @__cheriseed_shadowed_global_int_as200 to i64),
; CHECK-SAME:      i64 4, i32 2, void ()* null
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @ptr_as200 to i64),
; CHECK-SAME:      i64 ptrtoint (i32** @__cheriseed_shadowed_global_ptr_as200 to i64),
; CHECK-SAME:      i64 8, i32 2, void ()* null
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @cap_as200 to i64),
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @__cheriseed_shadowed_global_cap_as200 to i64),
; CHECK-SAME:      i64 16, i32 2, void ()* null
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @cap_to_cap_null_as200 to i64),
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @__cheriseed_shadowed_global_cap_to_cap_null_as200 to i64),
; CHECK-SAME:      i64 16, i32 2, void ()* null
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @cap_to_cap_as200 to i64),
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @__cheriseed_shadowed_global_cap_to_cap_as200 to i64),
; CHECK-SAME:      i64 16, i32 2, void ()* @__cheriseed_initializer_cap_to_cap_as200
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @case.3 to i64),
; CHECK-SAME:      i64 ptrtoint (%case.3.s* @__cheriseed_shadowed_global_case.3 to i64), i64 48, i32 2,
; CHECK-SAME:      void ()* @__cheriseed_initializer_case.3
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @case.3.g to i64),
; CHECK-SAME:      i64 ptrtoint (%com.nocap.s* @__cheriseed_shadowed_global_case.3.g to i64),
; CHECK-SAME:      i64 16, i32 2, void ()* null
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @case.4 to i64),
; CHECK-SAME:      i64 ptrtoint (%case.4.s* @__cheriseed_shadowed_global_case.4 to i64),
; CHECK-SAME:      i64 48, i32 2, void ()* @__cheriseed_initializer_case.4
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @case.4.g to i64),
; CHECK-SAME:      i64 ptrtoint (%com.hascap.s* @__cheriseed_shadowed_global_case.4.g to i64),
; CHECK-SAME:      i64 32, i32 2, void ()* null
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 0, i64 0, i64 0, i32 0, void ()* @__cheriseed_initializer_case.5
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @case.5.g2 to i64),
; CHECK-SAME:      i64 ptrtoint (i8* @__cheriseed_shadowed_global_case.5.g2 to i64),
; CHECK-SAME:      i64 1, i32 2, void ()* null
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 0, i64 0, i64 0, i32 0, void ()* @__cheriseed_initializer_case.6
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 0, i64 0, i64 0, i32 0, void ()* @__cheriseed_initializer_case.8
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 0, i64 0, i64 0, i32 0, void ()* @__cheriseed_initializer_case.9
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @case.9.g2 to i64),
; CHECK-SAME:      i64 ptrtoint (i8* @__cheriseed_shadowed_global_case.9.g2 to i64),
; CHECK-SAME:      i64 1, i32 2, void ()* null
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @case.11.g1 to i64),
; CHECK-SAME:      i64 ptrtoint ([2 x i64]* @__cheriseed_shadowed_global_case.11.g1 to i64),
; CHECK-SAME:      i64 16, i32 2, void ()* null
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @case.11 to i64),
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @__cheriseed_shadowed_global_case.11 to i64),
; CHECK-SAME:      i64 16, i32 2, void ()* @__cheriseed_initializer_case.11
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @case.14.g to i64),
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @__cheriseed_shadowed_global_case.14.g to i64),
; CHECK-SAME:      i64 16, i32 2, void ()* null
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @case.14 to i64),
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @__cheriseed_shadowed_global_case.14 to i64),
; CHECK-SAME:      i64 16, i32 2, void ()* @__cheriseed_initializer_case.14
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @case.19 to i64),
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @__cheriseed_shadowed_global_case.19 to i64),
; CHECK-SAME:      i64 16, i32 2, void ()* @__cheriseed_initializer_case.19
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @case.19.g1 to i64),
; CHECK-SAME:      i64 ptrtoint ([1 x %__cheriseed_cap_t]* @__cheriseed_shadowed_global_case.19.g1 to i64),
; CHECK-SAME:      i64 16, i32 2, void ()* @__cheriseed_initializer_case.19.g1
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @case.19.g2 to i64),
; CHECK-SAME:      i64 ptrtoint (i32* @__cheriseed_shadowed_global_case.19.g2 to i64),
; CHECK-SAME:      i64 4, i32 2, void ()* null
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 0, i64 0, i64 0, i32 0, void ()* @__cheriseed_initializer_case.20
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @case.21 to i64),
; CHECK-SAME:      i64 ptrtoint (%case.21.s* @__cheriseed_shadowed_global_case.21 to i64),
; CHECK-SAME:      i64 16, i32 42, void ()* null
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @case.22 to i64),
; CHECK-SAME:      i64 ptrtoint (%case.22.s* @__cheriseed_shadowed_global_case.22 to i64),
; CHECK-SAME:      i64 16, i32 42, void ()* @__cheriseed_initializer_case.22
; CHECK-SAME:    },
; CHECK-SAME:    {
; CHECK-SAME:      i64 ptrtoint (%__cheriseed_cap_t* @case.22.g to i64),
; CHECK-SAME:      i64 ptrtoint (i8* @__cheriseed_shadowed_global_case.22.g to i64),
; CHECK-SAME:      i64 1, i32 2, void ()* null
; CHECK-SAME:    }
; CHECK-SAME:  ],  section "__cheriseed_initializers", align 8

; CHECK-LABEL: @llvm.used = appending global [1 x i8*] [
; CHECK-SAME:    i8* bitcast ([27 x %__cheriseed_initializer_t]*
; CHECK-SAME:    @"__cheriseed_inits_<stdin>" to i8*)
; CHECK-SAME:  ], section "llvm.metadata"

; ------------------------------------------------------------------------------
; Check initializers

; CHECK-NOT:   @__cheriseed_initializer_no_recurse()
; CHECK-NOT:   @__cheriseed_initializer_int()
; CHECK-NOT:   @__cheriseed_initializer_ptr()
; CHECK-NOT:   @__cheriseed_initializer_ptr_array()
; CHECK-NOT:   @__cheriseed_initializer_ptr_nocap()
; CHECK-NOT:   @__cheriseed_initializer_ptr_hascap()
; CHECK-NOT:   @__cheriseed_initializer_cap()
; CHECK-NOT:   @__cheriseed_initializer_cap_array()
; CHECK-NOT:   @__cheriseed_initializer_ptr_to_cap_null()
; CHECK-NOT:   @__cheriseed_initializer_ptr_to_cap()
; CHECK-NOT:   @__cheriseed_initializer_cap_to_cap_null()

; CHECK-LABEL: define internal void @__cheriseed_initializer_cap_to_cap() {
; CHECK-NEXT:    %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:    %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:    %2 = call %__cheriseed_cap_t* @__cheriseed_ddc_get(%__cheriseed_cap_t* %1)
; CHECK-NEXT:    %3 = call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %2,
; CHECK-SAME:      %__cheriseed_cap_t* %2, i64 ptrtoint (%__cheriseed_cap_t* @cap to i64))
; CHECK-NEXT:    %4 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset
; CHECK-SAME:      %__cheriseed_cap_t* @cap_to_cap, %__cheriseed_cap_t* %3, i64 0)
; CHECK-NEXT:    ret void
; CHECK-NEXT:  }

; CHECK-LABEL: define internal void @__cheriseed_initializer_cap_to_cap_as200() {
; CHECK-NEXT:    %1 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* @__cheriseed_shadowed_global_cap_to_cap_as200,
; CHECK-SAME:      %__cheriseed_cap_t* @cap_as200, i64 0)
; CHECK-NEXT:    ret void
; CHECK-NEXT:  }

; CHECK-NOT:   @__cheriseed_initializer_int_as200()
; CHECK-NOT:   @__cheriseed_initializer_ptr_as200()
; CHECK-NOT:   @__cheriseed_initializer_cap_as200()
; CHECK-NOT:   @__cheriseed_initializer_cap_to_cap_null_as200()

; ------------------------------------------------------------------------------

; CHECK-NOT:   @__cheriseed_initializer_case.1()

; ------------------------------------------------------------------------------

; CHECK-NOT:   @__cheriseed_initializer_case.2()
; CHECK-NOT:   @__cheriseed_initializer_case.2.g()

; ------------------------------------------------------------------------------

; CHECK-LABEL: define internal void @__cheriseed_initializer_case.3() comdat($case.3) {
; CHECK-NEXT:    %1 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* getelementptr inbounds (%case.3.s,
; CHECK-SAME:      %case.3.s* @__cheriseed_shadowed_global_case.3, i32 0, i32 1),
; CHECK-SAME:      %__cheriseed_cap_t* @case.3.g, i64 0)
; CHECK-NEXT:    ret void
; CHECK-NEXT:  }

; ------------------------------------------------------------------------------

; CHECK-LABEL: define internal void @__cheriseed_initializer_case.4() {
; CHECK-NEXT:    %1 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* getelementptr inbounds (%case.4.s,
; CHECK-SAME:      %case.4.s* @__cheriseed_shadowed_global_case.4, i32 0, i32 1),
; CHECK-SAME:      %__cheriseed_cap_t* @case.4.g, i64 0)
; CHECK-NEXT:    ret void
; CHECK-NEXT:  }

; ------------------------------------------------------------------------------

; CHECK-LABEL: define internal void @__cheriseed_initializer_case.5() {
; CHECK-NEXT:    %1 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* getelementptr inbounds (%case.5.s,
; CHECK-SAME:      %case.5.s* @case.5, i32 0, i32 1, i32 0),
; CHECK-SAME:      %__cheriseed_cap_t* @case.5.g2, i64 0)
; CHECK-NEXT:    ret void
; CHECK-NEXT:  }

; CHECK-NOT:   @__cheriseed_initializer_case.5.g1()
; CHECK-NOT:   @__cheriseed_initializer_case.5.g2()

; ------------------------------------------------------------------------------

; CHECK-LABEL: define internal void @__cheriseed_initializer_case.6() {
; CHECK-NEXT:    %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:    %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:    %2 = call %__cheriseed_cap_t* @__cheriseed_ddc_get(%__cheriseed_cap_t* %1)
; CHECK-NEXT:    %3 = call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %2,
; CHECK-SAME:      %__cheriseed_cap_t* %2, i64 ptrtoint (i8* @case.6.g to i64))
; CHECK-NEXT:    %4 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* getelementptr inbounds (%case.6.s,
; CHECK-SAME:      %case.6.s* @case.6, i32 0, i32 1), %__cheriseed_cap_t* %3, i64 0)
; CHECK-NEXT:    ret void
; CHECK-NEXT:  }

; ------------------------------------------------------------------------------

; CHECK-NOT:  @__cheriseed_initializer_case.7()

; ------------------------------------------------------------------------------

; CHECK-LABEL: define internal void @__cheriseed_initializer_case.8() {
; CHECK-NEXT:    %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:    %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:    %2 = call %__cheriseed_cap_t* @__cheriseed_generic_cap_init(
; CHECK-SAME:      %__cheriseed_cap_t* %1,
; CHECK-SAME:      i64 ptrtoint (void ()* @case.8.f.2 to i64),
; CHECK-SAME:      i64 1,
; CHECK-SAME:      i32 60)
; CHECK-NEXT:    %3 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t*
; CHECK-SAME:      getelementptr inbounds (%case.8.s, %case.8.s* @case.8, i32 0, i32 3),
; CHECK-SAME:      %__cheriseed_cap_t* %2, i64 0)
; CHECK-NEXT:    ret void
; CHECK-NEXT:  }

; ------------------------------------------------------------------------------

; CHECK-LABEL: define internal void @__cheriseed_initializer_case.9() {
; CHECK-NEXT:    %1 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* getelementptr inbounds (%case.9.s,
; CHECK-SAME:      %case.9.s* @case.9, i32 0, i32 1, i64 1), %__cheriseed_cap_t* @case.9.g2, i64 0)
; CHECK-NEXT:    ret void
; CHECK-NEXT:  }

; ------------------------------------------------------------------------------

; CHECK-NOT:   @__cheriseed_initializer_case.10()

; ------------------------------------------------------------------------------

; CHECK-LABEL: define internal void @__cheriseed_initializer_case.11() {
; CHECK-NEXT:    %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:    %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:    %2 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* %1, %__cheriseed_cap_t* @case.11.g1, i64 8)
; CHECK-NEXT:    %3 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* @__cheriseed_shadowed_global_case.11, %__cheriseed_cap_t* %2, i64 0)
; CHECK-NEXT:    ret void
; CHECK-NEXT:  }

; ------------------------------------------------------------------------------

; CHECK-NOT:   @__cheriseed_initializer_case.12()

; ------------------------------------------------------------------------------

; CHECK-NOT:   @__cheriseed_initializer_case.13()

; ------------------------------------------------------------------------------

; CHECK-LABEL: define internal void @__cheriseed_initializer_case.14() {
; CHECK-NEXT:    %1 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* @__cheriseed_shadowed_global_case.14,
; CHECK-SAME:      %__cheriseed_cap_t* @case.14.g, i64 0)
; CHECK-NEXT:    ret void
; CHECK-NEXT:  }

; ------------------------------------------------------------------------------

; CHECK-NOT:   @__cheriseed_initializer_case.15()

; ------------------------------------------------------------------------------

; CHECK-NOT:   @__cheriseed_initializer_case.16()

; ------------------------------------------------------------------------------

; CHECK-NOT:   @__cheriseed_initializer_case.17()

; ------------------------------------------------------------------------------

; CHECK-NOT:   @__cheriseed_initializer_case.18()

; ------------------------------------------------------------------------------

; CHECK-LABEL: define internal void @__cheriseed_initializer_case.19() {
; CHECK-NEXT:    %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:    %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:    %2 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* %1, %__cheriseed_cap_t* @case.19.g1, i64 112)
; CHECK-NEXT:    %3 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* @__cheriseed_shadowed_global_case.19, %__cheriseed_cap_t* %2, i64 0)
; CHECK-NEXT:    ret void
; CHECK-NEXT:  }

; CHECK-LABEL: define internal void @__cheriseed_initializer_case.19.g1() {
; CHECK-NEXT:    %1 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* getelementptr inbounds ([1 x %__cheriseed_cap_t],
; CHECK-SAME:      [1 x %__cheriseed_cap_t]* @__cheriseed_shadowed_global_case.19.g1, i32 0, i64 0),
; CHECK-SAME:      %__cheriseed_cap_t* @case.19.g2, i64 0)
; CHECK-NEXT:    ret void
; CHECK-NEXT:  }

; ------------------------------------------------------------------------------

; CHECK-LABEL: define internal void @__cheriseed_initializer_case.20() {
; CHECK-NEXT:    %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:    %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:    %2 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* %1, %__cheriseed_cap_t* null, i64 32)
; CHECK-NEXT:    %3 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* @case.20, %__cheriseed_cap_t* %2, i64 0)
; CHECK-NEXT:    ret void
; CHECK-NEXT:  }

; ------------------------------------------------------------------------------

; CHECK-LABEL: define internal void @__cheriseed_initializer_case.22() {
; CHECK-NEXT:    %1 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:     %__cheriseed_cap_t* getelementptr inbounds (
; CHECK-SAME:       %case.22.s, %case.22.s* @__cheriseed_shadowed_global_case.22, i32 0, i32 0),
; CHECK-SAME:     %__cheriseed_cap_t* @case.22.g, i64 0)
; CHECK-NEXT:    ret void
; CHECK-NEXT:  }

; ------------------------------------------------------------------------------
