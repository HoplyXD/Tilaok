# NLB-P00 contract amendment — schema 6 / replicated results, result vote, in-place replay re-key and session end

**Contract version:** wire major 1, minor 2; schema 6; required feature mask `0x07FF`. **Date:** 2026-10-21. **Status:** NLB-P09 preparatory source design. The source is authored. No Godot parse, test, multi-process, loss/reorder, phone or rendered run has executed (`COULD-NOT-RUN — deferred while the shared laptop is in use`). This amendment supplements [v1](protocol-measurement-contract-v1.md), [v1.1](protocol-measurement-contract-v1.1.md), [v1.2](protocol-measurement-contract-v1.2.md), [v1.3](protocol-measurement-contract-v1.3.md), [v1.4](protocol-measurement-contract-v1.4.md) and [v1.5](protocol-measurement-contract-v1.5.md). It implements the v1 §4 "Outcome / results / score ledger" and "Session shutdown / host loss" rows and the v1 §2 session-epoch / match-ID rule for replay. It changes only the items listed here. P02 lobby rules, P04 input/state/snapshot rules, P06 placement, P07 transient/matrix and P08 pause/reclaim rules stay in force.

**Scope:**
- Both network routes (scheduled P12 and opt-in `network_live_build`). Offline play is unchanged: every new room hook is off unless the network session turns it on.
- No score, Barya, Lagsanay, Karera, Last Cluck, terminal-order, 80-unit target, 12-round or sudden-death rule changes. Scores are signed eighth-point integer units end to end.

## 1. Versioning and identity

- **Envelope minor stays 2** (older binaries still read the host welcome and show the readable build-mismatch notice).
- **Gating:** schema 6 and feature bit 10 (`0x0400`, results). Exactly `0x07FF` is required (`NetworkFrame.FEATURE_REQUIRED_MASK`). The compatibility hello stays 38 bytes. A schema-5 / `0x03FF` (P08) peer is refused at hello with `INCOMPATIBLE`. Android needs an APK built from this revision.
- **Manifest:** `build` becomes `tilaok-nlb-p09-2026-10-21`. The live matrix gains three `life` cells (§6), so the manifest digest changes.
- **Identities (v1 §2):**
  - **Session epoch** changes on replay. The host first clears every match-scoped container, reservation, reclaim token and the pause epoch (a full match-session teardown, spec §3.3), then mints a new 64-bit epoch. The ENet connections stay open. Return to Lobby is a full `stop_session()`.
  - **Match ID** is a **host-lineage counter** that only grows within one host session (1, 2, 3 …). This is stricter than the v1 row ("scoped to the epoch, starts at 1"): an old match's packet is stale even if an epoch ever collided. It is cleared when the session stops.
  - **Attempt ID** is unchanged from v1.2 (`match_run_id & 0xffff`, u16; u32 in `PAUSE_STATE`). This differs from the v1 row (per-round retry counter) and is a pre-existing deviation.
  - **Event ID** is a per-match u32 allocated by the host ledger at commit (1, 2, 3 …). **Ledger revision** is the number of committed entries, so it equals the highest event ID. Both are ≤ 128 (the v1 §1 bound; a real match holds at most 15). The client dedupe key is `(match_id, round_id, attempt_id, event_id)` plus the revision.
  - **Request ID** for `RESULT_ACTION` is a client counter per session, restarted by a re-key.
  - **Reclaim token** is replaced for every seat at a re-key; the Player ID is kept. A token issued before a replay is `TOKEN_INVALID` afterwards.

## 2. Wire families (all reliable control channel 0; added to `FAMILIES`, now 38 entries ending at `0x26`)

| Family | Name | Direction | Size | Notes |
|---:|---|---|---:|---|
| `0x22` | Result event | host → clients (a client frame is refused `HOST_ONLY`) | ≤ 188 | Common 23: kind u8 (1 ROUND, 2 SD_ENTRY, 3 SD_RESULT, 4 FINAL), match u64, round u32, attempt u16, event id u32, revision u32. Bodies below |
| `0x23` | Result action | client → host | 27 | request id u64, match u64, round u32, attempt u16, event id u32, action u8 (1 continue, 2 vote Replay, 3 vote Lobby). ≤ 4/s per peer |
| `0x24` | Result vote | host → clients (a client frame is refused `HOST_ONLY`) | 23 | match u64, round u32, event id u32, vote seq u32, action i8 (−1 none), ready mask u8, required mask u8 |
| `0x25` | Re-key | host → clients (a client frame is refused `HOST_ONLY`) | 34 | new epoch u64, new match id u64, route u8, flags u8 (bit 0 unverified content), new reclaim token 16. Sent under the **old** epoch |
| `0x26` | Re-key ack | client → host | 12 | new epoch u64, peer generation u32. Sent under the **new** epoch. ≤ 2/s per peer |

