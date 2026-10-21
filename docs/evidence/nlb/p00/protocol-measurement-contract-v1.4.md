# NLB-P00 contract amendment — schema 4 / live transients and content matrix

**Contract version:** wire major 1, minor 2; schema 4; required feature mask `0x01FF`. **Date:** 2026-10-21. **Status:** NLB-P07 preparatory source design. The source is authored. No Godot parse, test, multi-process, loss/reorder, phone or rendered run has executed (`COULD-NOT-RUN — deferred while the shared laptop is in use`). This amendment supplements [v1](protocol-measurement-contract-v1.md), [v1.1](protocol-measurement-contract-v1.1.md), [v1.2](protocol-measurement-contract-v1.2.md) and [v1.3](protocol-measurement-contract-v1.3.md). It changes only the items listed here. NLB-P08 supersedes the schema, feature mask and build ID in [v1.5](protocol-measurement-contract-v1.5.md). The P02 lobby rules, the P04 input/state/snapshot rules and the P06 placement families stay in force.

**Route and scope:**
- The opt-in network live-build route (`-- --match-route=network_live_build` on the PC host) now takes its content from the NLB-P07 live compatibility matrix ([matrix](../p07/compatibility-matrix.md), source `tilaok!/scripts/network/nlb_live_compatibility_matrix.gd`) instead of the P05/P06 three-variant allowlist.
- The matrix is default-deny. VERIFIED cells are selectable; ENGINEERING cells only with the host development override `--nlb-unverified-content`; DISABLED cells never. No cell is VERIFIED yet.
- The scheduled P12 network route stays the default and sends no transient records.
- The offline routes are unchanged. The offline live route keeps its exact P05 slice through the matrix's `offline_live` cells.

## 1. Versioning and identity

- **Envelope minor stays 2,** for the reason given in v1.3 §1.
- **Gating:** live transients and the 11-byte lifecycle are gated by schema 4 and feature bit 8 (`0x0100`, live transients). Exactly `0x01FF` is required (`NetworkFrame.FEATURE_REQUIRED_MASK`). The compatibility hello stays 38 bytes.
- **Older hellos:** the host refuses a schema-3 / `0x00FF` (P06) hello with `INCOMPATIBLE` and closes the peer; schema 2 is refused the same way. A mismatched peer is never half-admitted.
- **Manifest:** the compatibility manifest `build` becomes `tilaok-nlb-p07-2026-10-21`. It gains `live_matrix: {version, cells: [{id, status, reason, min_protocol, min_content, requires}]}`, canonical-sorted by id.
- **Digest mismatch:**
  - A peer with a different matrix computes a different digest. It is refused before admission with the existing readable build-mismatch notice.
  - The digest cannot tell a matrix mismatch from any other content mismatch, so the notice text is unchanged.
- **The override is not in the digest:**
  - It is host policy. Android clients can never set it, so folding it into the digest would make every phone incompatible with a development host.
  - Instead it travels in `MATCH_LIFECYCLE` and is shown as a banner.
- **`MATCH_LIFECYCLE` grows from 10 to 11 bytes:** `u8 1`, `u64 match_id`, `u8 route` (0 scheduled, 1 live build), `u8 flags`.
  - Flags bit 0 means "unverified content": the host runs ENGINEERING cells under the override.
  - Clients show "UNVERIFIED CONTENT — development host; results are not evidence."
  - Other flag bits, other route values, and the 9- or 10-byte forms are rejected.

## 2. New state records (inside the existing STATE_UPDATE family `0x13` and snapshots)

| Type | Record | Size | Notes |
|---:|---|---|---|
| 6 | Live transient | exactly 37 | Host → synchronized peers; unreliable state channel, plus snapshots |
| 7 | Transient end | exactly 4 | Host → synchronized peers; repeated 3 times (same as tombstones) |

