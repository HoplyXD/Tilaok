# Tilaok! — Game Design Document

_Last updated: 2026-10-11_

## 1. Pitch
A 2–4 player competitive party platformer. Each round, players pick eggs from the **Pugad** (nest), place what hatches on a shared stage, then play. Most rounds are a race to the flag. Every 4th round, a **traditional Filipino game event** takes over the same stage and changes the rules entirely.

**One-liner:** Build the level, survive the level, and every few rounds a laro ng lahi takes over.

## 2. Concept: Sabong, Reimagined
All characters are chickens. Instead of the traditional sabong where roosters fight, Tilaok!'s chickens compete through platforming and Filipino games. It turns a gambling-associated tradition into a wholesome, skill-based competition.

## 3. Core Loop (every round)
1. **Pugad:** a nest appears holding a random set of eggs (placeholder: players + 2); each player picks one and it hatches into an item.
2. **Place:** players place their item anywhere on the shared stage.
3. **Play:** either
   - a **Race Round**: run from start to the flag, or
   - an **Event Round**: play the active laro ng lahi on the same stage.

The stage **persists and grows** across rounds. Pugad and building continue during event rounds too, so traps become terrain for events.

**Round end (race rounds):** dying puts you out for the rest of the round (you can spectate and return next round). The round ends when every player has either reached the flag or died, so there can be one winner, several, or none. Once the first player reaches the flag, a ~15s countdown starts to prevent stalling.

**Event cadence:** every **4th round** (4, 8, 12). The next event is **announced during the Pugad phase of the round before**, so players can build with it in mind. Until a second event exists, every event round is Lagsanay.

## 4. Events (Laro ng Lahi)
Each event is its own mini game mode with its own win condition, played on the current stage. Placed traps stay active and can still kill.

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
| Trap | **Patibong** | +0.25 each | Each player killed by a trap you placed (not your own) | Same |
| Comeback | **Bawi** | +0.75 | Underdog reaches the flag | Underdog completes the objective / places 1st in Lagsanay |
| Coin | **Barya** | +0.5 | Reach the flag alive carrying the Barya | Race rounds only for now |

**Underdog:** a player who is 3+ points behind the leader at the start of the round.

### Too easy / too hard (all rounds except Lagsanay)
- Everyone gets Tapos → **no points** that round (except Barya).
- Nobody gets Tapos → **no points** that round (except Barya).
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
- **First to 10 points**, or the highest score after **round 12**, whichever comes first (keeps matches time-bounded).
- If players tie at the end → **Sudden Death**: a Lagsanay between the tied players, which always produces exactly one winner.
- A results screen shows a **local win tally** that persists between matches (leaderboard).

## 6. Characters
- All players are **chickens** with different skins/colors (black, white, orange, etc.).
- Ideas: Philippine native-chicken looks; accessories like salakot, bandana, tsinelas for readability.

## 7. Items & Traps (brainstorm)
Items arrive as eggs in the Pugad and hatch when picked. Filipino-themed obstacles:
- Tsinelas launcher
- Rolling niyog (coconut)
- Sampayan (clothesline)
- Kawali of hot oil
- Charging tricycle
- Banana-peel slip
- **Bomb:** destroys items in a radius; this is the stage-clutter control (a hard item cap is a playtesting question).
- Plus basics: platforms and springs
- _Full trap list: not decided yet; more items to be added later._

## 8. Platform & Multiplayer
- Engine: **Godot 4** (free and open source, so no license is needed to play or build).
- PC (free to play, no license needed).
- **Local multiplayer** (2–4 players, **gamepads first**, shared keyboard as fallback). Online play is out of scope for the deadline.

## 9. Open Questions
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
