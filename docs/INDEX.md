# Tilaok! Documentation Index

**Active route (2026-10-24):** local/offline play is the normal route: Lobby → Pugad → shared 10-second BUILD → final 3–2–1/GO cue → active play/build → results. BUILD’s timer stays in the side HUD and its full-screen cue appears only during its final 3 seconds; expiry starts PLAY immediately. The separate 3-second GET READY countdown is for pause resume. During BUILD the camera follows placement cursors and confirmed items appear instantly, inert until PLAY. During PLAY the camera follows chickens and live construction takes two seconds. The scheduled P12 Place route remains a developer fallback. Phone/LAN, Android and QR work is retired; the original specs, tracker and evidence are preserved under [`archive/retired-networked-live-build/`](archive/retired-networked-live-build/). Retirement does not mark those tasks complete.

Project documentation belongs in this directory. The repository root retains only the public overview and agent guidance:

- `README.md` — project overview and entry point.
- `CLAUDE.md` — Claude Code guidance.
- `AGENTS.md` — Codex and repository guidance.

Historical network specifications and evidence are preserved in the retired archive listed above. Do not use them as active implementation scope or infer completion from their former status.

## Current source documents

| Document | Purpose | Status |
|---|---|---|
| [PROMPT_RULES.md](PROMPT_RULES.md) | Standing prompt-writing workflow, context checks, phase checkboxes, delivery and safe Desktop synchronization. | Read before every implementation/phase prompt |
| [PRD.md](PRD.md) | Consolidated product requirements, release/optional scope and acceptance, traceable to the GDD and specialized contracts. | Normal Play now uses offline live-build; P20 evidence records construction checks and fail-closed content; physical-controller, human, performance and release reviews remain open |
| [PHASETASK.md](PHASETASK.md) | Ordered implementation/non-code tasks, dependencies, verification, evidence and milestone status. | P22 has 1/5 tasks checked; instant preparation placement and camera handoff need runtime/lifecycle verification. See phase evidence. Physical-controller/human checks remain open. |
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | P01–P20 project layout, responsibility map, programming provenance, run and test commands. | Default offline live-build and developer fallback routes; human/device, content, performance and release gates remain open |
| [GDD.md](GDD.md) | Source of truth for the game loop, events, scoring, items, presentation, and approved design decisions. | Active; P04 implementation status per family/variant recorded (nothing release-enabled) |
| [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md) | Coupled controller/input/tuning defaults, focused balance audit, measured P02/P03/P04/P11 results, and remaining team handoff. | Values remain provisional; P11 frame target, physical hardware, player feel and balance review open |
| [ITEMS.md](ITEMS.md) | 36-family item catalog, eight-item first batch, lifecycle contracts, and reference boundaries. | Active |
| [PLAYTEST.md](PLAYTEST.md) | Documentation review, technical verification, gameplay playtests, and performance evidence plan. | Prior P22 checks (123/0 focused suite, P12 59/0, P13 58/0 and 10-cycle reset audit) cover the previous preparation-job behavior; revised instant placement/camera behavior is pending verification. See [P22 evidence](evidence/p22_preparation/README.md) |
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
