# UI shells verification — 2026-10-14

Revision: base `17afb12` + uncommitted new UI files. Engine: Godot 4.7.2.stable.official.ed1daf0bf. Input: synthetic only (K1/K2 key events, one synthetic gamepad d-pad); no physical devices. Run against a clean `git archive HEAD` scratch copy plus the new UI files, because another session (P05) had uncommitted edits in the main checkout. Reviewer: automated; no human review claimed.

| Check | Result |
|---|---|
| Headless `--editor --quit` import, new scenes/resources | PASSED (no errors/warnings in filtered output) |
| `gdlint` / `gdformat --check` on `scripts/ui` and new tests | PASSED (0 problems) |
| `tests/run_ui_tests.gd` | PASSED: checks=437 failures=0 (`2026-10-14_ui_tests.txt`) |
| foundation / p02 83 / p02 wall 85 / p03 103 / p04 268 | PASSED, 0 failures (baseline counts unchanged) |
| `run_p04_interactive.gd` 25 | PASSED, 0 failures |
| Rendered captures: 12 screens x 1 and 4 players x 1280x720, 1920x1080, 1920x800 | PASSED: 72 PNGs in this folder; montage `montage_1280x720_4p.png` inspected |
| Gallery frame time at 1920x1080 (Play HUD, 4 players, 300 frames) | median 1.272 ms, p95 1.578 ms, worst 8.875 ms; 1917 objects, 72.8 MiB (budget 16.67 ms / 512 MiB; P04 baseline median 1.954 ms) |
| Windows export + exported headless startup of the gallery | COULD-NOT-RUN this session |
| Foundation-harness wiring, project-wide `gui/theme/custom` | NOT DONE: held until P05 lands (shared files) |
| Real editing by Shanti in the Godot editor | COULD-NOT-RUN: needs a human |

What the UI test covers: every screen/component loads and instantiates; documented `%Unique` nodes exist with the right class; no `.new()` of Controls or `add_theme_*` in `scripts/ui/`; every button has no Godot focus; 12 screens x all states x 1 and 4 players stay inside 1280x720 and use text >= 12 px; Play HUD bar is exactly 64 px at y 0; badges/slots show number + shape; K1 up/down/confirm drives Title with a single activation; K2 cannot drive a seat-1-owned menu; held press is consumed on a screen transition; K1 left/right adjusts Settings; a synthetic gamepad seat drives a menu it owns; a test texture in `Art_Circle` replaces the placeholder shape; a second Theme swaps in and layouts stay valid; 10 open/close cycles keep node count stable and add no orphans.

Known limitations: Library item text is clipped at 9 lines; the lobby state-0 capture shows empty slots; Pause live binding is display-only (menu selection is local); Title relies on the first seat joining via the ready key (decision D8) once wired.

Human 5-step checklist for Shanti (COULD-NOT-RUN): (1) open `ui_gallery.tscn` and press F6; (2) change a colour in `tilaok_theme.tres` and re-run; (3) move a node in `title_screen.tscn`; (4) assign a PNG to `Art_Logo`; (5) run again and confirm the change with no code edits.
