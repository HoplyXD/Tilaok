# AI Assistance Record — Tilaok!

**NLB-P01 update (2026-10-19):** after the approved P00 documentation track, Codex implemented the separately gated P01 local action/seat and simulation-authority foundation and its focused tests, capture runner, verification evidence, and tracker/status updates. No transport, Android export/client, or live-placement work was performed. Verification used synthetic input; no physical-device session or independent human review is claimed. The original P00-only record remains in the dated history below.

_Current policy and cumulative disclosure record. Updated 2026-10-21. This file prepares evidence for DOST Form 03; it is not the signed form._

## Current standing programming policy

AI/LLM-assisted programming, including generation and modification of core gameplay code, is the approved standing development workflow for Tilaok!. The users (the lead developer and the co-lead developer) use AI/LLMs as the primary code generators and direct development, retaining responsibility for integration, review, testing and delivery. Human responsibility does not mean source code was manually written by humans. The human team handles art, assets and other production work; this programming authorization does not authorize generating final art, audio or other production assets. Current human production assignments cover UI design and game audio, and maps, characters, obstacles, traps, effects and related game assets, each held by team members. These assigned production visuals and audio will be created without AI generation.

AI coding agents may implement programming work within an approved task: gameplay mechanics, scripts, scenes used for programming or integration, tools, tests, fixes and refactors. Agents do not need a separate AI-use approval for each approved programming task or phase. Follow the requested task scope and design decisions; standing authorization does not authorize scope expansion, unapproved design changes, data deletion or bypassing required tests. Normal plan approval remains in force when a task requests it. Actual technical verification is required before marking work complete. Human review and release responsibility remain, and review is recorded only when performed.

Never describe AI-generated code as manually team-written. Do not copy Ultimate Chicken Horse code, third-party core implementations, tutorial/template mechanics or unlicensed assets. Disclose actual AI assistance, including generated programming work, rather than describing assistance only as review or documentation. Preserve prompts, outputs and history where available; do not invent missing records. AI-generated code is not automatically free of provenance or licensing concerns. Keep code provenance and asset provenance accurate.

This standing internal workflow does not establish organizer approval, registration, human review, competition eligibility or originality acceptance. Competition forms and any eligibility interpretation remain separate submission obligations. See [COMPETITION.md](COMPETITION.md) and [SUBMISSION.md](SUBMISSION.md). The team must select the official Form 03 extent category using total project-wide assistance; this record does not select or sign that category on the team's behalf.

## Cumulative assistance summary

On 2026-10-13, at the user's request, Codex consolidated conversation preferences into `PROMPT_RULES.md` and added agent, documentation-index and rule-discovery references. This was documentation/rule configuration only; it did not implement gameplay, run gameplay verification or complete any phase checklist task.

OpenAI Codex has assisted with research, design/specification, project documentation, and programming. It authored the P01 foundation, P02 input/controller/movement diagnostic implementation, P03 graybox arena/camera/support implementation, and NLB-P01 local action/seat and authority foundation, with focused tests, rendered evidence tooling and related documentation. It also authored the documentation work listed below, the policy correction and this role clarification. This cumulative summary is intended to prevent older delivery-specific statements from being mistaken for the full project history. No AI-generated final art, audio or other production asset is recorded here; P03 uses simple code-drawn debug geometry.

