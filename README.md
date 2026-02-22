# libCF
libcellfrontend - is a (kinda) lightweight frontend for cellular automatons. You define the functions that act on cells. It is also *cpu based*, which means it only uses GPU to render things. That is intentional, because it gives the user more power and flexibility.

# How to build
```bash
zig build -Doptimize=ReleaseFast
./zig-out/bin/lcf
```
