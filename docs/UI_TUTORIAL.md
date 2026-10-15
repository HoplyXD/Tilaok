# Tilaok! UI, Accessibility, and Tutorial Specification


## Experience goals

- A new local player understands how to join, move, jump, select an egg, place an item, and finish a Karera round without reading a long rules page.
- Every player can identify their chicken without relying on colour alone.
- A spectator can identify the current phase, objective, leader, event, and winner at a glance.
- Event prompts remain understandable at minimum camera zoom and during a crowded, persistent stage.

## Screen flow

```mermaid
flowchart LR
  Title[Title] --> Lobby[Local join lobby]
  Title --> Library[Library]
  Lobby --> Tutorial[Guided first Karera]
  Tutorial --> Match[Pugad → Place → Play]
  Match --> Round[Round result]
  Round --> Match
  Match --> Results[Match result]
  Results --> Lobby
```

| Screen | Required content | Primary actions |
|---|---|---|
| Title | Game title, start-local-match option, Library, settings, clear build/version label during development. | Start, Library, settings, back/quit. |
| Library | Browse enabled items, events, scoring, controls, and accessibility help outside an active match. | Choose category, inspect animated entry, back. |
| Local join lobby | Two-to-four player join slots, controller/keyboard prompt, chicken colour plus number/shape marker, ready state. | Join, select permitted identifier, ready, leave. |
| Tutorial | Guided first Karera with one instruction at a time. | Move, jump, grab egg, place/rotate/confirm, reach flag. |
| Pugad | Visible eggs and contained items, selection countdown, locked next-round Main Challenge/Twist announcement where applicable. | Move pointer/character, claim egg. |
| Place | Shared stage, each player pointer, valid/invalid ghost, rotation prompt, countdown, protected-zone feedback. | Move, rotate where available, confirm. |
| Play | Phase/objective display, timer where applicable, score, player identity markers, event and item tells. | Run and jump baseline; wall slide/jump controls appear only if the approved Should extension is implemented, verified and selected for release. |
| Round result | Finishes/eliminations, awarded points, current match total, clear winner or no-score explanation. | Continue when all players are ready or after timeout. |
| Match result | Exactly one winner, each original participant's exact final score, ordinary or sudden-death outcome, and Last Cluck explanation when applicable. | Replay, Return to Lobby, Quit; all original participants freshly ready. Quit/whole-group leave require confirmation and cancel restores the prior state. |

## Persistent in-match information

The HUD shows only information needed to make a current decision:

- current round and Main Challenge;
- a visible **TWIST** label beneath the Main Challenge when a compatible event is stacked;
- score totals in eighth-point-capable display form where ties require it;
- time limit/countdown only when the active challenge uses one;
- each player’s number or shape marker in addition to colour;
- player state: alive, finished/secured, eliminated, or current taya;
- Kangaroo failure sequence: **KANG → GA → ROO**;
- Barya carrier marker when Barya is enabled;
- next-round event announcement during the preceding Pugad phase.

Do not expose technical IDs, collision shapes, or internal random seeds in the player-facing HUD.

## Library

The Library is available from the title screen, lobby, and pause/settings menu. It is the deliberate slow-reading space for information that would interrupt a Pugad or Place phase.

| Section | Contents |
|---|---|
| How to Play | Pugad → Place → Play, controls, placement validation, stage persistence, and match end. |
| Karera | Flag objective, Tapos, first-finisher Una, no second/third-place points, Bayani, Bawi, Barya, and too-easy/too-hard outcomes. |
| Lagsanay | Taya, passing, timer, eliminations, Last Cluck, and survival placement scoring (first eliminated in four-player play is fourth for zero placement points). |
| Kangaroo | Slipper poses, Freeze, Rising wave, Hug pairs, misses, Slipper Storm, and player-built wave supports. |
| Items | Name, looping animation, grid/size variants, what it does, placement preview, tell, counterplay, and applicable event behavior. |
| Accessibility | Player markers, colour-independent tells, screen-shake settings, and audio/visual cue policy. |

The Library displays only enabled release content by default. Backlog entries can be visible only in a clearly marked development/reference mode; they must never imply that an unimplemented item is playable.

