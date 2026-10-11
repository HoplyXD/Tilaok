# CLAUDE.md — Tilaok!

Context for Claude Code sessions in this repo.

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
- Every round: **Party Box → Place → Play.** The stage persists and grows.
- Most rounds race to the flag. Every few rounds, a **laro ng lahi event** takes over the same stage (next event announced one round ahead).
- **Lagsanay** (Ilonggo for tag): bomb-taya tag. Touch to pass; when the timer hits zero the taya is eliminated; repeat until one survivor.
- **Scoring:** UCH default values (Goal 1, First +0.2, Solo +0.6, Trap +0.2/kill, Comeback +0.8, Coin +0.6; no points if all or none reach the goal). Events map onto Goal/First. **Exception: Lagsanay uses placement** (1.0 / 0.6 / 0.2 / 0) plus Trap and Comeback. Win at 10 points.

## Competition rules that affect code
- **All game logic/mechanics/code must be written by the team.** No tutorial, template, or open-source code for core mechanics.
- **AI use is allowed but must be disclosed** (Form 03), and organizers may request git history or prompts. Keep commits honest and descriptive; note AI-assisted work.
- Assets must be team-made, Godot-included, or properly licensed. Track any third-party asset with its license.
- Must run on PC with no paid license.

## Working conventions
- Local multiplayer only (no networking) for the deadline.
- Polish over quantity: base loop + Lagsanay first, then more events.
- Update `docs/GDD.md` when design decisions change.

## Open items
Team roles, art style (pixel art suggested for speed), event trigger frequency, final trap list, stage-clutter control.
