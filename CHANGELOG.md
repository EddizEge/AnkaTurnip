# Anka Turnip changelog

## Anka Turnip 1.0.1

Base: Mesa `main` at `db6c407`, as in 1.0.0. Built for Android (aarch64, KGSL) with NDK r28c.
It is 1.0.0 plus two fixes from newer Mesa. It does **not** fix the Adreno 840 hang (Anka Native
[#5](https://github.com/EddizEge/AnkaNative/issues/5)).

- Unused shader stage base registers are cleared on Adreno 8xx (Mesa `78fd465cef84`,
  patch 0008).
- The driver waits before it reads registers it has just written (Mesa `1c87c6018706`,
  patch 0009; every GPU).
- Tested on the Adreno 830 (POCO F8 Pro) only, with Anka Native's Ocarina of Time: the same
  speed and picture as 1.0.0, no device loss. Peak memory of the game was higher: 3.51 GB,
  against 3.27-3.38 GB with 1.0.0; we have not shown whether this is noise.
- Adreno 840: an owner of one tested the 1.0.1 test build and the device was still lost, the
  same way as with 1.0.0. The test build's extra Adreno 840 change
  (`AnkaTurnip-1.0.1-a840ccu.zip`) did not help either and is not in this release.

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
