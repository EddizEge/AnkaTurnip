#!/bin/sh
# Builds Anka Turnip: Mesa main at MESA_COMMIT with patches/ applied, for Android (aarch64, Qualcomm's
# KGSL kernel driver), then packs the driver zip Anka Native installs.
#
# Needs: git, meson (1.12.1 was used), ninja, python3 with mako, packaging and PyYAML, bison, flex,
# glslangValidator, zip, and an Android NDK (r28c, 28.2.13676358, was used).
#
#   ANDROID_NDK_HOME=/path/to/ndk ./build.sh
#
# Optional:
#   MESA_SRC=<dir>  use this Mesa checkout instead of fetching one (at MESA_COMMIT, with no changes other than patches/)
#   WORK=<dir>      where the source, the build and the zip go (default: ./work)
set -eu

VERSION=1.0.0
MESA_COMMIT=db6c407405a4353a1029704a344b565cf7f1fa48
MESA_URL=https://gitlab.freedesktop.org/mesa/mesa.git
LIBRARY=vulkan.anka_turnip.so

HERE=$(cd "$(dirname "$0")" && pwd)
WORK=${WORK:-$HERE/work}
NDK=${ANDROID_NDK_HOME:?set ANDROID_NDK_HOME to an Android NDK (r28c was used)}
BIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin
[ -x "$BIN/aarch64-linux-android34-clang" ] || { echo "no aarch64-linux-android34-clang in $BIN" >&2; exit 1; }
mkdir -p "$WORK"

# 1. The Mesa source at MESA_COMMIT
if [ -n "${MESA_SRC:-}" ]; then
    SRC=$MESA_SRC
    [ "$(git -C "$SRC" rev-parse HEAD)" = "$MESA_COMMIT" ] || { echo "$SRC is not at $MESA_COMMIT" >&2; exit 1; }
else
    SRC=$WORK/mesa
    if [ ! -d "$SRC/.git" ]; then
        git init -q "$SRC"
        git -C "$SRC" remote add origin "$MESA_URL"
        git -C "$SRC" fetch --depth 1 origin "$MESA_COMMIT" || git -C "$SRC" fetch origin
    fi
    git -C "$SRC" checkout -q --detach "$MESA_COMMIT"
    git -C "$SRC" reset -q --hard
fi

# 2. The patches, in order (a tree that already has them is left as it is)
for p in "$HERE"/patches/*.patch; do
    if git -C "$SRC" apply --check "$p" 2>/dev/null; then
        git -C "$SRC" apply "$p"
    elif git -C "$SRC" apply --check --reverse "$p" 2>/dev/null; then
        echo "already applied: $(basename "$p")"
    else
        echo "does not apply: $p" >&2; exit 1
    fi
done

# 3. The cross file and the build (the options of the released build). The build folder is inside
#    the source tree, as for the release: Mesa's assert and log messages keep source paths
#    relative to it (../src/...), so another folder gives a different library.
BUILD=$SRC/build-android
cat > "$WORK/android-aarch64.ini" <<INI
[binaries]
ar = '$BIN/llvm-ar'
c = ['$BIN/aarch64-linux-android34-clang']
cpp = ['$BIN/aarch64-linux-android34-clang++']
c_ld = 'lld'
cpp_ld = 'lld'
strip = '$BIN/llvm-strip'
pkg-config = ['env', 'PKG_CONFIG_LIBDIR=', '/usr/bin/false']
[host_machine]
system = 'android'
cpu_family = 'aarch64'
cpu = 'armv8'
endian = 'little'
INI

if [ ! -f "$BUILD/build.ninja" ]; then
    meson setup "$BUILD" "$SRC" \
        -Dbuildtype=release -Dplatforms=android -Dplatform-sdk-version=36 -Dandroid-stub=true \
        -Dgallium-drivers= -Dvulkan-drivers=freedreno -Dfreedreno-kmds=kgsl \
        -Dandroid-libbacktrace=disabled -Db_lto=false -Dllvm=disabled -Dzstd=disabled \
        -Dexpat=disabled -Dvalgrind=disabled -Degl=disabled -Dopengl=false -Dgles1=disabled \
        -Dgles2=disabled -Dglx=disabled -Dgbm=disabled -Dcpp_link_args=-static-libstdc++ \
        -Dandroid-strict=false --cross-file="$WORK/android-aarch64.ini"
fi
ninja -C "$BUILD" src/freedreno/vulkan/libvulkan_freedreno.so

# 4. The driver zip: the stripped library, meta.json and the license notices
PKG=$WORK/pkg
rm -rf "$PKG"; mkdir -p "$PKG"
"$BIN/llvm-strip" -o "$PKG/$LIBRARY" "$BUILD/src/freedreno/vulkan/libvulkan_freedreno.so"
sed -e "s/@VERSION@/$VERSION/g" -e "s/@LIBRARY@/$LIBRARY/g" "$HERE/pkg/meta.json.in" > "$PKG/meta.json"
cp "$HERE/LICENSE" "$PKG/LICENSE.txt"
cp "$HERE/NOTICE.md" "$PKG/NOTICE.md"
ZIP=$WORK/AnkaTurnip-$VERSION.zip
rm -f "$ZIP"
(cd "$PKG" && zip -q -X "$ZIP" meta.json "$LIBRARY" LICENSE.txt NOTICE.md)
sha256sum "$PKG/$LIBRARY" "$ZIP"
