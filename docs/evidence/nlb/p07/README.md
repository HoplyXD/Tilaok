# NLB-P07 evidence — all-content live compatibility matrix and special-case replication

**Date:** 2026-10-21. **Base revision:** `1353427` (main, level with origin/main before this delivery). **Author:** Claude Code (Claude Opus 5.5, `claude-opus-5-5`), at the user's direction, as preparatory source under the standing AI-assisted programming workflow. **Reviewer:** none; no human review is claimed. **Contract:** [v1.4](../p00/protocol-measurement-contract-v1.4.md). **Matrix:** [compatibility-matrix.md](compatibility-matrix.md).

## Status

**P07 is 0/3 checked; it is not complete.**

The user authorized preparatory implementation only. The shared laptop was in use, so nothing was launched: no Godot editor, game, headless run, script, import, export, test, multi-process runner, ADB, listener or capture. Every task's actual result is `COULD-NOT-RUN — preparatory source only; deferred while the shared laptop is in use; P06-T03 and upstream dependencies open`.

That authorization clears none of the open dependencies:
- P06-T01/T02/T03: COULD-NOT-RUN.
- P05-T02/T03: COULD-NOT-RUN.
- P04-T01/T02/T03: COULD-NOT-RUN.
- P03-T02/T03: user-reported pass; retained evidence incomplete.

**User decisions recorded for this delivery (2026-10-21):**
- **Unverified content:** strict default-deny plus a dev-only host override (`-- --nlb-unverified-content`). The alternative, leaving the P06 slice "engineering-enabled", was not chosen.
- **Explosives:** detonate at the host commit boundary. No new fuse is added.
- **Shipping:** all slices in one delivery, as separate commits, with no co-author or AI trailer in commits.

## What the matrix does

The matrix has 91 cells:
- 6 lifecycle cells;
- 4 map cells;
- 10 round cells (Mains, stacks, sudden death and the Kangaroo commands);
- 70 variant × allowed-mode cells, plus Barya.

84 cells are ENGINEERING, 7 are DISABLED, and none is VERIFIED. The full table, the enforcement points and the §6.2 coverage are in [compatibility-matrix.md](compatibility-matrix.md).

Consequences:
- **Strict host (the default):** it cannot start a networked live match. The lobby says why and names the override.
- **Scheduled route:** the scheduled P12 network route (the default) and both offline routes behave as before. The offline live route still deals exactly the P05 slice.
- **Development host:** a host started with the override plays ENGINEERING cells. Its clients show "UNVERIFIED CONTENT — development host; results are not evidence."

## Implemented source (unverified)

| Commit | Area | Files |
|---|---|---|
| `feat(network): add P07 live compatibility matrix` | Matrix, enforcement, identity | `tilaok!/scripts/network/nlb_live_compatibility_matrix.gd` (new), `compatibility_manifest.gd`, `network_session_manager.gd` (start gate, lobby summary), `scripts/match/nlb_p05_live_build_match_room.gd` (allowlist removed), `nlb_p06_network_live_build_match_room.gd` (per-round pool, schedule, Barya, start and commit gates), `p12_scheduled_match_room.gd` (`schedule_pairs()` hook), `match_room.gd` (`_prepare_pugad_pool()` hook), `scripts/flow/game_flow.gd` (flag, effective map), `scripts/ui/ui_lan_lobby_screen.gd` (host content list); P06 test fixture and multi-process runner opt into the override |
| `feat(network): add P07 transient wire records` | Contract v1.4 | `network_frame.gd` (schema 4, `0x01FF`), `network_match_codec.gd` (records 6/7, caps, `decode_record`), `network_placement_codec.gd` (details 41–49), `network_session_manager.gd` (11-byte lifecycle, transient send/end/stale, overflow → resync / SNAPSHOT_LIMIT), `network_match_presentation.gd` (draw transients, banner), `p12_scheduled_match_room.gd` (`network_transient_states()` hook), `nlb_p06_…` (transient collector, blast flashes), contract v1.4 and v1.3 forward link, P04/P06 test version updates |
| `feat(network): replicate P07 item special cases` | §6.2 items | `scripts/items/item_manager.gd` (Walis crash fix, entity age), `nlb_p05_…` (`_live_effect_check`, in-flight rects, one-shot hook), `nlb_p06_…` (blast replication), `network_session_manager.gd` (entity-less one-shot acceptance) |
| `feat(network): enforce P07 event and lifecycle cases` | §6.2 events | `nlb_p05_…` (Barya rejection code, same-tick ordering audit) |
| `test(network): author P07 matrix suite and runner`, `test(network): correct P07 matrix cell count` | Tests (authored, not run) | `tilaok!/tests/run_nlb_p07_tests.gd`, `tilaok!/tests/run_nlb_p07_matrix_runner.gd` |

