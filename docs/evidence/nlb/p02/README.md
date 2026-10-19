## NLB-P02 PC host lobby verification — 2026-10-20

This is local engineering evidence for the opt-in PC lobby. It does not establish real-Wi-Fi, no-internet, Android, human-play, or network-gameplay acceptance. Godot 4.7.2 (`4.7.2.stable.official.ed1daf0bf`) ran in the Windows desktop project. The only usable selected interface available during this run was the WSL virtual IPv4 interface `172.28.192.1`; this environment cannot verify Wi-Fi client isolation or a real LAN without internet. No firewall/router settings were changed and no general LAN flood was run.

| Check | Result | Evidence / limit |
|---|---|---|
| Godot import and script parse | PASSED | [`import-parse-final.log`](test-logs/import-parse-final.log); existing invalid resource UID warnings remain from the preserved P01 UID deletion. |
| Raw ENet and discovery/admission | PASSED — 52 checks | [`p02-focused-tests-final.log`](test-logs/p02-focused-tests-final.log): Lobby ID lookup, compatibility, invalid proof, expired invitation, approval/rejection, assignment acknowledgment, readiness, capacity, closure and cleanup. |
| Separate process host/client lifecycle | PASSED — 10 cycles | [`p02-multi-process-final.log`](test-logs/p02-multi-process-final.log): each cycle starts host/client processes, joins, readies, leaves, stops and rebinds; final seats, peers and cache are zero. |
| QR utility | PASSED | Synthetic invalid test URI independently decoded with ZXing C++ 3.1.1. No live credential was placed in the QR capture or logs. |
| Static formatting/lint | PASSED | [`gdlint-final.log`](test-logs/gdlint-final.log), [`gdformat-final.log`](test-logs/gdformat-final.log), and `git diff --check`. |
| Lobby UI audit | PARTIAL — 503/505 | [`ui-regression-final.log`](test-logs/ui-regression-final.log). LAN-specific layout/theme and menu focus checks pass; the only failures are known P01 `%Outcome1` and `%Final1` score-row type assertions. |
| Local host/client rendered walkthrough | PASSED, redacted/safe | [`host-lobby-active-redacted.png`](captures/host-lobby-active-redacted.png), [`host-lobby-seats-redacted.png`](captures/host-lobby-seats-redacted.png), [`client-awaiting-approval.png`](captures/client-awaiting-approval.png). Client capture shows manual address plus separate code field in the approval-pending state. |
| Real Wi-Fi/no-internet LAN | COULD-NOT-RUN | No physical Wi-Fi interface/client was available in the environment. Manual fallback remains in the UI. |
| Abuse-flood thresholds and rejection-log aggregation | COULD-NOT-RUN | Not exercised; no general LAN traffic was generated. |

## Implemented boundary

The PC host may spectate without occupying a seat. Only the host's approval followed by client assignment acknowledgment creates a remote lobby seat. The existing `PlayerSeatRegistry` remains the single four-seat authority. Readiness is attributed to the assigned peer. P02 does not bind remote gameplay input or enable gameplay message families. The UI reports that network gameplay is unavailable until a later phase, and the normal offline route remains available after teardown.

The implementation uses raw `ENetConnection`/`ENetPacketPeer`, reliable channel 0 control packets, bounded IPv4 UDP discovery, a 128-bit one-use invitation credential expiring after 300 seconds, HMAC-SHA-256 proof, a canonical SHA-256 compatibility manifest, host approval, and idempotent stop/rehost cleanup. Trusted-LAN packets are not encrypted.

## Evidence files

- `test-logs/`: focused, process-separated and regression outputs, plus import/lint/format results.
- `captures/`: host and client lobby views. Host invitation material is redacted; QR fixture contains an invalid documentation-only address and dummy credential.
- `../p00/protocol-measurement-contract-v1.1.md`: versioned family, query, admission and interface clarification.

P02 tracker status is PARTIAL (2/3): implementation and admission tasks have evidence; the abuse and real-LAN verification task remains open. Desktop client evidence is engineering-only. Android camera/device/network-play claims are not made.
