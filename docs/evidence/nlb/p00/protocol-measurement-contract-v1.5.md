# NLB-P00 contract amendment — schema 5 / host pause, phone lifecycle, seat reservation and reclaim

**Contract version:** wire major 1, minor 2; schema 5; required feature mask `0x03FF`. **Date:** 2026-10-21. **Status:** NLB-P08 preparatory source design. The source is authored. No Godot parse, test, multi-process, loss/reorder, phone or rendered run has executed (`COULD-NOT-RUN — deferred while the shared laptop is in use`). This amendment supplements [v1](protocol-measurement-contract-v1.md), [v1.1](protocol-measurement-contract-v1.1.md), [v1.2](protocol-measurement-contract-v1.2.md), [v1.3](protocol-measurement-contract-v1.3.md) and [v1.4](protocol-measurement-contract-v1.4.md). It implements the v1 §4 "Pause / resume" and "Client lifecycle / neutral / background / disconnect / reclaim" rows and the §2 reclaim token. It changes only the items listed here. P02 lobby rules, P04 input/state/snapshot rules, P06 placement and P07 transient/matrix rules stay in force.

**Scope:**
- Both network routes (scheduled P12 and opt-in `network_live_build`). Offline play is unchanged, including the offline pause coordinator, gamepad reclaim and their tests.
- No score, Barya, Lagsanay or Karera rule changes. The only ordering addition is the `disconnect` cause below.

## 1. Versioning and identity

- **Envelope minor stays 2** (same reason as v1.3 §1: older binaries still read the host welcome and show the readable build-mismatch notice).
- **Gating:** schema 5 and feature bit 9 (`0x0200`, lifecycle). Exactly `0x03FF` is required (`NetworkFrame.FEATURE_REQUIRED_MASK`). The compatibility hello stays 38 bytes. A schema-4 / `0x01FF` (P07) peer is refused at hello with `INCOMPATIBLE`; it is never half-admitted. Android needs an APK built from this revision.
- **Manifest:** `build` becomes `tilaok-nlb-p08-2026-10-21`. The live matrix gains three `life` cells (§6), so the manifest digest changes.
- **Identities (v1 §2, now implemented):**
  - **Player ID:** host-assigned random 128 bits, stable through reclaim. It is a lookup key only, never authority.
  - **Reclaim token:** 128 random bits bound to the Player ID and seat. Memory only on both sides: never written to disk, never logged, never echoed. Compared only through the HMAC proof (constant time). It rotates after every successful reclaim and the old token is revoked.
  - **Where the token travels:** only inside the seat assignment (reliable channel 0) and inside the `RECLAIM_RESULT` that rotates it. This is a trusted-LAN design. There is no encryption and no confidentiality claim.

## 2. Wire families (all reliable control channel 0; added to `FAMILIES`)

| Family | Name | Direction | Size | Notes |
|---:|---|---|---:|---|
| `0x1E` | Pause state | host → clients (a client frame is refused `HOST_ONLY`) | 26 | match u64, round u32, attempt u32, **epoch u32**, host tick u32, state u8 (0 running, 1 paused), reason u8 (0 host request, 1 focus, 2 system) |
| `0x1F` | Lifecycle hint | client → host | 9 | peer generation u32, client sequence u32, state u8 (0 foreground, 1 background, 2 focus out, 3 focus in). Max 2/s per peer |
| `0x20` | Reclaim begin | client → host | 36 | Player ID 16, client nonce 16, last snapshot id u32. No raw token, no seat. Max 1/s per peer. Compatibility digest/protocol/schema/mask are proven by the hello that must precede it |
| `0x21` | Reclaim result | host → client | 27 | reason u16, seat u8, new peer generation u32, **rotated token 16** (zero on any refusal), reserved-remaining ms u32 |

