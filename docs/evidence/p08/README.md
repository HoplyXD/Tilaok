# P08 Independent Lagsanay evidence

**Date:** October 14, 2026 (UTC). **Source:** baseline `160a0b4` plus P08 task-local changes, before the delivery commit. **Engine:** Godot `4.7.2.stable.official.ed1daf0bf`; matching Windows x86_64 export templates installed. **Machine:** Windows, Intel Core i5-13420H (12 logical CPUs), NVIDIA GeForce RTX 4050 Laptop GPU, 1920×1080. **Profile/seed:** `lagsanay_lab` / `12345`, unless stated otherwise. **Reviewer:** Codex engineering run (implementation author); no independent human review is recorded.

All test seats and placement actions were synthetic. Two-seat fixtures used K1/K2 identities; three- and four-seat fixtures added synthetic gamepad identities. No physical gamepads or human play session were available. Screenshots are rendered development/debug UI with placeholder assets; they are not final art or a human readability review.

## P08 checks

| Check | Procedure and expected result | Actual result / command / exit | Evidence |
|---|---|---|---|
| Taya, head start, sensor passing and pause clocks | Run the room at 2/3/4 seats using current physics overlaps. Check random seeded opening taya, 3-second freeze/immunity, no opening pass, nearest contact/tie, stationary overlap, captured recipient, pass-back immunity, unchanged timer, freed-overlap cleanup, and pause/resume clock freezing. | **PASSED** — rendered interactive runner: 87 checks, 0 failures, exit 0. HUD explicitly explains pass-back protection and that other recipients stay eligible. Actual Trumpo sweeps did not eliminate the opening taya. Contact snapshots were taken from live physics overlap state. | [Interactive report](p08_interactive_run.txt); captures [head start](01_opening_head_start_1920x1080.png), [passed taya and immunity cue](02_passed_taya_1920x1080.png). |
| Elimination and scoring controller | Run deterministic 2/3/4-seat fixtures for timeout/hazard arbitration, simultaneous elimination batches, non-taya death, taya reassignment, exact placement tables, Patibong ownership/self-kill, Bawi threshold, duplicate events and exactly-once commit. | **PASSED** — focused runner: 86 checks, 0 failures, exit 0. Command: `D:\Downloads\Godot_v4.7.2-stable_win64_console.exe --headless --path tilaok! --script res://tests/run_p08_tests.gd`. | [Focused log](regressions/final/run_p08_tests.log). |
| Real hazard attribution | Exercise a placed Trumpo contact and a Tsinelas Launcher projectile in the P08 room; expect the mode ledger to receive direct source/owner records, reject self-credit, and retain source identity. | **PASSED** — actual Trumpo direct contact and Launcher projectile reached the independent Lagsanay elimination sink; placer/owner and item IDs were preserved. The attribution record time is round-relative simulation time supplied by the hazard behavior/director; it is not proof of arbitrary sub-frame physical ordering. | [Interactive report](p08_interactive_run.txt); [Trumpo capture](03_trumpo_direct_contact_1920x1080.png); [Launcher capture](04_projectile_direct_contact_1920x1080.png). |
| Expiry and ordinary winner results | Expire the current taya in a two-seat room; expect one surviving winner, both outcomes, one placement award and an explanation. | **PASSED** — rendered interactive runner; ordinary winner gets exactly one first-place award. | [Ordinary results capture](05_expiry_ordinary_winner_1920x1080.png). |
| Last Cluck | Exercise all-final elimination for 2/3/4 seats, exact and supplied distinguishable timestamps, smaller final groups, lower-place averages, legacy tick-only inputs, callback-order permutations and duplicates. Render the result explanation. | **PASSED** — unit and presentation fixtures select exactly one latest-recorded-time winner, exact ties use the lowest stable slot, and no first-place averaging or duplicate score commit occurs. Distinguishable timestamps are explicitly **supplied fixture records**, not inferred from callback order. Runtime integration exposes only the times its engine/hazard producers record; truly indistinguishable records remain ties. | [Focused log](regressions/final/run_p08_tests.log); [interactive report](p08_interactive_run.txt); [explained result capture](06_last_cluck_explained_results_1920x1080.png). |
| Restart/cleanup and performance | Sample 300 rendered frames per player count at 1920×1080 with active Trumpo and Launcher, v-sync off; then send three synthetic `escaped_bounds` signals and retry from pre-play scores/construction. | **PASSED** — 2/3/4-player median/p95/worst intervals were `5.092/8.997/11.140`, `4.873/8.526/13.106`, and `6.325/10.564/13.361` ms. Godot static memory was `87.94–88.92 MiB`; external 100 ms Windows process-tree sampling observed peak working set `287.84 MiB` and private bytes `421.58 MiB`. Two persistent hazards, correct actor counts, zero post-teardown orphan nodes; three synthetic retries preserved score and construction. All measured frame/memory values were below the provisional budgets. | [Performance report](p08_performance.txt); [2P active-hazards capture](07_performance_2p_active_hazards_1920x1080.png). The restart trigger was a synthetic signal, not a physical escape. |

