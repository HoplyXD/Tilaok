# Tilaok! Production Plan

**Status:** pre-production planning document. Team roles are unassigned as of 2026-10-12. `ROADMAP.md` remains the scope and schedule source of truth.

## Delivery principle

Ship a small, stable, understandable local-multiplayer game before adding breadth. The core loop, Karera, scoring, Lagsanay, tutorial, and the eight targeted first-batch families take priority over backlog content.

All gameplay systems, controls, scenes, and game logic must be written and understood by registered team members. Documentation, research attribution, and review can be AI-assisted when accurately declared in Form 03.

## Role assignment sheet

Fill names before production work begins. A person may hold more than one role only when the workload remains realistic.

| Workstream | Primary owner | Backup/reviewer | Responsibilities |
|---|---|---|---|
| Production and integration | **TBD** | **TBD** | Scope calls, branch/integration hygiene, daily build, schedule, and final submission. |
| Team-authored gameplay | **TBD** | **TBD** | Godot project, controls, stages, round lifecycle, placement, scoring, items, events, and save-free local match flow. |
| Art and UI | **TBD** | **TBD** | 2D visual direction, chicken readability, stage, item/event art, menus, accessibility cues. |
| Audio | **TBD** | **TBD** | SFX, crowd reactions, music direction, mixing, and asset provenance. |
| QA and balance | **TBD** | **TBD** | Test matrix, local multiplayer sessions, defect log, performance notes, balance evidence. |
| Compliance and media | **TBD** | **TBD** | Forms, AI/asset register, cultural review, synopsis, trailer, demo video, and screenshots. |

## Implementation order after documentation sign-off

1. Verify the intended engine toolchain; team-author input/movement, camera and graybox using PROTOTYPE_DEFAULTS.md. No engine-version change is implied.
2. Build Kaing Stack and Tulay na Kawayan with Pugad, atomic Place, Karera and one-time round scoring. Construction prerequisites precede Lagsanay.
3. Verify persistent placement/reset, minimal onboarding and three/four-player input/camera. Add Gulong Talon after both construction pieces pass.
4. Implement Lagsanay independently: tag, placement scoring, Last Cluck and solid-floor containment; enable items only after compatibility checks.
5. Complete first-to-10/round-12 results, tied-match Lagsanay sudden death, full tutorial and repeatable restart. Earlier race-only scaffolding is not this full gate.
6. Implement Kangaroo independently from the current contract; unapproved rule-change proposals remain inactive.
7. Implement all three core stacks after their components pass. Karera + Lagsanay can be tested earlier once both work; Kangaroo-dependent stacks wait for Kangaroo.
8. Complete all eight targeted families and applicable approved variants, art/audio, performance and submission evidence where dependencies permit. Bubble capture stays last; stacking remains release scope.

No step is evidence of completion until it has the required team-written implementation and `PLAYTEST.md` evidence.

## Feature gates

| Gate | Entry condition | Exit condition |
|---|---|---|
| Documentation sign-off | GDD, item, stage, UI, asset, production, submission, and verification documents reviewed by the team. | Remaining unknowns are assigned an owner or explicitly deferred. |
| Core loop | Team-authored project and basic player controller exist. | 2–4 local players can complete Pugad → Place → Karera → results → next round without duplicate placement/scoring. |
| Lagsanay | Core loop and scoring work. | Tag, taya timer, elimination placement, Last Cluck, and 2/3/4-player tests pass. |
| Construction seed set | Movement, stage and atomic placement work. | Kaing/Tulay enable the base loop before Lagsanay; spring follows their validation. |
| Remaining first item set | Core loop and relevant event foundations are stable. | Accepted items satisfy lifecycle and counterplay contracts. |
| Core event stacks | Karera, Lagsanay, and Kangaroo work alone. | Karera + Lagsanay, Karera + Kangaroo, and Kangaroo + Lagsanay pass their compatibility tests. |
| Content freeze | Required systems, tutorial, and selected item set are stable. | No new feature enters without replacing a lower-priority approved feature. |
| Submission candidate | Build, test evidence, and compliance records are complete. | Trailer, demo, forms, synopsis, and final package are reviewed and submitted. |

