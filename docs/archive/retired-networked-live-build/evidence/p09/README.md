# NLB-P09 — replicated results, sudden death, replay, lobby return and teardown (preparatory)

## Status

**Date:** 2026-10-21. **Base revision:** `b048e0c`. **Author:** Claude Code (Claude Sonnet 5.5, `claude-sonnet-5-5`) at the user's direction. **Reviewer:** none; no human review is claimed. **Contract:** [v1.6](../p00/protocol-measurement-contract-v1.6.md). **Matrix:** [compatibility-matrix.md](../p07/compatibility-matrix.md) (three new `life` cells).

This is authored source and tests only. Nothing ran while the shared laptop was in use: no Godot editor, game, headless run, import, parse, test suite, multi-process or phone session, ADB, network listener, capture, lint or performance measurement. Every check below is `COULD-NOT-RUN — deferred while the shared laptop is in use`. All three P09 tracker boxes stay unchecked. P07-T03 and P08-T03 (and upstream P03-T03, P04-T03, P05-T02/T03, P06-T03) remain open; the authorization to build preparatory source clears none of them.

User decisions applied (2026-10-21): **Replay is an in-place re-key** (new epoch and match ID over the open connections after a full match-session teardown); **a deliberate client Leave forfeits the seat at once** instead of holding it for 60 s.

## What it does

| Situation | Behavior |
|---|---|
| A round ends | The host ledger commits one ROUND entry (per-seat outcome, cause, owner, placement, delta and total in eighth-point units, award segments, suppression, Last Cluck, Barya seat, lifecycle decision). It goes once to every synchronized peer and is repeated after every sync. The client model refuses anything that breaks the ledger rules. |
| Match ends by score target or round limit | A ROUND entry with decision WINNER, then a FINAL entry (winner, Last Cluck, totals). No round follows. |
| Tied leaders | A ROUND entry with decision SUDDEN_DEATH, an SD_ENTRY (no deltas), an SD_RESULT and a FINAL entry. Totals never change after the tie. The phone shows "Sudden Death", not "Round 13". |
| Resync or reclaim | The complete ledger rides the snapshot, so the results and exact totals return with it. |
| Phone result controls | Continue (round), Replay / Return to Lobby votes and Leave (final). The host counts them with the offline agreement rule; a reserved seat never blocks. |
| Replay | Roster of connected players (lost remote seats released; fewer than two refuses), `REKEY` under the old epoch, new epoch and match ID, every container/reservation/token/pause epoch cleared, existing room reset and start, per-peer ack then lifecycle and snapshot. |
| Return to Lobby | `stop_session(LOBBY_RETURN)`; the host lands on the LAN lobby; phones show why and return to the lobby. |
| Host Quit | `stop_session(HOST_QUIT)` before the process exits. |
| Client Leave | Local stop; the host forfeits the seat (one disconnect elimination at the next safe boundary, no Patibong). |
| Host loss (abrupt) | The client sees the transport loss as `HOST_LOST`, shows the session-ended screen and returns to the lobby. |

## Implemented source

- **Wire (contract v1.6):** `network_frame.gd` (schema 6, mask `0x07FF`, families `0x22`–`0x26`, `peek_epoch`), `network_results_codec.gd` (new), `network_lifecycle_codec.gd` (re-key, ack, 11-byte host close), `network_match_codec.gd` (`RECORD_LEDGER`, snapshot cap 288), `compatibility_manifest.gd` (build `tilaok-nlb-p09-2026-10-21`), `nlb_live_compatibility_matrix.gd` (three `life` cells).
- **Host ledger and vote:** `result_ledger.gd` (new), `p09_match_lifecycle_room.gd` (ledger hooks, vote, replay roster and handler, host commands), `p12_scheduled_match_room.gd`, `player_seat_registry.gd` (`release_unconnected_remote_seat`), `seat_reservation_book.gd` (`rekey`, `retain_only`, `forfeit`).
- **Session:** `network_session_manager.gd` (results send/receive/dedupe, vote, result action, replay re-key, retired epochs, `_clear_match_scope`, match-ID lineage, session-end reasons, forfeit, teardown fixes, `teardown_counts()`).
- **Client:** `network_results_model.gd` (new), `network_results_overlay.gd` (new), `network_match_presentation.gd` (overlay, sudden-death label, units-based score text), `game_flow.gd` (session-ended handling, host lobby/title/quit routes, authority restore).
- **Tests:** `tilaok!/tests/run_nlb_p09_tests.gd`, `tilaok!/tests/audit_nlb_p09_cycles.gd`, `tilaok!/tests/run_nlb_p09_multi_process.gd`; schema/build/cell-count expectations updated in `run_nlb_p04_tests.gd`, `run_nlb_p06_tests.gd`, `run_nlb_p07_tests.gd` and `run_nlb_p08_tests.gd`.

