# NLB-P04 sanitized runtime record — 2026-10-21

## Environment

- Engine: Godot 4.7.2 stable, official revision `ed1daf0bf`.
- Source revision used for checks: `10b92d55` plus the uncommitted P04 working-tree changes described in the evidence README. No independent reviewer was present.
- Android device: TECNO KJ8, Android 14 / API 34; package `org.hoplyxd.tilaok.debug`, version `0.3.2-debug`.
- Updated Android APK: 172,070,912 bytes; SHA-256 `C939E28F5056BFBC7D9888E8FF6DE4542306B44D3AAEDC7A4691CCF8D1B6937A`; v2 signature verified and installed.
- Host/client topology for the automated process check: two Godot processes on one Windows laptop, fixed test seed `12345`.

## Results

- Focused P04 suite: `NLB_P04_TESTS PASSED checks=35` on the current source tree.
- Separate-process production path: `PASSED host_owned_match=true client_snapshot=true remote_input=true`. Snapshot readiness and remote movement input were observed between separate host/client processes on the same laptop. This is not a separate-device or packet-fault result.
- Prior P01 / P02 / P03 / P12 regression suites: 65 / 74 / 61 / 61 checks passed before the final camera-zoom metadata adjustment.
- Physical Android on an earlier P04 APK: admission, snapshot readiness, and remote input were recorded by the runner. That APK predates the camera-zoom correction.
- Physical Android on the updated APK: the retained [capture](p04-android-pugad-marker-2026-10-21.png) shows Pugad, the shared stage, scores, touch controls, and the Player 2 marker. On a later manual attempt the phone displayed “connected, waiting for host approval,” while the host runner showed no admitted peer; movement on the updated APK was not verified.

## Limits and remaining work

No raw ENet ordering/flag experiment, packet-loss/jitter/reorder injection, measured rate or 150 ms timeout boundary, snapshot corruption/retry test, same-tick convergence comparison, network teardown-cycle test, Windows release export, or performance/traffic measurement is recorded here. The physical movement and host/client outcome walkthrough remains open. P03-T03 remains formally open. P04 stays 0/3 checked.

No invitation code, peer nonce, or host address is retained in this record. Temporary invitation files were removed after the session.
