# Project structure and responsibility map

P01 foundation plus P02 input/movement, P03 graybox stage/camera/support, P04 item infrastructure, P05 lobby/Pugad/atomic Place, P06 Karera with explained race results, scoped P07 First Playable, standalone P08 Lagsanay Lab, P09 full-match lifecycle, and P11 independent Kangaroo route run on Godot 4.7. The main scene opens a local development harness; choose P03 Graybox Arena, Item Lab, P05 Match Loop, P07 First Playable, P08 Lagsanay Lab, P09 Match Lifecycle or P11 Kangaroo Lab. P07–P09 and P11 are development routes over a local 2–4 seat loop. P08, P09 and P11 have technical evidence but are not release profiles; P07 player/device/human acceptance remains open. P09 ends at the score target or round 12 and routes tied leaders to Lagsanay on the same constructed stage; it does not implement P12 scheduling/stacks. P11 independently evaluates Freeze, Rising and Hug with a seeded Slipper Storm; it does not instantiate the Lagsanay controller. Human acceptance, event stacks, persistent saves, networking, final production UI/art and complete release onboarding remain unimplemented.

| Area | P01 path | Responsibility and current state |
|---|---|---|
| Project entry | `tilaok!/project.godot`, `tilaok!/scenes/harness/` | Starts the foundation harness; its P02 button opens the playable movement/input diagnostic fixture. |
| Configuration | `tilaok!/scripts/config/` | Typed provisional tuning, presentation settings, immutable-at-run-start snapshots, and labeled profiles. P02 movement/input, P08 Lagsanay, P09 match lifecycle and P11 Kangaroo timing/Rising lines/Storm caps are centralized in `gameplay_tuning.gd`; gameplay tuning remains provisional. |
| Content diagnostics | `tilaok!/scripts/diagnostics/` | Catalog validation, verified-content eligibility, normalized weights, and independent seeded diagnostic/gameplay streams, including `kangaroo`. Development profiles enable only their explicit allowlists; none is release-enabled. |
| Harness | `tilaok!/scripts/harness/`, `tilaok!/scenes/harness/` | Local profile/seed identity, validation, fixture open/close, scenario reset, full harness reload, exit, and paused presentation configuration. P08, P09 and P11 are available by buttons or `--open-room=p08_lagsanay`, `--open-room=p09_match_lifecycle` and `--open-room=kangaroo_contract_lab`. Diagnostics do not enter a player HUD. |
| P07 First Playable | `tilaok!/scenes/match/p07_first_playable_room.tscn`, `tilaok!/scripts/match/p07_first_playable_match_room.gd` | Dedicated harness route over the existing match room. Keeps `karera_slice` profile identity but sets a per-room tuning copy to `build.hollow_blocks.cell_1x1`, `build.hollow_blocks.stack_2x3`, and `build.bamboo_bridge.span_4x1`; validates each generated Pugad pool and returns to Lobby with an error if an unsupported variant appears. Adds reset audit rows without changing shared tuning or other profiles. |
| P08 Independent Lagsanay | `tilaok!/scenes/match/p08_lagsanay_room.tscn`, `tilaok!/scripts/match/p08_lagsanay_match_room.gd`, `lagsanay_round_controller.gd`, `lagsanay_score_calculator.gd` | Dedicated independent pass-through tag route over the persistent stage and Lobby → Pugad → Place → Lagsanay → results → next round. Does not instantiate Karera clock/controller or race awards. Uses `lagsanay_lab`; only Kaing, Tulay, Trumpo and Launcher variants are eligible. Trumpo/Launcher real direct-contact attribution, timer/placement/Last Cluck and 2/3/4-seat engineering checks pass. Development-only; P07-T04 and human/device acceptance remain open. |
| P09 Match Lifecycle | `tilaok!/scenes/match/p09_match_lifecycle_room.tscn`, `tilaok!/scripts/match/p09_match_lifecycle_room.gd`, `match_lifecycle_coordinator.gd`, `match_results_view_model.gd`, `ui_match_result_screen.gd` | Dedicated development route over P07's `karera_slice` identity and three-variant allowlist. Commits real Karera round awards once, checks integer eighth-point totals against 80 or completed round 12, sends only tied top original seats into P08 Lagsanay on the same stage, and binds exact scores/outcome/one winner to the themed result screen. Replay derives a reproducible new seed from base seed + match identity; Lobby/Quit and confirmation/readiness flows reset the group. P12 schedule/stacks and release behavior remain out of scope. See [P09 evidence](evidence/p09/README.md). |
| P11 Independent Kangaroo | `tilaok!/scenes/match/p11_kangaroo_room.tscn`, `tilaok!/scripts/match/p11_kangaroo_match_room.gd`, `kangaroo_round_controller.gd`, `kangaroo_command_instance.gd`, `kangaroo_slipper_presenter.gd` | Standalone `kangaroo_contract_lab` profile using the existing match lifecycle, persistent construction, `SupportTracker`, `PlacementScoreResolver` and shared attribution/scoring helpers. Race goal/deadline are inactive; no `LagsanayRoundController` is created. Only Trumpo and the Tsinelas Launcher are enabled. Seeded command cadence, input-edge Freeze, current-support Rising, pair-only Hug, batched terminal resolution and capped Slipper Storm pass the 77-check focused suite and 81-check 2/3/4 synthetic route. P12 stacks/schedule, release eligibility, human/device review and performance acceptance remain open. See [P11 evidence](evidence/p11/README.md). |
| Fixture rooms | `tilaok!/scenes/fixtures/`, `tilaok!/scripts/harness/p02_movement_room.gd`, `tilaok!/scripts/harness/p03_stage_room.gd` | P02 retains its four-seat movement/input probes. `p03_stage_room.tscn` builds the 64-unit-grid (since 2026-10-14; was 32), 2048×1024-wu arena drawn with the 64 px stage TileMapLayer with labeled protection/bounds, live diagnostic actors, Play/Place camera targets, pointers and support-contact indicators. These are fixtures, not complete game modes or production UI. |
| Input and seats | `tilaok!/scripts/input/` | Device-to-seat registry, permanent identity markers, phase-specific input routing, edge/repeat gating, pause/reconnect and all-ready resume coordination. Physical keyboard/controller coverage is still open. |
| Movement and lifecycle | `tilaok!/scripts/movement/` | Current code provides the typed run/jump controller, separate body/contact sensor, intentional-input reporting, external force, terminal/capture/opening-freeze precedence and bounds event. `wall_contact_probe.gd` plus controller hooks implement the approved Should wall slide/jump (enabled by default (core movement, owner decision 2026-10-13); automated checks pass, human review pending; P02-T15–T22). |
| Karera and shared placement | `tilaok!/scripts/match/race_round_controller.gd`, `race_outcome_ledger.gd`, `race_score_calculator.gd`, `placement_score_resolver.gd`, `score_format.gd`, `race_candidate_queue.gd` | Karera retains its active-simulation deadline, goal trigger, batch ordering and race awards. P10 runtime hazards report real direct-contact attribution; P08 uses a separate independent sink and the shared placement resolver's comparable-time extension. Barya has no gameplay integration. See P06/P08 tracker and evidence. |
| Arena and support | `tilaok!/scripts/stage/` | `ArenaDefinition` owns tile-edge geometry, protected zones, immutable signatures and narrow edit/removal guards. `SupportSurfaceMetadata`, `SupportContact` and `SupportTracker` require explicit provenance/eligibility and actual current upward collision contact. P05 atomic placement consumes the arena protection/removal APIs; standalone Kangaroo uses the current support record for Rising. Demolition remains unimplemented. |
| Camera | `tilaok!/scripts/camera/` | `BoundedStageCamera` fits actual Play actor or unconfirmed Place extents inside the HUD-safe viewport, clamps to world bounds, and uses fast zoom-out/safe inward easing. HUD compensation is applied once during target fitting, not again during easing. `StageCameraTarget` identifies cached target rectangles. |
| Recovery contract | `tilaok!/scripts/harness/containment_recovery_contract.gd`; `p08_lagsanay_match_room.gd` | The shared harness contract remains diagnostic. P08 independently pauses on containment defects and restarts from the pre-Play score snapshot with construction retained and no award on the aborted attempt; three synthetic `escaped_bounds` restarts passed. |
| Checks | `tilaok!/tests/` | P09 adds `run_p09_tests.gd` (77 focused checks), `run_p09_interactive.gd` (108 rendered synthetic/real-physics interaction assertions and screenshots) and `audit_p09_restarts.gd` (ten full ending/restart cycles with state snapshots, object/static-memory deltas and frame samples). P11 adds `run_p11_tests.gd` (77 deterministic checks) and `run_p11_interactive.gd` (81 rendered 2/3/4 synthetic-seat assertions, including a Last Cluck result capture); P11 logs/captures/export evidence are indexed under `docs/evidence/p11/`. P03's 103-check support suite covers real moving contact, airborne/coyote states, provenance and same-step support removal. Foundation, P02, P05–P08 and UI regression logs are indexed under `docs/evidence/p09/`; the P04 suite did not complete in its 30-second command window. Automated fixtures are engineering evidence, not human play evidence. |
| Checks | `tilaok!/tests/` | `run_foundation_tests.gd` includes repeated P03 cleanup/reload regressions; `run_p02_tests.gd` preserves P02 tests; `run_p03_tests.gd` covers route/protection/camera/support; `run_p03_interactive.gd` drives the visible GUI; `capture_p03_evidence.gd` saves rendered views and performance observations; `capture_p03_camera_jitter.gd` renders the close-chicken camera regression at 1080p; `run_p04_tests.gd` covers item definitions/validation, lifecycle, caps and real-physics Kaing/Tulay trials; `run_p04_interactive.gd` drives the Item Lab GUI; `capture_p04_evidence.gd` saves 1080p captures and the 48-piece performance sample; `run_p02_wall_tests.gd` and `capture_p02_wall_evidence.gd` cover the wall extension. |
| Chicken scene (2026-10-14) | `tilaok!/scenes/characters/chicken.tscn`, `tilaok!/scripts/movement/chicken_sprite_animator.gd`, `tilaok!/assets/character/` | `ChickenController` root + 56×120 `CollisionShape2D` (resized from tuning) + `Sprite` (`AnimatedSprite2D`, ×0.25) with 12 animations: idle, run_right/left, wall_slide_right/left, sneak, jump, jump_right/left, glide, glide_right/left. The animator picks one from the controller state each frame and applies a per-animation feet offset; edit frames in the SpriteFrames resource. `P03StageRoom._build_actor` instances it (P02 room keeps its historical code-built chicken). |
| Stage tiles (2026-10-14) | `tilaok!/scenes/stage/stage_tiles.tscn`, `tilaok!/scripts/stage/stage_tile_layer.gd`, `tilaok!/assets/tiles/`, `tilaok!/tools/make_debug_tiles.gd` | 64×64 px TileMapLayer painted from `ArenaDefinition` surfaces (visual only; per-surface collision bodies keep their support/wall metadata). The atlas is a DEBUG placeholder written by the tool script; replace the PNG, keep the 64 px tile size. |
| Stage blocks (2026-10-14) | `tilaok!/scenes/blocks/`, `tilaok!/scripts/items/solid_block.gd`, `wood_box.gd`, `collapsing_block.gd`, `stage_block_support.gd`, `tilaok!/data/items/build.solid_block.tres`, `build.wood_box.tres`, `build.collapsing_block.tres` | One editable scene per block (root body + `CollisionShape2D` + `Visual`), authored at turn 0 and centered on its footprint. To change a block's look, edit its `Visual` node; its size comes from the `.tres` footprint (tests check the scene matches). `ItemManager` places them through the same interface as `ConstructionPiece`. |
| Items | `tilaok!/scripts/items/`, `tilaok!/scenes/items/`, `tilaok!/data/items/` | `ItemFamilyDefinition`/`ItemVariantDefinition`/`ItemRegionSpec` typed resources, `ItemApprovedVariants` (documented variant table), one `ItemDefinitionValidator`, `ItemDefinitions` loader/catalog rows, `ItemPlacementValidator` (reasoned rejections), `ItemManager` (placement, Walis-hook removal, Place/Play/round/match lifecycle, 48-piece cap), `TransientBudget` (16/4/32 caps, TTLs, rotating allocation, captive-safe release), `ConstructionPiece` + `kaing_piece.tscn`/`tulay_piece.tscn`, `ItemGhost`, placeholder `ItemEggPreview` (animated egg, click to claim a variant) and `ItemLibraryEntry` (placeholder Library model with a release filter). `.tres` definitions for `build.hollow_blocks` and `build.bamboo_bridge`. Item tunables are `item_*` fields in `gameplay_tuning.gd`. |
| Item Lab | `tilaok!/scripts/harness/item_lab_room.gd`, `tilaok!/scenes/fixtures/item_lab.tscn` | No longer a placeholder: extends the P03 stage room with immediate lab-only placement, rotate/confirm, Play/Reset/Clear all, and an `--open-room=item_lab` startup hook for exported smoke tests. |
| UI shells | `tilaok!/scenes/ui/`, `tilaok!/scripts/ui/`, `tilaok!/assets/ui/`, `tilaok!/data/ui/` | Scene-authored placeholder screens, components, one project Theme, SAMPLE resources and UI Gallery remain separate from the match room. P09 binds live match results to the themed `match_result_screen.tscn`; gallery SAMPLE data remains separate. Presentation remains placeholder and final art/type, broader P13 integration and human readability remain open. |
| Future responsibilities | events, scoring extensions, presentation and remaining item families | P12 event scheduling and all stacks; Barya; Walis Cleanup; persistent saves/network systems; final UI/assets and production onboarding remain unimplemented. P11 standalone Kangaroo is implemented as a development route; its pair-only Hug and forced two-survivor Storm risk need human balance review. P09 only handles a development Karera match ending and tied-player Lagsanay sudden death. |

