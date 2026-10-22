# NLB-P06 evidence — network live placement, terrain replication, mixed-device slice

**Date:** 2026-10-21. **Base revision:** `6096775` (main, level with origin/main before this delivery). **Author:** Claude Code (Claude Opus 5.5, `claude-opus-5-5`), at the user's direction, as preparatory source under the standing AI-assisted programming workflow. **Reviewer:** none; no human review is claimed. **Contract:** [v1.3](../p00/protocol-measurement-contract-v1.3.md).

## Status

**P06 is 0/3 checked; it is not complete.** The user authorized preparatory implementation only. The shared laptop was in use, so nothing was launched: no Godot editor, game, headless run, script, import, export, test, ADB, listener or capture. Every task's actual result is `COULD-NOT-RUN — preparatory source only; deferred while the shared laptop is in use; dependencies P03-T03, P04-T03, P05-T03 open.` That authorization clears none of the open dependencies:

- P03-T02/T03: user-reported pass; retained evidence incomplete.
- P04-T01/T02/T03: COULD-NOT-RUN.
- P05-T02/T03: COULD-NOT-RUN.

## How the slice is meant to play

1. The PC host starts the game with `-- --match-route=network_live_build` and opens the LAN lobby as in P02/P04. The phone and a local K1–K4 keyboard or gamepad seat join and ready. Without the flag the scheduled P12 network route runs exactly as before.
2. Start sends `MATCH_LIFECYCLE` with route byte 1. The host loads `nlb_p06_network_live_build_room.tscn`, which is the P05 live round on the P12 schedule.
3. Pugad assigns one item per seat (8 s, then a random fallback). The host issues one inventory ID per seat and enters the shared 3 s GO. During GO, phone input stays bound but is applied as neutral.
4. In Play everyone runs. The phone shows Build, a four-way aim pad, Rotate, Place and Cancel above the existing movement row.
   - Build opens a local dashed **PREVIEW** ghost at the host cursor. The aim pad moves only the ghost; aim axes also steer the host cursor.
   - Place sends one 48-byte intent with a stable request ID. The ghost shows **SENDING…**.
   - The host queues the intent by receipt time and validates it at the next physics boundary with the P05 rules. It sends the versioned terrain commit, then the result.
   - On acceptance the ghost shows **CONFIRMING…** until the committed entity arrives, then disappears. The committed piece is drawn with its real footprint and rotation, plus a dashed hourglass countdown during its safe grace.
   - On rejection the ghost shows **✕** and the localized reason for about 2 s; the item is kept.
5. The local PC seat uses the same pipeline. Its live build keys already reach the room; `live_build_confirm_enabled` lets E/F, Enter, O and Num 0 confirm in Play, and gamepad RT confirms.
6. Results run, then the next Pugad. Accepted construction persists; unused items are discarded at round end. A request still queued when Play ends receives `ROUND_ENDED` once.

## Implemented source (unverified)

| Area | Files |
|---|---|
| Wire and codec | `tilaok!/scripts/network/network_frame.gd`, `network_placement_codec.gd` (new), `network_match_codec.gd` |
| Host integration | `network_session_manager.gd`, `scripts/match/nlb_p06_network_live_build_match_room.gd` (new), `scenes/match/nlb_p06_network_live_build_room.tscn` (new), `nlb_p05_live_build_match_room.gd`, `live_placement_pipeline.gd`, `p12_scheduled_match_room.gd` |
| Route and identity | `scripts/flow/game_flow.gd`, `scripts/network/compatibility_manifest.gd` |
| Input | `scripts/input/local_input_router.gd`, `scripts/input/remote_seat_input_adapter.gd` |
| Client | `scripts/network/network_live_placement_client.gd` (new), `network_match_presentation.gd` |
| Tests (authored, not run) | `tilaok!/tests/run_nlb_p06_tests.gd`, `tilaok!/tests/run_nlb_p06_multi_process.gd`; `run_nlb_p04_tests.gd` wire-version check updated to schema 3 |

New `.gd`/`.tscn` files have no `.uid` sidecars yet; Godot generates them on the first import, which was not run.

Changes worth reviewing because they touch shared paths:

- `TERRAIN_COMMIT` now sends a diff on **both** network routes.
- `MATCH_LIFECYCLE` is now 10 bytes on both routes.
- Unversioned tombstones repeat 3 times instead of once.
- STATE_UPDATE no longer advances the client stage version.
- The `_reject` close path now erases `"peer:family"` keyed sequence and rate tables. Its earlier int-key erase was a no-op.
- Network GO input is neutral only on the live route.
- The client phase label table now matches `MatchPhaseController.Phase`; GO had shown as "Pause".

## Unverified limits and known gaps

