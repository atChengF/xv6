
# To compile and run with a lab solution, set the lab name in lab.mk
# (e.g., LB=util).  Run make grade to test solution with the lab's
# grade script (e.g., grade-lab-util).

-include conf/lab.mk

# kernel, 内核
K=kernel
# user 用户
U=user

# 对象
OBJS = \
  $K/entry.o \
  $K/start.o \
  $K/console.o \
  $K/printf.o \
  $K/uart.o \
  $K/kalloc.o \
  $K/spinlock.o \
  $K/string.o \
  $K/main.o \
  $K/vm.o \
  $K/proc.o \
  $K/swtch.o \
  $K/trampoline.o \
  $K/trap.o \
  $K/syscall.o \
  $K/sysproc.o \
  $K/bio.o \
  $K/fs.o \
  $K/log.o \
  $K/sleeplock.o \
  $K/file.o \
  $K/pipe.o \
  $K/exec.o \
  $K/sysfile.o \
  $K/kernelvec.o \
  $K/plic.o \
  $K/virtio_disk.o \

#目前没什么用
ifeq ($(LAB),pgtbl)
OBJS += $K/vmcopyin.o
endif

# riscv64-unknown-elf- or riscv64-linux-gnu-
# perhaps in /opt/riscv/bin
#TOOLPREFIX = 

# 寻找risc-v64相关的依赖链
# Try to infer the correct TOOLPREFIX if not set
ifndef TOOLPREFIX
TOOLPREFIX := $(shell if riscv64-unknown-elf-objdump -i 2>&1 | grep 'elf64-big' >/dev/null 2>&1; \
	then echo 'riscv64-unknown-elf-'; \
	elif riscv64-linux-gnu-objdump -i 2>&1 | grep 'elf64-big' >/dev/null 2>&1; \
	then echo 'riscv64-linux-gnu-'; \
	elif riscv64-unknown-linux-gnu-objdump -i 2>&1 | grep 'elf64-big' >/dev/null 2>&1; \
	then echo 'riscv64-unknown-linux-gnu-'; \
	else echo "***" 1>&2; \
	echo "*** Error: Couldn't find a riscv64 version of GCC/binutils." 1>&2; \
	echo "*** To turn off this error, run 'gmake TOOLPREFIX= ...'." 1>&2; \
	echo "***" 1>&2; exit 1; fi)
endif

#qemu
QEMU = qemu-system-riscv64

# 编译c文件工具
CC = $(TOOLPREFIX)gcc
# 编译
AS = $(TOOLPREFIX)gas
#链接器
LD = $(TOOLPREFIX)ld
#文件复制
OBJCOPY = $(TOOLPREFIX)objcopy
#文件反汇编
OBJDUMP = $(TOOLPREFIX)objdump

#CFLAGS用于编译器的参数，开启警告 -Wall、编译时检查错误 -Werror、优化等级 -O、保留帧指针 -fno-omit-frame-pointer、调试信息 -ggdb
CFLAGS = -Wall -Werror -O -fno-omit-frame-pointer -ggdb

ifdef LAB
LABUPPER = $(shell echo $(LAB) | tr a-z A-Z)
CFLAGS += -DSOL_$(LABUPPER)
endif
#-DSOL_$(LABUPPER)表示定义预处理宏SOL_$(LABUPPER)，其中$(LABUPPER)为LAB变量的值（即实验名），这个宏用于在代码中判断当前实验；

CFLAGS += -MD #-MD表示生成依赖关系文件，即.d文件；
CFLAGS += -mcmodel=medany # -mcmodel=medany表示使用medany内存模型，即允许数据和代码同时存在于4GB以上的内存中；
CFLAGS += -ffreestanding -fno-common -nostdlib -mno-relax  
# -ffreestanding表示代码可以在没有操作系统支持的环境下运行；
# -fno-common表示禁止使用未初始化全局变量的共享内存；
# -nostdlib表示不使用标准库函数；
# -mno-relax表示不使用relax机制；
CFLAGS += -I. 
# -I.表示添加当前目录到头文件搜索路径；
CFLAGS += $(shell $(CC) -fno-stack-protector -E -x c /dev/null >/dev/null 2>&1 && echo -fno-stack-protector)
# 表示检测编译器是否支持-fno-stack-protector选项，如果支持则添加该选项到CFLAGS中。
# Disable PIE when possible (for Ubuntu 16.10 toolchain)
ifneq ($(shell $(CC) -dumpspecs 2>/dev/null | grep -e '[^f]no-pie'),)
CFLAGS += -fno-pie -no-pie
endif
ifneq ($(shell $(CC) -dumpspecs 2>/dev/null | grep -e '[^f]nopie'),)
CFLAGS += -fno-pie -nopie
endif
# 解决工具链中出现的一个问题
# -z max-page-size=4096表示设置最大页面大小为4096字节。
LDFLAGS = -z max-page-size=4096