**Result bodies**
- **ROUND:** scoring family u8 (1 race, 2 Lagsanay, 3 Kangaroo), suppression u8 (0 none, 1 no finisher, 2 all finished), finisher count u8, first-finish seat mask u8, last-cluck seat i8, Barya seat i8, decision u8 (1 continue, 2 winner, 3 sudden death), winner seat i8, tied mask u8, terminal reason u8 (0 none, 1 score target, 2 round limit), seat count u8 (2..4); then per seat: seat u8, outcome u8 (0 none, 1 finished, 2 eliminated), cause u8, owner seat i8, placement u8, delta i32, total i32, award count u8 (≤ 8) × (key u8, units i16). Largest legal entry: 23 + 11 + 4 × (14 + 24) = **186 bytes**.
- **SD_ENTRY:** tied mask u8, sudden-death attempt u8, terminal reason u8, count u8, count × (seat u8, total i32).
- **SD_RESULT:** winner seat i8, last-cluck u8, sudden-death attempt u8.
- **FINAL:** winner seat i8, last-cluck u8, sudden-death u8, terminal reason u8, count u8, count × (seat u8, total i32).

**Enums (unknown values reject):** cause {0 none, 1 goal, 2 direct hazard, 3 hazard, 4 elimination, 5 hard cap, 6 post-finish deadline, 7 timeout, 8 command failure, 9 disconnect, 10 bounds}; award key {1 tapos, 2 una, 3 bayani, 4 bawi, 5 barya, 6 patibong, 7 placement}. A host cause string with no entry encodes as 4. No free text is ever sent.

**Existing families, changed:**
- `SESSION_CLOSE` (`0x0E`) **host → client** grows from 2 to **11 bytes**: reason u16 (as before), session-end u8 {1 `HOST_LOST` (client-synthesised on transport loss), 2 `HOST_CLOSED`, 3 `LOBBY_RETURN`, 4 `HOST_QUIT`, 5 `CLIENT_LEFT`, 6 `REPLAY_UNAVAILABLE`}, final ledger revision u32, host tick u32. **Client → host stays 2 bytes.** A malformed or unknown notice still ends the client session, as `HOST_LOST`.
- `MATCH_LIFECYCLE` (`0x0F`) is reused after a re-key ack for the new match. A client ignores a repeated start for the match it already runs.
- **Snapshot:** one `RECORD_LEDGER` (type 8; type byte + the `0x22` body) per committed entry, ≤ 128. `MAX_SNAPSHOT_RECORDS` rises from 160 to 288. A ledger that cannot be encoded refuses the snapshot (`SNAPSHOT_LIMIT`); it is never truncated.
- **Sequence counters** are connection-scoped and **continue across a re-key** (they are not reset), so a frame of the retired epoch can never move a counter backwards.

## 3. Host rules

**Ledger.**
- The ledger (`result_ledger.gd`) is append-only and committed once per entry. A ROUND entry is committed from the round-conclusion path after the calculators have committed the score once and the lifecycle decision is known; SD_ENTRY when sudden death begins (no deltas: the totals are frozen at the tie); SD_RESULT when it resolves; FINAL when the match result is shown. No ROUND entry follows a winner or a sudden-death decision, and none exceeds the round limit.
- Each entry goes once, reliably, to every synchronized peer. After every `SYNC_READY` the host repeats the whole ledger and the current vote, so an entry committed while a peer was synchronizing is never lost. The snapshot carries the complete ledger; cumulative scores already ride the seat records.

**Vote and action.**
- The vote follows the offline agreement rule: changing the selected action clears everyone's readiness; the host commits when every connected original seat agrees. A reserved or disconnected seat never blocks it (P08 exemption, now also re-checked for the final results).
- The seat always comes from the peer's binding. A stale or repeated request is answered with the current vote and is **not** rejected, because a rejection releases the seat. Malformed → `MALFORMED`; a frame from a peer that is not bound to its seat → `OWNERSHIP`.
- Remote `ACTION_REQUEST` ids 1 (confirm), 2 (back) and 7–10 (navigation) are not accepted in Results. This removes the remote path that opened the host's leave dialog and paused the whole tree.
- A spectator host (no local seat) commits the result planks by host authority: Replay and Lobby act at once, Quit asks first.

