# Item event and stack integration — October 16, 2026

Evidence for P04-T11 (Kaing), P04-T20 (Tulay) and P10-T07 / T16 / T25 / T34 / T43 / T52 (Gulong, Trumpo, Parol, Tsinelas, Walis, Bula).

All runs are headless Godot 4.7.stable.official.5b4e0cb0f on Windows 11 with `--fixed-fps 60` and synthetic seats (K1/K2 plus synthetic gamepad IDs). They run on the default arena, with the working tree on `fec0d3f` plus uncommitted changes. Reviewer: Claude (AI, automated). No human, playtest, balance or physical-device review is claimed.

## User decisions (2026-10-16)

1. **Filter eggs only.** An event round deals only items approved for that event, and a stacked round deals only items approved for both its Main and its Twist. Pieces already on the stage stay exactly as they are.
2. **The six P10 families join the real match pool** with low provisional weights: Gulong 15, Trumpo 20, Parol 15, Tsinelas 20, Walis 15, Bula 10.

## What changed

- `PugadEggPoolGenerator.generate(..., mode_ids)` skips a family unless its `modes_allowed` lists every active mode (`allows_modes`). A mode listed under `modes_pending_review` is not dealt.
- `EventSchedule.mode_ids(entry)` returns the Main's mode plus the Twist's mode.
  - The scheduled P12 room returns these from `pugad_mode_ids()`.
  - Other rooms return none, so their fixed development pools are unchanged.
  - Every family allows Karera, so Karera rounds deal the same seeded eggs as before (checked).
- The 14 P10 scenes no longer set `in_main_game = false`. P10 weight defaults in `gameplay_tuning.gd` were lowered; the dev labs still override them to 50.

## Mode table (from the scenes)

| Family | Allowed | Pending review | Wave support | Weight |
|---|---|---|---|---|
| Kaing | Karera, Lagsanay, Kangaroo | — | support | 50 |
| Tulay | Karera, Kangaroo | Lagsanay (safe-floor review) | support | 50 |
| Gulong | Karera | Lagsanay, Kangaroo | none | 15 |
| Trumpo | Karera, Lagsanay, Kangaroo | — | none | 20 |
| Parol | Karera | Lagsanay, Kangaroo | none | 15 |
| Tsinelas | Karera, Lagsanay, Kangaroo | — | none | 20 |
| Walis | Karera | Lagsanay, Kangaroo | none | 15 |
| Bula | Karera | Lagsanay, Kangaroo | none | 10 |

Of these eight families, each round type leaves these out of its eggs:

| Round type | Families left out |
|---|---|
| Karera | none |
| Lagsanay | Tulay, Gulong, Parol, Walis, Bula |
| Kangaroo | Gulong, Parol, Walis, Bula |
| Karera + Bomb-Taya | Tulay, Gulong, Parol, Walis, Bula |
| Karera + Kangaroo | Gulong, Parol, Walis, Bula |
| Kangaroo + Bomb-Taya | Tulay, Gulong, Parol, Walis, Bula |

## Checks — `tests/run_item_mode_integration_tests.gd` (83 checks, 0 failures)

[Log](2026-10-16_item_mode_integration_tests.txt). Each case uses a fresh scheduled P12 match room (3–4 seats). The round's locked schedule entry is forced to the round type under test; this is test-only, since the real schedule rolls it. The piece goes through the real Place resolver, and real physics runs with the victim held at the hazard.

| Area | Result in all six round types |
|---|---|
| Egg filter, 1500 seeded eggs | Only approved families are dealt, and every approved family appears: 16 / 11 / 9 / 11 / 9 / 8 families. |
| The room's own Pugad, 28 eggs | Only approved items are dealt. |
| Trumpo, Parol, Tsinelas direct kills | P2 is eliminated with `cause = direct_hazard`, `direct_owner_seat` = P1 (the placer) and the piece's instance id. Credit goes through the Karera ledger, the Lagsanay controller or the Kangaroo controller. Parol was placed directly in event rounds to stand in for a Parol kept from an earlier Karera round. |
| Gulong | One launch, about 309 wu up; no elimination, no outcome, no credit. |
| Bula | One capture and one release; no elimination, no outcome, no credit. |
| Kaing 2x3, Tulay 4x1 | Standable (feet on the top within 2 wu); support metadata is wave-support ELIGIBLE; no elimination. |
| Walis 3x3 (Karera) | Clears P2's earlier-round Kaing during Place; leaves no Play piece and no elimination record. |

A first run failed the event-round kill rows because the test set tuning values the event start validation rejects: a head start of 0, a 600 s telegraph and a 600 s taya timer. The event never began. The test now clears the head start and countdown on the live controllers instead. This was a test error, not a game defect.

## Test expectations updated for the new rules

| Suite | Old expectation | Now |
|---|---|---|
| `run_p04_tests.gd` | 10 families and 11 egg previews | 16 families and one preview per enabled variant |
| `run_p04_tests.gd` | Old mode flags (Tulay Karera-only) | The scenes' current flags |
| `run_p04_tests.gd` | `kangaroo_contract_lab` has an empty pool | That lab lists its four reviewed families; `stack_lab` is the empty case |
| `run_p07_tests.gd` | Out-of-pool example was a P10 hazard | Kaing 1x3 (off by default) |
| `run_p10_tests.gd` | "No P10 variants in the default pool" | 25 variants, 14 of them P10 |
| `run_p13_library_tests.gd` | Wrap check started on whatever row an earlier step selected | Starts on row 0. The 16-row list exposed this; the old run happened to start mid-list. |
| `run_p13_library_tests.gd` | Reference rows came from the full live set | Live set is a subset without the P10 families, so reference rows still appear |
| `run_barya_tests.gd` | The other seat's random egg was placed at corner cell (5,3) | That seat uses a 1x1 Kaing for this check; a large P10 piece can't fit there |

After the update, P04 passes 270/270, including its two older failures (mode flags, empty lab pool), which are now fixed.

## Full headless regression

[2026-10-16_regression_summary.txt](2026-10-16_regression_summary.txt) covers every `run_*_tests.gd` suite except the windowed `*_interactive` ones. The suites updated above were re-run separately; the summary lists those re-runs.

Remaining failures were all present before this work:

- P07 reset audit: 10.
- Tutorial: 3 (Pugad copy with Barya text).
- UI: 4 (score award legend, award line, `%Outcome1` / `%Final1`).

The windowed suites were not run.

## Still open

- Release enablement for each family (P04-T13/T22, P10-T09/T18/T27/T36/T45/T54): the 2/3/4-player, preview, Library and ten-reset run on final art, `PlaceholderAudit` and the owner's `release_target` decision.
- Tulay's Lagsanay safe-floor review, and any Lagsanay/Kangaroo approval for Gulong, Parol, Walis and Bula. Approving one means editing that scene's BlockData mode flags.
- Human balance review of the new match weights.
