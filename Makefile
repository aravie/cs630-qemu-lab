CC        = gcc -g -m32
LD        = ld -melf_i386
OBJCOPY   = objcopy
ENTRY     = __start

TOP_DIR   = $(CURDIR)
LDFILE    = $(TOP_DIR)/src/bootloader_x86.ld
QUICKLOAD1= $(TOP_DIR)/src/_quickload_floppy.s
QUICKLOAD2= $(TOP_DIR)/src/quickload_floppy.s
QUICKLOAD = $(QUICKLOAD1)
DEF_SRC   = $(TOP_DIR)/src/rtc.s
CONFIGURE = $(TOP_DIR)/configure
CS630     = http://www.cs.usfca.edu/~cruse/cs630f06/

all: clean boot.img

pmboot.img: boot.bin
	@make quickload.bin QUICKLOAD=$(QUICKLOAD2)
	@dd if=quickload.bin of=boot.img bs=512 count=1
	@dd if=boot.bin of=boot.img seek=1 bs=512 count=2879

boot.img: boot.bin
	@dd if=boot.bin of=boot.img bs=512 count=1

config: $(DEF_SRC) $(SRC)
	@if [ ! -f $(TOP_DIR)/boot.S ]; then $(CONFIGURE) $(DEF_SRC); fi
	@$(if $(SRC), $(CONFIGURE) $(SRC))

boot.bin: config
	@$(CC) -g -c boot.S
	@$(LD) boot.o -o boot.elf -T$(LDFILE) #-e $(ENTRY)
	@$(OBJCOPY) -R .pdr -R .comment -R.note -S -O binary boot.elf boot.bin

quickload.bin:
	$(CC) -c $(QUICKLOAD) -o boot.o
	$(LD) boot.o -o boot.elf -T$(LDFILE) #-e $(ENTRY)
	$(OBJCOPY) -R .pdr -R .comment -R.note -S -O binary boot.elf quickload.bin

update:
	@wget -c -m -nH -np --cut-dirs=2 -P res/ $(CS630)

# Debugging support
ELF_SYM ?= $(TOP_DIR)/boot.elf
GDB_CMD ?= gdb --quiet $(ELF_SYM)
XTERM_CMD ?= lxterminal --working-directory=$(TOP_DIR) -t "$(GDB_CMD)" -e "$(GDB_CMD)"

gdbinit:
	@echo "add-auto-load-safe-path $(TOP_DIR)/.gdbinit" > $(HOME)/.gdbinit

debug: gdbinit
	@$(XTERM_CMD) &
	@make -s boot D=1

defboot: clean boot.img
	@bash qemu.sh

pmboot: clean pmboot.img
	@bash qemu.sh

P ?= $(PM)
boot:
	@make $(if $P, pmboot, defboot)

clean:
	@rm -rf quickload.bin boot.o boot.elf boot.bin boot.sym boot.img

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
	@echo "    ./configure src/rtc.s        -- configure the sources with real mode"
	@echo "    ./configure src/pmrtc.s      -- configure the sources with protected mode"
	@echo ""
	@echo "    :: Compile and Boot ::"
	@echo ""
	@echo "    make boot                    -- For Real mode"
	@echo "    make boot G=0                -- For Real mode, Curses based output, for ssh like console"
	@echo "    make boot D=1                -- For Real mode, for debugging with gdb"
	@echo "    make pmboot                  -- For Protected mode"
	@echo "    make boot P=1                -- For Protected mode, the same as above"
	@echo "    make boot PM=1               -- For Protected mode, the same as above"
	@echo ""
	@echo "    :: Configure, Compile and Boot ::"
	@echo ""
	@echo "    make boot SRC=src/rtc.s      -- Specify the source directly with SRC"
	@echo "    make boot   S=src/rtc.s      -- Specify the source directly with S"
	@echo ""
	@echo "    :: Notes ::"
	@echo ""
	@echo "    make note"
	@echo ""
	@echo "--------------------------------------------------------------------"
