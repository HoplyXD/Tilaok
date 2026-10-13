# P02 wall movement extension — evidence record (REQ-MOVE-004, P02-T15–T22)

**Date:** 2026-10-13 · **Base revision:** `765ed09` plus uncommitted working-tree changes (this record's delivery) · **Profile/seed:** `movement_room` / `12345` · **Scope:** SHOULD (Oct 21 keep/defer decision: **PENDING**, producer/team) · **Author:** AI-generated implementation (Claude); no human review recorded.

## Result summary

**Implemented in source, NOT RUN.** No Godot binary, `gdtoolkit` or export templates exist on the implementing machine, so no runtime, lint, format, import, render, performance or export result below is a PASS. Nothing in this folder is physical-device evidence. No PHASETASK checkbox is ticked.

| Check | Status | Reason / command to run |
|---|---|---|
| `gdlint` / `gdformat --check` on all `.gd` | COULD-NOT-RUN | gdtoolkit 4.5.0 not installed |
| Godot 4.7.2 import/parse (`--headless --editor --path 'tilaok!' --quit`) | COULD-NOT-RUN | no Godot binary |
| `run_foundation_tests.gd`, `run_p02_tests.gd` (83), `run_p03_tests.gd` (103) regressions | COULD-NOT-RUN | no Godot binary; default tuning keeps wall movement disabled, so existing behavior is intended to be unchanged but is unverified |
| `run_p02_wall_tests.gd` (new; prints `P02_WALL_TESTS checks=N failures=M`) | COULD-NOT-RUN | no Godot binary |
| Rendered 1920×1080 captures (`capture_p02_wall_evidence.gd`) | COULD-NOT-RUN | no Godot binary / renderer |
| `--write-movie` clip | COULD-NOT-RUN | no Godot binary |
| Performance rerun (`capture_p03_evidence.gd`) vs P03 median 0.826 / p95 1.426 / worst 6.141 ms, 199.91 MiB | COULD-NOT-RUN | no Godot binary |
| Windows export + exported startup smoke | COULD-NOT-RUN | no binary or 4.7.2 templates |
| Physical K1/K2/gamepad parity | COULD-NOT-RUN | no physical gamepads; synthetic events only |
| Human feel/balance review (T22) | NOT DONE | needs a named human reviewer; see [session sheet](human_feel_session_sheet.md) |

Commands (from the repository root, Godot 4.7.2 console binary):

```powershell
& '<godot-4.7.2-console>' --headless --editor --path 'tilaok!' --quit
& '<godot-4.7.2-console>' --headless --path 'tilaok!' --script 'res://tests/run_foundation_tests.gd'
& '<godot-4.7.2-console>' --headless --path 'tilaok!' --script 'res://tests/run_p02_tests.gd'
& '<godot-4.7.2-console>' --headless --path 'tilaok!' --script 'res://tests/run_p03_tests.gd'
& '<godot-4.7.2-console>' --headless --path 'tilaok!' --script 'res://tests/run_p02_wall_tests.gd'
& '<godot-4.7.2-console>' --path 'tilaok!' --script 'res://tests/capture_p02_wall_evidence.gd'
& '<godot-4.7.2-console>' --path 'tilaok!' --script 'res://tests/capture_p03_evidence.gd'
gdlint tilaok!; gdformat --check tilaok!
```

## What was implemented

- `scripts/movement/wall_contact_probe.gd` — per-tick 1 wu sideways `test_move` probe; a wall counts only with explicit `wall_movement_eligibility == ELIGIBLE` metadata, a live (not queued-for-deletion) collider and a near-vertical face. Missing metadata fails closed. Never touches `SupportTracker`.
- `scripts/movement/chicken_controller.gd` — slide cap (descent only), single-kick consumption of the shared jump buffer (ground/coyote jump wins), per-contact lock released by an 8 wu separation probe, post-separation grace, `reset_wall_state()` on launch/capture/freeze/terminal/non-Play/phase change/snapshot, code-drawn debug cue.
- `scripts/config/gameplay_tuning.gd` — `wall_movement_enabled` (default **false**), `wall_slide_fall_cap_wu_s` 120, `wall_jump_horizontal_wu_s` 240, `wall_jump_vertical_wu_s` −520, `wall_jump_contact_grace_s` 0.08, `wall_jump_recontact_separation_wu` 8, `wall_contact_probe_wu` 1, `wall_normal_tolerance_degrees` 10; validated. All unmeasured.
- `scripts/stage/support_surface_metadata.gd`, `arena_definition.gd` — separate wall-eligibility field; base platform A–D and goal sides eligible, floor/left/right/ceiling explicitly not. Wave eligibility untouched.
- `scripts/harness/wall_fixture_builder.gd`, `p02_movement_room.gd`, `p03_stage_room.gd` — on-demand labeled debug fixtures (slab, shaft pair, excluded, one-way, moving) and a toggle button; P03 base geometry unchanged.

## Interpretation choices to confirm (not user-decided)

1. Wall eligibility defaults to INELIGIBLE (fail closed) rather than UNSET-invalid so the existing P03 suite is untouched.
2. `wall_jump_contact_grace_s` is implemented as a post-separation grace (0.08 s); the pre-contact case is covered by the existing 0.10 s jump buffer.
3. The kick obeys `jump_release_gravity_multiplier` like a ground jump.
4. Ground/coyote jump wins any overlap with wall contact.
5. Fresh contact on a different wall or side resets the lock, so two-wall shaft climbing is possible; the test runner measures it for human balance review.
6. T17's "no indefinite wall climb" is read as same-contact only.

## Known risks of unverified code

The code has never been parsed by Godot. Expect first-run fixes (typing, `test_move` behavior against one-way shapes, timing assumptions in the new test runner such as the one-tick offset after `await physics_frame`). Treat every check as unproven until `P02_WALL_TESTS ... failures=0` is recorded here.
