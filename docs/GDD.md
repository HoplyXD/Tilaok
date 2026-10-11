# Tilaok! — Game Design Document

_Last updated: 2026-10-11_

## 1. Pitch
A 2–4 player competitive party platformer. Each round, players pick eggs from the **Pugad** (nest), place what hatches on a shared stage, then play. Most rounds are a race to the flag. Every 4th round, a **traditional Filipino game event** takes over the same stage and changes the rules entirely.

**One-liner:** Build the level, survive the level, and every few rounds a laro ng lahi takes over.

## 2. Concept: Sabong, Reimagined
All characters are chickens. Instead of the traditional sabong where roosters fight, Tilaok!'s chickens compete through platforming and Filipino games. It turns a gambling-associated tradition into a wholesome, skill-based competition.

## 3. Core Loop (every round)
1. **Pugad:** a nest appears holding a random set of eggs (placeholder: players + 2); each player picks one and it hatches into an item.
   - Each egg is see-through with its **item visible inside**, so players pick on purpose. Grabbing an egg cracks it open and the item pops out into your pointer.
   - Picking is **simultaneous**: first to grab an egg gets it. ~8s to pick; leftover eggs are assigned at random.
2. **Place:** players place their item anywhere on the shared stage.
   - Placing is **simultaneous**, with grid snap; you can't place on a player or the flag.
   - Placement controls: **move**, **rotate** (one button) and **confirm** (one button). A ghost shows green/red for a valid/invalid spot.
   - ~15s to place. If time runs out, the item auto-places at the pointer if the spot is valid, otherwise it is discarded.
   - Nothing is active during Place. When Play begins, every placed item resets to its starting position/state.
   - Pointers are visible to everyone, but nothing announces a placed Barya, so it can be tucked into the clutter.
3. **Play:** either
   - a **Race Round**: run from start to the flag, or
   - an **Event Round**: play the active laro ng lahi on the same stage.

The stage **persists and grows** across rounds. Pugad and building continue during event rounds too, so traps become terrain for events.

**Starting stage:** a hand-built base layout with a spawn on the left, a flag on the right, a solid floor and a few platforms, so round 1 already has something to run across. Base stage pieces, the spawn and the flag are indestructible. (Exact layout to be designed and playtested.)

**Round end (race rounds):** dying puts you out for the rest of the round (you can spectate and return next round). The round ends when every player has either reached the flag or died, so there can be one winner, several, or none. Once the first player reaches the flag, a ~15s countdown starts to prevent stalling. A hard cap of ~60s also ends the round; anyone not at the flag by then counts as failed. Dead players get a **cheer button** that triggers crowd reactions.

**Event cadence:** every **4th round** (4, 8, 12). The next event is **announced during the Pugad phase of the round before**, so players can build with it in mind. Until a second event exists, every event round is Lagsanay.

## 4. Events (Laro ng Lahi)
Each event is its own mini game mode with its own win condition, played on the current stage. Placed traps stay active and can still kill. The flag is hidden in event rounds (its platform stays).

**"Alam mo ba?" card:** before each event, a short card explains the real traditional game (what it is, where it's from, how it's played in real life) so the game communicates the theme, not just uses it.

### Lagsanay (locked)
Ilonggo for tag (Tagalog: *habulan* / *taya-tayaan*). Tag + hot potato.
- A random player becomes the **taya**, with a visible countdown over their head.
- Touching another player passes the taya.
- When the timer hits zero, the current taya is eliminated.
- A new random player becomes taya; repeat until one survives.
- Tuning ideas:
  - ~1s pass-back immunity (no instant re-tag)
  - Taya moves slightly faster
  - Timer shortens as players are eliminated (e.g., 15s → 10s → 7s)
- **Trap kills:** a trap death is an elimination, and the dead player takes the lowest remaining placement slot. If the taya is killed, a new taya is picked from the survivors.
- **Simultaneous eliminations** share a placement, and the points are averaged.
- The Lagsanay floor is solid (no bottomless pits), so a fall never eliminates anyone.
- **Start:** everyone spawns at the same spawn point. The first taya is frozen for ~3s, and their countdown only starts after that, so the others can run.

### Other events
| Event | Idea | Status |
|---|---|---|
| Langit-Lupa | The floor (lupa) rises; stay high until the timer ends. | **Second event to build** |
| Luksong Tinik | Spike waves sweep the stage; survive them all. | Optional third |
| Agawan Buko | Coconuts drop; most held when time runs out wins. Works at any player count. | Backlog |
| Agawan Base | Team capture-the-flag. | Cut (team-based, breaks at 3 players) |
| Patintero / Tubigan | Guards patrol lines. | Cut |

