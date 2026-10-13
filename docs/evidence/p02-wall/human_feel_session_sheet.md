# Wall movement — human feel/balance session sheet (P02-T22)

**Status:** BLOCKED (human review). This sheet is a blank procedure; nothing here is a result. Synthetic tests, calculations and agent-authored runs do not substitute for it.

## Header (fill in)

| Field | Value |
|---|---|
| Reviewer name(s) | |
| Date / build revision | |
| Engine | Godot 4.7.2.stable |
| Profile / seed | `movement_room` / 12345 |
| Player count | |
| Devices (model, K1/K2/gamepad) | |
| Rooms | P02 movement room → "Wall fixtures (debug) on/off"; P03 Graybox Arena → "Wall fixtures" |
| Wall movement setting | `wall_movement_enabled` set by the room buttons (default resource value is false) |

## Procedure (about 25 min, two or more players, rotate people and devices)

1. **Discoverability (3 min).** Without explanation, ask each player to leave the floor and reach the high platform using only the labeled fixtures. Record what they tried and whether they found slide and kick.
2. **Slide readability (4 min).** Drop onto the slab, shaft and excluded wall. Can they tell WALL OK from NO WALL? Is the slide speed legible at minimum zoom? Is the debug bar visible?
3. **Kick response (5 min).** Ten kicks off each side of the slab. Count misses; separate input mistakes from timing/feel complaints.
4. **Repeat rule (4 min).** Try to chain kicks on one wall, then in the shaft. Can they explain why a second kick sometimes does nothing?
5. **Shortcuts and stalling (5 min).** Try to bypass the base route and stall near walls. Record each new shortcut with start/end coordinates.
6. **Freeze and multiplayer overlap (2 min).** Two players near one wall: any push, steal or confusion?
7. **Free play (2 min).**

## Record

| # | Case | Expected | Observed | Pass/Fail/Unclear | Notes (verbatim feedback) |
|---|---|---|---|---|---|
| 1 | Slide cap legible | slow controlled descent | | | |
| 2 | Kick away (left/right) | one kick, clear direction | | | |
| 3 | Held jump | no repeat | | | |
| 4 | Same-wall repeat | blocked until separation | | | |
| 5 | Shaft climb | climbable? how fast? | | | |
| 6 | Excluded wall | no slide/kick | | | |
| 7 | New shortcut found | recorded, not auto-rejected | | | |
| 8 | Wall stalling | none harmful | | | |

## Decisions the reviewer should inform

- Slide cap 120 wu/s: keep / change to ___ (range 80–180).
- Kick 240/−520: keep / change to ___ (ranges 180–300, −440…−600).
- Grace 0.08 s: keep / change / remove.
- Separation 8 wu: keep / change (4–16).
- Is shaft climbing acceptable for Lagsanay and event stacks?
- **Keep / defer for the October 21 freeze: PENDING — producer/team decision, not made by the implementing agent.**
