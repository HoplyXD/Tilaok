# Tilaok! — Game Design Document

_Last updated: 2026-10-13 — approved scope/wording reconciliation, P00 target-PC confirmation, and wall-movement extension; existing gameplay values unchanged._

## 1. Pitch
A 2–4 player competitive party platformer. Each round, players pick eggs from the **Pugad** (nest), place what hatches on a shared stage, then play a main challenge. **Karera** is the default flag-race challenge; every 4th round, a **traditional Filipino game event** takes over the same stage. As the match advances, a rare compatible second event can stack on the main challenge.

**One-liner:** Build the level, survive the level, and every few rounds a laro ng lahi takes over.

## 2. Concept: Sabong, Reimagined
All characters are chickens. Instead of the traditional sabong where roosters fight, Tilaok!'s chickens compete through platforming and Filipino games. It turns a gambling-associated tradition into a wholesome, skill-based competition.

## 3. Core Loop (every round)
1. **Pugad:** a nest appears holding a random set of eggs (placeholder: players + 2); each player picks one and it hatches into an item.
   - Each egg is see-through with its **item visible inside**, so players pick on purpose. The item/size variant plays a short looping visual animation, but shows no name or description during the party flow. Grabbing an egg cracks it open and the item pops out into your pointer; names, descriptions, controls, and event rules belong in the Library.
   - Picking is **simultaneous**: first to grab an egg gets it. ~8s to pick; leftover eggs are assigned at random.
2. **Place:** players place their item anywhere on the shared stage.
   - Placing is **simultaneous**, with grid snap; you can't place on a player or protected goal geometry.
   - Placement controls: **move**, **rotate** (one button) and **confirm** (one button). A ghost shows green/red for a valid/invalid spot.
   - ~15s to place. If time runs out, the item auto-places at the pointer if the spot is valid, otherwise it is discarded.
   - Nothing is active during Place. The sole exception is the one-shot **Walis Cleanup** edit when confirmed; it is a construction action, never a Play-phase hazard. When Play begins, placed items reset to their defined starting position/state.
   - Pointers are visible to everyone, but nothing announces a placed Barya, so it can be tucked into the clutter.
3. **Play:** either
   - a **Main Challenge**: Karera (run from start to the flag) or an active laro ng lahi event; and
   - at most one compatible **Twist** event layered onto that main challenge.

The stage **persists and grows** across rounds. Pugad and building continue during event rounds too, so traps become terrain for events.

**Starting stage:** a hand-built base layout with a spawn on the left, a flag on the right, a solid floor and a few platforms, so round 1 already has something to run across. Base stage pieces, the spawn and the flag are indestructible. Raised player-built geometry is the intended way to prepare for Kangaroo's Rising wave; a team that does not build useful elevation can lose to it. (Exact layout to be designed and playtested.)

**Construction rules (design contract):** the stage uses a logical tile grid whose pixel size is set from the project player-collision dimensions when the project is created. Validate simultaneous edits against a shared phase snapshot. If newly placed solid footprints conflict, reject the entire conflicting set rather than giving an advantage based on callback order. Intentional solid/trigger intersections are allowed only when the trigger remains readable and its danger region is shown. Walis Cleanup targets only removable player-built items in its preview; cleanup targets are resolved as one edit against the phase snapshot, then remaining placements are validated and committed as one set. It cannot affect base geometry, spawn safety, the goal platform/flag zone, or a hidden event goal zone. Removal persists across rounds. A removed support does not cause crushing: unsupported moving items return to their defined safe start or are removed according to their item contract. Layout solvability is not guaranteed.

Placement footprints, mover sweeps, projectile lanes and effect radii are distinct regions. Every new item defines rotation, bounding behavior and protected clearance. Moving hazards have bounded visible paths, reset to a deterministic direction at Play start, and remain inactive through Place. Use a short configurable activation grace so resets do not create unavoidable first-frame hits. Solids block Tsinelas Launcher projectiles. Item parameters are centralized data, not scattered constants. Exact pixel dimensions remain dependent on the team-created player and stage.

