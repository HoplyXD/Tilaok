# P12 terminal-order decision table (P12-T03 / P12-T04)

**Status:** APPROVED row by row by the project owner. Implemented on the scheduled match room (`P12ScheduledMatchRoom`, `BombTayaTwist`, `KangarooRoundController` Twist role) and verified by `tilaok!/tests/p12_table_scenarios.gd` (pure controller scenarios, with callback-order permutations) and `tilaok!/tests/p12_pair_room_scenarios.gd` (real room, real physics, 2/3/4 seats), both run by `tilaok!/tests/run_p12_pairs_tests.gd`. It supersedes the [draft](../../P12_TERMINAL_ORDER_DRAFT.md) rows K1–K8, C1–C4 and L1–L4 (mapping at the end).

## Approval record

| Field | Value |
|---|---|
| Approver | The project owner who ran this session (the repository's configured git author is Francis Gabriel Austria `<trashdump098123@gmail.com>`; **confirm the approver's name here**) |
| Date | 2026-10-15 |
| Channel | Claude Code chat session, reply to the Stage A plan and draft table |
| Decision (verbatim) | "approved. Plan approved. Table: approve U1-U12 as proposed, D1-D7 as recommended. Proceed with Stage B." |
| Reviewer for P12-T04 | the same project owner; engineering verification by the AI-assisted session below |

R1–R4 remain inactive. No row below changes a PRD/GDD rule: C rows cite the existing source; U rows are owner-approved additions that are consistent with those sources and are appended (not substituted) to `docs/STAGE_AND_PLACEMENT.md` and GDD §4.

## Same-step rules

Every stacked round resolves in one deterministic batch per physics step: finalise movement/support → snapshot goal overlaps, tag contacts and hazard records → each active controller proposes terminal outcomes against the same frozen live set → merge in stable order (recorded time → cause rank → seat) → single commit (one terminal outcome per player) → derived effects (taya transfer/re-pick, placement, round end).

### Covered rows (an existing source decides; the scenario proves it still does)

| # | Same-step combination | Source | Rule | Scenario |
|---|---|---|---|---|
| C1 | Karera goal vs direct hazard, same seat | GDD §5 outcome contract; PRD REQ-SCORE-001; PROTOTYPE_DEFAULTS movement precedence | Recorded time decides; indistinguishable → elimination wins. Goals carry no sub-step time, so any same-step pair is indistinguishable | `_c1_goal_vs_hazard_ledger` |
| C2 | Competing hazards on one seat | GDD §5; STAGE_AND_PLACEMENT order | Earliest recorded contact, then stable item ID | `_c2_competing_hazards_ledger` |
| C3 | Goal vs 15 s / 60 s deadline | PRD REQ-RACE-001; P06 evidence | Boundary-step events resolve first; the 60 s cap has priority | `_c3_deadline_boundary_ledger` |
| C4 | Taya timeout vs hazard | GDD Lagsanay ordering; PROTOTYPE_DEFAULTS | Strictly earlier comparable hazard wins; tie/incomparable → timeout | `_c4_c5_bomb_batch`; room: "C4 a strictly earlier trap beats the timeout" |
| C5 | Tag pass vs timeout | GDD Lagsanay ordering | Timeout wins on the expiry step | `_c4_c5_bomb_batch`; room: "C4 a strictly earlier trap beats the timeout" |
| C6 | Lagsanay batch order | GDD §5 batch precedence | Timeout + hazards commit before survivor count, re-pick, placement, tag | `_c4_c5_bomb_batch`; room: "C4 a strictly earlier trap beats the timeout" |
| C7 | Command failure vs direct hazard | PRD REQ-KANG-005; STAGE_AND_PLACEMENT | Hazard wins only if strictly earlier and comparable | `_c7_command_failure_vs_hazard` |
| C8 | Support destruction vs Rising evaluation | STAGE_AND_PLACEMENT | Destroyed support is absent | P11 evidence (unchanged controller) |
| C9 | Simultaneous final eliminations | GDD §5 Last Cluck | Latest recorded time, then lowest slot | P08/P11 Last Cluck suites (unchanged resolver) |
| C10–C15 | One outcome per player; secured ≠ eliminated; Twist kills are never Patibong; secured finisher out of commands/hazards/tag; taya time continues through Freeze (R4 inactive); forced motion is not a Freeze violation | PRD/GDD/PROTOTYPE_DEFAULTS | enforced by the batch | room scenarios (secured exclusion, continuous taya time, tag during Freeze) |

### Owner-approved rows (UNCOVERED in the sources)

