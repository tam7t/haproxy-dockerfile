# haproxy-dockerfile
haproxy docker image built with binary hardening &amp; libressl

# protections
This docker image aims to be a drop in replacement for the offical `haproxy`
image but built with binary hardening flags and statically linked against
LibreSSL.

* `-fPIE -DPIE` - Position independent code to take advantage of ASLR
* `-D_FORTIFY_SOURCE=2` - Replaces functions commonly resulting in buffer overflows
* `-fstack-protector-strong` - Adds cookies to detect buffer overflows in the stack
* `-fvisibility=hidden -flto -fsanitize=cfi -fuse-ld=gold` - Control Flow Integrity to block unexpected jumps
* `-z relro -z now` - Read only Global Offset Table to prevent GOT overwrite attacks

# references
* http://blog.quarkslab.com/clang-hardening-cheat-sheet.html
* https://blog.trailofbits.com/2016/10/17/lets-talk-about-cfi-clang-edition/
* https://wiki.debian.org/Hardening
