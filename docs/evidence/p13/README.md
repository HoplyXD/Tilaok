# P13 — complete UX and onboarding: engineering evidence (2026-10-15)

**Status:** implemented and verified with **synthetic input on one developer PC**. **No spectator, novice, QA reviewer, physical gamepad or physical keyboard session happened and none is claimed.** All copy is PLACEHOLDER English pending Filipino / Hiligaynon review; all art, audio and fonts are unchanged placeholders.

| Field | Value |
|---|---|
| Base revision | `origin/main` `1d058e2` (P12 Kangaroo Twist stacks; tracker 152/413 before this work) |
| Engine | `D:\Downloads\Godot_v4.7.2-stable_win64_console.exe` — 4.7.2.stable.official.ed1daf0bf (the PATH `godot` is 4.6.3 and was never used as evidence) |
| Date / machine | 2026-10-15 · Windows 11, Intel i5-13420H, NVIDIA RTX 4050 Laptop GPU |
| Profile / seed | `karera_slice` · default seed 12345 (HUD/library/cheer scenarios force the schedule entry under test; seed 3 for the human sheets) |
| Seats / input | 2 and 4 seats; K1/K2 keyboard events and synthetic gamepad identities. **Never physical-device evidence.** |
| Reviewer | engineering run (AI-assisted); no human reviewer |

## What changed (player-visible)

- **Routes:** the scheduled full match (Karera / Lagsanay / Kangaroo Mains, three Twist stacks, sudden death, final results) is now the default route (`D4`, owner-approved 2026-10-15). The P07 first-playable build stays behind `-- --match-route=first_playable`; `-- --match-seed=<n>` reproduces a match for facilitators.
- **Navigation:** Lobby help (the Rotate control opens the Library), a Lobby Back that asks once a seat is ready, Quit from the match result through the flow, left-stick menu navigation outside Play, and held-press consumption on every screen swap.
- **HUD:** next-round selection beside the clock (`NEXT R6 KANGAROO + BOMB-TAYA`, `FINAL ROUND`), scene-authored Kangaroo command cards and per-seat KANG → GA → ROO grid, `MISS n/3` in the score row, Last Cluck / Twist / next-round lines on the round result.
- **Library:** real PLACEHOLDER pages for How to Play, Karera, Lagsanay, Kangaroo and Accessibility with numbers from live tuning; one entry per enabled family with every enabled size animated in turn; entries scroll; stack and mode pages absent unless enabled; `--library-dev` shows clearly marked reference-only content.
- **Tutorial:** Kangaroo poses / built supports / three misses prompts once per session; the taya prompt also teaches the Bomb-Taya Twist and hands the stage back after 12 s.
- **Settings:** Master / Music / Effects / Crowd buses with a Mute switch and Screen shake that reaches the match; session only.
- **Cheer:** eliminated or finished chickens cheer during Play with Rotate (R / Right Shift / West); 1 s cooldown; "CHEER!" in the seat's own HUD row plus a soft Crowd-bus sound; no effect on the simulation.
- **Accessibility:** stun brightening is a ≤ 2 Hz smooth pulse (was an 8 Hz hard flash), steady with shake Off.
- **Tooling:** `scenes/tools/key_chord_recorder.tscn` for the physical keyboard session (P02-T04).

## Automated results

Full table with exit codes: [test_logs/baseline_vs_final.txt](test_logs/baseline_vs_final.txt). Every pre-existing suite has identical counts to the clean `1d058e2` baseline (P04: the same 2 failures; UI: the same 4; the UI suite gains 9 contract checks for the new nodes).