**Round end (Karera):** dying puts you out for the rest of the round (you can spectate and return next round). The round ends when every player has either reached the flag or died, so there can be one winner, several, or none. Once the first player reaches the flag, a ~15s countdown starts to prevent stalling. A hard cap of ~60s also ends the round; anyone not at the flag by then counts as failed. Dead players get a **cheer button** that triggers crowd reactions.

**Event cadence and stacking:** every round has exactly one Main Challenge. **Karera** is the default flag-race Main Challenge and the backbone of the match. Round 1 is always Karera so every match starts with the core build-and-race loop. Rounds 4, 8, and 12 are always standalone Lagsanay Main Challenges. On every other round after Round 1, select the Main Challenge from the active pool: Karera 70%, Lagsanay 20%, Kangaroo 10%. This gives Karera the clear majority while allowing standalone Lagsanay and Kangaroo rounds. The tutorial may temporarily override this schedule only for its guided first Karera.

The next round's Main Challenge and any Twist are locked and announced during the preceding Pugad phase, so players can build for both. A Twist is a second, compatible event running at the same time as the Main Challenge. It is a core feature, not a post-launch add-on. There is never more than one Twist and a challenge cannot stack with itself. Only non-guaranteed rounds roll for a Twist: the chance is 0% in rounds 1–4, 10% in rounds 5–7, 20% in rounds 8–10, and 30% in rounds 11–12. Sudden Death never uses a Twist. A failed roll means a normal single-challenge round.

## 4. Events (Laro ng Lahi)
Each event is its own mini game mode with its own win condition, played on the current stage. Placed traps stay active and can still kill. The flag is hidden in event rounds (its platform stays).

**"Alam mo ba?" card (Should, optional):** when included, before each event, a short card explains the real traditional game (what it is, where it's from, how it's played in real life) so the game communicates the theme, not just uses it.

### Event stacks (core)

The Main Challenge alone determines the round's end condition and scoring family. A Twist adds pressure and can eliminate players, but never creates a second score table. Objective Main Challenges use Tapos/Una/Bayani/Bawi and race-only Barya where applicable; elimination Main Challenges use Lagsanay placement scoring and Bawi. Patibong still belongs only to the direct placed hazard that eliminates a player. A taya timeout or Kangaroo command failure is an event elimination, not a Patibong.

The first compatible stacks are:

| Main Challenge | Twist | Combined rules |
|---|---|---|
| **Karera** | **Lagsanay** | The flag remains active while Bomb-Taya runs. Player bodies stay pass-through as in a normal race, but the tag sensor is active. A finisher becomes secured: they are no longer a taya/pass target and are immune to remaining hazards. If the current taya reaches the flag, they become secured and taya transfers immediately to a random unfinished live player; if none remains, the round resolves. The race ends when all players finish or are eliminated. Use race scoring only, including its too-easy/too-hard rule and Barya; Lagsanay placement points do not apply. |
| **Karera** | **Kangaroo** | The flag remains active while Kangaroo commands run. A failed command adds a Kangaroo failure marker; the third marker eliminates that player. A finisher becomes secured and no longer receives commands or hazard effects. The race ends when all players finish or are eliminated. Use race scoring only, including its too-easy/too-hard rule and Barya; Kangaroo failures never create a second score table. |
| **Kangaroo** | **Lagsanay** | Kangaroo remains the Main Challenge: its command cadence and three-failure elimination rule continue while Bomb-Taya passes, its timer runs, and its contact sensor remains active. Either a third Kangaroo failure, a taya timeout, or a trap can eliminate a player. The last survivor wins. Use Lagsanay placement scoring only; neither event grants an additional score table. |

Only the combinations in this table are enabled initially. A new stack needs an explicit compatibility row that defines input, collision, terminal outcome, scoring family, player state after completion, and presentation before it can enter the Twist pool. The round-announcement UI must show the Main Challenge first and the Twist below it, for example: **KARERA** / **TWIST: BOMB-TAYA**.

