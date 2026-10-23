# P20 — Offline live-build verification

**Date:** 2026-10-22. **Source revision before task changes:** `c97f94ea5b30b5be7b5edb8665e6021fb30eb074`. **Engine:** Godot `4.7.2.stable.official.ed1daf0bf`. The game executable was not launched, and no physical-controller or human-play evidence is claimed.

**Later owner decision (2026-10-23):** the owner requested that the eight spring, Parol, launcher and cannon variants named below be restored to normal live-build offers and construction despite the failures/incomplete audit recorded in this report. The historical results below remain unchanged; this later re-enablement has not been verified and is not full-pool acceptance.

## Results

| Check | Status | Result |
|---|---|---|
| Godot editor import and parse | PASSED | Headless editor import completed with no script or resource errors. Log: [import-parse.log](import-parse.log). |
| Offline construction route | PASSED | 57 synthetic checks, 0 failures: normal route selection; local 2/3/4-seat Pugad and shared GO; visible job, exact fixed-step deadline, pause, duplicate/overlap handling, cancellation, actor recheck, Barya delay, and cleanup. Log: [offline-live-build-tests.log](offline-live-build-tests.log). |
| Reset/restart lifecycle | PASSED | Ten synthetic cleanup cycles, 0 failures; two synthetic keyboard seats. Log: [ten-cycle-audit.log](ten-cycle-audit.log). |
| Existing regressions | PARTIAL | P12 61/0 ([log](p12-tests.log)); P12 pairs 285/0; P12 stack 47/0; Barya 72/0; controls 13/0; Match UI 196/0; P09 77/0; UI 501/0; item-mode integration 83/0; P13 tutorial 58/0 ([log](tutorial-tests.log)). The 220-assertion UI theme runner reports 0 failed assertions but also emits a missing `Card/Art_Emblem` node error from its existing title-art check. |
| P10 item suite | FAILED, fail-closed | 435 checks, 4 failures: T03 expected at least two spring launches after 40 held-contact frames but observed one; T20 expected the covered Parol beam to total 128 wu but observed 384 wu; T30 reported the projectile crossed the solid cover and the lane still showed 384/384 wu. |
| Live-build content gate | PASSED | Every enabled catalog variant is either covered by the live-build behavior allowlist or explicitly fail-closed. Eight variants are withheld from the live egg pool: `move.tire_spring.tire_2x2`; `hazard.parol_pulse.span_3x1` through `span_6x1`; `hazard.slipper_launcher.lane_4x1` and `lane_6x1`; and `block.cannon.main`. Reasons are shown to the player if a blocked item is submitted. Barya remains on its separately audited Karera objective path. This is not full-pool acceptance. |
| Named-file lint and format | FAILED | Changed GDScript lint found four existing style findings in `tests/run_ui_theme_tests.gd` (two long lines, file length over the configured limit, and a repeated title-scene load). `gdformat --check` also reports that same legacy test file would be reformatted. Other changed GDScript files pass these checks. |
| Diff whitespace | PASSED | `git diff --check HEAD` returned no whitespace errors. |
| Active runtime inventory | PASSED | No retired network, phone, LAN, Android or QR classes/references remain in active project/runtime sources. |
| Markdown local links | PASSED | 107 Markdown files checked; 0 missing local file targets. |
| Headless route captures | COULD NOT RUN | The route-capture harness reached all ten requested scenes, but this headless renderer returned no viewport images (`Parameter "t" is null`); no screenshots were produced. Log: [capture-run.log](capture-run.log). |
| Physical-controller and human play | COULD NOT RUN | Not performed. Use the manual check below on a later safe session. |
| Performance / gameplay-network traffic | NOT MEASURED | No FPS, memory or traffic measurement was taken; no performance claim is made. |

## Windows export

