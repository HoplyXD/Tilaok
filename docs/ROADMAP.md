# Roadmap

Deadline: **Oct 25, 2026** (as of Oct 12, 2026).

## Priorities
| Priority | Scope |
|---|---|
| **Must** | Team-authored platformer controls; Pugad → Place → Play loop; 1 stage; Karera as the weighted default Main Challenge; unified scoring; Lagsanay; core event stacking with Karera + Lagsanay, Karera + Kangaroo, and Kangaroo + Lagsanay; tutorial/onboarding (required for screening); all eight first-batch families and applicable approved variants (conditional Tulay orientation gated); title/results, Library, settings/help, essential audio/visual cues and release presentation |
| **Should** | Langit-Lupa remains the named second event; richer chicken cosmetics; enhanced crowd audio; Barya; reviewed "Alam mo ba?" cards; session-only local win tally |
| **Nice / backlog** | Expanded 36-family item catalog, more events/stages, extra polish, accessories |

**Rule:** polish beats quantity. Completeness is 20% of screening.

## Item scope and gates

The design catalog in `docs/ITEMS.md` contains **36 mechanically distinct proposals**; cosmetic variants do not count. It is a backlog, not a commitment to implement all 36. The approved October 13 submission target is all eight first-batch families: Hollow Blocks / Kaing Stack, Tulay na Kawayan, Gulong Talon, Trumpo sa Riles, Parol Pulse, Bula-Bulaklak, Tsinelas Launcher, and Walis Cleanup. Bubble capture comes last because forced movement adds temporary player-state, release, ownership, and event dependencies. If capacity is short, defer Bula-Bulaklak first with an explicit team decision; preserve the four originally requested families in the catalog.

Before advanced item implementation, the team must have movement/input, stage, round lifecycle, placement validation, scoring, and relevant event foundations. Kaing Stack and Tulay na Kawayan are construction prerequisites for the base-loop slice and precede Lagsanay; Gulong Talon follows their validation. Items remain inactive during Place except Walis Cleanup's one-shot construction edit. Event stacking is a core system: every round has one Main Challenge and may gain one compatible Twist at its round-scaled chance. Karera is guaranteed in Round 1 and weighted at 70% on non-guaranteed rounds; Lagsanay is guaranteed in rounds 4, 8, and 12, and Kangaroo is a 10% standalone Main Challenge on the remaining eligible rounds. The first required compatibility pairs are Karera + Lagsanay, Karera + Kangaroo, and Kangaroo + Lagsanay; every further pair needs a written compatibility contract and playtest evidence. Langit-Lupa remains the named second laro ng lahi. Do not displace tutorial or Lagsanay to reach an item count. See PRODUCTION.md for ordered prototype gates: each stack follows its independently working components; early race-only profiles do not change release scope.

The repository now contains a Godot project skeleton, but no gameplay scenes or scripts. This roadmap is not evidence that any gameplay prerequisite or item is implemented or stable. See `docs/PLAYTEST.md` for the observed import result, version mismatch, verification scenarios, and honest status boundary.

## Rough Schedule
| Days | Goal |
|---|---|
| Oct 11–12 | Engine locked (Godot 4); lock team roles, art style |
| Oct 13–16 | Movement, item placement, race round, scoring |
| Oct 17–19 | Lagsanay, Karera + Lagsanay stack, Filipino traps |
| Oct 20–21 | Kangaroo and its stacks only after independent-mode gates; core UI/tutorial and selected content (**feature freeze Oct 21**); explicit scope review if gates slip |
| Oct 22 | Stabilize the frozen build; no new event or item implementation |
| Oct 23 | Bug fixing, playtesting |
| Oct 24 | Record trailer + demo video, fill forms, write synopsis |
| Oct 25 | Submit |

## PRD and tracker alignment

[PRD](PRD.md) consolidates the approved product and acceptance; [PHASETASK](PHASETASK.md) records dependencies, verification and actual work. All eight families remain targeted until an explicit scope decision changes that baseline; no automatic cut occurs if dates slip. Prototype defaults remain untested. Title/results/Library and essential cues are required; optional Should work needs an include/defer decision before October 21 freeze. The schedule is high risk from a skeleton and unknown team capacity, not proof that all gates fit. Forms, synopsis, licences and media planning begin alongside early implementation; final footage waits for a tested build.
