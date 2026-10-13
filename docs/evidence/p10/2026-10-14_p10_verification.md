# P10 verification record — 2026-10-14

**Source baseline:** `main` at `a368c96` (P06 landed during this work) plus the P10 working tree.
**Engine:** Godot 4.7.2.stable.official.ed1daf0bf (`--version` re-checked; PATH `godot` 4.6.3 was not used).
**Machine:** Windows, Intel Core i5-13420H (12 logical CPUs), NVIDIA GeForce RTX 4050 Laptop GPU.
**Profile/seed:** development `items_lab` (all eight first-batch families), seed 12345 unless a case states its own.
**Input:** synthetic K1/K2 keyboard events and synthetic gamepad events for seats 3/4. No physical device, no human playtest, no independent human review is claimed.
**Release state:** nothing is release-enabled. Every family has `release_target=false`.

## Scope verified

Six new families (`move.tire_spring`, `hazard.rail_trumpo`, `hazard.parol_pulse`, `hazard.slipper_launcher`, `utility.walis_cleanup`, `hazard.bubble_planter`) with 14 new approved variants (20 with Kaing/Tulay), replaceable PLACEHOLDER presentation, the Item Visualizer, and the all-families P05 match pool. Integration with Lagsanay, Kangaroo and stack pairing, and release enablement, are **not** implemented and stay unchecked.

## Architecture as built (and deviations from the approved plan)

| Plan | As built | Why |
|---|---|---|
| `items_lab` as a `ProfileRegistry` profile | A room-level profile constant in `ItemEnabledProfiles` (applied by the Visualizer and `MatchRoomItemsLab`); `karera_spring` is made truthful there | The foundation baseline asserts exactly seven registered profiles; changing it would edit a baseline test |
| One scene per family | One shared `scenes/items/hazard_piece.tscn` + per-family behaviour classes | The scenes would have been identical; behaviour and visuals come from data |
| `egg_loop` visual slot | Dropped; the egg, ghost, Library and live piece all draw through one painter that reads the part slots (`body`, `top`, `post`, …) | One source of truth; an `egg_loop` image could not show the exact variant |
| Two additive controller hooks | `carry_captive_to()` (only for a CAPTURED chicken) and `clear_external_motion()` | As approved (D8) |
| Attribution records only | Records plus a hand-off of direct eliminations to the P06 ledger through `ItemEliminationBridge` / `ItemHazardDirector.elimination_sink` | P06 landed with a candidate interface (`queue_elimination(seat, tick, source_item_id, direct_owner_seat)`); without the hand-off the ledger would never see item kills. The ledger, not P10, orders outcomes, drops self-kill credit and computes points |
| Baselines unchanged | `ItemDefinitions.load_all()` still returns exactly Kaing/Tulay; first-batch families load through `load_for_profile()`; no baseline test was edited | Seeded P04/P05 pools stay byte-identical |

## Automated suite results

| Suite | Result | Log |
|---|---|---|
| Foundation harness/lifecycle | 0 failures | [log](suite_run_foundation_tests.log) |
| P02 input/movement | 83 checks, 0 failures | [log](suite_run_p02_tests.log) |
| P02 wall movement | 85 checks, 0 failures | [log](suite_run_p02_wall_tests.log) |
| P03 graybox | 103 checks, 0 failures | [log](suite_run_p03_tests.log) |
| P04 Item Lab | 268 checks, 0 failures | [log](suite_run_p04_tests.log) |
| P05 match loop | 137 checks, 0 failures | [log](suite_run_p05_tests.log) |
| P06 Karera scoring | 97 checks, 0 failures | [log](suite_run_p06_tests.log) |
| UI gallery | 437 checks, 0 failures | [log](suite_run_ui_tests.log) |
| **P10 tests** | **421 checks, 0 failures** | [log](suite_run_p10_tests.log) |
| P04 interactive | 25 checks, 0 failures | [log](suite_run_p04_interactive.log) |
| P05 interactive | 64 checks, 0 failures | [log](suite_run_p05_interactive.log) |
| P06 interactive | 17 checks, 0 failures | [log](suite_run_p06_interactive.log) |
| **P10 interactive** | **56 checks, 0 failures** | [log](suite_run_p10_interactive.log) |
| P03 interactive | 14 checks; **flaky**: failed 2 of 4 runs (and 1 of 2 in this batch) on the **unchanged `a368c96` checkout** at the "Return restores the harness" step and passes otherwise | [log](suite_run_p03_interactive.log) |

