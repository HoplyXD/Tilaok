# Project structure and responsibility map

P01 foundation plus P02 input/movement, P03 graybox stage/camera/support, P04 item-infrastructure and the P05 diagnostic lobby-to-next-round construction loop for Godot 4.7. The main scene opens a local development harness; choose P03 Graybox Arena, Item Lab or P05 Match Loop. P05 supports 2–4 local seats, Pugad claims, atomic Place edits, diagnostic Play and a no-score results shell. It does not implement Karera finish/scoring, Walis Cleanup gameplay, persistent saves, networking or full Lagsanay/Kangaroo rules.

| Area | P01 path | Responsibility and current state |
|---|---|---|
| Project entry | `tilaok!/project.godot`, `tilaok!/scenes/harness/` | Starts the foundation harness; its P02 button opens the playable movement/input diagnostic fixture. |
| Configuration | `tilaok!/scripts/config/` | Typed provisional tuning, presentation settings, immutable-at-run-start snapshots, and seven labeled profiles. P02 movement/input constants are centralized in `gameplay_tuning.gd`; snapshots are used by the fixture. |
| Content diagnostics | `tilaok!/scripts/diagnostics/` | Catalog validation, verified-content eligibility, normalized weights, and independent seeded diagnostic RNG streams. No gameplay content is enabled. |
| Harness | `tilaok!/scripts/harness/`, `tilaok!/scenes/harness/` | Local profile/seed identity, validation, fixture open/close, scenario reset, full harness reload, exit, and paused presentation configuration. Diagnostics do not enter a player HUD. |
| Fixture rooms | `tilaok!/scenes/fixtures/`, `tilaok!/scripts/harness/p02_movement_room.gd`, `tilaok!/scripts/harness/p03_stage_room.gd` | P02 retains its four-seat movement/input probes. `p03_stage_room.tscn` builds the 64-unit-grid (since 2026-10-14; was 32), 2048×1024-wu arena drawn with the 64 px stage TileMapLayer with labeled protection/bounds, live diagnostic actors, Play/Place camera targets, pointers and support-contact indicators. These are fixtures, not complete game modes or production UI. |
| Input and seats | `tilaok!/scripts/input/` | Device-to-seat registry, permanent identity markers, phase-specific input routing, edge/repeat gating, pause/reconnect and all-ready resume coordination. Physical keyboard/controller coverage is still open. |
| Movement and lifecycle | `tilaok!/scripts/movement/` | Current code provides the typed run/jump controller, separate body/contact sensor, intentional-input reporting, external force, terminal/capture/opening-freeze precedence and bounds event. `wall_contact_probe.gd` plus controller hooks implement the approved Should wall slide/jump (enabled by default (core movement, owner decision 2026-10-13); automated checks pass, human review pending; P02-T15–T22). |
| Arena and support | `tilaok!/scripts/stage/` | `ArenaDefinition` owns tile-edge geometry, protected zones, immutable signatures and narrow edit/removal guards. `SupportSurfaceMetadata`, `SupportContact` and `SupportTracker` require explicit provenance/eligibility and actual current upward collision contact. P05 atomic placement consumes the arena protection/removal APIs; demolition and the Kangaroo event scheduler remain unimplemented. |
| Camera | `tilaok!/scripts/camera/` | `BoundedStageCamera` fits actual Play actor or unconfirmed Place extents inside the HUD-safe viewport, clamps to world bounds, and uses fast zoom-out/safe inward easing. HUD compensation is applied once during target fitting, not again during easing. `StageCameraTarget` identifies cached target rectangles. |
| Recovery contract | `tilaok!/scripts/harness/containment_recovery_contract.gd` | Narrow Race/Lagsanay/Kangaroo diagnostic outcome and pre-round snapshot contract; not the production score/restart system. |
| Checks | `tilaok!/tests/` | `run_foundation_tests.gd` includes repeated P03 cleanup/reload regressions; `run_p02_tests.gd` preserves P02 tests; `run_p03_tests.gd` covers route/protection/camera/support; `run_p03_interactive.gd` drives the visible GUI; `capture_p03_evidence.gd` saves rendered views and performance observations; `capture_p03_camera_jitter.gd` renders the close-chicken camera regression at 1080p; `run_p04_tests.gd` covers item definitions/validation, lifecycle, caps and real-physics Kaing/Tulay trials; `run_p04_interactive.gd` drives the Item Lab GUI; `capture_p04_evidence.gd` saves 1080p captures and the 48-piece performance sample; `run_p02_wall_tests.gd` and `capture_p02_wall_evidence.gd` cover the wall extension. |
| Stage tiles (2026-10-14) | `tilaok!/scenes/stage/stage_tiles.tscn`, `tilaok!/scripts/stage/stage_tile_layer.gd`, `tilaok!/assets/tiles/`, `tilaok!/tools/make_debug_tiles.gd` | 64×64 px TileMapLayer painted from `ArenaDefinition` surfaces (visual only; per-surface collision bodies keep their support/wall metadata). The atlas is a DEBUG placeholder written by the tool script; replace the PNG, keep the 64 px tile size. |
| Stage blocks (2026-10-14) | `tilaok!/scenes/blocks/`, `tilaok!/scripts/items/solid_block.gd`, `wood_box.gd`, `collapsing_block.gd`, `stage_block_support.gd`, `tilaok!/data/items/build.solid_block.tres`, `build.wood_box.tres`, `build.collapsing_block.tres` | One editable scene per block (root body + `CollisionShape2D` + `Visual`), authored at turn 0 and centered on its footprint. To change a block's look, edit its `Visual` node; its size comes from the `.tres` footprint (tests check the scene matches). `ItemManager` places them through the same interface as `ConstructionPiece`. |
| Items | `tilaok!/scripts/items/`, `tilaok!/scenes/items/`, `tilaok!/data/items/` | `ItemFamilyDefinition`/`ItemVariantDefinition`/`ItemRegionSpec` typed resources, `ItemApprovedVariants` (documented variant table), one `ItemDefinitionValidator`, `ItemDefinitions` loader/catalog rows, `ItemPlacementValidator` (reasoned rejections), `ItemManager` (placement, Walis-hook removal, Place/Play/round/match lifecycle, 48-piece cap), `TransientBudget` (16/4/32 caps, TTLs, rotating allocation, captive-safe release), `ConstructionPiece` + `kaing_piece.tscn`/`tulay_piece.tscn`, `ItemGhost`, placeholder `ItemEggPreview` (animated egg, click to claim a variant) and `ItemLibraryEntry` (placeholder Library model with a release filter). `.tres` definitions for `build.hollow_blocks` and `build.bamboo_bridge`. Item tunables are `item_*` fields in `gameplay_tuning.gd`. |
| Item Lab | `tilaok!/scripts/harness/item_lab_room.gd`, `tilaok!/scenes/fixtures/item_lab.tscn` | No longer a placeholder: extends the P03 stage room with immediate lab-only placement, rotate/confirm, Play/Reset/Clear all, and an `--open-room=item_lab` startup hook for exported smoke tests. |
| UI shells | `tilaok!/scenes/ui/`, `tilaok!/scripts/ui/`, `tilaok!/assets/ui/`, `tilaok!/data/ui/` | Scene-authored placeholder UI: screens, components, the single project Theme (`assets/ui/theme/tilaok_theme.tres`), SAMPLE data resources, `UiScreen` base, `UiMenuList`, `UiInputBridge` and the UI Gallery harness room. Scripts only bind data; layout/style live in scenes and the Theme. Not yet wired into the P05 match room. |
| Future responsibilities | events, scoring, presentation and remaining item families | Karera finish rules, score calculation, Walis Cleanup gameplay, full Lagsanay/Kangaroo rules, save/network systems and production UI/assets remain unimplemented. P05 provides only the diagnostic lobby/construction/round shell. |

