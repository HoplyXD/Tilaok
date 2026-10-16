# Four keyboard layouts, clickable map row, Place block preview, Library Back — evidence (2026-10-16)

Build: HEAD `fec0d3f` plus uncommitted work; Godot 4.7.stable.official.5b4e0cb0f; Windows 11; headless `--fixed-fps 60` for tests and a 1920×1080 window for captures; synthetic keys and mouse events. Reviewer: Claude (AI, automated). No physical keyboard rollover test and no human review.

| File | What it shows | Result |
|---|---|---|
| [2026-10-16_controls_tests.txt](2026-10-16_controls_tests.txt) | `run_controls_tests.gd`, 13 checks: <ul><li>all four layouts map confirm, rotate, move, jump and ready to their own keys, and F no longer confirms;</li><li>seats follow join order (numpad joined first is P1);</li><li>every action has prompts for all five devices;</li><li>the Place ghost shows the block itself, rotates with R and swaps when the block changes;</li><li>real mouse clicks on the Lobby ◀ ▶ change the map;</li><li>a click on the Library Back button leaves.</li></ul> | PASSED |
| [2026-10-16_regression.txt](2026-10-16_regression.txt) | Every headless suite, plus the windowed match-UI and P05 interactive suites | PASSED except four groups that fail identically on a clean HEAD checkout (listed in the file) |
| [2026-10-16_lobby_four_keyboards_map_row_1080p.png](2026-10-16_lobby_four_keyboards_map_row_1080p.png) | Lobby with WASD / IJKL / arrows / numpad seats and the clickable map arrows | Rendered |
| [2026-10-16_place_block_previews_1080p.png](2026-10-16_place_block_previews_1080p.png) | Place ghosts showing Spikes at 90°, Cannon at 180°, Tulay at 0° and Bomb at 0°, each with its facing arrow, name and angle | Rendered |

Also changed so the suites match the new controls:
- Test key presses moved from F to E for WASD.
- The P13 Library check expects the new keyboard names.
- The P05 interactive check counts one-use eggs (Bomb, Dynamite, Nuke) as resolved edits, not pieces. That check had failed since the explosives were added.

Open:
- Four players on one physical keyboard depends on its key rollover. Use the key-chord recorder chords C25–C31 on the target keyboard.
- Human readability review of the ghost previews.