$K/kernel: $(OBJS) $K/kernel.ld $U/initcode
	$(LD) $(LDFLAGS) -T $K/kernel.ld -o $K/kernel $(OBJS) 
	$(OBJDUMP) -S $K/kernel > $K/kernel.asm
	$(OBJDUMP) -t $K/kernel | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $K/kernel.sym

$U/initcode: $U/initcode.S
	$(CC) $(CFLAGS) -march=rv64g -nostdinc -I. -Ikernel -c $U/initcode.S -o $U/initcode.o
	$(LD) $(LDFLAGS) -N -e start -Ttext 0 -o $U/initcode.out $U/initcode.o
	$(OBJCOPY) -S -O binary $U/initcode.out $U/initcode
	$(OBJDUMP) -S $U/initcode.o > $U/initcode.asm

tags: $(OBJS) _init
	etags *.S *.c

ULIB = $U/ulib.o $U/usys.o $U/printf.o $U/umalloc.o

_%: %.o $(ULIB)
	$(LD) $(LDFLAGS) -N -e main -Ttext 0 -o $@ $^ 
	$(OBJDUMP) -S $@ > $*.asm
	$(OBJDUMP) -t $@ | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $*.sym

$U/usys.S : $U/usys.pl
	perl $U/usys.pl > $U/usys.S

$U/usys.o : $U/usys.S
	$(CC) $(CFLAGS) -c -o $U/usys.o $U/usys.S

$U/_forktest: $U/forktest.o $(ULIB)
	# forktest has less library code linked in - needs to be small
	# in order to be able to max out the proc table.
	$(LD) $(LDFLAGS) -N -e main -Ttext 0 -o $U/_forktest $U/forktest.o $U/ulib.o $U/usys.o
	$(OBJDUMP) -S $U/_forktest > $U/forktest.asm

mkfs/mkfs: mkfs/mkfs.c $K/fs.h $K/param.h
	gcc -Werror -Wall -I. -o mkfs/mkfs mkfs/mkfs.c

# Prevent deletion of intermediate files, e.g. cat.o, after first build, so
# that disk image changes after first build are persistent until clean.  More
# details:
# http://www.gnu.org/software/make/manual/html_node/Chained-Rules.html
.PRECIOUS: %.o

# 用户态程序
UPROGS=\
	$U/_cat\
	$U/_echo\
	$U/_forktest\
	$U/_grep\
	$U/_init\
	$U/_kill\
	$U/_ln\
	$U/_ls\
	$U/_mkdir\
	$U/_rm\
	$U/_sh\
	$U/_stressfs\
	$U/_usertests\
	$U/_grind\
	$U/_wc\
	$U/_zombie\
	$U/_test\
	$U/_sleep\
	$U/_pingpong\
	$U/_primes\
	$U/_find\


ifeq ($(LAB),syscall)
UPROGS += \
	$U/_trace\
	$U/_sysinfotest
endif

ifeq ($(LAB),trap)
UPROGS += \
	$U/_call\
	$U/_alarmtest
endif

ifeq ($(LAB),lazy)
UPROGS += \
	$U/_lazytests
endif

ifeq ($(LAB),cow)
UPROGS += \
	$U/_cowtest
endif

UEXTRA=
ifeq ($(LAB),util)
	UEXTRA += user/xargstest.sh
endif

fs.img: mkfs/mkfs README $(UEXTRA) $(UPROGS)
	mkfs/mkfs fs.img README $(UEXTRA) $(UPROGS)

