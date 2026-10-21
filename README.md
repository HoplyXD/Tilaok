# Tilaok!

**Current build:** offline, local 2–4 player baseline. The scheduled P12 `Pugad → Place → Play` route remains default. An engineering-only offline live-build route is available by explicit opt-in; it is separately gated and is not an October submission obligation. NLB-P02 adds an opt-in PC LAN lobby and admission flow. NLB-P03-T01's Android debug APK and local QR scanner package pass export inspection; retained Android runtime/phone evidence remains incomplete, while P02 passes. NLB-P04 network-match source has bounded runtime evidence (focused suite, separate-process run, physical phone admission), but the phase remains unchecked. Preparatory NLB-P06 source adds an opt-in network live-build route that has not run. Preparatory NLB-P07 (content matrix), P08 (pause, seat reclaim) and P09 (replicated results, in-place replay, session-end screens) source is also authored and has not run. See [networked live-build specification](docs/NETWORKED_LIVE_BUILD.md), [separate tracker](docs/PHASETASK_NETWORKED_LIVE_BUILD.md), [P03 evidence](docs/evidence/nlb/p03/README.md), [P04 evidence](docs/evidence/nlb/p04/README.md), and [P06 evidence](docs/evidence/nlb/p06/README.md).

> A Filipino party platformer where chickens build the level, then try to survive it.

