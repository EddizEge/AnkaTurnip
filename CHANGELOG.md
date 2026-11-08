# Anka Turnip changelog

## Anka Turnip 1.0.0

Base: Mesa `main` at `db6c407` (7 November 2026, 27.0.0-devel). Built for Android (aarch64,
KGSL) with NDK r28c. The library is the one Anka Native's Ocarina of Time runs used on a POCO F8
Pro (Adreno 830) from 7 November 2026, then called `up0`; only its name in `meta.json` and its
file name changed.

- Snapalloc window buffers (Android 15+ Qualcomm gralloc) are linear: no more striped picture on
  screen (patch 0001).
- Private memory per fiber is kept within the hardware's 8-bit size field; a shader that needs
  more fails to compile instead of breaking the shaders made after it (patch 0002).
- Faster compiles of large shaders: single-block function inlining, an index for
  `nir_opt_copy_prop_vars`, and the ir3 scheduler's address-register check (patches 0003-0005).
- Pipeline creation feedback reports cache hits and misses correctly (patch 0006).
- Compute shaders keep the per-wave private-memory layout: spills are one dword at a time
  (patch 0007).
