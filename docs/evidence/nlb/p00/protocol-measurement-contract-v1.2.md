# NLB-P00 contract amendment — wire minor 2 / gameplay stream

**Contract version:** wire major 1, minor 2; schema 2. **Date:** 2026-10-21. **Status:** approved P04 protocol design; source implementation and bounded host/client checks exist, while raw ENet ordering, fault recovery and full acceptance remain unverified. This amendment supplements [v1](protocol-measurement-contract-v1.md) and [the implemented P02 v1.1 clarification](protocol-measurement-contract-v1.1.md). It does not replace P02 framing, invitation, discovery, lobby, approval, or seat-capacity rules.

> **Forward link (2026-10-21):** [v1.3](protocol-measurement-contract-v1.3.md) amends this contract for NLB-P06 live placement (schema 3, required mask `0x00FF`, families `0x1B`–`0x1D`, revised `0x1A`, 10-byte match lifecycle). The text below records the P04 design as approved.

P04 targets the existing P12 scheduled `karera_slice` route (`Pugad → Place → Play`). The offline route remains the default. NLB-P05 live-build and P06 placement requests are not enabled. Old lobby-only binaries with schema 1 / feature mask `0x000F` cannot start or enter a P04 match. A P04 peer must negotiate schema 2 and every required feature bit; there is no gameplay downgrade.

## 1. Transport and families

The application envelope stays exactly 22 bytes, `TILK`, with 900 bytes maximum including the envelope. Transport is raw Godot `ENetConnection` / `ENetPacketPeer`; SceneMultiplayer RPCs, `get_var`, Object decoding, client-selected resources, and client-selected seats remain prohibited.

Configure three channels at both endpoints: channel 0 for reliable control/events, channel 1 for unreliable-sequenced input, channel 2 for unreliable-sequenced authoritative state. The source currently requests channel flags `0` for channels 1–2 and does not request `FLAG_UNSEQUENCED`. Exact raw ENet ordering/flag behavior remains an experiment and is not claimed verified by this amendment.

| ID | Family | Channel | Direction |
|---:|---|---:|---|
| `0x0F` | Match lifecycle | 0 | Host → admitted peers |
| `0x10` | Continuous input | 1 | Assigned peer → host |
| `0x11` | Action request | 0 | Assigned peer → host |
| `0x12` | Action result | 0 | Host → requester |
| `0x13` | State update | 2 | Host → synchronized peers |
| `0x14` | Snapshot request | 0 | Client → host |
| `0x15` | Snapshot chunk | 0 | Host → client |
| `0x16` | Snapshot end | 0 | Host → client |
| `0x17` | Snapshot acknowledgment | 0 | Client → host |
| `0x18` | Sync ready | 0 | Host → client |
| `0x19` | Authoritative event | 0 | Host → synchronized peers |
| `0x1A` | Terrain commit | 0 | Host → synchronized peers |

Feature bits 0–3 (`0x000F`) retain P02 meanings. Bit 4 (`0x0010`) means logical-input transport, bit 5 (`0x0020`) authoritative view schema, and bit 6 (`0x0040`) snapshot recovery. P04 requires `0x007F`. Compatibility hello remains 38 bytes: digest[32], major u8, minor u8, schema u16 LE, features u16 LE.

## 2. P04 bounded payloads

All integers are little-endian. New gameplay messages contain no seat ID. The authenticated transport peer maps to one host-owned seat and a nonzero `peer_generation:u32`; generation increments on each new seat binding. Input is accepted only when peer, generation, session epoch, match, round, attempt, family/channel, phase, sequence, range, and rate are current.

`CONTINUOUS_INPUT` is 41 bytes: match ID u64; round u32; attempt u16; peer generation u32; sample sequence u32; client tick hint u32; movement X/Y signed i16 thousandths; aim X/Y signed i16 thousandths; held mask u16; build intent u8; reliable-edge watermark u32. Axes outside `[-1000,1000]` reject the whole sample. World position/velocity use signed Q8 fixed point (256 wire units per world unit). Current held bits are left (bit 0), right (bit 1), up (bit 2), down (bit 3), jump (bit 4), and sneak (bit 5); unknown bits reject.

`ACTION_REQUEST` is 53 bytes: request ID u64; match ID u64; round u32; attempt u16; peer generation u32; edge sequence u32; action enum u8; target ID u64; cell X/Y signed i32; rotation u8; pressed u8; client tick hint u32. Current route actions are jump, confirm, back, rotate, claim, cheer, and directions; IDs outside the route allowlist reject. A result carries request ID u64 and reason u16. Exact request-ID retry with identical bytes returns the cached result; changed-payload reuse rejects. Cache target is 32 results per peer / 120 seconds. Limit is 10 action messages/s per peer and 2/s per action; continuous input targets 30 Hz and hard-limits at 60/s.

Reliable edge sequences and continuous held revisions share a watermark. A one-shot edge represented by a newer held sample is applied once; a late held-action press cannot override a newer release. If no valid continuous sample arrives for 150 ms by the host's monotonic receipt clock, clear movement, held actions, aim/build state, and queued stale edges. Invalid, stale, duplicate, wrong-channel, wrong-phase, wrong-generation, out-of-range, or excess-rate packets do not refresh the timer. After a transient timeout, only a fresh valid sample from the still-bound peer can restore input. Initial assignment and snapshot resync require a fresh neutral sample after snapshot readiness; snapshot installation never replays input.

`STATE_UPDATE` includes a typed metadata record plus one complete current entity record so a dropped frame does not make later state depend on a lost property patch. The metadata record includes host camera position in Q8 and camera zoom as `u16` Q8 (valid 0.25–2.0); its fixed portion is 61 bytes before the map ID. Positions and velocities are Q8. Records currently cover seat transform/velocity/lifecycle/score, construction block transform/velocity/collapse state, Barya objective, event context, and explicit entity tombstones. P04 source target is 20 Hz. Critical metadata/score changes use monotonic reliable event revisions; terrain uses reliable versioned commits.

Snapshots use metadata and length-prefixed typed records. The encoded snapshot is at most 65,536 bytes; chunks carry 858 bytes maximum, at most 77 chunks; full application frames remain ≤900 bytes. Each transfer includes snapshot ID, chunk index/count, total length and CRC32; end and acknowledgment must match ID/checksum/length. Validate and assemble before atomic replica replacement. Input remains disabled until matching acknowledgment and host `SYNC_READY`. Retries and buffers are bounded; repeated failure closes or leaves the peer unsynchronized rather than truncating state.

## 3. Replicated-state limits and verification status

Host simulation owns phase, timers, physics, item state, event schedule, Barya, RNG, terminal decisions and scores. The current codec uses typed seat, stage, Barya, event-context and tombstone records; local map catalog data is draw-only on clients. Clients do not deserialize Variants or instantiate client-named scenes. The initial P04 client canvas currently covers shared camera framing, actors, score, current event, Barya, and construction records; complete outcome-ledger history, all transient/projectile visuals, and detailed presentation parity remain acceptance items until shown by code review and tests.

The P04 source does not establish measured ENet ordering, latency, traffic, performance, physical-phone behavior, loss recovery, or full content convergence. Those require the deferred experiment and testing window. Targets remain separate: host 60 Hz / 16.67 ms at 1080p; phone ≥30 FPS / p95 ≤33.3 ms at 720p; proposed 512 MiB process-memory target. No bandwidth threshold is defined. Record application bytes separately from transport overhead/retransmissions, and measure RTT, host receipt-to-commit, and client receive-to-render separately.
