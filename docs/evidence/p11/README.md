# P11 Independent Kangaroo evidence

Recorded October 14, 2026 on Windows with Godot `4.7.2.stable.official.ed1daf0bf`, Intel Core i5-13420H, NVIDIA GeForce RTX 4050 Laptop GPU, Compatibility renderer. The run profile is `kangaroo_contract_lab`, seed `12345` unless the focused suite identifies a test-specific seed. Evidence was captured after upstream commit `01f8665` scene-based match UI integration and P11 commit `c1c607c`, with local P11 presenter/scoring compatibility fixes. This was a development build, not a release build. Seats, timestamps and controller events in automated checks are synthetic. No human participant, physical controller, independent review, native-speaker review or balance review was used.

## Verification results

| Evidence | Result |
|---|---|
| [`p11_unit_run.txt`](p11_unit_run.txt) | Godot 4.7.2 focused deterministic suite: **78 checks, 0 failures**. Covers seeded selection/cadence; Freeze event edges, held-input grace and external motion; Rising line/band/provenance/boundary/moving-current-contact/removal/drain; Hug deterministic pairing and live-seat filter; strict hazard timestamp ordering and missing/tied timestamps; batched markers, Last Cluck and teardown; Storm timing/cap/delay/two-survivor pair/reset. |
| [`p11_interactive_run.txt`](p11_interactive_run.txt) and [`p11_interactive_console.txt`](p11_interactive_console.txt) | **85 checks, 0 failures** on the rendered `kangaroo_contract_lab` route for 2, 3 and 4 synthetic seats. Checks the existing Pugad → Place → Play lifecycle, persistent construction, shared placement scoring/results, no race goal/deadline or Lagsanay controller, Trumpo/Launcher-only event allowlist, muted HUD, shake settings, pause/reclaim, active-clock pause and teardown. Includes a three-player simultaneous terminal fixture rendering Last Cluck in the results screen. |
| [`p11_2p_command_hud_1920x1080.png`](p11_2p_command_hud_1920x1080.png) | Project-runner 1920×1080 debug HUD capture with shake off. The visible labels and timing cues were visually inspected; this is not a player-comprehension study, nor an exported-build screenshot. |
| [`p11_last_cluck_results_1920x1080.png`](p11_last_cluck_results_1920x1080.png) | Rendered three-player simultaneous Last Cluck result with the stable lowest-slot tie explanation; synthetic outcome fixture, not a human-play result. |
| [`p11_regression_matrix.txt`](p11_regression_matrix.txt) | Current rebased-tree regressions: P02 **83**, P03 **103**, P08 **86**, P09 **77**, and P10 **430 checks**; all 0 failures on Godot 4.7.2. |
| [`p11_match_ui_regressions.txt`](p11_match_ui_regressions.txt) | Scene-based UI regressions after the upstream room migration: match UI **198**, binding **185**, mode **62**, and general UI **447 checks**; all 0 failures. |
| [`p11_os_memory_sample.txt`](p11_os_memory_sample.txt) | Windows process sample during the rendered synthetic route: peak working set **306.7 MiB**, private bytes **420.5 MiB**, sampled every 100 ms over 14 seconds. Under the provisional 512 MiB private-memory ceiling for this local Debug sample only; not release-PC acceptance. |
| [`p11_editor_import.txt`](p11_editor_import.txt) | Godot 4.7.2 headless editor import and global class registration exited 0 without parser/import errors. |
| [`p11_windows_export.txt`](p11_windows_export.txt) and [`p11_windows_export_smoke.txt`](p11_windows_export_smoke.txt) | Windows Desktop Debug export using installed 4.7.2 templates succeeded. Exported executable started the selected route headlessly and reported `P11_KANGAROO_READY`, exit 0. This checks exported startup only, not exported interactive input or visual readability. |

Reproduce from the repository root with the explicit Godot 4.7.2 executable:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p11_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_p11_interactive.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p03_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --editor --quit
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --export-debug 'Windows Desktop' '../build/tilaok-p11.exe'
& '.\build\tilaok-p11.exe' --headless --quit-after 5 -- --open-room=kangaroo_contract_lab
```

The harness route is also available from the main project window or by opening `tilaok!` with `-- --open-room=kangaroo_contract_lab`. It uses the current match lifecycle and construction persistence, with race goals and race deadlines inactive and no `LagsanayRoundController`.

## Timing and memory observations

The interactive runner records 120 local debug samples at each seat count while showing the standalone route. Values are raw local observations from this run, not target-PC acceptance or a stable benchmark:

| Synthetic seats | Process p50 / p95 / max (ms) | Physics p95 / max (ms) | Godot static memory (MiB) |
|---:|---:|---:|---:|
| 2 | 96.397 / 96.397 / 96.397 | 173.369 / 173.369 | 110.4 |
| 3 | 236.831 / 236.831 / 236.831 | 27.418 / 27.418 | 110.6 |
| 4 | 292.063 / 292.063 / 292.063 | 10.023 / 10.023 | 111.0 |

The observed process p95 values exceed the provisional 16.67 ms 1080p target. Mark P11 performance as **not met / requires profiling**; this short debug sample is noisy and physics p95/max are also high. Godot static memory is 110.4–111.0 MiB. The 100 ms Windows process sample measured peak working set/private bytes of 306.7/420.5 MiB over 14 seconds, below the provisional 512 MiB private-memory ceiling for this local Debug run only. No actual-device or exported-render performance claim is made. Use `docs/PLAYTEST.md` and P15 to track the remaining measurement.

## Human/team handoff still open

- A player/novice must assess whether command cues are understood with muted audio and full/reduced/off shake. This suite checks visible indicators, not comprehension.
- Exercise actual controller input, disconnect/reconnect and local multi-person pause/reclaim.
- Review Freeze grace, Rising solvability/provenance explanations, pair-only Hug, two-survivor forced Storm overlap, slot/tie bias and overall balance.
- Obtain native-speaker/cultural review and replace every labeled DEBUG pose/timing/audio placeholder with human-made or properly licensed production assets.
- Test the exported Windows build interactively on the target PC, sample process memory, and profile performance before release.

No network, R2/R3 contact alternatives, unrelated hazard activation, final production art/audio, or release enablement is included in this evidence.
