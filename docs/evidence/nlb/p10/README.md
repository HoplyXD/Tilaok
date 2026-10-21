# NLB-P10 — touch controls, phone HUD, mapping parity and mixed-device tutorial (preparatory)

## Status

**Date:** 2026-10-21. **Base revision:** `5efc6ef`. **Author:** Claude Code (Claude Sonnet 5.5, `claude-sonnet-5-5`) at the user's direction. **Reviewer:** none; no human review is claimed. **Spec:** [NETWORKED_LIVE_BUILD.md §5](../../../NETWORKED_LIVE_BUILD.md). **Tracker:** [NLB-P10](../../../PHASETASK_NETWORKED_LIVE_BUILD.md).

This is authored source and tests only. Nothing ran while the shared laptop was in use: no Godot editor, game, headless run, import, parse, test suite, capture, phone session, ADB, network listener, lint or performance measurement. Every check below is `COULD-NOT-RUN — deferred while the shared laptop is in use`. All three P10 tracker boxes stay unchecked; P06-T02 and everything upstream remain open. NLB-P10-T03 needs real participants, target Android hardware and an actual reviewer, and an agent can never complete it.

User decisions applied (2026-10-21): the gamepad `live_cancel` is the **Left bumper**; keyboards change **only** by the K4 aim detection fix; the work ships as several commits with no co-author trailer.

## What it does

- **Touch ownership.** `NetworkTouchLayer` owns each touch index by exactly one control or zone from press to release. A release outside the zone still releases the original owner; a finger that lands on nothing (palm, dead margin) is ignored; a second finger in an owned zone is swallowed; a disabled button owns the finger but never fires. Focus loss, hiding the layer, a viewport change and `NOTIFICATION_EXIT_TREE` release everything (buttons emit a release, zones return to neutral).
- **Independent zones.** The left Move zone drives the horizontal axis and the held direction actions (edges only, so the per-action rate limit is not spent on repeats). The right Aim zone drives only the ghost (`NetworkLivePlacementClient.set_aim`) and never the movement axis, so a player can move while aiming, rotating or placing.
- **Controls.** Jump (wire 0), Sneak (11), Cheer (6), Claim/OK (4 in the Pugad, 1 in Place), Back (2), Menu (local pause overlay only; the host alone pauses the match), Build (live build toggle), Rotate (live rotate in build mode, wire 3 in the legacy Place phase), Place (one stable request ID from the P06 client), Cancel (keeps the item). Ready and Results/Continue stay on the P09 `NetworkResultsOverlay`; the touch layer hides while it blocks. Claim/OK answers only in the Pugad and Place screens, so it never doubles as Place.
- **Phone HUD.** A top-left badge "You are P#" shows the number, a seat shape (circle, square, triangle, diamond) and the seat colour; the local chicken gets an outer ring and a "YOU" tag. A placement chip shows shape plus text for Placing, Sent, Accepted and Rejected (a cross). The status line keeps the phase, event, round, timer and host pause. Nothing flashes.
- **Mappings and glyphs.** The K4 numpad aim keys (7/1/3/9) are now detected as K4. The Left bumper is `live_cancel` in Play; B stays Back, A Jump, X Rotate (the Play cheer alias), Y Build, RB live rotate, RT confirm, right stick aim. The prompt map gains build_toggle, aim, live_rotate, live_confirm and live_cancel for k1–k4 and gamepad, and a new `touch` device for every action.
- **Tutorial.** Eight `net_*` steps (data in `tutorial_script.tres`) shown as client-local help cards. A hosted live-build match no longer selects the tutorial stage or attaches the coach.

## Implemented source

| Area | Files |
|---|---|
| Touch layer, HUD, cards | `scripts/network/network_touch_layer.gd`, `network_phone_hud.gd`, `network_help_cards.gd`, `network_match_presentation.gd` |
| Layout math | `scripts/ui/touch_layout.gd` |
| Input | `scripts/input/local_input_router.gd`, `scripts/input/input_context_table.gd` |
| Glyphs | `data/ui/prompt_map.tres`, `scripts/ui/ui_prompt_map.gd` |
| Tutorial | `data/ui/tutorial_script.tres`, `scripts/tutorial/tutorial_script.gd`, `scripts/flow/game_flow.gd` |
| Tests | `tests/run_nlb_p10_tests.gd`, `tests/capture_nlb_p10_layouts.gd` |

No wire family or contract change was needed: every control uses an existing action ID or a P06 live-placement intent. Godot `.uid` files for the new scripts are generated on first import and are not committed.

## Action table

One action per control in each device and context (the table is data in `input_context_table.gd`; `audit()` and the test compare it with the router). Keyboard columns show K1 / K2 / K3 / K4.