**Existing families, changed:**
- `SEAT_ASSIGNMENT` (`0x09`) grows from 6 to 38 bytes: seat u8, seat+1 u8, peer generation u32, **Player ID 16, reclaim token 16**. A client rejects the old 6-byte form.
- `CHALLENGE` / `PROOF` keep their sizes. The proof is `HMAC-SHA-256(token, "TILK-AUTH-v1" || session_epoch_u64 || client_nonce_16 || server_nonce_16 || auth_context_u8 || protocol_major_u8 || protocol_minor_u8)` with `auth_context` 0 = invitation join (key: room token) and **1 = reclaim (key: reclaim token)**. The host knows the context from the claim state, so it is not sent. Challenge: 16-byte server nonce, single use, 30 s expiry. A changed proof for a used nonce rejects.
- `ASSIGNMENT_ACK` is reused to acknowledge a reclaim (seat u8 + new peer generation u32).
- `MATCH_LIFECYCLE` is reused: a reclaiming peer is told the running match before its snapshot.
- No pause or lifecycle byte is added to `STATE_UPDATE`; the existing metadata `paused` flag keeps riding there, so schema-2 metadata decoders are untouched.

**Not carried (deviations from the v1 rows, stated so a reviewer can object):**
- The v1 pause row says pause state is "repeated in periodic state delta and snapshot". This revision repeats it as a **1 Hz `PAUSE_STATE` heartbeat while paused and once after every `SYNC_READY`**, plus the existing `paused` metadata bit. Snapshots themselves are unchanged.
- The v1 reclaim row lists "protocol/content digests" in the reclaim request. They are proven by the compatibility hello that every reclaim connection must pass first, so `RECLAIM_BEGIN` does not repeat them.

## 3. Host rules

**Pause (host only):**
- The host's tree pause (set only by host-local input; remote "pause" is not reachable and a `PAUSE_STATE` from a client is `HOST_ONLY`) is the authoritative state. A change advances a monotonic wrap-aware epoch (≤2 requests/s) and is sent to every synchronized peer.
- Simulation, physics, event clock, item grace, transient timers and phase timers already freeze with the tree. The input timeout also freezes: a peer is not timed out because of a pause. The 60 s reservation clock does **not** freeze.
- Network resume follows the host's own seats only (`PauseRecoveryCoordinator.remote_ready_exempt`). Remote seats cannot set ready, so the offline "every seat ready" rule would deadlock. Offline play keeps the offline rule.
- A host without a local seat has no in-game resume control; that needs host UI (P09/P10) and is not claimed here.

**Reservation:**
- In a match, a transport loss, session close or rejected frame reserves the seat instead of releasing it: seat, Player ID and score are kept, input is neutral, and a 60 s host monotonic timer starts. At most four seats. Cleared when the session stops. In the lobby a loss still releases the seat.
- The lobby-only join rule is unchanged. After the lobby closes, a new peer may complete the compatibility hello only while a seat is reserved, and its `JOIN_BEGIN` is refused `LOBBY_CLOSED`. A reserved seat can never be taken by a new join.

**Reclaim:**
1. New connection → compatibility hello → `RECLAIM_BEGIN`. An unknown Player ID and an unreserved seat get the same `TOKEN_INVALID`. An **expired** reservation is refused `WRONG_PHASE` while the round is in PLAY and accepted at any other phase.
2. At most one claim per seat is in flight; a racing peer gets `OWNERSHIP`.
3. The host sends the challenge. A proof that fails (wrong token, join-context proof, old token after rotation, wrong epoch, replayed nonce) frees the claim at once and counts as an auth failure (3 in 10 s closes the peer).
4. On a valid proof any older connection on the seat is dropped, the token **rotates**, a new peer generation is issued (the old generation loses authority immediately) and `RECLAIM_RESULT` carries the new token.
5. The peer acknowledges, receives `MATCH_LIFECYCLE` and a **current snapshot**, and acknowledges it. Only then, at that host packet boundary (never inside a physics step), the seat is rebound and the reservation clears. Input is gated on a fresh neutral sample; nothing is ever replayed. A peer lost before this point leaves the reservation running.

