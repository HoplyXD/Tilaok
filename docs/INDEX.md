# Tilaok! Documentation Index

**Separate track:** the offline opt-in live-build slice and P02 PC LAN lobby are implemented for engineering evaluation; scheduled P12 remains the default and fallback. P02 passes 3/3. P03 Android client work is partial: T01's debug APK and local QR scanner plugin packaging pass, while retained Android runtime/join and physical-device evidence remain incomplete. P04 network-match source has bounded runtime evidence (focused suite, separate-process run, physical phone admission) but all P04 tasks stay unchecked. Preparatory P06 live-placement source (opt-in `network_live_build` route, contract v1.3) is authored and unrun, with P06 0/3 checked. Preparatory P07 source (contract v1.4, default-deny live compatibility matrix with a dev-only override, live transients, §6.2 special cases) is authored and unrun, with P07 0/3 checked. None of this clears P03-T03 or enters the October submission scope. Legacy P00–P19 counts remain separate.

Project documentation belongs in this directory. The repository root retains only the public overview and agent guidance:

- `README.md` — project overview and entry point.
- `CLAUDE.md` — Claude Code guidance.
- `AGENTS.md` — Codex and repository guidance.

NLB-P00 evidence is indexed in [`evidence/nlb/p00/`](evidence/nlb/p00/); P01 implementation, regressions, and captures are in [`evidence/nlb/p01/`](evidence/nlb/p01/); P02 PC host/lobby evidence is in [`evidence/nlb/p02/`](evidence/nlb/p02/); partial P03 Android export/client evidence and blockers are in [`evidence/nlb/p03/`](evidence/nlb/p03/); P04 source, its bounded runtime results and remaining verification are indexed in [`evidence/nlb/p04/`](evidence/nlb/p04/); P05 offline live-build code, synthetic regression results, and route captures are in [`evidence/nlb/p05/`](evidence/nlb/p05/); P06 preparatory live-placement source, deferred commands and the physical session sheet are in [`evidence/nlb/p06/`](evidence/nlb/p06/). P03 retained physical-device evidence, P04 acceptance, P05 broad safety/content acceptance and all P06 verification remain open. The P07 compatibility matrix, preparatory source, deferred commands and physical session sheet are in [`evidence/nlb/p07/`](evidence/nlb/p07/); all P07 verification remains open. Network gameplay acceptance and networked live-placement readiness are not implied.

## Current source documents