## Interpretations a reviewer should confirm

- **Replay is a match-session teardown, not a socket teardown.** Spec §3.3 says "session teardown precedes a new session identity". The implementation clears every match-scoped container, reservation, token and the pause epoch before minting the identity, but keeps the ENet connections. Return to Lobby is the full `stop_session`. The user chose this; the alternative (full rehost with a new room code) is a cheap fallback.
- **Match ID is a lineage counter** (never reused within a host session), stricter than the v1 row. Attempt ID keeps its v1.2 meaning.
- **A replay needs two connected players.** Lost remote seats are released at that moment; a lost local device blocks it.
- **Remote confirm/back/navigation are not accepted in Results.** This closes a path where a phone could open the host's leave dialog and pause the tree. Results travel only through `RESULT_ACTION`.
- **A spectator host commits the result planks by host authority.** Phones cannot veto it.
- **A deliberate Leave forfeits at once.** The player cannot come back for that match even within 60 s.
- **A schema-5 peer is refused at hello.** The previous P06 hello check for "schema 4 admitted" was stale after P08 and now names the current schema.
- **`round_id` on the wire is unchanged** (the completed round plus one outside Results); the phone derives "Sudden Death" and "Final results" from the ledger instead, so the P08 per-round reservation marks are untouched.

## Unverified limits and known gaps

- **Event rounds use `joined_seats()`** while Karera uses `original_seat_indices` (`p12_scheduled_match_room.gd:436`); the entry follows whichever the calculator used. Not changed.
- **`reset_room()` must fully reset a non-default arena** for an in-place replay. The ten-cycle audit is the check; if it fails, replay on that map must fall back to the old flow request (`REPLAY_UNAVAILABLE`).
- **The phone screens are minimum code-drawn panels.** Touch targets, dp scaling, safe areas and accessibility are P10 work. No human or rendered review.
- **No reconnect or leave button on the match HUD beyond the results screens.**
- **Kangaroo main rounds are still not wired** to the disconnect elimination (P08 gap).
- **A mid-replay peer loss** shrinks the roster after the room restarted; the match continues through the existing disconnect-elimination path.
- **`SESSION_CLOSE` may not flush** when the host process is killed or the OS closes the window; the client then sees a transport loss (`HOST_LOST`).
- **No `.gd.uid` files** were created for the new scripts; the editor creates them on first import.
- **No parse or lint has run,** so a syntax error is possible. gdlint/gdformat are not installed.
- **Not claimed:** any result, replay, loss, phone, rendered or performance result.

## Deferred commands

Godot is `C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe` (GUI build; use `--log-file`). Replace `<project>` with `C:\Users\Mist\Downloads\Tilaok\tilaok!` and `<log>` with a log path. Run only when the user says the laptop is free.

| Purpose | Command |
|---|---|
| Import / parse | `C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe --headless --path <project> --log-file <log> --import` |
| P09 suite | `C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe --headless --fixed-fps 60 --path <project> --log-file <log> --script res://tests/run_nlb_p09_tests.gd` |
| Ten-cycle audit | `C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe --headless --fixed-fps 60 --path <project> --log-file <log> --script res://tests/audit_nlb_p09_cycles.gd` (writes `docs/evidence/nlb/p09/p09_cycle_audit.json`) |
| Ending matrix (spawns a host+client pair per scenario) | `C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe --headless --fixed-fps 60 --path <project> --log-file <log> --script res://tests/run_nlb_p09_multi_process.gd` |
| One scenario, host only, real phone | `C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe --headless --fixed-fps 60 --path <project> --log-file <log> --script res://tests/run_nlb_p09_multi_process.gd -- phone <ending> <exit>` (ending: `target`, `round_limit`, `tie_sd`; exit: `replay`, `lobby`, `host_quit`, `abrupt_kill`, `client_leave`; writes `user://p09-phone-invite.txt`) |
| Regressions | the same command with `res://tests/run_nlb_p01_tests.gd` … `run_nlb_p08_tests.gd`, `run_nlb_p08_multi_process.gd`, `run_p09_interactive.gd`, `audit_p09_restarts.gd`, `run_p09_tests.gd`, `run_p12_tests.gd`, `run_p12_pairs`/`run_p12_stack` runners, `run_barya_tests.gd`, `run_match_ui_tests.gd`, `run_match_ui_mode_tests.gd`, `run_p13_navigation_tests.gd` |
| Lint | `gdlint` / `gdformat --check` (tools absent; do not install without approval) |
| Android | export/install an APK from this revision; a P08 APK is refused at hello |

