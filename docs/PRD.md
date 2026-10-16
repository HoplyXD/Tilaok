# Tilaok! — Product Requirements Document

**Version:** 1.0 · **Baseline date:** October 13, 2026 · **Status:** approved planning scope consolidated; P02 input/movement slice partially implemented and verified; full gameplay remains unimplemented.

**Product owner:** Producer, name TBD. **Development leads:** Francis (lead developer) and Carlos (co-lead developer); both use AI-assisted programming. **Human production roles:** Shanti handles UI design and game audio; Jorge and Ivie handle maps, characters, obstacles, traps, effects and related game assets without AI generation. Registration status, capacity, audio backup, individual task owners and review completion remain unrecorded. This document was prepared with disclosed AI assistance; it is not evidence of a completed game.

## Contents

- [1. Authority, baseline and ownership](#1-authority-baseline-and-ownership)
- [2. Product identity, players and terminology](#2-product-identity-players-and-terminology)
- [3. Goals, scope and measurable success](#3-goals-scope-and-measurable-success)
- [4. Complete player journey](#4-complete-player-journey)
- [5. Inputs, identity and recovery](#5-inputs-identity-and-recovery)
- [6. Controller, contact, stage and camera](#6-controller-contact-stage-and-camera)
- [7. Selection, construction and lifecycle](#7-selection-construction-and-lifecycle)
- [8. Karera, exact scoring and match outcomes](#8-karera-exact-scoring-and-match-outcomes)
- [9. Lagsanay](#9-lagsanay)
- [10. Kangaroo](#10-kangaroo)
- [11. Scheduling, announcements and compatible stacks](#11-scheduling-announcements-and-compatible-stacks)
- [12. Content inventory and scope destinations](#12-content-inventory-and-scope-destinations)
- [13. UX, Library, tutorial and accessibility](#13-ux-library-tutorial-and-accessibility)
- [14. Presentation, audio and provenance](#14-presentation-audio-and-provenance)
- [15. Technical and quality requirements](#15-technical-and-quality-requirements)
- [16. Verification and release acceptance](#16-verification-and-release-acceptance)
- [17. Delivery, schedule and conditional finals](#17-delivery-schedule-and-conditional-finals)
- [18. Decisions, risks, sources and traceability](#18-decisions-risks-sources-and-traceability)

## 1. Authority, baseline and ownership

The GDD controls gameplay design. Specialized contracts elaborate it consistently. PROTOTYPE_DEFAULTS supplies **PROTOTYPE—UNTESTED** implementation starting points, never proven balance. ROADMAP controls release priority and schedule. This PRD explains the product and acceptance; PHASETASK records actual work/evidence. A contradiction is a recorded decision, not permission for the PRD to silently replace the GDD.

Read [GDD](GDD.md), [prototype defaults](PROTOTYPE_DEFAULTS.md), [roadmap](ROADMAP.md), [tracker](PHASETASK.md), and [documentation index](INDEX.md). Requirement source links identify authoritative documents; section context is supplied by each requirement and the source register below. Inactive R1–R4 remain inactive after approval of this document.

Historical source inspection before P01/P02: checkout `feat/filipino-obstacles-events` at `791084a`, with four modified and ten untracked documentation/guidance files. Remote main was `98ef17a74166b6ac10c7930dc48a00c488fe61c9`, merging PR #1 from `a44f1b8`. The documentation work was isolated on `feat/prd-phasetask` from that merged main. At that inspection the project contained only project settings and icon: no gameplay scripts/scenes, export preset or implemented features. Local origin/main was stale before the authorized fetch. Local GDD/ITEMS already matched merged requirements, including Library and animated previews. This is a dated source-history record; current P02 status appears in the requirements below and the PHASETASK tracker.

Requirements below have separate scope and design labels. **REQUIRED** is submission baseline; **SHOULD** needs an include/defer decision; **CONDITIONAL** is finalist-dependent; **EXPANSION** is outside submission. **CURRENT CONTRACT**, **PROTOTYPE—UNTESTED**, **UNKNOWN**, and **OPTIONAL** describe authority, not implementation. Requirements may be unimplemented, partially implemented or verified; [PHASETASK](PHASETASK.md) records current evidence. A requirement with known behavior may still have provisional tuning.


### REQ-PROD-001 — Confirm registered owners and available capacity

**Scope:** REQUIRED · **Design status:** UNKNOWN · **Owner role:** Producer (name TBD).

**Expected behavior:** Assign primary and reviewer/backup for production/integration, programming, art/UI, audio, QA/balance and compliance/media. Francis and Carlos are the supplied development leads; Shanti handles UI design and audio; Jorge and Ivie handle game assets. Individual task assignments, reviewer/backup, registration status and hours remain unknown. A person may cover multiple roles only after capacity review.

**Acceptance:** A dated role/capacity sheet names registered members, review responsibilities and available hours through October 25; no invented names.

**Source:** [PRODUCTION.md](PRODUCTION.md). **P00 evidence — October 13, 2026:** Francis supplied current roles after the earlier private-roster record: Francis — lead developer; Carlos — co-lead developer; both use AI-assisted programming; Shanti — UI design and game audio; Jorge and Ivie — maps, characters, obstacles, traps, effects and related game assets, created without AI generation. No surnames/legal identities, hours, registration status, coach details, audio backup or completed review are claimed. P00-T01/T02 remain open because the required role/capacity and review evidence is incomplete; see [PHASETASK](PHASETASK.md#p00--baseline-and-production-readiness). Runtime checks are not applicable to this team-record blocker.


### REQ-PROD-002 — Ratify the release manifest and document authority

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Producer (name TBD).

**Expected behavior:** Use GDD for gameplay, specialized specifications for consistent details, prototype defaults for untested starting points, ROADMAP for scope/schedule, PRD for consolidation and PHASETASK for execution evidence. October 13 approval targets all eight initial families and applicable approved variants; cuts need an explicit decision.

**Acceptance:** Producer records required/Should/conditional/expansion dispositions, eight-family target and inactive R1–R4; no automatic scope cut or promotion.

**Source:** [GDD.md](GDD.md); [ROADMAP.md](ROADMAP.md); [PRODUCTION.md](PRODUCTION.md). **P00 evidence — October 13, 2026:** The documented release target and authority chain are recorded in [PRODUCTION.md](PRODUCTION.md#p00-baseline-record) and cross-checked against GDD, ITEMS, specialized specifications, ROADMAP, and PHASETASK at source revision `fa6145839bff96ecb6e1afdb112e804bfb72260f`. Existing GDD/PRD approval statements were reused; no approver was named and no new ratification is claimed. P00-T03/T04 remain open pending producer confirmation/provenance; see [PHASETASK](PHASETASK.md#p00--baseline-and-production-readiness). No gameplay implementation is claimed.


### REQ-PROD-003 — Resolve toolchain and hardware facts

**Scope:** REQUIRED · **Design status:** UNKNOWN · **Owner role:** Producer (name TBD).

**Expected behavior:** Target remains Godot 4.7. The intended console binary is now user-identified in `D:\Downloads` and reports 4.7.2; the PATH wrapper remains 4.6.3, another installed executable reports 4.5.1, and gdlint/gdformat report 4.5.0. Confirm exact template compatibility, target OS/CPU/GPU/RAM/display, keyboard layout and physical controller models/connections. Any version change needs a separately recorded decision.

**Acceptance:** Named integration owner records executable/version/template paths and hardware/device inventory; target import and empty export checks either pass with logs or remain blocked with a reason.

**Source:** [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md); [PLAYTEST.md](PLAYTEST.md); [../tilaok!/project.godot](../tilaok!/project.godot). **P00 evidence — October 13, 2026:** Exact paths/versions, target-PC observations, generic keyboard enumeration, absent controller enumeration, installed `4.7.stable` templates (mismatched with editor `4.7.2.stable`), missing export preset/entry scene, and test outcomes are recorded in [PRODUCTION.md](PRODUCTION.md#p00-baseline-record) and [PLAYTEST.md](PLAYTEST.md#p00-production-readiness-evidence). A fresh isolated-copy Godot 4.7.2 import passed; a separate editor invocation logged an error/warning; no export or physical input test was performed. P00-T05/T06 remain open pending matching templates/export prerequisites, physical inventory, and owner/reviewer confirmation. No software was installed and no engine setting changed.

## 2. Product identity, players and terminology

Tilaok! is a free-to-play PC, 2–4-player local competitive party platformer for the DOST Level Up 3.0 Philippine Games and Sports theme. Chickens choose visible eggs, build a shared course, then compete on it. The course persists and grows; races alternate with traditional-game-inspired challenges and compatible pressure events.

**Pitch:** Build the level, survive the level, and every few rounds a laro ng lahi takes over. Intended players are friends sharing one PC; spectators should understand the objective and winner without specialist knowledge. The sabong reference is a wholesome reimagining, never fighting or betting.

Pillars: readable run/jump controls; strategic shared construction; original Filipino character and reviewed language; fair, understandable outcomes; replayability through persistent layouts; polish before breadth. Game-feel success means observable responsive input, predictable collision/tells, understandable mistakes and usable onboarding, assessed through recorded trials rather than “make it fun.” Borrow only the broad build-then-run mechanic, never UCH code/art/audio/characters/names/UI.

| Term | Meaning |
|---|---|
| Pugad | Nest/egg selection phase; contents visible and animated. |
| Place | Simultaneous grid construction and cleanup. |
| Play / Karera | Challenge phase / ordinary flag race. |
| Lagsanay / taya | Tag-hot-potato elimination mode / current timer carrier; local wording awaits cultural review. |
| Kangaroo | Slipper-presented Freeze, Rising wave and Hug commands with three-failure elimination. |
| Main Challenge / Twist | Main owns end condition/scoring; at most one compatible pressure event runs alongside it. |
| Secured | Finished racer excluded from future hazards, tagging and commands. |
| Tapos / Una / Bayani | Finish/objective award / first award / sole-finisher bonus. |
| Patibong / Bawi / Barya | Direct trap award / underdog comeback / optional carried coin. |
| Last Cluck | Deterministic one-winner resolution when all remaining players are eliminated together. |

## 3. Goals, scope and measurable success

| Milestone | Observable completion |
|---|---|
| First playable vertical slice | Two verified inputs complete two build/race rounds with Kaing/Tulay, basic tutorial/results and ten resets; explicitly race-only developmental profile. |
| Feature-complete submission | Required eight families/applicable variants, independent Karera/Lagsanay/Kangaroo, three stacks, full match/scoring, menus/Library/tutorial and essential presentation are integrated. |
| Release-ready | Supported 2/3/4-player/device tests, full-match/restarts, clean-PC export, accessibility and measured budgets pass; no critical defect; provenance complete. |
| Submitted | Reviewed package/forms/synopsis/trailer/demo delivered with successful receipt and preserved evidence. |
| Finalist preparation | Only after qualification: category extras, poster and real event-hardware rehearsal. |
| Full-catalog expansion | Each promoted optional family/event satisfies its own acceptance. Its remaining work never blocks the submission milestone. |

October 13 scope decision targets **all eight** initial families. Any cut needs an explicit owner decision; review Bula first if capacity slips. All applicable approved variants remain targeted, while vertical Tulay depends on a written support gate. Prototype slices may enable fewer variants without deleting the others.

Required: one arena, controls/local input, construction loop, exact outcomes/scoring, independent Lagsanay/Kangaroo, all three stacks, title/results/settings/help/Library, tutorial, accessibility, essential original art/music/SFX, export/quality/provenance and submission. Should: Barya, session win tally, enhanced crowd, richer skins/accessories, reviewed educational cards and Langit-Lupa. Included Should content becomes subject to required release quality gates. Other catalog families/events/stages are expansion.

Non-goals: networking, online accounts, servers/RPCs, paid gameplay licence, cloud saves, disk progression, extra movement abilities, team-based modes for the deadline, arbitrary event combinations and importing core mechanics from tutorials/templates. Save migrations and server/RPC validation are N/A. Session tutorial completion and optional session win tally do not introduce persistent saves.

## 4. Complete player journey

Launch → title → join/ready lobby → guided first Karera → Pugad → Place → Play → round results → next round; threshold/round limit → tied-player sudden death when needed → match results → replay or lobby. Title/lobby/pause provide Library/help access. Settings/pause/back/quit paths remain operable with supported inputs.

| State | Player-visible information/actions |
|---|---|
| Title | Start local match, Library, settings, quit; development build label. |
| Lobby | 2–4 slots, device prompts, fixed number/shape plus color, join/ready/leave/help. |
| Tutorial | One instruction at a time; move/jump, claim, place/rotate, flag and actual results. |
| Pugad | Exact animated item/size, countdown, ownership, next-round Main/Twist announcement. No names/descriptions. |
| Place | Pointer/ghost, rotate/confirm, countdown, validity reason, protected zones and effect/trajectory guide. |
| Play | Objective, relevant timers, round/scores/identity/state, readable hazards and event prompts. |
| Round result | Actual finish/elimination/points/totals, no-score reason; all-ready or provisional timeout. |
| Match result | Exactly one winner, exact scores for every original participant, ordinary or sudden-death outcome, Last Cluck explanation where applicable, Replay/Return to Lobby/Quit; optional session tally. |
| Pause/reconnect | Frozen simulation, missing-seat reclaim, settings/Library/help and all-ready resume. |
| Library | Enabled-content categories, animations, rules/controls/tells/counterplay; preserve return context. |


### REQ-UI-001 — Provide minimal join, round results and next-round flow

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Art/UI (name TBD).

**Expected behavior:** Lobby supports 2–4 joined ready seats with fixed markers; fewer than two cannot start. Round result explains outcomes, awards, no-score reason and total. Prototype result advance is all-ready or 8 s. Provide basic join/move/jump/egg/place hints early; add wall-movement instruction only if REQ-MOVE-004 is implemented, verified and selected for release.

**Acceptance:** New participants can join and identify themselves; results explain actual awards; next round consumes held presses and retains construction correctly.

**Source:** [UI_TUTORIAL.md](UI_TUTORIAL.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** minimal lobby, live explained race results and next-round loop pass P05-T12; see the [P05 verification record](evidence/p05/2026-10-14_p05_verification.md) and [P06 captures](evidence/p06/README.md). This is code-built DEBUG UI with synthetic inputs; final scene-based UI integration, human readability/onboarding and physical-device coverage remain open.


### REQ-MATCH-002 — Replay, return to lobby and reset all match state

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Match results bind live final scores, one winner and the ordinary/sudden-death outcome; Last Cluck results explain the winner rule. Offer Replay, Return to Lobby and Quit. The first fresh navigation/confirm claims menu ownership and every original participant freshly readies the selected action. Focus/device changes or disconnect clear readiness and cancel pending actions; missing seats remain reclaimable. Quit and mid-match whole-group leave use the shared confirmation dialog; cancel restores the prior match state, while confirm returns the whole group without changing scoring player count. Replay retains seats/devices, creates a fresh configuration snapshot and reproducible seed, and clears construction, scores, captures, transients, event state and ready edges.

**Acceptance:** Ten complete match-ending restarts show no retained score/timer/immunity/capture or sustained object growth; Replay/Lobby/Quit and leave-cancel routes work after ordinary and sudden-death endings. Every original participant's exact final score is visible, and each result screen names exactly one winner.

**Source:** [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md); [UI_TUTORIAL.md](UI_TUTORIAL.md); [PLAYTEST.md](PLAYTEST.md). **Implementation/evidence (2026-10-14):** P09 binds live match data to the themed match result screen. Its 108 rendered interaction assertions cover Replay/Lobby/Quit, unanimous fresh readiness, focus/device invalidation, missing-seat reclaim, Quit/leave cancellation, whole-group Lobby reset and a fresh Replay seed/configuration. The ten-cycle restart audit is in [P09 evidence](evidence/p09/README.md). Synthetic seats and shortened timers are used; physical devices and human play remain unverified.

**Scoreboard slice (2026-10-15, partial requirement evidence):** the live final-results screen now uses the shared vertical score chart, exact configured target line, fixed seat order, labelled/glyphed award legend and explicit Last Cluck callout. Round-12 winners remain below the target when their score is below it; tied sudden-death scores use the winner callout without changing bar height. See [P13-T13/T14 captures and tests](evidence/scoreboard/README.md). This does not replace the P09 restart/readiness contract or physical/human review.

## 5. Inputs, identity and recovery

Bindings below are **PROTOTYPE—UNTESTED**, not a claim of physical-controller validation. K1/K2 are key groups, not fixed player numbers. South/East/West identify controller button positions (A/B/X on Xbox). Shared Escape is a system pause key.

| Action | Gamepad | K1 (WASD) | K3 (IJKL) | K2 (arrows) | K4 (numpad) |
|---|---|---|---|---|---|
| Join/ready; claim; confirm | South | E or F | O | Enter | Num 0 |
| Back/leave | East | G | U | Backspace | Num . |
| Menu/Pugad/Place navigation | D-pad/left stick | WASD | IJKL | Arrows | Num 8 4 2 6 |
| Run | D-pad/stick horizontal | A/D | J/L | Left/Right | Num 4/6 |
| Jump | South | W or Space | I | Up or Right Ctrl | Num 8 |
| Rotate; spectator cheer | West | R | P | Right Shift | Num 5 |
| Pause/request resume | Start/Options | Escape | Escape | Escape | Escape |

**Four keyboard layouts (2026-10-16, requested by Jorge):** WASD (E or F confirm, R rotate), IJKL (O confirm, P rotate), arrows (Enter confirm, Right Shift rotate) and numpad 8 4 2 6 (Num 0 confirm, Num 5 rotate). A layout is only a device: seats are numbered in join order, so any layout can be any player. Internally WASD is K1, arrows K2, IJKL K3 and numpad K4. Four players on one keyboard depends on that keyboard's key rollover, which is untested; the key-chord recorder (chords C25–C31) checks it on the real keyboard.

Prototype digital stick activation is absolute x ≥.25, neutral below .20; D-pad takes precedence. Opposite directions cancel motion but still represent intentional input for Freeze. All assigned devices receive the same movement capability; analog walking is not an approved extra. See the source register for full provisional repeat/edge/pause policies.


### REQ-INPUT-001 — Assign devices and fixed chicken identity

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Support 2–4 local seats, gamepads first. A device joins one seat; join and ready require separate fresh presses. Number/shape stay fixed until lobby return: prototype 1 circle, 2 triangle, 3 square, 4 diamond. Color supplements identity.

**Acceptance:** Two identical gamepads and mixed input never control another seat, double-join or ready on the joining press; identifiers persist through phases and reconnect.

**Source:** [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md); [UI_TUTORIAL.md](UI_TUTORIAL.md). **Implementation/evidence (2026-10-13):** P02 seat assignment, fixed number/shape markers, separate join/ready edges and changed-ID reclaim are implemented; synthetic checks pass in [P02 evidence](evidence/p02-checks-2026-10-13.log). Two identical physical gamepads and mixed-input playtest remain COULD-NOT-RUN; see [tracker P02-T01/T02](PHASETASK.md#p02-t01).


### REQ-INPUT-002 — Implement phase-specific bindings and shared keyboard fallback

**Scope:** REQUIRED · **Design status:** PROTOTYPE—UNTESTED · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Use the provisional binding table below. Release target is 2–4 players on verified gamepads/mixed devices. Two keyboard seats require explicit shared-keyboard mode and physical rollover validation; four-player keyboard-only is not promised. Stick digital parity/deadzone/repeat values remain prototype settings.

**Acceptance:** Each phase action works only for its assigned seat; no lost simultaneous supported chords. Unavailable/failed keyboard combinations are documented, remapped or excluded from supported claims.

**Source:** [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md); [UI_TUTORIAL.md](UI_TUTORIAL.md). **Implementation/evidence (2026-10-13):** phase-specific gamepad and K1/K2 routes, explicit shared-keyboard mode, stick/D-pad priority and thresholds are implemented; synthetic routes pass in [P02 evidence](evidence/p02-checks-2026-10-13.log). Physical rollover and supported chord verification remain COULD-NOT-RUN; see [tracker P02-T03/T04](PHASETASK.md#p02-t03).


### REQ-INPUT-003 — Consume held presses across phase transitions

**Scope:** REQUIRED · **Design status:** PROTOTYPE—UNTESTED · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Consume existing press edges on transitions; release is required before claim/confirm/rotate/jump/ready. Held direction may continue; jump buffers clear. Ignore OS key repeat for one-shot actions. Prototype placement repeat is one cell then 0.25 s delay at 8 cells/s; menu/Pugad repeats at 6/s.

**Acceptance:** Holding jump/confirm through every transition creates no unintended next action; diagonal pointer movement gains no speed; unsupported rotations give a disabled cue.

**Source:** [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence (2026-10-13):** fresh press gating, phase edge consumption, jump-buffer clearing, OS echo rejection, diagonal navigation and Place/menu repeat timing passed synthetic Godot tests; see [P02 evidence](evidence/p02-checks-2026-10-13.log) and [tracker P02-T05/T06](PHASETASK.md#p02-t05). Physical keyboard rollover remains open under REQ-INPUT-002.


### REQ-INPUT-004 — Pause and reclaim disconnected seats safely

**Scope:** REQUIRED · **Design status:** PROTOTYPE—UNTESTED · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Any participant may pause; focus loss/device disconnect pauses all simulation, timers, immunity, physics, hazards and event windows. Preserve slot/score/taya/position. Reclaim missing slots using unassigned devices and visible slot confirmation. All participants ready, all missing seats reclaimed, then a paused 3 s resume countdown. Status changes cancel readiness.

**Acceptance:** Unplug/replug including identical controllers preserves identity and timer values; assigned devices cannot steal seats; focus changes cancel resume; no simulation progresses during pause/countdown.

**Source:** [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence (2026-10-13):** shared pause, focus/device status pause, seat reclaim, owner acquisition, all-ready countdown and timer/physics freeze probes are implemented and pass synthetic checks; see [P02 evidence](evidence/p02-checks-2026-10-13.log). Physical controller unplug/replug and identical-controller reclaim remain COULD-NOT-RUN; see [tracker P02-T07/T08](PHASETASK.md#p02-t07).

## 6. Controller, contact, stage and camera

Exact motion/geometry defaults remain centralized in [PROTOTYPE_DEFAULTS](PROTOTYPE_DEFAULTS.md) and [STAGE_AND_PLACEMENT](STAGE_AND_PLACEMENT.md). Numerical restatements here are readable summaries, not a second tuning authority. Retune jump/collider/grid/gaps/camera together and record experiments. World units are provisionally unscaled pixels; actual collision and readability remain untested.

Base stage is playable before construction; player changes may make it difficult or unsolvable. Player-built elevation helps Rising wave while immutable base platforms never qualify. No structural attachment simulation is implied: legal floating built support can qualify when actually supporting feet. Visibility and protected zones are hard constraints; solvability is not guaranteed.


### REQ-MOVE-001 — Implement responsive run and jump only

**Scope:** REQUIRED · **Design status:** PROTOTYPE—UNTESTED · **Owner role:** Gameplay (name TBD).

**Expected behavior — original P02 baseline:** This requirement's run/jump-only wording records the pre-extension controller scope; it does not exclude the separately approved REQ-MOVE-004. Preserve left/right, normal jump, ground/coyote behavior and the measured run/jump contract. Dash, double jump and drop-through remain excluded. Prototype uses 32 wu grid, 24×48 collider, 96 wu jump apex at 0.32 s, 280 wu/s run speed, variable jump, coyote/buffer, acceleration/braking and launch limits from the defaults register. These are starting values, not balance claims.

**Acceptance:** Measure full/short jumps, braking, reversal and 64 wu gap/rise trials; investigate apex deviations above 2 wu or one physics step; consume each buffered jump once and never auto-repeat held jump.

**Source:** [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence (2026-10-13):** run/jump-only controller and centralized provisional tuning are implemented and measured in the P02 movement fixture; full/short jumps, braking, reversal, held-jump, coyote/buffer, ceiling, launch and 64+64 gap/rise tests pass. See [P02 evidence](evidence/p02-checks-2026-10-13.log), [measurements](PROTOTYPE_DEFAULTS.md#p02-runtime-measurements--october-13-2026), and [tracker P02-T09/T10](PHASETASK.md#p02-t09). This does not establish balance or whole-stage reachability.


### REQ-MOVE-002 — Separate body collision, contact and intentional input

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Chicken bodies pass through in Karera, Lagsanay and Kangaroo; independent sensors support tag/Hug. Forced movement is distinct from intentional input. Prototype precedence is terminal > opening taya freeze > capture > forced motion > locomotion. A lower state cannot reactivate a secured/eliminated player.

**Acceptance:** Overlap creates no pushing; intentional input is observable while captured; launch clears coyote state and is not shortened by jump release; terminal states ignore later movement/capture.

**Source:** [GDD.md](GDD.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence (2026-10-13):** independent 28×48 contact sensing, pass-through body collision, input/force separation and lifecycle precedence are implemented and pass diagnostic checks; see [P02 evidence](evidence/p02-checks-2026-10-13.log) and [tracker P02-T11/T12](PHASETASK.md#p02-t11). These contracts do not implement Lagsanay, Kangaroo, scoring or a production match.


### REQ-MOVE-003 — Contain players and expose invalid escapes

**Scope:** REQUIRED · **Design status:** PROTOTYPE—UNTESTED · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Visible floor/side/ceiling bounds contain ordinary and forced movement. Lagsanay has no fall elimination. Prototype unexpected race-only escape fails once; containment failure with Lagsanay or standalone Kangaroo pauses as a defect and restarts the round from pre-round scores and unchanged construction.

**Acceptance:** Maximum launches cannot bypass bounds; injected breach cannot repeatedly award score, teleport an active taya while time runs, or convert a Lagsanay fall into elimination. Recovery is labeled a prototype safeguard.

**Source:** [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md); [GDD.md](GDD.md). **Implementation/evidence (2026-10-13):** visible floor/walls/ceiling, maximum configured launch containment and explicit Race/Lagsanay/Kangaroo breach recovery contract pass diagnostic tests; see [P02 evidence](evidence/p02-checks-2026-10-13.log) and [tracker P02-T13/T14](PHASETASK.md#p02-t13). Recovery is a labeled prototype safeguard, not a scoring or complete round-restart system.


### REQ-MOVE-004 — Slide on eligible walls and kick away with a fresh jump press

**Scope:** SHOULD · **Design status:** APPROVED; IMPLEMENTED, AUTOMATED CHECKS PASSED, HUMAN REVIEW PENDING (October 13, 2026) · **Owner role:** Gameplay (name TBD).

**Existing baseline:** REQ-MOVE-001 and P02-T09/T10 accurately record the previously implemented and measured run/jump-only controller. That historical acceptance excluded wall jump; it is not evidence for this extension. The extension is separately approved; its implementation passes automated Godot physics, route, containment and camera checks (see [wall evidence](evidence/p02-wall/README.md)); human feel review and physical-device parity are pending.

**Expected behavior:** While airborne and actually touching a qualifying solid side, slide down with a configurable cap on downward speed only. Contact does not require directional hold. Base and player-built solid sides qualify; moving solids qualify only while actual contact remains valid. Exclude one-way platform sides/undersides, triggers, pass-through chicken bodies and arena containment boundaries. A fresh jump press near eligible wall contact produces one kick away, using a configurable horizontal-away and vertical impulse. Air steering remains available immediately. One kick is allowed per contact; physical separation and fresh recontact are required before another. Normal ground jump/coyote behavior remains unchanged. Holding jump or OS key-repeat never auto-repeats a wall jump; buffered input is consumed exactly once.

**State and system precedence:** Preserve terminal > opening freeze > capture > external forced motion > locomotion. External launches preempt and clear wall-action eligibility and pending wall jump input; wall jump must not shorten or overwrite an external launch. Pause freezes movement and input consumption. Phase changes, reset, and scene reload clear stale contact/buffer/repeat state. Keep intentional jump input observable for future Freeze evaluation. Player bodies remain pass-through. Wall contact is not grounded support, never populates upward support provenance, and never qualifies for Rising wave.

**Configurable prototype tuning:** Start wall-jump candidates at 240 wu/s horizontal-away and −520 wu/s vertical. Centralize the descending slide cap, optional short contact grace, separation/recontact threshold and impulse values. All are provisional, unmeasured starting points, not balance-approved values. Compare alternatives in actual Godot physics and human feel sessions.

**Acceptance:** Left/right eligible walls behave symmetrically; contact loss/removal clears state; only descent is speed-capped; each fresh press yields at most one jump and held/repeated input cannot chain; same-wall re-jump requires separation; excluded surfaces never activate; lifecycle/launch/pause/reset precedence is respected; support/Rising-wave state stays false; ground jump/coyote and pass-through-body behavior regressions pass; P03's base route remains traversable without wall movement; maximum kicks/launches remain contained and camera-visible. Actual feel/balance review and physical input parity must be recorded separately from synthetic tests.

**Explicit non-goals:** Dash, double jump, drop-through, player-to-player wall interaction, AI-created final art/audio, changing P03 base route, implementing Lagsanay/Kangaroo/event logic, or promoting Should scope to a required October submission feature.

**Source / tasks:** [GDD.md](GDD.md#wall-slide-and-wall-jump--approved-extension), [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md#wall-movement--approved-should-extension), [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md#wall-contact-and-upward-support-are-distinct), [PLAYTEST.md](PLAYTEST.md#wall-movement--future-verification), and [PHASETASK P02-T15–T22](PHASETASK.md#p02-wall-movement-extension--approved-unimplemented-should-scope). P02-T15–T17 and T19–T21 are checked on automated/synthetic evidence; T18 (physical devices) and T22 (human review) remain unchecked. Later event-stack integration belongs at the corresponding event gates; this requirement does not depend on unimplemented events.


### REQ-MOVE-005 — Sneak into a one-tile body and glide while holding jump

**Scope:** SHOULD · **Design status:** REQUESTED BY JORGE 2026-10-14; IMPLEMENTED, AUTOMATED CHECKS PASSED, HUMAN REVIEW PENDING · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Holding down while grounded shrinks the chicken to a 1×1-tile body anchored at the feet; it cannot walk or jump while sneaking and stands up only when there is headroom. Holding jump while falling caps descent at a configurable glide speed with normal air steering; wall slide takes precedence on eligible walls and a fresh press still wall-jumps. On keyboards W/Up jump during Play (Space/Ctrl remain alternates) and S/Down sneak; W/Up stay navigation keys outside Play. Lifecycle/launch/pause precedence matches REQ-MOVE-004.

**Acceptance:** Sneak and glide behave as above in real Godot physics on the 64 wu grid; existing run/jump/wall regressions pass; human feel review and physical-device parity are recorded separately.

**Source / tasks:** [GDD](GDD.md#sneak-and-glide--2026-10-14-extension), [PROTOTYPE_DEFAULTS](PROTOTYPE_DEFAULTS.md#64-wu-grid-sneak-glide-and-stage-blocks--october-14-2026), [PHASETASK P02-T23–T26](PHASETASK.md#p02-sneak-glide-64-wu-grid-and-stage-blocks-extension--implemented-should-scope).


### REQ-STAGE-004 — 64 px tile stage and scene-authored stage blocks

**Scope:** SHOULD · **Design status:** REQUESTED BY JORGE 2026-10-14; IMPLEMENTED, AUTOMATED CHECKS PASSED, HUMAN REVIEW PENDING · **Owner role:** Gameplay / Maps (names TBD).

**Expected behavior:** The stage grid is 64×64 px; a chicken is 1×2 tiles. The base stage is drawn with a 64 px TileMapLayer painted from ArenaDefinition (collision stays per surface so support/wall metadata is unchanged). Solid Block (3×1, rotatable), Wood Box (2×2, gravity, pushable, resets to its placed spot) and Collapsing Block (1×1, collapses 2 s after standing/wall-slide contact, returns after 3 s when clear) each live in their own editable scene and enter the Pugad pool as construction items.

**Acceptance:** Tiles line up with arena coordinates; block scenes match their data footprints; behaviors pass real-physics checks; existing P03–P05 regressions pass at the new scale.

**Source / tasks:** [GDD](GDD.md#stage-blocks--2026-10-14), [ITEMS](ITEMS.md#stage-blocks--october-14-2026), [PHASETASK P02-T23–T26](PHASETASK.md#p02-sneak-glide-64-wu-grid-and-stage-blocks-extension--implemented-should-scope).


### REQ-STAGE-005 — Scene-authored block catalog with kill and stun hitboxes

**Scope:** SHOULD · **Design status:** REQUESTED BY JORGE 2026-10-14; IMPLEMENTED, AUTOMATED CHECKS PASSED, HUMAN REVIEW PENDING · **Owner role:** Gameplay / Maps (names TBD).

**Expected behavior:** Every placeable item is one scene in `tilaok!/scenes/blocks/` with a BlockData customization node: placement box size, solid hitbox, kill/stun hitboxes, anchor (Anchored/Heavy/Light), effects and specials (Spawn Projectiles along a Path2D, Follow Rail, Timed Hitbox, Launch, Collapse, Cleanup). A new scene in the folder joins the selection pool automatically. Kill hitboxes eliminate with placer credit; stun hitboxes knock back and freeze controls without credit. Spikes and Cannon are the first new blocks, and the match selector offers every main-game block scene. Place is first come, first served: the first confirmed placement claims its cells. Eliminated chickens show the death sprite.

**Acceptance:** Catalog-built definitions match the previous data exactly; drop-in, Spikes, Cannon, stun, Heavy/Light and death checks pass in real physics; existing suites pass.

**Source / tasks:** [GDD](GDD.md#block-scenes-spikes-cannon-and-stun--2026-10-14-requested-by-jorge), [ITEMS](ITEMS.md#block-scenes--how-every-placeable-item-is-authored-2026-10-14), [PHASETASK P02-T27–T29](PHASETASK.md#p02-t27).


### REQ-STAGE-001 — Build one protected barrio graybox arena

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Start with solid floor, left spawn, right flag, few base platforms and fixed bounds. Base/floor/spawn/goal are indestructible; hidden event goal clearance remains protected. Use the provisional 1024×512 wu graybox only after controller measurement. Layouts created by players need not remain solvable.

**Acceptance:** Base route is traversable before construction; bounds/protected zones are visible in tests; no placement/removal changes immutable geometry. Paper reachability is confirmed by actual collision trials.

**Source:** [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [GDD.md](GDD.md). **Implementation/evidence (2026-10-13):** P03 builds the 32-wu tile-edge arena, protected spawn/goal/build regions, fixed bounds, immutable base geometry, and labeled debug overlays in `tilaok!/scripts/stage/arena_definition.gd` and `tilaok!/scripts/harness/p03_stage_room.gd`. The real controller traversed floor→A→B→C→D→goal with collision; protected footprint/sweep/effect edits and immutable removals were rejected and left the geometry signature unchanged. See [P03 assertions](evidence/p03/2026-10-13_p03_tests.txt), [rendered capture](evidence/p03/2026-10-13_interactive_harness_1080p.png), and [verification record](evidence/p03/2026-10-13_p03_verification.md). **Verification result:** PASSED for the P03 graybox contract. Future player edits are not guaranteed to remain solvable; no production placement system is claimed.


### REQ-STAGE-002 — Frame active players and unfinished placement pointers

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Play frames live unfinished chickens; eliminated/secured chickens are excluded. Place frames unconfirmed pointers including item extents. Ease framing changes with bounded zoom/pan; zoom out fast enough for launches. Empty sets hold safe framing. HUD remains screen-sized.

**Acceptance:** At 2/3/4 players, maximum separation/high construction/launches keep relevant targets visible and readable; finishing/confirming removes the correct target without unsafe snapping.

**Source:** [GDD.md](GDD.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md). **Implementation/evidence (2026-10-13):** `tilaok!/scripts/camera/bounded_stage_camera.gd` fits real Play identity/body extents and unconfirmed Place preview rectangles inside the HUD-safe view, clamps pan to the actual viewport/bounds, and holds safe framing for empty sets. P03 verified 2/3/4 targets, opposite-corner preview extents, the highest legal preview, an actual 900-wu/s controller launch, and per-target finish/confirm exclusion. [Rendered evidence](evidence/p03/2026-10-13_play_1080p.png) is at zoom 1.0/1920×1080; [the wide-window capture](evidence/p03/2026-10-13_place_wide_window_1920x800.png) kept the same 1280×720 logical gameplay view. Full procedures/results are in [P03 verification](evidence/p03/2026-10-13_p03_verification.md). **Verification result:** PASSED for the diagnostic camera and renderer fixtures; this is not physical-controller or final-art readability certification.


### REQ-STAGE-003 — Track actual supporting contact and construction provenance

**Scope:** REQUIRED · **Design status:** PROTOTYPE—UNTESTED · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Track player-built provenance and explicit wave-support eligibility on authored surfaces. Actual upward supporting contact after movement/destruction is required; stale grounded/coyote/sensor states are insufficient. Prototype upward normal is within 45 degrees, v1 horizontal tops; numeric epsilon is untested.

**Acceptance:** Support row matrix distinguishes base, Kaing, one-way bridge, launch, moving/removed surface, bubble, projectile, side contact and airborne state; missing eligibility metadata fails content validation.

**Source:** [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence (2026-10-13):** P03 implements explicit eligibility/provenance metadata, stable surface/construction IDs, post-movement upward collision contacts, feet-height evaluation, and same-step invalidation on launch, capture, reset and surface removal in `tilaok!/scripts/stage/`. The [100-check P03 suite](evidence/p03/2026-10-13_p03_tests.txt) covers base terrain, Kaing-like construction, one-way contact, launch, moving/removal, safe-face fixtures, another player's build, pass-through chickens, capture, projectile, side-wall, coyote and airborne states, missing metadata and inherited child provenance. Three fixture-only sample lines test above/on/below bounds; they do not define Kangaroo event heights or implement that event. **Verification result:** PASSED for the supporting-surface contract; later wave scheduling, scoring and hazards remain unimplemented.

## 7. Selection, construction and lifecycle

Players select simultaneously, see a hatch into their pointer, submit placement, then all valid edits resolve fairly from a shared snapshot. Item footprints differ from trigger/sweep/projectile/effect regions. Walis is the sole active Place action and never a Play hazard. Construction persists between rounds; transient objects and temporary states do not. The selected size never changes secretly.


### REQ-ITEMSYS-001 — Define item metadata and bounded regions

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Item definitions use stable catalog IDs and explicit family/variant, footprint, solid/trigger, sweep/lane/effect regions, rotations, ownership, safe start, removal, event eligibility and preview/Library presentation. Centralize all tunables. Only approved variants may enter pools.

**Acceptance:** Definition validation rejects missing required fields, unbounded regions and undocumented variants; effect regions remain distinct from occupied grid cells.

**Source:** [ITEMS.md](ITEMS.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** implemented and verified 2026-10-13 (P04-T01/T02): typed definitions, one validator and a 31-case rejection table; effect regions never occupy cells. See [P04 verification index](evidence/p04/2026-10-13_p04_verification.md). Synthetic-input harness evidence only; no human review.


### REQ-ITEMSYS-002 — Implement persistent items and bounded transient lifecycle

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Items are inert in Place except Walis edit; reset deterministic position/direction/phase at Play with configurable grace. Persist placed construction across rounds and remove it on match reset. Clear timers/signals/projectiles/captures on appropriate removal/death/end/restart. Prototype caps: 48 persistent, 16 projectiles, 4 bubbles, 32 VFX; saturation suppresses spawns rather than evicting captives.

**Acceptance:** Ten reset cycles retain only intended construction and no transient state. Saturation/removal releases references and captives safely; spawn allocation follows reviewed rotating order, not callback order.

**Source:** [ITEMS.md](ITEMS.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** implemented and verified 2026-10-13 (P04-T03/T04): inert Place, deterministic Play reset with grace, persistence, match reset, caps 48/16/4/32, rotating allocation and captive-safe release; ten cycles stable. See [P04 verification index](evidence/p04/2026-10-13_p04_verification.md). Transient items are test-only fixtures; no human review.


### REQ-PUGAD-001 — Show exact-variant animated egg previews

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Art/UI (name TBD).

**Expected behavior:** Every egg shows a short looping visual preview of its exact item and variant without names/descriptions. Claiming preserves variant identity through hatch to placement ghost. Library is the deliberate space for descriptions.

**Acceptance:** For every enabled variant, capture matching egg/ghost pairs; animation shows shape/effect extent and no descriptive name/text; no hidden size substitution.

**Source:** [GDD.md](GDD.md); [ITEMS.md](ITEMS.md); [UI_TUTORIAL.md](UI_TUTORIAL.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-PUGAD-002 — Resolve simultaneous egg claims and timeouts

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Pugad is simultaneous, one egg per player and one owner per egg. Approximate defaults: players+2 eggs and 8 s. Earlier claims win; prototype indistinguishable same-step claims use a seeded equal lottery; timeout assigns remaining eggs without replacement. Losing claimants receive a non-color cue and may choose again.

**Acceptance:** Contested claims and simultaneous timeout never duplicate eggs or ownership; selection uses eligible pool only and leaves each player with at most one item.

**Source:** [GDD.md](GDD.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md); [UI_TUTORIAL.md](UI_TUTORIAL.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-PLACE-001 — Preview grid placement with actionable rejection reasons

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Move/rotate/confirm a visible grid-snapped ghost. Show exact variant, footprint and relevant sweep/lane/effect, protected areas and non-color validity cues. Projectile/rolling guides show first blocker, predicted bounds or full possible envelope if an exact path is unreliable.

**Acceptance:** Every allowed orientation and boundary gives the correct ghost and actionable protected-zone/player/bounds/solid-conflict/item-rule reason; no misleading exact trajectory.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [UI_TUTORIAL.md](UI_TUTORIAL.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-PLACE-002 — Commit placement and cleanup atomically

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Confirm submits a pending edit against one phase snapshot. At resolution union Walis targets from that snapshot, remove eligible prior construction, validate remaining placements and reject entire conflicting solid sets; commit valid edits together. Never remove same-phase new pieces or protected geometry. Allow solid/trigger intersections only with readable danger regions.

**Acceptance:** Permuting callbacks/submission order yields identical committed layout; overlapping cleanup executes once; rejected sets get no partial placement. Unsupported movers reset/remove safely without crushing.

**Source:** [GDD.md](GDD.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [ITEMS.md](ITEMS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-PLACE-003 — Handle phase timing and persistent construction

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Approximate Place duration 15 s. Timeout commits the pointer item only if valid, otherwise discards it. Remove Pugad UI/collision from Play, reset items safely, retain construction until cleanup/match reset and retain removal in later rounds.

**Acceptance:** Timeout, discard, confirmation and reset cannot create duplicates; repeated rounds retain exact valid construction and do not resurrect removed objects.

**Source:** [GDD.md](GDD.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.

## 8. Karera, exact scoring and match outcomes

| Award | Value | Condition |
|---|---:|---|
| Tapos | 1.0 | Finish alive/objective completed. |
| Una | +0.25 | Earliest race finish; indistinguishable exact-first ties all receive it. |
| Bayani | +0.5 | Only finisher, including a two-player round. |
| Patibong | +0.25/kill | Directly eliminating owned hazard; no self-kill/assist; race suppression applies. |
| Bawi | +0.75 | At least 3 points behind leader at round start and finishes/wins elimination Main. |
| Barya | +0.5 | Optional coin carried across race flag; pays even when everyone finishes, but nobody earns it if no one finishes. |

In 2–4-player Karera rounds, everyone reaching the goal suppresses ordinary race awards, including Patibong, but an eligible Barya carrier still earns +0.5. Nobody reaching the goal awards zero to everyone. Otherwise the ordinary awards apply. Karera awards Una to the first finisher, but no second/third-place points or placement table. Lagsanay and Kangaroo use survival placement with no all/none suppression: in four-player play the first eliminated is fourth for zero placement points and the last survivor is first. A fourth-place chicken retains any independently earned direct Patibong. Main Challenge determines score family even with a Twist. No duplicated awards, rounded placement averages or assist points.

End-of-round total ≥10 ends a match unless leaders tie; otherwise highest after round 12 wins. Equal leaders play standalone Lagsanay sudden death among themselves. Optional session tally is not an online leaderboard or disk save.


### REQ-RACE-001 — Resolve Karera finish, failure and deadlines

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Race to the flag; death eliminates for this round, return next round. End when all players finish/fail, or at the earlier of the provisional 60 s hard cap and 15 s after first finish. Remaining runners fail at deadline. Finished players are secured against later effects.

**Acceptance:** Exercise none/some/all finish, both deadlines, last-frame finish and no live runners; resolve the round once and show the applicable reason.

**Source:** [GDD.md](GDD.md); [UI_TUTORIAL.md](UI_TUTORIAL.md). **Implementation/evidence:** implemented for the `karera_slice` development profile; see [P06 verification](evidence/p06/2026-10-14_p06_verification.md), [deadline test log](evidence/p06/regression_run_p06_tests.txt), and [live goal/results captures](evidence/p06/README.md). Automated and synthetic 2/4-seat paths pass. Physical-device, human playtest, final UI and full-release coverage remain open; 60/15 s values are provisional. Non-code decisions require their own documented review.


### REQ-SCORE-001 — Record one terminal outcome and direct attribution

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Each player has one terminal outcome and one award application per round. Earliest recorded hazard contact owns a kill; indistinguishable contacts use stable item ID. Goal versus death uses event time; indistinguishable elimination wins. Self-kill and setup assists earn no Patibong. Event elimination is never trap credit.

**Acceptance:** Replay duplicated/reordered callbacks, competing hazards and goal/death ties; one outcome remains and direct ownership is stable. Actual hazard integration is retested when P10 hazards exist.

**Source:** [GDD.md](GDD.md); [PLAYTEST.md](PLAYTEST.md). **Implementation/evidence:** per-step `RaceOutcomeLedger` with event/round identity, deduplication, stable hazard ID ordering and exactly-once score commit; see [P06 verification](evidence/p06/2026-10-14_p06_verification.md) and [ledger tests](evidence/p06/regression_run_p06_tests.txt). Hazard-source attribution currently uses test-only candidate fixtures; P10 runtime hazard integration and retest are still required. No physical-device/human review is claimed.


### REQ-SCORE-002 — Calculate race awards and suppression exactly

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Tapos 1.0 per finish; Una +0.25 for earliest finish, all exact indistinguishable first finishers receive it; Bayani +0.5 sole finisher; Patibong +0.25 per directly killed opponent subject to race scoring; Bawi +0.75 if at least 3 points behind leader at round start and finishing. All finish suppresses ordinary awards in 2/3/4-player races, but optional Barya still pays to its finisher. No finish awards zero to everyone. Ordinary awards apply when some but not all finish.

**Acceptance:** Table-driven 2/3/4-player cases cover all/none/sole/multiple finishes, exact-first ties, dead trap owner, self kill, underdog snapshot and the all-finish Barya exception; totals are exact and awarded once.

**Source:** [GDD.md](GDD.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** integer eighth-point `RaceScoreCalculator` feeds explained live results. The [2026-10-15 Barya correction](evidence/p06/2026-10-15_all_finish_barya_correction.md) verifies current 2/3/4-player all-finish suppression with the retained Barya exception; the earlier [P06 verification](evidence/p06/2026-10-14_p06_verification.md) records the superseded two-player waiver. P12 supplies only committed finisher receipt seats from its round-scoped Barya controller; the complete pickup, terminal-order, result, cleanup and all-finish behavior is recorded in [Barya evidence](evidence/barya/README.md). Rendered result readability remains synthetic; human review remains open.


### REQ-SCORE-003 — Store elimination placement ties without rounding

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Use eighth-point units or equivalent exact rational storage. Current legal non-winning groups include 4-player places 3–4 =0.125, 2–3 =0.375, 2–4 =0.25 and 3-player places 2–3 =0.25. First place is never averaged when all remaining players die: Last Cluck applies. Prototype lower loser allocation follows recorded order then averages exactly tied lower groups.

**Acceptance:** Enumerate every legal group and compare exact totals at 10 points and underdog threshold; display eighth fractions or sufficient decimals. No claim that eighths cover arbitrary future scoring tables.

**Source:** [GDD.md](GDD.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** `PlacementScoreResolver` and `ScoreFormat` use exact eighth-units for current legal groups and Last Cluck ordering; see [P06 placement cases](evidence/p06/regression_run_p06_tests.txt) and [verification record](evidence/p06/2026-10-14_p06_verification.md). This does not claim arbitrary future scoring denominators or implement Lagsanay.


### REQ-MATCH-001 — Finish matches and run tied-player sudden death

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** After authoritative round awards commit once and `ItemManager.end_round()` records the completed round, compare cumulative integer eighth-point scores to the exact 80-unit (10-point) target or completed round 12. A unique leader at threshold/limit wins; tied top scores enter Lagsanay sudden death among only those original seats. Resolve one winner from the authoritative survivor or Last Cluck result without applying Lagsanay placement awards to match totals. Round 12 cannot start round 13. The P09 route uses Karera and the P07 three-variant allowlist; it does not implement the P12 event schedule/stacks or replace release validation.

**Acceptance:** Verify below/exact/above threshold; unique/equal leaders; rounds 11/12 and threshold-plus-limit; lower-place ties; duplicate/reordered/stale callbacks; 2/3/4 tied players; a noncontiguous tied subset of four original seats; live score awards and the full round-12 transition path. Verify real-physics Lagsanay contact and survivor resolution, the authoritative Last Cluck winner path, unchanged match score during sudden death, spectator exclusion, original identity/device retention and rendered ending. Exactly one winner is returned and no placement score table is applied to match totals.

**Source:** [GDD.md](GDD.md); [PRODUCTION.md](PRODUCTION.md). **Implementation/evidence (2026-10-14):** the pure lifecycle coordinator, P09 route, live score-commit path and Lagsanay tie-break are implemented in the `karera_slice` development route. 77 focused and 108 rendered checks pass, including real contact transfer and a four-player `P2/P4` tied subset; screenshots and boundary notes are in [P09 evidence](evidence/p09/README.md). The authored P09 route is not P12 schedule completion, and device/human and 1080p performance acceptance remain open.

## 9. Lagsanay

Tag-hot-potato on the current constructed stage, with solid floor and pass-through chickens. A random taya carries a visible timer; touch transfers it without reset. Timer expiry or traps eliminate; repeat until one survivor. Opening frozen/immune taya gives others a head start. Countdown values and speed advantage are provisional, not balanced.

| Placement | 4 players | 3 players | 2 players |
|---|---:|---:|---:|
| 1st | 1.0 | 1.0 | 1.0 |
| 2nd | 0.5 | 0.5 | 0 |
| 3rd | 0.25 | 0 | N/A |
| 4th | 0 | N/A | N/A |

Simultaneous earlier eliminations average affected lower places exactly. If the simultaneous group includes everyone left, Last Cluck determines one winner instead. Patibong and winner Bawi remain available. No fixed round timer substitutes for the elimination process.


### REQ-LAG-001 — Implement opening taya, contact passing and countdown

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Choose random taya; first taya freezes hazard-immune about 3 s before countdown starts. Others disperse from shared spawn. Pass by sensor contact; nearest eligible candidate then lowest slot on exact distance tie. Prototype ongoing overlap checks permit at most one global pass per step, 1 s previous-taya immunity; pass does not reset countdown.

**Acceptance:** 2/3/4-player tests include stationary overlap, multiple candidates, immunity expiry, opening hazard contact and no opening tag; recorded countdown never resets on pass.

**Source:** [GDD.md](GDD.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** `tilaok!/scripts/match/lagsanay_round_controller.gd`, `p08_lagsanay_match_room.gd`, and `chicken_contact_sensor.gd`; 86 focused and 86 rendered engineering checks passed at 2/3/4 synthetic seats. Actual overlap sensors, opening hazard immunity, captured-player tagging, cleanup and pause-frozen clocks are covered in [P08 evidence](evidence/p08/README.md). Physical-device and independent human acceptance remain open and are not inferred from these checks.


### REQ-LAG-002 — Resolve Lagsanay eliminations and placements

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Timeout eliminates taya; trap death eliminates directly. Reassign random live taya if needed, with prototype timers 15/10/7 s at 4/3/2 alive. Last survivor wins. Placements: 4 players 1/.5/.25/0; 3 players 1/.5/0; 2 players 1/0. Patibong applies to direct hazards, Bawi to an underdog winner. No too-easy/too-hard suppression.

**Acceptance:** Timeout/trap/taya death and simultaneous earlier deaths produce one placement set; verify all player-count tables and Bawi/Patibong with direct hazard tests when available.

**Source:** [GDD.md](GDD.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** `lagsanay_round_controller.gd`, `lagsanay_score_calculator.gd`, `placement_score_resolver.gd`, and the independent hazard sink in `p08_lagsanay_match_room.gd`; 86 focused checks, 86 rendered checks, actual Trumpo direct-contact and Tsinelas Launcher projectile attribution, and placement/Bawi/Patibong checks passed. See [P08 evidence](evidence/p08/README.md). Physical-device, human fairness and independent-review acceptance remain separate.


### REQ-LAG-003 — Select exactly one Last Cluck winner

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** If all remaining chickens are eliminated in the same physics tick, latest recorded elimination time wins; exactly identical time uses lowest player slot. Remaining losers take lower placements, with the provisional exact-tie allocation documented separately. Brief freeze frame and Last Cluck callout explain the result.

**Acceptance:** Exercise 2/3/4 all-remaining eliminations, distinguishable times and exact ties; one winner only, no averaged first and no duplicate award; correct explanation appears.

**Source:** [GDD.md](GDD.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md); [UI_TUTORIAL.md](UI_TUTORIAL.md). **Implementation/evidence:** `placement_score_resolver.gd` preserves tick-only callers and compares latest recorded time only when records are marked comparable; `match_results_view_model.gd` supplies the explanation and the P08 room adds an independent brief freeze. 2/3/4-player all-final, exact-time, tick-only, callback-order and one-time score checks passed; the supplied distinguishable-time presentation fixture displays the result in [the Last Cluck capture](evidence/p08/06_last_cluck_explained_results_1920x1080.png). Fixture timestamps are not claimed as physical sub-frame measurements. See [P08 evidence](evidence/p08/README.md).

## 10. Kangaroo

The giant slipper is a background presenter, not a crushing collider. Freeze checks intentional input; Rising checks current eligible player-built support against world-space lines at 768/576/384 wu; Hug pairs live contacts at evaluation. Three misses shown as KANG/GA/ROO eliminate. Independent Kangaroo ends with one survivor and the Lagsanay placement family. Traps and input continue throughout. The standalone `kangaroo_contract_lab` has no Bomb-Taya controller; the later stack may run both systems together.

Current pair-only Hug, lowest-slot exact ties, forced Freeze+Rising Storm overlap and continuously running Bomb-Taya in the future stack remain active contracts despite documented risks. Direct hazard time wins over a command failure only when strictly earlier and comparable; a tie or unavailable comparison resolves as command failure without Patibong credit. R1–R4 alternatives are not enabled by this PRD. The team must observe and explicitly review problematic cases rather than quietly changing them.


### REQ-KANG-001 — Present and schedule independent Kangaroo commands

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Non-colliding background slipper announces Freeze sole-down, Rising sole-up/facing-down, Hug sideways at equal 1:1:1 weights. Use 1 s telegraph, 3 s response, evaluation and .75 s reset initially. Pose, text/icon, distinct audio and timing ring are redundant. World/input/traps/taya continue. Reroll Hug before telegraph at two survivors without pressure increment.

**Acceptance:** Seeded selection checks distribution and two-survivor reroll; no commands after a sole survivor; presenter never collides; full/reduced/off shake preserves comprehension.

**Source:** [GDD.md](GDD.md); [UI_TUTORIAL.md](UI_TUTORIAL.md). **Implementation/evidence:** independent controller, seeded selection, command instance state, full/reduced/off shake, and labeled debug presenter are in `kangaroo_round_controller.gd`, `kangaroo_command_instance.gd` and `p11_kangaroo_match_room.gd`. Seed/reroll/cadence and muted/Shake Off HUD checks pass; the rendered 1920×1080 debug capture is [here](evidence/p11/p11_2p_command_hud_1920x1080.png). Automated evidence only; novice comprehension and final pose/audio review remain open. See [P11 verification](evidence/p11/README.md).


### REQ-KANG-002 — Evaluate Freeze from intentional input

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** During response, intentional run/jump fails Freeze. Input already held at response start gets exactly one 0.10 s release grace; a fresh press fails immediately, and grace never renews. Shared deadzone filters drift. Opposing run buttons still count as intent. Passive motion, launch, wind or tag contact does not fail; deliberate run/jump while captured still counts.

**Acceptance:** Test drift, held/released inputs, opposite keys, forced motion, capture and passive tag; input intent and movement outcome cannot be confused.

**Source:** [GDD.md](GDD.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** `local_input_router.gd` emits physical intentional-input edges and current held sources; the controller records between-sample presses/releases. P11 tests cover tap, held release/expiry, fresh jump, opposing keys, captured input, and forced movement. The existing P02 input suite covers device thresholds; P11 results are synthetic, not physical-stick drift or human play evidence. See [P11 verification](evidence/p11/README.md).


### REQ-KANG-003 — Evaluate Rising wave with actual built support

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Select equal-probability world bands at 768/576/384 wu, never camera-relative or rerolled for an impossible layout. Telegraph target line then raise/drain wave. At evaluation require current grounded player-built eligible support at or above the line, with the documented 1-wu numerical tolerance; base, airborne, jumping through, bubble or coyote state fails.

**Acceptance:** Test every support-table state just above/on/below each band, destroyed/moving support on evaluation tick and another player’s platform; empty layout remains intentionally unsolvable; drain clears.

**Source:** [GDD.md](GDD.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md). **Implementation/evidence:** command rows lock the selected world line; `SupportTracker.evaluate` supplies current provenance/contact at evaluation; the code-drawn wave raises and drains. P11 synthetic tests cover band lines, built/base/ineligible/stale/below/removal, same-step refresh and drain; P03's 103-check real-physics support suite covers the full support-state matrix and moving/crumbling-platform evaluation. Human explanation and stage playability remain open; see [P11 verification](evidence/p11/README.md).


### REQ-KANG-004 — Evaluate pair-only Hug deterministically

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** At evaluation pair live eligible chickens by shortest contact first, equal-distance player-slot order; one partner maximum. Paired chickens pass and unpaired fail. Contact only at evaluation matters. Three clustered chickens leave one unpaired; four may form two pairs. R2 group-contact alternative remains inactive.

**Acceptance:** Verify all-contact three, two pairs of four, split groups, equal distances, entry/exit at evaluation, removed players and the two-survivor pre-telegraph reroll.

**Source:** [GDD.md](GDD.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** `pair_hug_contacts` sorts actual evaluation contacts by distance then stable seat IDs and assigns at most one partner. Automated cases cover two pairs, a three-player cluster, exact ties, evaluation-only contacts and two-player Hug rejection. Synthetic contact snapshots; physical playability remains open. See [P11 verification](evidence/p11/README.md).


### REQ-KANG-005 — Integrate failure markers, elimination and cleanup

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Failed commands add KANG, GA, ROO markers; third eliminates. A comparable direct hazard takes terminal precedence only if its timestamp is strictly earlier than command evaluation. Exact ties and unavailable/incomparable times resolve as command failure without Patibong credit for that failure. Remove terminal players from future command/tag eligibility. Last survivor uses Lagsanay placement/Bawi/Patibong rules and Last Cluck ordering. Resolve once through shared outcome infrastructure.

**Acceptance:** Test first/second/third failures, overlapping failures and trap same-step review cases; no fourth marker or duplicate placement. End/removal/restart clears scheduler, rings, wave and markers.

**Source:** [GDD.md](GDD.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md). **Implementation/evidence:** bounded markers, batched command/hazard outcomes, shared placement resolver, one-time commit and terminal cleanup are implemented. Deterministic tests cover first/second/third/fourth marker behavior, same-step/tied hazards, no-credit command failures, simultaneous Last Cluck and reset; the synthetic route verifies placement results, hazard attribution, persistent construction and teardown. See [P11 verification](evidence/p11/README.md).


### REQ-KANG-006 — Implement no-elimination acceleration and Slipper Storm

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** After every two completed commands without elimination reduce next response .5 s and reset .15 s, minimum 1 s response and zero reset. After eight enter Storm: landing every .5 s, 1 s command, maximum two active; delay a third. At two survivors force overlapping Freeze plus Rising pairs; Hug rerolls. Any elimination resets pressure/cadence. R3 non-overlap proposal remains inactive.

**Acceptance:** Check each acceleration boundary, active cap, delayed landing, two-survivor overlap, elimination reset and all-remaining Last Cluck; reproduce unavoidable-choice risks without claiming balance.

**Source:** [GDD.md](GDD.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** deterministic tests cover two-command easing, eight-command Storm entry, 0.5 s landings, 1 s windows, max-two overlap, delayed landing, the two-survivor seeded Freeze/Rising pair, no Hug, and elimination reset. These checks establish scheduler behavior only; overlap fairness and balance review remain open. See [P11 verification](evidence/p11/README.md).

## 11. Scheduling, announcements and compatible stacks

| Main | Twist | Score/end authority |
|---|---|---|
| Karera | Lagsanay | Race end/awards; secured finishers excluded from tagging and hazards. |
| Karera | Kangaroo | Race end/awards; secured finishers excluded from command/hazard effects. |
| Kangaroo | Lagsanay | Last survivor; placement family only; timer and commands continue together. |

Only these pairs may initially enter the pool after verification. Flag is hidden in standalone elimination events, while its platform/protected clearance remains. A new pair requires a full written compatibility contract and evidence. An early race-only profile may override scheduling for development but cannot silently replace required release modes.


### REQ-EVENT-001 — Select and announce the required event schedule

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Round 1 Karera; rounds 4/8/12 standalone Lagsanay. Other eligible rounds use Karera 70%, Lagsanay 20%, Kangaroo 10%. Only non-guaranteed rounds roll a Twist: 0% rounds 1–4, 10% 5–7, 20% 8–10, 30% 11–12. No self-stack, maximum one Twist, none in sudden death. Lock next round and announce Main then Twist during preceding Pugad; tutorial override only guided first Karera.

**Acceptance:** Seeded table covers all 12 rounds, guaranteed-round precedence, prior announcement consistency, zero/one compatible options and required missing-mode rejection.

**Source:** [GDD.md](GDD.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence (2026-10-15):** `EventSchedule` and `P12ScheduledMatchRoom` (the `--match-route=lifecycle` full match); P12-T01/T02 pass on automated synthetic evidence ([P12 evidence](evidence/p12/README.md)). The three Twist pairs are registered but disabled until REQ-STACK-001–003 pass, so no Twist runs yet. No player session or human review.


### REQ-EVENT-002 — Review unresolved simultaneous terminal ordering

**Scope:** REQUIRED · **Design status:** UNKNOWN · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Preserve recorded-time hazard/goal and exact-tie rules, one terminal outcome and Main-only scoring. Before integration document unresolved ordering among command evaluation, timeout, pass, goal and support destruction where existing sources do not fully determine a case. Keep proposed rule replacements inactive.

**Acceptance:** A team-reviewed decision table resolves each uncovered same-step case with source or explicit approval and corresponding scenario; no callback-order dependence or silently invented PRD rule.

**Source:** [GDD.md](GDD.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence (2026-10-15):** owner-approved decision table ([P12 decision table](evidence/p12/p12_terminal_order_decision_table.md)): C1–C15 sourced, U1–U12 approved; implemented in `BombTayaTwist`, the Kangaroo Twist role and `P12ScheduledMatchRoom`; scenarios and callback-order permutations in `run_p12_pairs_tests.gd` ([P12 evidence](evidence/p12/README.md)). Synthetic seats only; no human review.


### REQ-STACK-001 — Integrate Karera with Lagsanay pressure

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Flag remains active, bodies pass through, tag sensor works. Finishers become secured and leave taya/target/hazard eligibility. Finishing taya transfers to random unfinished live runner or resolves if none. Prototype reassignment preserves remaining countdown and gives no new opening freeze. Use race-only scoring/suppression and optional Barya.

**Acceptance:** 2/3/4 players: current taya finishes, last live runner finishes/dies, secured exclusion, timeout/goal conflict and direct trap awards; no placement score added.

**Source:** [GDD.md](GDD.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence (2026-10-15):** `BombTayaTwist` in `P12ScheduledMatchRoom`; P12-T05/T06 pass on automated synthetic evidence ([P12 evidence](evidence/p12/README.md)). Provisional same-step rows are in the [terminal-order draft](P12_TERMINAL_ORDER_DRAFT.md) pending team review. No player session or human review.


### REQ-STACK-002 — Integrate Karera with Kangaroo pressure

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Karera controls round end and scoring. Kangaroo third failure eliminates unfinished runners; secured finishers receive no commands/hazards. Flag and optional Barya stay available; command failure gives no Patibong and no extra score table.

**Acceptance:** 2/3/4 players complete all commands under race deadlines; secured finishers never gain markers, failed runners cannot finish later, race suppression and terminal ordering hold.

**Source:** [GDD.md](GDD.md); [PLAYTEST.md](PLAYTEST.md). **Implementation/evidence (2026-10-15):** `KangarooRoundController` Twist role driven by `P12ScheduledMatchRoom`; P12-T07/T08 pass on automated synthetic evidence at 2/3/4 seats ([P12 evidence](evidence/p12/README.md)). Barya is enabled on the default P12 route and is covered in both Karera stacks by the [Barya evidence](evidence/barya/README.md). No player session or human review.


### REQ-STACK-003 — Integrate Kangaroo with Lagsanay pressure

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Kangaroo is Main; Bomb-Taya passes/counts continuously including Freeze. Either third failure, timeout or trap can eliminate; last survivor wins with Lagsanay placement family only. R4 pausing the taya countdown during Freeze remains inactive.

**Acceptance:** 2/3/4 players exercise low-countdown Freeze, tag during forced movement, multiple terminal causes, Storm and Last Cluck; one award table and continuous taya time.

**Source:** [GDD.md](GDD.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence (2026-10-15):** Kangaroo Main with `BombTayaTwist` in `P12ScheduledMatchRoom`; P12-T09/T10 pass on automated synthetic evidence at 2/3/4 seats ([P12 evidence](evidence/p12/README.md)). No player session or human review.

## 12. Content inventory and scope destinations

All **36 mechanically distinct families** appear as individually identified requirements below. The first eight target submission; the other 28 are expansion. Size variants do not increase family count; Barya is separate. Catalog approval does not finalize every tuning/mechanic field or prove implementation. Family specifications below retain their original risk and reference boundaries.

The approved size-variant table takes precedence over the abbreviated default grid matrix when enumerating variants. Default matrix dimensions remain provisional. Each family has an independent promotion/enablement gate; a missing conditional orientation is an explicit dependency, never silently promised.

### Catalog destination register

| Family / requirement | Scope | Variants / enablement |
|---|---|---|
| `build.hollow_blocks` — [Hollow Blocks / Kaing Stack](#req-item-001--hollow-blocks--kaing-stack) | Required submission target | 1×1, 1×3 column, 2×3 stack; prototype slice initially 1×1 and 2×3 only. |
| `build.bamboo_bridge` — [Tulay na Kawayan](#req-item-002--tulay-na-kawayan) | Required submission target | 3×1, 4×1, 5×1; prototype starts horizontal 4×1; vertical 1×3/1×4/1×5 only after controller-support gate. |
| `move.tire_spring` — [Gulong Talon](#req-item-003--gulong-talon) | Required submission target | Single 2×2 default; transformed launch normal at 0/90/180/270 degrees. |
| `hazard.rail_trumpo` — [Trumpo sa Riles](#req-item-004--trumpo-sa-riles) | Required submission target | 4×1, 5×1, 6×1 rails; sweep matches visible length. |
| `hazard.parol_pulse` — [Parol Pulse](#req-item-005--parol-pulse) | Required submission target | 3–6 cell fixture span; both fixtures and entire beam previewed. |
| `hazard.bubble_planter` — [Bula-Bulaklak](#req-item-006--bula-bulaklak) | Required submission target | 1×3 or 1×5 bubble path; 1×1 emitter; fixed upward direction. |
| `hazard.slipper_launcher` — [Tsinelas Launcher](#req-item-007--tsinelas-launcher) | Required submission target | 4×1 or 6×1 lane; 1×1 launcher; 0/180 degrees. |
| `utility.walis_cleanup` — [Walis Cleanup](#req-item-008--walis-cleanup) | Required submission target | 3×3 or 5×5 cleanup area; no solid footprint. |
| `build.house_stairs` — [Hagdan ng Bahay](#req-item-009--hagdan-ng-bahay) | Expansion; disabled until promotion | 2×2 or 3×3 steps. |
| `build.bamboo_corner` — [Sulok na Kawayan](#req-item-010--sulok-na-kawayan) | Expansion; disabled until promotion | 2×2 or 3×3 L-shape; arms grow together. |
| `build.fragile_papag` — [Marupok na Papag](#req-item-011--marupok-na-papag) | Expansion; disabled until promotion | 2×1 or 3×1 platform. |
| `hazard.flipping_banig` — [Baliktad na Banig](#req-item-012--baliktad-na-banig) | Expansion; disabled until promotion | Single default from grid matrix: 3×1 footprint; Active face: 3×1 active region. |
| `move.rope_raft` — [Balsa sa Lubid](#req-item-013--balsa-sa-lubid) | Expansion; disabled until promotion | 2×1 or 3×1 raft; 5×1 or 7×1 path; both visible. |
| `move.basket_lift` — [Angat-Kaing](#req-item-014--angat-kaing) | Expansion; disabled until promotion | 2×1 lift; 2×4 or 2×6 path. |
| `move.perya_wheel` — [Perya Wheel](#req-item-015--perya-wheel) | Expansion; disabled until promotion | Single default from grid matrix: 5×5 envelope footprint; Same 5×5 orbit envelope active region. |
| `move.palay_conveyor` — [Palay Conveyor](#req-item-016--palay-conveyor) | Expansion; disabled until promotion | 3×1 or 4×1 surface. |
| `move.bentilador` — [Bentilador](#req-item-017--bentilador) | Expansion; disabled until promotion | 3×3 or 5×3 air corridor, not just fan footprint. |
| `move.water_jet` — [Bomba ng Tubig](#req-item-018--bomba-ng-tubig) | Expansion; disabled until promotion | 1×3 or 1×5 jet. |
| `move.kite_ferry` — [Saranggola Ferry](#req-item-019--saranggola-ferry) | Expansion; disabled until promotion | Single default from grid matrix: Kite: 2×1 footprint; Travel lane: 7×1 active region. |
| `modifier.sorbetes_ice` — [Yelo ng Sorbetero](#req-item-020--yelo-ng-sorbetero) | Expansion; disabled until promotion | 3×1 or 4×1 surface. |
| `modifier.malagkit_patch` — [Malagkit Patch](#req-item-021--malagkit-patch) | Expansion; disabled until promotion | Single default from grid matrix: 3×1 footprint; Surface effect: 3×1 active region. |
| `hazard.toy_burr_strip` — [Tinik-Tinik Strip](#req-item-022--tinik-tinik-strip) | Expansion; disabled until promotion | 3×1 or 4×1 strip. |
| `hazard.surprise_broom` — [Gulat na Walis](#req-item-023--gulat-na-walis) | Expansion; disabled until promotion | Single default from grid matrix: Anchor: 1×1 footprint; Trigger: 2×2; strike: 3×1 active region. |
| `hazard.orbit_trumpo` — [Umiikot na Trumpo](#req-item-024--umiikot-na-trumpo) | Expansion; disabled until promotion | 3×3 or 5×5 sweep; pivot 1×1. |
| `hazard.coconut_pendulum` — [Niyog Pendulum](#req-item-025--niyog-pendulum) | Expansion; disabled until promotion | 3×3 or 5×5 sweep; pivot 1×1. |
| `hazard.slipper_jab` — [Sipa ng Tsinelas](#req-item-026--sipa-ng-tsinelas) | Expansion; disabled until promotion | Single default from grid matrix: Anchor: 1×1 footprint; Jab lane: 3×1 active region. |
| `hazard.aiming_pot` — [Gulat na Palayok](#req-item-027--gulat-na-palayok) | Expansion; disabled until promotion | Single default from grid matrix: 1×1 footprint; Aim/swat area: 4×3 active region. |
| `hazard.tansan_ricochet` — [Tansan Ricochet](#req-item-028--tansan-ricochet) | Expansion; disabled until promotion | Single default from grid matrix: 1×1 footprint; Initial lane: 6×1; maximum bound: 6×4 active region. |
| `hazard.coconut_chute` — [Niyog Chute](#req-item-029--niyog-chute) | Expansion; disabled until promotion | Single default from grid matrix: Chute: 2×1 footprint; Downhill lane: up to 6×1 active region. |
| `hazard.steam_burst` — [Singaw Steamer](#req-item-030--singaw-steamer) | Expansion; disabled until promotion | 2×2 or 3×2 plume. |
| `hazard.kuliglig_swarm` — [Gulong Kuliglig](#req-item-031--gulong-kuliglig) | Expansion; disabled until promotion | Single default from grid matrix: Emitter: 1×1 footprint; Chase boundary: 5×5 active region. |
| `hazard.ipo_ipo` — [Ipo-Ipo](#req-item-032--ipo-ipo) | Expansion; disabled until promotion | Single default from grid matrix: Core: 1×1 footprint; Pull radius envelope: 5×5 active region. |
| `move.kambal_na_pinto` — [Kambal na Pinto](#req-item-033--kambal-na-pinto) | Expansion; disabled until promotion | Single default from grid matrix: Each door: 1×2 footprint; Exit clearance: 1×2 per door active region. |
| `move.balsa_fan` — [Balsa-Bentilador](#req-item-034--balsa-bentilador) | Expansion; disabled until promotion | Single default from grid matrix: Platform: 3×1 footprint; Path/air envelope: 6×4 active region. |
| `move.rotating_drum` — [Umiikot na Dram](#req-item-035--umiikot-na-dram) | Expansion; disabled until promotion | Single default from grid matrix: 3×3 footprint; Same 3×3 rotation envelope active region. |
| `hazard.toy_tricycle` — [Peryang Traysikel](#req-item-036--peryang-traysikel) | Expansion; disabled until promotion | 6×1 or 8×1 lane; body remains 2×1. |


### Earlier ideas, parked events and exclusions

| Idea | Destination and boundary |
|---|---|
| Rolling niyog, charging tricycle | Earlier brainstorms retained; Niyog Chute/Peryang Traysikel are related catalog proposals, not proof that the original idea was replaced or implemented. |
| Sampayan, kawali of hot oil, banana-peel slip | Uncommitted brainstorm ledger; any promotion needs wholesome presentation, original mechanics and full contract. |
| Bomb | Distinct uncommitted removal proposal; radius/item-cap behavior unresolved, protects base/floor/spawn/flag. Walis does not silently replace it. |
| Basic platforms/springs | Broad earlier ideas; Kaing/Tulay/Gulong are specific approved catalog implementations, with no extra anonymous family commitment. |
| Tumba Lata, Sikyo, Sepak Takraw, Dr. Quack Quack | Parked pending design/cultural review; Sikyo is not assumed to equal Syato. |
| Agawan Base | Excluded: team mode breaks the intended three-player free-for-all scope. |
| Patintero / Tubigan | Explicitly cut; no implementation work without renewed approval. |

Backlog comparison never silently replaces Langit-Lupa, Agawan Buko or another approved identity. Names and real-world claims remain reviewable.


### REQ-OPT-001 — Barya

**Scope:** SHOULD · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Race-only optional pickup: about 1-in-3 Pugad appearance replacing one egg; one per round, picker places it, carrier visible, drop on death for others, finish while carrying earns +0.5 even when everyone finishes; remove at round end, never persist as a 37th obstacle.

**Acceptance:** Test contested pickup/drop/death/finish, one-coin cap, suppression exception, stacked races, cleanup and disabled pool.

**Source:** [GDD.md](GDD.md); [ITEMS.md](ITEMS.md). **Implementation/evidence (2026-10-15):** implemented in the default scheduled P12 match with `--barya-disabled` rollback and P07 disabled. Deterministic policy, placement, actual Area2D pickup, drops/recovery, terminal ordering, score/history, cleanup/retry and UI gates pass; the 72-check focused suite, eight rendered captures, 14 dependent suites, Windows export, default/P12/P07/rollback startup smoke and 4-seat performance sample are recorded in [Barya evidence](evidence/barya/README.md). Input was synthetic; physics overlaps used Godot's actual physics server. No human, physical-device, accessibility, cultural or independent review is claimed; final art and audio remain human-team work. Barya remains Should content and does not ratify the release manifest.


### REQ-OPT-002 — Local session win tally

**Scope:** SHOULD · **Design status:** OPTIONAL · **Owner role:** Art/UI (name TBD).

**Expected behavior:** Optional match-result win tally persists between matches only in current process/session; no account, disk save, cloud sync or migration.

**Acceptance:** Replay increments only the actual winner once; lobby return retains session tally; new process clears it; disabled option does not block results.

**Source:** [GDD.md](GDD.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-OPT-003 — Enhanced crowd and spectator cheer

**Scope:** SHOULD · **Design status:** OPTIONAL · **Owner role:** Audio (name TBD).

**Expected behavior:** Enhanced crowd: rooster start, trap anticipation, soft elimination/fall groan, gasp, finish/Una cheer, none/all-finish reactions, Bawi celebration, late-taya drumroll, final-two tension and winner chant. Optional player-colored fans and tension 0–1 drive ambient mix. Spectator cheer has no simulation effect and prototype 1 s cooldown.

**Acceptance:** Each enabled reaction triggers once at the correct moment; no rapid spam/overload, critical cues remain audible/visible and all crowd assets are registered.

**Source:** [GDD.md](GDD.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-OPT-004 — Reviewed educational cards

**Scope:** SHOULD · **Design status:** OPTIONAL · **Owner role:** Compliance (name TBD).

**Expected behavior:** Optional Alam mo ba cards explain a real traditional game, region and real-life rules before its event using reliable evidence and native-speaker review. Do not describe fictional item/Kangaroo rules as verified tradition.

**Acceptance:** Every public claim has reviewed evidence/date; cards are concise/readable and do not misrepresent the implemented adaptation.

**Source:** [COMPETITION.md](COMPETITION.md); [ASSETS.md](ASSETS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-OPT-005 — Langit-Lupa

**Scope:** SHOULD · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Named second laro ng lahi remains a Should event, not displaced by Kangaroo. Rising floor, survive to end; documented mapping is Tapos for survivors and Una for highest position. Detailed timer/height/tie/stack behavior requires a contract before implementation.

**Acceptance:** Approve unresolved rules, then test 2/3/4 players, reachable/blocked layouts, terminal/scoring/reset and tutorial/Library before enablement.

**Source:** [GDD.md](GDD.md); [ROADMAP.md](ROADMAP.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-OPT-006 — Cosmetic skins and accessories

**Scope:** SHOULD · **Design status:** OPTIONAL · **Owner role:** Art/UI (name TBD).

**Expected behavior:** Distinct chicken color/shape identity is required; richer skins/accessories beyond the required readable set are optional. Preserve marker visibility, wholesome silhouettes and asset/cultural provenance.

**Acceptance:** Optional cosmetics cannot obscure chicken number/shape or hazards, affect collisions, or imply gameplay advantages.

**Source:** [GDD.md](GDD.md); [ROADMAP.md](ROADMAP.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-BACKLOG-001 — Luksong Tinik / 10–20 Garter

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Compare and choose one implementation family; define telegraph, sweep/thickness, platform interaction, avoidance and anti-camping. Existing Luksong Tinik mapping is survive all waves for Tapos, no Una.

**Acceptance:** Approved comparison and contract precede code; 2/3/4-player avoidance, scoring, reset and help pass.

**Source:** [GDD.md](GDD.md); [ITEMS.md](ITEMS.md); [ROADMAP.md](ROADMAP.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-BACKLOG-002 — Agawan Buko / Jackstone comparison

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Agawan Buko remains coconut collection: holding at least one at end gives Tapos, most gives Una. Compare Jackstone without automatic replacement; define supply/quota by count, reachable spawns, contested collection, elimination drops and impossible-quota recovery.

**Acceptance:** Resolve ties and collection/ownership rules, then verify all counts, clutter, drops and impossible quotas before enablement.

**Source:** [GDD.md](GDD.md); [ITEMS.md](ITEMS.md); [ROADMAP.md](ROADMAP.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-BACKLOG-003 — Sipa

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Prototype only after choosing responsibility rules that do not punish the player keeping the ball aloft. Define contact credit, equal distance, body collision, bounds/unreachable recovery and terminal scoring.

**Acceptance:** Approved responsibility and recovery contract plus 2/3/4-player fairness/reset evidence precedes pool inclusion.

**Source:** [GDD.md](GDD.md); [ITEMS.md](ITEMS.md); [ROADMAP.md](ROADMAP.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-BACKLOG-004 — Additional stages and event pairs

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Extra stages and unlisted Main/Twist pairs are expansion. Each pair needs written input/collision/terminal/scoring/secured-state/presentation compatibility; each stage needs protected zones, bounds/support/readability and device/performance tests.

**Acceptance:** New content remains disabled until a named promotion and complete compatibility/quality evidence; no silent third concurrent event.

**Source:** [GDD.md](GDD.md); [ITEMS.md](ITEMS.md); [ROADMAP.md](ROADMAP.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-BACKLOG-005 — Retain parked events and earlier brainstorm dispositions

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Producer (name TBD).

**Expected behavior:** Park Tumba Lata, Sikyo, Sepak Takraw and Dr. Quack Quack with cultural/mechanic review before promotion; do not equate Sikyo and Syato. Retain earlier rolling niyog, sampayan, kawali, charging tricycle, banana peel, Bomb and generic platforms/springs as uncommitted ideas. Bomb remains distinct from Walis. Agawan Base and Patintero/Tubigan remain explicitly cut.

**Acceptance:** Disposition ledger names every idea, relationship to catalog if any and promotion/exclusion reason; no parked/cut idea is playable by default or counted as required.

**Source:** [GDD.md](GDD.md); [ITEMS.md](ITEMS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


**Event and stack integration (2026-10-16):** REQ-ITEM-001 to REQ-ITEM-008 now have their event/scoring integration implemented and verified on synthetic evidence (P04-T11/T20, P10-T07/T16/T25/T34/T43/T52): mode-filtered Pugad eggs on the scheduled match route and real-piece credit checks in every independent mode and supported stack. The six P10 families are in the match pool. Release enablement remains open per family. See [ITEMS](ITEMS.md#event-and-stack-integration--2026-10-16).

### REQ-ITEM-001 — Hollow Blocks / Kaing Stack

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Solid construction pieces create footholds, walls, routes, and projectile cover. Danger is route obstruction or hiding a tell. Tell: strong distinct crate silhouette and placement ghost. Counter: jump around/over, use another route, or Walis Cleanup. UCH basic-block inspiration; original barrio treatment. One-cell and 2×3-cell variants in a single family; 90° rotation where footprint changes. Solid full footprint, no trigger. No overlap with protected geometry or other solids; projectile occlusion uses actual solid volume. Footprint and item cap are tunables. Usable in race and event rounds including Lagsanay. Owner is placer; removable by Walis Cleanup; persists until removed, no moving state. Needs original crate/block sprites and sound. Low relative risk; depends on placement grid/collision and cleanup. Cultural check: “kaing” use/context. Approved size inventory: 1×1, 1×3 column, 2×3 stack; prototype slice initially 1×1 and 2×3 only. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** core family implemented and harness-verified 2026-10-13 (P04-T05–T09): 1×1, 2×3, rotated 3×2 enabled; 1×3 defined but disabled. Preview/Library, event integration and release enablement remain open (P04-T10–T13). See [P04 verification index](evidence/p04/2026-10-13_p04_verification.md).


### REQ-ITEM-002 — Tulay na Kawayan

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** One-way thin bridge creates a route; its underside can be passed through, so it may be missed or become an ambush landing. Tell: narrow bamboo silhouette and one-way arrow on ghost. Counter: approach from below to pass through, or use another path. Inspired by the general utility-platform role; one-way behavior is Tilaok’s adaptation. One-way solid top, non-solid underside/sides; horizontal/vertical rotation in 90° steps if the movement model supports both. Footprint distinct from top collision strip. Length, thickness, allowed rotations are tunables. Race and event terrain; enabled in Lagsanay only after safe-floor compatibility review. Placer owns it; cleanup removes it, otherwise persists. Static reset. Needs original bridge art. Medium risk because one-way collision must match run/jump-only controls. Verify material/name culturally; no “traditional rule” claim. Approved size inventory: 3×1, 4×1, 5×1; prototype starts horizontal 4×1; vertical 1×3/1×4/1×5 only after controller-support gate. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** core family implemented and harness-verified 2026-10-13 (P04-T14–T18): horizontal 4×1 enabled; 3×1/5×1 defined but disabled; vertical orientation gated and geometry-only. Preview/Library, event integration, Lagsanay safe-floor review and release enablement remain open (P04-T19–T22). See [P04 verification index](evidence/p04/2026-10-13_p04_verification.md).


### REQ-ITEM-003 — Gulong Talon

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Contact bounce launches a chicken; timed jump input boosts height. It creates a useful shortcut but can throw players into hazards. Tell: visible compression/coil and bounce arc cue. Counter: approach slowly, decline the boost, or time the jump. Spring is verified community-wiki reference pattern; tire/playful presentation and tuning are original. 2×2 logical footprint proposal; top is launch trigger, body is solid support. Rotation 0/90/180/270; direction follows the transformed launch normal. Force, jump bonus, footprint, cooldown, and grace are tunables. Race and Lagsanay; Lagsanay force must not bypass solid-floor containment. Placer owns trap attribution only if the spring impact itself eliminates; otherwise no assist credit. Resets force/cooldown at Play. Needs original tire animation/audio and movement-state interface. Medium-high risk: player launch state and ceiling/bounds safety. Approved size inventory: Single 2×2 default; transformed launch normal at 0/90/180/270 degrees. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence (2026-10-14):** implemented and verified in the development `items_lab` profile with PLACEHOLDER art/audio and synthetic input (P10-T01–T06 and T08 PASSED); see [P10 verification index](evidence/p10/2026-10-14_p10_verification.md). Event integration (Lagsanay/Kangaroo/stacks) and release enablement are not done and stay COULD-NOT-RUN pending P08-T06, P11-T12, P12-T04/T06/T08/T10 and P13-T06. No human review is claimed.


### REQ-ITEM-004 — Trumpo sa Riles

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** A playful spinning top travels along a short visible rail, pauses at ends, and eliminates on contact. Safe gaps/endpoint pauses allow timing. Tell: rail, rotation, endpoint pause and audio cue. Counter: cross during pause/gap or route above/below. Verified inspiration: Linear Saw’s back-and-forth path; original trumpo, safe timing, and tuning. Place a bounded rail segment; footprint is anchor/rail; sweep is separate and shown in preview. Rotate in 90° increments, with deterministic start direction. Speed, pause, rail length, hitbox width, grace are tunables. No off-camera or unbounded path. Race and event terrain; Lagsanay enabled only after playtest. Owner gets Patibong only for direct contact elimination. Resets to start endpoint and deterministic direction each Play; cleanup releases mover. Needs original top/rail animations, sound, and mover lifecycle. Medium-high risk: collision ordering and sweeps. Approved size inventory: 4×1, 5×1, 6×1 rails; sweep matches visible length. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence (2026-10-14):** implemented and verified in the development `items_lab` profile with PLACEHOLDER art/audio and synthetic input (P10-T10–T15 and T17 PASSED); see [P10 verification index](evidence/p10/2026-10-14_p10_verification.md). Event integration (Lagsanay/Kangaroo/stacks) and release enablement are not done and stay COULD-NOT-RUN pending P08-T06, P11-T12, P12-T04/T06/T08/T10 and P13-T06. No human review is claimed.


### REQ-ITEM-005 — Parol Pulse

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Two visible fixtures project a timed light barrier; crossing active span eliminates. A 3-second cycle has 1.5s active and 1.5s inactive; charge-up occupies the final part of inactive time, so it does not extend the cycle. Tell: fixture icons, brightness ramp, non-flashing shape change and audio cue. Counter: cross during safe interval or use cover if cover truly blocks it. Original Tilaok proposal; not UCH reference. Two endpoint anchors define span and collision width; endpoints/beam shown in preview. Horizontal/vertical orientation only. Default proposal: solids block the beam; define and show occlusion. Cycle, charge time (inside inactive 1.5s), width, range and grace are tunables. Race and event; Lagsanay only after readability and balance pass. Placer owns direct elimination. Resets phase to inactive/charge at Play start. Needs distinct beam art/audio, overlap readability test. Medium risk; verify at minimum zoom and with multiple emitters. No rapid strobe. Approved size inventory: 3–6 cell fixture span; both fixtures and entire beam previewed. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence (2026-10-14):** implemented and verified in the development `items_lab` profile with PLACEHOLDER art/audio and synthetic input (P10-T19–T24 and T26 PASSED); see [P10 verification index](evidence/p10/2026-10-14_p10_verification.md). Event integration (Lagsanay/Kangaroo/stacks) and release enablement are not done and stay COULD-NOT-RUN pending P08-T06, P11-T12, P12-T04/T06/T08/T10 and P13-T06. No human review is claimed.


### REQ-ITEM-007 — Tsinelas Launcher

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Telegraphs then fires a slipper along a straight lane; hit eliminates. Solids block the projectile. Tell: barrel/aim lane, charge animation and sound. Counter: cover, dodge, or cross outside firing lane. Projectile-launcher pattern is broad reference; slipper, timing, and cover interactions are original. One-cell launcher footprint plus distinct visible lane/hitbox, 0/180° rotation. No projectile spawn inside solid/player/protected area. Fire delay, speed, lifetime, cap, cooldown, hitbox, target policy are tunables. Race and event; Lagsanay only after body/tag and projectile balance checks. Launcher placer owns direct hit. Projectile has bounded lifetime and is removed at round end/removal. Needs original slipper sprite/animation and projectile pooling if profiling supports it. Medium-high risk: projectile collision ordering and cleanup. No weapon realism. Approved size inventory: 4×1 or 6×1 lane; 1×1 launcher; 0/180 degrees. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence (2026-10-14):** implemented and verified in the development `items_lab` profile with PLACEHOLDER art/audio and synthetic input (P10-T28–T33 and T35 PASSED); see [P10 verification index](evidence/p10/2026-10-14_p10_verification.md). Event integration (Lagsanay/Kangaroo/stacks) and release enablement are not done and stay COULD-NOT-RUN pending P08-T06, P11-T12, P12-T04/T06/T08/T10 and P13-T06. No human review is claimed.


### REQ-ITEM-008 — Walis Cleanup

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** During Place only, removes player-built pieces inside a previewed bounded area. Restores a route obstructed by accumulated stage clutter. No Play-phase behavior, no direct damage, no trap credit. Tell: broom preview outlines every exact target and protected exclusion. Counterplay is to place thoughtfully; cleanup is limited by one item use and fixed radius. Broad inspiration from UCH Bomb’s removal role; one-shot construction edit is original. Bounded radius/region with preview; no rotation needed. Never targets base geometry, spawn/goal clearance, hidden event goal, or same-phase newly submitted pieces. Resolve as one removal set, then validate other placements against resulting snapshot; no callback-order dependence. Radius and eligible item categories are tunables. Construction-only in race and event rounds; no Lagsanay Play effect. Owner is cleaner for edit audit only, never Patibong. Removed objects do not return on reset. Needs clear ghost/target list and protected-zone outlines. Medium risk: atomic simultaneous edit semantics and support cleanup. Approved size inventory: 3×3 or 5×5 cleanup area; no solid footprint. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence (2026-10-14):** implemented and verified in the development `items_lab` profile with PLACEHOLDER art/audio and synthetic input (P10-T37–T42 and T44 PASSED); see [P10 verification index](evidence/p10/2026-10-14_p10_verification.md). Event integration (Lagsanay/Kangaroo/stacks) and release enablement are not done and stay COULD-NOT-RUN pending P08-T06, P11-T12, P12-T04/T06/T08/T10 and P13-T06. No human review is claimed.


### REQ-ITEM-006 — Bula-Bulaklak

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Emits one bubble at a time along a fixed upward path/cadence. Captures one live chicken for about 2s; no control while held; never eliminates itself. It can displace a player into another trap or past a route. Tell: visible bubble path, cadence and captive icon. Counter: time the gap or let another direct hazard be avoided after release. Original Tilaok proposal; no plant identification or educational claim. Emitter footprint separate from bubble trigger/path; vertical fixed path, no rotation in v1. One captive per bubble and one bubble per player. Cadence, path, capture time (~2s), release velocity, grace, bubble cap are tunables. Stop/resolve against ceiling and bounds; release at nearest safe non-overlapping position with bounded velocity. If no safe location exists, release at last safe point with zero velocity. Race: captive must be released before goal completion; captured player can be hit by external traps. Lagsanay: timer continues and captive remains taggable; disable in Lagsanay if capture-to-elimination is unavoidable. Exclude dead/finished/already-captured players; simultaneous captures resolved by stable player ID and bubble ID; short immunity prevents immediate re-capture. Bubble gives no Patibong; actual eliminating trap does. Remove bubble/captive state on death/end/restart/emitter removal. Needs custom player-state lifecycle and cage-free release tests; highest risk, last in A. Approved size inventory: 1×3 or 1×5 bubble path; 1×1 emitter; fixed upward direction. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence (2026-10-14):** implemented and verified in the development `items_lab` profile with PLACEHOLDER art/audio and synthetic input (P10-T46–T51 and T53 PASSED); see [P10 verification index](evidence/p10/2026-10-14_p10_verification.md). Event integration (Lagsanay/Kangaroo/stacks) and release enablement are not done and stay COULD-NOT-RUN pending P08-T06, P11-T12, P12-T04/T06/T08/T10 and P13-T06. No human review is claimed.


### REQ-ITEM-009 — Hagdan ng Bahay

**Promoted 2026-10-16 (Jorge):** implemented as block scenes with DEBUG art and in the match egg pool; presentation, integration and verification tasks stay open (P19). Evidence: [P19 promoted](evidence/p19_promoted/README.md).

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; build; UCH Stairs family reference, Filipino staircase design original. Multi-step footholds; can create a steep obstacle. Tell: stair silhouette. Counter: alternate jump route. Solid stepped footprint; 90° rotations. Tune tread count/height and footprint. Terrain in both modes; placer owns removable static piece; medium risk: collision seams. Approved size inventory: 2×2 or 3×3 steps. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-010 — Sulok na Kawayan

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; build/cover; UCH L Girder pattern reference. L-shaped ledge/cover gives foothold and projectile defense; may occlude tells. Outline both arms; route around. Solid L footprint; four rotations. Tune arm length/clearance. Terrain; placer owns, cleanup removes; low-medium risk: multi-cell overlap validation. Approved size inventory: 2×2 or 3×3 L-shape; arms grow together. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-011 — Marupok na Papag

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; temporary platform; crumbling-block pattern reference. Temporary bridge collapses after landings; visible cracks warn. Counter: cross quickly or use another route. Solid footprint, no rotation or 180°; tune landing count/recovery. Race/event; collapse state resets next Play; no kill credit from falling unless direct hazard owns it. Medium risk: simultaneous landing. Approved size inventory: 2×1 or 3×1 platform. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-012 — Baliktad na Banig

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; alternating platform; flipping-block pattern reference. Periodically usable/unsafe face changes after warning; tell by shape/icon. Counter: leave during warning. Defined solid top and trigger face; 180° rotation. Tune phase/duration/grace. Both modes after Lagsanay test; resets phase; placer owns only direct elimination. Medium-high moving-collision risk. Approved size inventory: Single default from grid matrix: 3×1 footprint; Active face: 3×1 active region. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-013 — Balsa sa Lubid

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; horizontal mover; moving-platform family reference. Shuttle crosses a gap, enabling timed boarding; endpoints pose falls. Tell: rope/endpoint pause. Counter: board at pause or jump off. Platform footprint separate bounded horizontal sweep; horizontal only. Tune speed/pause/range/cap. Both modes; resets to endpoint/direction; no assist credit. High risk: rider carry/support lifecycle. Approved size inventory: 2×1 or 3×1 raft; 5×1 or 7×1 path; both visible. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-014 — Angat-Kaing

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; vertical mover; moving-platform family reference. Lift reaches high routes; endpoint timing risks falls. Tell: visible guide and endpoint pause. Counter: wait for basket. Solid top, bounded vertical sweep; rotate not allowed. Tune height/speed/pause. Both modes subject to Lagsanay containment; reset deterministic; high risk: platform carrying/player state. Approved size inventory: 2×1 lift; 2×4 or 2×6 path. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-015 — Perya Wheel

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** C; orbit mover; Ferris Wheel reference. Several rideable footholds circle an axle; transfers are risky. Tell: visible full orbit. Counter: board near low arc, dismount. Footprint is pivot/arms, sweep separate; fixed rotation direction. Tune radius/speed/platform count. Both modes only after event testing; reset angle; high risk: multi-platform collision. Approved size inventory: Single default from grid matrix: 5×5 envelope footprint; Same 5×5 orbit envelope active region. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-016 — Palay Conveyor

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; conveyor modifier; Treadmill reference. Carries grounded players sideways; running against it changes traversal. Tell: belt texture and motion marks. Counter: reverse run or leave surface. Surface footprint only; 0/180° orientation. Tune velocity and acceleration. Both modes; modifier owner not trap credit unless direct lethal interaction exists. Medium dependency on grounded-state handling. Approved size inventory: 3×1 or 4×1 surface. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-017 — Bentilador

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; force field; Fan reference. Visible airflow pushes chickens, changing jumps near hazards. Counter: cover if blocking is enabled or move out of corridor. Footprint anchor plus force rectangle; four rotations. Tune force/falloff/blocking. Both modes after Lagsanay and item tests; resets field state; no assist credit. Medium-high force/bounds risk. Approved size inventory: 3×3 or 5×3 air corridor, not just fan footprint. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-018 — Bomba ng Tubig

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; pulsed movement; Hydrant family reference. Timed upward water burst boosts route; can push into trap. Tell: pressure gauge and rising sound. Counter: cross between bursts. Jet corridor distinct from solid footprint; rotate 90°; tune cadence/force/duration. Both modes after safe-floor test; resets idle. Medium-high player launch dependency. Approved size inventory: 1×3 or 1×5 jet. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-019 — Saranggola Ferry

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** C; periodic mover; Paper Airplane Shooter family reference. Small rideable kite platform traverses a bounded path then despawns; supports crossing. Tell: launch spool/path. Counter: dismount before endpoint. Platform and path separate; 0/180° lane. Tune dwell/path/lifetime/cap. Race/event after Lagsanay safety review; resets docked. High risk: transient platform support. Approved size inventory: Single default from grid matrix: Kite: 2×1 footprint; Travel lane: 7×1 active region. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-020 — Yelo ng Sorbetero

**Promoted 2026-10-16 (Jorge):** implemented as block scenes with DEBUG art and in the match egg pool; presentation, integration and verification tasks stay open (P19). Evidence: [P19 promoted](evidence/p19_promoted/README.md).

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; surface modifier; Ice reference. Reduces braking for longer slides; can carry player into danger. Tell: frosty edge pattern. Counter: jump off or plan stopping distance. Surface-only footprint; 90° orientation irrelevant. Tune friction and max speed. Both modes; no trap credit; reset is static. Medium movement tuning. Approved size inventory: 3×1 or 4×1 surface. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-021 — Malagkit Patch

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; surface modifier; Honey slowing role only. Slows player/reduces jump while touching; no object attachment in v1. Tell: textured sticky patch. Counter: jump over or avoid. Surface trigger, 0/90°; tune speed/jump multipliers. Both modes; no assist credit; static reset. Medium movement-state restoration risk. Approved size inventory: Single default from grid matrix: 3×1 footprint; Surface effect: 3×1 active region. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-022 — Tinik-Tinik Strip

**Promoted 2026-10-16 (Jorge):** implemented as block scenes with DEBUG art and in the match egg pool; presentation, integration and verification tasks stay open (P19). Evidence: [P19 promoted](evidence/p19_promoted/README.md).

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; contact hazard; Barbed Wire spatial role reference. Narrow marked strip eliminates on contact, allowing face-level defense. Tell: soft oversized burr silhouette. Counter: jump over/route around. Thin trigger strip, four rotations; tune thickness/active faces. Both modes after wholesome-art review; placer receives direct kill credit; static reset. Medium readability risk. Approved size inventory: 3×1 or 4×1 strip. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-023 — Gulat na Walis

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; trigger hazard; Trigger Spikes pattern reference. Footstep trigger warns then raises soft bristles; bait it and cross recovery. Marked trigger area vs narrow hitbox; rotate 90°. Tune trigger radius/warning/recovery. Race/event after Lagsanay floor check; owner only on direct hit; resets armed. Medium-high trigger race risk. Approved size inventory: Single default from grid matrix: Anchor: 1×1 footprint; Trigger: 2×2; strike: 3×1 active region. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-024 — Umiikot na Trumpo

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; orbiting hazard; Spinning Saw pattern reference distinct from rail trumpo. Tethered top sweeps circular zone; time gap around orbit. Tell: visible tether and arc. Pivot footprint vs swept danger region; fixed orbit, 90° start phase. Tune radius/period/width. Both modes after event test; owner direct hit; resets angle. High sweep collision risk. Approved size inventory: 3×3 or 5×5 sweep; pivot 1×1. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-025 — Niyog Pendulum

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; swing hazard; Wrecking Ball pattern reference. Padded coconut swings a predictable arc across a route. Tell: full arc and endpoint pause. Counter: pass behind pivot or time swing. Anchor footprint and arc separate; four start orientations. Tune arc/period/width. Both modes after Lagsanay safety test; reset endpoint; medium-high mover collision risk. Approved size inventory: 3×3 or 5×5 sweep; pivot 1×1. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-026 — Sipa ng Tsinelas

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; triggered strike; Boxing Glove pattern reference. Pressure/contact trigger launches a short slipper jab. Tell: button compresses and arm winds up. Counter: bait then pass during cooldown. Anchor, trigger zone and fixed jab lane separate; four orientations. Tune range/warning/cooldown. Race/event; direct strike owner; reset idle. Medium-high projectile/hitbox lifecycle. Approved size inventory: Single default from grid matrix: Anchor: 1×1 footprint; Jab lane: 3×1 active region. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-027 — Gulat na Palayok

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; targeting hazard; Punching Flower pattern reference. Detects a chicken, visibly aims, then releases padded swat. Counter: bait aim then move. Footprint plus limited target range/swat lane; 90° rotate. Tune reacquire, telegraph, range. Both modes after fairness test; direct hit attribution; resets neutral. High risk: target selection determinism. Approved size inventory: Single default from grid matrix: 1×1 footprint; Aim/swat area: 4×3 active region. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-028 — Tansan Ricochet

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; bounded projectile; bouncing projectile family reference. Toy cap ricochets a bounded number then expires. Tell: direction preview and bounce count icon. Counter: solid cover/leave lane. Launcher footprint, lane/sweep separate; four orientations. Tune bounce/lifetime/cap/speed. Both modes only after projectile cap test; launcher owns direct kill; cleanup at end. High risk: deterministic collision and transient count. Approved size inventory: Single default from grid matrix: 1×1 footprint; Initial lane: 6×1; maximum bound: 6×4 active region. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-029 — Niyog Chute

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; gravity projectile; original barrio adaptation. Rumble warns before coconuts roll downhill/off ledges. Counter: step out of lane or use cover. Chute anchor and terrain-following lane; rotate 180°. Tune warning, launch interval, speed, cap. Both modes only when direct hit attribution is stable; resets empty. High risk: terrain traversal and transient cleanup. Approved size inventory: Single default from grid matrix: Chute: 2×1 footprint; Downhill lane: up to 6×1 active region. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-030 — Singaw Steamer

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** B; timed area hazard; timed-area role references Flamethrower, visuals/behavior original. Cartoon steam plume blocks passage briefly; no burn imagery. Tell: valve hiss and pressure rise. Counter: cross during cooldown. Emitter footprint and plume rectangle separate; four rotations. Tune warning, reach, duty cycle. Race/event after Lagsanay test; owner on direct contact elimination; resets depressurized. Medium readability/timing risk. Approved size inventory: 2×2 or 3×2 plume. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-031 — Gulong Kuliglig

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** C; bounded chase; Beehive chase pattern reference. Fictional noisy insect swarm pursues a visibly marked target briefly. Counter: survive until expiry/route away. Emitter and chase boundary separate; no rotation. Tune target rule, duration, speed, cap. Lagsanay disabled initially; race only until fair target policy proves out. Direct source owns elimination. High AI/target-state risk; fictional insect art, no real-species claims. Approved size inventory: Single default from grid matrix: Emitter: 1×1 footprint; Chase boundary: 5×5 active region. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-032 — Ipo-Ipo

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** C; force/core hazard; Black Hole attraction pattern reference. Bounded visible pull toward small elimination core; strength cap keeps escape possible. Counter: leave radius/use cover if blocking is defined. Core footprint/effect radius separate; no rotation. Tune force/radius/core. Both modes only after projectile interaction is excluded or specified; direct core owns kill; resets field. Very high force, bounds, and readability risk. Approved size inventory: Single default from grid matrix: Core: 1×1 footprint; Pull radius envelope: 5×5 active region. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-033 — Kambal na Pinto

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** C; paired traversal; Teleporter reference. Linked fantasy doors relocate a chicken to a clear partner exit. Tell: matched symbol and exit preview. Counter: avoid endpoint or use cooldown window. Pair footprint and exit clearance; rotate each exit in 90° increments. Tune cooldown/exit offset. Race only initially; disable in Lagsanay pending fairness. Pair ownership and removal delete both ends; high risk: pairing, anti-loop, blocked exit. Approved size inventory: Single default from grid matrix: Each door: 1×2 footprint; Exit clearance: 1×2 per door active region. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-034 — Balsa-Bentilador

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** C; mover + force; Fan Platform family reference. Rideable top with marked hazardous underside. Tell: underside icon and path. Counter: board only from safe side/dismount. Platform solid top, underside trigger, bounded path; fixed orientation. Tune path/force/danger area. Disable Lagsanay initially; direct underside hit owner only. Resets endpoint; very high combined mover/force risk. Approved size inventory: Single default from grid matrix: Platform: 3×1 footprint; Path/air envelope: 6×4 active region. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-035 — Umiikot na Dram

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** C; rotating surface; Gear/Tire rotation family reference. Rotating drum changes standing and takeoff timing without attached contraptions. Tell: rotation arrows. Counter: ride with rotation or jump away. Cylindrical support/sweep separate; axis fixed, start angle configurable. Tune speed/radius. Race/event after Lagsanay test; reset angle; high collision geometry risk. Approved size inventory: Single default from grid matrix: 3×3 footprint; Same 3×3 rotation envelope active region. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ITEM-036 — Peryang Traysikel

**Scope:** EXPANSION · **Design status:** OPTIONAL · **Owner role:** Gameplay (name TBD).

**Expected behavior:** C; lane-crossing mover; original barrio hazard. Toy tricycle signals, crosses a fixed lane, waits offstage, repeats. Large body differs from small projectile. Tell: bell/headlight and lane warning. Counter: leave lane or use cover if defined. Spawn anchor and complete lane separate; 0/180° direction. Tune speed/warning/dwell/cap. Both modes only with full lane visible and safe spawn; direct body collision owner; resets offstage. High risk: bounds and large hitbox. Approved size inventory: 6×1 or 8×1 lane; body remains 2×1. Grid/world measurements and tuning are provisional. Catalog approval is not implementation or release enablement.

**Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.

**Source:** [ITEMS.md](ITEMS.md); [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.

## 13. UX, Library, tutorial and accessibility

The Library is the slow-reading space; Pugad stays visual and fast. Every enabled entry explains its name, animation, sizes, controls, placement, tells/counterplay and mode behavior. How to Play, Karera, Lagsanay, Kangaroo, Items and Accessibility categories must be reachable without starting a match. Final UI/art choices must preserve the source contracts, not invent new abilities.


### REQ-UI-002 — Complete title, menus, settings and navigation

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Art/UI (name TBD).

**Expected behavior:** Title offers local match, Library, settings and quit; lobby offers ready/leave/help; pause offers help/Library/settings/resume and confirmed return to lobby. Results offer replay/lobby. Menu ownership follows prototype pause rules. Development builds expose a build label, never internal seeds on player HUD.

**Acceptance:** Gamepad and keyboard traverse every screen/back/quit route without traps or accidental game input; opening Library from pause keeps simulation paused and preserves return context.

**Source:** [UI_TUTORIAL.md](UI_TUTORIAL.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence (2026-10-15):** implemented and synthetically verified on the scheduled full match (default route): [navigation suite](evidence/p13/test_logs/run_p13_navigation_tests.txt) (205 checks), captures in [P13 evidence](evidence/p13/README.md). Physical gamepad traversal is COULD-NOT-RUN (P13-T02 / P02-T08; owner's dated override D1).


### REQ-UI-003 — Explain current play and results in the HUD

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Art/UI (name TBD).

**Expected behavior:** Show round/Main Challenge, subordinate TWIST label, exact score totals, relevant deadlines, number/shape, alive/secured/eliminated/taya state, KANG→GA→ROO and enabled Barya carrier. Explain suppressed awards, Last Cluck and next-round selection. No internal IDs/collision shapes/seeds.

**Acceptance:** Spectators identify phase, objective, leader, taya, winner and no-score reason; overlapping command rings stay distinct at minimum zoom and with sound/shake off.

**Source:** [UI_TUTORIAL.md](UI_TUTORIAL.md); [GDD.md](GDD.md). **Implementation/evidence (2026-10-14, engineering only):** the guided first match, build-gated tutorial stage, retry hint, Pause skip, Library replay, session-only memory and once-per-session Lagsanay prompt are implemented with PLACEHOLDER copy; see [tutorial evidence](evidence/tutorial/README.md). **Scoreboard slice (2026-10-15):** reusable round and match score charts display exact eighth-point totals, status, labelled/glyphed score segments and the configured target, with bounded presentation history and reduced-motion modes. The 52-check chart suite, 185 binding checks, 198 UI-flow checks, 62 mode checks, scoring/lifecycle/mode suites, rendered result captures and Windows export smoke pass; details are in [scoreboard evidence](evidence/scoreboard/README.md). Synthetic input and screenshots are engineering evidence only: spectator comprehension, accessibility/player review, cultural review and physical devices remain open, so REQ-UI-003 is not met. **Implementation/evidence (2026-10-15):** the scheduled default route has live cues for all three Mains and all three stacks; the Barya carrier and award rows now join that cue set. The earlier 264-check P13 log records the pre-Barya state; current Barya-integrated HUD checks and captures are indexed in [Barya evidence](evidence/barya/README.md). Spectator identification (P13-T04) is COULD-NOT-RUN.


### REQ-LIB-001 — Provide enabled-content Library and animated entries

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Art/UI (name TBD).

**Expected behavior:** Library is reachable from title, lobby and pause/settings. Categories: How to Play, Karera, Lagsanay, Kangaroo, Items, Accessibility. Include controls/scoring, all enabled variants, looping animation, placement guides, tell/counterplay and compatible event behavior. Backlog appears only in marked development/reference mode.

**Acceptance:** Every enabled family/variant/event has a readable entry and controller-operable category/back navigation; disabled content is absent from release browsing; Pugad remains visual-only.

**Source:** [UI_TUTORIAL.md](UI_TUTORIAL.md); [ITEMS.md](ITEMS.md). **Implementation/evidence (2026-10-15):** PLACEHOLDER pages for every category, one animated entry per enabled family, scrolling, enabled-content filtering and dev-only reference mode ([Library suite](evidence/p13/test_logs/run_p13_library_tests.txt), 352 checks). Copy is unreviewed; physical-controller operation is COULD-NOT-RUN.


### REQ-TUTORIAL-001 — Teach the first round and later event rules

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Art/UI (name TBD).

**Expected behavior:** Guided first Karera teaches identity, move/jump, visible-item selection, claim timeout, place/rotate/validity/confirm, flag and actual results. Prompts are skippable after completion in current session; replayable help remains. First Lagsanay teaches taya/pass/timer/last survivor; first Kangaroo teaches poses, three misses and built supports.

**Acceptance:** A novice follows the guided loop and explains objective/input/placement; record each facilitator intervention. Session skip and help replay work; no tutorial bonus or disk completion save is invented.

**Source:** [UI_TUTORIAL.md](UI_TUTORIAL.md); [GDD.md](GDD.md). **Implementation/evidence (2026-10-15):** guided Karera, Lagsanay / Bomb-Taya and first-Kangaroo prompts, session skip and replay, no disk save ([tutorial suite](evidence/p13/test_logs/run_p13_tutorial_tests.txt), 55 checks + the unchanged 140 / 48). No novice session has run (P13-T08 COULD-NOT-RUN).


### REQ-ACCESS-001 — Maintain color-independent readable play

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Art/UI (name TBD).

**Expected behavior:** Player identity, placement validity, taya, hazards, wave support and coin never depend on color alone. Use redundant silhouette/icon/text/motion/audio; no rapid flashing. Full/reduced/off shake. Critical cues remain understandable muted. Review minimum camera zoom, safe areas, needed language glyphs and supported resolutions.

**Acceptance:** QA captures minimum-zoom crowded stage with muted audio and shake off; identifies every critical cue and all four players. Check Parol overlap/readability and no strobe; document supported display/device limits.

**Source:** [UI_TUTORIAL.md](UI_TUTORIAL.md); [ASSETS.md](ASSETS.md); [PLAYTEST.md](PLAYTEST.md). **Implementation/evidence (2026-10-15):** shake Full / Reduced / Off applied, audio buses and Mute, no-strobe measurement, glyph and display report ([accessibility suite](evidence/p13/test_logs/run_p13_accessibility_tests.txt), 65 checks; [captures](evidence/p13/README.md)). QA identification (P13-T10) is COULD-NOT-RUN.


### REQ-UI-004 — Retain spectator cheer without gameplay effects

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Art/UI (name TBD).

**Expected behavior:** Eliminated players may cheer while spectating; the assigned cheer input produces modest crowd/visual feedback without obscuring active information. Prototype cooldown is 1 s. Enhanced layered crowd/tension behavior is optional, but the basic spectator action remains part of the documented flow.

**Acceptance:** An eliminated player can cheer using their assigned binding; repeated input respects cooldown, never moves a player, changes score/timers, triggers commands or obscures live HUD.

**Source:** [GDD.md](GDD.md); [UI_TUTORIAL.md](UI_TUTORIAL.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence (2026-10-15):** spectator cheer implemented with a 1 s cooldown and no simulation effect ([cheer suite](evidence/p13/test_logs/run_p13_cheer_tests.txt), 39 checks). Physical-keyboard validation (P02-T04) and P13-T12 are open.

## 14. Presentation, audio and provenance

Required presentation expresses Filipino barrio identity through original chicken/stage/item art, soft comedic eliminations and readable feedback. Enhanced crowd reactions/tension/fan coloring remain Should; essential gameplay cues and music/SFX are required. Public cultural statements need evidence and review. Register every asset/font, even when team-made or engine-included; do not infer distribution rights from availability.


### REQ-ART-001 — Deliver original chicken, stage and interface presentation

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Art/UI (name TBD).

**Expected behavior:** Choose final 2D direction/font with provenance. All chickens have distinct color plus markers; animate movement, hatch, placement, finish and soft comedic elimination. One barrio arena uses original Filipino setting motifs. No copied UCH art/UI/name/character/audio or gambling/gore.

**Acceptance:** Release contains no unintended placeholder assets, silhouettes remain clear at minimum zoom, every imported asset/font is approved and credited; cultural copy has review evidence.

**Source:** [GDD.md](GDD.md); [ASSETS.md](ASSETS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-AUDIO-001 — Deliver essential sound and music feedback

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Audio (name TBD).

**Expected behavior:** Provide suitable music and clear UI, hatch/place, movement/item tell, finish/elimination and event cues, all paired with visuals. Prefer team-made recordings. Define and document final volume-control scope; enhanced crowd layers remain Should. Shake/volume are presentation-only pause settings.

**Acceptance:** Muted play remains understandable; cues do not mask countdown/command information; volume/mute controls work, assets are registered and playback stops/cleans on transitions.

**Source:** [ASSETS.md](ASSETS.md); [UI_TUTORIAL.md](UI_TUTORIAL.md); [GDD.md](GDD.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-ASSET-001 — Maintain asset and cultural provenance

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Compliance (name TBD).

**Expected behavior:** Register creator/source, licence/permission proof, attribution, modifications, AI assistance, cultural reviewer/date and final approval for every shipped asset. Verify title/Pugad/Karera/Lagsanay/item names and factual cards; fictional adaptations are not claimed as authentic traditional rules.

**Acceptance:** Shipped asset manifest matches register and credits; no missing licence/permission or unsupported cultural claim; Form 03 references agree with assistance records.

**Source:** [ASSETS.md](ASSETS.md); [COMPETITION.md](COMPETITION.md); [AI_USAGE.md](AI_USAGE.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.

## 15. Technical and quality requirements

This is a local-only Godot game, not a service. There are no public APIs, remote endpoints, accounts or network/save migrations. Proposed interfaces describe responsibilities: assigned player inputs; actual support contacts; item definition/lifecycle; atomic stage edit set; terminal outcome ledger; exact score calculation; Main/Twist scheduling; presentation fed by resolved state. Names/paths in the tracker are suggested NEW components, not existing code or a mandated framework.

The available engine does not verify the target version. Do not change project version to make prose appear complete. Central tunables are provisional; capability switches prevent unverified content entering production. Memory/performance targets are budgets awaiting measurement, not achievements.


### REQ-TECH-001 — Establish team-directed project responsibilities

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Organize input/identity, movement/contact, phase and match lifecycle, stage/placement, item definitions/runtime, event scheduling/evaluation, scoring/outcomes, presentation and local diagnostics. Proposed paths are NEW, not existing implementations. Use the standing AI-assisted programming workflow in `AI_USAGE.md`; record actual provenance and do not copy tutorial/template/open-source core mechanics. The external originality/disclosure interpretation and submission eligibility remain separate compliance questions.

**Acceptance:** Project opens with an entry scene; the responsibility map and implementation provenance are documented; no copied tutorial/template/open-source core mechanics are used. Record actual human review when performed. Competition rule interpretation and eligibility are handled by the separate submission compliance gate.

**Source:** [PRODUCTION.md](PRODUCTION.md); [COMPETITION.md](COMPETITION.md); [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md); [AI_USAGE.md](AI_USAGE.md). **Implementation/evidence:** foundation structure and harness launched; actual human review and competition eligibility interpretation remain open. See [P01 evidence](PHASETASK.md#p01--project-foundations).


### REQ-CONFIG-001 — Centralize provisional configuration and profiles

**Scope:** REQUIRED · **Design status:** PROTOTYPE—UNTESTED · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Separate invariants, tunables and presentation. Use named movement_room, karera_slice, karera_spring, lagsanay_lab, kangaroo_contract_lab, stack_lab and release_candidate profiles. Snapshot gameplay tuning at match start; volume/shake may change while paused. Preserve defaults as untested; R1–R4 stay off.

**Acceptance:** No scattered gameplay tuning; changing gameplay keys requires a new test match. Logs identify profile/build/seed. All R proposals are off in contract/release profiles.

**Source:** [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** typed resources, seven profiles and run snapshots are implemented; test evidence is in [P01-T03/T04](PHASETASK.md#p01-t03). Provisional values remain untested.


### REQ-CONFIG-002 — Validate content pools and deterministic diagnostics

**Scope:** REQUIRED · **Design status:** PROTOTYPE—UNTESTED · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Enable only implemented and verified content. Zero disabled weights and normalize positive eligible weights. Empty required pools are configuration errors. Release rejects missing scheduled or sudden-death modes. Separate seeded egg, event and permitted tie-lottery streams from cosmetic randomness; provisional debug seed 12345.

**Acceptance:** Disabled content cannot be selected; empty pools fail visibly in diagnostics; same seed/profile reproduces selections; race-only profile is visibly developmental and cannot masquerade as release.

**Source:** [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md); [PLAYTEST.md](PLAYTEST.md). **Implementation/evidence:** eligible-content filtering, empty-pool rejection, weight normalization, independent seeded streams, and incomplete release rejection are implemented and covered by [P01-T05/T06](PHASETASK.md#p01-t05). No gameplay content is currently selectable.


### REQ-TECH-002 — Provide lifecycle and diagnostic harnesses

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Gameplay (name TBD).

**Expected behavior:** Provide local movement, item and event test rooms with reset controls and diagnostic observation. P01 rooms are labeled placeholders and do not implement P02+ mechanics. Diagnostics stay out of the player HUD. No analytics service, account, backend or gameplay networking.

**Acceptance:** Each harness resets without duplicate signals or retained state; diagnostic data is local and can identify build/profile/seed and a failing scenario.

**Source:** [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md); [PLAYTEST.md](PLAYTEST.md). **Implementation/evidence:** local diagnostic harness and placeholder fixtures are implemented; lifecycle evidence is in [P01-T07/T08](PHASETASK.md#p01-t07). No player HUD or gameplay mechanics are included.


### REQ-PERF-001 — Measure frame time, memory and bounded cleanup

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** QA (name TBD).

**Expected behavior:** Provisional targets: 60 FPS/16.67 ms at 1080p, 512 MiB process memory pending target-PC confirmation, 0 B/s gameplay networking. Measure base, representative four-player and worst-case round-12 stages at persistent/transient caps and repeated restarts. Record median/p95/worst frame times, memory and object counts.

**Acceptance:** Evidence names OS/CPU/GPU/RAM, build, resolution, duration, counts and modes; compare against confirmed budgets, investigate spikes/growth, and record any budget revision explicitly. No measured results are fabricated.

**Source:** [PLAYTEST.md](PLAYTEST.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.

## 16. Verification and release acceptance

Evidence records build/engine/profile/seed/date, players, devices, scenario, expected/actual result, artifact and reviewer. PASSED means observed; FAILED means reproduced defect; COULD-NOT-RUN identifies missing hardware/build/prerequisite. Documentation checks never mark gameplay verified.

Critical defects include crash, softlock, wrong winner/score, cross-controlled seats, unrecoverable lifecycle state, missing required tutorial or release functionality. A release cannot bypass them with a checked planning box. Resolve critical defects, rerun affected regression and preserve known noncritical limitations in the package.

Test layers: isolated test harnesses; functional integration; 2/3/4-player physical-device tests; novice playtests; full matches/sudden death/restarts; minimum-zoom/muted/shake-off accessibility; capped stress/performance; clean-PC exported acceptance. Use [PLAYTEST](PLAYTEST.md) for detailed scenarios and measured results.


### REQ-EXPORT-001 — Prove an early PC export path

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Integration (name TBD).

**Expected behavior:** Use the confirmed target engine and matching templates to export a minimal runnable project early; repeat with the final release later. P01 export contains AI-generated foundation code disclosed in `AI_USAGE.md`; it does not establish human review or competition eligibility. A successful editor import alone is not export or gameplay evidence.

**Acceptance:** A versioned smoke export launches and exits on the intended PC; record engine/templates, preset, build and logs. Missing templates block the check.

**Source:** [PLAYTEST.md](PLAYTEST.md); [PRODUCTION.md](PRODUCTION.md). **Implementation/evidence:** matching 4.7.2 templates, Windows export and local executable startup/clean exit passed; evidence is in [P01-T09/T10](PHASETASK.md#p01-t09). A later clean-PC/final-release export check remains required.


### REQ-SLICE-001 — Demonstrate the first playable build/race loop

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** QA (name TBD).

**Expected behavior:** First slice uses only verified Kaing/Tulay in labeled karera_slice. Two players complete Lobby→Pugad→Place→Karera→results→next round twice; stage persists through ten round resets. Early match ties may show pending sudden-death coverage, never a complete-match claim.

**Acceptance:** Record two complete rounds and ten resets with no duplicate placement/score, plus guided first-loop comprehension; missing Lagsanay/sudden death remains explicit.

**Source:** [PRODUCTION.md](PRODUCTION.md); [PLAYTEST.md](PLAYTEST.md). **Implementation/evidence (2026-10-14):** P07 First Playable route and exact three-variant Kaing/Tulay allowlist are implemented. Synthetic route/reset/scoring checks pass; 1080p debug captures and local performance measurements are recorded in [P07 evidence](evidence/p07/README.md). Required player-driven two-round session, novice comprehension and human review remain COULD-NOT-RUN; the route is not evidence of player acceptance or release completeness.


### REQ-SLICE-002 — Extend slice coverage to three and four players

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** QA (name TBD).

**Expected behavior:** After P07-T02 and P02-T08 pass, complete three rounds with three players and three with four players, rotating participants through slots/devices. Exercise simultaneous input, one-seat device ownership, maximum camera separation, placement-preview isolation, pause/focus loss, disconnect/reconnect, reclaim, countdown cancellation and fresh input after resume. Construction-only all-finish zero-score rounds are expected and are not release balance evidence.

**Acceptance:** The 2/3/4-player device matrix identifies tested, failed and unavailable combinations. No cross-controlled seat or hidden live player; simultaneous input remains isolated; camera targets and previews remain visible; pause/reclaim preserves state and resumed input is fresh. Record P02-T08 reconnect evidence separately; leave unavailable combinations COULD-NOT-RUN.

**Source:** [PRODUCTION.md](PRODUCTION.md); [PLAYTEST.md](PLAYTEST.md). **Implementation/evidence (2026-10-14):** the P07 route supports 2–4 seats and synthetic seat-isolation/camera/profile checks pass; a device-matrix framework and session sheet are recorded in [P07 evidence](evidence/p07/README.md). Required three-round human sessions at 3 and 4 players, rotation, simultaneous physical input, focus/pause and disconnect/reclaim remain COULD-NOT-RUN. No gamepads or participants were available for this implementation session; only synthetic devices are represented in automated checks.


### REQ-QA-001 — Run balance sessions and first-batch interaction checks

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** QA (name TBD).

**Expected behavior:** Test 2/3/4 players with slot/device rotation, novice onboarding and clean/representative/cluttered stages. Cover bridge+trumpo, spring+Parol, block+launcher, bubble+trumpo, cleanup+blocked route. Record avoidable versus forced outcomes, no-score frequency, stalls and participant feedback. Change one coupled tuning group per experiment.

**Acceptance:** At least two sessions/participants support feel changes, hard defects reproduce, all five interactions have clips/notes and direct ownership results; no assertion of statistical balance from tiny samples.

**Source:** [PLAYTEST.md](PLAYTEST.md); [ITEMS.md](ITEMS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-QA-002 — Complete physical device and regression coverage

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** QA (name TBD).

**Expected behavior:** Test 2/3/4-player gamepad/mixed/shared-keyboard supported combinations on editor and exported build, including simultaneous chords, drift, focus, unplug/reclaim, same-model devices and transition input edges. Exercise each mode/stack and score/terminal boundary, full match, sudden death and ten restarts.

**Acceptance:** Signed matrix distinguishes PASSED/FAILED/COULD-NOT-RUN with build/devices; no unsupported claim fills a missing physical test. Critical defects are fixed and affected regressions rerun.

**Source:** [PLAYTEST.md](PLAYTEST.md); [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-RELEASE-001 — Freeze approved content and close critical defects

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Producer (name TBD).

**Expected behavior:** October 21 is feature freeze; October 22–23 stabilization. Required scope includes all eight targeted families, modes/stacks, UI/Library/tutorial and essential presentation unless explicitly revised. Decide every Should item include/defer. Included Should work inherits full release gates. No new feature after freeze without explicit scope review.

**Acceptance:** Dated manifest enumerates enabled variants/modes/pairs, excluded/deferred content and reviewed defects; zero unresolved crash/softlock/wrong-score/winner/device/lifecycle/onboarding blockers.

**Source:** [ROADMAP.md](ROADMAP.md); [PRODUCTION.md](PRODUCTION.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-EXPORT-002 — Package and verify the final game on a clean PC

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Integration (name TBD).

**Expected behavior:** Export with recorded engine/templates/preset/build. Package executable and required data, credits/licences, supported devices, launch/quit/restart instructions and known noncritical limits. Verify clean-PC launch without editor or paid licence, complete supported match/tutorial/restart and no gameplay network dependency.

**Acceptance:** Checksums and version identify the tested package; clean-PC procedure passes with real hardware; instructions reproduce launch and controls; packaged credits/provenance match assets.

**Source:** [SUBMISSION.md](SUBMISSION.md); [PLAYTEST.md](PLAYTEST.md); [COMPETITION.md](COMPETITION.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.

## 17. Delivery, schedule and conditional finals

Feature freeze **October 21, 2026**; stabilize October 22–23; final capture/package review October 24; submit **October 25**. Start forms/storyboard/synopsis/licensing now, not on the final polish day. Finals are scheduled **November 26–27, 2026**, with qualification announcement November 9; verify organizer instructions before acting.

At the original baseline there were eight calendar days to freeze and twelve to submission, with no runnable game and unknown staffing/hardware. The P02 fixture now demonstrates a narrow input/movement foundation but does not change required scope or close the remaining gates. These dates are decision checkpoints, not an effort estimate. If evidence slips, producer must explicitly revise scope; no silent cuts to Lagsanay, Kangaroo, stacks or an initial family. Content-freeze review must assign every Should feature an include/defer outcome.


### REQ-SUB-001 — Prepare registration and official forms

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Compliance (name TBD).

**Expected behavior:** Start early: verify current official instructions/category, register, prepare Form 01 roles, Form 02 originality/waiver signatures and Form 03 asset/AI tool-area-extent disclosure with required signatures. The team chooses Form 03 extent across the entire project. Preserve available prompts/history and do not make false authorship claims.

**Acceptance:** Compliance checks current organizer forms, category eligibility and signatures against registered members; completed forms agree with asset/AI records and actual programming provenance. Verify the recorded §7/§8 interpretation for submission; this compliance gate does not block ordinary approved programming tasks.

**Source:** [SUBMISSION.md](SUBMISSION.md); [COMPETITION.md](COMPETITION.md); [AI_USAGE.md](AI_USAGE.md). **Implementation/evidence:** not yet available; submission and compliance review remain open. Non-code decisions require their own documented review.


### REQ-SUB-002 — Write the synopsis and plan media capture early

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Compliance (name TBD).

**Expected behavior:** Template 01 synopsis is at most 500 words, covering premise, loop, competitive rules, theme and original work. Plan trailer/demo shot list and captions while gameplay progresses; reserve capture/review time before October 24. Final copy describes only shipped behavior.

**Acceptance:** Word count <=500; reviewed copy and shot list cover Pugad, Place, Karera, Lagsanay, theme and results; final-build reconciliation is scheduled before upload.

**Source:** [SUBMISSION.md](SUBMISSION.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-SUB-003 — Produce captioned trailer and explanatory demo

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Compliance (name TBD).

**Expected behavior:** Trailer: 1–2 minute MP4, loops and reads without sound. Demo: 3–5 minute MP4 with narration/captions showing local join, Pugad/Place, Karera/scoring, Lagsanay, item counterplay and results/restart. Use actual tested gameplay; show a supported stack clearly, never mockups passed as runtime.

**Acceptance:** Check duration/container/playback/caption legibility and muted trailer; footage matches release candidate, explains Lagsanay and distinguishes Main/Twist; licensed media and source captures archived.

**Source:** [SUBMISSION.md](SUBMISSION.md); [COMPETITION.md](COMPETITION.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-SUB-004 — Review, submit and preserve delivery evidence

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Producer (name TBD).

**Expected behavior:** Before October 25 deadline, producer/compliance reviews registration/forms/synopsis/media/build, theme/tutorial/originality/licensing and final package identity. Submit through verified official channel with authorized team access; retain confirmation/receipt and delivered files. Submission is a separate milestone from release readiness.

**Acceptance:** Final review names approver/date, package hash/version and all deliverables; successful upload receipt records time/channel and archived package. Failed upload is not marked submitted.

**Source:** [SUBMISSION.md](SUBMISSION.md); [COMPETITION.md](COMPETITION.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-SUB-005 — Hand off source, build and operating instructions

**Scope:** REQUIRED · **Design status:** CURRENT CONTRACT · **Owner role:** Producer (name TBD).

**Expected behavior:** Retain reproducible source revision, engine/templates/preset, build checksum, test evidence, known issues, licences/disclosure, media masters and submission receipt in team-controlled storage. Name operational owner and explain launch/devices/pause/reconnect/restart and recovery at demonstrations.

**Acceptance:** Another registered member can locate the archive, identify the delivered build and run the documented demo/recovery without the original implementer.

**Source:** [PRODUCTION.md](PRODUCTION.md); [SUBMISSION.md](SUBMISSION.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-FINAL-001 — Prepare qualification-dependent finalist materials

**Scope:** CONDITIONAL · **Design status:** CURRENT CONTRACT · **Owner role:** Compliance (name TBD).

**Expected behavior:** After finalist confirmation (scheduled November 9), verify category-specific extras: team name; student school/logo, school IDs, enrollment proof and endorsement; professional group/company logo and valid IDs; poster dimensions from organizers. Treat personal documents as controlled team records, not public repo content.

**Acceptance:** Organizer checklist and category match delivered extras, permissions and poster specifications; record submission confirmation without exposing private ID data.

**Source:** [COMPETITION.md](COMPETITION.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.


### REQ-FINAL-002 — Rehearse and deliver the finalist demonstration

**Scope:** CONDITIONAL · **Design status:** CURRENT CONTRACT · **Owner role:** Producer (name TBD).

**Expected behavior:** Plan November 26–27 finals in General Santos City with confirmed participants/travel arrangements, actual PC/display/controllers, offline package backup, captions and reset/reconnect drill. Reverify organizer operational instructions and any permitted build changes.

**Acceptance:** Timed rehearsal passes on event hardware, backup launches, team knows controls/recovery and speaking roles; final delivered build and materials are recorded.

**Source:** [COMPETITION.md](COMPETITION.md); [SUBMISSION.md](SUBMISSION.md). **Implementation/evidence:** not yet available; runtime checks COULD-NOT-RUN until a suitable implemented build and required hardware are available. Non-code decisions require their own documented review.

## 18. Decisions, risks, sources and traceability

| Decision/risk | Status and owner/unblock condition |
|---|---|
| Eight initial families | October 13 approved submission target; Producer must approve any later cut, Bula first review candidate. |
| UI priority / tally | Title/results/Library/essential cues required; tally session-only Should; GDD/ROADMAP aligned in this task. |
| Engine and equipment | PARTIAL, Integration/Producer: intended Godot 4.7.2 binary and target PC are identified; exact template compatibility, export setup, keyboard details, and physical controller inventory remain open. See P00 evidence in PRODUCTION.md/PLAYTEST.md. |
| Staffing/time | Francis/Carlos lead development; Shanti handles UI design and audio; Jorge/Ivie handle game maps and assets. Remaining assignments, reviewer identities, registration status and capacity remain unknown; P00-T01/T02 remain open. |
| Final 2D style/font/music/cultural reviewer | Art/UI, Audio, Compliance: select/register/review before release assets; does not block geometric movement testing. |
| Tulay vertical orientation | Conditional controller-support gate; horizontal approved lengths remain targeted. |
| Wave numerical equality tolerance | PROTOTYPE—UNTESTED; Gameplay/QA: boundary/contact tests; no player-visible grace or changed rule implied. |
| Terminal ordering gaps | Gameplay: explicit decision table before affected stack integration; keep source-defined cases intact. |
| R1 exact tie lottery | PROPOSED—INACTIVE; current lowest-slot tag/Hug/Last Cluck ties stay. |
| R2 group-contact Hug | PROPOSED—INACTIVE; pair-only evaluation stays. |
| R3 prevent conflicting Storm overlap | PROPOSED—INACTIVE; current forced overlap stays and is tested for unavoidable choices. |
| R4 pause taya during Freeze | PROPOSED—INACTIVE; timer continues under current contract. |
| Capture/forced chains | Bubble last; Gameplay/QA: disable unsafe item/event eligibility until reviewed evidence permits it. |
| Stage clutter/performance | QA/Gameplay: bounded persistent/transient counts, cleanup and measured minimum-zoom/frame-time tests. |
| Should feature decisions | Producer: include/defer before freeze; optional is never hidden in required completion denominator. Wall slide/jump is approved Should scope, unimplemented, and may not delay P04. |

### Source register

| Source | Responsibility |
|---|---|
| [GDD](GDD.md) | Gameplay loop, event rules, scoring, outcomes and player experience. |
| [ITEMS](ITEMS.md) | 36-family contracts, approved variants and backlog relationships. |
| [STAGE_AND_PLACEMENT](STAGE_AND_PLACEMENT.md) | Atomic construction, protected bounds, provisional graybox and support matrix. |
| [UI_TUTORIAL](UI_TUTORIAL.md) | Screen/HUD/Library/tutorial/accessibility detail. |
| [PROTOTYPE_DEFAULTS](PROTOTYPE_DEFAULTS.md) | Untested starting parameters, input policy, profiles and inactive R1–R4. |
| [ROADMAP](ROADMAP.md), [PRODUCTION](PRODUCTION.md) | Scope, dates, roles, production gates and risks. |
| [PLAYTEST](PLAYTEST.md) | Runtime evidence procedures and earlier explicitly dated checks. |
| [ASSETS](ASSETS.md), [AI_USAGE](AI_USAGE.md) | Provenance/cultural/AI evidence, not signed official forms. |
| [COMPETITION](COMPETITION.md), [SUBMISSION](SUBMISSION.md) | Recorded competition requirements and package plan; verify official instructions at delivery. |
| [AGENTS](../AGENTS.md), [CLAUDE](../CLAUDE.md), [README](../README.md), [INDEX](INDEX.md) | Repo context, programming-provenance policy and navigation. |

Structural references only: IT game act PRD/PHASETASK and Cipher-Booth-Leaderboard PRD/phasetask were inspected in their separate local repositories. Their feature scope, technology, done marks and automatic commit behavior do not apply here.

Every requirement maps to implementation or justified non-code work and verification in the [tracker traceability matrix](PHASETASK.md#traceability-matrix). IDs remain stable across scope changes; add a decision record rather than deleting unfinished obligations. Documentation completion is separate from gameplay completion.
