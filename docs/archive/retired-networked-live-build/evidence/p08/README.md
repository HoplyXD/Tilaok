# NLB-P08 — host pause, phone lifecycle, seat reservation/reclaim and resync (preparatory)

## Status

**Date:** 2026-10-21. **Base revision:** `782d9bd`. **Author:** Claude Code (Claude Sonnet 5.5, `claude-sonnet-5-5`) at the user's direction. **Reviewer:** none; no human review is claimed. **Contract:** [v1.5](../p00/protocol-measurement-contract-v1.5.md). **Matrix:** [compatibility-matrix.md](../p07/compatibility-matrix.md) (three new `life` cells).

This is authored source and tests only. Nothing ran while the shared laptop was in use: no Godot editor, game, headless run, import, parse, test suite, multi-process or phone session, ADB, network listener, capture, lint or performance measurement. Every check below is `COULD-NOT-RUN — deferred while the shared laptop is in use`. All three P08 tracker boxes stay unchecked. P06-T03 and the upstream P03-T03, P04-T03 and P05-T02/T03 dependencies remain open, and the authorization to build preparatory source clears none of them.

## What it does

| Situation | Behavior |
|---|---|
| Host pauses (host-local input only) | The tree freezes simulation, physics, event clock, item grace, transient and phase timers. The session manager advances a monotonic pause epoch and sends `PAUSE_STATE` to every synchronized peer (1 Hz heartbeat while paused, and after every `SYNC_READY`). The host's input-timeout clock freezes too. Clients show "PAUSED BY HOST" and hold their timer. Resume follows the host's own seats; remote seats are not required to ready. |
| A client pauses | Only a local overlay opens. A `PAUSE_STATE` frame from a client is refused `HOST_ONLY` and never applied. |
| Client focus loss / background / Android pause | One neutral sample and one hint (≤2/s) leave immediately, the held state is zeroed and streaming stops. The host also neutralises the peer on the hint, and ignores held input from a backgrounded peer. The host's 150 ms timeout remains the authority because Android may not deliver the callback. |
| Client returns | A fresh neutral sample and a foreground hint; a full snapshot is requested if the last host state is older than 2 s. |
| Transport loss during a match | The seat is reserved for 60 s: seat, Player ID and score stay, input is neutral. The lobby behavior (release) is unchanged. |
| Reclaim | New connection → compatibility hello → `RECLAIM_BEGIN` → challenge → HMAC proof in the reclaim context → token rotates, new peer generation → `RECLAIM_RESULT` → `MATCH_LIFECYCLE` + current snapshot → snapshot ack → the seat is rebound at a host packet boundary, input gated on a fresh neutral sample. |
| Join while a seat is reserved | A new peer cannot take it: the lobby-only rule stands, and `JOIN_BEGIN` in the reclaim window is refused `LOBBY_CLOSED`. |
| Grace ends in a round | One `disconnect` elimination for that seat in that round (no Patibong), through the Karera ledger or the Lagsanay controller (also Sudden Death). The identity stays reserved. |
| Reclaim after expiry | Accepted at any phase except PLAY; refused `WRONG_PHASE` during PLAY. |
| Pugad / Place expiry | No elimination; the existing timeout assignment covers the unclaimed item. |
| Fewer than two connected | The round continues; no automatic pause; reservation clocks keep running. |
| Results | A reserved seat never blocks the round results on the network. |

## Implemented source

- **Wire (contract v1.5):** `network_frame.gd` (schema 5, mask `0x03FF`, families `0x1E`–`0x21`), `network_lifecycle_codec.gd` (new), `invitation_code.gd` (`auth_context`), `compatibility_manifest.gd` (build `tilaok-nlb-p08-2026-10-21`), `nlb_live_compatibility_matrix.gd` (three `life` cells).
- **Pause and lifecycle:** `network_pause_controller.gd` (new), `network_session_manager.gd`, `pause_recovery_coordinator.gd` (`remote_ready_exempt`), `network_match_presentation.gd`.
- **Reservation and reclaim:** `seat_reservation_book.gd` (new), `player_seat_registry.gd`, `remote_seat_input_adapter.gd`, `network_session_manager.gd`.
- **Elimination and results:** `race_outcome_ledger.gd` (`CAUSE_DISCONNECT`), `lagsanay_round_controller.gd` (`submit_disconnect`), `p12_scheduled_match_room.gd` (`network_commit_disconnect`), `match_room.gd` and `p09_match_lifecycle_room.gd` (`network_exempt_unconnected_seats`, `network_recheck_results`).
- **Tests:** `tilaok!/tests/run_nlb_p08_tests.gd`, `tilaok!/tests/run_nlb_p08_multi_process.gd`; schema/build/cell-count expectations updated in `run_nlb_p04_tests.gd`, `run_nlb_p06_tests.gd` and `run_nlb_p07_tests.gd`.

## Interpretations a reviewer should confirm

- **Cause rank:** `disconnect` is ranked with the lowest class, equal to `command_failure`, as the user approved on 2026-10-21 (table row U13, GDD §5). Beside a trap on the same step it leaves the cause ambiguous, so nobody gets Patibong.
- **An unclaimed seat is eliminated in each later round it is absent** (the contract row only says "that round"). This keeps a ghost from stalling a round.
- **Pause heartbeat instead of a metadata field:** pause is repeated as a 1 Hz `PAUSE_STATE` while paused and after every sync, plus the existing `paused` flag, not as a new field in periodic state. This leaves the metadata decoder untouched.
- **The `await_neutral` rejection became a silent drop,** because the old rejection released the seat.
- **Reserve on any rejected frame:** a rejected frame from an assigned peer now reserves the seat in a match (it used to release it).