## Programming provenance and review

AI/LLM-assisted programming, including core gameplay generation, is the standing Tilaok! development workflow. Francis (lead developer) and Carlos (co-lead developer) direct development using these tools and retain integration, review, testing and delivery responsibility. P01–P09 and P11 implementation code was AI-generated under the standing workflow and is not represented as manually team-written. The P02 wall extension and P10 work were authored by Claude; P03–P09 and P11 work in this checkout was authored by Codex. No independent human review of P09 or P11 is claimed. See [AI_USAGE.md](AI_USAGE.md) for the current policy and cumulative disclosure, and [COMPETITION.md](COMPETITION.md) for the recorded external-rule summary and its limitations. P01-T02's actual human review remains open. The workflow does not establish organizer approval or competition eligibility; Form 03 and other submission requirements remain separate.

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

Windows export preset output is `build/tilaok-p02.exe`; generated build output is ignored by Git. For a P07 route launch or export smoke, pass `-- --open-room=p07_first_playable`; export to a separate file such as `../build/tilaok-p07.exe` to retain the baseline P02 executable. P08 launches with `-- --open-room=p08_lagsanay`; P09 launches with `-- --open-room=p09_match_lifecycle` or the **P09 Match Lifecycle** harness button.

## P05 match-loop responsibilities and commands

