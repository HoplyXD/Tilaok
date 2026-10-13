# Tilaok!

> A Filipino party platformer where chickens build the level, then try to survive it.

**Tilaok!** (the rooster's crow) is our entry for the **DOST Level Up 3.0 Esports Game Dev Challenge** (finals 26–27 November 2026, GMall of GenSan, General Santos City).

Inspired by the build-then-run loop of party platformers, Tilaok! reimagines *sabong*: instead of chickens fighting, chickens compete in a trap-filled obstacle course, and every few rounds a **laro ng lahi** (traditional Filipino game) takes over the stage.

## Theme
**Philippine Games and Sports.** Traditional Filipino games are the core of the gameplay, not just the art.

## Docs
- [Product Requirements](docs/PRD.md): complete product scope, rules and acceptance; consolidates the GDD and specialized contracts
- [Phased Implementation Tracker](docs/PHASETASK.md): 112/405 task records checked; P10 is 42/54 on placeholder art in the development `items_lab` profile (integration and release enablement blocked); P05 is 12/12 and P06 is 8/8; P04 is 18/22, P03 is 6/6 and P02 is 17/26 (physical-device and human-review tasks open; includes the 2026-10-14 sneak/glide/64 px grid/stage-blocks extension)
- [Prototype Defaults](docs/PROTOTYPE_DEFAULTS.md): provisional controller/input values with measured P02/P03 graybox results and remaining limits
- [Documentation Index](docs/INDEX.md): complete map and pre-development documentation order
- [Game Design Document](docs/GDD.md): core loop, events, scoring, characters
- [Item Catalog](docs/ITEMS.md): first batch and expansion item contracts
- [Stage and Placement Specification](docs/STAGE_AND_PLACEMENT.md): stage rules, verified P03 graybox, and future shared construction contract
- [UI and Tutorial Specification](docs/UI_TUTORIAL.md): local multiplayer flow, onboarding, and accessibility
- [UI Handoff Spec](docs/UI_HANDOFF.md): everything UI design needs to start (frame, identity, prompts, screens, components, priorities, open decisions)
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
P01 provides the foundation harness and typed provisional configuration. P02 adds local movement/input; P03 adds the protected graybox arena, bounded camera and support fixtures. P04 adds Kaing/Tulay construction seeds. P05 adds the local lobby → Pugad → atomic Place flow, and P06 adds live Karera goal contact, deadlines, exact race scoring, explained results and next-round reset with persistent construction. P05 is 12/12 and P06 is 8/8 in the tracker. The first race slice is verified only in scripted/synthetic runs; human sessions, physical input, P10 hazard integration, Barya gameplay, Lagsanay, event stacking, full-match ending, tutorial, final art and release readiness remain open. P02 is 17/26 because physical controller, keyboard rollover/reconnect checks and wall-movement / sneak-glide human review remain open. Since 2026-10-14 the stage uses 64 px tiles (TileMapLayer), keyboard jump is W/Up (hold to glide), S/Down sneaks, and Solid Block, Wood Box and Collapsing Block scenes live in `tilaok!/scenes/blocks/`. Wall slide/jump is implemented; its human review and Should include/defer decision remain open. P03 is 6/6 and P04 is 18/22. AI-assisted programming is the standing development workflow; Francis and Carlos are the development leads. See [run instructions and responsibilities](docs/PROJECT_STRUCTURE.md), [tracker](docs/PHASETASK.md), [playtest evidence](docs/PLAYTEST.md), and [AI assistance disclosure](docs/AI_USAGE.md). Use the explicit Godot 4.7.2 executable; the PATH wrapper still launches 4.6.3.

## Run the P03 graybox

From the repository root, launch the harness with the explicit Godot 4.7.2 executable:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!'
```

Choose **P03 Graybox Arena** in the harness. Join K1/K2 with the visible buttons; K1 uses A/D + Space and K2 uses the arrow keys + Enter. The HUD buttons switch Play/Place fixtures, confirm/rotate a diagnostic preview, pause, reset, and return to the harness. See the [full run and test instructions](docs/PROJECT_STRUCTURE.md).

## Run the P04 Item Lab

Launch the harness as above, then choose **Item Lab**. Join K1/K2 with the visible buttons, press **Place**, use **Variant** to cycle the enabled variants (Kaing 1×1, Kaing 2×3, Tulay 4×1), then move (K1 WASD / K2 arrows), rotate (K1 R / K2 Right Shift) and confirm (K1 F / K2 Enter). The ghost shows outline style, an OK/X mark and a text reason in addition to colour. **Play** starts the item lifecycle with a 1.0 s activation grace; **Reset** restarts Play and keeps construction; **Clear all** performs a match reset. Placement here is immediate and lab-only; use P05 Match Loop to exercise Pugad, exact-variant eggs and the atomic Place resolver. All visuals are code-drawn DEBUG graybox.

## Review the UI shells

Launch the harness with the command above and choose **UI Gallery** (every screen and state with SAMPLE data; **F9** hides the review panel) or **Player flow (Title)**. To edit them, open `tilaok!` in the Godot 4.7.2 editor and follow the "How to edit the UI in Godot" section of [docs/UI_HANDOFF.md](docs/UI_HANDOFF.md). Everything is placeholder: no final art, font or live scoring data.

## Run the match loop

Launch the harness with the command above and choose **P05 Match Loop**. Join at least two seats and mark every joined seat ready before **Start match** enables. Keyboard seats use K1 **WASD + Space**, K2 **arrows + Ctrl**; **F / Enter** readies and confirms, arrows select a Pugad egg, and **R / Right Shift** rotates a supported Place piece. During Karera, reach the outlined goal to finish. Results show outcomes, awards, suppression/no-score reason, deltas and exact cumulative totals. Results advance when all seats are ready or after eight seconds. Construction remains for the next round.

Run the focused automated, interactive and capture checks with Godot 4.7.2:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p05_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_p05_interactive.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p06_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_p06_interactive.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p06_performance.gd'
```

The P05 interactive run covers four seats over two rounds; P06 live results use two seats and performance fixtures sample 2/3/4 seats over ten rounds each. Seats 3/4 use synthetic gamepad identities; physical gamepads and human review remain open. P05/P06 visuals remain DEBUG placeholders. See the [P06 verification record](docs/evidence/p06/2026-10-14_p06_verification.md) for results, export evidence and limits.
