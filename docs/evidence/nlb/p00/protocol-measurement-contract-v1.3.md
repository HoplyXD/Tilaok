# NLB-P00 contract amendment — schema 3 / live placement

**Contract version:** wire major 1, minor 2; schema 3; required feature mask `0x00FF`. **Date:** 2026-10-21. **Status:** NLB-P06 preparatory source design. The source is authored. No Godot parse, test, multi-process, loss/reorder, phone or rendered run has executed (`COULD-NOT-RUN — deferred while the shared laptop is in use`). This amendment supplements [v1](protocol-measurement-contract-v1.md), [v1.1](protocol-measurement-contract-v1.1.md) and [v1.2](protocol-measurement-contract-v1.2.md). It changes only the items listed here; P02 lobby rules and the P04 input, state and snapshot rules stay in force.

The opt-in network live-build route (`-- --match-route=network_live_build` on the PC host) runs the P05 round over the P04 session: Pugad, then one shared 3 s GO, then active movement with live placement, then results, then the next Pugad. Live placement remains limited to the P05 allowlist: `build.hollow_blocks.cell_1x1`, `build.hollow_blocks.stack_2x3`, `build.bamboo_bridge.span_4x1`, plus P12's Barya objective. The scheduled P12 network route stays the default. The offline routes are unchanged.

## 1. Versioning and route identity

- **Envelope minor stays 2.** A P04 binary decodes `minor > 2` as malformed. Raising the minor would make an older phone drop the host welcome before it could show "This client does not match the host build." Live placement is gated by schema 3 and by feature bit 7 (`0x0080`, live placement), with `0x00FF` required exactly. Compatibility hello stays 38 bytes.
- The host refuses a schema-2 / `0x007F` (P04-only) hello with `INCOMPATIBLE` and closes the peer. A mismatched peer is never half-admitted.
- The compatibility manifest `build` becomes `tilaok-nlb-p06-2026-10-21` and gains `routes: ["network_live_build", "scheduled"]`. The profile stays `karera_slice` because a client computes its digest before it knows the host's route. An older binary therefore fails the digest check with its existing readable message.
- `MATCH_LIFECYCLE` grows from 9 to 10 bytes: `u8 1`, `u64 match_id`, then `u8 route` (0 scheduled, 1 live build). Other route values, and the 9-byte P04 form, are rejected.

## 2. New and revised families (all channel 0, reliable)

| ID | Family | Direction | Size |
|---:|---|---|---|
| `0x1A` | Terrain commit (revised) | Host → synchronized peers | 27-byte header + edits, ≤878 |
| `0x1B` | Placement intent | Assigned peer → host | exactly 48 |
| `0x1C` | Placement result | Host → requester | exactly 38 |
| `0x1D` | Live seat state | Host → owning peer | 34 + key (0..48) |

All integers are little-endian. No payload carries a seat, world transform, Variant, Object, scene path or free text.

- **Placement intent (48 bytes):** request ID u64 (1..2⁶³−1, monotonic per session); match u64; round u32; attempt u16; peer generation u32; expected stage version u32; host-issued inventory ID u64; cell X/Y i32 (|v| ≤ 1024); rotation u8 (0..3); flags u8 (must be 0).
  - A wrong size, non-zero flags, rotation above 3, or request ID 0 rejects the frame as `MALFORMED`.
  - An out-of-range cell is answered with `FIELD_RANGE`.
  - Rate: 10 frames/s/peer at the frame layer. At most 2 *new* request IDs/s/peer; exact retries are exempt. The excess gets an uncached `RATE_LIMIT`.
- **Placement result (38 bytes):** request ID u64; reason u16; status u8 (1 queued, 2 accepted, 3 rejected); entity ID u64; committed cell X/Y i32; rotation u8; stage version u32; activation tick u32 (host physics tick when grace ends); detail u16 (≤63).
  - Only an acceptance names an entity. A Barya objective acceptance has entity 0 and detail `OBJECTIVE`.
  - Only a rejection carries a non-`OK` reason.
  - `queued` is non-terminal. The host sends it once a request enters the authority queue.
- **Live seat state (34 + k bytes):** match u64; round u32; attempt u16; inventory ID u64 (0 = none); key length u8 plus ASCII key (required if and only if the inventory ID is non-zero); item status u8 (0 none, 1 available, 2 pending, 3 used); build mode u8 (0/1); rotation u8; cursor X/Y i32. The host sends it when it changes, at most every 100 ms, immediately after a resolution boundary, and after every snapshot sync. **Build mode is host-owned.** The CONTINUOUS_INPUT build-intent byte is diagnostic only and carries no authority.
- **Terrain commit (revised):**
  - Header: match u64; round u32; base version u32; new version u32 (must equal base + 1); commit tick u32; part index u8; part count u8 (1..4); edit count u8 (0..16).
  - Each edit is op u8 (1 add, 2 update, 3 remove) and entity ID u64. Add and update then carry u16 length plus one stage record (36..83 bytes) whose entity ID must match. An entity appears at most once per commit.
  - One version holds at most 16 edits, split by byte budget across at most 4 frames. Zero edits is a valid version advance.
  - The host sends only what changed since its last committed version, using add/update/remove against a host shadow. More edits than allowed, an encode failure, a version jump, or a reset forces a full snapshot (`CONTENT_LIMIT_EXCEEDED` logged). The host never sends a truncated or non-contiguous commit.