The interactive suites write their screenshots into other phases' evidence folders, so they were run from an **isolated copy** of the project (`%TEMP%\p10_iso`); only the P10 logs and screenshots were written into `docs/evidence/p10/`. `gdlint` and `gdformat --check` pass on the whole project (143 files). Import/parse: `--headless --editor --quit` completes with no errors or warnings.

## Per-family measurements (from `run_p10_tests.gd`)

| Family | Case | Expected | Actual |
|---|---|---|---|
| Gulong | plain launch rise | ≈160 wu (775²/2g) | 168.2 wu (fixed 60-Hz step adds ~half a step of velocity) |
| Gulong | timed-jump boost rise | ≈192 wu | 200.8 wu |
| Gulong | cooldown | one launch per 0.20 s | 1 in the first 10 frames, 4 by frame 40 |
| Gulong | side launch cap | ≤480 wu/s | 480.0 wu/s |
| Gulong | ceiling containment | never above the arena | minimum centre y 24.00, no bounds event |
| Gulong | face support | not wave support | `ineligible surface` |
| Trumpo | travel | whole visible rail | centre x 458.0–598.0 for a 448–608 rail and 20 wu top |
| Trumpo | endpoint pause | 0.75 s | 45 frames |
| Trumpo | period | 3.25 s | 3.25 s |
| Trumpo | tunnelling | none at 40 wu/frame | eliminated a 24 wu body |
| Trumpo | start direction at 0/90/180/270 | RIGHT/DOWN/LEFT/UP | RIGHT/DOWN/LEFT/UP |
| Parol | charge start | 0.900 s ±1 step | 0.900 s |
| Parol | active start | 1.500 s ±1 step | 1.517 s |
| Parol | active frames per 2 cycles | 180 ±3 | 180 |
| Parol | phase changes per second | ≤1.5 | 0.92 |
| Parol | cover | beam shortened by block width | 64 wu of 96 wu |
| Tsinelas | fire | ~78 frames after arming ±3 | 76 (telegraph from 28) |
| Tsinelas | speed | 6.0 wu/frame | 6.00 |
| Tsinelas | flight | bounded by lane and 3 s TTL | gone at frame 98 |
| Tsinelas | spawn inside a chicken | suppressed | 0 fired, ≥1 suppressed |
| Tsinelas | cap 3 with six emitters | never above 3, all fire | peak 3, all fired |
| Walis | exact set | two earlier-round blocks | exactly those two |
| Walis | overlap | one union | shared block removed once |
| Bula | capture length | 120 ±4 frames | 121 |
| Bula | no control | position unchanged | unchanged |
| Bula | cleanup paths | not captured, 0 captives | removal, death, round end, reset — all pass |
| Cross | same-step tie | stable item ID | lowest item ID, one record |
| Cross | pause mid-cycle | clocks frozen | unchanged over 30 paused frames; resumed |
| Cross | ten reset cycles | stable nodes | 168 → 168 |

## Item Visualizer and match loop (rendered, 1920×1080)

The harness opens the Visualizer from its own **Item Visualizer** button and the all-families match from **P05 Match (all items)**. `run_p10_interactive.gd` drives K1/K2 with real key events and two synthetic gamepad devices: rotate, confirm, Place → Play, the Library with its release filter, a one-shot Walis edit, a seeded Pugad that offers first-batch eggs, exact egg → ghost → placed variant handoff, simultaneous four-seat confirm, Play and a goal-contact round end with the new families on the stage.

Screenshots: [Visualizer Place](01_visualizer_place_1920x1080.png), [Visualizer Play](02_visualizer_play_1920x1080.png), [Library](03_visualizer_library_1920x1080.png), [match Pugad](10_match_pugad_items_1920x1080.png), [match Place](11_match_place_items_1920x1080.png), [match Play](12_match_play_items_1920x1080.png); per-family sheets `*_sheet_variants_rotations_*.png`; [Walis targets/protected](walis_preview_targets_protected_1920x1080.png); [tell states](tells_t0_ready_inactive_1920x1080.png), [t1](tells_t1_charge_telegraph_compress_1920x1080.png), [t2](tells_t2_active_fire_paused_1920x1080.png); [eggs](egg_previews_every_new_variant_1920x1080.png); [ghosts](ghosts_regions_validity_1920x1080.png); [crowded stage](crowded_mixed_48_items_play_1920x1080.png).

