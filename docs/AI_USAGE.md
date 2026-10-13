# AI Assistance Record — Tilaok!

_Current policy and cumulative disclosure record. Updated 2026-10-13. This file prepares evidence for DOST Form 03; it is not the signed form._

## Current standing programming policy

AI/LLM-assisted programming, including generation and modification of core gameplay code, is the approved standing development workflow for Tilaok!. Francis (lead developer) and Carlos (co-lead developer) use AI/LLMs as the primary code generators and direct development, retaining responsibility for integration, review, testing and delivery. Human responsibility does not mean source code was manually written by humans. The human team handles art, assets and other production work; this programming authorization does not authorize generating final art, audio or other production assets.

AI coding agents may implement programming work within an approved task: gameplay mechanics, scripts, scenes used for programming or integration, tools, tests, fixes and refactors. Agents do not need a separate AI-use approval for each approved programming task or phase. Follow the requested task scope and design decisions; standing authorization does not authorize scope expansion, unapproved design changes, data deletion or bypassing required tests. Normal plan approval remains in force when a task requests it. Actual technical verification is required before marking work complete. Human review and release responsibility remain, and review is recorded only when performed.

Never describe AI-generated code as manually team-written. Do not copy Ultimate Chicken Horse code, third-party core implementations, tutorial/template mechanics or unlicensed assets. Disclose actual AI assistance, including generated programming work, rather than describing assistance only as review or documentation. Preserve prompts, outputs and history where available; do not invent missing records. AI-generated code is not automatically free of provenance or licensing concerns. Keep code provenance and asset provenance accurate.

This standing internal workflow does not establish organizer approval, registration, human review, competition eligibility or originality acceptance. Competition forms and any eligibility interpretation remain separate submission obligations. See [COMPETITION.md](COMPETITION.md) and [SUBMISSION.md](SUBMISSION.md). The team must select the official Form 03 extent category using total project-wide assistance; this record does not select or sign that category on the team's behalf.

## Cumulative assistance summary

OpenAI Codex has assisted with research, design/specification, project documentation, and programming. It authored the P01 foundation and P02 input/controller/movement diagnostic implementation, focused tests and evidence tooling; it also authored the documentation work listed below and this policy correction. This cumulative summary is intended to prevent older delivery-specific statements from being mistaken for the full project history. No AI-generated final art, audio or other production asset is recorded here.

The P01 foundation includes typed provisional settings/profile snapshots, content validation and seeded diagnostic streams, a local development harness, scenes, focused checks, export setup and evidence. The P02 work includes local seat/device assignment, phase-specific routing, pause/focus/reclaim state, movement/contact/lifecycle code, diagnostic fixtures and focused tests. Consult [PHASETASK.md](PHASETASK.md), [PLAYTEST.md](PLAYTEST.md), and [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for exact implementation status and limitations. AI authorship is disclosed and is not represented as manual human authorship. Actual human review remains unrecorded where it has not occurred.

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

### Standing policy and documentation correction — October 13, 2026

At Francis's direction, this documentation correction replaces the earlier internal “team manually writes core code; AI only reviews/documents” policy and phase-specific AI implementation exceptions with the standing AI-assisted programming workflow at the top of this file. This is a policy/documentation change, not gameplay implementation or proof of human review, organizer approval, registration or eligibility. The current production roles recorded from Francis are Francis — lead developer; Carlos — co-lead developer; both use AI-assisted programming. Human-team art/asset production is recorded without assigning individual creators. No surnames, hours, registration facts or reviewer identities are inferred.

### Verification of the PRD/tracker documentation delivery — October 13, 2026

The earlier documentation delivery recorded structural and content checks for 116 requirements, 20 phases and 393 tasks (207 required, 24 Should, 4 conditional-finalist, 158 expansion), rendered IDs, dependency DAG, traceability, local links/anchors, family destinations, variants, untouched source/reference hashes and whitespace. All game/delivery tasks remained unchecked. Those documentation checks did not constitute gameplay verification. See [PHASETASK documentation verification](PHASETASK.md#documentation-verification--october-13-2026-original-prdtracker-delivery).