## Scope protection and cut order

- Preserve the Pugad → Place → Play loop, Karera, scoring, Lagsanay, tutorial, and clear local multiplayer controls.
- Preserve all eight initial families as the approved October 13 submission target, with applicable approved variants and conditional Tulay orientation validation. If implementation capacity slips, seek an explicit team decision before cutting a family; the recommended first cut is Bula-Bulaklak because capture state and forced movement have the most dependencies.
- Keep expanded catalog items, Langit-Lupa implementation, extra stages, cosmetics, and nonessential polish behind the core gates.
- Do not silently replace an approved event, scoring rule, or compatibility contract.

## Definition of ready

A feature may enter team implementation only when it has:

- a GDD rule or approved written contract;
- clear player-facing tell and counterplay;
- lifecycle, reset, ownership, scoring, and event-stack behavior where relevant;
- asset and cultural-review status;
- acceptance scenarios in `PLAYTEST.md` or its own specification;
- a named team owner.

## Definition of done

A feature is done only when:

- team-written implementation is integrated into the target Godot 4.7 project;
- its intended controls and local multiplayer behavior work for supported player counts;
- it passes documented functional, reset, scoring, and accessibility checks;
- new or changed assets are registered and licensed;
- any AI assistance is accurately recorded;
- no critical regression appears in a full match/restart test.

## Active production risks

| Risk | Effect | Mitigation |
|---|---|---|
| Short schedule | Too many systems reach implementation at once. | Enforce gates and cut optional scope early. |
| Event-stack complexity | Unclear outcomes or untestable combinations. | Enable only the three written compatibility pairs; test each in 2/3/4-player sessions. |
| Persistent stage clutter | Unfair locks, unreadability, performance problems. | Atomic placement rules, Walis Cleanup, item caps, protected zones, and repeated-match profiling. |
| Cultural claim error | Theme and credibility risk. | Use the cultural ledger, evidence, and native-speaker review. |
| Asset/compliance gap | Competition eligibility risk. | Register every imported asset and keep Form 03 evidence current. |
| Local-device limits | Controls or performance fail at demo time. | Identify the target team PC and test all intended controllers early. |

## Immediate non-code tasks

1. Assign the role owners above.
2. Review the full documentation package and resolve only player-facing wording changes.
3. Choose the 2D art direction and font approach; record both in `ASSETS.md`.
4. Identify a native-speaker/cultural reviewer for final public copy.
5. Identify the target team PC and available controllers for future verification.

## Prototype milestones — all pending implementation

A smaller milestone is not a release-scope cut. Each exit is binary; functionality must be demonstrated, not merely described.

| Milestone | What it proves / exit checks | Not yet needed |
|---|---|---|
| M0 Movement room | Two inputs control only their own marker; measured full/short jump, braking, bounds, pause and restart meet the specification | Items, events, final art |
| M1 Two-player round | Lobby → Pugad → Place → Karera → score → next round twice; one egg/placement/outcome per player; timeout/invalid feedback; move/jump/place hints visible | Lagsanay, spring, hazards, match ties |
| M2 Persistence | Ten round resets preserve construction and never duplicate score; Kaing/Tulay boundary/one-way tests pass; then spring passes launch/reset checks | Bubble and advanced first-batch hazards |
| M3 Three/four-player loop | Three rounds at each count; all targets visible; supported simultaneous input, slot/device rotation, disconnect/reclaim and pause/resume pass | Additional events or stages |
| M4 Lagsanay alone | 2/3/4-player contact, stationary overlap, immunity, opening freeze, timer, placement ties, Last Cluck and containment pass; actual trap attribution checked when a hazard exists | Kangaroo and stacks |
| M5 Full match/restart | First-to-10 and round-12 paths, equal scores → sudden death → one winner, tutorial replay, return/replay and ten complete restarts pass | Extra catalog and production art |
| M6 Kangaroo alone | Commands/support rows/bands, markers, pressure, Hug and Last Cluck pass for 2/3/4 players; current contract distinguished from inactive proposals | New events and unlisted stacks |
| M7 Required stacks | Each of the three pairs passes 2/3/4-player completion, Main-only scoring, secured exclusion, outcome ordering and announcements | Any additional pairing |
| M8 Submission candidate | Export/full match/restart/onboarding/readability and performance measured on named hardware; licensed assets, AI disclosure, media/forms reviewed | Unaccepted optional scope |