The P01 foundation includes typed provisional settings/profile snapshots, content validation and seeded diagnostic streams, a local development harness, scenes, focused checks, export setup and evidence. The P02 work includes local seat/device assignment, phase-specific routing, pause/focus/reclaim state, movement/contact/lifecycle code, diagnostic fixtures and focused tests. The P03 work includes tile-edge arena/protection data, a bounded Play/Place camera, support-surface provenance/contact/invalidation contracts, integration into the harness, automated/rendered evidence, and tracker/specification updates. Its geometry and content are development fixtures, not production art or enabled item/event content. Consult [PHASETASK.md](PHASETASK.md), [PLAYTEST.md](PLAYTEST.md), and [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for exact implementation status and limitations. AI authorship is disclosed and is not represented as manual human authorship. Actual human review remains unrecorded where it has not occurred.

### NLB-P01 local actions and simulation authority — October 19, 2026

At the user's explicit direction to implement NLB-P01, OpenAI Codex authored the shared logical input/remote seat adapter and host-owned registry mapping; offline/host/client authority role; guards and role propagation through the existing router, GameFlow, match rooms, actor physics/lifecycle, items and transient budget, stage/support registries, event/RNG/timers, race ledger, score/Barya and pause paths; the focused regression runner and rendered offline route capture runner; and NLB-P01 evidence, tracker and current-status documentation. The implementation preserves the existing offline route and input layouts and introduces no transport, RPC, Android client, live-placement flow, final art or audio. Verification and failures/limitations are recorded in [NLB-P01 evidence](evidence/nlb/p01/verification-2026-10-19.md). Tests and captures used synthetic input. This record does not claim independent human review or select/sign the DOST Form 03 extent category.

On 2026-10-13, at the user's request, Codex investigated P03 vertical camera jitter with close chickens. It fixed proximity-based identity-badge repositioning and then traced a second drift to applying HUD compensation twice during camera easing. Codex changed the camera clamp path, added an easing regression, ran P03/foundation checks, captured and inspected 1080p rendered evidence, updated the stage camera contract and recorded measurements. No human review is claimed; the input was synthetic rather than a manual physical-controller playtest.

On 2026-10-13, at the user's request, an AI coding agent (Claude Sonnet 5.5 via Claude Code) authored the P04 item infrastructure and construction seeds: the typed item definition resources and validator, the lifecycle/cap manager and transient budget, the placement validator, the Kaing and Tulay piece scenes and scripts, the Item Lab room and ghost renderer, the `.tres` definitions, the `item_*` tunables, focused logic/physics tests, an interactive GUI runner, a render/performance capture script, evidence records and the documentation updates. It also made small supporting edits to `p03_stage_room.gd` (profile ID member), `arena_definition.gd` (construction unregister), `foundation_harness.gd` (catalog rows, full-view room list and a startup room hook) and the foundation test's fixture lookup. It then rebased onto the concurrently landed wall-extension source, resolved the resulting merge conflicts (tuning fields, structure doc) twice (the wall extension landed during the task); it did not modify the wall-extension code or tests. At the owner's request it later made wall movement enabled by default (a one-line tuning default, fixture-button changes and the matching test assertions) and added a Kaing wall slide/kick check. At the owner's request it also added code-drawn placeholder egg previews, a placeholder Library entry model/panel and their tests so P04-T10/T12/T19/T21 could be exercised; these are labeled DEBUG placeholders, not final art, and no production asset was generated. All visuals are code-drawn debug graybox; no final art, audio or other production asset was generated. The tests ran with synthetic input; no human review, physical-device check or human playtest is claimed. Generated code was not copied from Ultimate Chicken Horse or any tutorial/template; provenance and licensing review remains the team's responsibility.

### NLB-P02-T03 verification and partial NLB-P03 client work — October 20, 2026

At the user's approved implementation direction, OpenAI Codex updated the NLB-P02 abuse-state cleanup and added a locally owned malformed-frame flood test; it reran P02 focused and separate-process lifecycle checks. It authored the Android debug export preset, Android client-only GameFlow role selection, strict expiring invitation URI parser, landscape phone lobby and synchronized client lobby state; added a local CameraX/ZXing Godot v2 scanner plugin and decoder tests; and updated package/UI tests, build files, evidence and related documentation. After the user reported that Scan QR immediately said it could not start, Codex traced the message to `Object.has_method()` being used on Android's JNI singleton, changed the check to `JNISingleton.has_java_method()`, bound signals before starting the permission flow, and rebuilt the APK. The scanner implementation uses licensed third-party libraries; provenance is recorded in [ASSETS](ASSETS.md). The exact NDK 29.0.14206865 package was installed after the user's explicit approval. Godot 4.7.2 Android export and package inspection pass for T01, 55 focused P03 assertions pass, and two local decoder unit tests pass. The current P02 regression passes 74 assertions for a shared room-lifetime invitation, multiple proof/approval/seat cycles, leave/rejoin, and malformed-frame cleanup; ten separate-process rehost cycles pass. No human review, Android permission/camera runtime check, physical phone install/join, or real Wi-Fi/no-internet LAN verification is claimed. P03-T01 is checked; P03-T02/T03 and P02-T03 remain open. No final art/audio was generated. See [P03 evidence](evidence/nlb/p03/README.md).

### NLB-P04 preparatory network match implementation — October 21, 2026

At the user's direction to implement the P04 plan, OpenAI Codex authored the P00 wire/schema amendment, raw ENet channel routing, bounded match codecs, peer-generation-bound logical input, host input queue and neutral timeout, P12 host match-start integration, snapshot/state synchronization, detached draw-only client presentation, and minimum phone touch controls. It also authored focused P04 codec/router checks and updated the P04 tracker, evidence index and project documentation. The P03-T03 dependency remains open; this implementation does not claim prerequisite clearance. No Godot parser/import, P04 test, raw ENet experiment, multi-process session, rendered walkthrough, export, performance measurement, physical-phone test, or human review was run. The work is source-level and all P04 tracker boxes remain unchecked. The separate P04 multi-process runner and broader production-path fault coverage remain outstanding. No production art, audio or other non-code asset was generated. See [P04 evidence and exact deferred commands](evidence/nlb/p04/README.md).

_Correction (2026-10-21):_ the paragraph above describes the state when the P04 source was first delivered. The [P04 evidence](evidence/nlb/p04/README.md) records later runs:

- the focused 35-check suite passed;
- a separate-process host/client run passed;
- the multi-process runner was added and ran;
- a physical phone was admitted with snapshot readiness and remote movement;
- an updated-APK phone check was partial.

That record is authoritative for what ran and who ran it. No independent human review is claimed for those runs.

### NLB-P06 preparatory network live placement — October 21, 2026

At the user's explicit authorization of NLB-P06 as preparatory implementation, the AI coding agent Claude Code (Claude Opus 5.5, model `claude-opus-5-5`) authored the following:

- the P00 contract v1.3 amendment (schema 3, required live-placement feature `0x0080`, placement intent/result and live seat state families, revised versioned terrain commit, 10-byte route-bearing match lifecycle);
- the bounded `NetworkPlacementCodec` with its P05 code → reason/detail map;
- host session integration in `network_session_manager.gd`: host receipt stamping, intent validation, request-ID cache, per-requester results, ROUND_ENDED fan-out, add/update/remove terrain diffs with gap → snapshot recovery, the host-owned build-mode echo, neutral GO input on the live route, and per-peer cleanup;
- the opt-in `network_live_build` route with its `NLBP06NetworkLiveBuildMatchRoom` and scene;
- small additive hooks in the P05 room, placement pipeline and P12 replication record;
- remote live build actions and a live-room keyboard confirm flag;
- the client-side tentative ghost state machine;
- footprint/rotation drawing and minimum phone build controls in the client presentation;
- the focused `run_nlb_p06_tests.gd` and the `run_nlb_p06_multi_process.gd` slice/phone runner;
- a one-line P04 test update for the schema change;
- the P06 evidence, tracker and status documentation.

While the user's game was running on the shared laptop, nothing was launched or run: no Godot editor, game, headless run, script, import, export, test suite, multi-process or phone session, ADB, network listener, capture, lint or performance measurement. Only `git diff --check`, git status and manual source review were performed. All three P06 tracker boxes remain unchecked, with the actual result `COULD-NOT-RUN`. Dependencies P03-T03, P04-T03 and P05-T03 remain open, and this authorization does not clear them. No human review is claimed. No art, audio or other production asset was generated; the client visuals are code-drawn placeholders. The code is original to this task, with no Ultimate Chicken Horse or third-party core implementation copied; provenance review remains the team's responsibility. See [P06 evidence and exact deferred commands](evidence/nlb/p06/README.md).

### NLB-P07 preparatory live compatibility matrix and special cases — October 21, 2026

At the user's explicit authorization of NLB-P07 as preparatory implementation, the AI coding agent Claude Code (Claude Opus 5.5, model `claude-opus-5-5`) authored the following. The user chose strict default-deny with a dev-only host override, explosive detonation at the host commit boundary, and delivery as several commits.

- the default-deny `NLBLiveCompatibilityMatrix` (91 cells; none VERIFIED). It replaces the P05/P06 hard-coded live allowlist. It drives per-round Pugad dealing, schedule modes and stacks, the Barya offer, the start gate, commit-time intent checks, the host lobby content list and the compatibility manifest digest. The offline live route keeps its P05 slice through it.
- the `--nlb-unverified-content` development override and its client banner;
- the P00 contract v1.4 amendment and its source: schema 4, required mask `0x01FF`, bounded live transient and transient-end records with per-kind caps and no truncation, the 11-byte match lifecycle, and placement details 41–49;
- the host transient collector and client drawing;
- the §6.2 live special cases:
  - Walis/explosive entity age and a fix for a live one-shot crash;
  - the lethal-clearance, in-flight effect and fall-path checks;
  - the Barya rejection code;
  - the same-tick ordering and Freeze/Hug audit;
- the authored `run_nlb_p07_tests.gd` and `run_nlb_p07_matrix_runner.gd`;
- P04/P06 test and runner updates for the schema and override;
- the P07 evidence, matrix document, tracker and status documentation.

While the user's game was running on the shared laptop, nothing was launched or run: no Godot editor, game, headless run, script, import, export, test suite, multi-process or phone session, ADB, network listener, capture, lint or performance measurement. Only `git diff --check`, git status, grep audits and manual source review were performed.

The matrix document rows were produced by a scratch script that mirrors the matrix rules. The deferred P07 suite checks them against the real table.

All three P07 tracker boxes remain unchecked, with the actual result `COULD-NOT-RUN`. P06-T03 and the upstream dependencies remain open, and this authorization does not clear them. No human review is claimed. No art, audio or other production asset was generated; transient visuals are code-drawn placeholders. The code is original to this task, with no Ultimate Chicken Horse or third-party core implementation copied; provenance review remains the team's responsibility. See [P07 evidence and exact deferred commands](evidence/nlb/p07/README.md).

### NLB-P08 preparatory pause, lifecycle and seat reclaim — October 21, 2026

At the user's explicit authorization of NLB-P08 as preparatory implementation, the AI coding agent Claude Code (Claude Sonnet 5.5, model `claude-sonnet-5-5`) authored the following. The user decided that a disconnect elimination ranks with command failure and earns no Patibong, that fewer than two connected players does not pause or end a round, that the reclaim token is memory only (an Android process kill loses it), that three lifecycle cells join the compatibility matrix, and that the work ships as several commits with no co-author trailer.

- the P00 contract v1.5 amendment and its source: schema 5, required mask `0x03FF`, the pause-state, lifecycle-hint, reclaim-begin and reclaim-result families, the extended seat assignment and the reclaim HMAC context;
- the host-only pause epoch, the input-clock freeze while paused, the client pause banner and local-only overlay, and an opt-in network resume rule in the pause coordinator;
- client focus/background neutralisation with bounded hints;
- the memory-only Player ID, reclaim token and 60 s reservation book, the registry/adapter reclaim path, and the proof, rotation, snapshot-gated rebind and old-generation handling;
- the one-per-round `disconnect` elimination (Karera ledger and Lagsanay controller) and the network results gating;
- the authored `run_nlb_p08_tests.gd` and `run_nlb_p08_multi_process.gd`, schema/build/cell-count updates to the P04, P06 and P07 tests, and the P08 evidence, tracker and status documentation.

While the user's game was running on the shared laptop, nothing was launched or run: no Godot editor, game, headless run, script, import, export, test suite, multi-process or phone session, ADB, network listener, capture, lint or performance measurement. Only `git diff --check`, git status, grep audits and manual source review were performed. The code has therefore never been parsed by Godot.

All three P08 tracker boxes remain unchecked, with the actual result `COULD-NOT-RUN`. P06-T03 and the upstream dependencies remain open, and this authorization does not clear them. No human review is claimed. No art, audio or other production asset was generated; the pause banner is a text label. The code is original to this task, with no Ultimate Chicken Horse or third-party core implementation copied; provenance review remains the team's responsibility. See [P08 evidence and exact deferred commands](evidence/nlb/p08/README.md).

## Form 03 preparation

The team must choose the official extent category (Minimal / Moderate / Heavy) based on all project-wide AI work and obtain required signatures. Do not claim the project is unaided. Keep this record aligned with actual assistance, asset records, prompts/history and repository history. Review factual claims, cultural names, gameplay rules and citations before submission. Do not invent missing prompts or review evidence.

## Historical delivery-specific records

The following descriptions are scoped to the specific deliveries named. Statements that those deliveries did not include gameplay code, or that a task was documentation-only, remain accurate for those deliveries; they do not describe the cumulative project assistance or current standing policy.

### Filipino obstacle and event-design documentation — 2026-10-12

OpenAI Codex assisted with design research, synthesis, specification, gap analysis and documentation for the Filipino obstacle catalog and event-design handoff. It produced/revised `docs/GDD.md`, `docs/ROADMAP.md`, `docs/ITEMS.md`, `docs/PLAYTEST.md`, and this record. It included research summaries and links about Ultimate Chicken Horse item families, labeled as reference material and adaptation ideas. No production game code, movement, placement, trap, event, scoring, scene or asset implementation was generated in this specific documentation delivery. No item was implemented or gameplay-tested by that task.

### Prototype-default handoff — 2026-10-12 to 2026-10-13

Codex inspected repository/documentation state, queried engine documentation, calculated provisional movement arcs and legal placement averages, and prepared prototype recommendations and verification planning. Task-authored edits were `PROTOTYPE_DEFAULTS.md`, `STAGE_AND_PLACEMENT.md`, `UI_TUTORIAL.md`, `PRODUCTION.md`, `ROADMAP.md`, `PLAYTEST.md`, `INDEX.md` and the contemporaneous AI record. Existing GDD rules were preserved; proposed gameplay rule changes remain labeled inactive pending explicit review. This delivery generated no gameplay implementation, scene, asset, prompt file, network/save system or engine-version change. Mathematical/document checks did not constitute physical playtests, controller validation, performance measurements or balance evidence.

### PRD and phased tracker — October 13, 2026

Codex inspected local and merged source documents plus external-repository structure examples, reconciled authority/scope with the user, and drafted the PRD and phased implementation tracker. That documentation delivery used an isolated `feat/prd-phasetask` worktree based on fetched main `98ef17a`; the original dirty checkout and reference repositories were preserved. README navigation was carried forward; INDEX and approved GDD/ROADMAP/PRODUCTION scope wording were aligned. Prototype defaults and inactive R1–R4 were preserved. No game mechanics code, scene, production asset or gameplay test was generated/executed in that specific delivery.

### P00 production-readiness work — October 13, 2026

Codex inspected P00 requirements, production/toolchain records, project settings, local executable/template inventory, and observable target-PC/device information in an isolated `feat/p00-production-readiness` worktree at source revision `fa6145839bff96ecb6e1afdb112e804bfb72260f`. It recorded baseline evidence, documented local toolchain/PC observations and limits, and ran a Godot 4.7.2 headless import of an isolated project-skeleton copy. That import exited 0 with no warnings/errors. A separate working-project editor initialization exited 0 but logged an engine error and shutdown-thread warning. No gameplay code, scene, asset, software installation, engine setting, export fixture, physical-device test, gameplay test or performance measurement was produced by that P00 delivery. No export was attempted because there was no export preset or entry scene and exact template compatibility was unconfirmed at that time. Full console evidence is in `docs/evidence/p00-*.log`.

### P01 project foundations — October 13, 2026

At the user's explicit direction, OpenAI Codex authored P01 foundation scripts, scenes, diagnostic fixture rooms, focused checks, Windows export preset, project-structure documentation and P01 evidence updates in the existing main worktree. The work includes typed provisional settings/profile snapshots, profile/content validation, seeded diagnostic streams and a local development harness. Fixture rooms are placeholders; this P01 slice did not implement player movement, items, scoring, match lifecycle or event mechanics.

The P01 work was AI-generated and recorded under the task authorization and internal policy in force at that time. This history is not a current per-phase exception model. It is not represented as manually team-written, and it does not establish competition eligibility or organizer acceptance. P01-T02's actual human review evidence remains open. No third-party gameplay code, tutorials, templates or assets were used for core mechanics.

Codex also downloaded the official Godot 4.7.2 export-template archive, verified its archive identity/hash and embedded version, installed it in the standard versioned template directory, ran lint/format/import/headless/export checks, launched the exported executable locally and recorded results. The editor's template-manager UI was not used. These checks verify foundation diagnostics and local export startup/exit only; they do not establish gameplay, controller, performance, independent review or competition acceptance.

### P02 inputs and controller — October 13, 2026

At the user's direction after the task's Stage A plan approval and authorization clarification, OpenAI Codex implemented P02-T01–T14 systems and focused evidence tooling in the existing `main` checkout: local seat/device assignment and number/shape markers; phase-specific K1/K2/gamepad routing and fresh-edge/repeat handling; pause, focus/device-change, reclaim and all-ready resume coordination; typed run/jump movement, separate contact sensor and lifecycle state; visible movement/input fixtures and a narrow containment recovery contract; P02 automated tests, rendered capture, tracker and documentation updates. This work was AI-generated and is not represented as manually team-written. Its per-phase authorization was recorded under the then-current internal policy; the current standing policy supersedes that authorization model.

Godot 4.7.2 executed the P01 regression suite and P02 synthetic input/physics checks. The P02 fixture produced measured jump, braking, reversal, reachability, launch and rendered performance observations. Synthetic device events do not count as physical gamepad, keyboard rollover, unplug/replug or exported interactive-input tests. Those hardware checks remain open. P01-T02 human review is still open; implementation authorization does not establish DOST eligibility or organizer acceptance. No official Form 03 extent category has been selected or signed. R1–R4 remain inactive.

### P03 graybox stage and camera — October 13, 2026

At the user's direction after the P03 plan approval, OpenAI Codex implemented P03-T01–T06 in the existing `main` checkout: reusable protected arena data and scene integration; bounded Play/Place camera and debug fixtures; support provenance, actual contact tracking and same-step invalidation; automated route/camera/support checks; GUI-rendered screenshots/performance evidence; and tracker/specification/test documentation updates. Godot 4.7.2 tests passed, the rendered fixture was captured and inspected, and a Windows Desktop export/headless startup smoke passed. The implementation is AI-generated; the code-drawn geometry is labeled development/debug content. No final character, map, interface, audio or other production asset was AI-generated. This record does not claim independent human review, organizer acceptance, physical-device certification, or completion of Pugad/Place/match/gameplay systems. See [P03 verification](evidence/p03/2026-10-13_p03_verification.md).

### Standing policy and documentation correction — October 13, 2026

At the lead developer's direction, this documentation correction replaces the earlier internal “team manually writes core code; AI only reviews/documents” policy and phase-specific AI implementation exceptions with the standing AI-assisted programming workflow at the top of this file. This is a policy/documentation change, not gameplay implementation or proof of human review, organizer approval, registration or eligibility. At that time, the current production roles supplied were a lead developer and a co-lead developer, both using AI-assisted programming; art/asset creators had not yet been assigned in the repository. The later human production-role clarification is recorded below. No surnames, hours, registration facts or reviewer identities are inferred.

### Human production-role clarification — October 13, 2026

The lead developer later supplied the current assignments: team members handle UI design and game audio, and maps, characters, obstacles, traps, effects and related game assets. These assigned production visuals and audio will be created without AI generation. This records responsibilities only; it does not claim that assets are complete or establish registration, hours, review completion or competition eligibility.

### Verification of the PRD/tracker documentation delivery — October 13, 2026

The earlier documentation delivery recorded structural and content checks for 116 requirements, 20 phases and 393 tasks (207 required, 24 Should, 4 conditional-finalist, 158 expansion), rendered IDs, dependency DAG, traceability, local links/anchors, family destinations, variants, untouched source/reference hashes and whitespace. All game/delivery tasks remained unchecked. Those documentation checks did not constitute gameplay verification. See [PHASETASK documentation verification](PHASETASK.md#documentation-verification--october-13-2026-original-prdtracker-delivery).

### Wall-movement planning and documentation — October 13, 2026

At the user's approval, OpenAI Codex added the wall-slide/wall-jump extension to the Tilaok! planning documents as separate Should scope. This assistance updated the PRD, GDD, PHASETASK, prototype defaults, playtest plan, roadmap, production plan, stage/support contract, tutorial guidance, project-structure status, README/INDEX counts and this disclosure record. The approved behavior remains unimplemented; all eight new gameplay implementation/verification tasks are unchecked. Numeric tuning is provisional. No movement code, scene, test, tuning resource, production asset, runtime trial, human feel review or balance result was created or claimed in this documentation task. This record does not claim human review or make the extension a required submission feature.

### Wall-movement implementation — October 13, 2026

At the user's approved Stage A plan, Claude (Anthropic) implemented and verified the P02-T15–T21 work for the approved Should-scope wall slide/jump extension in the existing `main` checkout: a wall-contact probe, controller slide/kick/lock logic, explicit per-surface wall-eligibility metadata, centralized tuning keys, labeled debug fixtures for the P02/P03 diagnostic rooms, a focused 85-check test runner, a rendered-capture script, and tracker/specification/evidence updates. The code is AI-generated and is not represented as manually team-written. Claude installed the official Godot 4.7.2 editor (and, for the export smoke, its templates) and gdtoolkit 4.5.0 outside the repository at the user's authorization, then ran import, lint, format, the foundation/P02/P03 regressions, the wall runner, rendered captures and performance samples. A first pass was written without an engine; real runs then exposed a missing finite-validation entry and several test-setup errors, which were fixed. No human review, physical-device test or feel/balance evidence exists; P02-T18 and P02-T22 remain unchecked. No art, audio or other production asset was generated. See [wall evidence](evidence/p02-wall/README.md).

### P05 lobby, Pugad and construction loop — October 14, 2026

At the user's direction to implement the approved P05 plan on updated main, OpenAI Codex generated and integrated the P05 phase controller, lobby/readiness model, seeded weighted Pugad egg pool and claim arbiter, placement controller/ghost feedback, snapshot-based atomic resolver, results view model/panel shell, scene/harness integration, tuning validation, test-only mover/cleanup/solid-trigger fixtures, automated and interactive runners, capture tooling and tracker/evidence/documentation updates. The updated-main commit fa5a4e2 already contained the separate UI screen/component review gallery; Codex did not generate that gallery as part of P05. The first P05 export attempt exposed an invalid theme type variation in that UI dependency. The updated-main commit supplied the corrected theme variation, and the final export passed. This work is AI-generated programming and is not described as manually team-written.

Godot 4.7.2 import, lint/format, automated regressions, GUI harness runs, captures, local performance sampling, Windows Debug export and exported headless startup were run and recorded in docs/evidence/p05/. Codex ran the updated-main UI gallery contract runner, which passed 437 synthetic checks as a separate dependency smoke; its sample results are not connected to the P05 match room or scoring. Four-seat coverage uses synthetic gamepad identities for seats 3/4; physical controllers and human player review were unavailable. No independent human code review is claimed. Code-drawn P05 visuals are DEBUG placeholders; no final art/audio was AI-generated or imported. P05 has no score calculation, Karera finish logic, Walis Cleanup gameplay, network traffic or persistent save. P05-T12 and the phase exit remain blocked by P06-T08 result evidence. This record does not establish organizer approval, competition eligibility or completion of the human Form 03 process.

### Scene-based UI shells — October 14, 2026

At the user's approved plan, Claude (Anthropic, Sonnet 5.5 via Claude Code) generated the scene-based placeholder UI shells: the project Theme, Control-node screens and components, binding scripts, SAMPLE data resources, the UI Gallery harness room, `run_ui_tests.gd`, `capture_ui_evidence.gd` and the UI_HANDOFF how-to. Some scenes were produced by a small generator script kept out of the repository. No images, fonts or audio were generated. Verified with Godot 4.7.2 import, gdlint/gdformat, the 437-check UI suite and existing suites, rendered captures and a frame-time sample (`docs/evidence/ui-shells/`). No independent human review is claimed; real editor use by the UI role remains open.

### P06 Karera and scoring implementation — October 14, 2026

At the user's approval of the P06 plan, OpenAI Codex generated and integrated the P06 race clock/controller, candidate queue, terminal outcome ledger, exact race score calculator, placement arithmetic, score formatter, live results model/panel binding, ArenaDefinition goal trigger, actor round reset, focused tests, rendered P05/P06 evidence and the P06 documentation updates. This is AI-generated programming and is not represented as manually team-written. The approved tie policy awards no Patibong where a direct hazard and non-hazard elimination candidate tie in one physics step.

Godot `4.7.2.stable.official.ed1daf0bf` passed the 97-check P06 suite, the 17-check two-seat live run, the dependent 64-check four-seat P05 loop, the existing foundation/P02/P02-wall/P03/P04/P05/UI regressions, editor import/class registration, Windows Debug export/startup smoke, GDScript format/lint checks, and 2/3/4-seat ten-round rendered performance sampling. Logs and limits are recorded in `docs/evidence/p06/2026-10-14_p06_verification.md`. Synthetic/gamepad identities and scripted positioning were used; physical-device coverage, human playtest, independent review and balance/readability review were not performed. The code-drawn UI remains DEBUG placeholder work; no final art, audio or other production asset was generated.

The checkout also contained a separate uncommitted P10 work-in-progress set. Its files/assets are not included in the P06 task scope or staged for the P06 delivery. This record does not establish organizer approval, competition eligibility or Form 03 completion.

### P07 First Playable route and engineering checks — October 14, 2026

At the user's direction to implement the approved P07 plan, OpenAI Codex generated and integrated a dedicated P07 harness route, a room-specific Kaing/Tulay variant allowlist with generated-pool validation and a clear unsupported-pool fallback, reset audit instrumentation, route/reset test runners, a 1080p scripted capture/performance runner, and the P07 tracker/evidence and project documentation updates. The implementation reuses the existing match flow, preserves the `karera_slice` profile and global tuning, and does not change the GDD. This is AI-generated programming and is not represented as manually team-written.

Godot 4.7.2 passed the focused 590-check route suite, the 172-check synthetic ten-transition reset audit, foundation/P02/P03/P04/P05/P06/UI regressions, import/parse, lint/format, Windows Debug export and exported headless route startup. Project-runner captures and local 2/3/4-seat performance samples are recorded in `docs/evidence/p07/`. The packaged executable's `--script` capture probe did not run the capture script, and no exported UI screenshots were saved. All scripted runners use synthetic input/gamepad identities and scripted goal placement. No human playtest, novice observation, physical gamepad test or independent human review is claimed; P07-T01–T04 remain open, and P02-T08 remains COULD-NOT-RUN. No final art, audio or other production asset was AI-generated. Full-match ending, Lagsanay and sudden death remain outside P07.

### P10 remaining first-batch families and Item Visualizer — October 14, 2026

At the user's approved Stage A plan, Claude Code (Anthropic, Sonnet 5.5) generated and integrated the P10 programming work: the per-step hazard director and the spring, rail-top, Parol, launcher and bubble behaviours with their path/phase/lane/swept-contact/safe-release/cleanup components, the typed attribution record and its hand-off to the P06 race ledger, the schema/validator/placement/resolver extensions, six family definitions and visual-set resources, the egg/ghost/Library presentation, the Item Visualizer and all-families match room, the `PlaceholderAudit` release gate, and `run_p10_tests.gd`, `run_p10_interactive.gd` and `capture_p10_evidence.gd`. It also generated the 23 temporary PLACEHOLDER SVG/WAV files with `tools/generate_placeholder_assets.gd`; these are temporary development stand-ins, not final production assets, and final art/audio remain human-made.

Verification (Godot 4.7.2): 421 P10 checks, 56 rendered interactive checks, the foundation/P02/P02-wall/P03/P04/P05/P06/UI regressions, lint/format, editor import, a 48-item four-seat performance capture, a file-level placeholder swap probe and a Windows export with exported startup smoke are recorded in `docs/evidence/p10/`. The P03 interactive suite is flaky on the unchanged baseline too. No human review, playtest, organizer approval or Form 03 completion is claimed. Generation prompts/outputs are preserved only in the session transcript; no separate prompt archive was created.

### P09 match lifecycle and sudden death — October 14, 2026

At the user's direction under the standing AI-assisted programming workflow, OpenAI Codex generated and integrated the P09 match lifecycle coordinator, validated 80-eighth-point and 12-round tuning, P09 development room and harness route, Lagsanay sudden-death tie-in, original-seat spectator handling, live themed match-results binding, Replay/Lobby/Quit readiness and confirmation flow, focused/interactive/restart runners, and the P09 tracker/evidence and documentation updates. P09 reuses the P07 three-variant allowlist and P08 Lagsanay controller; it does not implement P12 scheduling/stacks or change release-profile rejection behavior. The code is AI-generated programming and is not represented as manually team-written.

Godot 4.7.2 passed 77 focused assertions, 108 rendered interactive assertions, ten ending/restart cycles, relevant regressions, import/parse, GDScript lint/format, Windows export and direct/exported route smoke. Real physics was used for Lagsanay contact transfer. Seats, race finish candidates, shortened timers and one Last Cluck hazard record are synthetic; no human/device/release acceptance is claimed. Frame p95 exceeded the provisional 16.67 ms target. No final art, audio or production asset was generated, and no independent human code review is claimed. Detailed evidence and limitations are in `docs/evidence/p09/README.md`. The approved plan and implementation task are preserved in the conversation; no separate prompt archive was created.
### 64 px grid, sneak/glide and stage blocks — October 14, 2026

At the user's request in a Claude Code session (Claude Opus 5.5, Anthropic), Claude generated and integrated: the 64 wu grid rescale of `GameplayTuning` (with `with_distance_scale()` / `legacy_32_wu()` keeping the P02 room on its historical scale), tuning-based launch caps, the 64 px stage TileMapLayer (`scenes/stage/stage_tiles.tscn`, `stage_tile_layer.gd`, a code-written flat placeholder atlas via `tools/make_debug_tiles.gd`), W/Up as jump during Play, sneak and glide in `ChickenController`, block contact/push notifications, three scene-authored block families (Solid Block, Wood Box, Collapsing Block) with scripts, data and registration, a `reset_to_placed` safe-start state, an Item Lab egg-row layout fix, the 60-check `run_blocks_tests.gd`, `capture_blocks_evidence.gd`, and updates to existing tests whose hardcoded 32 wu literals changed (expectations scaled, assertions not weakened). the team's earlier prototype (`scenes/prototype/`) was read but not copied or modified; its wall slide/jump idea was already implemented in the main controller. The code is AI-generated and is not described as manually team-written.

Verified with Godot 4.7.stable.official.5b4e0cb0f (the 4.7.2 build named elsewhere was not installed on this PC): import, gdlint/gdformat, all eight suites (1,173 synthetic checks, 0 failures) and 1080p rendered captures in `docs/evidence/blocks/`. No human code review, physical-device test or feel/balance review is claimed; P02-T26 stays open. No final art or audio was generated; tile and block visuals are DEBUG placeholders.

### Merge of the 64 px grid work with P06/P10 — October 14, 2026

At the user's request, Claude (Claude Opus 5.5 via Claude Code) resolved the merge of the 64 px grid/sneak/glide/stage-blocks commit with upstream P06 (Karera scoring) and P10 (first-batch hazards). It kept both sides in the conflicted files, doubled the P10 distance/speed tuning and the safe-release search for the 64 wu grid (adding them to `GameplayTuning.DISTANCE_FIELDS`), tied the spring cap validation to the launch-cap keys, added the stage blocks to the `items_lab` first-batch set, and scaled the 32 wu literals in `run_p10_tests.gd` (and its family/pool count checks for the three blocks) without weakening assertions. Verified with Godot 4.7.stable.official.5b4e0cb0f: foundation, P02 83, wall 85, P03 103, P04 268, P05 137, P06 97, P10 424, UI 437 and blocks 60 checks, 0 failures. No human review or physical-device test; the P10 hazard feel at the new scale still needs a playtest.

### Chicken scene and sprite animations — October 14, 2026

At the user's request, Claude (Claude Opus 5.5 via Claude Code) generated `scenes/characters/chicken.tscn` (controller, body shape and an AnimatedSprite2D whose SpriteFrames map the team's placeholder sprite sheet), `chicken_sprite_animator.gd` (state → animation, feet offsets, seat tint), a `draw_debug_body` switch in `ChickenController`, scene use in `P03StageRoom._build_actor`, an egg-preview routing fix for the stage blocks after the P10 merge, and 16 animation checks in `run_blocks_tests.gd`. The sprite sheet itself was supplied by the team and was not AI-generated. Verified with Godot 4.7.stable.official.5b4e0cb0f: all ten suites (1,710 checks, 0 failures), lint/format and a 1080p capture. No human review.

### P08 independent Lagsanay — October 14, 2026

At the user's request, after the Stage A plan was approved, OpenAI Codex generated and integrated the P08 programming work: validated Lagsanay timing snapshots and an independent seeded taya stream; opening freeze/immunity and sensor-based pass arbitration with stale-overlap cleanup; batched timeout/hazard eliminations, taya reassignment and integer eighth-point placement/Patibong/Bawi scoring; an independent mode hazard sink preserving actual Trumpo and Launcher source/owner records; comparable-time Last Cluck placement with legacy tick-only compatibility and explained results; the development-only `lagsanay_lab` profile, harness route and independent match-room integration; focused tests, rendered/performance runners, and task documentation/evidence. It also updated the existing placement resolver compatibly and extended actual mode flags only for the two tested hazards. The pass-back HUD explicitly describes immunity and other eligible receivers. No final art, audio or production asset was generated; presentation remains code-built DEBUG UI.

Godot 4.7.2 verified 86 focused checks, 87 rendered 2/3/4-seat checks, real Trumpo and projectile contacts, all 13 regressions, import/parse, format, Windows Debug export/startup, and 1080p timing/memory/restart/cleanup observations. Exact commands and limits are indexed in `docs/evidence/p08/README.md`. The work and seats were synthetic; no independent human code review, physical-device session, player/novice review, or organizer approval is claimed. P07-T04 remains open; P08 development authorization did not remove or satisfy that gate. AI assistance is disclosed as code generation/integration, not manual human authorship. The approved plan and task details remain available in the conversation; no separate prompt/output archive was created. Form 03 has not been submitted or signed.

### Live match UI wiring — October 14, 2026

AI-assisted programming (Claude Code, Sonnet 5.5 via the Claude Agent SDK) wrote `GameFlow`, `MatchScreenPresenter`, the DEBUG overlay, the additive `bind_live*` methods and scene nodes, the pause-menu hook on `PauseRecoveryCoordinator`, the room refactor that removes the code-built HUD, the migration of the P08 Lagsanay lab and P09 lifecycle rooms onto the same screens (presentation hooks on `P05MatchRoom`, an authored taya marker and match-result / confirmation nodes in `match_hud.tscn`, the opt-in `--match-route=lifecycle` flow route), the migrated test couplings and the new `run_match_ui_tests.gd`, `run_match_ui_binding_tests.gd`, `run_match_ui_mode_tests.gd`, `run_match_ui_interactive.gd` and `capture_match_ui_performance.gd`, plus the evidence and documentation updates. The user approved the plan (D1–D10) and the decision to migrate P08 and, after it landed, P09 as well, and directed the work; the AI session ran the suites and captured evidence on the user's machine with synthetic input only. **No independent human code review, physical-device test or playtest is claimed.** No art, audio or Theme asset was generated or edited: the human-owned Theme and sprite sheet are untouched. Prompts and outputs are in the session transcript; the plan is preserved in the delivery notes.
### P11 independent Kangaroo — October 14, 2026

At the user's request under the standing AI-assisted programming workflow, OpenAI Codex generated and integrated the independent `KangarooRoundController`, immutable command-instance definitions, validation/defaults for P11 timing and world-space Rising lines, the dedicated `kangaroo` seeded stream, Freeze input-edge tracking/grace, current-support Rising checks, deterministic Hug pairing, strict recorded-time hazard ordering, marker/terminal/Last Cluck resolution, cadence/Slipper Storm, an independent Kangaroo scorer using the shared `PlacementScoreResolver`, the `kangaroo_contract_lab` profile and harness route, the standalone match-room integration, visual-only debug pose/wave/HUD and runtime debug tones, plus focused and interactive test runners. It updated the two hazard compatibility records and the seed build definitions required for the profile. No Lagsanay round controller was used for the standalone room.

The user supplied the P11 design decisions and approved implementation scope. The code, tests and documentation are AI-generated programming outputs and are not described as manually team-written. Human developers remain responsible for integration, review and delivery; no separate human code review was performed during this session. The temporary pose, timing and audio cues are visibly labeled DEBUG placeholders. No final art, recorded audio, or other production media was generated. No UCH code, names, characters, art, or audio were copied.

Automated evidence currently includes the 78-check focused P11 suite, 85 synthetic 2/3/4-seat rendered interactive assertions, rendered 1920×1080 debug HUD and Last Cluck captures, P02/P03/P08/P09/P10 regressions (83/103/86/77/430 checks), and the scene-based match UI, binding, mode and general UI suites (198/185/62/447 checks), all with 0 failures on Godot 4.7.2. Editor import/class registration, GDScript format/lint, Windows Desktop Debug export and exported headless startup also passed. Detailed commands and output are indexed in `docs/evidence/p11/README.md`. Tests used synthetic seats and inputs; they are not physical-device or human-play evidence. Local debug timing samples exceeded the provisional 16.67 ms frame target; Godot static memory was 110.4–111.0 MiB; a 14-second Windows process sample measured 306.7 MiB peak working set and 420.5 MiB private bytes at 100 ms intervals, below the provisional 512 MiB private-memory ceiling for this local Debug run only. These are not release-PC certification. P11 human comprehension, physical controllers, balance/cultural review, target-PC performance/memory acceptance and production-asset review remain open. The prompt and generated output history are available in this conversation; no separate prompt archive was created. Update this record and Form 03 preparation if later assistance or human reviews change these facts.

### Guided first match with a build-to-reach-the-flag gate — October 14, 2026

Claude (Sonnet 5.5) in Claude Code generated the data-driven `ArenaLayout`/`ArenaDefinition` hook, the tutorial stage layout resource, `TutorialSession`/`TutorialScript`/`TutorialCoordinator`, the BUILD HERE marker scene, the additive coach-box, pause, library and flow wiring, the PLACEHOLDER English tutorial copy, and the gate, coordinator and capture scripts, under the users' direction and plan approval. The copy is not culturally or linguistically reviewed. Verified on Godot 4.7.2 with synthetic input only: a real-physics gate search (1,860 no-build attempts, none reached the flag; highest feet y 511.94 against a ledge top of 480), 48 gate checks, 140 coordinator/flow checks, 91 rendered capture checks, all existing suites unchanged (P04 keeps the two failures it already had on `origin/main`), gdformat/gdlint, a Windows Desktop debug export and its headless startup. Detailed commands and output: `docs/evidence/tutorial/README.md`. **No human review of the generated code, no novice session and no organizer approval is claimed**; the generated code is not described as manually team-written. No art, audio or production asset was generated. No UCH code, names, characters, art or audio were used. Prompt and output history are in this conversation; no separate archive was created.

### Block scenes (BlockData), Spikes, Cannon, stun and death sprite — October 14, 2026

At the user's request, Claude (Claude Opus 5.5 via Claude Code) generated the scene-authored block system: `BlockData` (an aLima-style `@tool` customization node modelled on the `ArtifactScannerData` pattern the user supplied), `BlockHitbox`, the folder-scanning `BlockCatalog`, the `StageBlock` runtime (anchor/gravity, push, collapse, projectile visuals), touch kill/stun effects in the item behaviors and director, a per-block tuning-override path, `ChickenController.apply_stun` and the animator's stun/death states, and the scene-preview egg path. A one-time migration script (not kept) converted every `data/items/*.tres` family into one scene per variant region-for-region; a parity script confirmed 0 differences before the `.tres` families, the `ItemApprovedVariants` table and the old piece scenes/scripts were removed. Spikes and Cannon were generated as new block scenes with DEBUG placeholder visuals. Existing P04/P10/blocks tests were updated only where counts, node layout or class names changed; assertions were not weakened. The chicken death pose and sprite sheet are the team's; no art or audio was AI-generated. Verification: see `docs/evidence/blocks/` (2026-10-14 block-scene records). No human code review or player feel review is claimed.

### Selector pool and first-come-first-served Place — October 14, 2026

At the user's request, Claude (Claude Opus 5.5 via Claude Code) made the match egg pool catalog-driven (`P07FirstPlayableMatchRoom.allowed_variants()`, used by P07/P09 and the Library) so Spikes, Cannon and future block scenes reach the selector, and changed Place to first come, first served (`MatchPlacementController.confirm_order`/`claimed_by`, `P05MatchRoom._placement_verdict`, confirmation-ordered `AtomicEditResolver`), with the new 12-check `run_place_claim_tests.gd`. This changes the earlier design rule that rejected conflicting placements as a set; GDD and STAGE_AND_PLACEMENT record the change. AI-generated code; no human review claimed.

### Hitbox "Effect" rename and match-kill fix — October 15, 2026

At the user's request Claude renamed the BlockHitbox `role` property/enum to `effect`/`Effect` (scenes, catalog, tests). The user reported that spikes did not kill: in the P05/P07 match rooms the item hazard director ran after the room had already resolved the race step, and the race ledger accepts only same-tick candidates, so every item elimination (Spikes, Cannon and the P10 hazards) was silently dropped in those matches. The match room now runs the director just before itself (`P05MatchRoom.start_match`), and `run_place_claim_tests.gd` gained a real-match spike-kill regression. AI-generated; no human review claimed.

### P12 event schedule and announced Main rounds — October 15, 2026

At the user's request, after the P12 plan was approved, Claude (Claude Opus 5.5 via Claude Code) generated:
- `EventSchedule`: seeded per-round locking, Main weights, Twist bands, the disabled compatibility registry and the required-mode refusal.
- `P12ScheduledMatchRoom` and its scene: the full match on the `--match-route=lifecycle` route, running Lagsanay and Kangaroo Main rounds with the existing controllers and scoring.
- `KangarooMainRound`, a host for Kangaroo inside the full match, and `KangarooCommandStyle`, which moves the P11 lab's DEBUG prompt, icon, tone and marker code into one shared place.
- The P09 `_conclude_round` extraction, the Pugad announcement binding and the Play HUD Twist tag.
- `run_p12_tests.gd` (61 checks) and `capture_p12_evidence.gd`.

It also found and fixed two defects in the existing P11 `KangarooRoundController`, both now covered by regressions:
- Storm drain: the base cadence never resumed after an elimination interrupted a Slipper Storm.
- `reset()` cleared the room's actor map.

AI-generated code; it is not described as manually team-written, and no human code review, player session or physical-device test is claimed. No art, audio or production asset was generated; all presentation stays DEBUG placeholder. Evidence: `docs/evidence/p12/README.md`. Prompts and outputs are in this conversation; no separate archive was created.

### P13-T13/T14 results scoreboard chart — October 15, 2026

At the user's request, OpenAI Codex generated and integrated the reusable `ScoreboardChart` / `ScoreColumn`, bounded committed score-presentation history, award legend and Theme tokens, result reveal motion setting, shared chicken SpriteFrames resource reference, round and match result screen changes, focused tests, rendered capture fixture and related documentation. Work was limited to programming and UI layout code; no final art, audio or font was generated. Existing team-supplied placeholder chicken frames were externalized to a shared Godot resource, not redesigned. The user-provided scoreboard image informed only the general layout concept of player columns and a shared score axis; its visual design, colors, typography, decoration, art and branding were not copied. The score values and winner rules did not change.

Automated evidence: 52 scoreboard/history checks; UI binding 185; match UI flow 198; mode UI 62; P06 97; P08 86; P09 77; P11 78; rendered interactive P06/P08/P09/P11 routes 17/87/108/85; import/parse, GDScript format/lint, Windows release export and exported startup all passed. See `docs/evidence/scoreboard/README.md` for captures and limits. Inputs and players were synthetic; no independent human code review, physical-device check or human readability review is claimed. The generated code is not described as manually team-written; the users retain integration, review and delivery responsibility. The prompt and output history are in this conversation; no separate prompt archive was created.

### Explosives, Pugad pick lock and merge — October 15, 2026

At the user's request, Claude (Claude Opus 5.5 via Claude Code):
- Resolved the merge with `origin/main` (the scoreboard commit `d930bd1`): the P09 race end now binds the scoreboard inside the shared `_conclude_round`, P12 event rounds record their scores for it, and the task counts were recomputed.
- Generated the Bomb (2x2), Dynamite (3x3) and Nuke (4x4) block scenes (Special = Cleanup, DEBUG placeholder polygons), the `ExplosionFlash` placeholder blast and its hook in `P05MatchRoom`, and the Pugad pick lock.
- Added `run_explosives_tests.gd` (23 checks) and `capture_explosives_evidence.gd`. Updated hardcoded family counts in the P04/P10 suites, the match-UI node-count check (egg previews counted as one node) and the two spike checks for the narrower Spikes hitbox set in the editor.

AI-generated code; no human code review or player session is claimed. No final art or audio was generated. Evidence: `docs/evidence/blocks/README.md`.

### Death fall and P12 Karera + Bomb-Taya pair — October 15, 2026

At the user's request, Claude (Claude Opus 5.5 via Claude Code):
- Made eliminated chickens keep falling until they land (`ChickenController._fall_while_eliminated`, plus a blocks-test regression).
- Continued the approved P12 plan:
  - `BombTayaTwist` and its `P12ScheduledMatchRoom` integration (HUD tag, taya marker, race-ledger timeout reporting).
  - Enabled the Karera + Lagsanay compatibility row.
  - `run_p12_stack_tests.gd` (47 checks) and `capture_p12_twist_evidence.gd`, with the P12 schedule tests updated for the enabled row.
  - The draft terminal-order decision table `docs/P12_TERMINAL_ORDER_DRAFT.md` (P12-T03, awaiting team review).

AI-generated code and draft; no human code review, player session or team approval is claimed. No art or audio was generated.

### P12 Kangaroo stacks and approved terminal order — October 15, 2026

At the project owner's direction, after the owner approved the plan and the decision table row by row (U1–U12, D1–D7), Claude (Claude Sonnet 5.5 via Claude Code) generated and integrated, on top of `origin/main` `ef78950`:
- The approved same-step ordering in `BombTayaTwist` (finishing-taya handoff keeps the countdown, timeout beats a same-step goal, no stale-contact pass) and the Twist role in `KangarooRoundController` (external elimination and secure-seat APIs, no Storm, no round end as a Twist).
- Karera + Kangaroo and Kangaroo + Bomb-Taya integration in `P12ScheduledMatchRoom`, an optional `cause` on the race ledger queue, results-text causes, the harness room key and the enabled compatibility rows.
- `p12_table_scenarios.gd`, `p12_pair_room_scenarios.gd`, `run_p12_pairs_tests.gd` (287 checks), `run_p12_pairs_interactive.gd`, `capture_p12_pairs_performance.gd`, the decision-table record, evidence and the documentation updates.

AI-generated code. The owner approved the decision table; no human code review, player session or physical-device test is claimed. No art, audio or production asset was generated. Evidence: `docs/evidence/p12/README.md`. Prompts and outputs are in the session transcript; no separate archive was created.

### P13 UX, onboarding and accessibility — October 15, 2026

At the project owner's direction, after the owner approved the Stage A plan and answered decisions D1–D3 (dependency override, keyboard session, technical checks), Claude (Claude Sonnet 5.5 via Claude Code) generated and integrated, on top of `origin/main` `1d058e2`:
- Routing and navigation: the scheduled match as the default route, `--match-route=first_playable` / `--match-seed`, Lobby help and a confirmed Lobby Back, Quit through the flow, held-press consumption on screen swaps, left-stick menu navigation.
- Presentation: HUD next-round and Kangaroo readout scenes, Round result Last Cluck / Twist / next-round lines, the real Library (pages, scrolling, enabled-content filtering, dev reference mode), audio buses with Mute, shake wiring, a ≤ 2 Hz stun pulse, and result-layout fixes found while inspecting captures.
- Tutorial and onboarding: Kangaroo and Bomb-Taya just-in-time prompts.
- The spectator cheer (`SpectatorCheer`, code-generated placeholder cue) and the keyboard chord recorder.
- `run_p13_navigation_tests.gd` (205), `run_p13_hud_tests.gd` (264), `run_p13_library_tests.gd` (352), `run_p13_tutorial_tests.gd` (55), `run_p13_accessibility_tests.gd` (65), `run_p13_cheer_tests.gd` (39), `run_p13_recorder_tests.gd` (60), `capture_p13_evidence.gd`, the evidence set in `docs/evidence/p13/`, the PLAYTEST sheets and the documentation updates.

AI-generated code and PLACEHOLDER copy. No human code review, spectator, novice or QA session, physical gamepad or physical keyboard test is claimed. No final art, audio or font was generated; the cheer cue and Kangaroo tones are code-generated placeholders owned by the UI/audio role for replacement. Prompts and outputs are in the session transcript; no separate archive was created.

### Scoring-family clarification — October 15, 2026

At the owner's direction, Codex clarified the existing Karera and elimination scoring contract in the GDD, PRD, UI handoff, tutorial and in-game Library copy. The owner explicitly kept Karera's Una +0.25 first-finisher bonus and confirmed that fourth place in Lagsanay/Kangaroo earns zero placement points while retaining eligible direct Patibong. The calculators already implemented these rules, so no gameplay scoring code was changed. Codex added focused synthetic assertions for four-player survival order, both elimination calculators and the Library explanation. Godot 4.7.2 import succeeded; P06 (99 checks), P13 Library (354), P08 (86) and P11 (78) passed with zero failures. No human review, physical-device test or playtest is claimed. Prompts and outputs remain in the task transcript.

### Karera all-finish zero-point correction — October 15, 2026

At the owner's request, Codex changed `RaceScoreCalculator` so all joined players reaching the flag awards zero round points in 2–4-player Karera, including test-only Barya. It removed the two-player waiver from the guided tutorial result selection, revised in-game Library/tutorial copy, updated affected automated checks and aligned the GDD, PRD, UI handoff, tutorial, playtest and phase-task descriptions. The prior scoring and explanation evidence remains in the repository as a historical record of the superseded rule. Actual Godot 4.7.2 synthetic verification and limits are recorded in [the dated P06 update](evidence/p06/2026-10-15_all_finish_zero.md). No final art/audio, human review, physical-device test or player session is claimed. Prompts and outputs remain in the task transcript.

### Barya exception restored for all-finish Karera — October 15, 2026

The owner clarified that Barya definitely counts even when everyone finishes. Codex restored the Barya payout in `RaceScoreCalculator` while retaining suppression of Tapos, Una and other ordinary race awards for all-finish rounds, updated the Library/tutorial explanations and revised the 2/3/4-player synthetic assertions and design/production records. The immediately preceding AI-use entry describes an intermediate rule that was superseded by this correction. Godot 4.7.2 import, focused scoring, Library, tutorial, result-binding and stack tests passed; [actual results and limits](evidence/p06/2026-10-15_all_finish_barya_correction.md) are recorded. No Barya gameplay implementation, human review, physical-device test, player session or production asset is claimed.

### Barya round objective — October 15, 2026

At the user's explicit direction to implement the approved Barya plan, OpenAI Codex generated and integrated the round-scoped offer policy, separate seeded RNG stream, objective state/controller and coin scene, Pugad/Place integration, actual-physics pickup/drop/recovery, committed-receipt scoring handoff, result/history/HUD cues, Library/tutorial copy and focused regression/performance runners. Codex also updated the tracker, design/provenance records and evidence. The technical run used Godot 4.7.2, synthetic seat/input events, real Godot Area2D/PhysicsServer overlaps, rendered captures, Windows export and exported startup smoke. Test logs, screenshots, measured limits, procedures and boundaries are in [Barya engineering evidence](evidence/barya/README.md); the user-approved scope/contract is in [the dated activation record](evidence/barya/activation_contract_2026-10-15.md). The request/plan and tool outputs are retained in this task transcript; no separate prompt archive was created.

AI-generated and edited code, scenes, tests, documentation and placeholder copy are not represented as manually team-written. No human code review, named Barya owner, QA reviewer, human play session, physical-device test, final art/audio generation, independent approval or organizer approval is claimed. the users remain the development leads under the standing workflow; task-specific owner/capacity assignment and human review remain open. The coin and egg preview are code geometry marked DEBUG and are recorded in [ASSETS.md](ASSETS.md) for human replacement; they are not production assets. Programming assistance does not grant art/audio approval or change the full release manifest. Record the actual tool/area/extent in Form 03 preparation.

### Map scenes and Lobby map selection — October 16, 2026

At the user's request, Claude (Claude Opus 5.5 via Claude Code) generated:
- `StageMap` (map scene root: DevMarkers → spawn/build/flag, Blocks → merged collision rectangles, validation and editor warnings) and `MapCatalog` (folder scan of `scenes/maps/`).
- `ArenaLayout.map_scene` and the room's map visual hook.
- The Lobby map row (scene label, `bind_map`, room polling, GameFlow `selected_map_id`, `--map=`).
- With a one-off generator script (not kept): the map marker tile image and TileSet, the Blocks TileSet (the team's Blocks Sprite Sheet plus the debug tiles) and the Sample Map scene.
- `run_maps_tests.gd` (23 checks) and `capture_maps_evidence.gd`.

The marker tiles are dev-only editing aids, never shown to players. No final art was generated. AI-generated code; no human code review claimed. Evidence: `docs/evidence/maps/README.md`.

### Tutorial map and map-loading fixes — October 16, 2026

At the user's request, Claude (Claude Opus 5.5 via Claude Code):
- Converted the tutorial stage into a map scene (`scenes/maps/tutorial.tscn`, written by a one-off generator, not kept). It was checked field-for-field against the verified layout before that `.tres` was removed.
- Added the optional `StageMap` Precise settings, the `no_wall_slide` TileSet custom data and `arena.goal` naming.
- Made cells and markers outside the stage decoration, so the team's framed Basic Map loads. Its Map Name and order were also set in the scene, because it still carried the Sample Map's.
- Let the Lobby map row work during the tutorial (picking another map skips it) and rescan the maps folder on each Lobby.
- Pointed the tutorial gate and tutorial tests at the map, and extended `run_maps_tests.gd` to 27 checks.

AI-generated code; no human code review claimed.

### Four keyboard layouts, clickable map row, Place block preview, Library Back — October 16, 2026

At the user's request, Claude (Claude Opus 5.5 via Claude Code):
- Added the K3 (IJKL) and K4 (numpad) keyboard layouts and moved K1 confirm from F to E (router, seat registry, prompt glyphs, device labels, key-chord recorder chords C25–C31).
- Added the Lobby map row's clickable ◀ ▶ buttons, the Place ghost block preview with a facing-arrow badge, and the Library Back button.
- Updated tests mechanically: F to E key presses, the Library keyboard names, and P05 one-use eggs.
- Added `run_controls_tests.gd` (13 checks) and `capture_controls_evidence.gd`.

AI-generated code; no human code review or physical keyboard rollover test claimed. Evidence: `docs/evidence/controls/README.md`.

### Bug-fix round: long Cannon, broken blocks, pause, placement overlaps, explosives — October 16, 2026

At the user's request (bug report: match showed only the map, pause/leave broken, bombs and recent blocks, remove first come, first served), Claude (Claude Opus 5.5 via Claude Code):
- Found the cause of the map-only match: the Cannon scene's path ran past the stage, which made the item catalog invalid. Added the path clamp, the lane clip to the build region (`ItemGeometry.clip_to_stage`) and skipping of invalid block scenes (`BlockCatalog.skipped`).
- Fixed the pause panel listing empty seats as lost controllers.
- Removed first come, first served (seat-order resolution, "Tile occupied" / "Invalid spot" notices) and let explosives blow up same-phase placements.
- Added `run_fix_regression_tests.gd` (9 checks), rewrote `run_place_claim_tests.gd` and updated the explosives, Barya, P05, Library, match UI and blocks tests to the new rules.

AI-generated code; no human code review claimed. Evidence: `docs/evidence/fixes/README.md`.

### Ledge climb and E / F confirm — October 16, 2026

At the user's request, Claude (Claude Opus 5.5 via Claude Code) generated the `ChickenController` ledge climb with its tuning keys, made F confirm for K1 alongside E, and wrote `run_ledge_climb_tests.gd` (21 checks). AI-generated code; no human code review or feel review claimed. Evidence: `docs/evidence/fixes/README.md`.

### Item event and stack integration — October 16, 2026

At the user's request ("continue on phase tasks") and with the user's two design decisions (filter event eggs only; add the six P10 families to the match pool), Claude (Claude Opus 5.5 via Claude Code):
- Generated the Pugad mode filter (`PugadEggPoolGenerator.allows_modes`, `EventSchedule.mode_ids`, `pugad_mode_ids` on the match rooms) and set the six P10 scenes to `in_main_game` with low provisional weights.
- Wrote `run_item_mode_integration_tests.gd` (83 checks).
- Updated stale test expectations that encoded the old dev-only P10 policy or older mode flags (P04, P07, P10, P13 Library, Barya).

AI-generated code; no human code review, playtest or balance review claimed. Evidence: `docs/evidence/integration/README.md`.

### Stabilization fixes and submission drafts — October 16, 2026

At the user's request ("continue on phase task"), Claude (Claude Opus 5.5 via Claude Code):
- Fixed the P07 reset audit's stale expectations: one finisher per round, and a physics step after the teleport reset.
- Fixed the tutorial Pugad copy priority and the Barya note text (`tutorial_coordinator.gd`, `tutorial_script.tres`).
- Drafted `docs/SYNOPSIS_DRAFT.md` (Template 01 synopsis, trailer shot list, demo outline, capture schedule) and `docs/RELEASE_MANIFEST_DRAFT.md`.

The synopsis is AI-drafted submission copy and must be disclosed as such on Form 03. Human editing, cultural review and approval are pending. No human code review is claimed. Evidence: `docs/evidence/stabilization/README.md`.

### Promoted P19 obstacles and windowed-suite fixes — October 16, 2026

At the user's request ("continue on phasetasks"; he chose "pick 3 low-risk ones"), Claude (Claude Opus 5.5 via Claude Code):
- Generated the Hagdan ng Bahay, Tinik-Tinik Strip and Yelo ng Sorbetero block scenes (DEBUG placeholder polygons and labels, written by a one-off script that was not kept).
- Generated the `slippery` BlockData flag and the ice tuning and controller hook.
- Wrote `run_p19_promoted_tests.gd` (25 checks).
- Made the windowed P04/P05/P10 suites robust to the larger egg pool: free-cell placement and the full variant cycle.

No final art or audio was generated. No human code, art or feel review is claimed. Evidence: `docs/evidence/p19_promoted/README.md`, `docs/evidence/stabilization/2026-10-16_windowed_suites.txt`.

### Sneak hitbox — October 16, 2026

At the user's request ("when sneaking the hitbox will be change to one tile"), Claude (Claude Opus 5.5 via Claude Code) generated `ChickenController.hit_rect()`, routed hazard and placement-clearance checks through it, and wrote `run_sneak_hitbox_tests.gd` (5 checks). AI-generated code; no human code review claimed.

### Reference UI restyle from the Figma screens — October 17, 2026

At the user's request (a Stage A / Stage B "UI enhancement from design reference" prompt with nine PNG exports of the team Figma file and the instruction to keep the existing UI code and enhance it), Claude via Claude Code wrote the Stage A plan with Claude Sonnet 5.5 and, after the user's `approved` and design answers (keep seat shapes/colours; use the supplied fonts with Handlee replacing Lemonade; rivet panel for in-game Leave match, torn paper for Quit; build every piece in scenes so it shows in the 2D editor), implemented it with Claude Opus 5.5. Claude:
- Sampled colours from the PNGs with a throwaway Godot script and generated the restyled Theme (`tilaok_theme.tres`: new StyleBoxes, font assignments and type variations; every earlier type name kept).
- Copied the user-supplied font files and licence texts into `tilaok!/assets/fonts/` unmodified and registered them in ASSETS.md (it did not create or edit a font).
- Generated the scene components `plank_button.tscn`, `vine_divider.tscn` (PLACEHOLDER line/leaf polygons), `score_chip.tscn`, `seat_pill.tscn`, `confirm_dialog_paper.tscn`, `component_sheet.tscn` and restyled `confirm_dialog`, `lobby_slot`, `player_badge`, `prompt_glyph`, `phase_banner`, `score_row`, `score_award_legend`, `award_line`, `score_column` and the Title, Lobby, Play HUD, Place, Round result and Pause screens.
- Generated small script changes: badge `prefix_text` / `tint_darken` / `use_seat_tint` / `bind_preview`, stacked Yes/No navigation in `UiConfirmDialog`, lobby slot copy and open-slot preview, Title quit scrim, award-line colour by Theme type, scene-authored legend, the gallery Components entry.
- Wrote `tests/run_ui_theme_tests.gd` and `tests/capture_ui_reference_evidence.gd` and ran the regressions and captures recorded in [ui-reference evidence](evidence/ui-reference/README.md).

AI-generated code and placeholder visuals; no final art, icon, texture or audio was generated. The reference PNGs and fonts were supplied by the user; their authorship/approval is the team's to record. No human code review, visual design review or physical-controller test is claimed.

### Round result built from the Figma frame — October 17, 2026

At the user's request ("how do i make one of the ui i made in figma here to be in a godot ui", then the link to frame `36:221` "Round Results" of the team Figma file "UI-Tilaok-"), Claude (Claude Opus 5.5 via Claude Code, with the official Figma MCP connector) read the frame's design context (layout, colours, font sizes, screenshot) with one `get_design_context` call and downloaded the frame's SVG assets. The user chose to widen the Awards column so award explanations still fit. Claude then:
- Imported the team's "Deco Line" vine SVG unmodified as `ui.common.vine_divider.svg` and assigned it on the Round result only (it did not draw, edit or generate the art).
- Generated the Theme changes (exact Figma colours and sizes at 1.8x: result title/subtitle/headings/text, chalkboard, legend fonts, chart axis font and lines, `CountdownBar`/`CountdownCaption`/`CountdownSeconds`, `ResultBackdrop`, `ResultTitleBlock`/`ResultTitleBlockStacked`, `ChartBadgeNumber`), the new `countdown_bar.tscn`, the rebuilt `round_result_screen.tscn`, the legend dash, the chart badge font, and the script changes in `ui_round_result_screen.gd` (title case, Next Round header, gallery sample copy, end-reason tuck/stack, legend fit and the explanation fallback when award lines do not fit), `ui_award_line.gd` (`height_for_width`), `ui_countdown_ring.gd` (`seconds_suffix`, BoxContainer base) and `scoreboard_chart.gd` (Theme axis font, 2 px lines).
- Updated the round-heading expectation in `run_match_ui_binding_tests.gd` to "Round 3 Result" and ran the regressions and captures listed in [UI_HANDOFF](UI_HANDOFF.md#round-result-from-the-figma-frame--2026-10-17).

AI-generated code and layout; the Figma design and the vine art are the team's. No human code review, visual design review or physical-device test is claimed.

### Plank button built from the Figma frame — October 17, 2026

At the user's request ("build this button variation in godot" with the link to frame `16:434` "Button Variants" of the team Figma file "UI-Tilaok-", then "strictly follow the gradient on the buttons and make sure the color is right"), Claude (Claude Opus 5.5 via Claude Code, with the official Figma MCP connector) read the frame with two `get_design_context` calls and one read-only `use_figma` call that returned the exact fills, gradient strokes (stops and transform) and effects; it downloaded the two rivet ellipse SVGs to a scratch folder only to read their colours (they were not imported). Claude then:
- Generated the Theme changes in `tilaok_theme.tres`: exact fills for the four plank states at 1.8x, the outline gradients (`PlankStroke`, `PlankStrokePressed`, `PlankStrokeDisabled`) with the Figma stops and direction, the ring and clip shapes (`PlankStrokeMask`, `PlankClip`), the pressed inner frame and shadow gradients computed from the Figma inner shadow (`PlankPressedFrame`, `PlankPressedShadeTop/Left/Right`), `RivetDisabled` and white disabled text.
- Generated `scripts/ui/ui_plank_button.gd` and the `Stroke` and `PressedLook` nodes and rivet size/position in `plank_button.tscn`.
- Added the exact-value, gradient and state checks to `tests/run_ui_theme_tests.gd`, compared rendered outline pixels with the Figma gradient formula in a scratch script, rendered a side-by-side with the Figma screenshot and ran the regressions listed in [UI_HANDOFF](UI_HANDOFF.md#plank-button-from-the-figma-frame--2026-10-17).

AI-generated code and Theme values; the Figma design is the team's. No human code review, visual design review or physical-device test is claimed.

### Pause screen built from the Figma frames — October 17, 2026

At the user's request ("make this pause frame. make sure that all the details are still the same and functioning. the colors, fonts should be the same" with the link to frame `5:44`, then "keep the ui pills according to the color of the player in our game rn but follow the figma as a reference with all the details in it", adding frame `5:81` for "texture, effects and such"), Claude (Claude Opus 5.5 via Claude Code, with the official Figma MCP connector) read the frames with one `get_design_context`, two read-only `use_figma` dumps (exact paints, gradients, effects, text styles, the frame's differences) and two `download_assets` exports (`5:81` and the paper layer `5:67` at 2.7x). Claude then:
- Imported the frame's icon images, the Iconoir leave icon (with its MIT licence fetched from upstream) and the vine SVG unchanged; recovered transparency on the white-backed paper export; and measured the pills' glass effect into a white highlight overlay with a scratch Godot script. It did not draw or design art.
- Generated the Theme changes (paper margins, backing colour and grain noise from the Figma noise values, title FontVariation, script, pill and warning text types, pill styles without borders, button shadow), the restyled `seat_pill.tscn` (standalone: glass overlay, centred symbol and name, state word on the right), outline nodes in `player_badge.tscn`, the rebuilt `pause_screen.tscn`, `shape_matches_panel` in `ui_score_row.gd`, and the `ui_pause_screen.gd` changes (frame copy, reason line only when informative, countdown in line 2's slot, the lost seat's pill becoming the reclaim pill).
- Added the Pause checks to `tests/run_ui_theme_tests.gd`, changed the owner-label expectation in `run_match_ui_tests.gd` to "paused by", compared 1080p renders with the Figma renders pixel by pixel (backing, shadow, text rows) and ran the regressions listed in [UI_HANDOFF](UI_HANDOFF.md#pause-screen-from-the-figma-frames--2026-10-17).

AI-generated code and Theme values; the Figma design and art are the team's (icon image provenance still open). No human code review, visual design review or physical-device test is claimed.

### Round result effects pass — October 17, 2026

At the user's request (the link to frame `36:221` "Round Results", after asking that Figma frames be followed exactly, including gradients, textures and effects), Claude (Claude Opus 5.5 via Claude Code, with the official Figma MCP connector) made one read-only `use_figma` dump of the frame's exact paints, effects and text styles and one `download_assets` call (a 2.7x render and the SVGs). Claude then:
- Generated the Theme changes: the `ResultTitle` outline (calibrated by measuring both renders), the white square chalkboard frame, the `ChalkGrain` type, and the countdown fill StyleBoxTexture. It placed the team's "Time remaining bar" vector unchanged except for cropping to the fill path.
- Generated the chalkboard grain overlay in `round_result_screen.tscn`, the symbol outline overrides in `score_column.tscn`, and removed the placeholder tag from the scene and from `ui_round_result_screen.gd`.
- Added the frame checks to `tests/run_ui_theme_tests.gd`, compared 1080p renders with the Figma render, and ran the regressions listed in [UI_HANDOFF](UI_HANDOFF.md#effects-pass--2026-10-17).

AI-generated code and Theme values; the Figma design and vector are the team's. No human code review, visual design review or physical-device test is claimed.

### Place screen built from the Figma frame — October 17, 2026

At the user's request (the link to frame `18:8` "Obstacle Place": "this is the obstacle place ui can you put it urself"), Claude (Claude Opus 5.5 via Claude Code, with the official Figma MCP connector) made one read-only `use_figma` dump of the frame's paints, effects and text styles and one `download_assets` call (a 2.7x render and the SVGs). Claude then:
- Generated the Theme changes: the HUD rail, chips, Guide card, status tabs and Place timer types.
- Generated the scene changes: `place_timer.tscn`, the rebuilt `ghost_legend.tscn` and `place_overlay.tscn`, the restyled `score_chip.tscn`, and the HUD layout in `play_hud.tscn`. It placed the team's "Time remaining bar" vector unchanged except for cropping.
- Generated the script changes: in `match_screen_presenter.gd`, "Placing" / "Placed" chip states and the three-line Guide hint; in `ui_place_overlay.gd`, the Guide title.
- Updated `run_match_ui_tests.gd` (the chips read Placing, the hidden rows stay bound, "15 secs"), added the Place checks to `run_ui_theme_tests.gd`, compared 1080p renders with the Figma render, and ran the regressions listed in [UI_HANDOFF](UI_HANDOFF.md#place-from-the-figma-frame--2026-10-17).

AI-generated code and Theme values; the Figma design and vector are the team's. No human code review, visual design review or physical-device test is claimed.

### Pugad pick screen built from the Figma frame — October 17, 2026

At the user's request (the link to frame `2:5`: "pick obstacle screen. make it the exact same as the frame"), Claude (Claude Opus 5.5 via Claude Code, with the official Figma MCP connector) made one read-only `use_figma` dump and two `download_assets` calls (the frame at 2.7x, and the nest layer). It asked the user two design questions; the user chose to follow the GDD (no item name or description on eggs) and to keep players + 2 eggs with two extra card spots. Claude then:
- Imported the egg vector unchanged. It rebuilt the nest asset from the team's original image by matching the frame's crop, because the layer export came back on white.
- Generated the Theme types, the scenes (`pugad_overlay.tscn`, the rebuilt `egg_slot.tscn`, `pill_badge.tscn`, `pugad_countdown.tscn`) and the scripts:
  - `ui_egg_slot.gd`: pick pill.
  - `ui_pugad_overlay.gd`: card spots, Pugad HUD, count and hint.
  - `item_egg_preview.gd`: the `draw_shell` switch.
  - `match_screen_presenter.gd`: Pugad HUD binding, the Play HUD hidden in Pugad, `_glyphs`.
- Updated `run_match_ui_tests.gd` and the `run_ui_tests.gd` contract, added the Pugad checks to `run_ui_theme_tests.gd`, compared 1080p renders with the Figma render, and ran the regressions listed in [UI_HANDOFF](UI_HANDOFF.md#pugad-pick-screen-from-the-figma-frame--2026-10-17).

AI-generated code and Theme values; the Figma design, egg vector and nest image are the team's (nest image provenance open). No human code review, visual design review or physical-device test is claimed.

### Tutorial coach card built from the Figma frame — October 17, 2026

At the user's request (the link to frame `91:2` "Tutorial": "make the ui of the tutorial like this"), Claude (Claude Opus 5.5 via Claude Code, with the official Figma MCP connector) made one `get_design_context` call. It asked the user one design question; the user chose to keep the coach box's current footprint and scale the frame by 1.125 (body text stays 18 px) instead of the ×1.8 used for the full-screen frames. Claude then:
- Generated the Theme types `TutorialCard`, `TutorialCardTitle`, `TutorialCardCaption` and `TutorialCardBody` (colours and fonts from the frame).
- Rebuilt `tutorial_prompt.tscn` as the "Guide:" card: a header holding the title and step line, then the body and the skip caption. The `%Unique` nodes are kept; the chip glyphs and the placeholder tag are hidden.
- Changed `ui_tutorial_prompt.gd`: the Results position and reserved strip for the 263 px card, and gallery samples that match the live card. Widened the coach box in `match_hud.tscn`.
- Measured text rows and line breaks of a 1080p Godot render against the Figma render with scratch scripts, and ran the regressions listed in [UI_HANDOFF](UI_HANDOFF.md#tutorial-coach-card-from-the-figma-frame--2026-10-17).
- Follow-up ("the step 1 tutorial, put it on the top left of the screen because its blocking the other elements on the ui"): rendered trial widths over the Lobby, then generated the Welcome-step position (`lobby_offset_top` 24, new `lobby_width` 400) in `ui_tutorial_prompt.gd`. Also updated the card checks in `run_ui_theme_tests.gd` to the owner's own scene edit (title removed) and the new position. Kept the owner's scene edits as made.

AI-generated code and Theme values; the Figma design is the team's. No human code review, visual design review or physical-device test is claimed.

### Final results screen built from the Figma frame — October 17, 2026

At the user's request (the link to frame `100:77` "Winner Results": "make an exact copy of this for the winner ui"), Claude (Claude Opus 5.5 via Claude Code, with the official Figma MCP connector) made one `get_design_context` call and one read-only `use_figma` dump of the frame's paints, effects and text styles. A `download_assets` render was refused by the plan's call limit. Claude then:
- Downloaded the frame's vine vector unchanged and imported it as `ui.match_result.vine.svg`.
- Rebuilt `match_result_screen.tscn` from the frame, reusing the Round result's Theme types, chalkboard grain and chart, and the Pause plank buttons. Changed `ui_match_result_screen.gd`: the winner line text, no placeholder tag, gallery sample copy.
- Updated the winner check in `run_match_ui_mode_tests.gd` and added the frame checks to `run_ui_theme_tests.gd`. Measured 1080p renders against the frame's screenshot with scratch scripts, and ran the regressions listed in [UI_HANDOFF](UI_HANDOFF.md#final-results-winner-screen-from-the-figma-frame--2026-10-17).
- Follow-up ("can you interchange the color of the buttons normal and hovered"; the user chose "everywhere"): Claude swapped the fills of `sb_plank` and `sb_plank_hover` in the Theme, updated `PLANK_FIGMA` in `run_ui_theme_tests.gd`, and recorded the decision in [UI_HANDOFF](UI_HANDOFF.md#plank-button-from-the-figma-frame--2026-10-17).

AI-generated code and scene values; the Figma design and vine vector are the team's. No human code review, visual design review or physical-device test is claimed.

### Menu action buttons built from the Figma frame — October 18, 2026

At the user's request (the link to frame `103:562` "Menu actions" of the team Figma file "UI-Tilaok-": "make the buttons variations like this"; asked how the selection should move, the user chose "Brown = selected"), Claude (Claude Opus 5.5 via Claude Code, with the official Figma MCP connector) made one `get_design_context` call, checked its flat colours against the screenshot's pixels and downloaded the frame's SVGs. It identified the play icon as Lucide "play" and downloaded Lucide's upstream LICENSE. Claude then:
- Copied the pointer and play SVGs unchanged into `assets/ui/common/` with the licence file.
- Generated the `MenuAction*` Theme types in `tilaok_theme.tres` from the frame's values (edge, face, inset edge, fastening dots, solid drop shadows, label styles, icon gap).
- Generated `scripts/ui/ui_menu_action_button.gd` and `scenes/ui/components/menu_action_button.tscn`; changed `ui_menu_list.gd` so items with `set_selected` set their own look; switched the Title menu in `title_screen.tscn` to the new buttons ("Play" label, play icon, 16 px gap) and added both looks to `component_sheet.tscn`.
- Added the checks to `tests/run_ui_theme_tests.gd`, measured 1x and 1080p renders against the Figma screenshot with scratch scripts, and ran the regressions listed in [UI_HANDOFF](UI_HANDOFF.md#menu-action-buttons-from-the-figma-frame--2026-10-18).

AI-generated code and Theme values; the Figma design and pointer vector are the team's; the play icon is Lucide's (ISC). The hover, pressed and disabled looks are Claude's derivations, not from the frame. No human code review, visual design review or physical-device test is claimed.

### Unintended upward wall movement regression — October 19, 2026

At the user's request, Codex reproduced the reported wall ascent in the current main checkout using Godot 4.7.2 real physics and synthetic K1 input. The failure was in ledge target selection: a vertical top ray accepted an eligible top from a different collider than the wall contact, so the climb moved the body 63.945 wu above the ordinary jump apex in the regression fixture. Codex changed the controller to require the top collider to match the active wall contact, validate the up-and-over path, and sweep each climb step against collision; the 0.22 s climb now finishes its rise before moving sideways. Codex added the failing-before/passing-after integration regression, a rendered after-fix capture script, and updated movement documentation and evidence. AI-generated code and tests; no human code review, physical-device run, or human feel review is claimed. See [fix evidence](evidence/fixes/2026-10-19_wall_upward_slide_fix.txt).

### Ledge-climb feature removal — October 19, 2026

At the user's request, Codex removed the ledge-climb implementation, tuning fields and validation, and ledge-specific runtime/capture scripts. Codex added a no-upward-wall-pull regression for both wall sides and updated current gameplay documentation; earlier records are retained and labeled historical. AI-generated code and test; no human review or physical-device run is claimed. See [removal verification](PLAYTEST.md#wall-climb-removal--october-19-2026).

### NLB-P00 baseline and protocol contract — October 19, 2026

At the user's request, Codex inspected the approved PC-host/Android/live-placement track and generated the dated offline baseline, versioned protocol/measurement contract, traceability review, and related specification/tracker/index updates. The contract is documentation for future separately gated implementation; no transport, RPC, Android client, placement validator, export profile, or runtime networking was generated. The request and work record are in this task transcript; the evidence is indexed under [NLB-P00](evidence/nlb/p00/).

Codex reran the existing P05, P12 schedule, P12 terminal-order/pair, and Barya suites with the user's Godot 4.7.2 executable. They reported respectively 137, 61, 285, and 72 checks with zero failures. The P12 schedule suite intentionally emits an error log for its negative test that refuses a schedule lacking Lagsanay; the runner completed with zero failures. These are offline tests using existing synthetic fixtures/physics, not network, Android, physical-device, battery, thermal, or latency evidence. Codex performed an engineering self-review; no independent human or producer review is claimed. No final art/audio or other production asset was created.

### NLB-P05 offline live-build route — October 19, 2026

At the user's request, Codex implemented a separate opt-in offline live-build route derived from the existing scheduled P12 match room, leaving the scheduled route as default/fallback. Codex added route selection and title/profile indication, GO phase and gating, Pugad assignment transition, bounded placement request/receipt/result records and pipeline, live item commit/grace support, independent build controls and off-screen target markers, a focused test suite and rendered synthetic capture harness. Codex updated the NLB specification/tracker, GDD, PRD, README, control defaults, project map, playtest record, evidence index, and this AI usage record. All new gameplay visuals are debug/code-drawn; no production asset was generated.

Godot 4.7.2 import/parse, gdlint, gdformat check, git diff check, 17 focused/regression suites, and ten synthetic 1920×1080 route captures are recorded under [NLB-P05 evidence](evidence/nlb/p05/README.md). Acceptance remains incomplete: 2/3/4-seat live routes, assignment timeout/failure, ten full reset/replay cycles, comparative performance, and several live moving-hazard/support/Barya cases were not completed. Synthetic results are not human/device evidence. Codex reviewed its generated changes; no independent human code review, physical gamepad session, or human playtest is claimed.

### NLB-P02 PC host lobby — October 20, 2026

At the user's request, Codex implemented the opt-in PC spectator lobby, raw ENet control transport, IPv4 UDP discovery, canonical compatibility manifest, initially expiring one-use invitation proof, host-approved assignment/readiness, and teardown using the existing four-seat registry. It also added the P00 wire minor 1 clarification, the host/client lobby UI, and focused plus multi-process tests. The licensed Kenyoni Software QR code utility v1.2.0 was integrated; the synthetic QR was decoded independently. Codex updated the separate NLB tracker/specification, project/run documentation, asset provenance and evidence. No AI-generated production art/audio was added.

At the user's follow-up request, Codex changed the invitation to remain active and reusable for the room's lifetime, removed the expiry countdown and refresh action, updated the v1.1 contract and tests, and retained host approval, compatibility checks and seat capacity for every join.

The later P03 production requirement temporarily superseded that invitation rule with one-use/300-second credentials. At the user's follow-up request on October 20, 2026, Codex restored a single shared code that remains reusable until room stop/rehost, removed expiry/rotation UI, retained fresh per-connection proof plus compatibility and host approval, and clarified the 13-character Lobby ID error. Godot P02 admission tests pass 74 checks, P03 focused tests pass 61 checks, and ten separate-process rehost cycles pass. After screenshots exposed a valid E-prefixed Lobby ID rejection, Codex fixed both QR and manual lookup bounds to accept first characters A–H and added the example plus A/H/I/digit-7 boundary tests. The exported debug APK was rebuilt as `0.3.2-debug`; physical Android use remains unverified because no device is connected. The contract history and current rule are recorded in [the v1.1 contract](evidence/nlb/p00/protocol-measurement-contract-v1.1.md).

Godot 4.7.2 import/parse, 52 focused P02 checks, ten separate-process host/client rehost cycles, gdlint and gdformat passed. The UI suite retains two known P01 score-row type assertions; the LAN screen-specific audit passes. Real Wi-Fi/no-internet behavior and abusive-flood thresholds were not exercised. Codex performed the engineering implementation and verification; no independent human review, Android device, human playtest or network gameplay claim is made. See [NLB-P02 evidence](evidence/nlb/p02/README.md).

### Title screen built from the Figma frame — October 20, 2026

At the user's request (the link to frame `103:553` "Parchment main menu" of the team Figma file "UI-Tilaok-": "make this for the main menu"), Claude Code built the frame as the title screen in two sessions on the same day.
- An earlier session could not read the frame (its Figma call was refused by the Starter plan limit) and worked from the user's 2x PNG export instead. It generated the parchment card in `scenes/ui/screens/title_screen.tscn` (backing page, paper, grain, dashed border, corner dots, title, subtitle, menu, build label, join prompt; LAN Lobby moved off the card), the `TitleCard*` Theme types in `tilaok_theme.tres` and `_test_title_card` in `tests/run_ui_theme_tests.gd`, and left the emblem and ornament as empty art slots. That session's transcript is not part of this record; its work is known from the uncommitted files it left in the `main-menu-parchment` worktree.
- A later session (Claude Opus 5.5 via Claude Code, with the official Figma MCP connector) made one `get_design_context` call (a second, read-only paint dump was refused by the plan limit) and copied the frame's emblem and ornament SVGs unchanged into `assets/ui/title/`. It filled the two art slots, set the title, subtitle, ornament, footer and backing positions from the frame's values (they had been measured by eye), and replaced the card's stylebox shadows with `Shadow` panels whose linear fade approximates Figma's blur. The backing's shadow values come from the design context; the paper's (about 0 10 18, 17 %) are fitted to the PNG export, because the design context leaves them out. It also added the pointer's share of the selected button's drop shadow to `menu_action_button.tscn`, updated `_test_title_card`, and compared 2x and 1080p renders against the PNG export with scratch scripts.

AI-generated code, Theme values and layout. The Figma design and its two vectors are from the team file; their origin is still to confirm (see [ASSETS](ASSETS.md#title-screen-main-menu-from-the-figma-frame--2026-10-20)). The subtitle "Pugad. Place. Play." is placeholder copy chosen by Claude, and putting the build label in the frame's footer line was Claude's choice. No human code review, visual design review or physical-device test is claimed.
