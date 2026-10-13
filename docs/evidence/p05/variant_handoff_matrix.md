# P05 exact variant handoff

Seed: `12345`; enabled variants were Kaing 1x1, Kaing 2x3, and Tulay 4x1.

| Run | Seat | Egg | Expected variant | Hatch/ghost | Placed piece | Evidence |
|---|---:|---|---|---|---|---|
| 1 | P1 | `egg_01` | `build.bamboo_bridge.span_4x1` | `build.bamboo_bridge.span_4x1` | pending | `02_pugad_eggs` → `04_place_exact_variant_pairs` |
| 1 | P2 | `egg_02` | `build.hollow_blocks.stack_2x3` | `build.hollow_blocks.stack_2x3` | pending | `02_pugad_eggs` → `04_place_exact_variant_pairs` |
| 1 | P4 | `egg_03` | `build.hollow_blocks.stack_2x3` | `build.hollow_blocks.stack_2x3` | pending | `02_pugad_eggs` → `04_place_exact_variant_pairs` |
| 1 | P3 | `egg_04` | `build.hollow_blocks.cell_1x1` | `build.hollow_blocks.cell_1x1` | pending | `02_pugad_eggs` → `04_place_exact_variant_pairs` |
| 1 | P2 | same egg | Kaing 2x3 | `build.hollow_blocks.stack_2x3` | 3x2 cells (96x64 wu) | `05_place_rotated_2x3_ghost` |
| 1 | P1 | `egg_01` | `build.bamboo_bridge.span_4x1` | `build.bamboo_bridge.span_4x1` | `build.bamboo_bridge.span_4x1` | `04_place_exact_variant_pairs` → `06_diagnostic_play` |
| 1 | P2 | `egg_02` | `build.hollow_blocks.stack_2x3` | `build.hollow_blocks.stack_2x3` | `build.hollow_blocks.stack_2x3` | `04_place_exact_variant_pairs` → `06_diagnostic_play` |
| 1 | P4 | `egg_03` | `build.hollow_blocks.stack_2x3` | `build.hollow_blocks.stack_2x3` | `build.hollow_blocks.stack_2x3` | `04_place_exact_variant_pairs` → `06_diagnostic_play` |
| 1 | P3 | `egg_04` | `build.hollow_blocks.cell_1x1` | `build.hollow_blocks.cell_1x1` | `build.hollow_blocks.cell_1x1` | `04_place_exact_variant_pairs` → `06_diagnostic_play` |
| 2 | P4 | `egg_01` | `build.bamboo_bridge.span_4x1` | `build.bamboo_bridge.span_4x1` | pending | `02_pugad_eggs` → `04_place_exact_variant_pairs` |
| 2 | P1 | `egg_02` | `build.hollow_blocks.stack_2x3` | `build.hollow_blocks.stack_2x3` | pending | `02_pugad_eggs` → `04_place_exact_variant_pairs` |
| 2 | P2 | `egg_03` | `build.bamboo_bridge.span_4x1` | `build.bamboo_bridge.span_4x1` | pending | `02_pugad_eggs` → `04_place_exact_variant_pairs` |
| 2 | P3 | `egg_04` | `build.bamboo_bridge.span_4x1` | `build.bamboo_bridge.span_4x1` | pending | `02_pugad_eggs` → `04_place_exact_variant_pairs` |
| 2 | P1 | same egg | Kaing 2x3 | `build.hollow_blocks.stack_2x3` | 3x2 cells (96x64 wu) | `05_place_rotated_2x3_ghost` |
| 2 | P4 | `egg_01` | `build.bamboo_bridge.span_4x1` | `build.bamboo_bridge.span_4x1` | `build.bamboo_bridge.span_4x1` | `04_place_exact_variant_pairs` → `06_diagnostic_play` |
| 2 | P1 | `egg_02` | `build.hollow_blocks.stack_2x3` | `build.hollow_blocks.stack_2x3` | `build.hollow_blocks.stack_2x3` | `04_place_exact_variant_pairs` → `06_diagnostic_play` |
| 2 | P2 | `egg_03` | `build.bamboo_bridge.span_4x1` | `build.bamboo_bridge.span_4x1` | `build.bamboo_bridge.span_4x1` | `04_place_exact_variant_pairs` → `06_diagnostic_play` |
| 2 | P3 | `egg_04` | `build.bamboo_bridge.span_4x1` | `build.bamboo_bridge.span_4x1` | `build.bamboo_bridge.span_4x1` | `04_place_exact_variant_pairs` → `06_diagnostic_play` |

The rotated 2x3 ghost changes from 2x3 to 3x2 cells while keeping the same item key.
