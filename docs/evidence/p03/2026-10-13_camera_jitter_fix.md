# P03 camera jitter investigation — 2026-10-13

- **Status:** PASSED
- **Build:** Desktop checkout at `9c46246` plus the camera/badge fix and regression checks in the working tree
- **Engine:** Godot 4.7.2 stable official `ed1daf0bf`
- **Renderer/device:** OpenGL 3.3 Compatibility, NVIDIA GeForce RTX 4050 Laptop GPU
- **Profile/seed:** `movement_room` / `12345`
- **Actors:** Two real `ChickenController` instances from `p03_stage_room.tscn`
- **Inputs:** Synthetic world-position assignments; no physical devices
- **Reviewer:** Codex ran the automated checks and inspected the rendered screenshots; no human review is claimed

## Cause and fix

The close-player layout had a proximity threshold: crossing 80 wu between the two actors changed badge offsets and shifted the camera target bounds vertically. Badges now stay anchored by seat, so actor separation does not change their layout.

A live easing probe exposed a second source of vertical drift. The camera computed a desired center with the HUD reservation applied, then passed its already-adjusted interpolated center through the target-position helper, which applied the reservation again on every frame. As zoom eased inward, this accumulated offset drove the camera to the arena's lower clamp. The easing path now interpolates and clamps a camera center directly; the HUD offset is applied only when fitting the target.

## Verification

Before the easing fix, the rendered diagnostic held both actors at y=300, allowed 1.5 seconds for zoom to settle, and measured desired camera y=268.1393 versus actual y=193.1833 at zoom 1.39978. This put the camera about 74.96 wu away from the target framing. An earlier frame-count-only comparison was discarded because it sampled while zoom was still settling.

After the fix, the visible 1920×1080 test moved actor 2 horizontally from x=478 to x=482 (pair separation 78→82 wu) while holding both actors at y=300:

| Measurement | Close | Apart | Result |
|---|---:|---:|---:|
| Expected camera Y | 268.1393 wu | 268.1426 wu | — |
| Actual camera Y | 268.1064 wu | 268.1384 wu | Each within 1 wu |
| Vertical movement | — | 0.0320 wu | Pass; limit 0.05 wu |
| Zoom | 1.39978 | 1.39998 | Within configured 1.0–1.4 range |

The automated P03 suite passed **103 checks, 0 failures**. The foundation suite passed with **0 failures**. `gdformat --check`, `gdlint`, and `git diff --check` passed. The focused deterministic easing test reports `camera_y=277.14`, expected `277.14`, at zoom 1.4, with the target visible.

## Evidence and reproducible commands

- [Rendered close spacing](2026-10-13_camera_jitter_fix_close_1080p.png)
- [Rendered apart spacing](2026-10-13_camera_jitter_fix_apart_1080p.png)
- [Visible-renderer run output](2026-10-13_camera_jitter_fix_render.txt)
- [P03 regression output](2026-10-13_camera_jitter_fix_p03_tests.txt)
- [Foundation regression output](2026-10-13_camera_jitter_fix_foundation_tests.txt)

Run the automated checks from the repository root:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p03_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_foundation_tests.gd'
```

Run the rendered pair-spacing capture in a visible Godot process:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p03_camera_jitter.gd'
```

The rendered check uses a temporary isolated copy because the desktop checkout was already open in Godot. It exercised the copied project sources, used synthetic positions, and captured actual OpenGL frames. This verifies the camera fixture; it is not a physical-controller playtest or final-art readability review.
