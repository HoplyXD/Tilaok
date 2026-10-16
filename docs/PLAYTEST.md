# Tilaok! Verification and Playtest Plan

_Originally a plan only on 2026-10-12. Updated through P11 technical engineering verification on 2026-10-14. This is not a full game or release playtest._

## Current verification status

P01 provides a Godot 4.7.2 foundation harness; P02 adds movement and input diagnostics; P03 adds the bounded graybox stage, camera and support contracts; P04 adds item infrastructure and Kaing/Tulay seeds; P05 adds lobby/Pugad/atomic Place; P06 supplies Karera finish rules and scoring; P07 adds a dedicated first-playable route; P08 adds independent Lagsanay; P09 adds a development-only Karera match ending and tied-player sudden death; and P11 adds the standalone `kangaroo_contract_lab` route. P07 human/device acceptance, P08 entry/release gate, P09 performance target and human/device acceptance, P11 human/device/balance/production-asset acceptance and performance target, and P02 physical-device acceptance remain open. The engineering routes use synthetic seats and scripted fixtures; none is a complete game or release playtest. Historical P00 results remain below.

| Check | Status | Evidence / limit |
|---|---|---|
| Guided first match (P13-T07 slice) | **PASSED (engineering, synthetic input) — no human session** | Tutorial-only stage gate (no-build search 1,860 attempts, 0 reached, highest feet 511.94 vs ledge 480), per-piece solutions, coach-box flow/skip/replay/session-memory tests (48 + 140 checks), rendered 1080p/720p captures, perf and export smoke on Godot 4.7.2; [evidence](evidence/tutorial/README.md). Novice comprehension, facilitator interventions, cultural review and Kangaroo prompts remain open (P13-T08 sheet below). |
| Results scoreboard chart (P13-T13/T14 slice) | **PASSED (engineering, synthetic fixtures) — human review open** | 52 focused history/chart checks; binding/UI/mode and P06/P08/P09/P11 suites; rendered 2/3/4-player, no-score, fractional, above-target, round-12, tied sudden-death, motion-mode and resolution captures. Godot 4.7.2 import, lint/format, Windows export/startup passed. See [scoreboard evidence](evidence/scoreboard/README.md). No physical-device test, independent code review or player comprehension session is claimed; wider P13 remains open. |
| Historical headless project initialization/import | **PASSED** | `godot --headless --path "tilaok!" --editor --quit`, Godot 4.6.3; completed filesystem scan, icon import, and editor initialization with no errors/warnings in the captured historical output. This is not target-engine validation. |
| Target Godot 4.7.2 P01 project import/parse | **PASSED** | Godot 4.7.2 imported the working project after P01 foundation additions; [full log](evidence/p01-import-godot-4.7.2-2026-10-13.log). |
| Historical P00 Godot 4.7.2 editor initialization | **FAILED — historical** | Earlier invocation exited 0 but logged `ERROR: Parameter "singleton" is null` and a thread-shutdown warning; [historical log](evidence/p00-import-godot-4.7.2-2026-10-13.log). The current P02 import/parse check below is clean. |
| Current P02 Godot 4.7.2 editor import/parse | **PASSED** | `--headless --path 'tilaok!' --editor --quit`; exit 0, no ERROR/WARNING lines; [full log](evidence/p02-import-godot-4.7.2-2026-10-13.log). |
| P03 Godot 4.7.2 import/parse | **PASSED** | Full project editor import/class registration completed with exit 0 and no parser/import errors; [P03 verification record](evidence/p03/2026-10-13_p03_verification.md). |
| P01 harness runtime | **PASSED** | Harness launched in Godot GUI; build/profile/seed displayed, a diagnostic run started, the movement placeholder loaded and returned, and reset released its fixture. This is harness evidence only, not gameplay. [Headless runtime log](evidence/p01-runtime-smoke-2026-10-13.log). |
| P01 foundation checks | **PASSED** | Configuration ranges/snapshots, seven profiles, incomplete release and empty-pool rejection, bad IDs/references/weights, eligibility, weight normalization, deterministic selection, independent streams and 30 fixture cleanup iterations passed. [Full test output](evidence/p01-foundation-checks-2026-10-13.log). |
| P02 synthetic input, physics and recovery checks | **PASSED** | 83 Godot assertions cover seat isolation/identity, synthetic gamepad and K1/K2 routes, deadzone/D-pad priority, phase edges/repeats, pause timer+physics probes including the bound-device disconnect path, actual jump/braking/reversal/contact/containment/recovery behavior, coyote/buffer and cleanup. [Full output](evidence/p02-checks-2026-10-13.log). Synthetic events are not hardware evidence. |
| P02 rendered room and frame sample | **PASSED — diagnostic only** | [Running fixture](evidence/p02-diagnostic-room.png), [synthetic disconnect pause](evidence/p02-reconnect-pause.png), [metrics](evidence/p02-rendered-metrics.txt). 1152×648 rendered window on RTX 4050, four diagnostic actors; no pre-P02 baseline, no 1080p comparison or late-game stress claim. |
| P02 export build/startup | **PASSED — startup only** | Windows Desktop export succeeded and exported executable started headlessly with `--quit-after 90`, exit 0; [logs](evidence/p02-export-2026-10-13.log), [runtime](evidence/p02-export-runtime-2026-10-13.log). Interactive exported input/pause smoke was not verified. |
| P03 route/protection | **PASSED — graybox contract** | 100 focused P03 assertions; real controller reached the goal via Godot collision, and rejected edits preserved immutable geometry. No promise of continued solvability after future player construction. [P03 test output](evidence/p03/2026-10-13_p03_tests.txt). |
| P03 camera/rendering | **PASSED — fixture evidence** | 2/3/4 target extents, highest legal preview, 900-wu/s controller launch, target lifecycle, 1080p min-zoom renders and 1920×800 aspect test passed. [Screenshots and GUI log](evidence/p03/2026-10-13_p03_verification.md). |
| P03 support provenance/contact | **PASSED — fixture contract** | Real collision matrix, explicit metadata rejection/inheritance, 3 sample-only boundary lines, moving/removal and invalidation assertions passed. No wave scheduler or item is implemented. [P03 test output](evidence/p03/2026-10-13_p03_tests.txt). |
| P03 render throughput/memory | **PASSED — one diagnostic sample** | 600 uncapped 1920×1080 render frames: median 0.826 ms, p95 1.426 ms, worst 6.141 ms; Godot static memory 67.60 MiB; sampled process peak working set 199.91 MiB/private bytes 250.59 MiB. This is not late-game stress or release evidence. [Metrics](evidence/p03/2026-10-13_performance.txt). |
| P03 Windows export/startup | **PASSED — startup only** | Matching 4.7.2.stable Windows templates; release export succeeded and the exported main scene completed a three-frame headless startup, both exit 0. [Log](evidence/p03/2026-10-13_windows_export_smoke.txt). |
| Physical gamepad isolation/reconnect | **COULD NOT RUN** | No gamepads available. Two identical controllers, mixed input, unplug/replug and exported physical input remain open. |
| Physical K1/K2 keyboard rollover | **COULD NOT RUN** | Software tests synthesize keyboard events; physical chord/rollover and keyboard model/layout were not verified in this session. |
| P02 rendered performance comparison | **COULD NOT RUN** | One post-change fixture sample only; no comparable pre-change rendered baseline. Single worst frame is not a stress bound. |
| Current GDScript lint/format | **PASSED** | All project GDScript files pass installed `gdlint` and `gdformat --check` 4.5.0; [P03 verification record](evidence/p03/2026-10-13_p03_verification.md). |
| P02 GDScript lint/format | **PASSED** | All P02-owned scripts/tests pass installed `gdlint` 4.5.0 and `gdformat --check` 4.5.0. [Lint](evidence/p02-lint-2026-10-13.log), [format](evidence/p02-format-2026-10-13.log). |
| Export / exported Windows build | **PASSED** | Official 4.7.2 templates installed in standard versioned path; Windows Desktop export succeeded. Executable opened a responsive `Tilaok!` window, accepted a normal close, and exited. [Template record](evidence/p01-template-install-2026-10-13.log), [export log](evidence/p01-export-godot-4.7.2-2026-10-13.log), [runtime record](evidence/p01-export-runtime-2026-10-13.log). Template-manager UI was not used. |
| Physical keyboard/controller validation | **COULD NOT RUN** | Windows enumerated keyboard devices but no gamepad/controller; keyboard model/layout and actual button mapping are unknown. Device enumeration is not an input test. |
| P02 diagnostic performance / full playtest baseline | **PARTIAL** | One rendered P02 fixture sample is measured below; complete-player playtests, physical controls, comparable pre-change baseline, 1080p and late-game stress remain unverified. |

## P05 diagnostic-loop session — October 14, 2026

**Build/source:** updated main checkout at fa5a4e27f61f884cd726dc35fd800da8a0fef121; Godot 4.7.2.stable.official.ed1daf0bf; seeded match 12345. **Machine:** Windows, Intel Core i5-13420H, NVIDIA RTX 4050 Laptop GPU. **Devices:** keyboard seats K1/K2 and synthetic gamepad identities 3/4. **Review:** automated checks and Codex capture inspection; no independent human review or human playtest.

| Check | Status | Result and evidence |
|---|---|---|
| Import/class registration | PASSED | Godot editor import exited 0 with no errors/warnings; [log](evidence/p05/import_parse.log). |
| Lint/format | PASSED | gdformat check and gdlint on all 100 project GDScript files; no lint issues. |
| Existing automated suites | PASSED | Foundation lifecycle 0 failures; P02 83, P02 wall 85, P03 103, P04 268 checks. Logs are indexed under [P05 evidence](evidence/p05/). |
| P05 automated match checks | PASSED | 137 checks, 0 failures: claim order/ties/final-timeout tick, 2/3/4 seats under seeds 12345/7/991, pool eligibility, placement validation, atomic permutations/conflicts/cleanup, timeout commit/discard, pause, lobby gate, held edges, result advance and ten-round persistence/reset. [log](evidence/p05/p05_test_run.log). |
| UI component gallery contract | **PASSED — isolated debug fixture** | 437 checks across scene/component instantiation, prompt/seat identity, owned-seat input, transitions, theme/layout, and resource-free lifecycle. Sample result data is not connected to P05 or the scoring engine. [log](evidence/p05/ui_gallery_smoke.log). |
| Existing visible regression runners | PASSED | P03 14 checks and P04 Item Lab 25 checks; see [P03 log](evidence/p05/existing_p03_interactive_run.log) and [P04 log](evidence/p05/existing_p04_interactive_run.log). |
| P05 visible loop | PASSED | 64 checks; traversed two round cycles through the harness with four fixed identities, contested egg/retry, exact-variant handoff, rotated 2×3 ghost, simultaneous confirmed edit batch, diagnostic Play/results and construction retention. [log](evidence/p05/p05_interactive_run.log). Seats 3/4 were synthetic. |
| Rejection/variant captures | PASSED | 1920×1080 images; 12 expected validator codes matched actual codes and visible non-color reason text. Exact variant egg/ghost/placed handoff matrix and screenshots are in [P05 evidence](evidence/p05/). |
| Four-seat crowded render/performance | PASSED — local diagnostic sample | 600 frames at 1920×1080, 48 persistent pieces after 12 rounds: median 2.356 ms, p95 4.616 ms, worst 8.577 ms; 79.80 MiB Godot static memory; 2,323 objects; 302 nodes; zero orphan nodes. P95/worst <16.67 ms and memory <512 MiB. P04 baseline was 1.954/3.109/6.059 ms and 70.97 MiB. [metrics](evidence/p05/p05_performance.txt), [crowded image](evidence/p05/crowded_post_round12_48_pieces_1920x1080.png). The stress capture had no removals; once-only cleanup and persistence were asserted separately. |
| Gameplay traffic | PASSED — architectural inspection | Local-only flow has no sockets/network calls; 0 B/s gameplay traffic. No traffic monitor was used. |
| Windows Debug export/startup | PASSED — startup only | Godot 4.7.2 Windows template export and exported headless P05 room smoke; final logs: [export](evidence/p05/windows_export.log), [runtime](evidence/p05/windows_export_runtime.log). This does not verify exported physical input. |

The verification report and dated D3 scope note are [here](evidence/p05/2026-10-14_p05_verification.md) and [here](evidence/p05/2026-10-14_p05_scope_note.md). P05-T01–T12 are recorded as checked, with T12 rerun against P06 results. P05 evidence alone does not cover scoring; see the P06 record below. Walis Cleanup gameplay, saves and networking remain outside the slice. Synthetic pad events do not count as physical gamepad validation; final art/audio and human/competition review remain outstanding.

## P07 First Playable engineering verification — October 14, 2026

