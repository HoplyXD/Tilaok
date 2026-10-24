# P25 Tutorial Revamp Evidence

**Run date:** 2026-10-25 (Asia/Manila)
**Working revision:** `2e887d4f900eb590f4d9439aae01a931345f0a4b` on `main`; no commit created.
**Engine:** installed `C:\Users\roman\Downloads\Godot_v4.6.3-stable_win64_console.exe`, Godot 4.6.3.stable.official.7d41c59c4.
**Input:** synthetic keyboard seats only; no physical keyboard/controller or human session.
**Profile/seed:** the P13 scripted harness uses its own lifecycle fixture and generated seeds; no fixed seed/profile override was supplied. The P13 Library harness reports `profile=karera_slice`, seed `12345`. The P12 regression uses seed `12345` plus its deterministic schedule table. The offline live-build test uses its fixture seeds. These are engineering checks, not rendered playtests.

## Results

| Command | Result | Scope / limit |
|---|---|---|
| `& 'C:\Users\roman\Downloads\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'tilaok!' --editor --quit` | **PASSED**, exit 0 | Headless import/editor initialization. No visible app. |
| `... --script res://tests/run_p13_tutorial_tests.gd` | **PASSED**, 72 checks, 0 failures | Copy, scheduled-route prompt rules, skip/replay, Barya cue, mixed-seat glyph behavior, per-seat lesson memory at 2/3/4 seat counts. Synthetic input; does not traverse a complete active BUILD match. A Forward+ volumetric fog warning appears in headless compatibility rendering. |
| `... --script res://tests/run_p13_library_tests.gd` | **PASSED**, 425 checks, 0 failures | Library data/navigation/keyboard/gamepad fixture checks. |
| `... --script res://tests/run_p12_tests.gd` | **PASSED**, 59 checks, 0 failures | Current schedule/mode integration and reset coverage. |
| `... --script res://tests/run_offline_live_build_tests.gd` | **PASSED**, 123 checks, 0 failures | Shared BUILD and live item mechanics; regression only, not tutorial integration. |
| `... --script res://tests/run_ui_theme_tests.gd` | **FAILED**, 274 checks, 5 failures | Current Library text/art assertion was updated and now passes; five unrelated existing score-chip/end-results/title-layout geometry assertions still fail. |
| `gdformat --check` on changed GDScript and `gdlint` on coordinator/session/script/prompt and changed tutorial tests | **PASSED** | Named files only. |
| `... --script res://tests/run_tutorial_tests.gd` | **FAILED**, 134 checks, 21 failures | Legacy P05 Place/tutorial route still asserts Place timing, BUILD HERE, old copy, and old guided-stage completion; this is not a pass for the new normal flow. |
| `... --script res://tests/run_tutorial_gate_tests.gd -- --quick` | **PARTIAL: 33 checks, 0 assertion failures; shutdown warnings** | Default geometry, tutorial map contract/art, real-controller base route, and stale map-copy check pass. Quick mode intentionally skips no-build and placement-solution searches. Godot reported ObjectDB/resource/RID leaks at shutdown; treat lifecycle verification as open. |
| `... --fixed-fps 60 --script res://tests/run_tutorial_gate_tests.gd` | **COULD-NOT-RUN** | Updated full search reached `NO_BUILD_PROGRESS arena.floor attempts=0` and produced no progress for about 75 seconds; interrupted. No conclusion about current movement solvability is claimed. |

No dedicated runtime suite yet drives per-seat movement observation and both inventory paths through full normal BUILD/PLAY rounds. No ten-cycle coordinator cleanup audit, all-map handoff exercise, rendered capture, performance sample, real first-time-player session, or physical-device matrix was run. The provisional 60 FPS / 16.67 ms and 512 MiB budgets were not measured. See P25-T01/T03/T05/T06 in `docs/PHASETASK.md`; they remain unchecked where acceptance is incomplete.

Commands ran from the repository root in PowerShell. The engine command prefix is:

```powershell
$godot = 'C:\Users\roman\Downloads\Godot_v4.6.3-stable_win64_console.exe'
$godot --headless --path 'tilaok!' --editor --quit
$godot --headless --path 'tilaok!' --script res://tests/run_p13_tutorial_tests.gd
$godot --headless --path 'tilaok!' --script res://tests/run_p13_library_tests.gd
$godot --headless --path 'tilaok!' --script res://tests/run_p12_tests.gd
$godot --headless --path 'tilaok!' --script res://tests/run_offline_live_build_tests.gd
$godot --headless --path 'tilaok!' --script res://tests/run_tutorial_tests.gd
$godot --headless --path 'tilaok!' --script res://tests/run_tutorial_gate_tests.gd -- --quick
$godot --headless --fixed-fps 60 --path 'tilaok!' --script res://tests/run_tutorial_gate_tests.gd
gdformat --check tilaok!/scripts/tutorial/tutorial_coordinator.gd tilaok!/scripts/tutorial/tutorial_session.gd tilaok!/scripts/tutorial/tutorial_script.gd tilaok!/scripts/ui/ui_tutorial_prompt.gd tilaok!/scripts/ui/ui_library_step_card.gd tilaok!/tests/run_p13_tutorial_tests.gd tilaok!/tests/run_p13_library_tests.gd tilaok!/tests/run_tutorial_tests.gd
gdlint tilaok!/scripts/tutorial/tutorial_coordinator.gd tilaok!/scripts/tutorial/tutorial_session.gd tilaok!/scripts/tutorial/tutorial_script.gd tilaok!/scripts/ui/ui_tutorial_prompt.gd tilaok!/scripts/ui/ui_library_step_card.gd tilaok!/tests/run_p13_tutorial_tests.gd tilaok!/tests/run_p13_library_tests.gd tilaok!/tests/run_tutorial_tests.gd
```
