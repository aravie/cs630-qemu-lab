shell echo -e "\nWaiting for 2 secs..."
shell sleep 2
shell echo -e "Executing gdb commands in local .gdbinit ..."

shell echo -e "\ngdb target remote :1234"
target remote :1234

shell sleep 1
shell echo -e "\ngdb break start"
b start
b _start

shell sleep 1
shell echo -e "\ngdb break main"
b main

shell sleep 1
shell echo -e "\ngdb continue"
c

shell sleep 1
shell echo -e "\ngdb backtrace"
bt

shell sleep 1
shell echo -e "\ngdb list"
l