| Area | P05 path | Responsibility and current state |
|---|---|---|
| Match room | tilaok!/scenes/match/ and tilaok!/scripts/match/match_room.gd | P05MatchRoom inherits the P04 stage room, adds the 2–4 seat lobby, phase shell, controls, diagnostic Play and results/next-round surface. Its HUD, egg row and results panel are no longer code-built: `MatchScreenPresenter` (`scenes/match/match_hud.tscn`) binds the live P05/P06 state to the scene screens and the DEBUG overlay replaces the old diagnostic buttons and labels. P06 awards, suppression reasons and totals are shown exactly as computed. |
| Phase and lobby | tilaok!/scripts/match/match_phase_controller.gd and lobby_view_model.gd | Minimum-two/all-ready start gate, phase timers, fixed seat identity and pause-frozen Pugad/Place/Results time. |
| Eggs and claims | tilaok!/scripts/match/pugad_egg_pool_generator.gd, pugad_claim_arbiter.gd and pugad_egg_card.gd | Seeded family-weight/within-family selection from enabled variants, duplicate variant definitions allowed, one distinct egg per seat, stable earlier/same-tick/timeout arbitration. |
| Place and results | tilaok!/scripts/match/placement_controller.gd, atomic_edit_resolver.gd and match_results_view_model.gd | Pending confirmations resolve against one snapshot and batch-commit in stable seat order; results carry outcome/award/no-score/total fields without calculating awards. |
| UI gallery fixture | tilaok!/scenes/ui/, tilaok!/scripts/ui/, tilaok!/data/ui/ and tilaok!/assets/ui/theme/ | Standalone DEBUG review gallery and sample data exercise reusable screen/component shells across device glyphs and seat counts. The same scenes are bound to live data by the match presenter and `GameFlow`; the gallery keeps its SAMPLE binds. |
| Harness entry | tilaok!/scripts/harness/foundation_harness.gd and foundation_harness.tscn | P05 Match Loop opens the P05 scene; P07 First Playable, P08 Lagsanay Lab and P09 Match Lifecycle open their labeled development rooms (all on the same scene screens, DEBUG overlay on); Item Lab remains the P04 immediate-placement regression fixture. The project main scene is `scenes/flow/game_flow.tscn` (Title); the harness opens with `-- --harness` or `-- --open-room=<id>`, and **Player flow (Title)** hosts the live flow. |
| P05 checks/evidence | tilaok!/tests/run_p05_tests.gd, run_p05_interactive.gd, run_ui_tests.gd, capture_p05_evidence.gd and p05_fixtures.gd | Automated deterministic checks, visible four-seat harness loop, standalone 446-check UI gallery contract runner, test-only mover/cleanup/solid-trigger fixtures, rejection/variant captures and 48-piece performance capture. |

