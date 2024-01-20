.SILENT:

build:
	nasm -f elf64 time.asm
	ld -s -g -o time time.o

run: build
	./time
