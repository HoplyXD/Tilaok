# NLB-P11 — Telemetry, scale fixtures, hardening and release profiles (preparatory)

## Status

- **Date:** 2026-10-21 · **Base revision:** `75108c0` · **Author:** Claude Code (Claude Sonnet 5.5, `claude-sonnet-5-5`) · **Reviewer:** none
- **Spec:** [NETWORKED_LIVE_BUILD.md](../../NETWORKED_LIVE_BUILD.md) · **Tracker:** [PHASETASK_NETWORKED_LIVE_BUILD.md](../../PHASETASK_NETWORKED_LIVE_BUILD.md) (NLB-P11-T01..T03) · **Matrix:** [release-matrix.md](release-matrix.md)
- Authored source, config and tests only. **Nothing was parsed, imported, run, exported, measured or installed**; the laptop was shared, so every execution is `COULD-NOT-RUN — deferred while the shared laptop is in use`. All three P11 boxes stay unchecked and no matrix cell is VERIFIED. P09-T03, P10-T03 and everything upstream (P03-T02/T03, P04–P10) remain open; P10-T03 needs humans.
- **The networked build stays opt-in and unpromoted.** Promotion needs a separate recorded team scope decision (`docs/ROADMAP.md`, tracker completion rules). The offline scheduled route is the default in every profile.
- **Decisions applied (user approved the plan with its defaults, 2026-10-21):** carry-over P08–P10 gaps are recorded as promotion blockers, not fixed; Android release package `org.hoplyxd.tilaok`, name "Tilaok! LAN Client", version `0.4.0` / code 4, keystore held by a human and never committed; battery/thermal by a PC-side adb sampler; telemetry and fault injection development-only; every development flag release-gated except the explicit `--match-route=network_live_build` opt-in.
- **Wire:** no change. Contract v1.6 stays current (MINOR 2, schema 6, mask `0x07FF`, 38 families). RTT comes from ENet's own per-peer estimate, so no ping family and no v1.7 were needed.

## What it does

- **Telemetry (T01):** an opt-in, bounded recorder for the contract v1 §7 metrics on the host and the phone, a production-path fault injector, a crowded-stage fixture at the content caps, a 2/3/4-seat synthetic scale runner, a fault runner, a report generator and a battery/thermal sampler script.
- **Hardening and release profiles (T02):** closes the audit gaps below, release-gates every development flag, adds one inspectable build identity and two release export presets (config only).
- **Release matrix (T03):** one consolidated matrix with session sheets, filled only from real runs ([release-matrix.md](release-matrix.md)).

## Implemented source

| Area | Files |
|---|---|
| Telemetry | `scripts/network/nlb_telemetry.gd`; hooks in `network_session_manager.gd` (`_telemetry_*`, `telemetry_cycle_record`); counters and ENet statistics in `raw_enet_transport.gd` (`app_tx_bytes`…, `peer_statistics`, `pop_host_statistics`) |
| Fault injection | `scripts/network/nlb_fault_injector.gd`, owned by `RawEnetTransport.fault` (send, send_to_all, receive, held-packet flush in `poll`) |
| Release gate | `scripts/diagnostics/nlb_build_flags.gd`; gated: `game_flow.gd`, `ui_library_screen.gd`, `p12_scheduled_match_room.gd`, `match_screen_presenter.gd`, `foundation_harness.gd`, `nlb_live_compatibility_matrix.gd` |
| Build identity | `scripts/network/build_identity.gd`; `compatibility_manifest.gd`; `project.godot` `config/version`; lobby (`ui_lan_lobby_screen.gd`), title (`game_flow._refresh_title`), settings (`ui_settings_screen.gd`) |
| Presets | `export_presets.cfg` preset.2 Windows Host (Release), preset.3 Android LAN Client (Release) |
| Shutdown | `game_flow.gd` `NOTIFICATION_WM_CLOSE_REQUEST` → `_quit()`; `set_auto_accept_quit(false)` while the flow is active |
| Tests / tools | `tests/run_nlb_p11_tests.gd`, `tests/run_nlb_p11_scale_runner.gd`, `tests/run_nlb_p11_fault_runner.gd`, `tests/fixtures/nlb_p11_crowded_stage.gd`, `tests/tools/nlb_p11_report_core.gd`, `nlb_p11_report.gd`, `nlb_p11_thermal_sampler.ps1` |

