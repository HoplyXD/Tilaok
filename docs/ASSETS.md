# Tilaok! Asset, Licence, and Cultural Verification Register

**Status:** pre-production register. No production art, audio, fonts, or third-party assets have been recorded in this repository yet. Do not treat this document as evidence that an asset has been created, licensed, or approved.

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
- Select the project font and confirm its distribution licence.
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
| `tilaok!/assets/character/Chicken Placeholder Sprite Sheet.png` (2048×1024: 4 cols × 2 rows of 512×512 cells; 256×512 hitbox column per cell) and its `.clip` source | `scenes/characters/chicken.tscn` (all chickens in the P03-based rooms and the match) | Supplied by Jorge (maps/characters role) on 2026-10-14; not AI-generated. Authorship/licence to be confirmed in this register by the team. | PLACEHOLDER — final chicken art replaces the sheet; frames are mapped per animation in the scene's SpriteFrames |

Cells: row 1 = idle, moving/wall-sliding right, moving/wall-sliding left, sneaking; row 2 = jump/glide still, jump/glide right, jump/glide left, (empty). Shown at ×0.25 (one cell = 128×128 wu = 2 tiles tall) and tinted by seat colour.

## Block scene visuals and death sprite — 2026-10-14

No production asset was created. Each block scene's `Visual` node (Polygon2D/Line2D/Label placeholders written by `tools/make_block_scenes.gd`; Solid/Wood/Collapsing visuals carried over from their earlier scenes) is a DEBUG placeholder for Jorge/Ivie to replace inside the scene. P10 hazards keep their existing PLACEHOLDER visual sets (`data/items/visual/`). The chicken death pose is Jorge's sprite sheet cell row 2, column 4 (`assets/character/Chicken Placeholder Sprite Sheet.png`, supplied by Jorge, PLACEHOLDER). `assets/character/Blocks Sprite Sheet.png` is currently a copy of the chicken sheet and is not used by the game.

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
| Kangaroo command cards and miss grid | `scenes/ui/components/kangaroo_hud.tscn`, `kangaroo_command_card.tscn` | UI scene, text icons `● ↑ ↔` | PLACEHOLDER wording and look; `Art_PoseIcon` slot is empty | Shanti (UI) / Jorge, Ivie (pose art) |
| Library copy | `tilaok!/data/ui/library_text.tres` | English text | PLACEHOLDER — needs Filipino / Hiligaynon and cultural review | team (native-speaker review) |
| Tutorial copy (Kangaroo, Bomb-Taya) | `tilaok!/data/ui/tutorial_script.tres` | English text | PLACEHOLDER — same review | team |
| UI font | engine default (Open Sans SemiBold) | font | engine-included; lacks `● ▲ ■ ◆ → ↑ ↔` (system fallback) — a final font that covers them is needed | Shanti |

Provenance: all of the above was generated or edited by AI-assisted programming under Francis and Carlos's direction and is disclosed in [AI_USAGE.md](AI_USAGE.md). Nothing is licensed from a third party.

## Barya DEBUG placeholder — 2026-10-15

The round coin and Pugad preview use code-drawn DEBUG geometry (gold coin disc, rim, letter B, and a small DEBUG label) implemented in `tilaok!/scripts/match/barya_coin.gd` and `tilaok!/scripts/items/item_egg_preview.gd`. No raster/vector art, audio file, font, third-party asset, or UCH material was added. The output is a temporary programming placeholder, not team-made production art.

| Placeholder | Used in | Status | Human handoff |
|---|---|---|---|
| `round_objective.barya.coin_1x1` DEBUG coin geometry | Pugad offer, placed/dropped coin, carrier attachment | DEBUG placeholder — replace | Jorge/Ivie (art); Shanti (UI cue) |
| DEBUG Barya egg silhouette | Pugad egg preview | DEBUG placeholder — replace | Jorge/Ivie (art); Shanti (UI cue) |

The live HUD uses text and a seat-number cue; no color-only identification is intended. Human art, contrast/minimum-zoom/accessibility review, native-speaker/cultural review and player comprehension are not yet performed. Keep this task in AI programming disclosure only; no AI-generated final art or audio is authorized or claimed. See the [scoped Barya activation record](evidence/barya/activation_contract_2026-10-15.md) and [engineering captures](evidence/barya/README.md#rendered-captures).
