# P23 Kangaroo presentation slice — October 24, 2026

This is a scoped presentation extension to P23. Race mechanics, command selection, simulation timing, scoring, collision and terminal resolution were not changed. The scheduled P23 route uses the illustrated textures in `tilaok!/assets/events/kangaroo/`; P11 keeps the original diagnostic fallback. Generated source outputs and provenance are recorded in [ASSETS](../../ASSETS.md#p23-kangaroo-illustrated-presentation-derivatives--october-24-2026) and [AI_USAGE](../../AI_USAGE.md#kangaroo-presentation-illustration--october-24-2026).

## Asset and runtime map

| Element | Imported image dimensions | Runtime display / anchor |
|---|---:|---|
| Freeze top view / card icon | 451×1024 | Presenter 104×258 world units, center pivot; card 48×48, keep-aspect. |
| Rising outsole / card icon | 474×1024 | Presenter 104×258 world units, center pivot, inverted for outsole view; card 48×48, keep-aspect. |
| Hug side profile / card icon | 1024×327 | Presenter 252×80 world units, center pivot; card 48×48, keep-aspect. |
| Rising foam/surface strip | 1536×86 | Arena width × 48 world units; surface texture top placed 5 wu above the simulated line. The translucent body begins at that same simulated line; final marker remains separate. |
| Freeze sparkles | 251×256 | Sprite2D at `(18, -58)` with 0.14 scale; hidden outside the existing Freeze state. |
| Hug contact cue | 384×194 | 36×18 world units at each live contact midpoint, only while Hug is in RESPONSE. |

The slipper textures preload once. Telegraph descent, a 160 ms strike and a 420 ms recovery/fade read only the command's simulation timestamps; they do not call or adjust gameplay evaluation. The three portrait views share a center pivot and stable display dimensions; Hug uses its independently authored side profile. The command icons retain their text labels and timing ring.

## Technical checks

| Check | Result | Evidence / limit |
|---|---|---|
| Godot 4.7.2 headless editor import/parse | **PASSED** | `Godot_v4.7.2-stable_win64_console.exe --headless --path tilaok! --editor --import --quit`; all new image references imported. |
| Presentation resource/lifecycle smoke | **PASSED — 16 checks, 0 failures** | `run_kangaroo_presentation_tests.gd` on Godot 4.7.2: each command binds its own icon while retaining text/timing; Storm label absent; P23 presenter state is non-colliding/node-free; Freeze accent begins hidden, appears with Freeze, and clears on thaw. |
| P02 actor/movement/Freeze regression | **PASSED — 95 checks, 0 failures** | Godot 4.7.2. Includes existing Freeze lock/tint, gravity, forced motion, projectile, terminal and reset checks. The suite also reports pre-existing ObjectDB/resource-at-exit warnings. |
| P11 command/controller suite | **PASSED — 19 checks, 0 failures** | Godot 4.7.2. Confirms diagnostic/controller cadence, no normal Storm sequence and ten controller reset cycles. |
| P12 standalone scheduled-route suite | **PASSED — 57 checks, 0 failures** | Godot 4.7.2. Confirms the live scheduled route and sequential Kangaroo rules. Room fixtures emit a ScoreboardChart “no animation with name idle” engine error; no Kangaroo art-script error was observed after the UI-slot fix. |
| P13 HUD suite | **PASSED — 119 checks, 0 failures** | Godot 4.7.2 headless assertions passed. The same ScoreboardChart fixture error appears during room setup; it is outside this slice. |
| P12 legacy room-pairs suite | **FAILED — 273 checks, 59 failures** | Same result on Godot 4.6.3 and project Godot 4.7.2. This runner exercises retired U6/U9 and mixed-mode/Twist routes (K+L, K+Kg and Kg+L), with cascading stale-seat errors after setup failures. It is not the current standalone P23 acceptance route. Historical P12 baseline remains 285/285; that old baseline is not current-slice verification. |
| `gdformat --check` on six changed GDScript files | **PASSED** | All six files left unchanged by formatter. |
| `gdlint` on six changed GDScript files | **PASSED** | No lint problems. |
| `git diff --check` | **PASSED** | No whitespace errors. Git reports only existing CRLF-to-LF normalization warning for `kangaroo_main_round.gd`. |

## Windowed after captures

**PASSED — integrated scripted render, 4 seats, 1920×1080, muted and shake off**, captured with Godot 4.7.2 / OpenGL 3.3 on the current scheduled P23 route. The capture runner enters the real match room, then pauses room stepping and supplies one synthetic presentation row per command so each pose, icon, instruction and effect can be inspected in a stable frame. These are rendered presentation previews; they do not verify command evaluation, pause/resume behavior or the natural simulation-time waterline. No current P23 before capture exists, so a matching before/after comparison is **COULD-NOT-RUN**. Earlier P11/P13 captures are not a baseline.

- [Freeze — slipper, command card and chicken accent](after_1920x1080_4p_freeze.png)
- [Rising — outsole, card, water surface and final marker](after_1920x1080_4p_rising.png)
- [Hug — side pose, card and pair/chain cues](after_1920x1080_4p_hug.png)

The captures were visually inspected after integration. At this camera size, the three command icons and text are distinct; the wrapped Rising instruction remains fully visible; the dark outlined final-height marker reads against the sky. Four-seat readability at 1280×720 and minimum zoom, 2/3-seat layouts, and dynamic pose endpoints remain unchecked.

## Rendered and human checks

| Check | Result | Exact reason |
|---|---|---|
| Matching before/after captures | **COULD-NOT-RUN** | No current P23 before image exists. The three after captures are linked above; historical P11/P13 images are not a matching baseline. |
| 4-seat presentation at 1920×1080, static command previews, muted/shake-off settings | **PASSED** | Windowed integrated captures above show all three commands, Freeze accent, Rising surface/final marker and Hug chain cues under muted/off presentation settings. |
| 2/3-seat layouts; 1280×720; minimum zoom | **COULD-NOT-RUN** | Not included in the approved after-capture pass. |
| Dynamic pose timing/endpoints, clipping, exact natural wave/simulation alignment, Freeze/Hug pause/resume/clear | **COULD-NOT-RUN** | Static command previews do not prove animation endpoints, normal response timing, natural wave progression or lifecycle transitions. |
| Projectiles/platforms/hitboxes visibility, ten full room reset cycles, muted/shake-off command play | **COULD-NOT-RUN** | The captures are static synthetic previews and do not exercise hazards, full lifecycle resets or a command response with audio events. |
| Human art, cultural, novice-comprehension and performance approval | **NOT APPROVED / NOT MEASURED** | Team review and target-machine measurement remain open. |

The output assets were visually inspected individually before integration. That inspection is not a rendered before/after capture and does not count as human approval.
