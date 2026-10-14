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
| World scale | 1 grid cell = **64 world units** since 2026-10-14 (the 32 wu figures in older evidence are history). Measured at 1080p: widest framing (camera zoom 0.512) a cell is 49.2 px and a chicken body (56 × 120 wu) is 43.0 × 92.2 px; tightest framing (the camera eases toward the 0.700 cap and measured 0.68–0.69; at the cap a cell is 67.2 px and the body 58.8 × 126.0 px) ([frame_measurements.txt](evidence/match-ui/frame_measurements.txt)) | CURRENT |
| Camera zoom | 0.5 (minimum, widest) to 0.7. Screen-space UI (HUD, overlays, status rows) is drawn on a canvas layer, so it never scales with the camera and never tracks world positions; only world-space text (the `ItemGhost` label, the identity badge) shrinks with zoom | CURRENT |
| Arena | 32 × 16 cells (2048 × 1024 world units), fixed visible bounds (2304 × 1280 with the camera margin) | CURRENT |
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

**Wall slide / wall jump (CURRENT, enabled by default):** while airborne and touching a qualifying solid side, a chicken slides at a capped fall speed; holding toward the wall is not required. A fresh jump press kicks away once per contact. Holding jump does not repeat; the chicken must separate from the wall before kicking it again. This needs a short Library/tutorial cue and no HUD element ([UI_TUTORIAL.md](UI_TUTORIAL.md) future-extension note).

Placement movement is cell steps (first press = one cell; repeat after 0.25 s at 8 cells/s). Rotation is a fresh press only; an unsupported orientation must show a **disabled cue**, not silence.

Prompts should name the **action**, not only the button (for example "Rotate" with the glyph).

## 6. Screen inventory

Flow (LOCKED, from UI_TUTORIAL): Title → Lobby → Tutorial (first Karera) → Pugad → Place → Play → Round result → next round … → Match result → Lobby. Library is reachable from Title, Lobby and Pause.

