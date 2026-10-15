# Karera all-finish Barya correction — 2026-10-15

The owner clarified the rule after the [intermediate all-finish zero change](2026-10-15_all_finish_zero.md): in a 2-, 3- or 4-player Karera where everyone reaches the flag, ordinary race awards are suppressed, but a player who carries Barya across the flag still earns its +0.5 (four eighth-point units). Without Barya, everyone earns zero round points. A no-finisher round awards zero. Previously earned totals are retained. Barya gameplay is not yet enabled; these are calculator test facts.

## Actual verification

Godot `D:\Downloads\Godot_v4.7.2-stable_win64_console.exe` (4.7.2) on Windows, using headless synthetic tests:

| Check | Result |
|---|---|
| Godot editor import/parse | Exit 0; no parse errors |
| `run_p06_tests.gd` | 102 checks, 0 failures; 2/3/4-player all-finish Barya, zero ordinary awards, prior totals, partial finish and no finish |
| `run_p13_library_tests.gd` | 355 checks, 0 failures; all-finish Barya explanation |
| `run_tutorial_tests.gd` | 142 checks, 0 failures |
| `run_match_ui_binding_tests.gd` | 177 checks, 0 failures |
| `run_p12_stack_tests.gd` | 47 checks, 0 failures |
| `gdformat --check`, `gdlint`, `git diff --check` | Passed for changed scripts/diff |

No rendered screenshot, physical-device test, human review or player session was performed for this correction. The earlier P06 screenshot shows the superseded two-player waiver.
