# Anka Turnip

**Anka Turnip — Mesa's Turnip Vulkan driver for Adreno 8xx phones, built for Anka Native.**
This release is **Anka Turnip 1.0.0**: Mesa `main` at commit `db6c407` with seven small patches.

Not affiliated with Mesa, freedreno, Qualcomm or Nintendo; please report problems in this
repository's Issues, not to them. https://github.com/EddizEge/AnkaTurnip/issues

## The name

Anka is the Zümrüdüanka of Turkish myth, the phoenix that rises from its ashes; Anka Native is
the Android app this driver is made for. Turnip is the name of Mesa's open-source Vulkan driver
for Qualcomm Adreno GPUs.

## At a glance

- **What it is:** a Vulkan driver (`vulkan.anka_turnip.so`) in the zip layout Android emulators
  use for custom GPU drivers: the library and a `meta.json` that names it. Anka Native loads it
  through its **GPU driver** setting instead of the phone's own Qualcomm driver.
- **Base:** Mesa `main`, commit `db6c407405a4353a1029704a344b565cf7f1fa48` (7 November 2026),
  version 27.0.0-devel. A development snapshot, not a Mesa release.
- **Built for:** Android, aarch64, Qualcomm's KGSL kernel driver (the one phones ship with),
  Android NDK r28c, API level 34 or newer.
- **Patches:** `patches/`, described below. All of them are general fixes; none is specific to a
  game.
- **Tested on one phone:** a Xiaomi POCO F8 Pro (Snapdragon 8 Elite, Adreno 830, 12 GB,
  Android 16), with the Ocarina of Time remake in Anka Native. Other phones, other Adreno GPUs
  and other games were not tried with this build.

## What you need

- An Android phone with a Snapdragon / Adreno 8xx GPU, Android 14 (API 34) or newer. Only an
  Adreno 830 was tried.
- **Anka Native**, or another app that installs custom Vulkan drivers in this zip layout.
- Your own legally owned game dumps for the app. This driver contains no game content, keys or
  firmware.

## Download and check

The release has `AnkaTurnip-1.0.0.zip` and `SHA256SUMS.txt`. Do not unpack the zip: the app
installs it as it is. To check a download on a PC: `sha256sum -c SHA256SUMS.txt --ignore-missing`
(Linux, macOS, Git Bash), or `certutil -hashfile AnkaTurnip-1.0.0.zip SHA256` in a Windows
command prompt and compare with the file.

The zip holds `meta.json`, `vulkan.anka_turnip.so`, `LICENSE.txt` and `NOTICE.md`. The library's
own SHA-256 is `178d66ffe240b527aa0689db5940a9977374764974eebf69a88db9e0a186dc4b`.

## Install

In Anka Native:

1. **Settings › GPU driver › Install… › Pick a zip…** and choose `AnkaTurnip-1.0.0.zip`. (Or
   copy the zip to the app's `Android/data/<app>/files/gpu_drivers/` folder first; the
   installer lists it there.)
2. Pick **Anka Turnip 1.0.0** in the list. It is then the driver of every game that has no
   choice of its own.
3. For one game only: the game's **⋯ › Game settings › GPU driver**.
4. The choice takes effect the next time a game starts. **System** goes back to the phone's own
   driver.

The app unpacks the zip into its private files (`files/gpu_drivers/Anka_Turnip_1.0.0/`). A zip
with the same name in `meta.json` replaces the installed copy.

## The patches

Applied in this order to `db6c407`. Each file is one topic.

| Patch | What it changes | Why |
|---|---|---|
| `0001-u_gralloc-linear-modifier-for-snapalloc-buffers` | Buffers from Qualcomm's newer gralloc (snapalloc, Android 15+) are treated as linear. | Their handles carry no `gmsm` magic, so the fallback gralloc gave no modifier and Turnip tiled a linear window buffer: the picture on screen was vertical stripes while the frame itself was right. |
| `0002-tu-keep-pvtmem-size-within-the-hardware-field` | Turnip's private-memory (spill) size per fiber is kept within what the 8-bit hardware field holds; a shader that needs more fails to compile instead; a failed grow forgets the freed buffer. | A shader that needed 96,256 bytes a fiber was rounded to 128 KiB, which wraps the field to 0: every program set up after it in the process read its spilled values as zeros. |
| `0003-nir-inline-single-block-functions-without-splitting` | Inlining a function whose body is one block moves its instructions in place. | Splitting and re-joining the block for each call made inlining many calls into one block quadratic. |
| `0004-nir-index-copy-prop-vars-lookups` | `nir_opt_copy_prop_vars` looks up array derefs in a hash index instead of comparing with every entry. | Large shaders spent much of their compile time in `nir_compare_deref_paths`. The lookup returns the same entry as the linear search. |
| `0005-ir3-sched-check-address-users-through-uses` | The ir3 scheduler finds the users of an address register write through its uses. | It scanned every indirect instruction of the shader for each check, which made scheduling large blocks quadratic (`check_instr`). |
| `0006-tu-pipeline-creation-feedback-on-cache-hits` | Pipeline creation feedback is right on cache misses and filled per stage on hits. | A fully compiled pipeline reported `APPLICATION_PIPELINE_CACHE_HIT`, so the app could not tell new compiles from cache hits. |
| `0007-ir3-spill-dword-by-dword-in-compute` | On a6xx and newer, compute shaders spill and reload one dword at a time. | A single multi-dword spill dropped the whole shader from the per-wave private-memory layout to the slower per-fiber one. |