| # | Screen | What it must show | Primary actions | Code status today | Tracker |
|---|---|---|---|---|---|
| 1 | **Title** | Game title, Start local match, Library, Settings, Quit; a clear build/version label while in development | Start, Library, Settings, Quit | **LIVE (2026-10-14):** `scenes/flow/game_flow.tscn` is the main scene. Title binds the real join prompt (press the ready key to join), a build label with the profile (never a seed) and routes Start / Library / Settings / Quit-with-confirmation. Library and Settings are the existing shells (in-memory only) | P13-T01/T02 |
| 2 | **Local join lobby** | 2–4 join slots with device prompt; chicken colour plus number/shape; ready state; "need at least 2 players" | Join, choose identifier, ready, leave | **LIVE:** `UiLobbyScreen.bind_live(registry, map)` shows the real four seats (device, number/shape, ready, device lost); all joined seats ready starts the match (no mouse click); Back returns to the Title | P05-T11 (minimal), P13 |
| 3 | **Tutorial (guided first Karera)** | One instruction at a time: identify your chicken, move/jump to markers, claim an egg, place/rotate/confirm, reach the flag, read the results | Skippable once completed in the session | Shell built: `tutorial_prompt.tscn` prompt box only; tutorial script not implemented (P13-T07). Pugad / Place / Play carry control hints in the phase banner and a Play-start hint toast instead | P13-T07/T08 |
| 4 | **Pugad** | Visible eggs, each showing its exact item and size by a short looping animation with **no name or description**; selection countdown; next-round event announcement; claim ownership change; lost-claim cue | Move, claim | **LIVE:** `bind_live_eggs/bind_live_state` show the real eggs, the owner badge on a claimed egg, every seat's number + shape on the egg it is pointing at, a text lost-claim cue and the tuned 8 s countdown. The next-round event announcement is hidden until P08/P11/P12 | P05-T01/T02 |
| 5 | **Place** | Shared stage; each player's pointer with identity marker; valid/invalid ghost (colour **and** outline/icon/texture); footprint, rotation, size; sweep/lane/effect where relevant; rejection reason text; countdown; protected-zone feedback | Move, rotate, confirm | **LIVE:** `bind_live` shows a status row per seat (exact variant + valid / blocked / locked), the live rejection reason, the tuned 15 s countdown and a "N of M locked" line. Ghost drawing stays in `ItemGhost` (its 12 px world label is a secondary cue) | P05-T05/T06 |
| 6 | **Play HUD** | Round number and Main Challenge; **TWIST** label when stacked; score totals; timer only when used; player state (alive / secured / eliminated / current taya); Kangaroo **KANG → GA → ROO** failures; Barya carrier marker; next event | Run, jump (wall slide/kick) | **LIVE:** `bind_live` shows the round, Karera, the race timer and a FINISH WINDOW tag, exact eighth-point totals (`ScoreFormat`), per-seat RUN / SECURED / OUT and a Play-start notice (hint or Place rejections). TWIST / next event / Kangaroo / Barya are hidden until their phases. The P08 Lagsanay lab and P09 sudden death use the same HUD through the room's presentation hooks: the challenge reads Lagsanay / Sudden death • Lagsanay, the clock is the head-start or taya countdown, the tag names the taya and the seat state reads TAYA (or WATCHING for a non-tied seat) | P08, P13-T03/T04 |
| 7 | **Round result** | Finishes/eliminations; awards in plain language (Tapos, Una, Bayani, Patibong, Bawi, Barya); match total; clear winner or the reason no points were awarded | Continue (all ready or 8 s) | **LIVE:** `bind_live(model, ...)` shows the P06 view model exactly: end reason, deadline text, per-seat outcome + round delta + total, up to ten award rows with plain-language names (explanations when six or fewer), the scoring / no-score reason every round and the 8 s advance with per-seat READY. The P08 lab binds its explained placement / Patibong / Bawi awards (`MatchResultsViewModel.lag_sanay`) through the same screen | P05-T11, P06, P08, P13 |
| 8 | **Match result** | Winner, final scores, **Last Cluck!** callout where applicable | Replay, Return to Lobby, Quit (all original participants freshly ready) | **LIVE on the P09 lifecycle route:** the presenter shows the authored `MatchResultScreen` and the shared `ConfirmDialog` from `match_hud.tscn`; the room binds `bind_final_match(model)` (winner, every participant's exact eighth-point score through `ScoreFormat`, outcome and Last Cluck explanation) and keeps the Replay / Lobby / Quit and leave rules. The default playtest route is the P07 first playable (no match end); reach this screen with `-- --match-route=lifecycle`. Gallery SAMPLE data stays separate | P09, P13 |
| 9 | **Pause / reconnect** | Pause owner; resume needs every connected player ready, then a 3 s countdown; a missing-device screen to reclaim a slot (choose seat number, explicit confirm) | Resume, settings, Library, leave (with confirmation) | **LIVE:** `bind_coordinator()` plus the presenter: owner badge, plain-language reason, roster ready / waiting / device lost, 3 s resume countdown, reclaim panel (single missing seat preselected, Left / Right picks another), Settings / Library / Leave-with-confirmation. Only the owner drives the menu | P02 (logic), P13 |
| 10 | **Settings** | Screen shake: full / reduced / off; volume (master, music, effects, crowd if scope permits); controls help; accessibility info | Adjust, back | Shell built: `settings_screen.tscn`, `bind_live(settings)` edits `PresentationSettings` in memory (nothing is saved or applied yet) | P13-T01/T02 |
| 11 | **Library** | Sections: How to Play, Karera, Lagsanay, Kangaroo, Items, Accessibility. Items entry: name, looping animation, sizes, placement preview, tell, counterplay, controls, permitted modes. Shows only enabled release content by default | Choose category, inspect entry, back | Shell built: `library_screen.tscn`; `bind_live(...)` shows the real enabled item definitions; the Items category is live from `ItemLibraryEntry`, other categories are SAMPLE text (P13-T05/T06) | P13-T05/T06 |
| 12 | **Event overlays** | Lagsanay: taya marker, countdown, opening-freeze countdown, pass-back immunity, placement order. Kangaroo: slipper-pose icon, text, audio, timing ring, Rising-wave target line, Hug pair marker, Slipper Storm two-command display | — | Taya cues are live in the P08 lab and P09 sudden death through the Play HUD (countdown, TAYA tag and state, pass-back immunity notice) and a world-space taya marker (`scenes/match/taya_world_marker.tscn`, authored). `events_overlay.tscn` stays a component placeholder and Kangaroo is unimplemented | P08, P11, P13 |

## 7. Components and visual language to design

### 7.1 Round and match information
- **Scoring cards:** Tapos 1.0, Una +0.25, Bayani +0.5, Patibong +0.25 per kill, Bawi +0.75, Barya +0.5. Lagsanay uses placement 1.0 / 0.5 / 0.25 / 0. Totals can need eighth-point precision on tie displays ([GDD.md §5](GDD.md)).
- Win condition: first to 10 points, or highest after round 12. Every 4th round is an event, announced a round ahead.
- **No-score explanations:** "everyone finished" and "nobody finished" must say why no points were awarded (waived in 2-player).
- **Secured** marker: finisher in stacked modes. **Taya** marker: body marker, player number/shape/name, countdown, head-start state and recent-player pass-back immunity feedback. P08 development implementation is verified in [P08 evidence](evidence/p08/README.md); final art/readability review remains open.

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

## 12. What development built (2026-10-14)

Screen shells are real Godot scenes, not code. Status (2026-10-14): **placeholder look, no final art, but the match loop is live.** The player flow (`scenes/flow/game_flow.tscn`, the project main scene) drives Title → Lobby → Pugad → Place → Play → Round result → next round and Pause / Reconnect from real P05/P06 data through these scenes; the code-built match panels (`match_results_panel.gd`, the old HUD / egg row) are deleted. SAMPLE data remains only in the UI Gallery and the non-Items Library text. The P08 Lagsanay lab and the P09 lifecycle room use the same screens: they override small presentation hooks on the room (`play_clock_seconds`, `play_challenge_text`, `play_tag_text`, `play_status_text`, `seat_state_text`, `shows_final_results`) and the presenter formats what they return.

- **Scenes:** `tilaok!/scenes/ui/screens/` (Title, Lobby, Tutorial prompt, Pugad, Place, Play HUD, Round result, Match result, Pause/Reconnect, Settings, Library, Event overlays) and `tilaok!/scenes/ui/components/` (player badge, prompt glyph, phase banner, countdown, score row, award line, toast, egg slot, ghost legend, confirm dialog, option row, lobby slot, taya marker, Kangaroo prompt).
- **One Theme:** `tilaok!/assets/ui/theme/tilaok_theme.tres`.
- **UI Gallery:** the foundation harness has **UI Gallery** (every screen and state with SAMPLE data, a K1/K2/gamepad glyph switch, a 1-4 player switch, a theme swap and Return; F9 hides the review panel) and **Player flow (Title)**, which now hosts the **live** flow (Quit returns to the harness). The old SAMPLE-only player flow is the gallery with its panel hidden.
- **Live-bound nodes (do not rename):** Title `BuildLabel`, `PressToJoinPrompt`, `MenuList`; Lobby `Slot1…4`, `NeedPlayersLabel`, `StartHint`, `BackHint`; Pugad `Egg1…6` (owner and `Selector1…4` badges inside each slot), `Countdown`, `PhaseBanner`, `LostClaimToast`; Place `SeatStatus1…4`, `ReasonToast`, `GhostStatus`, `Countdown`, `PhaseBanner`; Play HUD `RoundLabel`, `ChallengeLabel`, `TimerLabel`, `NextEventLabel`, `ScoreRow1…4`, `NoticeToast`; Round result `RoundLabel`, `EndReasonLabel`, `DeadlineLabel`, `Outcome1…4`, `Award1…10`, `NoScoreReason`, `ReadyHint`, `AdvanceCountdown`; Pause `OwnerBadge`, `OwnerLabel`, `ReasonLabel`, `Roster1…4`, `CountdownLabel`, `ReclaimPanel`, `ReclaimLabel`, `MenuList`, `LeaveConfirm`; Match result `WinnerBadge`, `WinnerLabel`, `OutcomeLabel`, `LastCluckCallout`, `Final1…4`, `MenuList`. New nodes added for live data (additive, no renames): `SeatStatus1…4`, `NoticeToast`, `EndReasonLabel`, `DeadlineLabel`, `Award7…10`, `Selector1…4`, the debug overlay's `ExtraButton`, and the `MatchResultScreen` / `ConfirmOverlay` instances in `scenes/match/match_hud.tscn`.
- **DEBUG overlay:** `scenes/ui/screens/debug_overlay.tscn` holds the developer text (build id, profile, seed, run, phase, timer, seats, last message) and fixture buttons (Join K1/K2, Start match, Pause, Return, Developer harness, plus an optional room action such as the Lagsanay lab's Restart attempt). It is off in the player flow, on by default in rooms opened from the harness, and F3 toggles it in debug builds (or with `-- --debug-overlay`). It also shows the diagnostic support test line in the world.
- **Input model:** in Pugad, Place, Play and Results the screens are display-only; game input stays with `P05MatchRoom`. Only menu screens (Lobby back, Title, Pause, Settings / Library from Pause) are driven through `UiInputBridge`, and only the pause owner drives the pause menu.
- **Tests:** `tilaok!/tests/run_ui_tests.gd`, captures `tilaok!/tests/capture_ui_evidence.gd`, evidence in `docs/evidence/ui-shells/`.

### How to edit the UI in Godot (for Shanti)

1. **Open the project** in Godot 4.7.2 (`Godot_v4.7.2-stable_win64.exe --path tilaok! --editor`). In the FileSystem dock open `scenes/ui/ui_gallery.tscn` and press **F6** to see every screen. Use the left panel (hide it with F9) to change screen, state, device glyphs and player count.
2. **Restyle:** open `assets/ui/theme/tilaok_theme.tres` and use the Theme editor. Colours, borders, fonts, font sizes and the safe-area margin all live there. Change what a type looks like; never rename the type variations (`TilaokMenuButton`, `MenuButtonSelected`, `RowPanel`, `RowPanelSelected`, `GhostValid`, `GhostInvalid`, `GhostProtected`, `GhostRotationOff`, `GhostConfirmed`, `HudBar`, `Backdrop`, `Scrim`, `SafeAreaMargin`...). To change the font, set the Theme's **Default Font**.
3. **Move things:** open any scene in `scenes/ui/screens/` and edit it like normal UI (containers, anchors, sizes). Press **F6** to run just that scene with sample data where the screen supports it.
4. **Drop art:** put PNG/SVG files in `assets/ui/<screen>/` named `ui.<screen>.<element>.<ext>`. In a scene, select the node named `Art_<Element>` and set its **Texture** in the inspector. Empty art slots show the Theme placeholder. Seat shapes: each badge has `Art_Circle`, `Art_Triangle`, `Art_Square`, `Art_Diamond`; assigning one replaces the placeholder shape.
5. **Register the asset** in `docs/ASSETS.md` (source, licence, AI-assistance field) before it enters a build.

**Do not rename or delete** nodes marked *Unique Name* (the `%Name` badge in the Scene tree): scripts find them by that name. The test `tilaok!/tests/run_ui_tests.gd` lists them per screen. Do not add Godot focus to menu buttons (`Focus Mode` must stay *None*): menus are driven by the input router, and focus would make Enter fire twice.

Questions: Francis or Carlos.

**Pending human decisions (placeholders until then):** safe-area inset (5 %, 64x36 px) and minimum text size (16 px mid-round, 12 px labels) are Theme constants under `TilaokPolicy`/`SafeAreaMargin`; typeface, art style and Filipino/Hiligaynon copy review are open.

## 13. Source documents

[UI_TUTORIAL.md](UI_TUTORIAL.md) · [GDD.md](GDD.md) · [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md) · [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md) · [ITEMS.md](ITEMS.md) · [ASSETS.md](ASSETS.md) · [PRODUCTION.md](PRODUCTION.md) · [COMPETITION.md](COMPETITION.md) · [PHASETASK.md](PHASETASK.md) (P05-T11, P13)

## 14. P10 item tells and placeholder slots (Jorge/Ivie art, Shanti UI/audio)

Every first-batch item is drawn through one `ItemVisualSet` per family (`tilaok!/data/items/visual/<family_id>.tres`). **Replace a placeholder by saving your file over `tilaok!/assets/items/<family_id>/PLACEHOLDER_<slot>.<ext>`, or set the slot's `frames`/`sound` in the inspector.** No code change is needed; the Item Visualizer's **Reload art** button shows the swap immediately and **Art slots** lists every slot and its owner. A missing slot falls back to a graybox shape.

| Family | Slots | Tell to preserve (shape + motion + sound, never colour alone) |
|---|---|---|
| Gulong Talon | `body`, `body_compressed`, `sfx_launch` | Coil compresses before/at launch; arrow along the launch face; boing |
| Trumpo sa Riles | `rail`, `top`, `sfx_pause` | Visible rail ends; top spins; pause marker and tick at each end |
| Parol Pulse | `post`, `beam_on`, `sfx_charge`, `sfx_on` | Dotted line → thickening line → solid band (no flashing faster than ~1 Hz); rising tone, then a click |
| Tsinelas Launcher | `launcher`, `launcher_charge`, `projectile`, `sfx_charge`, `sfx_fire` | Lane always visible and stops at the first solid; barrel pulls back; charge sound before the shot |
| Walis Cleanup | `broom_outline`, `sfx_sweep` | Every target gets an X, protected areas are hatched; sweep sound on confirm |
| Bula-Bulaklak | `pot`, `bubble`, `captive_icon`, `sfx_emit`, `sfx_capture`, `sfx_pop` | Upward path arrows; capture ring counts down the ~2 s hold |

Slot sizes: textures are stretched into the region (body = footprint, beam = beam segment, lane/projectile = 14 wu). Final art keeps those rectangles; add frames to a slot for a loop (`fps` per slot). Egg, ghost, Library and the live piece all use the same slots. See [ASSETS.md](ASSETS.md) for the register.
