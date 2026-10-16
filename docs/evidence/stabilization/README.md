# Stabilization evidence — October 16, 2026

Headless Godot 4.7.stable.official.5b4e0cb0f, Windows 11, `--fixed-fps 60`, synthetic seats, working tree on `fec0d3f` plus uncommitted changes. Reviewer: Claude (AI, automated). No human or physical-device review is claimed.

The goal is that the freeze manifest ([RELEASE_MANIFEST_DRAFT](../../RELEASE_MANIFEST_DRAFT.md)) starts from a known test state. Before this pass the headless regression had 17 failures that predated the day's work: P07 reset audit 10, tutorial 3, UI 4. Each one was classified as below.

| Suite | Failures | Cause | Fix | Now |
|---|---|---|---|---|
| `run_p07_reset_audit.gd` | 10 | **Stale test.** It put both chickens on the flag every round, and since the all-finish rule (GDD §5, `c1eaa9b`) such a round scores 0, so the "new score each round" check failed. Fixing that exposed a second test artifact: the audit ran Pugad, Place and Play in one frame, so the goal area still listed last round's finisher, who had already been moved back to spawn. In real play these phases take seconds of physics. | One finisher per round (alternating seats, 0.05 s post-finish deadline) and two physics steps after each reset. | 172/172; totals climb 14 → 70 / 70 over ten resets ([log](2026-10-16_p07_reset_audit.txt)) |
| `run_tutorial_tests.gd` | 3 | **Game issue (onboarding).** When a Barya egg was dealt, the Pugad coach showed only the Barya note, hiding the claim key, the timer and the claimed/lost feedback. | `TutorialCoordinator._pugad_variant` puts claim feedback first, and the Barya copy in `tutorial_script.tres` now repeats the claim key and timer. | 142/142 ([log](2026-10-16_tutorial_tests.txt)); P13 tutorial 58/58 ([log](2026-10-16_p13_tutorial_tests.txt)) |
| `run_ui_tests.gd` | 4 | Francis's results scoreboard chart (`d930bd1`): two scripts build layout in code against the UI handoff rule, and the result screens no longer have `%Outcome1` / `%Final1` rows. | **Not changed**; this is the UI owner's decision. Recorded in the manifest's defect table. | 466/470 (4 open) |

Suites re-run after the tutorial change, all passing:
- P13 HUD 265 ([log](2026-10-16_p13_hud_tests.txt))
- P13 navigation 205 ([log](2026-10-16_p13_navigation_tests.txt))
- P13 accessibility 65 ([log](2026-10-16_p13_accessibility_tests.txt))
- fix regression 9 ([log](2026-10-16_fix_regression_tests.txt))
- match UI 190 ([log](2026-10-16_match_ui_tests.txt))
- Barya 72 ([log](2026-10-16_barya_tests.txt))

The rest of the headless regression is unchanged from the [integration run](../integration/2026-10-16_regression_summary.txt). The windowed `*_interactive` suites were not run.

**Export check:** `%APPDATA%/Godot/export_templates` is empty for 4.7.stable, so no current export build was attempted (P16-T03 BLOCKED).
