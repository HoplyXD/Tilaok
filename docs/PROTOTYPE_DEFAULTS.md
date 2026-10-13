# Tilaok! Prototype Defaults and Team Handoff

**PROTOTYPE VALUES — NOT BALANCE-APPROVED.** Prepared 2026-10-12; documentation verification completed 2026-10-13. The standing AI-assisted programming workflow is recorded in `AI_USAGE.md`; P01/P02 assistance history and verification limits are recorded there and in `PHASETASK.md`. This programming authorization does not prove balance, constitute human review, or establish competition eligibility. The wall-movement extension below was approved October 13, 2026; its rule choices are active design direction, while numeric starting values remain untested. Other proposed rule changes remain inactive until explicitly accepted.

## 1. Recommendation and evidence

Start with responsive run/jump controls, a compact graybox, explicit device assignment, and Kaing Stack plus Tulay na Kawayan. Prove a two-player build/race round before adding Gulong Talon, then verify three/four players, Lagsanay, full-match ties/restart, Kangaroo, and finally the three required event stacks. Use an explicit surface-support property for Rising wave. Centralize tunables; keep art, new events, and extra obstacle families out of the first slice.

Decision labels throughout:

- **C — CURRENT CONTRACT:** preserve documented intent; it is not test evidence.
- **P — PROTOTYPE DEFAULT:** recommended starting point, cheap to revise.
- **R — PROPOSED RULE CHANGE:** differs from the current contract; inactive pending explicit approval.
- **D — DEFERRED:** not needed at the indicated milestone.
- **U — UNKNOWN FACT:** team information, never invented.

### Repository facts at the October 12 inspection (historical)

On October 12, `git status --short`, remote/branch/history inspection, `rg --files`, CLI version checks, and the merged-PR query were run. The source branch is `feat/filipino-obstacles-events`; its HEAD and the remote main verified by `git ls-remote` were `791084a75ca06b3d130f3bacf58a29eb88356b59`. Remote: `https://github.com/HoplyXD/Tilaok.git`. The merged-PR query returned `[]`; that is the query result, not proof of all historical development activity.

The source checkout has modified CLAUDE.md, README.md, GDD.md and ROADMAP.md and ten untracked documentation/guidance files. No source checkout changes were made by this task. The project skeleton exists, but no `.gd`, `.tscn`, or `.scn` gameplay files were found. `tilaok!/project.godot:14` declares 4.7; installed `godot --version` is `4.6.3.stable.official.7d41c59c4`; gdlint and gdformat are 4.5.0. No engine setting was changed.

| Area | Documented rules | Implemented system |
|---|---|---|
| Project | EXISTS: engine/platform intent | PARTIAL: project/icon only |
| Controller | PARTIAL: run/jump and pass-through contact | At inspection: NONE; P02 diagnostic controller and independent sensor now exist, with measured results below |
| Input/lobby | PARTIAL: flow, no device/binding policy | At inspection: NONE; P02 seat routing/pause implementation exists; physical device checks remain open |
| Loop, placement, scoring | EXISTS: detailed contracts | NONE |
| Stage/camera | PARTIAL: geometry deliberately pending | NONE |
| Items/events/support | EXISTS: catalog and event contracts; tuning partial | NONE |
| Configuration/tuning | PARTIAL: centralization requested | NONE |
| Production | PARTIAL: workstreams and gates; owners/equipment TBD | NONE: no build pipeline found |

