# NLB-P07 live compatibility matrix

**Status:** preparatory source, 2026-10-21. Nothing has run (`COULD-NOT-RUN — deferred while the shared laptop is in use`). The matrix is not signed off, and no cell is VERIFIED. Tracker tasks NLB-P07-T01/T02/T03 stay unchecked. P06-T03 and the upstream dependencies (P03-T03, P04-T03, P05-T02/T03) remain open.

**Source of truth:** `tilaok!/scripts/network/nlb_live_compatibility_matrix.gd` (`NLBLiveCompatibilityMatrix`). It is a GDScript constant table, not JSON, because the current export filter would not ship a `.json` file. This document must list exactly the rows that `NLBLiveCompatibilityMatrix.markdown_rows()` produces. `tests/run_nlb_p07_tests.gd` checks every row against it when the deferred suite runs.

**Matrix version:** 1. **Minimum protocol for every cell:** `1.2/schema6/0x07FF` ([contract v1.6](../p00/protocol-measurement-contract-v1.6.md); NLB-P09 raised it from `1.2/schema5/0x03FF`, [v1.5](../p00/protocol-measurement-contract-v1.5.md), which NLB-P08 had raised from `1.2/schema4/0x01FF`, [v1.4](../p00/protocol-measurement-contract-v1.4.md)). **Minimum content:** `tilaok-nlb-p09-2026-10-21`.

## How it is used

**Policy.** Unsupported or unknown content stays disabled with a reason.
- Default deny:
  - An unknown id, or catalog content without a reviewed rule, is `DISABLED` / `UNKNOWN_CONTENT`.
  - A `DISABLED` cell is never selectable.
  - A cell whose `requires` closure is not selectable is `DEPENDENCY_DISABLED`.
- `VERIFIED` is selectable. None exist yet.
- `ENGINEERING` (live rule authored, network verification pending) is selectable only on a PC host started with `-- --nlb-unverified-content`.
- That development override:
  - is never the default;
  - is ignored on Android and on release export templates;
  - is logged at start (`NLB_P07_LIVE_MATRIX … override=true` plus an `UNVERIFIED CONTENT` warning);
  - is announced to clients through the v1.4 `MATCH_LIFECYCLE` flag, which shows "UNVERIFIED CONTENT — development host; results are not evidence."
- A strict host (no override) is refused at the start gate with a readable reason.

**Enforcement points:** all on the host, which owns availability. Clients never decide it.
- **Pugad dealing:** each round's pool is the variants whose item cell is selectable in every active mode (Main plus Twist).
- **Barya:** offered only if its cell is selectable.
- **Schedule:** Main Challenges and stack rows come from the round cells.
- **Start gate:**
  - the map cell;
  - the Karera, Lagsanay and sudden-death round cells, because rounds 1/4/8/12 and the tie-break require them;
  - a non-empty Karera pool;
  - `validate()` must report no errors.
- **Intent receipt and commit boundary:** the cell is rechecked; a failure is `variant_disabled`.
- **Lobby:** the host lobby lists the cells that are off, with their reasons.

**Identity.**
- The `live_matrix` record enters the compatibility manifest digest, so a peer with a different table is refused before admission as `INCOMPATIBLE`, with the existing build-mismatch text.
- The override is host policy, not identity. It is not part of the digest.

**Offline route.** The opt-in offline live route keeps its exact P05 slice through the `offline_live` tag on `build.hollow_blocks.cell_1x1`, `build.hollow_blocks.stack_2x3` and `build.bamboo_bridge.span_4x1`. There is no second list.

## Shape and counts

There are 97 cells (NLB-P08 added `life:client_lifecycle`, `life:host_pause` and `life:seat_reclaim`; NLB-P09 added `life:results_replication`, `life:replay_rekey` and `life:host_loss`), factored on four axes instead of one cross product:

| Axis | Cells | ENGINEERING | DISABLED (reason) |
|---|---:|---:|---|
| `life:` cross-cutting live behavior | 12 | 12 | — |
| `map:` MapCatalog maps | 4 | 3 | 1 (`tutorial`: NO_LIVE_RULE) |
| `round:` Mains, stacks, sudden death, Kangaroo commands | 10 | 10 | — |
| `item:` variant × allowed mode (34 variants), plus Barya in Karera | 71 | 64 | 7 (DISABLED_BY_DEFAULT: `hollow_blocks.column_1x3` ×3, `bamboo_bridge.span_3x1` ×2, `bamboo_bridge.span_5x1` ×2) |
| **Total** | **97** | **90** | **7** |

