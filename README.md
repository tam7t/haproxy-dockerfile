# haproxy-dockerfile
haproxy docker image built with binary hardening &amp; libressl

# motivation
I noticed that the existing docker images were not compiling `haproxy` with
many (if any) exploit mitigations (as of 11 March 2017) when using Debian's `hardening-check`

|                                 |  Debian apt-get  | Docker (alpine)  | Docker (debian)  |
|---------------------------------|------------------|------------------|------------------|
| Position Independent Executable | no               | yes              | no               |
| Stack protected                 | yes              | yes              | no               |
| Fortify Source functions        | yes (some)       | no               | no               |
| Read-only relocations           | yes              | yes              | no               |
| Immediate binding               | no               | yes              | no               |
| OpenSSL                         | 1.0.1t           | 1.0.2k           | 1.0.1t           |

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