-include kernel/*.d user/*.d

clean: 
	rm -f *.tex *.dvi *.idx *.aux *.log *.ind *.ilg \
	*/*.o */*.d */*.asm */*.sym \
	$U/initcode $U/initcode.out $K/kernel fs.img \
	mkfs/mkfs .gdbinit \
        $U/usys.S \
	$(UPROGS)

# try to generate a unique GDB port
GDBPORT = $(shell expr `id -u` % 5000 + 25000)
# QEMU's gdb stub command line changed in 0.11
QEMUGDB = $(shell if $(QEMU) -help | grep -q '^-gdb'; \
	then echo "-gdb tcp::$(GDBPORT)"; \
	else echo "-s -p $(GDBPORT)"; fi)
ifndef CPUS
CPUS := 3
endif

QEMUOPTS = -machine virt -bios none -kernel $K/kernel -m 128M -smp $(CPUS) -nographic
QEMUOPTS += -drive file=fs.img,if=none,format=raw,id=x0
QEMUOPTS += -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0

qemu: $K/kernel fs.img
	$(QEMU) $(QEMUOPTS)

.gdbinit: .gdbinit.tmpl-riscv
	sed "s/:1234/:$(GDBPORT)/" < $^ > $@

qemu-gdb: $K/kernel .gdbinit fs.img
	@echo "*** Now run 'gdb' in another window." 1>&2
	$(QEMU) $(QEMUOPTS) -S $(QEMUGDB)

##
##  FOR testing lab grading script
##

ifneq ($(V),@)
GRADEFLAGS += -v
endif

print-gdbport:
	@echo $(GDBPORT)

grade:
	@echo $(MAKE) clean
	@$(MAKE) clean || \
          (echo "'make clean' failed.  HINT: Do you have another running instance of xv6?" && exit 1)
	./grade-lab-$(LAB) $(GRADEFLAGS)

##
## FOR web handin
##


WEBSUB := https://6828.scripts.mit.edu/2020/handin.py

handin: tarball-pref myapi.key
	@SUF=$(LAB); \
	curl -f -F file=@lab-$$SUF-handin.tar.gz -F key=\<myapi.key $(WEBSUB)/upload \
	    > /dev/null || { \
		echo ; \
		echo Submit seems to have failed.; \
		echo Please go to $(WEBSUB)/ and upload the tarball manually.; }

handin-check:
	@if ! test -d .git; then \
		echo No .git directory, is this a git repository?; \
		false; \
	fi
	@if test "$$(git symbolic-ref HEAD)" != refs/heads/$(LAB); then \
		git branch; \
		read -p "You are not on the $(LAB) branch.  Hand-in the current branch? [y/N] " r; \
		test "$$r" = y; \
	fi
	@if ! git diff-files --quiet || ! git diff-index --quiet --cached HEAD; then \
		git status -s; \
		echo; \
		echo "You have uncomitted changes.  Please commit or stash them."; \
		false; \
	fi
	@if test -n "`git status -s`"; then \
		git status -s; \
		read -p "Untracked files will not be handed in.  Continue? [y/N] " r; \
		test "$$r" = y; \
	fi

UPSTREAM := $(shell git remote -v | grep -m 1 "xv6-labs-2020" | awk '{split($$0,a," "); print a[1]}')

tarball: handin-check
	git archive --format=tar HEAD | gzip > lab-$(LAB)-handin.tar.gz

tarball-pref: handin-check
	@SUF=$(LAB); \
	git archive --format=tar HEAD > lab-$$SUF-handin.tar; \
	git diff $(UPSTREAM)/$(LAB) > /tmp/lab-$$SUF-diff.patch; \
	tar -rf lab-$$SUF-handin.tar /tmp/lab-$$SUF-diff.patch; \
	gzip -c lab-$$SUF-handin.tar > lab-$$SUF-handin.tar.gz; \
	rm lab-$$SUF-handin.tar; \
	rm /tmp/lab-$$SUF-diff.patch; \

myapi.key:
	@echo Get an API key for yourself by visiting $(WEBSUB)/
	@read -p "Please enter your API key: " k; \
	if test `echo "$$k" |tr -d '\n' |wc -c` = 32 ; then \
		TF=`mktemp -t tmp.XXXXXX`; \
		if test "x$$TF" != "x" ; then \
			echo "$$k" |tr -d '\n' > $$TF; \
			mv -f $$TF $@; \
		else \
			echo mktemp failed; \
			false; \
		fi; \
	else \
		echo Bad API key: $$k; \
		echo An API key should be 32 characters long.; \
		false; \
	fi;


.PHONY: handin tarball tarball-pref clean grade handin-check
