# Tilaok! — Game Design Document

**Current route (2026-10-24):** normal Play is Lobby → Pugad → shared 10-second BUILD → final 3–2–1/GO cue → active race/event with movement and 2-second non-gameplay construction jobs → results → next round. BUILD’s countdown remains in the side HUD; the full-screen cue appears only in the final 3 seconds. BUILD expiry starts active play immediately; the separate 3-second GET READY countdown is only for pause resume. The camera follows placement cursors during BUILD and chickens during PLAY. Confirming during BUILD places the assigned item immediately as an inert prepared piece that activates at PLAY; players may save it for live placement, where the two-second job applies. It retains P12 scheduling, scoring, Barya rules, stage persistence and sudden death. Sudden death has no new placement. The scheduled Place route is a developer fallback. Phone/LAN work is retired and preserved as history in `archive/retired-networked-live-build/`.

_Last updated: 2026-10-14 — guided first match uses a tutorial-only stage where building is required to reach the flag (§10); Place confirmation locks each edit with no undo during that round; also, block scenes with BlockData (kill/stun hitboxes, anchor/gravity, specials), Spikes, Cannon, stun and the death sprite (user request), 64 px tile grid, sneak and glide, W/Up jump, and the Solid Block, Wood Box and Collapsing Block (user request, 2026-10-14). Earlier: 2026-10-13 scope/wording reconciliation, P00 target-PC confirmation and wall-movement extension._

### Current balance and standalone-mode decision — 2026-10-23

This dated decision supersedes the earlier §1 stacking pitch, §3 optional Twist cadence/table, mixed-mode interface examples, and any “Karera with Bomb-Taya/Kangaroo” current-play text. Every round has exactly one Main: Karera, standalone Lagsanay (Bomb-Taya), or standalone Kangaroo. Sudden death remains standalone Lagsanay. Historical P12 pair tests remain historical integration evidence; they do not prove the current schedule. Provisional designer-editable windows are Pugad 15 s; Karera 120 s hard cap and 30 s after first finisher; Lagsanay 20/25/30 s at 2/3/4 alive; Kangaroo 2 s telegraph, 6 s base response, 1.5 s ordinary reset, accelerated floors 3 s/0.75 s, Storm threshold 16 commands, Storm response at least 3 s and 1.5 s landing interval. These are not final balance.

Rising Wave selects a world-space line from completed, explicitly eligible player-built support within playable map bounds and a conservative movement-response reach estimate. The selected line is shown before evaluation and is the line evaluated against fresh grounded support. If no fair target exists, Rising is skipped and one eligible alternate command is issued; no failure or command credit is charged for an unissued wave. Base geometry, previews, unfinished construction, side contact, coyote state and airborne crossing never qualify. Kangaroo KANG / GA / ROO strikes are compact overhead indicators driven by the existing controller count; the former side-panel miss rows are retired. See P21 in PHASETASK and the current evidence note for verification limits.

## 1. Pitch
A 2–4 player competitive party platformer. Each round, players pick eggs from the **Pugad** (nest), place what hatches on a shared stage, then play a main challenge. **Karera** is the default flag-race challenge; every 4th round, a **traditional Filipino game event** takes over the same stage. As the match advances, a rare compatible second event can stack on the main challenge.

**One-liner:** Build the level, survive the level, and every few rounds a laro ng lahi takes over.

## 2. Concept: Sabong, Reimagined
All characters are chickens. Instead of the traditional sabong where roosters fight, Tilaok!'s chickens compete through platforming and Filipino games. It turns a gambling-associated tradition into a wholesome, skill-based competition.

## 3. Core Loop (every round)

The normal route assigns one egg item per seat in Pugad, then runs a shared ten-second BUILD window. Its timer stays in the side HUD; no full-screen countdown appears until the final three seconds, when `3–2–1` leads directly into `GO!` and active play on the BUILD expiry boundary. There is no separate GO wait. Only pause resume has a separate three-second GET READY countdown. Movement, scoring, event clocks and hazards remain inactive during BUILD. During BUILD, the camera frames eligible placement cursors; entering build mode pauses that player's direct movement controls and directional input moves the item preview. Confirming a valid spot places the assigned item immediately as an inert prepared piece, which activates at PLAY. A player may wait, keeping the assigned item for active play. The final BUILD fixed-step boundary resolves confirmations already queued for that boundary before closing BUILD admission. During active PLAY the camera follows chickens, and a live placement starts the two-simulation-second construction job. During eligible active Play, an unused item can be placed live, and a started job cannot be manually canceled; a shot or bubble crossing its reserved area does not reject or cancel it. Round-end/reset and builder-ineligibility cleanup still apply. Each player can complete at most one placement per round. An unused item does not carry over: the next round offers a fresh Pugad item. A chicken entering an active construction footprint does not cancel the job; when a solid completes, any chicken intersecting its new footprint is moved onto its top surface. Construction pauses with the match. At the first fixed-step boundary after its deadline, terminal events resolve first and the game rechecks eligibility, inventory, current geometry, moving-piece sweeps, and support before committing. Live-built hazards activate immediately on completion without a nearby-player hold. The scheduled Place flow remains a developer fallback. This change does not alter the P12 event schedule or scoring; sudden death reuses the existing stage without new Pugad or placement.
1. **Pugad:** a nest appears holding a random set of eggs (players + 2); each player picks one and it hatches into an item. A match receives a fresh random seed unless `--match-seed=<number>` is supplied for a reproducible run. Eligible item variants are sampled without replacement within each nest, then the pool refills only if that round has fewer eligible variants than slots. Mode rules and the live-build safety gate still apply, so one nest does not display the whole catalog at once.
   - Each egg is see-through with its **item visible inside**, so players pick on purpose. The item/size variant plays a short looping visual animation, but shows no name or description during the party flow. Grabbing an egg cracks it open and the item pops out into your pointer; names, descriptions, controls, and event rules belong in the Library.
   - Picking is **simultaneous**: first to grab an egg gets it. ~8s to pick; leftover eggs are assigned at random.