- **Stage record lifecycle byte:** 0 static/legacy; 1 grace (a live piece in its safe activation grace, with `timer_ms` holding the remaining grace, capped at 65,535); 2 is reserved for the explicit active state. Values above 2 are rejected. Scheduled rooms keep sending 0. Snapshots carry the same records, so grace state survives resync.

## 3. Host rules

- **Authority:** the seat comes from the authenticated peer binding and generation. A generation or binding mismatch is an `OWNERSHIP` frame rejection. The item variant comes from the host inventory and never from the client. The host room validates at its authority boundary with the P05 validator, actor clearance and mover sweep, and remains the only commit path.
- **Ordering:** each packet is stamped with host receipt time (`Time.get_ticks_usec()`) before any validation, then queued for the next fixed physics boundary. Ties on equal receipt time rotate seat priority by round number, then by seat. Local keyboard and gamepad seats use the same pipeline. Client time has no authority.
- **Request-ID cache:** keyed by (session epoch, implicit because caches clear on session stop; peer generation; family; request ID).
  - Each entry stores a SHA-256 of the payload, the response, a time and a terminal flag. Limits: 32 entries per peer, 120 s for terminal entries.
  - Eviction removes the oldest terminal entry only. In-flight entries are never evicted; a cache full of in-flight entries answers `REQUEST_CAPACITY`.
  - An exact retry replays the stored response (queued or terminal). A changed payload under a used ID is `REQUEST_ID_REUSE`.
  - There is no double commit, double consumption or double version bump.
- **Round close:** the round's terminal result resolves before placements in the same frame. When Play ends, every still-queued request is answered once with `ROUND_ENDED` and its item is retained. A late retry receives the cached `ROUND_ENDED`.
- **Disconnect:** the seat's queued request is cancelled before validation, so the item is retained and nothing is answered. Per-peer caches, in-flight maps, rate windows and seat-state echoes are cleared on disconnect, on peer session close, on candidate expiry, on the abuse-close path and on session stop.
- **GO (live route only):** continuous input stays eligible so a streaming peer is not rejected and released during the countdown. It is applied as neutral (no movement, held bits, aim or build). Every action is refused in GO. Scheduled-route gating is unchanged.
- **Actions:** IDs 12/13/14 are build toggle, live rotate and live cancel. They are allowed only in Play on the live route. They are press-only on the wire; the host applies the full edge. Network confirm is the placement-intent family only: ACTION confirm stays refused in Play, and the live room ignores a confirm edge from a remote seat.

## 4. Reason enums

| Reason | Detail codes (P05 source) |
|---|---|
| `WRONG_PHASE` 9 | wrong_phase, actor_ineligible, wrong_route |
| `OWNERSHIP` 10 | seat_unregistered, other_seat_item |
| `STALE_STATE` 11 | stale_attempt, stale_round, future_stage |
| `FIELD_RANGE` 12 | rotation_unsupported, out_of_bounds, cell_range |
| `RATE_LIMIT` 13 | rate_limit |
| `REQUEST_ID_REUSE` 14 | request_id_reused |
| `REQUEST_CAPACITY` 15 | request_pending, boundary_full, request_limit, request_capacity |
| `INVENTORY` 16 | inventory_missing/used/mismatch, unknown_variant, variant_disabled |
| `PLACEMENT_BLOCKED` 17 | protected spawn/goal, outside build region, immutable base, player clearance, item overlap, invalid region, mover sweep, live effect path, objective rejected, stage unavailable |
| `ROUND_ENDED` 18 | round_ended, seat_disconnected |
| `CONTENT_LIMIT_EXCEEDED` 19 | persistent_cap |
| `INTERNAL_RETRY` 25 | commit_failed and any unknown code (fail closed) |
| `MALFORMED` 1 | invalid_request_id |

The per-code detail enum lives in `NetworkPlacementCodec.Detail`. Its client-local text is not wire data.

## 5. Client rules

- The ghost is presentation only. Its states are none → tentative → pending → accepted-awaiting-terrain → none, and pending → rejected (cross plus reason, about 2 s) → none, with the item kept.
- A repeat tap and the 1.5 s timeout (at most 3 resends) resend identical bytes. After that the client shows "No reply" and the next confirm uses a new ID.
- Cancel or Build while pending only hides the preview. Closing build mode never confirms. The ghost is never labelled placed or committed. A result for another or stale request ID is ignored.
- Terrain apply:
  - `base == local` and `new == base + 1`: apply once every part has arrived. Only one pending version is buffered.
  - `new ≤ local`: idempotent ignore.
  - otherwise: a gap. Edit-dependent actions are disabled and a snapshot is requested.
- STATE_UPDATE never advances the stage version. A state record ahead of the local version for 2 s also triggers snapshot recovery. An unknown entity from STATE_UPDATE is created only when the host is at the client's version (an unversioned addition).

## 6. Limits not claimed

No raw ENet ordering, loss/reorder behavior, latency, bandwidth, performance, phone or rendered result is claimed for this amendment. The proposed targets remain host 60 Hz / 16.67 ms at 1080p, phone ≥30 FPS / p95 ≤33.3 ms at 720p, and 512 MiB; all are unmeasured. The 44 dp touch-target minimum is proposed; its dp conversion is unverified (P10).