| Document | Purpose | Status |
|---|---|---|
| [PROMPT_RULES.md](PROMPT_RULES.md) | Standing prompt-writing workflow, context checks, phase checkboxes, delivery and safe Desktop synchronization. | Read before every implementation/phase prompt |
| [PRD.md](PRD.md) | Consolidated product requirements, release/optional scope and acceptance, traceable to the GDD and specialized contracts. | P09 match-end/sudden-death and P11 standalone command requirements have development-route engineering evidence; Barya is implemented on the default P12 route with human/device/art review open; P07/P08 release gates and P09/P11 performance and human acceptance remain open |
| [NETWORKED_LIVE_BUILD.md](NETWORKED_LIVE_BUILD.md) | Approved target architecture, multiplayer/session contract, shared phone view, live placement, migration and verification gates. | P02 passes; P03 Android work and retained physical-device evidence are incomplete; P04 has bounded runtime evidence with acceptance open; P06 and P07 source is preparatory and unrun |
| [PHASETASK_NETWORKED_LIVE_BUILD.md](PHASETASK_NETWORKED_LIVE_BUILD.md) | Separate ordered 12-phase implementation/verification tracker with requirement traceability. | NLB-P00 3/3, P01 3/3, P02 3/3, P03 partial 1/3, P04 0/3, P05-T01 1/3, P06 0/3 (preparatory source), P07 0/3 (preparatory source); 11/36 checked |
| [PHASETASK.md](PHASETASK.md) | Ordered implementation/non-code tasks, dependencies, verification, evidence and milestone status. | P00 0/6; P01 9/10; P02 25/35; P03 7/7; P04 20/22; P05 12/12; P06 8/8; P07 0/4; P08 6/6 technical; P09 4/4 technical; P10 48/54; P11 13/13 technical; P12 10/10 technical; P13 11/18 (T13/T14 scoreboard; T01, T03, T05, T06, T07, T09 technical; T15–T17 reference restyle technical; T02, T04, T08, T10, T11, T12, T18 open); P19 Barya 4/4 technical; 180/421 total. P07/P08 gates, P02 physical-device/human reviews, P09/P11 performance/human acceptance and P10 release enablement remain open (item event/stack integration passed 2026-10-16). |
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | P01–P13 project layout, responsibility map, programming provenance, run and test commands. | Dedicated P05, P07, P08, P09 and P11 development routes; human/device, P05 safety/content, performance and release gates remain open |
| [GDD.md](GDD.md) | Source of truth for the game loop, events, scoring, items, presentation, and approved design decisions. | Active; P04 implementation status per family/variant recorded (nothing release-enabled) |
| [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md) | Coupled controller/input/tuning defaults, focused balance audit, measured P02/P03/P04/P11 results, and remaining team handoff. | Values remain provisional; P11 frame target, physical hardware, player feel and balance review open |
| [ITEMS.md](ITEMS.md) | 36-family item catalog, eight-item first batch, lifecycle contracts, and reference boundaries. | Active |
| [PLAYTEST.md](PLAYTEST.md) | Documentation review, technical verification, gameplay playtests, and performance evidence plan. | P07/P08/P09/P11 synthetic routes and P13 scoreboard captures recorded; human rounds, chart readability, P02 reconnect, P09/P11 performance targets and physical sessions remain open |
| [ROADMAP.md](ROADMAP.md) | Scope priorities, feature gates, and delivery schedule. | Active |
| [COMPETITION.md](COMPETITION.md) | Competition rules, submission requirements, dates, and judging criteria. | Active |
| [AI_USAGE.md](AI_USAGE.md) | Record of AI-assisted work for Form 03 disclosure. | Active |
| [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md) | Stage zones, verified P03 graybox, future placement resolution, persistence, protected areas, and Rising wave elevation rules. | P03 arena/camera/support, P04 Kaing/Tulay support and P05 atomic construction loop verified; production items and event gameplay remain open |
| [UI_TUTORIAL.md](UI_TUTORIAL.md) | Screen flow, HUD, accessibility baseline, Kangaroo prompts, required tutorial sequence and results chart reading notes. | Active; P13 scoreboard chart implemented, novice comprehension and broader UI review open |
| [UI_HANDOFF.md](UI_HANDOFF.md) | Handoff spec for human UI design: technical frame, player identity, input prompts, screen inventory, components, accessibility, priorities, delivery format and open decisions. | Draft updated 2026-10-17 with the reference restyle (fonts supplied, components, deviations); final textures and icons not yet delivered |
| [ASSETS.md](ASSETS.md) | Asset provenance, licence register, cultural review ledger, and AI-disclosure linkage. | Active; five supplied fonts registered 2026-10-17 (approval open); restyle panels, planks and vine are placeholders |
| [PRODUCTION.md](PRODUCTION.md) | Role sheet, feature gates, definition of done, risks, and implementation order after sign-off. | Active |
| [SUBMISSION.md](SUBMISSION.md) | Competition deliverables, Form evidence, synopsis, trailer/demo, and final-review checklists. | Active |
| [SYNOPSIS_DRAFT.md](SYNOPSIS_DRAFT.md) | AI first draft of the Template 01 synopsis, trailer shot list, demo outline and capture schedule (P17-T03). | Draft, unreviewed |
| [RELEASE_MANIFEST_DRAFT.md](RELEASE_MANIFEST_DRAFT.md) | Draft content manifest and known-defect table for the October 21 freeze (P16-T01 input). | Draft, unapproved |

## Documentation work before development

Complete these in this order. They turn the approved GDD into a team-ready pre-production package without writing gameplay code.

The initial pre-production documentation package is complete. Keep these documents current as team owners, assets, platform measurements, and approved public copy become available.

Scoreboard implementation and rendered engineering evidence: [scoreboard evidence index](evidence/scoreboard/README.md). Captures are synthetic fixtures; they do not establish human readability or physical-device acceptance.

Reference UI restyle (2026-10-17) and its side-by-side captures: [ui-reference evidence index](evidence/ui-reference/README.md). Synthetic engineering evidence only; the human design review is P13-T18.

Each new document must identify its source of truth, label proposals separately from approved decisions, disclose actual AI assistance, and avoid claiming implementation or playtesting until systems are actually implemented and verified.

## Authority and execution

GDD controls gameplay; specialized specs elaborate it consistently; PROTOTYPE_DEFAULTS supplies untested starting points; ROADMAP controls release scope/schedule. PRD consolidates what success requires. PHASETASK tracks work and evidence, never design approval as implementation completion. R1–R4 remain inactive proposals. The approved October 13 baseline targets all eight initial families, required title/results/Library/essential cues, and separately tracked Should/expansion/finalist scope.
