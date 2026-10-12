# How the macOS numbers were taken

This is a working desktop, not an idle machine: background load was 6.7–13.7 on 10 cores (`load.txt`).

- The 13 implementations in `time.md` were measured in one `run.sh` pass. That is one RSS run each, then hyperfine with 3 runs each.
- Swift and Kotlin were added afterwards with `run-gated.sh`: `time-gated.md` and `time-swift.json` / `time-kotlin.json`, unpinned, at load 7.3–8.3. Kotlin's ±1.1 s spread is most likely the JVM's parallel GC threads competing with that background load.