**Live transient (37 bytes), in order:**
- type u8 = 6
- kind u8 (1 projectile, 2 bubble, 3 blast flash, 4 mover)
- transient ID u16 (1..65535, unique per kind while live)
- owner entity u64 (the placed item's wire entity ID; 0 when none)
- position X/Y i32 and velocity X/Y i32 (×256 fixed point)
- phase u8 (0..7)
- timer ms u16
- owner seat i8 (−1..3)
- captive seat i8 (−1..3; bubbles only)
- extent W/H u16 (world units)

**Transient end (4 bytes):** type u8 = 7, kind u8, transient ID u16.

**Caps per kind:**

| Kind | Cap | Source |
|---|---:|---|
| Projectiles | 16 | v1 §1 |
| Bubbles | 4 | v1 §1 |
| Blast flashes | 32 | v1 §1 VFX |
| Movers | 48 | persistent stage-entity cap, one per mover |
| Total | 100 | |

**Snapshots:**
- At most 4 + 48 + 8 + 100 = 160 records.
- The snapshot version u16 stays 1. Every peer that can decode it already passed the schema-4 hello.
- Worst case on paper is 4×26 + 48×83 + 8×22 + 100×37 plus 2 bytes per record. That is about 8.3 KB, well under 65,536 B. This is not measured.

**Bounds:**
- Over a cap, the host never truncates.
  - A periodic send logs `NLB_P06_TERRAIN_RESYNC reason=CONTENT_LIMIT_EXCEEDED live transients` once and forces snapshots.
  - A snapshot whose transients exceed a cap is refused with `SNAPSHOT_LIMIT` (admission decision) and the peer is closed.
  - A client that unpacks an over-cap snapshot rejects it as `SNAPSHOT_LIMIT`.
- The offline `TransientBudget` already caps projectiles at 16 and bubbles at 4, so this path is a guard.

**What rides where:**
- Collapse countdowns, Parol pulse phase and grace keep riding the STAGE_ENTITY record: its state flags, `timer_ms` and lifecycle.
- A Trumpo's moving top is a mover transient, because the stage record's position stays the placement origin.

## 3. Host rules

- **Host is the only source:** every transient is produced by the host room from the shared item runtime: `LauncherBehavior.projectiles`, `BubbleBehavior`, `TrumpoBehavior`, and live one-shot blasts. Clients draw them and never spawn, move, collide or resolve them.
- **End notices:** a transient that disappears gets a transient-end notice, repeated 3 times. A client also drops any transient the host has not refreshed for 500 ms (`TRANSIENT_STALE_MS`).
- **Snapshots:** a snapshot carries every live transient with its remaining timer and captive seat. A peer that resyncs during a blast, sweep or capture installs the same state.
- **Commit-time recheck:** before the shared validator runs, the live room rechecks that the assigned variant's matrix cell is selectable for every mode of the round (`variant_disabled`, `INVENTORY`). A remote intent is refused the same way on receipt.

## 4. Reason enums (additions)

The detail values below are new in `NetworkPlacementCodec.Detail` (41–49). Their client-local text is not wire data.

| Reason | New detail codes |
|---|---|
| `OK` 0 | one_shot (CLEANUP_DONE 41) — an accepted Walis/explosive edit; carries no entity ID |
| `PLACEMENT_BLOCKED` 17 | protected_target (42), unsafe_support (44), invalid_cleanup / cleanup_rejected (45), lethal_clearance (46), crush_risk (47), projectile_lane (48), one_shot_unsupported (49) |
| `STALE_STATE` 11 | stale_target (43) |

Before v1.4, an accepted one-shot edit (`one_shot`) was missing from the table and would have failed closed as `INTERNAL_RETRY`. No allowlisted item reached that path then.

## 5. Client rules

- The client presentation draws each transient kind with its own shape and glyph: projectile square with "»", bubble ring with the captive "P#", dashed blast area with "POP", mover square with "◆". It never depends on colour alone.
- The client never decides content availability. The lobby list of disabled cells and their reasons is host-only. Clients see only the host's lifecycle flag.

## 6. Limits not claimed

- No transient bandwidth, latency, loss/reorder, phone, rendered or performance result is claimed.
- The worst-case snapshot size above is arithmetic, not a measurement.
- The proposed targets from v1.3 §6 remain unmeasured.