| # | Pair | Case | Approved rule | Scenario(s) |
|---|---|---|---|---|
| U1 | K+L | Taya touches the flag on the same step its countdown expires | Timeout wins: eliminated (event elimination, no Patibong), not secured | `_u1_bomb_goal_vs_timeout` (2/3/4 seats); room: "U1 goal and timeout on one step" |
| U2 | K+L | Goal touch and tag-pass contact on one step | Goals commit before pass resolution; secured seats leave the frozen candidate set; the pass goes to the nearest remaining eligible runner, else none | `_u2_bomb_goal_vs_pass` |
| U3 | K+L | Finishing taya reassignment | After commit draw from the `taya` stream among unfinished live runners in ascending seat order; no pass-back immunity; countdown preserved; no opening freeze; none left → the race resolves; exactly one → that runner is taya and the Twist never ends the race | `_u3_bomb_finishing_taya_transfer`; room: "U3 the finishing taya is secured" |
| U4 | K+L | Timer after a taya timeout when finishers exist | Fresh timer for **N = unfinished live runners remaining after the elimination** (secured excluded); N = 1 uses the 2-alive value (7 s) | `_u4_bomb_timer_after_timeout_with_finishers` |
| U5 | K+L, K+Kg | Karera deadline on the same step as a Twist terminal | The Twist terminal commits first and keeps its cause; the deadline then fails the remaining runners; pending Twist commands are cancelled with no failure | `_u5_deadline_vs_twist_terminal` |
| U6 | K+Kg | Goal touch on the same step as a third failure | The third failure wins (eliminated, `command_failure`, no hazard credit); a first/second marker is moot once secured | `_u6_goal_vs_third_failure`; room: K+Kg "goal and third failure" |
| U7 | K+Kg | Commands with ≤ 1 unfinished runner | Commands continue for the last unfinished runner (Freeze/Rising only; Hug excluded under two unfinished runners); a Twist never ends the round | `_u7_commands_with_one_runner` |
| U8 | K+Kg | Storm cadence | Storm is not active when Kangaroo is a Twist; response/reset acceleration still applies | `_u8_no_storm_as_twist` |
| U9 | Kg+L | Several terminal causes for one seat on one step | Order by recorded time, then cause rank command failure < timeout < direct hazard; an incomparable-time hazard ranks last; one outcome per player | `_u9_multi_cause_rank`; room: "multiple terminal causes" |
| U10 | Kg+L | Command failure eliminates the taya or the pass target on a contact step | Failure eliminations join the batch first: an eliminated taya is not passed to (new taya, fresh timer for the new count); an eliminated target is removed before pass selection | `_u10_bomb_failure_before_pass`; room: "multiple terminal causes" |
| U11 | Kg+L | Tag pass during an active Hug response | Allowed; Hug evaluation and pass are independent | `_u11_bomb_pass_independent_of_hug` |
| U12 | all | Mixed producers in one placement batch | No new rule: all records feed the unchanged `PlacementScoreResolver` | `_u12_mixed_producers_one_batch`; room: Last Cluck |
| U13 | all (network) | A reserved seat's 60 s reconnect grace ends during PLAY (NLB-P08, owner-approved 2026-10-21) | Cause `disconnect` ranks with the lowest class, equal to `command_failure`: one no-source elimination (no Patibong), at most once per seat per round; elimination still beats a goal on the same step; it never outranks a hazard or timeout recorded for that seat on that step, and beside a trap the missing source item leaves the cause ambiguous so nobody earns Patibong | `run_nlb_p08_tests.gd` `_test_disconnect_elimination_paths` (authored, not run) |

**Callback-order permutations:** `_bomb_permutations` re-runs a four-seat same-step batch (two traps, a pass contact, a finisher) with reversed hazard, contact and finisher order (six variants) and the ledger with reversed/rotated candidate order (four variants); every variant yields the identical outcome set.

## Dated note — U4 example

The draft table's U4 *scenario* line said "4 seats: 1 finisher, taya times out → assert 3-alive timer (10 s)". With one finisher secured and the taya eliminated, **two** unfinished live runners remain, so the approved rule text ("N = unfinished live runners, secured excluded") gives the 2-alive value (7 s). The implementation and test follow the approved rule text; the 10 s example was an arithmetic slip in the draft scenario line. With no finisher the standard rule applies (four alive, one times out → 3 → 10 s) and is tested separately. If the owner intended the 10 s value, the one-line change is `timeout_seconds_by_alive` (the 1-runner entry) in `BombTayaTwist.advance_step` (the `_assign_new_taya` call after a timeout).

## Mapping from the draft table

| Draft row | Resolution |
|---|---|
| K1 (timeout and goal, same step) | U1 — timeout eliminates |
| K2 (timeout and trap, same step) | C4 — a strictly earlier comparable trap wins with its Patibong; a tie or later trap is the timeout. **Implemented 2026-10-15** (the pre-approval build gave no credit whenever a timeout was present) |
| K3 (taya tags while reaching the flag) | U2/U3 — goals commit first; the finishing taya hands the bomb to a random unfinished runner; its own contact is not replayed as a pass. **Implemented 2026-10-15** (the draft behaviour let the tag stand) |
| K4 (new taya finishes the same step) | U2/U3 — the draw excludes runners finishing this step. **Implemented 2026-10-15** |
| K5 (one live runner, which timer) | U3/U4 — the 2-alive value (7 s) |
| K6 (bubble-captured runner as taya) | Not a same-step ordering case; unchanged and still open for team review |
| K7, K8 | Sourced, unchanged |
| C1–C2 (command/third marker vs goal) | U6 — the third failure wins; a first/second marker is moot once secured |
| C3 | C7 — sourced |
| C4 (support vs Rising evaluation) | C8 — sourced (SP:203: destroyed support is absent) |
| L1 (failure vs timeout, clocks) | U9 — recorded-time order with rank failure < timeout < trap; the Bomb-Taya clock and the director clock both start at Play start and advance by the same step, and the room feeds the timeout to Kangaroo with its comparable time |
| L2 (timeout and Freeze violation, same seat) | U9 |
| L3 (tag during Freeze) | C14/C15 — sourced |
| L4 (everyone eliminated) | U12 — Last Cluck, unchanged resolver |