Three historical suites (`run_nlb_p07/p08/p09_tests.gd`) pinned the literal P09 build id; they now compare against `BuildIdentity.BUILD_ID` because P11 bumped it to `tilaok-nlb-p11-2026-10-21` (the manifest digest therefore changes: an older binary shows the build-mismatch notice).

## How to use the tools (all deferred)

Telemetry (development builds only; ignored in release and Android client builds):

```
--nlb-telemetry=<user://… or <project>/../build/… path>   enable the sink
--nlb-telemetry-synthetic=1 --nlb-telemetry-profile=<label> --nlb-telemetry-seed=<n>   optional header fields
--nlb-p11-fixture   host: fill the stage with the crowded fixture before play
--nlb-fault=loss=5,jitter=30,delay=20,reorder=5,duplicate=2,seed=7   development fault injection
```

Fault rules: loss applies only to the unreliable channels 1 and 2 (dropping before ENet on reliable channel 0 would fake a transport guarantee); delay, jitter, reorder and duplicate apply to every channel; a duplicated reliable packet is rejected by the sequence check and now counts toward the kick threshold. Loss/jitter/etc. are deterministic by seed. `NLB_FAULT_ACTIVE …` is printed at start and once per minute.

## Telemetry field dictionary (mapped to contract v1 §7, `protocol-measurement-contract-v1.md:135-147`)

Line grammar: `NLB_TELEM v1 <header|second|event|summary|gauge|truncated|end> key=value …`. Percentiles come from fixed 256-bucket histograms (value = upper edge of the bucket, never an understatement; the `resolution` field gives the bucket width; the last bucket is overflow and the exact max is kept). Output is capped at 8 MiB with 32 KiB reserved for summaries.

| §7 row | Metric (unit) | Endpoints / source | Status |
|---|---|---|---|
| Host sim/render | `frame_interval_ms` (ms) | consecutive frames, `Time.get_ticks_usec()` | measured by the sink |
| | `sim_step_ms` (ms) | 1 Hz sample of `Performance.TIME_PHYSICS_PROCESS` | engine-wide sample; per-step max and late/missed steps **unavailable** |
| | `fps_monitor` gauge | `Performance.TIME_FPS` | cross-check only |
| Phone FPS | `frame_interval_ms` on a client | same | measured by the sink on the device |
| Cadence | `input_rx`, `state_tx`, `state_rx` counters per second; `state_rx_interval_ms` | session manager | gaps/drops derived from the intervals |
| RTT | `rtt_ms`; `loss_ratio` gauge | `ENetPacketPeer.get_statistic(PEER_ROUND_TRIP_TIME / PEER_PACKET_LOSS)` ÷ `PACKET_LOSS_SCALE` | single-endpoint ENet estimate; never one-way |
| Input → host receipt | — | needs bounded clock offset | **unavailable** (no clock sync exists) |
| Host receipt → response | `input_receipt_to_state_ms`, `placement_receipt_to_response_ms` | host `_receipt_usec` → next state send / placement result send | measured by the sink |
| Delivery / render | `recv_to_next_frame_ms` (client), `state_rx_interval_ms` | state receipt → start of the next frame | a proxy; the host-send → client-receive leg is **unavailable** (clocks), first-rendered-frame needs external capture |
| End-to-end ≤100 ms | — | high-speed capture | **external only** |
| Traffic | `app_tx/rx_bytes_per_s`, `app_tx/rx_packets_per_s`, `net_tx/rx_bytes_per_s`, `snapshot_bytes` | transport counters (22-byte envelope + payload); `ENetConnection.pop_statistic(HOST_TOTAL_*)` | retransmit count unavailable (ENet exposes loss ratio, not a count); UDP/IP/link overhead needs a capture |
| Memory | `godot_static_bytes`, `object_count`, `node_count`, `orphan_node_count` gauges | `OS.get_static_memory_usage`, `Performance.*` | **not RSS**; RSS comes from the external sampler |
| Join / reclaim | `join_to_seat_ms`, `reclaim_to_ack_ms` + `join`/`reclaim` events | `connect_client` → seat assignment; `connect_reclaim` → snapshot ack | measured by the sink; grace excluded by construction |
| Ten-cycle cleanup | `cycle` events with every integer in `teardown_counts()` | scale runner `cycles` mode | measured by the sink |
| Battery / thermal | — | `tests/tools/nlb_p11_thermal_sampler.ps1` (adb, 1/min) | **external**, evidence only |