## Pugad and placement feedback

### Pugad

- Each egg visibly identifies its item and exact size variant through a short looping animation before a player claims it. It shows no name or description in the party flow.
- Egg ownership changes immediately and visibly on a successful simultaneous claim.
- A player whose claim loses receives a clear non-colour cue and can choose another available egg.
- Unclaimed-egg and timeout behavior must be explained before the first live Pugad phase.

### Placement

- The placement ghost distinguishes valid and invalid state through colour **and** outline/icon/texture.
- The preview shows the item footprint, rotation, size variant, and separate sweep, projectile lane, or effect radius where relevant.
- Projectile and rolling-shot items show a trajectory guide in Place: a straight lane to the first blocking solid, predicted ricochet segments, a terrain-following route, or a bounded sweep when the exact path depends on live physics.
- A rejected placement explains the actionable cause: protected zone, player clearance, world bound, solid conflict, or item-specific restriction.
- Walis Cleanup previews its exact target set and protected exclusions before confirmation.
- The transition to Play gives a short readable activation grace; no item should cause a first-frame surprise.

## Karera communication

- The flag is visible and clearly marks the objective.
- A finisher receives a **secured** state marker in Karera + Lagsanay and Karera + Kangaroo stacks.
- The post-first-finish countdown is visible to unfinished live runners.
- The round result explains Tapos, Una, Bayani, Bawi, Patibong, and Barya awards in plain language.
- When the too-easy or too-hard rule suppresses points, the result screen explicitly says why.

## Lagsanay communication

- The current taya has a clear body marker, countdown, and pass-back-immunity feedback.
- The opening frozen taya state has a visible countdown so every player understands why the taya cannot move or be hurt yet.
- **P08 current development implementation (scene-based since 2026-10-14):** the Play HUD names Lagsanay, shows the head-start or taya countdown, tags the taya's player number and shape, and marks that seat TAYA in its score row; a notice reports recently immune player identity/time. The DEBUG overlay adds the longer status (other contacts remain usable). An authored world-space marker repeats the taya identity over the chicken. The Round result screen explains outcomes, placement, direct Patibong/Bawi and the exact Last Cluck winner/tie rule. This is placeholder presentation, not the final UI design.
- Tagging uses an obvious contact effect independent of chicken body collision.
- Eliminations show placement order. If the final group is eliminated in the same physics tick, show **Last Cluck!** and the deterministic winner callout.
- Spectating players retain the cheer button and do not obscure active-player information. **Implemented (2026-10-15):** an eliminated or finished chicken presses its Rotate control (R / Right Shift / West) during Play; its own HUD row shows `CHEER!` for 1 s with a soft Crowd-bus sound; a 1 s per-seat cooldown applies; nothing in the simulation changes.

## Kangaroo communication

The giant background slipper is a non-colliding presenter. Every command needs all of these cues:

| Slipper pose | Command | Required cue |
|---|---|---|
| Normal, sole down | Freeze | Freeze icon/text, distinct audio, timing ring. |
| Sole up/facing down | Rising wave | Wave icon/text, target line, distinct audio, timing ring. |
| Sideways | Hug | Pair icon/text, distinct audio, timing ring. |

- Screen shake has full, reduced, and off settings. The command remains legible without screen shake or colour.
- Rising wave shows its world-space target line before the wave rises. A player-built support above the line is required; base platforms do not qualify.
- Hug shows the evaluation moment clearly. Pairing is evaluated only at that instant, and each chicken can have one partner.
- A sideways slipper rerolls at two survivors; communicate the reroll before the next telegraph.
- During Slipper Storm, show the two active command requirements separately and retain the same pose/icon/audio cues. The display must make the two-command cap clear.

## Tutorial sequence

The first match begins with a guided Karera. It introduces only the normal loop; it does not require a player to learn Lagsanay or Kangaroo before playing.