### Lagsanay (locked)
Ilonggo for tag (Tagalog: *habulan* / *taya-tayaan*). Tag + hot potato.
- A random player becomes the **taya**, with a visible countdown over their head.
- Touching another player passes the taya. If the taya touches more than one eligible chicken in the same physics step, pass taya to the nearest; an exact-distance tie goes to the lowest player slot/ID.
- When the timer hits zero, the current taya is eliminated.
- A new random player becomes taya; repeat until one survives.
- Tuning ideas:
  - ~1s pass-back immunity (no instant re-tag)
  - Taya moves slightly faster
  - Timer shortens as players are eliminated (e.g., 15s → 10s → 7s)
- **Trap kills:** a trap death is an elimination, and the dead player takes the lowest remaining placement slot. If the taya is killed, a new taya is picked from the survivors.
- **Simultaneous eliminations** share the affected placements, and their points are averaged. This does not apply when the simultaneous group contains every remaining player; use the Last Cluck rule below to determine one winner.
- The Lagsanay floor is solid (no bottomless pits), so a fall never eliminates anyone.
- **Player contact:** chickens pass through each other; a separate tag sensor handles taya transfer. This prevents body-blocking and corner traps.
- **Start:** everyone spawns at the same spawn point. The first taya is frozen for ~3s and is immune to hazards during that head start; their countdown only starts after it ends, so the others can run.

### Other events
| Event | Idea | Status |
|---|---|---|
| Langit-Lupa | The floor (lupa) rises; stay high until the timer ends. | **Second event to build** |
| Luksong Tinik | Spike waves sweep the stage; survive them all. | Optional third |
| Agawan Buko | Coconuts drop; most held when time runs out wins. Works at any player count. | Backlog |
| Agawan Base | Team capture-the-flag. | Cut (team-based, breaks at 3 players) |
| Patintero / Tubigan | Guards patrol lines. | Cut |

_Naming: prefer local Hiligaynon names where they exist. Verify all names with a native speaker before finalizing._

### Kangaroo (core Main Challenge)

Kangaroo does not replace Langit-Lupa, which remains the GDD's second named laro ng lahi. Kangaroo is also a Main Challenge for the core event-stack system because Kangaroo + Lagsanay is an approved compatible stack. Its giant slipper is a background-only, non-colliding presenter. At each command, it lands in one of three equally likely poses: sole down/normal for Freeze, sole up/facing down for Rising wave, or sideways for Hug (33.33% each). Each command is announced through that readable slipper movement and landing, a large text/icon prompt, audio, and an impact screen shake; the prompt must have a non-colour identifier and a reduced-shake option.

The command loop is: a one-second telegraph and slipper landing, a three-second response window, evaluation, then a 0.75-second reset. World movement, traps, projectiles, Bomb-Taya, and player input continue throughout; Kangaroo never pauses the match. A failed command adds one visible marker in order: **KANG** then **GA** then **ROO**. The third marker eliminates that player. Trap deaths still eliminate directly. The last survivor wins and uses the Lagsanay placement scoring family; command failures are event eliminations, never Patibong.

The first command set is:

- **Freeze:** during the response window, a chicken must not give intentional run or jump input. Controller deadzone and release grace prevent drift or a just-released control from counting. Passive movement from conveyors, launchers, knockback, or other forces does not fail this command.
- **Rising wave:** the stage selects one world-space height band at equal probability: middle-low, middle, or middle-high. It never selects near-floor or near-ceiling heights and is not camera-relative. A red/orange target line appears at that height, then a cartoon danger wave rises to it during the response window. At evaluation, a chicken must be grounded on player-built solid geometry whose standing position is above the line; base-stage platforms, jumping through the line, bubble capture, or being airborne do not qualify. A player below the line receives one marker. The wave drains immediately after evaluation in a short exit animation. It does not reroll when no player-built raised support exists: building useful height is part of the match's risk and preparation.
- **Hug:** this command uses pairs only. At evaluation, form contact pairs from the live chickens, beginning with the shortest eligible contact and resolving equal distances by player-slot order; a chicken can belong to only one pair. Every paired chicken passes and every unpaired chicken receives one marker. Contact is required only at the evaluation instant, not throughout the response window. A three-chicken cluster therefore leaves one chicken unpaired, while four chickens can form two pairs. If exactly two chickens remain, a sideways slipper rerolls before telegraphing; the reroll does not count as a command or affect the pressure level. Do not select Hug with one survivor because the round has already ended.