- **No runtime result exists.** Parse/import, every suite, the multi-process slice, the phone slice, loss/reorder replay, rendered captures, export and performance are all COULD-NOT-RUN.
- `gdlint`/`gdformat` are not installed (COULD-NOT-RUN, tool absent). Style was followed by hand: tabs, typed GDScript, existing `# gdlint:` pragmas.
- Raw ENet channel 0 is reliable and ordered. Within one session a lost result or commit is simulated in-process; a real loss implies reconnect, which is P08 work.
- The intent's cell is the request. The host cursor follows remote aim axes but can differ from the client ghost. There is no reach rule beyond the P05 validator (P07/P10 decision).
- Per-action rate is 2/s, and live actions are press-only on the wire, so Rotate and Build accept at most 2 presses/s.
- The 44 dp touch target is proposed. The buttons are 72 px; the dp conversion is unverified. Full touch UX, tutorial, dp scaling and the accessibility audit belong to P10.
- `active_match_id = 1` is still hard-coded (`network_session_manager.gd`, `start_network_match`); replay/new match epoch is P09.
- The lobby start-gate text still says "scheduled network match" on the live route.
- No movers, Walis, explosives or hazards are enabled (P07). Lifecycle value 2 is reserved.
- Performance targets stay PROPOSED/UNMEASURED.

## Deferred commands (run only when the user says testing is safe)

These use the GUI build that exists on this machine. Its stdout is not attached to a console, so `--log-file` captures output. Substitute the console build if one is provided.

```powershell
$godot = 'C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe'
$project = 'C:\Users\Mist\Downloads\Tilaok\tilaok!'
$logs = 'C:\Users\Mist\Downloads\Tilaok\build\nlb-p06-logs'   # ignored build output; create when testing
# 1. Parse/import (first; also creates .uid sidecars for the new scripts)
& $godot --headless --path $project --import --log-file "$logs\import.log"
# 2. Focused P06 suite
& $godot --headless --fixed-fps 60 --path $project --log-file "$logs\p06-tests.log" --script res://tests/run_nlb_p06_tests.gd
# 3. Regressions
foreach ($suite in 'run_nlb_p01_tests','run_nlb_p02_tests','run_nlb_p03_tests','run_nlb_p04_tests','run_nlb_p05_tests','run_p12_tests','run_p12_pairs_tests','run_p12_stack_tests','run_barya_tests','run_controls_tests','run_match_ui_tests','run_p13_navigation_tests') {
  & $godot --headless --fixed-fps 60 --path $project --log-file "$logs\$suite.log" --script "res://tests/$suite.gd"
}
# 4. Multi-process live slice (host + headless client + synthetic K1), twice
& $godot --headless --fixed-fps 60 --path $project --log-file "$logs\p06-slice-1.log" --script res://tests/run_nlb_p06_multi_process.gd
& $godot --headless --fixed-fps 60 --path $project --log-file "$logs\p06-slice-2.log" --script res://tests/run_nlb_p06_multi_process.gd
# 5. Physical phone slice, twice (writes user://p06-phone-invite.txt; delete it afterwards)
& $godot --headless --fixed-fps 60 --path $project --log-file "$logs\p06-phone-1.log" --script res://tests/run_nlb_p06_multi_process.gd -- phone
```

Lint, if a tool is later approved: `gdlint` and `gdformat --check` over the changed files. Android export and install use the P03 block in [P03 evidence](../p03/README.md) with this console/GUI path substituted; the phone needs an APK built from this revision. Rendered host and client captures are still to be authored (P04 has no capture runner for the network client).

Each check stays `COULD-NOT-RUN — deferred while the shared laptop is in use` until it actually runs. Record `PASSED`, `FAILED` or `COULD-NOT-RUN` only. Synthetic clients and the synthetic K1 seat are never phone or physical-controller evidence. Preserve failed runs.

## Check record

| Check | Result | Reason / evidence |
|---|---|---|
| Godot import/parse of new and changed scripts | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| gdlint / gdformat | COULD-NOT-RUN | Tool absent and not to be installed; deferred |
| `run_nlb_p06_tests.gd` | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| Regressions P01–P05, P12, P12 pairs/stack, Barya, controls, match UI, P13 navigation | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| Multi-process live slice ×2 | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| Physical phone + local PC slice ×2 | COULD-NOT-RUN | Deferred; P03-T03 evidence also open |
| Loss/reorder/duplicate replay, terrain diff audit | COULD-NOT-RUN | Authored in-process cases; deferred |
| Android export/install | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| Rendered host/client captures | COULD-NOT-RUN | Deferred; capture runner not yet authored |
| `git diff --check`, grep family audit, manual contract review | Performed | Quiet checks only; see the final delivery report |

## Physical session sheet (template — fill only from an actual run)

| Field | Value |
|---|---|
| Date / time zone | |
| Build revision (commit) and APK SHA-256 | |
| Engine (exact Godot executable) | |
| Route / profile / seed | `network_live_build` / `nlb_p06_network_live_build` / |
| Seats (count) and devices | Host PC: · Android model/OS: · Local PC input (keyboard layout or gamepad model): |
| Input type per seat (physical vs synthetic) | |
| Network topology / Wi-Fi conditions | |
| Procedure | Lobby → ready → start → Pugad → GO → movement + live placement → race → results → next Pugad; repeat once more |
| Expected | Stable seat identity; one score commit per seat per round; accepted construction persists; rejected ghosts disappear with a reason; host/client stage versions and entity IDs match; no authority errors |
| Actual (run 1) | |
| Actual (run 2) | |
| Tie/near-simultaneous edit observation | |
| Lost acknowledgment / resync observation | |
| Host log, client log, captures/video paths | |
| Result (PASSED / FAILED / COULD-NOT-RUN) | |
| Actual reviewer (name/role) | |
