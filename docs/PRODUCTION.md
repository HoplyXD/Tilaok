# Tilaok! Production Plan

**Status:** pre-production planning document with an implemented P02 movement/input diagnostic slice. Francis is lead developer and Carlos is co-lead developer; both use AI-assisted programming. Shanti handles UI design and game audio; Jorge and Ivie handle maps, characters, obstacles, traps, effects and related game assets. These human production outputs will not be AI-generated. `ROADMAP.md` remains the scope and schedule source of truth.

## Delivery principle

Ship a small, stable, understandable local-multiplayer game before adding breadth. The core loop, Karera, scoring, Lagsanay, tutorial, and the eight targeted first-batch families take priority over backlog content.

AI/LLM-assisted programming, including core gameplay generation, is the standing project workflow directed by Francis. Francis and Carlos direct development and retain integration, review, testing and delivery responsibility. See `AI_USAGE.md` for the detailed policy and disclosure record. This policy does not establish organizer approval or competition eligibility; P01-T02's actual human review evidence remains open, and Form 03 is a separate submission obligation.

## Role assignment sheet

Fill remaining individual assignments and backups before allocating production work. A person may hold more than one role only when the workload remains realistic.

| Workstream | Primary owner | Backup/reviewer | Responsibilities |
|---|---|---|---|
| Development leadership and programming | **Francis — lead developer**; **Carlos — co-lead developer** | **TBD** | Direct programming with AI/LLMs as primary code generators; retain integration, review, testing and delivery responsibility. Individual task assignments and capacity are not recorded. |
| UI design | **Shanti** | **TBD** | Game UI design and related visual work; human-created without AI asset generation. |
| Game audio | **Shanti** | **TBD** | Human-created game audio; no AI-generated audio. |
| Game maps and assets | **Jorge and Ivie** | **TBD** | Human-created maps, characters, obstacles, traps, effects and related game assets; no AI asset generation. |
| Other production | **Human team; individual assignments TBD** | **TBD** | Other production work; no individual creator or assignment is inferred. |
| QA and balance | **TBD** | **TBD** | Test matrix, local multiplayer sessions, defect log, performance notes, balance evidence. |
| Compliance and media | **TBD** | **TBD** | Forms, AI/asset register, cultural review, synopsis, trailer, demo video, and screenshots. |

## P00 baseline record

**Date:** October 13, 2026.

**Source revision:** `fa6145839bff96ecb6e1afdb112e804bfb72260f` (`origin/main` at inspection). P00 work is isolated on `feat/p00-production-readiness`. The original Desktop checkout remains at detached `791084a` with its user changes preserved. The Markdown inventory at checkout creation contains 18 project files: `AGENTS.md`, `CLAUDE.md`, `README.md`, and `docs/{AI_USAGE,ASSETS,COMPETITION,GDD,INDEX,ITEMS,PHASETASK,PLAYTEST,PRD,PRODUCTION,PROTOTYPE_DEFAULTS,ROADMAP,STAGE_AND_PLACEMENT,SUBMISSION,UI_TUTORIAL}.md`. Git internals are excluded; no `.godot` cache or third-party `addons` directory existed at inventory time. Godot's later diagnostics created only an ignored `.godot` cache in this worktree.

### Team ownership and capacity

Historical record — October 13, 2026, before Francis supplied current roles: the user directed that assignments and available hours be handled privately, so the then-current TBD role sheet and the statement that names were not recorded were accurate at that time. Current roles supplied afterward are shown in the role sheet above. No surnames or legal identities, membership/registration status, coach details, audio backup/review arrangements, hours, reviewer identities or capacity are inferred. At the earlier snapshot, no audio assignment had been supplied; Shanti's current audio role is recorded above. P00-T01 and P00-T02 remain open.

### Authority and release manifest

Authority for this baseline is reconciled as follows: **GDD** governs gameplay; specialized specifications elaborate their domains consistently; **PROTOTYPE_DEFAULTS** contains untested starting points; **ROADMAP** governs release priority and schedule; **PRD** consolidates requirements; **PHASETASK** records execution and verification evidence. A contradiction requires an explicit decision against the governing source; it does not promote a proposal or silently revise gameplay.

