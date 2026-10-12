# AGENTS.md — Tilaok!

Context for Codex sessions in this repo.

## What this is
**Tilaok!** is a 2–4 player local-multiplayer party platformer built in **Godot 4** for the **DOST Level Up 3.0 Esports Game Dev Challenge**.
- **Submission deadline: Oct 25, 2026.** Finals: Nov 26–27, 2026, General Santos City.
- Theme: **Philippine Games and Sports.**

## Read first
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
- **All game logic/mechanics/code must be written by the team.** No tutorial, template, or open-source code for core mechanics.
- **AI use is allowed but must be disclosed** (Form 03), and organizers may request git history or prompts. Keep commits honest and descriptive; note AI-assisted work.
- Assets must be team-made, Godot-included, or properly licensed. Track any third-party asset with its license.
- Must run on PC with no paid license.
- Content must be wholesome: no "torturous" material, no gambling imagery; deaths are soft and comedic. Colors must be accessible (second identifier besides color).
- A tutorial/onboarding is required for screening. Form 03 asks for AI tool, area and extent of use.

## Working conventions
- Local multiplayer only (no networking) for the deadline.
- Polish over quantity: base loop + Lagsanay first, then more events.
- Update `docs/GDD.md` when design decisions change.

## Open items
Team roles (later), exact 2D art style, final trap list (later), Pugad egg count tuning.
