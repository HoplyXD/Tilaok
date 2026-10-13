# AGENTS.md — Tilaok!

Context for Codex sessions in this repo.

## What this is
**Tilaok!** is a 2–4 player local-multiplayer party platformer built in **Godot 4** for the **DOST Level Up 3.0 Esports Game Dev Challenge**.
- **Submission deadline: Oct 25, 2026.** Finals: Nov 26–27, 2026, General Santos City.
- Theme: **Philippine Games and Sports.**

## Read first
- Before creating or revising any implementation/phase prompt, read `docs/PROMPT_RULES.md` in full. It records the user's context-gathering, approval, verification, checklist, Git and Desktop-sync requirements. Prompt requests mean draft in chat, not implement.
- `docs/GDD.md`: full design (source of truth for gameplay and scoring)
- `docs/COMPETITION.md`: contest rules, requirements, judging criteria
- `docs/ROADMAP.md`: scope priorities and schedule

## Design summary
- Inspired by the Ultimate Chicken Horse build-then-run loop. **Never copy UCH code, art, sounds, names, or characters**; only the mechanic is borrowed, with our own twist.
- All characters are chickens (color skins), a wholesome reimagining of sabong.
- Every round: **Pugad → Place → Play.** The Pugad is a nest of eggs; picking one hatches an item. The stage persists and grows.
- Most rounds race to the flag. Every **4th round**, a **laro ng lahi event** takes over the same stage (announced a round ahead).
- **Lagsanay** (Ilonggo for tag): bomb-taya tag. Touch to pass; when the timer hits zero the taya is eliminated; repeat until one survivor. Trap deaths are eliminations.
- **Scoring** (our own values; see GDD §5): Tapos 1.0, Una +0.25, Bayani +0.5, Patibong +0.25/kill, Bawi +0.75, Barya (coin) +0.5; no points if all or none reach the goal (waived in 2-player). Events map onto Tapos/Una. **Exception: Lagsanay uses placement** (1.0 / 0.5 / 0.25 / 0) plus Patibong and Bawi. First to 10 points, or highest after round 12.

## Competition rules that affect code
- The local competition notes record §7 as requiring code/mechanics created by registered team members and §8 as allowing disclosed AI programming. See `docs/COMPETITION.md` for the source note and unresolved interpretation; do not present this summary as organizer approval.
- No tutorial, template, third-party core implementation, or UCH code/art/audio/names/characters. Follow original-work and asset provenance requirements.
- Assets must be team-made, Godot-included, or properly licensed. Track any third-party asset with its license.
- Must run on PC with no paid license.
- Content must be wholesome: no "torturous" material, no gambling imagery; deaths are soft and comedic. Colors must be accessible (second identifier besides color).
- A tutorial/onboarding is required for screening. Form 03 asks for AI tool, area and extent of use.

## Standing AI-assisted programming workflow

AI/LLM-assisted programming, including generation of core gameplay code, is the approved standing development workflow for Tilaok!. Francis and Carlos lead development using these tools. Do not request a new AI-authorship exception for each task or phase. Follow the approved task scope, preserve truthful AI-use disclosure, and require actual verification before marking work complete.

- AI agents may generate and modify programming work within approved tasks, including mechanics, scripts, integration scenes, tools, tests, fixes and refactors. Francis and Carlos direct development and retain integration, review, testing and delivery responsibility. AI-generated code must not be described as manually team-written; record human review only when performed.
- This standing authorization does not expand a task, approve design changes, authorize data deletion, or bypass tests. Follow normal plan approval when a task requests it. Approved programming tasks need no separate AI-use approval.
- Art, audio and other production assets remain human-team responsibilities. This programming policy does not authorize AI generation of final production assets.
- Record actual assistance in `docs/AI_USAGE.md` and Form 03 preparation. Preserve available prompts, outputs and history; never invent missing records or assume generated code is free of provenance/licensing concerns. Do not copy UCH or third-party core implementations.

## Working conventions
- Local multiplayer only (no networking) for the deadline.
- Polish over quantity: base loop + Lagsanay first, then more events.
- Update `docs/GDD.md` when design decisions change.

## Open items
Remaining individual role assignments/capacity, exact 2D art style, final trap list (later), Pugad egg count tuning.