**Expiry (disconnect elimination):**
- If grace ends while the round can commit, the host commits **exactly one** elimination for that seat in that round, with cause `disconnect`, **no source item, so no Patibong**, through the existing paths: the Karera ledger (event id `<round>:disconnect:<seat>`) and the Lagsanay controller (which also serves Sudden Death). The identity stays reserved. An unclaimed seat is eliminated the same way in each later round it is still absent.
- A pause, a non-PLAY phase or a Kangaroo main round defers the commit (`not_playing`), it is not dropped. Kangaroo main rounds are **not wired**: a seat with neutral input fails its own commands (a documented gap, not a claim).
- Pugad/Place: no elimination; the existing timeout assignment covers an unclaimed item.
- **Ordering (design-approved, see the P12 table U13):** `disconnect` ranks with the lowest cause class, equal to `command_failure`. Elimination still beats a goal on the same step. It never outranks a hazard or timeout recorded for the same seat on that step; when it shares a step with a trap, the missing source item leaves the cause ambiguous, so no one earns Patibong.
- Fewer than two connected players: the round continues; reservation clocks keep running; there is no automatic pause.
- Results: on the network a reserved/disconnected seat never blocks the round results (`network_exempt_unconnected_seats`). Offline keeps every seat.

## 4. Client rules

- **Lifecycle:** on focus loss, window focus loss, or Android pause the client zeros its held state, sends **one neutral sample** and **one hint** (≤2/s; an over-budget hint waits and is retried next frame), and stops streaming. Held input cannot be re-armed while backgrounded. It never relies on Android delivering these callbacks: the host's 150 ms input timeout stays the authority.
- **Return:** a fresh neutral sample and a foreground hint; if the last host state is older than 2 s (or the stage has a gap) the client requests a full snapshot.
- **Host pause:** the client shows "PAUSED BY HOST" and stops extrapolating the phase timer. Its own pause button opens a local overlay only and changes nothing on the host.
- **Reconnect credential:** on a lost transport the client keeps `{Player ID, token, address, port, epoch, digest}` **in memory** and exposes `client_reclaim_available()` / `connect_reclaim()`. A user leave or a host close clears it. No UI button is added in this phase (touch HUD is P10).
- **Process death:** if Android kills the app, the memory-only token is lost and that player **cannot reclaim**. This is by design: no token is persisted. The seat simply runs out its grace and the player is eliminated for the round.

## 5. Reason enums

No new reason codes. Used: `HOST_ONLY` 23 (client pause frame), `OWNERSHIP` 10 (racing claim, stale generation, forged frame), `TOKEN_INVALID` 4 (unknown identity, unreserved seat, bad proof), `WRONG_PHASE` 9 (expired reservation during PLAY), `LOBBY_CLOSED` 7 (join in the reclaim window), `RATE_LIMIT` 13.

## 6. Matrix and limits

- **Matrix:** three ENGINEERING `life` cells are added (`life:host_pause`, `life:client_lifecycle`, `life:seat_reclaim`), default-deny, no VERIFIED cell. `MIN_PROTOCOL` becomes `1.2/schema5/0x03FF`.
- **Rejected in `await_neutral`:** a non-neutral sample while the host waits for a neutral one is now **dropped silently** instead of rejected (a rejection released the seat). No test depended on the old rejection.
- **Not claimed:** no pause, reclaim, loss/reorder, phone, rendered or performance result. The v1 provisional targets (≤5 s reclaim) are unmeasured. Reconnect after a Wi-Fi drop depends on the host noticing the transport loss; until it does the seat is not reserved and a reclaim attempt is refused, so the client retries.
- **Not in scope:** host migration, persistence to disk, internet/relay, encryption, replay/new match epoch and host-loss screens (P09), touch HUD (P10), performance (P11).