## Measured results

- **Picture on screen (patch 0001), phone:** Mesa main without it showed vertical stripes; with
  it the Ocarina of Time title screen was right on screen at 60 fps.
- **Memory, phone:** at the same title screen, Mesa main at this commit used about 3.5 GB less
  GPU memory (`GL mtrack`) than the third-party Turnip build used before. This is a property of
  the base commit, not of the patches.
- **Compile time (patches 0003-0005), PC:** compiled with this driver's compiler on a PC (Mesa's
  drm-shim, as an Adreno 830), three heavy fragment shaders of the game took 5.4-6.4 s each
  before and 2.0-2.2 s with the patches, one run each. The generated code was the same for all
  21 shader variants compared. On the phone these shaders took 13-29 s each before; the phone
  time with the patches was not measured separately.
- **Spills in compute (patch 0007), PC:** in two large compute shaders, multi-dword spill
  instructions went from 52 and 36 to 0, and Turnip no longer warns that it falls back to the
  per-fiber layout. Not timed on the phone by itself.
- **In use:** this exact library (SHA-256 above) was the driver of the Ocarina of Time runs that
  reached Kokiri Forest on the POCO F8 Pro (7-8 November 2026).

## Known issues

- **One phone, one game.** Only the Adreno 830 in a POCO F8 Pro and only the Ocarina of Time
  remake were tried. Donkey Kong Bananza and Mario Kart World were not run with this build.
- **Patches 0002 and 0006 were not checked on the phone by themselves.** 0002 makes a shader
  that needs more than 127.5 KiB of private memory a fiber fail to compile
  (`VK_ERROR_OUT_OF_DEVICE_MEMORY`) instead of breaking the shaders made after it.
- **Patch 0007** splits half-register spills into 2-byte accesses too; the compute shaders
  checked had no half-register spills.
- **The pipeline cache is per driver.** Switching to this driver from another one means the
  game's shaders are compiled again once.
- **Large shaders still take seconds to compile** the first time; Anka Native keeps them in its
  pipeline cache for later runs.
- A development snapshot of Mesa: other Vulkan features may behave differently from a Mesa
  release or from the phone's own driver.

## How to build

On Linux, with git, meson (1.12.1 was used), ninja, python3 with `mako`, `packaging` and
`PyYAML`, bison, flex, glslangValidator, zip and the Android NDK r28c:

```sh
ANDROID_NDK_HOME=/path/to/android-ndk ./build.sh
```

`build.sh` fetches Mesa at `db6c407` (or uses `MESA_SRC=<a clean checkout at that commit>`),
applies `patches/` in order, writes a cross file for the NDK, configures with the options of the
release build, builds `libvulkan_freedreno.so` (in `<mesa>/build-android`), strips it and packs
`work/AnkaTurnip-1.0.0.zip`. The meson options are in the script. To apply the patches by hand:
`git -C <mesa> apply patches/*.patch`.

The build is reproducible: on Linux with NDK r28c (28.2.13676358) and meson 1.12.1, `build.sh`
gave a library byte-identical to the released one (SHA-256 `178d66ff…`). The build folder must
stay inside the Mesa tree, as the script puts it: the library keeps source paths relative to it
in its messages, so another folder gives different bytes.

## License

Like Mesa's Turnip, Anka Turnip is under the **MIT license** (`LICENSE`): Mesa's copyright
holders for Mesa, EddizEge for the patches and this repository. Individual Mesa files may carry
other licenses (their SPDX headers; Mesa's `docs/license.rst`). The other code compiled into the
library (BLAKE3, xxHash, the KGSL interface header, the NDK's libc++) and its licenses are listed
in `NOTICE.md`.

Vulkan is a registered trademark of the Khronos Group Inc. Adreno and Snapdragon are trademarks
of Qualcomm Incorporated. Nintendo and its games are trademarks of Nintendo. This project has no
affiliation with any of them. Use Anka Native only with games you legally own.