- **Status:** PASSED; exported but not launched.
- **Engine:** Godot `4.7.2.stable.official.ed1daf0bf`.
- **Source revision before task changes:** `c97f94ea5b30b5be7b5edb8665e6021fb30eb074`.
- **Path:** `build/tilaok-offline-live-build-20261022-r3.exe` with companion `build/tilaok-offline-live-build-20261022-r3.pck` (new ignored path; earlier task exports were preserved).
- **SHA-256:** `39C7BC5E257083B14A195B72FE656DE51608E9E2F0287C83FBCED10411738C0B`.
- **Executable size:** 103,076,864 bytes. **PCK size:** 5,805,044 bytes.
- **PCK SHA-256:** `F49EA3E78F7F61B6BEE3AEE1CA05CA1F8A21C713C9E371532838EC6088122C2B`.
- **PowerShell launch command from the repository root:** `& ".\build\tilaok-offline-live-build-20261022-r3.exe"`.

## Manual check for a later safe session

1. Join locally with two or more keyboard/gamepad seats and ready each seat.
2. Start Play, select an item in Pugad, and wait for the shared three-second GO.
3. Keep moving during the race. Aim and confirm a build; observe its owner, footprint warning, progress and remaining time.
4. Verify no collision or hazard effect occurs before completion, then confirm a safe build appears at two seconds.
5. Try a blocked footprint and cancel a job; verify the item remains available and no duplicate job appears.
6. Finish the round, review results, and replay into the next Pugad.

Synthetic test evidence is not a substitute for this physical-controller or human-play check. P20 checkboxes remain open until the full acceptance review records the failed and unavailable checks accurately.

## Build-mode movement and placement fix — October 23, 2026

This follow-up fixes the reported Play-mode build interaction. While build mode is open, that seat's chicken stops receiving player movement/jump input and its player-driven horizontal velocity is cleared; gravity and external forces remain active. The same seat's WASD/arrows/IJKL/numpad directions or gamepad left stick/D-pad steer the placement preview. A successful confirm closes build mode and restores chicken controls while the separate two-second job runs. A rejected placement keeps build mode open so its player can reposition and retry. The offline room now initializes preview bounds and spawn anchor from the active map, which was missing and could make every confirm reject.

Verification on October 23 used the installed Godot `4.6.3.stable.official.7d41c59c4` (the project plan's 4.7.2 target was not installed in this checkout): headless editor import/parse passed; the focused offline live-build runner passed **75 checks, 0 failures**, including local movement lock, preview steering, rejected-placement retry, all-seat keyboard/gamepad HUD cards, repeat construction of completed normal items, and immediate cancellation/item return when a chicken enters an unfinished footprint; `gdlint` and `gdformat --check` passed for the five changed GDScript files; `git diff --check` passed. Logs: [build-mode-import-20261023.log](build-mode-import-20261023.log) and [build-mode-tests-20261023.log](build-mode-tests-20261023.log). The imported revision was `1c570ee` plus the local working-tree changes. No GUI game launch, physical-controller session or human playtest was performed. This follow-up does not verify the 4.7.2 export or the broader P20 regression suite.

The earlier 75-check record above describes an intermediate behavior and is superseded by the user's later clarification below: a chicken does not cancel construction, a player gets one completed placement per round, and unused items do not carry into later rounds.

### Gamepad confirm repair — October 23, 2026

The South face button (A on Xbox-style pads / Cross on PlayStation-style pads) now confirms a placement during build mode. The Right trigger remains an alternate confirm. The per-player build hint and the active input map show the bottom button, so the prompt corresponds to a usable face button. The Godot 4.6.3 headless live-build suite passed **76 checks, 0 failures**; the final result is recorded in [gamepad-confirm-tests-20261023.log](gamepad-confirm-tests-20261023.log). This synthetic check does not claim a physical gamepad was tested.

### Occupied builds and per-round item use — October 23, 2026

When a chicken enters a construction footprint, the job continues. At completion, a chicken intersecting the new solid is moved to its top surface. Successful completion consumes the assigned item for the rest of that round; each new round assigns a fresh item, and unused items are not carried over. The installed Godot 4.6.3 headless suite passed **76 checks, 0 failures**, including an occupied-footprint completion and the one-placement-per-round limit: [build-occupancy-tests-20261023.log](build-occupancy-tests-20261023.log). No physical/human play session was performed.
