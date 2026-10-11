# Tilaok! — Game Design Document

_Last updated: 2026-10-11_

## 1. Pitch
A 2–4 player competitive party platformer. Each round, players pick items from a Party Box, place them on a shared stage, then play. Most rounds are a race to the flag. Every few rounds, a **traditional Filipino game event** takes over the same stage and changes the rules entirely.

**One-liner:** Build the level, survive the level, and every few rounds a laro ng lahi takes over.

## 2. Concept: Sabong, Reimagined
All characters are chickens. Instead of the traditional sabong where roosters fight, Tilaok!'s chickens compete through platforming and Filipino games. It turns a gambling-associated tradition into a wholesome, skill-based competition.

## 3. Core Loop (every round)
1. **Party Box:** a random set of items appears; each player picks one.
2. **Place:** players place their item anywhere on the shared stage.
3. **Play:** either
   - a **Race Round**: run from start to the flag, or
   - an **Event Round**: play the active laro ng lahi on the same stage.

The stage **persists and grows** across rounds. Party Box and building continue during event rounds too, so traps become terrain for events.

The next event is **announced one round ahead** (during the Party Box phase), so players can build with it in mind.

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

### Candidate events (not final)
| Event | Idea |
|---|---|
| Langit-Lupa | The floor (lupa) becomes deadly and/or rises; stay high. Last one standing wins. |
| Agawan Base | Steal the other side's flag and bring it home. |
| Patintero / Tubigan | Guard(s) patrol lines; cross the stage without getting tagged. |
| Luksong Tinik | Spike waves sweep the stage; survive the most waves. |
| Agawan Buko | Coconuts drop; most held when time runs out wins. |

_Naming: prefer local Hiligaynon names where they exist. Verify names before finalizing._

## 5. Scoring (UCH-style, all rounds)
Scoring follows Ultimate Chicken Horse's default point values (in 1/5-point units). Event rounds reuse the **same point types**, re-mapped to each event's objective, so players learn one system.

### Point types
| Type | Points | Race round | Event round |
|---|---|---|---|
| **Goal** | 1.0 | Reach the flag alive | Complete the event's objective (see below) |
| **First** | +0.2 | First to reach the flag | Best performer in the event (see below) |
| **Solo** | +0.6 | Only player to reach the flag (3–4 players) | Only player to complete the objective |
| **Trap** | +0.2 each | Each player killed by a trap you placed | Same |
| **Comeback** | +0.8 | Reach the goal as an Underdog (missed goal 2+ rounds while others scored) | Same, using event Goals |
| **Coin** | +0.6 | Reach the flag carrying the coin | Optional event pickup (if the event uses one) |

### Too easy / too hard (all rounds)
- Everyone gets Goal → **no points** that round (except Coin).
- Nobody gets Goal → **no points** that round (except Coin).
- This forces players to build stages that are hard but beatable, in events too.

### Event mapping
| Event | Goal = | First = |
|---|---|---|
| **Lagsanay** | Survive until the event timer ends (not eliminated by the bomb or traps) | Player who held the taya the shortest total time |
| Langit-Lupa | Still standing when the timer ends | Highest position at the end |
| Agawan Base | Your team scores a capture | Player who carried the flag in |
| Patintero / Tubigan | Cross the stage without being tagged | First to cross |
| Luksong Tinik | Survive all spike waves | Last hit / fewest close calls (TBD) |
| Agawan Buko | Holding at least 1 coconut at the end | Most coconuts |

**Lagsanay adjustment:** to make "too easy / too hard" possible and avoid always ending with one survivor, the event runs on a fixed timer (~45s) with a set number of bomb detonations (e.g., players − 2). Survivors at the timer = Goal.

### Match settings
- **Points to win: 10** (UCH lets this be set from 3–20). Tune in playtesting for a ~10-minute match.
- If players tie at the limit → Sudden Death round.
- Optional later: Second/Third placement points (UCH has these, default 0).

## 6. Characters
- All players are **chickens** with different skins/colors (black, white, orange, etc.).
- Ideas: Philippine native-chicken looks; accessories like salakot, bandana, tsinelas for readability.

## 7. Items & Traps (brainstorm)
Filipino-themed obstacles:
- Tsinelas launcher
- Rolling niyog (coconut)
- Sampayan (clothesline)
- Kawali of hot oil
- Charging tricycle
- Banana-peel slip
- Plus basics: platforms, springs, and an eraser/bomb item to keep the stage playable

## 8. Platform & Multiplayer
- PC (free to play, no license needed).
- **Local multiplayer** (2–4 players, controllers or shared keyboard). Online play is out of scope for the deadline.

## 9. Open Questions
- [ ] Engine choice
- [ ] Team size and roles
- [ ] How often events trigger (every N rounds vs random, telegraphed)
- [ ] Final trap list and Party Box rules
- [ ] Stage-clutter control (eraser item vs placement cap)
- [ ] Art style and audio direction
