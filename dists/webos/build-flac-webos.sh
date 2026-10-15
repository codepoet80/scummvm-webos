#!/bin/bash
# build-flac-webos.sh — Cross-compile a static libFLAC for webOS
#
# Usage:
#   ./dists/webos/build-flac-webos.sh [deps-dir]
#
# Defaults:
#   deps-dir = ~/Projects/webos-deps
#
# Produces <deps-dir>/arm/{include/FLAC,lib/libFLAC.a}, which is passed to
# ScummVM's configure as --with-flac-prefix=<deps-dir>/arm.
#
# Notes:
#   - Static only, so no extra .so has to ship in the IPK.
#   - -fgnu89-inline is required: the PDK sysroot's glibc 2.5 headers use
#     GNU89 "extern inline" semantics. In GCC 4.9's default C99 mode they
#     emit duplicate definitions ("symbol `pread64' is already defined").
#   - Ogg FLAC, the C++ bindings and the command-line tools are disabled;
#     ScummVM only needs the native FLAC stream decoder.

set -e

DEPS_DIR="${1:-$HOME/Projects/webos-deps}"
WEBOS_PDK="${WEBOS_PDK:-/opt/PalmPDK}"
LINARO_BIN="${LINARO_BIN:-/opt/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabi/bin}"
FLAC_VERSION=1.3.4
FLAC_SHA256=8ff0607e75a322dd7cd6ec48f4f225471404ae2730d0ea945127b1355155e737

PREFIX="$DEPS_DIR/arm"
SRC_DIR="$DEPS_DIR/src"
TARBALL="flac-$FLAC_VERSION.tar.xz"
SYSROOT="$WEBOS_PDK/arm-gcc/sysroot"
CROSS="$LINARO_BIN/arm-linux-gnueabi"

if [ ! -x "$CROSS-gcc" ]; then
    echo "ERROR: Linaro GCC not found at $CROSS-gcc"
    echo "       Set LINARO_BIN env var to the Linaro bin directory."
    exit 1
fi

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "$TARBALL" ]; then
    echo "==> Downloading $TARBALL"
    curl -fSLO "https://downloads.xiph.org/releases/flac/$TARBALL"
fi
echo "$FLAC_SHA256  $TARBALL" | sha256sum -c -

rm -rf "flac-$FLAC_VERSION"
tar xf "$TARBALL"
cd "flac-$FLAC_VERSION"

echo "==> Configuring libFLAC $FLAC_VERSION"
CC="$CROSS-gcc" AR="$CROSS-ar" RANLIB="$CROSS-ranlib" STRIP="$CROSS-strip" \
CFLAGS="--sysroot=$SYSROOT -march=armv7-a -mfloat-abi=softfp -mfpu=neon -O2 -fPIC -fgnu89-inline" \
LDFLAGS="--sysroot=$SYSROOT" \
./configure \
    --host=arm-linux-gnueabi \
    --prefix="$PREFIX" \
    --disable-shared --enable-static \
    --disable-ogg --disable-oggtest \
    --disable-cpplibs --disable-programs --disable-examples \
    --disable-doxygen-docs --disable-xmms-plugin \
    --disable-asm-optimizations --disable-stack-smash-protection

echo "==> Building libFLAC"
make -C src/libFLAC -j"$(nproc)"
make -C src/libFLAC install
make -C include install

echo "==> Done: $PREFIX/lib/libFLAC.a"