Commands must use an icon, distinct audio cue, and clear timing ring as well as the slipper pose; screen shake has full, reduced, and off settings. Elimination removes a chicken from command checks and from Lagsanay tagging. Kangaroo + Lagsanay keeps Kangaroo's intentional-input rule, so a forced movement or tag contact does not itself fail Freeze.

**Slipper Storm:** count completed commands since the most recent elimination from any source. After every two commands with no elimination, shorten the next response window by 0.5 seconds and the reset by 0.15 seconds, to a minimum one-second response and no reset. After eight such commands, enter Slipper Storm: a command lands every 0.5 seconds, an active command lasts one second, and at most two command requirements can be active at once. If two are active, delay the next landing until one resolves. The giant slipper uses intensified impact, audio, and visual effects. With two survivors, Hug continues to reroll and every two-command Storm set contains one Freeze and one Rising wave, forcing their requirements to overlap until an elimination occurs. This intentionally chaotic pressure continues until an elimination occurs, then the no-elimination count resets and the normal cadence resumes. If a storm eliminates every remaining player in the same physics tick, use the existing Last Cluck rule to select one winner. Keep local names and real-world rule claims provisional pending cultural review. See `docs/ITEMS.md` for event backlog notes.

## 5. Scoring (all rounds)
Event rounds reuse the **same point types**, re-mapped to each event's objective, so players learn one system. Values are our own (multiples of 0.25) and are tuned in playtesting.

### Point types
| Type | Name | Points | Karera Main Challenge | Other Main Challenge |
|---|---|---|---|---|
| Goal | **Tapos** | 1.0 | Reach the flag alive | Complete the Main Challenge's objective |
| First | **Una** | +0.25 | First to reach the flag | Best performer in the Main Challenge |
| Solo | **Bayani** | +0.5 | Only player to reach the flag (2–4 players) | Only player to complete the Main Challenge's objective |
| Trap | **Patibong** | +0.25 each | Each player killed by a trap you placed, as long as at least one player reached the flag that round (you score even if you lost). Dying to your own trap scores nothing | Same, according to the Main Challenge's scoring family |
| Comeback | **Bawi** | +0.75 | Underdog reaches the flag | Underdog completes the Main Challenge's objective / places 1st in an elimination Main Challenge |
| Coin | **Barya** | +0.5 | Reach the flag alive carrying the Barya | Karera only for now |

**Underdog:** a player who is 3+ points behind the leader at the start of the round.

**Karera finish awards:** every chicken that reaches the flag alive earns Tapos (+1.0), subject to the existing too-easy/too-hard rule. The earliest recorded flag crossing earns Una (+0.25). If multiple chickens cross on the exact same physics tick and the game cannot distinguish an earlier crossing, every tied first finisher earns Una.

**Outcome and attribution contract (approved design):** record one terminal outcome per player per round and award it once. A self-elimination never grants Patibong. The directly eliminating hazard owns the elimination credit; bubbles, slowing, wind, or other setup effects receive no assist credit. If multiple hazards contact a player in one physics step, resolve from the earliest recorded contact time, with a stable item-ID tie-break for indistinguishable contacts; do not rely on signal/callback order. For race goal-versus-death in the same step, use recorded event time; if truly indistinguishable, elimination wins. Barya scores only for a race-round finisher carrying it. Too-easy/too-hard suppression applies to event Goal/First awards as written for non-Lagsanay events, while Lagsanay placement scoring is always used. Preserve values. Average tied placements exactly and store score in eighth-point units (or equivalent rational form), not rounded quarter-points.

