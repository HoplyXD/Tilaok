# Tilaok! Documentation Index

Project documentation belongs in this directory. The repository root retains only the public overview and agent guidance:

- `README.md` — project overview and entry point.
- `CLAUDE.md` — Claude Code guidance.
- `AGENTS.md` — Codex and repository guidance.

## Current source documents

| Document | Purpose | Status |
|---|---|---|
| [PROMPT_RULES.md](PROMPT_RULES.md) | Standing prompt-writing workflow, context checks, phase checkboxes, delivery and safe Desktop synchronization. | Read before every implementation/phase prompt |
| [PRD.md](PRD.md) | Consolidated product requirements, release/optional scope and acceptance, traceable to the GDD and specialized contracts. | P03 graybox stage/camera/support and P04 item-infrastructure/Kaing/Tulay evidence recorded; hardware coverage and full game remain open |
| [PHASETASK.md](PHASETASK.md) | Ordered implementation/non-code tasks, dependencies, verification, evidence and milestone status. | P00 0/6; P01 9/10; P02 14/22; P03 6/6; P04 14/22 (early exit met); 43/401 total. P02 physical-device checks, P02-T18/T22 wall-movement review and P01-T02 human review remain open. |
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | P01–P04 project layout, responsibility map, programming provenance, run and test commands. | Runnable harness with P02 movement, P03 graybox and P04 Item Lab fixtures; no full match loop |
| [GDD.md](GDD.md) | Source of truth for the game loop, events, scoring, items, presentation, and approved design decisions. | Active; P04 implementation status per family/variant recorded (nothing release-enabled) |
| [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md) | Coupled controller/input/tuning defaults, focused balance audit, measured P02/P03/P04 fixture results, and remaining team handoff. | Values remain provisional; physical hardware, player feel and balance review open |
| [ITEMS.md](ITEMS.md) | 36-family item catalog, eight-item first batch, lifecycle contracts, and reference boundaries. | Active |
| [PLAYTEST.md](PLAYTEST.md) | Documentation review, technical verification, gameplay playtests, and performance evidence plan. | P03 route, camera, support, rendering, and export evidence plus P04 item/physics/lifecycle/performance/export evidence recorded; full-game and physical-device checks remain open |
| [ROADMAP.md](ROADMAP.md) | Scope priorities, feature gates, and delivery schedule. | Active |
| [COMPETITION.md](COMPETITION.md) | Competition rules, submission requirements, dates, and judging criteria. | Active |
| [AI_USAGE.md](AI_USAGE.md) | Record of AI-assisted work for Form 03 disclosure. | Active |
| [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md) | Stage zones, verified P03 graybox, future placement resolution, persistence, protected areas, and Rising wave elevation rules. | P03 arena/camera/support and P04 Kaing/Tulay support results verified; production placement and event gameplay remain open |
| [UI_TUTORIAL.md](UI_TUTORIAL.md) | Screen flow, HUD, accessibility baseline, Kangaroo prompts, and required tutorial sequence. | Active |
| [ASSETS.md](ASSETS.md) | Asset provenance, licence register, cultural review ledger, and AI-disclosure linkage. | Active |
| [PRODUCTION.md](PRODUCTION.md) | Role sheet, feature gates, definition of done, risks, and implementation order after sign-off. | Active |
| [SUBMISSION.md](SUBMISSION.md) | Competition deliverables, Form evidence, synopsis, trailer/demo, and final-review checklists. | Active |

## Documentation work before development

Complete these in this order. They turn the approved GDD into a team-ready pre-production package without writing gameplay code.

The initial pre-production documentation package is complete. Keep these documents current as team owners, assets, platform measurements, and approved public copy become available.

Each new document must identify its source of truth, label proposals separately from approved decisions, disclose actual AI assistance, and avoid claiming implementation or playtesting until systems are actually implemented and verified.

## Authority and execution

GDD controls gameplay; specialized specs elaborate it consistently; PROTOTYPE_DEFAULTS supplies untested starting points; ROADMAP controls release scope/schedule. PRD consolidates what success requires. PHASETASK tracks work and evidence, never design approval as implementation completion. R1–R4 remain inactive proposals. The approved October 13 baseline targets all eight initial families, required title/results/Library/essential cues, and separately tracked Should/expansion/finalist scope.
