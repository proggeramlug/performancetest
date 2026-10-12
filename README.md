# performancetest: a GC-heavy program in TypeScript, Go, Rust and C++

One program, written four ways. The TypeScript version runs on Node, and is also compiled ahead of time to native code by [Perry](https://perryts.com), [scriptc](https://www.npmjs.com/package/scriptc) and [Porffor](https://github.com/CanadaHonk/porffor).

## The program

The program is the Benchmarks Game **binary-trees** shape, single-threaded, with `maxDepth = 21`.

- It allocates about **300 million short-lived** two-pointer nodes. These are trees from depth 4 to 20, each built, walked and dropped.
- It keeps one **long-lived** 4M-node tree alive for the whole run.
- Every implementation must print exactly the same output as Node. `run.sh` checks this.

| file | runs as |
|---|---|
| `bench.ts` | Node (type-stripped to `bench.js`), Perry, scriptc, Porffor (type-stripped `bench.js`) |
| `bench.go` | Go, with GC |
| `bench.rs` | Rust: `Box`, freed by ownership, no GC |
| `bench.cpp` | C++: `unique_ptr`, malloc/free, no GC |
| `bench-arena.rs` | Rust arena: nodes in one `Vec`, linked by `u32` index, `clear()` between trees |
| `bench-arena.cpp` | C++ arena: one `std::pmr::monotonic_buffer_resource` per tree, freed all at once |

Rust and C++ come in two variants each:

- **malloc/free** (`bench.rs`, `bench.cpp`) makes one heap allocation and one free per node. This is the straightforward way to write it.
- **arena** (`bench-arena.*`) bump-allocates each tree's nodes and drops the whole tree at once. The Benchmarks Game's fastest entries are built this way, and it is the realistic upper bound for this shape. It is also the pattern that a generational GC's young generation approximates automatically.

## Results

### Versions used

| | macOS | Linux |
|---|---|---|
| machine | Apple M1 Max, 10 cores, Darwin 25.5.0 arm64 | AMD Ryzen 7 7700X 8-Core Processor, 16 threads, Linux 6.17.0-23-generic x86_64 |
| Node | v26.5.1 | v26.8.1 |
| Perry | perry 0.5.1659 | perry 0.5.1659 |
| Perry commit | 996bc5d629dfbc4b0e99a377b6eeab57c32e54c6 (2026-10-12 04:40:53 +0200) | 996bc5d629dfbc4b0e99a377b6eeab57c32e54c6 (2026-10-12 04:40:53 +0200) |
| scriptc | 0.2.0 | 0.2.0 |
| Porffor | alpha 13 (547c781 2026-09-30) | alpha 13 (547c781 2026-09-30) |
| Go | go version go1.21.3 darwin/arm64 | go version go1.21.3 linux/amd64 |
| Rust | rustc 1.97.1 (8bab26f4f 2026-07-14) (-C opt-level=3) | rustc 1.98.0 (88d9e12ae 2026-08-18) (-C opt-level=3) |
| C++ compiler | Apple clang version 21.0.0 (clang-2100.1.1.101) (-O2 -std=c++17) | g++ (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0 (-O2 -std=c++17) |
| hyperfine | hyperfine 1.20.0 | hyperfine 1.20.0 |

Perry was built from source with `cargo build --release -p perry -p perry-runtime-static -p perry-stdlib-static` and linked with `PERRY_NO_AUTO_OPTIMIZE=1` on both machines. Its runtime and stdlib archives were rebuilt at that commit; their timestamps are in each `versions.txt`. Rust is 1.97.1 on macOS and 1.98.0 on Linux, both stable. Node is 26.5.1 on macOS and 26.8.1 on Linux, whatever each machine had installed.

### Numbers

| implementation | macOS time | macOS vs Node | macOS peak RSS | Linux time | Linux vs Node | Linux peak RSS |
|---|---:|---:|---:|---:|---:|---:|
| Rust arena | 2.10 s ± 0.05 | 0.31× | 100 MB | 1.56 s ± 0.01 | 0.24× | 98 MB |
| C++ arena | 2.65 s ± 0.03 | 0.39× | 167 MB | 2.22 s ± 0.03 | 0.34× | 131 MB |
| Node | 6.71 s ± 0.61 | 1.00× | 1482 MB | 6.57 s ± 0.05 | 1.00× | 1471 MB |
| C++ (unique_ptr) | 13.60 s ± 0.10 | 2.02× | 130 MB | 8.37 s ± 0.28 | 1.27× | 260 MB |
| Rust (Box) | 12.73 s ± 0.81 | 1.90× | 130 MB | 8.56 s ± 0.20 | 1.30× | 258 MB |
| **Perry** | 10.50 s ± 0.01 | 1.56× | 659 MB | 10.58 s ± 0.18 | 1.61× | 598 MB |
| Go | 14.21 s ± 0.30 | 2.12× | 222 MB | 13.34 s ± 0.08 | 2.03× | 190 MB |
| Porffor | 59.55 s ± 0.42 | 8.87× | 704 MB | 59.30 s ± 1.18 | 9.03× | 880 MB |
| scriptc | 65.79 s ± 0.58 | 9.80× | 1351 MB | 105.66 s ± 5.00 | 16.08× | 1346 MB |

Times are the mean ± standard deviation of 3 hyperfine runs. "vs Node" is time relative to Node on the same machine, where lower is faster. Peak RSS comes from one run under `/usr/bin/time`. All 9 implementations print output identical to Node on both machines.

How the numbers were measured:

- **macOS** used `run.sh` on a working desktop with load 5.5–13 on 10 cores, so it was not idle. A first full run ([`results/macos-m1max/run1`](results/macos-m1max/run1)) agrees within about 7% on every implementation.
- **Linux** is a shared server. Each implementation was timed separately, pinned to 2 cores / 4 threads, with load ≤ 2.9 at the start. See [`results/linux-ryzen7700x/NOTE.md`](results/linux-ryzen7700x/NOTE.md).

### What it shows

- **The arena versions are the fastest by far.** Rust with an arena runs in 1.6–2.1 s and uses about 100 MB. That is about 3–4× faster than Node, with 15× less memory. Freeing a whole tree at once beats any general-purpose allocator or GC on this workload.
- **Node beats the malloc/free versions of Rust and C++.** V8's generational GC allocates by bumping a pointer and reclaims dead young objects almost for free. The cost is memory: about 1.5 GB peak.
- **Perry takes about 1.6× Node's time and uses 40–45% of its memory.** It beats Go on both machines. Compared with malloc/free Rust and C++, the result depends on the platform: Perry is faster on macOS and slower on Linux, where glibc malloc is much faster for this pattern.
- **Porffor and scriptc are 9–16× slower than Node** on this workload, with scriptc using about as much memory as Node.

Raw data and exact versions are in [`results/`](results/).

## Caveats

- **Wall time only.** Node's V8 runs part of its GC concurrently on helper threads. Other runtimes may also use extra threads. User+sys CPU time is not compared here.
- Go 1.21.3 was used on both machines, which is not the latest.
- Neither machine was idle; see the measurement notes above.
- The Perry binary links the prebuilt full stdlib, so its size is not representative.
- These numbers come from one allocation-heavy microbenchmark. They are not a general ranking of these languages or compilers.

## Reproduce

```sh
# needs: node >= 23, go, rustc, a C++17 compiler, hyperfine, perry, scriptc, porffor
PERRY=perry SCRIPTC=scriptc PORF=porf ./build.sh
./run.sh 3 results/<machine>            # outputs, peak RSS, timing
# on a shared machine, time each implementation separately with a load gate / pinning:
WRAP='taskset -c 6,7,14,15 nice -n -10' MAXLOAD=3 ./run-gated.sh 3 results/<machine>
```
