# NLB-P05 Offline Live-Build Evidence

**Date:** 2026-10-20 final verification (implementation and initial captures began 2026-10-19) · **Base revision:** `808ababc3f2fe705351d6f91f27a8ac973b53884` plus the P05 changes recorded in this checkout · **Machine:** Windows 11 PC, 13th Gen Intel Core i5-13420H, NVIDIA GeForce RTX 4050 Laptop GPU · **Engine:** Godot `4.7.2.stable.official.ed1daf0bf` · **Renderer:** Compatibility / OpenGL 3.3 · **Profile:** `nlb_p05_live_build` · **Seed:** 73 in focused tests and route fixtures; the live Lagsanay capture log prints its resolved Pugad stream seed · **Input:** synthetic keyboard seats K1–K4 and scripted state changes · **Reviewer:** Codex engineering self-review; no independent human review.

This record covers the offline opt-in `--match-route=offline_live_build` route. It does not claim network, Android, physical gamepad, human play, independent review, release readiness, or P07-wide content certification. No production art/audio was generated. The scheduled P12 route remains default and fallback.

The route's current verified content allowlist and disabled-cell handling are recorded in the [P05 content manifest](content-manifest.md).

## Verification status

| Check | Result | Evidence / limit |
|---|---|---|
| Godot editor import and script/class scan | PASSED | [`godot-import-final.log`](godot-import-final.log), project root `tilaok!` |
| `gdlint` changed implementation and test scripts | PASSED | [`gdlint-final.log`](gdlint-final.log), 15 scripts |
| `gdformat --check` changed implementation and test scripts | PASSED | [`gdformat-final.log`](gdformat-final.log), 15 scripts unchanged by formatter |
| `git diff --check` | PASSED | [`git-diff-check-final.log`](git-diff-check-final.log); only Git line-ending normalization notices |
| Desktop checkout startup smoke | PASSED | Both scheduled default and `offline_live_build` command lines started the Title scene and logged the expected `route=` identity; [default log](desktop-smoke-default.log), [live log](desktop-smoke-live.log). The run also logged existing map resource UID fallback warnings; text-path loading continued. |
| Focused live-build P05 suite | PASSED | 49 checks, 0 failures; [`run_nlb_p05_tests.gd.log`](run_nlb_p05_tests.gd.log) |
| P05 content allowlist and live Barya path | PASSED | The live room deals only the three allowlisted construction variants plus P12's conditional Barya objective; the focused suite checks egg-pool filtering and that live Barya does not count as construction. See [content manifest](content-manifest.md). |
| Actor and mover hold with grace restart | PASSED | Actual chicken collision rectangles and a dynamic mover's live collision shape plus bounded sweep keep the new item inactive during overlap; after each path clears it restarts a full one-second grace. Covered in the focused suite. |
| NLB-P01 suite | PASSED | 65 checks, 0 failures; [`run_nlb_p01_tests.gd.log`](run_nlb_p01_tests.gd.log) |
| P05 / P06 / P08 / P09 / P11 / P12 suites | PASSED | 137 / 102 / 86 / 77 / 78 / 61 checks; raw logs below |
| P12 pair / stack suites | PASSED | 285 / 47 checks; raw logs below |
| Controls, item integration, explosives, Barya | PASSED | 13 / 83 / 23 / 72 checks; raw logs below |
| Match UI and mode/binding suites | PASSED | 196 / 62 / 177 checks; raw logs below |
| Rendered route captures | PASSED | Ten synthetic 1920×1080 captures below: fallback Pugad/Place/Play, live Pugad/GO/preview/accepted+grace/rejected/round close, and Lagsanay integration. The final windowed [`capture-run.log`](capture-run.log) records ten successful saves and zero errors. Initial headless/typed-array capture failures are preserved in [`capture-initial-failure.log`](capture-initial-failure.log), [`capture-headless-render-failure.log`](capture-headless-render-failure.log), and [`capture-initial-run.log`](capture-initial-run.log); the harness was fixed before the final captures. |
| Synthetic 2-, 3-, and 4-seat route setup | PASSED | Focused route suite confirms one unique assigned item per seat, one cursor per seat, and entry into GO with 2, 3, and 4 keyboard seats. No rendered 3/4-seat captures were made. |
| Pugad timeout and impossible assignment path | PASSED | Timeout deterministically assigned distinct remaining eggs before GO; an empty egg pool returned to Lobby with an explanation and did not start GO. See the focused test log. |
| Ten synthetic live start/play/reset cycles with state and memory ledger | PASSED | [`audit_nlb_p05_resets.gd.log`](audit_nlb_p05_resets.gd.log): 10/10 cycles, zero failures, two synthetic keyboard seats. Every reset returned to Lobby with zero live items, activation clocks, pending/deduplicated requests, inventory use or build-mode state; seat ownership remained intact. Recorded Godot static-memory readings ranged from 157.1 to 158.9 MiB, peak 158.9 MiB; post-reset scene counts returned to 2,181 nodes / 5,995 objects. This does not cover full results/replay loops or an OS process-memory reading. |
| Full results/replay cycles and baseline-versus-live performance under recorded load | COULD-NOT-RUN | Replay behavior and comparable frame/resource samples were not run. 16.67 ms frame interval, 512 MiB process memory and 0 B/s offline gameplay traffic remain targets, not passes. |
| Baseline versus opt-in performance under a recorded live load | COULD-NOT-RUN | No comparable frame/memory sample was run. 16.67 ms frame interval, 512 MiB process memory, and 0 B/s offline gameplay traffic remain targets, not passes. |
| Physical gamepad, human play, and independent review | COULD-NOT-RUN | No such session occurred; no claims are made. |

