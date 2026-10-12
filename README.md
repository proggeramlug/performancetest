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
| Perry commit | 996bc5d629dfbc4b0e99a377b6eeab57c32e54c6 (2026-10-12 04:40:53 +0200) | 996bc5d629dfbc4b0e99a377b6eeab57c32e54c6 (2026-10-12 04:40:53 +0200) |
| scriptc | 0.2.9 | 0.2.9 |
| Porffor | alpha 17 (731f1b2 2026-10-10) | alpha 17 (731f1b2 2026-10-10) |
| Go | go1.21.3 darwin/arm64 | go1.21.3 linux/amd64 |
| Swift | Apple Swift version 6.3.3 (swiftlang-6.3.3.1.3 clang-2100.1.1.101) (-O) | Swift version 6.3.3 (swift-6.3.3-RELEASE) (-O) |
| Kotlin | kotlinc-jvm 2.3.21 (JRE 26.0.2) | kotlinc-jvm 2.3.21 (JRE 26.0.2.1+1) |
| JVM for Kotlin | openjdk version "26.0.2" 2026-07-21 OpenJDK Runtime Environment Homebrew (build 26.0.2) (default GC, no flags) | openjdk version "26.0.2.1" 2026-08-18 OpenJDK Runtime Environment Temurin-26.0.2.1+1 (build 26.0.2.1+1) (default GC, no flags) |
| Rust | rustc 1.97.1 (8bab26f4f 2026-07-14) (-C opt-level=3) | rustc 1.98.0 (88d9e12ae 2026-08-18) (-C opt-level=3) |
| C++ compiler | Apple clang version 21.0.0 (clang-2100.1.1.101) (-O2 -std=c++17) | g++ (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0 (-O2 -std=c++17) |
| hyperfine | hyperfine 1.20.0 | hyperfine 1.20.0 |

Perry was built from source with `cargo build --release -p perry -p perry-runtime-static -p perry-stdlib-static` and linked with `PERRY_NO_AUTO_OPTIMIZE=1` on both machines. Its runtime and stdlib archives were rebuilt at that commit; their timestamps are in each `versions.txt`. Perry (main), scriptc and Porffor are the latest versions as of 2026-10-12; this was checked. The other toolchains are what each machine had installed, or recent releases installed for this test. Go 1.21.3 is notably old. The two machines differ in Node (26.5.1 vs 26.8.1) and Rust (1.97.1 vs 1.98.0, stable on both).

## Results

Times are the mean ± standard deviation of 3 hyperfine runs. "vs Node" is time relative to Node on the same machine, where lower is faster. RSS is peak resident memory from one run under `/usr/bin/time`. Rows are sorted by the average of the two "vs Node" columns.

### Idiomatic code

| implementation | macOS | vs Node | macOS RSS | Linux | vs Node | Linux RSS |
|---|---:|---:|---:|---:|---:|---:|
| Kotlin (JVM) | 5.28 s ± 1.12 | 0.82× | 2777 MB | 2.79 s ± 0.07 | 0.39× | 3102 MB |
| scriptc | 7.61 s ± 0.03 | 1.19× | 257 MB | 5.65 s ± 0.04 | 0.79× | 258 MB |
| Node | 6.42 s ± 0.09 | 1.00× | 1482 MB | 7.12 s ± 0.06 | 1.00× | 1472 MB |
| **Perry** | 10.66 s ± 0.09 | 1.66× | 659 MB | 10.72 s ± 0.08 | 1.51× | 594 MB |
| Rust (Box) | 12.18 s ± 0.12 | 1.90× | 130 MB | 9.31 s ± 0.19 | 1.31× | 258 MB |
| C++ (unique_ptr) | 13.49 s ± 0.07 | 2.10× | 130 MB | 8.55 s ± 0.34 | 1.20× | 260 MB |
| Go | 14.52 s ± 0.44 | 2.26× | 254 MB | 13.55 s ± 0.07 | 1.90× | 187 MB |
| Swift (ARC) | 23.45 s ± 0.24 | 3.65× | 259 MB | 15.81 s ± 0.74 | 2.22× | 393 MB |
| Porffor | 59.58 s ± 1.71 | 9.29× | 704 MB | 54.29 s ± 1.23 | 7.63× | 756 MB |

### Arena variants (hand-managed memory)

The Node row is repeated for reference.

| implementation | macOS | vs Node | macOS RSS | Linux | vs Node | Linux RSS |
|---|---:|---:|---:|---:|---:|---:|
| Rust arena | 2.06 s ± 0.01 | 0.32× | 100 MB | 1.60 s ± 0.02 | 0.22× | 98 MB |
| C++ arena | 2.63 s ± 0.00 | 0.41× | 165 MB | 2.23 s ± 0.00 | 0.31× | 131 MB |
| scriptc, typed-array arena | 5.02 s ± 0.07 | 0.78× | 98 MB | 3.74 s ± 0.33 | 0.53× | 98 MB |
| Node, typed-array arena | 6.92 s ± 0.02 | 1.08× | 154 MB | 4.54 s ± 0.20 | 0.64× | 149 MB |
| Node | 6.42 s ± 0.09 | 1.00× | 1482 MB | 7.12 s ± 0.06 | 1.00× | 1472 MB |
| Porffor, typed-array arena | 17.04 s ± 0.10 | 2.66× | 98 MB | 13.70 s ± 0.08 | 1.93× | 98 MB |
| **Perry**, typed-array arena | 36.67 s ± 0.23 | 5.71× | 105 MB | 31.77 s ± 0.02 | 4.46× | 108 MB |

How the numbers were measured:

- **macOS** is a working desktop with background load of about 7–14 on 10 cores. See [`results/macos-m1max/NOTE.md`](results/macos-m1max/NOTE.md).
- **Linux** is a shared server. Each build was timed separately, pinned to 2 cores / 4 threads, and started at load below 3. See [`results/linux-ryzen7700x/NOTE.md`](results/linux-ryzen7700x/NOTE.md).
- [`results/archive-v1`](results/archive-v1) has a superseded first round that used outdated scriptc and Porffor versions.

## What it shows

- **The arenas are the fastest by far.** Rust with an arena takes 1.6–2.1 s and about 100 MB. Freeing a whole tree at once beats every general-purpose allocator and GC on this workload.
- **Kotlin/JVM is the fastest idiomatic build.** It is 1.2–2.6× faster than Node, but uses about 3 GB because the JVM claims up to ¼ of RAM by default. Node is next, at about 1.5 GB. Generational GCs allocate by bumping a pointer and drop dead young objects almost for free, which is exactly this workload.
- **scriptc 0.2.9 is the fastest of the AOT TypeScript compilers here,** and uses only about 258 MB. That memory figure matches malloc/free Rust and C++ on Linux.
- **Perry takes 1.5–1.7× Node's time with 40–45% of its memory.** It beats Go and Swift on both machines. Compared with malloc/free Rust and C++, it is faster on macOS and slower on Linux, where glibc malloc is much faster for this pattern.
- **Swift (ARC) is the slowest of the non-JS languages here,** at 15.8–23.5 s. Every node creation and release updates a reference count.
- **Porffor is 7.6–9.3× Node's time** on this workload.

## Speeding up the TypeScript versions

`bench-arena.ts` is the TypeScript equivalent of the Rust and C++ arenas. It uses a struct-of-arrays layout: node fields live in two preallocated `Int32Array`s, a node is an index, and an arena is "freed" by resetting a counter. The GC never sees individual nodes. The same file runs on all four TS runtimes:

| runtime | plain → arena (macOS) | plain → arena (Linux) | memory |
|---|---|---|---|
| Node | 6.42 → 6.92 s | 7.12 → 4.54 s | ~1480 → ~150 MB |
| scriptc | 7.61 → 5.02 s | 5.65 → 3.74 s | ~258 → ~98 MB |
| Porffor | 59.58 → 17.04 s | 54.29 → 13.70 s | ~700 → ~98 MB |
| Perry | 10.66 → **36.67 s** | 10.72 → **31.77 s** | ~600 → ~105 MB |

- **Memory drops 2.6–10× everywhere.** That is the dependable win.
- **The speed gain depends on the runtime.** It is large for Porffor (3.5–4×), solid for scriptc, and mixed for Node: faster on Linux, slightly slower on macOS. V8's young-generation GC already does most of what the arena does.
- **Perry gets 3.0–3.4× slower.** A small probe points at typed-array element access through class fields: the same code with module-level arrays ran about 3.3× faster. That is a Perry codegen issue, not a property of the approach.
- Even the best TS arena (scriptc, 3.7–5.0 s) stays 2.3–2.4× behind the Rust arena. The likely causes are bounds-checked typed-array access and number semantics, but that was not profiled.

Other code-level options exist but were not measured here: object pooling (keep the `TreeNode` class, reuse instances from a free list), and avoiding the allocation altogether where the algorithm allows.

## Cost to write and to maintain

The token figures come from the Claude Code session that wrote these files. Each one is the actual output tokens of the step that created the file, split across the files written in that step by character share. That share includes the model's reasoning in the step, so treat the figures as approximate. All of them are small: about 0.5–1.5k tokens per file. The whole session, including building toolchains, debugging the measurement setup and writing this README, used about 90k output tokens. Writing the code is cheap; the real differences are in the last two columns.

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
