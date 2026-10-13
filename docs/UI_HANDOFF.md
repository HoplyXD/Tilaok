# Tilaok! UI Handoff Spec — for UI design (Shanti)

**Written 2026-10-13.** Status: handoff draft for human UI design. It collects what the existing project documents and the current code already fix, marks what is only a proposal, and lists the decisions still open. It does not replace [UI_TUTORIAL.md](UI_TUTORIAL.md), [GDD.md](GDD.md) or [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md); when they disagree with this file, they win and this file is wrong.

**Tags used below:** **LOCKED** = recorded in a project contract. **CURRENT** = what the code does today (may be a placeholder). **PROPOSAL** = my suggestion, needs a human decision. **OPEN** = nobody has decided.

## 1. What is being asked

Design the player-facing UI for a 2–4 player local party platformer: screens, HUD, icons, prompts, typography and the visual language for item tells. Everything on screen today is a developer test fixture drawn in code and labeled DEBUG. None of it is a visual reference.

- **Human-made only.** Art, icons, fonts and audio for UI must be team-made, Godot-included or properly licensed. No AI generation of production assets. No Ultimate Chicken Horse art, UI, names or layouts. See [ASSETS.md](ASSETS.md).
- **Register everything.** Every shipped asset, including fonts, goes into the ASSETS.md register with source, licence and AI-assistance fields.
- **Wholesome.** No gambling imagery, no torturous material; deaths are soft and comedic.
- **Cultural review.** Filipino/Hiligaynon spellings, meanings and any educational copy need native-speaker review before shipping. Names like Tilaok, Pugad, Lagsanay, Karera, Tapos, Bayani, Patibong, Bawi, Barya, Tulay na Kawayan and Kaing are working names.

## 2. Hard schedule facts

| Date | Fact |
|---|---|
| Oct 21, 2026 | Feature freeze (see [ROADMAP.md](ROADMAP.md)) |
| Oct 22–23 | Stabilization |
| Oct 24 | Final media/package review |
| Oct 25 | Submission deadline |
| Nov 26–27 | Finals, General Santos City |

UI that cannot be integrated before the freeze should be scoped by priority (section 9).

## 3. Technical frame

| Item | Value | Tag |
|---|---|---|
| Logical canvas | 1280 × 720, `canvas_items` stretch, letterboxed to this aspect (no extra world on wider windows) | CURRENT |
| Reference output | 1920 × 1080 (a 1.5× scale of the logical canvas) | CURRENT |
| Top HUD reservation | 64 logical px at the top of the canvas; the stage is framed in the remaining 1280 × 656 | CURRENT |
| World scale | 1 grid cell = 32 world units; at 1080p and minimum zoom 1.0 a cell is 48 px and a chicken body is 36 × 72 px | CURRENT |
| Camera zoom | 1.0 (minimum, widest) to 1.4; HUD text and markers are screen-space, not zoomed | CURRENT |
| Arena | 32 × 16 cells (1024 × 512 world units), fixed visible bounds | CURRENT |
| Renderer | Godot 4.7.2, Compatibility renderer, 2D | CURRENT |
| Performance budget | 60 FPS / 16.67 ms at 1080p, ≤ 512 MiB; keep UI cheap (atlases, no per-frame allocation) | LOCKED |
| Title/action-safe margin | Suggest 5 % inset (64 × 36 logical px) | PROPOSAL |
| Minimum body text size | Suggest ≥ 16 logical px for anything read mid-round; ≥ 12 only for non-critical labels | PROPOSAL |
| Font | Engine default today. Final typeface, language mix and licence | OPEN |
| 2D art style | Not chosen | OPEN |

**Readability rule (LOCKED):** every cue must remain legible at minimum camera zoom, with the stage crowded by persistent items.

## 4. Player identity (LOCKED except colour values)

Each seat has a fixed number and shape from join until return to lobby. **Colour is supplementary and never the only identifier.**