| Context | Touch | Keyboard | Gamepad |
|---|---|---|---|
| Lobby | Ready button (lobby screen), Menu | south = ready (E,F / Enter / O / Num 0), rotate = help, back, Esc pause | A ready, X help, B back, Start pause |
| Pugad | Move zone, Claim/OK, Back, Menu | south = claim, back, Esc | A claim, B back, Start |
| GO | Move zone, Jump, Sneak, Cheer, Back, Menu | up/left/right/down, back, Esc | D-pad/stick, B, Start |
| Play | as GO plus Build | up (W / Up / I / Num 8) = jump, Space / Right Ctrl alt jump, rotate = cheer (R / Right Shift / P / Num 5), build toggle (Q / [ / - / Num +) | A jump, X cheer, Y build |
| Play with build mode | Play plus Aim zone, Rotate, Place, Cancel (Move zone stays live) | Play plus aim (Z C V B / Y H N M / 7 4 8 6 / Num 7 1 3 9), live rotate (T / ] / = / Num *), place = south, cancel (X / \ / ' / Num -) | Play plus RB live rotate, **LB live cancel**, right stick aim, RT place |
| Results | Ready/Continue (overlay) | south = confirm, back | A confirm, B back |
| Pause | Menu toggles the local overlay, Back | south = confirm, back, Esc | A confirm, B back, Start |

Rules enforced by `audit()`: no control is bound twice in a context; only jump, ready, claim, confirm and pause may have alternate controls; build actions exist only in the build context (build toggle also in Play); jump and cheer controls are identical in Play and build.

## Layout math (PROPOSED, unmeasured until T03)

`TouchLayout.compute(viewport, safe_rect, dpi, window, live)`:

- inner rect = (OS safe rect ∩ viewport) shrunk by 5 % (UI_HANDOFF proposal, 64 × 36 at 1280 × 720);
- `dp_px = dpi/160 × viewport.x/window.x` (160 dpi when unknown, window 0 treated as unstretched);
- touch floor `max(44 dp × dp_px, 44 px)`; button size `clamp(0.11 × viewport.y, floor, 96 dp × dp_px)`; gap `max(6, 4 dp)`;
- drag zones are 28 % of the inner width (at least two buttons, at most 40 %); buttons wrap in the middle between the zones, first control on the bottom row.

Worked examples at 160 dpi, unstretched, live route (10 controls); the current project settings keep a 1280 × 720 viewport with letterbox bars, so the wider rows apply only if the stretch aspect changes:

| Aspect | Viewport | Inner rect | Button | Zone width | Columns × rows | Band height |
|---|---|---|---|---|---|---|
| 16:9 | 1280 × 720 | 1152 × 648 at (64, 36) | 79.2 | 322.6 | 5 × 2 | 194.4 |
| 19.5:9 | 1560 × 720 | 1404 × 648 at (78, 36) | 79.2 | 393.1 | 7 × 2 | 194.4 |
| 20:9 | 1600 × 720 | 1440 × 648 at (80, 36) | 79.2 | 403.2 | 7 × 2 | 194.4 |
| 4:3 tablet | 960 × 720 | 864 × 648 at (48, 36) | 79.2 | 241.9 | 4 × 3 | 255.6 |

A notch or gesture bar is handled by the OS safe rect (`DisplayServer.get_display_safe_area()`, Android only; scaled into viewport pixels). Controls sit in the bottom band and side columns; the arena, ghost and danger tells are above them. The aim zone is relative (a drag direction, not a pointer position), so the finger never sits on the ghost. The shared arena framing is unchanged: there is no follow camera.

## Interpretations a reviewer should confirm

- The tutorial guard applies only to the opt-in `network_live_build` route (the live matrix already disables `tutorial`). The scheduled P12 route keeps its existing behavior, so a pending tutorial can still select the tutorial map there; decide whether to guard that route too.
- The HUD number is the seat index + 1; confirm it always equals the seat identity drawn on chickens and score rows.
- Claim/OK is disabled outside the Pugad and Place screens so it cannot alias Place; confirm no needed phase is left without a confirm control.
- Help cards open once per session on the second match state and from the local Menu; the cards and their buttons are ordinary Godot controls (not touch-layer owned) at the top of the screen.

## Unverified limits and known gaps

- Nothing has been parsed, run or rendered. The new GDScript has never been seen by the Godot parser.
- All sizes, insets, the 14 dp drag dead zone and the 16 px text floor are proposals; no device has measured them.
- The host's own spectator controls and the P08 host resume HUD are still PC-only; the phone cannot resume a paused match by design.
- The phone's own chicken is marked with a ring and "YOU"; seat shapes are on the badge only, not on every chicken (the number is).
- Rendered tutorial and rendered aspect captures do not exist.

## Deferred commands

Each is `COULD-NOT-RUN — deferred while the shared laptop is in use`. Use `<log>` for a fresh log path.

```
"C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe" --headless --import --path "C:\Users\Mist\Downloads\Tilaok\tilaok!" --log-file <log>
"C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe" --headless --fixed-fps 60 --path "C:\Users\Mist\Downloads\Tilaok\tilaok!" --log-file <log> --script res://tests/run_nlb_p10_tests.gd
"C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe" --fixed-fps 60 --path "C:\Users\Mist\Downloads\Tilaok\tilaok!" --log-file <log> --script res://tests/capture_nlb_p10_layouts.gd
```

Regressions (same headless pattern, `--script res://tests/<runner>.gd`): `run_controls_tests`, `run_tutorial_tests`, `run_p13_tutorial_tests`, `run_p13_navigation_tests`, `run_match_ui_tests`, `run_match_ui_mode_tests`, `run_match_ui_binding_tests`, `run_nlb_p01_tests` … `run_nlb_p09_tests`. Also deferred: gdlint/gdformat (tools absent), an Android export and install from this revision, and physical touch checks.

## Check record

| Check | Result | Reason / evidence |
|---|---|---|
| `git diff --check` | PASSED | Run before each commit |
| Grep audit: every action|device glyph, one control per action per context | PASSED (static) | Source review of `prompt_map.tres` and `input_context_table.gd`; not a runtime result |
| Import/parse | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| Lint | COULD-NOT-RUN | Tools absent |
| `run_nlb_p10_tests.gd` | COULD-NOT-RUN | Deferred |
| Aspect / safe-area captures | COULD-NOT-RUN | Needs a non-headless run |
| Regressions | COULD-NOT-RUN | Deferred |
| Android export/install, physical touch | COULD-NOT-RUN | Deferred; needs hardware |
| T03 human sessions | COULD-NOT-RUN | Requires human sessions on target Android hardware and an actual reviewer |

## T03 human session protocol

Run by humans on real Android hardware with an APK built from the revision under test. Synthetic touch is never evidence.

**Participant procedure.**

1. Consent: tell the participant what is observed (taps, mistakes, questions, optional screen recording of the phone only) and that they may stop at any time. Record only a first name or role if needed; no other personal data. Record whether consent was given.
2. Record the device: make/model, Android version, screen size, dpi, orientation, safe-area/notch description, APK build ID and the host build.
3. Give no rules explanation beyond "join the room and play". Allow the help cards.
4. Session types: **touch-only** (all phones), **mixed-device** (at least one PC host or PC seat with keyboard or gamepad plus a phone), **novice** (participant has not played before).
5. Tasks, in order: join and get a seat; say which chicken is yours; say the objective out loud; pick an egg; move while a ghost is up (aim with one finger while moving with the other); place a piece; explain what happened after an accepted and after a rejected placement; cancel a placement and say whether the item is kept; finish the first round.
6. Observer notes: every hesitation, wrong tap, covered cue, missed control, question asked, and any use of the help cards.

**Session sheet (copy per participant).**

| Field | Value |
|---|---|
| Date / session ID / session type | |
| Participant (first name or role) / consent given | |
| Device make / model / Android version / dpi / safe area | |
| APK build ID / host build / host device | |
| Controls used (touch-only / mixed) | |
| Identified own chicken without help (Y/N, seconds) | |
| Stated the objective (Y/N) | |
| Moved while placing (Y/N) | |
| Understood accepted vs rejected (Y/N, quote) | |
| Understood cancel keeps the item (Y/N) | |
| Finished the first round without a long rules explanation (Y/N, minutes) | |
| Finger covered the ghost or a danger tell (Y/N, where) | |
| Control missed or mis-tapped (list) | |
| Safe-area / notch problems (Y/N) | |
| Smallest control that felt too small | |
| Captures (file names) | |
| Notes / quotes | |
| **Actual reviewer (name, role)** | |
| Outcome (PASSED / FAILED / COULD-NOT-RUN) | |

**Success criteria (acceptance).** A session passes only when the participant identifies their chicken and the objective, moves while placing, understands accepted versus rejected actions, and completes the first round without a long rules explanation, with no covered cue and no unrecoverable mis-tap. Any record without a named reviewer and real device data stays `COULD-NOT-RUN`. The proposed 44 dp floor, the 5 % inset and the 16 px text floor are judged from these sessions and may change.

## Shanti review list (UI design and audio are human work)

Control shapes, sizes and spacing; zone and button art and the pressed/disabled looks; the "You are P#" badge and seat shapes; the placement chip; help-card layout, tone and copy (and Filipino/Hiligaynon review); touch glyph text versus art; colour use and contrast; text sizes; HUD placement relative to the notch; any sound for tap, accept and reject (none exists). Everything above is a code-drawn placeholder with no generated final asset.

## Rollback

Each commit reverts independently: the router change, touch layer and HUD, glyphs and table, tutorial data and cards, tests, and docs. The offline keyboard and gamepad paths are untouched except the documented K4 detection fix.