**Build/source:** `P07-first-playable-dev`, `karera_slice`, seed `12345`; Godot `4.7.2.stable.official.ed1daf0bf`; Windows, Intel Core i5-13420H, NVIDIA GeForce RTX 4050 Laptop GPU, Compatibility renderer. The P07 room applies a per-room allowlist and validates its generated egg pool. No participant, novice, observer or physical gamepad took part in these checks. Scripted input, synthetic gamepad identities and teleported goal callbacks are engineering fixtures only.

| Check | Status | Result and evidence |
|---|---|---|
| P07 route and allowlist | PASSED — automated | 590 checks, 0 failures. The P07 route uses only `build.hollow_blocks.cell_1x1`, `build.hollow_blocks.stack_2x3`, and `build.bamboo_bridge.span_4x1`; generated pools outside that list are rejected. [log](evidence/p07/p07_route_tests.txt). |
| Next-round reset audit | PASSED — synthetic | Ten goal/results/next-round transitions, 172 checks, 0 failures. Stable IDs/signatures and scores persist; removed construction stays removed; actor/transient/pending-state cleanup and duplicate-results score idempotency pass. A separate full-match reset clears construction and totals. [log](evidence/p07/p07_reset_audit.txt). |
| Regressions | PASSED — automated | Foundation, P02 input/movement, P02 wall, P03 stage/camera, P04 items, P05 match flow, P06 scoring and UI suites all exit 0; per-suite logs are in [P07 evidence](evidence/p07/). |
| Import, export and launch | PASSED — engineering smoke | Godot editor import/parse, Windows Debug export and exported headless launch of `--open-room=p07_first_playable` each exit 0. The exported runtime prints the exact three-variant allowlist. See [import](evidence/p07/import_parse.log), [export](evidence/p07/windows_export.log), and [startup](evidence/p07/windows_export_runtime.log). |
| Exported interactive 1080p screenshots | COULD NOT RUN | The packaged binary ignored the `--script` capture probe; the subsequent interactive capture was stopped before export screenshots were saved. The seven 1920×1080 screenshots below are project-runner captures, not exported-build captures. See [probe log](evidence/p07/exported_capture_command.log). |
| Project-runner renders | PASSED — scripted debug capture | Lobby, Pugad, Place, Karera, results, next-round Pugad and four-seat minimum-zoom captures are 1920×1080. Synthetic corner spread at zoom 0.50 kept 4/4 targets visible; this is not human readability evidence. [captures and metrics](evidence/p07/). |
| Local performance sample | PASSED — provisional local budget | At 1920×1080 and 300 race + 300 results frames, 2/3/4-seat race median/p95/worst were 8.333/8.380/10.807, 8.333/8.371/8.756, and 8.334/8.427/10.891 ms; results were 8.333/8.368/8.712, 8.333/8.415/8.814, and 8.358/10.775/11.384 ms. Godot static memory was 86.73/86.76/90.25 MiB; object/node counts were 2044/133, 2064/141 and 2102/152; 0 orphan nodes; one persistent item; sample durations 5.133/5.130/5.278 s. These samples are below 16.67 ms and 512 MiB, but do not establish target-PC performance. Gameplay traffic is 0 B/s by local-only architecture; no traffic monitor ran. [full metrics](evidence/p07/p07_performance.txt). |
| Human/device acceptance | COULD-NOT-RUN | One keyboard, no gamepads, and no participants, novice, observer or dates were supplied. P07-T01–T04 remain unchecked; P02-T08 physical same-model disconnect/reconnect remains COULD-NOT-RUN. [session sheet and device matrix](evidence/p07/README.md). |

The P07 route and engineering checks are implemented, but the human gate remains open. No independent human review is claimed. Full-match ending, Lagsanay, sudden death, novice comprehension, human-used ten-reset evidence, 3/4-player rotations, pause/focus behavior on physical devices, reconnect/reclaim, and minimum-zoom readability review remain explicit gaps.

## P08 Independent Lagsanay engineering verification — October 14, 2026

**Source/build:** main baseline `160a0b4` plus the P08 task-local working tree; Godot `4.7.2.stable.official.ed1daf0bf`; Windows, Intel Core i5-13420H, NVIDIA GeForce RTX 4050 Laptop GPU, Compatibility renderer, 1920×1080. **Profile/seed:** `lagsanay_lab` / `12345`; values remain provisional. **Seats/input:** synthetic K1/K2 keyboard identities for 2 seats and additional synthetic gamepad identities at 3/4 seats. The engine ran real physics, current overlap sensors, actual Trumpo rail contact and an actual Tsinelas Launcher projectile. The supplied distinguishable Last Cluck timestamps are unit/presentation fixtures, not contact-order measurements. **Reviewer:** Codex implementation/verification session; no independent human reviewer or player session is recorded.

