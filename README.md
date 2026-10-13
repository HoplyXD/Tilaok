# Tilaok!

> A Filipino party platformer where chickens build the level, then try to survive it.

**Tilaok!** (the rooster's crow) is our entry for the **DOST Level Up 3.0 Esports Game Dev Challenge** (finals 26–27 November 2026, GMall of GenSan, General Santos City).

Inspired by the build-then-run loop of party platformers, Tilaok! reimagines *sabong*: instead of chickens fighting, chickens compete in a trap-filled obstacle course, and every few rounds a **laro ng lahi** (traditional Filipino game) takes over the stage.

## Theme
**Philippine Games and Sports.** Traditional Filipino games are the core of the gameplay, not just the art.

## Docs
- [Product Requirements](docs/PRD.md): complete product scope, rules and acceptance; consolidates the GDD and specialized contracts
- [Phased Implementation Tracker](docs/PHASETASK.md): 43/401 task records checked; P04 is 14/22 (early exit met, 8 blocked on later phases and human assets), P03 is 6/6 and P02 is 14/22 (physical-device and human-review tasks open)
- [Prototype Defaults](docs/PROTOTYPE_DEFAULTS.md): provisional controller/input values with measured P02/P03 graybox results and remaining limits
- [Documentation Index](docs/INDEX.md): complete map and pre-development documentation order
- [Game Design Document](docs/GDD.md): core loop, events, scoring, characters
- [Item Catalog](docs/ITEMS.md): first batch and expansion item contracts
- [Stage and Placement Specification](docs/STAGE_AND_PLACEMENT.md): stage rules, verified P03 graybox, and future shared construction contract
- [UI and Tutorial Specification](docs/UI_TUTORIAL.md): local multiplayer flow, onboarding, and accessibility
- [Asset and Cultural Register](docs/ASSETS.md): provenance, licences, cultural review, and asset compliance
- [Production Plan](docs/PRODUCTION.md): roles, gates, scope protection, and risks
- [Submission Plan](docs/SUBMISSION.md): forms, synopsis, trailer/demo, and final review
- [Verification and Playtest Plan](docs/PLAYTEST.md): required evidence before release
- [Competition Notes](docs/COMPETITION.md): rules, deadlines, requirements, judging criteria
- [Roadmap](docs/ROADMAP.md): scope and build priorities
- [AI Assistance Record](docs/AI_USAGE.md): Form 03 preparation

## Key Dates
| Date | Milestone |
|---|---|
| **Oct 25, 2026** | Deadline of submission of entries |
| Nov 9, 2026 | Announcement of finalists |
| Nov 26–27, 2026 | Game demo, judging, and awarding |

## Tech
- **Engine:** Godot 4.7
- **Platform:** PC, local multiplayer (2–4 players)

## Status
P01 provides the foundation harness and typed provisional configuration. P02 adds the movement/input diagnostic room; P03 adds a playable protected graybox arena, bounded Play/Place camera, and explicit support-provenance/contact fixtures. P03's six tasks are verified; P02 is 14/22 because physical controller, keyboard rollover and reconnect checks and the wall-movement human review are open. Wall slide/jump is an approved Should extension (P02-T15–T22) that is implemented and automated-test verified but disabled by default; try it via the P02 room's "Wall fixtures (debug)" button or the P03 room's "Wall fixtures" button. It is not a required October submission feature, awaits human review and the October 21 keep/defer decision, and must not delay P04. P04 adds typed item definitions and a validator, a lifecycle/cap manager and the Kaing (Hollow Blocks) and Tulay na Kawayan (bamboo bridge) construction seeds, exercised in an interactive Item Lab that uses immediate lab-only placement. This is not a full lobby-to-match game and does not implement Pugad, atomic placement, scoring, Kangaroo, hazards or production UI/assets. AI-assisted programming is the standing development workflow; Francis and Carlos are the development leads. See [run instructions and responsibilities](docs/PROJECT_STRUCTURE.md), the [P03 tracker](docs/PHASETASK.md#p03--graybox-stage-and-camera), [playtest evidence](docs/PLAYTEST.md), and [AI assistance disclosure](docs/AI_USAGE.md). Use the explicit Godot 4.7.2 executable; the PATH wrapper still launches 4.6.3.

## Run the P03 graybox

From the repository root, launch the harness with the explicit Godot 4.7.2 executable:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!'
```

Choose **P03 Graybox Arena** in the harness. Join K1/K2 with the visible buttons; K1 uses A/D + Space and K2 uses the arrow keys + Enter. The HUD buttons switch Play/Place fixtures, confirm/rotate a diagnostic preview, pause, reset, and return to the harness. See the [full run and test instructions](docs/PROJECT_STRUCTURE.md).

## Run the P04 Item Lab

Launch the harness as above, then choose **Item Lab**. Join K1/K2 with the visible buttons, press **Place**, use **Variant** to cycle the enabled variants (Kaing 1×1, Kaing 2×3, Tulay 4×1), then move (K1 WASD / K2 arrows), rotate (K1 R / K2 Right Shift) and confirm (K1 F / K2 Enter). The ghost shows outline style, an OK/X mark and a text reason in addition to colour. **Play** starts the item lifecycle with a 1.0 s activation grace; **Reset** restarts Play and keeps construction; **Clear all** performs a match reset. Placement here is immediate and lab-only; the atomic Place resolver, Pugad and egg previews belong to P05. All visuals are code-drawn DEBUG graybox.
