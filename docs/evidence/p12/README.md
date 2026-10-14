# P12 slice 1 — event schedule, compatibility registry and announced Main rounds (2026-10-15)

Build: working tree on `c024c9d`, plus the uncommitted Effect rename/match-kill fix and this work. Godot 4.7.stable.official (console build); Windows 11. Headless suites ran with `--fixed-fps 60`; rendered suites and captures used a 1920×1080 window. Seats and input are synthetic. Reviewer: Claude (AI, automated). No human reviewer, player session or physical device.

Covers P12-T01 (implement) and P12-T02 (verify). The Twist pairs (P12-T05–T10) and the terminal-order table (T03/T04) are **not** covered: all three compatibility rows are registered but disabled, so no Twist runs.

## Results

| File | What it shows | Result |
|---|---|---|
| [2026-10-15_p12_schedule_tests.txt](2026-10-15_p12_schedule_tests.txt) | `run_p12_tests.gd`: seeded schedule tables, Twist rules, required-mode refusal, two Kangaroo controller regressions, full 12-round scheduled matches with 2, 3 and 4 seats, room refusal | PASSED — 61 checks, 0 failures |
| [2026-10-15_p12_regression_summary.txt](2026-10-15_p12_regression_summary.txt) | Every headless `run_*_tests.gd` suite (23) | PASSED, except 2 P04 checks that already fail on `HEAD` |
| [2026-10-15_p12_pugad_announcement_1080p.png](2026-10-15_p12_pugad_announcement_1080p.png) | Round 5 Pugad: "NEXT • ROUND 6: KANGAROO" / "No Twist · This round: KARERA" | Rendered |
| [2026-10-15_p12_lagsanay_main_1080p.png](2026-10-15_p12_lagsanay_main_1080p.png) | Round 2 scheduled Lagsanay Main: flag hidden, taya marker, head-start clock | Rendered |
| [2026-10-15_p12_kangaroo_main_1080p.png](2026-10-15_p12_kangaroo_main_1080p.png) | Round 6 scheduled Kangaroo Main: shared DEBUG command prompt, slipper, failure markers | Rendered |

Rendered interactive suites, run because P09, P11 and the match screens changed:
- `run_p11_interactive.gd`: 85/85.
- `run_match_ui_interactive.gd`: 59/59.
- `run_p09_interactive.gd`: 106/108. Both failures also occur on a clean `HEAD` checkout:
  - "P09 keeps exactly the three P07 variants" fails on every run. Its expectation predates the catalog-driven egg pool (P02-T30).
  - "real contact transfers taya once" is timing-dependent in the unfixed-frame-rate rendered run. It failed 1 of 4 runs on `HEAD` and 2 of 3 runs on this tree, and passed on a third run here.

  Neither is caused by this work, but both remain open.

The interactive runs overwrite their own evidence images in `docs/evidence/{match-ui,p09,p11}`; those were restored to the committed versions.

## What the schedule tests check

- **Table:** 500 seeds × 12 rounds. Round 1 is Karera; rounds 4/8/12 are Lagsanay and flagged guaranteed; no Twist while no pair is enabled. The seed-12345 sample is printed in the log.
- **Weights:** 16,000 non-guaranteed rounds drew 0.699 / 0.197 / 0.103 (target 70/20/10). With Kangaroo unavailable, Karera drew 0.775 (expected 0.778) and Kangaroo never appeared.
- **Determinism:** the same seed gives the same table, and locking round 12 first does not change it.
- **Twist rules** (pairs force-enabled for the check only):
  - No Twist in rounds 1–4 or on guaranteed rounds.
  - Rates 0.105 / 0.202 / 0.303 for the 5–7 / 8–10 / 11–12 bands.
  - Never a self-stack or an unlisted partner, and Karera's two partners are equally likely.
  - A Kangaroo Main (one option) always gets Bomb-Taya. A Lagsanay Main (zero options) or an empty pool plays a normal round.
- **Refusal:** a missing Lagsanay (even in a 3-round match, for sudden death) or a missing Karera refuses the schedule; the room then returns to the lobby with the reason. A missing Kangaroo is allowed.
- **Full match** (seed 3: R1 K, R2 L, R3 K, R4 L, R5 K, R6 Kangaroo, R7 K, R8 L, R9 Kangaroo, R10 K, R11 K, R12 L), for 2, 3 and 4 seats:
  - Each round plays the Main announced in the previous Pugad, and the Pugad banner shows the locked next round.
  - The flag is live only in Karera.
  - Event rounds commit their placement scores; every round ends through the lifecycle; round 12 ends the match.
  - The room keeps its actors.
  - Lagsanay and Kangaroo timers are shortened through the match tuning to keep the run quick. In Kangaroo rounds every seat but one holds a run input, because idle synthetic chickens can pass Freeze and Hug forever.

## Defects found and fixed in the existing P11 Kangaroo controller

1. **Stalled cadence after a Storm elimination.** An elimination ended the Slipper Storm while a second Storm command was still pending. When that command drained in a later step, nothing scheduled the next base command, so the round never ended. `_maybe_resume_base_after_drain` now resumes whenever nothing is pending or scheduled. The regression check failed on the old code and passes now.
2. **`reset()` removed the room's chickens.** The controller kept a reference to the room's actor map from the last step and cleared it in place, so a second Kangaroo round in one match had no actors. It now drops the reference.

P11's single-round lab checks did not reach either case. The P11 focused (78) and interactive (85) suites still pass.

## Reproduce

```powershell
& '<Godot 4.7 console exe>' --headless --fixed-fps 60 --path 'tilaok!' --script 'res://tests/run_p12_tests.gd'
& '<Godot 4.7 console exe>' --path 'tilaok!' --script 'res://tests/capture_p12_evidence.gd'
```

Play it with the full-match route: `-- --match-route=lifecycle`.

## Open items

- Twist pairs: Karera + Lagsanay is next (P12-T05/T06).
- Terminal-order table: draft for team review (P12-T03); its human review is P12-T04.
- Human readability review of the banner text.
- Event-round containment breaches are ignored as in P09 sudden death (no defect pause as in the P08/P11 labs).
- The Lagsanay Last Cluck freeze from the P08 lab is not reproduced.
- Long 4-player taya tags can overflow the HUD clock row (the same text as the P08 lab).

Visuals are DEBUG placeholders.
