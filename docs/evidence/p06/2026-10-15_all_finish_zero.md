# Karera all-finish zero-point update — 2026-10-15

The owner changed Karera's all-finish rule: when all joined players reach the flag, every player earns zero **round** points in 2-, 3- and 4-player matches. No award row is committed, including Tapos, Una and test-only Barya. Previously earned cumulative totals remain unchanged. No-finisher rounds remain zero. If some but not all players finish, the existing ordinary awards still apply. Lagsanay and Kangaroo placement scoring is unchanged.

## Verification

Run with `D:\Downloads\Godot_v4.7.2-stable_win64_console.exe` against the `tilaok!` project on Windows. The script suites used headless Godot and synthetic events/input. They do not establish physical-controller, human readability or playtest results.

| Check | Actual result |
|---|---|
| Godot 4.7.2 headless editor import | Exit 0; no parse errors |
| `run_p06_tests.gd` | 102 checks, 0 failures; includes 2/3/4-player all-finish zero, coin suppression, retained prior totals, partial-finish coin payout and live two-player goal result |
| `run_tutorial_tests.gd` | 142 checks, 0 failures; includes two-player all-finish result copy |
| `run_match_ui_tests.gd` | 190 checks, 0 failures |
| `run_match_ui_binding_tests.gd` | 177 checks, 0 failures |
| `run_p13_library_tests.gd` | 355 checks, 0 failures; includes the revised two-player/Barya explanation |
| `run_p05_tests.gd` | 137 checks, 0 failures |
| `run_p09_tests.gd` | 77 checks, 0 failures |
| `run_p12_tests.gd` | 61 checks, 0 failures; the deliberate unavailable-mode refusal logs an error as part of its passing scenario |
| `run_p12_stack_tests.gd` | 47 checks, 0 failures |
| `run_p13_tutorial_tests.gd` | 55 checks, 0 failures |

The older P06 interactive screenshot and report show the superseded two-player waiver. This update did not produce a new rendered screenshot. No human code review is claimed.
