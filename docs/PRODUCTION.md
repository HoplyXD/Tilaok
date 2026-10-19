# Tilaok! Production Plan

**Networked live-build track:** approved target direction is recorded in [NETWORKED_LIVE_BUILD.md](NETWORKED_LIVE_BUILD.md); all implementation and verification is future work tracked separately in [PHASETASK_NETWORKED_LIVE_BUILD.md](PHASETASK_NETWORKED_LIVE_BUILD.md). It does not change October submission staffing, gates or deadlines. The current platform/export records remain the offline baseline.

**Status:** pre-production planning document with implemented P02 movement/input, P03 graybox stage/camera/support, P04 item infrastructure/Kaing/Tulay, P05 construction loop, P06 Karera/scoring, and P07–P09 development routes plus synthetic engineering verification. P07 human/device acceptance, P08 entry/release gate and P09 performance/human acceptance remain open; do not mark release gates complete. Francis is lead developer and Carlos is co-lead developer; both use AI-assisted programming. Shanti handles UI design and game audio; Jorge and Ivie handle maps, characters, obstacles, traps, effects and related game assets. These human production outputs will not be AI-generated. `ROADMAP.md` remains the scope and schedule source of truth.

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
| **Required** | Team-directed local 2–4 player core loop under the standing AI-assisted programming workflow; Karera and scoring; Lagsanay; independent Kangaroo; the three approved event stacks; tutorial/onboarding; title/results, Library, settings/help, and essential audio/visual cues; all eight first-batch families (Hollow Blocks / Kaing Stack, Tulay na Kawayan, Gulong Talon, Trumpo sa Riles, Parol Pulse, Bula-Bulaklak, Tsinelas Launcher, Walis Cleanup) and applicable approved variants. Tulay vertical orientation remains conditional on controller-support verification. | P08's standalone Lagsanay, P09's Karera match end/tied-player sudden death, and P11's standalone Kangaroo development route have technical engineering evidence, but none of these routes makes release eligibility or the event schedule/stacks complete. P11 is 13/13 technical tasks with synthetic tests and exported startup; its measured local debug p95 exceeds the provisional frame target. P07-T04 physical/player-session and human acceptance, P08 entry/release gate, P09/P11 performance and human acceptance, event scheduling/stacks, tutorial/product UI and release presentation remain open. Other variant contracts remain in `ITEMS.md` and `PRD.md`. |
| **Should** | Approved optional wall slide/jump extension; Langit-Lupa; richer skins/accessories; enhanced crowd audio; Barya; reviewed “Alam mo ba?” cards; session-only local win tally. | Wall movement is approved, implemented and automated-test verified (now enabled by default as core movement by owner decision on 2026-10-13; no human review); keep/defer is PENDING; it is not a required October target and cannot delay P04. Decide include/defer before feature freeze. Other Should work remains pending. |
| **Conditional finalist** | Qualification-dependent finalist materials and demonstration work. | Inactive unless the team qualifies. |
| **Expansion** | The other 28 catalog families, extra stages/events, and unapproved event pairs. | Outside submission obligations; not promoted. |

