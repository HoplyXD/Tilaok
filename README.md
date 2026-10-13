# Tilaok!

> A Filipino party platformer where chickens build the level, then try to survive it.

**Tilaok!** (the rooster's crow) is our entry for the **DOST Level Up 3.0 Esports Game Dev Challenge** (finals 26–27 November 2026, GMall of GenSan, General Santos City).

Inspired by the build-then-run loop of party platformers, Tilaok! reimagines *sabong*: instead of chickens fighting, chickens compete in a trap-filled obstacle course, and every few rounds a **laro ng lahi** (traditional Filipino game) takes over the stage.

## Theme
**Philippine Games and Sports.** Traditional Filipino games are the core of the gameplay, not just the art.

## Docs
- [Product Requirements](docs/PRD.md): complete product scope, rules and acceptance; consolidates the GDD and specialized contracts
- [Phased Implementation Tracker](docs/PHASETASK.md): 58/401 task records checked; P05 is 11/12 (P05-T12 waits on P06-T08 result evidence and the P05 phase exit remains open), P04 is 18/22, P03 is 6/6 and P02 is 14/22 (physical-device and human-review tasks open)
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
P01 provides the foundation harness and typed provisional configuration. P02 adds the movement/input diagnostic room; P03 adds a playable protected graybox arena, bounded Play/Place camera and support-provenance/contact fixtures. P04 adds typed item definitions and the Kaing/Tulay construction seeds in an immediate-placement Item Lab. P05 now adds a local lobby → Pugad → atomic Place → diagnostic Play → results shell → next-round loop, retaining construction across rounds. P05-T01–T11 have implementation/verification evidence; T12 waits on P06-T08 actual award/result evidence, so the P05 phase exit remains open. The P05 shell does not implement finish rules, scoring, Walis Cleanup gameplay, networking or saves. P02 is 14/22 because physical controller, keyboard rollover/reconnect checks and wall-movement human review remain open. Wall slide/jump is an approved Should extension, awaits human review and the October 21 keep/defer decision, and must not delay P05. P03 is 6/6 and P04 is 18/22. AI-assisted programming is the standing development workflow; Francis and Carlos are the development leads. See [run instructions and responsibilities](docs/PROJECT_STRUCTURE.md), [tracker](docs/PHASETASK.md), [playtest evidence](docs/PLAYTEST.md), and [AI assistance disclosure](docs/AI_USAGE.md). Use the explicit Godot 4.7.2 executable; the PATH wrapper still launches 4.6.3.

## Run the P03 graybox

From the repository root, launch the harness with the explicit Godot 4.7.2 executable:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!'
```

Choose **P03 Graybox Arena** in the harness. Join K1/K2 with the visible buttons; K1 uses A/D + Space and K2 uses the arrow keys + Enter. The HUD buttons switch Play/Place fixtures, confirm/rotate a diagnostic preview, pause, reset, and return to the harness. See the [full run and test instructions](docs/PROJECT_STRUCTURE.md).

## Run the P04 Item Lab

Launch the harness as above, then choose **Item Lab**. Join K1/K2 with the visible buttons, press **Place**, use **Variant** to cycle the enabled variants (Kaing 1×1, Kaing 2×3, Tulay 4×1), then move (K1 WASD / K2 arrows), rotate (K1 R / K2 Right Shift) and confirm (K1 F / K2 Enter). The ghost shows outline style, an OK/X mark and a text reason in addition to colour. **Play** starts the item lifecycle with a 1.0 s activation grace; **Reset** restarts Play and keeps construction; **Clear all** performs a match reset. Placement here is immediate and lab-only; use P05 Match Loop to exercise Pugad, exact-variant eggs and the atomic Place resolver. All visuals are code-drawn DEBUG graybox.

## Run the P05 match loop

Launch the harness with the command above and choose **P05 Match Loop**. Join at least two seats and mark every joined seat ready before **Start match** enables. Keyboard seats use K1 **WASD + Space**, K2 **arrows + Ctrl**; **F / Enter** readies and confirms, arrows select a Pugad egg, and **R / Right Shift** rotates a supported Place piece. During diagnostic Play, use **End Round • diagnostic** or the flag-touch stub to open the results shell. The shell advances when all seats are ready or after eight seconds. It awards no points. Construction remains for the next round.

Run the focused automated, interactive and capture checks with Godot 4.7.2:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p05_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_p05_interactive.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p05_evidence.gd'
```

Evidence seats 3/4 use synthetic gamepad identities; physical gamepads were unavailable. P05 visuals remain DEBUG placeholders. See the [P05 verification record](docs/evidence/p05/2026-10-14_p05_verification.md) for test results and limits.
