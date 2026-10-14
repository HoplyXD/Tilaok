# P07 First Playable evidence — 2026-10-14

## Scope and status

This folder separates engineering checks from human gate evidence. The P07 route is implemented over the existing match flow, with an exact runtime allowlist of `build.hollow_blocks.cell_1x1`, `build.hollow_blocks.stack_2x3`, and `build.bamboo_bridge.span_4x1`. Automated runners and screenshots use scripted input, synthetic gamepad identities, and teleported goal contacts. They do **not** satisfy player-driven sessions, novice comprehension, physical device, or independent human review criteria.

P07-T01 remains **IN PROGRESS**; P07-T02–T04 remain open. P02-T08 physical same-model controller disconnect/reconnect remains **COULD-NOT-RUN**. Full-match ending, Lagsanay, and sudden death are outside this slice and remain open. No release-readiness claim is made.

## Engineering evidence

- `p07_route_tests.txt` — exact pool allowlist, route, and ready-flow assertions.
- `p07_reset_audit.txt` — ten **synthetic** next-round transitions, construction IDs/count/signatures, removal persistence, score totals, actor reset, transient/callback cleanup, and duplicate score rejection.
- `p07_performance.txt` — scripted 1920×1080 phase captures and 2/3/4-seat local frame/memory samples. This is not a player session or a target-PC guarantee.
- `01_lobby_1920x1080.png` through `06_next_round_pugad_1920x1080.png` — code-drawn DEBUG UI captures from the scripted two-seat route.
- `07_four_seat_min_zoom_1920x1080.png` — scripted four-seat corner-spread visibility capture at the configured minimum zoom (0.50); it verifies target presence, not human readability.
- `verification_commands.txt` — commands and exit codes for P07, regression, import, lint/format, export and startup checks.
- `exported_capture_command.log` — records that the packaged runtime ignored the `--script` probe; exported UI screenshots are not available. The later interactive capture was stopped before screenshots were saved.

Current local machine: Windows, Intel Core i5-13420H, NVIDIA GeForce RTX 4050 Laptop GPU, Godot `4.7.2.stable.official.ed1daf0bf`, Compatibility renderer. The provisional limits are 60 FPS / 16.67 ms, 512 MiB static process memory, and 0 B/s gameplay traffic. The local runner records static memory and frame intervals; it does not claim OS working-set sampling or network traffic monitoring. The 2/3/4-seat samples are below the provisional frame and memory limits; they do not establish target-PC performance. Gameplay traffic is 0 B/s by local-only architecture, not by packet capture.

## Human session and device matrix

No participants, novice participant, observer, or session dates have been supplied. The only currently available input inventory is one keyboard and no gamepads; keyboard make/model, layout, and rollover are unrecorded. The proposal to use four identical gamepads is a setup target, not an availability claim.

| Session | Required human coverage | Current result | Device assignment / notes |
|---|---|---|---|
| P07-T01 two-player | Two participants including a novice; two full player-driven rounds; novice controls/comprehension notes; ten human-used next-round transitions with item IDs/count/signature and scores; observe placement/removal/reset behavior | **COULD-NOT-RUN** | One keyboard available; two simultaneous human seats and novice not arranged; no participant or observer identity/date supplied |
| P07-T02 review | Reviewer checks T01 evidence and records identity; state full-match/Lagsanay/sudden-death coverage remains open | **COULD-NOT-RUN** | T01 human evidence and reviewer identity absent |
| P07-T03 two-seat device matrix | Exercise available 2-seat combinations, one-seat device ownership, simultaneous input, camera/preview isolation, focus/pause, disconnect/reconnect, reclaim, countdown cancellation, fresh post-resume input | **COULD-NOT-RUN** | Target setup: two identical gamepads plus keyboard. Actual gamepad models/count/connection are unknown; P02-T08 is open |
| P07-T03 three-seat session | Three rounds; rotate participants/devices; same isolation/camera/input/pause/reclaim checks | **COULD-NOT-RUN** | Target setup: three of the same gamepad model; unavailable/unconfirmed |
| P07-T03 four-seat session | Three rounds; rotate participants/devices; same isolation/camera/input/pause/reclaim checks | **COULD-NOT-RUN** | Target setup: four of the same gamepad model; unavailable/unconfirmed |
| P07-T04 verification | Review T03 round counts, device matrix, visibility, simultaneous input, pause/reclaim, and P02-T08 evidence | **COULD-NOT-RUN** | No T03 physical session records or reviewer identity |

| Player count | Available physical combinations | Synthetic engineering coverage | Human/device acceptance |
|---:|---|---|---|
| 2 | One keyboard only; keyboard model/layout unknown. Two physical seats not demonstrated. | K1 + K2 routed in P07 tests and capture. | **COULD-NOT-RUN** |
| 3 | No gamepad available; no physical three-seat combination. | K1 + K2 + one synthetic gamepad identity in the render runner. | **COULD-NOT-RUN** |
| 4 | No gamepads available; no physical four-seat combination. | K1 + K2 + two synthetic gamepad identities in the render runner. | **COULD-NOT-RUN** |

No participant names, dates, device models, observer, novice observations, or actual human round/reset records are entered here. Add those details only when sessions occur; preserve failures and unavailable combinations rather than inferring a pass from automation.

## Session record template

For every real session, append a dated record containing:

1. Build/commit, engine, OS, machine, resolution, seed, and P07 variant allowlist.
2. Participant pseudonyms/roles (identify the novice), observer/reviewer name, date/time, and consent to record.
3. Actual device make/model, wired/wireless connection, seat assignment, button map, keyboard model/layout, and every unavailable combination.
4. Round-by-round result and capture/log links; novice first-action/control comprehension, confusion, and facilitator prompts.
5. For each of ten resets: transition number, stable item IDs/count/signature, removed IDs, score totals, actor lifecycle state, transient count, and duplicate-award result.
6. P03/P07 camera minimum-zoom readability; three/four-seat target visibility; simultaneous input isolation; pause/focus and countdown behavior; disconnect, reclaim, and fresh input after resume.
7. Status per acceptance check: PASSED, FAILED, or COULD NOT RUN, with evidence and defect links. Keep reviewer verification separate from implementation evidence.