_Naming: prefer local Hiligaynon names where they exist. Verify all names with a native speaker before finalizing._

## 5. Scoring (all rounds)
Event rounds reuse the **same point types**, re-mapped to each event's objective, so players learn one system. Values are our own (multiples of 0.25) and are tuned in playtesting.

### Point types
| Type | Name | Points | Race round | Event round |
|---|---|---|---|---|
| Goal | **Tapos** | 1.0 | Reach the flag alive | Complete the event's objective |
| First | **Una** | +0.25 | First to reach the flag | Best performer in the event |
| Solo | **Bayani** | +0.5 | Only player to reach the flag (3–4 players) | Only player to complete the objective |
| Trap | **Patibong** | +0.25 each | Each player killed by a trap you placed, as long as at least one player reached the flag that round (you score even if you lost). Dying to your own trap scores nothing | Same |
| Comeback | **Bawi** | +0.75 | Underdog reaches the flag | Underdog completes the objective / places 1st in Lagsanay |
| Coin | **Barya** | +0.5 | Reach the flag alive carrying the Barya | Race rounds only for now |

**Underdog:** a player who is 3+ points behind the leader at the start of the round.

### Too easy / too hard (all rounds except Lagsanay)
- Everyone gets Tapos → **no points** that round (except Barya, which is earned by reaching the flag, so it only matters here).
- Nobody gets Tapos → **no points** that round, including Patibong.
- This forces players to build stages that are hard but beatable.
- **2-player matches:** this rule is waived. Reaching the goal scores Tapos for each player, plus Una for the first, and Bayani if only one finishes.

### Event mapping
| Event | Goal = | First = |
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
- Runs until one survivor remains (no fixed timer needed).

### Barya (coin)
- Barya is an **item that sometimes appears among the Pugad eggs** (about a 1-in-3 chance per round, replacing one egg). Whoever picks it places it, so they choose how hard it is to reach.
- Touch it to pick it up; it follows you visibly. If you die, you drop it where you died and anyone can grab it.
- At most one per round, and it is removed at round end (unlike other items, it does not persist).
- It still pays out in a "too easy / too hard" round.
- Priority: **Should**. Build after the base loop and scoring work; cut first if the schedule slips.

### Match settings
- **First to 10 points**, or the highest score after **round 12**, whichever comes first (keeps matches time-bounded). This is checked at the **end of a round**; if more than one player passes 10 in the same round, the higher total wins. An equal total goes to Sudden Death.
- If players tie at the end → **Sudden Death**: a Lagsanay between the tied players, which always produces exactly one winner.
- A results screen shows a **local win tally** that persists between matches (leaderboard).

## 6. Characters
- All players are **chickens** with different skins/colors (black, white, orange, etc.).
- Ideas: Philippine native-chicken looks; accessories like salakot, bandana, tsinelas for readability.
- **Accessibility:** each chicken has a second identifier besides color (a number or shape marker above the head), and UI colors must be readable for colorblind players.

## 7. Items & Traps (brainstorm)
Items arrive as eggs in the Pugad (item visible inside) and hatch when picked. Filipino-themed obstacles:
- Tsinelas launcher
- Rolling niyog (coconut)
- Sampayan (clothesline)
- Kawali of hot oil
- Charging tricycle
- Banana-peel slip
- **Bomb:** destroys player-placed items in a radius (any player's); this is the stage-clutter control. The starting stage, floor, spawn and flag are indestructible. A hard item cap is a playtesting question.
- Plus basics: platforms and springs
- _Full trap list: not decided yet; more items to be added later._

## 8. Platform & Multiplayer
- Engine: **Godot 4** (free and open source, so no license is needed to play or build).
- PC (free to play, no license needed).
- **Local multiplayer** (2–4 players, **gamepads first**, shared keyboard as fallback). Online play is out of scope for the deadline.
- **Controls:** run and jump only (no extra abilities for now).
- **Player collision:** none in race rounds (chickens pass through each other). Lagsanay enables player contact for tagging; future modes can define their own.
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
- [x] Event cadence: every 4th round, announced a round ahead
- [x] Box/point naming and values (see §5; verify spelling with a native speaker)
- [x] Coin: Barya, placeable item
- [x] Death and race-round end rules (see §3)
- [x] Stage-clutter control: bomb item
- [x] Sudden Death: Lagsanay between the tied players
- [x] Art: 2D (exact style undecided)
- [ ] Final trap list (later); Pugad egg count/weighting (placeholder: players + 2)
- [ ] Audio direction
- [ ] Team size and roles (later)
