# Guided first match — engineering evidence (2026-10-14)

**Status:** implemented and verified with **synthetic input** on Godot 4.7.2 (`4.7.2.stable.official.ed1daf0bf`). **No human novice session was run and none is claimed.** The guided copy is PLACEHOLDER English and has not been culturally or linguistically reviewed. This evidence does not complete P13-T07 or P13-T08.

| Field | Value |
|---|---|
| Base revision | `origin/main` `009a422` (P11 Kangaroo commits `c1c607c`, `009a422` landed on top of `7486219` while this work was planned) |
| Engine | `D:\Downloads\Godot_v4.7.2-stable_win64_console.exe` (4.7.2.stable.official.ed1daf0bf) |
| Date | 2026-10-14 |
| Machine | Windows 11, i5-13420H, RTX 4050 Laptop (rendered captures) |
| Profile / seed | `karera_slice` / 12345 (default route); `-- --match-route=lifecycle` for the Lagsanay prompt |
| Seats / input | 2, 3 and 4 seats; K1/K2 keyboard events plus synthetic gamepad identities. **Not physical-device evidence.** |
| Reviewer | Automated author only |

## What is proved

### 1. Default stage unchanged
`ArenaLayout.make_default()` reproduces the literal `ArenaDefinition` geometry: identical `arena_geometry_signature()`, build region, protected zones, goal trigger, spawn and per-surface wall eligibility. The recorded default signature is the block between `DEFAULT_SIGNATURE_BEGIN/END` in [gate_run_godot_4_7_2.txt](gate_run_godot_4_7_2.txt). P03 (103 checks) and the rest of the suites are unchanged (below).

### 2. The flag is unreachable without building (real physics, real `ChickenController`)
Tutorial stage: ledge top **y = 480 wu**, flag trigger resting on it, ledge sides wall-INELIGIBLE, BUILD HERE zone tiles 24–28 × 8–11.

| Measure | Result |
|---|---|
| Unchanged P03 route reaches Base D on the tutorial stage | PASSED (floor → A → B → C → D), and does not reach the flag |
| No-build scripted search | **1,860 attempts, 0 reached the flag**; every base platform, 3 run directions, 5 jump delays, 2 hold lengths (incl. long hold for glide), 2 repeated-press patterns (wall kicks) |
| Highest feet height reached | **y = 511.94 wu** (Base D top 704 − jump apex 192 ≈ 512) |
| Margin | ledge top 480 → **31.94 wu short** |
| Calculation | jump apex = 2·192/0.32² gravity → 192 wu exactly; best wall kick from a base side rises 144 wu from a contact window under the platform top, cannot chain; glide / wall slide only cap descent; sneak blocks jumping |

Honest caveat: a scripted search is strong evidence, not a mathematical proof. A 31.94 wu margin is about half a tile. Re-run `tests/run_tutorial_gate_tests.gd` after any movement, geometry or tuning change.

### 3. Each allowed piece has a placement that reaches the flag
Placements fully inside the BUILD HERE zone, tried one at a time with a policy family (run right from Base D, repeated jump presses):

| Variant | Legal placements in zone | Reached the flag |
|---|---|---|
| Kaing 1×1 | 12 | 7 |
| Kaing 2×3 (upright and turned) | 7 | 6 |
| Tulay 4×1 | 3 | 3 |

Intended answers (all PASSED): Kaing 1×1 at cell (27, 9); Kaing 2×3 turned to 3×2 at (25, 9); Tulay 4×1 at (24, 9). Placements that did not reach with this policy family are listed row by row (`ZONE_TABLE`) in the gate output; they may reach with other control sequences, which were not searched. Tulay at row 8 works only by about 0.06 wu and should not be taught. Five wrong placements (far left, on Base A, above Base B, beside Base C, under Base D) did **not** reach the flag.

### 4. One map per match
The layout is chosen once, when `GameFlow` creates the room. The arena signature and the construction signature are identical across three consecutive rounds, and a Lagsanay / sudden-death round in the same lifecycle match plays on the same stage with the same built pieces. Skipping or replaying mid-match does not change the stage; the next match uses the default layout (tested). On the lifecycle route, Replay / Return to Lobby from a tutorial-stage room builds a fresh room.