The release target below reuses the October 13 approval evidence already recorded in the GDD, PRD, and ROADMAP. This entry records that baseline and does not create a new ratification or identify an unnamed approver.

| Disposition | Recorded target | Implementation / verification state at this baseline |
|---|---|---|
| **Required** | Team-directed local 2–4 player core loop under the standing AI-assisted programming workflow; Karera and scoring; Lagsanay; independent Kangaroo; the three approved event stacks; tutorial/onboarding; title/results, Library, settings/help, and essential audio/visual cues; all eight first-batch families (Hollow Blocks / Kaing Stack, Tulay na Kawayan, Gulong Talon, Trumpo sa Riles, Parol Pulse, Bula-Bulaklak, Tsinelas Launcher, Walis Cleanup) and applicable approved variants. Tulay vertical orientation remains conditional on controller-support verification. | Targets only. P02 provides a diagnostic input/movement slice; no required item, complete mode, stack, match loop, tutorial or product UI is implemented/runtime-enabled. Variant contracts remain in `ITEMS.md` and `PRD.md`. |
| **Should** | Langit-Lupa; richer skins/accessories; enhanced crowd audio; Barya; reviewed “Alam mo ba?” cards; session-only local win tally. | Include/defer decision remains pending before feature freeze. Not promoted by this baseline. |
| **Conditional finalist** | Qualification-dependent finalist materials and demonstration work. | Inactive unless the team qualifies. |
| **Expansion** | The other 28 catalog families, extra stages/events, and unapproved event pairs. | Outside submission obligations; not promoted. |

