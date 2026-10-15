# P12 terminal-order decision table — DRAFT for team review

_Drafted 2026-10-15 by Claude (AI) for P12-T03. **Not approved.** P12-T03 and its review (P12-T04) stay unchecked until Francis, Carlos and the team accept or change each row. P12-T07–T10 (the Kangaroo pairs) stay blocked on that review._

The table covers **same-physics-step** collisions between terminal events that the current sources do not fully settle when two challenges run together. The events are command evaluation, taya timeout, tag pass, goal, trap kill and support destruction. Each row gives:
- the existing source rule, if there is one;
- what the build does today (only the Karera + Bomb-Taya pair is implemented);
- a proposal where no source decides the case.

Proposals are written so the outcome never depends on callback order.

Status values:
- **SOURCED:** an existing contract decides the case.
- **IMPLEMENTED (needs approval):** the build already behaves this way, but no source decides it.
- **OPEN:** nothing is implemented, and there is a proposal only.

## Karera + Lagsanay (Bomb-Taya) — implemented in P12-T05

| # | Same-step case | Source / current behaviour | Status | Proposal / note |
|---|---|---|---|---|
| K1 | The taya's countdown expires on the step the taya touches the flag | The race ledger resolves a same-step elimination before a goal for one seat (P06). P08 also gives a timed expiry priority over an untimed contact. Result: eliminated. | SOURCED | Tested (`run_p12_stack_tests.gd`). |
| K2 | Taya timeout and a direct trap kill on the same runner, same step | The race ledger treats any elimination with no source item (bounds, timeout) as an ambiguous cause, so no Patibong (P06). Standalone Lagsanay instead keeps the trap credit when the trap's recorded time is strictly earlier. | IMPLEMENTED (needs approval) | Keep the race rule (race-only scoring), or adopt the Lagsanay recorded-time comparison inside the stack. |
| K3 | The taya tags a runner on the same step the taya reaches the flag | The Twist steps before the race resolves, so the tag stands. The tagged runner keeps the countdown, and the finisher is secured. | IMPLEMENTED (needs approval) | Accept. The alternative is a random transfer, which would ignore a visible touch. |
| K4 | A timeout picks a new taya, and that runner finishes on the same step | The new taya is drawn from runners live at the start of the step. If that runner finishes, the next step moves the taya again with the countdown kept. | IMPLEMENTED (needs approval) | Accept, or draw only from runners not finishing this step (that needs goal detection before the Twist step). |
| K5 | One live runner left when a new taya is needed | The 2-player timer (7 s) is used, since the Lagsanay table has no 1-player value. | IMPLEMENTED (needs approval) | Alternatives: no taya with one runner left, or a dedicated value. |
| K6 | A bubble-captured runner as taya target or new taya | A captured runner counts as live, so it can be drawn as the new taya, but it cannot be tagged while captured. | IMPLEMENTED (needs approval) | Accept, or skip captured runners when drawing (the Bula items are not in the default pool yet). |
| K7 | Race deadline and taya timeout, same step | Both are eliminations with no source item; one terminal outcome per seat. | SOURCED | — |
| K8 | The opening taya during the head start | The opening taya is frozen, ignores hazards and cannot reach the flag. Head start happens once per round (PROTOTYPE_DEFAULTS timer policy). | SOURCED | — |

## Karera + Kangaroo — P12-T07 (not implemented)

| # | Same-step case | Source | Status | Proposal |
|---|---|---|---|---|
| C1 | A command is evaluated (a failure would add a marker) on the step a runner touches the flag | GDD: secured finishers get no commands, and failed runners cannot finish later. The same step is not covered. | OPEN | The command is evaluated at its recorded `response_end_at` time, and the goal has no sub-step time. As in K1, the timed event wins: the marker counts, and a third marker eliminates before the goal. |
| C2 | Third marker and goal, same step | As C1. | OPEN | As C1: eliminated. |
| C3 | Command evaluation and a direct trap kill | P11: strict recorded-time ordering (`hazard_precedes_command`). | SOURCED | Reuse unchanged. |
| C4 | A support breaks (Collapsing Block, Gulong) on the step a Rising wave is evaluated | P11 checks current support at the evaluation time. The order between the block's update and the controller is not fixed. | OPEN | Freeze the support snapshot once per step, before any block changes, and evaluate Rising against it. |

## Kangaroo + Lagsanay — P12-T09 (not implemented)

| # | Same-step case | Source | Status | Proposal |
|---|---|---|---|---|
| L1 | Third Kangaroo failure and a taya timeout, different seats | Both are eliminations. Placement uses recorded times; an exact tie goes to the lowest seat (P08/P11 Last Cluck). | SOURCED (clock caveat) | The two controllers use different clocks today: Lagsanay keeps its own and Kangaroo uses the director's. Use one shared simulation clock so the recorded times can be compared. |
| L2 | Taya timeout and a Freeze violation on the same seat | The timeout eliminates. The marker no longer matters. | OPEN | The earlier recorded time is the cause; if they are equal, the timeout. |
| L3 | A tag during a Freeze or forced movement | PRD REQ-STACK-003: the taya countdown keeps running during a Freeze; the R4 pause stays inactive. | SOURCED | — |
| L4 | All remaining players eliminated in one step by mixed causes | Last Cluck by latest recorded time, then lowest seat. | SOURCED (needs L1's shared clock) | — |

## Not covered here

- Sudden death never has a Twist (GDD), so there are no rows for it.
- Rule replacements R1–R4 in PROTOTYPE_DEFAULTS stay inactive.
