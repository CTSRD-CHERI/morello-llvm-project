; RUN: llc -o - -mtriple=aarch64-none-elf -mattr=+morello %s
; Test that this compiles without any errors

@f = addrspace(200) global ptr addrspace(200) addrspacecast (ptr @_none_mbrtowc to ptr addrspace(200)), align 32

; Function Attrs: noinline nounwind
define void @_none_mbrtowc() #0 {
entry:
  ret void
}
