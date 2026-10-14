# How the Linux numbers were taken

The host is a shared server, and other jobs ran on it during the session (load 1 to 22 on 16 threads).

- **Correctness and peak RSS (`rss.md`).** Each implementation ran once, unpinned. Peak RSS doesn't depend on load.
- **Timing (`time-gated.md`, `time-*.json`).** Each implementation got its own hyperfine run of 3 iterations, pinned with `taskset -c 6,7,14,15 nice -n -10`. That is two physical cores plus their SMT siblings, so GC helper threads have room. A run started only once the 1-minute load average was below 3. The load at the start and end of each run is in the table: every one started at 2.2–2.9 and ended at 4.2 or below.
- Swift and Kotlin were added after the other 13 and timed the same way.
