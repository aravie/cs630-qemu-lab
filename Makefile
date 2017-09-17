AS        = as
AS_FLAGS  = -g --32
LD        = ld
LD_FLAGS  = -melf_i386
CC        = gcc
CC_FLAGS  = -g -m32 -fno-builtin -fno-stack-protector -fomit-frame-pointer -fstrength-reduce
OBJCOPY   = objcopy
OBJCOPY_FLAGS = -R .pdr -R .comment -R.note -S -O binary

LD_FLAGS += -r

MEM      ?= 129M
BOOT_ENTRY= main
LOAD_ENTRY= start
LOAD_ADDR = 0x1000
BOOT_ADDR = 0x7C00
_LOAD_ADDR= 0x07C0

TOP_DIR   = $(CURDIR)
LDFILE    = $(TOP_DIR)/src/bootloader_x86.ld
QUICKLOAD = $(TOP_DIR)/src/quickload_floppy.s
DEF_SRC   = $(TOP_DIR)/src/rtc.s
DEBUG_PATCH=$(TOP_DIR)/src/debug.patch
CONFIGURE = $(TOP_DIR)/configure
IMAGE    ?= $(TOP_DIR)/boot.img
CS630     = http://www.cs.usfca.edu/~cruse/cs630f06/

DD_SEEK   = 1

all: clean boot.img

boot.img: boot.bin quickload.bin
	@dd if=quickload.bin of=$(IMAGE) bs=512 count=1
	@dd if=boot.bin of=$(IMAGE) seek=$(DD_SEEK) bs=512 count=128

config: $(DEF_SRC) $(SRC)
	@if [ ! -f $(TOP_DIR)/boot.S ]; then $(CONFIGURE) $(DEF_SRC); fi
	@$(if $(SRC), $(CONFIGURE) $(SRC))

boot.bin: config
	@sed -i -e "s%$(_LOAD_ADDR)%$(LOAD_ADDR)%g" boot.S
	@$(AS) $(AS_FLAGS) -o boot.o boot.S
	@$(LD) $(LD_FLAGS) boot.o -o boot.elf #-Ttext 0 #-e $(LOAD_ENTRY)
	@$(OBJCOPY) $(OBJCOPY_FLAGS) boot.elf boot.bin

quickload.bin:
	@$(AS) $(AS_FLAGS) --defsym LOAD_ADDR=$(LOAD_ADDR) $(QUICKLOAD) -o quickload.o
	@$(LD) $(LD_FLAGS) quickload.o -o quickload.elf -Ttext $(BOOT_ADDR) -e $(BOOT_ENTRY)
	@$(OBJCOPY) $(OBJCOPY_FLAGS) quickload.elf quickload.bin

update:
	@wget -c -m -nH -np --cut-dirs=2 -P res/ $(CS630)

# Debugging support
DST ?= $(TOP_DIR)/quickload.elf
GDB_CMD ?= gdb --quiet $(DST)
XTERM_CMD ?= lxterminal --working-directory=$(TOP_DIR) -t "$(GDB_CMD)" -e "$(GDB_CMD)"

gdbinit:
	@echo "add-auto-load-safe-path $(TOP_DIR)/.gdbinit" > $(HOME)/.gdbinit

debug: gdbinit
ifeq ($(findstring boot.elf,$(DST)),boot.elf)
	@-patch -s -r- -N -l -p1 < $(DEBUG_PATCH)
endif
	@$(XTERM_CMD) &
	@make -s boot D=1

DEBUG = $(if $D, -s -S)
ifeq ($G,0)
   CURSES=-curses
endif

boot: clean boot.img
	qemu-system-i386 -M pc -m $(MEM) -fda $(IMAGE) -boot a $(CURSES) $(DEBUG)

pmboot: boot

clean:
	@rm -rf *.bin *.elf *.o $(IMAGE)

distclean: clean
	@rm -rf boot.S


note:
	@cat NOTE.md

help:
	@echo "--------------------Assembly Course (CS630) Lab---------------------"
	@echo ""
	@echo "    :: Download ::"
	@echo ""
	@echo "    make update                  -- download the latest resources for the course"
	@echo ""
	@echo "    :: Configuration ::"
	@echo ""
	@echo "    ./configure src/helloworld.s -- configure the source want to compile"
	@echo "    ./configure src/pmhello.s    -- configure the hello with protected mode"
	@echo "    ./configure src/rtc.s        -- configure the sources with real mode"
	@echo "    ./configure src/pmrtc.s      -- configure the sources with protected mode"
	@echo ""
	@echo "    :: Compile and Boot ::"
	@echo ""
	@echo "    make boot                    -- Compile and boot"
	@echo "    make boot G=0                -- Curses based output, for ssh like console"
	@echo "    make boot D=1                -- For debugging with gdb"
	@echo ""
	@echo "    :: Configure, Compile and Boot ::"
	@echo ""
	@echo "    make boot SRC=src/rtc.s      -- Specify the source directly with SRC"
	@echo "    make boot SRC=src/pmrtc.s    -- Specify the source directly with SRC"
	@echo ""
	@echo "    :: Notes ::"
	@echo ""
	@echo "    make note"
	@echo ""
	@echo "--------------------------------------------------------------------"