### 5. Coach box
- Step order Welcome → Pugad → Place → Karera → Results, with claimed / lost / timeout, retry (stronger hint when nobody finished), "everyone finished", "nobody finished" and 2-player waiver copy taken from the real `last_results_model`.
- Display-only: not attached to the input bridge, mouse ignored, Back does nothing, hidden under pause, Settings, Library, confirmation and final result.
- Copy numbers follow `GameplayTuning` / layout (test changes `match_pugad_seconds` and the copy follows); glyphs follow each seat's device (K1 / K2 / gamepad).
- Session memory is in `GameFlow` only; nothing under `user://` is created or changed (test lists the directory before and after; Godot's own `logs/` excluded). No `Control.new()`, `add_theme_*`, `FileAccess`, `ConfigFile`, `DirAccess`, `user://` or `ResourceSaver` in the tutorial scripts (code lines only).

### 6. Layout, size and overlap (1920×1080 captures; 1280×720 check)
See [layout_measurements.txt](layout_measurements.txt). The box is a narrow left column under the phase banner (right edge of the Results step uses a strip the Round result screen reserves), and automated rect checks report it **clear** of the 64 px HUD bar, the phase banner, countdown, Pugad eggs, Place strip (`SeatStatus1–4`), ghost status, outcome rows and award lines at 2 and 4 seats. Body text is 18 virtual px = **27 px at 1080p** (≥ 16 px); caption 21 px.

| Capture | Shows |
|---|---|
| `2p_1`, `4p_1` welcome_lobby | step 1 with every seat's number and shape |
| `2p_2`, `4p_2` pugad_pick | step 2 |
| `2p_3`, `4p_3` pugad_claimed | claimed copy |
| `2p_4`, `4p_4` place_build_here | step 3; dashed BUILD HERE outline + arrow + text |
| `2p_5`, `4p_5` play_no_build_gate | seats standing on Base D under the raised flag ledge, no piece built |
| `2p_6` results_nobody_finished | nobody-finished copy matching the real result |
| `2p_7` place_retry_hint | round 2 with the stronger hint and TRY A PIECE HERE |
| `2p_8` play_built_route | a built 1×1 beside the ledge and a chicken on it |
| `2p_9` lagsanay_prompt_on_built_stage | Lagsanay prompt (sudden death) on the same built stage |
| `4p_10`, `4p_11` 1280×720 | welcome and Place at 1280×720 |
| `4p_12`, `4p_13` results | everyone finished / one finished, box clear of rows and awards |

## Regression matrix (Godot 4.7.2, headless)

Baseline = unmodified clone of `origin/main` `009a422`, re-run before any change. Final = after the change, all suites re-run.

| Suite | Baseline | Final |
|---|---|---|
| Foundation harness lifecycle | 0 failures | 0 failures |
| P02 | 83 / 0 | 83 / 0 |
| P02 wall | 85 / 0 | 85 / 0 |
| Blocks | 76 / 0 | 76 / 0 |
| P03 | 103 / 0 | 103 / 0 |
| P04 | 269 / **2 failures** | 269 / **2 failures** (same two) |
| P05 | 137 / 0 | 137 / 0 |
| P06 | 97 / 0 | 97 / 0 |
| P07 | 590 / 0 | 590 / 0 |
| P08 | 86 / 0 | 86 / 0 |
| P09 | 77 / 0 | 77 / 0 |
| P10 | 430 / 0 | 430 / 0 |
| P11 | 78 / 0 | 78 / 0 |
| UI | 447 / 0 | 448 / 0 (+1: the Skip button's no-focus check) |
| Match UI | 198 / 0 | 198 / 0 |
| Match UI binding | 185 / 0 | 185 / 0 |
| Match UI modes | 62 / 0 | 62 / 0 |
| **Tutorial gate** (new) | — | 48 / 0 |
| **Tutorial coordinator/flow** (new) | — | 140 / 0 |
| **Tutorial capture** (new, rendered) | — | 91 / 0 |

The two P04 failures (`mode flags: Kaing karera+lagsanay; Tulay karera, Lagsanay pending review` and `profiles that do not list seed families keep an empty item pool`) already fail on unmodified `origin/main` `009a422`; they come from the P11 item-profile/definition changes, not from this work.

Interactive (windowed, 1920×1080) runners were run from isolated copies of both trees ([interactive_runs_base_vs_tutorial.txt](interactive_runs_base_vs_tutorial.txt)): identical results on both — P03 14/0, P05 61/0, P06 17/0, P08 87/0, P09 108/0, match-UI 59/0; P04 interactive 25 checks with the same 4 failures and P10 interactive 42 checks with the same 3 failures in **both** trees (pre-existing, not changed by this work).

## Performance and export
- [perf_baseline_origin_main.txt](perf_baseline_origin_main.txt) vs [perf_with_tutorial.txt](perf_with_tutorial.txt) (same machine, 1080p, v-sync off, ten rounds per seat count): race p95 1.28–1.51 ms before, 1.32–1.44 ms after; worst frame ≤ 3.69 ms (after) vs ≤ 1.96 ms (before, race) — both far under the 16.67 ms target; static memory 112.4–115.2 MiB → 114.8–117.6 MiB (+2.4 MiB); 0 orphans; nodes +31. Coordinator updates on events only.
- Windows Desktop debug export succeeds and the exported build boots to the Title ([windows_export_smoke.txt](windows_export_smoke.txt)).
- Editor import: 0 error/warning lines ([editor_import.txt](editor_import.txt)). `gdformat --check` and `gdlint` pass on every changed/new script ([lint_format.txt](lint_format.txt)).

## What this does not prove
- No human comprehension, no facilitator intervention log, no physical controllers, no rollover/reconnect evidence.
- The 1×1 / 2×3 / Tulay solution sets come from a scripted policy family, not an exhaustive control search.
- Copy is unreviewed placeholder; Kangaroo prompts and the wall-slide practice cue are not implemented.
- Local Debug timing on one machine; not a release-PC benchmark.

## Reproduce
Commands are in [PROJECT_STRUCTURE.md](../../PROJECT_STRUCTURE.md#guided-first-match-p13-t07-slice-2026-10-14). Run the interactive and capture runners from an isolated copy: several older runners overwrite tracked `docs/evidence/**`.
