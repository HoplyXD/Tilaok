# Tilaok! Verification and Playtest Plan

_Plan only, 2026-10-12. No runnable project or observed gameplay results were present when this document was written._

## Current verification status

The repository contains a Godot project skeleton at `tilaok!/project.godot` and its project icon, but no scenes, scripts, test framework, export preset, gameplay assets, or configured build pipeline were found. The user identifies Godot 4.7 in `D:\Downloads` as the intended toolchain and the current PC as the target. A fresh isolated-copy import with Godot 4.7.2 completed with exit code 0 and no logged warnings/errors. A separate editor initialization against the working project exited 0 but emitted an engine error and shutdown-thread warning; both outcomes are recorded below. Neither check demonstrates a playable build: no gameplay, item harness, controller test, or performance baseline exists.

| Check | Status | Evidence / limit |
|---|---|---|
| Historical headless project initialization/import | **PASSED** | `godot --headless --path "tilaok!" --editor --quit`, Godot 4.6.3; completed filesystem scan, icon import, and editor initialization with no errors/warnings in the captured historical output. This is not target-engine validation. |
| Target Godot 4.7.2 fresh import | **PASSED** | Godot 4.7.2 imported `icon.svg` in a fresh temporary copy using `--headless --path <isolated-copy> --import --quit`; exit code 0, no warnings/errors. [Full log](evidence/p00-clean-import-godot-4.7.2-2026-10-13.log). |
| Godot 4.7.2 editor initialization on working project | **FAILED** | `--headless --path "tilaok!" --editor --quit`; exit code 0, but output includes `ERROR: Parameter "singleton" is null` and a thread-shutdown warning. [Full log](evidence/p00-import-godot-4.7.2-2026-10-13.log). Do not treat this invocation as clean editor verification. |
| Runtime/gameplay, item harnesses, local multiplayer | **COULD NOT RUN** | No scenes or scripts exist. |
| GDScript lint/format | **COULD NOT RUN** | No GDScript paths exist. |
| Export / exported Windows build | **COULD NOT RUN** | No `export_presets.cfg` or entry scene; installed templates report `4.7.stable`, which does not match the selected editor's `4.7.2.stable` version identifier. Matching templates are absent. No temporary export fixture was created. |
| Physical keyboard/controller validation | **COULD NOT RUN** | Windows enumerated keyboard devices but no gamepad/controller; keyboard model/layout and actual button mapping are unknown. Device enumeration is not an input test. |
| Playtest/performance baseline | **COULD NOT RUN** | No runnable gameplay. The user selected the current PC as target; specs are recorded in `PRODUCTION.md`, but performance remains unmeasured. |

## P00 production-readiness evidence

**Date:** October 13, 2026.

**Inspection revision:** `fa6145839bff96ecb6e1afdb112e804bfb72260f` (`origin/main` before P00 documentation edits). The intended console executable reports `4.7.2.stable.official.ed1daf0bf`. The user-reported current PC target and observed system inventory, all discovered Godot executables, template paths, lint tools, and missing export setup are recorded in [PRODUCTION.md](PRODUCTION.md#p00-baseline-record).

The clean target import used a temporary copy of `project.godot`, `icon.svg`, and `icon.svg.import`, avoiding any claim that gameplay or a production build was tested. It completed filesystem scan and icon reimport with no warnings/errors. The direct editor invocation on the working checkout is retained as a separate failed diagnostic; it returned exit 0 but logged both an error and warning. A cached import repeat is preserved in [its log](evidence/p00-import-only-godot-4.7.2-2026-10-13.log). No export was attempted because there is no export preset or entry scene and matching 4.7.2 templates are absent.

Observed machine details do not establish which physical keyboard layout or controllers the team will use. No controller was found in the queried Windows device inventory. Button/axis mapping, rollover, simultaneous input, reconnect behavior, and multi-controller ownership remain untested. Performance budgets remain UNMEASURED.

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

### Team-written project checks (when available)

1. **Project/controls:** launch via documented Godot version; join local 2, 3, and 4 players; test gamepad-first and shared-keyboard fallback. Record physical-device limitations. Check run/jump only during Play and input deadzone behavior.
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

The prototype experiments and current documentation verification follow below; all implementation-dependent checks remain pending.

When a project exists, append date/build and a table containing check, status, evidence, player count/input, and defect reference. Report actual logs, including new warnings/errors, and unresolved output. Export checks may be run only if the repository has a verified preset and matching installed templates. Headless import does not replace runtime playtesting. Never tick an unrun check.

## Prototype test session and change discipline

**PROTOTYPE — UNTESTED.** Baseline values are centralized in PROTOTYPE_DEFAULTS.md; geometry/support are in STAGE_AND_PLACEMENT.md. Do not copy tunables into this checklist. Registered team members implement the harness and core mechanics.

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

## Documentation verification — completed 2026-10-13

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

No team milestone is marked complete by this documentation work.
