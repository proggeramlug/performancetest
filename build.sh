#!/bin/sh
# Builds all implementations into bin/. Override compiler paths via env:
#   PERRY, SCRIPTC, PORF, GO, RUSTC, CXX, SWIFTC, KOTLINC, JAVA (java binary that runs the Kotlin jar)
# For a source-built Perry also set PERRY_SRC (checkout) and PERRY_RUNTIME_DIR
# (dir with libperry_runtime.a / libperry_stdlib.a, built via
#  cargo build --release -p perry -p perry-runtime-static -p perry-stdlib-static)
set -e
cd "$(dirname "$0")"
PERRY=${PERRY:-perry}; SCRIPTC=${SCRIPTC:-scriptc}; PORF=${PORF:-porf}
GO=${GO:-go}; RUSTC=${RUSTC:-rustc}; CXX=${CXX:-c++}
SWIFTC=${SWIFTC:-swiftc}; KOTLINC=${KOTLINC:-kotlinc}; JAVA=${JAVA:-java}
mkdir -p bin
node -e "const m=require('node:module'),f=require('fs');for(const n of ['bench','bench-arena'])f.writeFileSync(n+'.js',m.stripTypeScriptTypes(f.readFileSync(n+'.ts','utf8')))" 2>/dev/null
"$GO" build -o bin/go bench.go
"$RUSTC" -C opt-level=3 -o bin/rust bench.rs
"$RUSTC" -C opt-level=3 -o bin/rust-arena bench-arena.rs
"$CXX" -std=c++17 -O2 -o bin/cpp bench.cpp
"$CXX" -std=c++17 -O2 -o bin/cpp-arena bench-arena.cpp
"$SWIFTC" -O bench.swift -o bin/swift
"$KOTLINC" bench.kt -include-runtime -d bin/kotlin.jar 2>/dev/null
printf '#!/bin/sh\nexec "%s" -jar "$(dirname "$0")/kotlin.jar"\n' "$JAVA" > bin/kotlin; chmod +x bin/kotlin
"$PERRY" compile bench.ts -o bin/perry
"$PERRY" compile bench-arena.ts -o bin/perry-arena
"$SCRIPTC" build bench.ts -o bin/scriptc
"$SCRIPTC" build bench-arena.ts -o bin/scriptc-arena
"$PORF" bench.js -o bin/porffor
"$PORF" bench-arena.js -o bin/porffor-arena
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
  echo "swift: $("$SWIFTC" --version 2>&1 | grep -m1 -i 'swift version') (-O)"
  echo "kotlin: $("$KOTLINC" -version 2>&1 | tail -1)"
  echo "jvm (runs kotlin): $("$JAVA" -version 2>&1 | head -2 | tr '\n' ' ')(default GC, no flags)"
  echo "hyperfine: $(hyperfine --version)"
} > bin/versions.txt
cat bin/versions.txt
