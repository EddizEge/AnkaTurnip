# Notices

Anka Turnip is a build of **Mesa**'s Turnip Vulkan driver with a few patches. It contains no
code of its own beyond the patches in `patches/`.

## Mesa

- Project: https://mesa3d.org, source https://gitlab.freedesktop.org/mesa/mesa
- Base: the `main` branch at commit `db6c407405a4353a1029704a344b565cf7f1fa48`
  (7 November 2026, "kk: Fix disabling all workarounds"), version 27.0.0-devel.
- License: most of Mesa, and every file the patches change, is under the MIT license (`LICENSE`).
  Individual Mesa files may carry other licenses: each file's SPDX header and Mesa's
  `docs/license.rst` and `licenses/` directory are authoritative.
- Turnip (`src/freedreno/vulkan`), the ir3 compiler (`src/freedreno/ir3`), NIR
  (`src/compiler/nir`) and the Mesa utility and Vulkan runtime code linked into the driver are
  the work of the Mesa and freedreno contributors; their names are in the file headers and in
  Mesa's git history.

## Also compiled into the driver library

These come with the Mesa source at that commit (or the Android NDK) and keep their own licenses:

- **BLAKE3** (`src/util/blake3`): CC0-1.0 OR Apache-2.0.
- **xxHash** (`src/util/xxhash.h`), Yann Collet: BSD-2-Clause.
- **Qualcomm KGSL kernel interface header** (`src/freedreno/vulkan/msm_kgsl.h`): GPL-2.0 WITH
  Linux-syscall-note; used only for the kernel interface definitions, which the syscall note
  covers.
- **LLVM libc++** from the Android NDK, linked statically (`-static-libstdc++`):
  Apache-2.0 WITH LLVM-exception.

The library links Android's own system libraries (libc, libm, libdl, liblog, libz, libsync,
libhardware, libnativewindow) at run time; they are not part of this package.

## Trademarks

Vulkan is a registered trademark of the Khronos Group Inc. Adreno and Snapdragon are trademarks
of Qualcomm Incorporated. This project is not affiliated with Mesa, freedreno, the Khronos Group
or Qualcomm.
