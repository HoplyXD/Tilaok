# Map scenes and Lobby map selection — evidence (2026-10-16)

Build: HEAD `fec0d3f` plus the uncommitted map work; Godot 4.7.stable.official.5b4e0cb0f; Windows 11; headless `--fixed-fps 60` for tests and a 1920×1080 window for captures; synthetic seats. Reviewer: Claude (AI, automated). No human review or player session.

| File | What it shows | Result |
|---|---|---|
| [2026-10-16_maps_tests.txt](2026-10-16_maps_tests.txt) | `run_maps_tests.gd`, 27 checks (re-run after the follow-up below): <ul><li>catalog order (default first), cycling;</li><li>Sample Map = default stage (same collision rectangles, build region, spawn zone, flag, floor);</li><li>cell-to-rectangle merging and marker mapping on a code-built map;</li><li>a map with no Flag is rejected with a reason;</li><li>a saved drop-in map appears, a broken one is excluded and reported;</li><li>a real match on the map: Blocks layer shown, dev markers and debug tiles gone, a chicken stands on the generated floor;</li><li>Lobby D/A (K1) changes the map, rebuilds the room, keeps the seat, shows the name.</li></ul> | PASSED |
| [2026-10-16_maps_regression.txt](2026-10-16_maps_regression.txt) | Every headless suite | PASSED except four groups that fail identically on a clean HEAD checkout (listed in the file) |
| [2026-10-16_lobby_map_row_1080p.png](2026-10-16_lobby_map_row_1080p.png) | Lobby with "MAP ◀ Sample Map (2/2) ▶" (first version) | Rendered |
| [2026-10-16_tutorial_map_parity.txt](2026-10-16_tutorial_map_parity.txt) | The Tutorial map scene vs the verified tutorial layout it replaced: every field equal | PASSED |
| [2026-10-16_lobby_basic_map_1080p.png](2026-10-16_lobby_basic_map_1080p.png), [2026-10-16_basic_map_play_1080p.png](2026-10-16_basic_map_play_1080p.png) | the team's framed Basic Map in the Lobby and in Play | Rendered |
| [2026-10-16_sample_map_play_1080p.png](2026-10-16_sample_map_play_1080p.png) | Round 1 Play on the Sample Map (its Blocks layer, debug placeholder tiles) | Rendered |

Reproduce:

```powershell
& '<Godot 4.7 console exe>' --headless --fixed-fps 60 --path 'tilaok!' --script 'res://tests/run_maps_tests.gd'
& '<Godot 4.7 console exe>' --path 'tilaok!' --script 'res://tests/capture_maps_evidence.gd'
```

Limits: maps are the fixed 32×16-tile stage. The Blocks Sprite Sheet is still the chicken placeholder, so the Sample Map is painted with the debug tiles (Blocks TileSet source 1); repaint with source 0 once the block art exists.
