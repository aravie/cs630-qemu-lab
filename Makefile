AS        = as
AS_FLAGS  = -g --32
LD        = ld
LD_FLAGS  = -melf_i386
CC        = gcc
CC_FLAGS  = -g -m32 -fno-builtin -fno-stack-protector -fomit-frame-pointer -fstrength-reduce
OBJCOPY   = objcopy
OBJCOPY_FLAGS = -R .pdr -R .comment -R.note -S -O binary

LD_FLAGS +=

MEM      ?= 129M
BOOT_ENTRY= main
BOOT_ADDR = 0x7C00

TOP_DIR   = $(CURDIR)
LDFILE    = $(TOP_DIR)/src/bootloader_x86.ld
QUICKLOAD = $(TOP_DIR)/src/quickload_floppy.s
DEF_SRC   = $(TOP_DIR)/src/rtc.s
DEBUG_PATCH=$(TOP_DIR)/src/debug.patch
CONFIGURE = $(TOP_DIR)/configure
CS630     = http://www.cs.usfca.edu/~cruse/cs630f06/

TOOL_DIR  = ${TOP_DIR}/tools/

ifeq ($(IMAGE),)
  IMAGE = $(TOP_DIR)/boot.img
  BUILD = clean boot.img
endif

ifeq ($(RAW), 1)
  DST = ${TOP_DIR}/boot.elf
endif

ifeq ($(findstring boot.elf,$(DST)),boot.elf)
  RAW = 1
endif

ifeq ($(RAW), 1)
  DD_SEEK    = 0
else
  LOAD_ADDR  = 0
  _LOAD_ADDR = 0x1000
  LOADER = quickload.bin
endif

_BOOT_ADDR= 0x07C0

LOAD_ENTRY?= start
_LOAD_ADDR?= $(_BOOT_ADDR)
LOAD_ADDR ?= $(BOOT_ADDR)
DD_SEEK   ?= 1

ifeq ($V, 1)
  Q =
  S =
else
  S ?= -s
  Q ?= @
endif

all: clean boot.img

boot.img: $(LOADER) boot.bin

config: $(DEF_SRC) $(SRC)
	$(Q)if [ ! -f $(TOP_DIR)/boot.S ]; then $(CONFIGURE) $(DEF_SRC); fi
	$(Q)$(if $(SRC), $(CONFIGURE) $(SRC))

boot.bin: config
	$(Q)sed -i -e "s%$(_BOOT_ADDR)%$(_LOAD_ADDR)%g" boot.S
	$(Q)$(AS) $(AS_FLAGS) -o boot.o boot.S
	$(Q)$(LD) $(LD_FLAGS) boot.o -o boot.elf -Ttext $(LOAD_ADDR) -e $(LOAD_ENTRY)
	$(Q)$(OBJCOPY) $(OBJCOPY_FLAGS) boot.elf boot.bin
	$(Q)dd if=boot.bin of=$(IMAGE) seek=$(DD_SEEK) bs=512 count=72

quickload.bin:
	$(Q)$(AS) $(AS_FLAGS) --defsym LOAD_ADDR=$(_LOAD_ADDR) $(QUICKLOAD) -o quickload.o
	$(Q)$(LD) $(LD_FLAGS) quickload.o -o quickload.elf -Ttext $(BOOT_ADDR) -e $(BOOT_ENTRY)
	$(Q)$(OBJCOPY) $(OBJCOPY_FLAGS) quickload.elf quickload.bin
	$(Q)dd if=quickload.bin of=$(IMAGE) bs=512 count=1

update:
	$(Q)wget -c -m -nH -np --cut-dirs=2 -P res/ $(CS630)

# Debugging support
DST ?= $(TOP_DIR)/quickload.elf
GDB_CMD ?= gdb --quiet $(DST)
XTERM_CMD ?= lxterminal --working-directory=$(TOP_DIR) -t "$(GDB_CMD)" -e "$(GDB_CMD)"

gdbinit:
	$(Q)echo "add-auto-load-safe-path $(TOP_DIR)/.gdbinit" > $(HOME)/.gdbinit

debug: gdbinit
	$(Q)$(XTERM_CMD) &
	$(Q)make -s boot D=1

DEBUG = $(if $D, -s -S)
ifeq ($G,0)
   CURSES=-curses
endif

QEMU_PATH =
QEMU_PREBUILT ?= 1
QEMU_PREBUILT_PATH= $(TOOL_DIR)/qemu/
QEMU  = qemu-system-i386

ifeq ($(QEMU_PREBUILT), 1)
  QEMU_PATH = $(QEMU_PREBUILT_PATH)
  QEMU_OPTS = -no-kqemu
endif

QEMU_CMD = $(QEMU) -M pc -m $(MEM) -fda $(IMAGE) -boot a $(CURSES) $(DEBUG)
ifeq ($(QEMU_PREBUILT),1)
  QEMU_STATUS = $(shell $(QEMU_PATH)/$(QEMU) --help >/dev/null 2>&1; echo $$?)
  ifeq ($(QEMU_STATUS), 0)
    QEMU_CMD := $(QEMU_PATH)/$(QEMU_CMD) $(QEMU_OPTS) -L $(QEMU_PATH)
  endif
endif

boot: $(BUILD)
	$(QEMU_CMD)

pmboot: boot

clean:
	$(Q)rm -rf *.bin *.elf *.o $(IMAGE)

distclean: clean
	$(Q)rm -rf boot.S


note:
	$(Q)cat NOTE.md

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
