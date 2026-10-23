# Tilaok! Item Catalog and Design Contracts

**Offline live-build status (2026-10-22):** the normal local route constructs items during play with a two-second visible, non-gameplay job. P20 audits the active mode-filtered item pool. Unverified or failing item interactions must remain fail-closed; see [P20](PHASETASK.md#p20--offline-live-build-and-network-retirement). Network migration is retired history in `archive/retired-networked-live-build/`.

**Pugad pool update (2026-10-23):** each new match now receives a fresh random seed (or a fixed seed through `--match-seed=<number>` for reproduction), and one nest samples eligible variants without replacement before refilling a smaller mode-specific pool. The 1×3 Kaing and 3×1/5×1 Tulay variants join the default pool. By the owner's follow-up request, the eight previously fail-closed variants listed in P20 are also selectable and constructible in live play. Their earlier test failures and missing audit remain unresolved; this re-enablement is not a safety or full-pool verification claim.

_Approved design catalog, 2026-10-12. As of 2026-10-14 the eight first-batch families have code: `build.hollow_blocks` and `build.bamboo_bridge` (P04) and `move.tire_spring`, `hazard.rail_trumpo`, `hazard.parol_pulse`, `hazard.slipper_launcher`, `utility.walis_cleanup` and `hazard.bubble_planter` (P10), all harness-verified with synthetic input on PLACEHOLDER presentation and enabled only in development profiles; nothing is release-enabled. Independent P08 `lagsanay_lab` enables only Hollow Blocks, Tulay na Kawayan, Trumpo sa Riles and Tsinelas Launcher. Actual Lagsanay direct-contact integration is verified for Trumpo and Launcher; other event/item pairings remain disabled or unreviewed. None of the 28 expansion families is implemented or playtested._

## Purpose and boundaries

This document describes original Tilaok! item designs informed by broad platform-obstacle patterns. UCH is a reference for mechanic families only: no code, art, sound, character, UI, exact layout, name, or tuning is copied. Wiki statements below are community-maintained evidence, not official product specifications; some pages were available only through search-index text. The official [Clever Endeavour changelog](https://www.cleverendeavourgames.com/changelog) and [Annifursary update](https://www.cleverendeavourgames.com/annifursary-update) show that UCH content has evolved through later updates. Do not imply every reference was present at launch.

Reference evidence:

- [Linear Saw (community wiki)](https://ultimate-chicken-horse.fandom.com/wiki/Linear_Saw): a hazard moves back and forth along a track. This is the closest pattern for a travelling trumpo.
- [Spinning Saw (community wiki)](https://ultimate-chicken-horse.fandom.com/wiki/Spinning_Saw): a distinct rotating hazard pattern, not the travelling track pattern.
- [Spring (community wiki)](https://ultimate-chicken-horse.fandom.com/wiki/Spring): a useful bounce can also propel a player into danger.
- [Honey (community wiki)](https://ultimate-chicken-horse.fandom.com/wiki/Honey): slows players and makes jumps difficult; also attaches inanimate objects to moving objects. A slow patch is only a partial adaptation.
- [Treadmill (community wiki)](https://ultimate-chicken-horse.fandom.com/wiki/Treadmill): carries grounded players in a direction that can be opposed or used.
- [Blocks and Items (community wiki)](https://ultimate-chicken-horse.fandom.com/wiki/Category%3AObjects): documents a mixture of platforms, moving things, hazards, shooty items and removal tools.
- Community search-index evidence also lists [Ferris Wheel](https://ultimate-chicken-horse.fandom.com/wiki/Ferris_Wheel), [Fan Platform](https://ultimate-chicken-horse.fandom.com/wiki/Fan_Platform), [Punching Flower](https://ultimate-chicken-horse.fandom.com/wiki/Punching_Flower), [Boxing Glove](https://ultimate-chicken-horse.fandom.com/wiki/Boxing_Glove), [Teleporter](https://ultimate-chicken-horse.fandom.com/wiki/Teleporter), and [Beehive](https://ultimate-chicken-horse.fandom.com/wiki/Beehive). Treat details as unverified where pages could not be directly inspected.
- Bubble capture and Parol Pulse’s timed light beam are original Tilaok proposals; they are not claimed as UCH classics.

Names are working names. Filipino/Hiligaynon spelling, meaning, local usage, and any educational copy require native-speaker review. The catalog does not claim that invented adaptations are traditional games. All art/audio must be made by the team, included with Godot, or properly licensed and recorded in `docs/ASSETS.md` if third-party content is actually selected.

**Asset inventory at planning time:** the project skeleton under `tilaok!/` contains only the Godot project icon; no reusable gameplay art/audio was found. Every catalog item therefore needs original team-made presentation or a properly licensed asset. Record every selected/imported asset in `docs/ASSETS.md`.

## Shared item contract

- **Stable IDs:** `build.*`, `move.*`, `hazard.*`, `utility.*`, or `modifier.*` identifiers below are design IDs, not code paths.
- **Placement unit:** use a logical tile grid sized from the project player collider and stage scale. Pixel size is intentionally undecided until it is selected and verified in the Godot project. Placement footprint, solid region, trigger region, moving sweep, projectile lane, and effect radius are separate authored data.
- **Visible item identity:** the Pugad item display shows an animated visual preview of the exact item and size variant inside the egg. It deliberately shows no item name or description, so the party flow stays visual and fast. The Library holds names, descriptions, controls, tells, counterplay, and event rules.
- **Size variants:** only the predefined variants in the grid matrix may appear. A size is visible in the egg/party-item animation and placement ghost; it never changes secretly after selection. Precision hazards keep one default size unless their row explicitly defines a variant.
- **Placement:** all players submit edits against one Place-phase snapshot. Exact/conflicting solid overlaps reject the conflicting set atomically; the result does not depend on callback order. Intentional solid/trigger overlap is allowed only when the warning and danger region remain readable. Never place on a chicken. Protected base geometry, spawn clearance, goal zone, and hidden event-goal clearance are immutable.
- **Placement guides:** any projectile, rolling launch, or bounded moving shot shows a trajectory guide during Place. Straight shots show their lane and first blocking solid; ricochets show their predicted bounce segments and expiry bound; terrain-following shots show their planned lane. If an exact path depends on live physics, show the full possible sweep/envelope instead of a misleading exact line. Guides use a non-colour cue as well as transparency/line style.
- **Walis Cleanup:** preview target set; on confirmation remove only removable player-built items. Resolve cleanup as one construction edit, then validate/commit the remaining placement set against the resulting stage snapshot. Removed items stay removed. No active Play hazard or trap credit.
- **Lifecycle:** every item is inert in Place; resets to a documented deterministic start at Play; is cleaned at match restart; and releases references, timers, signals, projectiles, and temporary player states on removal, death, round end, and restart. Movers stay inside visible bounded sweeps. Temporary objects have explicit caps/lifetimes. No persistent-save data is added.
- **Ownership/scoring:** an eliminating trap owns Patibong only when it directly causes the elimination. Self-elimination scores none. Movement or capture setup effects do not gain assist credit. Tilaok scoring values remain as defined in GDD §5.
- **Accessibility:** silhouette, motion, icons/text, and sound communicate danger; color is supplementary. Avoid rapid flashing. Validate at minimum camera zoom and during overlapping tells.
- **Configuration:** speed, timing, force, range, footprint, caps, grace, spawn weights, and feature switches are centralized tunables. Exact values below are initial proposals only, not tested balance values.
- **Event baseline:** Lagsanay uses a solid floor; each item must say whether it is enabled there. Every new item begins disabled in an event until its interactions pass the item-specific acceptance scenario. The known-good fallback remains the existing item pool plus Lagsanay.
- **P08 development profile:** `lagsanay_lab` is separate from release eligibility. Its allowlist is Hollow Blocks 1×1 and 2×3, Tulay na Kawayan 4×1, Trumpo sa Riles 4×1, and Tsinelas Launcher 4×1; the profile weights are centralized at 45/25/15/15. Only Trumpo and Launcher have actual lethal-contact/attribution acceptance in Lagsanay. Other first-batch hazards, springs, stacks and all other event combinations remain disabled. See [P08 evidence](evidence/p08/README.md).
- **Cost:** project-level prerequisites (movement, placement, ownership, scoring, reset, tutorial, round lifecycle) are not counted as free just because a given item uses them.

## Provisional logical-grid matrix

These dimensions are **proposed logical grid cells**, not final pixel measurements. The initial controller target is a chicken clearance of **1×2 cells**; validate it against the actual project collider before implementation. `W×H` means width × height in the item's default orientation. A rotated item swaps these dimensions where rotation is allowed. A footprint is what occupies the construction grid; a path, lane, sweep, or effect can extend beyond it.

| Family | Grid footprint | Separate active region / travel bound | What it does |
|---|---:|---:|---|
| **Hollow Blocks / Kaing Stack** | 1×1 or 2×3 | Solid footprint only | Builds footholds, walls, cover, and Rising-wave support. |
| **Tulay na Kawayan** | 4×1 | One-way top strip: 4×1 | A one-way bamboo bridge; pass through its underside. |
| **Gulong Talon** | 2×2 | Launch top: 2×1 | Tire spring launches a chicken upward. |
| **Trumpo sa Riles** | Rail: 5×1 | Moving-top sweep: 5×1 | Spinning top moves back and forth along a rail. |
| **Parol Pulse** | Two 1×1 fixtures | Beam: up to 6×1 between fixtures | Timed light barrier with safe and active windows. |
| **Bula-Bulaklak** | Emitter: 1×1 | Upward bubble path: 1×5 | Captures and lifts one chicken temporarily. |
| **Tsinelas Launcher** | 1×1 | Projectile lane: up to 6×1 | Telegraphs, then fires a slipper projectile. |
| **Walis Cleanup** | No solid footprint | Cleanup preview: 3×3 | Removes eligible player-built items during Place. |
| **Hagdan ng Bahay** | 3×3 | Solid stepped footprint | Builds a three-step route. |
| **Sulok na Kawayan** | 3×3 L-shape | Solid L footprint | Builds a corner ledge and cover. |
| **Marupok na Papag** | 3×1 | Solid top: 3×1 | Temporary platform that collapses after use. |
| **Baliktad na Banig** | 3×1 | Active face: 3×1 | Alternates between safe and unsafe faces. |
| **Balsa sa Lubid** | Raft: 3×1 | Horizontal path: 7×1 | Rideable raft travels across a gap. |
| **Angat-Kaing** | Lift: 2×1 | Vertical path: 2×6 | Basket platform moves upward and downward. |
| **Perya Wheel** | 5×5 envelope | Same 5×5 orbit envelope | Rideable platforms rotate around a hub. |
| **Palay Conveyor** | 4×1 | Surface effect: 4×1 | Conveyor pushes grounded chickens sideways. |
| **Bentilador** | Fan: 1×2 | Air corridor: 5×3 | Fan pushes chickens through a visible corridor. |
| **Bomba ng Tubig** | 1×1 | Jet corridor: 1×5 | Timed water burst launches or pushes chickens. |
| **Saranggola Ferry** | Kite: 2×1 | Travel lane: 7×1 | Temporary rideable kite crosses a bounded lane. |
| **Yelo ng Sorbetero** | 4×1 | Surface effect: 4×1 | Slippery surface reduces braking. |
| **Malagkit Patch** | 3×1 | Surface effect: 3×1 | Sticky surface slows movement and jumping. |
| **Tinik-Tinik Strip** | 4×1 | Hazard strip: 4×1 | Narrow contact hazard that players jump over. |
| **Gulat na Walis** | Anchor: 1×1 | Trigger: 2×2; strike: 3×1 | Triggered broom strike after a warning. |
| **Umiikot na Trumpo** | Pivot: 1×1 | Orbit envelope: 5×5 | Spinning top circles a central tether point. |
| **Niyog Pendulum** | Pivot: 1×1 | Swing envelope: 5×5 | Coconut swings across a predictable arc. |
| **Sipa ng Tsinelas** | Anchor: 1×1 | Jab lane: 3×1 | Triggered short-range slipper jab. |
| **Gulat na Palayok** | 1×1 | Aim/swat area: 4×3 | Pot tracks, telegraphs, and swats a nearby chicken. |
| **Tansan Ricochet** | 1×1 | Initial lane: 6×1; maximum bound: 6×4 | Bounded bouncing bottle-cap projectile. |
| **Niyog Chute** | Chute: 2×1 | Downhill lane: up to 6×1 | Warns, then rolls coconuts along a lane. |
| **Singaw Steamer** | 1×1 | Steam plume: 3×2 | Timed cartoon steam burst blocks a route. |
| **Gulong Kuliglig** | Emitter: 1×1 | Chase boundary: 5×5 | Briefly pursues a marked chicken. |
| **Ipo-Ipo** | Core: 1×1 | Pull radius envelope: 5×5 | Pulls chickens toward a small danger core. |
| **Kambal na Pinto** | Each door: 1×2 | Exit clearance: 1×2 per door | Linked doors relocate a chicken to the other end. |
| **Balsa-Bentilador** | Platform: 3×1 | Path/air envelope: 6×4 | Moving platform with a hazardous fan underside. |
| **Umiikot na Dram** | 3×3 | Same 3×3 rotation envelope | Rotating drum changes footing and takeoff timing. |
| **Peryang Traysikel** | Body: 2×1 | Crossing lane: 8×1 | Toy tricycle crosses a marked lane. |

**Barya** has a 1×1 pickup footprint. It is optional, race-only, and does not count among the 36 obstacle families.

### Approved size variants

Implementation note (2026-10-14): the runtime variant table is now the block scene folder (`tilaok!/scenes/blocks/`, see "Block scenes"); this design table still lists the intended sizes, and new sizes need a scene. Only some families vary in size. These variants create more placement choices while keeping the selected size readable before a player picks or places it.

| Family | Visible variant sizes | Notes |
|---|---|---|
| Hollow Blocks / Kaing Stack | 1×1, 1×3 column, 2×3 stack | The egg preview and ghost show the exact shape. |
| Tulay na Kawayan | 3×1, 4×1, 5×1 | Rotates to 1×3, 1×4, or 1×5 where vertical one-way behavior is supported. |
| Solid Block (`build.solid_block`) | 3×1 slab | Rotates to 1×3 with R. Added 2026-10-14. |
| Wood Box (`build.wood_box`) | 2×2 | Symmetric; no rotation. Added 2026-10-14. |
| Collapsing Block (`build.collapsing_block`) | 1×1 | Symmetric; no rotation. Added 2026-10-14. |
| Trumpo sa Riles | 4×1, 5×1, 6×1 rail | The moving top’s sweep always matches the shown rail length. |
| Parol Pulse | 3–6 cell fixture span | Both fixtures and the entire beam span appear in the preview. |
| Bula-Bulaklak | 1×3 or 1×5 path | The bubble path height is visible before selection. |
| Tsinelas Launcher | 4×1 or 6×1 lane | The full firing lane appears in Place. |
| Walis Cleanup | 3×3 or 5×5 area | The preview lists every removable target before confirmation. |
| Hagdan ng Bahay | 2×2 or 3×3 steps | The larger form gives higher, more disruptive elevation. |
| Sulok na Kawayan | 2×2 or 3×3 L-shape | Both arms grow together. |
| Marupok na Papag | 2×1 or 3×1 | Larger platforms remain readable as temporary terrain. |
| Balsa sa Lubid | 2×1 or 3×1 raft; 5×1 or 7×1 path | Both raft body and travel length are shown. |
| Angat-Kaing | 2×1 lift; 2×4 or 2×6 path | Vertical travel bound is visible. |
| Palay Conveyor / Yelo ng Sorbetero | 3×1 or 4×1 | Surface direction/effect remains unchanged. |
| Bentilador | 3×3 or 5×3 air corridor | The force envelope is shown, not only the fan body. |
| Bomba ng Tubig | 1×3 or 1×5 jet | The full jet height is shown. |
| Tinik-Tinik Strip | 3×1 or 4×1 | Thin profile remains a clear jump hazard. |
| Niyog Pendulum / Umiikot na Trumpo | 3×3 or 5×5 sweep envelope | Pivot stays 1×1; the visible arc/orbit changes. |
| Singaw Steamer | 2×2 or 3×2 plume | The warning and plume bound scale together. |
| Peryang Traysikel | 6×1 or 8×1 lane | The tricycle body remains 2×1; only crossing lane length changes. |

## First batch: full design contracts

| ID / family | Original Tilaok behavior, benefit, danger, tell, counterplay | Placement, regions, rotation, and tunables | Race / Lagsanay, ownership, lifecycle, needs, risk |
|---|---|---|---|
| `build.hollow_blocks` — **Hollow Blocks / Kaing Stack** (A, build/platform) | Solid construction pieces create footholds, walls, routes, and projectile cover. Danger is route obstruction or hiding a tell. Tell: strong distinct crate silhouette and placement ghost. Counter: jump around/over, use another route, or Walis Cleanup. UCH basic-block inspiration; original barrio treatment. | One-cell and 2×3-cell variants in a single family; 90° rotation where footprint changes. Solid full footprint, no trigger. No overlap with protected geometry or other solids; projectile occlusion uses actual solid volume. Footprint and item cap are tunables. | Usable in race and event rounds including Lagsanay. Owner is placer; removable by Walis Cleanup; persists until removed, no moving state. Needs original crate/block sprites and sound. Low relative risk; depends on placement grid/collision and cleanup. Cultural check: “kaing” use/context. |
| `build.bamboo_bridge` — **Tulay na Kawayan** (A, build/platform) | One-way thin bridge creates a route; its underside can be passed through, so it may be missed or become an ambush landing. Tell: narrow bamboo silhouette and one-way arrow on ghost. Counter: approach from below to pass through, or use another path. Inspired by the general utility-platform role; one-way behavior is Tilaok’s adaptation. | One-way solid top, non-solid underside/sides; horizontal/vertical rotation in 90° steps if the movement model supports both. Footprint distinct from top collision strip. Length, thickness, allowed rotations are tunables. | Race and event terrain; enabled in Lagsanay only after safe-floor compatibility review. Placer owns it; cleanup removes it, otherwise persists. Static reset. Needs original bridge art. Medium risk because one-way collision must match run/jump-only controls. Verify material/name culturally; no “traditional rule” claim. |
| `move.tire_spring` — **Gulong Talon** (A, movement tool) | Contact bounce launches a chicken; if the chicken stays on the launch face, Gulong bounces again after its 0.20 s cooldown. A timed jump press boosts the launch and is consumed by that bounce; ordinary surfaces do not auto-jump. It creates a useful shortcut but can throw players into hazards. Tell: visible compression/coil and bounce arc cue. Counter: approach slowly, decline the boost, or time the jump. Spring is verified community-wiki reference pattern; tire/playful presentation and tuning are original. | 2×2 logical footprint proposal; top is launch trigger, body is solid support. Rotation 0/90/180/270; direction follows the transformed launch normal. Force, jump bonus, footprint, cooldown, and grace are tunables. | Race and Lagsanay; Lagsanay force must not bypass solid-floor containment. Placer owns trap attribution only if the spring impact itself eliminates; otherwise no assist credit. Resets force/cooldown at Play. Needs original tire animation/audio and movement-state interface. Medium-high risk: player launch state and ceiling/bounds safety. |
| `hazard.rail_trumpo` — **Trumpo sa Riles** (A, moving hazard) | A playful spinning top travels along a short visible rail, pauses at ends, and eliminates on contact. Safe gaps/endpoint pauses allow timing. Tell: rail, rotation, endpoint pause and audio cue. Counter: cross during pause/gap or route above/below. Verified inspiration: Linear Saw’s back-and-forth path; original trumpo, safe timing, and tuning. | Place a bounded rail segment; footprint is anchor/rail; sweep is separate and shown in preview. Rotate in 90° increments, with deterministic start direction. Speed, pause, rail length, hitbox width, grace are tunables. No off-camera or unbounded path. | Enabled in the development-only `lagsanay_lab` after actual-physics Lagsanay contact and owner attribution checks. Owner gets Patibong only for direct contact elimination. Resets to start endpoint and deterministic direction each Play; cleanup releases mover. Placeholder tell only; fair-play, readability and original animation/audio review remain open. Medium-high risk: collision ordering and sweeps. |
| `hazard.parol_pulse` — **Parol Pulse** (A, timed area hazard) | Two visible fixtures project a timed light barrier; crossing active span eliminates. A 3-second cycle has 1.5s active and 1.5s inactive; charge-up occupies the final part of inactive time, so it does not extend the cycle. Tell: fixture icons, brightness ramp, non-flashing shape change and audio cue. Counter: cross during safe interval or use cover if cover truly blocks it. Original Tilaok proposal; not UCH reference. | Two endpoint anchors define span and collision width; endpoints/beam shown in preview. Horizontal/vertical orientation only. Default proposal: solids block the beam; define and show occlusion. Cycle, charge time (inside inactive 1.5s), width, range and grace are tunables. | Race and event; Lagsanay only after readability and balance pass. Placer owns direct elimination. Resets phase to inactive/charge at Play start. Needs distinct beam art/audio, overlap readability test. Medium risk; verify at minimum zoom and with multiple emitters. No rapid strobe. |
| `hazard.bubble_planter` — **Bula-Bulaklak** (A, capture/displacement) | Emits one bubble at a time along a fixed upward path/cadence. Captures one live chicken for about 2s; no control while held; never eliminates itself. It can displace a player into another trap or past a route. Tell: visible bubble path, cadence and captive icon. Counter: time the gap or let another direct hazard be avoided after release. Original Tilaok proposal; no plant identification or educational claim. | Emitter footprint separate from bubble trigger/path; vertical fixed path, no rotation in v1. One captive per bubble and one bubble per player. Cadence, path, capture time (~2s), release velocity, grace, bubble cap are tunables. Stop/resolve against ceiling and bounds; release at nearest safe non-overlapping position with bounded velocity. If no safe location exists, release at last safe point with zero velocity. | Race: captive must be released before goal completion; captured player can be hit by external traps. Lagsanay: timer continues and captive remains taggable; disable in Lagsanay if capture-to-elimination is unavoidable. Exclude dead/finished/already-captured players; simultaneous captures resolved by stable player ID and bubble ID; short immunity prevents immediate re-capture. Bubble gives no Patibong; actual eliminating trap does. Remove bubble/captive state on death/end/restart/emitter removal. Needs custom player-state lifecycle and cage-free release tests; highest risk, last in A. |
| `hazard.slipper_launcher` — **Tsinelas Launcher** (A, projectile trap) | Telegraphs then fires a slipper along a straight lane; hit eliminates. Solids block the projectile. Tell: barrel/aim lane, charge animation and sound. Counter: cover, dodge, or cross outside firing lane. Projectile-launcher pattern is broad reference; slipper, timing, and cover interactions are original. | One-cell launcher footprint plus distinct visible lane/hitbox, 0/180° rotation. No projectile spawn inside solid/player/protected area. Fire delay, speed, lifetime, cap, cooldown, hitbox, target policy are tunables. | Enabled in the development-only `lagsanay_lab` after actual-physics projectile contact and owner/source attribution checks. Launcher placer owns direct hit. Projectile has bounded lifetime and is removed at round end/removal. Placeholder tell only; fairness/readability and original slipper art/audio review remain open. Medium-high risk: projectile collision ordering and cleanup. No weapon realism. |
| `utility.walis_cleanup` — **Walis Cleanup** (A, construction utility) | During Place only, removes player-built pieces inside a previewed bounded area. Restores a route obstructed by accumulated stage clutter. No Play-phase behavior, no direct damage, no trap credit. Tell: broom preview outlines every exact target and protected exclusion. Counterplay is to place thoughtfully; cleanup is limited by one item use and fixed radius. Broad inspiration from UCH Bomb’s removal role; one-shot construction edit is original. | Bounded radius/region with preview; no rotation needed. Never targets base geometry, spawn/goal clearance, hidden event goal, or same-phase newly submitted pieces. Resolve as one removal set, then validate other placements against resulting snapshot; no callback-order dependence. Radius and eligible item categories are tunables. | Construction-only in race and event rounds; no Lagsanay Play effect. Owner is cleaner for edit audit only, never Patibong. Removed objects do not return on reset. Needs clear ghost/target list and protected-zone outlines. Medium risk: atomic simultaneous edit semantics and support cleanup. |

### First-batch interaction acceptance scenarios

These are design acceptance scenarios, not completed tests:

1. **Bridge + trumpo:** bridge supplies a useful route; rail sweep remains separate from the bridge footprint, and players can read and time the crossing.
2. **Spring + Parol Pulse:** launch arc can reach the barrier; inactive/charge/active phases remain legible and counterable at minimum zoom.
3. **Block + launcher:** block cover actually occludes projectile; it also creates a traversable route, and launcher lane stays visible.
4. **Bubble + trumpo:** bubble displacement can expose a player to a separately owned hazard; only direct trumpo elimination earns its owner Patibong.
5. **Cleanup + obstructed route:** preview lists only removable items, protected geometry survives, cleanup is committed once, and the cleared route remains cleared next round.

## Expansion backlog: 28 additional mechanical designs

**Promoted 2026-10-16 (user request):** `build.house_stairs` (Hagdan ng Bahay, `steps_2x2` / `steps_3x3`), `hazard.toy_burr_strip` (Tinik-Tinik Strip, `strip_3x1` / `strip_4x1`) and `modifier.sorbetes_ice` (Yelo ng Sorbetero, `surface_3x1` / `surface_4x1`) are block scenes in the main egg pool (weight 20 each, DEBUG art). Mode flags: stairs and ice allow Karera and Lagsanay, with Kangaroo pending; Tinik allows Karera, with Lagsanay and Kangaroo pending the wholesome-art review. Ice uses the BlockData `slippery` flag with `ice_brake_scale` 0.12, `ice_accel_scale` 0.6 and `ice_speed_scale` 1.25. Evidence: [P19 promoted](evidence/p19_promoted/README.md). Their rows below are unchanged; the other 25 designs remain deferred.

All rows are **original Tilaok proposals**. Reference names indicate mechanic-family inspiration only, not copied behavior or tuning. Shared lifecycle, ownership, access, and accessibility rules above apply; item-specific exceptions and principal tuning needs are stated in each row. All require original assets, provisional-name review, and a race/Lagsanay compatibility pass before enablement.

| ID / working name | Tier; family; reference vs adaptation | Benefit, danger, tell, counterplay; footprint/rotation/regions and tunables | Race/Lagsanay, ownership/reset, dependency/risk |
|---|---|---|---|
| `build.house_stairs` Hagdan ng Bahay | B; build; UCH Stairs family reference, Filipino staircase design original. | Multi-step footholds; can create a steep obstacle. Tell: stair silhouette. Counter: alternate jump route. Solid stepped footprint; 90° rotations. Tune tread count/height and footprint. | Terrain in both modes; placer owns removable static piece; medium risk: collision seams. |
| `build.bamboo_corner` Sulok na Kawayan | B; build/cover; UCH L Girder pattern reference. | L-shaped ledge/cover gives foothold and projectile defense; may occlude tells. Outline both arms; route around. Solid L footprint; four rotations. Tune arm length/clearance. | Terrain; placer owns, cleanup removes; low-medium risk: multi-cell overlap validation. |
| `build.fragile_papag` Marupok na Papag | B; temporary platform; crumbling-block pattern reference. | Temporary bridge collapses after landings; visible cracks warn. Counter: cross quickly or use another route. Solid footprint, no rotation or 180°; tune landing count/recovery. | Race/event; collapse state resets next Play; no kill credit from falling unless direct hazard owns it. Medium risk: simultaneous landing. |
| `hazard.flipping_banig` Baliktad na Banig | B; alternating platform; flipping-block pattern reference. | Periodically usable/unsafe face changes after warning; tell by shape/icon. Counter: leave during warning. Defined solid top and trigger face; 180° rotation. Tune phase/duration/grace. | Both modes after Lagsanay test; resets phase; placer owns only direct elimination. Medium-high moving-collision risk. |
| `move.rope_raft` Balsa sa Lubid | B; horizontal mover; moving-platform family reference. | Shuttle crosses a gap, enabling timed boarding; endpoints pose falls. Tell: rope/endpoint pause. Counter: board at pause or jump off. Platform footprint separate bounded horizontal sweep; horizontal only. Tune speed/pause/range/cap. | Both modes; resets to endpoint/direction; no assist credit. High risk: rider carry/support lifecycle. |
| `move.basket_lift` Angat-Kaing | B; vertical mover; moving-platform family reference. | Lift reaches high routes; endpoint timing risks falls. Tell: visible guide and endpoint pause. Counter: wait for basket. Solid top, bounded vertical sweep; rotate not allowed. Tune height/speed/pause. | Both modes subject to Lagsanay containment; reset deterministic; high risk: platform carrying/player state. |
| `move.perya_wheel` Perya Wheel | C; orbit mover; Ferris Wheel reference. | Several rideable footholds circle an axle; transfers are risky. Tell: visible full orbit. Counter: board near low arc, dismount. Footprint is pivot/arms, sweep separate; fixed rotation direction. Tune radius/speed/platform count. | Both modes only after event testing; reset angle; high risk: multi-platform collision. |
| `move.palay_conveyor` Palay Conveyor | B; conveyor modifier; Treadmill reference. | Carries grounded players sideways; running against it changes traversal. Tell: belt texture and motion marks. Counter: reverse run or leave surface. Surface footprint only; 0/180° orientation. Tune velocity and acceleration. | Both modes; modifier owner not trap credit unless direct lethal interaction exists. Medium dependency on grounded-state handling. |
| `move.bentilador` Bentilador | B; force field; Fan reference. | Visible airflow pushes chickens, changing jumps near hazards. Counter: cover if blocking is enabled or move out of corridor. Footprint anchor plus force rectangle; four rotations. Tune force/falloff/blocking. | Both modes after Lagsanay and item tests; resets field state; no assist credit. Medium-high force/bounds risk. |
| `move.water_jet` Bomba ng Tubig | B; pulsed movement; Hydrant family reference. | Timed upward water burst boosts route; can push into trap. Tell: pressure gauge and rising sound. Counter: cross between bursts. Jet corridor distinct from solid footprint; rotate 90°; tune cadence/force/duration. | Both modes after safe-floor test; resets idle. Medium-high player launch dependency. |
| `move.kite_ferry` Saranggola Ferry | C; periodic mover; Paper Airplane Shooter family reference. | Small rideable kite platform traverses a bounded path then despawns; supports crossing. Tell: launch spool/path. Counter: dismount before endpoint. Platform and path separate; 0/180° lane. Tune dwell/path/lifetime/cap. | Race/event after Lagsanay safety review; resets docked. High risk: transient platform support. |
| `modifier.sorbetes_ice` Yelo ng Sorbetero | B; surface modifier; Ice reference. | Reduces braking for longer slides; can carry player into danger. Tell: frosty edge pattern. Counter: jump off or plan stopping distance. Surface-only footprint; 90° orientation irrelevant. Tune friction and max speed. | Both modes; no trap credit; reset is static. Medium movement tuning. |
| `modifier.malagkit_patch` Malagkit Patch | B; surface modifier; Honey slowing role only. | Slows player/reduces jump while touching; no object attachment in v1. Tell: textured sticky patch. Counter: jump over or avoid. Surface trigger, 0/90°; tune speed/jump multipliers. | Both modes; no assist credit; static reset. Medium movement-state restoration risk. |
| `hazard.toy_burr_strip` Tinik-Tinik Strip | B; contact hazard; Barbed Wire spatial role reference. | Narrow marked strip eliminates on contact, allowing face-level defense. Tell: soft oversized burr silhouette. Counter: jump over/route around. Thin trigger strip, four rotations; tune thickness/active faces. | Both modes after wholesome-art review; placer receives direct kill credit; static reset. Medium readability risk. |
| `hazard.surprise_broom` Gulat na Walis | B; trigger hazard; Trigger Spikes pattern reference. | Footstep trigger warns then raises soft bristles; bait it and cross recovery. Marked trigger area vs narrow hitbox; rotate 90°. Tune trigger radius/warning/recovery. | Race/event after Lagsanay floor check; owner only on direct hit; resets armed. Medium-high trigger race risk. |
| `hazard.orbit_trumpo` Umiikot na Trumpo | B; orbiting hazard; Spinning Saw pattern reference distinct from rail trumpo. | Tethered top sweeps circular zone; time gap around orbit. Tell: visible tether and arc. Pivot footprint vs swept danger region; fixed orbit, 90° start phase. Tune radius/period/width. | Both modes after event test; owner direct hit; resets angle. High sweep collision risk. |
| `hazard.coconut_pendulum` Niyog Pendulum | B; swing hazard; Wrecking Ball pattern reference. | Padded coconut swings a predictable arc across a route. Tell: full arc and endpoint pause. Counter: pass behind pivot or time swing. Anchor footprint and arc separate; four start orientations. Tune arc/period/width. | Both modes after Lagsanay safety test; reset endpoint; medium-high mover collision risk. |
| `hazard.slipper_jab` Sipa ng Tsinelas | B; triggered strike; Boxing Glove pattern reference. | Pressure/contact trigger launches a short slipper jab. Tell: button compresses and arm winds up. Counter: bait then pass during cooldown. Anchor, trigger zone and fixed jab lane separate; four orientations. Tune range/warning/cooldown. | Race/event; direct strike owner; reset idle. Medium-high projectile/hitbox lifecycle. |
| `hazard.aiming_pot` Gulat na Palayok | B; targeting hazard; Punching Flower pattern reference. | Detects a chicken, visibly aims, then releases padded swat. Counter: bait aim then move. Footprint plus limited target range/swat lane; 90° rotate. Tune reacquire, telegraph, range. | Both modes after fairness test; direct hit attribution; resets neutral. High risk: target selection determinism. |
| `hazard.tansan_ricochet` Tansan Ricochet | B; bounded projectile; bouncing projectile family reference. | Toy cap ricochets a bounded number then expires. Tell: direction preview and bounce count icon. Counter: solid cover/leave lane. Launcher footprint, lane/sweep separate; four orientations. Tune bounce/lifetime/cap/speed. | Both modes only after projectile cap test; launcher owns direct kill; cleanup at end. High risk: deterministic collision and transient count. |
| `hazard.coconut_chute` Niyog Chute | B; gravity projectile; original barrio adaptation. | Rumble warns before coconuts roll downhill/off ledges. Counter: step out of lane or use cover. Chute anchor and terrain-following lane; rotate 180°. Tune warning, launch interval, speed, cap. | Both modes only when direct hit attribution is stable; resets empty. High risk: terrain traversal and transient cleanup. |
| `hazard.steam_burst` Singaw Steamer | B; timed area hazard; timed-area role references Flamethrower, visuals/behavior original. | Cartoon steam plume blocks passage briefly; no burn imagery. Tell: valve hiss and pressure rise. Counter: cross during cooldown. Emitter footprint and plume rectangle separate; four rotations. Tune warning, reach, duty cycle. | Race/event after Lagsanay test; owner on direct contact elimination; resets depressurized. Medium readability/timing risk. |
| `hazard.kuliglig_swarm` Gulong Kuliglig | C; bounded chase; Beehive chase pattern reference. | Fictional noisy insect swarm pursues a visibly marked target briefly. Counter: survive until expiry/route away. Emitter and chase boundary separate; no rotation. Tune target rule, duration, speed, cap. | Lagsanay disabled initially; race only until fair target policy proves out. Direct source owns elimination. High AI/target-state risk; fictional insect art, no real-species claims. |
| `hazard.ipo_ipo` Ipo-Ipo | C; force/core hazard; Black Hole attraction pattern reference. | Bounded visible pull toward small elimination core; strength cap keeps escape possible. Counter: leave radius/use cover if blocking is defined. Core footprint/effect radius separate; no rotation. Tune force/radius/core. | Both modes only after projectile interaction is excluded or specified; direct core owns kill; resets field. Very high force, bounds, and readability risk. |
| `move.kambal_na_pinto` Kambal na Pinto | C; paired traversal; Teleporter reference. | Linked fantasy doors relocate a chicken to a clear partner exit. Tell: matched symbol and exit preview. Counter: avoid endpoint or use cooldown window. Pair footprint and exit clearance; rotate each exit in 90° increments. Tune cooldown/exit offset. | Race only initially; disable in Lagsanay pending fairness. Pair ownership and removal delete both ends; high risk: pairing, anti-loop, blocked exit. |
| `move.balsa_fan` Balsa-Bentilador | C; mover + force; Fan Platform family reference. | Rideable top with marked hazardous underside. Tell: underside icon and path. Counter: board only from safe side/dismount. Platform solid top, underside trigger, bounded path; fixed orientation. Tune path/force/danger area. | Disable Lagsanay initially; direct underside hit owner only. Resets endpoint; very high combined mover/force risk. |
| `move.rotating_drum` Umiikot na Dram | C; rotating surface; Gear/Tire rotation family reference. | Rotating drum changes standing and takeoff timing without attached contraptions. Tell: rotation arrows. Counter: ride with rotation or jump away. Cylindrical support/sweep separate; axis fixed, start angle configurable. Tune speed/radius. | Race/event after Lagsanay test; reset angle; high collision geometry risk. |
| `hazard.toy_tricycle` Peryang Traysikel | C; lane-crossing mover; original barrio hazard. | Toy tricycle signals, crosses a fixed lane, waits offstage, repeats. Large body differs from small projectile. Tell: bell/headlight and lane warning. Counter: leave lane or use cover if defined. Spawn anchor and complete lane separate; 0/180° direction. Tune speed/warning/dwell/cap. | Both modes only with full lane visible and safe spawn; direct body collision owner; resets offstage. High risk: bounds and large hitbox. |

### Separate optional item: Barya

Barya is a round-scoped Karera scoring objective, not a 37th obstacle or construction piece. In the scheduled P12 match, a separate seeded 1-in-3 roll replaces one Pugad egg only when the locked Main is Karera (including its two Karera stacks); the Pugad pool size is unchanged. The picker claims and places the single 1×1 coin through the Place flow. It has no solid body, support behavior, Rising interaction, Walis target, ItemManager entry or construction-cap cost. Invalid/expired placement discards it. Physics-step pickup arbitration selects nearest controller root, then lower seat index. Capture preserves carry; committed elimination drops it at the controller root and deterministically recovers to the nearest valid cell (row-major `(y, x)` ties) or discards it if no valid cell exists. A same-step dropped coin waits until the next physics step to be picked up. A committed finisher receives +0.5 exactly once, including all-finish rounds; no finisher receives none. Score/history snapshots are recorded before round cleanup removes the objective. Aborted retries preserve the pre-Play placement and increment the attempt identity. P07 remains disabled, and `--barya-disabled` rolls back the P12 offer without consuming its random stream. See [Barya engineering evidence](evidence/barya/README.md).

The coin and Pugad silhouette currently use code-drawn DEBUG geometry. This is a development placeholder only; human-made final art and any accessibility, cultural and player review remain open. Barya remains optional Should content and does not change the base release manifest.

## Event stack and backlog notes

- **Event stacking is core:** every round has one Main Challenge and can gain one compatible Twist. Karera is the weighted default and always opens the match; standalone Lagsanay and Kangaroo are also Main Challenges. The first compatibility rows are Karera + Lagsanay, Karera + Kangaroo, and Kangaroo + Lagsanay; their exact scoring, terminal-state, collision, and presentation rules are in GDD §4. Each eligible non-guaranteed round makes one chance roll: 0% in rounds 1–4, 10% in 5–7, 20% in 8–10, and 30% in 11–12. It never uses more than two concurrent events and never adds a Twist in Sudden Death. New pairs remain disabled until they have an explicit compatibility contract and playtest evidence.
- **Langit-Lupa** remains the GDD's named second laro ng lahi; no replacement is implied.
- **Kangaroo** is a Main Challenge for the core Kangaroo + Lagsanay stack. A giant background slipper presents each command through a landing, readable text/icon, audio, and configurable screen shake. Its equally likely poses map to Freeze (normal, sole down), Rising wave (facing down, sole up), and Hug (sideways): 33.33% each, except that Hug rerolls without effect when exactly two chickens remain. Rising wave selects a middle-low, middle, or middle-high stage band at equal probability, shows a red/orange target line, then rises to it; only a chicken grounded above that line on player-built solid geometry passes. Base-stage platforms do not count, and the wave does not reroll if players failed to build useful raised geometry. Hug pairs chickens only: shortest contacts pair first with player-slot tie-breaks, each chicken has at most one partner, and every unpaired chicken fails; contact is checked only at evaluation. Freeze measures intentional input only, with deadzone/release grace; forced motion does not fail it. Three visible failures (KANG, GA, ROO) eliminate. Commands remain active with traps and Lagsanay. Start at a one-second telegraph, three-second response, and 0.75-second reset. Every two no-elimination commands accelerate the cadence; after eight, Slipper Storm lands every 0.5 seconds with one-second commands and at most two requirements active. With two survivors, each overlapping Storm pair is Freeze plus Rising wave until an elimination.
- **10–20 Garter / Luksong Tinik:** choose one implementation family after comparing; define telegraph, line thickness/sweep, platform interaction, avoidance route, and anti-camping rule.
- **Sipa:** prototype only after selecting a responsibility rule that does not punish the player who keeps the ball aloft. Specify contact credit, equal distance, out-of-bounds/unreachable recovery, and body-collision behavior.
- **Jackstone:** compare with Agawan Buko; define supply/quota by player count, reachable spawns on cluttered stages, simultaneous collection, drops after elimination, and impossible-quota recovery. Do not replace Agawan Buko automatically.
- Keep Tumba Lata, Sikyo, Sepak Takraw, and Dr. Quack Quack parked. Do not claim Sikyo equals Syato without confirmation.

## Approval and implementation gates

All 36 families are approved as the Tilaok design catalog. This approval does not claim that all 36 will ship before the deadline: the eight-family first batch remains the implementation target, with the other 28 held behind scope and test gates. Before implementing mechanics, the team must choose the actual project grid/player dimensions and target PC, resolve GDD scoring/tie implementation gates, and decide final Pugad weights/caps. Event stacking is core; additional unlisted event pairs remain feature-switched off until accepted and tested. Follow the standing AI-assisted programming policy in `AI_USAGE.md`; implementation still requires approved task scope and actual verification.

## Block scenes — how every placeable item is authored (2026-10-14)

Requested by the user: every placeable item is now its own editable scene in `tilaok!/scenes/blocks/` (one scene per size variant), with a **BlockData** customization node in the style of aLima's `ArtifactScannerData`. `BlockCatalog` scans that folder (recursively) whenever item definitions load, so **dropping a new block scene into the folder makes it appear in the Pugad eggs, the Item Lab and the Library with no code, `.tres` or table edit**. The old `data/items/*.tres` families and the `ItemApprovedVariants` table were converted into these scenes (region-for-region identical; checked by a parity script during migration) and removed: the scene folder is now the documented variant table.

Folders: `construction/` (Kaing 1x1 / 1x3 / 2x3, Tulay 3x1 / 4x1 / 5x1, Solid Block, Wood Box, Collapsing Block), `traps/` (Spikes, Cannon), `explosives/` (Bomb 2x2, Dynamite 3x3, Nuke 4x4: Special = Cleanup, one-use area clears; 2026-10-15), `hazards/` (Gulong, Trumpo rails, Parol spans, Tsinelas lanes, Walis areas, Bula paths).

**Scene layout** (authored at rotation 0, centred on the block root, which uses `scripts/items/blocks/stage_block.gd`):

| Node | Purpose |
|---|---|
| `BlockData` | Block name, family/variant IDs, Library text, modes; **Placement Box Size** (columns × rows); allowed rotations; **Anchor/Gravity** (Anchored = stays in its tile, Heavy = falls but players can't push it, Light = falls and is pushed); **Effects** (Kill, Stun + stun seconds/knockback); **Special** (Spawn Projectiles, Follow Rail, Timed Hitbox, Launch, Collapse, Cleanup) and per-block overrides (-1 = global tuning); selection pool flags and weight. In the editor it draws the placement box and grid. |
| `CollisionShape2D` children of the root | The **solid hitbox**. Independent of the placement box (a 2x2 block may have a 1x1 solid). `one_way_collision` makes a one-way platform. |
| `BlockHitbox` (Area2D) children | Pick its **Effect** in the inspector: **Kill / Stun / Launch** touch hitboxes and Sweep / Beam / Capture path / Cleanup area regions, each with RectangleShape2D children you resize freely. Kill and Stun act only when the block's Kill/Stun effect is on; kills are credited to the placer (Patibong), stuns are uncredited setup effects. |
| `Visual` | Everything players see; replace with final art. Eggs and the Library show it too when no legacy painter silhouette is set. |
| Projectile template (Spawn Projectiles) | A Node2D with a `Path2D` child the projectile follows and a `BlockHitbox` (Kill or Stun; Capture path for bubbles); its own `Visual` is shown for each live projectile. Straight paths fire like the Tsinelas lane and are stopped by solids. |

To add a block: duplicate a scene in `scenes/blocks/` (e.g. `traps/spikes.tscn`), rename it, change BlockData and the shapes, save. Hitbox shapes are rectangles; keep touch hitboxes inside the placement box.

Since 2026-10-16:
- A projectile path drawn longer than the stage (for example a Cannon aimed "to the far side") is clamped to the stage width or height from its start, so it shoots across the whole stage.
- A block scene that still fails validation is left out of the game, and the Output panel says which block and why ("BlockCatalog: … left out: …"). Before this, one broken block made every block invalid and a started match showed only the map.

## Stage blocks — October 14, 2026

Requested by the user on 2026-10-14 and implemented as three construction families, each with its own editable scene (collision + DEBUG visual) under `tilaok!/scenes/blocks/`. Since the block-scene migration (see "Block scenes" above) each scene's BlockData placement box is authoritative and the scene is the only definition. All declare solid-side wall eligibility, `modes_allowed` karera/lagsanay, Walis removal and persistence until removed; weights are 50 like Kaing/Tulay (tunable).

| Family / variant | Behavior | Safe start |
|---|---|---|
| `build.solid_block.slab_3x1` | Static solid, no gravity; rotates to 1×3. | `static_no_motion` |
| `build.wood_box.box_2x2` | Gravity; pushed by a grounded chicken walking into its side (160 wu/s, friction stop); rests on stage, blocks and chicken heads; inert in Place. | `reset_to_placed` (new documented state: returns to its placed spot at Place/Play start) |
| `build.collapsing_block.cell_1x1` | Static until a chicken stands or wall-slides on it; collapses after 2 s, returns after 3 s once its footprint is clear; inert in Place. | `static_no_motion` (restored at Place/Play start) |

Tell / counterplay: Solid — gray brick slab, jump over or route around. Box — crossed planks, push it or stand on it. Collapsing — cracked tile that shakes before dropping; keep moving or wait for it to return. Each has a second non-colour identifier (brick lines, plank cross, crack lines plus a text label).

## Implementation status — October 13, 2026

| Family / variant | Implemented | Prototype-enabled | Verified (harness, synthetic input) | Release-enabled |
|---|---|---|---|---|
| `build.hollow_blocks` 1×1 | yes | yes | yes | no |
| `build.hollow_blocks` 2×3 (and rotated 3×2) | yes | yes | yes | no |
| `build.hollow_blocks` 1×3 column (and rotated 3×1) | yes | no | geometry/standing only | no |
| `build.bamboo_bridge` 4×1 horizontal | yes | yes | yes | no |
| `build.bamboo_bridge` 3×1, 5×1 | yes | no | geometry/standing only | no |
| `build.bamboo_bridge` vertical orientations | geometry only | no (gated) | no | no |
| `move.tire_spring` `tire_2x2` (rotations 0/90/180/270) | yes | yes (`items_lab`, `karera_spring`) | yes | no |
| `hazard.rail_trumpo` `rail_4x1`, `rail_5x1`, `rail_6x1` (rotations 0–3) | yes | yes (`items_lab`) | yes | no |
| `hazard.parol_pulse` `span_3x1`–`span_6x1` (horizontal and vertical; span = total cells incl. both posts) | yes | yes (`items_lab`) | yes | no |
| `hazard.slipper_launcher` `lane_4x1`, `lane_6x1` (0° and 180°) | yes | yes (`items_lab`) | yes | no |
| `utility.walis_cleanup` `area_3x3`, `area_5x5` (one-shot Place edit) | yes | yes (`items_lab`) | yes | no |
| `hazard.bubble_planter` `path_1x3`, `path_1x5` (fixed upward path) | yes | yes (`items_lab`) | yes | no |
| `build.solid_block` 3×1 (and rotated 1×3) — 2026-10-14 | yes | yes (default pool and `items_lab`) | yes | no |
| `build.wood_box` 2×2 — 2026-10-14 | yes | yes (default pool and `items_lab`) | yes | no |
| `build.collapsing_block` 1×1 — 2026-10-14 | yes | yes (default pool and `items_lab`) | yes | no |
| Lagsanay/Kangaroo/stack interaction of any first-batch family | yes (2026-10-16) | yes (mode-filtered P12 eggs) | yes ([integration](evidence/integration/README.md)) | no |
| The 28 expansion families | no | no | no | no |

Evidence: [P04 verification index](evidence/p04/2026-10-13_p04_verification.md). Placeholder eggs, ghosts and Library entries exist (P04-T10/T12/T19/T21 passed on code-drawn DEBUG placeholders; final art is human-made and still open). Event/stack integration and release enablement (P04-T11/T13/T20/T22) remain blocked. Kaing declares solid-side wall eligibility and Tulay declares itself ineligible as data; wall movement itself is a separate extension that is enabled by default as core movement.

## Event and stack integration — 2026-10-16

P04-T11, P04-T20 and the six P10 integration tasks (T07/T16/T25/T34/T43/T52). User decisions (2026-10-16): event eggs are filtered by mode, pieces already on the stage are left as they are, and the six P10 families join the real match pool.

- `PugadEggPoolGenerator.generate(..., mode_ids)` deals only families whose `modes_allowed` lists every active mode of the round. The scheduled P12 room passes the locked round's Main and Twist (`P12ScheduledMatchRoom.pugad_mode_ids`). Every family allows Karera, so Karera rounds deal the same seeded eggs as before. Development rooms (P05/P07 harness, P08/P11 labs) keep their fixed pools.
- A mode still listed as pending review is not dealt. Changing a scene's BlockData mode flags is the way to approve an item for an event.
- Verified with real pieces and real physics on the P12 room in Karera, Lagsanay, Kangaroo, Karera + Bomb-Taya, Karera + Kangaroo and Kangaroo + Bomb-Taya: [integration evidence](evidence/integration/README.md).

| Family | Allowed modes | Pending review | Wave support | Match weight | Event/stack result (2026-10-16) |
|---|---|---|---|---|---|
| Kaing (`build.hollow_blocks`) | Karera, Lagsanay, Kangaroo | — | support | 50 | Standable terrain in all six round types; never eliminates; no credit. |
| Tulay (`build.bamboo_bridge`) | Karera, Kangaroo | Lagsanay (safe-floor review) | support | 50 | Not dealt in Lagsanay rounds or Bomb-Taya stacks; a Tulay already on the stage stays standable in every round type. |
| Gulong (`move.tire_spring`) | Karera | Lagsanay, Kangaroo | none | 15 | Dealt in Karera rounds only. A placed Gulong launches in every round type with no elimination or credit. |
| Trumpo (`hazard.rail_trumpo`) | Karera, Lagsanay, Kangaroo | — | none | 20 | Direct kill credits its placer in all six round types. |
| Parol (`hazard.parol_pulse`) | Karera | Lagsanay, Kangaroo | none | 15 | Dealt in Karera rounds only. A placed Parol still kills, and credits its placer, in every round type. |
| Tsinelas (`hazard.slipper_launcher`) | Karera, Lagsanay, Kangaroo | — | none | 20 | Direct kill credits its placer in all six round types. |
| Walis (`utility.walis_cleanup`) | Karera | Lagsanay, Kangaroo | none | 15 | Dealt in Karera rounds only; clears earlier pieces in Place; no Play piece, no credit. |
| Bula (`hazard.bubble_planter`) | Karera | Lagsanay, Kangaroo | none | 10 | Dealt in Karera rounds only. A placed Bula captures and releases in every round type with no elimination or credit. |

Explosives (Bomb, Dynamite, Nuke), Spikes, Cannon and the stage blocks keep their scene flags (all three modes for explosives, Spikes and Cannon; Karera and Lagsanay for Solid Block, Wood Box and Collapsing Block). Release enablement (`release_target`) is still an owner decision per family (P04-T13/T22, P10 verify tasks), and all art is still DEBUG placeholder.

### P10 implementation notes (2026-10-14)

Evidence: [P10 verification index](evidence/p10/2026-10-14_p10_verification.md). *(2026-10-16: Trumpo and Tsinelas have since been approved for Lagsanay and Kangaroo by the P08/P11 labs; see [Event and stack integration](#event-and-stack-integration--2026-10-16) for the current flags.)* All six new families declare `modes_allowed = karera` and `modes_pending_review = lagsanay, kangaroo`; wall contact is `ineligible` and wave-support role is `none` (fail closed). Spring "genuinely supported by a separate safe face" is not implemented. Parol's "3–6 cell fixture span" is built as the total span including both posts, so the beam is span − 2 cells and the 6×1 figure is the bounded envelope (approved Stage A decision D7). Presentation is PLACEHOLDER only (see [ASSETS.md](ASSETS.md)); names remain working names awaiting native-speaker review. Direct eliminations are typed `AttributionRecord`s and are handed to the P06 race ledger; the ledger owns the terminal commit and drops self-kill credit. Bubble capture and spring launches are setup records and never earn Patibong.
# Current mode eligibility amendment — 2026-10-23

In normal scheduled Play, Pugad item eligibility is filtered for exactly one standalone Main mode (`karera`, `lagsanay`, or `kangaroo`). Legacy mixed-mode compatibility rows are ignored by `EventSchedule`; a stale row cannot broaden the egg pool or start a second controller. Existing pieces remain on the persistent stage under the current rules.
