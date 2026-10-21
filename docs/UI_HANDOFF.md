# Tilaok! UI Handoff Spec — for UI design (Shanti)

**Future networked UI direction (approved 2026-10-19):** the current handoff describes offline UI. The separately gated phone client uses a shared landscape arena, independent touch movement and build-aim controls, LAN Lobby ID/QR/manual IP entry, and host/client lifecycle cues. See [NETWORKED_LIVE_BUILD.md](NETWORKED_LIVE_BUILD.md) and its [touch UX tasks](PHASETASK_NETWORKED_LIVE_BUILD.md#nlb-p10--touch-ux-tutorial-accessibility-mixed-device-parity); this direction is not implemented or an October submission obligation.

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
| Font | Since 2026-10-17: Handlee (body), Margarine, Mountains of Christmas Bold, Mansalva and Road Rage, supplied by the team with their licences (see [the reference restyle section](#reference-restyle-from-the-figma-screens--2026-10-17)). Language mix still open | CURRENT (fonts); OPEN (language mix) |
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

| Action | Gamepad | WASD (K1) | IJKL (K3) | Arrows (K2) | Numpad (K4) |
|---|---|---|---|---|---|
| Join / ready toggle (lobby) | South | E or F | O | Enter | Num 0 |
| Leave lobby / back | East | G | U | Backspace | Num . |
| Menu / Pugad / Place navigate | D-pad or left stick | W A S D | I J K L | Arrow keys | Num 8 4 2 6 |
| Run left / right | D-pad or left stick X | A / D | J / L | Left / Right | Num 4 / 6 |
| Jump (hold to glide) | South | W or Space | I | Up or Right Ctrl | Num 8 |
| Claim egg (Pugad) | South | E or F | O | Enter | Num 0 |
| Move placement pointer | D-pad or left stick | W A S D | I J K L | Arrow keys | Num 8 4 2 6 |
| Rotate clockwise | West | R | P | Right Shift | Num 5 |
| Confirm placement | South | E or F | O | Enter | Num 0 |
| Results: ready | South | E or F | O | Enter | Num 0 |
| Pause / request resume | Start / Options | Escape (shared) | Escape (shared) | Escape (shared) | Escape (shared) |
| Spectator cheer | West | R | P | Right Shift | Num 5 |
| Build mode toggle (NLB live build) | North | Q | - | [ | Num + |
| Aim the live ghost (never moves the chicken) | Right stick | Z C V B | 7 4 8 6 | Y H N M | Num 7 1 3 9 |
| Rotate the live piece | Right bumper | T | = | ] | Num * |
| Place the live piece | Right trigger | E or F | O | Enter | Num 0 |
| Cancel the live placement (keeps the item) | Left bumper | X | ' | \ | Num - |

**Four keyboard layouts (2026-10-16, user request):** WASD (E or F confirm, R rotate), IJKL (O confirm, P rotate), arrows (Enter confirm, Right Shift rotate) and numpad 8 4 2 6 (Num 0 confirm, Num 5 rotate). A layout is only a device: seats are numbered in join order, so any layout can be any player. Internally WASD is K1, arrows K2, IJKL K3 and numpad K4. Four players on one keyboard depends on that keyboard's key rollover, which is untested; the key-chord recorder (chords C25–C31) checks it on the real keyboard. The Lobby map row's ◀ ▶ arrows and the Library's Back button also take mouse clicks.

**Wall slide / wall jump (CURRENT, enabled by default):** while airborne and touching a qualifying solid side, a chicken slides at a capped fall speed; holding toward the wall is not required. A fresh jump press kicks away once per contact. Holding jump does not repeat; the chicken must separate from the wall before kicking it again. This needs a short Library/tutorial cue and no HUD element ([UI_TUTORIAL.md](UI_TUTORIAL.md) future-extension note).

Placement movement is cell steps (first press = one cell; repeat after 0.25 s at 8 cells/s). Rotation is a fresh press only; an unsupported orientation must show a **disabled cue**, not silence.

Prompts should name the **action**, not only the button (for example "Rotate" with the glyph).

**NLB-P10 phone touch (PLACEHOLDER, unreviewed, unrun):** the prompt map gains a `touch` device and the build rows above; touch glyphs are text labels (Move zone, Aim zone, Jump, Build, Rotate, Place, Cancel, Menu) that Shanti may replace with art in each glyph's Art_Glyph slot. Touch layout is code-drawn: two drag zones (Move left, Aim right) flank a button block that wraps above the thumbs. The 5 % theme margin inside the OS safe area, the 44 dp touch floor (computed from screen dpi and the stretch scale, minimum 44 viewport px), the 16 px mid-round text floor and the dead zone (14 dp) are PROPOSALS, unmeasured until NLB-P10-T03. Shanti review list: control shapes and spacing, button and zone art, the "You are P#" badge and seat shapes, the placement chip, help-card styling and copy, and colour use (state is always text plus shape or outline, never colour alone, and nothing flashes). See [P10 evidence](evidence/nlb/p10/README.md).

## 6. Screen inventory

Flow (LOCKED, from UI_TUTORIAL): Title → Lobby → Tutorial (first Karera) → Pugad → Place → Play → Round result → next round … → Match result → Lobby. Library is reachable from Title, Lobby and Pause.

| # | Screen | What it must show | Primary actions | Code status today | Tracker |
|---|---|---|---|---|---|

## 7. Components and visual language to design

### 7.1 Round and match information
- **Scoring cards:** Karera uses Tapos 1.0 for each finisher and Una +0.25 for the first, with no second/third-place points. Bayani +0.5, Patibong +0.25 per direct kill, Bawi +0.75 and Barya +0.5 retain their conditions. Lagsanay and Kangaroo use survival placement 1.0 / 0.5 / 0.25 / 0 for four players; fourth place may still earn direct Patibong. Totals can need eighth-point precision on tie displays ([GDD.md §5](GDD.md)).
- Win condition: first to 10 points, or highest after round 12. Every 4th round is an event, announced a round ahead.
- **Suppression explanations:** "everyone finished" must explain that ordinary race awards are zero but Barya still counts; "nobody finished" means zero points for everyone, including in two-player Karera.
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

## 13a. P13 live status and contracts (2026-10-15)

| Piece | Where | Notes |
|---|---|---|
| Default route | `scripts/flow/game_flow.gd` | the scheduled full match; `-- --match-route=first_playable` keeps the P07 gate build; `-- --match-seed=<n>` reproduces a match |
| Lobby help | `HelpHint` in `lobby_screen.tscn` | the Rotate control opens the Library over the Lobby; Back returns |
| Next-round line | `%UpNextLabel` in `play_hud.tscn` | `NextEventLabel` keeps its name and carries the live tag (taya countdown, finish window, command) |
| HUD bar | `HudBar/Row` → `Left` (round, challenge, TWIST) · `ScoreRow1…4` · `Right` (clock, tag, up next) | two lines per side; stays inside 64 px |
| Kangaroo readout | `scenes/ui/components/kangaroo_hud.tscn` (`%Card1/2`, `%Markers`, `%Marker1…4`, `%MoreLabel`) and `kangaroo_command_card.tscn` | below the notice row; copy in `KangarooCommandStyle.player_instruction` |
| Result lines | `%LastCluckCallout` (title row), `%TwistLine` / `%NextRoundLabel` (footer) in `round_result_screen.tscn` | |
| Library | `data/ui/library_text.tres` (`UiLibraryPage` resources: category, title, body with `{tokens}`, `requires`) | edit copy here; numbers come from tuning and score constants; `EntryList` has `Entry1…8` |
| Settings | `%MuteRow` + the volume rows | applied by `PresentationApplier` |
| Cheer | `SpectatorCheer`, `CHEER!` in the score row state | no new nodes |
| Recorder | `scenes/tools/key_chord_recorder.tscn` | `--open-room=key_chord_recorder` or run the scene |

**Do not rename** (new contracts, all `%Unique`): `UpNextLabel`, `HelpHint`, `LastCluckCallout`, `TwistLine`, `NextRoundLabel`, `MuteRow`, `Card1`, `Card2`, `Markers`, `Marker1…4`, `MoreLabel`, and every earlier contract in section 12. No `Control.new()` or `add_theme_*` override was added to a UI script. Copy is PLACEHOLDER everywhere it is listed above.

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

## 15. P11 command cue handoff

The standalone `kangaroo_contract_lab` room currently draws DEBUG pose and wave marks and binds them to command text, a timing ring, and transient generated tones. The on-screen labels remain visible when audio is muted; the room also exposes full/reduced/off shake settings. These checks establish that the indicators render and survive the settings, not that a player understands them. The [ASSETS P11 register](ASSETS.md#p11-debug-only-placeholders-and-human-replacement-handoff) records each temporary implementation and the human replacement/review action. The shared event-overlay shell remains separate and P13 integration is still open. No final production art or recording was created.
| 1 | **Title** | Game title, Start local match, Library, Settings, Quit; a clear build/version label while in development | Start, Library, Settings, Quit | **LIVE (2026-10-14):** `scenes/flow/game_flow.tscn` is the main scene. Title binds the real join prompt (press the ready key to join), a build label with the profile (never a seed) and routes Start / Library / Settings / Quit-with-confirmation. Library and Settings are the existing shells (in-memory only) | P13-T01/T02 |
| 2 | **Local join lobby** | 2–4 join slots with device prompt; chicken colour plus number/shape; ready state; "need at least 2 players" | Join, choose identifier, ready, leave | **LIVE:** `UiLobbyScreen.bind_live(registry, map)` shows the real four seats (device, number/shape, ready, device lost); all joined seats ready starts the match (no mouse click); Back returns to the Title | P05-T11 (minimal), P13 |
| 3 | **Tutorial (guided first Karera)** | One instruction at a time: identify your chicken, move/jump to markers, claim an egg, place/rotate/confirm, reach the flag, read the results | Skippable once completed in the session | Shell built: `tutorial_prompt.tscn` prompt box only; tutorial script not implemented (P13-T07). Pugad / Place / Play carry control hints in the phase banner and a Play-start hint toast instead | P13-T07/T08 |
| 4 | **Pugad** | Visible eggs, each showing its exact item and size by a short looping animation with **no name or description**; selection countdown; next-round event announcement; claim ownership change; lost-claim cue | Move, claim | **LIVE:** `bind_live_eggs/bind_live_state` show the real eggs, the owner badge on a claimed egg, every seat's number + shape on the egg it is pointing at, a text lost-claim cue and the tuned 8 s countdown. The next-round announcement is live on the P12 full-match route (`bind_announcement`, fed by `round_announcement()`): "NEXT • ROUND n: MAIN" with the Twist (or "No Twist") and this round below; other routes keep it hidden | P05-T01/T02 |
| 5 | **Place** | Shared stage; each player's pointer with identity marker; valid/invalid ghost (colour **and** outline/icon/texture); footprint, rotation, size; sweep/lane/effect where relevant; rejection reason text; countdown; protected-zone feedback | Move, rotate, confirm | **LIVE:** `bind_live` shows a status row per seat (exact variant + valid / blocked / locked), the live rejection reason, the tuned 15 s countdown and a "N of M locked" line. Ghost drawing stays in `ItemGhost` (its 12 px world label is a secondary cue) | P05-T05/T06 |
| 6 | **Play HUD** | Round number and Main Challenge; **TWIST** label when stacked; score totals; timer only when used; player state (alive / secured / eliminated / current taya); Kangaroo **KANG → GA → ROO** failures; Barya carrier marker; next event | Run, jump (wall slide/kick) | **LIVE:** `bind_live` shows the round, Karera, the race timer and a FINISH WINDOW tag, exact eighth-point totals (`ScoreFormat`), per-seat RUN / SECURED / OUT and a Play-start notice (hint or Place rejections). TWIST is live; since 2026-10-15 the locked next round shows in `UpNextLabel` ("NEXT R6 KANGAROO + BOMB-TAYA", "FINAL ROUND"), Kangaroo commands and misses are the scene-authored `kangaroo_hud.tscn` (cards + KANG → GA → ROO grid), the score row reads `MISS n/3` / `CHEER!`; Barya is enabled on the scheduled P12 route; its non-color carrier/status cue and +0.5 results/history award are live. The earlier 264-check HUD log predates Barya and is historical. The P08 Lagsanay lab and P09 sudden death use the same HUD through the room's presentation hooks: the challenge reads Lagsanay / Sudden death • Lagsanay, the clock is the head-start or taya countdown, the tag names the taya and the seat state reads TAYA (or WATCHING for a non-tied seat) | P08, P13-T03/T04 |
| 7 | **Round result** | Finishes/eliminations; awards in plain language (Tapos, Una, Bayani, Patibong, Bawi, Barya); match total; clear winner or the reason no points were awarded | Continue (all ready or 8 s) | **LIVE:** `bind_live(model, ...)` shows the P06 view model exactly: end reason, deadline text, per-seat outcome + round delta + total, up to ten award rows with plain-language names (explanations when six or fewer and they fit; see "Round result from the Figma frame"), the scoring / no-score reason every round and the 8 s advance with per-seat READY. The P08 lab binds its explained placement / Patibong / Bawi awards (`MatchResultsViewModel.lag_sanay`) through the same screen | P05-T11, P06, P08, P13 |
| 8 | **Match result** | Winner, final scores, **Last Cluck!** callout where applicable | Replay, Return to Lobby, Quit (all original participants freshly ready) | **LIVE on the P09 lifecycle route:** the presenter shows the authored `MatchResultScreen` and the shared `ConfirmDialog` from `match_hud.tscn`; the room binds `bind_final_match(model)` (winner, every participant's exact eighth-point score through `ScoreFormat`, outcome and Last Cluck explanation) and keeps the Replay / Lobby / Quit and leave rules. The default playtest route is the P07 first playable (no match end); reach this screen with `-- --match-route=lifecycle`. Gallery SAMPLE data stays separate | P09, P13 |
| 9 | **Pause / reconnect** | Pause owner; resume needs every connected player ready, then a 3 s countdown; a missing-device screen to reclaim a slot (choose seat number, explicit confirm) | Resume, settings, Library, leave (with confirmation) | **LIVE:** `bind_coordinator()` plus the presenter: owner badge, plain-language reason, roster ready / waiting / device lost, 3 s resume countdown, reclaim panel (single missing seat preselected, Left / Right picks another), Settings / Library / Leave-with-confirmation. Only the owner drives the menu | P02 (logic), P13 |
| 10 | **Settings** | Screen shake: full / reduced / off; volume (master, music, effects, crowd if scope permits); controls help; accessibility info | Adjust, back | **LIVE (2026-10-15):** `settings_screen.tscn`; `bind_live(settings)` edits `PresentationSettings` in memory and `PresentationApplier` applies it: Sound (Mute) row, Master / Music / Effects / Crowd buses from `default_bus_layout.tres`, Screen shake reaches the match (nothing is saved) | P13-T01/T02 |
| 11 | **Library** | Sections: How to Play, Karera, Lagsanay, Kangaroo, Items, Accessibility. Items entry: name, looping animation, sizes, placement preview, tell, counterplay, controls, permitted modes. Shows only enabled release content by default | Choose category, inspect entry, back | **LIVE (2026-10-15):** `library_screen.tscn`; pages from `data/ui/library_text.tres` (PLACEHOLDER, numbers from tuning), Items from `ItemLibraryEntry`, eight scrolling entry buttons, enabled-content filtering, `--library-dev` reference mode (P13-T05/T06) | P13-T05/T06 |
| 12 | **Event overlays** | Lagsanay: taya marker, countdown, opening-freeze countdown, pass-back immunity, placement order. Kangaroo: slipper-pose icon, text, audio, timing ring, Rising-wave target line, Hug pair marker, Slipper Storm two-command display | — | P08 Lagsanay cues are live in the P08 lab and P09 sudden death through the shared Play HUD and authored world-space taya marker. The standalone P11 room renders labeled DEBUG pose, timing and audio cues in `p11_kangaroo_match_room.gd`; `events_overlay.tscn` stays a component placeholder. Human comprehension and final presentation remain open. See [P11 evidence](evidence/p11/README.md) and [asset replacement handoff](ASSETS.md#p11-debug-only-placeholders-and-human-replacement-handoff) | P08, P11, P13 |

## 16. Live tutorial coach box and BUILD HERE marker (2026-10-14)

| Piece | Where | Notes |
|---|---|---|
| Coach box | `scenes/ui/screens/tutorial_prompt.tscn`, instanced as `%TutorialPrompt` in `scenes/match/match_hud.tscn` | Display-only: never attached to `UiInputBridge`, no router phase, `mouse_filter` ignore, Back does nothing when live. Position is the `Anchor` override on the instance in `match_hud.tscn`. Do not rename `%StepLabel`, `%BodyLabel`, `%PromptGlyph`, `%SkipText`, `%SkipHint`, `%Tag`. |
| Copy | `tilaok!/data/ui/tutorial_script.tres` (`TutorialScript` / `TutorialStepDef`) | PLACEHOLDER English, `{tokens}` filled from `GameplayTuning`, the stage layout and the live seats. Not reviewed; a Filipino / Hiligaynon pass is still needed. |
| Logic | `scripts/tutorial/tutorial_coordinator.gd` | Read-only; one `TutorialSession` on `GameFlow` holds the session set in memory. |
| BUILD HERE marker | `scenes/tutorial/build_here_marker.tscn` (`BuildHereMarker`) | World-space dashed outline + arrow + text label ("BUILD HERE", "TRY A PIECE HERE" on the retry hint); no collision. Label font sizes live in the scene. |
| Pause entry | `%SkipTutorialButton` in `pause_screen.tscn` (after Leave, visible only while the tutorial is active) | Signal `skip_tutorial_requested`. |
| Replay | Library How to Play page, entry 1 ("Replay tutorial") | Signal `replay_tutorial_requested`; clears the session set. |

## Results score chart handoff — 2026-10-15

The reusable `ScoreboardChart` and `ScoreColumn` components are live in the round and final result screens. The reference supplied for this task informed only the generic chart concept: player columns, a shared baseline, guides and score progression. Tilaok's existing dark-teal surfaces and provisional Theme tokens supply the interface styling; no reference palette, artwork, typography, branding or complete screen arrangement was copied.

- `tilaok!/scenes/ui/components/scoreboard_chart.tscn` owns the shared axis, exact target line and responsive column slots. `score_column.tscn` owns the player's number/shape badge, placeholder chicken, exact score, round delta, status and stacked award segments.
- Round results place the chart beside the award breakdown and labelled/glyphed legend, with readiness and the existing eight-second countdown in the footer. Final results place the chart and legend together beneath the winner/outcome callout and keep Replay / Return to Lobby / Quit below.
- Columns stay in stable seat order, including noncontiguous seat indexes. The chicken is a UI-only `AnimatedSprite2D` using the shared [chicken SpriteFrames](../tilaok!/assets/character/chicken_sprite_frames.tres); it has no controller, physics or gameplay signals.
- Score units are integer eighths. The target line uses the configured value (default 80 units / 10 points); one point of headroom is added above the greater of target or highest score. Scores above target expand the axis. Unproven prior totals use the neutral token.
- Award token swatches (`tapos`, `una`, `bayani`, `patibong`, `bawi`, `barya`, `placement`) are named in `tilaok!/assets/ui/theme/tilaok_theme.tres` and remain editable for review. Each chart segment has an award key/glyph, and the legend names every score type. Player number and shape remain visible beside color.
- Result reveal motion is a separate Normal / Reduced / Off setting; Screen shake is unchanged. Resize and repeated readiness binds do not restart the same result, and early advance settles the chart before navigation.

Rendered 1280×720, 1920×800 and 1920×1080 examples and the exact engineering limits are indexed in [scoreboard evidence](evidence/scoreboard/README.md). The placeholder SpriteFrames and Theme values are not final production art; final art and human readability review remain with the team.

## Reference restyle from the Figma screens — 2026-10-17

Source: nine PNG exports of the team Figma file "UI-Tilaok-" (Lobby, Obstacle Place, Round Results, Pause Menu, Pause Menu (With Warning), Leave Match Confirmation, Confirm Exit UI, Panels, Button Variants), supplied by the user in the request. The Figma link itself could not be read (no Figma connector in the session), so layout, colour and spacing come from the PNGs; colours were sampled from the exports and are approximations until exact Figma values are supplied. Some exports show a game screenshot behind the new UI; that background is reference only.

**Owner decisions (2026-10-17):** keep the code's seat shapes and colours (the reference's P3 diamond / P4 square and dark seat colours are **not** adopted) and only restyle the UI; use the supplied fonts with **Handlee in place of Lemonade**; the rivet panel is the in-game **Leave match** confirmation and the torn-paper panel is the **Quit the game** confirmation on the Title.

| Piece | Where | What it is |
|---|---|---|
| Fonts | `tilaok!/assets/fonts/` | Handlee (Theme default, body), Margarine (headings, slot state, chips), Mountains of Christmas Bold (screen titles), Mansalva (handwritten captions), Road Rage (prompt words and key-caps). Licences beside each file; register in [ASSETS](ASSETS.md#reference-restyle-fonts-and-placeholders--2026-10-17). |
| Theme tokens | `tilaok!/assets/ui/theme/tilaok_theme.tres` | Every earlier type keeps its name. New: `BackdropWarm`, `PanelPaper`, `PaperBacking`, `PanelRivet`, `Rivet`, `ScoreChip`, `PillSeat1…4`, `PillWarning`, `KeyCap`, `KeyCapLabel`, `PromptAction`, `ChalkboardPanel`, `ChalkLabel`, `ScreenTitle`, `PaperTitle`, `PaperHeading`, `PaperScript`, `PaperBody`, `DialogMessage`, `DialogScript`, `ResultTitle`, `ResultSubtitle`, `ResultHeading`, `ResultText`, `SlotState`, `SlotDevice`, `LobbyNote`, `BadgeNumberDark`, `ChipLabel`, `ChipState`, `HudTitle`, `HudSub`, `TwistTag`, `GuideTitle`, `GuideBody`, `Legend<Award>`. `TilaokMenuButton` / `MenuButtonSelected` are now the wooden plank (Normal / Hovered = router-selected / Pressed / Disabled). `Legend<Award>` letter colours must equal `ScoreAward/<award>` (a test checks it). `PillSeat1…4` are darkened versions of `PlayerSeatRegistry.COLORS`; change both together. |
| Plank button | `scenes/ui/components/plank_button.tscn` | Button + `RivetLeft` / `RivetRight` nodes. Used by Pause and both confirmations (the Title menu switched to the [menu action button](#menu-action-buttons-from-the-figma-frame--2026-10-18) on 2026-10-18); other menus get the plank look from the Theme without rivets. |
| Vine divider | `scenes/ui/components/vine_divider.tscn` | `Art_Vine` slot (`ui.common.vine_divider`) over a PLACEHOLDER Line2D + leaf polygons under `Placeholder`; hide `Placeholder` once the texture is set. |
| Seat pill / score chip | `seat_pill.tscn`, `score_chip.tscn` (inherited from `score_row.tscn`) | Pause roster pill (seat colour fill, cream shape, "Player N") and Play HUD chip (cream, darkened seat-colour shape, "PN"). The badge's new exports: `prefix_text`, `tint_darken`, `use_seat_tint`, `plain_tint`. |
| Confirmations | `confirm_dialog.tscn` (rivet, Yes / No stacked) and `confirm_dialog_paper.tscn` (inherited: torn-paper skin, "We're sorry to see you go :(" heading and vine) | Same `UiConfirmDialog` script and API. Up / Down move between Yes and No; Left / Right still work. |
| Lobby | `lobby_screen.tscn`, `lobby_slot.tscn` | Warm backdrop, "Lobby" title, tall cream cards, Ready / Help / Back words with key-caps. An open slot previews its fixed "Player N" and shape, faded, above "Open slot" (`UiPlayerBadge.bind_preview`; the seat still counts as empty). |
| Play HUD | `play_hud.tscn` | Round on line 1, challenge + TWIST on line 2, cream score chips; still exactly 64 px. |
| Place | `place_overlay.tscn`, `phase_banner.tscn`, `ghost_legend.tscn` | The phase banner is the cream Guide card (title + wrapped controls) at the top of the right column, above the status pills (mark + text + colour); the Place timer bar sits top-centre. |
| Round result | `round_result_screen.tscn`, `score_award_legend.tscn`, `award_line.tscn` | Orange title + vine, chalkboard chart with the Ready key-cap and next-round line in its header, Awards and Score Legend column, Next round bar bottom-right. The legend's entries are now authored in the scene. |
| Pause | `pause_screen.tscn` | Torn-paper panel with a brown backing page, "Paused" title, vine, seat pills, maroon warning pill for a lost controller, plank buttons. |
| Component sheet | `scenes/ui/screens/component_sheet.tscn` (UI Gallery → **Components**) | Every look side by side: plank states, paper and rivet panels, pills, chips, key-caps, status pills, chalkboard legend and timer. |

**Not changed:** node names and `%Unique` contracts in sections 12 and 13a, signals, input routing, scoring and copy except: lobby slot states read "Open slot / Not Ready / Ready / Device lost", the Lobby heading reads "Lobby", Pause reads "Paused", the result legend heading reads "Score Legend", and the Title quit message reads "Are you sure you want to leave?" under the new heading.

**Deviations from the reference (on purpose):** seat shapes and colours stay as in section 4 (owner decision); state words stay inside pills and chips (READY / WAITING / RUN / SAFE…) because the resume and HUD rules need them; Place status pills keep their `[OK] / [X] / [LOCK] / [NO TURN] / [SET]` marks and existing wording so colour is never the only cue; the round-result Score Legend uses two columns so ten award rows still fit at 1280×720; menu buttons keep "Ready / Resume" and "Leave match"; plank text has a thin brown outline for contrast on the orange Hovered plank; the torn paper edge, wood grain, chalk texture, button icons (play, gear, book, leave) and vine art are not reproduced. They need the team's transparent exports, because the PNGs are opaque on white. Side-by-side captures: [ui-reference evidence](evidence/ui-reference/README.md).

**Art requests for the team (empty slots, PLACEHOLDER until filled):** `ui.pause.panel` and `ui.title.quit_panel` (torn paper with backing, transparent PNG, 9-slice friendly), `ui.common.confirm_panel` (rivet panel), `ui.common.plank_button` states, `ui.common.vine_divider`, `ui.round_result.chalkboard`, `ui.lobby.slot_frame`, `ui.lobby.background`, menu icons, and seat shape art via `Art_Circle/Triangle/Square/Diamond`.

## Round result from the Figma frame — 2026-10-17

Source: frame `36:221` "Round Results" of the team Figma file "UI-Tilaok-", read through the Figma MCP connector (exact values, not sampled PNG colours). The frame is 711 × 400, so every size is ×1.8 on the 1280 × 720 canvas. This supersedes the round-result rows of the reference restyle above.

| Piece | From the frame | In Godot |
|---|---|---|
| Backdrop | `rgba(37,52,55,0.75)` | `ResultBackdrop` (75 % so the stage shows faintly behind in a match) |
| Title | Mountains of Christmas Bold 64 → 115 px, `#ffa666`, no shadow | `ResultTitle` **104 px** (see deviations), text "Round N Result" |
| Vine | "Deco Line" SVG | `assets/ui/common/ui.common.vine_divider.svg` in the Round result's `Vine/Art_Vine` (placeholder hidden there only) |
| End reason | Lemonade 20 → 36 px, right-aligned under the vine | `ResultSubtitle` Handlee 36 px; tucked beside the title when it fits (`ResultTitleBlock`), else on its own line (`ResultTitleBlockStacked`) |
| Chalkboard | `#022c02`, 6 → 11 px light frame | `sb_chalkboard` (frame `#dddddd`, the frame's rendered grey) |
| Board header | "Next Round:" Margarine 16 → 29 px; Ready + key-cap | `NextRoundCaption` + `NextRoundLabel` ("NEXT R6 KANGAROO" reads "Next Round: R6 KANGAROO"; "FINAL ROUND" alone); `ReadyHint` overrides in the scene |
| Chart | white 1 px guides, labels Margarine 9 → 16 px | `ScoreAxis` font/size, 2 px white guides and baseline; badges `ChartBadgeNumber` Margarine 27 px |
| Awards / Score Legend | Lemonade Thin 22 / 20 → Handlee 40 / 36 px `#ffa666`; text Margarine 10 → 18 px `#ffc092`; legend "T - Tapos" one column | `ResultHeading`, `ResultText`, `Legend*`; legend entries are letter + dash + name |
| Footer | deadline Margarine 8 → 14 px; bar `#173c50` / `#89b1d5` with a blue gradient; "Next round" / "8s" Margarine 9 → 16 px | `countdown_bar.tscn` (`CountdownBar`, `CountdownCaption`, `CountdownSeconds`; same `UiCountdownRing` script with `seconds_suffix = "s"`) |

**Deviations (on purpose):**
- **Awards column 300 px** instead of the frame's ~170 px, board 900 px instead of ~1010 px: owner decision 2026-10-17, so explained award lines ("● P1 Patibong +0.25 — …") still fit.
- **Title 104 px** instead of 115 px: "Round 5 Result" (with the round number) is ~90 px wider than the frame's "Round Result", and at 115 px the usual end reasons could not sit beside it.
- **Seat shapes and colours** stay as in section 4 (the frame's P3 diamond / P4 square and dark seat colours are not adopted; earlier owner decision). The frame's seat-symbol SVGs are therefore not imported.
- **The chart keeps its bars, chickens, totals, deltas, outcomes and TARGET line**, and the score text sits under each badge: the frame is an empty chart, but the PRD requires exact totals and outcomes. The plot is shorter than the frame's for that reason.
- **Award lines keep their number/shape badge and award colour** (identity rule; the frame's sample text has none).
- **Scoring reason** (the red `NoScoreReason` line, shown every live round) sits in the footer above the deadline note; the frame has no slot for it.
- **Score Legend** is one column as designed while the award lines fit; with more award text it folds to two columns, then hides (each award line already carries its letter and name). If the award lines still do not fit, each distinct explanation is shown once (on its first line; four Kangaroo placements share one), then none: the title + points form this screen already used above six rows. The fit runs when the screen is bound, shown or resized, inside that frame's layout pass, measured from the Theme fonts. The end reason, deadline and scoring-reason labels have minimum widths (600 / 300 / 400 px) so a hidden, never laid-out screen still measures sensibly.
- Lemonade is replaced by Handlee (earlier owner decision). Since the effects pass below, the countdown fill's slanted end and the board grain are reproduced; the art slot `ui.round_result.chalkboard` stays open for a hand-made board texture.

**Checked (synthetic, 2026-10-17):** UI Gallery side-by-side with the frame for 2/3/4 players; live P06 models bound at 1280 × 720 for ten award rows (legend hides, footer ends at 713 px), four explained awards, a long Last Cluck reason (stacked subtitle) and a four-player Kangaroo-style Last Cluck round bound while hidden and then shown (placement explanation once, title at y 0, footer at 713 px); Match result, Components and Place captures for the shared pieces. Regressions (headless, Godot 4.7.2): ui_theme 87, scoreboard_chart 52, p13_hud 265 (three runs), match_ui 190, match_ui_binding 177, match_ui_mode 62, p13_accessibility 65, p13_tutorial 58, p13_navigation 205, p06 102, p08 86, p11 78, p12 61 all pass; run_ui_tests 489 checks keep only its two older failures (`%Outcome1` / `%Final1` contract entries with no matching node). On this PC run_p13_hud_tests also flaked at HEAD (10 timing failures in the Kangaroo cases, results not yet open at the check), so a single failing run there is not by itself a layout regression. Not a human design review (P13-T18 stays open).

### Effects pass — 2026-10-17

The first build used only the frame's code export, which drops gradients and effects. A read-only paint and effect dump of `36:221` and a 1080p Figma render added these. Each one was checked against the render.

| Piece | Figma | In Godot |
|---|---|---|
| Title | 1 px `#624a39` stroke outside the text | `ResultTitle` outline `#624a39`, `outline_size` 6 (3.96 px at 1080p against Figma's 3.87 px) |
| Chalkboard | `#022c02`, **white** 6 px frame, square corners, NOISE (MONOTONE, black 25 %) over the whole frame including lines and labels | `sb_chalkboard` frame white with no radius (the earlier `#dddddd` was the grain's average); `Chalkboard/Grain/GrainPatch` (`ChalkGrain`, the same noise as the Pause backing) drawn over the board, frame and chart |
| Countdown fill | the "Time remaining bar" vector: a trapezoid (top edge 155, bottom 136.8) with stops `#177bb0` 0, `#398ad5` 0.1154, `#095194` 0.399, `#1980b3` 1 | `ui.round_result.countdown_fill.svg` (the team's vector moved to the origin) as the ProgressBar fill, `texture_margin_right` 33 so the slant keeps its shape at any width; it steps 3.7 px per 1080p row against Figma's 3.6 |
| Player symbols | 0.7 px `#fff8e8` inside stroke | the badge `Outline` nodes turned on in `score_column.tscn` (1.26 px), over the game seat colours |
| Placeholder tag | none | "PLACEHOLDER art · round result" removed (it only showed in the UI Gallery) |

**Checked (synthetic, 2026-10-17, effects pass):** 1080p render beside the Figma render. run_ui_theme_tests 139 checks (new: title outline, white frame, countdown trapezoid, grain covering the board, no tag, symbol outlines) pass. scoreboard_chart 52, match_ui 190, match_ui_binding 177, match_ui_mode 62, p13_accessibility 65, p13_navigation 205, p13_tutorial 58, p06 102, p08 86, p11 78 and p12 61 pass. run_ui_tests 490 keeps its two older failures. run_p13_hud_tests showed 9, then 6 failures, all in Kangaroo-round timing cases (results not open yet), the flake already recorded above.

## Plank button from the Figma frame — 2026-10-17

Source: frame `16:434` "Button Variants" of the team Figma file "UI-Tilaok-". Each state is 239 × 22 in the frame; sizes are ×1.8 like the Round result frame. This supersedes the plank values of the reference restyle above (which were sampled from a PNG). The exact paints were read from the file through the Figma MCP connector (a read-only `use_figma` call), because `get_design_context` flattens the gradient outline to plain black.

| State | Figma | In Godot |
|---|---|---|
| Normal | fill `#b77748`; 1 px inside **gradient** outline, stops `#000000` 0 → `#665b44` 0.639 → `#d8c190` 0.884; radius 3 | `sb_plank` fill (**`#eb9c62` since the swap below**), plus the `Stroke` ring with `PlankStroke` |
| Hovered (router-selected) | fill `#eb9c62`, same outline as Normal | `sb_plank_hover` (also `MenuButtonSelected` normal) (**`#b77748` since the swap below**), `PlankStroke` |
| Pressed | fill `#885a39`; outline stops `#000000` → `#665b44` → `#e5cd98`; 1 px `#764019` inner outline; inner shadow `0 4` blur 4, black 25 %, on the whole group | `sb_plank_pressed`, `PlankStrokePressed`, and `PressedLook`: `Frame` (`PlankPressedFrame`, 2 px `#764019`), `ShadeTop` / `ShadeLeft` / `ShadeRight` (black gradients computed from the shadow: 24 % at the top edge fading to 0 by 16 px, 12.5 % at the sides fading by 10 px). The text no longer shifts down 1 px |
| Disabled | fill `#bc9d86`; outline stops `#484848` → `#918b80` → `#d4c39e`; rivets `#775f57`; white text | `sb_plank_disabled`, `PlankStrokeDisabled`, rivets switch to `RivetDisabled`, `font_disabled_color` white |
| Outline direction | `gradientTransform` row 1: t = −0.216 u − 0.683 v + 1.165 over the button (cream along the top and upper left, near-black at the bottom right) | every `PlankStroke*` GradientTexture2D uses `fill_from (0.49039, 1.55062)` → `fill_to (0.06946, 0.21961)`, which gives the same t at any button size |
| Rivets | 5 px circles `#483934`, 7 px in from each end | 9 px `Rivet` circles, 13 px in, 1 px below centre |
| Text | Margarine 12 → 22 px, white, centred | unchanged (already 22 px) |

**Owner decision (2026-10-17): Normal and Hovered fills swapped everywhere.** At the owner's request ("interchange the color of the buttons normal and hovered"), `sb_plank` (Normal) is now orange `#eb9c62`, and `sb_plank_hover` (Hovered and router-selected) is now brown `#b77748`. This covers every plank: Title, Pause, Lobby map arrows, Settings, Library, both confirmations and Final results. Pressed and Disabled, the outline, the rivets and the text are unchanged. `run_ui_theme_tests.gd` (`PLANK_FIGMA`) checks the swapped fills.

**How the outline is built:** a stylebox has one border colour, so `Stroke` is a Panel drawing a 2 px rounded ring (`PlankStrokeMask`, white) with **Clip Children = Clip Only**; its child `Gradient` fills the whole button with the `PlankStroke*` gradient and only shows inside the ring. `PressedLook` (`PlankClip`, also Clip Only) clips the pressed shadow to the rounded plank and is drawn after the outline, so it darkens the outline, inner frame and text tops as Figma's group shadow does. To change a colour, edit the gradient of `tex_plank_stroke*` or the stops of `grad_plank_shade_*` in the Theme. `ui_plank_button.gd` only picks the Theme type per state (outline gradient, `PressedLook` visible, rivet colour). `RivetLeft` / `RivetRight` keep child indices 0 and 1 (the Lobby map arrows hide them through those overrides).

**Deviations (on purpose):** the thin brown text outline stays (white on the orange Hovered plank is about 2.2 : 1 contrast without it); the plank width stays set by each screen (the frame's 239 → 430 px is not forced on the component); the two shadow corners are a product of the top and side gradients, so the top 4 × 6 px of each corner can be up to about 7 % darker than Figma. Menus built from the `TilaokMenuButton` Theme type **without this scene** (Library, Settings, Match result) cannot show a gradient outline: their stylebox border is the gradient's middle stop (`#665b44`, Disabled `#918b80`) and they have no rivets or Pressed inner frame.

**Checked (synthetic, 2026-10-17):** the four states rendered at 1280 × 720 (430 × 40 planks) beside the Figma screenshot; 18 outline pixels per state compared with Figma's gradient formula differ by at most 1/255 per channel; the Pressed column matches Figma's rendered shadow row for row; fills are exact. run_ui_theme_tests 111 checks (exact fills, gradient stops and direction per state, clipping, state switching) pass; run_ui_tests 490 checks keep only the two older failures; p13_navigation 205, p13_accessibility 65 and match_ui 190 pass. Not a human design review.

## Pause screen from the Figma frames — 2026-10-17

Source: frames `5:44` "Pause Menu" and `5:81` "Pause Menu (With Warning)" of the team Figma file "UI-Tilaok-" (262 × 331 each), read through the Figma MCP connector with exact paints and effects. Sizes are ×1.8 like the other Figma screens, so the paper is 385 × 506 on the 1280 × 720 canvas. **Owner decision (2026-10-17):** the pills keep each player's in-game colour and shape; everything else follows the frames.

| Piece | Figma | In Godot |
|---|---|---|
| Paper | `#f6e7cd`, drop shadow `0 4` blur 4.6 spread 2 25 %, TEXTURE (torn edge) and NOISE effects | `Decor/PaperArt/Art_Panel`: the Figma render of the layer itself (`ui.pause.panel`), 9-slice, shown 1:1 at 1080p. It stretches only when extra rows appear |
| Backing | `#9e6941`, turned 2.344°, MONOTONE noise 25 % black | `Decor/Backing` (`PauseBacking`), `rotation` −2.344°, centred pivot; grain = `PauseBackingGrain` (NoiseTexture2D, about half the grains at 25 % black, 3 octaves) |
| Title | Mountains of Christmas Bold 24, `#784623`, tracking 4 % | `PauseTitle` 43 px, letter spacing 2 px (`fv_pause_title`) |
| Vine | "Deco Line" | `ui.pause.vine.svg` (its own drawing, not the Round result vine) |
| Lines | Mansalva 10, black: "shared pause · any player can take the menu" / "everyone must be ready to resume" | `PauseScript` 18 px. Figma centres these in short text boxes, so the rows sit 5.87 px higher than the box tops to land on the same glyph rows |
| Pills | 185 × 16.17, radius 6, two GLASS effects, symbol 9 px with a 0.7 px `#fff8e8` inside stroke, Margarine 8 white | `seat_pill.tscn`: game colours (`PillSeat1…4`, borders removed, radius 11), `ui.pause.pill_glass` overlay, symbol 16 px in the pill colour with a cream `Outline`, `PausePillLabel` 14 px |
| Buttons | the Button Variants plank at 185 × 17, rivets 4 px, group drop shadow `0 2` 25 %, icons, Margarine 8 | `plank_button.tscn` at 31 px (font 14, rivets 7 px at 9 px), a `DropShadow` panel 3.6 px below each, `Icon` nodes placed from the frame relative to the label |
| Warning | the lost player's pill grows to 185 × 46 with the message inside (Margarine 8 white, centred) | `%ReclaimPanel` moves into that seat's place in the roster and takes its `PillSeatN` colour; the seat's normal pill hides |

**Still working (unchanged contracts):** every `%Unique` node from sections 12/13a, the menu order and signals, owner-only navigation, ready / waiting / device-lost states, the 3 s countdown, reclaim seat choice with Left / Right, Skip tutorial and the Leave confirmation.

**Deviations (on purpose):**
- The pill shows the state word (READY / WAITING / DEVICE LOST) at its right end. The resume rule needs it, and colour alone may not carry it.
- The owner state reads "paused by" plus the owner badge in line 1, a state the frame does not show.
- A countdown replaces line 2 ("resuming in 3").
- An extra reason line appears only for reasons the frame and the reclaim pill do not already say: window focus lost or changed, or a controller changed.
- "Left/Right picks another missing seat" is added only when more than one seat is missing.
- The panel grows (the paper 9-slices) when a row is added. The warning frame instead tightens its spacing for three players.
- The Resume entry is highlighted because the menu shows the selected entry.
- Font sizes are whole pixels (14 for 14.4).
- Plank text keeps its thin brown outline.

**Checked (synthetic, 2026-10-17):** 1080p renders beside the Figma renders. The backing edge pixels and the bottom shadow band match row for row, and line glyph rows land within 0.6 Figma px of the frame. Pill and plank text sit within about 1 Figma px. In-game capture over the scrim shows no white box. run_ui_theme_tests 133 checks (new Pause frame and live-state checks), run_ui_tests 490 (the same two older failures), match_ui 190, match_ui_mode 62, match_ui_binding 177, fix_regression 9, p13_navigation 205, p13_accessibility 65 and tutorial 142 all pass. Not a human design review.

## Place from the Figma frame — 2026-10-17

Source: frame `18:8` "Obstacle Place" (711 × 400, ×1.8), read through the Figma MCP connector (read-only paint and effect dump, 2.7x render). The frame's background is a screenshot of the old debug Place screen; the new UI drawn over it replaces the PLACE banner, the `[OK]`/`[X]` legend and the bottom status rows. Seat colours and shapes stay the game's (owner decision).

| Piece | Figma | In Godot |
|---|---|---|
| HUD rail (all phases) | `#2d2920`, `#607477` bottom line, 43 px tall | `HudBar` same colours, **64 px** (the stage camera reserves 64 px, `camera_hud_reservation_px`); elements keep their 1.8x sizes and sit higher to fit |
| Round / level | Margarine 15 `#fff8e8` / Mansalva 9 `#b9c8c6` | `HudTitle` 27 px / `HudSub` Mansalva 16 `#b9c8c6`, pinned in a 54 px block (`Left` is a plain Control) |
| Score chips | 107 × 22, `#f6e8ce`, 0.7 px `#9d5c00`, radius 3; symbol 10 px with cream stroke; "P1" Margarine 8 `#483934`; state Mansalva 8 `#784623`; score Margarine 10; at x 107 / 219 / 331 / 443 | `score_chip.tscn` 192.6 × 39.6, the same colours, outlined 18 px symbol (game colours darkened), `ChipName` / `ChipState` 16 px (mid-round minimum, Figma 14.4), `ChipLabel` 18 px; chips left-aligned at the frame's x |
| Chip state in Place | "Placing" / "Placed" | presenter `_place_state_text`: Placed once the seat confirmed, else Placing |
| Timer | 125 × 4 bar `#173c50` with `#89b1d5` 0.7 px frame, the "Time remaining bar" trapezoid fill; "8 secs" Margarine 5 | `place_timer.tscn` (`%Countdown`, `UiCountdownRing` with " secs"), fill `ui.place.timer_fill.svg` (its own slant: 18 over 4), clipped to the rounded bar under the frame; label 12 px (minimum label size) |
| Guide card | 151 × 51, `#f6e7cd`, 0.7 px `#d6ba87`, radius 3, drop shadow `0 4` blur 4 25 %, four 3 px `#483934` rivets, "Guide" Margarine 13 `#483934`, three lines Margarine 8 `#8d5125` | `%PhaseBanner` with `GuideCard` / `GuideCardTitle` 23 px / `GuideCardBody` 14 px, `Rivets` nodes; title "Guide"; the live hint is one action per line in the frame's "W A S D/Arrow keys" style (Pugad's banner is unchanged) |
| Status tabs | four 92 × 16.4 tabs with a 4.7 px top strip, Road Rage 10 white: Valid `#3f675a`/`#7ad18d`, Blocked `#5e0d0e`/`#b40a0c`, Protected `#8a8c5a`/`#d3e018`, Cannot rotate `#4c5653`/`#9db9a3` | `ghost_legend.tscn` rebuilt: `PlaceTab*` / `PlaceTab*Strip` / `PlaceTabText` 18 px, frame copy unchanged; positions within 0.7 px of the render |

**Still working:** every `%Unique` node (`Countdown`, `PhaseBanner`, `GhostLegend`, `GhostStatus`, `ReasonToast`, `SeatStatus1…4`, `Pointer1…4`), the rejection toast, the live countdown and hint, and the HUD in Pugad and Play.

**Deviations (on purpose):**
- The HUD rail stays 64 px, not 77 px.
- The chip name and state are 16 px, not 14.4, and the timer label is 12 px, not 9, to meet the readability minimums.
- `GhostStatus` ("N of M locked") and the per-seat `SeatStatus` rows stay bound but hidden, as the frame drops them. The chips carry Placing / Placed.
- The "Placed" legend row is gone, as in the frame.
- The world ghosts (`item_ghost.gd`) still draw their own colours: valid `#7fd68a` is close to the tab, but blocked `#ef6a5b`, protected `#f2b84b` and rotate-off differ from the tabs (open question for the team).
- The frame's 30 % black layer over the stage is not added. It reads as a mock-up dim and would darken the ghosts.
- "cant" is kept as written in the frame.

**Checked (synthetic, 2026-10-17):** 1080p render over the frame's own background screenshot. The chips, Guide card, tabs and timer land at the frame's positions; the tabs measure within 0.7 px. run_ui_theme_tests 149 checks pass (new: HUD rail, chip styles, Guide card and rivets, four tab colours and copy, timer, hidden old rows, 64 px rail). run_match_ui_tests 194 pass (Place now checks the chips read Placing and the hidden rows stay bound). match_ui_mode 62, match_ui_binding 177, p13_accessibility 65, p13_navigation 205, p13_tutorial 58, tutorial 142, p13_cheer 39, fix_regression 9, p05 137 and p03 103 pass. run_ui_tests keeps its two older failures. run_p13_hud_tests shows only the recorded Kangaroo timing flake. Not a human design review.

## Pugad pick screen from the Figma frame — 2026-10-17

Source: frame `2:5` "Obstacle Pick" (711 × 392, ×1.8), read through the Figma MCP connector: a read-only paint and effect dump, a 2.7x render, and the nest layer's image. The frame's background is a screenshot of the old debug Pugad screen.

**Owner decisions (2026-10-17):**
- **Follow the GDD on eggs.** The cards show the live item preview but no item name or description (GDD §Pugad: names and descriptions belong in the Library). The frame's "Tulay" / "A little foothold" lines are not built.
- **Keep players + 2 eggs.** The frame's four card spots are used as drawn, and two more spots in the same tilted style sit left and right of the nest for 5 and 6 eggs.
- Seat colours and shapes stay the game's (earlier decision).

| Piece | Figma | In Godot |
|---|---|---|
| Dim | `#191818` at 41 % below the HUD | `Dim` ColorRect from 69.4 px (the frame's 3 px gap below the rail) |
| Pugad HUD | rail `#2d2920` / `#607477`; "Round 1" Margarine 11 `#fff8e8`; "Karera" Mansalva 9 `#b9c8c6`; `#e8c46e` live dot + "PUGAD" Margarine 13 `#f6e7cd`; four chips stacked at the right (120 × 22, `#f6e7cd`, 0.7 px `#d6ba87`) reading Picked / Choosing | `pugad_overlay.tscn/Hud`: the rail stays 64 px like the Play HUD; `PugadRound` 20 px, `HudSub`, `PugadPhaseDot` and `PugadPhase` 23 px; `HudChip1…4` are `score_chip.tscn` with `ScoreChipPaper` (216 × 39.6). The Play HUD hides during Pugad (presenter) |
| Nest | image layer `15:319`, cropped | `ui.pugad.nest.png`: the team's nest image, cropped to the frame's crop (scale 1.163, top 227 px), transparent background |
| Title | `#784623` backing tilted 0.8° behind a `#f6e7cd` card with a 1 px `#d6ba87` frame; "Pick an obstacle" Mountains of Christmas Bold 25 `#784623`; "One pick each. Make the next race your own!" Mansalva 10 `#483934` | `Title/Backing` and `Title/Card` (`PugadTitleBacking`, `PugadTitleCard`), `PugadTitle` 45 px, `PugadInstruction` 18 px |
| Egg cards | 98 × 158, the "Ellipse 15" egg (`#faeed2`, 1 px `#d8c190`), tilted 11.84 / 2.12 / -3.8 / -12.49°; pick pill in the seat colour with an outlined symbol, "P1" Margarine 9 and "✓ Picked" / "Choosing…" Margarine 8 `#fff8e8` | `egg_slot.tscn`: `ui.pugad.egg.svg`, the live `ItemEggPreview` inside it at 2x with its placeholder shell off (`draw_shell = false`), and `%Pill` (`EggPill1…4` in the game seat colours, `pill_badge.tscn`, `EggPillName` 16 px, `EggPillStatus` 14 px) |
| Card layout | four hand-placed spots | `Spots/Spots4…6/SpotN` markers, each with a `Pill` marker, copied onto `Egg1…6` by `UiPugadOverlay._layout_eggs`. Spots4 = the frame (A, B, D, C left to right); Spots5 adds E at the left; Spots6 adds F at the right |
| Countdown | "2 / 4 picked" Margarine 9 `#fff8e8`, "8s" Margarine 11 `#f5dea0`, the 218 × 7 bar with the "Time remaining bar" fill | `pugad_countdown.tscn` (`%Countdown`, "N / M picked" caption, "s" suffix), the same `CountdownBar` style and trapezoid fill as the Round result |
| Hints | "← → Choose" and "South / Enter  Pick", Mansalva 10 `#fff8e8` | `%NavHint` / `%PickHint` (`PugadHint` 18 px); the pick keys come live from the joined devices |

**Still working:**
- Every `%Unique` contract (`Egg1…6` with `%OwnerBadge` / `%Selector1…4`, `Countdown`, `PhaseBanner` kept but hidden, `AnnounceBanner`, `LostClaimToast`).
- The egg slot API (`configure`, `set_claim_owner`, `set_selectors`, `selector_numbers`, `claim_owner_number`).
- The next-round announcement and the lost-claim toast at the bottom left, and the twist tag in the Pugad HUD.
- `%EggRow` is now the card layer (`Control`); the UI contract test follows.

**Deviations (on purpose):**
- The HUD rail is 64 px, not 77 px, as on the other screens.
- Chip text is 16 px, not 14.4, and the pill status is 14 px, not 14.4 (readability minimums).
- The egg preview is the live item animation, not the frame's static plank drawing.
- No name or description on cards (GDD).
- Two extra card spots exist for 5 and 6 eggs.
- Margarine has no ✓ glyph, so it comes from the system symbol font, as in Figma's render.
- Where cards overlap, the frame's layer order is kept, so a pill can tuck slightly under the next egg.

**Checked (synthetic, 2026-10-17):** 1080p renders over the frame's own background for 4 eggs (the frame) and 6 eggs. run_ui_theme_tests 156 checks pass (new: title, paper chips, 4 eggs for 2 players, first card spot, no name or description, pill words, dim and nest, Pugad HUD, count and hint). run_match_ui_tests 196 pass (the Pugad HUD names the round, chips read Choosing, "0 / 2 picked", "8s", next-round totals on the Pugad chips). match_ui_mode 62, match_ui_binding 177, barya 72, p13_accessibility 65, p13_navigation 205, p13_tutorial 58, tutorial 142, p13_cheer 39, fix_regression 9, p05 137 and p12 61 pass. run_ui_tests keeps its two older failures. run_p13_hud_tests shows only the recorded Kangaroo timing flake. Not a human design review.

## Tutorial coach card from the Figma frame — 2026-10-17

Source: frame `91:2` "Tutorial" (262 × 315; the card is 234 × 271) of the team Figma file "UI-Tilaok-", read through the Figma MCP connector (one `get_design_context`). **Owner decision (2026-10-17):** keep the coach box's footprint and show the frame at **×1.125**, so the body stays 18 px. The ×1.8 used for the full-screen frames would make the card 421 px wide with 29 px body text.

| Piece | Figma | In Godot |
|---|---|---|
| Card | 234 × 271, `#f6e7cd`, 0.7 px `#d6ba87`, radius 3, drop shadow `0 4` blur 4 25 % | `TutorialCard` (`sb_tutorial_card`): 263 px wide, 1 px outline, radius 3, 4 px shadow at `0 4.5`; the height follows the text |
| Title | "Guide:" Mountains of Christmas Bold 32 `#784623`, centred | `Header/Title`, `TutorialCardTitle` 36 px |
| Step line | "Step 5 of 5 - Results" Margarine 12 `#94796f` | `%StepLabel`, `TutorialCardCaption` 14 px |
| Body | Margarine 16 `#483934`, 218 px wide | `%BodyLabel`, `TutorialCardBody` 18 px |
| Footer | "Pause > Skip Tutorial" Margarine 12 `#94796f`, right-aligned 4 px from the edge | `%SkipText`, `TutorialCardCaption` 14 px, right-aligned |

**Layout:** `Header` is a plain Control (62.9 px) that holds the title and the step line at the frame's baselines. Godot's line boxes are taller than Figma's, so a VBox could not keep both. The body, `FooterGap` (13.9 px) and the footer row follow. The card sits at (24, 167) in a match and 372 px down in the Lobby, as before, now 263 px wide. In Results it moves to x 947, so its right edge stays at 1210, and the Round result reserves 303 px (was 290).

**Still working:** `%Anchor`, `%StepLabel`, `%BodyLabel`, `%PromptGlyph`, `%SkipText`, `%SkipHint`, `%Tag`, `bind_live` / `bind_step`, the display-only rules of section 16, and the copy in `tutorial_script.tres` (unchanged).

**Deviations (on purpose):**
- The step line and footer are 14 px; ×1.125 gives 13.5, and font sizes are whole pixels.
- The footer still reads "Pause > Skip tutorial", matching the Pause button's label rather than the frame's "Skip Tutorial".
- The frame's body is sample copy with typos ("awares", "playes"). The live text comes from the script.
- The chip glyphs (`%PromptGlyph`, `%SkipHint`) and the PLACEHOLDER tag are hidden, as the frame has none. The copy is still unreviewed placeholder English.
- The body uses the card's full inner width (250 px, not the frame's 245). Godot counts a trailing space when it wraps; with the extra room, the frame's sample breaks into the same 8 lines.
- The base scene's `Anchor` now sits at the in-match position without `SafeAreaMargin`, so the 2D editor and the UI Gallery show the card as players see it. The gallery uses the 5-step titles.

**Open issue (needs a decision):** with 3 or 4 players, the Pugad pick screen (section above) puts egg spot E at x 94–270, y 212–497, under the coach card (x 24–287 from y 167). During the tutorial's Pugad step the card hides that egg. The old 250 px box covered it too, so the card's width is not the cause. `capture_tutorial_evidence.gd` reports it as "4p pugad: box does not overlap Egg1".

**Later edits (2026-10-17):**
- **Owner scene edit:** in `tutorial_prompt.tscn` the "Guide:" title is removed, `Header` is 26.5 px, the body has a 15 px override and the base `Anchor` is 222 px wide. `match_hud.tscn` still overrides the in-match box to 24–287 (263 px), so a match shows 263 px until that override changes.
- **Welcome step (owner request: "put it on the top left of the screen because its blocking the other elements"):** the Lobby card now sits at (24, 24), 400 px wide (`lobby_offset_top` 24, new `lobby_width` 400). The narrow card at the top-left would cover the Player 1 name. At 400 px, the longest 4-player text (three keyboards and a gamepad) ends at y 179. That is above the seat slots (y 196) and left of the map arrows (x 452). Other steps are unchanged.
- **Checked:** run_ui_theme_tests 166 pass (the title check was dropped; new: the Welcome card's top-left position, width and clearance). tutorial 142 and p13_tutorial 58 pass, and run_ui_tests keeps its two older failures. `capture_tutorial_evidence.gd` from an isolated copy: 58 checks, 1 failure, the Pugad overlap above. The 2p and 4p Lobby captures show the card clear of the title, map row and slots.

**Checked (synthetic, 2026-10-17):** a 1080p Godot render beside the Figma render, compared with scratch scripts: the title, the step line, all 8 body lines and the footer land within about 1 Figma px, with the same line breaks. run_ui_theme_tests 165 checks pass (new: card paper, three text types, card copy and alignment, hidden chips and tag, Results position and strip, match position, match HUD width). tutorial 142, p13_tutorial 58, match_ui 196, match_ui_binding 177, match_ui_mode 62, p13_accessibility 65 and p13_navigation 205 pass. run_ui_tests 498 keeps its two older failures. `capture_tutorial_evidence.gd`, run from an isolated copy (captures not committed): 46 checks, 2 failures. One is the Pugad overlap above. In the other, the 2-player Place shot lost window focus, so the game paused and hid the card and marker; the same check passed for 4 players. The Results and Lobby captures show the card clear of the awards, legend and slot text. gdformat / gdlint are not installed on this PC (COULD-NOT-RUN). Not a human design review.

## Final results (winner) screen from the Figma frame — 2026-10-17

Source: frame `100:77` "Winner Results" (711 × 400, ×1.8) of the team Figma file "UI-Tilaok-", read through the Figma MCP connector: one `get_design_context` and one read-only paint and effect dump. The plan's call limit was reached before a 2.7x render could be exported, so checks use the frame's 1x screenshot scaled to 1080p. The frame reuses the Round result's pieces (title style, chalkboard with white frame and grain, Awards / Score Legend type, the Button Variants plank).

| Piece | Figma | In Godot (`match_result_screen.tscn`) |
|---|---|---|
| Backdrop | `#253437` at 75 % | `ResultBackdrop` |
| Title | "Final Results" Mountains of Christmas Bold 64, `#ffa666`, 1 px `#624a39` outside stroke, box x 17–328 | `%TitleLabel` in `TitleArea` (a plain 162 px Control): `ResultTitle` at 115 px |
| Vine | "Deco Line" 501 × 31 at (338, 36): the Round result drawing at 1.24x | `TitleArea/Art_Vine`, `ui.match_result.vine.svg` at svg/scale 1.8 (902 × 55), drawn from x 608.4 off the right edge |
| Board | `#022c02`, 6 px white outside stroke, MONOTONE noise 25 %, (28, 96) 561 × 258 plus the players strip | `ChalkboardPanel` 40–1071 × 162–648 with the Round result's `Grain` patch; `%FinalChart` inside |
| Winner line | "Winner - P2  Triangle" Margarine 16 white at (49, 104) | `%WinnerLabel` (`ChalkLabel` 29 px) on the board header; text `UiMatchResultScreen.winner_text()` = "Winner - P%d  %s" with the shape in title case |
| Awards | "Awards" Lemonade Thin 22, outcome Margarine 10 `#ffc092` at x 606 | `AwardsHeader/AwardsHeading` (`ResultHeading` 40) on the frame's baseline; `%OutcomeLabel` (`ResultText` 18, line spacing −1) = the live outcome ("Highest score after round 12 ended the match.") |
| Score Legend | heading Lemonade Thin 20 at (606, 234); one column at (615, 257) | `LegendHeading` (`ResultHeading` **30**), `%ScoreAwardLegend` with `columns = 1` |
| Buttons | three 185 × 17 planks at x 62 / 274.71 / 480, y 369; `#b77748`, gradient outline, 4 px `#483934` rivets, group drop shadow `0 2` 25 %, Margarine 8 white | `%MenuList` (horizontal `UiMenuList`): `plank_button.tscn` 333 × 31 at x 112 / 495 / 864, y 664, font 14, rivets 7.2 px as placed in the frame, `DropShadow` (`PauseButtonShadow`) 3.6 px below; spacers `Lead` / `Gap1` / `Gap2` |

**Measured (1080p render against the frame scaled to 1080p, in Figma px):** title glyph rows within 0.3; winner line, "Awards", the three outcome lines, "Score Legend" and all seven legend rows within about 1.2; plank text within 1. Board edges and plank positions match the frame to the pixel (Quit at x 864 after rounding).

**Still working:** `%WinnerBadge`, `%WinnerLabel`, `%OutcomeLabel`, `%LastCluckCallout` (`UiPhaseBanner`), `%FinalChart`, `%ScoreAwardLegend`, `%MenuList`, `%ReplayButton`, `%LobbyButton`, `%QuitButton`, the signals, router-driven menu selection, the live P09 binding and the gallery states.

**Deviations (on purpose):**
- The chart keeps its bars, chickens, totals, TARGET line and WINNER / FINAL SCORE status under each badge, so the plot is shorter than the frame's empty chart (as on the Round result). Seat colours and shapes stay the game's.
- The selected menu entry shows the orange Hovered plank (the menu is router-driven, as on Pause).
- "Score Legend" is 30 px, not 36. Handlee (the stand-in for Lemonade Thin) at 36 px is 199 px wide and would run past the screen edge in the frame's 169 px column.
- The Last Cluck explanation, which the frame has no slot for, shows as a white 18 px chalk line under the winner line, only in that case. Its "LAST CLUCK!" title label is hidden because the explanation already starts with "Last Cluck!".
- The winner badge is hidden (the line names number and shape, as in the frame); the old PLACEHOLDER tag is removed.
- The live outcome keeps its final full stop ("…ended the match.").
- The two plank gaps are 49.9 and 36 px, as placed in the frame (the second rounds 36.5 to 36 so Quit lands on x 864).

**Checked (synthetic, 2026-10-17):** gallery renders (4 players; Last Cluck) and a live `bind_final_match` render (3 players, sudden death won by Last Cluck: two-line explanation, four-line outcome; legend and planks unmoved). run_ui_theme_tests 177 pass (new: winner text format, title, vine, board, winner line, Awards column and one-column legend, three planks, no tag, Last Cluck line). run_match_ui_mode_tests 62 (winner check now "Winner - P"), match_ui 196, match_ui_binding 177, scoreboard_chart 52, p13_navigation 205, p13_accessibility 65 and p09 77 pass. run_ui_tests 498 keeps its two older failures. gdformat / gdlint not installed (COULD-NOT-RUN). Not a human design review.

## Menu action buttons from the Figma frame — 2026-10-18

Source: frame `103:562` "Menu actions" of the team Figma file "UI-Tilaok-", read through the Figma MCP connector (one `get_design_context`; its colours are flat and matched the screenshot's pixels, so no paint dump was needed). This frame is drawn at game scale: 1 Figma px = 1 px on the 1280 × 720 canvas (its 22 px label equals the existing menu text), not ×1.8 like the full-screen frames. **Owner decision (2026-10-18): brown = selected.** Whichever entry the router selects takes the brown 72 px "Play action — Selected" look with the pointer; every other entry is the cream 54 px "Menu action". The list keeps its total height as the selection moves.

| Piece | Figma | In Godot (`scenes/ui/components/menu_action_button.tscn`, `UiMenuActionButton`) |
|---|---|---|
| Normal | 388 × 54, fill `#ead5af`, 1.5 px inside edge `#b99669`, radius 7, drop shadow `0 3 0` `#af895d` 40 % | Button type `MenuAction` (edge colour; 54 px from its margins plus the 22 px text), `Face` (`MenuActionFace`, 1.5 px in, radius 6), `Shadow` (`MenuActionShadow`, reaches 3 px below) |
| Selected | 388 × 72, fill `#b77748`, edge `#86502f`, drop shadow `0 4 0` `#754526` | `MenuActionSelected`, `MenuActionFaceSelected`, `MenuActionShadowSelected` (4 px) |
| Inset edge | 1 px line, radius 4, 5 px in from the top and sides, 7 px from the bottom; `#f8e9cb` / `#e6b484` | `Inset` (`MenuActionInset` / `MenuActionInsetSelected`) |
| Fastenings | 5 px dots, 18 px in from each end, centred; `#ae8659` / `#86502f` | `FasteningLeft` / `FasteningRight` (Theme circles; the frame's dot SVGs are not imported) |
| Label | Margarine 22 `#684127` / Margarine 31 `#fff8e8`; 20 px icon, 13 px gap, icon and text centred together | `ActionLabel` (`MenuActionRow`, separation 13): `Icon` + `Label` (`MenuActionText` / `MenuActionTextSelected`; a 2 / 3 px top margin puts the glyphs on Figma's rows) |
| Play icon | "play" 20 × 20, 1 px `#fff8e8` stroke | `ui.common.icon_play.svg` (Lucide "play", ISC) set as the Title `StartButton`'s **Action Icon**; shown while selected |
| Pointer | 15 × 22 `#86502f`, 14 px left of the button, centred | `Pointer`, `ui.common.menu_pointer.svg`; shown while selected |
| Gap | 16 px | Title `%MenuList` separation 16 |

**How it is built:** a stylebox border can only be whole pixels, so the button's own stylebox is the edge colour and `Face` sits 1.5 px inside it. The button keeps its `text`, but the Theme draws that text transparent: the 54 / 72 px heights come from the stylebox margins plus the text, and `ActionLabel` shows it (a Button's own icon would sit at its left edge, not beside the text). `ui_menu_action_button.gd` only picks each node's Theme type and copies the text. It is a tool script, so in the 2D editor you type the label in **Text** and tick **Selected** to preview the brown look. `UiMenuList` now calls `set_selected` on any item that has one before falling back to the plank Theme types, so plank menus are unchanged. To change a colour, edit the `sb_menu_action_*` StyleBoxes in the Theme.

**Title changes:** the four entries are menu action buttons 388 px wide; "Start local match" now reads **Play**, as in the frame; the gap is 16 px. Unique names, signals and router behaviour are unchanged. The Title quit confirmation keeps its plank buttons. The component sheet (UI Gallery) shows a Selected and a Normal button at 250 px wide.

**Not in the frame (derived, for Shanti to confirm or design):**
- Mouse hover on a cream entry: no change. Selection still moves by keys or click, as before.
- Mouse held on the selected entry: face `#885a39`, the Pressed fill from the Button Variants frame (16:434). A cream entry shows no pressed look; on release it becomes selected and acts.
- Disabled: cream with the text at 45 % (`MenuActionTextDisabled`). No Title entry is ever disabled.
- Play shows its icon only while selected (the frame shows Play only in that state).
- While the menu is inactive (quit dialog open) no entry is selected, so all four are cream and the column is 18 px shorter behind the scrim.

**Checked (synthetic, 2026-10-18):** the frame's layout rendered at 1x beside the Figma screenshot: button rects 388 × 72 / 54 at y 0, 88, 158, 228, exactly as the frame; edge, inset, fastening and shadow rows and colours match the pixel scan; icon ink centroid within 0.03 px; text ink centroids within 0.66 px across and 0.51 px down (Godot puts text on whole pixels). 1080p renders of the Title (Play selected, Settings selected, quit dialog) and of Library selected. run_ui_theme_tests 197 checks pass (new: exact colours, shadow reach, text styles, 388 × 54 / 72 sizes, pointer, fastening and inset positions, pointer and icon only while selected, Title selection moving). run_ui_tests 501 keep only the two older `%Outcome1` / `%Final1` failures. p13_navigation 205, match_ui 196, p13_accessibility 65, fix_regression 9, match_ui_binding 177, match_ui_mode 62, p13_library 422, p13_tutorial 58 and tutorial_gate (`--fixed-fps 60 --quick`) 46 pass. gdformat / gdlint could not run (not installed on this PC). Not a human design review or physical-device test.

## Title screen (main menu) from the Figma frame — 2026-10-20

Source: frame `103:553` "Parchment main menu" of the team Figma file "UI-Tilaok-" (one `get_design_context` call plus the team's 2x PNG export). Like the Menu actions frame inside it, it is drawn at game scale: 1 Figma px = 1 px on the 1280 × 720 canvas. The frame's 744 px card would not fit 720 px, but its title has two 92 px lines and "Tilaok!" needs one, so the card is 652 px tall and everything below the title sits 92 px higher than in the frame.

| Piece | Figma | In Godot (`scenes/ui/screens/title_screen.tscn`) |
|---|---|---|
| Card | 544 × 744 paper `#f6e7cd`, 1 px inside edge `#d6ba87`, radius 3 | `Card` 544 × 652, centred at (368, 34); `Paper` (`TitleCardPaper`) |
| Backing page | `#b77748`, 544 × 728, turned −1.5°, drop shadow 3 10 22 `#59391f` 19 % | `Backing` 544 × 636, same turn and centre offset (0.435, −5.245); `Backing/Shadow` (`TitleCardBackingShadow`) |
| Paper shadow | Not in the design context; fitted to the PNG export: about 0 10 18 `#59391f` 17 % | `Paper/Shadow` (`TitleCardPaperShadow`), drawn over the backing page as in the frame |
| Grain | Figma noise effect | `Grain/GrainPatch` (`TitleCardGrain`, generated noise, one texel per 1080p pixel) |
| Stitched border | 1 px dashed `#bc976a` at 65 %, 13 px in, radius 3 | `DashTop` / `DashBottom` / `DashLeft` / `DashRight` (`#d0b38d`, 3 px on, 5 px off) |
| Paper pins | 5 px `#d6ba87` at (24, 25) and (515, 25) | `DotLeft` / `DotRight` (Theme circles) |
| Emblem | "Postal emblem", 29 × 33.27 at (257, 31.73) | `Art_Emblem`, `ui.title.emblem.svg` |
| Title | "Bramble & Post", Mountains of Christmas Bold 100 `#684127`, 92 px lines from y 80 | `%TitleLabel` "Tilaok!" (`TitleCardTitle`); label top 56 because Godot's line box is 140 px, which keeps Figma's baseline at 161 |
| Subtitle | "Little letters. Grand adventures.", Margarine 17 `#94734f`, top 282 | `Subtitle` "Pugad. Place. Play." (PLACEHOLDER copy), top 188.85: 190 less the 1.15 px Godot draws this line lower |
| Ornament | "Botanical ornament", 332 × 27 at (106, 320) | `Art_Ornament` at (106, 228), `ui.title.ornament.svg` |
| Menu | Menu actions, 388 wide at (78, 374), 16 px gap | `%MenuList` at (78, 282); the buttons from "Menu action buttons" above |
| Footer | "A little kindness goes a long way.", Margarine 14 `#94734f`, top 685 | `%BuildLabel` (the build text), top 592.1 (593 less 0.9 px) |

**Pointer shadow (menu button component):** in the frame the pointer is part of the selected button, so the button's solid 0 4 0 `#754526` drop shadow shows under the pointer too. `menu_action_button.tscn` now has `Pointer/Shadow`: the same picture 4 px lower, tinted to `#754526`.

**Shadows:** a Godot StyleBox shadow fades in a straight line from the panel edge outward, while Figma's is a blur centred on the edge. Each `Shadow` panel therefore sits inside its page by half its fade, so the fade is centred on the page edge, and the fade is 3.09 × the blur's sigma (sigma = Figma blur ÷ 2): 34 px inset 17 for the backing, 28 px inset 14 for the paper. To change a shadow, edit `sb_title_card_backing_shadow` / `sb_title_card_paper_shadow` (colour, alpha, size) and keep the panel's inset at half the size.

**Not in the frame (Claude's choices, for Shanti to confirm or design):**
- One-line title and the shorter card (above). A picture logo can go in `Art_Logo` (hide `TitleLabel` if used).
- Subtitle copy "Pugad. Place. Play." and the build label in the footer line; the frame's lines are sample text.
- LAN Lobby: a normal menu button outside the card, bottom-right inside the safe area (mouse only, as before).
- Nobody joined: a brown join prompt (`TitleCardPromptAction`, Road Rage 34 `#684127`) replaces the menu on the card.
- Background: the frame has none, so the existing dark `Backdrop` and the empty `Art_Background` slot stay.

**Checked (synthetic, 2026-10-20):** 2x renders with the frame's sample text swapped in, compared with the PNG export (its second title line cut out). Ink centroids: title 0.3 / 0.2 px, emblem 0.2 / 0.5 px, subtitle 0.0 / 0.1 px, ornament 0.8 / 0.0 px (identical bounding box), footer 0.2 / 0.1 px, pointer 0.1 / 0.0 px; button edges fall on the same pixel rows; menu label glyphs within 0.4 px. Shadow darkness profiles below, left, right and above the card agree within 1–3 % (they were up to 13 % darker before). Grain: mean luminance 0.895 against 0.895, spread 0.013 against 0.015. 1080p renders of Play selected, Settings selected and nobody joined. run_ui_theme_tests 227 checks pass (new: art slots, exact positions, both shadows, pointer shadow); run_ui_tests 505 keep only the two older `%Outcome1` / `%Final1` failures; p13_navigation 205, match_ui 196, fix_regression 9 and p13_accessibility 65 pass. gdformat / gdlint could not run (not installed on this PC). Not a human design review or physical-device test.