| Suite (new) | Result | Covers |
|---|---|---|
| [`run_p13_navigation_tests.gd`](test_logs/run_p13_navigation_tests.txt) | **PASSED — 205 checks** | route flag and seed parsing; every Title / Library / Settings / Quit / Lobby / Pause / confirmation route for K1, K2 and gamepad on both routes; owner-only Pause; Library and Settings from Pause keep the tree paused, clocks frozen and return to the same Pause row; blocked during the resume countdown; Quit through the flow; router help / cheer aliases; stick navigation; 10 screen cycles and 10 overlay cycles stable |
| [`run_p13_hud_tests.gd`](test_logs/run_p13_hud_tests.txt) | **PASSED — 264 checks** | cue table at 2 and 4 seats for 3 Mains and 3 stacks; text ≥ theme minimum; no internal ids / seeds / DEBUG; HUD inside 64 px and the screen width; Kangaroo cards below any notice and never overlapping; result footer on screen with Last Cluck; Barya N/A |
| [`run_p13_library_tests.gd`](test_logs/run_p13_library_tests.txt) | **PASSED — 352 checks** | every category has pages; PLACEHOLDER tag; numbers follow tuning; stack / mode gating; one entry per enabled family; every enabled size animated; scrolling reaches every row and wraps; no disabled family; dev reference rows only with the flag; gamepad Library traversal; Replay entry; Pugad names no item |
| [`run_p13_tutorial_tests.gd`](test_logs/run_p13_tutorial_tests.txt) | **PASSED — 55 checks** | poses → supports → misses sequence once per session, Twist triggers, stacked-round hand-over, skip, replay, guided match keeps its steps, no disk I/O |
| [`run_p13_accessibility_tests.gd`](test_logs/run_p13_accessibility_tests.txt) | **PASSED — 65 checks** | buses exist; each slider drives its bus; Mute; shake Full > Reduced > Off through the Settings object; mid-cue change; stun brightness peaks/s and step size; Parol cycle; audio → visual partner table; glyph and display report; bus reset |
| [`run_p13_cheer_tests.gd`](test_logs/run_p13_cheer_tests.txt) | **PASSED — 39 checks** | eligibility, 1 s cooldown, ignored in Pugad / Place / paused, HUD fit, and a 400-press spam run equal to a no-cheer run (scores, sim clock, positions, commands, markers, taya, six random streams) |
| [`run_p13_recorder_tests.gd`](test_logs/run_p13_recorder_tests.txt) | **PASSED — 60 checks** | matrix, PASS / LOST / report, tool isolation (proves the tool, never a keyboard) |

- Import/parse: 0 problem lines ([editor_import.txt](test_logs/editor_import.txt)). `gdformat --check` 230 files unchanged and `gdlint` clean ([lint_format.txt](test_logs/lint_format.txt)).
- Interactive (windowed, 1920×1080) runners, run from isolated copies of the baseline and the final tree ([baseline](interactive/baseline_summary.txt), [final](interactive/final_summary.txt)): identical results except P03 (the known flaky run: 2 failures in the baseline run, 0 in the final run). The same failing sets in both trees: P04 25 checks / 4 failures, P05 58 / 2, P10 42 / 3 (pre-existing, unchanged). P06 17/0, P08 87/0, P09 108/0, P11 85/0, match UI 59/0, P12 pairs 40/0.
- Windows Desktop debug export succeeds and the exported build boots to the Title on the new default route (`route=lifecycle`), with `--match-route=first_playable`, with `--match-seed=3`, and the recorder room loads (headless startup smoke only).

## Rendered captures (96)

All in [captures/](captures/) — [capture_report.txt](capture_report.txt) lists each file and size. Produced by `tests/capture_p13_evidence.gd` (windowed, synthetic seats). I inspected the screenshots; that is an engineering inspection, **not** a spectator, novice or QA result.

| Set | Resolutions | Seats | Shows |
|---|---|---|---|
| Menu routes | 1920×1080, 1280×720, 1920×800 | 2, 4 | Title (and join prompt), Settings, Settings muted + shake Off, Library (every category at 1080p, Items elsewhere), Lobby, Lobby help Library |
| HUD per mode and stack | all three | 2, 4 | Karera, Lagsanay, Kangaroo, Karera + Bomb-Taya, Karera + Kangaroo, Kangaroo + Bomb-Taya (1280×720 and 1920×800 show the two Kangaroo-bearing cases) |
| Results | all three | 2, 4 | round result, Last Cluck on a Lagsanay Main and on a Kangaroo + Bomb-Taya Twist (Twist and next-round lines), final result (1080p) |
| Pause | 1920×1080 | 2, 4 | Pause, Library over Pause, Settings over Pause |
| Cheer | 1920×1080 | 4 | two rows showing `CHEER!`, one out, one running |
| Minimum-zoom crowded stage | 1920×1080 | 4 | muted, shake Off, 29 persistent pieces, Kangaroo + Bomb-Taya with Slipper Storm (two command cards), zoom 0.526 (minimum 0.500) |
| Parol overlap | 1920×1080 | 2 | two Parol beams (one rotated) at minimum zoom |

What the captures show (inspected): the HUD bar stays inside its 64 logical px with four seats and the longest text; the Kangaroo cards sit below the Play-start notice and the miss grid is top-left; `TAYA P3 ■` / `MISS n/3` / `SECURED` / `CHEER!` read as text; the round result keeps its footer on screen with the new lines; the Library has no empty animation box on text pages.