| Seat | Number | Shape | Current placeholder colour |
|---|---|---|---|
| 1 | 1 | Circle | `#f2c14e` |
| 2 | 2 | Triangle | `#63a7ff` |
| 3 | 3 | Square | `#f07c6c` |
| 4 | 4 | Diamond | `#89c77b` |

- The number and shape marker floats above the chicken and appears on the pointer, ghost, score entries and results (CURRENT: a drawn marker plus a text badge).
- When chickens overlap at spawn, badges fan out with leader lines (CURRENT; see the P03 camera notes in [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md)).
- Final colours, chicken skins and accessories are art-owned (Jorge/Ivie for characters; Shanti decides how UI uses them).

## 5. Inputs and prompt glyphs (PROTOTYPE — untested, from PROTOTYPE_DEFAULTS §3)

Prompts must show the correct glyph for the device that seat uses. Gamepad labels are **positions**, not brand symbols: South, East, West, Start/Options.

| Action | Gamepad | Keyboard K1 | Keyboard K2 |
|---|---|---|---|
| Join / ready toggle (lobby) | South | F | Enter |
| Leave lobby / back | East | G | Backspace |
| Menu / Pugad / Place navigate | D-pad or left stick | W A S D | Arrow keys |
| Run left / right | D-pad or left stick X | A / D | Left / Right |
| Jump | South | Space | Right Ctrl |
| Claim egg (Pugad) | South | F | Enter |
| Move placement pointer | D-pad or left stick | W A S D | Arrow keys |
| Rotate clockwise | West | R | Right Shift |
| Confirm placement | South | F | Enter |
| Results: ready | South | F | Enter |
| Pause / request resume | Start / Options | Escape (shared) | Escape (shared) |
| Spectator cheer | West | R | Right Shift |

**Wall slide / wall jump (CURRENT, enabled by default):** while airborne against a solid side, hold toward the wall to slide at a capped speed; a fresh jump press kicks away. Holding jump does not repeat; you must separate from the wall before kicking it again. This needs a short Library/tutorial cue and no HUD element ([UI_TUTORIAL.md](UI_TUTORIAL.md) future-extension note).

Placement movement is cell steps (first press = one cell; repeat after 0.25 s at 8 cells/s). Rotation is a fresh press only; an unsupported orientation must show a **disabled cue**, not silence.

Prompts should name the **action**, not only the button (for example "Rotate" with the glyph).

## 6. Screen inventory

Flow (LOCKED, from UI_TUTORIAL): Title → Lobby → Tutorial (first Karera) → Pugad → Place → Play → Round result → next round … → Match result → Lobby. Library is reachable from Title, Lobby and Pause.

