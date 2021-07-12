  .global hello
  .type hello,%object
   .data
  .zero 20
hello:
	.asciz "Hello world"
	.size hello, .-hello

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

 .bss
 .globl bss
 .type bss, %object
 .size bss, 4
bss:
 .space 4