## Unverified limits and known gaps

- **Android process kill:** the reclaim token is memory only. If Android kills the app the token is lost and that player cannot reclaim. This is by design (no persistence) and the user confirmed it on 2026-10-21. The seat runs out its grace and the player is eliminated for the round.
- **Wi-Fi loss:** a reclaim is possible only after the host's transport notices the loss and reserves the seat; until then the host refuses the attempt and the client retries.
- **No reconnect or pause UI:** the client exposes `client_reclaim_available()` / `connect_reclaim()` but no button (touch HUD is P10). A host without a local seat has no in-game resume control (P10 host/touch HUD; P09 added only the PC result-plank controls).
- **Kangaroo main rounds are not wired** to the disconnect elimination; a neutral seat fails its own commands. Karera, Bomb-Taya, Lagsanay and Sudden Death are wired.
- **The token travels once in the assignment and once in the rotation result,** on a trusted LAN with no encryption.
- **No `.gd.uid` files** were created for the new scripts; the editor creates them on first import.
- **No parse or lint has run,** so a syntax error is possible. gdlint/gdformat are not installed.
- **Not claimed:** any timing, loss/reorder, phone, rendered or performance result, and the ≤5 s reclaim target.

## Deferred commands

Godot is `C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe` (GUI build; use `--log-file`). Replace `<project>` with `C:\Users\Mist\Downloads\Tilaok\tilaok!` and `<log>` with a log path.

| Purpose | Command |
|---|---|
| Import / parse | `C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe --headless --path <project> --log-file <log> --import` |
| P08 suite | `... --headless --fixed-fps 60 --path <project> --log-file <log> --script res://tests/run_nlb_p08_tests.gd` |
| Reconnect runner (host; spawns the client) | `... --headless --fixed-fps 60 --path <project> --log-file <log> --script res://tests/run_nlb_p08_multi_process.gd` |
| Reconnect runner, phone mode | `... --headless --fixed-fps 60 --path <project> --log-file <log> --script res://tests/run_nlb_p08_multi_process.gd -- phone` |
| Regressions | the same command with `res://tests/run_nlb_p01_tests.gd` … `run_nlb_p07_tests.gd`, `run_p02_tests.gd`, `run_p05_tests.gd`, `run_p09_interactive.gd` / audit, `run_match_ui_tests.gd`, `run_match_ui_mode_tests.gd`, `run_p13_navigation_tests.gd`, `run_fix_regression_tests.gd`, `run_p12_tests.gd` |
| Lint | `gdlint` / `gdformat --check` (tools absent; do not install without approval) |
| Android | export/install an APK from this revision; a P07 APK is refused at hello |

## Check record

| Check | Result | Reason / evidence |
|---|---|---|
| Godot import/parse of new and changed scripts | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| gdlint / gdformat | COULD-NOT-RUN | Tools absent; deferred |
| `run_nlb_p08_tests.gd` | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| `run_nlb_p08_multi_process.gd` (host + client, ≥70 s of waits) | COULD-NOT-RUN | Deferred; synthetic only |
| Regressions NLB P01–P07, P02, P05, P09, P12, match UI, P13 navigation, fix regression | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| Physical background / screen lock / Wi-Fi off-on / 60 s expiry / host pause / Android kill | COULD-NOT-RUN | Needs a real phone, an APK from this revision and a named reviewer |
| Android export/install | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| `git diff --check`, manual review against v1 §2/§4 and spec §3.3, grep audit (every new family allowlisted, channel-mapped, rate-limited or refused, validated; no token or proof printed) | Done | Source review only; not runtime evidence |

## Physical session sheet (template)

Record build/revision, engine, date, profile and seed, player count, actual devices versus synthetic seats, network conditions, timings, the procedure, expected versus actual, artifacts and the **actual reviewer**. Only PASSED, FAILED or COULD-NOT-RUN. Synthetic seats are never physical evidence. Preserve failures.

| Step | Expected | Actual | Result |
|---|---|---|---|
| Home button for 10 s mid-race, then return | Neutral at once; seat reserved; return reclaims the same seat and score, no held jump | | |
| Lock the screen for 20 s, unlock | Same | | |
| Lock the screen for 70 s, unlock | One disconnect elimination, no Patibong; identity reserved; reclaim at the next boundary | | |
| Wi-Fi off 10 s, on | Host notices loss, reserves; client reclaims after the host does | | |
| Wi-Fi off 70 s, on | As the 70 s lock | | |
| Host pauses mid-race for 20 s | Every view frozen with the banner; timers equal at resume; no peer times out | | |
| Phone pause button | Local overlay only; the host keeps running | | |
| Stage changes while absent (a piece placed during the absence) | Snapshot on return matches terrain, movers, projectiles, Barya and exact scores | | |
| Kill the app and reopen | Cannot reclaim (expected); cannot join mid-match; the seat expires | | |
| Fewer than two connected | Round continues; no auto-pause | | |