| # | Screen | What it must show | Primary actions | Code status today | Tracker |
|---|---|---|---|---|---|
| 1 | **Title** | Game title, Start local match, Library, Settings, Quit; a clear build/version label while in development | Start, Library, Settings, Quit | Not built (foundation harness only) | P13-T01/T02 |
| 2 | **Local join lobby** | 2–4 join slots with device prompt; chicken colour plus number/shape; ready state; "need at least 2 players" | Join, choose identifier, ready, leave | Not built (join buttons in test rooms) | P05-T11 (minimal), P13 |
| 3 | **Tutorial (guided first Karera)** | One instruction at a time: identify your chicken, move/jump to markers, claim an egg, place/rotate/confirm, reach the flag, read the results | Skippable once completed in the session | Not built | P13-T07/T08 |
| 4 | **Pugad** | Visible eggs, each showing its exact item and size by a short looping animation with **no name or description**; selection countdown; next-round event announcement; claim ownership change; lost-claim cue | Move, claim | Placeholder egg row exists (Item Lab) | P05-T01/T02 |
| 5 | **Place** | Shared stage; each player's pointer with identity marker; valid/invalid ghost (colour **and** outline/icon/texture); footprint, rotation, size; sweep/lane/effect where relevant; rejection reason text; countdown; protected-zone feedback | Move, rotate, confirm | Debug ghost exists (Item Lab) | P05-T05/T06 |
| 6 | **Play HUD** | Round number and Main Challenge; **TWIST** label when stacked; score totals; timer only when used; player state (alive / secured / eliminated / current taya); Kangaroo **KANG → GA → ROO** failures; Barya carrier marker; next event | Run, jump (wall slide/kick) | Developer text lines only | P13-T03/T04 |
| 7 | **Round result** | Finishes/eliminations; awards in plain language (Tapos, Una, Bayani, Patibong, Bawi, Barya); match total; clear winner or the reason no points were awarded | Continue (all ready or 8 s) | Not built | P05-T11, P06, P13 |
| 8 | **Match result** | Winner, final scores, **Last Cluck!** callout where applicable | Replay, return to lobby (all ready) | Not built | P09, P13 |
| 9 | **Pause / reconnect** | Pause owner; resume needs every connected player ready, then a 3 s countdown; a missing-device screen to reclaim a slot (choose seat number, explicit confirm) | Resume, settings, Library, leave (with confirmation) | Debug pause only | P02 (logic), P13 |
| 10 | **Settings** | Screen shake: full / reduced / off; volume (master, music, effects, crowd if scope permits); controls help; accessibility info | Adjust, back | Not built | P13-T01/T02 |
| 11 | **Library** | Sections: How to Play, Karera, Lagsanay, Kangaroo, Items, Accessibility. Items entry: name, looping animation, sizes, placement preview, tell, counterplay, controls, permitted modes. Shows only enabled release content by default | Choose category, inspect entry, back | Placeholder panel (Item Lab) | P13-T05/T06 |
| 12 | **Event overlays** | Lagsanay: taya marker, countdown, opening-freeze countdown, pass-back immunity, placement order. Kangaroo: slipper-pose icon, text, audio, timing ring, Rising-wave target line, Hug pair marker, Slipper Storm two-command display | — | Not built | P08, P11, P13 |

## 7. Components and visual language to design

### 7.1 Round and match information
- **Scoring cards:** Tapos 1.0, Una +0.25, Bayani +0.5, Patibong +0.25 per kill, Bawi +0.75, Barya +0.5. Lagsanay uses placement 1.0 / 0.5 / 0.25 / 0. Totals can need eighth-point precision on tie displays ([GDD.md §5](GDD.md)).
- Win condition: first to 10 points, or highest after round 12. Every 4th round is an event, announced a round ahead.
- **No-score explanations:** "everyone finished" and "nobody finished" must say why no points were awarded (waived in 2-player).
- **Secured** marker: finisher in stacked modes. **Taya** marker: body marker, countdown, immunity feedback.

### 7.2 Items (current seeds)
| Item | Variants enabled now | Placement ghost must show | Tell (LOCKED text) |
|---|---|---|---|
| Kaing / Hollow Blocks | 1×1, 2×3 (rotates to 3×2) | Full solid footprint, rotation | Strong, distinct crate silhouette |
| Tulay na Kawayan | 4×1 horizontal | Footprint, the thin one-way top strip as a separate element, and a **one-way arrow** | Narrow bamboo silhouette plus arrow |

The Kaing 1×3 column, Tulay 3×1 / 5×1 and the vertical Tulay are defined but not enabled; design them so they drop in later. The first batch of eight families (Kaing, Tulay, Gulong Talon, Trumpo sa Riles, Parol Pulse, Bula-Bulaklak, Tsinelas Launcher, Walis Cleanup) is described in [ITEMS.md](ITEMS.md). Danger must read by **silhouette, motion, icon/text and sound**, never colour alone, and must not use rapid flashing (Parol Pulse uses a brightness ramp).

