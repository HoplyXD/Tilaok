# Results scoreboard evidence — 2026-10-15

Godot 4.7.2.stable.official.ed1daf0bf on Windows. The scoreboard was verified as a presentation-only chart over exact integer eighth-point units. No score values or winner rules changed.

## Rendered captures

`capture_scoreboard_evidence.gd` uses the actual Round result and Match result scenes with synthetic view-model fixtures. Each image was rendered in a Godot `SubViewport` at its named size; these are engineering fixtures, not screenshots of a human play session.

| Capture | Coverage |
|---|---|
| [02_player_mixed_awards_1280x720.png](02_player_mixed_awards_1280x720.png) | Two players, mixed award segments, mid-reveal at the 1280×720 minimum. |
| [03_player_placement_1920x800.png](03_player_placement_1920x800.png) | Three joined seats in stable, noncontiguous seat order; placement awards and wide aspect ratio. |
| [04_player_no_score_1280x720.png](04_player_no_score_1280x720.png) | Four zero-score columns on neutral perches and visible suppression explanation. |
| [fractional_eighths_1920x800.png](fractional_eighths_1920x800.png) | Exact fractional placement units; narrow segments retain their exact height. |
| [mid_reveal_1920x800.png](mid_reveal_1920x800.png) | Parallel player timelines during award reveal. |
| [settled_1920x800.png](settled_1920x800.png) | Settled mixed-award stack, exact total and delta labels. |
| [reduced_motion_1280x720.png](reduced_motion_1280x720.png) | Reduced motion places the chart at its final height immediately. |
| [four_player_above_target_1920x1080.png](four_player_above_target_1920x1080.png) | Four varied totals; one exceeds the target, while the target line stays at 10 points. |
| [round_12_winner_below_target_1920x1080.png](round_12_winner_below_target_1920x1080.png) | Round-12 winner at 9.625 points remains below the 10-point target line. |
| [tied_sudden_death_winner_callout_1280x720.png](tied_sudden_death_winner_callout_1280x720.png) | Equal-height tied leaders with an explicit Last Cluck winner callout at 1280×720. |

The renderer output is recorded in [scoreboard_capture_run.txt](scoreboard_capture_run.txt). The test runner is [capture_scoreboard_evidence.gd](../../../tilaok!/tests/capture_scoreboard_evidence.gd).

## Automated verification

Exact command summaries from Godot 4.7.2 are in [focused_tests.txt](focused_tests.txt):

| Suite | Checks | Result |
|---|---:|---|
| Scoreboard chart/history/reveal/resize/teardown | 52 | PASS |
| Live results binding, including noncontiguous awards and snapshot isolation | 185 | PASS |
| UI flow and screen ownership | 198 | PASS |
| P08/P09 result presentation integration | 62 | PASS |
| P06 scoring | 97 | PASS |
| P08 Lagsanay | 86 | PASS |
| P09 lifecycle | 77 | PASS |
| P11 Kangaroo | 78 | PASS |

The rendered P06/P08/P09/P11 interactive routes also completed successfully: P06 17 checks, P08 87, P09 108, P11 85. Their existing evidence folders hold the corresponding GUI captures and reports. Synthetic seat/input fixtures were used; no physical controller or independent human readability review is claimed.

`gdformat` and `gdlint` passed for all changed GDScript. Godot 4.7.2 editor import/class registration completed without parse/import errors. A Windows Desktop release export and a 20-frame headless startup of that export both exited 0. Final `git diff --check`, format/lint, import and export-startup results are recorded in [delivery_checks.txt](delivery_checks.txt).

The older P06 interactive runner initially stalled when launched headless; it was rerun with the rendered Godot executable and completed with 17 checks and three 1920×1080 captures. The headless attempt is not counted as a pass.

## Visual review limits

The chart uses the Tilaok Theme's editable provisional award swatches, the current dark teal surfaces, and the existing chicken placeholder SpriteFrames. Each award also has a text label and glyph; each player retains a number and shape. Only the generic shared-axis and player-column chart concept was taken from the user reference. Its palette, artwork, typography, decoration, branding and screen arrangement were not copied. Final art, player comprehension, physical-device checks and the larger P13 HUD/tutorial/accessibility review remain open.
