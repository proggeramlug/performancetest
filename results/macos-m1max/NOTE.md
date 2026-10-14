# How the macOS numbers were taken

This is a working desktop, not an idle machine: background load was 5.6–13.3 on 10 cores during the main pass (`load.txt`).

- `time.md`: one `run.sh` pass over all 15 builds. Peak RSS comes from one run each; timing is hyperfine with 3 runs each.
- `time-gated.md`: node, node-arena, perry and perry-arena re-timed with `run-gated.sh`, 5 runs each, at load 4.2–5.4. In the main pass, Perry had a ±1.27 s spread (8.3–10.7 s) from background load. The README uses these 5-run figures for those four rows; the main pass is kept unchanged in `time.md`.