**Known limits seen in the captures** (for the human reviewers): at minimum zoom the two Storm cards cover the upper-right of the stage and can sit over a chicken's label there (the chicken stays visible); the coach box still covers the stage's left edge for the first 12 s of a Lagsanay round; the result chart's second status line is tight beside the no-score notice at 1280×720; the `DEBUG SLIPPER` / `DEBUG RISING WAVE` world labels are still development placeholders.

## Strobe measurement (rendered)

`tests/capture_p13_evidence.gd` sampled the mean luminance of a Parol beam rectangle on every presented frame for 4.5 s at 1920×1080 (about 740 frames, all three phases inactive / charge / active seen): largest frame-to-frame step **0.018**, largest swing **0.029**, flashes of ≥ 10 % luminance in the worst one-second window **0** (WCAG general-flash limit 3). Uncapped frame rate was ~165 fps, so a 60 fps display sees steps about 2.7× larger (≈ 0.05), still far below 0.10. The stun pulse is a 2 Hz sine on a 1.5 → 2.4 brightness multiplier (at most 2 peaks per second, at most 21 % of its range per 60 Hz frame, never below the steady 1.5; flat with shake Off); that is checked analytically in `run_p13_accessibility_tests.gd` and was not rendered-sampled.

## Performance (1080p windowed, v-sync off; baseline vs final, three runs each)

Raw files in [perf/](perf/). Targets: p95 and worst < 16.67 ms; static memory < 512 MiB; 0 orphans.

| Case (40 persistent pieces) | Baseline p95 / worst (ms) | Final p95 / worst (ms) | Static MiB (base → final) |
|---|---|---|---|
| Kangaroo + Bomb-Taya, Storm, 4 seats (heaviest) | 2.97–3.03 / 6.27–6.53 | 2.64–2.69 / 4.43–4.84 | 122.8 → 127.3 |
| Kangaroo + Bomb-Taya, Storm, 2 seats | 2.76–2.81 / 4.98–6.48 | 2.44–2.51 / 3.30–5.93 | 122.4 → 127.1 |
| Karera + Bomb-Taya, 4 seats | 2.07–2.20 / 3.19–3.77 | 2.11–2.14 / 3.19–3.59 | 122.3 → 127.2 |
| Karera + Kangaroo, 4 seats | 2.39–2.47 / 4.67–5.04 | 2.51–2.56 / 3.42–3.92 | 122.6 → 127.3 |
| Match UI, 2 / 3 / 4 seats (race, P07 route) | p95 1.01 / 1.01 / 1.06 | p95 1.01 / 1.00 / 1.11 | 120.4–123.2 → 122.0–124.8 |

No regression; memory is +4.5 MiB (new scenes, bus layout, library text). These are debug-build numbers on one laptop, not target-PC or release acceptance (P15). The P09 note of a 27.78 ms p95 belongs to an earlier, different sample and is unchanged; this phase did not make it worse. Orphans 0 in every case; ten full-match restarts stay at node 1301 / objects 4435 (`run_p12_pairs_tests.gd`).

## Findings that need people or a decision

1. **Symbol glyphs.** The default font (Open Sans SemiBold) has no `● ▲ ■ ◆ → ↑ ↔`; Filipino letters `ñ á é í ó ú` are covered. Windows falls back to a system font (the captures show the marks); a machine without one may show boxes. The number and the drawn shape badge remain. The final font is human-owned (Shanti).
2. **Release browsing.** Every family has `release_target = false` (P04-T11/T13/T20/T22 blocked), so a literal release filter would list nothing. The Library lists *content enabled by the active profile*; reference content needs `--library-dev`. `ItemLibraryEntry.build_list(…, release_filter)` and the dev-mode toggle keep the literal behaviour.
3. **Default Screen shake is Off** (`PresentationSettings.screen_shake = 2`). Shake now works end to end when a player picks Full or Reduced.
4. **Pre-existing failures** (not caused here, unchanged): P04 2, UI 4, interactive P04 4 / P05 2 / P10 3.
5. **Window mode:** fixed 1280×720 logical with `canvas_items` stretch and no fullscreen option; 1920×800 letterboxes to 1422×800 content. No other size is claimed.

## Reproduce

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --editor --path 'tilaok!' --quit
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --fixed-fps 60 --path 'tilaok!' --script res://tests/run_p13_navigation_tests.gd
# likewise run_p13_hud_tests / run_p13_library_tests / run_p13_tutorial_tests / run_p13_accessibility_tests / run_p13_cheer_tests / run_p13_recorder_tests
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script res://tests/capture_p13_evidence.gd   # windowed; run from an isolated copy
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script res://tests/capture_p12_pairs_performance.gd
```

Run interactive and capture runners from an isolated copy of the tree: several older runners overwrite tracked `docs/evidence/**`.