## Check record

| Check | Result | Reason / evidence |
|---|---|---|
| Godot import/parse of new and changed scripts | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| gdlint / gdformat | COULD-NOT-RUN | Tools absent; deferred |
| `run_nlb_p09_tests.gd` | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| `audit_nlb_p09_cycles.gd` (ten cycles) | COULD-NOT-RUN | Deferred; synthetic only |
| `run_nlb_p09_multi_process.gd` (eight ending scenarios) | COULD-NOT-RUN | Deferred; synthetic only |
| Regressions NLB P01–P08, P09 interactive/audit, P12, Barya, match UI, P13 navigation | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| Physical mixed-device ending sessions | COULD-NOT-RUN | Needs a real phone, an APK from this revision and a named reviewer |
| Android export/install | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| `git diff --check`, review against GDD §5, the P12 terminal-order table and v1 §4, and a grep audit (no hard-coded match ID 1; every new family allowlisted, channel-mapped, validated and dispatched; host-only families refused from clients; teardown clears every container `teardown_counts()` lists) | Done | Source review only; not runtime evidence |

## Ten-cycle ledger (template)

One row per cycle from `NLB_P09_CYCLE_LEDGER` and `p09_cycle_audit.json`. Replace the empty cells with the audit's actual output; never fill them by hand.

| Cycle | Ending | Exit | Ledger revision | Host = client | New match ID / epoch | Seats | Peers | Caches (`teardown_counts` non-zero keys) | Entities | Transients | Pending requests | Objects | Static memory | Result |
|---:|---|---|---:|---|---|---:|---:|---|---:|---:|---:|---:|---:|---|
| 1 | score target | replay | | | | | | | | | | | | |
| 2 | sudden death | replay | | | | | | | | | | | | |
| 3 | score target | lobby | | | | | | | | | | | | |
| 4 | sudden death | replay | | | | | | | | | | | | |
| 5 | score target | replay | | | | | | | | | | | | |
| 6 | sudden death | lobby | | | | | | | | | | | | |
| 7 | score target | replay | | | | | | | | | | | | |
| 8 | sudden death | replay | | | | | | | | | | | | |
| 9 | score target | lobby | | | | | | | | | | | | |
| 10 | sudden death | replay | | | | | | | | | | | | |

Pass needs: no retained score, stage, token, actor, request, input or stale snapshot state after any cycle; object count within five and static memory within 1 MiB of the warmed baseline.

## Physical session sheet (template)

Record build/revision, engine, date, profile and seed, player count, actual devices versus synthetic seats, network conditions, timings, the procedure, expected versus actual, artifacts and the **actual reviewer**. Only PASSED, FAILED or COULD-NOT-RUN. Synthetic seats are never physical evidence. Preserve failures.

| Step | Expected | Actual | Result |
|---|---|---|---|
| Play to the score target with phones | Round results and the match result show the same winner and exact scores as the PC; Continue and Replay/Lobby votes are counted | | |
| Play to round 12 with one leader | Winner by the round limit; no round 13 | | |
| Tied leaders at round 12 | "Sudden Death" label, no score change, one winner, final result matches the host | | |
| Replay (host or phone vote) | New match; every phone re-keyed without re-scanning; scores zero; no stale stage or banner | | |
| Return to Lobby | Phones show "The host returned everyone to the lobby" and land on their lobby screen | | |
| Host Quit | Phones show "The host quit the game" and return | | |
| Phone Leave | The phone returns to its lobby; the host forfeits the seat once, no Patibong | | |
| Kill the host process (or pull the host Wi-Fi) | Phones show the lost-host screen and return; none stays on a stale match view | | |
| Ten Replay / Lobby cycles | No growth in objects, memory or seats; same scores each match | | |
