target remote :1234

python import time; print ("\nWaiting for 2 secs..."); time.sleep(2)
python print ("Executing gdb commands in local .gdbinit ...")

python print ("\n(gdb) break start")
b start
b _start

python import time; time.sleep(1)
python print ("\n(gdb) break main")
b main

python import time; time.sleep(1)
python print ("\n(gdb) continue")
c

python import time; time.sleep(1)
python print ("\n(gdb) backtrace")
bt

python import time; time.sleep(1)
python print ("\n(gdb) list")
l
