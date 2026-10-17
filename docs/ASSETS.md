# Tilaok! Asset, Licence, and Cultural Verification Register

**Status:** pre-production register. No production art or audio has been recorded in this repository yet. Since 2026-10-17 five third-party fonts (SIL OFL 1.1 / Apache 2.0) are registered in [Reference restyle fonts and placeholders](#reference-restyle-fonts-and-placeholders--2026-10-17); their final approval is still open. Do not treat this document as evidence that an asset has been created, licensed, or approved beyond what a row records.

## Asset policy

Every shipped asset must be one of the following:

1. made by a registered team member;
2. included with Godot under terms compatible with the entry; or
3. obtained under a documented licence that permits the intended competition, distribution, attribution, and modification use.

Do not use copied Ultimate Chicken Horse art, sounds, characters, names, interface elements, or code. The build-then-run structure is inspiration only; Tilaok!'s assets and presentation must be original.

Keep all deaths soft and comedic. Do not use gore, gambling or betting imagery, or material that could violate the competition's wholesome-content requirement.

## Register fields

Create one row per imported or shipped asset. Store licence text, purchase receipt, creator permission, or source-page capture outside the build and record its repository or team-storage location.

| Field | Record |
|---|---|
| Asset ID | Stable identifier, for example `art.chicken_base_01`. |
| Type | Sprite, tileset, UI icon, font, SFX, music, animation, VFX, or other. |
| Used in | Scene/screen/item/event where it appears. |
| Status | Planned, in progress, ready for review, approved, replaced, or removed. |
| Creator/source | Team member or direct source URL. |
| Licence/permission | Licence name, version, attribution wording, and proof location. |
| Modification | None, edited, recoloured, mixed, or derived under licence. |
| AI assistance | Tool, area, extent, and human edits; link to `AI_USAGE.md`. |
| Cultural review | Required/not required, reviewer, date, evidence, and outcome. |
| Final approval | Reviewer, date, and any required credits. |

## Planned asset groups

| Group | Required content | Ownership target | Status |
|---|---|---|---|
| Chickens | Base chicken, colour skins, number/shape identifiers, optional accessories. | Team-made. | Planned |
| Stage | Barrio environment, floor, base platforms, player-built geometry, background crowd. | Team-made or documented licensed sources. | Planned |
| First-batch items | Eight family sprites, tells, states, VFX, and placement ghosts. | Team-made. | Planned |
| Events | Lagsanay taya indicators, Kangaroo slipper poses, Rising wave, target line, Hug markers, Last Cluck result treatment. | Team-made. | Planned |
| UI | Menus, HUD, controls, icons, score/round cards, tutorial prompts, settings. | Team-made; any font must be logged. | Planned |
| Audio | Crowd reactions, rooster call, UI feedback, item/event tells, music. | Team-recorded or documented licensed sources. | Planned |
| Competition media | Logo, screenshots, trailer graphics/captions, poster if finalists. | Team-made or logged. | Planned |

## P11 debug-only placeholders and human replacement handoff

P11 contains no final production art or audio. These code-built stand-ins are labeled DEBUG in the running route and must be replaced/reviewed by the human art/audio team before any release decision.

| Asset ID / implementation | Kind and use | Provenance / status | Human handoff |
|---|---|---|---|
| `event.kangaroo.debug_pose` — `tilaok!/scripts/match/kangaroo_slipper_presenter.gd` | Code-drawn sole-down, sole-up and sideways slipper silhouettes; landing easing and target/wave lines. | Generated as programming/presentation code by OpenAI Codex for P11; no imported image or copied character. DEBUG placeholder, not production art. | Create original pose/landing art; review cultural framing and minimum-zoom visibility. |
| `event.kangaroo.debug_command_hud` — `tilaok!/scripts/match/p11_kangaroo_match_room.gd` | Text/icon/timing ring and KANG/GA/ROO marker presentation. | Code-built DEBUG layout; screenshot: [P11 1080p route capture](evidence/p11/p11_2p_command_hud_1920x1080.png). | Human UI/UX review for novice comprehension with muted audio and all shake settings; replace with final branded layout. |
| `event.kangaroo.debug_tones` — `p11_kangaroo_match_room.gd::_make_debug_tone` | Three short generated sine-wave cues tied to command type; simultaneous HUD cue is present. | AI-generated code creates transient tones at runtime; no audio file or production recording. DEBUG placeholder. | Record or commission original family-friendly cues, document rights/credits, and verify muted-audio parity. |

**Human acceptance still outstanding:** final pose art, production audio, novice comprehension/readability, Hiligaynon/native-speaker/cultural review, and balance review. No AI-generated final media was requested or added. Record final replacements, license/permission and approval here before release; update [AI_USAGE.md](AI_USAGE.md) and Form 03 preparation truthfully.

## Cultural verification ledger

Names, regional-language terms, history statements, and “Alam mo ba?” cards need native-speaker and evidence review before release. A visually Filipino motif alone does not establish a factual cultural claim.

| Subject | Current use | Verification required before final release |
|---|---|---|
| **Tilaok!** | Title and rooster-crow framing. | Spelling and presentation review. |
| **Pugad** | Nest/egg-selection phase. | Final copy review. |
| **Karera** | Default race Main Challenge. | Final copy review. |
| **Lagsanay** | Ilonggo tag event. | Native-speaker confirmation of wording and any explanatory copy. |
| **Laro ng lahi** | Event category/theme language. | Native-speaker confirmation of player-facing phrasing. |
| Item names | Filipino-themed item catalog and educational wording. | Name, regional relevance, and claim-by-claim evidence. |
| “Alam mo ba?” cards | Real-game explanation before an event. | Reliable source, concise reviewed claim, reviewer/date. |

Do not claim an item mechanic, Kangaroo variant, or proposed event is a faithful real-world traditional rule unless a reviewed source supports that exact claim. Use working-name language until approval.

## Audio direction and accessibility

The intended atmosphere is a wholesome interactive crowd: cheers, gasps, drumrolls, and a rooster call. Team-recorded crowd audio is preferred because it reduces licence risk.

Every gameplay-critical sound needs a simultaneous visual counterpart. Players must be able to understand item tells, Lagsanay state, Kangaroo commands, score results, and timers with audio muted.

Avoid rapid flashes. Screen shake is optional through full, reduced, and off settings. Audio should be suitable for a family-friendly public game-demonstration environment.

## AI disclosure linkage

AI assistance is allowed by the competition only when accurately disclosed. For every AI-assisted asset or asset-adjacent output, record:

- tool and date;
- what the tool contributed;
- extent of use;
- human editing and ownership review;
- licence/terms review where applicable;
- Form 03 entry reference.

`AI_USAGE.md` is the summary record for Form 03. This register is the asset-level evidence.

## Review gate before importing an asset

1. Add the asset to this register.
2. Verify source, licence/permission, and attribution requirements.
3. Check the content against competition and accessibility rules.
4. Obtain cultural review when the asset or copy makes a Filipino-language, regional, historical, or traditional-game claim.
5. Record AI assistance truthfully.
6. Approve the final in-game use and any required credits.

## Current open work

- Choose and document the final 2D art direction.
- Assign an asset-register owner.
- Identify a qualified native-speaker/cultural reviewer.
- Approve the project fonts registered on 2026-10-17 (licences recorded; Mountains of Christmas has an OFL/Apache discrepancy to note in credits) and confirm Filipino glyph coverage (ñ, accented vowels) during copy review.
- Decide whether music is team-made, commissioned, or licensed.
- Populate the register as soon as the first production asset is created or imported.

## Debug placeholders recorded — P04 (2026-10-13)

No production asset was created or imported in P04. The Item Lab and the Kaing/Tulay seeds use code-drawn graybox shapes drawn at runtime (crate cross-bracing, bamboo strip, dashed reservation, chevrons, ghost arrow and marks). They are labeled DEBUG on screen, were authored by AI-assisted programming under the standing programming workflow, and are placeholders only. They are not final art and must be replaced by team-made art.

| Placeholder | Used in | Status | Final owner |
|---|---|---|---|
| Code-drawn crate silhouette (`construction_piece.gd`) | Kaing pieces, Item Lab | Placeholder — replace | Jorge/Ivie |
| Code-drawn bamboo bridge silhouette and one-way arrow (`construction_piece.gd`, `item_ghost.gd`) | Tulay pieces and ghosts, Item Lab | Placeholder — replace | Jorge/Ivie |
| Placement validity marks and hatching (`item_ghost.gd`) | Ghost feedback | Placeholder — replace/restyle | Shanti (UI) |
| Code-drawn animated egg with item silhouette (`item_egg_preview.gd`) | Item Lab egg row, Library animation | Placeholder — replace | Jorge/Ivie (art), Shanti (UI) |
| Code-drawn Library panel and entry layout (`item_lab_room.gd`, `item_library_entry.gd`) | Item Lab Library button | Placeholder — P13 owns the real Library | Shanti (UI) |

Open follow-ups recorded 2026-10-13 (not code gates): original Kaing crate art/sound (Jorge/Ivie); original Tulay bridge art (Jorge/Ivie); cultural check of the names “kaing”, “tulay” and “kawayan” and of any copy (Compliance/cultural reviewer). No sound exists.

## Debug placeholders recorded — P05 (2026-10-14)

P05 added no production asset. Its lobby cards, animated/code-drawn egg previews, seat numbers/shapes, claim-loss retry cues, placement ghost outlines/reason marks, phase HUD and results shell are rendered with code and labeled DEBUG. The updated-main UI commit also contains an isolated code-drawn screen/component gallery; its sample-result resources are synthetic and are not connected to the P05 match or scoring system. They were generated as part of AI-assisted programming, remain placeholders, and need human art/UI replacement or review under the existing register gate. No final art, audio, font or external asset was generated/imported for P05.

| Placeholder | Used in | Status | Final owner |
|---|---|---|---|
| Code-drawn egg cards and exact-variant silhouettes | Pugad pool/claim and hatch handoff | DEBUG placeholder — replace | Jorge/Ivie (art), Shanti (UI) |
| Number/shape seat markers, claim-loss prompt and retry status | Lobby, Pugad and results | DEBUG placeholder — replace/restyle | Shanti (UI) |
| Placement ghost outline, footprint, guides and reason text | Place | DEBUG placeholder — replace/restyle | Shanti (UI), Jorge/Ivie (item art) |
| Phase HUD, hints and diagnostic results panel | P05 match shell | DEBUG placeholder — replace/restyle; result copy requires P06 binding | Shanti (UI) |

No human art review is claimed by the P05 implementation record. P05 capture screenshots document current behavior/readability only and are not approved production assets.

## Chicken sprite sheet (placeholder) — 2026-10-14

| Asset | Used in | Origin | Status |
|---|---|---|---|
| `tilaok!/assets/character/Chicken Placeholder Sprite Sheet.png` (2048×1024: 4 cols × 2 rows of 512×512 cells; 256×512 hitbox column per cell) and its `.clip` source | `scenes/characters/chicken.tscn` (all chickens in the P03-based rooms and the match) | Supplied by Art (Jorge/Ivie) on 2026-10-14; not AI-generated. Authorship/licence to be confirmed in this register by the team. | PLACEHOLDER — final chicken art replaces the sheet; frames are mapped per animation in the scene's SpriteFrames |

Cells: row 1 = idle, moving/wall-sliding right, moving/wall-sliding left, sneaking; row 2 = jump/glide still, jump/glide right, jump/glide left, (empty). Shown at ×0.25 (one cell = 128×128 wu = 2 tiles tall) and tinted by seat colour.

## Block scene visuals and death sprite — 2026-10-14

No production asset was created. Each block scene's `Visual` node (Polygon2D/Line2D/Label placeholders written by `tools/make_block_scenes.gd`; Solid/Wood/Collapsing visuals carried over from their earlier scenes) is a DEBUG placeholder for Jorge/Ivie to replace inside the scene. P10 hazards keep their existing PLACEHOLDER visual sets (`data/items/visual/`). The chicken death pose is the Art (Jorge/Ivie) sprite sheet cell row 2, column 4 (`assets/character/Chicken Placeholder Sprite Sheet.png`, supplied by the team, PLACEHOLDER). `assets/character/Blocks Sprite Sheet.png` is currently a copy of the chicken sheet and is not used by the game.

| Placeholder | Used in | Final owner |
|---|---|---|
| Spikes base + points, Cannon body/barrel/wheel and ball (`scenes/blocks/traps/`) | Spikes, Cannon | Jorge/Ivie (traps) |
| Kaing crate slats, Tulay strip (`scenes/blocks/construction/`) | Kaing, Tulay | Jorge/Ivie (obstacles) |

## Stage tiles and block placeholders recorded — 2026-10-14

No production asset was created or imported. The stage tile atlas is a flat three-colour image written by a code tool, and the block visuals are Polygon2D/Line2D/Label nodes authored in the block scenes. All are DEBUG placeholders for the art team to replace.

| Placeholder | Used in | Status | Final owner |
|---|---|---|---|
| `assets/tiles/debug_tiles_64.png` (3 flat 64×64 tiles: ground, boundary, platform; generated by `tools/make_debug_tiles.gd`) + `assets/tiles/debug_stage_tileset.tres` | `scenes/stage/stage_tiles.tscn` TileMapLayer | DEBUG placeholder — replace the atlas, keep the 64 px tile size | Jorge/Ivie (maps) |
| `Visual` nodes in `scenes/blocks/solid_block.tscn`, `wood_box.tscn`, `collapsing_block.tscn` | Solid Block, Wood Box, Collapsing Block | DEBUG placeholder — replace inside each scene's `Visual` node | Jorge/Ivie (obstacles) |
| Code-drawn egg silhouettes for the three blocks (`item_egg_preview.gd`) | Pugad eggs, Item Lab | DEBUG placeholder — replace | Jorge/Ivie, Shanti (UI) |

## Map editing tiles — 2026-10-16

| File | Used in | Status | Final owner |
|---|---|---|---|
| `assets/tiles/map_markers_64.png` + `map_markers_tileset.tres` (3 tiles: Spawn, Build Area, Flag; tint plus a shape identifier) | `DevMarkers` layer of map scenes; editor only, removed in the game | Dev tool; drawn by a one-off code generator, never shown to players | Jorge/Ivie (maps) |
| `assets/tiles/blocks_tileset.tres` | `Blocks` layer of map scenes | Source 0 is Art's (Jorge/Ivie) `Blocks Sprite Sheet.png`, still unfinished (it currently holds the chicken sheet), on a 64 px grid. Source 1 reuses the DEBUG `debug_tiles_64.png` until the block art is ready | Jorge/Ivie (maps) |

## UI shell placeholders recorded — UI shells (2026-10-14)

No production asset was created or imported. The UI uses flat Theme StyleBoxes, the engine default font and Polygon2D placeholder seat shapes, all labeled PLACEHOLDER. Final art is human-made and goes under `tilaok!/assets/ui/<screen>/`, named `ui.<screen>.<element>`, and is assigned to the matching `Art_<Element>` node. Register each file here before it ships.

| Placeholder | Used in | Status | Final owner |
|---|---|---|---|
| `assets/ui/theme/tilaok_theme.tres` (StyleBoxFlat set, engine default font) | all UI shells | Placeholder — restyle | Shanti (UI) |
| Polygon2D seat shapes in `player_badge.tscn` | player badge | Placeholder — replace via `Art_Circle/Triangle/Square/Diamond` | Shanti (UI), Jorge/Ivie |

Art slots (all empty; asset IDs): `ui.title.logo`, `ui.title.background`, `ui.lobby.slot_frame`, `ui.lobby.background`, `ui.tutorial.box_frame`, `ui.pugad.egg_frame`, `ui.place.legend_icons`, `ui.play_hud.bar`, `ui.round_result.card`, `ui.round_result.award_icon`, `ui.match_result.winner_banner`, `ui.pause.panel`, `ui.settings.panel`, `ui.library.panel`, `ui.library.entry_frame`, `ui.library.animation_frame`, `ui.events.taya_marker`, `ui.events.kang_pose`, `ui.common.shape_circle|triangle|square|diamond`, `ui.common.prompt_glyph`, `ui.common.countdown_ring`. The test texture used by `run_ui_tests.gd` is generated in memory and is not shipped content.

## Placeholders recorded — P10 (2026-10-14)

P10 added 23 **temporary placeholder** files so every first-batch item is visible and audible in the Item Visualizer and the match loop. They are original plain geometric SVG shapes and synthesized sine/square/noise tones written by `tilaok!/tools/generate_placeholder_assets.gd`; no third-party material, sample, font or UCH asset is used. **AI assistance:** Claude Code (Anthropic, Sonnet 5.5) wrote the generator and ran it; no human editing or art review has occurred. They are not final art/audio, are not team-made production assets, and are not presented as such; final assets are human-made (Jorge/Ivie art, Shanti audio). Each file is named `PLACEHOLDER_*`, every slot is flagged `placeholder = true` with its final owner, and `PlaceholderAudit.release_violations()` fails any family that is both `release_target` and `runtime_enabled` while it still uses one. Replacing a file by name needs no code or resource edit (verified: [swap probe](evidence/p10/swap_file_level_probe.txt)).

| File | Type | Slot | Status | Final owner |
|---|---|---|---|---|
| `assets/items/move.tire_spring/PLACEHOLDER_body.svg` | SVG | `body` | PLACEHOLDER — replace | Jorge/Ivie |
| `assets/items/move.tire_spring/PLACEHOLDER_body_compressed.svg` | SVG | `body_compressed` | PLACEHOLDER — replace | Jorge/Ivie |
| `assets/items/move.tire_spring/PLACEHOLDER_sfx_launch.wav` | WAV | `sfx_launch` | PLACEHOLDER — replace | Shanti |
| `assets/items/hazard.rail_trumpo/PLACEHOLDER_rail.svg` | SVG | `rail` | PLACEHOLDER — replace | Jorge/Ivie |
| `assets/items/hazard.rail_trumpo/PLACEHOLDER_top.svg` | SVG | `top` | PLACEHOLDER — replace | Jorge/Ivie |
| `assets/items/hazard.rail_trumpo/PLACEHOLDER_sfx_pause.wav` | WAV | `sfx_pause` | PLACEHOLDER — replace | Shanti |
| `assets/items/hazard.parol_pulse/PLACEHOLDER_post.svg` | SVG | `post` | PLACEHOLDER — replace | Jorge/Ivie |
| `assets/items/hazard.parol_pulse/PLACEHOLDER_beam_on.svg` | SVG | `beam_on` | PLACEHOLDER — replace | Jorge/Ivie |
| `assets/items/hazard.parol_pulse/PLACEHOLDER_sfx_charge.wav` | WAV | `sfx_charge` | PLACEHOLDER — replace | Shanti |
| `assets/items/hazard.parol_pulse/PLACEHOLDER_sfx_on.wav` | WAV | `sfx_on` | PLACEHOLDER — replace | Shanti |
| `assets/items/hazard.slipper_launcher/PLACEHOLDER_launcher.svg` | SVG | `launcher` | PLACEHOLDER — replace | Jorge/Ivie |
| `assets/items/hazard.slipper_launcher/PLACEHOLDER_launcher_charge.svg` | SVG | `launcher_charge` | PLACEHOLDER — replace | Jorge/Ivie |
| `assets/items/hazard.slipper_launcher/PLACEHOLDER_projectile.svg` | SVG | `projectile` | PLACEHOLDER — replace | Jorge/Ivie |
| `assets/items/hazard.slipper_launcher/PLACEHOLDER_sfx_charge.wav` | WAV | `sfx_charge` | PLACEHOLDER — replace | Shanti |
| `assets/items/hazard.slipper_launcher/PLACEHOLDER_sfx_fire.wav` | WAV | `sfx_fire` | PLACEHOLDER — replace | Shanti |
| `assets/items/utility.walis_cleanup/PLACEHOLDER_broom_outline.svg` | SVG | `broom_outline` | PLACEHOLDER — replace | Jorge/Ivie |
| `assets/items/utility.walis_cleanup/PLACEHOLDER_sfx_sweep.wav` | WAV | `sfx_sweep` | PLACEHOLDER — replace | Shanti |
| `assets/items/hazard.bubble_planter/PLACEHOLDER_pot.svg` | SVG | `pot` | PLACEHOLDER — replace | Jorge/Ivie |
| `assets/items/hazard.bubble_planter/PLACEHOLDER_bubble.svg` | SVG | `bubble` | PLACEHOLDER — replace | Jorge/Ivie |
| `assets/items/hazard.bubble_planter/PLACEHOLDER_captive_icon.svg` | SVG | `captive_icon` | PLACEHOLDER — replace | Jorge/Ivie |
| `assets/items/hazard.bubble_planter/PLACEHOLDER_sfx_emit.wav` | WAV | `sfx_emit` | PLACEHOLDER — replace | Shanti |
| `assets/items/hazard.bubble_planter/PLACEHOLDER_sfx_capture.wav` | WAV | `sfx_capture` | PLACEHOLDER — replace | Shanti |
| `assets/items/hazard.bubble_planter/PLACEHOLDER_sfx_pop.wav` | WAV | `sfx_pop` | PLACEHOLDER — replace | Shanti |

Open follow-ups (not gates): original art/audio for the six families; native-speaker and cultural review of the working names Gulong Talon, Trumpo sa Riles, Parol Pulse, Tsinelas Launcher, Walis Cleanup and Bula-Bulaklak, and of any educational copy.

## Results chart placeholders — October 15, 2026

The result screens reuse the team's existing chicken placeholder SpriteFrames through `tilaok!/assets/character/chicken_sprite_frames.tres`; the source sheet and sprite design were not generated or modified for this task. The new chart, column, legend, glyphs, layout and score award swatches are programming/UI presentation code, not production art. Theme swatches are provisional and editable for Shanti's review. The user-provided screenshot was used only for the broad shared-axis/player-column chart concept; its palette, typography, artwork, branding and complete screen arrangement were not copied. No external asset or font was added, so there is no new third-party licence entry. Human visual design and readability review remain open.

## Placeholders recorded — P13 (2026-10-15)

No final art, audio or font was generated or imported. Everything below is a development placeholder with a human owner for replacement.

| Item | Where | Kind | Status | Final owner |
|---|---|---|---|---|
| Spectator cheer cue | `SpectatorCheer.make_stream()` (code-generated 0.45 s noise + hum, plays on the **Crowd** bus) | audio placeholder, no file | PLACEHOLDER — replace with the recorded crowd "yay" (GDD §9) | Shanti |
| Kangaroo cue tones | `KangarooCommandStyle.make_tone()` (330 / 440 / 554 Hz sine, now on the **Effects** bus) | audio placeholder, no file | PLACEHOLDER — replace (P11 handoff unchanged) | Shanti |
| Audio bus layout | `tilaok!/default_bus_layout.tres` (Master, Music, Effects, Crowd) | engine resource | engine-authored; the mix is the audio owner's | Shanti |
| Kangaroo command cards and miss grid | `scenes/ui/components/kangaroo_hud.tscn`, `kangaroo_command_card.tscn` | UI scene, text icons `● ↑ ↔` | PLACEHOLDER wording and look; `Art_PoseIcon` slot is empty | Shanti (UI) / Jorge/Ivie (pose art) |
| Library copy | `tilaok!/data/ui/library_text.tres` | English text | PLACEHOLDER — needs Filipino / Hiligaynon and cultural review | team (native-speaker review) |
| Tutorial copy (Kangaroo, Bomb-Taya) | `tilaok!/data/ui/tutorial_script.tres` | English text | PLACEHOLDER — same review | team |
| UI font | engine default (Open Sans SemiBold) | font | engine-included; lacks `● ▲ ■ ◆ → ↑ ↔` (system fallback) — a final font that covers them is needed. **Superseded 2026-10-17** by the fonts in [Reference restyle fonts](#reference-restyle-fonts-and-placeholders--2026-10-17); the symbol glyphs still use the system fallback | Shanti |

Provenance: all of the above was generated or edited by AI-assisted programming under Francis and Carlos's direction and is disclosed in [AI_USAGE.md](AI_USAGE.md). Nothing is licensed from a third party.

## Barya DEBUG placeholder — 2026-10-15

The round coin and Pugad preview use code-drawn DEBUG geometry (gold coin disc, rim, letter B, and a small DEBUG label) implemented in `tilaok!/scripts/match/barya_coin.gd` and `tilaok!/scripts/items/item_egg_preview.gd`. No raster/vector art, audio file, font, third-party asset, or UCH material was added. The output is a temporary programming placeholder, not team-made production art.

| Placeholder | Used in | Status | Human handoff |
|---|---|---|---|
| `round_objective.barya.coin_1x1` DEBUG coin geometry | Pugad offer, placed/dropped coin, carrier attachment | DEBUG placeholder — replace | Jorge/Ivie (art); Shanti (UI cue) |
| DEBUG Barya egg silhouette | Pugad egg preview | DEBUG placeholder — replace | Jorge/Ivie (art); Shanti (UI cue) |

The live HUD uses text and a seat-number cue; no color-only identification is intended. Human art, contrast/minimum-zoom/accessibility review, native-speaker/cultural review and player comprehension are not yet performed. Keep this task in AI programming disclosure only; no AI-generated final art or audio is authorized or claimed. See the [scoped Barya activation record](evidence/barya/activation_contract_2026-10-15.md) and [engineering captures](evidence/barya/README.md#rendered-captures).

## Debug placeholders recorded — promoted P19 obstacles (2026-10-16)

| Asset ID / implementation | Kind and use | Provenance / status | Human handoff |
|---|---|---|---|
| `block.house_stairs.debug_visual` — `scenes/blocks/construction/hagdan_steps_2x2.tscn`, `hagdan_steps_3x3.tscn` | Brown stepped Polygon2D, outline and "STEPS • DEBUG" label | Scene nodes written by Claude (AI) at the user's request; no imported image. DEBUG placeholder. | Original house-step art (Jorge/Ivie); cultural check of the name "Hagdan ng Bahay". |
| `block.toy_burr_strip.debug_visual` — `scenes/blocks/traps/tinik_strip_3x1.tscn`, `tinik_strip_4x1.tscn` | Low green base with rounded burr bumps and "TINIK • DEBUG" label | Same provenance. DEBUG placeholder. | Soft, wholesome burr art (the contract requires a wholesome-art review before Lagsanay/Kangaroo); name check. |
| `block.sorbetes_ice.debug_visual` — `scenes/blocks/construction/yelo_ice_3x1.tscn`, `yelo_ice_4x1.tscn` | Pale-blue slab with frost marks and "ICE • DEBUG" label | Same provenance. DEBUG placeholder. | Original ice / sorbetero art; name check. |

## Reference restyle fonts and placeholders — 2026-10-17

The user supplied the font files and licence texts on 2026-10-17 (`C:\Users\omsha\Downloads\fonts`) and asked for Handlee to replace the Lemonade font used in the Figma design (Lemonade was not supplied and is not in the build). Only the files the UI uses were copied into `tilaok!/assets/fonts/`, each with its licence text; Mountains of Christmas Regular was supplied but not imported. Name-table data below was read from each file with Godot 4.7.2 (`FontFile.get_ot_name_strings()`). Files are unmodified (SHA-256 recorded). AI assistance: Claude Code copied and registered the files and wired them into the Theme; it did not create or edit any font.

| Asset ID | File | Type / used in | Creator / source | Licence and proof | Modification | Status |
|---|---|---|---|---|---|---|
| `font.handlee` | `assets/fonts/handlee/Handlee-Regular.ttf` (SHA-256 `9fa2f002…7eac5b`) | font; Theme default (body, buttons, legends) | Joe Prince / Admix Designs, v1.001; Google Fonts distribution | SIL OFL 1.1, Reserved Font Name "Handlee"; `assets/fonts/handlee/OFL.txt` | None | Imported — approval open |
| `font.margarine` | `assets/fonts/margarine/Margarine-Regular.ttf` (`53cc27f8…5b718b`) | font; headings, slot state, chips, HUD round line | Astigmatic (AOETI), v1.000; Google Fonts | SIL OFL 1.1, Reserved Font Name "Margarine"; `assets/fonts/margarine/OFL.txt` | None | Imported — approval open |
| `font.mountains_of_christmas_bold` | `assets/fonts/mountains_of_christmas/MountainsofChristmas-Bold.ttf` (`4b0e7a1f…50fed76`) | font; screen titles (Lobby, Paused, Round result, quit heading), Title logo text | Crystal Kluge / Tart Workshop (Font Diner), v1.003; Google Fonts | The supplied `LICENSE.txt` is Apache 2.0 (Google Fonts distributes this family under Apache 2.0); the font's own name table says SIL OFL 1.1 with Reserved Font Name "Mountains of Christmas". Both permit bundling in a game; keep both texts with the build and credit the font. | None | Imported — approval open; licence discrepancy noted |
| `font.mansalva` | `assets/fonts/mansalva/Mansalva-Regular.ttf` (`2050cf99…68d8568`) | font; handwritten captions (Pause subtitle, quit message, result headings) | Carolina Short / The Mansalva Project Authors, v2.112; Google Fonts | SIL OFL 1.1; `assets/fonts/mansalva/OFL.txt` (header year 2019, font says 2022) | None | Imported — approval open |
| `font.road_rage` | `assets/fonts/road_rage/RoadRage-Regular.ttf` (`d079b917…7eaaf3`) | font; prompt words (Ready / Help / Back) and key-caps | Robert E. Leuschke / The Road Rage Project Authors, v1.010; Google Fonts | SIL OFL 1.1; `assets/fonts/road_rage/OFL.txt` | None | Imported — approval open |

Cultural review: not required for the fonts themselves; Filipino/Hiligaynon copy must be checked for glyph coverage (ñ, accented vowels) during the existing copy review. Symbol glyphs `● ▲ ■ ◆ ◀ ▶ → ↑ ↔` still come from the system fallback font (unchanged from P13).

**Placeholders written for the restyle (programming, not production art).** All are scene nodes or Theme StyleBoxes written by Claude (AI) from the user-supplied reference PNGs; the PNGs themselves are the team's design exports and are not shipped (only downscaled side-by-side evidence JPGs are kept in `docs/evidence/ui-reference/`).

| Item | Where | Status | Human handoff |
|---|---|---|---|
| Plank button (flat fill, 2 px gradient outline ring, two rivet dots; Pressed inner frame and group shadow) | Theme `sb_plank*`, `PlankStroke*`, `PlankClip`, `PlankPressed*`, `RivetDisabled`, `plank_button.tscn` + `ui_plank_button.gd` | Since 2026-10-17 built from the exact values of Figma frame `16:434` "Button Variants" (Theme StyleBoxes and GradientTexture2D resources with the Figma stops, no image file; the frame's two rivet ellipse SVGs are reproduced as Theme circles of the same colours, not imported) | Shanti: wood-plank texture states via `ui.common.plank_button` if a textured look is wanted |
| Torn-paper panel and brown backing page | Theme `sb_paper`, `PaperBacking`; Pause and quit dialog `Decor/Backing` | PLACEHOLDER: straight edges, no grain or torn edge | Shanti: transparent torn-paper art via `ui.pause.panel`, `ui.title.quit_panel` |
| Rivet panel | Theme `sb_rivet_panel`, `Rivets` nodes in `confirm_dialog.tscn` | PLACEHOLDER approximation | Shanti: `ui.common.confirm_panel` |
| Vine divider | `vine_divider.tscn` `Placeholder` (Line2D + four leaf polygons) | Round result: replaced by the team's Figma vine (below), 2026-10-17. Pause and Leave-match dialog: still PLACEHOLDER | Shanti: confirm the same vine (brown) for Pause and the dialogs |
| Chalkboard frame | Theme `sb_chalkboard` | PLACEHOLDER (flat green, flat white frame) | Shanti: `ui.round_result.chalkboard` |
| Warm lobby backdrop | Theme `BackdropWarm` (GradientTexture2D in the Theme, no file) | PLACEHOLDER gradient sampled from the Lobby export | Shanti: `ui.lobby.background` |
| Menu icons (play, gear, book, leave) | not implemented | Missing | Shanti: icon set (button `icon` property) |

**Team art imported from the Figma file — 2026-10-17.** Read from frame `36:221` "Round Results" of the team Figma file "UI-Tilaok-" through the Figma MCP connector (asset download of layer `36:259` "Deco Line"). Claude Code copied the SVG into the project unchanged and assigned it in the scene; it did not create or edit the art. The frame's other SVGs (chart gridlines, countdown bar, seat symbols) are not shipped as files: the gridlines and bar are drawn by the chart and Theme from the frame's exact values, and the seat symbols differ from the owner-approved seat shapes/colours.

| Asset ID | File | Type / used in | Creator / source | Licence and proof | Modification | AI assistance | Status |
|---|---|---|---|---|---|---|---|
| `ui.common.vine_divider` | `assets/ui/common/ui.common.vine_divider.svg` (SHA-256 `45d281c9…888d369`; imported at `svg/scale=2.0`) | UI vector; Round result title vine (`Vine/Art_Vine`) | Team Figma file "UI-Tilaok-", layer "Deco Line" (node `36:259`); team designer to confirm authorship | Team-made (to confirm); Figma file history is the proof location | None | Download and placement only ([AI_USAGE](AI_USAGE.md#round-result-built-from-the-figma-frame--october-17-2026)) | Imported — creator confirmation and approval open |

## Pause screen built from the Figma frames — 2026-10-17

Read from frames `5:44` "Pause Menu" and `5:81` "Pause Menu (With Warning)" of the team Figma file "UI-Tilaok-" through the Figma MCP connector (design context, a read-only paint/effect dump, and asset downloads of `5:81` and the paper layer `5:67` at 2.7x). Claude Code copied the icon and vine files unchanged. It produced two files from the team's Figma renders: it recovered transparency on the paper export, which came back on white, and it measured the pills' glass look into an overlay. It did not draw or design any of the art. The backing grain is a Godot NoiseTexture2D in the Theme, set from the Figma noise values (no image file).

| Asset ID | File | Type / used in | Creator / source | Licence and proof | Modification | AI assistance | Status |
|---|---|---|---|---|---|---|---|
| `ui.pause.panel` | `assets/ui/pause/ui.pause.panel.png` (SHA-256 `74d14682…ae08f64`) | UI raster; Pause paper (`Decor/PaperArt/Art_Panel`, 9-slice) | Figma render of the team's layer `5:67` "Rectangle 11" (fill, drop shadow, TEXTURE and NOISE effects) | Team-made (to confirm); Figma file history | Transparency recovered from the white-backed export (round trip over white within 4/255) | Export, transparency recovery and placement ([AI_USAGE](AI_USAGE.md#pause-screen-built-from-the-figma-frames--october-17-2026)) | Imported — creator confirmation open |
| `ui.pause.pill_glass` | `assets/ui/pause/ui.pause.pill_glass.png` (SHA-256 `3f76abf9…d0cc7bd`) | UI raster; white highlight overlay on every Pause pill and the reclaim pill (9-slice) | Measured from the Figma 2.7x render of pill `5:256` (the team's GLASS effects) | Team-made design (to confirm) | Derived: per-pixel highlight alpha = (render − fill) / (white − fill) | Derivation script and placement (same entry) | Imported — creator confirmation open |
| `ui.pause.vine` | `assets/ui/pause/ui.pause.vine.svg` (SHA-256 `27b32379…7fbf214`; `svg/scale=3.0`) | UI vector; Pause title vine | Team Figma layer "Deco Line" (`5:245`) | Team-made (to confirm) | None | Download and placement only | Imported — creator confirmation open |
| `ui.pause.icon_resume` / `icon_settings` / `icon_library` | `ui.pause.icon_resume.png` (`163228f7…5c16f8e`), `ui.pause.icon_settings.png` (`5b02065a…9ca5f15`), `ui.pause.icon_library.png` (`bc672427…3df1cda`) (300 × 300, mipmaps on) | UI raster icons on the Resume / Settings / Library planks | Image fills placed in the Figma frame (`15:77`, `15:80`, `15:83`) | **Unknown — source and licence to confirm before release** | None | Download and placement only | Imported — provenance open |
| `ui.pause.icon_leave` | `assets/ui/pause/ui.pause.icon_leave.svg` (`9d15b123…e69ca10`; `svg/scale=4.0`) | UI vector; Leave Match plank icon | Iconoir "transition-left-solid" (via the Figma frame, node `15:89`) | MIT, © 2021 Luca Burgio; `assets/ui/pause/ICONOIR_LICENSE.txt` (`869b60da…2eb4fa2`, upstream LICENSE) | None | Download and placement only | Imported — third-party, licensed |

## Round result effects pass — 2026-10-17

Read from frame `36:221` "Round Results" through the Figma MCP connector: a read-only paint and effect dump plus a 2.7x render and SVG download. The board grain is the Theme's existing NoiseTexture2D (`ChalkGrain`, set from the Figma noise values), with no image file.

| Asset ID | File | Type / used in | Creator / source | Licence and proof | Modification | AI assistance | Status |
|---|---|---|---|---|---|---|---|
| `ui.round_result.countdown_fill` | `assets/ui/round_result/ui.round_result.countdown_fill.svg` (SHA-256 `87ec215d…456a011`; `svg/scale=1.8`) | UI vector; Round result countdown fill (`CountdownBar` fill StyleBoxTexture) | Team Figma layer "Time remaining bar" (`50:7`) | Team-made (to confirm); Figma file history | Only the fill path and its gradient kept, moved to the origin (shape and stops unchanged) | Download, crop and placement ([AI_USAGE](AI_USAGE.md#round-result-effects-pass--october-17-2026)) | Imported — creator confirmation open |