From the repository root:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p05_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p06_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_p05_interactive.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_p06_interactive.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p06_performance.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_ui_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p05_evidence.gd'
```

Choose **P05 Match Loop** in the harness. Join and ready two or more seats. K1 uses WASD/Space; K2 uses arrows/Ctrl. F/Enter confirms or readies, arrows select a Pugad egg, and R/Right Shift rotates supported variants. During Karera, reach the outlined flag goal; results show each outcome, award explanation, suppression reason and exact cumulative total. Results advance when all seats are ready or after eight seconds. Synthetic gamepad seats 3/4 are used in recorded checks; physical gamepads are not certified. See the [P06 verification record](evidence/p06/2026-10-14_p06_verification.md). All newly drawn UI/item visuals are DEBUG placeholders.

## P07 First Playable route

The harness **P07 First Playable** button opens `p07_first_playable_room.tscn`, the player-facing scored Karera slice. Direct launch and exported smoke use `-- --open-room=p07_first_playable`. Join two to four seats and have each seat ready. P07 only enables Kaing 1×1, Kaing Stack 2×3 and Tulay 4×1 in its Pugad pool; the runtime validator returns to Lobby if any other variant appears. It keeps the existing `karera_slice` profile ID and only changes tuning on the P07 room instance.

K1: A/D move, W/S navigate, W jumps/glides in Play, Space is the alternate jump, F joins/readies/claims/confirms, R rotates, G backs out. K2: arrows move/navigate, Up jumps/glides in Play, Ctrl is alternate jump, Enter joins/readies/claims/confirms, Right Shift rotates, Backspace backs out. Gamepad: D-pad navigates/moves, A joins/readies/claims/confirms and jumps in Play, X rotates, B backs out, Start pauses. Four-seat/reset/capture runners use synthetic gamepad identities and teleported goal contacts; no human or physical-device task is complete from those runs. See [P07 evidence](evidence/p07/README.md).

## P08 Independent Lagsanay Lab

The harness **P08 Lagsanay Lab** button opens `p08_lagsanay_room.tscn`; launch directly with `-- --open-room=p08_lagsanay`. Join K1 and K2 with the visible buttons (additional seats may use gamepads), have every joined seat ready, start the match, then follow Pugad → Place → Lagsanay. The room uses the persistent stage and the development-only `lagsanay_lab` allowlist. `A/D` (K1) and Left/Right (K2) move; `W` / Up jump or glide, `S` / Down sneak; **F / Enter** ready, claim, confirm and continue results; Escape pauses. The mode hides the Karera goal and its deadline/awards. HUD text and shape cues identify taya, head-start and bomb timer; results explain placement, Patibong and Last Cluck. Ready through results for the next round; construction and cumulative scores persist. See [P08 evidence and remaining gates](evidence/p08/README.md).

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p08_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_p08_interactive.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p08_performance.gd'
```