Never recorded: room codes, tokens, proofs, invitation URIs, addresses. Event fields are an allowlist of numbers, bools and ≤16-character identifiers; the P11 suite checks that a 26-character code and an `ip:port` string are dropped.

## Hardening review (T02, audit gaps a–h)

| Gap | Result |
|---|---|
| (a) no per-family limit | `FAMILY_RATE_LIMITS` on the host for hello/join/proof (2/s), assignment-ack (4/s), session-close (2/s), snapshot-request (4/s), snapshot-ack (8/s). Documented exemptions: host-to-client families (the client never limits the host), challenge/match-lifecycle/sync-ready/result-vote/reject families that only the host sends or that the host rejects outright (HOST_ONLY). Generous by design; real traffic sends these a handful of times per join. |
| (b) windows, not saturating counters | `_abuse_counters["peer:family:reason"]`, saturating at 65535, erased with the peer; `abuse_count()` accessor; `teardown_counts().abuse_counters`. Existing 10-detailed-logs/minute rule and 3-auth/120-format kick thresholds kept. |
| (c) STALE_STATE not counted | Now counted toward the format threshold (a stale-state spammer used to be unkickable). Judgment call: unreliable-channel reordering is already dropped by ENet's sequenced mode and by the retired-epoch quiet drop, and 120 per 10 s is far above legitimate rates. |
| (d) `_last_query_by_source` unbounded | Pruned by age (10 s) and capped at 128 entries. |
| (e) placement new-id budget | Traced: enforced once per new request id (resends hit the cache first). |
| (f) no close-request handler | `NOTIFICATION_WM_CLOSE_REQUEST` runs `_quit()` (SESSION_CLOSE with HOST_QUIT, 600 ms cap) and auto-accept-quit is off while the flow is active (restored in `_exit_tree`). |
| (g) development flags not release-gated | All routed through `NlbBuildFlags`; see the gating table. |
| (h) build label | `BuildIdentity` (below). |
| Extra: kick path leaked per-peer tables | `_drop_peer_tables()` shared by disconnect and kick; a peer that was never a candidate is also erased on disconnect. |
| Extra: transport endpoint tables | `close_peer` (immediate) now erases `_peer_ids_by_endpoint/_by_instance` because a hard close raises no disconnect event. |
| Extra: client snapshot receivers unbounded | capped at 4 partial snapshots, oldest dropped first. |
| Not an issue: `_idempotent_requests` | declared and cleared but never written; nothing to cap. |

Rejections never echo client data (only numeric peer id, family and reason are logged or counted).

## Release gating table (inspect with the grep audit below)

| Flag | Release / Android client build |
|---|---|
| `--harness`, `--open-room=`, `--map=`, `--match-seed=`, `--library-dev`, `--barya-disabled`, `--debug-overlay`, `--nlb-unverified-content`, `--nlb-telemetry*`, `--nlb-fault=`, `--nlb-p11-fixture` | ignored (`NlbBuildFlags.dev_flags_allowed()` is false when the built-in `release` tag or the `android_client` custom tag is present) |
| `--match-route=network_live_build` | **still honoured** (the explicit opt-in; unchanged by this task). Other `--match-route` values are ignored in release. |

Grep audit for reviewers: `Grep "get_cmdline" tilaok!/scripts` must list only `nlb_build_flags.gd`, `nlb_fault_injector.gd`, `nlb_telemetry.gd` and `game_flow.gd` (route + override, both gated); the P11 suite automates this.

## Release preset review

