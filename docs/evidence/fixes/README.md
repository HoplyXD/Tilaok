# Fix evidence — October 16, 2026

Bug-fix round and ledge climb requested by Jorge on 2026-10-16. All runs are headless Godot 4.7.stable.official.5b4e0cb0f on Windows 11, `--fixed-fps 60`, synthetic keyboard input, working tree on `fec0d3f` with uncommitted changes. Reviewer: Claude (AI, automated). No human or physical-device review is claimed.

## What was fixed or added

| Report / request | Cause or change | Check |
|---|---|---|
| "Start local match ... only see the map" | Jorge's Cannon `Path2D` ran about 2700 wu past its barrel, beyond the stage, so the item catalog failed validation and the match could not build its rooms. Paths are now clamped to the stage size, lanes drawn to the edge are cut at the build region or a protected zone (`ItemGeometry.clip_to_stage`), and a block scene that still fails validation is skipped with a warning instead of breaking every block (`BlockCatalog.skipped`). | `run_fix_regression_tests.gd`, `run_blocks_tests.gd` (Cannon lane 960 wu from column 12) |
| "Pause is bugged and leave and return to lobby does not work" | Same root cause, plus the pause screen listed empty seats as "lost its controller". Only joined seats are listed now. Leave → Yes returns to the Lobby (the confirmation starts on No by design). | `run_fix_regression_tests.gd` (title → lobby, pause, resume, leave) |
| "Bombs don't explode recently placed blocks" | Explosives now also blow up placements made in the same Place phase inside their blast area. Those placements never appear, and their player sees "Blown up by P#'s Bomb". | `run_explosives_tests.gd` (23) |
| "Remove the first come first serve" | Confirm order no longer matters. Same-phase overlaps resolve in seat order; notices say only "Tile occupied" or "Invalid spot". | `run_place_claim_tests.gd` (14), `run_barya_tests.gd` (72) |
| "Add a ledge climb" | `ChickenController` climbs a wall-eligible ledge within reach of the head when the player holds toward the wall and there is room to stand. | `run_ledge_climb_tests.gd` (21), `run_tutorial_gate_tests.gd` (48) |
| "WASD player will have E and F as confirm" | K1 confirm, ready and claim accept E or F; the prompt glyph reads "E / F". | `run_controls_tests.gd` (13) |

## Ledge climb measurements (Item Lab, 64 wu grid)

- Four Kaing 1x1 cells stacked at column 5 make a wall whose top is at 704 wu (floor 960).
- With the ledge climb off, the same running jump peaks with the feet at 767.9 wu and lands back on the floor.
- With it on, holding toward the wall: one climb, then standing on top with the feet at 704.0 wu.
- No climb when a block leaves only 64 wu of headroom above the ledge, or when the player lets go of the wall direction.

## Test changes caused by the new rules

- `run_blocks_tests.gd`: the Cannon lane check expected the old 5-cell path. It now expects the clipped lane (build-region edge at x 1792, minus the barrel edge at x 832, giving 960 wu).
- `run_p04_tests.gd` T09 Kaing wall slide and kick: the chicken starts with its head above the 2x3 Kaing top. Holding toward the wall there now starts a ledge climb, so the first run of this session failed this row (3 P04 failures). The row now slides without holding toward the wall; wall slide never required that input. It passes: slid at the 240 wu/s cap, kicked away at −480 wu/s.

## Full headless regression

[2026-10-16_regression_summary.txt](2026-10-16_regression_summary.txt): every `run_*_tests.gd` suite except the windowed `*_interactive` ones. All pass except these failures, which were already present before this work:

- P04: 2 (mode flags row; empty item pool profile).
- P07 reset audit: 10 ("round N produced a new cumulative score result").
- Tutorial: 3 (Pugad copy with Barya text).
- UI: 4 (score award legend, award line, `%Outcome1` / `%Final1` UiScoreRow), present since the scoreboard merge.

The windowed suites (`run_p05_interactive`, `run_match_ui_interactive`) were not re-run for this round.

## Logs

- [ledge climb](2026-10-16_ledge_climb_tests.txt)
- [controls](2026-10-16_controls_tests.txt)
- [fix regression](2026-10-16_fix_regression_tests.txt)
- [blocks](2026-10-16_blocks_tests.txt)
- [explosives](2026-10-16_explosives_tests.txt)
- [place resolution](2026-10-16_place_claim_tests.txt)
- [Barya](2026-10-16_barya_tests.txt)
- [tutorial gate](2026-10-16_tutorial_gate_tests.txt)
- [P04 rows](2026-10-16_p04_wall_rows.txt)

Human feel review of the ledge climb, and physical keyboard checks of E / F, remain open (PHASETASK P02-T29).