Focused automation is synthetic engineering evidence, not physical-device/human playtest acceptance. P08's 6/6 technical tasks pass; P07-T04 and the P08 development-only entry/release gate remain open.

## P09 Match Lifecycle route

The **P09 Match Lifecycle** harness button and `-- --open-room=p09_match_lifecycle` launch `p09_match_lifecycle_room.tscn`. This is a labeled development route using the `karera_slice` identity and the same three P07 variants. Match termination uses cumulative integer eighth-point totals: 80 units (10 points) or the end of completed round 12. Unequal leaders finish normally; tied top seats alone enter the existing Lagsanay controller, preserving their original seats and using the currently constructed stage. Its authoritative survivor/Last Cluck winner resolves one match winner without adding placement points to match totals.

The live result screen lists every original seat and exact score, names one winner, identifies ordinary or sudden-death resolution and explains Last Cluck when that rule applies. Replay derives a fresh seed from the configured base seed and next match identity while retaining seats/devices; Return to Lobby and Quit are unanimous fresh-ready actions with the shared confirmation dialog for Quit/whole-group leave. Detailed results, screenshots, scripts and measured limits are indexed in [P09 evidence](evidence/p09/README.md). P09 does not implement P12 schedules/stacks or alter release-profile validation.

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p07_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p07_reset_audit.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p07_evidence.gd'
```

## UI shell commands

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_ui_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_ui_evidence.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' 'res://scenes/ui/ui_gallery.tscn'
```