The no-networking target is architectural: this local mode instantiates no networking path. `0 B/s` was not established by packet capture. Save changes are N/A; only session cumulative scores and per-round score snapshots are used.

## Regression and toolchain record

The full required regression batch ran with Godot 4.7.2 headless synthetic fixtures. Every command exited `0`; each test runner reported zero failures.

| Runner | Result |
|---|---:|
| Foundation | PASSED, exit 0 |
| Blocks / 64 px grid | 76 checks, PASSED |
| P02 controller/input | 83 checks, PASSED |
| P02 wall movement | 85 checks, PASSED |
| P03 stage/camera/support | 103 checks, PASSED |
| P04 item/construction | 269 checks, PASSED |
| P05 round lifecycle | 137 checks, PASSED |
| P06 scoring/placement | 97 checks, PASSED |
| P07 engineering | 590 checks, PASSED |
| P07 reset audit | 172 checks, PASSED (synthetic participants) |
| P08 focused | 86 checks, PASSED |
| P10 item/hazard | 424 checks, PASSED |
| UI contract | 437 checks, PASSED |

Commands were `Godot_v4.7.2-stable_win64_console.exe --headless --path tilaok! --script res://tests/<runner>.gd`; each runner's current stdout/stderr and exit code are stored under `regressions/final/`, with the authoritative exit summary in [suite_summary.txt](regressions/final/suite_summary.txt). Files directly under `regressions/` and the older `final/summary.txt` preserve implementation-time iterations, including failed runs; they are not acceptance evidence. The current matching `final/*.stdout.txt`, `final/*.stderr.txt` and `suite_summary.txt` are the final rerun. The refreshed 2/3/4-seat rendered P08 runner passed 87 checks, 0 failures. Godot editor import/class registration/parse exited `0`. `gdformat --check` exited `0` (all changed GDScript files unchanged). `gdlint` found only `scripts/match/match_room.gd` over the 1,000-line rule (baseline 1,013 lines, current 1,022); no other changed-script lint findings. This inherited file-size finding remains open. See [import/parse](import_parse.log), [format](gdformat_check.log), [lint](gdlint.log), [Windows export](windows_export.log), and [exported startup](windows_export_runtime.log).

Windows Debug export using the installed matching 4.7.2 templates exited `0`. The exported console build ran headless with `--quit-after 120 -- --open-room=p08_lagsanay`, exited `0`, and printed `P08_LAGSANAY_READY build=P08-independent-lagsanay-dev profile=lagsanay_lab seed=12345`. Logs: [export](windows_export.log), [exported startup](windows_export_runtime.log). The exported binary is a generated build artifact, not included in the source commit.

## Limits and open gates

- P08 engineering checks use synthetic seats/fixtures; no independent human review, physical-device session, novice comprehension, balance, cultural-name, or minimum-zoom readability review is claimed.
- P07-T04 remains unchecked: its actual three-/four-player sessions, device rotation/isolation and review acceptance are not satisfied by these synthetic Lagsanay runs. P02 physical input/reconnect tasks also remain open. P08 development was authorized to proceed under a provisional, development-only prerequisite disposition; that does not complete P07 or make the release gate pass.
- The P08 development profile is not release-enabled. Karera+Lagsanay, Kangaroo+Lagsanay, event scheduling, full-match end/round-12/sudden-death orchestration, save/network systems and final art/audio remain out of scope.
- P08 tuning values remain provisional pending human playtesting. R1–R4 are inactive. No taya speed bonus was added.