**Notes on the axes:**
- A mode that a family does not allow, or that is only pending review, gets no cell. Offline never deals it either.
- Kangaroo requires all three command cells, so turning one off cannot silently change the event's meaning.
- Unimplemented events (for example Langit-Lupa) are not catalog modes and have no cell.

## Special-case coverage (NETWORKED_LIVE_BUILD.md §6.2)

| Behavior | Host source (unverified) | Live rule |
|---|---|---|
| Walis Cleanup | `ItemManager.apply_live_one_shot`, `NLBP05LiveBuildMatchRoom._commit_live_intent` | Targets removable pieces committed at an earlier authority boundary (entity age); same-boundary edits and pending requests are never touched; protected base/spawn/goal is excluded (fixed P05 crash); no entity on the wire; versioned REMOVE ops; no Patibong |
| Bomb / Dynamite / Nuke | same one-shot path | Detonates at the host commit boundary (user decision 2026-10-21; no new fuse); offline same-Place blast rule not applied; host blast flash replicated as a transient |
| Lethal / stun zones (Spikes, Tinik, Parol, Trumpo) | `_live_effect_check` | Extra lethal clearance (64 wu beyond the 32 wu actor clearance) across footprint and effect regions; grace/tell from host commit (existing activation grace) |
| Projectiles / moving paths (Tsinelas, Cannon, Bula, Trumpo) | `_live_effect_check`, `_live_effect_rects_in_flight`, `network_transient_states` | Geometric in-flight check replaces the global refusal; projectiles, bubbles (captive seat) and mover positions replicate as v1.4 transients |
| Collapse / physics (Collapsing Block, Wood Box, light Kaing) | existing `StageBlock` host state; `_live_effect_check` fall path | Collapse/restore host-owned (restore waits for no overlap); movable blocks refused over a chicken (`crush_risk`) |
| Barya | P12 objective; `_commit_live_intent` | Refused commits now `objective_rejected` (was an accepted code that encoded as INTERNAL_RETRY) |
| Rising / Freeze / Hug | shared P12 Kangaroo controller | Audit: terminal step resolves before the tick's edits (contract v1.3 §3); build aim/rotate/confirm never emit Freeze movement edges or Hug contacts |
| Round end / pending edits | existing `_close_live_attempt` | Gate closes before scoring; queued requests answered once with ROUND_ENDED |
| Sudden Death | existing | No placement request accepted; reuses persisted construction |
| Lagsanay, Kangaroo, stacks, terminal order, exact scores | shared P12/P09 rooms | Unchanged rules; gated by round/stack cells; parity runner `tests/run_nlb_p07_matrix_runner.gd` (deferred) |

## Cells