New `.gd` files have no `.uid` sidecars yet. Godot generates them on the first import, which was not run.

**Changes worth reviewing because they touch shared paths:**
- **Shared hooks:** `match_room.gd` (`_prepare_pugad_pool`) and `p12_scheduled_match_room.gd` (`schedule_pairs`, `network_transient_states`) gain no-op hooks. Default rooms behave as before.
- **Wire:** schema 4 and the 11-byte `MATCH_LIFECYCLE` apply on **both** network routes. A P06 binary is refused at hello.
- **`ItemManager.apply_live_one_shot`** (reached only from the live rooms):
  - It no longer crashes on `bool(Array)`.
  - It no longer refuses an area that touches protected geometry; it excludes that geometry, as offline does.
  - It may remove this round's pieces committed at an earlier boundary. That is §6.2 entity age.
- **Wire mapping:** `one_shot` is now an OK acceptance. It had been missing from `CODE_TABLE` and would have failed closed as INTERNAL_RETRY.
- **Shared refusal replaced:** the global "any projectile or bubble exists" refusal on the live route is replaced by a geometric check. The offline live route's P05 slice never has projectiles, so it behaves the same.
- **Map:** `GameFlow` computes the match map in one helper (`_match_map_id`). The live start gate checks the map the match will actually load: the Tutorial while the tutorial is pending, and the Tutorial is disabled here.

## Interpretations a reviewer should confirm

1. **Walis/explosive "previously committed".** This means committed at an earlier host authority boundary, including earlier in the same round. Offline Walis spares every same-Place piece, because offline there is one shared Place batch.
2. **Rising "same evaluation tick".** Contract v1.3 §3 resolves terminal outcomes before the tick's edits. Rising at tick N therefore sees every edit accepted before N, and a removal invalidates support at once (P12 C8). The order was not changed.
3. **Override is not in the digest.** Folding it in would make every Android client (which can never set it) incompatible with a development host. It is announced in the lifecycle flag and logs instead.
4. **Lethal clearance values are tuning, not design.** The extra lethal reach is 64 wu and the fall path is 2 cells. They are proposed and unmeasured.

## Unverified limits and known gaps

- **No runtime result exists.** Parse/import, both P07 runners, every regression, the physical mixed-device matrix, export and performance are all COULD-NOT-RUN.
- **No lint:** `gdlint`/`gdformat` are absent (tool absent; not installed). Style was followed by hand.
- **Matrix runner coverage:**
  - It compares round cells at 2/3/4 seats with scripted goals and synthetic traps. It does not yet place real items on the live route, script a Barya pickup, a map transition or a Rising/Hug command outcome, or run a full 12-round match.
  - Those cells rely on the shared rules plus the offline suites (`run_barya_tests`, `run_p12_pairs_tests`, `run_item_mode_integration_tests`) until per-cell scripts are added.
- **Transient visuals** are code-drawn placeholders: a shape and a glyph, never colour alone. No art or audio was produced.
- **Client mismatch message:** a matrix mismatch shows the existing "does not match the host build" text, because the digest cannot name the cause.
- **No release preset:** there is no release export preset yet (P11). The override is ignored under the `release` feature tag, which is Godot's release template, but not under a debug-template export.
- **Wire IDs:** transient wire IDs wrap at 65,535 and skip IDs still in use.
- **Performance and bandwidth** are PROPOSED/UNMEASURED. The ~8.3 KB worst-case snapshot is arithmetic only.

## Deferred commands (run only when the user says testing is safe)

These use the GUI build on this machine. Its stdout is not attached to a console, so `--log-file` captures output. Substitute the console build if one is provided.

