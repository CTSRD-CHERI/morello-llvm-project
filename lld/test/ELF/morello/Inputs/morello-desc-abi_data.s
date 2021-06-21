  .global hello
  .type hello,%object
   .data
  .zero 20
hello:
	.asciz "Hello world"
	.size hello, .-hello

  .globl __desc_start
  .globl __desc_end
  .globl __desc_ro_start
  .globl __desc_ro_end
  .xword __desc_start
  .xword __desc_end
  .xword __desc_ro_start
  .xword __desc_ro_end

  .global bye
  .type bye,%object
  .section .desc.data,"a",%progbits
  .zero 0x2000
bye:
	.asciz "Bye world"
	.size bye, .-bye


  .global foo
  .type foo,%object
  .section .data.rel.ro,"a",%progbits
  .zero 0x2000
foo:
	.asciz "Foo"
	.size foo, .-foo

  .global bar
  .type bar,%object
  .section .desc.data.rel.ro,"aw",%progbits
  .zero 0x2000
bar:
	.asciz "Bar"
	.size bar, .-bar

 .section .init_array, "a", %init_array
 .space 8

 .section .fini_array, "a", %fini_array
 .space 64



 .bss
 .globl bss
 .type bss, %object
 .size bss, 4
bss:
 .space 4
