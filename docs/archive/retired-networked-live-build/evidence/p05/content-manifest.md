# NLB-P05 Offline Live-Build Content Manifest

**Date:** 2026-10-20 · **Route profile:** `nlb_p05_live_build` · **Base:** P12 scheduled room and its existing event schedule · **Status:** scoped offline engineering content; not P07-wide certification.

The opt-in room applies a three-variant construction allowlist before Pugad generation. The Pugad generator still applies each item's existing `modes_allowed` filter for the locked P12 round, so a family is dealt only when it is eligible for every active mode. The scheduled default route retains its existing full pool.

| Content cell | P05 handling | Evidence / limit |
|---|---|---|
| `build.hollow_blocks.cell_1x1` | Enabled as persistent construction in any P12 mode permitted by the family's `modes_allowed` list. | Focused live commit, inventory, stage-version and activation-grace checks; existing P05/P12 suites. |
| `build.hollow_blocks.stack_2x3` | Enabled as persistent construction in any P12 mode permitted by the family. | Existing P05/P12 pair and stack suites; no separate P05 live stack capture. |
| `build.bamboo_bridge.span_4x1` | Enabled as persistent construction in any P12 mode permitted by the family. | Existing P05/P12 mode and placement suites; no separate P05 live bridge capture. |
| `round_objective.barya.coin_1x1` (P12's assigned 1×1 objective) | Offered only by the existing P12 Karera offer policy. Uses the live cursor/request path, remains nonpersistent, and does not enter construction counts. | P05 live-route placement assertion plus the 72-check Barya suite. Full live pickup/drop/capture/receipt/scoring lifecycle still needs a dedicated P05 event matrix. |
| All other enabled-by-default block/item variants | Disabled from the opt-in P05 Pugad pool. They remain available on the scheduled fallback wherever its current rules allow them. | P05 live-specific mover sweep, projectile/effect, support-removal, and item/mode interaction evidence is incomplete. The fallback is the documented handling until those cells pass review. |
| Other P12 events and sudden death | P12 schedule, terminal ordering, and same-stage sudden-death controller are inherited. No Pugad or new item is started for sudden death. | Existing P08/P09/P11/P12 suites pass; full P05 live event and sudden-death matrix remains open. |

This manifest reflects the P05 route's actual runtime allowlist, not the default P12 pool or the separate first-playable route. The allowlist is intentionally small while live-specific content safety evidence is incomplete. No P07-wide certification is claimed.

**Forward link (2026-10-21):** the hard-coded allowlist was replaced by the preparatory [NLB-P07 compatibility matrix](../p07/compatibility-matrix.md). The offline live route keeps exactly these three variants through its `offline_live` cells; the networked live route uses the matrix's default-deny cells. Neither is verified.
