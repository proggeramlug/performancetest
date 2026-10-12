#!/bin/sh
# Builds all implementations into bin/. Override compiler paths via env:
#   PERRY, SCRIPTC, PORF, GO, RUSTC, CXX
# For a source-built Perry also set PERRY_SRC (checkout) and PERRY_RUNTIME_DIR
# (dir with libperry_runtime.a / libperry_stdlib.a, built via
#  cargo build --release -p perry -p perry-runtime-static -p perry-stdlib-static)
set -e
cd "$(dirname "$0")"
PERRY=${PERRY:-perry}; SCRIPTC=${SCRIPTC:-scriptc}; PORF=${PORF:-porf}
GO=${GO:-go}; RUSTC=${RUSTC:-rustc}; CXX=${CXX:-c++}
mkdir -p bin
node -e "const m=require('node:module'),f=require('fs');f.writeFileSync('bench.js',m.stripTypeScriptTypes(f.readFileSync('bench.ts','utf8')))" 2>/dev/null
"$GO" build -o bin/go bench.go
"$RUSTC" -C opt-level=3 -o bin/rust bench.rs
"$RUSTC" -C opt-level=3 -o bin/rust-arena bench-arena.rs
"$CXX" -std=c++17 -O2 -o bin/cpp bench.cpp
"$CXX" -std=c++17 -O2 -o bin/cpp-arena bench-arena.cpp
"$PERRY" compile bench.ts -o bin/perry
"$SCRIPTC" build bench.ts -o bin/scriptc
"$PORF" bench.js -o bin/porffor
{
  echo "date: $(date -u +%Y-%m-%dT%H:%MZ)"
  echo "os: $(uname -srm)"
  if [ "$(uname)" = Darwin ]; then echo "cpu: $(sysctl -n machdep.cpu.brand_string), $(sysctl -n hw.ncpu) cores"
  else echo "cpu: $(lscpu | sed -n 's/^Model name: *//p' | head -1), $(nproc) threads"; fi
  echo "node: $(node --version)"
  echo "perry: $("$PERRY" --version)"
  [ -n "$PERRY_SRC" ] && echo "perry-commit: $(git -C "$PERRY_SRC" log -1 --format='%H (%cd)' --date=iso)"
  [ -n "$PERRY_RUNTIME_DIR" ] && for a in "$PERRY_RUNTIME_DIR"/libperry_runtime.a "$PERRY_RUNTIME_DIR"/libperry_stdlib.a; do
    echo "perry-lib: $(basename "$a") $(ls -l "$a" | awk '{print $6, $7, $8}')"; done
  [ -n "$PERRY_NO_AUTO_OPTIMIZE" ] && echo "perry-env: PERRY_NO_AUTO_OPTIMIZE=$PERRY_NO_AUTO_OPTIMIZE"
  echo "scriptc: $("$SCRIPTC" --version)"
  echo "porffor: $("$PORF" --version | tail -1)"
  echo "go: $("$GO" version)"
  echo "rustc: $("$RUSTC" --version) (-C opt-level=3)"
  echo "c++: $("$CXX" --version | head -1) (-O2 -std=c++17)"
  echo "hyperfine: $(hyperfine --version)"
} > bin/versions.txt
cat bin/versions.txt
