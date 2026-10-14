# 64 px grid, sneak/glide and stage blocks — evidence (2026-10-14)

Build: working tree on `19b3653`; Godot 4.7.stable.official.5b4e0cb0f (4.7.2 was not installed on this PC); Windows 11; profile `karera_slice` (Item Lab), seed 12345, 60 Hz; synthetic K1/K2 keyboard events; 1–2 seats. Reviewer: Claude (AI, automated). No human reviewer and no physical-device test.

| File | What it shows | Result |
|---|---|---|
| [2026-10-14_regression_summary.txt](2026-10-14_regression_summary.txt) | All eight headless suites at the 64 wu grid | PASSED — 1,173 checks, 0 failures |
| [2026-10-14_blocks_tests.txt](2026-10-14_blocks_tests.txt) | `run_blocks_tests.gd`: tiles, W/S mapping, W jump, sneak, glide, Solid/Box/Collapsing behavior | PASSED — 60 checks |
| [2026-10-14_lint.txt](2026-10-14_lint.txt) | gdformat --check and gdlint on every changed/new `.gd` file | PASSED |
| [2026-10-14_blocks_stage_sneak_glide_1080p.png](2026-10-14_blocks_stage_sneak_glide_1080p.png) | 64 px TileMapLayer stage, all three blocks, K1 sneaking (squashed), K2 gliding, six egg previews | Rendered |
| [2026-10-14_blocks_collapse_crumbling_1080p.png](2026-10-14_blocks_collapse_crumbling_1080p.png) | Collapsing block 1 s after a chicken lands on it | Rendered |
| [2026-10-14_blocks_collapse_gone_1080p.png](2026-10-14_blocks_collapse_gone_1080p.png) | Same block after 2 s: faded, no collision, chicken fell through | Rendered |

Reproduce from the repository root:

```powershell
& '<Godot 4.7 console exe>' --headless --path 'tilaok!' --script 'res://tests/run_blocks_tests.gd'
& '<Godot 4.7 console exe>' --path 'tilaok!' --script 'res://tests/capture_blocks_evidence.gd'
```

Open items: human feel/balance review of glide/sneak/push/collapse timings and physical keyboard/gamepad parity (PHASETASK P02-T26). Visuals are DEBUG placeholders (see ASSETS.md).

## Block scenes, Spikes, Cannon, stun and death sprite (2026-10-14, later the same day)

Build: working tree on `a9eb75f`; Godot 4.7.stable.official.5b4e0cb0f; headless `--fixed-fps 60`; synthetic input. Reviewer: Claude (AI, automated).

| File | What it shows | Result |
|---|---|---|
| [2026-10-14_block_scenes_regression.txt](2026-10-14_block_scenes_regression.txt) | All 21 headless suites after the migration | PASSED except 2 P04 checks that already failed on origin/main before this work |
| [2026-10-14_block_scenes_tests.txt](2026-10-14_block_scenes_tests.txt) | 110 checks: drop-in scene joins catalog/pool/eggs, Heavy anchor, Spikes kill + credit, standable flipped spikes, Cannon path/kill/cover, stun knockback/freeze/immunity, death sprite | PASSED |
| [2026-10-14_spikes_cannon_1080p.png](2026-10-14_spikes_cannon_1080p.png) | Upright and ceiling Spikes, Cannon ball in flight, stunned chicken, death pose, scene-visual eggs | Rendered |

