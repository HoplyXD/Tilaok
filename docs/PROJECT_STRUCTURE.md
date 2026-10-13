# Project structure and responsibility map

P01 foundation plus P02 input/movement and P03 graybox stage/camera/support diagnostic slices for Godot 4.7. The main scene opens a local development harness; choose P03 Graybox Arena for the bounded playable course. P03 reuses the P02 controller, input routing, identity and pause systems. The project still does not implement the complete lobby-to-match loop, atomic placement, scoring engine, production items, or full Lagsanay/Kangaroo rules.

| Area | P01 path | Responsibility and current state |
|---|---|---|
| Project entry | `tilaok!/project.godot`, `tilaok!/scenes/harness/` | Starts the foundation harness; its P02 button opens the playable movement/input diagnostic fixture. |
| Configuration | `tilaok!/scripts/config/` | Typed provisional tuning, presentation settings, immutable-at-run-start snapshots, and seven labeled profiles. P02 movement/input constants are centralized in `gameplay_tuning.gd`; snapshots are used by the fixture. |
| Content diagnostics | `tilaok!/scripts/diagnostics/` | Catalog validation, verified-content eligibility, normalized weights, and independent seeded diagnostic RNG streams. No gameplay content is enabled. |
| Harness | `tilaok!/scripts/harness/`, `tilaok!/scenes/harness/` | Local profile/seed identity, validation, fixture open/close, scenario reset, full harness reload, exit, and paused presentation configuration. Diagnostics do not enter a player HUD. |
| Fixture rooms | `tilaok!/scenes/fixtures/`, `tilaok!/scripts/harness/p02_movement_room.gd`, `tilaok!/scripts/harness/p03_stage_room.gd` | P02 retains its four-seat movement/input probes. `p03_stage_room.tscn` builds the 32-unit-grid, 1024×512-wu arena with labeled protection/bounds, live diagnostic actors, Play/Place camera targets, pointers and support-contact indicators. These are fixtures, not complete game modes or production UI. |
| Input and seats | `tilaok!/scripts/input/` | Device-to-seat registry, permanent identity markers, phase-specific input routing, edge/repeat gating, pause/reconnect and all-ready resume coordination. Physical keyboard/controller coverage is still open. |
| Movement and lifecycle | `tilaok!/scripts/movement/` | Current code provides the typed run/jump controller, separate body/contact sensor, intentional-input reporting, external force, terminal/capture/opening-freeze precedence and bounds event. `wall_contact_probe.gd` plus controller hooks implement the approved Should wall slide/jump (disabled by default, unverified; P02-T15–T22). |
| Arena and support | `tilaok!/scripts/stage/` | `ArenaDefinition` owns tile-edge geometry, protected zones, immutable signatures and narrow edit/removal guards. `SupportSurfaceMetadata`, `SupportContact` and `SupportTracker` require explicit provenance/eligibility and actual current upward collision contact. No item placement, demolition or Kangaroo event scheduler is implemented. |
| Camera | `tilaok!/scripts/camera/` | `BoundedStageCamera` fits actual Play actor or unconfirmed Place extents inside the HUD-safe viewport, clamps to world bounds, and uses fast zoom-out/safe inward easing. HUD compensation is applied once during target fitting, not again during easing. `StageCameraTarget` identifies cached target rectangles. |
| Recovery contract | `tilaok!/scripts/harness/containment_recovery_contract.gd` | Narrow Race/Lagsanay/Kangaroo diagnostic outcome and pre-round snapshot contract; not the production score/restart system. |
| Checks | `tilaok!/tests/` | `run_foundation_tests.gd` includes repeated P03 cleanup/reload regressions; `run_p02_tests.gd` preserves P02 tests; `run_p03_tests.gd` covers route/protection/camera/support; `run_p03_interactive.gd` drives the visible GUI; `capture_p03_evidence.gd` saves rendered views and performance observations; `capture_p03_camera_jitter.gd` renders the close-chicken camera regression at 1080p; `run_p02_wall_tests.gd` and `capture_p02_wall_evidence.gd` cover the wall extension (unexecuted). |
| Future responsibilities | `scripts/match`, `items`, `events`, `scoring`, `presentation` | Full game flow, atomic placement/cleanup, item implementations, events/scoring and production UI/assets remain unimplemented. P03 contracts are foundations only. |

## Programming provenance and review

AI/LLM-assisted programming, including core gameplay generation, is the standing Tilaok! development workflow. Francis (lead developer) and Carlos (co-lead developer) direct development using these tools and retain integration, review, testing and delivery responsibility. P01 and P02 code was AI-generated; it is not represented as manually team-written. See [AI_USAGE.md](AI_USAGE.md) for the current policy and cumulative disclosure, and [COMPETITION.md](COMPETITION.md) for the recorded external-rule summary and its limitations. P01-T02's actual human review remains open. The workflow does not establish organizer approval or competition eligibility; Form 03 and other submission requirements remain separate.

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
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p03_camera_jitter.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p02_room.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --export-debug 'Windows Desktop' '../build/tilaok-p02.exe'
```

The first command launches the local harness. Choose **P03 Graybox Arena** for the bounded course; its visible join controls add K1/K2 and its HUD switches the diagnostic Play/Place views. K1 uses A/D + Space; K2 uses arrows + Enter. Choose **P02 Movement Room** for the original input/movement probes; shared keyboard remains an explicit P02 option.

The P02/P03 test commands use synthetic inputs plus real Godot physics, timers and scene lifecycle. The P03 route is actual collision traversal; camera actor/preview rectangles are labeled synthetic fixtures. Synthetic events are not physical-device evidence. Physical controller/reconnect and keyboard rollover procedures remain open in [PLAYTEST](PLAYTEST.md). Current P03 screenshots, tests and Windows export/startup evidence are indexed in `docs/evidence/p03/2026-10-13_p03_verification.md`.

Windows export preset output is `build/tilaok-p02.exe`; generated build output is ignored by Git.
