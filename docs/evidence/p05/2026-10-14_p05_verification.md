# P05 verification record — 2026-10-14

**Source baseline:** updated `main` checkout at `fa5a4e27f61f884cd726dc35fd800da8a0fef121`, before the P05 worktree edits.
**Engine:** Godot 4.7.2.stable.official.ed1daf0bf.
**Machine:** Windows, Intel Core i5-13420H (12 logical CPUs), NVIDIA GeForce RTX 4050 Laptop GPU.
**Evidence date:** 2026-10-14 local time.
**Review:** no independent human review or human playtest is claimed.

## Scope verified

P05 adds the 2–4 seat lobby and seeded Pugad claim flow, exact enabled-variant egg/ghost/placed-piece identity, grid placement feedback, snapshot-based batch construction resolution, a diagnostic Play phase, a results interface shell and the next-round loop. Kaing and Tulay construction persists through rounds. The P05 results view is intentionally a shell; it does not calculate scores or invent awards. Diagnostic Play has no Karera finish rules, Walis Cleanup gameplay, networking or save system. All newly drawn egg, marker, ghost and panel visuals are DEBUG placeholders; production art/audio remain team work.

## Automated suite results

| Suite | Result | Evidence |
|---|---|---|
| Foundation harness/lifecycle | PASSED, 0 failures | [log](existing_foundation_run.log) |
| P02 input/movement | PASSED, 83 checks | [log](existing_p02_run.log) |
| P02 wall movement | PASSED, 85 checks; physical/human review remains open | [log](existing_p02_wall_run.log) |
| P03 graybox | PASSED, 103 checks | [log](existing_p03_run.log) |
| P04 Item Lab | PASSED, 268 checks | [log](existing_p04_run.log) |
| P05 match loop | PASSED, 137 checks, 0 failures | [log](p05_test_run.log) |
| UI component gallery | PASSED, 437 checks, 0 failures | [log](ui_gallery_smoke.log). This standalone DEBUG review fixture is not connected to the P05 match loop or score system. |

P05 claim permutations passed at 2, 3 and 4 seats under seeds 12345, 7 and 991, including final-timeout-tick claims, seeded tie resolution, timeout assignment without duplicate ownership, resolver submission permutations, cleanup-once, whole-set conflict rejection, protected regions, mover safety, timeout commit/discard, held presses, minimum-two/all-ready lobby gating, paused Pugad/Place/results timers and ten-round construction retention/removal/reset.

| Interactive GUI regression | Result | Evidence |
|---|---|---|
| P03 graybox | PASSED, 14 checks | [log](existing_p03_interactive_run.log) |
| P04 Item Lab | PASSED, 25 checks | [log](existing_p04_interactive_run.log) |
| P05 match loop | PASSED, 64 checks; two round cycles through the harness | [log](p05_interactive_run.log) |

The P05 visible run used keyboard K1/K2 plus synthetic gamepad seat identities 3/4. These synthetic events are not physical controller evidence. The exact egg-to-ghost-to-placed matrix is in [variant_handoff_matrix.md](variant_handoff_matrix.md); egg IDs and ownership were distinct while duplicate variant definitions were allowed. The Kaing 2×3 ghost showed its 3×2 rotated footprint. The [rejection matrix](rejection_reason_matrix.md) records all 12 expected/actual reason codes and displayed text; each has a 1920×1080 capture. The [capture manifest](capture_manifest.md) indexes the screenshots.

## Import, export and performance

The Godot 4.7.2 editor import/class-registration pass completed with exit 0 and no warnings/errors: [import/parse log](import_parse.log). GDScript formatting and lint checks passed for all 100 project scripts using gdtoolkit 4.5.0; see the [format log](gdformat.log) and [lint log](gdlint.log).

The final Windows Desktop Debug export used the matching installed Godot 4.7.2 template; export/runtime logs are [windows_export.log](windows_export.log) and [windows_export_runtime.log](windows_export_runtime.log). An earlier export exposed an invalid pre-existing theme variation base type; the variation was corrected and the final export succeeded. The exported executable opened the P05 room headlessly, emitted `P05_MATCH_READY`, and exited at the requested smoke duration. This verifies startup only.

At 1920×1080 with V-sync off, 600 completed rendered-frame samples were collected with four seats and 48 persistent construction pieces after 12 stress rounds. Seats 3/4 are synthetic gamepads. The measured values were median 2.272 ms, p95 4.720 ms, worst 11.011 ms, Godot static memory 79.78 MiB, 2,323 objects, 302 nodes, and zero orphan nodes. This stays below the 16.67 ms frame and 512 MiB static-memory targets. The P04 1080p reference was median 1.954 ms, p95 3.109 ms, worst 6.059 ms, 70.97 MiB, 2,089 objects, 232 nodes and zero orphans. The P05 stage therefore has measurable additional cost; this single local sample is diagnostic, not a broad release-device guarantee. The stress scene itself had no cleanup targets; the focused P05 tests verified once-only cleanup, ten-round persistence and reset separately. The build is local-only and adds no sockets/network calls (0 B/s gameplay traffic by design). See [p05_performance.txt](p05_performance.txt) and the [crowded stage capture](crowded_post_round12_48_pieces_1920x1080.png).

## Limits and remaining gates

- P05-T01–T11 are checked in [PHASETASK](../../PHASETASK.md#p05--lobby-pugad-and-construction-loop). T12 remains blocked pending P06-T08's verified score/result explanation and binding; the P05 phase exit is not met.
- The D3 interface boundary is recorded in the [dated scope note](2026-10-14_p05_scope_note.md). No GDD scoring/finish rule changed.
- No physical gamepads, physical keyboard rollover, human playtest, independent human review, human asset review or competition-organizer approval is claimed.
- No Karera finish logic, score calculation, Walis Cleanup gameplay, save system, network traffic, production art or audio was added.
- Export startup does not prove the exported game has physical input or release-ready content.
