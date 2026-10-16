# Reference UI restyle — evidence (2026-10-17)

Engineering evidence for [P13-T15…T18](../../PHASETASK.md#p13-reference-ui-restyle--approved-2026-10-17-required-presentation-slice). Design source: nine PNG exports of the team Figma file "UI-Tilaok-" supplied by the user (not committed; the side-by-side JPGs below contain downscaled copies for comparison only). Decisions, components and deviations: [UI_HANDOFF](../../UI_HANDOFF.md#reference-restyle-from-the-figma-screens--2026-10-17). Fonts and placeholders: [ASSETS](../../ASSETS.md#reference-restyle-fonts-and-placeholders--2026-10-17).

| Field | Record |
|---|---|
| Build | `main` at `d837e7b` plus the restyle change set; delivered by the restyle commits on `main` directly after `d837e7b` (see `git log -- docs/evidence/ui-reference`) |
| Engine | Godot 4.7.2.stable.official (`C:\Godot\Godot_v4.7.2-stable_win64_console.exe`), Compatibility renderer |
| Machine | Windows 11 Pro · AMD Ryzen 5 5500 · AMD Radeon RX 580 2048SP · 1920×1080 at 144 Hz |
| Date | 2026-10-17 |
| Input | SAMPLE gallery seats (1–4 players) and synthetic keyboard / gamepad events; no physical controller |
| Reviewer | engineering run (AI-assisted, Claude Code); no human reviewer |

## Checks

Full log: [delivery_checks.txt](delivery_checks.txt).

| Check | Procedure | Expected | Actual | Result |
|---|---|---|---|---|
| Baseline | 11 UI-related suites on `d837e7b` before any change | record the starting state | 10 suites 0 failures; `run_ui_tests` 470 checks, 4 failures (legend / award-line source rule, stale `%Outcome1`, stale `%Final1`) | recorded |
| Import / parse | `Godot --headless --path tilaok! --import` | no parse or import error | none; five fonts imported | PASSED |
| New theme / component suite | `run_ui_theme_tests.gd` | tokens, fonts + licences, plank, chip, pill, both dialogs, open-slot preview, component sheet | 87 checks, 0 failures | PASSED |
| Full headless regression | all 41 `run_*_tests.gd` suites (40 existing + 1 new); `--fixed-fps 60` where the suite documents it | no new failure | 5,212 counted checks plus the foundation harness: every suite 0 failures except `run_ui_tests` 487 checks, 2 failures = the two stale contract entries already failing on the baseline (2 baseline failures fixed) | PASSED (2 pre-existing failures unchanged) |
| Round result fit | `run_p13_hud_tests.gd` (Kangaroo + Bomb-Taya 4p results) and a worst-case probe (10 award rows / 6 explained rows, long deadline, notice, next round, twist) | title, Ready hint and countdown inside 720 px | first run FAILED (title at y −18.5, countdown bottom 751.5); fixed (smaller award badges, 16/24 px award and heading text, 46 px title, footer ratio); re-run 265 checks, 0 failures; probe content 627 / 677 px of 700 | PASSED after fix |
| Live flow (windowed) | `run_match_ui_interactive.gd`, `run_p09_interactive.gd` in an isolated project copy | live Title → Lobby → Pugad → Place → Play → Results → Pause → Leave confirm → Lobby → Title; lifecycle Quit / Leave confirmations | 59 / 0 and 108 / 0 | PASSED |
| Focus navigation | `run_p13_navigation_tests.gd` (K1, K2, synthetic gamepad) + confirm-dialog checks in `run_ui_theme_tests.gd` | every route, Up/Down and Left/Right on Yes/No, No preselected | 205 / 0; dialog checks pass | PASSED (synthetic; no physical controller) |
| Canvas / text size | `run_ui_tests.gd` gallery sweep: every screen × state at 1 and 4 players | inside 1280×720, text ≥ 12 px, HUD bar exactly 64 px | all pass | PASSED |
| Cleanup | `run_ui_tests.gd` 10 open/close cycles of all 13 gallery screens | node count stable, no new orphans | stable, 0 new orphans | PASSED |
| Lint / format | gdformat / gdlint | clean | not installed on this PC (no Python); manual scan: no line > 100 columns, no trailing whitespace | COULD-NOT-RUN |
| Export smoke | `--export-debug "Windows Desktop"`, then the console exe `--headless --quit-after 120` | export and startup succeed | exit 0 / exit 0, `TILAOK_FLOW_READY state=title` | PASSED |

## Rendered comparisons (1920×1080, reference left, build right)

Produced by `tests/capture_ui_reference_evidence.gd` (windowed; `-- --reference-dir=<PNG folder>`). Raw renders are `<screen>_s<state>_<players>p.png`; pairs are `*_vs_reference.jpg`.

| Screen | Renders | Reference | Deviations (reason) |
|---|---|---|---|
| Lobby | `lobby_s0_4p` (nobody joined), `lobby_s2_2p`, `lobby_s3_3p`, `lobby_s3_4p`, `lobby_s4_4p` (device lost) | Lobby.png | Seat shapes/colours stay the code's (owner decision: P3 square, P4 diamond, gold/blue/coral/green); the ready card gets a thick green border plus "Ready" text (the reference shows no ready state); the join line names all four keyboard layouts and South (four-keyboard support); key-caps show the device's real key ("E/F"); the open-slot preview is faded; PLACEHOLDER tag kept. |
| Play HUD | `play_hud_s0_2p/3p/4p`, `play_hud_s1_4p` (Twist), `play_hud_s2_4p` (Taya) | Obstacle Place.png (top bar) | Chip state words come from the live HUD (RUN / SAFE / OUT / TAYA) rather than "Placed"; the race clock stays text at the right; the Guide card belongs to Place, not the HUD. |
| Place | `place_s0_2p/4p`, `place_s1_4p` (blocked), `place_s2_4p`, `place_s3_4p` | Obstacle Place.png | The Guide card sits at the top of the right column below the 64 px HUD (the reference overlaps the HUD bar); status pills keep `[OK]/[X]/[LOCK]/[NO TURN]/[SET]` and the existing wording so colour is never the only cue; the timer is the shared countdown bar with its seconds number. |
| Round result | `round_result_s0_2p/3p/4p`, `s1_4p` (nobody finished), `s2_4p` (everybody finished) | Round Results.png | Title is the live "Round N result"; the chart is the existing scoreboard (chickens, stacked award segments, target line) on the chalkboard; Score Legend in two columns so ten award rows fit at 1280×720; flat chalk and frame (no texture); vine is a fixed-length placeholder. |
| Pause | `pause_s0_2p/3p/4p`, `pause_s3_4p` (lost controller) | Pause Menu.png, Pause Menu (With Warning).png | Pills keep READY / WAITING / DEVICE LOST (resume rule); owner line and reason kept; "Ready / Resume" wording kept; straight paper edges, no grain, no button icons (team art needed); the lost-controller message is a separate maroon pill under the roster. |
| Leave match | `pause_s4_4p` | Leave Match Confirmation.png | Copy "Leave the match and return to the lobby?" (existing); No preselected. |
| Quit | `title_s2_2p` | Confirm Exit UI.png | Apostrophe added ("We're"); dim scrim behind the dialog. |
| Components | `components_s0_4p` | Button Variants.png, Panels.png | Flat fills approximate the wood and paper textures. |

## Performance and cleanup

Heaviest screen: 4-player Round result (chart, chalkboard, awards, legend), windowed 1920×1080, VSync off, 300 frames: **median 0.452 ms, p95 0.716 ms, worst 0.882 ms** (budget 16.67 ms); 131 draw calls; 354 nodes; Godot static memory 118.7 MiB and video memory 56.4 MiB (budget 512 MiB process memory). With VSync on, every screen including the near-empty Title measures about 31 ms per sample on this 144 Hz display; that is display pacing, not UI cost. Textures: none added (StyleBoxFlat, one 4×256 GradientTexture2D in the Theme, five fonts). Layered panels: Pause draws scrim + backing + paper + pills; no full-screen layer was added except the Title quit scrim (only while the dialog is open). Gameplay network traffic: none (no networking code touched).

## Still open

Human visual review against the Figma file, couch-distance readability and a physical keyboard/gamepad pass ([PLAYTEST Sheet G](../../PLAYTEST.md#sheet-g--p13-t18-reference-restyle-review)); transparent texture exports for the paper, rivet, plank, vine, chalkboard and icons; font approval; lint/format (gdformat/gdlint are not installed on this PC).