| Field | Windows Host (Release), preset.2 | Android LAN Client (Release), preset.3 |
|---|---|---|
| export path | `../build/release/tilaok-host.exe` (ignored `build/`) | `../build/release/tilaok-android-release.apk` |
| package / version | file/product version `0.4.0.0` (applied only if `application/modify_resources` is enabled) | `org.hoplyxd.tilaok`, name "Tilaok! LAN Client", `0.4.0`, code 4 |
| ABIs | — | arm64-v8a only (debug preset keeps v7a too) |
| permissions | — | INTERNET, CAMERA only |
| custom features | none; relies on the engine's built-in `release` tag | `android_client` |
| exclude filter | `addons/tilaok_qr_scanner/android/**` | same (scanner provenance docs intact: CameraX 1.5.1, ZXing 3.5.3) |
| signing | n/a | all `keystore/*` fields empty; supply `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER`, `_PASSWORD` in the environment (variable names verified against the official Godot Android export page) or local editor settings. A human holds the keystore; this repo never contains one. |
| other | console wrapper off, PCK embedded, `runnable=false` | gradle build, landscape, debug preset untouched |

The debug presets (0 and 1) are unchanged. `release` templates set the built-in `release` feature automatically; exporting with *Export Project* (debug) instead of release leaves development flags on, so only `--export-release` outputs count as release evidence.

## Hash and size recording template (fill after a real export)

| Artifact | Command | SHA-256 | Bytes | Date | Revision | Exporter |
|---|---|---|---|---|---|---|
| `build/release/tilaok-host.exe` | `Get-FileHash -Algorithm SHA256 <path>`; `(Get-Item <path>).Length` | _unrecorded_ | _unrecorded_ | | | |
| `build/release/tilaok-host.pck` (if not embedded) | same | _unrecorded_ | _unrecorded_ | | | |
| `build/release/tilaok-android-release.apk` | same; `apksigner verify --print-certs` for the certificate (never commit the keystore) | _unrecorded_ | _unrecorded_ | | | |

## Interpretations a reviewer should confirm

- `MIN_CONTENT` (`nlb_live_compatibility_matrix.gd`) intentionally stays at the P09 content id: it is a minimum and P11 changed no gameplay content. Only `BUILD_ID` was bumped.
- The plan's "release custom feature tag" is replaced by the engine's built-in `release` tag (a custom `release` tag would be redundant); the Android presets still carry `android_client`.
- Windows `application/*` version fields are written but `modify_resources` is false: enabling it needs the third-party rcedit tool, a provenance decision for the team. The official Windows export page did not document these keys, so confirm them in the editor.
- The mismatch notice shows this copy's label only; the peer's label is not on the wire (no wire change), so it cannot be shown without a v1.7.
- `--match-route=network_live_build` stays in release as the opt-in; hide it behind a setting if the team prefers.
- Simulation-step telemetry is an engine monitor sample, not a per-step instrument.

## Carry-over gaps NOT fixed (promotion blockers; also in the matrix)

1. Kangaroo main rounds are not wired to the disconnect elimination (a neutral seat fails its own commands) — P08 README, P09 README.
2. Event rounds use `joined_seats()` while Karera uses `original_seat_indices` — P09 README.
3. `SESSION_CLOSE` may not flush when the host process is killed; the client then sees `HOST_LOST` (inherent to a process kill; the close-request path now covers window close and Quit).
4. A host with no local seat has no in-game resume control — P08 README.
5. No reconnect/leave button on the phone HUD beyond the results screens — P09 README.
6. Reclaim after a Wi-Fi drop waits for host loss detection — P08 README.
7. The reclaim token travels in clear text on the trusted LAN (by design).
8. `reset_room()` must fully reset a non-default arena for in-place replay (verified only by the ten-cycle audit) — P09 README.
9. A mid-replay peer loss shrinks the roster after the room restarted — P09 README.

## Unverified limits

Nothing parsed, linted (gdlint/gdformat absent), run, exported or measured. All numeric budgets remain PROPOSED. A headless synthetic run is not a render measurement. The crowded fixture assumes `items.place` works at the point the runner calls it on the live room and reports what it actually reached. The report core never judges a budget without a complete hardware record and a long-enough run.

## Deferred commands

Each is `COULD-NOT-RUN — deferred while the shared laptop is in use`. `<log>` is a fresh log path under the ignored `build/` folder; `<proj>` is `C:\Users\Mist\Downloads\Tilaok\tilaok!`.