What the renders show (inspected by the automated author): every variant/rotation sits on its own sheet with its footprint, solid/trigger/sweep/lane/effect regions and first-blocker marks; Parol reads as dotted line → thickening line → solid band with a changing shape, not colour alone; the launcher lane stays visible and stops at the first solid with a red bar; Bula's path and captive ring are visible; Walis marks targets with an X and protected areas with grey hatching. No effect alternates faster than ~1 Hz. The 48-item stage is dense: owner/name tags overlap at this density (they can be hidden with **Owner tags**), which is a known readability limit of the debug tag, not of the item shapes.

## Placeholder swap

| Case | Result |
|---|---|
| Resource-level: replace the `body` slot texture and the `sfx_launch` stream at runtime | Rendered magenta pixels in the spring rect rose from 0 to the swapped art and the swapped sound played through the same call; restoring returned 0 ([log](suite_capture_p10_evidence.log)) |
| File-level: overwrite `PLACEHOLDER_body.svg` with a magenta SVG, re-import, run the probe, restore | 0 → 4960 → 0 magenta pixels with no code or resource edit ([probe](swap_file_level_probe.txt)) |
| Release gate | `PlaceholderAudit.release_violations()` flags any `release_target && runtime_enabled` family that still has a PLACEHOLDER slot (test copy flagged; real definitions: none, nothing is release-enabled); `placeholder_files()` lists all 23 `PLACEHOLDER_*` files |

## Performance (1920×1080, V-sync off, 600 rendered frames, four seats)

48 persistent items (16 launchers, 4 bubble emitters, 4 springs, 4 rails, 3 Parol and filler blocks), peak **16 projectiles** and **4 bubbles** (both at their caps), `DisplayServer` windowed. Median **3.25 ms**, p95 **4.57 ms**, worst **5.70 ms**; 80.85 MiB static memory; 327 nodes; 0 orphan nodes; director step mean 0.98 ms, worst 2.35 ms. Budget: 16.67 ms / 512 MiB / 0 B/s (local only). For reference P04: 1.954/3.109/6.059 ms, 70.97 MiB, 232 nodes; P05 with 48 pieces: 2.272/4.720/11.011 ms, 79.78 MiB, 302 nodes. The first-batch tells are drawn, not spawned, so the 32-effect cosmetic pool is not exercised (**COULD-NOT-RUN**: no VFX emitter exists). Single local machine; not a release-device guarantee. See [p10_performance.txt](p10_performance.txt).

An earlier run measured 5.2–9.3 ms median because the Visualizer rebuilt region overlays and readout text every frame and pieces redrew while inert; both were made change-driven before the numbers above.

## Windows export

`--export-release "Windows Desktop"` with the matching 4.7.2 templates exited 0 and produced a 109 MB executable ([log](windows_export.log)). The exported executable started headless with `--quit-after 120 -- --open-room=item_visualizer` and `--open-room=p05_match_items`, printed `P10_ITEM_VISUALIZER_READY families=8 variants=20` and `P05_MATCH_READY`, and exited 0 ([runtime](windows_export_runtime.log)). Startup smoke only.

## Known limits and open items

- Placeholder art/audio only; final art/audio are human-made (Jorge/Ivie, Shanti). Names are working names awaiting native-speaker review. No cultural claim is made.
- Spring "genuinely supported by a separate safe face" is not implemented (whole body support-ineligible).
- Integration with Lagsanay/Kangaroo/stacks and release enablement are blocked on P08-T06, P11-T12, P12-T04, P12-T06/T08/T10 and P13-T06 (all unchecked).
- Bula no-safe-spot is verified on the resolver and the last-safe-point branch, not in a fully enclosed physical cage; capture-to-elimination chains in Lagsanay are not evaluated.
- Hidden event-goal clearance (Walis exclusion) cannot be tested: no hidden event goal exists yet.
- No human feel/balance review; synthetic input is not physical-device evidence.
- Another agent session committed P06 into the same worktree while this work was in progress; P10 edits to `match_room.gd`, `p03`-adjacent tuning and docs were applied as small additive hunks on top of its commit.