1. **Welcome:** identify the player’s chicken number/shape and explain the local join display.
2. **Move and jump:** reach short, safe markers on the base stage.
3. **Pugad:** point out that each egg shows the item inside; claim one egg.
4. **Place:** move the ghost, rotate if the selected item allows it, explain valid/invalid feedback, and confirm.
5. **Karera:** show the flag, run/jump prompt, and finish.
6. **Results:** explain Tapos and first-finisher Una with the actual Karera result; explain that second and third finishers get no rank bonus.
7. **Later just-in-time prompts:** before the first Lagsanay, explain taya, pass, timer, and last-survivor objective. Before the first Kangaroo, explain the three slipper poses, three misses, and player-built Rising wave supports.

Tutorial prompts must be skippable after a player has completed them in the current session. A replayable rules/help page remains available from the lobby and pause/settings menu.

**Future approved Should extension:** if wall movement is included before release, add a brief optional practice cue showing that wall contact slows descent and a fresh jump press kicks away. The cue must explain that holding jump does not repeat and that players must separate before kicking from the same wall again. Add the control to the Library and tutorial only after implementation and verification; no wall-movement tutorial, HUD, animation or sound currently exists. Human production owns any final animation/audio assets.

## Guided first match — implemented slice (2026-10-14, PLACEHOLDER copy)

**Owner decision (2026-10-14):** the guided first match uses a tutorial-only layout where building is required to reach the flag. The flag ledge is raised above the highest no-build jump, so the first round teaches Pugad → Place → Play for real. Every mode in that match plays on the same built map (no per-mode map change); normal matches are unchanged. Skip and replay are session-only.

| Step | Shown during | Advances when |
|---|---|---|
| 1 Welcome | Lobby | the match leaves the Lobby (number + shape of every seat; run/jump glyphs per device) |
| 2 Pugad | Pugad | a seat owns an egg or the timer assigns one (copy for claimed / lost / timeout) |
| 3 Place | Place | all confirmed or Place ends; BUILD HERE zone marker; stronger hint when the previous round had no finishers |
| 4 Karera | Play | the round ends |
| 5 Results | Round result | the next round starts; text selected from the real result (some / everyone / nobody / 2-player waiver) |
| Lagsanay | first Lagsanay or sudden death of a session | Lagsanay ends; shown once per session (only reachable on the lifecycle route today) |

**D1 note:** move/jump is taught inside the real first Karera (a warm-up note in step 1 and the Play prompt), not in a pre-Pugad practice phase. This supersedes the wording of sequence step 2 above ("reach short, safe markers on the base stage") for the guided match; the P13-T07 acceptance is unchanged.

Skip is a Pause menu entry ("Skip tutorial", shown only while the tutorial is active); Back is not used (P09 binds it to leave-confirm). Replay is the "Replay tutorial" entry on the Library How to Play page; it clears the session set. The coach box is display-only and sits where it does not cover the 64 px HUD or the Place strip. Copy lives in `tilaok!/data/ui/tutorial_script.tres` and is not culturally reviewed. The wall-slide practice cue is still a later Should extension. No human novice session has run: P13-T08 stays unchecked.

## Just-in-time prompts — implemented (2026-10-15, PLACEHOLDER copy)

| Prompt | Shown when | Source |
|---|---|---|
| `lagsanay` | the first Lagsanay Main round, or a Bomb-Taya Twist (Twist wording: the flag still wins); hands over after 12 s | `tutorial_script.tres` step `lagsanay`, variant `twist` |
| `kangaroo_poses` | the Pugad of a round that is, or precedes, a Kangaroo Main or Twist round | step `kangaroo_poses` |
| `kangaroo_supports` | the Place of that round (build up for the Rising wave) | step `kangaroo_supports` |
| `kangaroo_misses` | once Kangaroo commands run (KANG, GA, ROO; the third is out) | step `kangaroo_misses` |

Each shows once per session (`TutorialSession.seen_kangaroo_steps`, never saved); Pause > Skip tutorial hides all of them and Library > How to Play > Replay tutorial clears them. On a stacked round the taya prompt is shown first and hands over to the Kangaroo prompt. The guided first match keeps its own Pugad / Place / Results steps; the Kangaroo prompt takes over only in Play. Evidence: [P13 tutorial suite](evidence/p13/test_logs/run_p13_tutorial_tests.txt).

