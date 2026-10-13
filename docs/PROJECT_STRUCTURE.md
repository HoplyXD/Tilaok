# Project structure and responsibility map

P01 foundation plus P02 input/movement diagnostic layout for Godot 4.7. The main scene opens a local development harness; the P02 fixture is playable and exercises input, movement, pause/reclaim and containment contracts. It does not implement the complete lobby-to-match loop, scoring engine, production stage, or full Lagsanay/Kangaroo rules.

| Area | P01 path | Responsibility and current state |
|---|---|---|
| Project entry | `tilaok!/project.godot`, `tilaok!/scenes/harness/` | Starts the foundation harness; its P02 button opens the playable movement/input diagnostic fixture. |
| Configuration | `tilaok!/scripts/config/` | Typed provisional tuning, presentation settings, immutable-at-run-start snapshots, and seven labeled profiles. P02 movement/input constants are centralized in `gameplay_tuning.gd`; snapshots are used by the fixture. |
| Content diagnostics | `tilaok!/scripts/diagnostics/` | Catalog validation, verified-content eligibility, normalized weights, and independent seeded diagnostic RNG streams. No gameplay content is enabled. |
| Harness | `tilaok!/scripts/harness/`, `tilaok!/scenes/harness/` | Local profile/seed identity, validation, fixture open/close, scenario reset, full harness reload, exit, and paused presentation configuration. Diagnostics do not enter a player HUD. |
| Fixture rooms | `tilaok!/scenes/fixtures/`, `tilaok!/scripts/harness/p02_movement_room.gd` | `p02_movement_room.tscn` provides four diagnostic chickens, visible bounds and platforms, phase selector, opt-in keyboard, run/jump and force probes, timer/focus/pause probes, and recovery controls. Other movement/item/event rooms remain placeholders. Fixture contracts do not implement complete game modes. |
| Input and seats | `tilaok!/scripts/input/` | Device-to-seat registry, permanent identity markers, phase-specific input routing, edge/repeat gating, pause/reconnect and all-ready resume coordination. Physical keyboard/controller coverage is still open. |
| Movement and lifecycle | `tilaok!/scripts/movement/` | Typed run/jump controller, separate body/contact sensor, intentional-input reporting, external force, terminal/capture/opening-freeze precedence and bounds event. |
| Recovery contract | `tilaok!/scripts/harness/containment_recovery_contract.gd` | Narrow Race/Lagsanay/Kangaroo diagnostic outcome and pre-round snapshot contract; not the production score/restart system. |
| Checks | `tilaok!/tests/` | `run_foundation_tests.gd` preserves P01 regression checks; `run_p02_tests.gd` runs focused synthetic input and Godot physics assertions; `capture_p02_room.gd` creates the rendered image and performance sample. |
| Future responsibilities | `scripts/match`, `stage`, `items`, `events`, `scoring`, `presentation` | Required product systems remain unimplemented; P02 fixtures do not imply their completion. |

## Authorship and review

At the user's explicit direction, OpenAI Codex authored the P01 foundation and the P02 input, controller, sensor, pause/reconnect, diagnostic recovery scripts/scenes and focused tests. This is an explicit AI-implementation exception to the repository's team-authored-code acceptance wording, scoped to P01 and P02 implementation/tests. Codex-authored work is not labeled team-authored; a user exception does not establish DOST eligibility or organizer acceptance. P01-T02 registered-team authorship review remains open. The team must disclose this assistance on DOST Form 03.

## Running the foundation

From the repository root, use the explicit Godot 4.7.2 executable recorded in `docs/PRODUCTION.md`:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --editor
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_foundation_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p02_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p02_room.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --export-debug 'Windows Desktop' '../build/tilaok-p02.exe'
```

The first command launches the local harness. Choose **P02 Movement Room** to play with the movement/input diagnostic fixture; enable shared keyboard explicitly to join K1/K2.

The P02 test command uses synthetic keyboard/gamepad events plus real Godot physics, timers and scene lifecycle. Synthetic events are not physical-device evidence. Physical controller/reconnect and keyboard rollover procedures remain open in [PLAYTEST](PLAYTEST.md).

Windows export preset output is `build/tilaok-p02.exe`; generated build output is ignored by Git.
