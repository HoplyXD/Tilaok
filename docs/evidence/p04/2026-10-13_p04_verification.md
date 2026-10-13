# P04 verification index — item infrastructure and Kaing/Tulay seeds

**Status:** PASSED for P04-T01–T10, T12, T14–T19 and T21 (T10/T12/T19/T21 on code-drawn placeholders under a dated owner-approved scope note). P04-T11, T13, T20 and T22 are BLOCKED and unchecked.

**Build:** `main` rebased onto `647929f` (verified wall extension) plus the P04 commit; the physics, regression, lint, import and export runs below were repeated after the rebase except the 1080p captures and the performance sample, which were taken on the `9ee25c8` base; the later `647929f` delta changed only movement/tuning/wall code and docs, and all suites above were re-run on it. **Engine:** Godot 4.7.2.stable.official.ed1daf0bf. **Date:** 2026-10-13. **Profile/seed:** `karera_slice` / 12345. **Players:** 1–4 seats. **Input:** synthetic K1/K2 keyboard routing and synthetic gamepad seats; no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.

## Commands and results

| Check | Command | Result |
|---|---|---|
| P04 logic + real physics | `& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p04_tests.gd'` | **PASSED**, 265 checks, 0 failures. [Log](2026-10-13_p04_tests.txt) |
| Foundation regression (incl. Item Lab open/free/reload) | `... --script 'res://tests/run_foundation_tests.gd'` | **PASSED**, 0 failures. [Log](2026-10-13_foundation_tests.txt) |
| P02 regression | `... --script 'res://tests/run_p02_tests.gd'` | **PASSED**, 83 checks, 0 failures. [Log](2026-10-13_p02_tests.txt) |
| P03 regression | `... --script 'res://tests/run_p03_tests.gd'` | **PASSED**, 103 checks, 0 failures. [Log](2026-10-13_p03_tests.txt) |
| Interactive Item Lab (GUI, 1920×1080, harness button, K1/K2 join, place/rotate/confirm, Play, Reset, Clear, Return) | `... --path 'tilaok!' --script 'res://tests/run_p04_interactive.gd'` | **PASSED**, 25 checks, 0 failures (4 consecutive runs; an earlier flaky run was traced to a focused HUD button and window-focus pause and fixed). [Log](2026-10-13_interactive_test.txt) |
| Rendered captures + 48-piece performance | `... --path 'tilaok!' --script 'res://tests/capture_p04_evidence.gd'` | **PASSED**: median 1.954 ms, p95 3.109 ms, worst 6.059 ms; static 70.97 MiB; process peak working set 208.84 MiB, private 242.35 MiB (hold window 207.34 / 212.04, from the preceding identical-workload run). [Performance](2026-10-13_performance.txt), [memory](2026-10-13_memory_sample.txt), [log](2026-10-13_capture_log.txt) |
| Lint / format | `gdlint` and `gdformat --check` 4.5.0 on all 53 `.gd` files | **PASSED**. [Log](2026-10-13_static_checks.txt) |
| Wall-extension suite (not P04) | `... --script 'res://tests/run_p02_wall_tests.gd'` | **PASSED**, 85 checks, 0 failures on the rebased tree. [Log](2026-10-13_p02_wall_tests.txt) |
| Import/parse | `... --headless --editor --path 'tilaok!' --quit` | **PASSED**, exit 0, 0 error/warning lines. [Log](2026-10-13_import.txt) |
| Windows export + exported startup smoke | `... --headless --path 'tilaok!' --export-debug 'Windows Desktop' '../build/tilaok-p04.exe'`; then `tilaok-p04.console.exe --headless --quit-after 240 -- --open-room=item_lab` | **PASSED**: export exit 0; exported build printed `P04_ITEM_LAB_READY families=2 enabled_variants=3 profile=karera_slice` and exited 0. [Export](2026-10-13_export.log), [runtime](2026-10-13_export_runtime.log) |

## Performance versus the P03 baseline

P03 baseline (4 chickens, no items): median 0.826 / p95 1.426 / worst 6.141 ms; 199.91 MiB working set. P04 (4 chickens + 48 persistent pieces): median 1.954 / p95 3.109 / worst 6.059 ms; 208.8 MiB peak working set. Both are inside 16.67 ms and 512 MiB. **Disclosure:** the first capture run showed one 59.4 ms interval at frame 0, caused by the v-sync mode switch immediately before sampling; a 10-frame warm-up was added and the subsequent runs have no interval above 8 ms. A first memory sampler also matched an unrelated 790 MiB Godot editor process and was discarded in favour of a parent-PID filter.

