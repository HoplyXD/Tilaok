# AGENTS.md — Tilaok!

**Current route (2026-10-24):** normal Play is local/offline: Lobby → Pugad (15 s) → shared BUILD (10 s) → final 3–2–1/GO cue → one standalone Main (Karera, Lagsanay/Bomb-Taya, or Kangaroo) → results → next round. BUILD’s full-screen cue is hidden until the final 3 seconds; its countdown remains in the side HUD. If every player places their item during BUILD, skip the unused wait and begin its final 3-second 3–2–1/GO cue; otherwise keep the shared timer running so players can save items for play. BUILD expiry starts active play immediately. The separate 3-second GET READY countdown is used when resuming from pause. During BUILD the camera follows eligible placement cursors; confirming places that player’s assigned item immediately as an inert piece. A player may save the item for PLAY, when the camera follows chickens and live construction takes two gameplay seconds. Sudden death gives no new placement. Mixed-mode Twists are retired from normal scheduling. Provisional active windows: Karera 120 s hard cap / 30 s after first finisher; Lagsanay taya 20/25/30 s for 2/3/4 alive; Kangaroo race uses the same clock and race scoring, with one slipper at a time, a 2 s telegraph, 6 s base response, 1.5 s recovery, and 3 s / 0.75 s floors. Response shortens 0.5 s and recovery 0.15 s per completed slipper; Freeze lasts 2 s. Rising evaluates the chicken hitbox bottom against the visible final line at response end (1 wu tolerance); Hug accepts any current living contact group, including pairs and chains. Failed Hug/Rising directly eliminates through the race ledger. Storm and KANG/GA/ROO life markers are retired. Rising target choice remains bounded and map-aware, with an alternate-command fallback. Values remain provisional pending human playtesting. Phone/LAN code and Android/QR support are retired; history stays under `docs/archive/retired-networked-live-build/`. See P23 in `docs/PHASETASK.md` for redesign acceptance and evidence status.

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
- Every round: **Pugad → shared BUILD (10 s) → final 3–2–1/GO cue → active play/build → results.** The Pugad is a nest of eggs; picking one assigns an item. Build it in BUILD or save it for live placement; the stage persists and grows. The full-screen cue appears only in BUILD’s final 3 seconds; pause resume keeps its separate 3-second countdown.
- Most rounds race to the flag. Every **4th round**, a **laro ng lahi event** takes over the same stage (announced a round ahead).
- **Lagsanay** (Ilonggo for tag): bomb-taya tag. Touch to pass; when the timer hits zero the taya is eliminated; repeat until one survivor. Trap deaths are eliminations.
- **Scoring** (our own values; see GDD §5): Tapos 1.0, Una +0.25, Bayani +0.5, Patibong +0.25/kill, Bawi +0.75, Barya (coin) +0.5; ordinary Karera awards are suppressed if all or none reach the goal (no two-player waiver); eligible Barya still pays in all-finish rounds, and no finisher means no Barya points. Events map onto Tapos/Una. **Exception: Lagsanay uses placement** (1.0 / 0.5 / 0.25 / 0) plus Patibong and Bawi. First to 10 points, or highest after round 12.

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
- The October deadline build remains local/offline. Networked work is the separately gated approved target described above; it does not enter the freeze or submission obligation.
- Polish over quantity: base loop + Lagsanay first, then more events.
- Update `docs/GDD.md` when design decisions change.

## Open items
Remaining individual role assignments/capacity, exact 2D art style, final trap list (later), Pugad egg count tuning.
