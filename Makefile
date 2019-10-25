AS        = as
AS_FLAGS  = -g --32
LD        = ld
LD_FLAGS  = -melf_i386 -E
CC        = gcc
CC_FLAGS  = -g -m32 -fno-builtin -fno-stack-protector -fomit-frame-pointer -fstrength-reduce
OBJCOPY   = objcopy
OBJCOPY_FLAGS = -R .pdr -R .comment -R .note -S -O binary
STRIP     = strip
STRIP_FLAGS = -s

LD_FLAGS +=

MEM      ?= 129M
BOOT_ENTRY= main
BOOT_ADDR = 0x7C00

LDFILE   ?= src/quikload_floppy.ld
DEF_SRC  ?= src/rtc.s
DEF_APP  ?= res/hello.s
CS630     = http://www.cs.usfca.edu/~cruse/cs630f06/

QUIKLOAD_FD = src/quikload_floppy.s
QUIKLOAD_HD = src/quikload_hd.s

ifeq ($(BOOT_DEV), hd)
  QUIKLOAD ?= $(QUIKLOAD_HD)
  SYS_SIZE ?= 128
else
  QUIKLOAD ?= $(QUIKLOAD_FD)
  SYS_SIZE ?= 72
endif

ifeq ($(IMAGE),)
  IMAGE = boot.img
  BUILD = clean boot.img
endif

ifeq ($(RAW), 1)
  DST = boot.elf
endif

#ifeq ($(findstring boot.elf,$(DST)),boot.elf)
#  RAW = 1
#endif

ifeq ($(RAW), 1)
  DD_BOOT_SEEK    = 0
else
  LOAD_ADDR  = 0
  _LOAD_ADDR = 0x1000
  LOADER = quikload.bin
endif

_BOOT_ADDR= 0x07C0

LOAD_ENTRY?= start
_LOAD_ADDR?= $(_BOOT_ADDR)
LOAD_ADDR ?= $(BOOT_ADDR)
DD_BOOT_SEEK   ?= 1

ifeq ($V, 1)
  Q =
  S =
else
  S ?= -s
  Q ?= @
  LD_FALGS += 2>/dev/null
endif

SRC_CFG := .src.cfg
ifeq ($(SRC),)
  CFG = $(shell cat $(SRC_CFG) 2>/dev/null)
  ifeq ($(CFG),)
    SRC = $(DEF_SRC)
  else
    SRC = $(CFG)
  endif
endif

APP_CFG := .app.cfg
ifeq ($(APP),)
  _CFG = $(shell cat $(APP_CFG) 2>/dev/null)
  ifeq ($(_CFG),)
    APP = $(DEF_APP)
  else
    APP = $(_CFG)
  endif
endif

ifneq ($(APP),)
  DD_APP_SEEK    ?= 13
  APP_BIN        ?= app.elf
endif

all: src clean boot.img

src: $(SRC) $(APP) FORCE
	$(Q)echo $(SRC) > $(SRC_CFG)
	$(Q)echo $(APP) > $(APP_CFG)

boot.img: $(LOADER) boot.bin $(APP_BIN)

boot.bin: $(SRC)
	$(Q)sed -i -e "s%$(_BOOT_ADDR)%$(_LOAD_ADDR)%g" $<
	$(Q)$(AS) $(AS_FLAGS) -o boot.o $<
	$(Q)$(LD) $(LD_FLAGS) boot.o -o boot.elf -Ttext $(LOAD_ADDR) -e $(LOAD_ENTRY)
	$(Q)$(OBJCOPY) $(OBJCOPY_FLAGS) boot.elf $@
	$(Q)dd if=$@ of=$(IMAGE) status=none seek=$(DD_BOOT_SEEK) bs=512 count=$(SYS_SIZE)

app.elf: $(APP)
	$(Q)$(AS) $(AS_FLAGS) -o app.o $<
	$(Q)$(LD) $(LD_FLAGS) app.o -o app.elf
	$(Q)dd if=$@ of=$(IMAGE) status=none seek=$(DD_APP_SEEK) conv=notrunc

