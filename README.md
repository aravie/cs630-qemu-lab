# CS630 on Qemu in Ubuntu

- Author: Wu Zhangjin/Falcon <wuzhangjin@gmail.com> of [TinyLab.org](http://tinylab.org)
- Update: 2008-09-16, 2014/03/16, 2016/08/04
- Home: <http://www.tinylab.org/cs630-qemu-lab/>
- Repo: <http://github.com/tinyclub/cs630-qemu-lab.git>
- CS630: <http://www.cs.usfca.edu/~cruse/cs630f06/>

[![CS630 Qemu Lab Usage](doc/cs630-qemu-pmrtc.png)](http://showdesk.io/2017-03-18-15-21-20-cs630-qemu-lab-usage-00-03-33/)

## Prepare

Please install docker at first:

* Linux and Mac OSX: [Docker CE](https://store.docker.com/search?type=edition&offering=community)
* Windows: [Docker Toolbox](https://www.docker.com/docker-toolbox)

Notes:

In order to run docker without password, please make sure your user is added in the docker group:

    $ sudo usermod -aG docker $USER

In order to speedup docker images downloading, please configure a local docker mirror in `/etc/default/docker`, for example:

    $ grep registry-mirror /etc/default/docker
    DOCKER_OPTS="$DOCKER_OPTS --registry-mirror=https://docker.mirrors.ustc.edu.cn"
    $ service docker restart

In order to avoid network ip address conflict, please try following changes and restart docker:

    $ grep bip /etc/default/docker
    DOCKER_OPTS="$DOCKER_OPTS --bip=10.66.0.10/16"
    $ service docker restart

If the above changes not work, try something as following:

    $ grep dockerd /lib/systemd/system/docker.service
    ExecStart=/usr/bin/dockerd -H fd:// --bip=10.66.0.10/16 --registry-mirror=https://docker.mirrors.ustc.edu.cn
    $ service docker restart

## Choose a working directory

If installed via Docker Toolbox, please enter into the `/mnt/sda1` directory of the `default` system on Virtualbox, otherwise, after poweroff, the data will be lost for the default `/root` directory is only mounted in DRAM.

    $ cd /mnt/sda1

For Linux or Mac OSX, please simply choose one directory in `~/Downloads` or `~/Documents`.

    $ cd ~/Documents

## Install

Using Ubuntu as example:

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

> res/memsize.s: `ljmp $0x07C0, $main` --> `jmp main`, see `git show 86555`


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