Source-checkout evidence at inspection: [GDD.md:14](GDD.md#3-core-loop-every-round) (eggs/timers), GDD.md:63–74 (tag/contact), GDD.md:89–101 (commands/Storm), GDD.md:120 and :149 (ties), [STAGE_AND_PLACEMENT.md:29](STAGE_AND_PLACEMENT.md#base-stage-requirements) (geometry pending), STAGE_AND_PLACEMENT.md:87–93 (wave), [ITEMS.md:42–53](ITEMS.md#provisional-logical-grid-matrix) (footprints), [PRODUCTION.md:15–32](PRODUCTION.md#role-assignment-sheet) (owners/dependencies), UI_TUTORIAL.md:143–149 (input decisions), ROADMAP.md:18 and :28 (dependencies/freeze). Line numbers refer to the inspected source before this handoff's additions.

Networking: **N/A**, local only; target 0 B/s gameplay traffic. Save impact: **none**. Optional local win tally is session memory only for this prototype; no disk persistence or new save system.

## 2. Controller, scale, and contact

Dependency order: jump height/apex time → gravity/impulse → collider clearance and grid → reachable platform gaps/height → stage bounds → camera/readability. Input thresholds feed both locomotion and Freeze. Actual post-movement support feeds wave evaluation; coyote permission is never support. Forced movement feeds collision but is separate from intentional input. Retune these groups together when one affects the others.

All distances are world units (wu), provisionally equal to unscaled 2D pixels; this is not a final art resolution. Positive x is right, positive y is down. Use a 60 Hz simulation target for repeatable timing; verify actual team implementation rather than relying on engine defaults.

| Decision/key | Label; starting value and experimental range | Reason / main drawback | Experiment and change trigger | Confidence |
|---|---|---|---|---|
| `grid.cell_wu` | P: 32 wu; 24–40 wu only with proportional geometry review | Simple construction; changing it affects every footprint | Test 1-cell footholds/2-cell headroom; resize only if readable collisions cannot fit | Medium structural, low feel |
| `move.body_size_wu` | P: 24×48 wu; 22–26×44–52 wu, within 32×64 clearance | 1×2-cell clearance with margins; narrower than art may feel generous | Edge/ceiling runs; change if visible feet repeatedly disagree with collision | Low |
| `move.jump_height_wu`, `apex_s` | P: 96 wu and 0.32 s; 80–112 wu, 0.28–0.38 s | Clears useful 2-cell rises with reserve; cannot clear a 3-cell solid safely | Ten 2-cell rises per player; revise if controls cause >20% misses after practice | Low feel; high arithmetic |
| `move.run_speed_wu_s` | P: 280 wu/s; 240–320 | Fast across compact stage; less reaction time at upper end | Marked landing/stopping trials; lower if repeated unintentional overshoot persists | Low |
| `move.ground_accel_wu_s2` | P: 2400 wu/s²; 1800–3200 | Quick starts; limited weight | Start/stop trials; increase if late starts feel unresponsive | Low |
| `move.brake_wu_s2` | P: 2800 wu/s²; 2200–3600 | Short recoverable stops; may feel abrupt | Stop before ledge; change if >20% unintentional falls or movement looks discontinuous | Low |
| `move.reverse_wu_s2` | P: 3200 wu/s²; 2400–4000 | Distinct quick reversal; less momentum commitment | Alternate targets; revise if reversal frequently misses intended landing | Low |
| `move.air_accel_wu_s2` | P: 1600 wu/s²; 1000–2000; same air reversal rate | Midair corrections; weakens commitment | Compare landing corrections and deliberate long jumps | Low |
| `move.air_neutral_drag_wu_s2` | P: 0; compare 0–400 | Predictable momentum; releasing direction does not stop flight | Explain then test; add drag only if misunderstanding persists | Low |
| Derived ascent gravity/impulse | P: 1875 wu/s² down; jump velocity −600 wu/s; derive from height/time, never tune independently | Coherent arc; discrete collision differs from ideal model | Measure actual apex; investigate >2 wu or >1 physics-step deviation | High arithmetic |
| Falling gravity / terminal speed | P: 1.35× ascent = 2531.25 wu/s²; cap +900 wu/s; multiplier 1.1–1.6, cap 800–1100 | Crisp descent; less late correction | Drop/landing tests; reduce multiplier if timing window is too unforgiving | Low |
| Variable jump | P: while rising after release use 2.5× ascent gravity; range 2–3×; once descending use fall gravity | Short hops plus full jumps; extra learned timing | Ten taps/holds; reconsider only if players cannot distinguish heights | Low |
| `move.coyote_s`, `buffer_s` | P: 0.10 s each; 0.07–0.13 s | Forgives timing; long windows can feel like air jumps | Ledge and pre-landing presses; reduce if ghost jumps become visibly confusing | Medium rationale |
| `contact.sensor_size_wu` | P: 28×48 wu centered on body; width 24–32 wu | 2 wu expansion per side, readable near-contact; may appear early | Stationary, edge and crossing tests; reduce if visible gaps seem too large | Low |
| `contact.pass_back_s` | C/P: 1.0 s; 0.75–1.25 s | Stops immediate retaliation; temporary immunity can be exploited | Pursuit and overlap trials; change if repeated back-and-forth or no counterplay | Low |

The measured P02 baseline controls are left/right and jump only; that historical implementation had no wall jump, dash, double jump, or drop-through. The separately approved wall extension is implemented, enabled by default as core movement (owner decision, 2026-10-13) and measured only in synthetic fixtures (below). Neutral air input preserves horizontal speed; active air input approaches the signed run-speed target at the air acceleration rate. Ground reversal uses the reversal rate until the new target is reached. Consume each buffered press once; holding jump does not auto-repeat jumps. Clear coyote permission after a jump, launch, capture, or terminal outcome.

### Wall movement — approved Should extension

**Approved behavior, not implementation:** airborne actual contact with an eligible solid side enters a downward slide without requiring directional hold. Cap downward speed only. A fresh jump press kicks away once; allow immediate air steering. Require separation and fresh recontact before a repeat. Wall contact is not floor/ground/support contact. External launch preempts and clears wall eligibility and pending wall input; terminal > opening freeze > capture > forced motion > locomotion remains the state order. Pause freezes the action; phase/reset/reload clear stale contact and buffered input. Pass-through chicken bodies remain unchanged. See GDD, PRD REQ-MOVE-004 and PHASETASK P02-T15–T22.

Only solid sides identified as eligible wall surfaces qualify: base and player-built solids, plus moving solids while their actual contact remains valid. Exclude one-way platform sides/undersides, triggers, ineligible hazard/effect surfaces, chickens and arena containment boundaries. A sensor overlap alone is insufficient. Wall contact must never publish upward support or Rising-wave eligibility.

| Candidate tuning key | Starting candidate (unmeasured) | Experiment range / purpose |
|---|---:|---|
| `move.wall_slide_fall_cap_wu_s` | 120 wu/s downward | Compare 80–180 wu/s; measure descent over marked wall heights and review whether escape remains possible. |
| `move.wall_jump_horizontal_wu_s` | 240 wu/s away | Compare 180–300 wu/s against the 280 wu/s run speed; test horizontal clearance and steering return. |
| `move.wall_jump_vertical_wu_s` | −520 wu/s | Compare −440 to −600 wu/s against the −600 wu/s normal jump impulse; measure height/time and ceiling/bounds risk. |
| `move.wall_jump_contact_grace_s` | 0.08 s | Compare 0–0.12 s; a fresh press just before contact may be buffered briefly, but held input never auto-repeats. |
| `move.wall_jump_recontact_separation_wu` | 8 wu clear gap | Compare 4–16 wu; require observable physical separation before another kick on the same wall. |

These values now live in `tilaok!/scripts/config/gameplay_tuning.gd` (`wall_movement_enabled`, `wall_slide_fall_cap_wu_s`, `wall_jump_horizontal_wu_s`, `wall_jump_vertical_wu_s`, `wall_jump_contact_grace_s`, `wall_jump_recontact_separation_wu`, plus `wall_contact_probe_wu` 1 and `wall_normal_tolerance_degrees` 10) with unchanged starting values; first synthetic-fixture measurements follow and are not feel or balance evidence. They are candidates for centralized configuration, not finalized parameters or balance claims. Run real Godot collision trials, rendered sessions and human feel/balance review. Compare route completion, unintended falls, ceiling/bound escapes, repeat-climb time, and players' ability to understand the contact/recontact rule. Do not change normal ground-jump tuning just to make wall movement pass.

#### Wall movement runtime measurements — October 13, 2026

Build `9ee25c8` + working tree; Godot `4.7.2.stable.official.ed1daf0bf`; P02 movement room and P03 stage; seed 12345; 60 Hz; synthetic input; [log](evidence/p02-wall/2026-10-13_wall_tests.txt). Values are the unchanged starting candidates, not tuned or balance-approved.

| Measurement | Expected | Observed |
|---|---:|---:|
| Slide speed, wall on left / right | 120 wu/s cap | 120.00 / 120.00 wu/s |
| Kick velocity (K1 / K2 / gamepad) | 240 away, −520 up | vx 240.00; vy −457.50 two ticks after the kick (−520 + 2×31.25) |
| Kicks per fresh press | 1 | 1 (all three device types) |
| Kicks over a 1 s held press with OS repeats | 1 | 1; echo alone 0 |
| Same-contact second press | blocked | blocked; lock cleared at a 12.10 wu gap |
| Steering after kick (3 ticks toward wall) | immediate | vx 240 → 160 wu/s |
| Kick rise, jump held / released | ≈72.1 / lower | 72.07 / 33.84 wu |
| Enabled full ground jump apex | 96 ± 2 wu | 96.06 wu |
| Two-wall 64 wu shaft, 240 frames | measured only | 34 kicks; reaches the room ceiling; −2.0…+24.5 wu per cycle |
| Kick + launch (±480,−900), (0,−900), (480,0) | inside bounds | contained in all four P02-room trials; P03 camera visible, peak y 264.08 |

One-way Tulay: pass through underside/sides; land on its upward top only when descending relative to it and crossing the top from above. Start with horizontal 4×1-cell footprint and 4 wu visible/collision top strip; vertical orientation stays disabled because the existing contract makes it conditional on controller support. Leave via an edge or jump. Keep footprint reservation distinct from collision strip. Kaing starts with 1×1 and 2×3 variants (equal conditional weights), 90° rotation where shape changes. Other approved variants remain deferred, not deleted.

### Mathematical check — not a collision test

Choose H = 96 wu and t = 0.32 s first:

- g = 2H/t² = **1875 wu/s²**.
- Jump-speed magnitude = gt = **600 wu/s**.
- Full-hold descent to takeoff height = sqrt(2H / 2531.25) = **0.2754 s**.
- Full airtime = **0.5954 s**; full-speed horizontal displacement = **166.7 wu = 5.21 tiles**.
- Full jump reaches the starting height at about 697.1 wu/s downward, below the 900 wu/s terminal cap.
- Ground time to 280 wu/s = **0.1167 s**; acceleration distance = **16.33 wu**.
- Braking time = **0.10 s**, stopping distance v²/(2a) = **14 wu**.
- Reversal +280 to −280 = **0.175 s** at 3200 wu/s².
- From zero horizontal speed while jumping, air acceleration reduces ideal reach to about **142.2 wu**.
- Immediate jump release gives ideal height **38.4 wu**, airtime **0.3022 s**, and full-speed displacement **84.6 wu**; real taps depend on sampled release time.
- Landing 64 wu above takeoff occurs on descent at **0.4790 s**, giving **134.1 wu** ideal displacement.

Assumptions: level takeoff, full hold unless stated, no obstruction, no moving platform/force, maximum speed maintained, and continuous equations. Margins include body width and landing control, not merely gap width. A 64 wu gap with each center 20 wu inside the respective edge needs 104 wu travel: a comfortable candidate even at a 64 wu rise. A 96 wu level gap with the same margins needs 136 wu: an advanced candidate. Do not describe 166.7 wu as a safe gap. At the October 12 documentation inspection, all actual reachability was **UNTESTED**. P02 later measured the dedicated 64 wu gap + 64 wu rise in a collision fixture; see the dated implementation evidence below. Other stage reachability and balance remain untested.

### P02 runtime measurements — October 13, 2026

Build: local P02 implementation based on `e2b4a555e8d45bec774ffebde7c46e595cd3abdb`; Godot `4.7.2.stable.official.ed1daf0bf`; movement fixture; seed 12345; 60 Hz. `docs/evidence/p02-checks-2026-10-13.log` records physics output; `docs/evidence/p02-diagnostic-room.png` is the rendered fixture; `docs/evidence/p02-rendered-metrics.txt` records the separate rendered frame/memory sample.

| Measurement | Expected | Observed fixture result |
|---|---:|---:|
| Full jump apex height/time | 96 wu / 0.32 s | 96.06 wu / 19 physics frames (0.3167 s) |
| Short released jump | Lower than full jump | 44.27 wu |
| Run | 280 wu/s | 280.00 wu/s; 120.00 wu displacement over 30 physics ticks |
| Ground braking | Provisional stopping distance 14 wu | 11.67 wu; speed reached 0 |
| Ground reversal | Provisional model crosses in about 11 ticks | Crossed zero in 6 ticks |
| 64 wu gap + 64 wu rise | Land on the raised platform | Landed at x=871.34, y=273.93 in the dedicated fixture |
| External launch jump release | Release must not shorten launch | 101.12 wu with jump released and held, on an unobstructed path |

These results establish behavior only in this small authored collision fixture, not player feel, complete arena reachability or balance. The first launch comparison intersected overhead geometry; that invalid trial was replaced with a clear path and not used as evidence. No tuning values were changed from their provisional defaults.

### P03 graybox route, camera and support measurements — October 13, 2026

**Build/profile:** `P03-graybox-dev`, working tree based on `4cb31a9`; Godot `4.7.2.stable.official.ed1daf0bf`; `movement_room`; seed `12345`; 60-Hz physics. **Machine:** Windows, 13th Gen Intel Core i5-13420H (12 logical CPUs), NVIDIA GeForce RTX 4050 Laptop GPU, Godot Compatibility renderer. **Input:** synthetic fixtures; no physical controllers or keyboard rollover were certified.

| Measurement | Expected | Observed |
|---|---|---|
| Base stage route | Actual collision path floor → A → B → C → D → goal | Passed with the P02 controller; no teleport between route platforms; final goal position `(1012,360)` wu and still within bounds. Head/body clearance, takeoff, landing and braking assertions passed. |
| Spawn origin conversion | Controller feet begin on floor top at y=480 wu | Feet `(96,480)` convert to center `(96,456)` wu for the 48-wu controller. No geometry or movement tuning was changed. |
| Maximum camera launch | Keep identity/body extents visible through the configured 900-wu/s upward launch | Camera target top reached y=208.38 wu within 36 physics frames; full target remained inside the HUD-safe viewport throughout. |
| Camera target fitting | Full extents visible at 2/3/4 targets; highest legal preview at y=96; bounded zoom 1.0–1.4 | Assertions passed. 1920×1080 Play/Place captures ran at zoom 1.0. A 1920×800 window kept a 1280×720 logical viewport; no extra world was exposed. |
| Support tolerance | Actual upward eligible contact only; one-wu height/contact tolerance, no grace | Real collision fixtures passed above/on/below sample lines y=384/320/256 wu, same-step support removal, moving contact, and the full support-state matrix. These lines are test fixtures, not event band settings. |
| Render throughput/memory | Median/p95/worst ≤16.67 ms; process memory ≤512 MiB | 600 uncapped rendered frames at 1920×1080, v-sync off: median 0.826 ms, p95 1.426 ms, worst 6.141 ms; Godot static memory 67.60 MiB; sampled Windows process peak working set 199.91 MiB/private bytes 250.59 MiB; elapsed 0.544 s. |

Exact tests, captures and results are in [P03 verification evidence](evidence/p03/2026-10-13_p03_verification.md). These fixture measurements do not establish player feel, final-art readability, late-game stress, release readiness, or balance. No gameplay networking is instantiated by this local fixture; the sample is not a network-throughput test.

### P04 item infrastructure measurements — October 13, 2026

**Build/profile:** `P04-item-lab-dev`, `main` @ `765ed09` + P04 working tree; Godot `4.7.2.stable.official.ed1daf0bf`; `karera_slice`; seed `12345`; 60-Hz physics; synthetic input. **Tunable location:** every item knob is an `item_*` field in `tilaok!/scripts/config/gameplay_tuning.gd` (caps 48/16/2 per emitter/4/1/1/32, TTL 3/4/2 s, grace 1.0 s, Tulay strip 4 wu, vertical gate false, family weights 50/50, enabled variants); footprints, regions and rotations are typed `.tres` definition data in `tilaok!/data/items/`.

| Measurement | Expected | Observed |
|---|---|---|
| Ten Play/round-end cycles, three pieces + test transients | Only construction persists; counts stable | Nodes 110→110; objects 1760→1760; orphans 0→0 |
| Rotating allocation, 6 emitters, cap 4, 6 rounds | Equal wins independent of callback order | 4 wins each; reversed callback order identical |
| Tulay 4 wu strip at fall cap | All drops land | 5/5 landed; sampled peak 878.9 wu/s (cap 900) |
| 48 pieces + 4 chickens, 1080p uncapped, 600 frames | ≤16.67 ms; ≤512 MiB | median 1.954 / p95 3.109 / worst 6.059 ms; peak working set 208.8 MiB, private 242.4 MiB |

These P04 fixture measurements are not feel or balance evidence. At that earlier checkpoint the Kaing/Tulay equal weights were configuration only; P05 now uses the Pugad flow in the `karera_slice` profile.

### P06 Karera and scoring runtime measurements — October 14, 2026

The real ArenaDefinition goal trigger, race-clock policy, result binding, exact race awards and current elimination-placement arithmetic now run in the `karera_slice` development profile. The 97-check automated suite, 17-check two-seat live result, 64-check four-seat P05 flow and 2/3/4-seat frame sample passed. The P06 evidence record lists frame, static-memory, repeated-round and export results. These synthetic/scripted checks do not establish player feel, fairness or final balance. Hazard-owner candidates and Barya facts are test-only interfaces; P10 hazard contact, coin gameplay, Lagsanay, event stacks and full-match scoring orchestration remain future gates. No scoring design value changed from the GDD.

### Contact and temporary-state policy

**C:** bodies pass through each other in every supported mode; tag/Hug use sensors, never pushing. This follows GDD.md:73 and the race-stack rules; the more general collision wording at :181 should be read consistently with them.

**P:** evaluate ongoing overlaps each physics step, not only entry callbacks. Permit at most one taya transfer globally per step. Freeze the candidate set before transfer; pick nearest eligible contact. Preserve the current lowest-slot exact tie until R1 is approved. After a pass, the previous taya cannot receive it back for 1.0 s; contacts with others remain eligible. A stationary overlapping pair can pass back after immunity expires, never multiple times within one step. Ignore eliminated/secured chickens. Opening frozen taya cannot tag or be tagged during the head start. Hug uses the same contact geometry, requires actual overlap at evaluation, and never pushes bodies.

State precedence for movement: terminal outcome (secured or eliminated, mutually exclusive) > opening taya freeze > bubble capture > externally forced motion > normal locomotion. Do not let a lower state reactivate a terminal player. Same-step goal/death resolves by recorded time; indistinguishable elimination wins, per GDD. Opening freeze fixes position, clears pending motion and ignores hazards/capture. Bubble replaces movement control but remains taggable/vulnerable under its existing contract. Normal forced motion adds external velocity without a default input lockout; acceleration still permits steering. A spring launch is not shortened by releasing the ordinary jump button.

**P, later spring gate:** initial launch magnitude 775 wu/s along its rotated normal (about 160 wu rise under normal ascent gravity); timed jump within 0.10 s before contact boosts to 849 wu/s (about 192 wu rise). Use a 0.20 s per-player spring retrigger cooldown. External horizontal speed initially caps at 480 wu/s and upward launch at 900 wu/s; collision stops motion at world bounds. These values are provisional and do not apply to ordinary run speed. No new hazard damage behavior is added.

Freeze reads intentional run/jump input before movement-state suppression, with the same device thresholds as locomotion and a 0.10 s release grace at response start. Opposing run buttons still count as intentional input even when their movement cancels. Passive conveyors, spring launches and knockback do not fail Freeze. Merely being captured is not a Freeze failure; deliberately pressing run/jump while captured is still intentional input.

**P out-of-bounds safeguard:** visible solid side walls, floor and ceiling prevent normal escape. Race-only unexpected escape beyond the arena is a single failed terminal outcome, never a respawn or repeat score. Lagsanay, including its stacks, never converts falling into elimination: an unexpected containment breach pauses the entire simulation and reports a prototype defect; restart the round with its pre-round score snapshot and unchanged construction, with no awards from the aborted attempt. Do not teleport the taya to safety while its timer continues or reset only that player's timer. Kangaroo-only containment failure uses the same paused defect recovery. This is a development safeguard, not a player ability or finished recovery feature.

## 3. Input and local competition

**P supported baseline still requiring physical verification:** two gamepads, or one gamepad plus one keyboard seat. Release target remains 2–4 players using verified gamepads/mixed devices. Two shared-keyboard seats are an explicitly enabled fallback after rollover testing. Four-player keyboard-only support is not promised. Synthetic routing/physics checks pass, but the supplied environment has K1/K2 keyboards and no gamepads; keyboard model/layout and physical rollover remain unknown.

Gamepad labels are positions: South (Xbox A / PlayStation Cross), East (B / Circle), West (X / Square), Start/Options. Keyboard bindings below are provisional physical key positions.

| Phase/action | Gamepad | Keyboard seat K1 | Keyboard seat K2 |
|---|---|---|---|
| Join; ready toggle | South | F | Enter |
| Lobby leave / menu back | East | G | Backspace |
| Menu/Pugad navigation | D-pad or left stick | W A S D | Arrow keys |
| Run left/right | D-pad or left-stick x | A / D | Left / Right |
| Jump | South | Space | Right Ctrl |
| Pugad claim | South | F | Enter |
| Place pointer | D-pad or left stick | W A S D | Arrow keys |
| Rotate clockwise | West | R | Right Shift |
| Confirm placement | South | F | Enter |
| Round/match results ready | South | F | Enter |
| Pause / request resume | Start/Options | Escape | Escape (shared system key) |
| Pause/menu accept / back | South / East | F / G | Enter / Backspace |
| Spectator cheer | West | R | Right Shift |

Place movement is grid steps: first press moves one cell; repeat after 0.25 s at 8 cells/s. Pugad/menu repeat uses 0.25 s initial delay and 6 moves/s. Diagonal placement steps do not exceed the cardinal movement rate. Rotate on a fresh press only; unsupported orientations show a disabled cue. Confirm is a pending submission; all solid edits still resolve atomically at phase end, not by confirmation order. Conflicting submissions reject as a set.

**P movement parity:** use digital full-speed target on keyboard, D-pad and stick. Stick activates at |x| ≥ 0.25 and returns to neutral below 0.20; tune activation 0.20–0.35 after drift tests. No stick-exclusive precision walk. Opposing simultaneous directions cancel movement. If D-pad is active, use it rather than the stick. This loses analog walking but keeps the same locomotion possibilities across supported devices. The serious alternative is proportional analog movement only if tests show its extra precision is important enough to justify device asymmetry.

**P assignment:** player number and shape are fixed from join until return to lobby: 1 circle, 2 triangle, 3 square, 4 diamond. Color is supplementary. A device joins exactly one seat; a second join press readies it, never creates another seat. Keyboard is one source split into the two explicit key groups only after selecting shared-keyboard mode. K1/K2 are device layouts, not permanent player numbers. Each can join one vacant slot; mixed gamepads occupy the rest. Route events by device type and assigned device, never broadcast unfiltered gamepad actions to all players.

Newly joining devices cannot ready on the same press. Every phase transition consumes existing press edges; require release before claim, confirm, rotate, jump or ready can trigger again. Movement may continue from a held direction, but jump buffers clear across phases. Ignore operating-system key repeats for one-shot actions. Pugad cursors start centered with no preselected egg; exact same-step claims use a seeded equal lottery among claimants, then losing players can choose again. Existing earlier claims win. Leftovers at timeout are assigned without replacement.

**P disconnect/pause:** any participant may pause. Focus loss or a bound device disconnect pauses all gameplay clocks, hazards, projectiles, physics, event windows, immunity and phase timers together. Disconnect preserves slot, score, taya and position. Reclaim the missing slot through a visible reconnect screen using an unassigned device; no assumption that device IDs stay stable after reconnect. Multiple missing slots require choosing the displayed number and explicit confirmation. Existing assigned devices cannot steal another seat. Never silently substitute a bot or drop the player.

The pauser owns menu navigation; a system pause gives it to the first fresh confirm. Resume requires a fresh ready from every connected participant and all missing seats reclaimed, then a 3 s countdown with simulation still paused. Clear ready flags if focus/device status changes. Countdown cancellation returns to pause. Round results use all-ready or an 8 s timeout; match results wait for all-ready with Replay/Return-to-lobby chosen by the menu owner. Leaving during a match returns the whole group to lobby after a visible confirmation, rather than changing player-count scoring mid-match. Cheer has no simulation effect and a 1 s cooldown.

Engine implementation references, not team mechanic code: [official controller documentation](https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html) describes deadzones and unfocused controller input; [official pause documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html) explains process modes. Team verification must include timers/signals that can still operate during pause. The [4.7 migration documentation](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/migrating/upgrading_to_godot_4.7.rst) changes keyboard/mouse device IDs: use event type and target-version identifiers, never assume keyboard and gamepad 0 are interchangeable. No engine-version migration is authorized here.

Tradeoffs/tests: digital sticks sacrifice fine speed control; all-ready resume adds delay; shared keyboard risks lost simultaneous keys. Rotate players across slots/devices, test drift and every simultaneous key chord, and change bindings/thresholds only on reproducible device failures or consistent control complaints. Never market untested devices as supported.

## 4. Central tuning data and enablement

P02 uses the existing typed `tilaok!/scripts/config/gameplay_tuning.gd` resource and `configuration_snapshot.gd` run snapshot; values are editable centrally and validated. This document remains the provisional starting-value register; do not add parallel config files. No plugin, framework, live editor, public analytics or persistence is used.

Separate simulation invariants (one outcome, pass-through bodies, atomic edits, scoring family), tunable data (movement, timers, bounds, weights), and presentation (markers, colors, shake/text). Gameplay values snapshot at match start. Changing them requires a new test match; never change collision, height bands, timers or weights mid-round. Presentation-only volume/shake may change in pause. Log the test profile, seed and build locally in human test notes, not the player HUD.

| Keys/group | Label; default | Experimental range | Why / downside / change trigger | Confidence |
|---|---|---|---|---|
| `pugad.extra_eggs`, `pick_s` | C/P: players + 2; 8 s | +1…+3; 6–12 s | Choice without lengthy selection; change if claims routinely time out despite understood UI | Low |
| `pugad.family_weights` | P: Kaing 50, Tulay 50; after spring gate 45/40/15 | Kaing 35–60, Tulay 30–55, spring 5–20; normalize eligible weights | Construction first; less hazard pressure. Revise if one item is consistently unwanted, not from one losing round | Low |
| `place.seconds` | C/P: 15 s | 12–25 s | Fast rounds; extend if understood placement still times out often | Low |
| `race.cap_s`, `after_first_s` | C/P: 60 s, 15 s; end at earlier deadline | 45–75 s; 10–20 s | Limits stalling; revise from finish/stall logs | Low |
| `items.activation_grace_s` | P: 1.0 s after Play begins | 0.5–1.5 s | Readable hazard start; delays pressure. Test reset-on-player scenarios; preserve opening taya's longer immunity | Low |
| `events.main_weights` | C: Karera 70, Lagsanay 20, Kangaroo 10 | Fixed baseline; experiments only in named test profile | Preserve contract; disabling content must remove its weight before normalization | Contract only |
| `events.twist_chance` | C: rounds 1–4: 0; 5–7: .10; 8–10: .20; 11–12: .30 | Fixed baseline | Guaranteed rounds 4/8/12 still standalone; chance table never overrides that | Contract only |
| `events.twist_weights` | P: equal among verified compatible Twists | Compare equal vs one explicit weighted profile later | Small predictable pool; no eligible pair means no Twist | Low |
| `lagsanay.timer_by_alive_s` | C/P: 4→15, 3→10, 2→7 s | 12–18, 8–12, 6–10 s | Shorter endgame; test evasion/pass opportunity at each count | Low |
| `lagsanay.open_freeze_s`, `speed_multiplier` | C/P: 3 s; P: 1.05× run speed for taya | 2–3 s; 1.00–1.10× | Head start plus chase advantage; revise on pursuit trials, not win-rate equalization | Low |
| `kangaroo.telegraph_s`, `response_s`, `reset_s` | C/P: 1 / 3 / .75 s | .8–1.5 / 2.5–4 / .5–1 s outside locked baseline | Readable commands; preserve acceleration rule unless R3 approved | Low |
| `kangaroo.command_weights` | C: 1:1:1; Hug rerolls at two survivors | No change in baseline | R2 proposes changing the three-player rule; inactive | Contract only |
| `kangaroo.wave_y_wu` | P: 384, 288, 192 wu; equal probability | Move bands by one 32 wu cell as a group | World heights 3/6/9 tiles above floor; construction can fail deliberately | Low |
| `support.contact_epsilon_wu`, `height_epsilon_wu` | P: 1 wu each; zero time grace | 0.5–2 wu; no gameplay-time extension | Numerical tolerance only; investigate contact instability before enlarging | Medium rationale |
| `kangaroo.freeze_release_s` | P: .10 s | .07–.15 s | Forgives release after cue; too much grace permits a free move | Low |
| `items.persistent_cap` | P: 48 placed items (not cells); base excluded | 32–48 after cap-policy review | Matches four placements × 12 rounds; lower caps can deny construction and need a fair rejection rule | Medium bound |
| `transients.projectiles`, `bubbles`, `vfx` | P: max 16 projectiles (2/emitter), 4 bubbles (1/emitter, 1/player), 32 cosmetic effects | 8–24, 2–4, 16–48 | Bounded future workload; baseline has none of these items enabled | Low |
| `transients.ttl_s` | P: projectile 3 s, empty bubble 4 s, cosmetic 2 s; capture C/P ≈2 s | 2–4, 3–5, 1–3 s; capture 1–2 s | Prevents accumulation; expiry must release captives safely before removal | Low |
| `bubble.recapture_immunity_s` | P: 1.0 s against all bubbles | .75–1.5 s | Stops immediate recapture; not hazard immunity. Disable unsafe event pairing if chains remain unavoidable | Low |

P06 maps the race row to `match_race_hard_cap_seconds = 60.0` and `match_race_after_first_finish_seconds = 15.0` in `gameplay_tuning.gd`; both are validated and copied into the match snapshot. The active-simulation clock freezes on pause. These defaults passed timing fixtures but are still provisional until human play sessions record finish and stall rates. Race score storage uses integer eighth-point units (80 units = 10 points; Bawi requires a 24-unit round-start gap). See the dated P06 runtime record below and [P06 verification evidence](evidence/p06/2026-10-14_p06_verification.md).

Bounds/camera values live in STAGE_AND_PLACEMENT.md's graybox table; movement/contact values are above. Do not duplicate numeric sources in production code. Terminal velocity applies to ordinary gravity; external launch limits have their own keys.

Timer policy: passing taya never resets its countdown. A new taya after elimination receives the timer for the new alive count. Race-stack reassignment when a taya secures the flag preserves the remaining countdown; the newly assigned taya has no opening freeze. The initial head start occurs once at Play start. These are P clarifications to test against the existing stack behavior.

Caps: at the initial 48-item cap, ordinary 12-round play cannot overrun the limit. Debug insertion beyond the cap is rejected before play. At transient saturation, suppress new spawns rather than evict an existing captive/projectile. Allocate available spawn slots by a rotating emitter order, not callback order; telegraph only successful spawns. Do not lower persistent caps without specifying fair simultaneous-placement overflow behavior. Avoid unnecessary hot-path allocation; optimize from profiling, not assumptions.

Named profiles: `movement_room` (no score/events), `karera_slice` (Kaing/Tulay only), `karera_spring` (adds verified spring), `lagsanay_lab`, `kangaroo_contract_lab`, `stack_lab`, `release_candidate`. Debug seed starts at 12345 and is user-settable before a test. Separate seeded streams for egg selection, event selection and exact-tie lotteries so cosmetic randomness cannot affect results. Keep all R policies off in contract profiles; proposed-policy comparison runs need explicit team acceptance first.

Only implemented AND verified modes/items/pairs enter a profile's pool. Disabled weights are zeroed then positive eligible weights normalized; an empty required pool is a configuration error, not a random fallback. Production schedule still requires Lagsanay rounds 4/8/12 and sudden death. `karera_slice` is an explicitly labeled development override with races only; it may display tied leaders and pending sudden-death coverage but must not claim a complete competition-ready match. `release_candidate` refuses to start if required scheduled/sudden-death modes are missing. Do not silently reschedule unavailable release content as Karera.

No scored tutorial bonus, new save format, network service, or new obstacle family is introduced.

## 5. Focused balance audit — recommendations, not approved rule edits

GDD remains unchanged in this task. R1–R4 are concrete proposals for later explicit review; none is enabled by accepting this documentation handoff. A test of current behavior can demonstrate a risk without claiming that a replacement has already been approved or balanced.

| ID / label | Current behavior → problematic scenario | Recommendation | Cost / drawback | Prototype experiment and change trigger |
|---|---|---|---|---|
| R1 — PROPOSED RULE CHANGE | GDD:63 tag ties, :97 Hug ties and :149 exact Last Cluck ties favor lowest slot. Equal geometry/time repeats slot advantage | Keep nearest contact/latest time, but resolve only indistinguishable candidate ties with a seeded uniform lottery; exact Hug edge ties get seeded shuffled order | Small; random tie outcomes require an honest visual callout. Does not remove all randomness or guarantee equal wins | Reproduce exact ties at each slot/device permutation. Approval trigger: slot identity alone changes outcome; verify proposed selection gives every tied candidate opportunity across many seeds |
| R2 — PROPOSED RULE CHANGE | Pair-only Hug guarantees one failure at three live players even if everyone makes contact | With ≥3 eligible chickens, pass each chicken having at least one other eligible contact at evaluation; remove exclusive pairing. Keep two-survivor pre-telegraph Hug reroll | Small; reduces forced exclusion and creates group cooperation/denial choices; removes pair-only tactical identity | Compare three-player all-contact and separated-player cases. Approve if unavoidable markers undermine understanding/agency; four-player 3+1 should fail only the isolated player |
| R3 — PROPOSED RULE CHANGE | Storm forces Freeze + Rising overlap at two survivors; moving to necessary support can violate Freeze | Keep pressure escalation, but never overlap Freeze with a movement-demanding Hug or Rising response. Queue the next command until the incompatible response resolves; retain Storm's 1 s response and ≤2 active cap | Medium; reduces 0.5 s landing throughput and may lengthen endgame. Explicitly removes forced Freeze+Rising overlap | Test start off support with a reachable destination. Approve if current pair necessarily fails one command despite correct execution. Verify queue does not reroll wave height or cancel a command |
| R4 — PROPOSED RULE CHANGE | Bomb timer continues during Freeze; isolated taya with 1 s left must move and fail or stand and expire | Suspend only Bomb-Taya countdown during Freeze response, resume same remaining value afterward; contact/traps/world continue | Medium; changes the current always-running timer contract and slightly extends survival. Repeated Freeze cannot reset timer | Freeze at 0.5/1/3 s remaining with reachable contacts. Approve if no action avoids a failure/timeout solely because of command conflict; verify pause totals, no timer reset and eventual running windows |
| C — CURRENT CONTRACT | Equal-probability fixed wave bands can be above every usable player-built support | Keep no reroll, and show next event plus eligible-support feedback before play | Low; a whole group may fail due to poor preparation, deliberately | Test empty and well-built layouts; change presentation if players cannot explain failure. Only reopen rules if informed construction strategy still offers no meaningful preparation |
| P — PROTOTYPE DEFAULT | Bubble can capture for about 2 s, remain taggable and expose players to a hazard; overlapping emitters may remove repeated control | Keep bubble last/off initially; use global bubble recapture immunity and no generic knockback input lock. Disable bubble in Lagsanay if unavoidable chains persist, as existing item contract permits | Medium lifecycle testing; fewer compatible items until verified. Immunity is not protection from direct hazards | Compare avoidable entry, forced capture, multiple emitters and low-time taya. Any reproducible forced re-capture chain with no actionable interval blocks enablement |
| C/P — precision clarification | GDD:120 says exact averages/eighth units; generic three-way quarter-point averages can require thirds | Retain eighth units for the current legal placement groups, with explicit tests and no claim of universal precision. Use rational arithmetic if later rules permit other groups | Low now; future score-table changes need renewed proof | Exhaust every legal simultaneous group and Last Cluck loser allocation; reject any silently rounded award |

### Exact-score audit

Only eliminated players share placements while a survivor remains. Thus a tie cannot include first place; all-remaining elimination uses Last Cluck instead. For current tables:

| Match size / tied places | Exact average | Eighth-point units |
|---|---|---|
| 4 players, places 3–4 | (0.25+0)/2 = 0.125 | 1 |
| 4 players, places 2–3 | (0.5+0.25)/2 = 0.375 | 3 |
| 4 players, places 2–4 (three-way) | (0.5+0.25+0)/3 = 0.25 | 2 |
| 3 players, places 2–3 | (0.5+0)/2 = 0.25 | 2 |
| 2 players | No legal averaged non-winning group of two | Last Cluck applies |

After Last Cluck awards first, remaining exactly tied losers use the relevant lower placement group; distinguishable loser times retain their lower-order placement. This is a P clarification of the otherwise underspecified lower-placement allocation, not permission to share first. Base awards and additive bonuses are all multiples of 0.25 and therefore eighth-representable. No averaging of cumulative scores is performed.

The hypothetical first–third average (1+0.5+0.25)/3 = **7/12**, and first–fourth average = **7/16**, are NOT representable in eighths. Neither is legal under the current Last Cluck exception. Do not claim eighths represent every possible future tie, and do not falsely report the current legal three-player group as a precision defect. Display eighth fractions/three decimal places without rounding the stored score; compare exact totals for 10 points, underdog thresholds and match ties.

Additional scope contradictions: PRODUCTION originally placed stacking before Kangaroo; corrected dependency order is now in PRODUCTION.md. ROADMAP previously required Lagsanay before all items; construction seed pieces now explicitly precede it. The old Oct 20–22 feature window conflicted with Oct 21 freeze; Oct 22 is now stabilization. GDD's generic contact wording is less precise than its explicit pass-through rule; follow the latter. None of these documents supplies observed balance results.

## 6. Decision timing and unanswered facts

| When | Decisions/defaults | What remains open |
|---|---|---|
| Before first controller prototype | P movement/collider/grid/input/camera and no extra abilities; use the standing AI-assisted programming workflow for approved implementation tasks | P02 diagnostic implementation exists; P01-T02 human review and physical-device checks remain open |
| Before first complete round | P geometry, Kaing/Tulay variants, atomic placement, device isolation, timers and exact one-time score; current scoring preserved | U: physical keyboard/controller inventory and tested baseline device combination; no gamepads are available and keyboard model/layout/rollover are unverified; matching Godot 4.7.2 templates were installed and a local export succeeded |
| Before relevant event | Current contact/command/support contracts, independent-mode gates; explicit R1–R4 decisions before any replacement behavior | U: owner/time for event review and physical tests |
| Tune after playing | Movement feel, gaps, sensor dimensions, deadzones, egg weights, timers, force/caps and readability; one related parameter group at a time | All balance/feel confidence remains low |
| Defer to production art | Final sprite scale/style, font choice, animation, sounds and cultural copy review | U: creators/licences and reviewer names |

Essential factual questions, recorded rather than blocking this handoff:

1. Francis and Carlos are the supplied development leads. Their registration status, individual gameplay/integration assignments and available hours through October 21 remain unrecorded; P00 does not claim them.
2. The user selected the current PC as target; what keyboard model/layout and physical controllers/connections can the team test?
3. The intended Godot 4.7.2 binary is in `D:\Downloads`; obtain matching 4.7.2 templates before any export check. The installed `4.7.stable` templates have a different version identifier. No engine/version change or template installation was part of the P00 baseline.

Team names/registration/capacity and physical device details remain unknown; do not infer them from installed tools. The target PC and local machine specifications are recorded in `PRODUCTION.md`; this is not performance evidence. No final font/art decision is needed before graybox tests. R1–R4 are design proposals, not unknown factual questions.

## 7. Documentation-only delivery boundary

This handoff was prepared after the user asked to proceed, but a complete Stage A plan had not reached them. Consequently it applies prototype documentation and production ordering while preserving current GDD gameplay rules. Previously unseen rule replacements stay explicit inactive proposals. No gameplay code, scene, project setting, prompt file or production asset is generated.

Worktree: `C:\Users\roman\.codex\worktrees\prototype-balance-defaults\Tilaok`, branch `feat/prototype-balance-defaults`, created from fetched origin/main. Named prerequisite snapshots brought forward from the dirty source: AGENTS.md; docs/GDD.md, ROADMAP.md, ITEMS.md, STAGE_AND_PLACEMENT.md, UI_TUTORIAL.md, PRODUCTION.md, PLAYTEST.md, ASSETS.md, AI_USAGE.md, INDEX.md and SUBMISSION.md. They were hash-verified on copy. SUBMISSION/ASSETS/ITEMS/AGENTS provide referenced context; they receive no content changes. Source README/CLAUDE edits are not included. The source checkout is never overwritten.

Task edits: this NEW centralized defaults document; STAGE_AND_PLACEMENT graybox/support; UI_TUTORIAL input reference; PRODUCTION dependency gates/team setup; ROADMAP ordering/freeze; PLAYTEST experiments/evidence; AI_USAGE assistance scope; INDEX navigation. GDD stays byte-for-byte equal to its carried source snapshot; any diff versus origin/main is prerequisite user work, not a newly approved gameplay change.

Before any later commit, distinguish prerequisite user documentation from this task's edits and stage named files only. Commit only on the user's explicit `commit`; push/open PR only on explicit `push`; never merge. No Co-Authored-By trailer or AI attribution in commit/PR text; accurate disclosure belongs in AI_USAGE and Form 03. Do not rewrite history.

**One next physical experiment:** with the target PC's keyboard, run the shared K1/K2 simultaneous-chord and rollover matrix in PLAYTEST.md; record exact make/model/layout and every supported chord. Then arrange two identical gamepads to complete the remaining isolation and reconnect checks. This resolves the open physical-input acceptance without treating synthetic events as hardware evidence.

## P10 first-batch item keys (2026-10-14) — PROVISIONAL, UNMEASURED for feel

All live in `GameplayTuning` and are validated. Values marked *doc* come from the spring gate and transient policy above; others are first proposals. Measured results are in [P10 verification index](evidence/p10/2026-10-14_p10_verification.md).

| Key | Value | Source / measured |
|---|---|---|
| `item_spring_launch_wu_s` / `item_spring_boost_wu_s` | 775 / 849 | *doc*; measured rise 168.2 / 200.8 wu at 60 Hz |
| `item_spring_boost_window_s` / `item_spring_cooldown_s` | 0.10 / 0.20 s | *doc*; press timestamped from the input edge |
| `item_spring_horizontal_cap_wu_s` / `item_spring_upward_cap_wu_s` | 480 / 900 | *doc*; side launch measured 480.0 |
| `item_spring_contact_probe_wu` | 2 | face-contact tolerance |
| `item_trumpo_speed_wu_s` / `item_trumpo_pause_s` / `item_trumpo_hit_wu` | 160 / 0.75 / 20 | pause 45 frames, period 3.25 s on a 5×1 rail |
| `item_parol_cycle_s` / `item_parol_active_s` / `item_parol_charge_s` / `item_parol_beam_width_wu` | 3.0 / 1.5 / 0.6 / 12 | item time: charge 0.900 s, active 1.500 s |
| `item_launcher_initial_delay_s` / `_telegraph_s` / `_cooldown_s` | 0.5 / 0.8 / 1.7 | first shot at frame 76 after arming |
| `item_launcher_projectile_speed_wu_s` / `_size_wu` | 360 / 14 | 6.00 wu per frame |
| `item_bubble_cadence_s` / `_rise_wu_s` / `_radius_wu` | 2.5 / 60 / 14 | emits after the grace |
| `item_bubble_capture_s` / `_release_wu_s` / `_recapture_immunity_s` | 2.0 / 120 / 1.0 | *doc* capture ≈2 s (121 frames) and 1.0 s immunity |
| `item_spring_weight` / `item_trumpo_weight` / `item_parol_weight` / `item_launcher_weight` / `item_walis_weight` / `item_bubble_weight` | 15 / 50 each | spring 15 *doc* (Kaing 45 / Tulay 40 / spring 15 in `karera_spring`); `items_lab` applies equal 50 weights, labelled provisional |

`items_lab` is a development profile applied by the Visualizer and `MatchRoomItemsLab` (`ItemEnabledProfiles`); it is not a `ProfileRegistry` profile, and `release_candidate` is unchanged. Measured stress at 48 persistent items, 16 projectiles and 4 bubbles: median 3.25 ms, p95 4.57 ms, worst 5.70 ms, 80.85 MiB at 1080p.