| Check | Status | Procedure and result |
|---|---|---|
| Focused Lagsanay arbitration/scoring | PASSED | 86 assertions cover seeded selection, 3 s opening immunity, sensor candidates/ties, stationary overlap, 1 s pass-back, timeout/hazard and batch precedence, reassignment, exact placement tables, owner/self-kill, Bawi, tick-only compatibility, Last Cluck permutations and exactly-once scoring. Exit 0; [log](evidence/p08/regressions/final/run_p08_tests.log). |
| Rendered 2/3/4-seat route and results | PASSED — synthetic seats | 87 assertions, 0 failures, exit 0. Entered Lobby → Pugad → Place → Lagsanay, checked pass-through taya, HUD taya/head-start/countdown/pass-back explanation, exact winner/results, reset, pause/resume clocks and cleanup. [Report](evidence/p08/p08_interactive_run.txt), [captures](evidence/p08/README.md#p08-checks). |
| Real hazard attribution | PASSED — actual Godot physics | Rail Trumpo contact and Tsinelas Launcher projectile reached the independent Lagsanay sink with round/source/owner identity preserved. Direct owner credit, self-kill exclusion and competing-source order are covered by focused checks. Runtime timestamp precision is limited to values recorded by hazard integration. [Report and images](evidence/p08/README.md#p08-checks). |
| Last Cluck presentation | PASSED — supplied timestamp fixtures | 2/3/4 all-final cases select exactly one winner; exact ties use lowest stable slot; lower placements and one award set are preserved. Reversed callback permutations and duplicate events do not change the result. Rendered result explains “latest recorded elimination time” and the tie rule. [Capture](evidence/p08/06_last_cluck_explained_results_1920x1080.png). |
| Full regression batch | PASSED — 13 runners | Foundation, blocks, P02 controller/wall, P03, P04, P05, P06, P07, P07 reset, P08, P10 and UI exited 0. Per-run raw stdout/stderr and [exit summary](evidence/p08/regressions/final/suite_summary.txt). |
| Performance/restart/cleanup | PASSED — local provisional budget | 300 rendered frames per seat count with Trumpo and Launcher active, v-sync off: 2/3/4 worst frame intervals 11.140/13.106/13.361 ms; OS process sample 287.84 MiB peak working set / 421.58 MiB private bytes. Three synthetic containment-defect restarts retained construction and pre-round scores with zero awards; room teardown left 0 orphan nodes. [Metrics and commands](evidence/p08/p08_performance.txt). |
| Import/format/lint/export | PASSED with one inherited lint limit | Editor import/parse and Windows Debug export plus exported `--open-room=p08_lagsanay` startup passed. Format check passed. `gdlint` reports only the inherited `match_room.gd` file-size rule (baseline 1,013 lines; current 1,022); no other changed-script lint finding. |
| Human/device/release acceptance | COULD-NOT-RUN | No physical gamepads, human players, novice observer, cultural review or independent code reviewer participated. P07-T04 remains unchecked; development authorization for P08 does not satisfy its gate. `lagsanay_lab` is not release-enabled. |

Full task evidence and actual commands are indexed in [P08 evidence](evidence/p08/README.md) and [PHASETASK](PHASETASK.md#p08--lagsanay). The focused P08 count and regression results are synthetic engineering verification, not human play evidence. The complete match, event scheduling/stacks, final UI/art/audio and release onboarding remain outside this slice.

## P09 match lifecycle engineering verification — October 14, 2026

**Build/route:** `P09-match-lifecycle-dev`, `karera_slice`, seed `12345`; Godot `4.7.2.stable.official.ed1daf0bf`; Windows, Intel Core i5-13420H, NVIDIA GeForce RTX 4050 Laptop GPU, Compatibility renderer, 1920×1080 windowed. **Seats:** synthetic K1/K2 keyboard identities and synthetic gamepad IDs 7101/7102. **Reviewer:** Codex engineering run; no independent human review, player session, or physical-device input is recorded. P09 keeps the P07 three-variant allowlist and is not the P12 release schedule.

| Check | Status | Result and evidence |
|---|---|---|
| Focused coordinator/Lagsanay matrix | PASSED — automated | 77 assertions, 0 failures: threshold and leader matrix, round 11/12, lower-place ties, duplicate/reordered/stale callbacks, 2/3/4 tied contestants and four-seat noncontiguous subset `[1,3]`. [log](evidence/p09/p09_focused_tests.txt). |
| Rendered P09 loop and result actions | PASSED — synthetic inputs | 108 assertions, 0 failures. Real authoritative round scoring reaches 80 units after six rounds; four-player all-finish transitions through completed round 12 without round 13; a preloaded 40/40 fixture routes P2/P4 only. Covers exact live scores, one winner, Replay seed/config reset, whole-group Lobby, Quit/leave confirmation and cancel, pause/reclaim, focus/device readiness invalidation, spectator exclusion and unchanged match scores through sudden death. [report](evidence/p09/p09_interactive_run.txt), [console output](evidence/p09/p09_interactive_console.txt). |
| Lagsanay physics/sudden-death behavior | PASSED — engineering fixture | Actual Godot contact sensor transfers taya among contestants; spectator cannot tag or become taya. Survivor and synthetic Last Cluck outcome paths both resolve one winner without adding placement score to match totals. Synthetic Last Cluck source records are clearly labeled because the P07 allowlist has no hazards. |
| Ten full ending/restart cycles | PASSED — synthetic audit | Five 80-unit score endings and five round-12 all-finish sudden-death endings; Replay or Lobby action after each. State snapshots cover scores, persistent construction, removed/transient/captured items, actors, pending claims, result readiness, Lagsanay timer/immunity, match/round/attempt identity and stale callback rejection. [audit JSON](evidence/p09/p09_restart_audit.json), [console](evidence/p09/p09_restart_audit_console.txt). |
| Cleanup and process memory | PASSED — local sample | After cycle 3's warmed baseline, object deltas ranged −5 to +1 and Godot static-memory deltas ranged −97,572 to +249,784 bytes; no continuing rise appeared. Windows process-tree peaks: 292.3 MiB working set and 426.7 MiB private bytes (<512 MiB). [sample](evidence/p09/p09_process_memory.txt). |
| 1080p frame intervals | PERFORMANCE TARGET MISSED | Ten-cycle rendered sample: 226 warmed frames, median 9.52 ms, p95 27.78 ms, worst 55.60 ms; total run worst 144.38 ms. The warmed p95 exceeds the 16.67 ms target; P15 performance acceptance remains open. [audit JSON](evidence/p09/p09_restart_audit.json). |
| Rendered route captures | PASSED — project runner | 1920×1080 captures cover score-target results, Replay, round-limit sudden-death entry, tied-player contact, survivor result, noncontiguous tied seats, Last Cluck explanation and Lobby. They are project-runner engineering captures, not human readability or exported-UI acceptance. [capture index](evidence/p09/README.md#checks-and-captures). |
| Import, lint, Windows export and route smoke | PASSED — local engineering smoke | Godot 4.7.2 editor import/parse, changed-script gdformat/gdlint, Windows Debug export and direct plus exported P09 route startup passed. [logs](evidence/p09/). |
| Existing regressions | PASSED — selected suites | Foundation, P02, P05 (137), P06 (97), P07 (590), P08 (86) and UI (438) passed; individual saved logs are indexed under [P09 regressions](evidence/p09/regressions/). The separate P04 test runner did not finish within the 30-second command window and was stopped after its process was identified; P04 regression is not claimed as passed. |
| Human/device/release acceptance | COULD NOT RUN | No human players, novice observers, physical gamepads, independent reviewer or release review participated. P07 and P08 gates remain open; P12 event scheduling/stacks are covered by the engineering run and human-session sheet in the P12 section below. |

The pinned Godot 4.7.2 binary and exact launch/test commands are listed in [P09 evidence](evidence/p09/README.md). Automated input, shortened timers, injected finish candidates and the preloaded-score route fixture are not player session evidence. Local-only gameplay traffic is an architectural 0 B/s expectation; no packet capture was performed.

## P00 production-readiness evidence

**Date:** October 13, 2026.

**Inspection revision:** `fa6145839bff96ecb6e1afdb112e804bfb72260f` (`origin/main` before P00 documentation edits). The intended console executable reports `4.7.2.stable.official.ed1daf0bf`. The user-reported current PC target and observed system inventory, all discovered Godot executables, template paths, lint tools, and missing export setup are recorded in [PRODUCTION.md](PRODUCTION.md#p00-baseline-record).

The clean target import used a temporary copy of `project.godot`, `icon.svg`, and `icon.svg.import`, avoiding any claim that gameplay or a production build was tested. It completed filesystem scan and icon reimport with no warnings/errors. The direct editor invocation on the working checkout is retained as a separate failed diagnostic; it returned exit 0 but logged both an error and warning. A cached import repeat is preserved in [its log](evidence/p00-import-only-godot-4.7.2-2026-10-13.log). No export was attempted because there is no export preset or entry scene and matching 4.7.2 templates are absent.

Observed machine details do not establish which physical keyboard layout or controllers the team will use. No controller was found in the queried Windows device inventory. Button/axis mapping, rollover, simultaneous input, reconnect behavior, and multi-controller ownership remain untested. Performance budgets remain UNMEASURED.

## P01 foundation verification

**Date:** October 13, 2026. **Build identity:** `P01-foundation-dev`, Godot `4.7.2.stable.official.ed1daf0bf`, default profile `movement_room`, default seed `12345`. The default profile validates configuration only; no game content is selected or simulated. `release_candidate` is intentionally rejected until required modes and pools are implemented and verified.

The headless test script passed checks for valid/invalid finite tuning and presentation ranges, unknown profiles, snapshot isolation, pause-only presentation updates, inactive R1–R4, required empty-pool rejection, invalid/duplicate IDs, unknown references, invalid weights, enabled-but-unverified content, eligibility before normalization, same-seed weighted selection and independent RNG streams. It also instantiated, detached and freed each fixture 10 times, asserted one return callback per instance, and compared root node count to baseline. A harness scene test started/reset a run, opened/closed each fixture repeatedly, reloaded with a fixture active and confirmed the new scene had no retained state. The GUI harness displayed identity/status, started a diagnostic run, opened/returned from a placeholder room, and reset. A registered independent team reviewer is not recorded.

Formatting and lint passed using installed 4.5.0 tools. Godot 4.7.2 import/parse and headless run completed without warnings/errors. Matching 4.7.2 templates were installed by extracting the official package into the standard version directory; the manager UI was not used. Windows export succeeded and its executable launched/closed locally. Exact logs are linked in the current status table and in [PHASETASK P01](PHASETASK.md#p01--project-foundations).

**Limitations:** Codex generated these foundations under the task authorization and internal policy in force at that time; they are not described as manually team-written. This does not settle competition originality eligibility. No physical controller/input test, multiplayer gameplay, novice onboarding test, performance measurement, clean-PC install, or final-release export was performed. P00-T02 and P00-T06 remain open; see [PRODUCTION](PRODUCTION.md#p00-baseline-record).

## P02 input and movement diagnostic session — October 13, 2026

**Build identity:** `P02-input-movement-dev`, base `e2b4a555e8d45bec774ffebde7c46e595cd3abdb` plus the current local P02 changes; Godot `4.7.2.stable.official.ed1daf0bf`; movement room; seed `12345`; 60 Hz; local Windows PC with NVIDIA GeForce RTX 4050 Laptop GPU/OpenGL 3.3 Compatibility. P02 code was AI-generated under the authorization and internal policy in force at the time; no independent team reviewer is recorded.

| Check | Status | Procedure and observed result | Evidence/limit |
|---|---|---|---|
| Foundation regressions | PASSED | Existing `run_foundation_tests.gd`; configuration, content rules, seed isolation, fixture cleanup, harness lifecycle and reload checks passed with zero failures. | `p02-foundation-checks-2026-10-13.log`; no P01 regression failures. |
| P02 automated checks | PASSED | `run_p02_tests.gd`; 83 assertions passed. Synthetic device/phase events plus Godot CharacterBody2D/Area2D physics, Timer callback, physics freeze probes, synthetic bound-device disconnect, mode breaches, explicit diagnostic reset and five load/unload cycles. | `p02-checks-2026-10-13.log`; device events are synthetic. |
| Jump arc/timing | PASSED | Short release 44.27 wu; held jump 96.06 wu, apex at 19 physics frames (0.3167 s), within 2 wu/one-step target. Held jump landed once and did not auto-repeat; coyote jump and pre-landing buffered jump passed. | Automated physics output; fixture only, no player feel sample. |
| Run, braking, reversal | PASSED | 30-tick run displacement 120.00 wu at 280 wu/s; stopping distance 11.67 wu; reversal crossed zero in 6 physics frames. | Automated physics output; provisional values, not balance findings. |
| Collision/reachability | PASSED | Full jump traversed dedicated 64 wu gap + 64 wu rise and landed at x=871.34, y=273.93; ceiling blocked ordinary jump. | Diagnostic fixture only, not production arena reachability. Visible one-way test surface does not implement the item system. |
| Contact and movement ownership | PASSED | Overlapping chickens did not push; separate 28×48 contact sensor reported overlap. Capture preserved intent and blocked forced motion; opening freeze and terminal state prevented lower-priority motion. External launch was 101.12 wu held/released on a clear path. | Synthetic/physics tests; no Lagsanay or Kangaroo gameplay implemented. |
| Pause/reconnect software contract | PASSED synthetically | SceneTree pause held physics and a Timer callback; focus/device status cleared readiness/cancelled countdown; changed-ID seat reclaim preserved identity. | Does not prove physical disconnect/reconnect behavior. |
| Containment/recovery | PASSED as diagnostic contract | Maximum diagonal configured launch stayed inside bounds. Race breach failed once without auto-respawn; Lagsanay and standalone Kangaroo breach paused as prototype defects; recovery kept pre-round score/construction snapshot and awarded zero. | Contract fixture only; no score engine or production round restart. |
| Rendered sample | PASSED as observation | Captured four-seat markers, controls and graybox geometry. Median frame interval 0.490 ms, p95 0.893 ms, worst 3.481 ms; Godot static memory ~76.0 MB, process private memory 199,815,168 bytes, working set 202,584,064 bytes; 1,788 objects/128 nodes. | One 180-frame rendered sample at 1152×648. No pre-P02 baseline, 1080p comparison or late-game stress claim. |
| Export | PASSED startup only | Windows Desktop preset exported and executable completed 90 headless frames with exit 0. | Exported interactive input/pause, physical devices and GUI response not tested. |
| Physical devices | COULD NOT RUN | No gamepads; no two-identical-controller, mixed-input, physical unplug/replug or keyboard rollover test. | Keep P02-T01–T04 and T07–T08 open as recorded in PHASETASK. |

Commands and complete captured outputs are linked from [PHASETASK P02](PHASETASK.md#p02--inputs-and-controller). The local-only slice has no networking or save migration; only in-memory diagnostic snapshots are preserved. Full gameplay clocks/items/events/scoring are not present to stress or migrate.

## P03 graybox stage, camera and support verification — October 13, 2026

**Build identity:** `P03-graybox-dev`, local working tree based on `4cb31a9`; Godot `4.7.2.stable.official.ed1daf0bf`; `movement_room`; seed `12345`; 60-Hz physics. **Machine:** Windows, 13th Gen Intel Core i5-13420H, 12 logical CPUs, NVIDIA GeForce RTX 4050 Laptop GPU, Compatibility renderer. **Reviewer:** Codex automated tests and screenshot inspection; no independent team review is recorded. **AI assistance:** P03 implementation, test and evidence code, and these documentation updates were AI-assisted; no production art/audio was generated.

| Check | Status | Procedure, expected and observed result | Evidence/limit |
|---|---|---|---|
| Arena and protection | PASSED | Validate source geometry and protected footprints/sweeps/effects; try immutable and unknown removals; compare geometry signature. Expected rejected edits do not mutate base/floor/spawn/goal; observed all guards passed and signature stayed unchanged. | `2026-10-13_p03_tests.txt`; labeled graybox view in `2026-10-13_interactive_harness_1080p.png`. |
| Controller route | PASSED | Run actual controller from floor through A/B/C/D to goal, with collision/headroom/braking/containment assertions and no teleport between route platforms. Expected goal inside bounds; observed `goal=true x=1012 y=360`. | `2026-10-13_p03_tests.txt`. Route is a playable graybox result, not a full-game playtest. |
| Camera fit/lifecycle | PASSED | Check full target rectangles at 2/3/4 actors, opposite-corner Place previews, y=96 legal construction, confirmed/secured/eliminated filtering, empty target hold, launch and large-bounds clamp. Expected extents stay in HUD-safe view; all assertions passed. A real 900-wu/s upward controller launch had camera target top at y=208.38 after 36 physics frames and remained visible. | `2026-10-13_p03_tests.txt`. Camera rectangle/preview fixtures are synthetic and do not certify a controller. |
| Interactive GUI | PASSED | At 1920×1080, open P03 through visible harness button; join K1/K2; use Play/movement, Place/confirm/rotate, pause/resume, reset and Return. Expected all 14 checks pass and labels remain distinguishable at overlapping spawn; observed 14/14 and rendered evidence inspected. | `2026-10-13_interactive_test.txt`, `2026-10-13_interactive_harness_1080p.png`. Inputs were synthetic. |
| Rendered camera/aspect | PASSED | Capture Play and Place at 1920×1080/zoom 1.0, then resize to 1920×800. Expected 1280×720 logical gameplay view without extra horizontal world; observed all target extents visible and wide-window game image 1422×800 with unchanged logical size. | `2026-10-13_play_1080p.png`, `2026-10-13_place_1080p.png`, `2026-10-13_place_wide_window_1920x800.png`. Codex inspected labels, solid geometry, protection and preview extents. |
| Support matrix | PASSED | Run real collision support fixtures for built, one-way, launch, moving/removal, safe-face, child provenance, other-player construction, base, chicken, capture, projectile, wall, coyote and airborne states. Expected only explicit eligible upward built contact at/above the line; all 100 P03 assertions passed. Sample y=384/320/256 boundaries are test fixtures, not event heights. | `2026-10-13_p03_tests.txt`; future item/event contracts are not marked implemented. |
| Render performance | PASSED — one sample | Record 600 uncapped completed render frames at 1920×1080 with four controllers, active collision/support and camera movement. Observed median 0.826 ms, p95 1.426 ms, worst 6.141 ms; Godot static memory 67.60 MiB; 0.544 s elapsed. Windows sampled the engine process every 50 ms: peak working set 199.91 MiB and private bytes 250.59 MiB. | `2026-10-13_performance.txt`, `2026-10-13_rendered_capture.txt`; not a late-game stress or release benchmark. |
| Reset/reload and Foundation regression | PASSED | Ten repeated P03 scene cleanup cycles, ten harness open/return cycles, harness reload and Foundation tests. All assertions passed; no exit warnings/errors. | `2026-10-13_foundation_regression.txt`. |
| P02 regression | PASSED | Existing P02 test suite rerun after integration: 83 checks, zero failures. | `2026-10-13_p02_regression.txt`; remains synthetic, not physical P02 acceptance. |
| Windows export | PASSED — startup only | Export Release using matching 4.7.2.stable Windows templates; run exported main scene headlessly for three frames. Export and smoke exited 0. | `2026-10-13_windows_export_smoke.txt`; no exported interactive/device test. |

## P04 item infrastructure and construction seeds — October 13, 2026

**Build identity:** `P04-item-lab-dev`, `main` @ `765ed09` plus the P04 working tree; Godot `4.7.2.stable.official.ed1daf0bf`; profile `karera_slice`; seed `12345`; 60-Hz physics. **Machine:** Windows, 13th Gen Intel Core i5-13420H, NVIDIA GeForce RTX 4050 Laptop GPU. **Input:** synthetic keyboard (K1/K2) routing and synthetic gamepad seats; no physical device or rollover was certified. **Reviewer:** Codex (automated); no human playtest. Full table and logs: [P04 verification index](evidence/p04/2026-10-13_p04_verification.md).

| Check | Result | Notes |
|---|---|---|
| Definition validation rejection table | **PASSED** | 31 rejection cases plus effect-region ≠ occupied-cell checks. |
| Lifecycle, ten reset cycles, caps, rotating allocation | **PASSED** | Nodes 110→110, objects 1760→1760, orphans 0; caps 48/16/4/32; each of 6 emitters wins 4 of 6 rounds under cap 4; reversed callback order yields identical grants. |
| Kaing real-controller trials | **PASSED — synthetic input** | Stand on 1×1, 2×3, rotated 3×2; side blocks at x=396; foothold route; underside head stop; same-step support loss on removal. |
| Tulay real-controller trials | **PASSED — synthetic input** | Land from above, rise from below (never support while rising), walk off edge, jump off, side pass-through, ceiling pass, five fall-cap drops onto the 4 wu strip (peak sampled 878.9 wu/s). |
| Interactive Item Lab (1920×1080) | **PASSED** | 22 checks, 4 consecutive runs. An earlier flaky run was caused by a focused HUD button receiving Enter and by OS-focus pause; HUD buttons are now non-focusable and the runner resumes a focus-paused game like a player would. |
| 48-piece, four-chicken render sample | **PASSED — one diagnostic sample** | 600 uncapped 1080p frames: median 1.954 / p95 3.109 / worst 6.059 ms; peak working set 208.8 MiB. A first run's single 59.4 ms interval at the v-sync switch was fixed with a warm-up and is disclosed in the index. |
| Windows export + exported startup of Item Lab | **PASSED — startup only** | Debug export exit 0; exported build loaded both `.tres` definitions from the PCK and exited 0. |
| Lint/format/import | **PASSED** | `gdlint`/`gdformat --check` on 49 files; editor import exit 0 without diagnostics. |
| Wall-extension suite (not P04) | **PASSED** | `run_p02_wall_tests.gd` re-run on the rebased tree: 85 checks, 0 failures. Wall movement is enabled by default as core movement (owner decision, 2026-10-13); P04 declares Kaing wall eligibility and its tests slide and kick on a placed Kaing block. |
| Static checks over the whole project | **PASSED** | `gdlint`/`gdformat --check` on all 53 `.gd` files after the rebase. |
| Placeholder egg previews and Library | **PASSED — placeholder** | Egg → ghost → piece identity for all 3 enabled variants, looping animation, no text on eggs, Library fields and release filter (265 checks total; GUI runner 25 checks). [Capture](evidence/p04/2026-10-13_eggs_library_1080p.png). |
| Human feel/readability review | **COULD-NOT-RUN** | No human reviewer or physical device was available; crowd captures show crowded labels at 48 pieces. |

## Wall movement — future verification

**Status:** approved Should-scope extension, implemented and run on 2026-10-13 with automated synthetic checks (results in the dated session below). The cases in this table stay as the full future matrix; rows that still need a human or physical device are called out in the session. Evidence index: [wall evidence](evidence/p02-wall/README.md). Use actual Godot physics, rendered screenshots/clips, and human feel/balance review. Mathematical estimates alone do not establish playability. Record build/revision, engine, date, profile/seed, player count, actual devices or synthetic input, procedure, expected/actual result, artifact and reviewer. Mark each PASSED / FAILED / COULD-NOT-RUN. Keep synthetic and physical-device evidence separate.

| Area | Future procedure and expected result |
|---|---|
| Left/right symmetry; wall approach/departure | Approach eligible walls from both directions, touch, slide, jump away, leave and lose contact. Both sides behave symmetrically; no slide or stale wall state remains after separation. |
| Slide speed and vertical direction | Measure downward velocity against the configured descent cap. Verify the cap applies only while descending; selected ascending velocity remains uncapped by the slide rule. |
| Eligible surface classes | Test base solids, player-built solids and moving solids. Moving contact must track actual valid contact and clear when the wall moves away or is removed. |
| Excluded surfaces | Test one-way platform sides and undersides, triggers, ineligible hazard/effect surfaces, pass-through chicken bodies, and arena containment boundaries. None enables wall slide/jump. |
| Fresh press / held input / OS repeat | Compare a new jump edge against a held button and operating-system key repeats. Only a fresh press may create one wall jump; holding must not auto-repeat. |
| Buffer/grace consumption | Press just before, during and just after eligible contact, including the configured contact grace. A buffered jump is consumed exactly once and cleared on expiry or cancellation. |
| Impulse / steering / contact repeat | Measure horizontal-away and vertical impulse on both sides; steer immediately using normal air acceleration. Same-wall repeat requires physical separation and fresh recontact. |
| Corners, shafts and ceilings | Try corners, narrow shafts, rapid side switches, wall-to-wall climb routes and ceiling contact. No same-contact infinite climb, clipping, trapped state or unintended repeat occurs. |
| Ground and coyote regression | Repeat normal ground jump, coyote jump, short/full jump and landing tests with wall contact nearby. Existing ground-jump behavior remains within its P02 contract. |
| Bounds and maximum force | Combine the largest configured kick with approved external launch limits in every direction. Players remain inside visible bounds and cannot bypass immutable protection. |
| Route and camera | Traverse the existing P03 base route; it must remain traversable with wall movement enabled (default) and with it forced off. Then test wall shortcuts and maximum kick trajectories with the camera at minimum zoom and supported player separations. Record intentional shortcuts for balance review. |
| Built surfaces and support | Compare wall movement on base versus player-built sides. Assert wall contact never writes upward support/provenance or qualifies for Rising wave; verify actual landing on an eligible platform still does. |
| Lifecycle states | Attempt contact/input during capture, opening freeze, secured and eliminated states. Higher-priority states suppress wall actions and cannot reactivate terminal players. |
| External launches | Launch during wall slide/contact and while jump is buffered. Launch takes precedence, is not shortened or overwritten by wall logic, and clears wall eligibility/buffer. |
| Pause, phase/reset/reload | Pause while sliding and resume; change phase, reset, remove a contacted wall and reload the scene. No simulation advances while paused and no stale contact, repeat lock or jump replays. |
| Player-to-player interaction | Overlap chickens near an eligible wall and attempt to use another chicken as a wall. Bodies remain pass-through; no push, wall state, or wall-jump eligibility comes from players. |
| Freeze input observability | Inspect intentional-input telemetry while pressing jump for a wall action and while captured/frozen. Preserve existing intentional-input visibility for the future Freeze gate; do not claim Kangaroo integration from this check. |
| Keyboard/gamepad parity | Run synthetic seat-routed keyboard and gamepad events separately, then actual physical devices when available. Match press edges, buffering, direction and cancellation; synthetic checks do not satisfy physical-device acceptance. |
| Future Lagsanay/event stacks | In actual multiplayer builds, test repeated wall movement as an escape route or stalling strategy in Lagsanay and each applicable event stack. Keep these checks attached to their event gates; do not make the controller depend on full event implementations. |
| Feel and balance | Obtain human review of slide readability, jump response, repeated-contact rule, intended shortcuts, wall stalling and recovery. Record reviewer, players/devices, procedure and findings; calculations or agent-authored tests are not human feel evidence. |

Capture at minimum zoom and inspect rendered evidence for clear contact/eligibility cues. If a shortcut is intentionally possible, document it; escaping bounds, bypassing immutable protection or violating an event contract is a failure. The required P03 base route remains playable without this Should feature.

The full command/evidence inventory is in [P03 verification](evidence/p03/2026-10-13_p03_verification.md). This work does not certify physical controller behavior, player feel, final-art readability, late-game load, balance, full round/match lifecycle, item systems, or release readiness. The previous P02 device and P01 human-review tasks remain open.

## Wall movement verification session — October 13, 2026

**Build identity:** working tree on `9ee25c8` (base `765ed09`); Godot `4.7.2.stable.official.ed1daf0bf`; `movement_room`; seed `12345`; 60 Hz; three seats (synthetic K1, K2, gamepad). **Machine:** Windows, AMD Ryzen 5 5500 (12 logical CPUs), AMD Radeon RX 580, Compatibility renderer, 1920×1080 renders. **Reviewer:** Claude (AI, automated tests and screenshot inspection); no human reviewer, no physical devices. **Wall setting:** `wall_movement_enabled` = true only inside the wall test and capture scripts (shipped default false).

| Check | Status | Procedure and observed result | Evidence/limit |
|---|---|---|---|
| Wall runner | PASSED | `run_p02_wall_tests.gd`: 85 checks, 0 failures; real physics, synthetic input. | [log](evidence/p02-wall/2026-10-13_wall_tests.txt) |
| Existing regressions | PASSED | `run_foundation_tests.gd` 0 failures; `run_p02_tests.gd` 83/0; `run_p03_tests.gd` 103/0 (recorded with wall off; re-run 2026-10-13 with wall enabled by default: same counts, 0 failures). | `evidence/p02-wall/2026-10-13_regression_*.txt` |
| Import/parse, lint, format | PASSED | Editor import: 0 error/warning lines. gdlint 4.5.0 and gdformat 4.5.0 clean on all scripts and tests. | [import](evidence/p02-wall/2026-10-13_import_parse.txt) |
| Slide + symmetry | PASSED | 120.00 wu/s on left and right; ascent uncapped. | wall log |
| Excluded surfaces | PASSED | Ineligible, one-way, metadata-less, trigger, chicken: no slide and no kick. One-way underside passes through. | wall log |
| Kick, hold, echo, buffer | PASSED | 1 kick per fresh press on each device type; held 1 s with OS repeat → 1; echo → 0; pre-contact press → 1. | wall log |
| Per-contact lock | PASSED | Same-contact press blocked; lock cleared at 12.10 wu gap; recontact kicks once. | wall log |
| Lifecycle / pause / reset | PASSED | Launch, capture, freeze, terminal, pause/resume, phase change, reset, wall removal, moving wall away, stage reset, 5 reloads. | wall log |
| Support / Rising wave | PASSED | P03 base side slide leaves support contacts empty and result "no support". | wall log |
| Containment / camera | PASSED | Four kick+launch vectors stay in bounds; P03 camera keeps every target visible. | wall log, [capture log](evidence/p02-wall/2026-10-13_wall_render_capture.txt) |
| Rendered stills | PASSED — inspected | 1920×1080: [slide](evidence/p02-wall/01_slide_base_side_1080p.png), [kick](evidence/p02-wall/02_kick_1080p.png), [excluded](evidence/p02-wall/03_excluded_surface_1080p.png), [max kick+launch](evidence/p02-wall/04_max_kick_launch_camera_1080p.png). Camera zoom was 1.11–1.36 (two chickens), not 1.0; debug bar and label were visible; fixture labels remain small. | Not a readability or final-art claim. |
| Performance | PASSED — this machine only | 3 runs of `capture_p03_evidence.gd`: median 0.69–0.70 ms, p95 1.84–2.07 ms, worst 4.79–5.91 ms, static memory 68.95 MiB. Unmodified baseline `765ed09`, same machine, 3 runs: median 0.54–0.65, p95 2.05–2.20, worst 5.94–21.40 ms (one run over 16.67 ms), 68.74 MiB. Wall movement was disabled and no fixtures were built in these runs; enabled-mode cost is not separately measured. Different hardware from the P03 record, so not comparable to its 0.826/1.426/6.141 ms. | [current](evidence/p02-wall/2026-10-13_perf_current_tree_3runs.txt), [first run](evidence/p02-wall/2026-10-13_perf_rerun_this_machine.txt) |
| Physical devices | COULD NOT RUN | No gamepads; no physical keyboard/rollover session. P02-T18 stays open. | — |
| Human feel / balance | NOT DONE | Session sheet prepared, no reviewer. P02-T22 stays open; keep/defer PENDING. | [sheet](evidence/p02-wall/human_feel_session_sheet.md) |
| Windows export + startup | PASSED — startup only | Release export (matching 4.7.2 templates) and `--headless --quit-after 90` of the exported executable both exit 0. | [export](evidence/p02-wall/2026-10-13_export.txt), [runtime](evidence/p02-wall/2026-10-13_export_runtime.txt) |
| `--write-movie` clip | COULD NOT RUN | Not attempted; stills only. | — |

## 64 px grid, sneak/glide and stage blocks — October 14, 2026

Build: working tree on `19b3653`; Godot 4.7.stable.official.5b4e0cb0f; Windows 11; Item Lab (`karera_slice`), seed 12345, 60 Hz; synthetic K1/K2 keyboard events; 1–2 seats. Reviewer: Claude (AI, automated; no human reviewer).

| Check | Expected | Actual | Result |
|---|---|---|---|
| Existing suites on the 64 wu grid | no regressions | foundation, P02 83, wall 85, P03 103, P04 268, P05 137, UI 437 — 0 failures | PASSED |
| `run_blocks_tests.gd` | tiles, controls, sneak, glide, three blocks | 60 checks, 0 failures | PASSED |
| W press in Play | full jump | 192.1 wu rise | PASSED |
| Sneak | 56×56 body, feet fixed, no walk/jump, stays small under a 1-tile ceiling | as expected | PASSED |
| Glide | cap 180 wu/s, steering kept, wall slide wins on walls | max 180.0 wu/s | PASSED |
| Wood Box | falls, pushed, friction stop, standable, resets in Place | push 120 wu / 45 ticks | PASSED |
| Collapsing Block | collapse 2 s after floor or wall-slide contact; respawn 3 s when clear | 2.00 s / 3.02 s; waits while overlapped | PASSED |
| Rendered stage/blocks at 1080p | readable placeholders | [captures](evidence/blocks/README.md) | PASSED (visual inspection by Claude only) |
| Human feel/balance, physical devices | session with named reviewer | not run | COULD-NOT-RUN |

## Block scenes, Spikes, Cannon and stun — October 14, 2026

Build: working tree on `a9eb75f`; Godot 4.7.stable.official.5b4e0cb0f; Item Lab, seed 12345, 60 Hz; synthetic K1 events. Reviewer: Claude (AI, automated). Catalog parity with the removed `.tres` data: 0 differences across 23 variants. All 21 headless suites: PASSED except two P04 checks already failing on origin/main. `run_blocks_tests.gd` 110/110. Human feel review of spikes/cannon/stun and editor authoring by the user: COULD-NOT-RUN (P02-T29). [Evidence](evidence/blocks/README.md).

## Completion status vocabulary

For each check, record exactly one status:

- **PASSED** — run on the documented build/hardware and supported by a short procedure plus actual output, capture, or repeated observation.
- **FAILED** — reproducible defect with steps and evidence.
- **COULD NOT RUN** — environment, device, build, or prerequisite missing; state the reason.

Record build/commit, test date, local player count, input devices, scenario, item count, and evidence location. Keep design acceptance criteria separate from observed results.

## Required test layers

### Documentation review (available now)

- Count mechanically distinct catalog designs; verify there are at least 30 and that visual variants are not counted separately.
- Confirm the eight-family first batch and Bula-Bulaklak-last sequencing; confirm Barya is separate.
- Check every first-batch contract for tell, counterplay, footprint/trigger/sweep distinction, tunables, race/Lagsanay behavior, ownership, removal, reset, assets/cultural verification, dependencies, and risk.
- Trace all accepted design rules to GDD and roadmap; flag all still-open technical dependencies.
- Verify no source code, copied UCH art/audio/names, unsupported cultural origin claims, or false implementation/playtest claims.
- Verify new docs are referenced and paths marked NEW before implementation.

### Project implementation checks (when available)

1. **Project/controls:** launch via documented Godot version; join local 2, 3, and 4 players; test gamepad-first and shared-keyboard fallback. Record physical-device limitations. Check the implemented movement baseline and input deadzone during Play; add the wall-movement matrix only if the approved Should extension is implemented and selected. Do not infer physical-device parity from synthetic input.
2. **Pugad/placement:** simultaneous egg claims cannot duplicate an egg; timeout handling is deterministic; invalid placements discard cleanly; colliding solid placements reject atomically independent of callback order; allowed solid/trigger overlaps remain readable; no object places on a player or protected clearance.
3. **Cleanup/persistence:** preview names the exact target set; protected base/spawn/goal/hidden-event zone survive; same-phase new placements are not accidentally swept into cleanup; removed pieces stay removed; unsupported objects do not crush or permanently pin a player; item/transient counts stay bounded.
4. **Lifecycle:** each item is inactive during Place; Play reset uses the defined position/phase/direction and activation grace; round end/restart/removal clears timers, signals, projectiles, bubbles, captures, and references; stage items persist according to the contract.
5. **Per-item solo harness:** for every enabled item, exercise placement at valid/invalid boundaries, every rotation, tell/counterplay, collision/contact, ownership, removal, reset, and safe bounds. For the first batch also run the five combinations in `docs/ITEMS.md`.
6. **Bubble state matrix:** one and multiple simultaneous captives; already captured/dead/finished chicken; ceiling, side wall, moving platform, and world-bound contact; safe release position/velocity; immunity and recapture; external trap contact and direct-source credit; goal contact while captive; death, emitter removal, round end and restart cleanup; Lagsanay timer/tag interaction and unavoidable-chain check.
7. **Parol readability:** active/inactive/charge cue; active collision span and solid occlusion; overlapping emitters; minimum camera zoom; color-vision-independent icon/silhouette/audio. Confirm no rapid flicker.
8. **Scoring/ownership:** one terminal outcome per player; no duplicate award; self-elimination gives no Patibong; competing same-step contacts produce stable ownership; goal/death same-step ordering; exact indistinguishable Karera flag ties award Una to every tied first finisher only when some but not all players finish, with no second/third-place bonus; Main-Challenge scoring family remains authoritative during a Twist; Barya remains race-only and pays its carrier in an all-finish round while ordinary awards are suppressed (2–4 players); no-finish rounds award zero; Bawi; Lagsanay/Kangaroo four-player survival order (first eliminated fourth for zero placement points, last survivor first), independently earned Patibong even for fourth; placement ties with exact eighth-point precision; and simultaneous final Lagsanay eliminations. Confirm that the latest recorded elimination wins and that an exact timestamp tie uses the lowest player slot/ID, with the “Last Cluck!” result callout.
9. **Lagsanay compatibility:** each enabled item tested with pass-back immunity/timer and taya movement; multiple simultaneous tag contacts resolve by nearest eligible chicken then player-slot tie-break; chickens pass through each other while the tag sensor remains active; frozen opening taya is hazard-immune; trap death, taya death, shared earlier simultaneous placements, Last Cluck final placement, and solid-floor behavior. Disable an item in Lagsanay if unavoidable capture/force chains make play unfair.
10. **Match lifecycle:** complete a 12-round match, first-to-10 end, tie/Sudden Death, restart, and repeated matches; confirm no state or object growth and stage persistence/removal rules.
11. **Core event selection and stacks:** test Round 1 Karera guarantee; the standalone Main-Challenge selection weights on non-guaranteed rounds; guaranteed standalone Lagsanay in rounds 4, 8, and 12; the probability band on rounds 1–12; prior-Pugad announcement; no self-stacking; one-Twist cap; and no Sudden Death Twist. Test Karera + Lagsanay with 2/3/4 players: pass-through bodies with active tag sensing, finish-to-secured state, current taya finishing, all runners finishing/eliminated, race-only scoring, Barya, and no Lagsanay placement awards. Test Karera + Kangaroo: normal/sole-down Freeze, sole-up Rising wave, and sideways Hug landings occur at statistically equal one-third rates before the two-survivor Hug reroll; all three commands, failure markers, a secured finisher receiving no more commands/hazard effects, race-only scoring, and Barya. Test Kangaroo + Lagsanay with 2/3/4 players: command response while taya timer and passing remain active, command failure/taya timeout/trap elimination ordering, last-survivor resolution, and Lagsanay placement scoring only. For Rising wave, test every permitted height band, deliberate failure when players build no usable raised support, player-built support versus base platform versus jump/airborne/bubble state, and the drain/reset. For Hug, test evaluation-only contact pairing, contact-pair ordering, ties, 3-player clusters with one unpaired chicken, two pairs in 4-player games, split groups, pass-through sensing, eliminations, and the two-survivor reroll. Verify each two-command no-elimination acceleration; Slipper Storm's 0.5-second landings, one-second command duration, two-command cap, and delayed third landing; the required Freeze-plus-Rising-wave pair at two survivors; every elimination reset; and a simultaneous final elimination using Last Cluck. Verify full/reduced/off screen shake and distinct pose, icon, audio, and timing tells. Preserve Langit-Lupa as the planned second laro ng lahi.

### Gameplay playtests

- Run at 2, 3, and 4 local players. Use both gamepad and shared keyboard; record unavailable hardware rather than assuming coverage.
- At least one test facilitator should not know the item/event rules beforehand; record whether they can identify the hazard and counterplay from the game presentation.
- Test a clean stage, representative stage, cluttered 12-round stage, and a stress stage at the maximum configured persistent/transient counts.
- Repeat key race/Lagsanay scenarios after restart to expose order-dependent defects, dangling state, and stage persistence errors.
- Capture screenshots or short clips where available; screenshots alone do not prove a mechanic is stable.

## Performance measurement plan

Provisional targets from the approved design plan: **60 FPS / 16.67 ms frame time at 1080p** on the identified target PC; **512 MiB process memory** provisional ceiling; **0 B/s gameplay networking** (local-only). The user selected the current PC and its observed specifications are in `PRODUCTION.md`; these targets remain proposed budgets, not measured results.

For base, representative four-player, and worst-case 12-round scenes, record CPU/GPU if available, OS, CPU/GPU/RAM, resolution, build type, duration, persistent item count, transient projectile/bubble count, and enabled event. Report frame-time median/p95/worst spike, process memory, and object/node counts. Compare before/after repeated match restarts. Profile a normal four-player match and stress at up to 48 placements before cleanup, plus separately bounded transients. Do not optimize from node-count assumptions alone; use an observed profiler capture. If target hardware is not selected, mark baseline **COULD NOT RUN — target not specified**.

## Required final evidence report

The prototype experiments and documentation verification follow below. Current P02 results appear in the dated session above; full-game checks remain pending.

For each new session, append date/build and a table containing check, status, evidence, player count/input, and defect reference. Report actual logs, including new warnings/errors, and unresolved output. Headless import does not replace runtime playtesting. Never tick an unrun check.

## Original prototype test plan and change discipline

**Written before P02 implementation.** Baseline values are centralized in PROTOTYPE_DEFAULTS.md; geometry/support are in STAGE_AND_PLACEMENT.md. Do not copy tunables into this checklist. The current P02 fixture now exists; its measurements and AI authorship are recorded above. Human playfeel and physical device checks still require team sessions.

First session, once M0 exists: about 25 minutes with two actual available players/devices. Record hardware rather than assuming gamepads. Use `movement_room`, seed 12345, and the named baseline. Spend 3 minutes identifying controls, 8 minutes on ten full/short jumps and ten comfortable-gap/rise trials per player, 5 minutes on advanced landings/braking/reversal, 5 minutes swapping player slots/devices and repeating a subset, and 4 minutes collecting separate feedback. This is directional evidence, not enough to prove balance or equal win rates.

Record: build/engine, date, profile/seed, participant experience (anonymous labels suffice), slot/device, attempted target, success, missed press versus timing mistake, overshoot, collision surprise, confidence in identity and brief verbatim feedback. Measure apex height/time, stopping distance and max separation readability where possible. Do not label a missed jump as an input defect without a reproduced press trace or observed device failure.

After M1/M3, run a short session at each of 2, 3 and 4 players: 5 minutes onboarding, three complete rounds, then one pause/reconnect/restart scenario. Rotate people across slots/controllers. Record time to join/claim/confirm without help; phase and round durations; finish fraction; all/none-finish no-score rounds; stalled rounds; avoidable versus apparently unavoidable eliminations; camera/identity/hazard confusion. At construction-only milestones, report the lack of lethal content rather than treating all-finish rounds as release balance evidence.

| Experiment | Acceptance / investigation trigger |
|---|---|
| Arc/unit consistency | Measured apex within 2 wu and one physics step of the model; larger deviations investigated before feel tuning |
| Comfortable vs advanced jumps | After practice, comfortable targets aim for ≥80% success; advanced targets should demand more care. Repeated misses/overshoots trigger review, not an automatic balance verdict |
| Input consistency | Zero cross-controlled seats, duplicate claims or reused transition presses; any reproducible lost simultaneous key means remap or unsupported keyboard combination |
| Onboarding | Every participant can identify self, move/jump, claim and confirm after the guided first round; record every facilitator intervention |
| Atomic placement | All conflicting solids rejected together regardless of submission callback order; protected geometry remains unchanged |
| Scoring | One outcome/award per player; all-finish ordinary awards suppressed for 2–4 players with Barya exception, no-finish zero, underdog snapshot, goal/death tie and exact legal averaged placements pass |
| Slot advantage | Repeat identical contact/tie geometry after swapping slots/devices; report deterministic rule bias separately from player skill; inactive proposals require acceptance before replacement tests |
| Wave explanation | Each support-table case gives correct pass/fail; players can state whether failure was height, provenance or contact; test just above/on/below every line |
| Freeze/stacks | Reproduce off-support Freeze+wave and low-timer Freeze+taya scenarios under current rules; record unavoidable choice without silently enabling R3/R4 |
| Chain control | Record every input-suppression interval and escape opportunity; unavoidable repeated capture blocks that item/event enablement |
| Pause/device lifecycle | All gameplay clocks/hazards stop; identity and timers preserved on reconnect; all-ready countdown cannot leak movement or jump presses |
| Restarts | Ten round resets and later ten match restarts: no retained capture/projectile/immunity/score state; persistent stage resets only when intended |
| Readability | At all four corners/highest construction, live targets and relevant hazard/support cues remain legible; no hidden off-camera active player |
| Performance | Exported 1080p: measure median/p95/worst frame time against 16.67 ms target, process memory against provisional 512 MiB; record hardware and caps, no gameplay network traffic |

Change only one related group (for example jump height/apex and derived gravity, not unrelated score values). Preserve the original named baseline; write hypothesis, changed keys, expected result and observed result. Reproduce hard defects immediately. For feel changes, seek the same issue across at least two sessions/participants and repeat the same trials after adjustment. These small samples justify iteration, not statistical claims of competitive balance. No public telemetry/backend is needed; local notes and optional clips suffice.

### P06 engine verification — October 14, 2026

**Build:** `P06-karera-scoring-dev`, source base `11352c7` plus the P06 working tree; Godot `4.7.2.stable.official.ed1daf0bf`; `karera_slice`; seed `12345`; Windows 13th Gen Intel Core i5-13420H, NVIDIA RTX 4050 Laptop GPU, Compatibility renderer. **Input:** K1/K2 routing and synthetic seat identities 3/4; scripted positioning at the actual goal trigger. No physical controllers or human participants were used.

The 97-check P06 runner passed with 0 failures. It covered validated 60/15-second deadlines, active-time pause, boundary events, goal/elimination ordering, candidate permutations and deduplication, stale rounds, direct-owner rules, one-time score commits, 2/3/4-seat race scoring, suppression/waiver, snapshot Bawi, test-only Barya, every current legal placement tie, Last Cluck and exact eighth-point formatting. The P06 visible two-seat run passed 17 checks at 1920×1080, including tied same-step Una, exact 10-unit deltas, the two-player waiver explanation, all-ready next Pugad, score persistence and actor reset. The dependent four-seat P05 run passed 64 checks over two actual goal/results rounds; the P05 automated suite passed 137 checks, including the paused eight-second result advance.

**2026-10-15 rule changes:** the preceding P06 record is historical for the superseded two-player waiver. The current rule suppresses ordinary race awards when all 2–4 players finish, but an eligible Barya carrier still scores. [The all-finish zero update](evidence/p06/2026-10-15_all_finish_zero.md) was subsequently corrected for Barya; current synthetic results are in [the Barya correction](evidence/p06/2026-10-15_all_finish_barya_correction.md). No new rendered or human-session evidence is claimed.

| Seat count | Race median / p95 / worst (ms) | Results median / p95 / worst (ms) | Static memory | Repeated rounds/pieces | Result |
|---:|---:|---:|---:|---:|---|
| 2 | 2.450 / 3.039 / 3.876 | 2.200 / 3.049 / 3.467 | 82.89 MiB | 10 / 10 | p95/worst under 16.67 ms; no orphans |
| 3 | 2.350 / 3.036 / 3.801 | 2.193 / 3.061 / 4.057 | 83.10 MiB | 10 / 10 | p95/worst under 16.67 ms; no orphans |
| 4 | 2.180 / 3.005 / 3.788 | 2.397 / 3.073 / 4.247 | 86.57 MiB | 10 / 10 | p95/worst under 16.67 ms; no orphans |

Each performance sample used 300 rendered frames in active Play and 300 in live results at 1920×1080, V-sync off. The repeated-round fixture retained one construction piece per round. Godot static memory was below 512 MiB in all counts. OS process working-set memory was not sampled. Gameplay networking is absent by design (0 B/s). Godot 4.7.2 editor import/class registration, Windows Debug export with matching templates, and a five-second exported headless startup smoke all exited 0. Formatting and lint checks passed for the P06/P05 touched scripts; this is not a human review.

Evidence, full commands, logs, captures, environmental details and boundaries are recorded in [P06 verification](evidence/p06/2026-10-14_p06_verification.md). The results are local engineering measurements, not player-feel, balance, physical-device, release-PC or independent-review evidence. At that 2026-10-14 P06 verification point, hazard attribution and Barya were fixture interfaces; Barya runtime integration was added on 2026-10-15 and is recorded below.

## Documentation-only verification — completed 2026-10-13 (historical)

This section records the documentation-only pass before the P02 implementation session above. Its unbuilt-project statements and pending implementation checks are historical; the P02 session table is the current evidence record.

Final task checks are listed here. Earlier import evidence above belongs to its recorded run and was not rerun as a gameplay check. Git emitted only LF-to-CRLF conversion notices during source/worktree comparisons; no line-ending configuration was changed.

| Check | Status | Evidence / boundary |
|---|---|---|
| Historical repository/toolchain reinspection (prior documentation run) | PASSED | At that recorded inspection: skeleton only; no gameplay scripts/scenes; PATH Godot CLI 4.6.3 versus declared 4.7; gdlint/gdformat 4.5.0; merged-PR query empty. Current toolchain findings are in the P00 record above. |
| Movement equations and paper dimensions | PASSED | Recomputed g=1875 wu/s², impulse=600 wu/s, flight≈0.5954 s; raised reach 134.1 wu exceeds 104 wu candidate travel; descending shortcut reach 189.2 wu exceeds 168 wu; padded world fits viewport. Collision safety remains untested |
| Binding logic / dependency order / inactive modes | PASSED | Distinct keyboard seat bindings, phase-gated shared actions and system Escape; construction before Lagsanay; stacks after components; disabled weights filtered; required missing release modes reject configuration. Documentation review only |
| Legal placement average enumeration | PASSED | All current non-winning tie groups fit eighth units, including three-way places 2–4; first-place averages excluded by Last Cluck |
| Source preservation / documentation links / whitespace | PASSED | Original checkout status unchanged; GDD, AGENTS, ITEMS, ASSETS, SUBMISSION and project.godot match source hashes; all local Markdown file links, whitespace and conflict markers checked across 13 docs; git diff --check passed |
| Target-engine runtime and lint | COULD NOT RUN | No gameplay code/scenes; intended 4.7 CLI unavailable in inspected environment |
| Controller feel / exported performance / actual balance | COULD NOT RUN | No runnable game, physical-device tests or identified target PC |

At that documentation-only review, no team milestone was marked complete. The current P02 task state is recorded in [PHASETASK](PHASETASK.md#p02--inputs-and-controller); historical statements about an unbuilt project apply only to that prose-only task.

## P10 first-batch families — automated and rendered session (2026-10-14)

| Field | Record |
|---|---|
| Build / engine | `main` `a368c96` + P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf |
| Profile / seed / players / input | `items_lab`, 12345, 1–4 seats, synthetic K1/K2 keyboard and synthetic gamepad seats 3/4 (no physical device) |
| Procedure | `run_p10_tests.gd` (421 checks), `run_p10_interactive.gd` (56 checks through the harness Visualizer and the all-families P05 match), `capture_p10_evidence.gd` (sheets, tells, eggs, ghosts, 48-item stress, swap), file-level placeholder swap probe, Windows export + exported startup smoke |
| Expected / actual | Every row in [P10 verification index](evidence/p10/2026-10-14_p10_verification.md) passed; no row failed |
| Reviewer | Automated author only. **No human playtest, feel, balance or readability review is claimed.** |

**Still needed from people:** a human read of Parol (charge/active/inactive at minimum zoom with several emitters), launcher lane/cover fairness, bubble capture length and release placement, Trumpo pause timing and Gulong boost feel; native-speaker review of every working name; physical-device runs.

## P07-T01 playtest kit — live match UI build (2026-10-14)

**Status: ready for a human session; no session has been run and none is claimed.** The build starts at the Title and plays Lobby → Pugad → Place → Karera → Round result → next round with the scene-based screens bound to live P05/P06 data, in the P07 first-playable room (the three-variant allowlist verified above). Evidence for the build itself: [docs/evidence/match-ui/](evidence/match-ui/README.md); the device matrix and the session sheet from the engineering pass are in [docs/evidence/p07/README.md](evidence/p07/README.md). Synthetic input is not physical-device evidence.

### Launch

| Item | Value |
|---|---|
| Exported build | `build\tilaok-playtest-2026-10-14.exe` with its `.pck` in the same folder (Windows Desktop **release** export, Godot 4.7.2 templates). Double-click it. Nothing else is installed. |
| From source | `& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!'` |
| Developer harness | `... --path 'tilaok!' -- --harness` (or the F3 overlay's **Developer harness** button in a debug build) |
| Lifecycle route (optional) | `... -- --match-route=lifecycle` (the exported exe takes the same argument after `--`). Same flow with the P09 match end: first to 10 points or round 12 ends the match, ties go to Lagsanay sudden death, then the final result with Replay / Return to Lobby / Quit. It is **not** what the sheet below measures; use it to look at the Match result screen. |
| Profile / seed | `karera_slice`, seed 12345 (fixed; shown only in the DEBUG overlay, never on the player screens) |
| Devices | K1 (WASD, **F** ready/confirm/claim, **Space** jump, **R** rotate) and K2 (arrows, **Enter**, **Right Ctrl**, **Right Shift**) share one keyboard; gamepads: **South** ready/confirm/claim/jump, **West** rotate, **Start** pause. **Esc** pauses everyone. |
| Pool | Kaing 1×1, Kaing 2×3 and Tulay 4×1 only (the P07 allowlist; the room rejects any other egg). The Solid / Wood Box / Crumble stage blocks added on 2026-10-14 stay out of this build. The harness button **P07 First Playable** opens the same room without the Title. |

### Facilitator sheet (one page)

**Goal.** Watch two players complete the first loop twice without help beyond the scripted prompts, then reset ten times. Do not coach during Pugad or Place; note what they say.

| # | They do | They should see | Observe / ask afterwards |
|---|---|---|---|
| 1 | Press the ready key to join (Title) | Join prompt becomes the menu | "What did you press? What happened?" |
| 2 | Start, second player joins, both ready | Lobby slots with number + shape; match starts by itself | "Which chicken is yours? How do you know?" |
| 3 | Pugad: pick and claim an egg | Egg animation, your number on the egg, a text cue if you lose a claim | "What do you think this egg gives you?" |
| 4 | Place: move, rotate (if allowed), confirm | Ghost with valid / blocked text, your status row, countdown, "locked" after confirm | "Why was a spot refused? Could you undo?" (no undo by design) |
| 5 | Karera: run, jump, reach the flag | Timer, FINISH WINDOW after the first finish, SECURED / OUT | "What happens when the other player finishes?" |
| 6 | Round result: read it, press ready | Awards by name, totals, the scoring reason, 8 s countdown | "Why did you get these points? Why none (if suppressed)?" |
| 7 | Repeat to **10 round resets** (each Round result → next Pugad counts as one) | Construction persists, scores carry over, no duplicate piece or score | Count resets; record any duplicate placement, score, stuck input or stale text |
| 8 | Pause once (Esc), Resume, then Leave | Owner shown, all-ready resume, 3 s countdown; Leave returns to the Lobby | "Who could drive the menu?" |

**Explicitly missing in the default build (say so to the participants):** the Lagsanay event round, Kangaroo, event stacking and any twist; match end, winner and sudden death (they exist only on the optional lifecycle route above, so first to 10 or round 12 does not end this match); the guided tutorial (P13); final art, audio and typeface; saved settings.

**Record per session:** date, build file, engine, profile / seed / pool, player count, devices (K1 / K2 / pad model), rounds completed, resets completed, defects, comprehension answers verbatim, observer name. Do not fill reviewer identities you do not have.

### Session log

| Date | Build | Players | Devices | Rounds | Resets | Observer | Result |
|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | No human session run yet. P07-T01 stays unchecked. |
## P11 independent Kangaroo — standalone engineering route (2026-10-14)

**Build / engine / machine:** `P11-independent-kangaroo-dev`, rebased working tree after the scene-based match UI integration and P11 compatibility fixes; Godot `4.7.2.stable.official.ed1daf0bf`; Windows; Intel Core i5-13420H, NVIDIA GeForce RTX 4050 Laptop GPU, Compatibility renderer. **Profile / seed:** `kangaroo_contract_lab` / `12345`. **Input:** synthetic K1/K2 and synthetic gamepad seat identities only. No physical device, participant, independent human reviewer, or balance reviewer was involved.

| Check | Result | Evidence and limit |
|---|---|---|
| Deterministic command contract | **PASSED — 78 checks** | Seeded selection/cadence, Freeze event-edge handling and held-input grace, Rising current-support provenance/line/tolerance/removal/drain, deterministic live Hug pairs, strict recorded-time hazard precedence, batched terminal events, Last Cluck and Storm overlap/cap/reset; [`focused output`](evidence/p11/p11_unit_run.txt). P03's 103-check support suite separately covers real moving support, coyote/airborne rejection and support invalidation. |
| Standalone route and lifecycle | **PASSED — 85 synthetic assertions** | 2/3/4 seats, persistent construction, Pugad/Place/Play/results/next Pugad, placement scoring, pause/reclaim and cleanup; race goal/deadline and Lagsanay controller absent. Only Trumpo and Tsinelas Launcher are enabled. Includes same-time simultaneous failures and a rendered Last Cluck result. [`interactive report`](evidence/p11/p11_interactive_run.txt). |
| Visual HUD / muted and shake modes | **PASSED as engineering visual inspection** | Project-runner 1920×1080 [`HUD capture`](evidence/p11/p11_2p_command_hud_1920x1080.png) and [`Last Cluck result`](evidence/p11/p11_last_cluck_results_1920x1080.png); tests cover muted audio plus full/reduced/off shake and keep cues visible. This does not demonstrate player comprehension; human review remains open. |
| Rebased project regressions | **PASSED — 83/103/86/77/430 checks** | Godot 4.7.2 P02/P03/P08/P09/P10; all 0 failures in the current-tree [regression matrix](evidence/p11/p11_regression_matrix.txt). Includes input/reclaim, real support contacts, migrated Lagsanay and lifecycle rooms, and item behavior. Synthetic input only. |
| Scene-based UI regressions | **PASSED — 892 checks** | Match UI **198**, binding **185**, mode **62**, and general UI **447**; 0 failures in the current-tree [UI regression output](evidence/p11/p11_match_ui_regressions.txt). |
| Import, Windows export and exported startup | **PASSED** | Godot 4.7.2 class registration/import, Windows Desktop Debug export and five-second exported headless route startup; [`import`](evidence/p11/p11_editor_import.txt), [`export`](evidence/p11/p11_windows_export.txt), [`smoke`](evidence/p11/p11_windows_export_smoke.txt). Exported interactive input and visual capture were not verified. |
| GDScript lint / format | **PASSED** | Changed scripts and runners pass installed `gdlint` and `gdformat --check`; these are scoped checks rather than a full-project lint audit. |
| Local debug timing | **TARGET MISSED / PROFILE REQUIRED** | Latest rendered 120-sample debug run per seat count: process p50/p95/max were 96.397/96.397/96.397 ms (2 seats), 236.831/236.831/236.831 ms (3), and 292.063/292.063/292.063 ms (4). All p95 readings exceed the provisional 16.67 ms frame target; physics p95/max were 173.369 ms (2), 27.418 ms (3), and 10.023 ms (4). Sample is short/noisy and not an exported or release-PC benchmark. |
| Memory | **PARTIAL — local synthetic Debug sample** | Godot static memory was 110.4/110.6/111.0 MiB; a 100 ms Windows process sample over 14 seconds measured peak working set/private bytes of 306.7/420.5 MiB, under the provisional 512 MiB private-memory ceiling in this run. This is not exported-build or target-PC acceptance. [OS sample](evidence/p11/p11_os_memory_sample.txt). |

The full command list, metric interpretation and open human/team tasks are in the [P11 evidence index](evidence/p11/README.md). Remain open: player/novice comprehension, actual controller and pause/reclaim sessions, Rising explanations and moving-support review, pair-only Hug and forced two-survivor Storm balance, slot/tie bias, native-speaker/cultural review, production pose/timing/audio replacement, target-PC process-memory verification and performance profiling. P11 is a standalone development route only; R1–R4, event scheduling and all P12 stacks stay inactive. No final art or audio was generated.

## P13-T08 novice-session sheet — guided first match (2026-10-14)

**Status: ready for a human session; no session has been run and none is claimed.** The build is the default route since 2026-10-15 (the scheduled full match; the original 2026-10-14 sheet was written for the first-playable build, still reachable with `-- --match-route=first_playable`) started from the Title. The first match uses the tutorial stage where a built piece is needed to reach the flag. Kangaroo and Bomb-Taya additions are in [Sheet D](#sheet-d--p13-t08-novice-session-guided-first-match-lagsanay-and-kangaroo). Use a participant who has not seen the game; the facilitator must not explain Pugad, Place or the flag.

| Item | Value |
|---|---|
| Launch | `& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!'` → Title → join with **F** (K1) and **Enter** (K2) → Start |
| Devices | K1 + K2 on one keyboard (add gamepads if available); record what was actually used |
| Copy | PLACEHOLDER English (not culturally reviewed): `tilaok!/data/ui/tutorial_script.tres` |
| Optional | Lagsanay prompt: `-- --match-route=lifecycle` and reach sudden death (a fixture is needed; rounds 4/8/12 are not scheduled yet) |

### Observations to record (ask after the round, do not lead)

| # | Ask or watch | Record |
|---|---|---|
| 1 | "Why couldn't you reach the flag at first?" | participant's own words; did they notice the BUILD HERE zone? |
| 2 | "Explain the objective in your own words." | verbatim |
| 3 | "Explain how you moved / jumped / claimed / rotated / confirmed." | verbatim; which input was hard |
| 4 | "Explain what placing a piece does and why you put it there." | verbatim; placed in the zone? piece type? |
| 5 | Did the box ever cover something you needed? | what, when |
| 6 | Did anyone not realise they had to build? Did a retry round teach it? | yes / no, rounds taken |
| 7 | Skip: pause (Esc) and choose **Skip tutorial** mid-round. | works? did the box vanish and the stage stay? |
| 8 | Replay: Title → Library → How to Play → **Replay tutorial**, then Start. | guided again? |
| 9 | Close the game, check `%APPDATA%\Godot\app_userdata\Tilaok!` for new files. | none created by the tutorial |

### Intervention log (fill during the session)

| Time | Step | What the facilitator said or did | Why it was needed |
|---|---|---|---|
| | | | |

### Session record

| Date | Build / revision | Players | Devices | Rounds | Skip / replay worked | Facilitator | Participant pseudonym | Result |
|---|---|---|---|---|---|---|---|---|
| | | | | | | | | |

## P13-T13/T14 results scoreboard chart — October 15, 2026

**Scope:** one reusable vertical score chart in live round and final match results. This is an engineering and rendered-layout review of synthetic result data; it is not a player comprehension or release acceptance session. No scoring value, score suppression rule or winner rule changed.

| Verification | Result | Evidence / limit |
|---|---|---|
| Focused chart and history suite | **PASSED — 52 checks, 0 failures** | Integer eighth-point segment totals, stable player order, suppression/zero values, deduplication, replay reset, noncontiguous seats, resize/reveal/settle and teardown; see [`focused_tests.txt`](evidence/scoreboard/focused_tests.txt). |
| Existing integration regressions | **PASSED — 185/198/62/97/86/77/78 checks** | UI binding, match UI, mode UI, P06, P08, P09 and P11; same evidence index. |
| Interactive rendered routes | **PASSED — P06/P08/P09/P11: 17/87/108/85 assertions** | Rendered GUI execution, including live results; the runs used synthetic seats and input. |
| Screenshots and target sizes | **PASSED — 10 SubViewport captures** | Includes 1280×720, 1920×800 and 1920×1080, mixed awards, no score, fractional points, above target, round-12 below target, equal-height sudden-death winner, mid-reveal and Reduced motion; all captures and exact run output are linked from the [evidence index](evidence/scoreboard/README.md). Captures are synthetic fixtures, not participant play. |
| Import/parse, lint/format, Windows release export/startup | **PASSED** | Godot 4.7.2 editor import/class registration; `gdformat`/`gdlint`; exported executable headless startup. No physical-device review. |
| Human review | **NOT RUN** | Independent code review, final art direction, novice comprehension, accessibility and readability remain open. Synthetic input is not physical-device evidence. |

The chart uses only the generic player-column/shared-axis idea from the supplied reference. Its colors and visual styling were not copied. See the evidence README for the exact captures and commands.

## P12 scheduling and stacks — October 15, 2026

**Scope:** the seeded 12-round schedule and the three Twist pairs (Karera + Bomb-Taya, Karera + Kangaroo, Kangaroo + Bomb-Taya) on the opt-in `--match-route=lifecycle` development route. **Reviewer:** engineering run (AI-assisted); no independent human review, player session or physical-device input is recorded.

### Engineering session (synthetic)

| Verification | Result | Evidence / limit |
|---|---|---|
| Schedule tables, Twist rules, refusal, 2/3/4-seat full matches | **PASSED — 61 checks** | `run_p12_tests.gd`; [evidence](evidence/p12/README.md). |
| Bomb-Taya on Karera rules | **PASSED — 47 checks** | `run_p12_stack_tests.gd`. |
| Approved terminal-order table and the three pairs | **PASSED — 285 checks, 0 failures** | `run_p12_pairs_tests.gd` (90 controller scenarios incl. callback-order permutations, 195 real-room checks at 2/3/4 seats); [record](evidence/p12/p12_terminal_order_decision_table.md). |
| Rendered tour at 4 and 2 seats | **PASSED — 40 assertions, 26 captures** | `run_p12_pairs_interactive.gd`; synthetic seats and input. |
| Performance, heaviest stack (Kangaroo + Bomb-Taya, Storm, 4 seats, 40 pieces, 1080p) | p95 3.7 ms, worst 5.4 ms, 122.8 MiB, 0 orphans (3 runs) | One developer laptop; not a target-PC or release claim (P15). |
| Ten restarts | Node count 1301 → 1301, objects 4435 → 4435 | Real-room restart check. |
| Windows export + exported headless smoke | Exit 0 (default, `lifecycle`, `--open-room=p12_scheduled_match`) | Startup only. |
| Human, physical-device and balance acceptance | **NOT RUN** | No human players, observers or physical gamepads participated. |

### Human session sheet — P12 stacks (to be run by the team)

**Setup:** build from the delivered commit; `-- --match-route=lifecycle`; 2–4 players with physical gamepads and/or keyboard; one facilitator who does not coach; screen recording optional. Use a fixed seed first, then a fresh seed. Record the build, seed and devices below.

| # | Step | Ask the player | Pass if |
|---|---|---|---|
| 1 | Play a full 12-round match at 3–4 players. | "What is the next round? Say it before it starts." | Announced next round matches the round that starts, every time. |
| 2 | In a Karera + Bomb-Taya round, run to the flag with the taya countdown ticking. | "Who is the taya? What happens when time runs out? Does the flag still matter?" | Player explains taya and timer without help; understands the flag still ends the race. |
| 3 | In a Karera + Kangaroo round, miss a command on purpose, then fail three. | "Why were you out? Did anyone get points for it?" | Player names the failed commands; understands no one scores for the failure. |
| 4 | In a Kangaroo + Bomb-Taya round, let the taya time out and keep playing. | "Is this still Kangaroo? Who wins this round and why?" | Player describes one round with one result table. |
| 5 | Finish before the taya or command timer ends. | "Did you still get commands or tags?" | Finishers say they were safe and left alone. |
| 6 | Pause mid-stack, disconnect a device, resume. | "Did anything move while paused?" | No timer or command advanced during the pause; seat reclaim works. |
| 7 | Reach a level score after round 12. | "What decides this?" | Sudden death shows no Twist and the Bomb-Taya result decides it. |
| 8 | Ask each player to rate the stacked rounds. | "Too frequent? Too hard? Anything unfair?" | Notes recorded; no unexplained eliminations. |

### Intervention log (fill during the session)

| Time | Step | What the facilitator said or did | Why it was needed |
|---|---|---|---|
| | | | |

### Session record

| Date | Build / revision | Seed | Players | Devices | Pairs seen | Facilitator | Participant pseudonym | Result |
|---|---|---|---|---|---|---|---|---|
| | | | | | | | | |

## P13 UX, onboarding and accessibility — October 15, 2026

**Scope:** the player-facing UX pass on the scheduled full match (now the default route): menu routes, Lobby help, live HUD cues, a real Library, Kangaroo and Bomb-Taya just-in-time prompts, audio buses and Mute, Screen shake, the spectator cheer, and the keyboard chord recorder. **Reviewer for everything recorded below:** engineering run (AI-assisted). No spectator, novice, QA reviewer, physical gamepad or physical keyboard session has happened; the sheets below are the instruments for those sessions and **no human result is filled in**.

### Engineering session (synthetic) — Godot 4.7.2.stable.official.ed1daf0bf, Windows 11

| Verification | Result | Evidence / limit |
|---|---|---|
| Navigation matrix, K1 / K2 / synthetic gamepad, both routes | **PASSED — 205 checks, 0 failures** | `run_p13_navigation_tests.gd`: Title / Library / Settings / Quit confirm / Lobby help and Back / Pause owner and non-owner / Library and Settings from Pause (tree paused, clocks frozen, same Pause row on return) / confirmations / left-stick steps / held-press consumption / 10 overlay cycles stable. Synthetic input only. |
| HUD cue table on the scheduled route (3 Mains, 3 stacks, 2 and 4 seats) | **PASSED — 264 checks, 0 failures** | Historical pre-Barya `run_p13_hud_tests.gd` record; Barya N/A was asserted at that time. Current Barya-integrated HUD check (265) is in [Barya evidence](evidence/barya/README.md). |
| Library content, filtering, scrolling, controller navigation | **PASSED — 352 checks, 0 failures** | `run_p13_library_tests.gd`. |
| Kangaroo / Bomb-Taya just-in-time prompts | **PASSED — 55 checks, 0 failures** | `run_p13_tutorial_tests.gd`; existing tutorial suites unchanged (140 + 48). |
| Accessibility controls and audits | **PASSED — 65 checks, 0 failures** | `run_p13_accessibility_tests.gd`: buses, Mute, shake modes through the Settings path, stun brightness and Parol limits, glyph and display report. |
| Spectator cheer | **PASSED — 39 checks, 0 failures** | `run_p13_cheer_tests.gd`, including a 400-press spam run identical to a no-cheer run (scores, clocks, positions, commands, six random streams). |
| Keyboard chord recorder (tool) | **PASSED — 60 checks, 0 failures** | `run_p13_recorder_tests.gd`. Proves the tool, never a keyboard. |
| Rendered captures (1920×1080, 1280×720, 1920×800; 2 and 4 seats) | **96 captures** | [P13 evidence](evidence/p13/README.md). Agent inspection of screenshots is not a spectator, novice or QA result. |

### Findings the human reviewers should check first

- **Symbol glyphs:** the engine default font (Open Sans SemiBold) has no ● ▲ ■ ◆ → ↑ ↔. On Windows the engine falls back to a system font and the captures show them; a machine without a symbol fallback may show boxes (the number and the drawn shape badge remain). Final font is human-owned (Shanti).
- **Stun flash** was 8 Hz; it is now a smooth ≤ 2 Hz pulse (steady when Screen shake is Off).
- **Shake never reached the match** before this slice; it now follows the Settings value live. Default is Off.
- **Result chart statuses** were clipped by the no-score notice at 1080p/720p; the chart now reserves more room for them.
- **Release filter:** every family has `release_target = false`, so a literal release filter would list nothing. "Release browsing" here means *enabled by the active play profile*; reference content appears only with `--library-dev`.

### Common setup

| Item | Value |
|---|---|
| Build | delivered commit of this phase (record the SHA from `git log -1`) |
| Engine | `D:\Downloads\Godot_v4.7.2-stable_win64_console.exe` (4.7.2.stable) |
| Launch (default full match) | `& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!'` → Title |
| Reproducible seed | add `-- --match-seed=3` (seed 3 reaches Kangaroo in round 6) |
| First-playable gate build | add `-- --match-route=first_playable` |
| Library development mode | add `-- --library-dev` (marks reference content "not playable") |
| Keyboard recorder | `& '...console.exe' --path 'tilaok!' res://scenes/tools/key_chord_recorder.tscn` |

### Sheet A — P02-T03 / P02-T04 physical keyboard chords (recorder)

**Who:** the owner, on the keyboard that will be used. **Fill in:** keyboard model, layout name (the recorder prints it), connection, date.

1. Launch the recorder. For each chord (C01–C24) hold all the shown keys together for about half a second. A chord is **PASS** the moment every key is down at once and the recorder moves on by itself.
2. If the keyboard cannot report all of them, press **Insert** (LOST); try the chord once more first. **Page Down** skips, **Page Up** goes back, **Home** restarts.
3. Press **F2**: the report is printed and saved under `%APPDATA%\Godot\app_userdata\Tilaok!\p13_key_chords_<time>.txt`. Paste it into the chat or below.

**Pass:** every chord the game supports is PASS. Any LOST chord must be remapped, documented as unsupported or excluded from the supported claims (record which, here). The recorder tests the keyboard and operating system only.

| Chord | PASS / LOST | Decision if LOST (remap / unsupported / excluded) | Notes |
|---|---|---|---|
| | | | |

### Sheet B — P13-T02 physical navigation matrix

**Setup:** two identical gamepads (P02-T07/T08 procedure) plus K1 and K2; one participant per device. **Observer fields:** device, route, result, trap seen, stray game input seen.

| # | Route (start from Title unless stated) | Device kinds to run | Pass if |
|---|---|---|---|
| 1 | Join, Start, ready, **Help** (Lobby), Back to the Lobby, Back (confirm appears, No keeps, Yes returns to Title) | each pad, K1, K2 | the press that opened a screen never also acts on it; confirm defaults to No |
| 2 | Title → Library → every category and entry → Back | each | entries scroll, Back is zone-aware, returns to Title |
| 3 | Title → Settings → every row (shake, reveal, Mute, four volumes) | each | every row adjustable, Back returns |
| 4 | Title → Quit (No, then Yes) | each | Yes quits once; No restores the menu |
| 5 | In a match: pause with one seat, then with a different seat | pad Start, Esc | only that seat's owner drives the menu; others can only ready |
| 6 | Pause → Library → Back → Settings → Back → Resume | owner device | simulation stays frozen; returns to the same Pause row |
| 7 | Pause during the resume countdown, try to open Library | owner device | Library cannot open during the countdown |
| 8 | Pause → Leave (No, Yes) | owner device | returns the whole group to the Lobby with its seats |
| 9 | Round result: ready, wait for the 8 s advance | each | no stray jump / placement on the next phase |
| 10 | Match result: Replay, Return to Lobby, Quit (confirm) | owner device | one action needs every original seat ready |
| 11 | Unplug and replug a pad mid-round | pad | seat reclaimed, timers unchanged |

### Sheet C — P13-T04 spectator identification

**Setup:** a 4-player match played by others; observers only watch the screen with **sound muted**, **Screen shake Off** and the stage crowded (late rounds). At least three observers who are not playing. **Fields:** observer pseudonym, round, mode / stack on screen.

| Ask (each, glance up to 5 s) | Answer | Correct? |
|---|---|---|
| What phase is it (Pugad / Place / Play / results)? | | |
| What is the goal this round? | | |
| Who is leading? | | |
| Who is the taya (if any)? | | |
| Who won the round or the match? | | |
| If nobody scored, why not? | | |
| What happens at the next round? | | |
| With two command rings overlapping, which commands are active? | | |

**Pass:** every observer answers every question correctly from the screen alone, without asking the players.

### Sheet D — P13-T08 novice session (guided first match, Lagsanay and Kangaroo)

Use the existing [novice sheet](#p13-t08-novice-session-sheet--guided-first-match-2026-10-14) for the guided Karera. **Additions for this build** (default route is now the scheduled full match):

| # | Ask or watch | Record |
|---|---|---|
| 10 | Play on with `-- --match-seed=3`. Before round 6 (Kangaroo) does the coach show the three slipper poses (Pugad) and the build-up prompt (Place)? | seen / not seen; what the participant said |
| 11 | During the Kangaroo round: "What are KANG, GA and ROO?" | verbatim; understood three misses? |
| 12 | In a Bomb-Taya round: "Who is the taya? Does the flag still matter?" | verbatim |
| 13 | Did a prompt ever cover something needed (the box, the command cards, the miss grid)? | what, when |
| 14 | Replay: Library → How to Play → Replay tutorial; are the Kangaroo prompts shown again before the next Kangaroo? | yes / no |
| 15 | Close the game; check `%APPDATA%\Godot\app_userdata\Tilaok!` for files created by the tutorial or settings. | none |

Record every facilitator intervention in the intervention log of the existing sheet.

### Sheet E — P13-T10 QA readability at minimum zoom

**Setup:** 4 players, sound **muted**, Screen shake **Off**, camera at its minimum zoom (chickens at opposite ends), crowded stage (late round), Kangaroo + Bomb-Taya with Storm and a Parol overlap on a lab build. **QA reviewer:** name and date.

| Check | Result | Notes |
|---|---|---|
| All four players identifiable (number and shape) at all times | | |
| Taya identifiable | | |
| Each command (Freeze, Rising wave, Hug) identifiable muted | | |
| Overlapping command cards stay distinct; two active commands readable | | |
| KANG → GA → ROO misses readable per seat | | |
| Placement valid / invalid / reason readable | | |
| Secured / eliminated / cheer states readable | | |
| No effect that flashes more than 3 times a second (Parol, stun, explosions) | | |
| HUD text readable at 1280×720 and 1920×1080; safe area respected at 1920×800 | | |
| Symbol glyphs render on this PC (● ▲ ■ ◆ → ↑ ↔) | | |

### Sheet F — P13-T12 cheer check (needs Sheet A first)

**Setup:** one keyboard owner (K1: **R**, K2: **Right Shift**, gamepad: **West**). Play until one seat is eliminated and one has finished.

| # | Step | Pass if |
|---|---|---|
| 1 | Eliminated player presses their cheer control | "CHEER!" appears in their own HUD row and a soft crowd sound plays |
| 2 | Finished player presses it | same |
| 3 | A live player presses it | nothing happens, no movement, no message |
| 4 | Hold or mash the control | at most one cheer per second per player; no key-repeat bursts |
| 5 | Watch scores, timers, other chickens and command cards during the spam | none change; the HUD row text is the only change |
| 6 | Press it in Pugad and Place | it does the normal Rotate / claim behaviour only; no cheer |
| 7 | Pause, press it | nothing |
| 8 | Check the cue never hides the live HUD | HUD fully readable |

Record the date, device, build, who observed and the result under each sheet; **never fill a result in by inference.**

## Barya technical verification — October 15, 2026

This is engineering evidence for the user-approved optional Barya implementation, not a human playtest or release acceptance. The default player route is the scheduled P12 full match (`route=lifecycle`); P07 remains available by `--match-route=first_playable` with Barya disabled. The P12-only `--barya-disabled` flag is the rollback check.

| Field | Record |
|---|---|
| Engine | Godot 4.7.2.stable.official.ed1daf0bf, explicit console executable at `D:\Downloads\Godot_v4.7.2-stable_win64_console.exe` |
| Date / machine | 2026-10-15 · Windows · Intel i5-13420H · NVIDIA RTX 4050 Laptop GPU |
| Route / profile / seed | Default P12 scheduled match and P12 harness room; `karera_slice`; seed 12345; tests force only the Main/Twist under scenario |
| Seats / input | Two seats for the full loop; 2/3/4 seats for P12 stack and score matrices; four seats for the live performance sample. Synthetic keyboard/gamepad identities only. |
| Physics / reviewer | Real Godot Area2D/PhysicsServer overlap snapshots and controller roots; terminal candidates scripted by the engineering runner. Reviewer: Codex AI-assisted engineering run; no human reviewer. |

**Procedure / expected / actual:** ran the deterministic offer/eligibility and egg-pool tests; claim, placement protection, timeout, cap and disabled-seed-parity checks; contested and duplicate pickup through actual Area2D physics; attachment/capture, committed death drop and deterministic recovery, next-step pickup gate, reclaim, same-step terminal ordering, committed score receipt, all-finish 2/3/4-player exception, results/history and cleanup; and both Karera stacks across 2/3/4 seats. Expected one eligible coin at most, no Pugad-size or construction-cap change, only committed finisher payouts, and round cleanup without persistent residue. Actual: 72 focused assertions passed; the rendered capture invocation passed 80 assertions including eight saved-view assertions. Fourteen regression suites passed with zero failures: Barya 72, P05 137, Place/claim 15, blocks 111, P06 102, P09 77, P12 61, P12 stack 47, P12 pairs 285, P07 591, HUD 265, Library 368, tutorial 58 and scoreboard 52. Full raw results are indexed in [Barya evidence](evidence/barya/README.md).

Eight 1280×720 captures cover Pugad offer, Place lock, coin available, carrier, recovered death drop, re-claim, secured finish and results award. These use synthetic input; the overlaps came from Godot physics. A four-seat windowed 1280×720 sample, 120 warm-up plus 300 measured frames, with a carried coin and 41 persistent construction items measured 1.976 ms median / 2.836 ms p95 / 3.881 ms worst, 120.55 MiB static memory, and 5 µs synchronous cleanup (queue-free drained after one process and physics frame); 0 orphan nodes remained. It passed the documented 16.67 ms / 512 MiB local engineering budgets. This is one local machine and does not establish target-PC performance.

The Windows Desktop debug export and exported console-wrapper startup smoke passed for the default lifecycle route, direct P12 harness room with Barya on and with `--barya-disabled`, and the P07 first-playable route. This establishes export/startup only, not a clean-PC package review. Full logs, procedure, captures and exact command lines are in [Barya evidence](evidence/barya/README.md).

**Still open:** human gameplay/comprehension, physical keyboard/controller, QA/accessibility and minimum-zoom review, balance and cultural review, production art/audio, individual owner/capacity assignment, target-PC performance, independent reviewer, P00-T04 release-manifest ratification, and other release gates. No outcome is inferred for these sheets.