### Too easy / too hard (all rounds except Lagsanay)
- Everyone gets Tapos → **no points** that round (except Barya, which is earned by reaching the flag, so it only matters here).
- Nobody gets Tapos → **no points** that round, including Patibong.
- This forces players to build stages that are hard but beatable.
- **2-player matches:** this rule is waived. Reaching the goal scores Tapos for each player, plus Una for the first, and Bayani if only one finishes.

### Event mapping
| Main Challenge | Goal = | First = |
|---|---|---|
| **Lagsanay** | _Uses placement scoring, see below_ | — |
| Langit-Lupa | Alive when the timer ends | Highest position at the end |
| Luksong Tinik | Survive all spike waves | None |
| Agawan Buko | Holding at least 1 coconut at the end | Most coconuts |

### Lagsanay: placement scoring (exception)
Lagsanay is elimination-based, so it uses survival placement instead of Goal/First. This keeps it fair: everyone earns something for how long they lasted.

| Placement | 4 players | 3 players | 2 players |
|---|---|---|---|
| 1st (last survivor) | 1.0 | 1.0 | 1.0 |
| 2nd | 0.5 | 0.5 | 0 |
| 3rd | 0.25 | 0 | |
| 4th (first eliminated) | 0 | | |

- **Patibong** (+0.25 per kill) still applies; traps stay deadly during Lagsanay.
- **Bawi** (+0.75) applies if an Underdog places 1st.
- **No too easy / too hard rule**: there is always a winner.
- Runs until one survivor remains (no fixed timer needed). **Last Cluck exception:** if every remaining player is eliminated in the same physics tick, do not average first place. The player with the latest recorded elimination time wins; an exactly identical time is resolved by the lowest player slot/ID. The other players take the lower remaining placements. The result screen should make this understandable with a brief freeze frame and “Last Cluck!” callout.

### Barya (coin)
- Barya is an **item that sometimes appears among the Pugad eggs** (about a 1-in-3 chance per round, replacing one egg). Whoever picks it places it, so they choose how hard it is to reach.
- Touch it to pick it up; it follows you visibly. If you die, you drop it where you died and anyone can grab it.
- At most one per round, and it is removed at round end (unlike other items, it does not persist).
- It still pays out in a "too easy / too hard" round.
- Priority: **Should**. Build after the base loop and scoring work; cut first if the schedule slips.

### Match settings
- **First to 10 points**, or the highest score after **round 12**, whichever comes first (keeps matches time-bounded). This is checked at the **end of a round**; if more than one player passes 10 in the same round, the higher total wins. An equal total goes to Sudden Death.
- If players tie at the end → **Sudden Death**: a Lagsanay between the tied players, which always produces exactly one winner.
- An optional results-screen **local win tally** may persist between matches within the current session only. It is Should scope, not a disk save or online leaderboard.

## 6. Characters
- All players are **chickens** with different skins/colors (black, white, orange, etc.).
- Ideas: Philippine native-chicken looks; accessories like salakot, bandana, tsinelas for readability.
- **Accessibility:** each chicken has a second identifier besides color (a number or shape marker above the head), and UI colors must be readable for colorblind players.

## 7. Items & Traps
Items arrive as eggs in the Pugad (item visible inside) and hatch when picked. The design catalog contains 36 distinct item families, with an eight-family first batch and the remaining designs held as backlog. See `docs/ITEMS.md` for contracts, reference attribution and tuning needs.
- **First batch:** Hollow Blocks / Kaing Stack, Tulay na Kawayan, Gulong Talon, Trumpo sa Riles, Parol Pulse, Bula-Bulaklak, Tsinelas Launcher, and Walis Cleanup. Bubble capture is scheduled last in the batch because it introduces temporary player state and forced movement. The original Bomb remains a brainstormed clutter-control item; Walis Cleanup is a distinct proposed placement-phase edit and does not silently replace Bomb.