```powershell
$godot = 'C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe'
$project = 'C:\Users\Mist\Downloads\Tilaok\tilaok!'
$logs = 'C:\Users\Mist\Downloads\Tilaok\build\nlb-p07-logs'   # ignored build output; create when testing
# 1. Parse/import (first; also creates .uid sidecars for the new scripts)
& $godot --headless --path $project --import --log-file "$logs\import.log"
# 2. Focused P07 suite
& $godot --headless --fixed-fps 60 --path $project --log-file "$logs\p07-tests.log" --script res://tests/run_nlb_p07_tests.gd
# 3. Matrix runner (2/3/4 seats inside one run; synthetic evidence only)
& $godot --headless --fixed-fps 60 --path $project --log-file "$logs\p07-matrix.log" --script res://tests/run_nlb_p07_matrix_runner.gd
# 4. Regressions
foreach ($suite in 'run_nlb_p01_tests','run_nlb_p02_tests','run_nlb_p03_tests','run_nlb_p04_tests','run_nlb_p05_tests','run_nlb_p06_tests','run_p12_tests','run_p12_pairs_tests','run_p12_stack_tests','run_barya_tests','run_explosives_tests','run_item_mode_integration_tests','run_maps_tests','run_blocks_tests','run_p10_tests','run_p19_promoted_tests','run_controls_tests','run_match_ui_tests','run_p13_navigation_tests') {
  & $godot --headless --fixed-fps 60 --path $project --log-file "$logs\$suite.log" --script "res://tests/$suite.gd"
}
# 5. Multi-process live slice (host + headless client + synthetic K1; runs under the override), twice
& $godot --headless --fixed-fps 60 --path $project --log-file "$logs\p06-slice-1.log" --script res://tests/run_nlb_p06_multi_process.gd
& $godot --headless --fixed-fps 60 --path $project --log-file "$logs\p06-slice-2.log" --script res://tests/run_nlb_p06_multi_process.gd
# 6. Manual development host for the physical matrix (PC host; phones join from the LAN lobby)
& $godot --path $project -- --match-route=network_live_build --nlb-unverified-content --match-seed=7307
```

Lint, if a tool is later approved: `gdlint` and `gdformat --check` over the changed files. Android export and install use the P03 block in [P03 evidence](../p03/README.md) with this path substituted. The phone needs an APK built from this revision, because a P06 APK is refused at hello.

Each check stays `COULD-NOT-RUN — deferred while the shared laptop is in use` until it actually runs. Record `PASSED`, `FAILED` or `COULD-NOT-RUN` only. Runner output is SYNTHETIC evidence and is never physical-device evidence. Any result produced under `--nlb-unverified-content` is development evidence and does not by itself make a cell VERIFIED.

A cell becomes VERIFIED only through a reviewed matrix change. That change adds the cell's evidence reference to `EVIDENCE` and flips its status. The digest changes with it.

## Check record

| Check | Result | Reason / evidence |
|---|---|---|
| Godot import/parse of new and changed scripts | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| gdlint / gdformat | COULD-NOT-RUN | Tool absent and not to be installed; deferred |
| `run_nlb_p07_tests.gd` | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| `run_nlb_p07_matrix_runner.gd` (2/3/4 seats) | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| Regressions P01–P06, P12, pairs/stack, Barya, explosives, item/mode, maps, blocks, P10, P19, controls, match UI, P13 navigation | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| Multi-process live slice ×2 | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| Physical mixed-device matrix (2/3/4 total players) | COULD-NOT-RUN | Deferred; P03-T03/P06-T03 also open |
| Android export/install | COULD-NOT-RUN | Deferred while the shared laptop is in use |
| `git diff --check`, grep audit (no hard-coded live allowlist; every catalog key/mode/map enumerated), manual §6.2 / GDD §5 review | Performed | Quiet checks only; see the final delivery report |

## Physical session sheet (template — fill only from an actual run)

| Field | Value |
|---|---|
| Date / time zone | |
| Build revision (commit) and APK SHA-256 | |
| Engine (exact Godot executable) | |
| Route / override / profile / seed | `network_live_build` / `--nlb-unverified-content` (yes/no) / `nlb_p06_network_live_build` / |
| Total players (2/3/4) and devices | Host PC: · Android model/OS per phone: · Local PC input (keyboard layout or gamepad model): |
| Input type per seat (physical vs synthetic) | |
| Network topology / Wi-Fi conditions | |
| Cells exercised (ids from the matrix) | |
| Procedure | Lobby → ready → start → per round: Pugad → GO → movement + live placement → result; include each exercised item family, a stack round, a Lagsanay round, Barya pickup/drop, Walis/explosive edit, one projectile and one bubble, and a map transition (new match) |
| Expected | Only matrix-selectable content dealt; host/client stage versions, entity IDs and transients agree; no client-decided outcome; exact eighth-point totals equal the offline rules for the same events |
| Actual (run 1) | |
| Actual (run 2) | |
| Score comparison (host totals vs offline expectation) | |
| Host log, client logs, captures/video paths | |
| Result (PASSED / FAILED / COULD-NOT-RUN) | |
| Actual reviewer (name/role) | |