QUIKLOAD_AS_FLAGS = --defsym LOAD_ADDR=$(_LOAD_ADDR) --defsym SYS_SIZE=$(SYS_SIZE)

quikload.bin: $(QUIKLOAD)
	$(Q)$(AS) $(AS_FLAGS) $(QUIKLOAD_AS_FLAGS) $< -o quikload.o
	$(Q)$(LD) $(LD_FLAGS) quikload.o -o quikload.elf -T $(LDFILE)
	$(Q)$(OBJCOPY) $(OBJCOPY_FLAGS) quikload.elf $@
	$(Q)dd if=$@ status=none of=$(IMAGE) bs=512 count=1

update:
	$(Q)wget -c -m -nH -np --cut-dirs=2 -P res/ $(CS630)

# Debugging support
# Xterm: lxterminal, terminator
XTERM ?= $(shell echo `tools/xterm.sh lxterminal`)
DST ?= quikload.elf
GDB_CMD ?= gdb --quiet $(DST)
XTERM_CMD ?= $(XTERM) --working-directory=$(CURDIR) -T "$(GDB_CMD)" -e "$(GDB_CMD)"
XTERM_STATUS = $(shell $(XTERM) --help >/dev/null 2>&1; echo $$?)
ifeq ($(XTERM_STATUS), 0)
  DEBUG_CMD = $(XTERM_CMD)
else
  DEBUG_CMD = echo "\nLOG: Please run this in another terminal:\n\n    " $(GDB_CMD) "\n"
endif

gdbinit:
	$(Q)echo "add-auto-load-safe-path .gdbinit" > $(HOME)/.gdbinit

debug: src gdbinit $(BUILD)
	$(Q)$(DEBUG_CMD) &
	$(QEMU_CMD) $(DEBUG)

debug-hd:
	@make debug BOOT_DEV=hd

DEBUG = -s -S

# Use curses based window for ssh/bash login
ifneq ($(shell env | grep -q ^XDG; echo $$?), 0)
  override G := 0
endif

ifneq ($(SSH_TTY),)
  override G := 0
endif

ifeq ($G,0)
  CURSES=-curses
endif

# Some examples using floppy, which may not work on latest qemu versions
# but you can force use latest qemu for better performance if not using floppy examples.
# simply run: QEMU_PREBUILT=0 make boot

QEMU_PATH =
QEMU_PREBUILT ?= 1
QEMU_PREBUILT_PATH= tools/qemu
QEMU  = qemu-system-i386

ifeq ($(BOOT_DEV), hd)
# BOOT_FLAGS = -fda $(IMAGE) -boot a -hda $(IMAGE)
  BOOT_FLAGS = -hda $(IMAGE) -boot c
else
  BOOT_FLAGS = -fda $(IMAGE) -boot a
endif

QEMU_CMD  = $(QEMU)
QEMU_OPTS = -M pc -m $(MEM) $(BOOT_FLAGS) $(CURSES)

ifeq ($(QEMU_PREBUILT), 1)
  QEMU_PATH = $(QEMU_PREBUILT_PATH)
  QEMU_XOPTS = -no-kqemu -L $(QEMU_PATH)
else
  QEMU_CMD := sudo $(QEMU_CMD)
  ifneq ($(filter debug,$(MAKECMDGOALS)),debug)
    KVM_DEV ?= /dev/kvm
    ifeq ($(KVM_DEV),$(wildcard $(KVM_DEV)))
      QEMU_OPTS += -enable-kvm
    endif
  endif
endif

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
	$(Q)rm -rf $(SRC_CFG) $(APP_CFG)


note:
	$(Q)cat NOTE.md

FORCE:;

help:
	@echo "--- Assembly Course (CS630) Lab: http://tinylab.org/cs630-qemu-lab ---"
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
	@echo "--- Assembly Course (CS630) Lab: http://tinylab.org/cs630-qemu-lab ---"
	@echo ""
