# Live match UI — verification record (2026-10-14)

Scene-based UI screens (Title, Lobby, Pugad, Place, Play HUD, Round result, Match result, Pause / Reconnect) driven by the live P05/P06/P08/P09 match code through `GameFlow` and `MatchScreenPresenter`; the code-built panels are deleted from the P05, P08 and P09 rooms; developer text lives in a DEBUG overlay.

| Field | Value |
|---|---|
| Base revision | `332f173` (`origin/main`, P09 landed) plus this change. An earlier pass was measured on `a6bb928` and then on `160a0b4`; its baseline file is kept as `baseline_suite_summary.txt` |
| Engine | Godot `4.7.2.stable.official.ed1daf0bf` (explicit `D:\Downloads\Godot_v4.7.2-stable_win64_console.exe`; PATH `godot` 4.6.3 is never evidence) |
| Machine | Windows 11, 13th Gen Intel i5-13420H (12 logical CPUs), NVIDIA GeForce RTX 4050 Laptop GPU, Compatibility renderer, windowed 1920×1080 |
| Profile / seed | `karera_slice` / `12345` for the player flow (P07 first-playable room: Kaing 1×1, Kaing 2×3, Tulay 4×1 only); `-- --match-route=lifecycle` plays the P09 lifecycle room on the same profile; the P08 lab runs `lagsanay_lab` |
| Input | Synthetic `InputEventKey` / `InputEventJoypadButton` events into `LocalInputRouter` (K1, K2 and gamepad ids 710–712, 800+, 900+). **No physical device and no human player was used** |
| Reviewer | None. No independent human review is claimed |
| Runner | PowerShell wrapper over the test scripts, run in an isolated copy so the tracked evidence PNGs of earlier phases were not overwritten |

## Suites: baseline `332f173` vs after

Counts from `baseline_332f173_suite_summary.txt` and `final_suite_summary.txt`.

| Suite | Baseline `332f173` | After | Note |
|---|---|---|---|
| foundation | 0 failures | 0 failures | |
| P02 | 83 / 0 | 83 / 0 | |
| P02 wall | 85 / 0 | 85 / 0 | |
| P03 | 103 / 0 | 103 / 0 | |
| P03 interactive | 14 / 0 | 14 / 0 | GUI-click timing was intermittent on `a6bb928` (see the older baseline file); both clean here |
| P04 | 269 / 0 | 269 / 0 | |
| P04 interactive | 25 checks, 4 failures | 25 checks, **the same 4 failures** | Stale variant-cycle assertions; pre-existing, not touched |
| P05 | 137 / 0 | 137 / 0 | |
| P05 interactive | 61 / 0 | 61 / 0 | 3 conditional checks are skipped with the current pool |
| P06 | 97 / 0 | 97 / 0 | |
| P06 interactive | 17 / 0 | 17 / 0 | |
| P07 route | 590 / 0 | 590 / 0 | the HUD-button assertion now checks the DEBUG overlay is off |
| P07 reset audit | 172 / 0, 10 resets | 172 / 0, 10 resets | |
| P08 | 86 / 0 | 86 / 0 | |
| P08 interactive | 87 / 0 | 87 / 0 in 7 of 10 runs; **flaky in long windowed sequences** | see "Windowed runs and focus loss" |
| P09 | 77 / 0 | 77 / 0 | |
| P09 interactive | 108 / 0 | 108 / 0 | |
| P09 restart audit | — | 10 cycles, 0 failures | |
| P10 | 424 / 0 | 424 / 0 | |
| P10 interactive | 42 checks, 3 failures | 42 checks, **the same 3 failures** | Stale "eight families" / commit assertions; pre-existing |
| UI | 438 / 0 | 447 / 0 | +9: new contract nodes, the debug-overlay scene and its extra button |
| blocks | 76 / 0 | 76 / 0 | |
| **match UI (new)** | — | **198 / 0** | flow, ownership, pause / resume, reclaim, double activation, lifecycle, source rules, DEBUG overlay / harness |
| **match UI bindings (new)** | — | **185 / 0** | every live bind equals the view model for 2 / 3 / 4 players |
| **match UI modes (new)** | — | **62 / 0** | P08 lab HUD / results / restart action, P09 sudden-death HUD, final match result, confirmation dialog, pause over the final result, Return to Lobby, GameFlow lifecycle route |
| **match UI interactive (new)** | — | **59 / 0** (3 clean runs) | rendered 1080p flow with 30 captures |

Lint / format: `gdlint` clean and `gdformat --check` clean on every changed or new file. Over the whole project `scenes/prototype/chicken.gd`, `chicken_2.gd` and `gameplay.gd` still fail both tools exactly as before (not touched). Godot import / parse: `--headless --editor --quit` exit 0 with no error or warning lines (`import_parse.log`).

