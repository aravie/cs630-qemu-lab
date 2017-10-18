#!/bin/sh

ppid () { ps -p ${1:-$$} -o ppid=; }
pcom () { ps -p ${1:-$$} -o cmd=; }
pppid () { ppid `ppid ${1:-$$}`; }
ppcom () { pcom `pppid ${1:-$$}`; }
ppppid () { pppid `ppid ${1:-$$}`; }
pppcom () { pcom `ppppid ${1:-$$}`; }
pppppid () { ppppid `ppid ${1:-$$}`; }
ppppcom () { pcom `pppppid ${1:-$$}`; }

# Override XTERM
_XTERM=`ppppcom`
echo $_XTERM | grep -q 'term'
[ $? -eq 0 ] && XTERM=$(basename `echo $_XTERM | tr ' ' '\n' | grep 'term'`)

XTERM=${XTERM:-$1}

echo $XTERM