## Programming provenance and review

AI/LLM-assisted programming, including core gameplay generation, is the standing Tilaok! development workflow. Francis (lead developer) and Carlos (co-lead developer) direct development using these tools and retain integration, review, testing and delivery responsibility. P01–P05 implementation code was AI-generated under the standing workflow and is not represented as manually team-written. The P02 wall extension was authored by Claude; P03–P05 work in this checkout was authored by Codex. See [AI_USAGE.md](AI_USAGE.md) for the current policy and cumulative disclosure, and [COMPETITION.md](COMPETITION.md) for the recorded external-rule summary and its limitations. P01-T02's actual human review remains open. The workflow does not establish organizer approval or competition eligibility; Form 03 and other submission requirements remain separate.

## Running the foundation

From the repository root, use the explicit Godot 4.7.2 executable recorded in `docs/PRODUCTION.md`:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --editor
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_foundation_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p02_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p03_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p02_wall_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p02_wall_evidence.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_p03_interactive.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p03_evidence.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p04_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_p04_interactive.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p04_evidence.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p03_camera_jitter.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p02_room.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --export-debug 'Windows Desktop' '../build/tilaok-p02.exe'
```

The first command launches the local harness. Choose **P03 Graybox Arena** for the bounded course; its visible join controls add K1/K2 and its HUD switches the diagnostic Play/Place views. Since 2026-10-14: K1 A/D move, W jump (hold to glide), S sneak, Space alternate jump; K2 arrows (Up jump/glide, Down sneak), Ctrl alternate jump, Enter confirm. The 64 px grid, sneak/glide and stage-block checks run with `--headless --path 'tilaok!' --script 'res://tests/run_blocks_tests.gd'`; rendered captures with `--path 'tilaok!' --script 'res://tests/capture_blocks_evidence.gd'` ([evidence](evidence/blocks/README.md)). Choose **Item Lab** for the P04 construction seeds (Place → Variant → move/rotate/confirm → Play); choose **P02 Movement Room** for the original input/movement probes; shared keyboard remains an explicit P02 option.

The P02/P03 test commands use synthetic inputs plus real Godot physics, timers and scene lifecycle. The P03 route is actual collision traversal; camera actor/preview rectangles are labeled synthetic fixtures. Synthetic events are not physical-device evidence. Physical controller/reconnect and keyboard rollover procedures remain open in [PLAYTEST](PLAYTEST.md). Current P03 screenshots, tests and Windows export/startup evidence are indexed in `docs/evidence/p03/2026-10-13_p03_verification.md`; P04 evidence is indexed in `docs/evidence/p04/2026-10-13_p04_verification.md`.

Windows export preset output is `build/tilaok-p02.exe`; generated build output is ignored by Git.

## P05 match-loop responsibilities and commands

| Area | P05 path | Responsibility and current state |
|---|---|---|
| Match room | tilaok!/scenes/match/ and tilaok!/scripts/match/match_room.gd | P05MatchRoom inherits the P04 stage room, adds the 2–4 seat lobby, phase shell, controls, diagnostic Play and results/next-round surface. The result panel is a P06 binding shell; P05 awards no points. |
| Phase and lobby | tilaok!/scripts/match/match_phase_controller.gd and lobby_view_model.gd | Minimum-two/all-ready start gate, phase timers, fixed seat identity and pause-frozen Pugad/Place/Results time. |
| Eggs and claims | tilaok!/scripts/match/pugad_egg_pool_generator.gd, pugad_claim_arbiter.gd and pugad_egg_card.gd | Seeded family-weight/within-family selection from enabled variants, duplicate variant definitions allowed, one distinct egg per seat, stable earlier/same-tick/timeout arbitration. |
| Place and results | tilaok!/scripts/match/placement_controller.gd, atomic_edit_resolver.gd and match_results_view_model.gd | Pending confirmations resolve against one snapshot and batch-commit in stable seat order; results carry outcome/award/no-score/total fields without calculating awards. |
| UI gallery fixture | tilaok!/scenes/ui/, tilaok!/scripts/ui/, tilaok!/data/ui/ and tilaok!/assets/ui/theme/ | Standalone DEBUG review gallery and sample data exercise reusable screen/component shells across device glyphs and seat counts. It is not connected to the P05 match room or its results/scoring pipeline. |
| Harness entry | tilaok!/scripts/harness/foundation_harness.gd and foundation_harness.tscn | P05 Match Loop opens the P05 scene; Item Lab remains the P04 immediate-placement regression fixture. |
| P05 checks/evidence | tilaok!/tests/run_p05_tests.gd, run_p05_interactive.gd, run_ui_tests.gd, capture_p05_evidence.gd and p05_fixtures.gd | Automated deterministic checks, visible four-seat harness loop, standalone 437-check UI gallery contract runner, test-only mover/cleanup/solid-trigger fixtures, rejection/variant captures and 48-piece performance capture. |

From the repository root:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p05_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_p05_interactive.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_ui_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p05_evidence.gd'
```

Choose **P05 Match Loop** in the harness. Join and ready two or more seats. K1 uses WASD/Space; K2 uses arrows/Ctrl. F/Enter confirms or readies, arrows select an egg, and R/Right Shift rotates supported variants. Diagnostic Play advances only through the labeled End Round/flag-touch controls. Synthetic gamepad seats 3/4 are used in the recorded harness evidence; physical gamepads are not certified. See the [P05 verification record](evidence/p05/2026-10-14_p05_verification.md). All newly drawn UI/item visuals are DEBUG placeholders.

## UI shell commands

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_ui_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_ui_evidence.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' 'res://scenes/ui/ui_gallery.tscn'
```

In the harness, **UI Gallery** shows every screen/state with SAMPLE data and **Player flow (Title)** starts at Title with the review panel hidden (F9 shows it). Designers edit the scenes and Theme in the Godot editor; see the how-to in [UI_HANDOFF.md](UI_HANDOFF.md).
