# performancetest: a GC-heavy program in 7 languages, 15 builds

One program, written as TypeScript, Go, Swift, Kotlin, Rust and C++. The TypeScript runs on Node and is also compiled ahead of time to native code by [Perry](https://perryts.com), [scriptc](https://www.npmjs.com/package/scriptc) and [Porffor](https://github.com/CanadaHonk/porffor). TypeScript, Rust and C++ also get an "arena" variant: memory managed by hand, specialised for this workload.

## The program

The program is the Benchmarks Game **binary-trees** shape, single-threaded, with `maxDepth = 21`.

- It allocates about **300 million short-lived** two-pointer nodes. These are trees from depth 4 to 20, each built, walked and dropped.
- It keeps one **long-lived** 4M-node tree alive for the whole run.
- Every build must print exactly the same output as Node. The scripts check this, and all 15 match on both machines.

| file | memory model | runs as |
|---|---|---|
| `bench.ts` | GC | Node, Perry, scriptc, Porffor (Node and Porffor get the type-stripped `bench.js`) |
| `bench.go` | GC | Go |
| `bench.kt` | GC (JVM default, no flags) | Kotlin on the JVM |
| `bench.swift` | reference counting (ARC) | Swift |
| `bench.rs` | ownership, `Box`, one malloc/free per node | Rust |
| `bench.cpp` | ownership, `unique_ptr`, one malloc/free per node | C++ |
| `bench-arena.ts` | manual: nodes are indices into two `Int32Array`s, reset per tree | Node, Perry, scriptc, Porffor |
| `bench-arena.rs` | manual: nodes in one `Vec`, linked by `u32` index, `clear()` per tree | Rust |
| `bench-arena.cpp` | manual: one `std::pmr::monotonic_buffer_resource` per tree | C++ |

## Versions used

| | macOS | Linux |
|---|---|---|
| machine | Apple M1 Max, 10 cores (Darwin 25.5.0 arm64) | AMD Ryzen 7 7700X 8-Core Processor, 16 threads (Linux 6.17.0-23-generic x86_64) |
| Node | v26.5.1 | v26.8.1 |
| Perry | perry 0.5.1659 | perry 0.5.1659 |
| Perry commit | 7bdf9b9d3a8959b6965f997a32ea92b97dd0fa99 (2026-10-13 07:15:58 +0200) | 7bdf9b9d3a8959b6965f997a32ea92b97dd0fa99 (2026-10-13 07:15:58 +0200) |
| scriptc | 0.3.0 | 0.3.0 |
| Porffor | alpha 17 (731f1b2 2026-10-10) | alpha 17 (731f1b2 2026-10-10) |
| Go | go1.21.3 darwin/arm64 | go1.21.3 linux/amd64 |
| Swift | Apple Swift version 6.3.3 (swiftlang-6.3.3.1.3 clang-2100.1.1.101) (-O) | Swift version 6.3.3 (swift-6.3.3-RELEASE) (-O) |
| Kotlin | kotlinc-jvm 2.3.21 (JRE 26.0.2) | kotlinc-jvm 2.3.21 (JRE 26.0.2.1+1) |
| JVM for Kotlin | openjdk version "26.0.2" 2026-07-21 OpenJDK Runtime Environment Homebrew (build 26.0.2) (default GC, no flags) | openjdk version "26.0.2.1" 2026-08-18 OpenJDK Runtime Environment Temurin-26.0.2.1+1 (build 26.0.2.1+1) (default GC, no flags) |
| Rust | rustc 1.97.1 (8bab26f4f 2026-07-14) (-C opt-level=3) | rustc 1.98.0 (88d9e12ae 2026-08-18) (-C opt-level=3) |
| C++ compiler | Apple clang version 21.0.0 (clang-2100.1.1.101) (-O2 -std=c++17) | g++ (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0 (-O2 -std=c++17) |
| hyperfine | hyperfine 1.20.0 | hyperfine 1.20.0 |

Measured 2026-10-13. Perry was built from source at main `7bdf9b9d3a` with `cargo build --release -p perry -p perry-runtime-static -p perry-stdlib-static` and linked with `PERRY_NO_AUTO_OPTIMIZE=1` on both machines. Its runtime and stdlib archives were rebuilt at that commit; their timestamps are in each `versions.txt`. Perry (main), scriptc and Porffor are the latest versions as of that date; this was checked. The other toolchains are what each machine had installed, or recent releases installed for this test. Go 1.21.3 is notably old. The two machines differ in Node (26.5.1 vs 26.8.1) and Rust (1.97.1 vs 1.98.0, stable on both).

## Results

Times are the mean ± standard deviation of hyperfine runs. "vs Node" is time relative to Node on the same machine, where lower is faster. RSS is peak resident memory from one run under `/usr/bin/time`. Rows are sorted by the average of the two "vs Node" columns. All 15 builds print output identical to Node on both machines.

### Idiomatic code

| implementation | macOS | vs Node | macOS RSS | Linux | vs Node | Linux RSS |
|---|---:|---:|---:|---:|---:|---:|
| Kotlin (JVM) | 3.22 s ± 0.52 | 0.50× | 5782 MB | 2.72 s ± 0.02 | 0.41× | 3242 MB |
| scriptc | 7.75 s ± 0.12 | 1.20× | 257 MB | 4.97 s ± 0.06 | 0.75× | 260 MB |
| Node | 6.45 s ± 0.29 | 1.00× | 1481 MB | 6.59 s ± 0.01 | 1.00× | 1472 MB |
| **Perry** | 7.93 s ± 0.10 | 1.23× | 666 MB | 5.97 s ± 0.01 | 0.91× | 591 MB |
| Rust (Box) | 12.30 s ± 0.01 | 1.91× | 130 MB | 8.39 s ± 0.05 | 1.27× | 258 MB |
| C++ (unique_ptr) | 13.73 s ± 0.15 | 2.13× | 130 MB | 8.33 s ± 0.12 | 1.26× | 260 MB |
| Go | 14.52 s ± 0.15 | 2.25× | 212 MB | 13.20 s ± 0.06 | 2.00× | 192 MB |
| Swift (ARC) | 23.91 s ± 0.33 | 3.70× | 259 MB | 15.28 s ± 0.32 | 2.32× | 393 MB |
| Porffor | 60.57 s ± 1.01 | 9.38× | 704 MB | 51.14 s ± 0.19 | 7.76× | 704 MB |

### Arena variants (hand-managed memory)

The Node row is repeated for reference.

| implementation | macOS | vs Node | macOS RSS | Linux | vs Node | Linux RSS |
|---|---:|---:|---:|---:|---:|---:|
| Rust arena | 2.10 s ± 0.00 | 0.33× | 102 MB | 1.55 s ± 0.02 | 0.23× | 98 MB |
| C++ arena | 2.77 s ± 0.17 | 0.43× | 166 MB | 2.22 s ± 0.00 | 0.34× | 131 MB |
| scriptc, typed-array arena | 4.99 s ± 0.06 | 0.77× | 98 MB | 3.35 s ± 0.01 | 0.51× | 98 MB |
| Node, typed-array arena | 6.96 s ± 0.28 | 1.08× | 154 MB | 4.28 s ± 0.03 | 0.65× | 149 MB |
| Node | 6.45 s ± 0.29 | 1.00× | 1481 MB | 6.59 s ± 0.01 | 1.00× | 1472 MB |
| **Perry**, typed-array arena | 8.65 s ± 0.07 | 1.34× | 105 MB | 5.85 s ± 0.07 | 0.89× | 107 MB |
| Porffor, typed-array arena | 17.75 s ± 1.06 | 2.75× | 98 MB | 13.40 s ± 0.00 | 2.03× | 98 MB |

How the numbers were measured:

- **Linux** is a shared server. Each build was timed separately (3 runs), pinned to 2 cores / 4 threads, and started at load below 3; actual load was 1.0–1.9. See [`results/linux-ryzen7700x/NOTE.md`](results/linux-ryzen7700x/NOTE.md).
- **macOS** is a working desktop with background load of 5.6–13.3 on 10 cores. Node and Perry rows use a 5-run re-time; the others come from one 3-run pass. See [`results/macos-m1max/NOTE.md`](results/macos-m1max/NOTE.md). The Linux numbers are the cleaner reference.
- Earlier rounds are kept in [`results/archive-v1`](results/archive-v1) and [`results/archive-v2`](results/archive-v2). Between round 2 (2026-10-12) and this round, Perry went from 10.7 s to 6.0 s (plain) and from 31.8 s to 5.8 s (arena) on Linux. That window includes four fixes that came out of profiling this benchmark (#12468, #12473, #12491, #12499) plus other work merged to main in the meantime.

## What it shows

- **The Rust and C++ arenas are the fastest by far,** at 1.5–2.8 s and 100–170 MB. Freeing a whole tree at once beats every general-purpose allocator and GC on this workload.
- **Kotlin/JVM is the fastest idiomatic build,** at 0.41–0.50× Node's time, but it uses 3.2–5.8 GB because the JVM claims up to ¼ of RAM by default.
- **Perry beats Node on Linux (0.91×) and trails it on macOS (1.23×),** using 40–45% of Node's memory. It now beats malloc/free Rust and C++, Go and Swift on both machines.
- **scriptc 0.3.0 is the fastest AOT TypeScript compiler here,** at 0.75× Node on Linux and 1.20× on macOS, with only about 258 MB. Version 0.2.9 used reference counting instead of a GC (seen in a profile); 0.3.0 shows the same memory pattern but was not re-profiled.
- **Swift (ARC) is the slowest of the non-JS languages here,** at 2.3–3.7× Node. Every node creation and release updates a reference count.
- **Porffor is 7.8–9.4× Node's time** on this workload.

## Speeding up the TypeScript versions

`bench-arena.ts` is the TypeScript equivalent of the Rust and C++ arenas. It uses a struct-of-arrays layout: node fields live in two preallocated `Int32Array`s, a node is an index, and an arena is "freed" by resetting a counter. The GC never sees individual nodes. The same file runs on all four TS runtimes:

| runtime | plain → arena (macOS) | plain → arena (Linux) | memory |
|---|---|---|---|
| Node | 6.45 → 6.96 s | 6.59 → 4.28 s | ~1480 → ~150 MB |
| scriptc | 7.75 → 4.99 s | 4.97 → 3.35 s | ~258 → ~98 MB |
| Porffor | 60.57 → 17.75 s | 51.14 → 13.40 s | ~704 → ~98 MB |
| Perry | 7.93 → 8.65 s | 5.97 → 5.85 s | ~590–666 → ~106 MB |

- **Memory drops 2.6–10× everywhere.** That is the dependable win.
- **The speed gain depends on the runtime.** It is large for Porffor (3.4–3.8×) and solid for scriptc (1.5×). For Node, it is faster on Linux and slightly slower on macOS. For Perry it is about even on Linux and slower on macOS, because Perry's plain version is already fast.
- On 2026-10-12, Perry's arena version was 3× *slower* than its plain version. Measured individually on Linux, #12473 (`++` on class fields) cut its time by 61% and #12499 (direct typed-array element access) by another 54%.

Other code-level options exist but were not measured here: object pooling (keep the `TreeNode` class, reuse instances from a free list), and avoiding the allocation altogether where the algorithm allows.

## Cost to write and to maintain

The token figures come from the Claude Code session that wrote these files. Each one is the actual output tokens of the step that created the file, split across the files written in that step by character share. That share includes the model's reasoning in the step, so treat the figures as approximate. All of them are small: about 0.5–1.5k tokens per file. By the time the code was written, the whole session (including building toolchains and debugging the measurement setup) had used about 90k output tokens. Writing the code is cheap; the real differences are in the last two columns.

| variant | code lines | ≈ tokens to write | who manages memory | what breaks when requirements change |
|---|---:|---:|---|---|
| TS plain | 29 | ~560 | GC | nothing; one source serves all four TS runtimes |
| Go | 29 | ~460 | GC | nothing |
| Kotlin | 23 | ~820 | GC | nothing. Memory needs `-Xmx` tuning if 3 GB is too much |
| Swift | 29 | ~900 | ARC, automatic | reference cycles leak silently and need `weak`/`unowned` |
| Rust (Box) | 32 | ~600 | ownership, compiler-checked | sharing a node later needs a redesign (`Rc`/`Arc`) |
| C++ (unique_ptr) | 29 | ~570 | ownership by convention | raw `.get()` pointers can dangle, uncaught |
| Rust arena | 34 | ~1,000 | you; arena-scoped | a node that must outlive its tree no longer fits; stale indices are logic bugs, not crashes |
| C++ arena | 33 | ~890 | you; arena-scoped | a pointer escaping its arena is undefined behaviour, uncaught |
| TS arena | 43 | ~1,450 | you; manual indices and capacity | capacity is fixed up front, and **out-of-bounds typed-array writes are silently dropped**, so an overflow gives wrong results, not a crash |

## Caveats

- **Wall time only.** Node, the JVM and Go do part of their GC work on helper threads. User+sys CPU time is not compared here; the raw hyperfine JSON has it.
- Go 1.21.3 is not the latest release. Other toolchains besides Perry, scriptc and Porffor were not checked for being the newest.
- These numbers come from one allocation-heavy microbenchmark. They are not a general ranking. A workload with shared, long-lived objects that die unpredictably would favour GCs over arenas.
- Neither machine was idle; see the measurement notes.

## Reproduce

```sh
# needs: node >= 23, go, rustc, a C++17 compiler, swiftc, kotlinc + a JVM, hyperfine, perry, scriptc, porffor
PERRY=perry SCRIPTC=scriptc PORF=porf JAVA=java ./build.sh
./run.sh 3 results/<machine>            # outputs, peak RSS, timing
# on a shared machine, time each build separately with a load gate and pinning:
WRAP='taskset -c 6,7,14,15 nice -n -10' MAXLOAD=3 ./run-gated.sh 3 results/<machine>
```