## Windowed runs and focus loss

The windowed runners drive a real window. By the P02 rules (`PauseRecoveryCoordinator`) a window that loses focus pauses everyone and clears readiness, so any focus change during a run freezes the simulated clocks and fails the time-based checks. In a long sequential run the P08 interactive runner failed its first 2-player time-based block (3 of 10 runs; four to five checks, always the same block). A temporary print in the scratch copy showed `application focus lost` as the pause reason in the failing run (`focus_loss_flake_diagnostic.txt`); the passing runs show only the runner's own deliberate pause. The match UI interactive runner failed once in the same way (its pause / resume block). The upstream baseline passed P08 interactive once in the same order; no repeated baseline runs were made. P03 / P04 interactive are known to be intermittent on the same basis. This is environment noise, not a P08 behaviour change, but it means a windowed pass needs an idle machine.

## A P05 gap the UI exposed (handled in the presenter, reported here)

The room's `_on_match_action_pressed` and `_on_match_navigation_step` stay connected to the router while the game is paused, so once the pause screen had a navigable menu, **arrows moved the Place cursor and a confirm on "Resume" locked a placement** (and the Place-lock commit makes that final). Evidence: `pause_input_exposed_by_ui_before_fix.txt` (2 failures of the new test on the presenter without the isolation). `MatchScreenPresenter` now detaches those two handlers while the pause screen is open and reconnects them on resume; no P05 rule, timing or score changed, and the room code is untouched. The decision whether to move this guard into the room itself is left to the owner.

## What the captures show (all inspected)

| File | State | What it shows |
|---|---|---|
| `01_title_nobody_joined` / `22_title_after_return` | Title, nobody seated | Join prompt with all three device glyphs, build label with the profile and no seed |
| `02_title_menu_one_seat` | Title, one seat | Start / Library / Settings / Quit menu appears for the joined seat |
| `03_lobby_one_seat` / `04_lobby_four_seats_two_ready` | Lobby | Four slots with number + shape, device, READY / NOT READY, `F Ready` / `G Back` hints |
| `05_pugad_four_players_pointing_at_egg_1` | Pugad | Six eggs, all four seats' number + shape badges on egg 1, control hint in the banner, countdown 8, HUD with four score rows |
| `06_pugad_claim_lost` | Pugad after a same-tick contest | Winner's badge on egg 1, text lost-claim cue for seats 2, 3, 4 |
| `07_place_four_players_valid` | Place | Per-seat status rows (exact variant + `[OK] Valid`) in the bottom strip, 15 s countdown, ghosts |
| `08_place_blocked_with_reason` | Place, seat 4 on the goal zone | `[X] Blocked` row and the live reason text |
| `09_play_hud_four_players` | Play | Round, Karera, 1:00 race timer, four RUN rows, Play-start hint toast |
| `10_results_four_finished_no_points` | Round result, 4 finishers | Suppression reason, no award rows, deltas +0 |
| `11_debug_overlay_on_results` / `12_debug_overlay_off_results` | Same state | DEBUG overlay on (build, profile, seed, seats, message, buttons) vs the clean player screen |
| `13_play_finish_window` | Play after the first finishes | `0:15 FINISH WINDOW`, three SECURED, one RUN |
| `14_results_three_finished_one_out` | Round result | Tapos / Una rows with explanations, "did not reach the flag within 15 s", total and delta per seat |
| `15_results_worst_case_ten_awards_FIXTURE` | **Staged model, not a played round** | Ten award rows fit (title + points only above six rows) |
| `16_pause_owner_seat_2` / `17_pause_three_ready_waiting_on_owner` | Pause | Owner badge, plain-language reason, live roster READY / WAITING, Resume / Settings / Library / Leave |
| `18_pause_resume_countdown` | Pause | Resume countdown over a frozen stage |
| `19_pause_device_lost_reclaim` | Pause, controller lost | Roster DEVICE LOST and the reclaim panel text |
| `20_pause_leave_confirmation` / `21_lobby_after_leave` | Leave | Confirmation, then a fresh Lobby with the same seats |
| `23_results_two_players_waiver` | Round result, 2 players | The two-player waiver text and both Tapos + Una rows |
| `24_results_wide_window_letterbox_1422x800` | 1920×800 window | 16:9 viewport inside a wider window; nothing clipped |
| `25_play_camera_widest` / `25_play_camera_tightest` | Camera extremes | World scale measured in `frame_measurements.txt` |
| `26_lifecycle_sudden_death_hud` | **Staged P09 fixture** (scores preloaded 5 / 5 / 1 at round 12), lifecycle route in the player flow | `Sudden death • Lagsanay`, head-start clock, `HEAD START • TAYA P1 ● CIRCLE` tag, seat 3 `WATCHING`, the sudden-death notice |
| `27_lifecycle_final_match_result` | **Staged fixture**: `_show_final_results` | Winner, outcome sentence, exact final score per participant, Replay / Return to Lobby / Quit |
| `28_lifecycle_leave_confirmation` | Same, Back pressed | The shared confirmation dialog over the dimmed final result |
| `29_lagsanay_lab_head_start_hud` | P08 lab, DEBUG overlay on | `Lagsanay` HUD, head-start clock, TAYA tag and state, play-start hint ("Touch to pass the taya!" plus the run / jump keys), DEBUG status lines |
| `30_lagsanay_lab_results` | P08 lab, taya expired | Scene Round result: last survivor, Lagsanay timing sentence, placement awards with explanations |

