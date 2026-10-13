# P02 wall movement extension — evidence record (REQ-MOVE-004, P02-T15–T22)

**Date:** 2026-10-13 · **Base:** `765ed09`; first delivery `9ee25c8` (committed without an engine run); this record covers the working tree on top of it · **Profile/seed:** `movement_room` / `12345` · **Engine:** Godot `4.7.2.stable.official.ed1daf0bf` · **Machine:** Windows, AMD Ryzen 5 5500, Radeon RX 580, Compatibility renderer · **Input:** synthetic K1, K2 and gamepad events only · **Reviewer:** Claude (AI, automated); **no human reviewer, no physical devices** · **Scope:** SHOULD · **Oct 21 keep/defer decision: PENDING** (producer/team).

## Result summary

Tasks checked in PHASETASK: **T15, T16, T17, T19, T20, T21**. Open: **T18** (physical devices / synthetic-only acceptance is the producer's call) and **T22** (human review). Extension exit criteria: **NOT MET**.

| Check | Status | Evidence |
|---|---|---|
| gdlint 4.5.0 / gdformat 4.5.0, all scripts and tests | PASSED | run in session; clean (36 files) |
| Godot import/parse (`--headless --editor --quit`) | PASSED | [import log](2026-10-13_import_parse.txt) — 0 error/warning lines |
| `run_foundation_tests.gd` | PASSED | [log](2026-10-13_regression_foundation.txt) — 0 failures |
| `run_p02_tests.gd` | PASSED | [log](2026-10-13_regression_p02.txt) — 83 checks, 0 failures (unchanged count) |
| `run_p03_tests.gd` | PASSED | [log](2026-10-13_regression_p03.txt) — 103 checks, 0 failures (unchanged count) |
| `run_p02_wall_tests.gd` (new) | PASSED | [log](2026-10-13_wall_tests.txt) — 85 checks, 0 failures |
| Rendered captures, 1920×1080 | PASSED — inspected | [01 slide](01_slide_base_side_1080p.png), [02 kick](02_kick_1080p.png), [03 excluded](03_excluded_surface_1080p.png), [04 max kick+launch](04_max_kick_launch_camera_1080p.png), [log](2026-10-13_wall_render_capture.txt) |
| Performance vs baseline, same machine | PASSED (noise noted) | [current ×3](2026-10-13_perf_current_tree_3runs.txt); baseline `765ed09` ×3: worst 5.94 / 9.12 / 21.40 ms (one run FAILED the 16.67 ms worst-frame rule). Current: median 0.69–0.70, p95 1.84–2.07, worst 4.79–5.91 ms; 68.95 vs 68.74 MiB static |
| Windows export + exported startup smoke | PASSED — startup only | Release export with matching 4.7.2 templates exit 0 ([export](2026-10-13_export.txt)); exported `tilaok-p02.exe --headless --quit-after 90` exit 0 ([runtime](2026-10-13_export_runtime.txt)). No interactive or device test of the export |
| `--write-movie` clip | COULD-NOT-RUN | not attempted; stills only |
| Physical keyboard / gamepad parity | COULD-NOT-RUN | no gamepads; synthetic events are not device evidence |
| Human feel / balance review (T22) | NOT DONE | [session sheet](human_feel_session_sheet.md) prepared |
| Desktop sync | COULD-NOT-RUN | `C:\Users\roman\...` checkout does not exist on this machine |

Commands (repository root):

```powershell
& '<godot-4.7.2-console>' --headless --editor --path 'tilaok!' --quit
& '<godot-4.7.2-console>' --headless --path 'tilaok!' --script 'res://tests/run_foundation_tests.gd'
& '<godot-4.7.2-console>' --headless --path 'tilaok!' --script 'res://tests/run_p02_tests.gd'
& '<godot-4.7.2-console>' --headless --path 'tilaok!' --script 'res://tests/run_p03_tests.gd'
& '<godot-4.7.2-console>' --headless --path 'tilaok!' --script 'res://tests/run_p02_wall_tests.gd'
& '<godot-4.7.2-console>' --path 'tilaok!' --script 'res://tests/capture_p02_wall_evidence.gd'
gdlint tilaok!; gdformat --check tilaok!
```

Note: `capture_p03_evidence.gd` overwrites `docs/evidence/p03/*` with the current machine's output; those tracked P03 files were restored and this folder keeps the new numbers.

## Measurements (synthetic fixtures; not feel or balance evidence)

| Measure | Value |
|---|---|
| Slide speed vs cap 120 wu/s | 120.00 left wall, 120.00 right wall |
| Kick (K1, K2, gamepad) | vx 240.00, vy −457.50 two ticks after the kick |
| Kicks per fresh press | 1 each device; 1 over a 1 s held press with OS repeats; 0 for echo alone |
| Recontact lock cleared at | 12.10 wu gap (threshold 8 wu) |
| Steering | vx 240 → 160 wu/s in 3 ticks toward the wall |
| Kick rise, held / released jump | 72.07 / 33.84 wu |
| Ground full jump with wall enabled | 96.06 wu (unchanged) |
| 64 wu shaft, 240 frames | 34 kicks, reaches ceiling, gain per cycle −2.0 … +24.5 wu |
| Kick + launch containment (P02 room) | (480,−900): x 156–244, y 124–556; (−480,−900): x 188–354, y 124–556; (0,−900): x 200–300, y 124–440; (480,0): x 188–244, y 126–556 — all inside bounds |
| P03 camera, kick + launch (480,−900) | all targets visible; peak y 264.08 |

## What exists

- `scripts/movement/wall_contact_probe.gd` — per-tick 1 wu sideways `test_move`; wall counts only with explicit `wall_movement_eligibility == ELIGIBLE`, a live collider and a near-vertical face. Missing metadata fails closed. Never touches `SupportTracker`.
- `scripts/movement/chicken_controller.gd` — slide cap (descent only), single kick from the shared jump buffer (ground/coyote jump wins), per-contact lock released by an 8 wu separation probe, 0.08 s post-separation grace, `reset_wall_state()` on launch/capture/freeze/terminal/non-Play/phase/snapshot and both room resets, code-drawn debug cue.
- `scripts/config/gameplay_tuning.gd` — `wall_movement_enabled` (default **false**), cap 120, 240/−520, grace 0.08, separation 8, probe 1, normal tolerance 10°; all validated and finite-checked.
- `scripts/stage/*` — separate wall-eligibility field; base A–D and goal sides eligible; floor/walls/ceiling not.
- `scripts/harness/wall_fixture_builder.gd` and both rooms — on-demand labeled debug fixtures behind a button.

## Defects found by real runs (fixed)

1. The new tuning keys were missing from the `is_finite` list (NaN passed validation). Added; covered by a test.
2. First pass of the runner had cumulative kick-count assertions, a one-way platform overlapping the ceiling test, ceilings clamping the kick-rise trial, a bystander placed inside the goal platform, and a bystander badge hanging past the arena edge (a pre-existing camera property, not a wall effect). All test-setup errors; fixed.

## Interpretation choices (not user-decided; please confirm)

1. Wall eligibility defaults to INELIGIBLE (fail closed).
2. `wall_jump_contact_grace_s` is a post-separation grace; the existing 0.10 s buffer covers pre-contact presses.
3. The kick obeys `jump_release_gravity_multiplier` (held 72.07 wu vs released 33.84 wu).
4. Ground/coyote jump wins any overlap with wall contact.
5. Contact on a different wall resets the lock, so two-wall shaft climbing exists (measured above) — a balance/shortcut item for human review.
6. T17's "no indefinite wall climb" was read as same-contact only.
7. The slide cap applies instantly (a 600 wu/s fall becomes 120 wu/s on contact); a ramp is a possible feel change.

## Known limits

Synthetic input only; one machine, different from the P03 record; the performance runs did not enable wall movement; no human or physical-device evidence; fixtures are floating debug geometry, not stage content; no Lagsanay or event integration (see [procedure](event_stack_escape_procedure.md)).