## Rendered captures (1920×1080, minimum zoom ≈1.0)

- [2026-10-13_variants_enabled_1080p.png](2026-10-13_variants_enabled_1080p.png) — Enabled prototype variants: 1×1, 2×3, rotated 3×2 crates and the 4×1 Tulay with strip, dashed reservation and chevrons.
- [2026-10-13_variants_disabled_geometry_1080p.png](2026-10-13_variants_disabled_geometry_1080p.png) — Defined-but-disabled geometry under a capture-only tuning override: 1×3 column, rotated 3×1, Tulay 3×1/5×1 and the gated vertical Tulay (strip on the right edge).
- [2026-10-13_ghost_valid_invalid_1080p.png](2026-10-13_ghost_valid_invalid_1080p.png) — Valid Tulay ghosts (solid outline, OK mark, arrow) versus an invalid one (dashed outline, hatch, X mark, text reason).
- [2026-10-13_ghost_kaing_1080p.png](2026-10-13_ghost_kaing_1080p.png) — Kaing 2×3 ghosts: valid, rotated valid, protected spawn and out-of-bounds/goal invalid.
- [2026-10-13_crowd_48_1080p.png](2026-10-13_crowd_48_1080p.png) — 48 persistent pieces and four chickens; pieces remain distinguishable but chevrons and DEBUG labels crowd each other.
- [2026-10-13_item_lab_place_1080p.png](2026-10-13_item_lab_place_1080p.png) — Interactive Item Lab Place frame with two rotated crates, a Tulay and an invalid K2 ghost reason.
- [2026-10-13_item_lab_play_1080p.png](2026-10-13_item_lab_play_1080p.png) — Interactive Item Lab Play frame, grace elapsed.
- [2026-10-13_eggs_library_1080p.png](2026-10-13_eggs_library_1080p.png) — Placeholder egg previews (selected egg highlighted), ghost and the placeholder Library panel.

## Expected / actual rows (from the P04 test log)