In the harness, **UI Gallery** shows every screen/state with SAMPLE data and **Player flow (Title)** starts at Title with the review panel hidden (F9 shows it). Designers edit the scenes and Theme in the Godot editor; see the how-to in [UI_HANDOFF.md](UI_HANDOFF.md).

## P10 first-batch families, Item Visualizer and commands

| Area | Path | Responsibility and current state |
|---|---|---|
| Runtime components | `tilaok!/scripts/items/runtime/` | `ItemHazardDirector` (one deterministic per-step resolver), `ItemBehavior` + `SpringBehavior`, `TrumpoBehavior`, `ParolBehavior`, `LauncherBehavior`, `BubbleBehavior`; `PathMover`, `PhaseCycle`, `LaneQuery`, `SweptContact`, `SafeReleaseResolver`, `CleanupTargetResolver`, `AttributionRecord`, `ItemSilhouettePainter`, `ItemOverlayBuilder`, `HazardPiece`, `PlaceholderAudit` |
| Data | `tilaok!/data/items/*.tres`, `data/items/visual/*.tres` | Six new family definitions and six `ItemVisualSet` resources (replaceable presentation slots) |
| Placeholder assets | `tilaok!/assets/items/<family_id>/PLACEHOLDER_*` | 23 generated SVG/WAV placeholders; replace by file name or by editing the `ItemVisualSet` slot; regenerated by `tools/generate_placeholder_assets.gd` |
| Item Visualizer | `tilaok!/scripts/harness/item_visualizer_room.gd`, `scenes/fixtures/item_visualizer.tscn` | Extends the Item Lab: family/size/rotation pickers, put-here, overlays, slow-motion, step, extra chickens, readouts, Art slots list and Reload art; opened from the harness **Item Visualizer** button or `-- --open-room=item_visualizer` |
| All-families match | `tilaok!/scripts/match/match_room_items_lab.gd`, `item_elimination_bridge.gd` | The P05/P06 match with the `items_lab` pool; hazard eliminations are handed to the race ledger |
| Profile pools | `tilaok!/scripts/items/item_enabled_profiles.gd` | Dev-only enabled-variant/weight sets; `ItemDefinitions.load_all()` still returns exactly Kaing/Tulay |
| Checks | `tilaok!/tests/run_p10_tests.gd`, `run_p10_interactive.gd`, `capture_p10_evidence.gd` | Headless physics/definition/attribution suite, harness-driven rendered session, evidence/performance/swap capture |

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p10_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_p10_interactive.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p10_evidence.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!'
```

Interactive and capture scripts write screenshots into `docs/evidence/` (override with `P10_EVIDENCE_DIR`); run them from a scratch copy if other phases' evidence must not change. In the harness choose **Item Visualizer** (every family, variant and rotation) or **P05 Match (all items)**.

## Live match UI — GameFlow, presenter and DEBUG overlay (2026-10-14)

| Area | Path | Responsibility and current state |
|---|---|---|
| Entry / flow | `tilaok!/scenes/flow/game_flow.tscn`, `scripts/flow/game_flow.gd` | Project main scene. Owns one `LocalInputRouter` (injected into the match room), the Title / Library / Settings screens and the match room's lifetime. The room it plays is `scenes/match/p07_first_playable_room.tscn` (karera_slice limited to the verified Kaing / Tulay variants); `-- --match-route=lifecycle` plays `p09_match_lifecycle_room.tscn` instead (match end, sudden death, final result). `-- --harness` or `-- --open-room=<id>` opens the developer harness instead. |
| Presenter | `tilaok!/scripts/match/match_screen_presenter.gd`, `scenes/match/match_hud.tscn` | Instanced by `P05MatchRoom`; subscribes to room, phase, pause and actor signals and calls the `bind_live*` methods of the scene screens. Text and visibility only: no scoring, no per-frame allocation. |
| Screens | `tilaok!/scenes/ui/screens/`, `scripts/ui/` | Lobby, Pugad, Place, Play HUD, Round result, Match result (P09) and Pause are live; Title / Library / Settings are bound by GameFlow. The P08 and P09 rooms drive the same screens through small presentation hooks on `P05MatchRoom`; `scenes/match/taya_world_marker.tscn` is the authored world-space taya label. |
| DEBUG overlay | `tilaok!/scenes/ui/screens/debug_overlay.tscn`, `scripts/ui/ui_debug_overlay.gd` | Developer text and fixture buttons. Off in the player flow, on when opened from the harness, F3 in debug builds. |
| Pause menu hook | `tilaok!/scripts/input/pause_recovery_coordinator.gd` | Additive `external_menu` flag (default false) and `mark_ready(seat)` so the scene pause menu's Resume entry readies the owner; P02 behaviour is unchanged by default. |
| Removed | `scripts/match/match_results_panel.gd`, the code-built HUD / egg row in `match_room.gd` | Replaced by the screens above. |
| Checks | `tilaok!/tests/run_match_ui_tests.gd`, `run_match_ui_binding_tests.gd`, `run_match_ui_mode_tests.gd`, `run_match_ui_interactive.gd`, `capture_match_ui_performance.gd` | Flow / ownership / pause / reclaim / lifecycle, view-model equality, P08 / P09 presentation, 1080p captures and the frame sample. Evidence: `docs/evidence/match-ui/`. |

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!'                       # player flow (Title)
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' -- --harness          # developer harness
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' -- --match-route=lifecycle   # player flow with the P09 match end
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_match_ui_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_match_ui_binding_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_match_ui_mode_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_match_ui_interactive.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_match_ui_performance.gd'
```

