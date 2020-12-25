
ENTRY = 0x30000
CC          =gcc
CFLAGS      =-I include -c -fno-builtin
### -fno-builtin
LD          =ld
LDFLAGS     = -N -s --oformat binary -e _start -Ttext ${ENTRY}
TARGET		= final.img

KERNEL_OBJS = kernel.o init.o global.o kprintf.o isr.o exceptions.o task.o libcc.o


.PHONY : clean build

all: ${TARGET}

clean :
	rm -f *.o
	rm -f *.bin
	rm -f /tmp/final.img

final.img : floppy.img kernel.bin 
	cp floppy.img /tmp/floppy.img 
	mount -o loop /tmp/floppy.img /mnt/floppy
	cp kernel.bin /mnt/floppy
	cp boot/loader.bin /mnt/floppy
	umount /mnt/floppy
	cp /tmp/floppy.img /mnt/hgfs/lily/final.img
kernel.bin : ${KERNEL_OBJS}
	$(LD) $(LDFLAGS) -o $@ $(KERNEL_OBJS)
global.o : kernel/global.c include/const.h include/global.h
	${CC} ${CFLAGS} -o $@ $<
kprintf.o : lib/kprintf.c include/const.h include/global.h include/kprintf.h  
	${CC} ${CFLAGS} -o $@ $<
libcc.o : lib/libcc.c include/const.h include/libcc.h 
	${CC} ${CFLAGS} -o $@ $<
init.o : kernel/init.c include/const.h include/global.h include/kprintf.h include/libcc.h
	${CC} ${CFLAGS} -o $@ $<
exceptions.o : kernel/exceptions.c include/const.h include/global.h include/kprintf.h
	${CC} ${CFLAGS} -o $@ $<
task.o : kernel/task.c include/const.h include/global.h include/kprintf.h include/task.h include/libcc.h
	${CC} ${CFLAGS} -o $@ $<
kernel.o : kernel/kernel.o
	cp kernel/kernel.o kernel.o
isr.o : kernel/isr.o
	cp kernel/isr.o isr.o