**Replay (decision A, in-place re-key).**
1. The room's replay handler releases lost remote seats from the roster; fewer than two connected players refuses the replay (the room shows a reason and Lobby stays available). A lost local device keeps blocking it.
2. The host sends `REKEY` to each connected peer under the old epoch, then retires that epoch (kept for 10 s, at most two), switches to the new epoch and the next match ID, clears every match-scoped container, reservation, token and the pause epoch, and runs the room's existing reset and start.
3. A peer that acknowledges (`REKEY_ACK` under the new epoch, matching generation) receives `MATCH_LIFECYCLE` and a fresh snapshot; its input is gated on a neutral sample. A peer that does not acknowledge within 3 s is dropped and its seat forfeits through the disconnect-elimination path.
4. Packets of the retired epoch are dropped **silently**; any other wrong epoch is still `STALE_STATE`.

**Return to Lobby, Quit, loss.** Return to Lobby stops the session (`LOBBY_RETURN`) and the host lands on the LAN lobby. Host Quit stops it (`HOST_QUIT`) before the process exits. A client `SESSION_CLOSE` during a match **forfeits** the seat: it is reserved with its grace already over and its token replaced, so the one disconnect elimination commits at the next safe boundary (no Patibong) and the identity cannot be reclaimed. A lost connection still keeps the 60 s reservation.

## 4. Client rules

- **Result model** (`network_results_model.gd`): `revision == last + 1` applies; the same key and body again is an idempotent duplicate; an older revision with a different body is ignored; a larger gap asks for a snapshot. Before applying, the model checks: event ID equals revision; seats unique and 2..4; `delta` equals the sum of its awards; `total − delta` equals the previously committed total; a winner holds the unique maximum; a sudden-death tie equals the set of maximum totals; no ROUND after a winner or a sudden-death decision; sudden death and the final entry change no total; the final winner matches the decision. A snapshot's ledger must pass the same rules or nothing is installed.
- **Screens:** the phone shows the round results (outcome, awards, totals, Last Cluck and suppression notes) with Continue, the match result with Replay, Return to Lobby and Leave, and a session-ended screen with a bounded reason. Sudden death is labelled from the ledger, not from the wire round number. The phone's score text derives from units (the old `/100` display was wrong).
- **Re-key:** the client adopts the new epoch, match ID and token only from the host peer, clears the old match (replica, ledger, pause, input and request counters, snapshot buffers), acknowledges under the new epoch and drops the retired epoch's packets silently. Hint counters belong to the connection and stay.
- **Session end:** `session_ended(reason)` fires from every stop. `GameFlow` shows the reason and returns to the LAN lobby (immediately for `CLIENT_LEFT`, otherwise on tap or after 10 s).

## 5. Reason enums

No new reason codes. Used: `HOST_ONLY` 23 (client result event, vote or re-key frame), `OWNERSHIP` 10 (an unbound seat, a wrong re-key ack), `MALFORMED` 1, `STALE_STATE` 11 (unknown epoch), `RATE_LIMIT` 13, `SNAPSHOT_LIMIT` 20. The session-end enum in §2 is new and separate from the reason enum.

## 6. Matrix and limits

- **Matrix:** three ENGINEERING `life` cells are added (`life:results_replication`, `life:replay_rekey`, `life:host_loss`); `round:sudden_death_lagsanay` additionally requires `life:results_replication`. Default-deny; no VERIFIED cell. `MIN_PROTOCOL` becomes `1.2/schema6/0x07FF`.
- **Known interactions:** a rejected frame from an assigned peer still releases or reserves its seat (v1.5), so only stale or repeated results are repaired instead of rejected. A mid-replay peer loss shrinks the roster after the room restarted; the match continues through the existing disconnect-elimination path.
- **Not claimed:** any result, replay, loss, phone, rendered or performance result. The 128-entry bound is a protocol limit, not a measured one.
- **Not in scope:** host migration, persistence to disk, internet/relay, encryption, touch HUD redesign (P10), performance (P11).