2. **Place:** players place their item anywhere on the shared stage.
   - Placing is **simultaneous**, with grid snap; you can't place on a player or protected goal geometry.
   - Placement controls: **move**, **rotate** (one button) and **confirm** (one button). A ghost shows green/red for a valid/invalid spot.
   - Confirming a valid placement locks that edit for the rest of Place. It cannot be moved, rotated, or undone; a player who has locked an edit waits while the others finish.
   - ~15s to place. If time runs out, the item auto-places at the pointer if the spot is valid, otherwise it is discarded.
   - Nothing is active during Place. The sole exception is the one-shot **Walis Cleanup** edit when confirmed; it is a construction action, never a Play-phase hazard. When Play begins, placed items reset to their defined starting position/state.
   - Pointers are visible to everyone. Barya placement and carrying receive a live text cue so the round objective stays identifiable among the construction pieces.
3. **Play:** either
   - a **Main Challenge**: Karera (run from start to the flag) or an active laro ng lahi event; and
   - at most one compatible **Twist** event layered onto that main challenge.

The stage **persists and grows** across rounds. Pugad and building continue during event rounds too, so traps become terrain for events.

**Event-round eggs (2026-10-16, user decision):** an event round's Pugad only deals items approved for that event, and a stacked round only items approved for both its Main and its Twist (each item's mode flags; see [ITEMS](ITEMS.md#event-and-stack-integration--2026-10-16)). Pieces already on the stage stay exactly as they are and keep working in every round. Since the same date, Gulong, Trumpo, Parol, Tsinelas, Walis and Bula are in the real match's egg pool, with low provisional weights.

**Maps (2026-10-16, user request):** stages are map scenes in `scenes/maps/` (see [STAGE_AND_PLACEMENT](STAGE_AND_PLACEMENT.md#map-scenes-and-the-lobby-map-selection--2026-10-16-requested-by-jorge)). Players pick the map in the Lobby, and one map is used for the whole match. The built-in default stage stays available.

**Starting stage:** a hand-built base layout with a spawn on the left, a flag on the right, a solid floor and a few platforms, so round 1 already has something to run across. Base stage pieces, the spawn and the flag are indestructible. Raised player-built geometry is the intended way to prepare for Kangaroo's Rising wave; a team that does not build useful elevation can lose to it. (Exact layout to be designed and playtested.)

**Construction rules (design contract):** the stage uses a logical tile grid of **64×64 px tiles** (2026-10-14). A chicken is 1 tile wide and 2 tiles tall (clearance 64×128; collision body 56×120). Block sizes are written width×height in tiles (1x1 = 64×64, 3x1 = 192×64) and most blocks rotate in Place with R. The base stage is drawn by a 64 px TileMapLayer. Validate simultaneous edits against a shared phase snapshot. **Overlapping placements (2026-10-16, user request):** first come, first served (2026-10-14) was removed. Confirming earlier gives no advantage. A ghost only says **Tile occupied** (a piece, the stage or a chicken is there) or **Invalid spot**. If two players place on the same cells in one Place phase, the lower seat number keeps them and the other sees "Tile occupied" (the original P05 seat-order rule). Intentional solid/trigger intersections are allowed only when the trigger remains readable and its danger region is shown. Walis Cleanup targets only removable player-built items in its preview; cleanup targets are resolved as one edit against the phase snapshot, then remaining placements are validated and committed as one set. It cannot affect base geometry, spawn safety, the goal platform/flag zone, or a hidden event goal zone. Removal persists across rounds. A removed support does not cause crushing: unsupported moving items return to their defined safe start or are removed according to their item contract. Layout solvability is not guaranteed.

Placement footprints, mover sweeps, projectile lanes and effect radii are distinct regions. Every new item defines rotation and bounded behavior. Items remain inactive through Place; at Play start they use their normal reset/tell timing. Live-built hazards activate at completion and do not wait for nearby players to leave their effect area. A shot or bubble already in motion does not block a confirmed construction job. Solids block Tsinelas Launcher projectiles. Item parameters are centralized data, not scattered constants. Exact pixel dimensions remain dependent on the team-created player and stage.

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

**P12 same-step ordering for stacks — owner decision, 2026-10-15.** Appended; no earlier rule changes. Every stacked round resolves in one deterministic batch per physics step, never by callback order: the Twist proposes terminal outcomes against the same frozen live set, the merge orders them by recorded time then cause rank (command failure, then taya timeout, then direct trap; an incomparable-time trap ranks last), and each player gets one terminal outcome. Approved additions: (U1) a taya who touches the flag on the step its countdown expires is eliminated by the timeout; (U2) goals commit before the tag pass, so a finisher is never a pass target; (U3) a finishing taya hands the bomb to a random unfinished live runner in ascending-slot order, keeping the remaining countdown with no opening freeze (one unfinished runner left becomes the taya; none left resolves the race, and the Twist never ends a Karera round); (U4) after a taya timeout the fresh timer uses the number of unfinished live runners remaining (one left uses the two-alive value); (U5) a Twist terminal due on a Karera deadline step commits first and keeps its cause; (U6) a third Kangaroo failure on the step a runner touches the flag eliminates them; (U7) commands continue for the last unfinished runner under Karera, with Hug excluded below two; (U8) Slipper Storm never runs when Kangaroo is a Twist; (U10) a command failure that eliminates the taya or the pass target is committed before the tag pass; (U11) a tag pass is independent of an active Hug. R1–R4 remain inactive. Full table with sources, scenarios and the approval record: [P12 decision table](evidence/p12/p12_terminal_order_decision_table.md).

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
- **Start:** everyone spawns at the same spawn point. The first taya is frozen for ~3s and is immune to hazards and capture during that head start; they cannot tag or be tagged, and their countdown only starts after it ends so the others can disperse. The initial prototype uses centralized 3 s opening, 1 s pass-back immunity, and 15/10/7 s countdowns at 4/3/2 alive. The tentative taya speed bonus is not approved or implemented.
- **Recorded-step ordering:** use one actual sensor-overlap snapshot and one elimination batch per physics step. Commit the step's hazard/timeout outcomes before counting survivors, assigning a new taya, resolving placements or selecting tag recipients. Ignore terminal participants in the frozen tag candidate set. If a non-taya dies and the taya survives, the taya keeps the remaining countdown. Passing cannot reset or extend it. A dead taya is never transferred; select a new taya from the surviving live group and give that taya the timer for the new survivor count.
- **Expiry boundary:** an un-timed contact on the countdown-expiry step loses to timeout. A direct hazard on the current taya wins only when its comparable recorded time is strictly earlier than expiry; an exact tie or unavailable/incomparable event time resolves as timeout. Do not use signal/callback arrival order or invent sub-frame precision. Captured live players remain eligible tag recipients under the existing capture contract.

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

The base command loop is: a one-second telegraph and slipper landing, a three-second response window, evaluation, then a 0.75-second reset. World movement, hazards, and player input continue; Kangaroo never pauses the match. The standalone P11 lab has no Bomb-Taya controller. The later Kangaroo + Lagsanay stack will keep its taya timer and passing active. A failed command adds one visible marker in order: **KANG** then **GA** then **ROO**. The third marker eliminates that player. Direct trap deaths still eliminate. The last survivor wins and uses the Lagsanay placement scoring family; command failures are event eliminations, never Patibong.

The first command set is:

- **Freeze:** during the response window, a chicken must not give intentional run or jump input. A fresh press fails immediately, including a press/release between physics samples. Input already held when the response window starts has one 0.10-second release grace; releasing within it passes, holding past it fails, and the grace never renews. Shared input thresholds reject stick drift. Passive movement from conveyors, launchers, knockback, or other forces does not fail this command.
- **Rising wave:** the stage selects one fixed world-space line at equal probability: middle-low **768 wu**, middle **576 wu**, or middle-high **384 wu**. It is not camera-relative. A target line appears, then a debug wave placeholder rises toward it during the response window. At evaluation, a chicken must have actual current upward support from eligible player-built solid geometry at or above the line (feet `y <= line + 1 wu` numerical tolerance); base-stage platforms, jumping through the line, bubble capture, or being airborne do not qualify. A player below the line receives one marker. The wave drains after evaluation. It does not reroll when no player-built raised support exists: useful elevation is a shared construction responsibility.
- **Hug:** this command uses pairs only. At evaluation, form contact pairs from the live chickens, beginning with the shortest eligible contact and resolving equal distances by player-slot order; a chicken can belong to only one pair. Every paired chicken passes and every unpaired chicken receives one marker. Contact is required only at the evaluation instant, not throughout the response window. A three-chicken cluster therefore leaves one chicken unpaired, while four chickens can form two pairs. If exactly two chickens remain, a sideways slipper rerolls before telegraphing; the reroll does not count as a command or affect the pressure level. Do not select Hug with one survivor because the round has already ended.

Commands use a pose, icon, distinct audio cue, and timing ring; the development implementation labels its code-drawn pose, tone, and wave as DEBUG placeholders. Screen shake has full, reduced, and off settings. Elimination removes a chicken from later command checks and from Lagsanay tagging. Kangaroo + Lagsanay keeps Kangaroo's intentional-input rule, so forced movement or tag contact does not itself fail Freeze. Final pose art and production audio, human comprehension/readability review, cultural review, and balance approval remain with the team.

**Presentation default update — 2026-10-23:** fresh Settings use Full screen shake, unmuted sound, and 100% Master / Music / Effects / Crowd levels so item and event cues are present by default. Reduced and Off screen shake and the existing volume/mute controls remain available to players. These are presentation defaults only; they do not enable gameplay variants or change item rules.

Terminal ordering is based on recorded simulation time rather than callback order: a comparable direct hazard wins only when its timestamp is strictly earlier than command evaluation. An exact tie or missing/incomparable hazard time resolves as command failure and awards no Patibong for that failure. Resolve due commands and eliminations in a deterministic batch, with at most one terminal outcome per player; simultaneous final eliminations use Last Cluck.

**Slipper Storm:** count completed commands since the most recent elimination from any source. After every two commands with no elimination, shorten the next response window by 0.5 seconds and the reset by 0.15 seconds, to a minimum one-second response and no reset. After eight such commands, enter Slipper Storm: a command lands every 0.5 seconds, an active command lasts one second, and at most two command requirements can be active at once. Delay another landing until a slot opens. With two survivors, each two-command Storm pair contains one Freeze and one Rising wave in seeded order; Hug is never selected and the two requirements intentionally overlap. This pressure continues until an elimination, then cadence resets. If a Storm batch eliminates the remaining players in one physics step, Last Cluck selects one winner. Keep local names and real-world rule claims provisional pending cultural review. See `docs/ITEMS.md` for event backlog notes.

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

**Barya runtime contract (approved 2026-10-15):** the scheduled P12 match rolls a separate seeded Barya offer only for Karera, including Karera + Bomb-Taya and Karera + Kangaroo. At the default 1-in-3 chance it replaces one uniformly selected Pugad egg without changing pool size. The picker claims and places one non-persistent 1×1 objective; invalid/expired placement discards it. Overlapping pickups resolve by nearest chicken controller origin, then lower seat index. Carrying survives capture. A committed elimination drops the coin at the controller root; an invalid drop cell recovers to the nearest valid cell, with row-major `(y, x)` ties, or discards only when no cell is valid. A coin dropped during a physics step cannot be reclaimed until the next step. Only a committed Karera finisher carrying it earns +0.5 (four eighth-point units), including an all-finish round; no finisher means no Barya points. Round cleanup removes it after score/history capture. It is not an obstacle, does not enter the persistent item manager or 48-piece cap, is not solid, and does not support Rising or Walis. The P07 first-playable route remains Barya-disabled. See [Barya engineering evidence](evidence/barya/README.md). Human art, accessibility, cultural, physical-device and player review remain open.

**Underdog:** a player who is 3+ points behind the leader at the start of the round.

**Karera finish awards (clarified 2026-10-15):** every chicken that reaches the flag alive earns Tapos (+1.0), subject to the existing too-easy/too-hard rule. The earliest recorded flag crossing earns Una (+0.25). If multiple chickens cross on the exact same physics tick and the game cannot distinguish an earlier crossing, every tied first finisher earns Una. Karera has no second- or third-place award or separate 1st/2nd/3rd placement table; Bayani, direct Patibong, eligible Bawi and Barya keep their own conditions.

**Retired proposal — network disconnect elimination (2026-10-21):** the prior network-only proposal is superseded by the 2026-10-22 retirement of phone/LAN connectivity. It is not an active game rule or release requirement; the original network tracker retains its recorded status in the retired archive.

**Outcome and attribution contract (approved design):** record one terminal outcome per player per round and award it once. A self-elimination never grants Patibong. The directly eliminating hazard owns the elimination credit; bubbles, slowing, wind, or other setup effects receive no assist credit. If multiple hazards contact a player in one physics step, resolve from the earliest recorded contact time, with a stable item-ID tie-break for indistinguishable contacts; do not rely on signal/callback order. For race goal-versus-death in the same step, use recorded event time; if truly indistinguishable, elimination wins. Barya scores only for a race-round finisher carrying it. Too-easy/too-hard suppression applies to event Goal/First awards as written for non-Lagsanay events, while Lagsanay placement scoring is always used. Preserve values. Average tied placements exactly and store score in eighth-point units (or equivalent rational form), not rounded quarter-points.

**Lagsanay runtime clarification (approved for the independent development mode):** timer expiry and accepted hazard eliminations are committed as one batch before survivor count, reassignment, placement and any surviving-taya tag transfer. The hazard director uses its round-relative simulation clock; only contacts whose producers supply comparable event times may be ordered within a physics tick. Otherwise they remain indistinguishable and use the existing stable tie rule. Last Cluck test fixtures may supply distinguishable timestamps to verify the arithmetic, but they do not claim that real callbacks reveal sub-frame order. A brief 0.75 s prototype freeze presents the Last Cluck explanation after score/terminal commit; the presentation callback cannot award again. These runtime bindings do not activate R1–R4 or the tentative taya-speed idea.

### Too easy / too hard (objective scoring, including Karera)
- Everyone reaches the goal → ordinary race awards are suppressed in 2–4-player matches. **Barya still pays +0.5** to a finisher carrying it; other players earn zero round points.
- Nobody gets Tapos → **no points** that round, including Patibong.
- This forces players to build stages that are hard but beatable.
- **2-player matches:** the same all-finish suppression applies. Barya still pays if carried across the flag; if no Barya is present, everyone earns zero round points. If only one player finishes, their ordinary Tapos, Una, Bayani and eligible bonuses apply.

### Event mapping
| Main Challenge | Goal = | First = |
|---|---|---|
| **Lagsanay** | _Uses placement scoring, see below_ | — |
| Langit-Lupa | Alive when the timer ends | Highest position at the end |
| Luksong Tinik | Survive all spike waves | None |
| Agawan Buko | Holding at least 1 coconut at the end | Most coconuts |

### Lagsanay and Kangaroo: placement scoring (exception)
Both elimination Main Challenges use survival placement instead of Karera's finish awards. The last chicken standing is first; the first eliminated is last. In a four-player round, that first elimination is fourth and earns zero placement points. Directly earned Patibong can still add points to an eliminated chicken, including fourth place.

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
- It pays out when its carrier reaches the flag alive, including an all-finish round. If nobody finishes, nobody earns Barya.
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
- **Four keyboard layouts (2026-10-16, user request):** WASD (E or F confirm, R rotate), IJKL (O confirm, P rotate), arrows (Enter confirm, Right Shift rotate) and numpad 8 4 2 6 (Num 0 confirm, Num 5 rotate). A layout is only a device: seats are numbered in join order, so any layout can be any player. Internally WASD is K1, arrows K2, IJKL K3 and numpad K4. Four players on one keyboard depends on that keyboard's key rollover, which is untested; the key-chord recorder (chords C25–C31) checks it on the real keyboard.
- **Keyboard controls (2026-10-14):** K1 A/D move, **W jump (hold W while falling to glide)**, **S sneak**; K2 uses the arrows the same way (Up jump/glide, Down sneak). Space/Ctrl stay as alternate jump keys and W/Up still move cursors in menus and Place. Gamepad: A jumps (hold to glide), d-pad down sneaks. See [Sneak and glide](#sneak-and-glide--2026-10-14-extension).
- **Controls baseline:** the measured P02 controller implements run and jump only. On October 13, wall slide/jump was approved as a separate Should-scope extension, implemented, verified on synthetic evidence and enabled by default as core movement (owner decision, 2026-10-13); see [Wall slide and wall jump](#wall-slide-and-wall-jump--approved-extension). Dash, double jump and drop-through remain excluded.
- **Player collision:** chicken bodies pass through each other in all supported modes. Separate contact sensors handle Lagsanay tagging and Kangaroo Hug; contact does not introduce body pushing. Future modes need their own explicit contract.

### Wall slide and wall jump — approved extension

**Status — October 13, 2026:** Approved; implemented and covered by automated Godot checks, with human review and physical-device parity pending (see PHASETASK P02-T15–T22). Design rules below are unchanged. This adds a distinct optional movement mechanic to the existing measured run/jump baseline; it does not revise the historical P02-T09/T10 evidence. The extension is Should scope, scheduled after P03, and must not delay P04 or automatically become a required October submission feature. Decide whether to include it before the October 21 feature freeze.

While airborne and touching an eligible solid side, a chicken slides down with a configurable cap on downward speed; wall contact never pulls the chicken upward. Holding toward the wall is not required. Base and player-built solid sides qualify; moving solids qualify only while actual contact remains valid. One-way platform sides and undersides, pass-through chicken bodies and arena containment boundaries do not qualify. A fresh jump press kicks the chicken away; start with configurable prototype candidates of 240 wu/s horizontally and −520 wu/s vertically. Steering remains available immediately under ordinary air control. One kick is allowed per wall contact; the chicken must separate and make fresh contact before another. Holding jump and operating-system repeats do not repeat a kick; buffered input is consumed once.

Terminal, opening-freeze, capture and external-force precedence remain unchanged. External launches preempt wall actions and clear wall eligibility/input. Pause freezes the action; phase changes, reset and reload clear stale wall contact or buffered input. Chicken bodies remain pass-through. Wall contact is not grounded support and never qualifies for Rising wave. Slide cap, grace/separation thresholds and impulse values remain provisional and require real physics trials and human feel review. Dash, double jump and drop-through remain out of scope. See [PRD REQ-MOVE-004](PRD.md#req-move-004--slide-on-eligible-walls-and-kick-away-with-a-fresh-jump-press) and [PHASETASK P02-T15–T22](PHASETASK.md#p02-wall-movement-extension--approved-unimplemented-should-scope).
### Sneak and glide — 2026-10-14 extension

**Status — October 14, 2026:** requested by the user and implemented in the main game; automated Godot checks pass; human feel review and physical-device checks are pending (see [PHASETASK P02-T23–T26](PHASETASK.md#p02-sneak-glide-64-wu-grid-and-stage-blocks-extension--implemented-should-scope)). Should scope, like wall movement.

- **Sneak:** hold down (S / Down / d-pad down) while standing to crouch into a 1×1 body (56×56). A sneaking chicken cannot walk or jump. Releasing stands back up only when there is headroom; under a one-tile ceiling the chicken stays small instead of clipping. Sneak ends on launch, capture, freeze, elimination and phase change (when there is room). **Hitbox (2026-10-16, user request):** while sneaking, the chicken's hitbox is that one-tile body for everything. Traps, beams, slippers, block kill and stun hitboxes, tagging, and the "a chicken is too close" building check all use it. A crouching chicken can duck under a head-height hazard, and a piece may be placed on the tile just above it, where it then stays small.
- **Glide:** hold jump while falling to cap descent at a configurable 180 wu/s; steering is unchanged. Tapping still jumps normally, a fresh press on a wall still wall-jumps, and wall slide wins over glide while touching an eligible wall.
- Wall slide and wall jump are the existing approved extension below (rescaled to the 64 px grid).

### Per-pose hitboxes — 2026-10-24 (user request)

**Status — October 24, 2026:** requested by the user and implemented; automated Godot checks pass (P02 movement and wall, P03 stage, blocks, sneak hitbox). Human feel review and physical-device checks are pending. Checked on Godot 4.6 in a throwaway copy, because the installed engines here are 4.5.1 and 4.6 while the project targets 4.7.

The chicken carries one authored hitbox per pose and enables exactly one at a time. The controller's state picks it, and the sprite animator picks its animation from that same state, so the pose on screen and the body in the physics world cannot disagree. All three share a feet line, so a swap never moves the chicken.

| Pose | Hitbox | Size (wu) |
| --- | --- | --- |
| Standing, running, grounded | `MainHitbox` | 56 × 120 |
| Airborne (jump, fall, glide, wall slide) | `JumpHitbox` | 56 × 56 |
| Sneaking | `SneakHitbox` | 56 × 56 |

- The swap is **physics only**. The gameplay hitbox that traps, beams, slippers, block kill/stun hitboxes, tagging and the "a chicken is too close" building check read is still the tuning-derived body described under Sneak above, and it is unchanged while airborne.
- **Wall-slide reach narrows (owner decision, 2026-10-24).** The airborne body is one tile tall at the feet, so a wall slide only catches a wall beside that tile. A chicken can no longer slide on a block level with its standing head but more than one tile above its feet. This is a deliberate narrowing of [Wall slide and wall jump](#wall-slide-and-wall-jump--approved-extension), chosen over keeping the previous reach; it is not a bug. Feel review should confirm it before the freeze.
- Growing back to the standing body needs headroom, reusing the sneak check: a chicken that lands in a one-tile gap keeps the small body until it fits.
- The tuning body size stays authoritative — the controller resizes the authored standing and sneak shapes to `body_width_wu` / `body_height_wu` / `sneak_height_wu` on ready. `JumpHitbox` has no gameplay counterpart, so its authored size is left alone and only its feet are pinned to the standing feet line.

### Chicken animation states — 2026-10-24 (user request)

**Status — October 24, 2026:** requested by the user and implemented; `run_blocks_tests` covers every chain below (120 checks). Human feel review is pending, and one open concern is recorded at the end.

`ChickenSpriteAnimator` calls `play()` once per pose change, never per frame, so each animation's own loop flag in the SpriteFrames decides whether it repeats. Left/right of running and of the rising `jump` comes from the movement key the controller accepted (`ChickenController.facing_input`), so a chicken sliding on ice reads as idle rather than running. **Revised the same day at the user's request:** falling, gliding and landing follow where the chicken is actually moving (`velocity.x`, with a 40 wu/s deadzone that plays the sideless pose), not the key, so a chicken that lets go of left mid-air while still drifting left keeps falling, gliding and landing facing left. The landing side is the one it was moving on its last airborne frame.

**Per-colour art, no tint (2026-10-24, user request):** `scenes/characters/chicken.tscn` holds one `ChickenSpriteAnimator` per seat colour (pink, yellow, cyan, green) under an `Animations` node, each with its own pre-coloured SpriteFrames. Each sprite has a `skin_color` (the matching `PlayerSeatRegistry.COLORS` entry) and only the one nearest the chicken's `marker_color` is shown; the old grey-art seat tint (`seat_tint`, `tint_strength`) is gone. The results chart reads the same SpriteFrames through `ChickenSpriteAnimator.frames_for_color()`, and an open Lobby slot shows its own colour's chicken faded instead of a grey one. Eliminated chickens keep their own colour (the grey art used to be tinted white). The stun brightness pulse is unchanged and is the only modulate left on the sprite. The number/shape marker above the head remains the second identifier.

Priority order, highest first: `dead` → `stun` → sneak → wall slide → airborne → landing / stand-up → run / `idle`.

| Trigger | Pose |
| --- | --- |
| No other state applies | `idle` |
| Jump, while rising | `jump`, `jump_left`, `jump_right` |
| Falling (including walking off a ledge), sided by horizontal motion | `jump*_falling` |
| Holding jump while falling, sided by horizontal motion | `jump*_gliding` |
| Touching the ground, sided by the motion just before | `jump*_landing` |
| On the ground with a direction held | `run_left`, `run_right` |
| Pressing down | `sneak`, then `sneak_hold` while held |
| Releasing down | `sneak_stand` |
| Stunned | `stun` |
| Held against a wall | `wall_slide_left`, `wall_slide_right` |

Three of these are transitions that must be seen in full before the next pose starts, gated on `animation_finished`: `sneak` → `sneak_hold`, `sneak_stand` → idle/run, and `jump*_landing` → idle/run. Each is authored non-looping so it ends on its own; a pose that loops, or is missing from the sheet, is never waited for, so a mis-set loop flag cannot freeze the chicken. A fresh jump cuts a landing or stand-up short, because the airborne branch is reached first.

**Open — `dead` is authored looping.** The user's three `downdead_animation_front` frames are a collapse that settles on an X-eyes sitting pose, but the animation is flagged `loop = 1`, so an eliminated chicken replays the collapse every 0.6 s instead of staying down. `loop = 0` would hold the final frame. Left as authored, since the owner keeps the loop flags.

**Open — responsiveness cost of the one-shots.** As authored, `jump*_landing` runs 0.80 s and `sneak_stand` 0.60 s (4 and 3 frames at 5 fps), and both block `run_left` / `run_right`. A player who lands already holding a direction therefore sees the landing animation for 0.8 s before the run starts. This is the behaviour the owner asked for ("always play after hitting the ground"), but it has not had a feel review. If it reads as sluggish, the fix is either shorter landing frames or letting a held direction cut the landing short.

### Cannon art and firing animation — 2026-10-24 (user request)

**Status — October 24, 2026:** art supplied by the user, wired by Claude Code; `run_blocks_tests` covers it (122 checks). Human visual review is pending.

The Cannon's placeholder polygons are replaced by the bamboo cannon sprite (`assets/tiles/cannon sprites/`, 9 frames plus a wheel). Its `shoot` animation is driven from the launcher's own state rather than on a timer: it starts when the piece enters its 0.8 s telegraph, so the wind-up frames run while the shot is charging and the muzzle-blast frame is on screen as the ball spawns. It then hands back to the one-frame `reloading` rest pose. `shoot` is authored non-looping so `animation_finished` can make that handover; `StageBlock` leaves a looping or missing pose alone rather than restarting it, so a mis-set flag cannot strand the barrel mid-recoil. A round reset returns it to rest.

The art is drawn facing left while the projectile path runs right, so the sprite is flipped in the scene (`flip_h`) rather than re-exported; the firing direction, lane region and all four rotations are unchanged. **2026-10-24:** the owner removed `flip_h` from the barrel sprite on purpose, so the art is now drawn as authored; the test no longer asserts the flip. Any block may now carry an `AnimatedSprite2D` under its `Visual` node and get the same treatment.

- **Solid shrank with the new art (user authoring, 2026-10-24).** The Cannon's `Solid` shape went from the full 64x64 cell to 64x46 offset 9 wu down, so its derived SOLID region is now the bottom 72% of the cell (`(0, 0.28) size (1.0, 0.72)`): the top ~18 wu is passable and a chicken standing on it rests that much lower. The placement footprint is still 1x1, since that comes from `placement_size`, not the shape. Confirm this is the intended silhouette during visual review.
- **Open — the blast frame trails the ball by one animation frame.** Measured: the ball spawns while the barrel is on frame 3, the last wind-up frame, and the blast (frame 4) appears 0.2 s later, because 4 frames at 5 fps exactly fills the 0.8 s telegraph and the animation starts a render frame after the state change. Raising `shoot`'s speed to 6 fps would put the shot inside frame 4 instead; left as authored pending the owner's call.

### Map terrains and water — 2026-10-22 (user request)

**Status — October 22, 2026:** requested by the user and implemented; automated Godot checks pass (maps, P02 movement, P03 stage, blocks and tutorial suites). Human feel review, water art and physical-device checks are pending. No shipped map paints water yet.

A map scene's `Blocks` layer no longer carries meaning in its atlas coordinates. What a painted cell does comes from its **terrain** in terrain set 0 of `assets/tiles/map_tiles_tileset.tres`, so the art can be repainted without changing gameplay:

| Terrain | Name | Behavior |
|---|---|---|
| 1st | Grass | Solid base geometry; chickens may wall-slide and wall-kick on its sides. |
| 2nd | Stone | Solid base geometry that is **not climbable** — no wall slide, no wall kick. |
| 3rd | Water | **Not solid.** Chickens float in it. |

- **Floating:** a chicken whose centre enters a water volume has its fall capped at the sink cap, is then carried up by buoyancy, and settles bobbing at the waterline rather than being thrown out of the pool. Jump is an upward stroke; horizontal speed is capped while submerged. Wall slide, wall kick, coyote time and glide do not apply in water — the chicken is swimming, not standing on anything.
- Water is drawn by the map's own tiles and generates no collision, so it never blocks a build and never counts as a support surface.
- Tunables live in `GameplayTuning` (`water_enabled`, `water_sink_cap_wu_s`, `water_buoyancy_wu_s2`, `water_stroke_wu_s`, `water_move_wu_s`) and are distance-scaled with the grid. **PROTOTYPE — UNMEASURED.**
- Water does not yet interact with eliminations, Lagsanay tagging or Barya; a chicken in water is simply floating. Drowning, currents and water-specific scoring are **not** approved by this entry.

### Stage blocks — 2026-10-14

Each block is its own editable scene in `tilaok!/scenes/blocks/` and enters the Pugad pool like any other construction item.

| Block | Size (tiles) | Behavior |
|---|---|---|
| Solid Block | 3x1 (rotates to 1x3) | No gravity; wall-slide eligible. |
| Wood Box | 2x2 | Falls under gravity; a grounded chicken walking into its side pushes it; chickens can stand on it; returns to its placed spot at every Place/Play start. |
| Collapsing Block | 1x1 | No gravity. Standing on it or wall-sliding on it starts a 2 s shake; then it drops away (no collision) and returns about 3 s later once no chicken overlaps it. Restored at every Place/Play start. |

The Collapsing Block overlaps the proposed *Marupok na Papag* expansion idea (2×1/3×1); it is recorded as a separate 1×1 family and does not approve or replace that proposal.

### Promoted expansion obstacles — 2026-10-16 (user decision)

Three P19 designs were promoted into the main game as block scenes with DEBUG placeholder art ([evidence](evidence/p19_promoted/README.md)):

| Obstacle | Sizes (tiles) | Behavior | Modes |
|---|---|---|---|
| Hagdan ng Bahay (house steps) | 2x2, 3x3 | Solid steps rising toward one side; four rotations. Standable terrain; removable by Walis and explosives. | Karera, Lagsanay (Kangaroo pending review) |
| Tinik-Tinik Strip (soft burrs) | 3x1, 4x1 | A thin, low kill strip with no solid body; four rotations. Touching it is an elimination credited to the placer (Patibong). | Karera (Lagsanay/Kangaroo after the wholesome-art review) |
| Yelo ng Sorbetero (ice) | 3x1, 4x1 | A solid slab you can stand on. On it a chicken brakes and turns slowly and runs up to 25% faster, so it slides further. Never eliminates, no credit. | Karera, Lagsanay (Kangaroo pending review) |

### Block scenes, Spikes, Cannon and stun — 2026-10-14 (user request)

- **Every placeable item is a scene** in `tilaok!/scenes/blocks/` with a BlockData customization node (placement box size, solid hitbox, kill/stun hitboxes, anchor/gravity, effects, special). A scene dropped into that folder joins the selection pool automatically. See [ITEMS "Block scenes"](ITEMS.md#block-scenes--how-every-placeable-item-is-authored-2026-10-14).
- **Anchor/Gravity:** Anchored blocks stay in their tile; Heavy blocks fall but cannot be pushed; Light blocks fall and are pushed by a grounded chicken (the Wood Box). Moving blocks return to their placed spot at every Place/Play start.
- **Spikes (1×1, trap):** solid bottom half; the points on top eliminate a chicken that touches them. Rotatable, so ceiling and wall spikes are possible (the solid half can be stood on).
- **Cannon (1×1, trap):** solid barrel that charges and fires a ball along its path (5 tiles by default) every 2 s; the ball eliminates on touch and is stopped by solids. Rotatable in four directions.
- **Kill** hitboxes eliminate (soft, comedic defeat) and credit the placer with Patibong under the existing scoring rules; self-kills earn nothing.
- **Stun** hitboxes: the chicken is knocked away from the hitbox and its controls freeze for the block's stun time (default 1 s). A short immunity (0.5 s) follows so stuns cannot chain-lock a player. A stun is a setup effect: never credited, never an elimination.
- **Death sprite:** an eliminated chicken shows the dedicated death pose (sheet row 2, column 4). It keeps falling until it lands (2026-10-15, user request) instead of hanging where it died; it has no control and no further effect on blocks or hazards.

### Explosives and the Pugad pick lock — 2026-10-15 (user request)

- **Bomb (2×2), Dynamite (3×3) and Nuke (4×4)** are one-use explosive eggs. Placed in the Place phase, each clears every player-built piece inside its area when Place resolves, then a short blast shows. That includes pieces another player places in the same Place phase (2026-10-16, user request): such a placement is blown up and does not appear, and its player sees "Blown up by P#'s Bomb". Walis Cleanup keeps sparing same-phase pieces. The base stage, spawn and flag are never affected, and removed pieces never return. The Nuke is rarer in the egg pool (prototype weights 30 / 20 / 8).
- **Pugad pick lock:** once a player has claimed an egg, their selection is locked for the rest of that Pugad; only players without an egg can keep browsing.

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
- **Guided first match (owner decision, 2026-10-14):** the guided first match uses a tutorial-only stage layout in which building is required to reach the flag: the flag ledge is raised 32 wu above the highest no-build jump, so a correctly placed piece (Kaing 1x1, Kaing 2x3 or Tulay 4x1) is needed. Every round and every mode in that match (Karera, Lagsanay, sudden death) plays on that same stage plus everything players build; no mode swaps or alters the map. Normal matches keep the default stage unchanged, and the next match after the tutorial match starts fresh on the default layout. Skip (Pause menu) and replay (Library > How to Play) are session-only; nothing is saved and there is no tutorial bonus. See [UI_TUTORIAL.md](UI_TUTORIAL.md) and [STAGE_AND_PLACEMENT.md](STAGE_AND_PLACEMENT.md#tutorial-stage-layout--2026-10-14).
- **Default route (owner decision, 2026-10-15):** the scheduled full match (Karera / Lagsanay / Kangaroo Mains, the three verified Twist stacks, sudden death and final results) is the default player route from the Title. The P07 first-playable build stays available behind `--match-route=first_playable` for its human gate. No scoring, timing or rule value changes.
- **UI:** simple and easy to navigate: title screen, join/lobby (pick color), the match, and a results screen. A local win tally on the results screen is optional.
- **Results chart presentation (2026-10-15):** round and match results may show each joined player as a stable seat-order column on a shared vertical score axis, with a shared baseline, guides and the exact configured target line. Use integer eighth-point units; the display scale grows above the target without clipping, and no score is inflated to fill visual space. Newly committed award segments may reveal in calculator order while the chicken marker remains anchored to the stack; prior totals without retained award provenance stay neutral. Pair every award color with a name and glyph, and keep player number/shape as identity cues beside color. A Last Cluck winner is identified with a callout even when tied players have equal score heights. The independent Normal / Reduced / Off result-reveal setting does not affect Screen shake. This is presentation only: §5 scoring values, suppression, placements and winner rules do not change. Current colors and placeholder chicken animation are provisional; final art and readability review remain team work.
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

## 13. P09 sudden-death terrain policy — October 14, 2026

Lagsanay sudden death uses the same persistent stage and construction that remained after the last Karera round. Construction already removed by a player remains removed; do not restore it when the tiebreak starts. Reset moving items through the existing Play-start reset contract, and clear transient items, captures and other attempt-only state before Lagsanay begins. Do not run another Pugad/Place phase for sudden death. After a match ends, Replay starts a fresh match on the same room while clearing construction, match scores and match state, retaining the original seats/devices, and taking a new configuration snapshot. This is the P09 development-route terrain contract; it does not define P12 scheduling or stacks.
