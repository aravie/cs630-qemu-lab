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
LDFILE   ?= $(TOP_DIR)/src/quikload_floppy.ld
DEF_SRC   = $(TOP_DIR)/src/rtc.s
DEBUG_PATCH=$(TOP_DIR)/src/debug.patch
CS630     = http://www.cs.usfca.edu/~cruse/cs630f06/

QUIKLOAD_FD = $(TOP_DIR)/src/quikload_floppy.s
QUIKLOAD_HD = $(TOP_DIR)/src/quikload_hd.s

ifeq ($(BOOT_DEV), hd)
  QUIKLOAD ?= $(QUIKLOAD_HD)
  SYS_SIZE ?= 128
else
  QUIKLOAD ?= $(QUIKLOAD_FD)
  SYS_SIZE ?= 72
endif

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
  LOADER = quikload.bin
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
  LD_FALGS += 2>/dev/null
endif

SRC_CFG := ${TOP_DIR}/.src.cfg
ifeq ($(SRC),)
  CFG = $(shell cat $(SRC_CFG) 2>/dev/null)
  ifeq ($(CFG),)
    SRC = $(DEF_SRC)
  else
    SRC = $(CFG)
  endif
endif

all: src clean boot.img

src: $(SRC) FORCE
	$(Q)echo $(SRC) > $(SRC_CFG)

boot.img: $(LOADER) boot.bin

boot.bin: $(SRC)
	$(Q)sed -i -e "s%$(_BOOT_ADDR)%$(_LOAD_ADDR)%g" $<
	$(Q)$(AS) $(AS_FLAGS) -o boot.o $<
	$(Q)$(LD) $(LD_FLAGS) boot.o -o boot.elf -Ttext $(LOAD_ADDR) -e $(LOAD_ENTRY)
	$(Q)$(OBJCOPY) $(OBJCOPY_FLAGS) boot.elf $@
	$(Q)dd if=$@ of=$(IMAGE) status=none seek=$(DD_SEEK) bs=512 count=$(SYS_SIZE)

QUIKLOAD_AS_FLAGS = --defsym LOAD_ADDR=$(_LOAD_ADDR) --defsym SYS_SIZE=$(SYS_SIZE)

quikload.bin: $(QUIKLOAD)
	$(Q)$(AS) $(AS_FLAGS) $(QUIKLOAD_AS_FLAGS) $< -o quikload.o
	$(Q)$(LD) $(LD_FLAGS) quikload.o -o quikload.elf -T $(LDFILE)
	$(Q)$(OBJCOPY) $(OBJCOPY_FLAGS) quikload.elf $@
	$(Q)dd if=$@ status=none of=$(IMAGE) bs=512 count=1

update:
	$(Q)wget -c -m -nH -np --cut-dirs=2 -P res/ $(CS630)

# Debugging support
DST ?= $(TOP_DIR)/quikload.elf
GDB_CMD ?= gdb --quiet $(DST)
XTERM_CMD ?= lxterminal --working-directory=$(TOP_DIR) -t "$(GDB_CMD)" -e "$(GDB_CMD)"

gdbinit:
	$(Q)echo "add-auto-load-safe-path $(TOP_DIR)/.gdbinit" > $(HOME)/.gdbinit

debug: src gdbinit
	$(Q)$(XTERM_CMD) &
	$(Q)make $(S) boot D=1

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
  QEMU_XOPTS = -no-kqemu -L $(QEMU_PATH)
endif

ifeq ($(BOOT_DEV), hd)
# BOOT_FLAGS = -fda $(IMAGE) -boot a -hda $(IMAGE)
  BOOT_FLAGS = -hda $(IMAGE) -boot c
else
  BOOT_FLAGS = -fda $(IMAGE) -boot a
endif

QEMU_CMD  = $(QEMU)
QEMU_OPTS = -M pc -m $(MEM) $(BOOT_FLAGS) $(CURSES) $(DEBUG)

ifeq ($(QEMU_PREBUILT),1)
  QEMU_STATUS = $(shell $(QEMU_PATH)/$(QEMU) --help >/dev/null 2>&1; echo $$?)
  ifeq ($(QEMU_STATUS), 0)
    QEMU_CMD := $(QEMU_PATH)/$(QEMU) $(QEMU_XOPTS)
  endif
endif

QEMU_CMD += $(QEMU_OPTS)

boot: src $(BUILD)
	$(QEMU_CMD)

pmboot: boot

boot-hd:
	$(Q) make boot BOOT_DEV=hd
hd-boot: boot-hd

clean:
	$(Q)rm -rf *.bin *.elf *.o $(IMAGE)

distclean: clean
	$(Q)rm -rf $(SRC_CFG)


note:
	$(Q)cat NOTE.md

FORCE:;

help:
	@echo "--------------------Assembly Course (CS630) Lab---------------------"
	@echo ""
	@echo "    :: Download ::"
	@echo ""
	@echo "    make update                  -- download the latest resources for the course"
	@echo ""
	@echo "    :: Configuration ::"
	@echo ""
	@echo "    make SRC=src/pmrtc.s         -- configure the sources with protected mode"
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