```
"C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe" --headless --import --path "<proj>" --log-file <log>
"C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe" --headless --fixed-fps 60 --path "<proj>" --log-file <log> --script res://tests/run_nlb_p11_tests.gd
"C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe" --headless --fixed-fps 60 --path "<proj>" --log-file <log> --script res://tests/run_nlb_p11_scale_runner.gd -- matrix 30 profile
"C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe" --headless --fixed-fps 60 --path "<proj>" --log-file <log> --script res://tests/run_nlb_p11_scale_runner.gd -- matrix 720 profile
"C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe" --headless --fixed-fps 60 --path "<proj>" --log-file <log> --script res://tests/run_nlb_p11_scale_runner.gd -- matrix 0 cycles
"C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe" --headless --fixed-fps 60 --path "<proj>" --log-file <log> --script res://tests/run_nlb_p11_fault_runner.gd -- 30
"C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe" --headless --path "<proj>" --log-file <log> --script res://tests/tools/nlb_p11_report.gd -- --host=<host.telem> --host-hardware=<file> --out=<report.md>
```

Release exports and device steps (all deferred; a human supplies signing through the environment, never the repo):

```
"C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe" --headless --path "<proj>" --log-file <log> --export-release "Windows Host (Release)" ../build/release/tilaok-host.exe
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH="<keystore>"; $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER="<alias>"; $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="<password>"
"C:\Users\Mist\Downloads\Godot_v4.7.2-stable_win64.exe" --headless --path "<proj>" --log-file <log> --export-release "Android LAN Client (Release)" ../build/release/tilaok-android-release.apk
Get-FileHash -Algorithm SHA256 <exported file>; (Get-Item <exported file>).Length
adb -s <serial> install -r <proj>\..\build\release\tilaok-android-release.apk
powershell -ExecutionPolicy Bypass -File tests/tools/nlb_p11_thermal_sampler.ps1 -DeviceLabel <label> -Serial <serial> -Minutes 30 -OutFile ..\build\nlb_p11\<label>-thermal.csv
```

Regressions (same headless pattern, `--script res://tests/<runner>.gd`): every `run_nlb_p01_tests` … `run_nlb_p10_tests` and the multi-process runners `run_nlb_p02/p04/p06/p08/p09_multi_process`, plus the offline suites listed in the P07/P09 evidence. Also deferred: gdlint/gdformat (tools absent), the 10-minute host profile in the exported windowed Windows build, the 10-minute phone profile, the 30-minute thermal sample, and the whole T03 physical/human matrix.

## Check record

| Check | Result | Reason |
|---|---|---|
| `git diff --check` | PASSED (before each commit) | whitespace only |
| Grep audits (dev flags, secrets, build id) | PASSED by inspection | manual; the suite automates them but has not run |
| `export_presets.cfg` secret review | PASSED by inspection | every `keystore/*` value is empty |
| Import/parse, lint, `run_nlb_p11_tests`, scale/fault runners, report generator, regressions | COULD-NOT-RUN | deferred while the shared laptop is in use |
| Windows / Android release export, hashes, install | COULD-NOT-RUN | deferred; signing material and a human are required |
| 10-minute host/phone profiles, 30-minute thermal sample, ten-cycle audit | COULD-NOT-RUN | deferred; phone profiles need physical devices |
| T03 physical/human matrix | COULD-NOT-RUN | requires physical phones, human participants and an actual reviewer |

## Reviewer checklist

1. Confirm the interpretations above, especially `MIN_CONTENT` and the release-flag choice.
2. Read `_accept_rate`, `_reject`, `_drop_peer_tables` and `RawEnetTransport.close_peer` for behavior changes on the kick path.
3. Inspect `export_presets.cfg` presets 2 and 3 in the Godot editor (it may rewrite keys on open) before any export.
4. Review [release-matrix.md](release-matrix.md) and decide the team thresholds the plan left as "evidence only".

## Rollback

Revert the P11 commits. Telemetry, fault injection and the fixture are inert unless their flags are given in a development build; the offline route, the wire and the debug presets are untouched. Reverting the build-identity commit also needs the three historical test assertions reverted.