## Accessibility baseline

- Colour is never the sole identifier for chickens, teams, valid/invalid state, taya, Barya, or hazards.
- Use readable text, shape/icon, animation, and audio as redundant cues.
- Keep HUD text, target lines, and danger regions legible at minimum camera zoom.
- Provide independent volume controls for master, music, effects, and crowd audio if the final settings scope permits.
- Support gamepad-first local play and a documented shared-keyboard fallback.
- Avoid rapid flashing; Parol Pulse uses a brightness ramp and other cues rather than rapid flicker.
- Do not require a screen shake effect, fine colour distinction, or audio alone to react correctly.

## Results chart reading — 2026-10-15

Round and final results include a shared vertical score chart. Columns stay in seat order and retain each chicken's number and shape identifier. Read the horizontal guides from the zero baseline; the target guide marks the configured match target. Each stack segment is an exact integer eighth-point award and the adjacent legend names it with both a glyph and text. A neutral segment means the prior total has no award history available, not a newly invented award. A zero-score chicken stands on a neutral perch. The round breakdown and suppression reason remain readable outside the chart.

The final-results winner callout remains explicit in tied sudden death, even when tied leaders have equal-height bars. A round-12 winner below the target line remains below it. The independent Result reveal motion setting controls the reveal; changing Screen shake does not affect it. These are implementation notes, not evidence of novice comprehension. A human readability review and tutorial comprehension session remain open.

## Decisions still dependent on art and implementation

Provisional phase bindings, device/identity assignment, held-button policy and pause/reconnect now live in [PROTOTYPE_DEFAULTS.md](PROTOTYPE_DEFAULTS.md#3-input-and-local-competition). They are **PROTOTYPE — UNTESTED**. The list below concerns final choices and physical validation rather than permission to invent conflicting per-player input rules.

- final typography, language mix, icon set, and text copy;
- exact lobby navigation and keyboard-sharing constraints;
- pause behavior in local multiplayer;
- final settings list and audio-control granularity;
- exact minimum zoom, safe-area dimensions, and device-resolution targets.

## Verification links

`PLAYTEST.md` contains the required 2/3/4-player, device, minimum-zoom Parol, Kangaroo accessibility, tutorial, and event-stack checks. P08 taya/head-start/pass immunity and P09 live match-end, sudden-death, result and restart behavior passed synthetic engineering checks. P11's standalone command cues and event checks also have synthetic engineering evidence; see [P08 evidence](evidence/p08/README.md), [P09 evidence](evidence/p09/README.md) and [P11 evidence](evidence/p11/README.md). The guided tutorial, final visual treatment, player comprehension/readability, physical-device validation and P13 product UI remain open.
**Status:** pre-production contract. `GDD.md` is the gameplay source of truth. This document defines what players must be able to understand and operate; it does not prescribe UI code or final visual style. **UI shell status (2026-10-14):** placeholder scene-based shells for the Title, Lobby, Tutorial prompt box, Pugad, Place, Play HUD, results, Pause/Reconnect, Settings and Library exist; the Title, Lobby, Pugad, Place, Play HUD, Round result and Pause/Reconnect screens are **bound to the live P05/P06 match loop**, and the Match result screen is bound to live P09 data on the lifecycle route (`-- --match-route=lifecycle`); the Library shows live Items with SAMPLE text for other categories; see [UI_HANDOFF.md](UI_HANDOFF.md)). P08 adds a development Lagsanay HUD and explained round results; P09 binds live final match results to the themed screen; P11 renders standalone DEBUG command poses, timing cues and generated tones. The shared event-overlay component remains a placeholder. The guided first-match script is implemented as a PLACEHOLDER-copy slice (2026-10-14, see [Guided first match](#guided-first-match--implemented-slice-2026-10-14-placeholder-copy)) and, since 2026-10-15, the first-Kangaroo and Bomb-Taya prompts, the real Library, the live HUD cues, the cheer and the accessibility controls are implemented on the scheduled full match (the default route); it has had no human novice, spectator or QA session, so P13-T04/T08/T10 stay open (see [P13 evidence](evidence/p13/README.md)).