Known look limits: the stage still draws labelled P03 / P04 graybox geometry (`SPAWN • PROTECTED`, `BUILD REGION • DEBUG`, `TULAY • DEBUG`); the `ItemGhost` world label is about 9 px at 1080p / zoom 0.5, so the readable per-seat Place copy is the screen-space row; every screen carries its PLACEHOLDER tag; the result toast uses the Theme's alert panel for neutral text; with the DEBUG overlay on, its bottom panel covers the lowest part of the stage and results.

## Performance

`match_ui_performance.txt` (Godot 4.7.2, 1920×1080, v-sync off, 300 frames per phase, 10 real rounds per seat count, DEBUG overlay off; the last of three clean runs; all three PASSED):

| Seats | Race median / p95 / worst (ms) | Results median / p95 / worst (ms) | Static memory | Nodes | Orphans |
|---:|---|---|---:|---:|---:|
| 2 | 1.500 / 3.001 / 5.804 | 1.347 / 2.155 / 2.982 | 111.99 MiB | 1222 | 0 |
| 3 | 2.319 / 4.883 / 14.025 | 1.532 / 5.008 / 7.290 | 112.01 MiB | 1229 | 0 |
| 4 | 2.739 / 5.613 / 8.314 | 1.464 / 2.324 / 3.099 | 114.76 MiB | 1236 | 0 |

Targets (p95 and worst < 16.67 ms, memory < 512 MiB, 0 orphans) pass in all three runs. The three runs spread widely (race worst 2.8–14.0 ms; the 14.0 ms is a single spike), so the figures are machine-noise-limited rather than UI-limited; binding runs on change only. Against `docs/evidence/p06/p06_performance.txt` (4 seats: race 2.180 / 3.005 / 3.788 ms, 86.57 MiB, 165 nodes) the UI plus the P07 room adds about 1070 static nodes and about 28 MiB (the match-result and confirmation screens added about 100 nodes). The P08 sampler (`capture_p08_performance.gd`) on this tree passed in two of three runs; the failure was one 22.8 ms frame (3 seats) and the untouched `332f173` copy also failed one of two runs on a 39.6 ms spike, so that sampler is noise-sensitive on this machine. Its `director_steps` column reads 0 here because uncapped fast frames give the director few physics ticks inside 330 rendered frames; the baseline copy shows 1–17 for the same reason.

## Exported build

`export_smoke.txt`: Windows Desktop **release** export, `build\tilaok-playtest-2026-10-14.exe` + `.pck` (SHA-256 in the file; the `.exe` is the unchanged engine template, the `.pck` holds the project). Headless startup prints `TILAOK_FLOW_READY state=title … route=first_playable`; `-- --harness`, `-- --open-room=p05_match / p07_first_playable / p08_lagsanay / p09_match_lifecycle / ui_player_flow` reach the harness and the rooms; `-- --match-route=lifecycle` prints `route=lifecycle`; windowed launches render on the NVIDIA GPU and exit 0. Not a human session.

## Limits

Synthetic input only; no physical controller, rollover, reconnect or human readability test. The default player route is the P07 first-playable room, so there is no match end there; the Match result screen and sudden death are reachable on `-- --match-route=lifecycle` (staged fixtures were used for the captures; the played-through paths are covered by `run_p09_interactive.gd`). Per-seat leave in the Lobby is not implemented (the seat registry has no leave API): Back returns the whole group to the Title. Settings are in-memory only. The P08 / P09 `evidence/p08` and `evidence/p09` captures predate this UI and still show the code-built panels; they are history, not current. Final art, typeface and Filipino / Hiligaynon copy review are open.
