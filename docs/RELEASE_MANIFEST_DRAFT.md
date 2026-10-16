# Release content manifest — DRAFT (2026-10-16)

**Status:** working draft for the producer's freeze decision (PHASETASK [P16-T01](PHASETASK.md#p16-t01)). Nothing here is approved. Claude (AI) compiled it from the block scenes, the event schedule, the map folder and the test runs of 2026-10-16. The producer must review it, decide every open row, then date and sign it on the October 21 feature freeze.

## 1. Enabled match content

### Item eggs (31 variants, scene flags `in_main_game` and `enabled_by_default`)

| Family | Variants dealt | Modes (scene flags) | Weight | Release target |
|---|---|---|---|---|
| Kaing / Hollow Blocks | 1×1, 2×3 | Karera, Lagsanay, Kangaroo | 50 | decide (P04-T13) |
| Tulay na Kawayan | 4×1 | Karera, Kangaroo (Lagsanay pending safe-floor review) | 50 | decide (P04-T22) |
| Gulong Talon | 2×2 | Karera | 15 | decide (P10-T09) |
| Trumpo sa Riles | 4×1, 5×1, 6×1 | Karera, Lagsanay, Kangaroo | 20 | decide (P10-T18) |
| Parol Pulse | 3×1, 4×1, 5×1, 6×1 | Karera | 15 | decide (P10-T27) |
| Tsinelas Launcher | 4×1, 6×1 | Karera, Lagsanay, Kangaroo | 20 | decide (P10-T36) |
| Walis Cleanup | 3×3, 5×5 | Karera | 15 | decide (P10-T45) |
| Bula-Bulaklak | 1×3, 1×5 | Karera | 10 | decide (P10-T54; first cut-review candidate) |
| Solid Block | 3×1 | Karera, Lagsanay | 50 | Should item: include or defer |
| Wood Box | 2×2 | Karera, Lagsanay | 50 | Should item: include or defer |
| Collapsing Block | 1×1 | Karera, Lagsanay | 50 | Should item: include or defer |
| Spikes | 1×1 | Karera, Lagsanay, Kangaroo | 50 | Should item: include or defer |
| Cannon | 1×1 (lane to the stage edge) | Karera, Lagsanay, Kangaroo | 50 | Should item: include or defer |
| Bomb / Dynamite / Nuke | 2×2 / 3×3 / 4×4 | Karera, Lagsanay, Kangaroo | 30 / 20 / 8 | Should item: include or defer |
| Hagdan ng Bahay (P19, promoted 2026-10-16) | 2×2, 3×3 | Karera, Lagsanay | 20 | Expansion item: include or defer |
| Tinik-Tinik Strip (P19, promoted 2026-10-16) | 3×1, 4×1 | Karera | 20 | Expansion item: include or defer (wholesome-art review) |
| Yelo ng Sorbetero (P19, promoted 2026-10-16) | 3×1, 4×1 | Karera, Lagsanay | 20 | Expansion item: include or defer |
| Barya (round objective, P19) | 1×1 coin, Karera rounds only, 1-in-3 offer | Karera | separate roll | approved scoped P19 extra; confirm |

Event and stacked rounds deal only families approved for every active mode ([integration evidence](evidence/integration/README.md)). Pieces already on the stage keep working in every round.

### Defined but not dealt

- Kaing 1×3 column.
- Tulay 3×1 and 5×1.
- Vertical Tulay (gated).
- The other 25 expansion families (P19; three were promoted on 2026-10-16).

### Modes and stacks

- **Main Challenges:** Karera, Lagsanay and Kangaroo (weights 70 / 20 / 10).
  - Round 1 is always Karera.
  - Rounds 4, 8 and 12 are always standalone Lagsanay.
- **Twists from round 5** (10% / 20% / 30% by round band):
  - Karera + Bomb-Taya;
  - Karera + Kangaroo;
  - Kangaroo + Bomb-Taya.
- **Match end:** first to 10 points or the highest score after round 12. A tie goes to Lagsanay sudden death, which never takes a Twist.

### Maps (`scenes/maps/`)

| Map | Order | Notes |
|---|---|---|
| Tutorial | 0 | Guided first match; building is required to reach the flag. |
| Sample Map | 10 | Team map. |
| Basic Map | 20 | Jorge's framed map. |
| Built-in default stage | — | Always available. |

Decide which maps ship.

### Movement (Should extensions, enabled by default)

Each needs an include or defer decision:

- wall slide and wall jump;
- sneak and glide;
- stun;
- ledge climb (2026-10-16);
- eliminated chickens falling.

### Controls

- Four keyboard layouts:
  - WASD: E or F confirm, R rotate.
  - IJKL: O confirm, P rotate.
  - Arrows: Enter confirm, Right Shift rotate.
  - Numpad 8 4 2 6: 0 confirm, 5 rotate.
- Gamepads.
- Physical rollover and gamepad checks are untested.

## 2. Known defects and test status (2026-10-16)

The headless regression covers every `run_*_tests.gd` except the windowed suites. All pass except:

| Defect | Severity (proposed) | Owner | Disposition |
|---|---|---|---|
| UI rule check: `score_award_legend.gd` and `ui_award_line.gd` build layout in code (`Label.new`, `add_theme_*`), against the UI handoff rule. | Low (code convention, no player impact seen) | Francis (scoreboard chart, `d930bd1`) | Move the layout into scenes, or record a rule exception. |
| UI scene check: the round and match result screens no longer have `%Outcome1` / `%Final1` UiScoreRow nodes after the scoreboard chart redesign. | Low (stale test or missing rows; needs owner confirmation) | Francis | Confirm the redesign, then update the test, or restore the rows. |
| Windowed `run_p04_interactive`, `run_p05_interactive` and `run_p12_pairs_interactive` are intermittent on this desktop. P05 passes 58/58 standalone three times but fails 9–15 checks when chained after P04. P12 pairs: 7 runs gave 0, 3, 0, 4, 0, 0 and 3 failures, in different round-end/sudden-death checks. The headless pairs suite (285 checks) is green. | Low–medium (test timing; a game timing issue is not ruled out) | P12 owner | Investigate the windowed timing before freeze. The other nine windowed suites pass ([windowed log](evidence/stabilization/2026-10-16_windowed_suites.txt)). |
| No export templates installed on this PC for Godot 4.7.stable, so no current export build exists. | **Blocker for P16-T03** | Integration | Install the matching official export templates, export, then run the clean-PC test. |
| All art and audio are DEBUG placeholders. | **Blocker for release** (P14) | Art / Audio | Human-made assets. |

Fixed on 2026-10-16 (Claude):
- **P07 reset audit:** the stale all-finish test is fixed, and a teleport test now steps physics before Play.
- **Tutorial:** the Barya note no longer hides the claim key, the timer and claim feedback in the first Pugad.
- **P04 mode-flag checks:** the stale expectations are updated to the current scene flags.

## 3. Open decisions for the producer

1. Release target for each of the eight required families.
2. Include or defer for every Should item above (stage blocks, Spikes, Cannon, explosives, movement extensions, extra maps).
3. Tulay in Lagsanay (safe-floor review), and any event approval for Gulong, Parol, Walis and Bula.
4. Match weights after a balance playtest.
5. Sign-off on the defect table.