**Pugad weighting proposal:** keep construction and recovery tools available in the pool, but do not promise that every round contains a guaranteed item or that every resulting layout is solvable. Egg count, weights, item cap, and recovery availability remain playtest tunables.

**Existing item brainstorm retained:** rolling niyog, sampayan, kawali of hot oil, charging tricycle, banana-peel slip, Bomb, and basic platforms/springs remain in the team's earlier brainstorm. The 36-family catalog adds detailed proposals but does not silently approve, delete, or implement these ideas. The existing Bomb proposal removes any player's placed items in a radius while protecting base geometry, floor, spawn, and flag; its range and item-cap behavior remain undecided.

## 8. Platform & Multiplayer
- Engine: **Godot 4.7** (free and open source, so no license is needed to play or build).
- PC (free to play, no license needed).
- **Local multiplayer** (2–4 players, **gamepads first**, shared keyboard as fallback). Online play is out of scope for the deadline.
- **Controls baseline:** the measured P02 controller implements run and jump only. On October 13, wall slide/jump was approved as a separate, unimplemented Should-scope extension; see [Wall slide and wall jump](#wall-slide-and-wall-jump--approved-extension). Dash, double jump and drop-through remain excluded.
- **Player collision:** chicken bodies pass through each other in all supported modes. Separate contact sensors handle Lagsanay tagging and Kangaroo Hug; contact does not introduce body pushing. Future modes need their own explicit contract.

### Wall slide and wall jump — approved extension

**Status — October 13, 2026:** Approved; source implemented but not run or verified (see PHASETASK P02-T15–T22). Design rules below are unchanged. This adds a distinct optional movement mechanic to the existing measured run/jump baseline; it does not revise the historical P02-T09/T10 evidence. The extension is Should scope, scheduled after P03, and must not delay P04 or automatically become a required October submission feature. Decide whether to include it before the October 21 feature freeze.

While airborne and touching an eligible solid side, a chicken slides down with a configurable cap on downward speed. Holding toward the wall is not required. Base and player-built solid sides qualify; moving solids qualify only while actual contact remains valid. One-way platform sides and undersides, pass-through chicken bodies and arena containment boundaries do not qualify. A fresh jump press kicks the chicken away; start with configurable prototype candidates of 240 wu/s horizontally and −520 wu/s vertically. Steering remains available immediately under ordinary air control. One kick is allowed per wall contact; the chicken must separate and make fresh contact before another. Holding jump and operating-system repeats do not repeat a kick; buffered input is consumed once.

Terminal, opening-freeze, capture and external-force precedence remain unchanged. External launches preempt wall actions and clear wall eligibility/input. Pause freezes the action; phase changes, reset and reload clear stale wall contact or buffered input. Chicken bodies remain pass-through. Wall contact is not grounded support and never qualifies for Rising wave. Slide cap, grace/separation thresholds and impulse values remain provisional and require real physics trials and human feel review. Dash, double jump and drop-through remain out of scope. See [PRD REQ-MOVE-004](PRD.md#req-move-004--slide-on-eligible-walls-and-kick-away-with-a-fresh-jump-press) and [PHASETASK P02-T15–T22](PHASETASK.md#p02-wall-movement-extension--approved-unimplemented-should-scope).
- **Camera:** dynamic, always keeps everyone who matters in frame by zooming and panning smoothly.
  - **Play phase:** frames live players only. Dead players are excluded (finished players too, so the camera follows whoever is still running).
  - **Place phase:** frames the pointers of players who have **not placed yet**. Far-apart pointers zoom out to fit both; once a player places, their pointer drops out and the camera eases in on the remaining ones. When everyone has placed, the camera eases to the Play framing.
  - Min/max zoom limits; the stage has fixed world bounds and pointers can't leave them.
  - Eased movement (no snapping) when the framed set changes.

## 9. Atmosphere & Audio
The stage is an arena with an **interactive crowd**: the sabong crowd reimagined as wholesome fans. No fighting; they cheer, groan and gasp at the platforming.

| Moment | Crowd reaction |
|---|---|
| Round start | Rooster crow ("Tilaok!") and hype murmur |
| Nasty trap placed | "Oooooh" |
| Chicken hits a trap | Big "OHHH!" then groan |
| Falls down a pit | Long, sad "awwwwww" |
| Close call | Sharp gasp |
| Reaches the flag | Cheer; louder roar for Una |
| Nobody reaches the flag | Collective sigh |
| Everyone reaches the flag | Confused "...eh?" |
| Underdog gets Bawi | Extra-loud celebration |
| Lagsanay, timer under 5s | Drumroll and chant, building |
| Lagsanay, last two chickens | Rising tension, then eruption on elimination |
| Match won | Roar, then "TI-LA-OK!" chant |

- **Fans in player colors:** background crowd sprites are palette-swapped to each player's color and cheer when their chicken scores.
- **Tension meter (0–1):** rises near the flag, in Lagsanay's last seconds and with few survivors; drives the volume and pitch of the ambient crowd loop.
- **Tone:** wholesome. Chickens who "die" are just out for the round, so reactions are comedic, not violent. No blood or gore, and no gambling or betting imagery anywhere (the competition prohibits "torturous" content).
- **Sourcing:** the team records the crowd sounds themselves (team-made, no license risk). Any stock clip is logged with its license in `docs/ASSETS.md`.
- **Priority:** Should. About 8 clips cover most of the table.

## 10. Onboarding & Presentation
Driven by the competition criteria (see `docs/COMPETITION.md`):
- **Tutorial/onboarding is required** for screening: a short guided first round (move, jump, grab an egg, place, reach the flag) plus on-screen hints for event rounds.
- **UI:** simple and easy to navigate: title screen, join/lobby (pick color), the match, and a results screen. A local win tally on the results screen is optional.
- **Setting:** a Filipino barrio look (bahay kubo, sari-sari store, palay fields) so the theme reads even in race rounds.
- **Trailer:** loops at events, so it must read without sound (use captions).
- **Demo video:** shows a Lagsanay round and explains the rules in plain language.
- **Rules clarity:** winning and losing rules must be easy to understand at a glance (points shown clearly each round).

## 11. Open Questions
- [x] Engine choice: **Godot 4**
- [x] Target engine version: **Godot 4.7**
- [x] Main Challenge cadence: laro ng lahi every 4th round, announced a round ahead
- [x] Core event stacking: one compatible Twist, with round-scaled chance and no Sudden Death Twist
- [x] Box/point naming and values (see §5; verify spelling with a native speaker)
- [x] Coin: Barya, placeable item
- [x] Death and race-round end rules (see §3)
- [x] Stage-clutter control: bomb item
- [x] Sudden Death: Lagsanay between the tied players
- [x] Art: 2D (exact style undecided)
- [ ] Final item enablement and Pugad egg count/weighting (placeholder: players + 2); see `docs/ITEMS.md`
- [x] Target team PC selected: current Acer Nitro ANV15-51; see `docs/PRODUCTION.md` for observed specifications.
- [ ] Confirmed performance/memory limits; targets remain unmeasured (see `docs/PLAYTEST.md`).
- [ ] Exact pixel grid and player dimensions when the Godot project exists
- [ ] Audio direction
- [ ] Team size and roles (later)

## 12. Approved delivery scope — October 13, 2026

All eight first-batch families and applicable approved size variants are submission targets. Prototype slices may enable a subset without deleting the full target; Tulay vertical orientation requires controller-support verification. Any later family cut requires an explicit team decision, with Bula-Bulaklak first for cut review. Title/results, Library, required tutorial, settings/help and essential audio/visual cues are required. Local session win tally, enhanced crowd, Barya, Langit-Lupa, richer cosmetic variants/accessories and reviewed educational cards remain Should. Include/defer Should work before freeze; included content must pass release gates. The other 28 catalog families remain expansion. See [PRD](PRD.md) and [PHASETASK](PHASETASK.md). No R1–R4 rule proposal is activated by this scope reconciliation.
