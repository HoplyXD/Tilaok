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

## 5. Scoring (unified, all rounds)
| Result | Points |
|---|---|
| 1st | 3 |
| 2nd | 2 |
| 3rd | 1 |
| 4th / didn't finish / first eliminated | 0 |
| Each kill by your placed trap | +1 |

- **Race rounds:** placement = finish order at the flag.
- **Event rounds:** placement = survival order. **Placement points are doubled** (6/4/2/0). Trap kills stay +1.
- **Race-round balance rules:**
  - Everyone finishes → no placement points (trap kills still count).
  - Nobody finishes → no placement points (trap kills still count).
  - Only one finisher → **Solo bonus +1**.
- **Win condition:** first player to **25 points** (~10-minute match).
- Balance watch: if trap-kill farming dominates events, cap at +2 per round.

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
