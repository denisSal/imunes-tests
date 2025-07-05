# imunes-tests
Tests for the IMUNES network emulator.

[IMUNES](https://imunes.net) is a lightweight network emulator that runs on top
of the FreeBSD kernel which is used to create a virtual network topology by
using FreeBSD [jails](https://www.freebsd.org/doc/handbook/jails.html) and
[netgraph](https://www.freebsd.org/cgi/man.cgi?netgraph%284%29).

To run the tests, run (as root):
```
$ ./testAll.sh -j 4
```

The table below shows which tests work on Linux and FreeBSD operating systems.

|                  |    Linux    |   FreeBSD   |
|------------------|:-----------:|:-----------:|
| functional_tests |     YES     |     YES     |
| combinations     |     YES     |     YES     |
| services         |     YES     |     YES     |
