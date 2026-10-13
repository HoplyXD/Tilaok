# Tilaok! Verification and Playtest Plan

_Originally a plan only on 2026-10-12. P02, P03 and P04 implementation/evidence were added on 2026-10-13; this is not a full game or release playtest._

## Current verification status

P01 provides a Godot 4.7.2 foundation harness; P02 adds a playable run/jump and input diagnostic room; P03 adds the bounded graybox stage, camera and support contracts; P04 adds the item infrastructure and the Kaing/Tulay seeds in an Item Lab. These are development slices, not the lobby-to-match game. Hardware coverage, player feel and late-game performance limits remain explicit. Historical P00 results remain below; P01/P02/P03 evidence follows them.

| Check | Status | Evidence / limit |
|---|---|---|
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
8. **Scoring/ownership:** one terminal outcome per player; no duplicate award; self-elimination gives no Patibong; competing same-step contacts produce stable ownership; goal/death same-step ordering; exact indistinguishable Karera flag ties award Una to every tied first finisher; Main-Challenge scoring family remains authoritative during a Twist; Barya race-only; too-easy/too-hard suppression; Bawi; placement ties with exact eighth-point precision; and simultaneous final Lagsanay eliminations. Confirm that the latest recorded elimination wins and that an exact timestamp tie uses the lowest player slot/ID, with the “Last Cluck!” result callout.
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
| Scoring | One outcome/award per player; race all/none finish, 2-player waiver, underdog snapshot, goal/death tie and exact legal averaged placements pass |
| Slot advantage | Repeat identical contact/tie geometry after swapping slots/devices; report deterministic rule bias separately from player skill; inactive proposals require acceptance before replacement tests |
| Wave explanation | Each support-table case gives correct pass/fail; players can state whether failure was height, provenance or contact; test just above/on/below every line |
| Freeze/stacks | Reproduce off-support Freeze+wave and low-timer Freeze+taya scenarios under current rules; record unavoidable choice without silently enabling R3/R4 |
| Chain control | Record every input-suppression interval and escape opportunity; unavoidable repeated capture blocks that item/event enablement |
| Pause/device lifecycle | All gameplay clocks/hazards stop; identity and timers preserved on reconnect; all-ready countdown cannot leak movement or jump presses |
| Restarts | Ten round resets and later ten match restarts: no retained capture/projectile/immunity/score state; persistent stage resets only when intended |
| Readability | At all four corners/highest construction, live targets and relevant hazard/support cues remain legible; no hidden off-camera active player |
| Performance | Exported 1080p: measure median/p95/worst frame time against 16.67 ms target, process memory against provisional 512 MiB; record hardware and caps, no gameplay network traffic |

Change only one related group (for example jump height/apex and derived gravity, not unrelated score values). Preserve the original named baseline; write hypothesis, changed keys, expected result and observed result. Reproduce hard defects immediately. For feel changes, seek the same issue across at least two sessions/participants and repeat the same trials after adjustment. These small samples justify iteration, not statistical claims of competitive balance. No public telemetry/backend is needed; local notes and optional clips suffice.

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
