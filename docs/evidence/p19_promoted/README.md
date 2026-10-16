# Promoted P19 obstacles — October 16, 2026

The user asked to "continue on phasetasks" and chose "pick 3 low-risk ones". Claude (AI) promoted three expansion designs into the main game as block scenes with DEBUG placeholder art.

Test setup: headless Godot 4.7.stable.official.5b4e0cb0f, Windows 11, Item Lab (default arena, 64 wu grid), one synthetic K1 seat, `--fixed-fps 60`. Reviewer: Claude (AI, automated). No human, art, playtest or feel review is claimed.

| Family | Scenes | Contract as built |
|---|---|---|
| `build.house_stairs` — Hagdan ng Bahay | `scenes/blocks/construction/hagdan_steps_2x2.tscn`, `hagdan_steps_3x3.tscn` | One solid column per step, rising toward one side. Four rotations; anchored; support- and wall-eligible; removable by Walis and explosives. Modes: Karera and Lagsanay (Kangaroo pending). |
| `hazard.toy_burr_strip` — Tinik-Tinik Strip | `scenes/blocks/traps/tinik_strip_3x1.tscn`, `tinik_strip_4x1.tscn` | No solid body; an 18 wu kill strip along the bottom of its cells. Four rotations; a direct kill credited to the placer. Modes: Karera (Lagsanay and Kangaroo pending the wholesome-art review). |
| `modifier.sorbetes_ice` — Yelo ng Sorbetero | `scenes/blocks/construction/yelo_ice_3x1.tscn`, `yelo_ice_4x1.tscn` | A solid slab with BlockData `slippery`. `ChickenController._on_slippery_floor` scales braking (`ice_brake_scale` 0.12), grip (`ice_accel_scale` 0.6) and run speed (`ice_speed_scale` 1.25). No credit. Modes: Karera and Lagsanay (Kangaroo pending). |

Each family has egg weight 20 and joined the match pool from its scene alone. Event rounds deal each family only in its approved modes.

## `tests/run_p19_promoted_tests.gd` — 25 checks, 0 failures ([log](2026-10-16_p19_promoted_tests.txt))

- **Catalog:** stays valid; all six variants are in the catalog and the match pool; mode flags as above; the 3×3 stairs are three solid columns; the strip has no solid region; each weight is 20.
- **Stairs:** a chicken stands on each 3×3 step (feet 512 / 448 / 384 wu). A quarter-turned 2×2 keeps three solid cells (12288 wu²).
- **Tinik:** walking into the strip eliminates the chicken, with a credit-eligible kill owned by the placer (`hazard.toy_burr_strip`). A chicken held 40 wu above it is never touched.
- **Ice:** after letting go at full speed, the chicken slides 323 wu on ice and stops at once on the floor. Top speed is 700 vs 560 wu/s. No elimination or credit records.

## Count checks made catalog-driven

`run_p04_tests.gd` and `run_p10_tests.gd` hardcoded family and variant counts (16 / 25), so every new block scene broke them. They now compare against `BlockCatalog` and still require the known families: P04 270/270 ([log](2026-10-16_p04_tests.txt)), P10 438/438 ([log](2026-10-16_p10_tests.txt)).

## Still open (P19)

- Approval: named owners and capacity (T23/T88/T78 stay unchecked).
- Final art, audio, Library animation and cultural review (T25/T90/T80).
- Family-specific removal, support-provenance and event checks (T26/T91/T81).
- Verification before promotion, including 2/3/4 players and minimum zoom (T27/T92/T82).
- Human feel review of the ice values.
