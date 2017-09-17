# CS630 on Qemu in Ubuntu

- Author: Wu Zhangjin/Falcon <wuzhangjin@gmail.com> of [TinyLab.org](http://tinylab.org)
- Update: 2008-09-16, 2014/03/16, 2016/08/04
- Home: <http://www.tinylab.org/cs630-qemu-lab/>
- Repo: <http://github.com/tinyclub/cs630-qemu-lab.git>
- CS630: <http://www.cs.usfca.edu/~cruse/cs630f06/>

[![CS630 Qemu Lab Usage](doc/cs630-qemu-pmrtc.png)](http://showdesk.io/2017-03-18-15-21-20-cs630-qemu-lab-usage-00-03-33/)

## Prepare

    $ git clone https://github.com/tinyclub/cloud-lab.git

    $ cd cloud-lab/ && tools/docker/choose cs630-qemu-lab

    $ tools/docker/run

Login the noVNC website with the printed password and launch the lab via the
desktop shortcut.

## Update

A backup of the cs630 exercises has been downloaded in `res/`, update it with:

    $ make update

## Usage

Bascially, please type:

    $ make help

### Compile and Boot

Some examples can be compiled for **Real mode**, some others need to be
compiled for **Protected mode**.

To boot with curses based graphic (console friendly), please pass 'G=0' to
make, exit with 'ESC' + '2' to Qemu monitor console and the 'quit' command.

    $ make boot G=0

By default, `src/rtc.s` is compiled and boot, Or use `SRC` to specify one:

    $ make boot SRC=src/rtc.s
    $ make boot SRC=res/rtcdemo.s

To debug with it:

    $ make debug

    $ make debug SRC=src/helloworld.s DST=boot.elf
    $ make debug SRC=src/rtc.s DST=boot.elf

Modify `.gdbinit` to customize your own auto-load gdb scripts.

Notes:

* Due to linking issue, debug not work with protected mode assembly currently, need to be fixed up later.

* To debug the real mode example, please replace the 'ljmp $addr $label' instruntion with 'jmp label'

> res/memsize.s: `ljmp $0x07C0, $main` --> `jmp main`


#### **Real mode** exercise

- helloworld

        $ make boot SRC=src/helloworld.s

- rtc

        $ make boot SRC=src/rtc.s

#### **Protected mode** exercise

- helloworld

        $ make boot SRC=src/pmhello.s

- rtc

        $ make boot SRC=src/pmrtc.s

## NOTES

In fact, some exercises not about "protected mode" also need to use the
2nd method to compile, for they begin execution with `CS:IP = 1000:0002`, and
need a "bootloader" to load them, or their size are more than 512 bytes, can
not be put in the first 512bytes of the disk (MBR).

See more notes from NOTE.md:

    $ make note
