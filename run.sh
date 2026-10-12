#!/bin/sh
# Usage: ./run.sh [runs] [outdir]   — after ./build.sh
set -e
cd "$(dirname "$0")"
RUNS=${1:-3}; OUT=${2:-results/local}
mkdir -p "$OUT"; cp bin/versions.txt "$OUT/"
node bench.js > "$OUT/expected.txt"
if [ "$(uname)" = Darwin ]; then TIME="/usr/bin/time -l"; else TIME="/usr/bin/time -v"; fi
echo "| impl | output | peak RSS |" > "$OUT/rss.md"; echo "|---|---|---|" >> "$OUT/rss.md"
load() { if [ "$(uname)" = Darwin ]; then sysctl -n vm.loadavg | awk '{print $2}'; else cut -d" " -f1 /proc/loadavg; fi; }
echo "load before run: $(load)" > "$OUT/load.txt"
for t in node go rust rust-arena cpp cpp-arena perry scriptc porffor; do
  if [ $t = node ]; then set -- node bench.js; else set -- ./bin/$t; fi
  $TIME "$@" > out.txt 2> time.txt
  ok=$(cmp -s out.txt "$OUT/expected.txt" && echo match || echo DIFF)
  # macOS reports bytes, GNU time reports kbytes
  rss=$(awk '/maximum resident set size/{printf "%.0f MB", $1/1048576} /Maximum resident set size/{printf "%.0f MB", $NF/1024}' time.txt)
  echo "| $t | $ok | $rss |" >> "$OUT/rss.md"
  echo "load after $t RSS run: $(load)" >> "$OUT/load.txt"
done
rm -f out.txt time.txt
hyperfine --runs "$RUNS" --export-markdown "$OUT/time.md" \
  -n node 'node bench.js' -n go ./bin/go -n rust ./bin/rust -n cpp ./bin/cpp -n rust-arena ./bin/rust-arena -n cpp-arena ./bin/cpp-arena \
  -n perry ./bin/perry -n scriptc ./bin/scriptc -n porffor ./bin/porffor
echo "load after hyperfine: $(load)" >> "$OUT/load.txt"
cat "$OUT/rss.md" "$OUT/time.md" "$OUT/load.txt"
