# P06 Interactive Evidence

Build: Godot source checkout at `11352c7` plus uncommitted P06 changes; engine `4.7.2.stable.official.ed1daf0bf`.
Command: `D:\Downloads\Godot_v4.7.2-stable_win64_console.exe --path tilaok! --script res://tests/run_p06_interactive.gd`; exit code 0. Full stdout/stderr: `run_p06_interactive.txt`.
Date: 2026-10-14 Asia/Manila. Profile: `karera_slice`; seed: `12345`; seats: 2; input: K1/K2 synthetic keyboard control plus scripted fixture positioning at the real goal Area2D.

Procedure: start two ready seats, pass through Pugad and Place, retain a real Kaing 1x1 construction piece, enter Karera, pause and verify active time freezes, overlap both active released chickens with the arena-defined goal trigger, inspect result awards and totals, ready both seats, and inspect the next Pugad.
Expected: goal finishes secure both actors; Tapos and exact earliest Una are shown; two-player waiver is explained; cumulative totals commit once; next round resets actor lifecycle while retaining construction and scores.
Actual: PASSED — the runner reported 17 checks, including two tied Una rows and exact 10-unit deltas for both seats. Full command output is in `run_p06_interactive.txt`.
Reviewer: not recorded; no independent human review is claimed. Physical devices were not used.

| Capture | Meaning |
|---|---|
| `01_karera_live_1920x1080.png` | Active race objective and clock. |
| `02_explained_live_results_1920x1080.png` | Live goal result with award detail, suppression explanation and exact totals. |
| `03_next_pugad_persistent_stage_1920x1080.png` | Next-round Pugad after result readiness; construction remains in the stage. |
