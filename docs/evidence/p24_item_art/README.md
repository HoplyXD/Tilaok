# P24 item art integration evidence — 2026-10-25

## Scope and source state

This records a headless technical check of AI-generated artwork integration for Bula-Bulaklak, Trumpo sa Riles and Parol Pulse. The checkout was on `main` at base revision `4f4b555e1d60b3e1deef10cd02bb44c6ed2fcf49` with unrelated local work already present. Godot wrapper: 4.6.3 stable (`7d41c59c4`). All test inputs were synthetic; no visible game was launched.

Eleven transparent PNG assets are imported under the three existing item-family asset folders. They are preloaded by the family `ItemVisualSet` resources. The painter is shared by runtime item drawing, `ItemEggPreview`, and the existing Library item preview path. SVG placeholders and all audio references remain in place. AI provenance, style references, retained originals and rejected variants are recorded in [ASSETS](../../ASSETS.md#three-item-families--generated-art-integration--2026-10-25) and [AI_USAGE](../../AI_USAGE.md#three-item-family-artwork-and-integration--october-25-2026).

## Results

| Check | Result | Evidence |
|---|---|---|
| Godot import/parse | PASSED | `godot-import-20261025.log`, headless editor import exited 0. |
| P24 item art resources and preview configurations | PASSED | `p24-item-art-tests.log`: 65 checks, 0 failures. Checks texture resource loads and dimensions, placeholder flags, unchanged audio placeholders, Bula 1×3/1×5 preview configs, Trumpo 4×1/5×1/6×1 at 0/90/180/270°, Parol 3–6-cell horizontal/vertical variants, and confirms art does not enable a release family. |
| P10 item/runtime regression | PASSED | `p10-item-regression.log`: 444 checks, 0 failures. Includes Bula capture/release, ceiling handling, ownership and cleanup; Trumpo sweep, movement, pauses, duration and rotation; Parol timing, blocker clipping, ownership, orientation; item previews and visual/audio slot gates. |
| P13 Library regression | PASSED | `p13-library-tests.log`: 425 checks, 0 failures. Exercises Library navigation and item entries; item art comes through the existing shared preview path. Godot emits a non-failing Forward+ volumetric fog availability warning in this headless run. |
| Named-file format/lint | PASSED | `gdformat --check` and `gdlint` passed for `item_silhouette_painter.gd`, `run_p10_tests.gd` and `run_p24_item_art_tests.gd`. |
| Diff whitespace check | PASSED | `git diff --check` exited 0. Git printed only existing line-ending normalization warnings. |
| Integrated rendered review and asset contact sheet | PARTIAL — PASSED | Permissioned runtime, Pugad, Library, matched placeholder-fallback/current-art images, three Parol-state captures and the eleven-asset sheet are recorded below. Human review remains separate. |
| Human art, creator, license and competition review | COULD-NOT-RUN | No human approval or provenance/eligibility determination is claimed. |

## Rendered showcase — 2026-10-25

The user approved the rendered check. Two windowed Godot 4.6.3/OpenGL 3.3 captures ran at 1920×1080 on an NVIDIA GeForce RTX 4050 Laptop GPU. The item showcase uses the Item Visualizer stage, one synthetic seat and real item behaviors. Bula's bubble captured a live `ChickenController`; the images freeze simulation after that real capture. Parol's inactive/charge/active stills set its presentation preview time while physics is frozen, so these show each art state without claiming their timing was measured by the capture. Trumpo remains a live moving piece in the showcase. The selection captures use the normal offline match UI, with a synthetic three-variant egg pool for Pugad; the Library image uses its actual screen and shared preview painter bound to the `items_lab` catalog so the unpromoted Bula item is visible.

| Capture | Result | Notes |
|---|---|---|
| `p24_in_game_before_placeholders.png` and `p24_in_game_active.png` | PASSED | Matched 1920×1080 scene and captured chicken; `p24_in_game_active.png` is refreshed with the simplified Tsinelas launcher art. The “before” image temporarily clears art textures to show the current painter's code fallback, not a binary from the earlier revision. |
| `p24_in_game_bula_capture_closeup.png` | PASSED | Real chicken held in the real bubble during a live Item Visualizer run. |
| `p24_in_game_inactive.png`, `p24_in_game_charge.png`, `p24_in_game_active.png` | PASSED | Same captured-chicken and moving-Trumpo scene; Parol's three visual states are shown separately. |
| `p24_pugad_egg_previews.png` | PASSED | Actual Pugad UI with Bula, Trumpo, Parol and Gulong previews; the tire preview now uses the same `assets/tiles/tire.png` texture as the placed Gulong. The egg pool was injected for this showcase. |
| `p24_library_bula_preview.png` | PASSED | Actual Library screen and Bula entry preview using `items_lab`; this does not enable the item for release. |
| `asset_contact_sheet.png` | PASSED | All eleven repository PNGs composed on light cards with System.Drawing; source artwork is unchanged. |
| `p24_tsinelas_launcher_charge.png` | PASSED | Windowed 1920×1080 showcase with the launcher behavior set to its charge preview; shows the matching charge sprite in-game. |

Capture console output is in `in_game_capture.log` and `selection_capture.log`; the setup and limits are summarized in their adjacent `*_manifest.md` files. The runner sources are `tilaok!/tests/capture_p24_item_art.gd` and `tilaok!/tests/capture_p24_selection_previews.gd`.

## Tsinelas Launcher art follow-up — 2026-10-25

The user asked for a simpler launcher sprite. Codex replaced the idle and charge placeholder textures with compact flat-color vector prototypes and moved the launcher lower in the showcase layout so it is fully visible. `p24_in_game_active.png` shows the launcher in the running Item Visualizer beside the live Trumpo, active Parol and captured Bula chicken; `p24_tsinelas_launcher_charge.png` shows its charge variant. The windowed Godot 4.6.3 capture exited 0 with `P24_IN_GAME_CAPTURE failures=0 captured_chicken=true`. Headless resource checks now include the two 64×64 launcher slots; P24 passed 198/198 and P10 passed 443/443. No gameplay or audio changes were made. Human art approval and provenance/competition review remain pending.

## Gulong Pugad preview alignment — 2026-10-25

The user reported that Gulong showed old artwork in Pugad while the placed item used the new hand-drawn tire. Both `body` and `body_compressed` slots in `move.tire_spring.tres` now point to the existing `assets/tiles/tire.png`, matching the scene sprite across the egg's animation states. The four-item windowed Pugad capture passed with `P24_SELECTION_CAPTURE failures=0`; it shows the updated tire inside its egg. The focused P24 suite passed 203/203, and P10 passed 443/443 after its placeholder-count assertion was updated for the replaced Gulong art slots. Godot import/parse passed. Logs are `gulong-pugad-capture.log`, `gulong-pugad-preview-tests.log` and `p10-gulong-preview-regression.log`. No art file or gameplay/audio behavior changed. Source confirmation and human art review remain pending.

The matched baseline is a same-scene code-fallback comparison, not a capture from the prior Git revision. The inspection is scripted, not a human play session. Creator confirmation, license/competition eligibility, cultural/art approval, physical-device review and performance remain unreviewed. P24-T08 stays unchecked for those remaining acceptance items. No gameplay timing, collision geometry, footprints, ownership, audio or effect lifecycles were intentionally changed. No commit or push was made.