### 7.3 Placement ghost states
Design a distinct, non-colour-dependent look for: valid; invalid with reason; protected zone; rotation unavailable (disabled cue); confirmed; same-phase new piece. CURRENT debug look: green solid outline + "OK" mark versus red dashed outline + hatch + "X" mark + reason text. Replace, do not copy.

### 7.4 Egg preview
A looping animation of the exact item and size inside an egg. **No name, no description.** Ownership change is visible at once; a lost claim gives a clear non-colour cue and lets the player pick again. CURRENT placeholder: a 76×96 px egg with a ~2 s loop and a highlighted selected state.

### 7.5 Reading aids to mock up
Phase banner (Pugad / Place / Play), countdown ring, announce banner for next-round event, rejection toast, "Last Cluck!" callout, spectator cheer feedback (no gameplay effect, 1 s cooldown).

## 8. Accessibility checklist (LOCKED)

- Colour is never the sole identifier for chickens, valid/invalid, taya, Barya or hazards; add shape, icon, texture, text or motion.
- Screen shake has full, reduced and off settings; commands stay legible without shake, colour or audio alone.
- No rapid flashing; no fine colour distinctions needed to react correctly.
- HUD text, target lines and danger regions legible at minimum zoom; verify at 1080p minimum zoom with four players.
- Gamepad-first design; shared-keyboard (K1/K2) fallback documented; four-player keyboard-only is not promised.
- Independent volume controls if scope permits.

## 9. Suggested priority (PROPOSAL)

1. **Must for a playable submission:** Lobby, Pugad + Place feedback, Play HUD, Round result, Match result, Pause/reconnect, minimal Title.
2. **Strongly needed for screening:** guided Tutorial (the competition requires onboarding; see [COMPETITION.md](COMPETITION.md)).
3. **Should:** Library, Settings (shake/volume), Lagsanay and Kangaroo overlays, wall-movement cue.
4. **Later polish:** animated transitions, crowd/audience presentation, extra skins.

## 10. Delivery format and integration (PROPOSAL)

| Topic | Proposal |
|---|---|
| Asset IDs | `ui.<screen>.<element>` (for example `ui.lobby.slot_ready`), matching the ASSETS.md register |
| File types | PNG for raster, SVG for vector icons, WAV/OGG for audio; keep atlases per screen |
| Repo location | `tilaok!/assets/ui/<screen>/` (new folder; the repo has no `assets/` yet) |
| Layout hand-off | A layout sheet per screen at 1280 × 720 with safe-area guides, plus states (default, focused, disabled, error) |
| Wiring | Developers build Godot scenes that read these assets; designers do not need to write code |
| Nothing ships unregistered | Each asset gets a row in ASSETS.md before it enters a build |

## 11. Open decisions (need a human answer)

1. Final 2D art direction and typeface (and its licence).
2. Language mix and tone of on-screen copy; who reviews Filipino/Hiligaynon text.
3. Lobby navigation details and keyboard-sharing constraints.
4. Settings list and audio-control granularity.
5. Exact safe-area dimensions and the minimum supported resolution.
6. Whether the Library is shown in the release build as designed, or trimmed to How to Play only.
7. Who integrates Shanti's assets (Francis or Carlos) and the review cadence.

## 12. What development provides next (PROPOSAL, pending approval)

- Screen **shells** for Title, Lobby, Pause/Reconnect, Settings, Round and Match result and the HUD, wired to the existing input and phase code with placeholder art, so final assets drop in without code changes.
- A per-screen **state list** and sample data for score cards and results so layouts can be tested with real content.
- A **test harness button** for each screen so Shanti can review a build without playing a full match.

## 13. Source documents

[UI_TUTORIAL.md](UI_TUTORIAL.md) · [GDD.md](GDD.md) · [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md) · [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md) · [ITEMS.md](ITEMS.md) · [ASSETS.md](ASSETS.md) · [PRODUCTION.md](PRODUCTION.md) · [COMPETITION.md](COMPETITION.md) · [PHASETASK.md](PHASETASK.md) (P05-T11, P13)
