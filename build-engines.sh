#!/bin/bash
ROOT=$(cd "$(dirname "$0")" && pwd)
OUT=${1:?output directory required}
NDK=${ANDROID_NDK:?ANDROID_NDK required}
COMPILER=${TARGET_COMPILE:-aarch64-linux-gnu-}
mkdir -p "$OUT" || exit 1
OUT=$(cd "$OUT" && pwd)
for VERSION in 0.13.8 0.13.9; do
    REF=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$ROOT/engines.json" "$VERSION") || exit 1
    SOURCE="$ROOT/.engine-build/$VERSION"
    if [ ! -d "$SOURCE" ]; then
        git -C "$ROOT" worktree add --detach "$SOURCE" "$REF" || exit 1
    fi
    make -C "$SOURCE/kernel" TARGET_COMPILE="$COMPILER" -j2 || exit 1
    for COMPONENT in tools user; do
        cmake -S "$SOURCE/$COMPONENT" -B "$SOURCE/$COMPONENT/build/android" -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" -DCMAKE_BUILD_TYPE=Release -DANDROID_PLATFORM=android-33 -DANDROID_ABI=arm64-v8a || exit 1
        cmake --build "$SOURCE/$COMPONENT/build/android" -j2 || exit 1
    done
    mkdir -p "$OUT/$VERSION" || exit 1
    cp "$SOURCE/kernel/kpimg" "$OUT/$VERSION/kpimg" || exit 1
    cp "$SOURCE/tools/build/android/kptools" "$OUT/$VERSION/kptools" || exit 1
    cp "$SOURCE/user/build/android/kpatch" "$OUT/$VERSION/kpatch" || exit 1
done