NLB-P05-T01 passed and is checked. T02 and T03 remain unchecked because their full safety, compatibility, replay, and performance evidence is incomplete. The tracker counts 10/36 checked overall; two P05 task results are COULD-NOT-RUN (plus one partial P02 result).

## Regression commands and results

All Godot suites used the Windows Godot 4.7.2 executable, `--headless --fixed-fps 60`, project root `tilaok!`, and synthetic fixtures. Each raw stdout log is stored beside this report.

The item/mode integration log has one trailing space removed from a printed empty mode-table row so the evidence patch passes `git diff --check`; its test output and result line are otherwise unchanged.

| Suite | Checks | Raw log |
|---|---:|---|
| NLB-P01 | 65 | [`run_nlb_p01_tests.gd.log`](run_nlb_p01_tests.gd.log) |
| NLB-P05 focused | 49 | [`run_nlb_p05_tests.gd.log`](run_nlb_p05_tests.gd.log) |
| Controls | 13 | [`run_controls_tests.gd.log`](run_controls_tests.gd.log) |
| P05 | 137 | [`run_p05_tests.gd.log`](run_p05_tests.gd.log) |
| P06 | 102 | [`run_p06_tests.gd.log`](run_p06_tests.gd.log) |
| P08 | 86 | [`run_p08_tests.gd.log`](run_p08_tests.gd.log) |
| P09 | 77 | [`run_p09_tests.gd.log`](run_p09_tests.gd.log) |
| P11 | 78 | [`run_p11_tests.gd.log`](run_p11_tests.gd.log) |
| P12 | 61 | [`run_p12_tests.gd.log`](run_p12_tests.gd.log) |
| P12 pairs | 285 | [`run_p12_pairs_tests.gd.log`](run_p12_pairs_tests.gd.log) |
| P12 stacks | 47 | [`run_p12_stack_tests.gd.log`](run_p12_stack_tests.gd.log) |
| Item/mode integration | 83 | [`run_item_mode_integration_tests.gd.log`](run_item_mode_integration_tests.gd.log) |
| Explosives | 23 | [`run_explosives_tests.gd.log`](run_explosives_tests.gd.log) |
| Barya | 72 | [`run_barya_tests.gd.log`](run_barya_tests.gd.log) |
| Match UI | 196 | [`run_match_ui_tests.gd.log`](run_match_ui_tests.gd.log) |
| Match UI modes | 62 | [`run_match_ui_mode_tests.gd.log`](run_match_ui_mode_tests.gd.log) |
| Match UI bindings | 177 | [`run_match_ui_binding_tests.gd.log`](run_match_ui_binding_tests.gd.log) |

## Rendered captures

These screenshots use synthetic input/state fixtures and are not human readability or device-acceptance results.

| Capture | Scenario |
|---|---|
| [`01-fallback-pugad.png`](captures/01-fallback-pugad.png) | Default scheduled route, Pugad |
| [`02-fallback-place.png`](captures/02-fallback-place.png) | Default scheduled route, Place |
| [`03-fallback-play.png`](captures/03-fallback-play.png) | Default scheduled route, Play |
| [`04-live-pugad.png`](captures/04-live-pugad.png) | Live route, assignment window |
| [`05-live-go.png`](captures/05-live-go.png) | Shared GO countdown |
| [`06-live-build-preview.png`](captures/06-live-build-preview.png) | Build mode and off-screen numbered/shape indicators |
| [`07-live-placement-accepted-and-grace.png`](captures/07-live-placement-accepted-and-grace.png) | Accepted build with its activation grace notice |
| [`08-live-placement-rejected.png`](captures/08-live-placement-rejected.png) | Rejected placement response |
| [`09-live-round-close-cleanup.png`](captures/09-live-round-close-cleanup.png) | Results/round close and reset audit |
| [`10-live-lagsanay-event.png`](captures/10-live-lagsanay-event.png) | Lagsanay schedule integration |

## Reproduction

From the repository root, the default scheduled route is:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!'
```

The opt-in offline live-build route is:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' -- --match-route=offline_live_build
```

The capture harness is `tilaok!/tests/capture_nlb_p05_routes.gd`; the focused regression is `tilaok!/tests/run_nlb_p05_tests.gd`.