R1–R4 remain inactive. No family is cut, no backlog item is promoted, and no prototype profile changes the release target. Cross-event same-step ordering among command evaluation, timeout, pass, goal, and support destruction is resolved for the three verified pairs by the owner-approved table recorded in [p12_terminal_order_decision_table.md](evidence/p12/p12_terminal_order_decision_table.md) ([REQ-EVENT-002](PRD.md#req-event-002--review-unresolved-simultaneous-terminal-ordering), [P12-T03](PHASETASK.md#p12-t03), [P12-T04](PHASETASK.md#p12-t04)); standalone P11 keeps the accepted strict-earlier comparable hazard rule. The P11 local debug sample missed the provisional 16.67 ms p95 target. A 14-second local Windows process sample measured 306.7 MiB working set and 420.5 MiB private bytes, below the provisional 512 MiB private-memory ceiling for that run; exported/target-PC performance and memory evidence remains incomplete. Local-only gameplay remains an architectural 0 B/s target, not a packet-capture result.

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

1. Verify the intended engine toolchain; implement input/movement, camera and graybox under the standing AI-assisted programming workflow using PROTOTYPE_DEFAULTS.md. No engine-version change is implied. The approved wall-movement extension is separate Should work after P03 and may not delay step 2 or required loop gates.
2. Build Kaing Stack and Tulay na Kawayan with Pugad, atomic Place, Karera and one-time round scoring. Construction prerequisites precede Lagsanay.
3. Verify persistent placement/reset, minimal onboarding and three/four-player input/camera. Add Gulong Talon after both construction pieces pass.
4. Implement Lagsanay independently: tag, placement scoring, Last Cluck and solid-floor containment; enable items only after compatibility checks.
5. Complete first-to-10/round-12 results, tied-match Lagsanay sudden death, full tutorial and repeatable restart. Earlier race-only scaffolding is not this full gate.
6. Implement Kangaroo independently from the current contract; P11 technical route and engineering checks pass (2026-10-14). Unapproved rule-change proposals remain inactive; human/device/balance gates stay open.
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
- Treat wall slide/jump as a separate approved Should extension, not an automatic submission requirement. Schedule it after P03 only when it does not delay P04 or the required loop; decide include/defer before October 21. Preserve the P03 base route without requiring wall movement.
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
| M0 Movement and stage foundations | **PARTIAL:** P02 diagnostic room has four numbered/shape-marked seats, synthetic input routing, measured movement and bounds probes; P03's protected graybox route, bounded camera and support contract passed. Physical keyboard/gamepad coverage remains open; P03 does not complete a round or item system. | Items, events, final art |
| M1 Two-player round | Lobby → Pugad → Place → Karera → score → next round twice; one egg/placement/outcome per player; timeout/invalid feedback; move/jump/place hints visible. **PARTIAL (2026-10-14):** P07's scoped player-facing route and exact pool restriction pass 590 synthetic assertions; P06/P05 real-goal engineering runners cover score/results/reset bindings. Two human-driven rounds, novice comprehension, fresh participant inputs and human onboarding review remain open. | Lagsanay, spring, hazards, match ties |
| M2 Persistence | Ten round resets preserve construction and never duplicate score; Kaing/Tulay boundary/one-way tests pass; then spring passes launch/reset checks. **PARTIAL (2026-10-14):** P07's reset audit completed ten scripted goal/results/next-round transitions, preserving IDs/signatures and scores while clearing actors/transients and rejecting duplicate awards; the full-match reset clears construction and totals. This is not a human-driven ten-round playtest. | Bubble and advanced first-batch hazards |
| M3 Three/four-player loop | Three rounds at each count; all targets visible; supported simultaneous input, slot/device rotation, disconnect/reclaim and pause/resume pass. **PARTIAL (2026-10-14):** P07 has local 2/3/4-seat render/performance samples and a synthetic 4/4 minimum-zoom visibility check. Physical rounds, participant rotation, isolation, pause/reclaim and reconnect coverage remain open. | Additional events or stages |
| M4 Lagsanay alone | **PASSED as P08 engineering scope (2026-10-14):** 2/3/4-player contact, stationary overlap, immunity, opening freeze, timer, placement ties, Last Cluck, containment retry, and actual Trumpo/Launcher attribution pass on synthetic seats. Human feel/fairness, physical-device coverage and independent review remain open. | Kangaroo and stacks |
| M5 Full match/restart | First-to-10 and round-12 paths, equal scores → sudden death → one winner, tutorial replay, return/replay and ten complete restarts pass | Extra catalog and production art |
| M6 Kangaroo alone | **PASSED as P11 engineering scope (2026-10-14):** standalone route, commands/support rows/bands, markers, pressure/Storm, Hug, Last Cluck, scoring and cleanup pass with synthetic 2/3/4 seats. Human comprehension, physical-device coverage, balance/cultural review, final assets and performance target remain open; see [P11 evidence](evidence/p11/README.md). | New events and unlisted stacks |
| M7 Required stacks | Each of the three pairs passes 2/3/4-player completion, Main-only scoring, secured exclusion, outcome ordering and announcements | Any additional pairing |
| M8 Submission candidate | Export/full match/restart/onboarding/readability and performance measured on named hardware; licensed assets, AI disclosure, media/forms reviewed | Unaccepted optional scope |

M1–M3 use the labeled race-only development profile. P02 is not a full lobby-to-match loop and does not complete M0's physical-device acceptance. A tied-leader display does not claim resolved sudden death or a release-complete match. Required Lagsanay schedule and sudden death remain mandatory for release. Construction-only all-finish no-score rounds are expected at three/four players; preserve scoring rather than hiding that slice limitation.

### P02 delivery record — October 13, 2026

Historical P02 delivery evidence records 8/14 original task records verified. With the October 13 approved wall-movement extension, P02 had 14/22 tasks checked; six of the eight new Should tasks (T15–T17, T19–T21) are checked on automated evidence and T18/T22 stay open. The October 14 sneak/glide/64 px grid/stage-blocks extension (user request) adds P02-T23–T26 with T23–T25 checked on automated evidence, so P02 is now 17/26. The fixture supports synthetic four-seat routing, identity markers, measured run/jump, pass-through bodies with contact sensing, pause/reconnect state probes, and labeled containment defect recovery. Godot 4.7.2 foundation regressions and 83 focused P02 assertions pass; the Windows export and headless startup pass. Wall movement has its own automated evidence in `docs/evidence/p02-wall/`; it has no human review. See `PLAYTEST.md` and `PHASETASK.md` for exact procedures and evidence.

Physical identical-gamepad isolation, mixed input, keyboard rollover, unplug/replug, and exported interactive-input checks remain open. The P02 rendered sample is one 1152×648 graybox run, not the 1080p/late-game performance gate; no pre-P02 rendered comparison exists. P01-T02 human review evidence and competition eligibility interpretation remain unresolved. P02 was AI-generated under the authorization then in force; the standing workflow is now recorded in `AI_USAGE.md`. Neither implementation nor this policy records team review or organizer acceptance. P03 status is limited to the graybox contracts; do not treat these slices as a complete game or release candidate.

### P03 graybox delivery record — October 13, 2026

P03-T01–T06 are verified. The arena uses the documented 1024×512-wu bounds and protected grid, and the real P02 controller traverses the base route with collision. The bounded Play/Place camera passed 2/3/4-target extent checks, a maximum 900-wu/s launch, target lifecycle transitions and rendered 1080p/wide-window checks. Explicit support provenance/contact/invalidation passed its focused fixture matrix. The uncapped 1080p sample recorded median 0.826 ms, p95 1.426 ms, worst 6.141 ms, 67.60 MiB Godot static memory, 199.91 MiB peak working set and 250.59 MiB peak private bytes over 600 frames on the local RTX 4050 machine. A Windows Desktop export and three-frame headless startup passed. Exact records are in `PLAYTEST.md`, `PHASETASK.md` and `docs/evidence/p03/2026-10-13_p03_verification.md`.

This is diagnostic geometry and fixture-contract evidence. It is not player-feel or final-art review, late-game stress, Pugad/atomic placement, production item/event implementation, full match testing, physical-device coverage, independent human review or organizer acceptance. P03 programming and test/documentation assistance is recorded in `AI_USAGE.md`; no AI-generated final art or audio was created.

### P04 item-infrastructure delivery record — October 13, 2026

P04-T01–T09 and T14–T18 are verified (14/22; early exit met): typed item definitions with one validator, a lifecycle/cap manager, and the Kaing and Tulay seeds with real-controller harness evidence, an interactive Item Lab, 1080p captures, a 48-piece performance sample and a Windows export smoke. T10–T13 and T19–T22 are blocked on P05 preview infrastructure, later modes/stacks, the Library schema and human Art/UI assets. Art and cultural checks for Kaing/Tulay are recorded follow-ups (Jorge/Ivie; Compliance), not code gates, per the owner decision of 2026-10-13. Seeds are runtime-enabled for the development `karera_slice` profile only; `release_target` stays false. No human review, physical-device evidence or production asset exists for this slice.

### P06 Karera and scoring delivery record — October 14, 2026

P06-T01–T08 passed. The live development room uses the arena goal trigger, active-simulation race deadlines, same-step outcome batching, an idempotent ledger, exact integer-unit race scoring, explained results and current placement arithmetic. Focused and dependent regressions passed, Godot 4.7.2 import/export/startup smoke passed, and ten repeated scripted rounds per 2/3/4-seat profile stayed within the local frame/static-memory targets. The local machine used K1/K2 plus synthetic gamepad identities; no physical device or human session/review is claimed. The code-built results panel uses DEBUG placeholder UI. At this historical P06 verification point, P10 hazard families, Barya gameplay, Lagsanay, event stacks and match-ending/sudden-death orchestration were future gates. Barya was implemented later on the default P12 route on 2026-10-15; its remaining human, device and production-asset gates are recorded in [Barya evidence](evidence/barya/README.md). See [P06 verification](evidence/p06/2026-10-14_p06_verification.md); AI assistance is recorded in `AI_USAGE.md`.

### P07 First Playable engineering delivery — October 14, 2026

The dedicated P07 harness route preserves the `karera_slice` profile identity and applies an instance-only allowlist for Kaing 1×1, Kaing Stack 2×3 and Tulay 4×1. It validates each generated Pugad pool and returns to Lobby with a diagnostic if any unsupported variant appears. Shared tuning and other profiles were not changed. Automated route checks passed 590 assertions; a synthetic ten-transition reset audit passed 172 checks, including stable item IDs/signatures, removed-piece persistence, actor/transient cleanup, once-only scoring and full-match reset clearing. Foundation, input/movement, stage/camera, item, match-flow, scoring and UI regressions, Godot import, Windows export and exported headless P07 startup passed. Project-runner 1080p captures and 2/3/4-seat performance samples are indexed in [P07 evidence](evidence/p07/README.md).

P07-T01–T04 remain unchecked. There are no human session logs, novice observations, human-used ten-reset ledger or independent reviews. This machine has one keyboard and no gamepads; P02-T08 and P07 device acceptance remain COULD-NOT-RUN. The exported UI screenshots were not captured; the available 1080p images come from the scripted project runner. Full-match ending, Lagsanay, sudden death and final art/UI remain open. No GDD design change or AI-generated production asset was made. See [P07 evidence](evidence/p07/README.md) and the dated verification record in `PLAYTEST.md`.

### P08 independent Lagsanay engineering delivery — October 14, 2026

OpenAI Codex implemented the P08 standalone development room, independent seeded taya controller, validated head-start/countdown/pass-back tuning, live overlap arbitration and stale-contact cleanup, elimination batch/reassignment, integer eighth-point placement/Patibong/Bawi scoring, an adapted P08-only hazard attribution sink, timestamp-compatible Last Cluck arithmetic/results explanation, profile/harness route, focused tests, rendered evidence and documentation. It reuses Lobby → Pugad → Place → Lagsanay → results → next round on the persistent stage without constructing a race controller or enabling Karera deadlines/scoring. The `lagsanay_lab` development allowlist contains only Hollow Blocks, Tulay na Kawayan, Trumpo and Tsinelas Launcher; only Trumpo/Launcher direct lethal contact is enabled and verified. All P08 timing values remain provisional; no taya speed bonus or R1–R4 change was made.

P08-T01–T06 passed technical acceptance (6/6). The focused unit runner passed 86 checks; rendered 2/3/4-seat interaction passed 87 checks; all 13 existing regressions passed; Godot 4.7.2 import, Windows Debug export and exported standalone startup passed. Actual Trumpo and Tsinelas Launcher attribution reached the independent mode sink. Rendered 1080p p95/worst intervals stayed below 16.67 ms; Godot static memory was 87.91–88.91 MiB; external Windows process-tree working set/private-byte peaks were 287.78/422.09 MiB. The three restart triggers were synthetic `escaped_bounds` signals, not physical escapes. Logs, screenshots, exact commands and boundaries are in [P08 evidence](evidence/p08/README.md).

All seats were synthetic; no independent human code review, human playtest, novice-comprehension or physical-device session is claimed. The authorized P08 work used a provisional development-only override for P07-T04; P07-T04 remains unchecked with its actual player/device/human acceptance intact. P02 physical input/reconnect gates also remain open. This engineering delivery does not complete the P08 release/entry gate, P09 full match, any event stack, final production UI/assets, competition review or Form 03 process. See [P08 tracker records](PHASETASK.md#p08--lagsanay) and [evidence](evidence/p08/README.md).

### P09 match lifecycle and sudden death — October 14, 2026

OpenAI Codex implemented the pure match-level coordinator and P09 development room, keeping round outcomes/awards separate from match totals. The route commits Karera awards once, uses the exact 80-eighth-point threshold or completed round 12, and starts Lagsanay sudden death with only tied top original seats on the current constructed stage. It binds live final results to the themed match-result screen with exact scores, one winner, ordinary/Last Cluck outcome, and Replay/Return to Lobby/Quit. The results flow includes unanimous fresh readiness, focus/device invalidation, seat reclaim and shared Quit/whole-group-leave confirmation. Replay retains original seats/devices and derives a new deterministic seed from configured base seed plus next match identity. It retains P07's three-variant allowlist and does not add the P12 schedule/stacks or weaken release-profile validation.

P09-T01–T04 pass technical acceptance (4/4). Godot 4.7.2 passed 77 focused assertions and 108 rendered interaction assertions; the rendered run used real Godot contact transfer but synthetic seats, shortened timers and injected race candidates. The ten-cycle audit passed with five score-threshold and five round-limit sudden-death endings, followed by Replay or Lobby. After cycle 3, object-count deltas ranged from −5 to +1 and static-memory deltas from −97,572 to +249,784 bytes; process-tree peaks were 292.3 MiB working set and 426.7 MiB private bytes. The latest warmed 1080p frame sample was median 9.52 ms, p95 27.78 ms and worst 55.60 ms (overall run worst 144.38 ms), above the 16.67 ms p95 target. Performance acceptance remains open. Regression logs, captures, export and smoke evidence are indexed in [P09 evidence](evidence/p09/README.md).

No human review, human playtest, physical-device session, or final-art/audio work is claimed. Last Cluck attribution in the P09 room is a synthetic record because P07's allowlist contains no hazards; P08's separate regression covers actual Trumpo/Launcher attribution. P07 player/device gates, P08 entry/release gate, P12 schedule/stacks, release acceptance and Form 03 remain open.

### P13 UX, onboarding and accessibility — October 15, 2026

P13 is 11/18 (T01, T03, T05, T06, T07, T09, T13, T14 and the 2026-10-17 reference restyle T15–T17) on synthetic engineering evidence; Shanti's design review of the restyle and the physical keyboard/gamepad pass are P13-T18 ([PLAYTEST Sheet G](PLAYTEST.md#sheet-g--p13-t18-reference-restyle-review)); the scheduled full match is now the default player route. Remaining before the Oct 21 freeze review, all needing people or devices: the keyboard chord session ([PLAYTEST Sheet A](PLAYTEST.md#sheet-a--p02-t03--p02-t04-physical-keyboard-chords-recorder), owner), two identical gamepads for P13-T02 / P02-T08, spectator, novice and QA sessions (Sheets C–E), the cheer check (Sheet F), Filipino / Hiligaynon review of the Library and tutorial copy, and Shanti's font and cue replacements ([ASSETS P13 register](ASSETS.md#placeholders-recorded--p13-2026-10-15)). Evidence: [P13](evidence/p13/README.md).

## Team and integration defaults

**U — UNKNOWN FACT:** Francis and Carlos are the supplied development leads; Shanti handles UI design and game audio; Jorge and Ivie handle game maps and assets. Individual task assignments, available hours, registration status and review/backup assignments remain unknown. Retain the workstreams above; combine responsibilities only where capacity permits. QA/review should involve someone other than the feature author where team size allows. Do not invent team members. Each active feature needs an assigned owner and an explicit review responsibility; record actual review only when performed.

**P:** choose one gate and acceptance scenario at the start of a session. Use small feature branches and review behavior/provenance before integration. Produce a labeled daily build once runnable systems exist; record engine, build, profile, seed and blockers. A playable build launches on the selected PC, accepts its claimed devices, completes its stated loop, explains controls/results and restarts cleanly. A skeleton/import/document is never a playable build.

Required equipment facts: target OS/CPU/GPU/RAM/display resolution; keyboard model/layout; controller models/count and wired/wireless connection; intended engine binary and export-template availability. The supplied workstation has K1/K2 keyboard input but no gamepads; the keyboard model/layout and physical rollover remain unrecorded. Godot 4.7.2 and matching export templates are installed and a Windows export was verified. Unknown facts block unsupported runtime/coverage claims.

Device checklist: map every button/axis, verify neutral drift, simultaneous direction+jump for all seats, opposite-input neutralization, placement navigation/rotate/confirm rollover, unplug/replug without identity change, two identical controllers reclaiming the correct seats, focus pause and isolated mixed keyboard/gamepad input. P02 synthetic tests are not physical-device evidence; this session has no gamepads and has not tested keyboard rollover. Repeat on the exported build and intended connection type. Four-player keyboard-only support is not assumed.

Temporary art: one short review chooses geometric chicken placeholders, clear solid/hazard silhouettes and number+shape markers. Use engine-provided typography for graybox; verify/register terms before export. Require legible numbers, needed Philippine-language glyphs, distinct symbols and readable 1080p/minimum-zoom text. Final art style/font family/audio and cultural review do not block movement testing. Record provenance in ASSETS.md.

Inspection on October 12 found only a skeleton. At documentation completion on October 13, about eight calendar days remain to October 21 feature freeze and twelve to October 25 submission. The existing required scope is high risk, not guaranteed by a calendar. Seek core-loop evidence October 13–16; independent modes/stacks October 17–20 only after gates; October 21 is the last feature-entry decision. October 22–23 stabilize, October 24 prepare media/forms, October 25 submit. If gates slip, the producer must explicitly revise release scope. Do not silently remove Lagsanay, Kangaroo or stacking, or spend the only gameplay capacity on final assets.

## Product and execution handoff

Use [PRD](PRD.md) for consolidated requirements and [PHASETASK](PHASETASK.md) for stable task IDs and evidence. Title/results, Library, settings/help, tutorial and essential audio/visual cues are required. Wall slide/jump is implemented and automated-test verified as core movement, but human review and the Should include/defer decision remain open. Session-only win tally, enhanced crowd, Langit-Lupa, richer cosmetics and reviewed educational cards remain Should work. Barya remains Should content, implemented on the default P12 route on 2026-10-15; human play/accessibility/cultural review and final art remain open. No source decision checkbox is implementation evidence. Registration/forms/synopsis/storyboards and provenance preparation run early in parallel; final media uses the tested RC. Development leads are recorded above; individual assignments/capacity remain unknown. The target PC is identified and inventoried above; keyboard rollover and physical controller verification remain open.