| Case | Expected | Actual |
|---|---|---|
| T02 reject: missing family_id | family_id is required | 6 error(s) |
| T02 reject: missing ownership | ownership must be | 1 error(s) |
| T02 reject: missing safe_start | safe_start is required | 1 error(s) |
| T02 reject: missing removal_policy | removal_policy is required | 1 error(s) |
| T02 reject: missing persistence | persistence is required | 1 error(s) |
| T02 reject: missing event eligibility | event eligibility | 1 error(s) |
| T02 reject: missing wall_contact | wall_contact declaration | 1 error(s) |
| T02 reject: missing weight key | weight_tuning_key | 1 error(s) |
| T02 reject: missing preview silhouette | preview_silhouette is required | 1 error(s) |
| T02 reject: missing library tell | library_tell is required | 1 error(s) |
| T02 reject: no variants | at least one variant | 3 error(s) |
| T02 reject: missing variant id | variant_id is required | 2 error(s) |
| T02 reject: undocumented variant | undocumented variant | 2 error(s) |
| T02 reject: wrong documented footprint | does not match documented | 1 error(s) |
| T02 reject: zero footprint | footprint is required | 2 error(s) |
| T02 reject: no rotations | at least one documented rotation | 1 error(s) |
| T02 reject: rotation out of range | outside 0..3 | 1 error(s) |
| T02 reject: gated rotation undocumented | gated rotation | 1 error(s) |
| T02 reject: no regions | at least one region | 1 error(s) |
| T02 reject: region kind unset | region kind is required | 2 error(s) |
| T02 reject: zero-size region | missing, unbounded or non-positive | 2 error(s) |
| T02 reject: infinite region | missing, unbounded or non-positive | 2 error(s) |
| T02 reject: arena-sized region | exceeds the arena extent | 2 error(s) |
| T02 reject: effect not declared bounded | must declare explicit bounds | 1 error(s) |
| T02 reject: solid outside footprint | inside the footprint | 1 error(s) |
| T02 reject: strip without thickness key | thickness tuning key | 1 error(s) |
| T02 reject: strip thicker than cell | strip thickness is outside | 1 error(s) |
| T02 reject: strip overlaps solid | may not overlap a solid | 1 error(s) |
| T02 reject: enabled without verification | runtime_enabled requires | 1 error(s) |
| T02 reject: duplicate variant | duplicate variant | 2 error(s) |
| T02 reject: enabled variant undefined | is not defined | 1 error(s) |
| T06/T15 placement: valid 1x1 | valid | valid (Valid placement.) |
| T06/T15 placement: valid rotated 3x2 | valid | valid (Valid placement.) |
| T06/T15 placement: valid Tulay 4x1 | valid | valid (Valid placement.) |
| T06/T15 placement: out of bounds | out_of_bounds | out_of_bounds (Outside the arena. Move it inside the stage. (outside arena bounds)) |
| T06/T15 placement: past right edge | out_of_bounds | out_of_bounds (Outside the arena. Move it inside the stage. (outside arena bounds)) |
| T06/T15 placement: protected spawn | protected_spawn | protected_spawn (Spawn area is protected. Move it right of the spawn zone. (protected spawn zone)) |
| T06/T15 placement: protected goal | protected_goal | protected_goal (Goal area is protected. Move it away from the flag platform. (protected goal zone)) |
| T06/T15 placement: outside build region | outside_build_region | outside_build_region (Outside the build region. Move it inside the green area. (outside build region)) |
| T06/T15 placement: base geometry | immutable_base | immutable_base (Overlaps stage ground. Move it into open space. (immutable base geometry: arena.base_a)) |
| T06/T15 placement: disabled variant | variant_disabled | variant_disabled (This variant is not enabled in the current pool.) |
| T06/T15 placement: disabled Tulay 5x1 | variant_disabled | variant_disabled (This variant is not enabled in the current pool.) |
| T06/T15 placement: unknown variant | unknown_variant | unknown_variant (Unknown item variant. Pick one from the approved list.) |
| T06/T15 placement: 1x1 rotation | rotation_unsupported | rotation_unsupported (This variant cannot face that way. Rotate to a supported direction.) |
| T06/T15 placement: 180 degrees | rotation_unsupported | rotation_unsupported (This variant cannot face that way. Rotate to a supported direction.) |
| T06/T15 placement: vertical Tulay gated | rotation_unsupported | rotation_unsupported (This variant cannot face that way. Rotate to a supported direction.) |
| T06 placement: player clearance | player_clearance | player_clearance |
| T06 placement: overlap | item_overlap | item_overlap |
| T03 cap: 49th piece | persistent_cap | persistent_cap |
| T04 ten cycles: node count | stable at 124 | 124 |
| T04 ten cycles: object count | stable at 1797 | 1797 |
| T04 ten cycles: orphan nodes | stable at 0 | 0 |
| T09 Kaing 1x1 top | stands with feet at y=256 on build.hollow_blocks.cell_1x1#001, eligible player-built support | floor=true feet=255.98 reason=eligible built support |
| T09 Kaing 2x3 top | stands with feet at y=256 on build.hollow_blocks.stack_2x3#001, eligible player-built support | floor=true feet=255.98 reason=eligible built support |
| T09 Kaing rotated 3x2 top | stands with feet at y=256 on build.hollow_blocks.stack_2x3#001, eligible player-built support | floor=true feet=255.98 reason=eligible built support |
| T06 Kaing collider #0 | solid == footprint (32.0, 32.0), one shape, no trigger, occlusion == solid | footprint (32.0, 32.0) shape (32.0, 32.0) children 1 |
| T06 Kaing collider #1 | solid == footprint (64.0, 96.0), one shape, no trigger, occlusion == solid | footprint (64.0, 96.0) shape (64.0, 96.0) children 1 |
| T06 Kaing collider #2 | solid == footprint (96.0, 64.0), one shape, no trigger, occlusion == solid | footprint (96.0, 64.0) shape (96.0, 64.0) children 1 |
| T09 Kaing solid side | stopped at x>=396 (block right edge 384 + half body 12); side contact is not support | min_x=396.00 side_counted=false |
| T09 Kaing route foothold | chicken jumps from the floor onto the 1x1 foothold (top y=448) | on_foothold=true feet=447.93 |
| T09 Kaing underside | head stops at the solid underside y=288 with a ceiling contact | highest_head=288.00 ceiling=true |
| T08 Kaing removal | was supported; support is gone on the removal step; chicken falls to a different surface | stood=true immediate=no support feet_after=351.96 |
| T15 Tulay regions | footprint 128x32, one-way strip 128x4 at the top, footprint != strip | footprint (128.0, 32.0) strip [[P: (448.0, 256.0), S: (128.0, 4.0)]] |
| T18 Tulay land from above | lands with feet y=256 on the strip; eligible player-built support | floor=true feet=255.98 reason=eligible built support |
| T18 Tulay jump off | leaves the strip, rises about 96 wu, and lands back on it | left=true apex_feet=159.94 feet_after=255.98 |
| T18 Tulay walk off edge | walks past x=576 and lands on a different surface | x=836.33 feet=479.93 supported_by_tulay=false |
| T18 Tulay rise from below | passes up through the strip, is never support while rising, then lands on top (y=416) | min_feet=383.28 passed=true counted_rising=false final_feet=415.98 supported=true |
| T15 Tulay sides non-solid | body overlapping the strip height walks through the footprint side (x passes 470) | on_platform=true max_x=603.32 |
| T18 Tulay strip at fall cap | five drops reach ~900 wu/s and all land on the 4 wu strip (feet y=384), none tunnel | peak_speed=878.9 all_landed=true |
| T18 Tulay under ceiling | passes the strip, stops at the arena ceiling (head y>=0), then lands on top (feet y=96) | highest_head=0.00 ceiling=true final_feet=95.99 |
| T18 matrix: base floor | base surface | base surface |
| T18 matrix: airborne | no support | no support |
| T09/T18 disabled variant: Kaing 1x3 column | footprint (32.0, 96.0) and a chicken stands on its top at y=256 | footprint (32.0, 96.0) feet=255.98 stands=true |
| T09/T18 disabled variant: Kaing 1x3 rotated 3x1 | footprint (96.0, 32.0) and a chicken stands on its top at y=256 | footprint (96.0, 32.0) feet=255.98 stands=true |
| T09/T18 disabled variant: Tulay 3x1 | footprint (96.0, 32.0) and a chicken stands on its top at y=256 | footprint (96.0, 32.0) feet=255.98 stands=true |
| T09/T18 disabled variant: Tulay 5x1 | footprint (160.0, 32.0) and a chicken stands on its top at y=256 | footprint (160.0, 32.0) feet=255.98 stands=true |
| T15 gated vertical Tulay geometry | 1x4 footprint, 4 wu strip on the right edge, one-way normal pointing right | footprint (32.0, 128.0) strip [[P: (572.0, 192.0), S: (4.0, 128.0)]] normal [(1.0, 0.0)] |
| T09 Kaing wall eligibility | metadata ELIGIBLE and the wall probe finds the solid side | metadata=1 probe=true |
| T18 Tulay wall eligibility | metadata INELIGIBLE and no wall at the strip's side | metadata=0 probe=false |
| T10/T19 egg to ghost to piece identity | claiming an egg yields a ghost and a placed piece of the same variant and size | identity_ok=true |
| T12/T21 Library entry fields | both families list name, sizes, placement, tell, counterplay, controls, modes, animation | entries=2 fields_ok=true |

## Known limits

- Eggs, ghosts and the Library are code-drawn placeholders; the shared P05 preview components and the P13 Library shell do not exist, and final art is human-made.
- No projectile, bubble or VFX item exists in P04: the transient budget is exercised only by labeled test-only emitters.
- Kaing projectile cover is verified as occlusion-volume equality with the solid, not with a real projectile.
- Tulay occlusion is undefined (no SOLID region); revisit with the first projectile item.
- The vertical Tulay orientation is geometry only and remains gated; it was never driven by the controller.
- Peak fall speed is sampled after the slide step (878.9 wu/s against a 900 cap).
- Wall slide/kick is a separate, disabled-by-default extension (P02-T15–T22). Kaing declares solid-side wall eligibility and Tulay declares itself ineligible; only the metadata and the extension's probe were checked.
- Item Lab placement is immediate and lab-only; P05 owns the atomic resolver, Pugad and previews.
- Input was synthetic keyboard routing and synthetic gamepad seats; no physical device, rollover or human feel evidence exists.
- All visuals are code-drawn DEBUG graybox; no production art or audio was created.
