# How the Linux numbers were taken

The host is a shared server, and other jobs ran on it during this session (load 1 to 22 on 16 threads).

- **Correctness and peak RSS (`rss.md`).** Each implementation ran once, unpinned. RSS doesn't depend on load. The Rust binaries were later rebuilt with stable 1.98.0 instead of the nightly. Their outputs still match, and their RSS is unchanged (`rss-rust-stable.txt`).
- **Timing (`time-gated.md`, `time-*.json`).** Each implementation got its own hyperfine run of 3 iterations, pinned with `taskset -c 6,7,14,15 nice -n -10`. That is two physical cores plus their SMT siblings, so GC helper threads have room. The load average at the start and end of each hyperfine run is recorded in the table. Every implementation started at load 2.9 or below. Load rose to 8.9 during scriptc's run.
- **`pinned-pass1/`** is an earlier pinned pass. In it, node, go, rust, rust-arena and cpp ran at load 11–16. It is kept for transparency, and shows how much contention hurts Node's concurrent GC in particular (15.2 s vs 6.6 s).
- **`ungated/`** is the first unpinned run. Load climbed to 18.8 during it, so it is not representative.
