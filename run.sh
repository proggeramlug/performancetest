#!/bin/sh
# Usage: ./run.sh [runs] [outdir]   — after ./build.sh
set -e
cd "$(dirname "$0")"
. ./impls.sh
RUNS=${1:-3}; OUT=${2:-results/local}
mkdir -p "$OUT"; cp bin/versions.txt "$OUT/"
node bench.js > "$OUT/expected.txt"
if [ "$(uname)" = Darwin ]; then TIME="/usr/bin/time -l"; else TIME="/usr/bin/time -v"; fi
echo "| impl | output | peak RSS |" > "$OUT/rss.md"; echo "|---|---|---|" >> "$OUT/rss.md"
load() { if [ "$(uname)" = Darwin ]; then sysctl -n vm.loadavg | awk '{print $2}'; else cut -d" " -f1 /proc/loadavg; fi; }
echo "load before run: $(load)" > "$OUT/load.txt"
for t in $IMPLS; do
  $TIME $(impl_cmd $t) > out.txt 2> time.txt
  ok=$(cmp -s out.txt "$OUT/expected.txt" && echo match || echo DIFF)
  # macOS reports bytes, GNU time reports kbytes
  rss=$(awk '/maximum resident set size/{printf "%.0f MB", $1/1048576} /Maximum resident set size/{printf "%.0f MB", $NF/1024}' time.txt)
  echo "| $t | $ok | $rss |" >> "$OUT/rss.md"
  echo "load after $t RSS run: $(load)" >> "$OUT/load.txt"
done
rm -f out.txt time.txt
set --
for t in $IMPLS; do set -- "$@" -n "$t" "$(impl_cmd $t)"; done
hyperfine --runs "$RUNS" --export-markdown "$OUT/time.md" "$@"
echo "load after hyperfine: $(load)" >> "$OUT/load.txt"
cat "$OUT/rss.md" "$OUT/time.md" "$OUT/load.txt"
