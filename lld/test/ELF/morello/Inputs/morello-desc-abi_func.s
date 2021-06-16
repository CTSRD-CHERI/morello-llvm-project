  .data
funcptr1:
  .capinit func
  .xword 0
  .xword 4
  .size funcptr1, 16

funcptr2:
  .capinit func
  .xword 0
  .xword 4
  .size funcptr2, 16

ifuncptr:
  .capinit ifunc
  .xword 0
  .xword 4
  .size ifuncptr, 16

  .global func
  .type func,%function
  .section function,"ax",%progbits
func:
  ret
  .size func, .-func

  .globl ifunc
  .type ifunc,STT_GNU_IFUNC
  .section ifunction,"ax",%progbits
ifunc:
  ret
  .size ifunc, .-ifunc
