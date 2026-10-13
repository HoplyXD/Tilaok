# P06 verification record — 2026-10-14

**Source baseline:** `main` at `11352c7` before this delivery. The test checkout contained P06 changes and separate uncommitted P10 work; P10 files/assets are excluded from this P06 delivery. No independent human review is claimed.
**Engine:** Godot `4.7.2.stable.official.ed1daf0bf`; matching Windows Desktop templates installed.
**Machine:** Windows, 13th Gen Intel Core i5-13420H (12 logical CPUs), NVIDIA GeForce RTX 4050 Laptop GPU; Compatibility renderer.
**Profile/seed:** `karera_slice` / `12345` unless otherwise noted.
**Input:** K1/K2 keyboard routing and synthetic gamepad identities for seats 3/4; fixtures script positions at the actual ArenaDefinition goal trigger. No physical controller or player testing is claimed.

**Staged-source verification:** A temporary clean snapshot was created from `11352c7` plus the complete staged index, excluding all unstaged and untracked P10 work. Godot import/class registration, the 97-check P06 suite, and the 137-check P05 suite all passed with exit code 0 in that exact staged-source snapshot; see [staged snapshot logs](staged_snapshot_import.log), [P06](staged_snapshot_p06_tests.log), and [P05](staged_snapshot_p05_tests.log). The separate GUI, performance, regression, lint and export records below were captured in the shared checkout, which also contained excluded local P10 work.

## Focused and dependent checks

| Check | Expected | Actual | Evidence |
|---|---|---|---|
| P06 automated | Deadlines/boundaries/pause, batch order and identity, duplicate/stale events, score matrix and placements | **PASSED**, 97 assertions, 0 failures | [log](regression_run_p06_tests.txt); command used Godot 4.7.2 `--headless --path tilaok! --script res://tests/run_p06_tests.gd`, exit 0 |
| P06 interactive | Live two-seat goal, tied Una, exact totals, pause freeze, ready advance, reset and persistent construction | **PASSED**, 17 checks, 0 failures, three 1920×1080 captures | [stdout/stderr](run_p06_interactive.txt), [capture/runner README](README.md) |
| P05-T12 dependent rerun | Four seats complete two real Pugad→Place→goal→results rounds; explain all-finish suppression; held confirm is consumed; all-ready advances and construction persists | **PASSED**, 64 checks, 0 failures; the P05 suite separately verifies paused eight-second advance | [interactive log](../p05/p05_interactive_run.log), [P05 regression log](regression_run_p05_tests.txt) |
| Existing regression suites | Foundation, P02, P02 wall, P03, P04 and UI behavior retained | **PASSED**: foundation exit 0; P02 83; P02 wall 85; P03 103; P04 268; UI 437; P05 137; P06 97; 0 reported assertion failures | [logs](.) |
| Import/class registration | Godot scans all project scripts and registers classes | **PASSED**, editor scan and script registration exit 0 | [log](import_parse.log) |
| Windows Debug export and startup smoke | Export with matching Godot 4.7.2 template; exported app initializes then exits | **PASSED**, export exit 0; exported headless startup exit 0 | [export log](windows_export.log), [smoke log](windows_export_smoke.log); artifact was `build/tilaok-p06.exe` |

Commands use the explicit `D:\Downloads\Godot_v4.7.2-stable_win64_console.exe`, never the PATH wrapper. With gdtoolkit 4.5.0, the full project check passed for all 139 GDScript files: `gdformat --check` and `gdlint` both exited 0, including the separate local P10 work-in-progress files.

## Timing and lifecycle policy verified

The real goal is an `Area2D` built from `ArenaDefinition.goal_trigger`. Only active released chickens can finish; the queue rechecks overlap, so release while inside the goal can finish. Every physics step is collected as a batch before resolution: earlier steps win; same-step elimination beats goal; simultaneous events have no invented sub-frame order. Same-step direct hazards use stable item IDs; tied hazard/non-hazard eliminations receive no Patibong because cause is ambiguous. The selected tie policy was the user-approved plan default.

The `RaceRoundController` uses active simulation time, so pause freezes it. A first valid finish starts the non-extending 15 s deadline; the 60 s hard cap has priority when deadlines coincide; collected boundary-step events resolve before deadline failures. All-terminal outcomes end with the all-terminal reason. Finishers are secured and removed from the camera target set; next-round reset restores actor lifecycle/motion while preserving construction and cumulative score. The score ledger commits once per round identity.

## Exact scoring and placement cases

Scores are integer eighth-point units: Tapos 8, Una 2, Bayani 4, Patibong 2 per direct opponent elimination, Bawi 6, and Barya 4. Bawi reads the immutable round-start snapshot and needs a 24-unit gap. All/none suppression applies in 3/4-seat races; two seats waive it; no finisher means no Patibong; Barya applies only to a finisher and survives all-finish suppression. Current legal placement ties, stable lower-place groups, latest-elimination Last Cluck, lowest-slot exact tie, 80-unit threshold and exact display formatting are covered.

Hazard attribution candidates and Barya facts are test-only interfaces. No P10 hazard family, coin gameplay, Lagsanay, event stacking, complete-match end/sudden-death orchestration, save/network system or final production assets were added. Retest source attribution when P10 hazards are integrated. Tuning deadlines remain provisional pending human playtesting.

## 2/3/4-seat performance and repeated-round sample

The GUI runner performed ten actual Play/results transitions per seat count while retaining ten construction pieces. It sampled 300 rendered active-race frames and 300 rendered-results frames at 1920×1080 with V-sync off, using K1/K2 and synthetic gamepad identities where needed.

| Seats | Race median / p95 / worst (ms) | Results median / p95 / worst (ms) | Godot static memory | Orphan nodes | Target |
|---:|---:|---:|---:|---:|---|
| 2 | 2.450 / 3.039 / 3.876 | 2.200 / 3.049 / 3.467 | 82.89 MiB | 0 | Passed |
| 3 | 2.350 / 3.036 / 3.801 | 2.193 / 3.061 / 4.057 | 83.10 MiB | 0 | Passed |
| 4 | 2.180 / 3.005 / 3.788 | 2.397 / 3.073 / 4.247 | 86.57 MiB | 0 | Passed |

All sampled p95/worst frame intervals stayed below 16.67 ms and Godot static memory stayed below 512 MiB. These are local diagnostic measurements, not a broad PC guarantee; OS working-set memory was not sampled. Gameplay networking is absent (0 B/s by design). Details and procedure are in [p06_performance.txt](p06_performance.txt); execution output is in [performance_command.log](performance_command.log).

## Review limits

Reviewer: not recorded; no independent human review, human readability/feel review, physical-device test, cultural review, competition approval or Form 03 completion is claimed. The 1920×1080 screenshots are DEBUG/code-drawn prototype UI. Actual hazard/item attribution, coin integration, two-player complete repeated match with fresh human inputs, three/four-player human sessions and release readiness remain future gates.
