# NLB-P04 implementation and verification — 2026-10-21

## Status

P04 has source implementation and partial runtime evidence. **P04 remains 0/3 checked; it is not complete.** P03-T03 remains formally open because its exact prior build/device record and retained join/leave/rejoin/rejection evidence have not been recovered. P04 work does not clear that dependency. Keep all P04 boxes unchecked until the remaining P04 acceptance and dependency evidence are reviewed.

## Implemented source

- P00 wire 1.2/schema 2 gameplay contract, raw ENet channels, typed records and bounded snapshot recovery are documented in [the v1.2 amendment](../p00/protocol-measurement-contract-v1.2.md).
- The implementation uses the existing P12 `karera_slice` Pugad → Place → Play route. The offline route stays the default; P05 live-build and P06 placement requests are not enabled.
- Host-owned simulation, peer/seat generation binding, logical input, detached client presentation, host phase/score/state updates, touch controls and the P12 session handoff are described in [the P04 tracker records](../../PHASETASK_NETWORKED_LIVE_BUILD.md).
- Client camera framing now includes the host zoom value. Without it, actor markers rendered offscreen on the phone even though the stage and score arrived.

## Recorded checks

Engine: Godot 4.7.2 stable (`ed1daf0bf`). The checked source was the `10b92d5` base plus the working-tree changes from this task; the implementation was not yet committed when these runs were made. Fixed test seed: `12345` where the runner uses a seed.

| Check | Result | Scope and limits |
|---|---|---|
| `run_nlb_p04_tests.gd` | PASSED — 35 checks | Codec bounds, input/ownership, snapshot validation and local lifecycle cases. Does not replace transport fault injection. |
| `run_nlb_p04_multi_process.gd` | PASSED — `host_owned_match=true client_snapshot=true remote_input=true` | Production host and separate client processes on one Windows laptop. Snapshot readiness and remote movement input reached the host. No packet loss or separate-device claim. |
| P01 / P02 / P03 / P12 regressions | PASSED — 65 / 74 / 61 / 61 checks | Godot headless suites on the task working tree before the final camera-zoom metadata adjustment. |
| Android debug export and install | PASSED | Package `org.hoplyxd.tilaok.debug`, version `0.3.2-debug`, Android 14/API 34 device. Updated APK: 172,070,912 bytes, SHA-256 `C939E28F5056BFBC7D9888E8FF6DE4542306B44D3AAEDC7A4691CCF8D1B6937A`; v2 signature verified and installed. App reached `android_client_lobby` without a parse/fatal error. |
| Physical phone join on earlier P04 APK | PASSED for admission, snapshot readiness and remote input | Host approved Player 2; the P04 runner recorded `NLB_P04_PHONE PASSED host_owned_match=true client_snapshot=true remote_input=true`. This build predated the camera-zoom correction. |
| Physical phone on the updated APK | PARTIAL | The latest app rendered the Pugad phase, shared stage, scores, touch controls and the blue Player 2 marker. See [the phone capture](p04-android-pugad-marker-2026-10-21.png). A later manual attempt reached the phone lobby's “connected, waiting for host approval” screen, but the host runner did not register an admitted peer; no updated-build movement result was produced. |

The updated APK’s capture verifies the camera-zoom fix and snapshot-backed presentation. The earlier APK’s host log verifies remote input routing. These results are from different APK runs. Repeat the physical movement check on the updated APK before treating that combined visual/input acceptance as passed. A sanitized run summary is in [the runtime record](runtime-log-2026-10-21.md).

## Remaining verification

- P03-T03 evidence closure and review.
- Updated-APK phone movement and rendered host/client walkthrough, including visible movement of the assigned marker.
- Raw ENet channel/flag ordering experiment; sequence wrap and cross-channel edge ordering.
- Production-path packet loss, jitter, reorder, duplication, malformed/spoofed traffic, rate-boundary and 150 ms timeout cases.
- Snapshot corruption/gap/retry and score/event convergence at a common acknowledged tick/version.
- Ten network teardown cycles, Windows release export, performance/traffic samples, and human review.

No performance budget was measured. The proposed host 60 Hz / 16.67 ms, phone ≥30 FPS / p95 ≤33.3 ms, and 512 MiB memory targets remain provisional; there is no bandwidth threshold. Do not claim a release-performance pass.

## Reproduction commands

Run during an approved testing window:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\roman\Desktop\Vscode Projects\Tilaok\tilaok!' --script res://tests/run_nlb_p04_tests.gd
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\roman\Desktop\Vscode Projects\Tilaok\tilaok!' --script res://tests/run_nlb_p04_multi_process.gd
```

The physical test uses the same multi-process runner with `-- phone`; it writes a short-lived invitation to Godot user data for manual phone entry. Remove that invitation after the session. Retain sanitized logs, captures, exact revision/build/device details, seed/topology, and the actual reviewer. Current automated checks were run by Codex; no independent human review is claimed.
