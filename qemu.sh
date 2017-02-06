#!/bin/bash

[ -z "$1" ] && exit -1

image="$1".img

[ -n "$G" -a "$G" == "0" ] && CURSES=-curses

qemu-system-i386 $CURSES -m 129M -fda $image -boot a
