cd ..
cd ..
cd ..
cd ..
cd ..
cd ..
cd ..
cd ..
cd C:\lily\kernel
nasmw -f elf kernel.asm -o kernel.o
cd ..
cd C:\lily\kernel
nasmw -f elf isr.asm -o isr.o
cd ..
cd C:\lily\boot
nasmw loader.asm -o loader.bin
cd ..
cd C:\lily\boot
nasmw boot.asm -o boot.bin