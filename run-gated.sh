#!/bin/sh
# Like run.sh's timing pass, but for shared/noisy machines: each implementation is
# timed separately, only once the 1-min load average is below MAXLOAD, and the load
# at start/end is recorded next to the result.
# Usage: MAXLOAD=2 ./run-gated.sh [runs] [outdir]   — after ./build.sh
# Optional WRAP prefixes hyperfine, e.g. WRAP='taskset -c 6,7,14,15 nice -n -10' MAXLOAD=999
set -e
cd "$(dirname "$0")"
RUNS=${1:-3}; OUT=${2:-results/local}; MAXLOAD=${MAXLOAD:-2}
mkdir -p "$OUT"; [ -n "$WRAP" ] && echo "WRAP: $WRAP" > "$OUT/gated-wrap.txt"
load() { if [ "$(uname)" = Darwin ]; then sysctl -n vm.loadavg | awk '{print $2}'; else cut -d" " -f1 /proc/loadavg; fi; }
for t in node go rust rust-arena cpp cpp-arena perry scriptc porffor; do
  if [ $t = node ]; then cmd='node bench.js'; else cmd="./bin/$t"; fi
  while [ "$(load | cut -d. -f1)" -ge "$MAXLOAD" ]; do sleep 30; done
  l0=$(load)
  $WRAP hyperfine --runs "$RUNS" -n "$t" --export-json "$OUT/time-$t.json" "$cmd"
  echo "$t $l0 $(load)" >> "$OUT/gated-load.txt"
done
node -e '
const fs=require("fs"),out=process.argv[1];
const rows=fs.readFileSync(out+"/gated-load.txt","utf8").trim().split("\n").map(l=>l.split(" "));
let md="| impl | mean [s] | min [s] | max [s] | load at start | load at end |\n|---|---:|---:|---:|---:|---:|\n";
for (const [t,l0,l1] of rows) {
  const r=JSON.parse(fs.readFileSync(`${out}/time-${t}.json`)).results[0];
  md+=`| ${t} | ${r.mean.toFixed(3)} ± ${r.stddev.toFixed(3)} | ${r.min.toFixed(3)} | ${r.max.toFixed(3)} | ${l0} | ${l1} |\n`;
}
fs.writeFileSync(out+"/time-gated.md",md); process.stdout.write(md);' "$OUT"