R1–R4 remain inactive. No family is cut, no backlog item is promoted, and no prototype profile changes the release target. The uncovered same-step ordering among command evaluation, timeout, pass, goal, and support destruction remains assigned to [REQ-EVENT-002](PRD.md#req-event-002--review-unresolved-simultaneous-terminal-ordering) / [P12-T03](PHASETASK.md#p12-t03) and [P12-T04](PHASETASK.md#p12-t04); existing recorded-time/tie rules remain active until that review. Prototype budgets remain **UNMEASURED**: 60 FPS / 16.67 ms at 1080p, provisional 512 MiB process memory, and 0 B/s gameplay networking.

### Toolchain and target-PC inventory

The user identified the current PC as the development/demo target. The following are local observations, not controller compatibility or gameplay-performance results.

| Area | Observed / reported fact | Evidence boundary |
|---|---|---|
| Target PC | User-reported target: current PC. Windows reports Acer Nitro ANV15-51; Windows 10 Home Single Language, DisplayVersion 25H2, build 26200, 64-bit; Intel Core i5-13420H (8 cores / 12 logical processors); 34,049,220,608 bytes RAM (about 31.7 GiB); NVIDIA GeForce RTX 4050 Laptop GPU and Intel UHD; reported current output 1920×1080. | OS/API inventory only; performance is unmeasured. The OS product/build fields are recorded as reported by Windows and not independently reconciled. |
| Keyboard | Windows enumerated a Standard PS/2 Keyboard and HID Keyboard Device entries. | Physical model, layout, rollover, and intended player assignment are unknown; no key-chord test was performed. |
| Controllers | No gamepad/controller appeared in the queried Windows device inventory. | No model, count, connection type, button mapping, simultaneous-input, reconnect, or multi-controller test is confirmed. |
| Intended Godot | User reported Godot 4.7 in `D:\Downloads`; both `Godot_v4.7.2-stable_win64_console.exe` and its GUI sibling are present and report `4.7.2.stable.official.ed1daf0bf`. | The 4.7.2 console binary was used for the fresh diagnostic import below. |
| PATH Godot | `C:\Users\roman\tools\bin\godot.cmd` invokes `C:\Users\roman\Downloads\Godot_v4.6.3-stable_win64_console.exe`; `godot --version` reports `4.6.3.stable.official.7d41c59c4`. `C:\Users\roman\Desktop\Godot\godot.exe` reports `4.5.1.stable.official.f62fdbde1`. | Do not use the PATH wrapper as evidence of the intended editor. |
| Export templates | `%APPDATA%\Godot\export_templates\4.7.2.stable` now contains the official 4.7.2 templates (`version.txt`: `4.7.2.stable`), alongside unchanged `4.7.stable` and `4.5.1.stable` directories. | The official archive package hash and installed Windows x86_64 templates are recorded in [P01 template evidence](evidence/p01-template-install-2026-10-13.log). The official archive was extracted to the standard versioned directory; Godot's template-manager UI was not used. |
| Lint / format | `gdlint.exe` and `gdformat.exe` at `C:\Users\roman\AppData\Local\Programs\Python\Python312\Scripts\` both report 4.5.0. | P01 GDScript passes both checks; see [lint](evidence/p01-lint-2026-10-13.log) and [format](evidence/p01-format-2026-10-13.log). Tool version is older than the Godot editor. |
| Project/export setup | `tilaok!/project.godot` declares feature `4.7`, GL Compatibility and the foundation harness as entry scene; `tilaok!/export_presets.cfg` defines a Windows Desktop preset. | Godot 4.7.2 imports the project, headless foundation/runtime checks pass, and an exported Windows executable launched and closed on the target development PC. See [P01 import](evidence/p01-import-godot-4.7.2-2026-10-13.log), [export](evidence/p01-export-godot-4.7.2-2026-10-13.log), and [exported runtime](evidence/p01-export-runtime-2026-10-13.log). |

The historical P00 import results above remain unchanged. New P01 checks on the working project are recorded separately below; they do not retroactively change the P00 inspection record.

**P00 exit:** not satisfied. Some current development and production roles are now recorded, but the complete ownership/capacity evidence (including registration, hours, review assignments and remaining workstream coverage) is incomplete. P00-T06 also awaits its named owner and physical-device verification. Matching templates, working-project import, and a local export/runtime smoke check are now evidenced under P01. Keyboard details, physical controller inventory/testing, independent review and performance remain open. See [PHASETASK](PHASETASK.md#p00--baseline-and-production-readiness) for task-level status and blockers.

### P01 foundation and export evidence

**Date:** October 13, 2026. **Engine:** `4.7.2.stable.official.ed1daf0bf`. **Template package:** official 4.7.2 stable archive; SHA-256 and extracted version recorded in `evidence/p01-template-install-2026-10-13.log`. The archive was extracted to `%APPDATA%\Godot\export_templates\4.7.2.stable`; the existing 4.7 templates were left in place. Installation used the official package in the standard template directory, not the editor's template-manager UI.

P01 created the diagnostic harness, typed config/profile resources, content validation and seeded streams, three placeholder-only fixtures, Windows preset, and headless tests. Godot import/parse, test script, runtime smoke, formatting and lint checks passed. The release export created `build/tilaok-p01.exe`; the executable opened a responsive window and exited after a normal close request. Logs and test boundaries are linked from [PHASETASK P01](PHASETASK.md#p01--project-foundations) and [PLAYTEST](PLAYTEST.md#p01-foundation-verification).

Codex generated the P01 scripts/scenes/tests under the task authorization and internal policy in force at that time; see the historical disclosure in `AI_USAGE.md`. This is not described as manually team-written. P01-T02's human review evidence remains open; competition interpretation and submission obligations remain separate. Placeholder rooms are not gameplay. No controller, multiplayer, performance, clean-PC, or final-release evidence is implied. P00-T02 remains open and is not a prerequisite to P01 implementation. P00-T06 remains open for its required named-owner and physical-device verification; matching templates, import and an initial export are recorded as complete evidence.

## Implementation order after documentation sign-off

1. Verify the intended engine toolchain; team-author input/movement, camera and graybox using PROTOTYPE_DEFAULTS.md. No engine-version change is implied.
2. Build Kaing Stack and Tulay na Kawayan with Pugad, atomic Place, Karera and one-time round scoring. Construction prerequisites precede Lagsanay.
3. Verify persistent placement/reset, minimal onboarding and three/four-player input/camera. Add Gulong Talon after both construction pieces pass.
4. Implement Lagsanay independently: tag, placement scoring, Last Cluck and solid-floor containment; enable items only after compatibility checks.
5. Complete first-to-10/round-12 results, tied-match Lagsanay sudden death, full tutorial and repeatable restart. Earlier race-only scaffolding is not this full gate.
6. Implement Kangaroo independently from the current contract; unapproved rule-change proposals remain inactive.
7. Implement all three core stacks after their components pass. Karera + Lagsanay can be tested earlier once both work; Kangaroo-dependent stacks wait for Kangaroo.
8. Complete all eight targeted families and applicable approved variants, art/audio, performance and submission evidence where dependencies permit. Bubble capture stays last; stacking remains release scope.

No step is evidence of completion until the implementation and required `PLAYTEST.md` evidence are actually verified. Programming may be AI-assisted under the standing workflow; do not claim human review unless it occurred.

## Feature gates

| Gate | Entry condition | Exit condition |
|---|---|---|
| Documentation sign-off | GDD, item, stage, UI, asset, production, submission, and verification documents reviewed by the team. | Remaining unknowns are assigned an owner or explicitly deferred. |
| Core loop | Project and basic player controller exist, with implementation provenance recorded. | 2–4 local players can complete Pugad → Place → Karera → results → next round without duplicate placement/scoring. |
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

- implementation is integrated into the target Godot 4.7 project, with actual AI assistance and provenance disclosed;
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
| Local-device limits | Controls or performance fail at demo time. | Target PC is identified in P00; confirm available controllers and test them early. |

## Immediate non-code tasks

1. Assign the role owners above.
2. Review the full documentation package and resolve only player-facing wording changes.
3. Choose the 2D art direction and font approach; record both in `ASSETS.md`.
4. Identify a native-speaker/cultural reviewer for final public copy.
5. Confirm available controller models/connections and physical-test availability for the identified target PC.

## Prototype milestones — current status

A smaller milestone is not a release-scope cut. Each exit is binary; functionality must be demonstrated, not merely described.

| Milestone | What it proves / exit checks | Not yet needed |
|---|---|---|
| M0 Movement room | **PARTIAL:** P02 diagnostic room has four numbered/shape-marked seats, synthetic input routing, measured full/short jump, braking, bounds, pause/reclaim state probes and fixture cleanup; physical keyboard/gamepad coverage and exported interactive input/reconnect remain open | Items, events, final art |
| M1 Two-player round | Lobby → Pugad → Place → Karera → score → next round twice; one egg/placement/outcome per player; timeout/invalid feedback; move/jump/place hints visible | Lagsanay, spring, hazards, match ties |
| M2 Persistence | Ten round resets preserve construction and never duplicate score; Kaing/Tulay boundary/one-way tests pass; then spring passes launch/reset checks | Bubble and advanced first-batch hazards |
| M3 Three/four-player loop | Three rounds at each count; all targets visible; supported simultaneous input, slot/device rotation, disconnect/reclaim and pause/resume pass | Additional events or stages |
| M4 Lagsanay alone | 2/3/4-player contact, stationary overlap, immunity, opening freeze, timer, placement ties, Last Cluck and containment pass; actual trap attribution checked when a hazard exists | Kangaroo and stacks |
| M5 Full match/restart | First-to-10 and round-12 paths, equal scores → sudden death → one winner, tutorial replay, return/replay and ten complete restarts pass | Extra catalog and production art |
| M6 Kangaroo alone | Commands/support rows/bands, markers, pressure, Hug and Last Cluck pass for 2/3/4 players; current contract distinguished from inactive proposals | New events and unlisted stacks |
| M7 Required stacks | Each of the three pairs passes 2/3/4-player completion, Main-only scoring, secured exclusion, outcome ordering and announcements | Any additional pairing |
| M8 Submission candidate | Export/full match/restart/onboarding/readability and performance measured on named hardware; licensed assets, AI disclosure, media/forms reviewed | Unaccepted optional scope |

M1–M3 use the labeled race-only development profile. P02 is not a full lobby-to-match loop and does not complete M0's physical-device acceptance. A tied-leader display does not claim resolved sudden death or a release-complete match. Required Lagsanay schedule and sudden death remain mandatory for release. Construction-only all-finish no-score rounds are expected at three/four players; preserve scoring rather than hiding that slice limitation.

### P02 delivery record — October 13, 2026

P02 has an implemented diagnostic input/movement foundation and 8/14 task records verified. The fixture supports synthetic four-seat routing, identity markers, measured run/jump, pass-through bodies with contact sensing, pause/reconnect state probes, and labeled containment defect recovery. Godot 4.7.2 foundation regressions and 83 focused P02 assertions pass; the Windows export and headless startup pass. See `PLAYTEST.md` and `PHASETASK.md` for exact procedures and evidence.

Physical identical-gamepad isolation, mixed input, keyboard rollover, unplug/replug, and exported interactive-input checks remain open. The P02 rendered sample is one 1152×648 graybox run, not the 1080p/late-game performance gate; no pre-P02 rendered comparison exists. P01-T02 human review evidence and competition eligibility interpretation remain unresolved. P02 was AI-generated under the authorization then in force; the standing workflow is now recorded in `AI_USAGE.md`. Neither implementation nor this policy records team review or organizer acceptance. Do not enter P03/full-game or release status based solely on this slice.

## Team and integration defaults

**U — UNKNOWN FACT:** Francis and Carlos are the supplied development leads; Shanti handles UI design and game audio; Jorge and Ivie handle game maps and assets. Individual task assignments, available hours, registration status and review/backup assignments remain unknown. Retain the workstreams above; combine responsibilities only where capacity permits. QA/review should involve someone other than the feature author where team size allows. Do not invent team members. Each active feature needs an assigned owner and an explicit review responsibility; record actual review only when performed.

**P:** choose one gate and acceptance scenario at the start of a session. Use small feature branches and review behavior/provenance before integration. Produce a labeled daily build once runnable systems exist; record engine, build, profile, seed and blockers. A playable build launches on the selected PC, accepts its claimed devices, completes its stated loop, explains controls/results and restarts cleanly. A skeleton/import/document is never a playable build.

Required equipment facts: target OS/CPU/GPU/RAM/display resolution; keyboard model/layout; controller models/count and wired/wireless connection; intended engine binary and export-template availability. The supplied workstation has K1/K2 keyboard input but no gamepads; the keyboard model/layout and physical rollover remain unrecorded. Godot 4.7.2 and matching export templates are installed and a Windows export was verified. Unknown facts block unsupported runtime/coverage claims.

Device checklist: map every button/axis, verify neutral drift, simultaneous direction+jump for all seats, opposite-input neutralization, placement navigation/rotate/confirm rollover, unplug/replug without identity change, two identical controllers reclaiming the correct seats, focus pause and isolated mixed keyboard/gamepad input. P02 synthetic tests are not physical-device evidence; this session has no gamepads and has not tested keyboard rollover. Repeat on the exported build and intended connection type. Four-player keyboard-only support is not assumed.

Temporary art: one short review chooses geometric chicken placeholders, clear solid/hazard silhouettes and number+shape markers. Use engine-provided typography for graybox; verify/register terms before export. Require legible numbers, needed Philippine-language glyphs, distinct symbols and readable 1080p/minimum-zoom text. Final art style/font family/audio and cultural review do not block movement testing. Record provenance in ASSETS.md.

Inspection on October 12 found only a skeleton. At documentation completion on October 13, about eight calendar days remain to October 21 feature freeze and twelve to October 25 submission. The existing required scope is high risk, not guaranteed by a calendar. Seek core-loop evidence October 13–16; independent modes/stacks October 17–20 only after gates; October 21 is the last feature-entry decision. October 22–23 stabilize, October 24 prepare media/forms, October 25 submit. If gates slip, the producer must explicitly revise release scope. Do not silently remove Lagsanay, Kangaroo or stacking, or spend the only gameplay capacity on final assets.

## Product and execution handoff

Use [PRD](PRD.md) for consolidated requirements and [PHASETASK](PHASETASK.md) for stable task IDs and evidence. Title/results, Library, settings/help, tutorial and essential audio/visual cues are required. Session-only win tally, enhanced crowd, Barya, Langit-Lupa, richer cosmetics and reviewed educational cards are Should; decide include/defer before freeze. No source decision checkbox is implementation evidence. Registration/forms/synopsis/storyboards and provenance preparation run early in parallel; final media uses the tested RC. Development leads are recorded above; individual assignments/capacity remain unknown. The target PC is identified and inventoried above; keyboard rollover and physical controller verification remain open.
