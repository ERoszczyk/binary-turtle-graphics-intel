CC=gcc
ASMBIN=nasm

all : asm cc link clean
asm : 
	$(ASMBIN) -o exec_command.o -f elf64 exec_command.asm
cc :
	$(CC) -c -g -O0 bin_turtle.c
link :
	$(CC) -o turtle bin_turtle.o exec_command.o
clean :
	rm *.o
	rm turtle