M1–M3 use the labeled race-only development profile. A tied-leader display does not claim resolved sudden death or a release-complete match. Required Lagsanay schedule and sudden death remain mandatory for release. Construction-only all-finish no-score rounds are expected at three/four players; preserve scoring rather than hiding that slice limitation.

## Team and integration defaults

**U — UNKNOWN FACT:** all owner names and available hours remain TBD. Retain the six workstreams above; combine production with compliance/media, gameplay with integration, and art/UI with audio where capacity permits. QA/review should involve someone other than the feature author where team size allows. Do not invent team members. Each active feature needs a named registered-team owner and an explicit review responsibility.

**P:** choose one gate and acceptance scenario at the start of a session. Use small feature branches and review behavior/provenance before integration. Produce a labeled daily build once runnable systems exist; record engine, build, profile, seed and blockers. A playable build launches on the selected PC, accepts its claimed devices, completes its stated loop, explains controls/results and restarts cleanly. A skeleton/import/document is never a playable build.

Required equipment facts: target OS/CPU/GPU/RAM/display resolution; keyboard model/layout; controller models/count and wired/wireless connection; intended engine binary and export-template availability. These facts can remain TBD in this handoff, but block unsupported runtime/coverage claims.

Device checklist: map every button/axis, verify neutral drift, simultaneous direction+jump for all seats, opposite-input neutralization, placement navigation/rotate/confirm rollover, unplug/replug without identity change, two identical controllers reclaiming the correct seats, focus pause and isolated mixed keyboard/gamepad input. Repeat on the exported build and intended connection type. Four-player keyboard-only support is not assumed.

Temporary art: one short review chooses geometric chicken placeholders, clear solid/hazard silhouettes and number+shape markers. Use engine-provided typography for graybox; verify/register terms before export. Require legible numbers, needed Philippine-language glyphs, distinct symbols and readable 1080p/minimum-zoom text. Final art style/font family/audio and cultural review do not block movement testing. Record provenance in ASSETS.md.

Inspection on October 12 found only a skeleton. At documentation completion on October 13, about eight calendar days remain to October 21 feature freeze and twelve to October 25 submission. The existing required scope is high risk, not guaranteed by a calendar. Seek core-loop evidence October 13–16; independent modes/stacks October 17–20 only after gates; October 21 is the last feature-entry decision. October 22–23 stabilize, October 24 prepare media/forms, October 25 submit. If gates slip, the producer must explicitly revise release scope. Do not silently remove Lagsanay, Kangaroo or stacking, or spend the only gameplay capacity on final assets.

## Product and execution handoff

Use [PRD](PRD.md) for consolidated requirements and [PHASETASK](PHASETASK.md) for stable task IDs and evidence. Title/results, Library, settings/help, tutorial and essential audio/visual cues are required. Session-only win tally, enhanced crowd, Barya, Langit-Lupa, richer cosmetics and reviewed educational cards are Should; decide include/defer before freeze. No source decision checkbox is implementation evidence. Registration/forms/synopsis/storyboards and provenance preparation run early in parallel; final media uses the tested RC. All owners and physical hardware facts remain TBD until the team supplies evidence.
