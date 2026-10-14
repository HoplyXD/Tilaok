# P09 — Match lifecycle engineering evidence

**Date:** October 14, 2026

**Engine:** Godot 4.7.2 stable (`ed1daf0bf`)

**Route/build:** `p09_match_lifecycle_room.tscn`, `P09-match-lifecycle-dev`; `karera_slice` development profile.

**Renderer/hardware:** Windows Compatibility renderer, NVIDIA GeForce RTX 4050 Laptop GPU, 1920×1080 windowed.
**Scope:** Karera ends at the exact 80-eighth-point target or completed round 12; equal top scores enter Lagsanay sudden death. This route retains P07’s three-variant allowlist. It does not implement the P12 schedule or stacks and does not replace the release profile.

## Checks and captures

- [Focused coordinator and Lagsanay checks](p09_focused_tests.txt): 77 assertions, 0 failures. Covers defaults/validation, below/exact/above target, threshold-plus-round-limit, round 11/12, lower-place ties, reordered/duplicate round callbacks, stale match/round/attempt callbacks, and stable 2/3/4-seat sudden-death winners. A four-seat case preserves the noncontiguous tied subset `[1, 3]`.
- [Rendered interactive engineering run](p09_interactive_run.txt), [console output](p09_interactive_console.txt): 108 assertions, 0 failures. Real round awards feed the P09 coordinator; synthetic seats and injected goal candidates keep the threshold and 12-round path repeatable. A preloaded 40/40 cumulative-score fixture isolates the noncontiguous subset route. Real Godot contact sensors transfer taya, and the P09 spectator roster is excluded from tagging and hazard resolution. Device reclaim/pause, readiness invalidation, leave/Quit cancellation, Replay and Lobby reset are covered.
- [Ten-cycle restart audit](p09_restart_audit.json), [console output](p09_restart_audit_console.txt), and [external Windows process memory sample](p09_process_memory.txt): ten completed match endings (five score-target and five round-limit sudden-death), each followed by Replay or Lobby return and a fresh Pugad. The four action/end combinations are represented. State snapshots include score totals, construction, actors, transients, captures, pending claims, result readiness, Lagsanay timers/immunity, lifecycle identity/callback state, Godot object count and static memory.
- Screenshots: [score-target final result](01_score_target_final_results_1920x1080.png), [Replay](02_replay_fresh_match_1920x1080.png), [round-limit sudden-death entry](03_all_finish_round_limit_sudden_death_1920x1080.png), [tied-player contact](03b_tied_player_contact_1920x1080.png), [survivor result](04_final_sudden_death_results_1920x1080.png), [noncontiguous tied-player entry](05_noncontiguous_tied_players_sudden_death_1920x1080.png), [Last Cluck result](06_final_noncontiguous_sudden_death_results_1920x1080.png), and [Return to Lobby](07_return_to_lobby_1920x1080.png).
- [Godot import/parse](p09_import_parse.txt), [changed-script format/lint](p09_lint_format.txt), [Windows export log](p09_windows_export.txt), [development-route smoke](p09_route_smoke.txt), and [exported-route smoke](p09_exported_route_smoke.txt). The exported executable is generated at `build/p09/tilaok-p09.exe` (ignored build output).
- Regression logs: [Foundation](regressions/run_foundation_tests.txt), [P02](regressions/run_p02_tests.txt), [P05](regressions/run_p05_tests.txt), [P06](regressions/run_p06_tests.txt), [P07](regressions/run_p07_tests.txt), [P08](regressions/run_p08_tests.txt), and [UI](regressions/run_ui_tests.txt).

## Measurements and interpretation

After cycle 3 (warmed baseline) and deferred frees, object-count deltas over cycles 3–10 ranged from **−5 to +1**; Godot static-memory deltas ranged from **−97,572 to +249,784 bytes** (about −0.09 to +0.24 MiB). No continuing upward trend appeared in those samples. The external 100 ms process-tree sampler recorded peak working set **306,495,488 bytes (292.3 MiB)** and peak private bytes **447,467,520 bytes (426.7 MiB)**, below the 512 MiB target.

At 1080p with vsync disabled, 226 warmed samples measured median **9.52 ms**, p95 **27.78 ms**, and worst **55.60 ms**. The p95 and worst frame intervals exceed the 16.67 ms / 60 FPS target; performance acceptance therefore remains open. Across all 306 samples, the maximum was **144.38 ms**. The automated run has synthetic local inputs; it is not a human-used restart session or physical-device test. No networking was used; 0 B/s is an architectural expectation for the local-only route, not a packet capture.

## Evidence boundaries

- All player/device identities are synthetic. The interactive test uses shortened race/head-start/taya timers. Race goal candidates are injected into the real ledger and scoring path; the round-limit subset test uses an explicitly preloaded-score fixture.
- Last Cluck attribution is injected synthetically because the P07 allowlist has no hazard items. The P08 engineering regression covers actual Trumpo/Launcher attribution separately; this does not claim a natural Last Cluck hazard in P09.
- A tied-player contact transfer was produced through real Godot physics. No human review, playtest, physical controller acceptance, final-art review, competitive balance result, P12 schedule result or release-gate closure is claimed.
- The combined regression command did not finish the existing `run_p04_tests.gd` suite inside its 30-second command window; that process was stopped after confirming it was the P04 runner. P05, P06, P07, P08, UI, Foundation and P02 checks completed successfully. P09’s own repeated ItemManager start/end/reset paths passed.

## Reproduction commands

Run from the repository root with the pinned Godot 4.7.2 console executable:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' -- --open-room=p09_match_lifecycle
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p09_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_p09_interactive.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/audit_p09_restarts.gd'
```
