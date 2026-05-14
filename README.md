code_lock
=====

An OTP application

Build
-----

    $ rebar3 compile

```bash
$ rebar3 compile
===> Verifying dependencies...
===> Analyzing applications...
===> Compiling code_lock
$ rebar3 shell
===> Verifying dependencies...
===> Analyzing applications...
===> Compiling code_lock
Erlang/OTP 25 [erts-13.2.2.5] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit:ns]

Eshell V13.2.2.5  (abort with ^G)
1> Locked
===> Booted code_lock
code_lock:button(1).
ok
2> code_lock:button(2).
ok
3> code_lock:button(3).
Open
ok
4> code_lock:button(3).
ok
5> code_lock:button(3).
ok
6> code_lock:button(ok).
New Code = [3,3]
Locked
ok
7> code_lock:button(1).
ok
8> code_lock:button(1).
ok
9> code_lock:button(1).
ok
10> code_lock:button(1).
ok
11> code_lock:button(1).
ok
12> code_lock:button(1).
Suspended
ok
13> code_lock:button(1).
Error
ok
14> Locked

[2]+  Остановлен    rebar3 shell
$ rebar3 eunit
===> Verifying dependencies...
===> Analyzing applications...
===> Compiling code_lock
===> Performing EUnit tests...
.......
Finished in 0.793 seconds
7 tests, 0 failures