**Tilaok!** (the rooster's crow) is our entry for the **DOST Level Up 3.0 Esports Game Dev Challenge** (finals 26–27 November 2026, GMall of GenSan, General Santos City).

Inspired by the build-then-run loop of party platformers, Tilaok! reimagines *sabong*: instead of chickens fighting, chickens compete in a trap-filled obstacle course, and every few rounds a **laro ng lahi** (traditional Filipino game) takes over the stage.

## Theme
**Philippine Games and Sports.** Traditional Filipino games are the core of the gameplay, not just the art.

## Docs
- [Product Requirements](docs/PRD.md): complete product scope, rules and acceptance; consolidates the GDD and specialized contracts
- [Networked Live Build Specification](docs/NETWORKED_LIVE_BUILD.md): approved future PC-host/Android target, architecture, input and placement contracts
- [Networked Live Build Tracker](docs/PHASETASK_NETWORKED_LIVE_BUILD.md): separate 12-phase, 36-task implementation and verification track (11/36 checked; P02 passes; P03, P04, P05, P06, P07, P08 and P09 acceptance remains open)
- [Phased Implementation Tracker](docs/PHASETASK.md): 180/421 task records checked; P13 is 11/18 (scoreboard, the routes, HUD, Library, tutorial and accessibility on the scheduled default route, and the 2026-10-17 reference UI restyle; physical-device and human sessions, including the restyle design review, open); P12 is 10/10 technical (seeded schedule, announcements, the three verified Twist pairs and the owner-approved terminal-order table on the default scheduled route; human sessions open); P11 is 13/13 on standalone development-route engineering evidence (human/device/balance and performance gates remain); P09 is 4/4 and P08 is 6/6 technical; P07 is 0/4 with player/device gates open; P10 is 48/54 on placeholder art (event/stack integration passed 2026-10-16 and the six families are in the match pool; release enablement open); P05 is 12/12 and P06 is 8/8; P04 is 20/22, P03 is 7/7 (map scenes added) and P02 is 24/34 (physical-device and human-review tasks open; includes the 2026-10-14 sneak/glide/64 px grid/stage-blocks extension)
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
P01 provides the foundation harness and typed provisional configuration. P02 adds local movement/input; P03 adds the protected graybox arena, bounded camera and support fixtures. P04 adds Kaing/Tulay construction seeds. P05 adds the local lobby → Pugad → atomic Place flow, and P06 adds live Karera goal contact, deadlines, exact race scoring, explained results and next-round reset with persistent construction. P07 adds a dedicated first-playable route limited to three verified Kaing/Tulay variants; its synthetic engineering checks pass, while player sessions, physical-device acceptance and human review remain open (0/4 tasks checked). P08 adds independent pass-through bomb-taya Lagsanay on the persistent stage and is 6/6 technically verified in development; its profile is not release-enabled and P07-T04 remains an open entry/release gate. P09 adds a development-only full-match route that ends at 80 eighth-point units or round 12, sends tied leaders to Lagsanay sudden death, and binds one winner and exact scores to the live result screen with Replay/Lobby/Quit. P09's four technical tasks pass, but its 1080p warmed p95 frame interval is above target; see [P09 evidence](docs/evidence/p09/README.md). P11 adds standalone `kangaroo_contract_lab` using the existing match lifecycle and persistent construction, with no race goal/deadline or Bomb-Taya controller; its 77 focused checks, 81 rendered synthetic 2/3/4-seat assertions and Windows startup smoke pass. P11's debug timing exceeds the provisional frame target, and human comprehension/device/balance/asset review remains open; see [P11 evidence](docs/evidence/p11/README.md). P10 hazard-family verification/release enablement, production review and release readiness remain open. P12 scheduling/stacks, tutorial and Library are implemented on the default scheduled route. Barya is enabled there after scoped P19 approval and technical verification; P07 remains disabled and P00-T04/full-manifest ratification stays open. P02 is 24/34 because physical controller, keyboard rollover/reconnect checks and wall-movement / sneak-glide human review remain open. Since 2026-10-14 the stage uses 64 px tiles (TileMapLayer), keyboard jump is W/Up (hold to glide), S/Down sneaks, and Solid Block, Wood Box and Collapsing Block scenes live in `tilaok!/scenes/blocks/`. Wall slide/jump is implemented; its human review and Should include/defer decision remain open. P03 is 7/7 (map scenes and Lobby map selection, 2026-10-16) and P04 is 18/22. AI-assisted programming is the standing development workflow; Francis and Carlos are the development leads. See [run instructions and responsibilities](docs/PROJECT_STRUCTURE.md), [tracker](docs/PHASETASK.md), [playtest evidence](docs/PLAYTEST.md), and [AI assistance disclosure](docs/AI_USAGE.md). Use the explicit Godot 4.7.2 executable; the PATH wrapper still launches 4.6.3.

NLB-P05 adds an explicitly selected offline live-build route while preserving the scheduled P12 route as the default. Its focused synthetic regression suite and rendered captures pass, but broad live safety/content acceptance is still open; see [P05 evidence](docs/evidence/nlb/p05/README.md).

NLB-P02 adds a spectator PC host lobby with IPv4 discovery, manual address join, a room-lifetime reusable access code, host approval and lobby readiness. NLB-P04 starts the scheduled network match from that lobby. The track remains separately gated; see [P02 evidence](docs/evidence/nlb/p02/README.md), [P03 evidence](docs/evidence/nlb/p03/README.md) and [P04 evidence](docs/evidence/nlb/p04/README.md).

NLB-P06 (preparatory, unrun) adds an opt-in **network live-build** route. Start the PC host with `-- --match-route=network_live_build` and it runs Pugad → shared GO → live placement → results → next Pugad with phone and local seats. The host validates and commits every placement. Phones get Build, a four-way aim pad, Rotate, Place and Cancel above the movement row, and see a tentative ghost until the host answers. Without the flag, network matches stay on the scheduled route. See [P06 evidence](docs/evidence/nlb/p06/README.md).

NLB-P09 (preparatory, unrun) finishes the match on the network. The host's committed results (round results, Sudden Death, the winner and exact scores) appear on every phone with Continue, Replay, Return to Lobby and Leave. Replay re-keys the session in place so phones stay connected; Return to Lobby, host Quit or a lost host ends the session and each phone shows why before returning to its lobby. See [P09 evidence](docs/evidence/nlb/p09/README.md).

## Play the live match flow (P07 playtest build)

The project now starts at the **Title**. From the repository root, with the explicit Godot 4.7.2 executable:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!'
```

Press your ready key to join (WASD **E** or **F**, IJKL **O**, arrows **Enter**, numpad **Num 0**, gamepad **South**; any layout can be any player). In the Lobby, ◀ ▶ (keys or mouse) choose the map, choose **Start**, let the other players join in the Lobby and mark every seat ready: the match starts by itself. Then Pugad (**← / →** pick an egg, ready key claims), Place (move, **R** / **Right Shift** rotate, ready key confirms), Karera, Round result, next round. **Esc** or a pad **Start** pauses; the pause owner chooses Resume / Settings / Library / Leave. This default route is the Kaing/Tulay slice of the Karera loop with no match end. To play the same flow with the P09 match end (first to 10 points or round 12, Lagsanay sudden death on ties, final result with Replay / Return to Lobby / Quit), add `-- --match-route=lifecycle` to the command above. The facilitator sheet and launch steps for the exported build are in [docs/PLAYTEST.md](docs/PLAYTEST.md).

The opt-in **Offline Live Build** route keeps the Pugad selection window, then starts movement and building together after the shared GO countdown. It uses one assigned item per player, reuses the current stage and events, and leaves the scheduled Place route as the default. From the repository root:

```powershell
# Default scheduled route
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!'

# Opt-in offline live-build route
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' -- --match-route=offline_live_build
```

Live-build keyboard controls: K1 toggles build with **Q**, aims with **Z/C/V/B**, rotates with **T**, confirms with **E/F**, and cancels with **X**. K2 uses **[**, **Y/H/N/M**, **]**, **Enter**, and **\\**. K3 uses **-**, **7/4/8/6**, **=**, **O**, and **'**. K4 uses **Num +**, **Num 7/1/3/9**, **Num \***, **Num 0**, and **Num -**. Gamepad uses **Y**, right stick, right bumper, right trigger, and **B**. Movement/jump/sneak, pause and cheer keep their existing bindings. The keyboard confirm keys reach live placement only in live-build rooms; this was wired in NLB-P06 and is unrun. These routes and controls have synthetic engineering evidence only; physical gamepad and human play acceptance are open. See [P05 evidence](docs/evidence/nlb/p05/README.md).

## Try the PC LAN lobby (P02 engineering build)

Launch the project with the explicit Godot 4.7.2 executable, select **LAN Lobby** from Title, choose one eligible IPv4 interface and start a spectator host. On a second PC running the same build, enter the host IPv4 and game port (default `27777`), then enter the displayed access code separately; alternatively search by Lobby ID and enter that code. The host approves the request, after which the client acknowledges its seat and can toggle Ready. Discovery uses UDP port `27778`. Both ports are configurable in the lobby. This trusted-LAN engineering feature does not encrypt traffic. When every seat is ready, the host can start the P04 scheduled network match (or, with the P06 opt-in flag, the network live-build match). The offline Play route remains available after leaving or stopping the session. See [P02 evidence and limits](docs/evidence/nlb/p02/README.md).

From the repository root, launch either desktop:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64.exe' --path 'tilaok!'
```

## Run the developer harness

The harness (P01–P10 fixtures, Item Lab, UI Gallery, the P05 match room with the DEBUG overlay) is no longer the main scene. Open it with a user argument, or from the Title's DEBUG overlay in debug builds (F3, **Developer harness**):

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' -- --harness
```

## Run the P03 graybox

From the repository root, launch the harness with the explicit Godot 4.7.2 executable:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' -- --harness
```

Choose **P03 Graybox Arena** in the harness. Join K1/K2 with the visible buttons; K1 uses A/D + Space and K2 uses the arrow keys + Enter. The HUD buttons switch Play/Place fixtures, confirm/rotate a diagnostic preview, pause, reset, and return to the harness. See the [full run and test instructions](docs/PROJECT_STRUCTURE.md).

## Run the P04 Item Lab

Launch the harness as above, then choose **Item Lab**. Join K1/K2 with the visible buttons, press **Place**, use **Variant** to cycle the enabled variants (Kaing 1×1, Kaing 2×3, Tulay 4×1), then move (K1 WASD / K2 arrows), rotate (K1 R / K2 Right Shift) and confirm (K1 F / K2 Enter). The ghost shows outline style, an OK/X mark and a text reason in addition to colour. **Play** starts the item lifecycle with a 1.0 s activation grace; **Reset** restarts Play and keeps construction; **Clear all** performs a match reset. Placement here is immediate and lab-only; use P05 Match Loop to exercise Pugad, exact-variant eggs and the atomic Place resolver. All visuals are code-drawn DEBUG graybox.

## Review the UI shells

Launch the harness with the command above and choose **UI Gallery** (every screen and state with SAMPLE data; **F9** hides the review panel) or **Player flow (Title)**. To edit them, open `tilaok!` in the Godot 4.7.2 editor and follow the "How to edit the UI in Godot" section of [docs/UI_HANDOFF.md](docs/UI_HANDOFF.md). Since 2026-10-17 the Lobby, Play HUD, Place, Round result, Pause and both confirmations follow the team's Figma screens with the team-supplied fonts (see "Reference restyle" in UI_HANDOFF); textures and icons are still placeholders, and **Components** in the gallery shows every restyled piece. **Player flow (Title)** now runs the live match loop; the gallery itself stays SAMPLE-only.

## Run the match loop

Launch the harness with the command above and choose **P05 Match Loop** (the DEBUG overlay is on; F3 toggles it). Join at least two seats and mark every joined seat ready before **Start match** enables (the player flow from the Title starts without a click). Keyboard seats use K1 **WASD + Space**, K2 **arrows + Ctrl**; **F / Enter** readies and confirms, arrows select a Pugad egg, and **R / Right Shift** rotates a supported Place piece. During Karera, reach the outlined goal to finish. Results show outcomes, awards, suppression/no-score reason, deltas and exact cumulative totals. Results advance when all seats are ready or after eight seconds. Construction remains for the next round.

Run the focused automated, interactive and capture checks with Godot 4.7.2:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p05_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_p05_interactive.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p06_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_p06_interactive.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p06_performance.gd'
```

The P05 interactive run covers four seats over two rounds; P06 live results use two seats and performance fixtures sample 2/3/4 seats over ten rounds each. Seats 3/4 use synthetic gamepad identities; physical gamepads and human review remain open. P05/P06 visuals remain DEBUG placeholders. See the [P06 verification record](docs/evidence/p06/2026-10-14_p06_verification.md) for results, export evidence and limits.

## Run P07 First Playable

Choose **P07 First Playable** in the harness for the scored two-to-four-seat Karera slice, or launch directly:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' -- --open-room=p07_first_playable
```

K1 (WASD) joins/readies/claims/confirms with **E** or **F**, moves with **A/D**, jumps with **W** (hold to glide), sneaks with **S**, rotates with **R**, and backs out with **G**. K2 uses **Enter**, arrows, **Up** to jump/glide, **Down** to sneak, **Right Shift** to rotate, and **Backspace** to go back. A gamepad uses **A** to join/readies/claims/confirms, the D-pad to move/select, **A** to jump in Karera, **X** to rotate, **B** to go back, and **Start** to pause. Join at least two seats; each seat must ready before Pugad. P07's egg pool is restricted to Kaing 1×1, Kaing Stack 2×3 and Tulay 4×1 variants.

The project has passed synthetic route, reset and scoring checks, but player-driven sessions, novice comprehension, physical controllers, human minimum-zoom readability review and the P02 reconnect gate remain open. The available 1080p images are project-runner captures; exported-build UI screenshots were not saved. Do not treat automated captures or teleported finishers as human evidence. See the [P07 evidence and session matrix](docs/evidence/p07/README.md) and [tracker](docs/PHASETASK.md).

## Run independent Kangaroo

Choose **P11 Kangaroo Lab** in the development harness or launch the standalone profile directly:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' -- --open-room=kangaroo_contract_lab
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p11_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_p11_interactive.gd'
```

This is a development-only event on the current match lifecycle and persistent construction. It has no race goal/deadline or Bomb-Taya controller; only Trumpo and the Tsinelas Launcher are enabled. Command cues are labeled DEBUG placeholders. Automated seats are synthetic, and human/device/balance review and performance profiling remain open; see the [P11 evidence index](docs/evidence/p11/README.md).

## Run independent Lagsanay

Choose **P08 Lagsanay Lab** in the development harness or launch it directly:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' -- --open-room=p08_lagsanay
```

Join K1 and K2 using the visible buttons, then ready both seats with **F / Enter** and start. Complete Pugad and Place as in P05; the mode transitions into independent bomb-taya tag on the same constructed stage. The opening taya is identified by seat, shape and text; after the three-second head start, contact passes the bomb without resetting its countdown. K1 uses **A/D**, **W** jump/glide, **S** sneak; K2 uses **Left/Right**, **Up** jump/glide, **Down** sneak. **Escape** pauses; resume requires participants to ready. Results explain placements, direct trap credit and any Last Cluck winner/tie rule. Ready seats advance to the next round while construction and cumulative scores persist. Use **P08 Lagsanay Lab** again through the harness to start over. `lagsanay_lab` is development-only and its tuning remains provisional.

Run the focused and rendered synthetic checks with the explicit Godot 4.7.2 build:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p08_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_p08_interactive.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p08_performance.gd'
```

P08 is 6/6 technically verified; the P07-T04 player/device acceptance gate and physical-device/human review remain open. See [P08 evidence and limits](docs/evidence/p08/README.md) and [the tracker](docs/PHASETASK.md).

## Run P09 Match Lifecycle (development)

Choose **P09 Match Lifecycle** in the development harness or launch it directly:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' -- --open-room=p09_match_lifecycle
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p09_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_p09_interactive.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/audit_p09_restarts.gd'
```

The route retains P07's three-item allowlist. Matches end at 10 points (80 eighth-point units) or after round 12; tied leaders play Lagsanay sudden death on the same persistent stage. Results show one winner, every original seat's score and the outcome, with Replay, Return to Lobby and Quit. `run_p09_tests.gd`, `run_p09_interactive.gd` and `audit_p09_restarts.gd` provide synthetic engineering checks; they do not replace human/device acceptance. See [P09 evidence and limits](docs/evidence/p09/README.md) and [the tracker](docs/PHASETASK.md).

Run the focused P07 checks and render/performance capture with Godot 4.7.2:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p07_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_p07_reset_audit.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_p07_evidence.gd'
```