### Mode rooms on the scene UI (P08, P09 and later modes such as P11 Kangaroo)

A room that extends `P05MatchRoom` no longer builds HUD controls: `_top_bar`, `_match_buttons`, `_phase_label`, `_timer_label`, `_feedback_label`, `_hints_label`, `_info_panel`, `_egg_row`, `_results_panel`, `_match_canvas`, `_add_match_button()`, `_phase_hint()` and `MatchResultsPanel` were removed on 2026-10-14. A new mode overrides the presentation hooks and `MatchScreenPresenter` shows what they return (see `p08_lagsanay_match_room.gd` and `p09_match_lifecycle_room.gd`):

| The mode needs | Do this |
|---|---|
| A different Play clock, challenge name or goal sentence | Override `play_clock_seconds()`, `play_challenge_text()`, `play_goal_text()` |
| A tag next to the clock, a one-line HUD notice | `play_tag_text()`, `play_status_text()` (longer developer text: `debug_status_text()`) |
| A per-seat state word (TAYA, WATCHING, ...) | `seat_state_text(seat_index)` |
| Its own results | Set `last_results_model` with a `MatchResultsViewModel` builder; the Round result screen binds it when `round_number` equals the item manager's round |
| The final match result | `shows_final_results()` (the room binds `UiMatchResultScreen.bind_final_match`) |
| A developer-only button | `debug_action_label()` and `run_debug_action()` (shown in the DEBUG overlay) |
| A build id in the DEBUG overlay | `build_id()` |
| A world-space marker or a new prompt | Author a scene (`scenes/match/taya_world_marker.tscn` is the pattern; new screens live under `scenes/ui/` and are instanced from `scenes/match/match_hud.tscn`) and add `theme_type_variation`s in the scene, never `Label.new()` / `Control.new()` / `add_theme_*` in a room script |

Call `_notify_presentation(&"reason")` when something the screens show changes (not every physics step: whole-second clocks re-render by themselves). Add the new room script to `ROOM_SOURCES` in `tests/run_match_ui_mode_tests.gd` so the no-code-built-UI rule covers it.