| Cell | Axis | Status | Reason | Requires |
|---|---|---|---|---|
| `item:block.cannon.main@kangaroo` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:block.cannon.main@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:block.cannon.main@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:block.spikes.main@kangaroo` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:block.spikes.main@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:block.spikes.main@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:build.bamboo_bridge.span_3x1@kangaroo` | item | DISABLED | DISABLED_BY_DEFAULT | — |
| `item:build.bamboo_bridge.span_3x1@karera` | item | DISABLED | DISABLED_BY_DEFAULT | — |
| `item:build.bamboo_bridge.span_4x1@kangaroo` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:build.bamboo_bridge.span_4x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:build.bamboo_bridge.span_5x1@kangaroo` | item | DISABLED | DISABLED_BY_DEFAULT | — |
| `item:build.bamboo_bridge.span_5x1@karera` | item | DISABLED | DISABLED_BY_DEFAULT | — |
| `item:build.collapsing_block.cell_1x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:build.collapsing_block.cell_1x1@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:build.hollow_blocks.cell_1x1@kangaroo` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:build.hollow_blocks.cell_1x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:build.hollow_blocks.cell_1x1@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:build.hollow_blocks.column_1x3@kangaroo` | item | DISABLED | DISABLED_BY_DEFAULT | — |
| `item:build.hollow_blocks.column_1x3@karera` | item | DISABLED | DISABLED_BY_DEFAULT | — |
| `item:build.hollow_blocks.column_1x3@lagsanay` | item | DISABLED | DISABLED_BY_DEFAULT | — |
| `item:build.hollow_blocks.stack_2x3@kangaroo` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:build.hollow_blocks.stack_2x3@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:build.hollow_blocks.stack_2x3@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:build.house_stairs.steps_2x2@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:build.house_stairs.steps_2x2@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:build.house_stairs.steps_3x3@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:build.house_stairs.steps_3x3@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:build.solid_block.slab_3x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:build.solid_block.slab_3x1@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:build.wood_box.box_2x2@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:build.wood_box.box_2x2@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:explosive.bomb.main@kangaroo` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:explosive.bomb.main@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:explosive.bomb.main@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:explosive.dynamite.main@kangaroo` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:explosive.dynamite.main@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:explosive.dynamite.main@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:explosive.nuke.main@kangaroo` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:explosive.nuke.main@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:explosive.nuke.main@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.bubble_planter.path_1x3@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.bubble_planter.path_1x5@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.parol_pulse.span_3x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.parol_pulse.span_4x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.parol_pulse.span_5x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.parol_pulse.span_6x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.rail_trumpo.rail_4x1@kangaroo` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.rail_trumpo.rail_4x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.rail_trumpo.rail_4x1@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.rail_trumpo.rail_5x1@kangaroo` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.rail_trumpo.rail_5x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.rail_trumpo.rail_5x1@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.rail_trumpo.rail_6x1@kangaroo` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.rail_trumpo.rail_6x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.rail_trumpo.rail_6x1@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.slipper_launcher.lane_4x1@kangaroo` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.slipper_launcher.lane_4x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.slipper_launcher.lane_4x1@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.slipper_launcher.lane_6x1@kangaroo` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.slipper_launcher.lane_6x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.slipper_launcher.lane_6x1@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain, life:live_transients |
| `item:hazard.toy_burr_strip.strip_3x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:hazard.toy_burr_strip.strip_4x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:modifier.sorbetes_ice.surface_3x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:modifier.sorbetes_ice.surface_3x1@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:modifier.sorbetes_ice.surface_4x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:modifier.sorbetes_ice.surface_4x1@lagsanay` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:move.tire_spring.tire_2x2@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:round_objective.barya.coin_1x1@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:barya_lifecycle |
| `item:utility.walis_cleanup.area_3x3@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `item:utility.walis_cleanup.area_5x5@karera` | item | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `life:barya_lifecycle` | life | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:round_end_pending_edits, life:snapshot_recovery |
| `life:client_lifecycle` | life | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:snapshot_recovery |
| `life:host_loss` | life | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:results_replication |
| `life:host_pause` | life | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:snapshot_recovery |
| `life:live_transients` | life | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:snapshot_recovery |
| `life:map_transition` | life | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:snapshot_recovery, life:persistent_terrain |
| `life:persistent_terrain` | life | ENGINEERING | PENDING_NETWORK_VERIFICATION | — |
| `life:replay_rekey` | life | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:results_replication, life:seat_reclaim |
| `life:results_replication` | life | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:snapshot_recovery |
| `life:round_end_pending_edits` | life | ENGINEERING | PENDING_NETWORK_VERIFICATION | — |
| `life:seat_reclaim` | life | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:client_lifecycle, life:host_pause, life:snapshot_recovery |
| `life:snapshot_recovery` | life | ENGINEERING | PENDING_NETWORK_VERIFICATION | — |
| `map:Basic Map` | map | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:map_transition |
| `map:default` | map | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:map_transition |
| `map:sample_map` | map | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:map_transition |
| `map:tutorial` | map | DISABLED | NO_LIVE_RULE | — |
| `round:kangaroo` | round | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:round_end_pending_edits, round:kangaroo#freeze, round:kangaroo#rising, round:kangaroo#hug |
| `round:kangaroo#freeze` | round | ENGINEERING | PENDING_NETWORK_VERIFICATION | — |
| `round:kangaroo#hug` | round | ENGINEERING | PENDING_NETWORK_VERIFICATION | — |
| `round:kangaroo#rising` | round | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:persistent_terrain |
| `round:karera` | round | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:round_end_pending_edits |
| `round:lagsanay` | round | ENGINEERING | PENDING_NETWORK_VERIFICATION | life:round_end_pending_edits |
| `round:stack_kangaroo_lagsanay` | round | ENGINEERING | PENDING_NETWORK_VERIFICATION | round:kangaroo, round:lagsanay |
| `round:stack_karera_kangaroo` | round | ENGINEERING | PENDING_NETWORK_VERIFICATION | round:karera, round:kangaroo |
| `round:stack_karera_lagsanay` | round | ENGINEERING | PENDING_NETWORK_VERIFICATION | round:karera, round:lagsanay |
| `round:sudden_death_lagsanay` | round | ENGINEERING | PENDING_NETWORK_VERIFICATION | round:lagsanay, life:persistent_terrain, life:results_replication |
