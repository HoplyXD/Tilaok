# Tilaok! — Phased Implementation Tracker

**Version:** 1.0 · **Baseline:** October 13, 2026 · **Owner:** Producer (name TBD).

**Historical implementation baseline (before P01/P02):** no gameplay scenes/scripts, no export preset, no runnable game. Project/icon skeleton only. Documentation was prepared on `feat/prd-phasetask` from main `98ef17a74166b6ac10c7930dc48a00c488fe61c9`; original dirty `feat/filipino-obstacles-events` at `791084a` is preserved. The fetched merged source includes prototype defaults and newer Library/preview contracts. Engine declares 4.7; inspected CLI 4.6.3, lint/format 4.5.0. Historical import/document checks are not current gameplay evidence.

## How to use this tracker

- [PRD](PRD.md) consolidates requirements; [GDD](GDD.md) remains gameplay authority, [ROADMAP](ROADMAP.md) scope/schedule, specialized specs detailed contracts, [PROTOTYPE_DEFAULTS](PROTOTYPE_DEFAULTS.md) untested starting values. Resolve conflicts explicitly.
- `[ ]` = not verified complete; `[x]` = complete with evidence. Planned, designed, approved or implemented-but-untested is not checked. No game task is completed by writing this file.
- Status metadata: **TODO**, **IN PROGRESS**, **BLOCKED**, **DEFERRED**. TODO tasks with unmet dependency IDs cannot start; mark BLOCKED when an actual unresolved impediment needs tracking. Deferred/conditional work needs an explicit activation decision.
- Follow task dependencies rather than requiring every earlier phase to finish. Seed-item core gates precede the slice; later seed compatibility/Library checks intentionally wait for events/UI. Phase exit criteria distinguish these gates.
- Every task names requirement(s), dependency IDs, owner role, acceptance and evidence. Project development leads are recorded in PRODUCTION; person names for individual task ownership remain TBD until assigned. Proposed systems/paths are **NEW** and are not a claim they exist.
- Completion evidence records build/commit, engine/profile/seed, date, scenario, expected/actual result, artifact location and reviewer; hardware/devices/player count when relevant. Tests use PASSED/FAILED/COULD-NOT-RUN. Missing runtime evidence stays COULD-NOT-RUN, never “passed by design.”
- A requirement is complete only when all applicable implementation and verification tasks pass. Check partial work separately. Update [PLAYTEST](PLAYTEST.md), [ASSETS](ASSETS.md) and [AI_USAGE](AI_USAGE.md) when their evidence changes.
- Scope change requires owner/date/reason and updated GDD if gameplay changes, ROADMAP, PRD, tracker, content manifest and verification. Preserve IDs/history. Eight initial families remain targeted; Bula is the first cut-review candidate, not an automatic cut.
- Decide each Should feature include/defer before freeze. Included Should tasks become release obligations; retain original IDs and record promotion. Conditional finals and unpromoted expansion never enter the required-release denominator.
- Commit/push follow the authorization in the active task. For the approved P05 delivery, verify the work, stage only named P05 implementation/docs/evidence files, push the existing `main`, and fast-forward the Desktop checkout only if its branch/state is safe. No AI trailers/lines in commit metadata; truthful disclosure stays in dedicated docs/Form 03.

## Milestones, critical path and parallel work

| Milestone | Gate |
|---|---|
| First playable | P00–P07 relevant tasks and seed core checks; two-player construction/race slice, then 3/4-player coverage. |
| Feature-complete approved submission | P08–P14 required mechanics, eight family final gates, complete match, all three pairs, UX/Library/tutorial and essential assets. |
| Release-ready | P15 regressions/performance and P16 frozen clean-PC package, zero critical defects. |
| Submitted package | P17 reviewed deliverables, successful receipt and archived handoff. |
| Conditional finalist preparation | P18 only after qualification. |
| Optional full-catalog expansion | P19 individually promoted groups; not a blocker for completed submission. |

Critical chain: verified owners/toolchain → foundations → input/motion → arena/support → construction seed core → Pugad/atomic Place → Karera/outcomes → slice → Lagsanay → full match; independently Kangaroo → its stacks → final integrated content/UX → regression/performance → release → submission. Karera+Lagsanay starts as soon as its components pass. Gulong follows construction core gates, not all of P08. Bula core follows the other initial items.

Parallel work: art/UI/audio and licence/cultural preparation after owner assignment; menus/tutorial basics during the first loop; Library entry data with each item; registration/forms/synopsis/storyboards from P00; final capture after RC. Avoid spending the only gameplay capacity on final art. Export smoke is early and repeated for release. Proposed future organization under `tilaok!/` is `config/`, `scenes/`, `scripts/`, `assets/` and `tests/`; all are NEW suggestions, not existing paths or implementation delivered by this task.

October 21 feature freeze; October 22–23 stabilization; October 24 final media/package review; October 25 submission. Starting from a skeleton with unknown team capacity makes this high risk. Missing gates trigger an explicit scope/schedule decision, never a fabricated completion estimate.

## Phase summary and counts

**20 phases · 415 tasks · 120 requirements.** Initial checked tasks: **0**. Required release/submission: **209**; Should: **44**; conditional finals: **4**; expansion: **158**. Counts come from the actual task records below, not effort estimates. Documentation completion is reported separately at the end.

**Path note (2026-10-14):** evidence recorded before P02-T27 cites `tilaok!/data/items/*.tres`, `scenes/items/*_piece.tscn`, `ItemApprovedVariants.TABLE` and the stage-block scripts. Those were migrated region-for-region into one scene per variant under `tilaok!/scenes/blocks/` (parity check: 0 differences) and removed; the historical references are kept as recorded.

**Current implementation check count (2026-10-17): 180/421 task records checked** (P00 0/6; P01 9/10; P02 25/35; P03 7/7; P04 20/22; P05 12/12; P06 8/8; P07 0/4; P08 6/6 technical; P09 4/4 technical; P10 48/54; P11 13/13 technical; P12 10/10 technical; P13 11/18 (reference restyle T15–T17 technical, T18 human review open); P19 Barya 4/4 technical; P19 promoted obstacles 3/15). P13 exit criteria remain NOT MET because seven human/device tasks are open (T02, T04, T08, T10, T11, T12, T18). The scheduled P12 full-match route is now the default player route; P07 remains a separately gated first-playable route. Barya is separately implemented and verified on P12 under the scoped P19 approval, not the P12 denominator. P00-T04 remains BLOCKED and no full release-manifest ratification is claimed. The P02 Should extensions, P07/P08 gates, P09/P11 performance and human acceptance, human/physical sessions, and final art/audio review remain open. This counts checked records on disk and is not a release-readiness percentage.

| Phase | Purpose | Tasks | Scope |
|---|---|---:|---|
| [P00](#p00--baseline-and-production-readiness) — Baseline and production readiness | Own the decisions and establish what can actually be built. | 6 | Required |
| [P01](#p01--project-foundations) — Project foundations | Launch an original harness and establish an early export path. | 10 | Required |
| [P02](#p02--inputs-and-controller) — Inputs and controller | Players control only their own readable chicken and recover from device loss; wall movement, sneak/glide/stage blocks and block scenes are separately scoped Should extensions. | 33 | Required + Should extensions |
| [P03](#p03--graybox-stage-and-camera) — Graybox stage and camera | Players can traverse one bounded stage and remain visible; map scenes (P03-T07) are a Should extension. | 7 | Required + Should extension |
| [P04](#p04--item-infrastructure-and-construction-seeds) — Item infrastructure and construction seeds | Kaing and Tulay make the initial buildable course. | 22 | Required |
| [P05](#p05--lobby-pugad-and-construction-loop) — Lobby, Pugad and construction loop | Players join, recognize eggs and commit fair shared construction. | 12 | Required |
| [P06](#p06--karera-and-scoring) — Karera and scoring | A race ends once and its result is understandable. | 8 | Required |
| [P07](#p07--first-playable-gate) — First playable gate | Demonstrate a truthful build/race slice, then expand device counts. | 4 | Required |
| [P08](#p08--lagsanay) — Lagsanay | Independent tag elimination yields one winner. | 6 | Required |
| [P09](#p09--complete-match-lifecycle) — Complete match lifecycle | A match and tied-player sudden death finish and restart cleanly. | 4 | Required |
| [P10](#p10--remaining-initial-items) — Remaining initial items | Add the six individually verified families after construction seeds. | 54 | Required |
| [P11](#p11--kangaroo-independently) — Kangaroo independently | Implement and verify a standalone three-command event. | 13 | Required |
| [P11](#p11--kangaroo-independently) — Kangaroo independently | Players read and respond to three commands through escalation. | 13 | Required |
| [P12](#p12--scheduling-and-stacks) — Scheduling and stacks | The announced challenge and optional compatible Twist execute with one scoring family. | 10 | Required |
| [P13](#p13--complete-ux-and-onboarding) — Complete UX and onboarding | New players can learn, navigate, read results and browse enabled content. | 18 (T15–T18 reference restyle added 2026-10-17) | Required |
| [P14](#p14--release-presentation-and-provenance) — Release presentation and provenance | The build has readable original art, animation, sound and reviewed cultural identity. | 6 | Required |
| [P15](#p15--balance-and-regression) — Balance and regression | Demonstrate reliable play on named hardware at bounded workload. | 6 | Required |
| [P16](#p16--freeze-and-release-candidate) — Freeze and release candidate | Produce a tested package that another PC can run. | 4 | Required |
| [P17](#p17--submission-and-handoff) — Submission and handoff | Deliver the verified game and evidence before the deadline. | 10 | Required |
| [P18](#p18--conditional-finals) — Conditional finals | Represent the qualified game with prepared hardware and materials. | 4 | Conditional finals |
| [P19](#p19--optional-scope-and-expansion) — Optional scope and expansion | Keep every additional idea visible without inflating submission completion. | 182 | Should and expansion |

## P00 — Baseline and production readiness

**Goal / player-visible result:** Own the decisions and establish what can actually be built.

**Milestone / scope:** First playable and foundational delivery.

**Entry:** Read the approved documentation; no gameplay prerequisite.

**External task dependencies:** None.

**Owner roles:** Producer; person names TBD. **Systems touched:** Existing project and production documents.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Francis and Carlos are recorded as development leads; Shanti handles UI design and game audio; Jorge and Ivie handle game maps and assets. Remaining workstream assignments, reviewer identities, registration status and capacity remain unknown. Producer and integration-owner assignments are not confirmed. Matching Godot 4.7.2 templates and an initial Windows export are verified; keyboard details and physical-controller inventory/testing remain unresolved. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Owners, scope manifest and confirmed toolchain/device records unblock their respective workstreams.

**Evidence required:** Documentation baseline, role-sheet disposition, tool versions, observed/reported device inventory, actual import/export outputs and explicit unknowns. **P00 exit: NOT SATISFIED.** All six task checkboxes remain open; phase summary counts are unchanged.

**Evidence assessment:** October 13, 2026, 13:01 Asia/Manila; source revision `fa6145839bff96ecb6e1afdb112e804bfb72260f` before P00 edits. This timestamp/revision applies to the six task records below; import commands and exact run times are preserved in their linked logs.


#### P00-T01

- [ ] **Record team roles, reviewers and available hours**
  - **Status:** BLOCKED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Producer (name not recorded).
  - **Requirements:** [REQ-PROD-001](PRD.md#req-prod-001--confirm-registered-owners-and-available-capacity). **Dependencies:** None.
  - **Work:** Record primary and reviewer/backup for production/integration, programming, art/UI, audio, QA/balance and compliance/media, plus per-person capacity through October 25 without double-counting. Historical note: on October 13 the user said assignments and hours would be handled privately; the then-current TBD roster record was accurate. Francis later supplied current roles: Francis (lead developer) and Carlos (co-lead developer), both using AI-assisted programming; Shanti (UI design and game audio); Jorge and Ivie (maps, characters, obstacles, traps, effects and related game assets, created without AI generation). Individual review assignments, registration status and hours remain unknown.
  - **Acceptance:** A dated role/capacity sheet names registered members, review responsibilities and available hours through October 25; no invented names.
  - **Evidence:** Current development, UI, audio and game-asset roles are recorded in `PRODUCTION.md`; no complete role/capacity sheet, registration confirmation or reviewer evidence is available. **Procedure / expected / actual:** compared current supplied roles with the complete acceptance requirement; expected registered members, full role coverage, reviewer arrangement and hours, actual development leads, UI/audio and game-asset responsibilities are known but registration, remaining role coverage, review assignments and capacity are not. **Verification result:** COULD-NOT-RUN — P00 ownership/capacity gate remains open. **Reviewer:** not recorded. **Next action:** complete remaining assignments/capacity and verify them under team direction.


#### P00-T02

- [ ] **Verify confirm registered owners and available capacity**
  - **Status:** BLOCKED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** Producer (name not recorded).
  - **Requirements:** [REQ-PROD-001](PRD.md#req-prod-001--confirm-registered-owners-and-available-capacity). **Dependencies:** [P00-T01](#p00-t01).
  - **Work:** Independently verify registered membership, role coverage, reviewer arrangement, date range, and non-duplicated person-level hours from a confirmed role sheet.
  - **Acceptance:** A dated role/capacity sheet names registered members, review responsibilities and available hours through October 25; no invented names.
  - **Evidence:** Current development, UI, audio and game-asset roles are recorded, but T01 has no complete repository role/capacity artifact. **Procedure / expected / actual:** dependency and available evidence checked; expected a dated role/capacity sheet and registration confirmation, actual those role assignments are known but registration, reviewer arrangement and capacity are not. **Verification result:** COULD-NOT-RUN — complete ownership/capacity evidence remains outstanding. **Reviewer:** not recorded. **Next action:** complete and verify remaining team facts under team direction.


#### P00-T03

- [ ] **Record the reconciled authority and approved release baseline**
  - **Status:** IN PROGRESS · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Producer (name not recorded).
  - **Requirements:** [REQ-PROD-002](PRD.md#req-prod-002--ratify-the-release-manifest-and-document-authority). **Dependencies:** None.
  - **Work:** Reconcile the authority chain and record the existing October 13 approved planning target: all eight initial families and applicable approved variants; preserve Required/Should/Conditional/Expansion dispositions and inactive R1–R4. `PRODUCTION.md` now records the source revision, existing approval statements, scope categories, implementation/verification boundary, and no-new-ratification caveat. No family cut or backlog promotion is made.
  - **Acceptance:** Producer records required/Should/conditional/expansion dispositions, eight-family target and inactive R1–R4; no automatic scope cut or promotion.
  - **Evidence:** [P00 baseline record](PRODUCTION.md#p00-baseline-record), GDD §12, PRD v1.0 §§1/12, ROADMAP priorities and item gates; source revision `fa6145839bff96ecb6e1afdb112e804bfb72260f`. **Procedure / expected / actual:** cross-checked scope dispositions and authority; expected the recorded eight-family target, variants, inactive proposals, and explicit release categories; actual these agree across the cited sources and are recorded in PRODUCTION. **Verification result:** COULD-NOT-RUN for producer confirmation — the existing documents call the planning scope approved but do not identify a producer/approver; no new ratification is claimed. **Next action:** producer confirmation/provenance remains outstanding.


#### P00-T04

- [ ] **Verify ratify the release manifest and document authority**
  - **Status:** BLOCKED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** Producer (name not recorded).
  - **Requirements:** [REQ-PROD-002](PRD.md#req-prod-002--ratify-the-release-manifest-and-document-authority). **Dependencies:** [P00-T03](#p00-t03).
  - **Work:** Verify the baseline against GDD, specialized specifications, PROTOTYPE_DEFAULTS, ROADMAP, PRD, and PHASETASK. Confirm item-family/variant coverage, scope categories, inactive proposals, and release-target versus implementation/runtime state; keep unresolved approval provenance explicit.
  - **Acceptance:** Producer records required/Should/conditional/expansion dispositions, eight-family target and inactive R1–R4; no automatic scope cut or promotion.
  - **Evidence:** Cross-document check recorded in the [P00 baseline record](PRODUCTION.md#p00-baseline-record); source revision `fa6145839bff96ecb6e1afdb112e804bfb72260f`. **Procedure / expected / actual:** compared GDD, ITEMS, STAGE_AND_PLACEMENT, UI_TUTORIAL, PROTOTYPE_DEFAULTS, ROADMAP, PRD, and PHASETASK; expected one consistent authority/scope baseline without activating R1–R4 or implying implementation; actual no scope contradiction was found for the recorded manifest, and all game scope remains unimplemented. **Verification result:** COULD-NOT-RUN for final ratification verification — producer identity/confirmation is not recorded, so the documented baseline cannot be represented as newly ratified. **Reviewer:** not recorded. **Next action:** producer confirms the existing baseline or records an explicit decision; no scope change is inferred.


#### P00-T05

- [ ] **Confirm engine, templates and physical test inventory**
  - **Status:** IN PROGRESS · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Integration/Producer (person not recorded).
  - **Requirements:** [REQ-PROD-003](PRD.md#req-prod-003--resolve-toolchain-and-hardware-facts). **Dependencies:** None.
  - **Work:** Inventory Godot binaries, templates, lint/format tools, project/export setup, target PC, keyboard, and physical controller inventory. Do not infer device coverage from OS enumeration.
  - **Acceptance:** Named integration owner records executable/version/template paths and hardware/device inventory; target import and empty export checks either pass with logs or remain blocked with a reason.
  - **Evidence:** [P00 inventory](PRODUCTION.md#p00-baseline-record); [fresh target import](evidence/p00-clean-import-godot-4.7.2-2026-10-13.log), [working-project editor initialization](evidence/p00-import-godot-4.7.2-2026-10-13.log), [cached import repeat](evidence/p00-import-only-godot-4.7.2-2026-10-13.log); source revision `fa6145839bff96ecb6e1afdb112e804bfb72260f`. **Procedure / expected / actual:** inspected configured executable paths, `--version` outputs, template directories/version file, project settings/files, Windows system/device enumeration; expected target Godot 4.7.2, matching templates, selected-PC/device details, and export prerequisites. Actual: Godot 4.7.2 console/GUI are in `D:\Downloads`; PATH wrapper is 4.6.3; another executable is 4.5.1; templates report `4.7.stable`/`4.5.1.stable`; Godot documents patch-specific template IDs, so the installed 4.7 templates do not match the 4.7.2 editor; project declares 4.7/GL Compatibility; no export preset, entry scene, gameplay scenes/scripts; user confirms current PC target and its observed specs are recorded; Windows exposes generic keyboard devices but no controller, keyboard layout/model and team test inventory unknown. **Verification result:** import passed on an isolated copy; matching-template export and physical inventory verification are blocked. **Next action:** install matching 4.7.2 templates under the team's toolchain process, then an integration owner confirms physical test devices and export prerequisites.


#### P00-T06

- [ ] **Verify resolve toolchain and hardware facts**
  - **Status:** BLOCKED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** Integration/Producer (person not recorded).
  - **Requirements:** [REQ-PROD-003](PRD.md#req-prod-003--resolve-toolchain-and-hardware-facts). **Dependencies:** [P00-T05](#p00-t05).
  - **Work:** Verify toolchain and device inventory against the intended 4.7.2 target, actual templates/export setup, and named target PC; preserve the distinction between import, export, runtime, physical-input, and performance evidence.
  - **Acceptance:** Named integration owner records executable/version/template paths and hardware/device inventory; target import and empty export checks either pass with logs or remain blocked with a reason.
  - **Evidence:** [P00 inventory](PRODUCTION.md#p00-baseline-record), [PLAYTEST P00 checks](PLAYTEST.md#p00-production-readiness-evidence), [fresh target import](evidence/p00-clean-import-godot-4.7.2-2026-10-13.log), and [editor initialization](evidence/p00-import-godot-4.7.2-2026-10-13.log); source revision `fa6145839bff96ecb6e1afdb112e804bfb72260f`. **Procedure / expected / actual:** ran a fresh Godot 4.7.2 `--import --quit` against an isolated copy and inspected available template/export/device facts. Expected a clean target import and export/device verification or precise blockers. Actual fresh import passed; at the P00 inspection, matching templates, preset and entry scene were absent, and no controller/physical input test was available. **Verification result:** COULD-NOT-RUN for complete P00 verification. **P01 follow-up (October 13, 2026):** the official matching 4.7.2 template archive is now installed and a local P01 Windows export and executable startup/exit passed; see [P01 template](evidence/p01-template-install-2026-10-13.log), [export](evidence/p01-export-godot-4.7.2-2026-10-13.log) and [runtime](evidence/p01-export-runtime-2026-10-13.log). P00-T06 remains BLOCKED because its named-owner/physical-device verification and independent review are still missing. The template archive was extracted to the standard versioned path; Godot template-manager UI was not used.


## P01 — Project foundations

**Phase roll-up:** ✅ Foundation implementation and local verification complete (P01-T01, P01-T03–T10: 9/10 tasks PASSED). ⏳ P01-T02 remains COULD-NOT-RUN pending actual human review of implementation and provenance, so the full phase is not yet closed. This review task does not block other approved implementation work.

**Goal / player-visible result:** Launch an original harness and establish an early export path.

**Milestone / scope:** First playable and foundational delivery.

**Entry:** P00-T06 remains the toolchain gate. Its matching template/import/export evidence is now present, while owner/capacity and physical-device evidence remain open. P00-T02 remains open and is not a prerequisite for approved programming work.

P01 code was generated by Codex under the task authorization and internal policy in force at that time; it is disclosed in `AI_USAGE.md` and is not represented as manually team-written. Implementation and local runtime checks do not count as human review or competition eligibility approval.

**External task dependencies:** [P00-T06](#p00-t06). P01's relevant Godot 4.7.2 toolchain subset is verified; P00-T06 remains open for residual named-owner/device evidence, which is not a gate on ordinary programming. P00-T02 is not an implementation prerequisite and remains open for owner/capacity evidence. Competition compliance is handled separately in P17.

**Owner roles:** Integration; person names TBD. **Systems touched:** NEW project organization, config resources, harness and export preset.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Entry scene, config/profile validation, diagnostic harness and initial smoke export pass.

**Evidence required:** Human review of implementation/provenance, import/export logs, profile validation results.


#### P01-T01

- [x] **Create the project structure and responsibility map**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (person name not recorded).
  - **Requirements:** [REQ-TECH-001](PRD.md#req-tech-001--establish-team-directed-project-responsibilities). **Dependencies:** [P00-T06](#p00-t06). P01's Godot 4.7.2 project-open/import sub-check is verified in the linked evidence; the still-open P00-T06 named-owner/device portions do not block this foundation task. P00-T02 is a separate owner/capacity record, not an implementation gate.
  - **Work:** Created a runnable harness, responsibility map, typed configuration/diagnostics layout and test fixtures. No future gameplay responsibility is represented as implemented.
  - **Evidence:** [project map](PROJECT_STRUCTURE.md), [Godot import](evidence/p01-import-godot-4.7.2-2026-10-13.log), [runtime smoke](evidence/p01-runtime-smoke-2026-10-13.log). **Procedure / expected / actual:** opened the project in Godot 4.7.2 and ran the harness; expected a working diagnostic entry and clear scope labels, actual build/profile/seed identity and controls displayed without script errors. Codex generated this P01 work under the task authorization and internal policy in force then; its provenance is recorded and it is not represented as manually team-written. **Verification result:** PASSED for project structure/launch; actual human review remains P01-T02. **Reviewer:** Codex for implementation/runtime evidence; no human reviewer recorded.


#### P01-T02

- [ ] **Review foundation implementation and provenance**
  - **Status:** COULD-NOT-RUN · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (person name not recorded).
  - **Requirements:** [REQ-TECH-001](PRD.md#req-tech-001--establish-team-directed-project-responsibilities). **Dependencies:** [P01-T01](#p01-t01).
  - **Work:** A human reviewer inspects the P01 project structure, generated implementation, provenance/disclosure and evidence; records reviewer, date, findings and any follow-up. Confirm the project opens and that no tutorial/template/open-source core mechanics were copied. This is human review, not a manual-authorship test or competition-eligibility decision.
  - **Acceptance:** Project structure and provenance are reviewed by a human; reviewer/date/findings are recorded; project opens; no copied tutorial/template/open-source core mechanics are found. Competition rule interpretation remains in the separate submission gate.
  - **Evidence:** [programming provenance and review](PROJECT_STRUCTURE.md#programming-provenance-and-review); historical result: the prior review inspection found no human reviewer artifact. **Procedure / expected / actual:** Codex inspected files and disclosure; expected a human review record plus technical/provenance findings, actual no human review has been recorded. **Verification result:** COULD-NOT-RUN — actual human review remains outstanding. **Policy/dependency update (2026-10-13):** Francis directed a standing project-wide AI-assisted programming workflow, superseding the earlier internal manual-authorship rule. This task remains open for genuine human review but is not a prerequisite for downstream implementation. **Reviewer:** not recorded.


#### P01-T03

- [x] **Author configuration resources and labeled test profiles**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (person name not recorded).
  - **Requirements:** [REQ-CONFIG-001](PRD.md#req-config-001--centralize-provisional-configuration-and-profiles). **Dependencies:** [P01-T01](#p01-t01). **Dated dependency update (2026-10-13):** the earlier P01-T02 authorization dependency is removed because Francis's standing workflow approval settles AI-use permission; P01-T02 remains open for human review and does not block programming.
  - **Work:** Separate invariants, tunables and presentation. Use named movement_room, karera_slice, karera_spring, lagsanay_lab, kangaroo_contract_lab, stack_lab and release_candidate profiles. Snapshot gameplay tuning at match start; volume/shake may change while paused. Preserve defaults as untested; R1–R4 stay off.
  - **Acceptance:** No scattered gameplay tuning; changing gameplay keys requires a new test match. Logs identify profile/build/seed. All R proposals are off in contract/release profiles.
  - **Evidence:** `tilaok!/scripts/config/` and [foundation checks](evidence/p01-foundation-checks-2026-10-13.log). Seven contract profile IDs are available; prototype values remain labeled untested; snapshots copy gameplay/presentation values and keep R1–R4 off. **Procedure / expected / actual:** loaded the typed resources and registry in Godot 4.7.2; expected valid default/range checks and isolated snapshots, actual checks passed. **Verification result:** PASSED. **Reviewer:** Codex (implementation author); no registered team reviewer recorded.


#### P01-T04

- [x] **Verify centralize provisional configuration and profiles**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (person name not recorded).
  - **Requirements:** [REQ-CONFIG-001](PRD.md#req-config-001--centralize-provisional-configuration-and-profiles). **Dependencies:** [P01-T03](#p01-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. No scattered gameplay tuning; changing gameplay keys requires a new test match. Logs identify profile/build/seed. All R proposals are off in contract/release profiles.
  - **Acceptance:** No scattered gameplay tuning; changing gameplay keys requires a new test match. Logs identify profile/build/seed. All R proposals are off in contract/release profiles.
  - **Evidence:** [foundation checks](evidence/p01-foundation-checks-2026-10-13.log). **Procedure / expected / actual:** validated good/bad tuning and presentation ranges, unknown profiles, deep-copy snapshots, pause-only presentation changes and inactive R1–R4; all expected pass/reject results matched. Build/profile/seed identity was observed in the harness. **Verification result:** PASSED. **Reviewer:** Codex (AI-authored/automated; no independent team reviewer recorded).


#### P01-T05

- [x] **Build content validation and seeded diagnostic selection**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (person name not recorded).
  - **Requirements:** [REQ-CONFIG-002](PRD.md#req-config-002--validate-content-pools-and-deterministic-diagnostics). **Dependencies:** [P01-T04](#p01-t04).
  - **Work:** Enable only implemented and verified content. Zero disabled weights and normalize positive eligible weights. Empty required pools are configuration errors. Release rejects missing scheduled or sudden-death modes. Separate seeded egg, event and permitted tie-lottery streams from cosmetic randomness; provisional debug seed 12345.
  - **Acceptance:** Disabled content cannot be selected; empty pools fail visibly in diagnostics; same seed/profile reproduces selections; race-only profile is visibly developmental and cannot masquerade as release.
  - **Evidence:** `tilaok!/scripts/diagnostics/` and [foundation checks](evidence/p01-foundation-checks-2026-10-13.log). **Procedure / expected / actual:** built the validator and selector, then checked valid and invalid catalogs; expected only implemented, verified and enabled positive-weight entries to enter eligible normalized pools, and empty required pools/incomplete release profiles to reject, actual all checks matched. **Verification result:** PASSED. **Reviewer:** Codex (implementation author); no registered team reviewer recorded.


#### P01-T06

- [x] **Verify validate content pools and deterministic diagnostics**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (person name not recorded).
  - **Requirements:** [REQ-CONFIG-002](PRD.md#req-config-002--validate-content-pools-and-deterministic-diagnostics). **Dependencies:** [P01-T05](#p01-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Disabled content cannot be selected; empty pools fail visibly in diagnostics; same seed/profile reproduces selections; race-only profile is visibly developmental and cannot masquerade as release.
  - **Acceptance:** Disabled content cannot be selected; empty pools fail visibly in diagnostics; same seed/profile reproduces selections; race-only profile is visibly developmental and cannot masquerade as release.
  - **Evidence:** [foundation checks](evidence/p01-foundation-checks-2026-10-13.log). **Procedure / expected / actual:** exercised empty required pools, disabled/unverified entries, bad references/IDs/weights, normalization, release rejection, same-seed weighted sequences and egg/event/cosmetic stream independence; all expected outcomes matched. R1–R4 remain off. **Verification result:** PASSED. **Reviewer:** Codex (AI-authored/automated; no independent team reviewer recorded).


#### P01-T07

- [x] **Create local harness and lifecycle inspection controls**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (person name not recorded).
  - **Requirements:** [REQ-TECH-002](PRD.md#req-tech-002--provide-lifecycle-and-diagnostic-harnesses). **Dependencies:** [P01-T01](#p01-t01). **Dated dependency update (2026-10-13):** P01-T02 is review evidence, not a prerequisite for implementing or verifying the diagnostic harness.
  - **Work:** Provide clearly labeled local movement, item and event placeholder rooms with scenario reset/reload controls and local diagnostic identity. P01 fixtures exercise scene lifecycle only and contain no P02+ gameplay, terminal-event simulation, scoring, or player HUD. No analytics service, account, backend or gameplay networking.
  - **Acceptance:** Placeholder rooms open/close, reset and reload without duplicate callbacks or retained fixture/run state; diagnostics stay local and identify build/profile/seed. The fixtures do not claim gameplay readiness.
  - **Evidence:** [harness scene](../tilaok!/scenes/harness/foundation_harness.tscn), [runtime smoke](evidence/p01-runtime-smoke-2026-10-13.log), [foundation checks](evidence/p01-foundation-checks-2026-10-13.log). **Procedure / expected / actual:** opened the harness and exercised diagnostic run, fixture open/return, reset and reload; expected identity display and clean fixture lifecycle, actual controls responded and the headless lifecycle checks passed. The rooms are explicitly placeholders and display no gameplay. **Verification result:** PASSED. **Reviewer:** Codex (implementation author); team review remains open in P01-T02.


#### P01-T08

- [x] **Verify provide lifecycle and diagnostic harnesses**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (person name not recorded).
  - **Requirements:** [REQ-TECH-002](PRD.md#req-tech-002--provide-lifecycle-and-diagnostic-harnesses). **Dependencies:** [P01-T07](#p01-t07).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Each harness resets without duplicate signals or retained state; diagnostic data is local and can identify build/profile/seed and a failing scenario.
  - **Acceptance:** Each harness resets without duplicate signals or retained state; diagnostic data is local and can identify build/profile/seed and a failing scenario.
  - **Evidence:** [fixture cleanup checks](evidence/p01-foundation-checks-2026-10-13.log), [runtime smoke](evidence/p01-runtime-smoke-2026-10-13.log), [exported runtime](evidence/p01-export-runtime-2026-10-13.log). **Procedure / expected / actual:** instantiated, removed and freed each of three fixture rooms 10 times, checked exactly one return callback per instance, and compared root node count to baseline; opened/returned from a fixture, reset a run, then reloaded the scene with an active fixture. Expected no retained fixture or duplicate callback and fresh controls after reload; actual all assertions passed. **Verification result:** PASSED. **Reviewer:** Codex (AI-authored/automated; no independent team reviewer recorded).


#### P01-T09

- [x] **Configure and smoke-test the initial PC export**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Integration (person name not recorded).
  - **Requirements:** [REQ-EXPORT-001](PRD.md#req-export-001--prove-an-early-pc-export-path). **Dependencies:** [P01-T01](#p01-t01).
  - **Work:** Use the confirmed target engine and matching templates to export a minimal runnable P01 harness early; repeat with the final release later. The P01 harness is AI-generated and disclosed in `AI_USAGE.md`, not represented as manually team-written. A successful editor import alone is not export or gameplay evidence.
  - **Acceptance:** A versioned smoke export launches and exits on the intended PC; record engine/templates, preset, build and logs. Missing templates block the check.
  - **Evidence:** [template install](evidence/p01-template-install-2026-10-13.log), [export log](evidence/p01-export-godot-4.7.2-2026-10-13.log), [exported runtime](evidence/p01-export-runtime-2026-10-13.log). **Procedure / expected / actual:** installed the matching official 4.7.2 templates in the versioned Godot path; exported with the Windows Desktop preset; expected an executable that starts and exits, actual the app opened a responsive `Tilaok!` window and exited after a clean close request. The archive was installed by extracting its verified `templates/` subtree into the standard version path; the editor template-manager UI was not used. **Verification result:** PASSED for local target-PC smoke export. The executable contains AI-generated foundation code under the disclosed historical authorization; no human-review or competition-eligibility claim is made. **Reviewer:** Codex (implementation author); no human reviewer recorded.


#### P01-T10

- [x] **Verify prove an early pc export path**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (person name not recorded).
  - **Requirements:** [REQ-EXPORT-001](PRD.md#req-export-001--prove-an-early-pc-export-path). **Dependencies:** [P01-T09](#p01-t09).
  - **Work:** Record the procedure, expected and actual result, and review evidence. A versioned smoke export launches and exits on the intended PC; record engine/templates, preset, build and logs. Missing templates block the check.
  - **Acceptance:** A versioned smoke export launches and exits on the intended PC; record engine/templates, preset, build and logs. Missing templates block the check.
  - **Evidence:** [export log](evidence/p01-export-godot-4.7.2-2026-10-13.log), [exported runtime](evidence/p01-export-runtime-2026-10-13.log). **Procedure / expected / actual:** launched the exported Windows executable on the identified development/demo PC, checked the window responded, requested a normal close, and confirmed process exit; all expected observations passed. **Verification result:** PASSED. **Reviewer:** Codex (AI-authored/automated; no independent team reviewer recorded). No physical controller, performance, or clean-PC test is implied.


## P02 — Inputs and controller

**Goal / player-visible result:** Players control only their own readable chicken and recover from device loss.

**Milestone / scope:** First playable and foundational delivery.

**Entry:** P01 harness and config available.

**External task dependencies:** [P01-T04](#p01-t04). **Dated dependency update (2026-10-13):** Francis's standing AI-assisted programming direction supersedes the internal manual-authorship authorization gate. P01-T02 remains open for genuine human review but does not block P02 implementation.

**Owner roles:** Gameplay; person names TBD. **Systems touched:** NEW input, chicken controller, sensors and pause/reconnect flow.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Movement/input/contact/bounds and pause/reclaim scenarios pass on recorded devices.

**Evidence required:** Measured arc, device chords, slot isolation and reconnect captures.

**Original P02 implementation roll-up (2026-10-13, before the approved extension): 8/14 task records passed; P02 remains OPEN.** Passed: P02-T05/T06, P02-T09/T10, P02-T11/T12 and P02-T13/T14. Unchecked: P02-T01/T02 (two identical physical gamepads and mixed-input playtest unavailable), P02-T03/T04 (physical shared-keyboard rollover and supported-chord validation unavailable), and P02-T07/T08 (physical disconnect/reconnect and identical-controller reclaim unavailable). Synthetic device events are labeled synthetic and do not satisfy these hardware criteria. The controller, seat registry and pause/recovery code exist for the unchecked implementation records, but their task acceptance includes the corresponding physical checks. The supplied environment has K1/K2 keyboards and no gamepads. Current P02 total is 17/26: the eight Should-scope wall-movement tasks add six checked (T15–T17, T19–T21) and two open (T18, T22); the October 14 sneak/glide/64 wu grid/stage-blocks extension adds three checked (T23–T25) and one open (T26).

**Approved scope extension — October 13, 2026:** The user approved a distinct wall-slide/wall-jump extension after the existing P02 run/jump baseline. The extension is Should scope, planned after P03, and must not delay P04 or automatically become an October submission obligation. It is approved and implemented as of 2026-10-13 (enabled by default (core movement, owner decision 2026-10-13)); automated Godot checks pass, human review and physical-device parity are pending. Existing P02-T09/T10 evidence remains an accurate record of the original run/jump-only baseline. Measured values come only from synthetic fixtures; no human feel review or physical-device evidence is claimed. New tasks P02-T15–T22 are all unchecked.

**Programming provenance and dependency disposition:** P02 was AI-generated under the task authorization and internal policy in force at the time; this remains historical provenance, not a current P02-only exception. Francis's October 13 standing workflow direction supersedes the internal manual-authorship gate. P01-T02 remains unchecked for actual human review, but it no longer blocks implementation. The external §7/§8 interpretation, competition eligibility and organizer acceptance are not established here and remain in the centralized P17 submission gate. Physical input/reconnect checks remain open; synthetic evidence does not satisfy them. Francis and Carlos are recorded as development leads in `PRODUCTION.md`; no hours or registration status are inferred.

**Build/evidence identity:** local implementation based on `e2b4a555e8d45bec774ffebde7c46e595cd3abdb`, Godot `4.7.2.stable.official.ed1daf0bf`, default fixture seed `12345`, 60 Hz; run date 2026-10-13. Automated synthetic coverage: [P02 checks](evidence/p02-checks-2026-10-13.log); P01 regression: [foundation checks](evidence/p02-foundation-checks-2026-10-13.log). Rendered fixture: [running room](evidence/p02-diagnostic-room.png), [synthetic disconnect pause](evidence/p02-reconnect-pause.png), [capture log](evidence/p02-render-capture-2026-10-13.log) and [metrics](evidence/p02-rendered-metrics.txt). [Godot import/parse](evidence/p02-import-godot-4.7.2-2026-10-13.log), [format](evidence/p02-format-2026-10-13.log), [lint](evidence/p02-lint-2026-10-13.log), [export](evidence/p02-export-2026-10-13.log) and [exported startup](evidence/p02-export-runtime-2026-10-13.log) records are retained. Reviewer: Codex, AI implementation author; independent registered-team review not recorded.


#### P02-T01

- [ ] **Implement isolated device assignment and player markers**
  - **Status:** IN PROGRESS · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-INPUT-001](PRD.md#req-input-001--assign-devices-and-fixed-chicken-identity). **Dependencies:** [P01-T04](#p01-t04). P01-T02 is not an implementation gate under the standing workflow; this dated dependency revision (2026-10-13) removes only that obsolete authorization constraint.
  - **Work:** Support 2–4 local seats, gamepads first. A device joins one seat; join and ready require separate fresh presses. Number/shape stay fixed until lobby return: prototype 1 circle, 2 triangle, 3 square, 4 diamond. Color supplements identity.
  - **Acceptance:** Two identical gamepads and mixed input never control another seat, double-join or ready on the joining press; identifiers persist through phases and reconnect.
  - **Evidence:** `tilaok!/scripts/input/player_seat_registry.gd`, `tilaok!/scripts/input/local_input_router.gd`, the numbered/shape markers in `tilaok!/scripts/movement/chicken_controller.gd`, and synthetic seat isolation assertions in [P02 checks](evidence/p02-checks-2026-10-13.log). **Procedure / expected / actual:** automated synthetic tests join two distinct device IDs, reject duplicate assignment, enforce separate join/ready edges, check seat-isolated jump routing, and verify identity persistence after reclaim with a changed ID; all passed. **Verification result:** implementation is present; task acceptance remains open pending two identical physical gamepads and mixed-input playtest. **Reviewer:** Codex (implementation author). **Next action:** run the recorded physical-device procedure in PLAYTEST.md.


#### P02-T02

- [ ] **Verify assign devices and fixed chicken identity**
  - **Status:** COULD-NOT-RUN · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-INPUT-001](PRD.md#req-input-001--assign-devices-and-fixed-chicken-identity). **Dependencies:** [P02-T01](#p02-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Two identical gamepads and mixed input never control another seat, double-join or ready on the joining press; identifiers persist through phases and reconnect.
  - **Acceptance:** Two identical gamepads and mixed input never control another seat, double-join or ready on the joining press; identifiers persist through phases and reconnect.
  - **Evidence:** synthetic results only in [P02 checks](evidence/p02-checks-2026-10-13.log). **Procedure / expected / actual:** two identical physical gamepads and mixed keyboard/gamepad seats must be joined, exercised simultaneously, and checked for cross-control, duplicate joins, join-press readiness, and identity across reconnect. **Expected:** no cross-control and fixed numbered/shape identity. **Actual:** hardware procedure not run; no gamepads are available in the supplied environment. **Verification result:** COULD-NOT-RUN. **Reviewer:** not recorded. **Next action:** perform the physical-device session and append results/capture.


#### P02-T03

- [ ] **Implement phase bindings and opt-in keyboard seats**
  - **Status:** IN PROGRESS · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-INPUT-002](PRD.md#req-input-002--implement-phase-specific-bindings-and-shared-keyboard-fallback). **Dependencies:** [P02-T01](#p02-t01). The seat-assignment implementation is the programming prerequisite; P02-T02's physical two-gamepad verification remains open and is not an implementation authorization gate.
  - **Work:** Use the provisional binding table below. Release target is 2–4 players on verified gamepads/mixed devices. Two keyboard seats require explicit shared-keyboard mode and physical rollover validation; four-player keyboard-only is not promised. Stick digital parity/deadzone/repeat values remain prototype settings.
  - **Acceptance:** Each phase action works only for its assigned seat; no lost simultaneous supported chords. Unavailable/failed keyboard combinations are documented, remapped or excluded from supported claims.
  - **Evidence:** `tilaok!/scripts/input/local_input_router.gd`, `tilaok!/scripts/harness/p02_movement_room.gd`, and synthetic phase/key checks in [P02 checks](evidence/p02-checks-2026-10-13.log). Implemented pad South/East/West/Start, D-pad/stick hysteresis and priority, K1/K2 mappings, explicit shared-keyboard opt-in, and shared Escape pause. **Procedure / expected / actual:** synthetic phase bindings and seat routes pass, including Right Ctrl location handling; physical simultaneous chords and rollover have not been exercised. **Verification result:** implementation present, acceptance remains open until supported physical keyboard combinations are tested and any failed chords are remapped/excluded. **Reviewer:** Codex (implementation author). **Next action:** run the shared-keyboard chord matrix in PLAYTEST.md.
  - **Tool note (2026-10-15, no checkbox change):** the physical chord session now has an instrument: `tilaok!/scenes/tools/key_chord_recorder.tscn` (24 chords from PROTOTYPE_DEFAULTS §3 including the cheer chords, automatic PASS, LOST, text report) and [PLAYTEST Sheet A](PLAYTEST.md#sheet-a--p02-t03--p02-t04-physical-keyboard-chords-recorder). The tool is tested synthetically (60 checks); **no physical keyboard result exists yet and none is claimed**; the owner will run the session.

#### P02-T04

- [ ] **Verify implement phase-specific bindings and shared keyboard fallback**
  - **Status:** COULD-NOT-RUN · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-INPUT-002](PRD.md#req-input-002--implement-phase-specific-bindings-and-shared-keyboard-fallback). **Dependencies:** [P02-T03](#p02-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Each phase action works only for its assigned seat; no lost simultaneous supported chords. Unavailable/failed keyboard combinations are documented, remapped or excluded from supported claims.
  - **Acceptance:** Each phase action works only for its assigned seat; no lost simultaneous supported chords. Unavailable/failed keyboard combinations are documented, remapped or excluded from supported claims.
  - **Evidence:** synthetic binding checks in [P02 checks](evidence/p02-checks-2026-10-13.log); rendered identity/controls in [diagnostic room capture](evidence/p02-diagnostic-room.png). **Procedure / expected / actual:** exercise every documented simultaneous keyboard chord on the target physical keyboard, including movement+jump and menu/placement navigation+confirm/rotate. **Expected:** every claimed chord registers without rollover loss; unsupported chords are remapped or removed from supported claims. **Actual:** K1/K2 bindings pass synthetic events; physical keyboard model/layout and rollover result are not available. **Verification result:** COULD-NOT-RUN. **Reviewer:** not recorded. **Next action:** run the physical chord matrix and record exact keyboard/layout.
  - **Tool note (2026-10-15, no checkbox change):** the physical chord session now has an instrument: `tilaok!/scenes/tools/key_chord_recorder.tscn` (24 chords from PROTOTYPE_DEFAULTS §3 including the cheer chords, automatic PASS, LOST, text report) and [PLAYTEST Sheet A](PLAYTEST.md#sheet-a--p02-t03--p02-t04-physical-keyboard-chords-recorder). The tool is tested synthetically (60 checks); **no physical keyboard result exists yet and none is claimed**; the owner will run the session.

#### P02-T05

- [x] **Gate input edges and pointer repeat by phase**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-INPUT-003](PRD.md#req-input-003--consume-held-presses-across-phase-transitions). **Dependencies:** [P02-T03](#p02-t03). The binding implementation is the programming prerequisite; P02-T04's physical keyboard-rollover acceptance remains open and is not an implementation authorization gate.
  - **Work:** Consume existing press edges on transitions; release is required before claim/confirm/rotate/jump/ready. Held direction may continue; jump buffers clear. Ignore OS key repeat for one-shot actions. Prototype placement repeat is one cell then 0.25 s delay at 8 cells/s; menu/Pugad repeats at 6/s.
  - **Acceptance:** Holding jump/confirm through every transition creates no unintended next action; diagonal pointer movement gains no speed; unsupported rotations give a disabled cue.
  - **Evidence:** `tilaok!/scripts/input/local_input_router.gd` and [P02 checks](evidence/p02-checks-2026-10-13.log). **Procedure / expected / actual:** synthetic tests hold/release K1 actions across Play→Pugad→Place transitions, ignore OS echo, check one-shot release gating, diagonal navigation, 0.25 s repeat delay, 8/s Place repeat and disabled rotation cue; all assertions passed. **Verification result:** PASSED for the implemented routing/edge contract. **Reviewer:** Codex (implementation author); physical input limitations are recorded under P02-T04.


#### P02-T06

- [x] **Verify consume held presses across phase transitions**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-INPUT-003](PRD.md#req-input-003--consume-held-presses-across-phase-transitions). **Dependencies:** [P02-T05](#p02-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Holding jump/confirm through every transition creates no unintended next action; diagonal pointer movement gains no speed; unsupported rotations give a disabled cue.
  - **Acceptance:** Holding jump/confirm through every transition creates no unintended next action; diagonal pointer movement gains no speed; unsupported rotations give a disabled cue.
  - **Evidence:** [P02 synthetic/runtime checks](evidence/p02-checks-2026-10-13.log). **Procedure / expected / actual:** ran synthetic one-shot transition, held jump through phase change, diagonal step-count, 0.25 s/8 per second Place repeat, menu repeat timing, disabled-rotation cue and held-jump-through-landing assertions. All passed in Godot 4.7.2; the test does not claim physical rollover coverage. **Verification result:** PASSED for software phase-edge and repeat criteria. **Reviewer:** Codex (automated; no independent team reviewer recorded).


#### P02-T07

- [ ] **Implement shared pause, reconnect and all-ready resume**
  - **Status:** IN PROGRESS · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-INPUT-004](PRD.md#req-input-004--pause-and-reclaim-disconnected-seats-safely). **Dependencies:** [P02-T02](#p02-t02), [P02-T06](#p02-t06).
  - **Work:** Any participant may pause; focus loss/device disconnect pauses all simulation, timers, immunity, physics, hazards and event windows. Preserve slot/score/taya/position. Reclaim missing slots using unassigned devices and visible slot confirmation. All participants ready, all missing seats reclaimed, then a paused 3 s resume countdown. Status changes cancel readiness.
  - **Acceptance:** Unplug/replug including identical controllers preserves identity and timer values; assigned devices cannot steal seats; focus changes cancel resume; no simulation progresses during pause/countdown.
  - **Evidence:** `tilaok!/scripts/input/pause_recovery_coordinator.gd`, `tilaok!/scripts/input/local_input_router.gd`, and synthetic state/timer assertions in [P02 checks](evidence/p02-checks-2026-10-13.log). **Procedure / expected / actual:** synthetic focus/device status changes pause the tree, clear ready flags and cancel countdown; a Timer callback and physics probe remain frozen; owner acquisition, all-ready 3 s resume, and changed-ID seat reclaim pass. **Verification result:** implementation present; acceptance remains open pending physical unplug/replug, multiple missing seats and focus/device tests on the target PC. **Reviewer:** Codex (implementation author). **Next action:** run PLAYTEST.md's physical disconnect/reclaim matrix.


#### P02-T08

- [ ] **Verify pause and reclaim disconnected seats safely**
  - **Status:** COULD-NOT-RUN · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-INPUT-004](PRD.md#req-input-004--pause-and-reclaim-disconnected-seats-safely). **Dependencies:** [P02-T07](#p02-t07).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Unplug/replug including identical controllers preserves identity and timer values; assigned devices cannot steal seats; focus changes cancel resume; no simulation progresses during pause/countdown.
  - **Acceptance:** Unplug/replug including identical controllers preserves identity and timer values; assigned devices cannot steal seats; focus changes cancel resume; no simulation progresses during pause/countdown.
  - **Evidence:** [synthetic pause/reclaim checks](evidence/p02-checks-2026-10-13.log) and [rendered diagnostic room](evidence/p02-diagnostic-room.png). **Procedure / expected / actual:** use two identical physical controllers, disconnect/reconnect each (including changed IDs), test multiple missing seats, assigned-device theft rejection, focus loss, held action on resume, and all-ready countdown cancellation; inspect both timers and physics. **Expected:** full simulation freeze, preserved player state/identity, and safe fresh-input resume. **Actual:** synthetic focus/device-change and probe checks pass; physical controller disconnect/reconnect cannot run because no gamepads are available. **Verification result:** COULD-NOT-RUN. **Reviewer:** not recorded. **Next action:** complete the physical unplug/replug/reclaim session and record captures.


#### P02-T09

- [x] **Implement and instrument the initial run/jump controller**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-MOVE-001](PRD.md#req-move-001--implement-responsive-run-and-jump-only). **Dependencies:** [P02-T06](#p02-t06), [P01-T04](#p01-t04). The phase-edge implementation/verification is the input prerequisite; P02-T04's physical keyboard-rollover acceptance remains open and does not block the controller implementation.
  - **Work:** Original P02 baseline: normal Play controls are left/right and jump, without dash, wall jump, double jump or drop-through. This records the pre-extension implementation scope, not the later approved extension. Prototype uses 32 wu grid, 24×48 collider, 96 wu jump apex at 0.32 s, 280 wu/s run speed, variable jump, coyote/buffer, acceleration/braking and launch limits from the defaults register. These are starting values, not balance claims.
  - **Acceptance:** Measure full/short jumps, braking, reversal and 64 wu gap/rise trials; investigate apex deviations above 2 wu or one physics step; consume each buffered jump once and never auto-repeat held jump.
  - **Evidence:** `tilaok!/scripts/movement/chicken_controller.gd`, centralized `tilaok!/scripts/config/gameplay_tuning.gd`, and visible measurement surfaces in `tilaok!/scenes/fixtures/p02_movement_room.tscn`. **Procedure / expected / actual:** instrumented fixed-step movement, collision, full/short jump, held-jump latch, coyote/buffer windows, braking/reversal and an explicit one-way test surface in the P02 fixture. **Actual:** implementation and diagnostics exist; values remain provisional. Measured details and test command appear under P02-T10. **Verification result:** PASSED as implementation; do not interpret as balance approval or a complete game controller. **Reviewer:** Codex (implementation author).


#### P02-T10

- [x] **Verify implement responsive run and jump only**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-MOVE-001](PRD.md#req-move-001--implement-responsive-run-and-jump-only). **Dependencies:** [P02-T09](#p02-t09).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Measure full/short jumps, braking, reversal and 64 wu gap/rise trials; investigate apex deviations above 2 wu or one physics step; consume each buffered jump once and never auto-repeat held jump.
  - **Acceptance:** Measure full/short jumps, braking, reversal and 64 wu gap/rise trials; investigate apex deviations above 2 wu or one physics step; consume each buffered jump once and never auto-repeat held jump.
  - **Evidence:** [P02 checks and measured physics output](evidence/p02-checks-2026-10-13.log); [rendered diagnostic capture](evidence/p02-diagnostic-room.png); [rendered performance sample](evidence/p02-rendered-metrics.txt). **Build/profile/seed:** Godot 4.7.2, local pre-commit implementation based on `e2b4a555`, movement room, seed 12345, 60 Hz. **Procedure / expected / actual:** headless fixture test measured full/short jump, acceleration/braking, reversal, ceiling, 64 wu gap + 64 wu rise, held-jump landing, launch and containment. Expected full apex 96 wu at about 0.32 s; actual full 96.06 wu at 19 frames (0.3167 s), short 44.27 wu; 30-tick full-run displacement 120.00 wu at 280 wu/s; stop distance 11.67 wu; reversal crossed zero in 6 ticks; gap/rise landing at x=871.34, y=273.93. Held jump did not auto-repeat. No balance claim. **Verification result:** PASSED for measured fixture/controller criteria. **Reviewer:** Codex (automated, implementation author); no independent team reviewer recorded.


#### P02-T11

- [x] **Implement contact sensing and movement-state ownership**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-MOVE-002](PRD.md#req-move-002--separate-body-collision-contact-and-intentional-input). **Dependencies:** [P02-T10](#p02-t10).
  - **Work:** Chicken bodies pass through in Karera, Lagsanay and Kangaroo; independent sensors support tag/Hug. Forced movement is distinct from intentional input. Prototype precedence is terminal > opening taya freeze > capture > forced motion > locomotion. A lower state cannot reactivate a secured/eliminated player.
  - **Acceptance:** Overlap creates no pushing; intentional input is observable while captured; launch clears coyote state and is not shortened by jump release; terminal states ignore later movement/capture.
  - **Evidence:** `tilaok!/scripts/movement/chicken_contact_sensor.gd`, `tilaok!/scripts/movement/player_lifecycle_state.gd`, `tilaok!/scripts/movement/chicken_controller.gd`, and the narrow Lagsanay/contact diagnostic fixture. **Procedure / expected / actual:** separate body collision from the 28×48 sensor, hold intentional input under capture, keep force in an external velocity field, and apply precedence terminal → opening freeze → capture → forced → normal. **Actual:** systems are implemented and the paired test evidence is recorded in P02-T12. This is a narrow integration contract, not Lagsanay/Kangaroo gameplay. **Verification result:** PASSED as implementation. **Reviewer:** Codex (implementation author).


#### P02-T12

- [x] **Verify separate body collision, contact and intentional input**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-MOVE-002](PRD.md#req-move-002--separate-body-collision-contact-and-intentional-input). **Dependencies:** [P02-T11](#p02-t11).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Overlap creates no pushing; intentional input is observable while captured; launch clears coyote state and is not shortened by jump release; terminal states ignore later movement/capture.
  - **Acceptance:** Overlap creates no pushing; intentional input is observable while captured; launch clears coyote state and is not shortened by jump release; terminal states ignore later movement/capture.
  - **Evidence:** [P02 checks](evidence/p02-checks-2026-10-13.log). **Procedure / expected / actual:** overlapping two diagnostic chickens at the same coordinates must leave both unpushed while the independent Area2D detects contact; captured input remains observable; capture blocks launch; launch clears coyote; held/released jump during unobstructed external launch yields the same height; opening freeze outranks capture/launch; terminal state rejects later movement. **Actual:** all assertions passed. External launch height was 101.12 wu both held and released; fixture path was moved clear of overhead geometry before measurement. **Verification result:** PASSED for the diagnostic movement/contact contract. Lagsanay and Kangaroo themselves are not implemented or claimed. **Reviewer:** Codex (automated, implementation author).


#### P02-T13

- [x] **Implement bounds and diagnostic containment recovery**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-MOVE-003](PRD.md#req-move-003--contain-players-and-expose-invalid-escapes). **Dependencies:** [P02-T12](#p02-t12).
  - **Work:** Visible floor/side/ceiling bounds contain ordinary and forced movement. Lagsanay has no fall elimination. Prototype unexpected race-only escape fails once; containment failure with Lagsanay or standalone Kangaroo pauses as a defect and restarts the round from pre-round scores and unchanged construction.
  - **Acceptance:** Maximum launches cannot bypass bounds; injected breach cannot repeatedly award score, teleport an active taya while time runs, or convert a Lagsanay fall into elimination. Recovery is labeled a prototype safeguard.
  - **Evidence:** `tilaok!/scripts/harness/containment_recovery_contract.gd`, visible floor/walls/ceiling and explicit breach controls in `tilaok!/scripts/harness/p02_movement_room.gd`. **Procedure / expected / actual:** recover a Lagsanay/Kangaroo prototype defect from saved pre-round scores/construction token; fail a race escape once; verify no automatic race respawn or repeated outcome. **Actual:** implementation and paired checks are recorded in P02-T14. The UI clearly labels the prototype safeguard. **Verification result:** PASSED as a narrow diagnostic recovery contract; no scoring or full game recovery engine exists. **Reviewer:** Codex (implementation author).


#### P02-T14

- [x] **Verify contain players and expose invalid escapes**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-MOVE-003](PRD.md#req-move-003--contain-players-and-expose-invalid-escapes). **Dependencies:** [P02-T13](#p02-t13).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Maximum launches cannot bypass bounds; injected breach cannot repeatedly award score, teleport an active taya while time runs, or convert a Lagsanay fall into elimination. Recovery is labeled a prototype safeguard.
  - **Acceptance:** Maximum launches cannot bypass bounds; injected breach cannot repeatedly award score, teleport an active taya while time runs, or convert a Lagsanay fall into elimination. Recovery is labeled a prototype safeguard.
  - **Evidence:** [P02 checks](evidence/p02-checks-2026-10-13.log) and the screenshot [diagnostic room](evidence/p02-diagnostic-room.png). **Procedure / expected / actual:** apply maximum diagonal launch and track all physics positions against configured bounds; inject one breach in Race, Lagsanay and standalone Kangaroo; check one race terminal outcome/no respawn, defect pause for Lagsanay/Kangaroo, no elimination of the taya, and recovery from score/construction snapshot with zero awards. **Actual:** all checks passed; race outcome remained idempotent, Lagsanay/Kangaroo paused as prototype defects, and maximum configured diagonal launch remained contained. **Verification result:** PASSED for the fixture contract. The fixture does not implement production scoring, round restart, Lagsanay or Kangaroo. **Reviewer:** Codex (automated, implementation author).


### P02 wall movement extension — approved, implemented, verified on synthetic evidence, Should scope

**Goal / player-visible result:** While airborne beside an eligible solid wall, the chicken descends at a configurable capped speed and can press jump for a fresh kick away from that wall.

**Implementation status (2026-10-13):** implemented and verified with automated Godot 4.7.2 physics (85 wall checks; existing suites 83 and 103 unchanged), lint/format and import clean. T15–T17 and T19–T21 are checked; T18 awaits physical devices/producer decision and T22 a human reviewer. Evidence record: [wall evidence](evidence/p02-wall/README.md). Keep/defer decision: **PENDING** (producer/team; not made by the implementing agent).

**Scope / schedule:** SHOULD, user-approved October 13, 2026. Planned after the verified P03 stage contracts, independently of P04 item infrastructure. This approval does not promote the feature to a required October submission target or authorize delaying P04. Make an include/defer decision before the October 21 feature freeze. All tasks below start unchecked.

**Approved behavior:** Wall slide needs qualifying airborne wall contact but no directional hold. Only downward speed is capped. Base and player-built solid sides qualify; moving solids qualify while actual contact remains valid. One-way platform sides/undersides and arena containment boundaries do not qualify. Wall jump requires a fresh jump press, consumes it once, kicks away immediately with ordinary air steering available, and permits at most one kick per contact until the chicken separates. Prototype kick candidates are 240 wu/s horizontally away and −520 wu/s vertically; these and the slide cap/contact grace/separation thresholds are unmeasured tuning. External launches take precedence and clear wall action eligibility. Terminal, opening-freeze, capture and pause behavior follows the existing state precedence. Wall contact is not grounded support and cannot satisfy Rising wave.

**Entry / dependencies:** P02-T06, T10, T12 and T14 provide relevant input, run/jump, lifecycle and containment contracts. P03-T02, T04 and T06 provide base route, camera and actual support-contact contracts. No dependency requires unrelated physical-device completion or full event implementation. Later event-stack integration remains at its event gates.

**Exit criteria:** Four implementation/verification pairs below pass, including real Godot physics trials, rendered evidence, P03 base-route traversal without wall movement, containment/camera regressions, input-device parity evidence, and an actual human feel/balance review. Synthetic input is reported separately from physical keyboard/gamepad evidence. New shortcuts may be intentional; bounds escapes, immutable-protection bypasses and event-contract violations are not.

**Exit-criteria status (2026-10-13): NOT MET.** Automated physics, rendered, route, containment and camera evidence pass; physical-device parity (T18) and the human feel/balance review (T22) are open.

#### P02-T15

- [x] **Implement eligible wall-contact classification and slide state**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-MOVE-004](PRD.md#req-move-004--slide-on-eligible-walls-and-kick-away-with-a-fresh-jump-press). **Dependencies:** [P02-T06](#p02-t06), [P02-T10](#p02-t10), [P02-T12](#p02-t12), [P02-T14](#p02-t14), [P03-T02](#p03-t02), [P03-T06](#p03-t06).
  - **Work:** Classify actual airborne side contact on eligible base/player-built/moving solid surfaces; exclude one-way sides/undersides, triggers, hazards without eligible solid sides, pass-through chickens and arena boundaries. Apply a configurable downward-only slide speed cap. Clear state on separation, landing, loss/removal of a moving wall, or ineligible contact. Do not publish wall contact as grounded support.
  - **Acceptance:** Left and right eligible walls enter the same slide state only while airborne and actually touching; descending speed respects the configured cap while ascending speed is unchanged; ineligible surfaces never activate it; loss/removal clears contact promptly and never creates support-tracker eligibility.
  - **Evidence:** Future Godot physics fixture output and rendered captures for both sides, approach/departure, ascending/descending, each surface class and moving-wall removal. Record build/revision, engine, date, profile/seed, procedure, expected/actual outcomes and reviewer. **Evidence (evidence/p02-wall):** [wall tests](evidence/p02-wall/2026-10-13_wall_tests.txt) (`run_p02_wall_tests.gd`, 85 checks, 0 failures), [render capture](evidence/p02-wall/2026-10-13_wall_render_capture.txt) and [slide screenshot](evidence/p02-wall/01_slide_base_side_1080p.png). **Procedure / expected / actual:** airborne chicken beside eligible wall on the left and right; expected descent capped at 120 wu/s and equal on both sides; actual 120.00 / 120.00 wu/s; ascending at −400 wu/s uncapped; ineligible, one-way, metadata-less, trigger and chicken surfaces never slide; moving-wall departure and same-step `queue_free` clear contact; P03 base platform side slides with an empty support-contact list and 'no support'. **Result:** PASSED (synthetic input). **Build:** Godot 4.7.2.stable.official.ed1daf0bf, Windows (AMD Ryzen 5 5500, Radeon RX 580, Compatibility renderer), `movement_room`, seed 12345, 60 Hz, working tree on `9ee25c8`, 2026-10-13, synthetic K1/K2/gamepad events, 3 seats (K1, K2, one gamepad), reviewer: Claude (AI, automated; no human reviewer).


#### P02-T16

- [x] **Verify eligible wall contact and slide behavior**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** SHOULD · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-MOVE-004](PRD.md#req-move-004--slide-on-eligible-walls-and-kick-away-with-a-fresh-jump-press). **Dependencies:** [P02-T15](#p02-t15).
  - **Work:** Run real Godot physics and inspect rendered evidence for left/right symmetry; approach, departure and lost contact; descending cap and selected ascending behavior; base versus built solids; moving and removed walls; one-way sides and undersides; arena boundaries; corners, narrow shafts and ceilings. Confirm player contact never counts as support or Rising-wave qualification.
  - **Acceptance:** Every case has a recorded expected and actual result; eligible contacts slide as specified, excluded contacts do not, and no stale wall/support state survives contact loss or wall removal.
  - **Evidence:** Godot output, rendered screenshots/clips and a case-by-case results table with engine/build/date/profile/seed, player count, actual/synthetic input, expected/actual and reviewer. **Evidence:** same wall-test log, case-by-case in [wall tests](evidence/p02-wall/2026-10-13_wall_tests.txt): left/right symmetry, approach/departure (jump buffer, grace, moving wall away), descending cap vs ascending, base (P03 base A side) vs built-flag shaft walls, moving and removed walls, one-way side and underside, containment-like and metadata-less walls, trigger, chicken, bottom corner, ceiling and top landing, narrow shaft. Support never counted (P03 fixture). **Result:** PASSED (synthetic/automated; rendered stills inspected). **Build:** Godot 4.7.2.stable.official.ed1daf0bf, Windows (AMD Ryzen 5 5500, Radeon RX 580, Compatibility renderer), `movement_room`, seed 12345, 60 Hz, working tree on `9ee25c8`, 2026-10-13, synthetic K1/K2/gamepad events, 3 seats (K1, K2, one gamepad), reviewer: Claude (AI, automated; no human reviewer).


#### P02-T17

- [x] **Implement fresh-press wall jump and same-contact repetition rule**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-MOVE-004](PRD.md#req-move-004--slide-on-eligible-walls-and-kick-away-with-a-fresh-jump-press). **Dependencies:** [P02-T15](#p02-t15), [P02-T16](#p02-t16).
  - **Work:** Consume one fresh buffered jump press for one configurable kick away from the contacted wall. Start with provisional `240 wu/s` horizontal-away and `−520 wu/s` vertical components; expose values and any short wall-contact grace/separation thresholds in centralized tuning. Holding jump or OS repeats must not retrigger. Permit another kick only after physical separation and fresh recontact. Preserve normal ground jump/coyote behavior and existing air steering.
  - **Acceptance:** A fresh press while eligible produces exactly one kick; held jump/OS repeats do not; buffered input is consumed once; no same-contact repeated kick or indefinite wall climb occurs; normal ground jump/coyote results remain unchanged. Horizontal direction is symmetric and the player can steer immediately under configured air acceleration.
  - **Evidence:** Focused Godot input/physics output and rendered trials for press/hold/repeat, buffering, separation/recontact, corners, shafts, ceiling and ground/coyote regressions; record full reproducibility details. **Evidence:** [wall tests](evidence/p02-wall/2026-10-13_wall_tests.txt). **Procedure / expected / actual:** one fresh press beside a wall → exactly 1 kick (K1, K2, gamepad each), vx=240.00 away, vy −457.50 two ticks after the kick (−520 + 2×31.25 gravity); wall on the right mirrors; 60-tick held jump with OS repeats → 1 kick; echo alone → 0; press 6 wu before contact → 1 kick; second press at the same contact blocked until separation, lock cleared at a 12.10 wu gap, recontact kicks once more; steering toward the wall drops vx to 160 within 3 ticks; ground jump beside a wall is a ground jump; enabled full ground jump apex 96.06 wu; coyote ledge jump unchanged; held kick rise 72.07 wu vs released 33.84 wu. **Result:** PASSED (synthetic input). **Build:** Godot 4.7.2.stable.official.ed1daf0bf, Windows (AMD Ryzen 5 5500, Radeon RX 580, Compatibility renderer), `movement_room`, seed 12345, 60 Hz, working tree on `9ee25c8`, 2026-10-13, synthetic K1/K2/gamepad events, 3 seats (K1, K2, one gamepad), reviewer: Claude (AI, automated; no human reviewer).


#### P02-T18

- [ ] **Verify wall-jump input consumption and repetition limits**
  - **Status:** COULD-NOT-RUN · **Kind:** VERIFY · **Scope:** SHOULD · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-MOVE-004](PRD.md#req-move-004--slide-on-eligible-walls-and-kick-away-with-a-fresh-jump-press). **Dependencies:** [P02-T17](#p02-t17).
  - **Work:** Test fresh versus held presses and OS repeats, press buffering consumed exactly once, jump release, left/right impulse, steering return, same-wall recontact, narrow shafts, corners, ceiling contact and ground/coyote regressions. Run separately with synthetic keyboard/gamepad events and physical keyboard/gamepad trials when devices are available.
  - **Acceptance:** Each case records observed impulse and action count; no held/repeated press creates another kick, each eligible fresh press creates at most one, separation is necessary for repetition, and ground/coyote behavior remains within the existing P02 contract.
  - **Evidence:** Automated/focused output plus rendered clips and physical-device results labeled by actual device; record missing physical checks as COULD-NOT-RUN, never infer them from synthetic input. **Current result (2026-10-13):** synthetic keyboard (K1, K2) and gamepad cases PASSED (see [wall tests](evidence/p02-wall/2026-10-13_wall_tests.txt)): fresh vs held vs OS-repeat, buffering consumed once, jump release, left/right impulse, steering, same-wall recontact, shaft, corner, ceiling, ground/coyote. Physical keyboard/gamepad rows are COULD-NOT-RUN (no gamepads; no physical-device session). Left unchecked because acceptance asks for physical trials when devices exist and the include-synthetic-only decision (open question g) is the producer's. **Next action:** run the keyboard/gamepad rows of the session sheet, or confirm synthetic-only acceptance.


#### P02-T19

- [x] **Integrate wall actions with lifecycle, forced motion, support and pause/reset**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-MOVE-004](PRD.md#req-move-004--slide-on-eligible-walls-and-kick-away-with-a-fresh-jump-press). **Dependencies:** [P02-T12](#p02-t12), [P02-T15](#p02-t15), [P02-T17](#p02-t17), [P03-T06](#p03-t06).
  - **Work:** Preserve terminal > opening freeze > capture > forced motion > locomotion precedence; external launches preempt wall slide/jump and clear wall action/buffer state. Pause freezes motion and input consumption; phase change, reset and scene reload clear stale contact/cooldown/buffer state. Wall contact never writes upward supporting contact/provenance. Keep intentional jump input observable for future Freeze evaluation. Do not implement event rules or change pass-through player bodies.
  - **Acceptance:** Secured/eliminated, opening-frozen and captured players cannot wall-act; external launches are not shortened or overwritten; pause/resume, phase transition, reset and reload cannot replay a stale jump/contact; support tracking remains invalid from wall contact; input intent remains visible under existing semantics.
  - **Evidence:** Future Godot lifecycle/force/support integration output and rendered trials, including removal during contact and reload/reset loops. Record actual engine/build/date/profile/seed and reviewer. **Evidence:** [wall tests](evidence/p02-wall/2026-10-13_wall_tests.txt) and `reset_wall_state()` wiring in `chicken_controller.gd`. **Result:** PASSED. Launch, capture, opening freeze, secured, eliminated, pause/resume, phase change, diagnostic reset, P03 stage reset while sliding, wall removal and 5 reload cycles leave no stale contact, lock or buffered press; wall contact leaves the support list empty. **Build:** Godot 4.7.2.stable.official.ed1daf0bf, Windows (AMD Ryzen 5 5500, Radeon RX 580, Compatibility renderer), `movement_room`, seed 12345, 60 Hz, working tree on `9ee25c8`, 2026-10-13, synthetic K1/K2/gamepad events, 3 seats (K1, K2, one gamepad), reviewer: Claude (AI, automated; no human reviewer).


#### P02-T20

- [x] **Verify lifecycle, forced-motion, support and pause/reset integration**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** SHOULD · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-MOVE-004](PRD.md#req-move-004--slide-on-eligible-walls-and-kick-away-with-a-fresh-jump-press). **Dependencies:** [P02-T19](#p02-t19).
  - **Work:** Exercise capture, opening freeze, secured/eliminated states, external launches, pause/resume, phase changes, reset and scene reload while sliding or pressing jump. Check no player-to-player wall interaction, no stale support/Rising-wave qualification, and intentional jump remains observable for a future Freeze gate.
  - **Acceptance:** Each state transition has expected/actual results; higher-priority lifecycle/forced states win, paused simulation does not advance, no action replays after resume/reset, support remains false, and intent telemetry is visible without enabling Kangaroo.
  - **Evidence:** Godot output, rendered captures and integration case table with reproducibility metadata. **Evidence:** [wall tests](evidence/p02-wall/2026-10-13_wall_tests.txt). **Procedure / expected / actual (all matched):** launch while sliding → wall state cleared and a same-tick press cannot overwrite it; captured/opening-freeze/secured/eliminated + press → no kick (intent stays observable in captured and frozen states); pause + press, then resume → no replay and position unchanged during pause; phase change with a held press → no kick; reset clears side/lock/slide; support stays 'no support'. **Result:** PASSED (synthetic). **Build:** Godot 4.7.2.stable.official.ed1daf0bf, Windows (AMD Ryzen 5 5500, Radeon RX 580, Compatibility renderer), `movement_room`, seed 12345, 60 Hz, working tree on `9ee25c8`, 2026-10-13, synthetic K1/K2/gamepad events, 3 seats (K1, K2, one gamepad), reviewer: Claude (AI, automated; no human reviewer).


#### P02-T21

- [x] **Add wall-movement regression fixtures for route, camera and containment**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-MOVE-004](PRD.md#req-move-004--slide-on-eligible-walls-and-kick-away-with-a-fresh-jump-press). **Dependencies:** [P02-T18](#p02-t18), [P02-T20](#p02-t20), [P03-T02](#p03-t02), [P03-T04](#p03-t04), [P03-T06](#p03-t06).
  - **Work:** Add focused regression scenarios for the unchanged P03 base route (which must remain traversable without wall movement), maximum kick/launch containment, camera framing of wall kicks, and builds that create tempting shortcuts. Cover bounds, immutable protections and support/event contract assertions. Add trial procedures for future Lagsanay/event-stack escape and stalling review without depending on unimplemented event code.
  - **Acceptance:** Existing base route still traverses with wall movement disabled (re-verified with it enabled by default on 2026-10-13: the P02/P03 suites pass); maximum wall-kick/launch combinations remain in bounds and camera-visible; no immutable protection or specified event contract is bypassed. Intended new shortcuts are recorded for human balance review rather than automatically rejected.
  - **Evidence:** Godot route/camera/containment fixture output and rendered evidence, plus procedure for future Lagsanay/event-stack review. **Evidence:** [wall tests](evidence/p02-wall/2026-10-13_wall_tests.txt), [regressions](evidence/p02-wall/2026-10-13_regression_p03.txt), [renders](evidence/p02-wall/04_max_kick_launch_camera_1080p.png), [event-stack procedure](evidence/p02-wall/event_stack_escape_procedure.md). **Result:** PASSED. The shipped default is disabled and the unmodified `run_p03_tests.gd` (103 checks) traverses the base route; with wall movement enabled, kick + launch (±480,−900 / 0,−900 / 480,0) stays in bounds (P02 room) and the P03 camera keeps all targets visible (peak y 264.08); fixtures leave the arena geometry signature unchanged and immutable-region rejection intact. Shaft climbing reaches the room ceiling (34 kicks, gains −2.0…+24.5 wu per cycle) and is recorded as an intentional shortcut candidate for human balance review. **Build:** Godot 4.7.2.stable.official.ed1daf0bf, Windows (AMD Ryzen 5 5500, Radeon RX 580, Compatibility renderer), `movement_room`, seed 12345, 60 Hz, working tree on `9ee25c8`, 2026-10-13, synthetic K1/K2/gamepad events, 3 seats (K1, K2, one gamepad), reviewer: Claude (AI, automated; no human reviewer).


#### P02-T22

- [ ] **Verify route, camera, containment and wall-movement feel/balance**
  - **Status:** BLOCKED (human review) · **Kind:** VERIFY · **Scope:** SHOULD · **Owner:** QA / Human playtester (names TBD).
  - **Requirements:** [REQ-MOVE-004](PRD.md#req-move-004--slide-on-eligible-walls-and-kick-away-with-a-fresh-jump-press). **Dependencies:** [P02-T21](#p02-t21).
  - **Work:** Run the P03 route without wall movement; inspect maximum wall-kick/launch bounds and camera framing; test intended shortcuts and failure cases in actual multiplayer sessions. Review repeated-wall escape/stalling as a future Lagsanay and event-stack risk. Obtain and record actual human feel/balance review; do not substitute synthetic trials or calculations.
  - **Acceptance:** Route and containment regressions pass with evidence; all new shortcuts and remaining risks are recorded; human reviewer identity, player count, actual devices, procedure and subjective findings are documented. Future event-specific integration stays attached to its own event gate.
  - **Evidence:** Godot output, rendered screenshots/clips and actual human review record with build/revision, engine/date/profile/seed, player count, devices/input type, expected/actual and reviewer. **Current result (2026-10-13):** automated route/containment/camera regressions PASSED (T21); human feel/balance review NOT DONE. No named reviewer has run the [session sheet](evidence/p02-wall/human_feel_session_sheet.md). **Next action:** a named reviewer runs it; keep/defer for the Oct 21 freeze is PENDING (producer/team).


### P02 sneak, glide, 64 wu grid and stage blocks extension — implemented, Should scope

**Goal / player-visible result:** The stage uses 64×64 px tiles; chickens can sneak into a 1×1 body and glide by holding W; three new blocks (Solid, Wood Box, Collapsing) can be built.

**Scope / schedule:** SHOULD, requested by the user on 2026-10-14 and implemented the same day. Include/defer before the October 21 freeze with the wall extension (producer/team decision, not made by the implementing agent).

**Implementation status (2026-10-14):** T23–T25 implemented and verified on automated/synthetic evidence ([blocks evidence](evidence/blocks/README.md)); T26 (human feel/balance and physical devices) open. Requirements: [REQ-MOVE-005](PRD.md#req-move-005--sneak-into-a-one-tile-body-and-glide-while-holding-jump), [REQ-STAGE-004](PRD.md#req-stage-004--64-px-tile-stage-and-scene-authored-stage-blocks).

#### P02-T23

- [x] **Rescale the stage and controller to a 64 wu tile grid with a TileMapLayer stage**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-STAGE-004](PRD.md#req-stage-004--64-px-tile-stage-and-scene-authored-stage-blocks). **Dependencies:** [P03-T02](#p03-t02), [P04-T02](#p04-t02).
  - **Work:** Double every distance/speed/acceleration tuning value (64 wu tiles, 56×120 body), move launch caps into tuning, keep the P02 room on `GameplayTuning.legacy_32_wu()`, scale P03 debug literals, and draw the base stage with `scenes/stage/stage_tiles.tscn` (64 px TileSet) painted from ArenaDefinition.
  - **Acceptance:** All existing suites pass at the new scale with expectations scaled, not weakened; tiles align with arena coordinates.
  - **Evidence:** [regression summary](evidence/blocks/2026-10-14_regression_summary.txt) (foundation, P02 83, wall 85, P03 103, P04 268, P05 137, UI 437 — 0 failures), [blocks tests](evidence/blocks/2026-10-14_blocks_tests.txt) (132 tiles painted, distinct ground/platform/boundary tiles). **Result:** PASSED. **Build:** Godot 4.7.stable.official.5b4e0cb0f, Windows 11, Item Lab `karera_slice`, seed 12345, 60 Hz, working tree on `19b3653`, 2026-10-14, synthetic K1/K2 keyboard events, 1–2 seats, reviewer: Claude (AI, automated; no human reviewer).

#### P02-T24

- [x] **Implement sneak, glide and W/Up jump**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-MOVE-005](PRD.md#req-move-005--sneak-into-a-one-tile-body-and-glide-while-holding-jump). **Dependencies:** [P02-T10](#p02-t10), [P02-T15](#p02-t15), [P02-T23](#p02-t23).
  - **Work:** W/Up map to jump in Play; hold down to sneak (56×56 body, feet fixed, no walk/jump, headroom check); hold jump while falling to glide (180 wu/s cap; wall slide wins).
  - **Acceptance:** Behaviors above in real physics; wall/jump regressions unchanged.
  - **Evidence:** [blocks tests](evidence/blocks/2026-10-14_blocks_tests.txt): W jump rise 192.1 wu; sneak shrink/no-walk/no-jump/headroom; glide max 180.0 wu/s, steering kept, wall slide wins. **Result:** PASSED. **Build:** Godot 4.7.stable.official.5b4e0cb0f, Windows 11, Item Lab `karera_slice`, seed 12345, 60 Hz, working tree on `19b3653`, 2026-10-14, synthetic K1/K2 keyboard events, 1–2 seats, reviewer: Claude (AI, automated; no human reviewer).

#### P02-T25

- [x] **Add scene-authored Solid Block, Wood Box and Collapsing Block**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD); visuals Jorge/Ivie.
  - **Requirements:** [REQ-STAGE-004](PRD.md#req-stage-004--64-px-tile-stage-and-scene-authored-stage-blocks). **Dependencies:** [P04-T05](#p04-t05), [P05-T05](#p05-t05), [P02-T23](#p02-t23).
  - **Work:** One scene per block in `scenes/blocks/`, scripts, data definitions, approved-variant/registry/pool registration, `reset_to_placed` safe start, egg silhouettes.
  - **Acceptance:** Scenes match data footprints; Solid 3×1 rotates to 1×3; Box falls, is pushed, is standable and resets in Place; Collapsing collapses 2 s after floor or wall-slide contact and returns after 3 s once clear.
  - **Evidence:** [blocks tests](evidence/blocks/2026-10-14_blocks_tests.txt) (push 120 wu / 45 ticks; collapse 2.00 s; respawn 3.02 s; respawn waits while overlapped), [captures](evidence/blocks/README.md). **Result:** PASSED. **Build:** Godot 4.7.stable.official.5b4e0cb0f, Windows 11, Item Lab `karera_slice`, seed 12345, 60 Hz, working tree on `19b3653`, 2026-10-14, synthetic K1/K2 keyboard events, 1–2 seats, reviewer: Claude (AI, automated; no human reviewer).

#### P02-T26

- [ ] **Verify sneak/glide/blocks feel, balance and physical-device parity**
  - **Status:** BLOCKED (human review) · **Kind:** VERIFY · **Scope:** SHOULD · **Owner:** QA / Human playtester (names TBD).
  - **Requirements:** [REQ-MOVE-005](PRD.md#req-move-005--sneak-into-a-one-tile-body-and-glide-while-holding-jump), [REQ-STAGE-004](PRD.md#req-stage-004--64-px-tile-stage-and-scene-authored-stage-blocks). **Dependencies:** [P02-T24](#p02-t24), [P02-T25](#p02-t25).
  - **Work:** Play real multiplayer sessions on keyboards and gamepads; judge glide/sneak/push/collapse timings and shortcut/stalling risks; record findings.
  - **Acceptance:** Named reviewer, devices, player count, procedure and findings recorded.
  - **Evidence:** **Current result (2026-10-14):** NOT DONE. **Next action:** a named reviewer plays the Item Lab / P05 match with the new controls.

#### P02-T27

- [x] **Make every placeable item a BlockData scene in a scanned folder**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD); visuals Jorge/Ivie.
  - **Requirements:** [REQ-STAGE-005](PRD.md#req-stage-005--scene-authored-block-catalog-with-kill-and-stun-hitboxes). **Dependencies:** [P02-T25](#p02-t25), [P04-T05](#p04-t05).
  - **Work:** `BlockData`/`BlockHitbox` authoring nodes (each hitbox picks an **Effect**: Kill, Stun, Launch, Sweep, Beam, Capture path, Cleanup area, Lane — renamed from Role on 2026-10-15), folder-scanning `BlockCatalog` (definitions, pool, approved table, lab keys), `StageBlock` runtime (anchor/gravity, push, collapse), migration of all 23 legacy variants (Kaing, Tulay, Solid, Wood Box, Collapsing and the six P10 hazards) to one scene each with 0 region differences, removal of the `.tres` families and variant table.
  - **Acceptance:** A scene dropped into `scenes/blocks/` appears in definitions, the default pool and Item Lab eggs with no other edit; existing P04/P10 behavior suites pass unchanged except counts/node access.
  - **Evidence:** [block-scene regression](evidence/blocks/2026-10-14_block_scenes_regression.txt), [blocks tests](evidence/blocks/2026-10-14_block_scenes_tests.txt) (drop-in, Heavy anchor). **Result:** PASSED. **Build:** Godot 4.7.stable.official.5b4e0cb0f, Windows 11, Item Lab / Item Visualizer, seed 12345, 60 Hz (`--fixed-fps 60`), working tree on `a9eb75f`, 2026-10-14, synthetic K1 keyboard events, 1-2 seats, reviewer: Claude (AI, automated; no human reviewer).

#### P02-T28

- [x] **Add kill/stun hitboxes, Spikes, Cannon, stun and the chicken death sprite**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-STAGE-005](PRD.md#req-stage-005--scene-authored-block-catalog-with-kill-and-stun-hitboxes). **Dependencies:** [P02-T27](#p02-t27), [P10-T04](#p10-t04).
  - **Work:** Touch kill/stun regions in the deterministic director (kills credited to the placer, stuns as uncredited setup), stun-capable projectiles, per-block tuning overrides, `apply_stun` (knockback + control freeze + 0.5 s immunity), Spikes and Cannon scenes, stun and death animations.
  - **Acceptance:** Spikes kill on the points and are standable on the solid half; the Cannon fires along its path, kills and is stopped by cover; stun knocks back and freezes controls for its time; eliminated chickens show the death sprite.
  - **Evidence:** [blocks tests](evidence/blocks/2026-10-14_block_scenes_tests.txt), [capture](evidence/blocks/2026-10-14_spikes_cannon_1080p.png). **Result:** PASSED. **Build:** Godot 4.7.stable.official.5b4e0cb0f, Windows 11, Item Lab / Item Visualizer, seed 12345, 60 Hz (`--fixed-fps 60`), working tree on `a9eb75f`, 2026-10-14, synthetic K1 keyboard events, 1-2 seats, reviewer: Claude (AI, automated; no human reviewer).

#### P02-T30

- [x] **Offer every main-game block in the selector and make Place first come, first served**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-STAGE-005](PRD.md#req-stage-005--scene-authored-block-catalog-with-kill-and-stun-hitboxes). **Dependencies:** [P02-T27](#p02-t27), [P05-T05](#p05-t05).
  - **Work:** The match egg pool (P07/P09 rooms and the Library) comes from the block catalog instead of a hardcoded Kaing/Tulay list. A confirmed placement claims its cells at once: other ghosts show "Taken by P#", later confirms there are refused, edits resolve in confirmation order, and unconfirmed placements on claimed cells are discarded at the timer.
  - **Acceptance:** Spikes and Cannon appear in seeded Pugad eggs; the first confirmer keeps a contested spot regardless of seat number; the loser can still place elsewhere.
  - **Evidence:** `tests/run_place_claim_tests.gd` (15 checks, incl. a real-match spike-kill regression after fixing item kills being dropped by the race ledger in P05/P07 rooms), [regression](evidence/blocks/2026-10-14_place_claim_regression.txt). **Result:** PASSED (synthetic input; human pace/fairness review is P02-T29). **Build:** Godot 4.7.stable.official.5b4e0cb0f, working tree on `a9eb75f`, 2026-10-14, reviewer: Claude (AI, automated; no human reviewer).

  - **Superseded 2026-10-16 (user request):** first come, first served was removed. Confirm order no longer matters: same-phase overlaps resolve in seat order, and ghosts and notices say only "Tile occupied" or "Invalid spot". `run_place_claim_tests.gd` (14 checks) now verifies that behaviour; see [fix evidence](evidence/fixes/README.md). The selector-pool part of this task is unchanged.

#### P02-T31

- [x] **Use an animated chicken scene built from the team's placeholder sprite sheet**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD); sprite sheet Art (Jorge/Ivie).
  - **Requirements:** [REQ-STAGE-005](PRD.md#req-stage-005--scene-authored-block-catalog-with-kill-and-stun-hitboxes), [REQ-MOVE-005](PRD.md#req-move-005--sneak-into-a-one-tile-body-and-glide-while-holding-jump). **Dependencies:** [P02-T24](#p02-t24).
  - **Work:** `scenes/characters/chicken.tscn` (ChickenController + 56×120 body + AnimatedSprite2D at ×0.25: 512×512 cells → 128 wu, 256×512 hitbox column → 64×128) with 14 animations: idle, run, wall slide, sneak, jump and glide (left/right/still), stun and dead (row 2 col 4). `ChickenSpriteAnimator` picks the animation from controller state, applies per-animation feet offsets and the seat tint; the identity marker stays above the head. P03-based rooms and the match build chickens from this scene.
  - **Acceptance:** Every state shows its frame with feet on the collision bottom; seat colours and number/shape markers stay readable.
  - **Evidence:** [blocks tests](evidence/blocks/2026-10-14_block_scenes_tests.txt) (animation checks incl. stun and dead), [capture](evidence/blocks/2026-10-14_spikes_cannon_1080p.png). **Result:** PASSED (synthetic). **Build:** Godot 4.7.stable.official.5b4e0cb0f, 2026-10-14, reviewer: Claude (AI, automated; no human reviewer).

#### P02-T32

- [x] **Add Bomb, Dynamite and Nuke explosives, lock a claimed Pugad pick, and let eliminated chickens fall**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD); user request (2026-10-15).
  - **Requirements:** [REQ-STAGE-005](PRD.md#req-stage-005--scene-authored-block-catalog-with-kill-and-stun-hitboxes). **Dependencies:** [P02-T27](#p02-t27), [P02-T30](#p02-t30).
  - **Work:**
    - `scenes/blocks/explosives/` holds `bomb_2x2`, `dynamite_3x3` and `nuke_4x4`: BlockData Special = Cleanup, so each is a one-shot area edit that clears earlier-round player-built pieces through the existing atomic Place resolver. Visuals are DEBUG placeholders with an orange blast-area outline; pool weights are 30 / 20 / 8.
    - `ExplosionFlash` shows a short placeholder blast over each committed cleanup (`P05MatchRoom._show_blasts`).
    - 2026-10-16 (user request): explosives also blow up placements made in the same Place phase inside their blast area (`AtomicEditResolver._blast_same_phase`); Walis keeps sparing them.
    - Pugad: a seat that owns an egg, or has a claim pending, can no longer move its selection.
    - An eliminated chicken keeps falling under gravity (no control, no sideways drift) until it lands, instead of hanging where it died. It never touches blocks or hazards again, and stops once it leaves the stage without reporting an escape (`ChickenController._fall_while_eliminated`; blocks test: a chicken eliminated 4 tiles up lands straight below).
    - The two spike kill checks now land on the points from above, because the Spikes kill hitbox was narrowed to 60×24 in the editor (in `d2b72e0`) and is no longer reached from the side.
  - **Acceptance:** All three are in the catalog and match pool from their scenes alone. In a real match a Bomb clears the earlier piece in its area, leaves pieces outside it and pieces placed in the same phase, and shows one blast; a Nuke clears its 4×4. A claimed seat cannot browse while an unclaimed seat can.
  - **Evidence:** [explosives tests](evidence/blocks/2026-10-15_explosives_tests.txt) (23 checks), [regression summary](evidence/blocks/2026-10-15_explosives_regression.txt). **Result:** PASSED (synthetic). **Build:** Godot 4.7.stable.official.5b4e0cb0f, 2026-10-15, reviewer: Claude (AI, automated; no human reviewer).

#### P02-T33

- [x] **Add four keyboard layouts, a clickable map row, a Place block preview and a Library Back button**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD); user request (2026-10-16).
  - **Requirements:** [REQ-INPUT-001](PRD.md#req-input-001--assign-devices-and-fixed-chicken-identity), [REQ-STAGE-005](PRD.md#req-stage-005--scene-authored-block-catalog-with-kill-and-stun-hitboxes). **Dependencies:** [P02-T30](#p02-t30), [P03-T07](#p03-t07).
  - **Work:**
    - Keyboard layouts: WASD (E confirm, R rotate), IJKL (O, P), arrows (Enter, Right Shift) and numpad 8 4 2 6 (0, 5). Seats follow join order, so any layout can be any player. Prompts, lobby device names and Library controls cover all four.
    - The Lobby map row has ◀ ▶ buttons that take mouse clicks.
    - The Place ghost draws the block's own art, rotated as it will be placed, with a facing-arrow badge, the block name and the angle.
    - The Library has a clickable Back button.
  - **Acceptance:** Every layout drives confirm/rotate/move/jump/ready, and F no longer confirms (*2026-10-16 later, user request:* F confirms again alongside E; see [P02-T34](#p02-t34)). Join order sets seat numbers. Mouse clicks change the map and leave the Library. The ghost preview matches the block and its rotation.
  - **Evidence:** [controls evidence](evidence/controls/README.md) (13 checks, captures). **Result:** PASSED (synthetic). Physical four-player keyboard rollover is untested. **Build:** Godot 4.7.stable.official.5b4e0cb0f, 2026-10-16, reviewer: Claude (AI, automated; no human reviewer).

#### P02-T34

- [x] **Add a ledge climb and let WASD confirm with E or F**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD); user request (2026-10-16).
  - **Requirements:** [REQ-MOVE-004](PRD.md#req-move-004--slide-on-eligible-walls-and-kick-away-with-a-fresh-jump-press), [REQ-INPUT-001](PRD.md#req-input-001--assign-devices-and-fixed-chicken-identity). **Dependencies:** [P02-T22](#p02-t22), [P02-T33](#p02-t33).
  - **Work:**
    - `ChickenController` ledge climb: airborne against a wall-slide-eligible wall, holding toward it, with that contacted collider's top within reach of the head and room to stand, the chicken pulls up onto the ledge (`find_ledge_target`, `_advance_ledge_climb`). The rise completes before the over-edge movement; initial route and every movement step are collision checked. Tuning: `ledge_climb_enabled`, `ledge_reach_above_head_wu` 24, `ledge_reach_below_head_wu` 64, `ledge_climb_seconds` 0.22, `ledge_climb_max_rise_wu_s` 240.
    - Wall-ineligible ledges are never climbed, so the tutorial flag ledge still needs its route.
    - K1 confirms, readies and claims with E or F (router, prompt glyph "E / F").
    - Same-day bug fixes are recorded in [fix evidence](evidence/fixes/README.md): long Cannon path clamp and lane clip, broken block scenes skipped, pause panel for empty seats, first come, first served removed, explosives blowing up same-phase placements.
  - **Acceptance:** A plain jump cannot reach a 4-tile wall top; the same jump holding toward the wall climbs it once and stands on top. No climb without holding toward the wall, without headroom, when the top belongs to unrelated geometry, or when the swept route is blocked. The tutorial gate still holds. F and E both confirm for WASD.
  - **Evidence:** [fix evidence](evidence/fixes/README.md) (`run_ledge_climb_tests.gd` 37 checks, `run_controls_tests.gd` 13, `run_tutorial_gate_tests.gd` 48); the relevant reruns and incomplete tutorial-gate search are itemized in [upward wall movement fix evidence](evidence/fixes/2026-10-19_wall_upward_slide_fix.txt). **Result:** PASSED for synthetic ledge/wall engineering checks. Human feel review is open under [P02-T29](#p02-t29). **Build:** Godot 4.7.2.stable.official.ed1daf0bf, 2026-10-19, reviewer: Codex (AI, automated; no human reviewer).

#### P02-T35

- [x] **Use the one-tile sneak body as the chicken's hitbox while sneaking**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD); user request (2026-10-16).
  - **Requirements:** [REQ-MOVE-005](PRD.md#req-move-005--sneak-into-a-one-tile-body-and-glide-while-holding-jump). **Dependencies:** [P02-T24](#p02-t24), [P02-T28](#p02-t28).
  - **Work:** `ChickenController.hit_rect()` returns the 56×56 sneak body at the feet while sneaking, otherwise the standing body. Users: `SweptContact.body_rect` (every item hazard and block kill/stun hitbox) and the placement-clearance rects (`ItemLabRoom._actor_rects`, `P12ScheduledMatchRoom._actor_rects_except`). The collision body and tag sensor already shrank.
  - **Acceptance:** A standing chicken is hit by a head-height slipper lane and a sneaking chicken in the same spot is not; the tile just above a sneaking chicken accepts a piece, while the same tile above a standing chicken is refused.
  - **Evidence:** [fix evidence](evidence/fixes/README.md) (`run_sneak_hitbox_tests.gd` 5 checks, full headless regression). **Result:** PASSED (synthetic). Feel review is open under [P02-T26](#p02-t26). **Build:** Godot 4.7.stable.official.5b4e0cb0f, Item Lab, 60 Hz, 2026-10-16, reviewer: Claude (AI, automated; no human reviewer).

#### P02-T29

- [ ] **Verify block scenes, Spikes, Cannon and stun with players**
  - **Status:** BLOCKED (human review) · **Kind:** VERIFY · **Scope:** SHOULD · **Owner:** QA / Human playtester (names TBD).
  - **Requirements:** [REQ-STAGE-005](PRD.md#req-stage-005--scene-authored-block-catalog-with-kill-and-stun-hitboxes). **Dependencies:** [P02-T27](#p02-t27), [P02-T28](#p02-t28).
  - **Work:** Edit a block in the Godot editor and play it; judge spike/cannon fairness, ledge climb reach and feel (P02-T34), Bomb/Dynamite/Nuke power and egg rarity, stun time and knockback, readability of hitboxes, and whether seat-order resolution of same-spot placements feels fair (P02-T30; first come, first served was removed 2026-10-16).
  - **Acceptance:** Named reviewer, devices, player count, procedure and findings recorded.
  - **Evidence:** **Current result (2026-10-14):** NOT DONE.

## P03 — Graybox stage and camera

**Goal / player-visible result:** Players can traverse one bounded stage and remain visible.

**Milestone / scope:** First playable and foundational delivery.

**Entry:** P02 measured controller and bounds available.

**External task dependencies:** [P02-T10](#p02-t10), [P02-T12](#p02-t12), [P02-T14](#p02-t14)

**Owner roles:** Gameplay; person names TBD. **Systems touched:** NEW arena, grid/protected-zone data, camera and supporting-surface state.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Base route, protected grid, support provenance and camera separation cases pass.

**Evidence required:** Route trials, bounds/zoom captures and support matrix.

**Phase roll-up (2026-10-13): 6/6 task records passed; P03 is complete for the graybox stage, camera and support contracts.** Passed: P03-T01–T06. Dependencies P02-T10, P02-T12 and P02-T14 were rechecked as passed. At P03 completion, the original P02 task set was 8/14; the current P02 tracker is 8/22 after the later wall-movement extension, with physical input/reconnect tasks still open. P03 uses a 32-wu grid and a 1024×512-wu scene; the real-controller route, target fitting, rendered screenshots and support fixtures are recorded below and in [the P03 verification index](evidence/p03/2026-10-13_p03_verification.md). This phase does not implement the full Pugad/Place/match loop, item placement or removal, Kangaroo scheduling, scoring, hazards, or production presentation.


#### P03-T01

- [x] **Build the arena and protected-zone data**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-STAGE-001](PRD.md#req-stage-001--build-one-protected-barrio-graybox-arena). **Dependencies:** [P02-T10](#p02-t10), [P02-T14](#p02-t14).
  - **Work:** Start with solid floor, left spawn, right flag, few base platforms and fixed bounds. Base/floor/spawn/goal are indestructible; hidden event goal clearance remains protected. Use the provisional 1024×512 wu graybox only after controller measurement. Layouts created by players need not remain solvable.
  - **Acceptance:** Base route is traversable before construction; bounds/protected zones are visible in tests; no placement/removal changes immutable geometry. Paper reachability is confirmed by actual collision trials.
  - **Evidence:** `tilaok!/scripts/stage/arena_definition.gd`, `tilaok!/scripts/harness/p03_stage_room.gd`, `tilaok!/scenes/fixtures/p03_stage_room.tscn`, and [P03 tests](evidence/p03/2026-10-13_p03_tests.txt). The table uses tile-edge coordinates, a 32-wu grid and a 1024×512-wu arena. Feet `(96,480)` convert to the controller center `(96,456)` using its 48-wu body height. **Procedure / expected / actual:** instantiate the real arena data, validate footprint/sweep/effect regions against protected spawn/goal, bounds and base pieces, attempt guarded base edits/removal, and compare the immutable-geometry signature. Expected: visible labeled zones and unchanged immutable geometry after rejected edits; actual: every guard assertion passed and the signature stayed unchanged. The optional upper E platform was omitted. **Verification result:** PASSED as implementation; the paired collision trial is P03-T02. **Reviewer:** Codex (automated, implementation author); no human review claimed.


#### P03-T02

- [x] **Verify build one protected barrio graybox arena**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-STAGE-001](PRD.md#req-stage-001--build-one-protected-barrio-graybox-arena). **Dependencies:** [P03-T01](#p03-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Base route is traversable before construction; bounds/protected zones are visible in tests; no placement/removal changes immutable geometry. Paper reachability is confirmed by actual collision trials.
  - **Acceptance:** Base route is traversable before construction; bounds/protected zones are visible in tests; no placement/removal changes immutable geometry. Paper reachability is confirmed by actual collision trials.
  - **Evidence:** [100 P03 assertions](evidence/p03/2026-10-13_p03_tests.txt), [interactive 1080p harness capture](evidence/p03/2026-10-13_interactive_harness_1080p.png), and [capture set](evidence/p03/2026-10-13_play_1080p.png). **Build/profile/seed:** Godot 4.7.2, `P03-graybox-dev` on the local `4cb31a9` working tree, `movement_room`, seed 12345, 60-Hz physics. **Procedure / expected / actual:** run the route with the real `ChickenController` and Godot collision from floor→A→B→C→D→goal, without teleporting between route platforms; check head/body clearance, takeoffs, landings, braking and bounds; exercise edit/removal guards on the arena definition. Expected: goal reached inside bounds and rejected edits preserve immutable geometry; actual: route reached the goal at `(1012,360)` and all route/protection assertions passed. **Verification result:** PASSED for the graybox route/protection contract; no claim that later player construction remains solvable. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P03-T03

- [x] **Implement bounded dynamic camera and readability probes**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-STAGE-002](PRD.md#req-stage-002--frame-active-players-and-unfinished-placement-pointers). **Dependencies:** [P03-T02](#p03-t02).
  - **Work:** Play frames live unfinished chickens; eliminated/secured chickens are excluded. Place frames unconfirmed pointers including item extents. Ease framing changes with bounded zoom/pan; zoom out fast enough for launches. Empty sets hold safe framing. HUD remains screen-sized.
  - **Acceptance:** At 2/3/4 players, maximum separation/high construction/launches keep relevant targets visible and readable; finishing/confirming removes the correct target without unsafe snapping.
  - **Evidence:** `tilaok!/scripts/camera/bounded_stage_camera.gd`, `tilaok!/scripts/camera/stage_camera_target.gd`, and `tilaok!/scripts/harness/p03_stage_room.gd`. **Procedure / expected / actual:** configure the target rectangles and viewport/HUD defaults; run Play and Place contexts; fit actual body/badge or preview extents, clamp with viewport bounds, and retain the last safe framing for empty targets. Expected: launches zoom out before targets leave the usable area, zoom-in easing never hides targets, and the HUD remains screen-sized; actual: bounded fitting, safe clamps and target filtering are implemented and pass the paired checks in P03-T04. **Verification result:** PASSED as implementation; runtime coverage is P03-T04. **Reviewer:** Codex (implementation author); no human review claimed.


#### P03-T04

- [x] **Verify frame active players and unfinished placement pointers**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-STAGE-002](PRD.md#req-stage-002--frame-active-players-and-unfinished-placement-pointers). **Dependencies:** [P03-T03](#p03-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. At 2/3/4 players, maximum separation/high construction/launches keep relevant targets visible and readable; finishing/confirming removes the correct target without unsafe snapping.
  - **Acceptance:** At 2/3/4 players, maximum separation/high construction/launches keep relevant targets visible and readable; finishing/confirming removes the correct target without unsafe snapping.
  - **Evidence:** [P03 tests](evidence/p03/2026-10-13_p03_tests.txt), [Play at 1080p](evidence/p03/2026-10-13_play_1080p.png), [Place at 1080p](evidence/p03/2026-10-13_place_1080p.png), [wide-window Place capture](evidence/p03/2026-10-13_place_wide_window_1920x800.png), and [interactive UI test](evidence/p03/2026-10-13_interactive_test.txt). **Procedure / expected / actual:** fit 2/3/4 targets at opposite bounds and high construction; check full preview rectangles, rotated extents, 900-wu/s controller launch, Play/Place target membership, individual finishing/elimination/confirmation, empty-set hold, oversized bounds and pause; render at 1920×1080, then resize the window to 1920×800. Expected: each full target stays in the HUD-safe area, 16:9 gameplay world remains fixed, and identity/geometry stay legible at zoom 1.0; actual: all screen-containment assertions passed, the GUI flow passed 14/14, the 1920×1080 captures rendered at zoom 1.0, and the wide window retained a 1280×720 logical viewport (1422×800 game image). **Verification result:** PASSED for synthetic camera fixtures and the rendered graybox; camera fixture movement is not physical-controller certification. **Reviewer:** Codex inspected the screenshots and ran automated checks; no independent human review claimed.


#### P03-T05

- [x] **Implement supporting-surface provenance and invalidation**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-STAGE-003](PRD.md#req-stage-003--track-actual-supporting-contact-and-construction-provenance). **Dependencies:** [P03-T02](#p03-t02), [P02-T12](#p02-t12).
  - **Work:** Track player-built provenance and explicit wave-support eligibility on authored surfaces. Actual upward supporting contact after movement/destruction is required; stale grounded/coyote/sensor states are insufficient. The tested prototype normal limit is within 45 degrees, v1 tops are horizontal, and contact/height tolerances are 1 wu; player feel remains for future Kangaroo playtesting.
  - **Acceptance:** Support row matrix distinguishes base, Kaing, one-way bridge, launch, moving/removed surface, bubble, projectile, side contact and airborne state; missing eligibility metadata fails content validation.
  - **Evidence:** `tilaok!/scripts/stage/support_surface_metadata.gd`, `tilaok!/scripts/stage/support_contact.gd`, `tilaok!/scripts/stage/support_tracker.gd`, `tilaok!/scripts/movement/chicken_controller.gd`, and [P03 tests](evidence/p03/2026-10-13_p03_tests.txt). **Procedure / expected / actual:** validate required eligibility/provenance, record only actual post-movement upward slide contacts with stable surface/construction IDs, and invalidate support synchronously on launch, capture, terminal/reset, or surface removal. Expected: a same-step queued removal cannot qualify and freed support nodes are not dereferenced; actual: contact, lifecycle and invalidation checks passed with 1-wu height/contact tolerances and no gameplay-time grace. Authored children inherit provenance only through an explicit eligible parent contract; any player's construction can support any actor. **Verification result:** PASSED as implementation; the collision matrix is P03-T06. This does not implement a Kangaroo event, wave scheduler or score outcome. **Reviewer:** Codex (implementation author); no human review claimed.


#### P03-T06

- [x] **Verify track actual supporting contact and construction provenance**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-STAGE-003](PRD.md#req-stage-003--track-actual-supporting-contact-and-construction-provenance). **Dependencies:** [P03-T05](#p03-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Support row matrix distinguishes base, Kaing, one-way bridge, launch, moving/removed surface, bubble, projectile, side contact and airborne state; missing eligibility metadata fails content validation.
  - **Acceptance:** Support row matrix distinguishes base, Kaing, one-way bridge, launch, moving/removed surface, bubble, projectile, side contact and airborne state; missing eligibility metadata fails content validation.
  - **Evidence:** [100 P03 physics/assertion results](evidence/p03/2026-10-13_p03_tests.txt) and [support diagnostic rendering](evidence/p03/2026-10-13_play_1080p.png). **Procedure / expected / actual:** exercise real upward contacts for Kaing-like and one-way platforms; separate spring support from a launch; test marked safe hazard faces, moving/collapsing supports, inherited child provenance, elevated base platforms, another player's construction, overlapping chickens, capture, projectile collision, side-wall contact, coyote state and airborne crossing. Test just above/on/below sample boundaries y=384/320/256 wu using actual colliders. Expected: only explicit player-built eligible upward contact at `feet_y <= line_y + 1 wu` qualifies, and removal/launch invalidates it in the evaluation step; actual: all matrix and metadata assertions passed. The three lines are labeled test fixtures because P03 does not define the future event's selected wave heights. **Verification result:** PASSED for the support contract and diagnostic fixtures; no hazards, springs or temporary items are enabled in the production catalog. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P03-T07

- [x] **Add map scenes with dev markers and a Lobby map selection**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD); maps Jorge/Ivie; user request (2026-10-16).
  - **Requirements:** [REQ-STAGE-005](PRD.md#req-stage-005--scene-authored-block-catalog-with-kill-and-stun-hitboxes). **Dependencies:** [P03-T01](#p03-t01).
  - **Work:**
    - `scenes/maps/`: each map scene has a `StageMap` root and two TileMapLayers. `DevMarkers` has three tiles (Spawn, Build Area, Flag). `Blocks` is painted with the block sprite sheet; cells merge into collision rectangles.
    - `MapCatalog` scans the folder: a new map scene appears in the selection with no other edit, and invalid maps are reported and left out.
    - Lobby map row: any joined seat's left/right rebuilds the room on the next map; `-- --map=<id>` also works. The map's Blocks layer replaces the debug stage tiles in the match.
    - Sample Map reproduces the default stage.
    - Follow-up the same day:
      - The tutorial stage is the Tutorial map scene; it matches the verified layout exactly, and the tutorial gate suite (48 checks, 3,341 attempts) passes on it.
      - Precise settings handle the half-tile ledge and the `no_wall_slide` tile flag.
      - Cells outside the stage are decoration (the team's framed Basic Map now loads).
      - The Lobby map row works during the tutorial: picking another map skips it, and picking Tutorial brings it back.
      - The Lobby rescans the folder each time it opens.
  - **Acceptance:** The catalog lists the default plus each valid map scene. Blocks and markers convert to the right surfaces, build region, spawn and flag. A dropped-in map appears and a broken one is excluded with a reason. A chicken stands on a map's generated floor in a real match. Lobby left/right changes the map, keeps the seats, and shows the name.
  - **Evidence:** [maps evidence](evidence/maps/README.md) (27 checks, tutorial parity, captures). **Result:** PASSED (synthetic). **Build:** Godot 4.7.stable.official.5b4e0cb0f, 2026-10-16, reviewer: Claude (AI, automated; no human reviewer).


## P04 — Item infrastructure and construction seeds

**Goal / player-visible result:** Kaing and Tulay make the initial buildable course.

**Milestone / scope:** First playable and foundational delivery.

**Entry:** P01 configuration and P03 grid/collision contracts available.

**External task dependencies:** [P01-T04](#p01-t04), [P01-T08](#p01-t08), [P03-T02](#p03-t02), [P05-T02](#p05-t02), [P05-T06](#p05-t06), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10), [P13-T06](#p13-t06)

**Owner roles:** Gameplay; person names TBD. **Systems touched:** NEW item resources/runtime, Kaing and Tulay scenes.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Early exit: shared infrastructure and both core harness tests pass. Final seed-family enablement follows later preview/Library/event checks; it does not block P05.

**Evidence required:** Per-variant collision, one-way, reset and later integration records.

**Phase roll-up (2026-10-13): 18/22 task records passed; the P04 early exit is MET (shared infrastructure and both core harness tests pass). P04 is NOT complete: 4 records remain unchecked.** Passed: P04-T01–T10, T12, T14–T19 and T21. At the P04 checkpoint, T10, T12, T19 and T21 passed on **placeholder** code-drawn eggs, ghosts and a Library entry model under a dated, owner-approved scope note on each record. Final art and the P13 Library remain open; shared P05 egg/ghost/match components were implemented and verified in the 2026-10-14 P05 records. Unchecked and blocked: T11 and T20 (Lagsanay P08-T06, Kangaroo P11-T12, stack pairing P12-T04 — those modes do not exist); T13 and T22 (release enablement: P13-T06, P12-T06/T08/T10 and T11/T20). Evidence is indexed in the [P04 verification index](evidence/p04/2026-10-13_p04_verification.md). The seeds are enabled for the development `karera_slice` profile only; `release_target` is false until T13/T22. Item Lab placement remains immediate and lab-only. P05 now provides Pugad and atomic placement; Walis Cleanup, scoring and every other item family remain unimplemented. **Update (2026-10-16): 20/22.** T11 and T20 passed on the scheduled P12 route ([integration evidence](evidence/integration/README.md)): mode-filtered Pugad eggs and Kaing/Tulay terrain rows in every independent mode and supported stack; Tulay stays pending the human Lagsanay safe-floor review. T13 and T22 (release enablement) remain open.


#### P04-T01

- [x] **Implement shared item definitions and validation**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEMSYS-001](PRD.md#req-itemsys-001--define-item-metadata-and-bounded-regions). **Dependencies:** [P01-T04](#p01-t04), [P03-T02](#p03-t02).
  - **Work:** Item definitions use stable catalog IDs and explicit family/variant, footprint, solid/trigger, sweep/lane/effect regions, rotations, ownership, safe start, removal, event eligibility and preview/Library presentation. Centralize all tunables. Only approved variants may enter pools.
  - **Acceptance:** Definition validation rejects missing required fields, unbounded regions and undocumented variants; effect regions remain distinct from occupied grid cells.
  - **Evidence:** `tilaok!/scripts/items/` (`item_region_spec.gd`, `item_variant_definition.gd`, `item_family_definition.gd`, `item_approved_variants.gd`, `item_definition_validator.gd`, `item_definitions.gd`), `tilaok!/data/items/build.hollow_blocks.tres`, `tilaok!/data/items/build.bamboo_bridge.tres`, the `item_*` tunables in `tilaok!/scripts/config/gameplay_tuning.gd`, and [P04 tests](evidence/p04/2026-10-13_p04_tests.txt). **Procedure / expected / actual:** load the shipped typed `.tres` definitions and validate them with the single `ItemDefinitionValidator`. Expected: zero errors; every listed field (stable catalog ID, family/variant, footprint, solid/one-way/trigger/sweep/lane/effect regions, rotations, ownership, safe start, removal, event eligibility, preview/Library fields) present; caps, TTLs, grace, weights, strip thickness, the enabled-variant list and the vertical gate live only in `GameplayTuning`. Actual: 2 families / 6 variants valid; caps 48 / 16 (2 per emitter) / 4 (1 per emitter, 1 per player) / 32; TTL 3 / 4 / 2 s; grace 1.0 s; tuning validation rejects a zero cap and a zero strip. **Verification result:** PASSED (implementation); rejection coverage is P04-T02. **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + the P04 commit; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P04-T02

- [x] **Verify define item metadata and bounded regions**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEMSYS-001](PRD.md#req-itemsys-001--define-item-metadata-and-bounded-regions). **Dependencies:** [P04-T01](#p04-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Definition validation rejects missing required fields, unbounded regions and undocumented variants; effect regions remain distinct from occupied grid cells.
  - **Acceptance:** Definition validation rejects missing required fields, unbounded regions and undocumented variants; effect regions remain distinct from occupied grid cells.
  - **Evidence:** [P04 tests](evidence/p04/2026-10-13_p04_tests.txt) (`T02 reject:` rows and the effect-region checks) and [P04 verification index](evidence/p04/2026-10-13_p04_verification.md). **Procedure / expected / actual:** mutate copies of the shipped definitions and validate each. Expected: every case is rejected with a specific message. Actual: 31 of 31 cases rejected — missing family ID, ownership, safe start, removal, persistence, event eligibility, wall-contact declaration, weight key, preview and Library fields; no variants, rotations or regions; unset region kind; zero-size, infinite and arena-sized regions; sweep/effect not declared bounded; solid outside footprint; missing or oversized strip thickness; one-way strip overlapping a solid; runtime-enabled without verification; duplicate variant; enabled-but-undefined variant; undocumented variant; wrong documented footprint. A bounded 3×3 effect around a 1×1 leaves the occupied footprint at one cell (32×32 wu), allows a neighbour piece inside the effect, and an effect reaching protected spawn is rejected. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + the P04 commit; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P04-T03

- [x] **Implement shared lifecycle, caps and teardown**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEMSYS-002](PRD.md#req-itemsys-002--implement-persistent-items-and-bounded-transient-lifecycle). **Dependencies:** [P04-T02](#p04-t02), [P01-T08](#p01-t08).
  - **Work:** Items are inert in Place except Walis edit; reset deterministic position/direction/phase at Play with configurable grace. Persist placed construction across rounds and remove it on match reset. Clear timers/signals/projectiles/captures on appropriate removal/death/end/restart. Prototype caps: 48 persistent, 16 projectiles, 4 bubbles, 32 VFX; saturation suppresses spawns rather than evicting captives.
  - **Acceptance:** Ten reset cycles retain only intended construction and no transient state. Saturation/removal releases references and captives safely; spawn allocation follows reviewed rotating order, not callback order.
  - **Evidence:** `tilaok!/scripts/items/item_manager.gd`, `transient_budget.gd`, `placed_item.gd`, `item_placement_validator.gd`, the `unregister_player_construction()` addition in `tilaok!/scripts/stage/arena_definition.gd`, and [P04 tests](evidence/p04/2026-10-13_p04_tests.txt). **Procedure / expected / actual:** exercise Place/Play/round-end/match-reset on a live `ItemManager`, plus the transient budget with test-only emitters. Expected: construction is placed only in Place, Play start resets deterministically with a configurable grace, construction persists across rounds and is removed at match reset, removal/end/restart clear timers, transients and captives, caps 48/16/4/32 suppress rather than evict, grants follow a rotating stable-ID order. Actual: all implemented and exercised; placement during Play is rejected `wrong_phase`; grace restarts at 1.0 s each Play; the 49th persistent piece is rejected `persistent_cap`. **Verification result:** PASSED (implementation); the ten-cycle and saturation acceptance evidence is P04-T04. Projectile/bubble/VFX use is test-only (no P04 item spawns them). **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + the P04 commit; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P04-T04

- [x] **Verify implement persistent items and bounded transient lifecycle**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEMSYS-002](PRD.md#req-itemsys-002--implement-persistent-items-and-bounded-transient-lifecycle). **Dependencies:** [P04-T03](#p04-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Ten reset cycles retain only intended construction and no transient state. Saturation/removal releases references and captives safely; spawn allocation follows reviewed rotating order, not callback order.
  - **Acceptance:** Ten reset cycles retain only intended construction and no transient state. Saturation/removal releases references and captives safely; spawn allocation follows reviewed rotating order, not callback order.
  - **Evidence:** [P04 tests](evidence/p04/2026-10-13_p04_tests.txt) (`cycle N:`, `T04 ten cycles:` and transient-budget rows) and [P04 verification index](evidence/p04/2026-10-13_p04_verification.md). **Procedure / expected / actual:** ten Play/round-end cycles over three placed pieces with test-only projectile, bubble (with a captive) and VFX allocations each cycle, then saturation, permutation and TTL trials. Expected: only the intended construction survives, zero transients, stable node/object counts, saturation never evicts a captive, rotating order independent of callback order. Actual: signature and surface IDs identical in all 10 cycles; node count 110 → 110, object count 1760 → 1760, orphan nodes 0 → 0; 20 requesters yield 16 projectiles then suppression, 6 emitters yield 4 bubbles, 40 requesters yield 32 VFX, one emitter is limited to 2 projectiles; with 6 emitters, cap 4 and 6 rounds each emitter wins exactly 4 times and reversed callback order yields the identical grant sequence; a captive's bubble survives saturation and TTL, is released explicitly, and `clear_all` / emitter removal release captives. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + the P04 commit; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


### Hollow Blocks / Kaing Stack — `build.hollow_blocks`


#### P04-T05

- [x] **Define Hollow Blocks / Kaing Stack configuration and variants**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04).
  - **Work:** Author the family definition from the catalog; expose tuning keys and keep precision/effect regions distinct.
  - **Acceptance:** Definition lists 1×1, 1×3 column, 2×3 stack; prototype slice initially 1×1 and 2×3 only. Regions, rotations, safe start, owner and mode flags are explicit.
  - **Evidence:** `tilaok!/data/items/build.hollow_blocks.tres`, `tilaok!/scripts/items/item_approved_variants.gd`, `item_enabled_variants` in `gameplay_tuning.gd`, and [P04 tests](evidence/p04/2026-10-13_p04_tests.txt). **Procedure / expected / actual:** load the Kaing definition and read it back. Expected: variants 1×1, 1×3 column and 2×3 stack; prototype subset 1×1 and 2×3 only; regions, rotations, safe start, owner and mode flags explicit. Actual: `cell_1x1`, `column_1x3`, `stack_2x3` defined; enabled subset is exactly `cell_1x1` and `stack_2x3` (data, not code); each variant is one SOLID region equal to its footprint with no trigger; rotations `[0]` for 1×1 (with a disabled-rotation cue) and `[0,1]` for 1×3 and 2×3; safe start `static_no_motion`; owner `placer`; modes karera + lagsanay allowed; wall-contact declaration `eligible` (solid sides carry `wall_movement_eligibility` ELIGIBLE; it only matters if the separate, enabled-by-default wall extension is enabled). **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + the P04 commit; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P04-T06

- [x] **Build Hollow Blocks / Kaing Stack scene and collision regions**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack). **Dependencies:** [P04-T05](#p04-t05).
  - **Work:** Create original scene/solid/sensor regions and visible bounds; verify the family-specific placement and rotation contract.
  - **Acceptance:** One-cell and 2×3-cell variants in a single family; 90° rotation where footprint changes. Solid full footprint, no trigger. No overlap with protected geometry or other solids; projectile occlusion uses actual solid volume. Footprint and item cap are tunables.
  - **Evidence:** `tilaok!/scenes/items/kaing_piece.tscn`, `tilaok!/scripts/items/construction_piece.gd`, `item_geometry.gd`, `item_placement_validator.gd`, and [P04 tests](evidence/p04/2026-10-13_p04_tests.txt) (`T06 Kaing collider`, `T06/T15 placement` rows). **Procedure / expected / actual:** instantiate each enabled variant/rotation and inspect shapes; run the placement validator against each protected condition. Expected: solid equals the full footprint, no trigger, 90° rotation where the footprint changes, no overlap with protected geometry or other solids, occlusion volume equals the solid, footprint and cap are tunables. Actual: 32×32, 64×96 and rotated 96×64 pieces each have exactly one collision shape equal to the footprint and an occlusion rect equal to it; placements reject `out_of_bounds`, `protected_spawn`, `protected_goal`, `outside_build_region`, `immutable_base`, `player_clearance`, `item_overlap`, `variant_disabled`, `unknown_variant` and `rotation_unsupported`; a flush neighbour that only shares an edge is valid. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + the P04 commit; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P04-T07

- [x] **Implement Hollow Blocks / Kaing Stack mechanic and feedback**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack). **Dependencies:** [P04-T06](#p04-t06).
  - **Work:** Implement the family behavior, tell and counterplay without copying reference code/art; use centralized timing/force settings.
  - **Acceptance:** Solid construction pieces create footholds, walls, routes, and projectile cover. Danger is route obstruction or hiding a tell. Tell: strong distinct crate silhouette and placement ghost. Counter: jump around/over, use another route, or Walis Cleanup. UCH basic-block inspiration; original barrio treatment.
  - **Evidence:** [P04 tests](evidence/p04/2026-10-13_p04_tests.txt) (`T09 Kaing` rows), [variants capture](evidence/p04/2026-10-13_variants_enabled_1080p.png), [Kaing ghost capture](evidence/p04/2026-10-13_ghost_kaing_1080p.png) and [valid/invalid ghost capture](evidence/p04/2026-10-13_ghost_valid_invalid_1080p.png). **Procedure / expected / actual:** real `ChickenController` trials plus rendered 1080p inspection. Expected: footholds, walls, routes and cover; tell = crate silhouette + placement ghost; counter = go around/over, another route, or Walis. Actual: stands on 1×1, 2×3 and rotated 3×2 (feet y=255.98, eligible built support); a 2×3 stops a running chicken at x=396 (side contact not counted as support); a chicken jumps from the floor onto a 1×1 foothold (feet 447.93); the underside stops the head at y=288 with a ceiling contact; occlusion rect equals the solid. Captures show cross-braced crate silhouettes labeled DEBUG and ghosts with outline style, OK/X mark and a text reason in addition to colour. Projectile cover is asserted as volume equality only — no projectile item exists yet. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + the P04 commit; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P04-T08

- [x] **Implement Hollow Blocks / Kaing Stack ownership and cleanup**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack). **Dependencies:** [P04-T07](#p04-t07).
  - **Work:** Preserve direct-source ownership/no-assist rules; implement inactive Place, deterministic Play reset, persistent removal and reference/transient teardown.
  - **Acceptance:** Usable in race and event rounds including Lagsanay. Owner is placer; removable by Walis Cleanup; persists until removed, no moving state. Needs original crate/block sprites and sound. Low relative risk; depends on placement grid/collision and cleanup. Cultural check: “kaing” use/context.
  - **Evidence:** `tilaok!/scripts/items/item_manager.gd` (`place`, `remove`, `begin_play`, `end_round`, `reset_match`), `placed_item.gd`, `construction_piece.gd`, and [P04 tests](evidence/p04/2026-10-13_p04_tests.txt) (`T08 Kaing removal`, `cycle N`, `T04 ten cycles`). **Procedure / expected / actual:** place pieces for two seats, cycle rounds, remove in Place, attempt removal in Play. Expected: placer is owner, no trap credit, removable via the Walis hook, persists until removed, static reset, provenance is player-built and eligible. Actual: `PlacedItem.owner_seat` records the placer and the record has no Patibong field; `remove()` is rejected `wrong_phase` in Play, succeeds in Place, invalidates support the same step (`no support` immediately, chicken then falls), unregisters the construction and frees the node; pieces persist and return to identical positions across 10 cycles; the support surface is `player_built` with `ELIGIBLE` metadata. **Recorded follow-ups, not gates (owner decision 2026-10-13):** original crate/block art and sound — Jorge/Ivie (Art/UI), production art remains human-made; cultural check of the name “kaing” — Compliance/cultural reviewer. Both remain open. **Verification result:** PASSED for the code acceptance. **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + the P04 commit; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P04-T09

- [x] **Verify Hollow Blocks / Kaing Stack core behavior in its harness**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack). **Dependencies:** [P04-T08](#p04-t08).
  - **Work:** Run isolated collision/behavior/reset cases before exposing the family to a selectable pool; this is not the later event-compatibility gate.
  - **Acceptance:** Check all configured variants, rotations, collider boundaries, tell/counterplay, deterministic reset and removal. Capture actual results and known limits.
  - **Evidence:** [P04 tests](evidence/p04/2026-10-13_p04_tests.txt), [P04 verification index](evidence/p04/2026-10-13_p04_verification.md), [interactive Item Lab log](evidence/p04/2026-10-13_interactive_test.txt) and [Item Lab place capture](evidence/p04/2026-10-13_item_lab_place_1080p.png). **Procedure / expected / actual:** isolated real-physics cases for every configured variant and rotation, collider boundaries, tell/counterplay, deterministic reset and removal; the expected/actual rows are in the verification index. Expected: every row passes. Actual: enabled 1×1, 2×3 and rotated 3×2 pass stand/collider/side/route/underside/removal; defined-but-disabled 1×3 column and rotated 3×1 pass geometry and standing under a capture-only tuning override and are rejected `variant_disabled` otherwise; reset and removal rows pass. **Known limits:** projectile cover is volume equality only (no projectile item); disabled variants are geometry/standing only; wall slide/kick is a separate extension that is enabled by default as core movement (P02-T15–T22), so Kaing wall behaviour is verified only at the metadata and probe level (`T09 Kaing wall eligibility`) and not as a played feature; synthetic keyboard input only; no human feel review. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + the P04 commit; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P04-T10

- [x] **Add Hollow Blocks / Kaing Stack egg animation and placement ghost**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack), [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews), [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P04-T09](#p04-t09), [P05-T02](#p05-t02), [P05-T06](#p05-t06).
  - **Work:** Produce/register original visual preview assets; reuse shared preview infrastructure and preserve claimed variant identity.
  - **Acceptance:** Preview/ghost show 1×1, 1×3 column, 2×3 stack; prototype slice initially 1×1 and 2×3 only. Include relevant sweep/lane/effect and non-color validity; no Pugad names/descriptions.
  - **Evidence:** `tilaok!/scripts/items/item_egg_preview.gd`, the egg row and ghost in `tilaok!/scripts/harness/item_lab_room.gd`, [P04 tests](evidence/p04/2026-10-13_p04_tests.txt) (`T10/T19 egg to ghost to piece identity`), [eggs/Library capture](evidence/p04/2026-10-13_eggs_library_1080p.png) and the [Place capture](evidence/p04/2026-10-13_item_lab_place_1080p.png). **Procedure / expected / actual:** click each enabled egg, read the ghost, confirm and read the placed piece. Expected: the animated egg shows the exact variant (1×1, 2×3; the 1×3 column is not enabled and has no egg), the ghost keeps shape/size, validity uses non-colour cues, no names/descriptions. Actual: 3 enabled eggs (1×1, 2×3, Tulay 4×1) each with a looping 2 s animation and no text; claim → ghost → placed piece keeps the same variant key and footprint for every egg; ghost shows outline style, OK/X mark and text reason; Kaing and Tulay variants have no sweep/lane/effect regions to show. **Verification result:** PASSED for the placeholder acceptance. **Dated dependency/scope note (2026-10-13, approved by the project owner in chat: "generate placeholder art ... so we can test them"):** this record is satisfied by a code-drawn DEBUG placeholder built inside P04, not by the shared P05/P13 components or by final art. Original dependencies are kept unchanged above; the shared P05 preview components and the P13 Library shell must adopt or replace this placeholder, and Jorge/Ivie/Shanti still own the final human-made art. **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + P04 commits; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; synthetic keyboard seats and mouse clicks, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P04-T11

- [x] **Integrate Hollow Blocks / Kaing Stack with events and scoring**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack). **Dependencies:** [P04-T09](#p04-t09), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04).
  - **Work:** Apply catalog mode restrictions; unsafe capture/force chains block pairing enablement. Walis is construction-only, never a Play hazard.
  - **Acceptance:** Document enabled modes and support eligibility; verify direct credit/no credit and family-specific hazards or forces in independent modes and supported stacks.
  - **Evidence:** [integration evidence](evidence/integration/README.md) (`tests/run_item_mode_integration_tests.gd`, 83 checks, 0 failures) and the mode filter in `scripts/match/pugad_egg_pool_generator.gd` / `P12ScheduledMatchRoom.pugad_mode_ids`. **Procedure / expected / actual:** deal 1500 seeded eggs and the real room's Pugad for each of the six round types, then place the real piece through the Place resolver and run real physics with a held victim. Expected and actual: Kaing is dealt in every round type and is standable, wave-support eligible terrain that never eliminates or credits in all six round types (Karera, Lagsanay, Kangaroo, Karera + Bomb-Taya, Karera + Kangaroo, Kangaroo + Bomb-Taya). Enabled modes and support eligibility are documented in [ITEMS](ITEMS.md#event-and-stack-integration--2026-10-16). **Result:** PASSED (synthetic). **Build:** Godot 4.7.stable.official.5b4e0cb0f, Windows 11, scheduled P12 match room (default arena), 3–4 synthetic seats (K1/K2 plus synthetic gamepad IDs), seeded, 60 Hz (`--fixed-fps 60`), working tree on `fec0d3f`, 2026-10-16, reviewer: Claude (AI, automated; no human reviewer). Earlier history: blocked until P08-T06, P11-T12 and P12-T04 passed.


#### P04-T12

- [x] **Write and animate the Hollow Blocks / Kaing Stack Library entry**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack), [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P04-T10](#p04-t10).
  - **Work:** Author entry data/assets against the shared Library schema; integration is checked when the Library shell is available.
  - **Acceptance:** Entry includes name, looping animation, sizes, placement, tell/counterplay, controls and permitted modes; release filter exposes only enabled content.
  - **Evidence:** `tilaok!/scripts/items/item_library_entry.gd`, the Library panel and release filter in `item_lab_room.gd`, [P04 tests](evidence/p04/2026-10-13_p04_tests.txt) (`T12/T21 Library entry fields` and Library checks) and [eggs/Library capture](evidence/p04/2026-10-13_eggs_library_1080p.png). **Procedure / expected / actual:** open the Library for both families with and without the release filter. Expected: entry has name, looping animation, sizes, placement, tell/counterplay, controls and permitted modes; the release filter exposes only enabled content. Actual: both families list a working name (flagged for native-speaker review), size list with not-enabled sizes marked, placement rules, tell, counterplay, controls, allowed and pending-review modes and a looping animation; the release filter lists only content that is both runtime-enabled and a release target, so it correctly shows nothing today. **Verification result:** PASSED for the placeholder acceptance. **Dated dependency/scope note (2026-10-13, approved by the project owner in chat: "generate placeholder art ... so we can test them"):** this record is satisfied by a code-drawn DEBUG placeholder built inside P04, not by the shared P05/P13 components or by final art. Original dependencies are kept unchanged above; the shared P05 preview components and the P13 Library shell must adopt or replace this placeholder, and Jorge/Ivie/Shanti still own the final human-made art. **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + P04 commits; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; synthetic keyboard seats and mouse clicks, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P04-T13

- [ ] **Verify Hollow Blocks / Kaing Stack release enablement**
  - **Status:** BLOCKED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack). **Dependencies:** [P04-T11](#p04-t11), [P04-T12](#p04-t12), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Test harness plus 2/3/4-player integration, exact preview/ghost, Library, bounds, source credit, support and ten lifecycle resets. Register artifacts and unresolved defects before enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available. **Blocked by:** [P04-T11](#p04-t11), [P04-T12](#p04-t12), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10). **Next action:** run the 2/3/4-player integration, exact preview/ghost, Library and ten-reset checks, then decide `release_target` (currently false). **2026-10-16:** the family's integration task passed ([integration evidence](evidence/integration/README.md)) and it is in the match pool. Still open: the 2/3/4-player, preview/ghost, Library and ten-reset release run on final art, `PlaceholderAudit` replacement and the owner's `release_target` decision.


### Tulay na Kawayan — `build.bamboo_bridge`


#### P04-T14

- [x] **Define Tulay na Kawayan configuration and variants**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04).
  - **Work:** Author the family definition from the catalog; expose tuning keys and keep precision/effect regions distinct.
  - **Acceptance:** Definition lists 3×1, 4×1, 5×1; prototype starts horizontal 4×1; vertical 1×3/1×4/1×5 only after controller-support gate. Regions, rotations, safe start, owner and mode flags are explicit.
  - **Evidence:** `tilaok!/data/items/build.bamboo_bridge.tres`, `tilaok!/scripts/items/item_approved_variants.gd`, `item_enabled_variants` and `item_tulay_vertical_enabled` in `gameplay_tuning.gd`, and [P04 tests](evidence/p04/2026-10-13_p04_tests.txt). **Procedure / expected / actual:** load the Tulay definition. Expected: 3×1, 4×1 and 5×1; prototype starts horizontal 4×1; vertical only after the controller-support gate; regions, rotations, safe start, owner and mode flags explicit. Actual: `span_3x1`, `span_4x1`, `span_5x1` defined; enabled subset exactly `span_4x1`; each variant is one ONE_WAY_TOP strip region with its thickness taken from the `item_tulay_strip_thickness_wu` tunable; rotation `[0,1]` with turn 1 (vertical) gated by `item_tulay_vertical_enabled=false`, so placement rejects it as `rotation_unsupported`; owner `placer`; modes karera allowed, Lagsanay pending review; wall-contact declared `ineligible` (metadata INELIGIBLE; the wall probe finds no wall at its side). **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + the P04 commit; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P04-T15

- [x] **Build Tulay na Kawayan scene and collision regions**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan). **Dependencies:** [P04-T14](#p04-t14).
  - **Work:** Create original scene/solid/sensor regions and visible bounds; verify the family-specific placement and rotation contract.
  - **Acceptance:** One-way solid top, non-solid underside/sides; horizontal/vertical rotation in 90° steps if the movement model supports both. Footprint distinct from top collision strip. Length, thickness, allowed rotations are tunables.
  - **Evidence:** `tilaok!/scenes/items/tulay_piece.tscn`, `construction_piece.gd`, `item_geometry.gd`, and [P04 tests](evidence/p04/2026-10-13_p04_tests.txt) (`T15`, `T18` rows). **Procedure / expected / actual:** instantiate Tulay and inspect shapes; walk a chicken through its side; compute the gated vertical geometry. Expected: one-way solid top, non-solid underside/sides, footprint distinct from the strip, length/thickness/rotation tunable. Actual: footprint 128×32 wu with exactly one one-way shape of 128×4 wu at the top and no solid; a body overlapping strip height walks through the footprint side (max x 603.3); the occlusion list is empty (Tulay has no SOLID region); with the gate forced on, a 1×4 footprint gets a 4×128 wu strip on the right edge with a rightward normal (geometry only, not enabled). **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + the P04 commit; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P04-T16

- [x] **Implement Tulay na Kawayan mechanic and feedback**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan). **Dependencies:** [P04-T15](#p04-t15).
  - **Work:** Implement the family behavior, tell and counterplay without copying reference code/art; use centralized timing/force settings.
  - **Acceptance:** One-way thin bridge creates a route; its underside can be passed through, so it may be missed or become an ambush landing. Tell: narrow bamboo silhouette and one-way arrow on ghost. Counter: approach from below to pass through, or use another path. Inspired by the general utility-platform role; one-way behavior is Tilaok’s adaptation.
  - **Evidence:** [P04 tests](evidence/p04/2026-10-13_p04_tests.txt) (`T18 Tulay` rows), [valid/invalid ghost capture](evidence/p04/2026-10-13_ghost_valid_invalid_1080p.png) and [variants capture](evidence/p04/2026-10-13_variants_enabled_1080p.png). **Procedure / expected / actual:** real-controller trials plus rendered inspection. Expected: a one-way route whose underside can be passed through; tell = narrow bamboo silhouette + one-way arrow on the ghost; counter = approach from below or use another path. Actual: lands from above (feet 255.98, eligible built support); rises through from below (min feet 383.28, never supported while rising, then lands on top at 415.98); walks off an edge and jumps off. Captures show a yellow bamboo strip with node ticks, a dashed reservation outline, chevrons, and a ghost arrow drawn inside the footprint in addition to colour; all labeled DEBUG. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + the P04 commit; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P04-T17

- [x] **Implement Tulay na Kawayan ownership and cleanup**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan). **Dependencies:** [P04-T16](#p04-t16).
  - **Work:** Preserve direct-source ownership/no-assist rules; implement inactive Place, deterministic Play reset, persistent removal and reference/transient teardown.
  - **Acceptance:** Race and event terrain; enabled in Lagsanay only after safe-floor compatibility review. Placer owns it; cleanup removes it, otherwise persists. Static reset. Needs original bridge art. Medium risk because one-way collision must match run/jump-only controls. Verify material/name culturally; no “traditional rule” claim.
  - **Evidence:** `tilaok!/scripts/items/item_manager.gd`, `placed_item.gd`, `construction_piece.gd`, and [P04 tests](evidence/p04/2026-10-13_p04_tests.txt) (`cycle N`, `T04 ten cycles`, `T18` rows). **Procedure / expected / actual:** the same ownership/removal/reset trials with a Tulay in the set. Expected: placer owns it, cleanup removes it, otherwise persists, static reset, eligible player-built support, no “traditional rule” claim. Actual: identical ownership and removal behaviour to Kaing; Tulay persisted across 10 cycles with unchanged position; support is `player_built`, `ELIGIBLE`, counted only on a real landing. Lagsanay stays `modes_pending_review` (safe-floor compatibility review is later event work). **Recorded follow-ups, not gates (owner decision 2026-10-13):** original bridge art — Jorge/Ivie (Art/UI); verification of the material/name “kawayan/tulay” — Compliance/cultural reviewer; no traditional-game claim is made anywhere. **Verification result:** PASSED for the code acceptance. **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + the P04 commit; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P04-T18

- [x] **Verify Tulay na Kawayan core behavior in its harness**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan). **Dependencies:** [P04-T17](#p04-t17).
  - **Work:** Run isolated collision/behavior/reset cases before exposing the family to a selectable pool; this is not the later event-compatibility gate.
  - **Acceptance:** Check all configured variants, rotations, collider boundaries, tell/counterplay, deterministic reset and removal. Capture actual results and known limits.
  - **Evidence:** [P04 tests](evidence/p04/2026-10-13_p04_tests.txt), [P04 verification index](evidence/p04/2026-10-13_p04_verification.md), [interactive Item Lab log](evidence/p04/2026-10-13_interactive_test.txt) and [48-piece crowd capture](evidence/p04/2026-10-13_crowd_48_1080p.png). **Procedure / expected / actual:** isolated real-physics cases for every configured variant, collider boundary, tell/counterplay, reset and removal. Expected: every row passes. Actual: 4×1 land/jump-off/walk-off/rise-through/side pass-through/ceiling pass; five drops at the fall cap all land on the 4 wu strip (peak sampled 878.9 wu/s of the 900 cap, none tunnel); rising under the arena ceiling never clips (head y=0.00, then lands at 95.99); defined-but-disabled 3×1 and 5×1 pass geometry and standing; matrix rows: base floor `base surface`, airborne `no support`. **Known limits:** the vertical one-way orientation has geometry only — it was never exercised with the controller and stays gated; peak speed is sampled after the slide step; Lagsanay safe-floor compatibility is unreviewed; synthetic keyboard input only; no human feel review. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + the P04 commit; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P04-T19

- [x] **Add Tulay na Kawayan egg animation and placement ghost**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan), [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews), [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P04-T18](#p04-t18), [P05-T02](#p05-t02), [P05-T06](#p05-t06).
  - **Work:** Produce/register original visual preview assets; reuse shared preview infrastructure and preserve claimed variant identity.
  - **Acceptance:** Preview/ghost show 3×1, 4×1, 5×1; prototype starts horizontal 4×1; vertical 1×3/1×4/1×5 only after controller-support gate. Include relevant sweep/lane/effect and non-color validity; no Pugad names/descriptions.
  - **Evidence:** same as P04-T10 (`item_egg_preview.gd`, Item Lab egg row and ghost, [P04 tests](evidence/p04/2026-10-13_p04_tests.txt), [eggs/Library capture](evidence/p04/2026-10-13_eggs_library_1080p.png)), plus the [valid/invalid ghost capture](evidence/p04/2026-10-13_ghost_valid_invalid_1080p.png) showing the one-way arrow. **Procedure / expected / actual:** as T10 for the Tulay. Expected: 3×1, 4×1, 5×1 defined with prototype horizontal 4×1 only; vertical gated. Actual: the 4×1 egg shows a bamboo silhouette, a thin one-way strip and a pulsing up-arrow; the Library lists 3×1 and 5×1 as "not enabled yet"; the vertical ghost geometry exists but is gated and untested. **Verification result:** PASSED for the placeholder acceptance. **Dated dependency/scope note (2026-10-13, approved by the project owner in chat: "generate placeholder art ... so we can test them"):** this record is satisfied by a code-drawn DEBUG placeholder built inside P04, not by the shared P05/P13 components or by final art. Original dependencies are kept unchanged above; the shared P05 preview components and the P13 Library shell must adopt or replace this placeholder, and Jorge/Ivie/Shanti still own the final human-made art. **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + P04 commits; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; synthetic keyboard seats and mouse clicks, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P04-T20

- [x] **Integrate Tulay na Kawayan with events and scoring**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan). **Dependencies:** [P04-T18](#p04-t18), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04).
  - **Work:** Apply catalog mode restrictions; unsafe capture/force chains block pairing enablement. Walis is construction-only, never a Play hazard.
  - **Acceptance:** Document enabled modes and support eligibility; verify direct credit/no credit and family-specific hazards or forces in independent modes and supported stacks.
  - **Evidence:** [integration evidence](evidence/integration/README.md) (`tests/run_item_mode_integration_tests.gd`, 83 checks, 0 failures) and the mode filter in `scripts/match/pugad_egg_pool_generator.gd` / `P12ScheduledMatchRoom.pugad_mode_ids`. **Procedure / expected / actual:** deal 1500 seeded eggs and the real room's Pugad for each of the six round types, then place the real piece through the Place resolver and run real physics with a held victim. Expected and actual: Tulay is dealt in Karera and Kangaroo rounds and the Karera + Kangaroo stack, never in Lagsanay rounds or Bomb-Taya stacks (Lagsanay stays pending the human safe-floor review); a Tulay already on the stage is standable, wave-support eligible terrain that never eliminates in all six round types. Enabled modes and support eligibility are documented in [ITEMS](ITEMS.md#event-and-stack-integration--2026-10-16). **Result:** PASSED (synthetic). **Build:** Godot 4.7.stable.official.5b4e0cb0f, Windows 11, scheduled P12 match room (default arena), 3–4 synthetic seats (K1/K2 plus synthetic gamepad IDs), seeded, 60 Hz (`--fixed-fps 60`), working tree on `fec0d3f`, 2026-10-16, reviewer: Claude (AI, automated; no human reviewer). Earlier history: blocked until P08-T06, P11-T12 and P12-T04 passed.


#### P04-T21

- [x] **Write and animate the Tulay na Kawayan Library entry**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan), [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P04-T19](#p04-t19).
  - **Work:** Author entry data/assets against the shared Library schema; integration is checked when the Library shell is available.
  - **Acceptance:** Entry includes name, looping animation, sizes, placement, tell/counterplay, controls and permitted modes; release filter exposes only enabled content.
  - **Evidence:** same as P04-T12 for `build.bamboo_bridge` ([P04 tests](evidence/p04/2026-10-13_p04_tests.txt), [eggs/Library capture](evidence/p04/2026-10-13_eggs_library_1080p.png)). **Procedure / expected / actual:** as T12. Actual: the Tulay entry lists 3×1 (not enabled yet), 4×1, 5×1 (not enabled yet), one-way placement text, tell, counterplay, controls, modes `karera` with `lagsanay` pending review and a looping animation; the release filter hides it. **Verification result:** PASSED for the placeholder acceptance. **Dated dependency/scope note (2026-10-13, approved by the project owner in chat: "generate placeholder art ... so we can test them"):** this record is satisfied by a code-drawn DEBUG placeholder built inside P04, not by the shared P05/P13 components or by final art. Original dependencies are kept unchanged above; the shared P05 preview components and the P13 Library shell must adopt or replace this placeholder, and Jorge/Ivie/Shanti still own the final human-made art. **Build/engine/date/profile/seed/input:** `main` rebased onto `647929f` + P04 commits; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-13; `karera_slice`, seed 12345; synthetic keyboard seats and mouse clicks, no physical devices. **Reviewer:** Codex (automated, implementation author); no independent human review claimed.


#### P04-T22

- [ ] **Verify Tulay na Kawayan release enablement**
  - **Status:** BLOCKED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan). **Dependencies:** [P04-T20](#p04-t20), [P04-T21](#p04-t21), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Test harness plus 2/3/4-player integration, exact preview/ghost, Library, bounds, source credit, support and ten lifecycle resets. Register artifacts and unresolved defects before enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available. **Blocked by:** [P04-T20](#p04-t20), [P04-T21](#p04-t21), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10). **Next action:** run release-enablement integration after the blockers pass; vertical orientations additionally need recorded controller-support evidence. **2026-10-16:** the family's integration task passed ([integration evidence](evidence/integration/README.md)) and it is in the match pool. Still open: the 2/3/4-player, preview/ghost, Library and ten-reset release run on final art, `PlaceholderAudit` replacement and the owner's `release_target` decision.


## P05 — Lobby, Pugad and construction loop

**Goal / player-visible result:** Players join, recognize eggs and commit fair shared construction.

**Milestone / scope:** First playable and foundational delivery.

**Entry:** P04 seed core gates and P02 input exist; see task dependencies, not whole-phase completion.

**External task dependencies:** [P01-T06](#p01-t06), [P02-T06](#p02-t06), [P03-T04](#p03-t04), [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18), [P06-T08](#p06-t08)

**Owner roles:** Gameplay + Art/UI; person names TBD. **Systems touched:** NEW lobby/Pugad/Place flow, preview components and atomic edit resolver.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Simultaneous claims, atomic edits, timeout/discard, persistence, hints and lobby shell pass.

**Evidence required:** Claim/placement permutation results and variant/ghost captures.


#### P05-T01

- [x] **Build reusable animated egg previews and variant handoff**
  - **Status:** COMPLETE · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews). **Dependencies:** [P04-T02](#p04-t02).
  - **Work:** Every egg shows a short looping visual preview of its exact item and variant without names/descriptions. Claiming preserves variant identity through hatch to placement ghost. Library is the deliberate space for descriptions.
  - **Acceptance:** For every enabled variant, capture matching egg/ghost pairs; animation shows shape/effect extent and no descriptive name/text; no hidden size substitution.
  - **Evidence:** [P05 verification](evidence/p05/2026-10-14_p05_verification.md), [interactive handoff matrix](evidence/p05/variant_handoff_matrix.md), and matching egg/ghost/placed captures in `evidence/p05/`. Exact definition identity is retained through hatch, rotated ghost and materialized piece for every enabled variant. **Verification result:** PASSED — DEBUG preview is code-drawn and contains no variant names.


#### P05-T02

- [x] **Verify show exact-variant animated egg previews**
  - **Status:** COMPLETE · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews). **Dependencies:** [P05-T01](#p05-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. For every enabled variant, capture matching egg/ghost pairs; animation shows shape/effect extent and no descriptive name/text; no hidden size substitution.
  - **Acceptance:** For every enabled variant, capture matching egg/ghost pairs; animation shows shape/effect extent and no descriptive name/text; no hidden size substitution.
  - **Evidence:** [P05 interactive log](evidence/p05/p05_interactive_run.log), [variant handoff matrix](evidence/p05/variant_handoff_matrix.md), [exact variant pairs](evidence/p05/04_place_exact_variant_pairs_1920x1080.png), [rotated 2×3 ghost](evidence/p05/05_place_rotated_2x3_ghost_1920x1080.png). **Verification result:** PASSED — all three enabled definitions matched the egg/hatch/ghost/placed identity; Kaing 2×3 rotates to a visible 3×2 footprint.


#### P05-T03

- [x] **Implement claim arbitration, hatch and timeout assignment**
  - **Status:** COMPLETE · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-PUGAD-002](PRD.md#req-pugad-002--resolve-simultaneous-egg-claims-and-timeouts). **Dependencies:** [P05-T02](#p05-t02), [P02-T06](#p02-t06), [P01-T06](#p01-t06), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Pugad is simultaneous, one egg per player and one owner per egg. Approximate defaults: players+2 eggs and 8 s. Earlier claims win; prototype indistinguishable same-step claims use a seeded equal lottery; timeout assigns remaining eggs without replacement. Losing claimants receive a non-color cue and may choose again.
  - **Acceptance:** Contested claims and simultaneous timeout never duplicate eggs or ownership; selection uses eligible pool only and leaves each player with at most one item.
  - **Evidence:** [P05 test log](evidence/p05/p05_test_run.log), [interactive log](evidence/p05/p05_interactive_run.log), and claim/ retry cue captures in `evidence/p05/`. **Verification result:** PASSED — claims resolve by arrival order, seeded same-tick tie stream and timeout assignment; the final-tick claim is included before assignment.


#### P05-T04

- [x] **Verify resolve simultaneous egg claims and timeouts**
  - **Status:** COMPLETE · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-PUGAD-002](PRD.md#req-pugad-002--resolve-simultaneous-egg-claims-and-timeouts). **Dependencies:** [P05-T03](#p05-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Contested claims and simultaneous timeout never duplicate eggs or ownership; selection uses eligible pool only and leaves each player with at most one item.
  - **Acceptance:** Contested claims and simultaneous timeout never duplicate eggs or ownership; selection uses eligible pool only and leaves each player with at most one item.
  - **Evidence:** [P05 test log](evidence/p05/p05_test_run.log) covers permutations at 2/3/4 seats for seeds 12345, 7 and 991; [interactive log](evidence/p05/p05_interactive_run.log) shows all four identities, a contested claim, retry cues and re-picks. **Verification result:** PASSED — no duplicate owners/items; the user-interface device seats 3/4 were synthetic gamepads.


#### P05-T05

- [x] **Implement placement ghosts, guides and validity feedback**
  - **Status:** COMPLETE · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P05-T04](#p05-t04), [P03-T04](#p03-t04).
  - **Work:** Move/rotate/confirm a visible grid-snapped ghost. Show exact variant, footprint and relevant sweep/lane/effect, protected areas and non-color validity cues. Projectile/rolling guides show first blocker, predicted bounds or full possible envelope if an exact path is unreliable.
  - **Acceptance:** Every allowed orientation and boundary gives the correct ghost and actionable protected-zone/player/bounds/solid-conflict/item-rule reason; no misleading exact trajectory.
  - **Evidence:** [P05 verification](evidence/p05/2026-10-14_p05_verification.md), [rejection reason matrix](evidence/p05/rejection_reason_matrix.md), and reason-labelled 1920×1080 captures `01`–`12_rejection_*.png`. **Verification result:** PASSED — ghosts show identity/footprint, orientation, protected zones, boundary guides and readable text/outline cues.


#### P05-T06

- [x] **Verify preview grid placement with actionable rejection reasons**
  - **Status:** COMPLETE · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P05-T05](#p05-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Every allowed orientation and boundary gives the correct ghost and actionable protected-zone/player/bounds/solid-conflict/item-rule reason; no misleading exact trajectory.
  - **Acceptance:** Every allowed orientation and boundary gives the correct ghost and actionable protected-zone/player/bounds/solid-conflict/item-rule reason; no misleading exact trajectory.
  - **Evidence:** [rejection reason matrix](evidence/p05/rejection_reason_matrix.md) records expected and actual codes and shown copy for all 12 validator cases; captures and [P05 test log](evidence/p05/p05_test_run.log) cover supported/unsupported orientations, bounds, protection and overlap. **Verification result:** PASSED — each capture matched its specific actionable rejection.


#### P05-T07

- [x] **Implement snapshot-based atomic stage edits**
  - **Status:** COMPLETE · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-PLACE-002](PRD.md#req-place-002--commit-placement-and-cleanup-atomically). **Dependencies:** [P05-T06](#p05-t06), [P04-T04](#p04-t04).
  - **Work:** Confirm submits a pending edit against one phase snapshot. At resolution union Walis targets from that snapshot, remove eligible prior construction, validate remaining placements and reject entire conflicting solid sets; commit valid edits together. Never remove same-phase new pieces or protected geometry. Allow solid/trigger intersections only with readable danger regions.
  - **Acceptance:** Permuting callbacks/submission order yields identical committed layout; overlapping cleanup executes once; rejected sets get no partial placement. Unsupported movers reset/remove safely without crushing.
  - **Evidence:** [P05 test log](evidence/p05/p05_test_run.log) and [P05 verification](evidence/p05/2026-10-14_p05_verification.md). **Verification result:** PASSED — callback permutations resolve to the same signature; cleanup is unioned and applied once; conflicting solid edits reject as a complete set; mover safety uses a test-only fixture.


#### P05-T08

- [x] **Verify commit placement and cleanup atomically**
  - **Status:** COMPLETE · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-PLACE-002](PRD.md#req-place-002--commit-placement-and-cleanup-atomically). **Dependencies:** [P05-T07](#p05-t07).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Permuting callbacks/submission order yields identical committed layout; overlapping cleanup executes once; rejected sets get no partial placement. Unsupported movers reset/remove safely without crushing.
  - **Acceptance:** Permuting callbacks/submission order yields identical committed layout; overlapping cleanup executes once; rejected sets get no partial placement. Unsupported movers reset/remove safely without crushing.
  - **Evidence:** all resolver, conflict, unioned-cleanup, once-only removal, protection and test-mover assertions in [P05 test log](evidence/p05/p05_test_run.log). **Verification result:** PASSED — submissions are validated against one phase snapshot, then applied as one stable batch; rejected edit sets add no subset.


#### P05-T09

- [x] **Connect phase transitions, placement timeout and persistence**
  - **Status:** COMPLETE · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-PLACE-003](PRD.md#req-place-003--handle-phase-timing-and-persistent-construction). **Dependencies:** [P05-T08](#p05-t08).
  - **Work:** Approximate Place duration 15 s. Timeout commits the pointer item only if valid, otherwise discards it. Remove Pugad UI/collision from Play, reset items safely, retain construction until cleanup/match reset and retain removal in later rounds.
  - **Acceptance:** Timeout, discard, confirmation and reset cannot create duplicates; repeated rounds retain exact valid construction and do not resurrect removed objects.
  - **Evidence:** [P05 test log](evidence/p05/p05_test_run.log) covers valid-timeout commit, invalid-timeout discard, pause-frozen Pugad/Place timers, Play cleanup/reset and ten-round signature/removal retention. [Interactive log](evidence/p05/p05_interactive_run.log) demonstrates the Pugad→Place→diagnostic Play→results→next Pugad loop twice through the harness. **Verification result:** PASSED — repeated rounds do not duplicate or resurrect construction.


#### P05-T10

- [x] **Verify handle phase timing and persistent construction**
  - **Status:** COMPLETE · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-PLACE-003](PRD.md#req-place-003--handle-phase-timing-and-persistent-construction). **Dependencies:** [P05-T09](#p05-t09).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Timeout, discard, confirmation and reset cannot create duplicates; repeated rounds retain exact valid construction and do not resurrect removed objects.
  - **Acceptance:** Timeout, discard, confirmation and reset cannot create duplicates; repeated rounds retain exact valid construction and do not resurrect removed objects.
  - **Evidence:** [P05 test log](evidence/p05/p05_test_run.log), latest [interactive log](evidence/p05/p05_interactive_run.log), and [10+ round crowded-stage evidence](evidence/p05/crowded_post_round12_48_pieces_1920x1080.png). **Verification result:** PASSED — timeout, pause, Play cleanup, match reset and ten-round persistence/removal cases passed; performance capture reaches 48 pieces after 12 rounds.


#### P05-T11

- [x] **Build minimal lobby, instructional prompts and results shell**
  - **Status:** COMPLETE · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-UI-001](PRD.md#req-ui-001--provide-minimal-join-round-results-and-next-round-flow). **Dependencies:** [P02-T06](#p02-t06).
  - **Work:** Lobby supports 2–4 joined ready seats with fixed markers; fewer than two cannot start. Results shell carries outcome, award-row, suppression/no-score and total fields; P06 will bind actual awards. Prototype result advance is all-ready or 8 s. Provide basic join/move/jump/egg/place hints early.
  - **Acceptance (D3 scope note, 2026-10-14):** New participants can join and identify themselves; the results shell exposes the P06 outcome/award/no-score/total interface without inventing awards; next round consumes held presses and retains construction correctly. P06-T08 remains the gate for actual result explanations.
  - **Evidence:** [P05 interactive log](evidence/p05/p05_interactive_run.log), [UI gallery contract log](evidence/p05/ui_gallery_smoke.log), [lobby capture](evidence/p05/01_lobby_1920x1080.png), [results shell capture](evidence/p05/07_results_shell_1920x1080.png), and [D3 scope note](evidence/p05/2026-10-14_p05_scope_note.md). **Verification result:** PASSED — join/readiness gate, number/shape identity, early prompts, held-edge handling, construction retention and result advance interface are present. P05 carries per-seat outcome/award/no-score/totals fields but displays no invented award computation; the real award explanation remains P06 work per D3.
  - **UI shell note (2026-10-14, IN PROGRESS, no checkbox change):** scene-based placeholder shells for the lobby/results shell (`lobby_screen.tscn`, `round_result_screen.tscn`) exist under `tilaok!/scenes/ui/` and are reviewable in the UI Gallery harness room (SAMPLE data, PLACEHOLDER theme, evidence `docs/evidence/ui-shells/`). Remaining: the P05 match room still uses its own code-built panels; converting them to these scenes, live award data from P06, and final human art/typeface.
  - **Live wiring note (2026-10-14):** the "Remaining" items above are done: the P05 match room no longer builds its own panels (`match_results_panel.gd` and the code-built HUD / egg row are deleted); the scene screens are bound to live data by `MatchScreenPresenter`. No checkbox change (P05-T11 was already checked on its own acceptance).


#### P05-T12

- [x] **Verify provide minimal join, round results and next-round flow**
  - **Status:** COMPLETE · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-UI-001](PRD.md#req-ui-001--provide-minimal-join-round-results-and-next-round-flow). **Dependencies:** [P05-T11](#p05-t11), [P06-T08](#p06-t08).
  - **Work:** Record the procedure, expected and actual result, and review evidence. New participants can join and identify themselves; results explain actual awards; next round consumes held presses and retains construction correctly.
  - **Acceptance:** New participants can join and identify themselves; results explain actual awards; next round consumes held presses and retains construction correctly.
  - **Evidence:** [updated four-seat interactive run](evidence/p05/p05_interactive_run.log), [P05 automated run](evidence/p06/regression_run_p05_tests.txt), [P06 live two-seat results](evidence/p06/run_p06_interactive.txt), [explained results capture](evidence/p06/02_explained_live_results_1920x1080.png), and [P06 verification record](evidence/p06/2026-10-14_p06_verification.md). **Verification result:** PASSED — the 64-check four-seat run completes Pugad→Place→real goal→explained all-finish suppression→all-ready next round twice, preserves construction and consumes held confirmation so it does not claim the next egg. The P05 137-check suite verifies the paused eight-second advance timeout. The 17-check two-seat P06 run verifies live Tapos/Una, the two-player waiver, exact totals, score persistence and actor reset. Synthetic devices/scripted positioning only; physical and human review remain open.

**D3 scope note (2026-10-14):** At that checkpoint P05 accepted the minimal lobby and results shell/interface; actual awards were deferred to P06. P06-T08 has since passed and P05-T12 was rerun against live results and checked. The optional wall hint remains pending the freeze decision. See [dated note](evidence/p05/2026-10-14_p05_scope_note.md) and the completed verification record above.

**P05 checkpoint (2026-10-14): 12/12 checked.** T01–T12 have implementation or verification evidence. P05 phase exit is met for the approved construction-to-next-round scope; full release readiness is not implied.


## P06 — Karera and scoring

**Goal / player-visible result:** A race ends once and its result is understandable.

**Milestone / scope:** First playable and foundational delivery.

**Entry:** P05 construction loop available.

**External task dependencies:** [P05-T10](#p05-t10)

**Owner roles:** Gameplay; person names TBD. **Systems touched:** NEW race controller, outcome ledger, score calculator and results binding.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Race deadlines, terminal ledger and exact scoring cases pass; later hazard integration remains explicit.

**Evidence required:** 2/3/4-player outcome/scoring tables and duplicate-event tests. Test-only hazard/Barya facts are not gameplay integration; those remain future gates.


#### P06-T01

- [x] **Implement Karera objectives and round deadlines**
  - **Status:** COMPLETE · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-RACE-001](PRD.md#req-race-001--resolve-karera-finish-failure-and-deadlines). **Dependencies:** [P05-T10](#p05-t10).
  - **Work:** Race to the flag; death eliminates for this round, return next round. End when all players finish/fail, or at the earlier of the provisional 60 s hard cap and 15 s after first finish. Remaining runners fail at deadline. Finished players are secured against later effects.
  - **Acceptance:** Exercise none/some/all finish, both deadlines, last-frame finish and no live runners; resolve the round once and show the applicable reason.
  - **Evidence:** [P06 verification record](evidence/p06/2026-10-14_p06_verification.md), [live race capture](evidence/p06/01_karera_live_1920x1080.png), and [source](../tilaok!/scripts/match/race_round_controller.gd). **Verification result:** PASSED — real ArenaDefinition goal contact, secure finish, active-simulation 60/15 s deadlines and a single result commit are integrated; no-finish, boundary-step, pause and terminal paths pass. Defaults remain provisional.


#### P06-T02

- [x] **Verify resolve karera finish, failure and deadlines**
  - **Status:** COMPLETE · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-RACE-001](PRD.md#req-race-001--resolve-karera-finish-failure-and-deadlines). **Dependencies:** [P06-T01](#p06-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Exercise none/some/all finish, both deadlines, last-frame finish and no live runners; resolve the round once and show the applicable reason.
  - **Acceptance:** Exercise none/some/all finish, both deadlines, last-frame finish and no live runners; resolve the round once and show the applicable reason.
  - **Evidence:** [97-check P06 log](evidence/p06/regression_run_p06_tests.txt), [17-check live run](evidence/p06/run_p06_interactive.txt), and [captures](evidence/p06/). **Verification result:** PASSED — hard-cap and first-finish deadlines, boundary frames, same-step goal/elimination, pause freeze, none/some/all terminal paths and one-time result were verified with Godot 4.7.2. Inputs are synthetic/scripted; physical-device and human playtesting remain open.


#### P06-T03

- [x] **Implement terminal event ledger and attribution resolver**
  - **Status:** COMPLETE · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-SCORE-001](PRD.md#req-score-001--record-one-terminal-outcome-and-direct-attribution). **Dependencies:** [P06-T02](#p06-t02).
  - **Work:** Each player has one terminal outcome and one award application per round. Earliest recorded hazard contact owns a kill; indistinguishable contacts use stable item ID. Goal versus death uses event time; indistinguishable elimination wins. Self-kill and setup assists earn no Patibong. Event elimination is never trap credit.
  - **Acceptance:** Replay duplicated/reordered callbacks, competing hazards and goal/death ties; one outcome remains and direct ownership is stable. Actual hazard integration is retested when P10 hazards exist.
  - **Evidence:** [P06 verification record](evidence/p06/2026-10-14_p06_verification.md), [ledger](../tilaok!/scripts/match/race_outcome_ledger.gd), and [candidate fixtures](../tilaok!/tests/p06_fixtures.gd). **Verification result:** PASSED — per-step batches are order-independent, deduplicated and stale-round safe; exact ties and direct-owner ambiguity follow the approved policy. Hazard contacts remain test-only pending P10 runtime integration.


#### P06-T04

- [x] **Verify record one terminal outcome and direct attribution**
  - **Status:** COMPLETE · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-SCORE-001](PRD.md#req-score-001--record-one-terminal-outcome-and-direct-attribution). **Dependencies:** [P06-T03](#p06-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Replay duplicated/reordered callbacks, competing hazards and goal/death ties; one outcome remains and direct ownership is stable. Actual hazard integration is retested when P10 hazards exist.
  - **Acceptance:** Replay duplicated/reordered callbacks, competing hazards and goal/death ties; one outcome remains and direct ownership is stable. Actual hazard integration is retested when P10 hazards exist.
  - **Evidence:** [97-check P06 log](evidence/p06/regression_run_p06_tests.txt) and [P06 verification record](evidence/p06/2026-10-14_p06_verification.md). **Verification result:** PASSED — duplicate/reordered/stale events, tied sources, self-hit, direct owner, ambiguous same-step elimination, score idempotency and the real goal trigger all pass. P10 hazard-family integration is still a future gate.


#### P06-T05

- [x] **Implement exact scoring and race award explanations**
  - **Status:** COMPLETE · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-SCORE-002](PRD.md#req-score-002--calculate-race-awards-and-suppression-exactly). **Dependencies:** [P06-T04](#p06-t04).
  - **Work:** Tapos 1.0 per finish; Una +0.25 for earliest finish, all exact indistinguishable first finishers receive it; Bayani +0.5 sole finisher; Patibong +0.25 per directly killed opponent subject to race scoring; Bawi +0.75 if at least 3 points behind leader at round start and finishing. If everyone finishes in a 2/3/4-player Karera, ordinary awards are suppressed but optional Barya still pays its finisher. If nobody finishes, everyone earns zero. Otherwise normal awards apply.
  - **Acceptance:** Table-driven 2/3/4-player cases cover all/none/sole/multiple finishes, exact-first ties, dead trap owner, self kill, underdog snapshot and the all-finish Barya exception; totals are exact and awarded once.
  - **Evidence:** [P06 verification record](evidence/p06/2026-10-14_p06_verification.md), [calculator](../tilaok!/scripts/match/race_score_calculator.gd), [results model](../tilaok!/scripts/match/match_results_view_model.gd), and [explained-results capture](evidence/p06/02_explained_live_results_1920x1080.png). **Verification result:** PASSED — points use integer eighth-units; award, suppression, outcome, delta and total explanations are bound to live results. During P06 implementation, the calculator accepted Barya as a test-only fact; runtime coin gameplay was added later under P19 (see [Barya evidence](evidence/barya/README.md)).
  - **2026-10-15 rule update:** [all-finish Barya correction](evidence/p06/2026-10-15_all_finish_barya_correction.md) covers the current 2–4-player scorer and tutorial text. The older capture shows the superseded two-player waiver and was not recaptured in this correction.


#### P06-T06

- [x] **Verify calculate race awards and suppression exactly**
  - **Status:** COMPLETE · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-SCORE-002](PRD.md#req-score-002--calculate-race-awards-and-suppression-exactly). **Dependencies:** [P06-T05](#p06-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Table-driven 2/3/4-player cases cover all/none/sole/multiple finishes, exact-first ties, dead trap owner, self kill, underdog snapshot and the all-finish Barya exception; totals are exact and awarded once.
  - **Acceptance:** Table-driven 2/3/4-player cases cover all/none/sole/multiple finishes, exact-first ties, dead trap owner, self kill, underdog snapshot and the all-finish Barya exception; totals are exact and awarded once.
  - **Evidence:** [97-check P06 log](evidence/p06/regression_run_p06_tests.txt), [17-check live results run](evidence/p06/run_p06_interactive.txt), and [2/3/4-seat cases](../tilaok!/tests/run_p06_tests.gd). **Verification result:** PASSED — 2/3/4-seat score tables cover suppression, waiver, sole/multiple finishers, exact-first ties, owner/self attribution, Bawi snapshot thresholds, Barya exception and exact totals. Rendered results are 1920×1080; physical devices and human readability review remain open.
  - **2026-10-15 rule update:** [all-finish Barya correction](evidence/p06/2026-10-15_all_finish_barya_correction.md) supersedes the waiver conclusion in the historical evidence above and restores Barya payout under all-finish suppression. Physical devices and human readability remain open.


#### P06-T07

- [x] **Implement exact placement arithmetic and score formatting**
  - **Status:** COMPLETE · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-SCORE-003](PRD.md#req-score-003--store-elimination-placement-ties-without-rounding). **Dependencies:** [P06-T06](#p06-t06).
  - **Work:** Use eighth-point units or equivalent exact rational storage. Current legal non-winning groups include 4-player places 3–4 =0.125, 2–3 =0.375, 2–4 =0.25 and 3-player places 2–3 =0.25. First place is never averaged when all remaining players die: Last Cluck applies. Prototype lower loser allocation follows recorded order then averages exactly tied lower groups.
  - **Acceptance:** Enumerate every legal group and compare exact totals at 10 points and underdog threshold; display eighth fractions or sufficient decimals. No claim that eighths cover arbitrary future scoring tables.
  - **Evidence:** [P06 verification record](evidence/p06/2026-10-14_p06_verification.md), [placement resolver](../tilaok!/scripts/match/placement_score_resolver.gd), and [exact formatter](../tilaok!/scripts/match/score_format.gd). **Verification result:** PASSED — current legal tied groups resolve in exact eighth-point units; Last Cluck awards first place without averaging it across an all-eliminated round.


#### P06-T08

- [x] **Verify store elimination placement ties without rounding**
  - **Status:** COMPLETE · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-SCORE-003](PRD.md#req-score-003--store-elimination-placement-ties-without-rounding). **Dependencies:** [P06-T07](#p06-t07).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Enumerate every legal group and compare exact totals at 10 points and underdog threshold; display eighth fractions or sufficient decimals. No claim that eighths cover arbitrary future scoring tables.
  - **Acceptance:** Enumerate every legal group and compare exact totals at 10 points and underdog threshold; display eighth fractions or sufficient decimals. No claim that eighths cover arbitrary future scoring tables.
  - **Evidence:** [97-check P06 log](evidence/p06/regression_run_p06_tests.txt) and [P06 verification record](evidence/p06/2026-10-14_p06_verification.md). **Verification result:** PASSED — every current legal tied group, latest-elimination/seat-slot Last Cluck, survivor/lower-placement ordering, eighth-unit formatting, score threshold and Bawi threshold compare exactly. No arbitrary future denominator support is claimed.

**P06 checkpoint (2026-10-14): 8/8 checked.** T01–T08 have implementation and automated/live verification evidence. The first Karera slice is now executable and results explain exact race awards. Hazard-family contact integration, coin gameplay, physical devices, independent human review, final UI/art, complete-match orchestration, Lagsanay and sudden death remain separate gates.


## P07 — First playable gate

**Goal / player-visible result:** Demonstrate a truthful build/race slice, then expand device counts.

**Milestone / scope:** First playable and foundational delivery.

**Entry:** P06 scoring and initial instruction available.

**External task dependencies:** [P02-T08](#p02-t08), [P04-T09](#p04-t09), [P04-T10](#p04-t10), [P04-T18](#p04-t18), [P04-T19](#p04-t19), [P05-T12](#p05-t12), [P06-T08](#p06-t08)

**Owner roles:** QA; person names TBD. **Systems touched:** Existing implemented slice; PLAYTEST evidence.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Two two-player loops, ten resets and three rounds each at three/four players documented.

**Evidence required:** Build/profile/device/seed plus captures and novice observations.


#### P07-T01

- [ ] **Run and document the first playable gate**
  - **Status:** IN PROGRESS · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-SLICE-001](PRD.md#req-slice-001--demonstrate-the-first-playable-buildrace-loop). **Dependencies:** [P05-T12](#p05-t12), [P06-T08](#p06-t08), [P04-T09](#p04-t09), [P04-T18](#p04-t18), [P04-T10](#p04-t10), [P04-T19](#p04-t19).
  - **Work:** First slice uses only verified Kaing/Tulay in labeled karera_slice. Two players complete Lobby→Pugad→Place→Karera→results→next round twice; stage persists through ten round resets. Early match ties may show pending sudden-death coverage, never a complete-match claim.
  - **Acceptance:** Record two complete rounds and ten resets with no duplicate placement/score, plus guided first-loop comprehension; missing Lagsanay/sudden death remains explicit.
  - **Evidence:** [P07 route, synthetic checks, and session sheet](evidence/p07/README.md); [automated reset audit](evidence/p07/p07_reset_audit.txt); [1080p captures and performance](evidence/p07/p07_performance.txt). Synthetic checks are engineering evidence only. **Verification result:** IN PROGRESS — two player-driven rounds, novice comprehension, human observations, and ten human-used round transitions have not been recorded; no participant or observer has been supplied.
  - **Playtest kit note (2026-10-14, no checkbox change):** a launchable build that starts at the Title and a one-page facilitator sheet exist ([PLAYTEST.md](PLAYTEST.md) "P07-T01 playtest kit"). **This task stays open: it needs a human session** (two complete rounds, ten resets without duplicate placement / score, guided first-loop comprehension). The default player flow uses the P07 first-playable room, so the pool is exactly Kaing 1×1, Kaing 2×3 and Tulay 4×1 and there is no match end (stated on the sheet); `-- --match-route=lifecycle` plays the same flow on the P09 lifecycle room (match end, sudden death, final result) and is not what the P07-T01 sheet measures.


#### P07-T02

- [ ] **Verify demonstrate the first playable build/race loop**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-SLICE-001](PRD.md#req-slice-001--demonstrate-the-first-playable-buildrace-loop). **Dependencies:** [P07-T01](#p07-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Record two complete rounds and ten resets with no duplicate placement/score, plus guided first-loop comprehension; missing Lagsanay/sudden death remains explicit.
  - **Acceptance:** Record two complete rounds and ten resets with no duplicate placement/score, plus guided first-loop comprehension; missing Lagsanay/sudden death remains explicit.
  - **Evidence:** [P07 evidence index](evidence/p07/README.md). **Verification result:** COULD-NOT-RUN — T01 human-session artifacts and an identified reviewer are unavailable; no independent human review is claimed. Keep full-match, Lagsanay and sudden-death coverage explicitly open.


#### P07-T03

- [ ] **Run multiplayer slice and device-isolation sessions**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-SLICE-002](PRD.md#req-slice-002--extend-slice-coverage-to-three-and-four-players). **Dependencies:** [P07-T02](#p07-t02), [P02-T08](#p02-t08).
  - **Work:** After T02 and P02-T08 pass, run three rounds at three players and three at four players, rotating participants through slots/devices. Exercise simultaneous input, one-seat device ownership, camera separation, placement-preview isolation, pause/focus loss, disconnect/reconnect, reclaim, countdown cancellation and fresh input after resume. Construction-only all-finish zero-score rounds are expected and are not release balance evidence.
  - **Acceptance:** 2/3/4-player device matrix identifies tested, failed and unavailable combinations. No cross-controlled seat or hidden live player; simultaneous input remains isolated; camera and previews remain visible; pause/reclaim preserves state and resumed input is fresh.
  - **Evidence:** [P07 session/device matrix](evidence/p07/README.md). **Verification result:** COULD-NOT-RUN — no gamepads, participant roster, session date or observer were supplied. P02-T08 remains COULD-NOT-RUN; synthetic gamepad identities do not satisfy reconnect/isolation acceptance.


#### P07-T04

- [ ] **Verify extend slice coverage to three and four players**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-SLICE-002](PRD.md#req-slice-002--extend-slice-coverage-to-three-and-four-players). **Dependencies:** [P07-T03](#p07-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Verify round counts, the 2/3/4-player device matrix, simultaneous-input isolation, camera/preview visibility, pause/reclaim state, fresh post-resume input and separate P02-T08 disconnect/reconnect evidence.
  - **Acceptance:** Review T03 evidence for the three three-player and three four-player rounds; tested, failed and unavailable combinations; slot/device rotation; no cross-controlled seat or hidden live player; isolated simultaneous input; visible camera targets/previews; pause/reclaim state preservation; countdown cancellation; and P02-T08 evidence. Unavailable device/session coverage remains COULD-NOT-RUN.
  - **Evidence:** [P07 session/device matrix](evidence/p07/README.md). **Verification result:** COULD-NOT-RUN — T03 player sessions and P02-T08 physical reconnect evidence are unavailable; no reviewer or independent verification record exists.


## P08 — Lagsanay

**Goal / player-visible result:** Independent tag elimination yields one winner.

**Milestone / scope:** Feature-complete submission, then release/submission.

**Entry:** P07 input/loop gates and exact outcome arithmetic available. P06-T08 and P02-T12 are checked. P07-T04 remains unchecked; see the explicit development-only prerequisite disposition below.

**External task dependencies:** [P02-T12](#p02-t12), [P06-T08](#p06-t08), [P07-T04](#p07-t04)

**Owner roles:** Gameplay; person names TBD. **Systems touched:** NEW tag mode and placement/Last Cluck integration.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** P07-T04 player/device/human acceptance remains a formal open gate; development-only enablement does not grant release eligibility. R1–R4 remain inactive. Taya speed stays unchanged. No implicit scope cuts.

**Exit criteria:** Passing, immunity/head start, elimination tables and Last Cluck pass at 2/3/4 players.

**Evidence required:** Independent-mode results; real trap credit verified after hazards exist.

**Entry-gate disposition — October 14, 2026:** The user explicitly authorized P08 development despite the unchecked P07-T04 prerequisite. This is a provisional, development-only dependency override for implementation and technical verification. It does not satisfy, edit, or remove P07-T04's physical/player-session and human-review acceptance. P08's technical tasks may be checked against their own evidence; formal entry/release eligibility remains unresolved until the P07 gate is addressed. P02-T12 and P06-T08 were rechecked as checked foundations. No P07 completion is inferred from synthetic P08 tests.

**P08 engineering roll-up — October 14, 2026: 6/6 technical task records passed.** The standalone `lagsanay_lab` route uses the existing Lobby → Pugad → Place → Lagsanay → explained results → next-round flow and a persistent constructed stage. Focused P08 controller checks passed 86/86; the refreshed 2/3/4-seat rendered interaction run passed 87/87; all 13 required regressions exited 0; import/parse, format, Windows Debug export and exported `--open-room=p08_lagsanay` smoke passed. Actual Trumpo and Tsinelas Launcher attribution was verified. At 1080p with those two hazards, 2/3/4-seat p95/worst frame intervals were 8.997/11.140, 8.526/13.106, and 10.564/13.361 ms; sampled OS process-tree working set/private bytes were 287.84/421.58 MiB. Evidence and limits are indexed in [P08 evidence](evidence/p08/README.md). All input seats are synthetic and no independent human review is claimed. The development profile is not release-enabled. **P08 release/entry gate remains OPEN** because P07-T04 and physical-device/human acceptance are still open. Full-match/event scheduling, stacks, final art/audio, and release onboarding remain later obligations.


#### P08-T01

- [x] **Implement taya lifecycle, head start and tag arbitration**
  - **Status:** COMPLETE · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-LAG-001](PRD.md#req-lag-001--implement-opening-taya-contact-passing-and-countdown). **Dependencies:** [P07-T04](#p07-t04), [P02-T12](#p02-t12).
  - **Work:** Choose random taya; first taya freezes hazard-immune about 3 s before countdown starts. Others disperse from shared spawn. Pass by sensor contact; nearest eligible candidate then lowest slot on exact distance tie. Prototype ongoing overlap checks permit at most one global pass per step, 1 s previous-taya immunity; pass does not reset countdown.
  - **Acceptance:** 2/3/4-player tests include stationary overlap, multiple candidates, immunity expiry, opening hazard contact and no opening tag; recorded countdown never resets on pass.
  - **Implementation:** `tilaok!/scripts/match/lagsanay_round_controller.gd`, `p08_lagsanay_match_room.gd`, `tilaok!/scripts/movement/chicken_contact_sensor.gd`, `chicken_controller.gd`, and validated tuning in `tilaok!/scripts/config/gameplay_tuning.gd`. Gameplay taya selection uses its own seeded stream; cosmetic randomness remains separate. The current overlap set is frozen before each step's arbitration; exact-distance ties use the lowest stable slot. Opening freeze and immunity are applied once per attempt; pass-back immunity and timer never reset on transfer.
  - **Evidence:** [P08 evidence](evidence/p08/README.md), [86-check controller log](evidence/p08/regressions/final/run_p08_tests.log), [2/3/4-player interaction report](evidence/p08/p08_interactive_run.txt). **Procedure / expected / actual:** ran stationary and multiple-contact fixtures plus live physics sensor overlap at 2/3/4 seats, checked pass-back expiration, captured recipient, freed-contact cleanup, opening hazard sweep and no opening tag; all expected assertions passed. **Verification result:** PASSED. **Reviewer:** Codex (implementation author); no independent human reviewer recorded.


#### P08-T02

- [x] **Verify implement opening taya, contact passing and countdown**
  - **Status:** COMPLETE · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-LAG-001](PRD.md#req-lag-001--implement-opening-taya-contact-passing-and-countdown). **Dependencies:** [P08-T01](#p08-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. 2/3/4-player tests include stationary overlap, multiple candidates, immunity expiry, opening hazard contact and no opening tag; recorded countdown never resets on pass.
  - **Acceptance:** 2/3/4-player tests include stationary overlap, multiple candidates, immunity expiry, opening hazard contact and no opening tag; recorded countdown never resets on pass.
  - **Evidence:** [rendered 1920×1080 head-start/pass captures](evidence/p08/README.md#p08-checks), [interactive report](evidence/p08/p08_interactive_run.txt), and [regression summary](evidence/p08/regressions/final/suite_summary.txt). **Procedure / expected / actual:** ran the Godot 4.7.2 rendered runner with 2/3/4 synthetic seats; expected a visible shape/text taya marker and active countdown, frozen and hazard-immune opening taya, actual sensor-based transfer, no transfer during opening, 1-second pass-back exclusion and unchanged countdown; all 87 interactive assertions passed, and captures show the opening and passed state with the pass-back explanation. **Command:** `Godot_v4.7.2-stable_win64_console.exe --path tilaok! --script res://tests/run_p08_interactive.gd`; **exit:** 0. **Verification result:** PASSED for technical acceptance; no physical-device or human-review evidence is claimed. **Reviewer:** Codex engineering run (implementation author).


#### P08-T03

- [x] **Implement elimination placement scoring and taya reassignment**
  - **Status:** COMPLETE · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-LAG-002](PRD.md#req-lag-002--resolve-lagsanay-eliminations-and-placements). **Dependencies:** [P08-T02](#p08-t02), [P06-T08](#p06-t08).
  - **Work:** Timeout eliminates taya; trap death eliminates directly. Reassign random live taya if needed, with prototype timers 15/10/7 s at 4/3/2 alive. Last survivor wins. Placements: 4 players 1/.5/.25/0; 3 players 1/.5/0; 2 players 1/0. Patibong applies to direct hazards, Bawi to an underdog winner. No too-easy/too-hard suppression.
  - **Acceptance:** Timeout/trap/taya death and simultaneous earlier deaths produce one placement set; verify all player-count tables and Bawi/Patibong with direct hazard tests when available.
  - **Implementation:** `lagsanay_round_controller.gd` batches accepted direct hazards and timeout before survivor counting, taya reassignment, placement or tag; `lagsanay_score_calculator.gd` applies integer eighth-point placement, direct Patibong and snapshot Bawi exactly once; `placement_score_resolver.gd` retains P06 tick-only behavior while accepting comparable timestamps. The independent room does not create a race controller. The P08-only hazard sink owns accepted/rejected lethal records, preserving source and owner identity without the race-specific ItemEliminationBridge.
  - **Evidence:** [P08 evidence](evidence/p08/README.md), [focused P08 log](evidence/p08/regressions/final/run_p08_tests.log), [real Trumpo and Launcher integration report/captures](evidence/p08/README.md#p08-checks). **Procedure / expected / actual:** covered timeout vs earlier/equal/un-timed hazard, same-step multi-elimination batches, non-taya death with unchanged taya clock, reassignment timers, all three placement tables, lower-placement ties, owner-dead credit, self-kill rejection, stable competing-source selection, duplicate and stale-round records, and one-time commit; actual Trumpo contact and Launcher projectile reached the independent mode sink with owner/source preserved. **Verification result:** PASSED. **Reviewer:** Codex (implementation author); no independent human reviewer recorded.


#### P08-T04

- [x] **Verify resolve lagsanay eliminations and placements**
  - **Status:** COMPLETE · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-LAG-002](PRD.md#req-lag-002--resolve-lagsanay-eliminations-and-placements). **Dependencies:** [P08-T03](#p08-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Timeout/trap/taya death and simultaneous earlier deaths produce one placement set; verify all player-count tables and Bawi/Patibong with direct hazard tests when available.
  - **Acceptance:** Timeout/trap/taya death and simultaneous earlier deaths produce one placement set; verify all player-count tables and Bawi/Patibong with direct hazard tests when available.
  - **Evidence:** [86-check P08 controller log](evidence/p08/regressions/final/run_p08_tests.log), [2/3/4-player rendered hazard/results report](evidence/p08/p08_interactive_run.txt), [performance and restart report](evidence/p08/p08_performance.txt). **Procedure / expected / actual:** checked the 2/3/4 placement tables, direct trap credit and self-kill exclusion using actual Trumpo and Tsinelas Launcher contacts, timer reassignment, non-taya death behavior, Bawi exactly at and below its 3-point threshold, and duplicate award handling; actual assertions passed with no failure. **Command:** focused headless and rendered P08 runners, both exit 0. **Verification result:** PASSED for technical acceptance; not a human fairness or physical-device playtest. **Reviewer:** Codex engineering run (implementation author).


#### P08-T05

- [x] **Implement Last Cluck resolution and explanation**
  - **Status:** COMPLETE · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-LAG-003](PRD.md#req-lag-003--select-exactly-one-last-cluck-winner). **Dependencies:** [P08-T04](#p08-t04).
  - **Work:** If all remaining chickens are eliminated in the same physics tick, latest recorded elimination time wins; exactly identical time uses lowest player slot. Remaining losers take lower placements, with the provisional exact-tie allocation documented separately. Brief freeze frame and Last Cluck callout explain the result.
  - **Acceptance:** Exercise 2/3/4 all-remaining eliminations, distinguishable times and exact ties; one winner only, no averaged first and no duplicate award; correct explanation appears.
  - **Implementation:** `tilaok!/scripts/match/placement_score_resolver.gd` selects the latest comparable recorded time in the final physics-tick group and the lowest slot for exact or truly indistinguishable time. Legacy tick-only callers remain indistinguishable. Lower placements retain exact recorded-time/tick tie allocation. `match_results_view_model.gd` explains the selected winner/tie rule; a brief pause-style freeze is independent of terminal and score commit.
  - **Evidence:** [P08 evidence](evidence/p08/README.md), [focused P08 log](evidence/p08/regressions/final/run_p08_tests.log), and [Last Cluck rendered results](evidence/p08/06_last_cluck_explained_results_1920x1080.png). Distinguishable values in the final-group fixture are explicitly supplied records; runtime timing precision is limited to the engine/hazard timestamps producers actually record. **Verification result:** PASSED. **Reviewer:** Codex (implementation author); no independent human reviewer recorded.


#### P08-T06

- [x] **Verify select exactly one last cluck winner**
  - **Status:** COMPLETE · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-LAG-003](PRD.md#req-lag-003--select-exactly-one-last-cluck-winner). **Dependencies:** [P08-T05](#p08-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Exercise 2/3/4 all-remaining eliminations, distinguishable times and exact ties; one winner only, no averaged first and no duplicate award; correct explanation appears.
  - **Acceptance:** Exercise 2/3/4 all-remaining eliminations, distinguishable times and exact ties; one winner only, no averaged first and no duplicate award; correct explanation appears.
  - **Evidence:** [focused P08 log](evidence/p08/regressions/final/run_p08_tests.log), [interactive report](evidence/p08/p08_interactive_run.txt), and [explained Last Cluck capture](evidence/p08/06_last_cluck_explained_results_1920x1080.png). **Procedure / expected / actual:** tested 2/3/4 all-eliminated rounds, original participants and smaller final groups, supplied distinguishable records, exact ties, tick-only compatibility, lower-place averages, reversed callback permutations, duplicate callbacks, one winner, no averaged first, one final award and visible explanation; all 86 focused and 87 interactive assertions passed. No callback order is used as timing evidence. **Command:** P08 headless and rendered runners, exit 0. **Verification result:** PASSED for technical acceptance; supplied timestamps are test fixtures, not engine-derived sub-frame measurements. **Reviewer:** Codex engineering run (implementation author).


## P09 — Complete match lifecycle

**Phase roll-up (October 14, 2026):** ✅ P09-T01–T04 pass technical implementation/verification acceptance (4/4). The P09 development route, 77 focused checks, 108 rendered interactive assertions and ten finish-to-restart cycles are indexed in [P09 evidence](evidence/p09/README.md). The latest 1080p warmed p95 frame interval was 27.78 ms, above the 16.67 ms target; see P15 follow-up. Synthetic seats/finish fixtures, no P09 physical-device/human review, and the Last Cluck hazard-fixture boundary are explicit in the evidence. P07/P08 release gates remain open; this does not implement P12 scheduling/stacks or close release requirements.

**Goal / player-visible result:** A match and tied-player sudden death finish and restart cleanly.

**Milestone / scope:** Feature-complete submission, then release/submission.

**Entry:** P08 independent Lagsanay passes.

**External task dependencies:** [P08-T06](#p08-t06)

**Owner roles:** Gameplay; person names TBD. **Systems touched:** NEW match coordinator and replay/lobby teardown.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Threshold/round-12/tie paths and ten match restarts pass; release schedule verified later in P12.

**Evidence required:** Full-match, sudden-death and restart logs/captures.


#### P09-T01

- [x] **Implement match termination and sudden-death routing**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-MATCH-001](PRD.md#req-match-001--finish-matches-and-run-tied-player-sudden-death). **Dependencies:** [P08-T06](#p08-t06).
  - **Work:** Check totals at round end: first to 10 or highest after round 12. Multiple above 10 are ordered by total; equal leaders enter Lagsanay only among tied players, no Twist, producing exactly one winner. Full match release retains guaranteed event schedule; development override is not release behavior.
  - **Acceptance:** Verify threshold, round-12, unequal simultaneous threshold crossings and 2/3/4 tied-player sudden death; exactly one match winner and no extra score table.
  - **Evidence:** `tilaok!/scripts/match/match_lifecycle_coordinator.gd`, `p09_match_lifecycle_room.gd`, P09 scene/harness route, and [77 focused checks](evidence/p09/p09_focused_tests.txt). **Procedure / expected / actual:** exercised exact integer eighth-point termination, unique/unequal leaders, ties, end-of-round ordering, stale/duplicate callback guards and the 2/3/4-seat Lagsanay controller; expected one unique match winner or only the tied top-seat subset entering Lagsanay, actual all focused cases passed and the four-seat noncontiguous subset `[1,3]` excludes spectators. The route keeps the P07 three-variant allowlist and does not enable release behavior. **Verification result:** PASSED for implementation; see P09-T02 for integration. **Reviewer:** Codex engineering run, author; no independent human review recorded.


#### P09-T02

- [x] **Verify finish matches and run tied-player sudden death**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-MATCH-001](PRD.md#req-match-001--finish-matches-and-run-tied-player-sudden-death). **Dependencies:** [P09-T01](#p09-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Verify threshold, round-12, unequal simultaneous threshold crossings and 2/3/4 tied-player sudden death; exactly one match winner and no extra score table.
  - **Acceptance:** Verify threshold, round-12, unequal simultaneous threshold crossings and 2/3/4 tied-player sudden death; exactly one match winner and no extra score table.
  - **Evidence:** [108-assertion rendered run](evidence/p09/p09_interactive_run.txt), [77 focused checks](evidence/p09/p09_focused_tests.txt), and rendered [threshold](evidence/p09/01_score_target_final_results_1920x1080.png), [four-player sudden-death entry](evidence/p09/03_all_finish_round_limit_sudden_death_1920x1080.png), [tied-player contact](evidence/p09/03b_tied_player_contact_1920x1080.png), [Last Cluck result](evidence/p09/06_final_noncontiguous_sudden_death_results_1920x1080.png). **Procedure / expected / actual:** used real coordinator/scorer/round transitions with synthetic goal-event candidates and short timers; six sole-finisher rounds committed 84 eighth-units and ended at the 80-unit target, while four-player all-finish suppression completed round 12 and entered sudden death without round 13. A labeled preloaded 40/40 fixture routed only original seats P2/P4 from a four-player roster; real physics contact transferred taya, and placement awards did not modify match totals. Focused controller timeout tests resolved 2/3/4 contestants. Last Cluck hazards were synthetic because the P07 allowlist has no hazard items. **Verification result:** PASSED for automated engineering acceptance. No human/device acceptance is claimed. **Reviewer:** Codex engineering run, implementation author.


#### P09-T03

- [x] **Implement match results, replay and complete teardown**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-MATCH-002](PRD.md#req-match-002--replay-return-to-lobby-and-reset-all-match-state). **Dependencies:** [P09-T02](#p09-t02).
  - **Work:** Match results show final scores/winner with replay and lobby choices. Prototype menu owner selects action and all players freshly ready. Leaving mid-match confirms whole-group return to lobby, never silently changes scoring player count. New match clears construction, scores, captures, transients, event state and ready edges.
  - **Acceptance:** Ten complete restarts show no retained score/timer/immunity/capture or object growth; replay/lobby/quit routes work after ordinary and sudden-death endings.
  - **Evidence:** live `MatchResultsViewModel.final_match` binding and shared themed screen in `match_results_view_model.gd`, `ui_match_result_screen.gd`, and `match_result_screen.tscn`; [interactive results/menu assertions](evidence/p09/p09_interactive_run.txt); [score-target result](evidence/p09/01_score_target_final_results_1920x1080.png), [Replay](evidence/p09/02_replay_fresh_match_1920x1080.png), [Last Cluck result](evidence/p09/06_final_noncontiguous_sudden_death_results_1920x1080.png), and [Lobby](evidence/p09/07_return_to_lobby_1920x1080.png). **Procedure / expected / actual:** checked exact scores for every original participant, one winner, Last Cluck explanation, Replay seed/config/device retention, unanimous fresh readiness, action clearing on focus/device events, shared Quit/leave confirmation and cancel, and full-group Lobby return; all passed. SAMPLE gallery data stays on its sample binding path. **Verification result:** PASSED for implementation and synthetic UI flow. **Reviewer:** Codex engineering run, author; no human readability or device review claimed.


#### P09-T04

- [x] **Verify replay, return to lobby and reset all match state**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-MATCH-002](PRD.md#req-match-002--replay-return-to-lobby-and-reset-all-match-state). **Dependencies:** [P09-T03](#p09-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Ten complete restarts show no retained score/timer/immunity/capture or object growth; replay/lobby/quit routes work after ordinary and sudden-death endings.
  - **Acceptance:** Ten complete restarts show no retained score/timer/immunity/capture or object growth; replay/lobby/quit routes work after ordinary and sudden-death endings.
  - **Evidence:** [ten-cycle audit JSON](evidence/p09/p09_restart_audit.json), [process-memory sample](evidence/p09/p09_process_memory.txt), and [evidence index](evidence/p09/README.md). **Procedure / expected / actual:** ten complete ordinary/sudden-death matches restarted through Replay (6) or Lobby (4), with construction, scores, actors, captures, transients, pending claims, Lagsanay timer/immunity, readiness, callback identity, object count and memory recorded before/after; all ten passed their lifecycle assertions. After cycle 3's warmed baseline, object count varied from −5 to +1 and Godot static memory from −97,572 to +249,784 bytes, with no continuing upward trend. External process-tree peaks were 292.3 MiB working set and 426.7 MiB private bytes, under 512 MiB. Warmed frame p95 was 27.78 ms and worst 55.60 ms (overall run worst 144.38 ms), so the 16.67 ms target remains open for P15. Quit/leave confirmation paths and cancel were covered in the interactive runner. **Verification result:** PASSED for P09 restart/reset acceptance; performance target, human-used restart ledger and human/device acceptance remain open. **Reviewer:** Codex engineering run; no independent review recorded.


## P10 — Remaining initial items

**Goal / player-visible result:** Add the six individually verified families after construction seeds.

**Milestone / scope:** Feature-complete submission, then release/submission.

**Entry:** Gulong starts after P04 core gates; advanced compatibility awaits relevant modes.

**External task dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18), [P05-T02](#p05-t02), [P05-T06](#p05-t06), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10), [P13-T06](#p13-t06)

**Owner roles:** Gameplay + Art/UI; person names TBD. **Systems touched:** NEW spring, rail trumpo, Parol, launcher, Walis and bubble scenes/data.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** All six families and applicable variants pass their final enablement gates; Bula core starts last.

**Evidence required:** Per-item harness and integration records, registered assets and Library entries.

**Phase roll-up (2026-10-14): 42/54 task records passed; P10 is NOT complete and its exit criteria are NOT MET.** Passed: the Define, Build, Mechanic, Ownership/cleanup, Verify-core, Egg+ghost and Library records of all six families (T01–T06, T08, T10–T15, T17, T19–T24, T26, T28–T33, T35, T37–T42, T44, T46–T51, T53), on **placeholder** art/audio and synthetic input, in the development `items_lab` profile with nothing release-enabled. Blocked and unchecked (12): the six Integrate records T07/T16/T25/T34/T43/T52 (need P08-T06 Lagsanay, P11-T12 Kangaroo, P12-T04 pairing) and the six release-enablement records T09/T18/T27/T36/T45/T54 (need those plus P13-T06 and P12-T06/T08/T10). Bula's core started last, after T05/T14/T23/T32/T41 were checked. Evidence is indexed in the [P10 verification index](evidence/p10/2026-10-14_p10_verification.md). Final art and audio, the P13 Library shell, native-speaker name review and human feel/balance review remain open follow-ups. **Update (2026-10-16): 48/54.** The six Integrate records T07/T16/T25/T34/T43/T52 passed ([integration evidence](evidence/integration/README.md)); the six families are in the real match pool, dealt only in their approved modes. The six release-enablement records remain open (final art, `PlaceholderAudit`, owner `release_target` decision).


### Gulong Talon — `move.tire_spring`


#### P10-T01

- [x] **Define Gulong Talon configuration and variants**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Author the family definition from the catalog; expose tuning keys and keep precision/effect regions distinct.
  - **Acceptance:** Definition lists Single 2×2 default; transformed launch normal at 0/90/180/270 degrees. Regions, rotations, safe start, owner and mode flags are explicit.
  - **Evidence:** `tilaok!/data/items/move.tire_spring.tres`, `scripts/items/runtime/spring_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Load all definitions through `ItemDefinitions.load_for_profile(tuning, "items_lab")`, validate, then mutate copies. Expected: one variant `tire_2x2` (2×2), rotations 0/1/2/3, explicit SOLID 2×2 body and TRIGGER 2×1 launch face, safe start `reset_ready`, placer owner, karera allowed with lagsanay/kangaroo pending review, wall ineligible, wave-support role none; an undocumented, mismatched, regionless or bad-safe-start definition is rejected. Actual: all T01 rows passed, including the rejection rows. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T02

- [x] **Build Gulong Talon scene and collision regions**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon). **Dependencies:** [P10-T01](#p10-t01).
  - **Work:** Create original scene/solid/sensor regions and visible bounds; verify the family-specific placement and rotation contract.
  - **Acceptance:** 2×2 logical footprint proposal; top is launch trigger, body is solid support. Rotation 0/90/180/270; direction follows the transformed launch normal. Force, jump bonus, footprint, cooldown, and grace are tunables.
  - **Evidence:** `tilaok!/data/items/move.tire_spring.tres`, `scripts/items/runtime/spring_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Gulong sheet](evidence/p10/gulong_sheet_variants_rotations_1920x1080.png). **Procedure / expected / actual:** Place a Gulong at every rotation and read its resolved regions. Expected: 64×64 solid body; launch face on the transformed normal edge. Actual: trigger rects (0,0,64,32), (32,0,32,64), (0,32,64,32), (0,0,32,64) for rotations 0/1/2/3, each on the edge named by its normal; one 64×64 collision shape. Tunables are `GameplayTuning` `item_spring_*` (launch 775, boost 849, boost window 0.10 s, cooldown 0.20 s, caps 480/900), validated. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T03

- [x] **Implement Gulong Talon mechanic and feedback**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon). **Dependencies:** [P10-T02](#p10-t02).
  - **Work:** Implement the family behavior, tell and counterplay without copying reference code/art; use centralized timing/force settings.
  - **Acceptance:** Contact bounce launches a chicken; timed jump input boosts height. It creates a useful shortcut but can throw players into hazards. Tell: visible compression/coil and bounce arc cue. Counter: approach slowly, decline the boost, or time the jump. Spring is verified community-wiki reference pattern; tire/playful presentation and tuning are original.
  - **Evidence:** `tilaok!/data/items/move.tire_spring.tres`, `scripts/items/runtime/spring_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Gulong sheet](evidence/p10/gulong_sheet_variants_rotations_1920x1080.png). **Procedure / expected / actual:** Drop a chicken onto the face with and without a timed jump press; hold it on the face; launch sideways; launch under a ceiling. Expected: plain rise near 775²/(2·1875) ≈ 160 wu, boosted near 192 wu, one launch per 0.20 s, horizontal cap 480 wu/s, never outside the arena. Actual: plain rise 168.2 wu, boosted 200.8 wu (a fixed 60-Hz step adds about half a step of velocity over the continuous estimate); 1 launch in the first 10 frames and 4 by frame 40; side launch measured 480.0 wu/s; minimum centre y 24.00 under the ceiling with no bounds event. Tell: coil compression plus a launch-normal arrow; counter: approach slowly, decline the boost or time the jump. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T04

- [x] **Implement Gulong Talon ownership and cleanup**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon). **Dependencies:** [P10-T03](#p10-t03).
  - **Work:** Preserve direct-source ownership/no-assist rules; implement inactive Place, deterministic Play reset, persistent removal and reference/transient teardown.
  - **Acceptance:** Race and Lagsanay; Lagsanay force must not bypass solid-floor containment. Placer owns trap attribution only if the spring impact itself eliminates; otherwise no assist credit. Resets force/cooldown at Play. Needs original tire animation/audio and movement-state interface. Medium-high risk: player launch state and ceiling/bounds safety.
  - **Evidence:** `tilaok!/data/items/move.tire_spring.tres`, `scripts/items/runtime/spring_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Place with seat 1 as owner, run Play, remove and reset. Expected: the launch is a setup record with no credit and no assist; inert in Place and for the 1.0 s grace; deterministic reset; removal invalidates support the same step. Actual: `SETUP|…|owner1|setup=true`, `credit_eligible()` false, no elimination record; face reports `ineligible surface` for wave support; ten reset cycles kept the node count identical (168 → 168). **Recorded follow-up, not a gate (owner decision 2026-10-13 on P04, applied to P10 by approved Stage A decision D1):** the original tire art and launch sound are made by the human team (Jorge/Ivie art, Shanti audio). Every placeholder file is `PLACEHOLDER_*`, registered in [ASSETS.md](ASSETS.md) and flagged by the release gate (`PlaceholderAudit`); replacing the file or the `ItemVisualSet` slot needs no code change ([file-level swap probe](evidence/p10/swap_file_level_probe.txt)). **Verification result:** PASSED for the code acceptance. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T05

- [x] **Verify Gulong Talon core behavior in its harness**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon). **Dependencies:** [P10-T04](#p10-t04).
  - **Work:** Run isolated collision/behavior/reset cases before exposing the family to a selectable pool; this is not the later event-compatibility gate.
  - **Acceptance:** Check all configured variants, rotations, collider boundaries, tell/counterplay, deterministic reset and removal. Capture actual results and known limits.
  - **Evidence:** `tilaok!/data/items/move.tire_spring.tres`, `scripts/items/runtime/spring_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Procedure details and the full expected/actual matrix: [P10 verification index](evidence/p10/2026-10-14_p10_verification.md). **Procedure / expected / actual:** Run every rotation boundary, plain/boosted/cooldown/cap/ceiling cases, support, ownership and reset rows in `run_p10_tests.gd`. Expected/actual rows are in the log and the verification index. **Known limits:** the conditional "separate safe eligible face" support row is not implemented (the whole body is declared support-ineligible, fail closed); no human feel review; synthetic input only. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T06

- [x] **Add Gulong Talon egg animation and placement ghost**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon), [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews), [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P10-T05](#p10-t05), [P05-T02](#p05-t02), [P05-T06](#p05-t06).
  - **Work:** Produce/register original visual preview assets; reuse shared preview infrastructure and preserve claimed variant identity.
  - **Acceptance:** Preview/ghost show Single 2×2 default; transformed launch normal at 0/90/180/270 degrees. Include relevant sweep/lane/effect and non-color validity; no Pugad names/descriptions.
  - **Evidence:** `tilaok!/data/items/move.tire_spring.tres`, `scripts/items/runtime/spring_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Gulong sheet](evidence/p10/gulong_sheet_variants_rotations_1920x1080.png); [P10 interactive](evidence/p10/suite_run_p10_interactive.log) (56 checks, 0 failures). **Procedure / expected / actual:** Configure an egg preview and a placement ghost for `tire_2x2` at all four rotations. Expected: exact 2×2 shape with the launch face, a looping animation, no text on the egg, non-colour validity cues. Actual: eggs draw the tire with its arrow and loop (phase differs at 0 s vs 1 s); ghosts carry the solid hatch, a double-outline trigger with a normal arrow and the existing OK/X mark, dashed outline and reason text for invalid cells. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T07

- [x] **Integrate Gulong Talon with events and scoring**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon). **Dependencies:** [P10-T05](#p10-t05), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04).
  - **Work:** Apply catalog mode restrictions; unsafe capture/force chains block pairing enablement. Walis is construction-only, never a Play hazard.
  - **Acceptance:** Document enabled modes and support eligibility; verify direct credit/no credit and family-specific hazards or forces in independent modes and supported stacks.
  - **Evidence:** [integration evidence](evidence/integration/README.md) (`tests/run_item_mode_integration_tests.gd`, 83 checks, 0 failures) and the mode filter in `scripts/match/pugad_egg_pool_generator.gd` / `P12ScheduledMatchRoom.pugad_mode_ids`. **Procedure / expected / actual:** deal 1500 seeded eggs and the real room's Pugad for each of the six round types, then place the real piece through the Place resolver and run real physics with a held victim. Expected and actual: Gulong is dealt in Karera rounds only (Lagsanay/Kangaroo pending review); a placed Gulong launches a chicken (one launch, about 309 wu rise) with no elimination or credit in all six round types, so no unsafe force chain enters a stack's credit. Enabled modes and support eligibility are documented in [ITEMS](ITEMS.md#event-and-stack-integration--2026-10-16). **Result:** PASSED (synthetic). **Build:** Godot 4.7.stable.official.5b4e0cb0f, Windows 11, scheduled P12 match room (default arena), 3–4 synthetic seats (K1/K2 plus synthetic gamepad IDs), seeded, 60 Hz (`--fixed-fps 60`), working tree on `fec0d3f`, 2026-10-16, reviewer: Claude (AI, automated; no human reviewer). Earlier history: blocked until P08-T06, P11-T12 and P12-T04 passed.


#### P10-T08

- [x] **Write and animate the Gulong Talon Library entry**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon), [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P10-T06](#p10-t06).
  - **Work:** Author entry data/assets against the shared Library schema; integration is checked when the Library shell is available.
  - **Acceptance:** Entry includes name, looping animation, sizes, placement, tell/counterplay, controls and permitted modes; release filter exposes only enabled content.
  - **Evidence:** `item_library_entry.gd`, the Library panel/release filter in the Item Visualizer, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Build the Library entry from the definition. Expected/actual: working name flagged "(working name)", size 2×2, placement text, tell, counterplay, controls, modes (karera allowed, lagsanay/kangaroo pending review), looping animation key, region summary and its PLACEHOLDER slots; the release filter lists nothing because no family is release-enabled. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T09

- [ ] **Verify Gulong Talon release enablement**
  - **Status:** BLOCKED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon). **Dependencies:** [P10-T07](#p10-t07), [P10-T08](#p10-t08), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Test harness plus 2/3/4-player integration, exact preview/ghost, Library, bounds, source credit, support and ten lifecycle resets. Register artifacts and unresolved defects before enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available. **Blocked by:** the family's integration task, [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08) and [P12-T10](#p12-t10). **Next action:** run the 2/3/4-player integration, exact preview/ghost, Library and ten-reset checks, replace placeholders (`PlaceholderAudit`), then decide `release_target` (currently false). **2026-10-16:** the family's integration task passed ([integration evidence](evidence/integration/README.md)) and it is in the match pool. Still open: the 2/3/4-player, preview/ghost, Library and ten-reset release run on final art, `PlaceholderAudit` replacement and the owner's `release_target` decision.


### Trumpo sa Riles — `hazard.rail_trumpo`


#### P10-T10

- [x] **Define Trumpo sa Riles configuration and variants**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Author the family definition from the catalog; expose tuning keys and keep precision/effect regions distinct.
  - **Acceptance:** Definition lists 4×1, 5×1, 6×1 rails; sweep matches visible length. Regions, rotations, safe start, owner and mode flags are explicit.
  - **Evidence:** `tilaok!/data/items/hazard.rail_trumpo.tres`, `scripts/items/runtime/trumpo_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Validate the family and mutate copies. Expected: `rail_4x1`, `rail_5x1`, `rail_6x1`, rotations 0–3, a bounded SWEEP equal to the rail, no collision region required, safe start `reset_to_endpoint`, placer owner, karera allowed/lagsanay pending, wall ineligible. Actual: all T10 rows passed; a rail whose footprint disagrees with the approved table is rejected. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T11

- [x] **Build Trumpo sa Riles scene and collision regions**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles). **Dependencies:** [P10-T10](#p10-t10).
  - **Work:** Create original scene/solid/sensor regions and visible bounds; verify the family-specific placement and rotation contract.
  - **Acceptance:** Place a bounded rail segment; footprint is anchor/rail; sweep is separate and shown in preview. Rotate in 90° increments, with deterministic start direction. Speed, pause, rail length, hitbox width, grace are tunables. No off-camera or unbounded path.
  - **Evidence:** `tilaok!/data/items/hazard.rail_trumpo.tres`, `scripts/items/runtime/trumpo_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Trumpo sheet](evidence/p10/trumpo_sheet_variants_rotations_1920x1080.png). **Procedure / expected / actual:** Resolve the sweep for all 12 variant/rotation pairs. Expected: sweep size equals the visible rail. Actual: 12/12 equal; start direction RIGHT/DOWN/LEFT/UP for rotations 0/1/2/3. Tunables: `item_trumpo_speed_wu_s` 160, `item_trumpo_pause_s` 0.75, `item_trumpo_hit_wu` 20, activation grace 1.0 s; no unbounded or off-camera path (placement validates the sweep against the arena). **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T12

- [x] **Implement Trumpo sa Riles mechanic and feedback**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles). **Dependencies:** [P10-T11](#p10-t11).
  - **Work:** Implement the family behavior, tell and counterplay without copying reference code/art; use centralized timing/force settings.
  - **Acceptance:** A playful spinning top travels along a short visible rail, pauses at ends, and eliminates on contact. Safe gaps/endpoint pauses allow timing. Tell: rail, rotation, endpoint pause and audio cue. Counter: cross during pause/gap or route above/below. Verified inspiration: Linear Saw’s back-and-forth path; original trumpo, safe timing, and tuning.
  - **Evidence:** `tilaok!/data/items/hazard.rail_trumpo.tres`, `scripts/items/runtime/trumpo_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Trumpo sheet](evidence/p10/trumpo_sheet_variants_rotations_1920x1080.png). **Procedure / expected / actual:** Run a 5×1 rail for one period; stand in its path; run a 6×1 rail at 2400 wu/s. Expected: the top spans exactly the rail, pauses at both ends, eliminates on contact and cannot tunnel. Actual: centre x spans 458.0–598.0 (rail 448–608 minus the 20 wu top), endpoint pause 45 frames (0.75 s), period 3.25 s, contact eliminated in the first pass; at 40 wu per frame the swept test still hit a 24 wu body. Tell: rail, spin, pause marker and tick; counter: cross during the pause or route around. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T13

- [x] **Implement Trumpo sa Riles ownership and cleanup**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles). **Dependencies:** [P10-T12](#p10-t12).
  - **Work:** Preserve direct-source ownership/no-assist rules; implement inactive Place, deterministic Play reset, persistent removal and reference/transient teardown.
  - **Acceptance:** Race and event terrain; Lagsanay enabled only after playtest. Owner gets Patibong only for direct contact elimination. Resets to start endpoint and deterministic direction each Play; cleanup releases mover. Needs original top/rail animations, sound, and mover lifecycle. Medium-high risk: collision ordering and sweeps.
  - **Evidence:** `tilaok!/data/items/hazard.rail_trumpo.tres`, `scripts/items/runtime/trumpo_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Kill a seat from another owner's rail and from its own rail; reset; remove. Expected: direct contact credits the placer only; self-kill no credit; deterministic start endpoint and direction each Play; removal releases the mover. Actual: `ELIM|…|owner1|self=false` is credit-eligible, own-rail `self_kill=true` is not; reset returns the top to the start endpoint; ten cycles keep counts stable. **Recorded follow-up, not a gate (owner decision 2026-10-13 on P04, applied to P10 by approved Stage A decision D1):** the original top and rail art and the endpoint tick are made by the human team (Jorge/Ivie art, Shanti audio). Every placeholder file is `PLACEHOLDER_*`, registered in [ASSETS.md](ASSETS.md) and flagged by the release gate (`PlaceholderAudit`); replacing the file or the `ItemVisualSet` slot needs no code change ([file-level swap probe](evidence/p10/swap_file_level_probe.txt)). **Verification result:** PASSED for the code acceptance. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T14

- [x] **Verify Trumpo sa Riles core behavior in its harness**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles). **Dependencies:** [P10-T13](#p10-t13).
  - **Work:** Run isolated collision/behavior/reset cases before exposing the family to a selectable pool; this is not the later event-compatibility gate.
  - **Acceptance:** Check all configured variants, rotations, collider boundaries, tell/counterplay, deterministic reset and removal. Capture actual results and known limits.
  - **Evidence:** `tilaok!/data/items/hazard.rail_trumpo.tres`, `scripts/items/runtime/trumpo_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Procedure details and the full expected/actual matrix: [P10 verification index](evidence/p10/2026-10-14_p10_verification.md). **Procedure / expected / actual:** Boundary, pause, period, extent, rotation, tunnelling, attribution, same-step ordering and reset rows in `run_p10_tests.gd`. **Known limits:** Lagsanay and balance are untested (pending review); no human feel review; no pursuit/aim logic exists to verify. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T15

- [x] **Add Trumpo sa Riles egg animation and placement ghost**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles), [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews), [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P10-T14](#p10-t14), [P05-T02](#p05-t02), [P05-T06](#p05-t06).
  - **Work:** Produce/register original visual preview assets; reuse shared preview infrastructure and preserve claimed variant identity.
  - **Acceptance:** Preview/ghost show 4×1, 5×1, 6×1 rails; sweep matches visible length. Include relevant sweep/lane/effect and non-color validity; no Pugad names/descriptions.
  - **Evidence:** `tilaok!/data/items/hazard.rail_trumpo.tres`, `scripts/items/runtime/trumpo_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Trumpo sheet](evidence/p10/trumpo_sheet_variants_rotations_1920x1080.png); [P10 interactive](evidence/p10/suite_run_p10_interactive.log) (56 checks, 0 failures). **Procedure / expected / actual:** Egg and ghost for all 12 variant/rotation pairs. Expected: exact rail length and orientation, sweep outline, a moving top that loops. Actual: egg previews animate the top along the exact length; ghosts show a dashed sweep with a centre line and the start position per rotation ([sheet](evidence/p10/trumpo_sheet_variants_rotations_1920x1080.png)). **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T16

- [x] **Integrate Trumpo sa Riles with events and scoring**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles). **Dependencies:** [P10-T14](#p10-t14), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04).
  - **Work:** Apply catalog mode restrictions; unsafe capture/force chains block pairing enablement. Walis is construction-only, never a Play hazard.
  - **Acceptance:** Document enabled modes and support eligibility; verify direct credit/no credit and family-specific hazards or forces in independent modes and supported stacks.
  - **Evidence:** [integration evidence](evidence/integration/README.md) (`tests/run_item_mode_integration_tests.gd`, 83 checks, 0 failures) and the mode filter in `scripts/match/pugad_egg_pool_generator.gd` / `P12ScheduledMatchRoom.pugad_mode_ids`. **Procedure / expected / actual:** deal 1500 seeded eggs and the real room's Pugad for each of the six round types, then place the real piece through the Place resolver and run real physics with a held victim. Expected and actual: Trumpo is dealt in every round type; a direct Trumpo kill eliminates and credits its placer (`direct_hazard`, `direct_owner_seat` = placer) in all six round types through the Karera ledger, the Lagsanay controller and the Kangaroo controller. Enabled modes and support eligibility are documented in [ITEMS](ITEMS.md#event-and-stack-integration--2026-10-16). **Result:** PASSED (synthetic). **Build:** Godot 4.7.stable.official.5b4e0cb0f, Windows 11, scheduled P12 match room (default arena), 3–4 synthetic seats (K1/K2 plus synthetic gamepad IDs), seeded, 60 Hz (`--fixed-fps 60`), working tree on `fec0d3f`, 2026-10-16, reviewer: Claude (AI, automated; no human reviewer). Earlier history: blocked until P08-T06, P11-T12 and P12-T04 passed.


#### P10-T17

- [x] **Write and animate the Trumpo sa Riles Library entry**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles), [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P10-T15](#p10-t15).
  - **Work:** Author entry data/assets against the shared Library schema; integration is checked when the Library shell is available.
  - **Acceptance:** Entry includes name, looping animation, sizes, placement, tell/counterplay, controls and permitted modes; release filter exposes only enabled content.
  - **Evidence:** `item_library_entry.gd`, the Library panel/release filter in the Item Visualizer, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Library entry fields as for Gulong. Actual: sizes 4×1, 5×1, 6×1, tell/counterplay from the definition, karera allowed / lagsanay and kangaroo pending review, looping animation, PLACEHOLDER slots listed; release filter empty. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T18

- [ ] **Verify Trumpo sa Riles release enablement**
  - **Status:** BLOCKED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles). **Dependencies:** [P10-T16](#p10-t16), [P10-T17](#p10-t17), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Test harness plus 2/3/4-player integration, exact preview/ghost, Library, bounds, source credit, support and ten lifecycle resets. Register artifacts and unresolved defects before enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available. **Blocked by:** the family's integration task, [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08) and [P12-T10](#p12-t10). **Next action:** run the 2/3/4-player integration, exact preview/ghost, Library and ten-reset checks, replace placeholders (`PlaceholderAudit`), then decide `release_target` (currently false). **2026-10-16:** the family's integration task passed ([integration evidence](evidence/integration/README.md)) and it is in the match pool. Still open: the 2/3/4-player, preview/ghost, Library and ten-reset release run on final art, `PlaceholderAudit` replacement and the owner's `release_target` decision.


### Parol Pulse — `hazard.parol_pulse`


#### P10-T19

- [x] **Define Parol Pulse configuration and variants**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Author the family definition from the catalog; expose tuning keys and keep precision/effect regions distinct.
  - **Acceptance:** Definition lists 3–6 cell fixture span; both fixtures and entire beam previewed. Regions, rotations, safe start, owner and mode flags are explicit.
  - **Evidence:** `tilaok!/data/items/hazard.parol_pulse.tres`, `scripts/items/runtime/parol_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Validate and mutate. Expected: `span_3x1`–`span_6x1` (span = total cells including both posts, approved decision D7; beam = span − 2 cells), rotations 0/1 only, two reserved post cells, bounded blockable EFFECT beam, safe start `reset_inactive_charge`. Actual: all T19 rows passed; a span-7 definition and occupied cells outside the footprint are rejected. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T20

- [x] **Build Parol Pulse scene and collision regions**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse). **Dependencies:** [P10-T19](#p10-t19).
  - **Work:** Create original scene/solid/sensor regions and visible bounds; verify the family-specific placement and rotation contract.
  - **Acceptance:** Two endpoint anchors define span and collision width; endpoints/beam shown in preview. Horizontal/vertical orientation only. Default proposal: solids block the beam; define and show occlusion. Cycle, charge time (inside inactive 1.5s), width, range and grace are tunables.
  - **Evidence:** `tilaok!/data/items/hazard.parol_pulse.tres`, `scripts/items/runtime/parol_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Parol sheet](evidence/p10/parol_sheet_variants_rotations_1920x1080.png). **Procedure / expected / actual:** Place all spans at both orientations. Expected: posts reserve only two cells; the beam is bounded and shown in the ghost. Actual: beam lengths 32/64/96/128 wu for spans 3/4/5/6 at both orientations; occupied rects (448,128)+(576,128) at turn 0 and (448,128)+(448,256) at turn 1; a block may sit between the posts and a block cannot take a post cell. Tunables: cycle 3.0 s, active 1.5 s, charge 0.6 s, beam width 12 wu. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T21

- [x] **Implement Parol Pulse mechanic and feedback**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse). **Dependencies:** [P10-T20](#p10-t20).
  - **Work:** Implement the family behavior, tell and counterplay without copying reference code/art; use centralized timing/force settings.
  - **Acceptance:** Two visible fixtures project a timed light barrier; crossing active span eliminates. A 3-second cycle has 1.5s active and 1.5s inactive; charge-up occupies the final part of inactive time, so it does not extend the cycle. Tell: fixture icons, brightness ramp, non-flashing shape change and audio cue. Counter: cross during safe interval or use cover if cover truly blocks it. Original Tilaok proposal; not UCH reference.
  - **Evidence:** `tilaok!/data/items/hazard.parol_pulse.tres`, `scripts/items/runtime/parol_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Parol sheet](evidence/p10/parol_sheet_variants_rotations_1920x1080.png). **Procedure / expected / actual:** Sample the cycle over 2 cycles; stand in the beam; add cover. Expected: 1.5 s inactive (charge in its tail), 1.5 s active, solids occlude. Actual: charge starts at 0.900 s, active at 1.500 s (±1 step), 180 active frames per 2 cycles, 0.92 phase changes/s (no strobe); inactive/charge safe, active eliminates; one block shortens the beam by exactly its 32 wu. Tell: posts, dotted → thickening → solid band, sound; counter: cross while inactive or use cover. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T22

- [x] **Implement Parol Pulse ownership and cleanup**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse). **Dependencies:** [P10-T21](#p10-t21).
  - **Work:** Preserve direct-source ownership/no-assist rules; implement inactive Place, deterministic Play reset, persistent removal and reference/transient teardown.
  - **Acceptance:** Race and event; Lagsanay only after readability and balance pass. Placer owns direct elimination. Resets phase to inactive/charge at Play start. Needs distinct beam art/audio, overlap readability test. Medium risk; verify at minimum zoom and with multiple emitters. No rapid strobe.
  - **Evidence:** `tilaok!/data/items/hazard.parol_pulse.tres`, `scripts/items/runtime/parol_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Direct elimination, pause mid-cycle, reset. Expected: placer owns the direct kill; reset to inactive/charge; pause freezes the clock. Actual: `owner1 credit-eligible`; 30 paused frames left item and director time unchanged; resume continued from the same point. **Recorded follow-up, not a gate (owner decision 2026-10-13 on P04, applied to P10 by approved Stage A decision D1):** the original lantern, beam art and charge/on sounds are made by the human team (Jorge/Ivie art, Shanti audio). Every placeholder file is `PLACEHOLDER_*`, registered in [ASSETS.md](ASSETS.md) and flagged by the release gate (`PlaceholderAudit`); replacing the file or the `ItemVisualSet` slot needs no code change ([file-level swap probe](evidence/p10/swap_file_level_probe.txt)). **Verification result:** PASSED for the code acceptance. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T23

- [x] **Verify Parol Pulse core behavior in its harness**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse). **Dependencies:** [P10-T22](#p10-t22).
  - **Work:** Run isolated collision/behavior/reset cases before exposing the family to a selectable pool; this is not the later event-compatibility gate.
  - **Acceptance:** Check all configured variants, rotations, collider boundaries, tell/counterplay, deterministic reset and removal. Capture actual results and known limits.
  - **Evidence:** `tilaok!/data/items/hazard.parol_pulse.tres`, `scripts/items/runtime/parol_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Procedure details and the full expected/actual matrix: [P10 verification index](evidence/p10/2026-10-14_p10_verification.md). **Procedure / expected / actual:** Phase timing, occlusion, all spans/orientations, attribution, pause and reset rows in `run_p10_tests.gd`. **Known limits:** minimum-zoom readability with several emitters was inspected on the [crowded stage](evidence/p10/crowded_mixed_48_items_play_1920x1080.png) by the automated author only; no human readability or balance review; Lagsanay pending. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T24

- [x] **Add Parol Pulse egg animation and placement ghost**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse), [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews), [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P10-T23](#p10-t23), [P05-T02](#p05-t02), [P05-T06](#p05-t06).
  - **Work:** Produce/register original visual preview assets; reuse shared preview infrastructure and preserve claimed variant identity.
  - **Acceptance:** Preview/ghost show 3–6 cell fixture span; both fixtures and entire beam previewed. Include relevant sweep/lane/effect and non-color validity; no Pugad names/descriptions.
  - **Evidence:** `tilaok!/data/items/hazard.parol_pulse.tres`, `scripts/items/runtime/parol_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Parol sheet](evidence/p10/parol_sheet_variants_rotations_1920x1080.png); [P10 interactive](evidence/p10/suite_run_p10_interactive.log) (56 checks, 0 failures). **Procedure / expected / actual:** Egg and ghost for all spans/orientations. Actual: egg shows both posts and the whole beam pulsing; ghosts show both posts, the beam and its first blocker ([sheet](evidence/p10/parol_sheet_variants_rotations_1920x1080.png), [tells](evidence/p10/tells_t1_charge_telegraph_compress_1920x1080.png)). **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T25

- [x] **Integrate Parol Pulse with events and scoring**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse). **Dependencies:** [P10-T23](#p10-t23), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04).
  - **Work:** Apply catalog mode restrictions; unsafe capture/force chains block pairing enablement. Walis is construction-only, never a Play hazard.
  - **Acceptance:** Document enabled modes and support eligibility; verify direct credit/no credit and family-specific hazards or forces in independent modes and supported stacks.
  - **Evidence:** [integration evidence](evidence/integration/README.md) (`tests/run_item_mode_integration_tests.gd`, 83 checks, 0 failures) and the mode filter in `scripts/match/pugad_egg_pool_generator.gd` / `P12ScheduledMatchRoom.pugad_mode_ids`. **Procedure / expected / actual:** deal 1500 seeded eggs and the real room's Pugad for each of the six round types, then place the real piece through the Place resolver and run real physics with a held victim. Expected and actual: Parol is dealt in Karera rounds only (Lagsanay/Kangaroo pending review); a placed Parol still kills and credits its placer in all six round types (pieces already on the stage stay active). Enabled modes and support eligibility are documented in [ITEMS](ITEMS.md#event-and-stack-integration--2026-10-16). **Result:** PASSED (synthetic). **Build:** Godot 4.7.stable.official.5b4e0cb0f, Windows 11, scheduled P12 match room (default arena), 3–4 synthetic seats (K1/K2 plus synthetic gamepad IDs), seeded, 60 Hz (`--fixed-fps 60`), working tree on `fec0d3f`, 2026-10-16, reviewer: Claude (AI, automated; no human reviewer). Earlier history: blocked until P08-T06, P11-T12 and P12-T04 passed.


#### P10-T26

- [x] **Write and animate the Parol Pulse Library entry**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse), [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P10-T24](#p10-t24).
  - **Work:** Author entry data/assets against the shared Library schema; integration is checked when the Library shell is available.
  - **Acceptance:** Entry includes name, looping animation, sizes, placement, tell/counterplay, controls and permitted modes; release filter exposes only enabled content.
  - **Evidence:** `item_library_entry.gd`, the Library panel/release filter in the Item Visualizer, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Library entry fields as for Gulong; sizes 3×1–6×1; looping animation; PLACEHOLDER slots; release filter empty. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T27

- [ ] **Verify Parol Pulse release enablement**
  - **Status:** BLOCKED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse). **Dependencies:** [P10-T25](#p10-t25), [P10-T26](#p10-t26), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Test harness plus 2/3/4-player integration, exact preview/ghost, Library, bounds, source credit, support and ten lifecycle resets. Register artifacts and unresolved defects before enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available. **Blocked by:** the family's integration task, [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08) and [P12-T10](#p12-t10). **Next action:** run the 2/3/4-player integration, exact preview/ghost, Library and ten-reset checks, replace placeholders (`PlaceholderAudit`), then decide `release_target` (currently false). **2026-10-16:** the family's integration task passed ([integration evidence](evidence/integration/README.md)) and it is in the match pool. Still open: the 2/3/4-player, preview/ghost, Library and ten-reset release run on final art, `PlaceholderAudit` replacement and the owner's `release_target` decision.


### Tsinelas Launcher — `hazard.slipper_launcher`


#### P10-T28

- [x] **Define Tsinelas Launcher configuration and variants**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Author the family definition from the catalog; expose tuning keys and keep precision/effect regions distinct.
  - **Acceptance:** Definition lists 4×1 or 6×1 lane; 1×1 launcher; 0/180 degrees. Regions, rotations, safe start, owner and mode flags are explicit.
  - **Evidence:** `tilaok!/data/items/hazard.slipper_launcher.tres`, `scripts/items/runtime/launcher_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Validate and mutate. Expected: `lane_4x1`/`lane_6x1`, 1×1 launcher footprint, LANE outside the footprint, rotations 0/2, safe start `reset_idle`. Actual: all T28 rows passed; an unbounded lane is rejected. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T29

- [x] **Build Tsinelas Launcher scene and collision regions**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher). **Dependencies:** [P10-T28](#p10-t28).
  - **Work:** Create original scene/solid/sensor regions and visible bounds; verify the family-specific placement and rotation contract.
  - **Acceptance:** One-cell launcher footprint plus distinct visible lane/hitbox, 0/180° rotation. No projectile spawn inside solid/player/protected area. Fire delay, speed, lifetime, cap, cooldown, hitbox, target policy are tunables.
  - **Evidence:** `tilaok!/data/items/hazard.slipper_launcher.tres`, `scripts/items/runtime/launcher_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Tsinelas sheet](evidence/p10/tsinelas_sheet_variants_rotations_1920x1080.png). **Procedure / expected / actual:** Resolve lanes at 0° and 180°. Expected: lane beside the launcher, bounded. Actual: lane_6x1 x=32 (right) and x=−192 (left), 192 wu; 90° is rejected `rotation_unsupported`. Tunables: initial delay 0.5 s, telegraph 0.8 s, cooldown 1.7 s, speed 360 wu/s, projectile 14 wu, TTL 3 s, caps 16 / 2 per emitter. Spawn safety rejects spawns inside solids, players or protected areas and skips the shot. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T30

- [x] **Implement Tsinelas Launcher mechanic and feedback**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher). **Dependencies:** [P10-T29](#p10-t29).
  - **Work:** Implement the family behavior, tell and counterplay without copying reference code/art; use centralized timing/force settings.
  - **Acceptance:** Telegraphs then fires a slipper along a straight lane; hit eliminates. Solids block the projectile. Tell: barrel/aim lane, charge animation and sound. Counter: cover, dodge, or cross outside firing lane. Projectile-launcher pattern is broad reference; slipper, timing, and cover interactions are original.
  - **Evidence:** `tilaok!/data/items/hazard.slipper_launcher.tres`, `scripts/items/runtime/launcher_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Tsinelas sheet](evidence/p10/tsinelas_sheet_variants_rotations_1920x1080.png). **Procedure / expected / actual:** Measure a 4×1 launcher; hit a chicken; cover it; sit in the muzzle. Expected: telegraph then fire, bounded flight, solids block, no spawn in a body. Actual: telegraph at frame 28, shot at frame 76 (expected 78 ±3), 6.00 wu/frame, gone at frame 98; a hit eliminates; a block in the lane protects the chicken behind it and the lane reports its first blocker; a chicken in the muzzle cell suppresses the shot (0 fired). **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T31

- [x] **Implement Tsinelas Launcher ownership and cleanup**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher). **Dependencies:** [P10-T30](#p10-t30).
  - **Work:** Preserve direct-source ownership/no-assist rules; implement inactive Place, deterministic Play reset, persistent removal and reference/transient teardown.
  - **Acceptance:** Race and event; Lagsanay only after body/tag and projectile balance checks. Launcher placer owns direct hit. Projectile has bounded lifetime and is removed at round end/removal. Needs original slipper sprite/animation and projectile pooling if profiling supports it. Medium-high risk: projectile collision ordering and cleanup. No weapon realism.
  - **Evidence:** `tilaok!/data/items/hazard.slipper_launcher.tres`, `scripts/items/runtime/launcher_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Direct hit, cap saturation, teardown. Expected: placer owns the direct hit; projectile bounded and cleared on removal/round end; rotating allocation under a cap. Actual: `owner1 credit-eligible`; with a cap of 3 and six launchers the peak was 3 and every launcher fired; removal and round end clear handles. **Recorded follow-up, not a gate (owner decision 2026-10-13 on P04, applied to P10 by approved Stage A decision D1):** the original launcher, slipper art and charge/fire sounds are made by the human team (Jorge/Ivie art, Shanti audio). Every placeholder file is `PLACEHOLDER_*`, registered in [ASSETS.md](ASSETS.md) and flagged by the release gate (`PlaceholderAudit`); replacing the file or the `ItemVisualSet` slot needs no code change ([file-level swap probe](evidence/p10/swap_file_level_probe.txt)). **Verification result:** PASSED for the code acceptance. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T32

- [x] **Verify Tsinelas Launcher core behavior in its harness**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher). **Dependencies:** [P10-T31](#p10-t31).
  - **Work:** Run isolated collision/behavior/reset cases before exposing the family to a selectable pool; this is not the later event-compatibility gate.
  - **Acceptance:** Check all configured variants, rotations, collider boundaries, tell/counterplay, deterministic reset and removal. Capture actual results and known limits.
  - **Evidence:** `tilaok!/data/items/hazard.slipper_launcher.tres`, `scripts/items/runtime/launcher_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Procedure details and the full expected/actual matrix: [P10 verification index](evidence/p10/2026-10-14_p10_verification.md). **Procedure / expected / actual:** Telegraph/fire timing, speed, lifetime, blocking, spawn safety, rotations, caps and attribution rows in `run_p10_tests.gd`. **Known limits:** projectile pooling was not needed (16 live projectiles stayed within budget); body/tag balance for Lagsanay untested. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T33

- [x] **Add Tsinelas Launcher egg animation and placement ghost**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher), [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews), [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P10-T32](#p10-t32), [P05-T02](#p05-t02), [P05-T06](#p05-t06).
  - **Work:** Produce/register original visual preview assets; reuse shared preview infrastructure and preserve claimed variant identity.
  - **Acceptance:** Preview/ghost show 4×1 or 6×1 lane; 1×1 launcher; 0/180 degrees. Include relevant sweep/lane/effect and non-color validity; no Pugad names/descriptions.
  - **Evidence:** `tilaok!/data/items/hazard.slipper_launcher.tres`, `scripts/items/runtime/launcher_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Tsinelas sheet](evidence/p10/tsinelas_sheet_variants_rotations_1920x1080.png); [P10 interactive](evidence/p10/suite_run_p10_interactive.log) (56 checks, 0 failures). **Procedure / expected / actual:** Egg and ghost for both lanes at 0°/180°. Actual: egg shows launcher, barrel pull-back and a slipper flying down the exact lane; ghosts draw the dotted lane to its first blocker with a red stop mark ([sheet](evidence/p10/tsinelas_sheet_variants_rotations_1920x1080.png)). **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T34

- [x] **Integrate Tsinelas Launcher with events and scoring**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher). **Dependencies:** [P10-T32](#p10-t32), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04).
  - **Work:** Apply catalog mode restrictions; unsafe capture/force chains block pairing enablement. Walis is construction-only, never a Play hazard.
  - **Acceptance:** Document enabled modes and support eligibility; verify direct credit/no credit and family-specific hazards or forces in independent modes and supported stacks.
  - **Evidence:** [integration evidence](evidence/integration/README.md) (`tests/run_item_mode_integration_tests.gd`, 83 checks, 0 failures) and the mode filter in `scripts/match/pugad_egg_pool_generator.gd` / `P12ScheduledMatchRoom.pugad_mode_ids`. **Procedure / expected / actual:** deal 1500 seeded eggs and the real room's Pugad for each of the six round types, then place the real piece through the Place resolver and run real physics with a held victim. Expected and actual: Tsinelas is dealt in every round type; a direct slipper hit eliminates and credits its placer in all six round types. Enabled modes and support eligibility are documented in [ITEMS](ITEMS.md#event-and-stack-integration--2026-10-16). **Result:** PASSED (synthetic). **Build:** Godot 4.7.stable.official.5b4e0cb0f, Windows 11, scheduled P12 match room (default arena), 3–4 synthetic seats (K1/K2 plus synthetic gamepad IDs), seeded, 60 Hz (`--fixed-fps 60`), working tree on `fec0d3f`, 2026-10-16, reviewer: Claude (AI, automated; no human reviewer). Earlier history: blocked until P08-T06, P11-T12 and P12-T04 passed.


#### P10-T35

- [x] **Write and animate the Tsinelas Launcher Library entry**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher), [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P10-T33](#p10-t33).
  - **Work:** Author entry data/assets against the shared Library schema; integration is checked when the Library shell is available.
  - **Acceptance:** Entry includes name, looping animation, sizes, placement, tell/counterplay, controls and permitted modes; release filter exposes only enabled content.
  - **Evidence:** `item_library_entry.gd`, the Library panel/release filter in the Item Visualizer, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Library entry fields as for Gulong; sizes 1×1 launcher with 4×1/6×1 lane; PLACEHOLDER slots; release filter empty. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T36

- [ ] **Verify Tsinelas Launcher release enablement**
  - **Status:** BLOCKED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher). **Dependencies:** [P10-T34](#p10-t34), [P10-T35](#p10-t35), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Test harness plus 2/3/4-player integration, exact preview/ghost, Library, bounds, source credit, support and ten lifecycle resets. Register artifacts and unresolved defects before enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available. **Blocked by:** the family's integration task, [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08) and [P12-T10](#p12-t10). **Next action:** run the 2/3/4-player integration, exact preview/ghost, Library and ten-reset checks, replace placeholders (`PlaceholderAudit`), then decide `release_target` (currently false). **2026-10-16:** the family's integration task passed ([integration evidence](evidence/integration/README.md)) and it is in the match pool. Still open: the 2/3/4-player, preview/ghost, Library and ten-reset release run on final art, `PlaceholderAudit` replacement and the owner's `release_target` decision.


### Walis Cleanup — `utility.walis_cleanup`


#### P10-T37

- [x] **Define Walis Cleanup configuration and variants**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Author the family definition from the catalog; expose tuning keys and keep precision/effect regions distinct.
  - **Acceptance:** Definition lists 3×3 or 5×5 cleanup area; no solid footprint. Regions, rotations, safe start, owner and mode flags are explicit.
  - **Evidence:** `tilaok!/data/items/utility.walis_cleanup.tres`, `scripts/items/cleanup_target_resolver.gd` and `scripts/match/atomic_edit_resolver.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Validate. Expected: `area_3x3`/`area_5x5`, no collision region, one-shot edit, rotation 0 only, safe start static. Actual: all T37 rows passed. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T38

- [x] **Build Walis Cleanup scene and collision regions**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup). **Dependencies:** [P10-T37](#p10-t37).
  - **Work:** Create original scene/solid/sensor regions and visible bounds; verify the family-specific placement and rotation contract.
  - **Acceptance:** Bounded radius/region with preview; no rotation needed. Never targets base geometry, spawn/goal clearance, hidden event goal, or same-phase newly submitted pieces. Resolve as one removal set, then validate other placements against resulting snapshot; no callback-order dependence. Radius and eligible item categories are tunables.
  - **Evidence:** `tilaok!/data/items/utility.walis_cleanup.tres`, `scripts/items/cleanup_target_resolver.gd` and `scripts/match/atomic_edit_resolver.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Walis preview](evidence/p10/walis_preview_targets_protected_1920x1080.png). **Procedure / expected / actual:** Resolve the target set against fixtures. Expected: bounded area, never base geometry, spawn/goal, same-phase pieces; one removal set. Actual: 3×3 over two earlier-round blocks, one same-phase block and one far block removed exactly the two earlier blocks; an area outside the arena is rejected; protected exclusions are listed. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T39

- [x] **Implement Walis Cleanup mechanic and feedback**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup). **Dependencies:** [P10-T38](#p10-t38).
  - **Work:** Implement the family behavior, tell and counterplay without copying reference code/art; use centralized timing/force settings.
  - **Acceptance:** During Place only, removes player-built pieces inside a previewed bounded area. Restores a route obstructed by accumulated stage clutter. No Play-phase behavior, no direct damage, no trap credit. Tell: broom preview outlines every exact target and protected exclusion. Counterplay is to place thoughtfully; cleanup is limited by one item use and fixed radius. Broad inspiration from UCH Bomb’s removal role; one-shot construction edit is original.
  - **Evidence:** `tilaok!/data/items/utility.walis_cleanup.tres`, `scripts/items/cleanup_target_resolver.gd` and `scripts/match/atomic_edit_resolver.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Walis preview](evidence/p10/walis_preview_targets_protected_1920x1080.png). **Procedure / expected / actual:** Preview and commit. Expected: outlines every exact target and protected exclusion; Place-only; no Play state. Actual: the ghost lists the same two targets the resolver removed; protected base/spawn/goal rects are outlined; Walis has no Play behavior. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T40

- [x] **Implement Walis Cleanup ownership and cleanup**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup). **Dependencies:** [P10-T39](#p10-t39).
  - **Work:** Preserve direct-source ownership/no-assist rules; implement inactive Place, deterministic Play reset, persistent removal and reference/transient teardown.
  - **Acceptance:** Construction-only in race and event rounds; no Lagsanay Play effect. Owner is cleaner for edit audit only, never Patibong. Removed objects do not return on reset. Needs clear ghost/target list and protected-zone outlines. Medium risk: atomic simultaneous edit semantics and support cleanup.
  - **Evidence:** `tilaok!/data/items/utility.walis_cleanup.tres`, `scripts/items/cleanup_target_resolver.gd` and `scripts/match/atomic_edit_resolver.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Commit twice, reset, overlap. Expected: removed pieces never return; owner is audit only; overlapping Walis form one union. Actual: pieces stayed removed after begin_play/end_round; two overlapping Walis removed the shared block once; no trap credit exists. **Recorded follow-up, not a gate (owner decision 2026-10-13 on P04, applied to P10 by approved Stage A decision D1):** the original broom outline art and sweep sound are made by the human team (Jorge/Ivie art, Shanti audio). Every placeholder file is `PLACEHOLDER_*`, registered in [ASSETS.md](ASSETS.md) and flagged by the release gate (`PlaceholderAudit`); replacing the file or the `ItemVisualSet` slot needs no code change ([file-level swap probe](evidence/p10/swap_file_level_probe.txt)). **Verification result:** PASSED for the code acceptance. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T41

- [x] **Verify Walis Cleanup core behavior in its harness**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup). **Dependencies:** [P10-T40](#p10-t40).
  - **Work:** Run isolated collision/behavior/reset cases before exposing the family to a selectable pool; this is not the later event-compatibility gate.
  - **Acceptance:** Check all configured variants, rotations, collider boundaries, tell/counterplay, deterministic reset and removal. Capture actual results and known limits.
  - **Evidence:** `tilaok!/data/items/utility.walis_cleanup.tres`, `scripts/items/cleanup_target_resolver.gd` and `scripts/match/atomic_edit_resolver.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Procedure details and the full expected/actual matrix: [P10 verification index](evidence/p10/2026-10-14_p10_verification.md). **Procedure / expected / actual:** Exact sets, protected/same-phase exclusions, union, once-only commit, out-of-bounds rejection rows in `run_p10_tests.gd` and the match-loop resolver path. **Known limits:** hidden event goal clearance does not exist yet; item cap relief is verified only by the validator rule. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T42

- [x] **Add Walis Cleanup egg animation and placement ghost**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup), [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews), [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P10-T41](#p10-t41), [P05-T02](#p05-t02), [P05-T06](#p05-t06).
  - **Work:** Produce/register original visual preview assets; reuse shared preview infrastructure and preserve claimed variant identity.
  - **Acceptance:** Preview/ghost show 3×3 or 5×5 cleanup area; no solid footprint. Include relevant sweep/lane/effect and non-color validity; no Pugad names/descriptions.
  - **Evidence:** `tilaok!/data/items/utility.walis_cleanup.tres`, `scripts/items/cleanup_target_resolver.gd` and `scripts/match/atomic_edit_resolver.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Walis preview](evidence/p10/walis_preview_targets_protected_1920x1080.png); [P10 interactive](evidence/p10/suite_run_p10_interactive.log) (56 checks, 0 failures). **Procedure / expected / actual:** Egg and ghost for 3×3 and 5×5. Actual: egg shows the exact grid and a sweeping broom; ghost shows the bounded dashed area with X-marked targets and hatched protected areas ([preview](evidence/p10/walis_preview_targets_protected_1920x1080.png), [protected](evidence/p10/walis_preview_protected_exclusion_1920x1080.png)). **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T43

- [x] **Integrate Walis Cleanup with events and scoring**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup). **Dependencies:** [P10-T41](#p10-t41), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04).
  - **Work:** Apply catalog mode restrictions; unsafe capture/force chains block pairing enablement. Walis is construction-only, never a Play hazard.
  - **Acceptance:** Document enabled modes and support eligibility; verify direct credit/no credit and family-specific hazards or forces in independent modes and supported stacks.
  - **Evidence:** [integration evidence](evidence/integration/README.md) (`tests/run_item_mode_integration_tests.gd`, 83 checks, 0 failures) and the mode filter in `scripts/match/pugad_egg_pool_generator.gd` / `P12ScheduledMatchRoom.pugad_mode_ids`. **Procedure / expected / actual:** deal 1500 seeded eggs and the real room's Pugad for each of the six round types, then place the real piece through the Place resolver and run real physics with a held victim. Expected and actual: Walis is dealt in Karera rounds only; in a real match it clears the earlier-round piece in its area during Place, leaves no Play piece and records no elimination or credit (construction-only, never a Play hazard). Enabled modes and support eligibility are documented in [ITEMS](ITEMS.md#event-and-stack-integration--2026-10-16). **Result:** PASSED (synthetic). **Build:** Godot 4.7.stable.official.5b4e0cb0f, Windows 11, scheduled P12 match room (default arena), 3–4 synthetic seats (K1/K2 plus synthetic gamepad IDs), seeded, 60 Hz (`--fixed-fps 60`), working tree on `fec0d3f`, 2026-10-16, reviewer: Claude (AI, automated; no human reviewer). Earlier history: blocked until P08-T06, P11-T12 and P12-T04 passed.


#### P10-T44

- [x] **Write and animate the Walis Cleanup Library entry**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup), [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P10-T42](#p10-t42).
  - **Work:** Author entry data/assets against the shared Library schema; integration is checked when the Library shell is available.
  - **Acceptance:** Entry includes name, looping animation, sizes, placement, tell/counterplay, controls and permitted modes; release filter exposes only enabled content.
  - **Evidence:** `item_library_entry.gd`, the Library panel/release filter in the Item Visualizer, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Library entry fields as for Gulong; sizes 3×3, 5×5; PLACEHOLDER slots; release filter empty. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T45

- [ ] **Verify Walis Cleanup release enablement**
  - **Status:** BLOCKED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup). **Dependencies:** [P10-T43](#p10-t43), [P10-T44](#p10-t44), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Test harness plus 2/3/4-player integration, exact preview/ghost, Library, bounds, source credit, support and ten lifecycle resets. Register artifacts and unresolved defects before enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available. **Blocked by:** the family's integration task, [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08) and [P12-T10](#p12-t10). **Next action:** run the 2/3/4-player integration, exact preview/ghost, Library and ten-reset checks, replace placeholders (`PlaceholderAudit`), then decide `release_target` (currently false). **2026-10-16:** the family's integration task passed ([integration evidence](evidence/integration/README.md)) and it is in the match pool. Still open: the 2/3/4-player, preview/ghost, Library and ten-reset release run on final art, `PlaceholderAudit` replacement and the owner's `release_target` decision.


### Bula-Bulaklak — `hazard.bubble_planter`


#### P10-T46

- [x] **Define Bula-Bulaklak configuration and variants**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18), [P10-T05](#p10-t05), [P10-T14](#p10-t14), [P10-T23](#p10-t23), [P10-T32](#p10-t32), [P10-T41](#p10-t41).
  - **Work:** Author the family definition from the catalog; expose tuning keys and keep precision/effect regions distinct.
  - **Acceptance:** Definition lists 1×3 or 1×5 bubble path; 1×1 emitter; fixed upward direction. Regions, rotations, safe start, owner and mode flags are explicit.
  - **Evidence:** `tilaok!/data/items/hazard.bubble_planter.tres`, `scripts/items/runtime/bubble_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Validate (T46 required T05/T14/T23/T32/T41 checked first; they were). Expected: `path_1x3`/`path_1x5`, 1×1 emitter, fixed upward EFFECT path, rotation 0 only, safe start `reset_idle`. Actual: all T46 rows passed; a path beyond the arena is rejected. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T47

- [x] **Build Bula-Bulaklak scene and collision regions**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak). **Dependencies:** [P10-T46](#p10-t46).
  - **Work:** Create original scene/solid/sensor regions and visible bounds; verify the family-specific placement and rotation contract.
  - **Acceptance:** Emitter footprint separate from bubble trigger/path; vertical fixed path, no rotation in v1. One captive per bubble and one bubble per player. Cadence, path, capture time (~2s), release velocity, grace, bubble cap are tunables. Stop/resolve against ceiling and bounds; release at nearest safe non-overlapping position with bounded velocity. If no safe location exists, release at last safe point with zero velocity.
  - **Evidence:** `tilaok!/data/items/hazard.bubble_planter.tres`, `scripts/items/runtime/bubble_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Bula sheet](evidence/p10/bula_sheet_variants_rotations_1920x1080.png). **Procedure / expected / actual:** Resolve the path. Expected: emitter separate from the path; bounded. Actual: path_1x5 is (0,−160,32,160) relative to the pot. Tunables: cadence 2.5 s, rise 60 wu/s, capture 2.0 s, release 120 wu/s, immunity 1.0 s, caps 4 / 1 per emitter / 1 per player. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T48

- [x] **Implement Bula-Bulaklak mechanic and feedback**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak). **Dependencies:** [P10-T47](#p10-t47).
  - **Work:** Implement the family behavior, tell and counterplay without copying reference code/art; use centralized timing/force settings.
  - **Acceptance:** Emits one bubble at a time along a fixed upward path/cadence. Captures one live chicken for about 2s; no control while held; never eliminates itself. It can displace a player into another trap or past a route. Tell: visible bubble path, cadence and captive icon. Counter: time the gap or let another direct hazard be avoided after release. Original Tilaok proposal; no plant identification or educational claim.
  - **Evidence:** `tilaok!/data/items/hazard.bubble_planter.tres`, `scripts/items/runtime/bubble_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Bula sheet](evidence/p10/bula_sheet_variants_rotations_1920x1080.png). **Procedure / expected / actual:** Capture, hold, release, hold input. Expected: one bubble at a time, capture ≈2 s, no control, never eliminates. Actual: captured on contact, held 121 frames (120 ±4), rose measurably, released on a free non-overlapping spot, no terminal state, a held D key did not move it, the capture is a setup record. Release resolver cases: open, wall overlap, ceiling and no-safe-spot (reported, so the last safe point with zero velocity is used). **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T49

- [x] **Implement Bula-Bulaklak ownership and cleanup**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak). **Dependencies:** [P10-T48](#p10-t48).
  - **Work:** Preserve direct-source ownership/no-assist rules; implement inactive Place, deterministic Play reset, persistent removal and reference/transient teardown.
  - **Acceptance:** Race: captive must be released before goal completion; captured player can be hit by external traps. Lagsanay: timer continues and captive remains taggable; disable in Lagsanay if capture-to-elimination is unavoidable. Exclude dead/finished/already-captured players; simultaneous captures resolved by stable player ID and bubble ID; short immunity prevents immediate re-capture. Bubble gives no Patibong; actual eliminating trap does. Remove bubble/captive state on death/end/restart/emitter removal. Needs custom player-state lifecycle and cage-free release tests; highest risk, last in A.
  - **Evidence:** `tilaok!/data/items/hazard.bubble_planter.tres`, `scripts/items/runtime/bubble_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Removal, death, round end, restart, immunity, same-step order. Expected: captive state cleared each time; no recapture inside 1.0 s. Actual: all four cleanup paths ended not captured with 0 captives; no recapture before 0.97 s; bubble + trumpo scenario credits the trumpo owner only. **Recorded follow-up, not a gate (owner decision 2026-10-13 on P04, applied to P10 by approved Stage A decision D1):** the original flower, bubble art and emit/capture/pop sounds are made by the human team (Jorge/Ivie art, Shanti audio). Every placeholder file is `PLACEHOLDER_*`, registered in [ASSETS.md](ASSETS.md) and flagged by the release gate (`PlaceholderAudit`); replacing the file or the `ItemVisualSet` slot needs no code change ([file-level swap probe](evidence/p10/swap_file_level_probe.txt)). **Verification result:** PASSED for the code acceptance. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T50

- [x] **Verify Bula-Bulaklak core behavior in its harness**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak). **Dependencies:** [P10-T49](#p10-t49).
  - **Work:** Run isolated collision/behavior/reset cases before exposing the family to a selectable pool; this is not the later event-compatibility gate.
  - **Acceptance:** Check all configured variants, rotations, collider boundaries, tell/counterplay, deterministic reset and removal. Capture actual results and known limits.
  - **Evidence:** `tilaok!/data/items/hazard.bubble_planter.tres`, `scripts/items/runtime/bubble_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Procedure details and the full expected/actual matrix: [P10 verification index](evidence/p10/2026-10-14_p10_verification.md). **Procedure / expected / actual:** Capture/release/immunity/cleanup/cap rows in `run_p10_tests.gd` and the four-bubble cap stress. **Known limits:** Lagsanay capture-to-elimination chains are not evaluated (pending review); no-safe-spot is verified on the resolver and the last-safe-point branch, not in a fully enclosed physical cage. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T51

- [x] **Add Bula-Bulaklak egg animation and placement ghost**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak), [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews), [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P10-T50](#p10-t50), [P05-T02](#p05-t02), [P05-T06](#p05-t06).
  - **Work:** Produce/register original visual preview assets; reuse shared preview infrastructure and preserve claimed variant identity.
  - **Acceptance:** Preview/ghost show 1×3 or 1×5 bubble path; 1×1 emitter; fixed upward direction. Include relevant sweep/lane/effect and non-color validity; no Pugad names/descriptions.
  - **Evidence:** `tilaok!/data/items/hazard.bubble_planter.tres`, `scripts/items/runtime/bubble_behavior.gd`, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). Rendered evidence: [Bula sheet](evidence/p10/bula_sheet_variants_rotations_1920x1080.png); [P10 interactive](evidence/p10/suite_run_p10_interactive.log) (56 checks, 0 failures). **Procedure / expected / actual:** Egg and ghost for both paths. Actual: egg shows the pot, the exact upward path with arrows and a rising bubble; ghost shows the bounded path to its first blocker ([sheet](evidence/p10/bula_sheet_variants_rotations_1920x1080.png)). **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T52

- [x] **Integrate Bula-Bulaklak with events and scoring**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak). **Dependencies:** [P10-T50](#p10-t50), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04).
  - **Work:** Apply catalog mode restrictions; unsafe capture/force chains block pairing enablement. Walis is construction-only, never a Play hazard.
  - **Acceptance:** Document enabled modes and support eligibility; verify direct credit/no credit and family-specific hazards or forces in independent modes and supported stacks.
  - **Evidence:** [integration evidence](evidence/integration/README.md) (`tests/run_item_mode_integration_tests.gd`, 83 checks, 0 failures) and the mode filter in `scripts/match/pugad_egg_pool_generator.gd` / `P12ScheduledMatchRoom.pugad_mode_ids`. **Procedure / expected / actual:** deal 1500 seeded eggs and the real room's Pugad for each of the six round types, then place the real piece through the Place resolver and run real physics with a held victim. Expected and actual: Bula is dealt in Karera rounds only (Lagsanay/Kangaroo pending review); a placed Bula captures and releases a chicken with no elimination or credit in all six round types, so capture never becomes a credited chain. Enabled modes and support eligibility are documented in [ITEMS](ITEMS.md#event-and-stack-integration--2026-10-16). **Result:** PASSED (synthetic). **Build:** Godot 4.7.stable.official.5b4e0cb0f, Windows 11, scheduled P12 match room (default arena), 3–4 synthetic seats (K1/K2 plus synthetic gamepad IDs), seeded, 60 Hz (`--fixed-fps 60`), working tree on `fec0d3f`, 2026-10-16, reviewer: Claude (AI, automated; no human reviewer). Earlier history: blocked until P08-T06, P11-T12 and P12-T04 passed.


#### P10-T53

- [x] **Write and animate the Bula-Bulaklak Library entry**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak), [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P10-T51](#p10-t51).
  - **Work:** Author entry data/assets against the shared Library schema; integration is checked when the Library shell is available.
  - **Acceptance:** Entry includes name, looping animation, sizes, placement, tell/counterplay, controls and permitted modes; release filter exposes only enabled content.
  - **Evidence:** `item_library_entry.gd`, the Library panel/release filter in the Item Visualizer, [P10 tests](evidence/p10/suite_run_p10_tests.log) (421 checks, 0 failures). **Procedure / expected / actual:** Library entry fields as for Gulong; sizes 1×3 and 1×5 path; PLACEHOLDER slots; release filter empty. **Verification result:** PASSED. **Build/engine/date/profile/seed/input:** `main` at `a368c96` + the P10 working tree; Godot 4.7.2.stable.official.ed1daf0bf; 2026-10-14; profile `items_lab` (development only, nothing release-enabled), seed 12345; 60-Hz physics; synthetic K1/K2 keyboard seats and synthetic gamepad seats 3/4, no physical devices. **Reviewer:** Claude Code automated session (implementation author); no independent human review claimed.


#### P10-T54

- [ ] **Verify Bula-Bulaklak release enablement**
  - **Status:** BLOCKED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak). **Dependencies:** [P10-T52](#p10-t52), [P10-T53](#p10-t53), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Test harness plus 2/3/4-player integration, exact preview/ghost, Library, bounds, source credit, support and ten lifecycle resets. Register artifacts and unresolved defects before enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available. **Blocked by:** the family's integration task, [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08) and [P12-T10](#p12-t10). **Next action:** run the 2/3/4-player integration, exact preview/ghost, Library and ten-reset checks, replace placeholders (`PlaceholderAudit`), then decide `release_target` (currently false). **2026-10-16:** the family's integration task passed ([integration evidence](evidence/integration/README.md)) and it is in the match pool. Still open: the 2/3/4-player, preview/ghost, Library and ten-reset release run on final art, `PlaceholderAudit` replacement and the owner's `release_target` decision.


## P11 — Kangaroo independently

**Goal / player-visible result:** Players read and respond to three commands through escalation.

**Milestone / scope:** Feature-complete submission, then release/submission.

**Entry:** P08 outcome infrastructure and P03 actual support contact available.

**External task dependencies:** [P02-T12](#p02-t12), [P03-T06](#p03-t06), [P08-T06](#p08-t06)

**Owner roles:** Gameplay; person names TBD. **Systems touched:** NEW slipper presenter, scheduler, command evaluators and pressure controller.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** The standalone implementation and engineering evidence are complete. Human comprehension, physical controller, player-feel/balance, native-speaker/cultural and final asset reviews remain open. R1–R4 and all event stacks remain inactive; P12 owns schedule and stack integration. The P11 standalone hazard rule is strict recorded-time precedence: only a strictly earlier comparable direct hazard wins; exact ties or unavailable comparison resolve as command failure without Patibong.

**Exit criteria:** Individual commands, markers, pressure/Storm, standalone match lifecycle and cleanup pass on the development route; R1–R4 remain inactive. This engineering exit does not close human/release gates or P12 stacks.

**Evidence required:** [P11 test and route evidence index](evidence/p11/README.md), including support/command coverage, overlap limits, Last Cluck, rendered capture, export smoke and measured limitations.


#### P11-T01

- [x] **Build the non-colliding slipper presenter and command cues**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-KANG-001](PRD.md#req-kang-001--present-and-schedule-independent-kangaroo-commands). **Dependencies:** [P08-T06](#p08-t06), [P03-T06](#p03-t06).
  - **Work:** Create original normal/sole-up/sideways poses, landing animation, text/icon, audio and timing ring. Integrate full/reduced/off shake without any collision or simulation pause.
  - **Acceptance:** Each command has a distinct pose/icon/audio/ring and remains readable muted with shake off; presenter has no gameplay collision.
  - **Evidence:** [P11 interactive report](evidence/p11/p11_interactive_run.txt), [1920×1080 HUD capture](evidence/p11/p11_2p_command_hud_1920x1080.png). **Verification result:** PASSED — synthetic 2/3/4-seat route displays the debug pose, timing and audio placeholder labels; visual-only presenter collision checks and muted/shake-off HUD assertions pass. Human comprehension remains open.


#### P11-T13

- [x] **Implement Kangaroo command selection and base cadence**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-KANG-001](PRD.md#req-kang-001--present-and-schedule-independent-kangaroo-commands). **Dependencies:** [P11-T01](#p11-t01).
  - **Work:** Select equal-weight commands, telegraph/respond/evaluate/reset on the source timings; pre-telegraph Hug reroll at two survivors has no command/pressure effect. Stop selecting at one survivor.
  - **Acceptance:** Seeded selection checks distribution and two-survivor reroll; no commands after a sole survivor; presenter never collides; full/reduced/off shake preserves comprehension.
  - **Evidence:** [P11 focused suite](evidence/p11/p11_unit_run.txt), checks 1–15. **Verification result:** PASSED — seeded command distribution, two-player Hug reroll without consuming a command ID, cadence easing and sole-survivor stop pass.


#### P11-T02

- [x] **Verify present and schedule independent kangaroo commands**
  - **Status:** PASSED — synthetic engineering evidence · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-KANG-001](PRD.md#req-kang-001--present-and-schedule-independent-kangaroo-commands). **Dependencies:** [P11-T13](#p11-t13).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Seeded selection checks distribution and two-survivor reroll; no commands after a sole survivor; presenter never collides; full/reduced/off shake preserves comprehension.
  - **Acceptance:** Seeded selection checks distribution and two-survivor reroll; no commands after a sole survivor; presenter never collides; full/reduced/off shake preserves comprehension.
  - **Evidence:** [P11 interactive report](evidence/p11/p11_interactive_run.txt), [HUD capture](evidence/p11/p11_2p_command_hud_1920x1080.png). **Verification result:** PASSED — 85/85 synthetic route assertions, including 2/3/4 seats, command cues, muted audio, full/reduced/off shake, pause/reclaim, Last Cluck results and cleanup. Human comprehension and actual-device review remain open.


#### P11-T03

- [x] **Implement the Freeze command evaluator**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-KANG-002](PRD.md#req-kang-002--evaluate-freeze-from-intentional-input). **Dependencies:** [P11-T02](#p11-t02), [P02-T12](#p02-t12).
  - **Work:** During response, intentional run/jump fails Freeze. Shared deadzone and prototype .10 s release grace filter drift/release. Opposing run buttons still count as intent. Passive motion, launch, wind or tag contact does not fail; deliberate run/jump while captured still counts.
  - **Acceptance:** Test drift, held/released inputs, opposite keys, forced motion, capture and passive tag; input intent and movement outcome cannot be confused.
  - **Evidence:** [P11 focused suite](evidence/p11/p11_unit_run.txt), Freeze cases. **Verification result:** PASSED — event-edge evaluation catches taps between physics samples, fresh presses fail immediately, and start-held input gets one nonrenewable 0.10-second release grace. Forced motion does not count as intent.


#### P11-T04

- [x] **Verify evaluate freeze from intentional input**
  - **Status:** PASSED — synthetic input and physics evidence · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-KANG-002](PRD.md#req-kang-002--evaluate-freeze-from-intentional-input). **Dependencies:** [P11-T03](#p11-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Test drift, held/released inputs, opposite keys, forced motion, capture and passive tag; input intent and movement outcome cannot be confused.
  - **Acceptance:** Test drift, held/released inputs, opposite keys, forced motion, capture and passive tag; input intent and movement outcome cannot be confused.
  - **Evidence:** [P11 focused suite](evidence/p11/p11_unit_run.txt), [P02 regression](evidence/p11/p02_input_regression_run.txt). **Verification result:** PASSED — held/released/fresh/opposing/captured/passive-force paths pass; P02's 83-check suite confirms input edges, captured intent and release clearing. Physical drift/controller hardware remains open.


#### P11-T05

- [x] **Implement wave presentation, support evaluation and drain**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-KANG-003](PRD.md#req-kang-003--evaluate-rising-wave-with-actual-built-support). **Dependencies:** [P11-T02](#p11-t02), [P03-T06](#p03-t06).
  - **Work:** Select equal-probability middle-low/middle/middle-high world bands, never camera-relative or rerolled for an impossible layout. Telegraph target line then raise/drain wave. At evaluation require actual grounded player-built eligible support above line; base, airborne, jumping through, bubble or coyote state fails. Prototype bands/tolerance remain untested.
  - **Acceptance:** Test every support-table state just above/on/below each band, destroyed/moving support on evaluation tick and another player’s platform; empty layout remains intentionally unsolvable; drain clears.
  - **Evidence:** [P11 focused suite](evidence/p11/p11_unit_run.txt), Rising cases. **Verification result:** PASSED — seeded selection uses each fixed 768/576/384 wu world line; only current, eligible player-built support above the line with 1 wu tolerance qualifies. Impossible layouts are not rerolled.


#### P11-T06

- [x] **Verify evaluate rising wave with actual built support**
  - **Status:** PASSED — synthetic support-contract evidence · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-KANG-003](PRD.md#req-kang-003--evaluate-rising-wave-with-actual-built-support). **Dependencies:** [P11-T05](#p11-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Test every support-table state just above/on/below each band, destroyed/moving support on evaluation tick and another player’s platform; empty layout remains intentionally unsolvable; drain clears.
  - **Acceptance:** Test every support-table state just above/on/below each band, destroyed/moving support on evaluation tick and another player’s platform; empty layout remains intentionally unsolvable; drain clears.
  - **Evidence:** [P11 focused suite](evidence/p11/p11_unit_run.txt), [P03 support regression](evidence/p11/p03_support_regression_run.txt). **Verification result:** PASSED — all three P11 bands, boundary tolerance, base/below/ineligible/stale support rejection, other-player construction, same-step moving contact, support removal and wave drain are covered. P03's 103-check suite adds real physics for coyote/airborne/bubble, moving/crumbling/one-way/spring supports and same-step invalidation. Player explanation and live layout playability still need human review.


#### P11-T07

- [x] **Implement pair selection and Hug evaluation**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-KANG-004](PRD.md#req-kang-004--evaluate-pair-only-hug-deterministically). **Dependencies:** [P11-T02](#p11-t02), [P02-T12](#p02-t12).
  - **Work:** At evaluation pair live eligible chickens by shortest contact first, equal-distance player-slot order; one partner maximum. Paired chickens pass and unpaired fail. Contact only at evaluation matters. Three clustered chickens leave one unpaired; four may form two pairs. R2 group-contact alternative remains inactive.
  - **Acceptance:** Verify all-contact three, two pairs of four, split groups, equal distances, entry/exit at evaluation, removed players and the two-survivor pre-telegraph reroll.
  - **Evidence:** [P11 focused suite](evidence/p11/p11_unit_run.txt), Hug cases. **Verification result:** PASSED — live evaluation contacts are sorted by center distance and stable slot IDs, greedily paired once, and excluded when a seat is no longer live.


#### P11-T08

- [x] **Verify evaluate pair-only hug deterministically**
  - **Status:** PASSED — deterministic synthetic contact evidence · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-KANG-004](PRD.md#req-kang-004--evaluate-pair-only-hug-deterministically). **Dependencies:** [P11-T07](#p11-t07).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Verify all-contact three, two pairs of four, split groups, equal distances, entry/exit at evaluation, removed players and the two-survivor pre-telegraph reroll.
  - **Acceptance:** Verify all-contact three, two pairs of four, split groups, equal distances, entry/exit at evaluation, removed players and the two-survivor pre-telegraph reroll.
  - **Evidence:** [P11 focused suite](evidence/p11/p11_unit_run.txt). **Verification result:** PASSED — equal-distance slot order, nearest-pair choice, four-seat double pair, unpaired third, removed seat, evaluation-only contact and two-seat pre-telegraph reroll pass.


#### P11-T09

- [x] **Integrate Kangaroo markers and terminal lifecycle**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-KANG-005](PRD.md#req-kang-005--integrate-failure-markers-elimination-and-cleanup). **Dependencies:** [P11-T04](#p11-t04), [P11-T06](#p11-t06), [P11-T08](#p11-t08).
  - **Work:** Failed commands add KANG, GA, ROO markers; third eliminates. Traps eliminate directly. Remove terminal players from future command/tag eligibility. Last survivor uses Lagsanay placement/Bawi/Patibong rules; command failures do not earn trap credit. Resolve once through shared outcome infrastructure.
  - **Acceptance:** Test first/second/third failures, overlapping failures and trap same-step review cases; no fourth marker or duplicate placement. End/removal/restart clears scheduler, rings, wave and markers.
  - **Evidence:** [P11 focused suite](evidence/p11/p11_unit_run.txt), [interactive lifecycle report](evidence/p11/p11_interactive_run.txt). **Verification result:** PASSED — markers saturate at three, direct trap precedence follows the strict timestamp rule, tied/terminal results batch once, shared placement scoring commits once, Last Cluck placement is stable, and teardown clears round state while preserving construction.


#### P11-T10

- [x] **Verify integrate failure markers, elimination and cleanup**
  - **Status:** PASSED — synthetic lifecycle evidence · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-KANG-005](PRD.md#req-kang-005--integrate-failure-markers-elimination-and-cleanup). **Dependencies:** [P11-T09](#p11-t09).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Test first/second/third failures, overlapping failures and trap same-step review cases; no fourth marker or duplicate placement. End/removal/restart clears scheduler, rings, wave and markers.
  - **Acceptance:** Test first/second/third failures, overlapping failures and trap same-step review cases; no fourth marker or duplicate placement. End/removal/restart clears scheduler, rings, wave and markers.
  - **Evidence:** [P11 focused suite](evidence/p11/p11_unit_run.txt), [interactive report](evidence/p11/p11_interactive_run.txt). **Verification result:** PASSED — overlapping third failures, exactly one result per player, cleanup, persistent construction, next Pugad and pause/reclaim clock freeze all pass. Human review and non-synthetic device lifecycle remain open.


#### P11-T11

- [x] **Implement acceleration, Storm overlap and reset**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-KANG-006](PRD.md#req-kang-006--implement-no-elimination-acceleration-and-slipper-storm). **Dependencies:** [P11-T10](#p11-t10).
  - **Work:** After every two completed commands without elimination reduce next response .5 s and reset .15 s, minimum 1 s response and zero reset. After eight enter Storm: landing every .5 s, 1 s command, maximum two active; delay a third. At two survivors force overlapping Freeze plus Rising pairs; Hug rerolls. Any elimination resets pressure/cadence. R3 non-overlap proposal remains inactive.
  - **Acceptance:** Check each acceleration boundary, active cap, delayed landing, two-survivor overlap, elimination reset and all-remaining Last Cluck; reproduce unavoidable-choice risks without claiming balance.
  - **Evidence:** [P11 focused suite](evidence/p11/p11_unit_run.txt), Storm cases. **Verification result:** PASSED — two-completion easing, eight-completion pressure, 0.5-second landing/one-second active timing, delayed landings at the two-command cap, two-seat Freeze/Rising pairs and reset after any elimination are implemented.


#### P11-T12

- [x] **Verify implement no-elimination acceleration and slipper storm**
  - **Status:** PASSED — deterministic synthetic pressure evidence · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-KANG-006](PRD.md#req-kang-006--implement-no-elimination-acceleration-and-slipper-storm). **Dependencies:** [P11-T11](#p11-t11).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Check each acceleration boundary, active cap, delayed landing, two-survivor overlap, elimination reset and all-remaining Last Cluck; reproduce unavoidable-choice risks without claiming balance.
  - **Acceptance:** Check each acceleration boundary, active cap, delayed landing, two-survivor overlap, elimination reset and all-remaining Last Cluck; reproduce unavoidable-choice risks without claiming balance.
  - **Evidence:** [P11 focused suite](evidence/p11/p11_unit_run.txt), [Last Cluck result capture](evidence/p11/p11_last_cluck_results_1920x1080.png), including extended-window cap stress and simultaneous Last Cluck. **Verification result:** PASSED — acceleration boundaries, overlap cap, delayed landing, forced pair, elimination reset and terminal batch pass; unavoidable-choice balance remains unreviewed.
  - **Defects found later (2026-10-15, during P12-T01):** running several Kangaroo rounds in one match exposed two controller defects that the single-round P11 checks did not cover. (1) When an elimination ended a Slipper Storm while a second Storm command was still pending, the base cadence never resumed after that command drained, so the round could not end. (2) `reset()` cleared the room's own actor map in place (it kept a reference from the last step), so the next Kangaroo round had no chickens. Both are fixed in `kangaroo_round_controller.gd`, with regressions in `run_p12_tests.gd` (the Storm regression was confirmed to fail on the old code). The P11 focused (78) and interactive (85) suites still pass; see the [P12 evidence index](evidence/p12/README.md).


## P12 — Scheduling and stacks

**Goal / player-visible result:** The announced challenge and optional compatible Twist execute with one scoring family.

**Milestone / scope:** Feature-complete submission, then release/submission.

**Entry:** Each pair starts when its individual components pass; Karera+Lagsanay may start before Kangaroo.

**External task dependencies:** [P01-T06](#p01-t06), [P06-T02](#p06-t02), [P06-T08](#p06-t08), [P08-T06](#p08-t06), [P11-T10](#p11-t10), [P11-T12](#p11-t12)

**Owner roles:** Gameplay; person names TBD. **Systems touched:** NEW event scheduler, compatibility registry and stack integration.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** All rounds/announcements and three pairs pass; unresolved terminal cases receive explicit review.

**Evidence required:** Seeded schedule checks, reviewed precedence table and 2/3/4-player pair results.

**Phase roll-up (2026-10-15): 10/10 task records pass on technical, synthetic-seat evidence; human sessions pending.** T01/T02/T05/T06 are the schedule, registry, Pugad announcement and Karera + Bomb-Taya pair; T03/T04/T07–T10 add the owner-approved terminal-order table ([decision table](evidence/p12/p12_terminal_order_decision_table.md)), Karera + Kangaroo and Kangaroo + Bomb-Taya. All three compatibility rows are enabled, so Twists roll from round 5 on `P12ScheduledMatchRoom`, now selected by the default player route; P07 remains available through its separately gated first-playable route. `run_p12_pairs_tests.gd` passes 285/285 (90 decision-table scenario checks with callback-order permutations, 195 real-room checks at 2/3/4 seats, ten restarts with constant node counts), a rendered 2- and 4-seat tour passes 40/40 with 26 captures, and every earlier suite matches the `ef78950` baseline. The heaviest stack (Kangaroo + Bomb-Taya with Storm, 4 seats, 40 pieces) measured p95 3.7 ms / worst 5.7 ms and 122.8 MiB in three warmed runs on an otherwise idle machine; target-PC profiling stays open. Barya is now implemented and verified separately under P19-T01/T163/T164/T02, with a P12 `--barya-disabled` rollback switch. Not claimed: human playtest, physical device, novice comprehension, balance/cultural review, final art/audio or P07/P08 release acceptance. Evidence index: [P12 evidence](evidence/p12/README.md).


#### P12-T01

- [x] **Implement schedule, compatibility pool and prior-Pugad announcement**
  - **Status:** PASSED — automated synthetic evidence (2026-10-15) · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-EVENT-001](PRD.md#req-event-001--select-and-announce-the-required-event-schedule). **Dependencies:** [P11-T12](#p11-t12), [P01-T06](#p01-t06).
  - **Work:** Round 1 Karera; rounds 4/8/12 standalone Lagsanay. Other eligible rounds use Karera 70%, Lagsanay 20%, Kangaroo 10%. Only non-guaranteed rounds roll a Twist: 0% rounds 1–4, 10% 5–7, 20% 8–10, 30% 11–12. No self-stack, maximum one Twist, none in sudden death. Lock next round and announce Main then Twist during preceding Pugad; tutorial override only guided first Karera.
  - **Implementation:** `EventSchedule` (`scripts/match/event_schedule.gd`) locks each round once, in order, from the match's seeded `event` stream. Unavailable modes are zeroed before the weights are normalized. A missing required mode (Karera for round 1; Lagsanay for rounds 4/8/12 and sudden death) refuses the match instead of rescheduling it as Karera. `COMPATIBILITY` lists the three GDD pairs with `enabled = false` until each pair task passes. `P12ScheduledMatchRoom` locks round N+1 during round N's Pugad and shows it in the Pugad `AnnounceBanner`, Main first and Twist below (for example "NEXT • ROUND 6: KANGAROO" / "No Twist · This round: KARERA"); the Play HUD shows the challenge and any Twist. Karera rounds run the P09 race. Lagsanay and Kangaroo Main rounds reuse the verified `LagsanayRoundController` and `KangarooRoundController` (the latter through the new `KangarooMainRound` host) with their own placement scoring and result screens, then end through the same match lifecycle (`_conclude_round`, extracted from P09's race end). Sudden death stays standalone Lagsanay. Round 1 is always Karera, so the guided tutorial needs no override.
  - **Acceptance:** Seeded table covers all 12 rounds, guaranteed-round precedence, prior announcement consistency, zero/one compatible options and required missing-mode rejection.
  - **Evidence:** [P12 evidence index](evidence/p12/README.md); [schedule and full-match tests](evidence/p12/2026-10-15_p12_schedule_tests.txt) (61 checks, 0 failures). **Verification result:** PASSED — see P12-T02. Synthetic seats and inputs; no player session, physical device or human review.


#### P12-T02

- [x] **Verify select and announce the required event schedule**
  - **Status:** PASSED — automated synthetic evidence (2026-10-15) · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-EVENT-001](PRD.md#req-event-001--select-and-announce-the-required-event-schedule). **Dependencies:** [P12-T01](#p12-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Seeded table covers all 12 rounds, guaranteed-round precedence, prior announcement consistency, zero/one compatible options and required missing-mode rejection.
  - **Acceptance:** Seeded table covers all 12 rounds, guaranteed-round precedence, prior announcement consistency, zero/one compatible options and required missing-mode rejection.
  - **Procedure:** `godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_p12_tests.gd` (Godot 4.7, Windows 11, synthetic seats). Expected and actual results:
    - 500 seeded 12-round tables: round 1 Karera and rounds 4/8/12 Lagsanay, with no Twist while no pair is enabled. Non-guaranteed Main draws were 0.699/0.197/0.103 over 16,000 rounds (target 70/20/10); an unavailable Kangaroo is zeroed and the rest renormalized.
    - The same seed gives the same table, and locking round 12 first does not change it.
    - With the pairs force-enabled for the check: no Twist in rounds 1–4 or on guaranteed rounds; Twist rates 0.105/0.202/0.303 for the 5–7/8–10/11–12 bands; never a self-stack or an unlisted partner; Karera's two partners equally likely. One option: a Kangaroo Main always gets Bomb-Taya. Zero options: a Lagsanay Main, or an empty pool, plays as a normal round.
    - A missing Lagsanay or Karera refuses the schedule, and the room returns to the lobby with the reason; a missing Kangaroo is allowed.
    - Full 12-round matches with 2, 3 and 4 seats (seed 3: Karera ×6, Lagsanay ×4, Kangaroo ×2): every round plays the Main announced in the previous Pugad, the banner shows the locked next round, the flag is live only in Karera, event rounds commit their placement scores, every round ends through the lifecycle and round 12 ends the match.
    - Rendered 1920×1080 captures of the banner and of both event rounds.
  - **Evidence:** [P12 evidence index](evidence/p12/README.md). **Verification result:** PASSED (61 checks, 0 failures; full regression in the index). Reviewer: Claude (AI, automated). The Twist rows themselves stay disabled; no player, physical-device or human review is claimed.


#### P12-T03

- [x] **Resolve the event terminal-order decision table**
  - **Status:** PASSED — owner-approved decision table implemented (2026-10-15) · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-EVENT-002](PRD.md#req-event-002--review-unresolved-simultaneous-terminal-ordering). **Dependencies:** [P08-T06](#p08-t06), [P11-T10](#p11-t10).
  - **Work:** Preserve recorded-time hazard/goal and exact-tie rules, one terminal outcome and Main-only scoring. Before integration document unresolved ordering among command evaluation, timeout, pass, goal and support destruction where existing sources do not fully determine a case. Keep proposed rule replacements inactive.
  - **Acceptance:** A team-reviewed decision table resolves each uncovered same-step case with source or explicit approval and corresponding scenario; no callback-order dependence or silently invented PRD rule.
  - **Draft:** [P12 terminal-order decision table — DRAFT](P12_TERMINAL_ORDER_DRAFT.md). It has 16 rows: 8 for Karera + Bomb-Taya (behaviour as implemented, with the unsourced rows marked "needs approval"), 4 for Karera + Kangaroo and 4 for Kangaroo + Lagsanay (proposals only). It stays unchecked until the team reviews every row; no proposal is active in the Kangaroo pairs.
  - **Evidence:** [Decision table](evidence/p12/p12_terminal_order_decision_table.md): C1–C15 cite their source; U1–U12 approved row by row by the project owner on 2026-10-15 (chat: "approve U1-U12 as proposed, D1-D7 as recommended"). It supersedes the [draft](P12_TERMINAL_ORDER_DRAFT.md); the draft rows K2, K3 and K4 changed behaviour to the approved rules in `BombTayaTwist`/`P12ScheduledMatchRoom`. One batch per physics step; no callback-order dependence. Appended (not substituted) to [STAGE_AND_PLACEMENT](STAGE_AND_PLACEMENT.md) and GDD §4. R1–R4 inactive. Open: draft row K6 (bubble-captured runner as taya) is a state question, not a same-step ordering case, and stays with the team. **Verification result:** PASSED — see P12-T04.


#### P12-T04

- [x] **Verify review unresolved simultaneous terminal ordering**
  - **Status:** PASSED — every approved row has a passing scenario (2026-10-15) · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-EVENT-002](PRD.md#req-event-002--review-unresolved-simultaneous-terminal-ordering). **Dependencies:** [P12-T03](#p12-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. A team-reviewed decision table resolves each uncovered same-step case with source or explicit approval and corresponding scenario; no callback-order dependence or silently invented PRD rule.
  - **Acceptance:** A team-reviewed decision table resolves each uncovered same-step case with source or explicit approval and corresponding scenario; no callback-order dependence or silently invented PRD rule.
  - **Evidence:** Controller scenarios (`p12_table_scenarios.gd`) and room scenarios (`p12_pair_room_scenarios.gd`) in [the P12 pairs run](evidence/p12/p12_pairs_test_run.txt), including ten callback-order permutations with identical outcomes. Review record: approver is the project owner named in the [decision table](evidence/p12/p12_terminal_order_decision_table.md). Procedure: `Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path tilaok! --script res://tests/run_p12_pairs_tests.gd` (real physics, deterministic scripted synthetic inputs; forced locked entries are test-only). Build: Godot 4.7.2.stable on `origin/main` `ef78950` plus the P12 pairs change set; seed 12345. Input type: synthetic K1/K2 keyboard seats plus synthetic gamepad IDs — no physical device. Reviewer: engineering run; no independent human review. **Verification result:** PASSED. Dated note: the draft U4 scenario example (10 s) was an arithmetic slip; the approved rule text gives 7 s and is what is implemented and tested.


#### P12-T05

- [x] **Integrate and expose the Karera + Lagsanay pair**
  - **Status:** PASSED — automated synthetic evidence (2026-10-15) · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-STACK-001](PRD.md#req-stack-001--integrate-karera-with-lagsanay-pressure). **Dependencies:** [P08-T06](#p08-t06), [P06-T02](#p06-t02), [P06-T08](#p06-t08).
  - **Work:** Flag remains active, bodies pass through, tag sensor works. Finishers become secured and leave taya/target/hazard eligibility. Finishing taya transfers to random unfinished live runner or resolves if none. Prototype reassignment preserves remaining countdown and gives no new opening freeze. Use race-only scoring/suppression and optional Barya.
  - **Acceptance:** 2/3/4 players: current taya finishes, last live runner finishes/dies, secured exclusion, timeout/goal conflict and direct trap awards; no placement score added.
  - **Implementation:** `BombTayaTwist` (`scripts/match/bomb_taya_twist.gd`) runs the taya pressure beside the race in `P12ScheduledMatchRoom`. It uses the P08 timers, head start and pass-back immunity; the opening taya is seeded from the `taya` stream.
    - It steps before the race drains each physics step, and reports a timeout to the race ledger as a source-less elimination (no Patibong).
    - Finishers are secured and leave the taya pool. A finishing taya hands the taya to a random live runner with the countdown kept and no freeze; an eliminated taya is replaced with the timer for the new live count.
    - The race keeps the flag, the deadlines, the round end and race-only scoring.
    - The HUD shows "TWIST: BOMB-TAYA", the taya and its countdown; the taya marker floats over the taya.
    - The Karera + Lagsanay compatibility row is now enabled, so Karera rounds from round 5 can roll this Twist.
    - Two rules are provisional and listed in the T03 draft: one live runner keeps the 2-player timer, and same-step trap + timeout follows the race ledger's ambiguous-cause rule.
  - **Evidence:** [P12 evidence index](evidence/p12/README.md); [stack tests](evidence/p12/2026-10-15_p12_stack_tests.txt) (47 checks). **Verification result:** PASSED — see P12-T06.


#### P12-T06

- [x] **Verify integrate karera with lagsanay pressure**
  - **Status:** PASSED — automated synthetic evidence (2026-10-15) · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-STACK-001](PRD.md#req-stack-001--integrate-karera-with-lagsanay-pressure). **Dependencies:** [P12-T05](#p12-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. 2/3/4 players: current taya finishes, last live runner finishes/dies, secured exclusion, timeout/goal conflict and direct trap awards; no placement score added.
  - **Acceptance:** 2/3/4 players: current taya finishes, last live runner finishes/dies, secured exclusion, timeout/goal conflict and direct trap awards; no placement score added.
  - **Procedure:** `godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_p12_stack_tests.gd` (Godot 4.7, synthetic seats), plus the Twist rounds inside the full 12-round matches of `run_p12_tests.gd`. Expected and actual results:
    - **Controller:** no pass during the head start; nearest-runner pass; pass-back immunity; the countdown is never reset by a pass; secured runners are never targets; the countdown is kept when the taya finishes; a fresh timer after an elimination; one recorded timeout; idle when no runner is left.
    - **2, 3 and 4 seats in the real room:**
      - The taya reaches the flag, is secured, and the taya moves to a live runner with the remaining countdown and no freeze.
      - The finisher standing on the new taya for 30 steps is never tagged back.
      - Timeouts are race eliminations with no Patibong.
      - The last live runner carries the taya and can still finish (3/4 players) or time out (2 players); the race then ends.
      - Totals equal the race calculator alone, with no Lagsanay placement points.
    - **Timeout and goal in the same step:** eliminated.
    - **Spike kill during the Twist (3 and 4 seats):** a direct kill credited to the placer, who keeps the race Patibong; a trapped taya is replaced.
    - **Full matches:** each player count's 12-round match includes a Bomb-Taya round.
    - **Capture:** a rendered capture of a 4-seat Twist round.
  - **Evidence:** [P12 evidence index](evidence/p12/README.md). **Verification result:** PASSED (47 + 61 checks, 0 failures). Reviewer: Claude (AI, automated). No player session, physical device or human review; the provisional rows in the T03 draft still need team approval.


#### P12-T07

- [x] **Integrate the Karera + Kangaroo pair**
  - **Status:** PASSED — automated synthetic evidence (2026-10-15) · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-STACK-002](PRD.md#req-stack-002--integrate-karera-with-kangaroo-pressure). **Dependencies:** [P11-T12](#p11-t12), [P12-T04](#p12-t04), [P06-T02](#p06-t02).
  - **Work:** Karera controls round end and scoring. Kangaroo third failure eliminates unfinished runners; secured finishers receive no commands/hazards. Flag and optional Barya stay available; command failure gives no Patibong and no extra score table.
  - **Acceptance:** 2/3/4 players complete all commands under race deadlines; secured finishers never gain markers, failed runners cannot finish later, race suppression and terminal ordering hold.
  - **Evidence:** Karera Main + Kangaroo Twist: `KangarooRoundController` runs with `twist_role` (no round end, no Storm, `secure_seat`/`mark_externally_eliminated`, last unfinished runner keeps receiving Freeze/Rising); `P12ScheduledMatchRoom` steps it after support finalisation and before the race ledger drains and forwards its eliminations (cause `command_failure`/`direct_hazard`) as ledger candidates, so Karera owns the end and the one race score and a command failure is never Patibong. The `EventSchedule` row is enabled. Barya was not enabled during this historical P12-T08 verification; its later implementation is tracked under P19. **Verification result:** PASSED — see P12-T08.


#### P12-T08

- [x] **Verify integrate karera with kangaroo pressure**
  - **Status:** PASSED — 2/3/4 seats, synthetic (2026-10-15) · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-STACK-002](PRD.md#req-stack-002--integrate-karera-with-kangaroo-pressure). **Dependencies:** [P12-T07](#p12-t07).
  - **Work:** Record the procedure, expected and actual result, and review evidence. 2/3/4 players complete all commands under race deadlines; secured finishers never gain markers, failed runners cannot finish later, race suppression and terminal ordering hold.
  - **Acceptance:** 2/3/4 players complete all commands under race deadlines; secured finishers never gain markers, failed runners cannot finish later, race suppression and terminal ordering hold.
  - **Evidence:** At 2, 3 and 4 seats: commands complete under the race deadlines, a secured finisher never gains a marker and leaves command eligibility, a failed runner cannot finish later, nobody finishing gives no points and a visible reason, goal + third failure on one step eliminates (U6), scores equal the race calculator alone. Rendered: [K+Kg play](evidence/p12/p12_kk_play_4p.png), [K+Kg result](evidence/p12/p12_kk_result_4p.png). Procedure: `Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path tilaok! --script res://tests/run_p12_pairs_tests.gd` (real physics, deterministic scripted synthetic inputs; forced locked entries are test-only). Build: Godot 4.7.2.stable on `origin/main` `ef78950` plus the P12 pairs change set; seed 12345. Input type: synthetic K1/K2 keyboard seats plus synthetic gamepad IDs — no physical device. Reviewer: engineering run; no independent human review. **Verification result:** PASSED.


#### P12-T09

- [x] **Integrate the Kangaroo + Lagsanay pair**
  - **Status:** PASSED — automated synthetic evidence (2026-10-15) · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-STACK-003](PRD.md#req-stack-003--integrate-kangaroo-with-lagsanay-pressure). **Dependencies:** [P11-T12](#p11-t12), [P12-T04](#p12-t04), [P08-T06](#p08-t06).
  - **Work:** Kangaroo is Main; Bomb-Taya passes/counts continuously including Freeze. Either third failure, timeout or trap can eliminate; last survivor wins with Lagsanay placement family only. R4 pausing the taya countdown during Freeze remains inactive.
  - **Acceptance:** 2/3/4 players exercise low-countdown Freeze, tag during forced movement, multiple terminal causes, Storm and Last Cluck; one award table and continuous taya time.
  - **Evidence:** Kangaroo Main + Bomb-Taya Twist: the taya timeout is fed to Kangaroo as an elimination with its comparable time before Kangaroo's batch (order command failure, timeout, trap), then `BombTayaTwist` runs on the survivors so an eliminated taya or pass target is settled before the tag pass; placement family only. The `EventSchedule` row is enabled. **Verification result:** PASSED — see P12-T10.


#### P12-T10

- [x] **Verify integrate kangaroo with lagsanay pressure**
  - **Status:** PASSED — 2/3/4 seats, synthetic (2026-10-15) · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-STACK-003](PRD.md#req-stack-003--integrate-kangaroo-with-lagsanay-pressure). **Dependencies:** [P12-T09](#p12-t09).
  - **Work:** Record the procedure, expected and actual result, and review evidence. 2/3/4 players exercise low-countdown Freeze, tag during forced movement, multiple terminal causes, Storm and Last Cluck; one award table and continuous taya time.
  - **Acceptance:** 2/3/4 players exercise low-countdown Freeze, tag during forced movement, multiple terminal causes, Storm and Last Cluck; one award table and continuous taya time.
  - **Evidence:** At 2, 3 and 4 seats: the taya countdown keeps running through a Freeze and a low countdown still eliminates (R4 inactive), timeout + trap in one step stay one outcome per player, Storm with two survivors, Last Cluck on an all-eliminated step, one placement table (no Tapos/Una/Bayani), flag hidden. Rendered: [Kg+L play](evidence/p12/p12_gl_play_4p.png), [Kg+L result](evidence/p12/p12_gl_result_4p.png). Procedure: `Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path tilaok! --script res://tests/run_p12_pairs_tests.gd` (real physics, deterministic scripted synthetic inputs; forced locked entries are test-only). Build: Godot 4.7.2.stable on `origin/main` `ef78950` plus the P12 pairs change set; seed 12345. Input type: synthetic K1/K2 keyboard seats plus synthetic gamepad IDs — no physical device. Reviewer: engineering run; no independent human review. **Verification result:** PASSED.


## P13 — Complete UX and onboarding

**Goal / player-visible result:** New players can learn, navigate, read results and browse enabled content.

**Milestone / scope:** Feature-complete submission, then release/submission.

**Entry:** Basic UI begins in P05; final pass uses P09–P12 behaviors.

**External task dependencies:** [P02-T04](#p02-t04), [P02-T08](#p02-t08), [P05-T02](#p05-t02), [P08-T06](#p08-t06), [P09-T04](#p09-t04), [P12-T02](#p12-t02), [P12-T08](#p12-t08), [P12-T10](#p12-t10)

**Owner roles:** Art/UI; person names TBD. **Systems touched:** NEW menu/settings/Library/tutorial/HUD components.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Every route/HUD/help/Library/tutorial/accessibility scenario passes.

**Evidence required:** Navigation matrix, novice sessions, muted/shake-off minimum-zoom evidence.

**Entry-gate disposition — October 15, 2026:** The project owner answered the P13 Stage A decisions in chat. **D1 (b):** a provisional, development-only dependency override for P13 in the P08 style: P13 tasks may be checked against their own acceptance while [P02-T08](#p02-t08) (two identical physical gamepads) stays unchecked and formal release eligibility stays unresolved. **D1b:** [P13-T02](#p13-t02) stays unchecked because its acceptance names physical gamepad traversal; [P13-T06](#p13-t06) may be checked as "PASSED — synthetic, physical devices COULD-NOT-RUN". **D2:** the owner will run the physical keyboard chord matrix; [P02-T03](#p02-t03)/[P02-T04](#p02-t04) and [P13-T11](#p13-t11)/[P13-T12](#p13-t12) wait for that session. **D3:** [P13-T03](#p13-t03), [P13-T07](#p13-t07) and [P13-T09](#p13-t09) are checked technically with a dated waiver of their human-session dependencies ([P13-T04](#p13-t04), [P13-T08](#p13-t08)); the human VERIFY tasks T04, T08 and T10 stay unchecked until a real person does the session from the [PLAYTEST sheets](PLAYTEST.md#p13-ux-onboarding-and-accessibility--october-15-2026). The override does not satisfy, edit or remove P02-T04, P02-T08, P13-T04, P13-T08 or P13-T10 acceptance; no human or physical-device result is inferred from synthetic tests.

**P13 roll-up — October 17, 2026: 11/18 task records checked (T01, T03, T05, T06, T07, T09, T13, T14 and the reference restyle T15, T16, T17); the P13 exit criteria are NOT MET.** Open: T02, T04, T08, T10, T11, T12 (below) and T18 (human visual review of the restyle and a physical keyboard/gamepad pass, [PLAYTEST Sheet G](PLAYTEST.md#sheet-g--p13-t18-reference-restyle-review)). Restyle evidence: [ui-reference](evidence/ui-reference/README.md).

**P13 roll-up — October 15, 2026 (history): 8/14 task records checked (T01, T03, T05, T06, T07, T09, T13, T14); the P13 exit criteria are NOT MET.** Open: T02 (physical gamepads), T04 (spectators), T08 (novice), T10 (QA readability), T11 (P02-T04 physical keyboard session) and T12 (cheer verification). On the scheduled full match (now the default route, owner decision D4): every menu route, Library-from-Pause return context, the live HUD cue table, a real Library with enabled-content filtering, Kangaroo / Bomb-Taya just-in-time prompts, audio buses with Mute, Screen shake that reaches the match, a ≤ 2 Hz stun pulse, the spectator cheer and the keyboard chord recorder are implemented and covered by 1,040 new synthetic checks (navigation 205, HUD 264, Library 352, tutorial 55, accessibility 65, cheer 39, recorder 60) with every pre-existing suite unchanged. Evidence index: [P13 evidence](evidence/p13/README.md).


#### P13-T01

- [x] **Complete all menu routes and settings controls**
  - **Status:** DONE (technical) — synthetic K1/K2/gamepad; P02-T08 dependency override (2026-10-15) · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-UI-002](PRD.md#req-ui-002--complete-title-menus-settings-and-navigation). **Dependencies:** [P09-T04](#p09-t04), [P02-T08](#p02-t08).
  - **Work:** Title offers local match, Library, settings and quit; lobby offers ready/leave/help; pause offers help/Library/settings/resume and confirmed return to lobby. Results offer replay/lobby. Menu ownership follows prototype pause rules. Development builds expose a build label, never internal seeds on player HUD.
  - **Acceptance:** Gamepad and keyboard traverse every screen/back/quit route without traps or accidental game input; opening Library from pause keeps simulation paused and preserves return context.
  - **Evidence:** [P13 evidence](evidence/p13/README.md); `tilaok!/scripts/flow/game_flow.gd`, `scripts/match/match_screen_presenter.gd`, `scripts/input/local_input_router.gd`, `scripts/ui/ui_lobby_screen.gd`, `scripts/ui/ui_settings_screen.gd`, `scripts/config/presentation_applier.gd`, `default_bus_layout.tres`; [navigation test log](evidence/p13/test_logs/run_p13_navigation_tests.txt) (205 checks, 0 failures). **Procedure / expected / actual:** `Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path tilaok! --script res://tests/run_p13_navigation_tests.gd` walks Title, Library, Settings, Quit confirm, Lobby (ready, help, Back, confirm), Pause (owner and non-owner), Library and Settings from Pause, leave confirm and Quit with K1, K2 and a synthetic gamepad on the first-playable and the scheduled route; **expected:** no trap, no stray game input, held presses consumed on every swap, simulation frozen under every overlay and the same Pause row on return; **actual:** all 205 checks passed. Build: `origin/main` `1d058e2` plus the P13 change set; Godot 4.7.2.stable.official.ed1daf0bf; Windows 11; 2026-10-15; profile `karera_slice`, seed 12345; 2 and 4 seats; synthetic K1/K2 keyboard seats and synthetic gamepad IDs 7101/7102 (no physical device); reviewer: engineering run (AI-assisted), no human reviewer. **Verification result:** PASSED (technical, synthetic); physical gamepad traversal is COULD-NOT-RUN and stays with P13-T02/P02-T08.
  - **UI shell note (2026-10-14, IN PROGRESS, no checkbox change):** scene-based placeholder shells for Title, Lobby, Pause/Reconnect and Settings (`title_screen`, `lobby_screen`, `pause_screen`, `settings_screen`) exist under `tilaok!/scenes/ui/` and are reviewable in the UI Gallery harness room (SAMPLE data, PLACEHOLDER theme, evidence `docs/evidence/ui-shells/`). Remaining: live route wiring, quit/return flow in a player build, Library-from-pause context preservation, gamepad/keyboard route matrix on physical devices, final art.
  - **Live wiring note (2026-10-14, IN PROGRESS, no checkbox change):** `scenes/flow/game_flow.tscn` is now the main scene. Title (join prompt, build label, Start / Library / Settings / Quit-with-confirmation), Lobby (Back to Title), Pause / Reconnect (owner-only menu, Resume, Settings / Library with the simulation still paused, Leave with confirmation) and the Library / Settings shells are driven by live seat, pause and router data; evidence `docs/evidence/match-ui/`, procedure and limits in `README.md` there. The P09 Match result screen, its Replay / Return to Lobby / Quit actions and the shared leave / quit confirmation are shown by the presenter on the opt-in lifecycle route (the P08 and P09 development rooms no longer build their own panels). Still open: making the lifecycle route the default player route (a product decision), P02-T08 physical gamepad / keyboard route matrix, the Library from Pause "return context" on physical devices, per-seat leave (the seat registry has no leave API) and final art.
  - **Completion note (2026-10-15):** Lobby offers ready / help (the Rotate control opens the Library; Back returns to the Lobby) / leave (Back asks first once a seat is ready); Library and Settings from Pause keep the tree paused and return to the exact Pause row, and cannot open during the resume countdown; Quit from the match result goes through `GameFlow`; Back on the Title asks before quitting; the left stick steps menus outside Play like the D-pad; every screen swap consumes held presses; Settings gained a Sound (Mute) row and its Master / Music / Effects / Crowd sliders drive real buses (session only); the build label never shows a seed and the HUD shows no internal ids. The scheduled full match is the default route (`--match-route=first_playable` keeps the P07 gate build). Per-seat leave is not added: leaving stays whole-group with confirmation (PROTOTYPE_DEFAULTS §3).

#### P13-T02

- [ ] **Verify complete title, menus, settings and navigation**
  - **Status:** IN PROGRESS — synthetic matrix PASSED; physical gamepad part COULD-NOT-RUN (D1b, 2026-10-15) · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-UI-002](PRD.md#req-ui-002--complete-title-menus-settings-and-navigation). **Dependencies:** [P13-T01](#p13-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Gamepad and keyboard traverse every screen/back/quit route without traps or accidental game input; opening Library from pause keeps simulation paused and preserves return context.
  - **Acceptance:** Gamepad and keyboard traverse every screen/back/quit route without traps or accidental game input; opening Library from pause keeps simulation paused and preserves return context.
  - **Evidence:** synthetic matrix only: [navigation test log](evidence/p13/test_logs/run_p13_navigation_tests.txt) (205 checks, 0 failures), [P13 evidence](evidence/p13/README.md). **Procedure / expected / actual:** as P13-T01 with synthetic gamepad events; the physical matrix is [PLAYTEST Sheet B](PLAYTEST.md#sheet-b--p13-t02-physical-navigation-matrix) (two identical gamepads plus K1/K2). **Verification result:** COULD-NOT-RUN for the physical-device part — no gamepads are available; synthetic input is not physical-device evidence. **Reviewer:** engineering run; no human reviewer. **Next action:** run Sheet B once two identical gamepads exist (with P02-T07/T08).


#### P13-T03

- [x] **Complete HUD, result explanations and event overlays**
  - **Status:** DONE (technical) — owner waiver of the T04 human dependency (D3, 2026-10-15) · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-UI-003](PRD.md#req-ui-003--explain-current-play-and-results-in-the-hud). **Dependencies:** [P12-T02](#p12-t02), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Show round/Main Challenge, subordinate TWIST label, exact score totals, relevant deadlines, number/shape, alive/secured/eliminated/taya state, KANG→GA→ROO and enabled Barya carrier. Explain suppressed awards, Last Cluck and next-round selection. No internal IDs/collision shapes/seeds.
  - **Acceptance:** Spectators identify phase, objective, leader, taya, winner and no-score reason; overlapping command rings stay distinct at minimum zoom and with sound/shake off.
  - **Evidence:** [P13 evidence](evidence/p13/README.md); [HUD test log](evidence/p13/test_logs/run_p13_hud_tests.txt) (264 checks, 0 failures); rendered captures under [captures](evidence/p13/captures/) (HUD per mode and stack at 1920×1080, 1280×720 and 1920×800, 2 and 4 seats, round results with Last Cluck, final result, cheer). **Procedure / expected / actual:** `run_p13_hud_tests.gd` opens the scheduled room at 2 and 4 seats for Karera, Lagsanay, Kangaroo, Karera + Bomb-Taya, Karera + Kangaroo and Kangaroo + Bomb-Taya and binds every Work-line cue to live room state; **expected:** each cue present as text/shape, text at or above the theme minimum, no internal ids / seeds / DEBUG, HUD inside the 64 px reservation and screen width, Kangaroo cards below any notice and never overlapping, result footer on screen; **actual:** all 264 historical pre-Barya checks passed and asserted Barya N/A; current Barya-integrated HUD verification is 265 checks ([Barya evidence](evidence/barya/README.md)). Build: `origin/main` `1d058e2` plus the P13 change set; Godot 4.7.2.stable.official.ed1daf0bf; Windows 11; 2026-10-15; profile `karera_slice`, seed 12345; 2 and 4 seats; synthetic K1/K2 keyboard seats and synthetic gamepad IDs 7101/7102 (no physical device); reviewer: engineering run (AI-assisted), no human reviewer. **Verification result:** PASSED (technical); spectator identification is P13-T04 and is not claimed.
  - **UI shell note (2026-10-14, IN PROGRESS, no checkbox change):** scene-based placeholder shells for the Play HUD, Round/Match result and event placeholders (`play_hud`, `round_result_screen`, `match_result_screen`, `events_overlay`) exist under `tilaok!/scenes/ui/` and are reviewable in the UI Gallery harness room (SAMPLE data, PLACEHOLDER theme, evidence `docs/evidence/ui-shells/`). Remaining: live scores/awards/taya/Kangaroo data from P06–P12, Last Cluck and no-score reasons from real modes, final art.
  - **Live wiring note (2026-10-14, IN PROGRESS, no checkbox change):** the Play HUD, Place overlay, Pugad overlay and Round result screen are bound to live P05/P06 data (exact eighth-point totals through `ScoreFormat`, plain-language award names, the scoring / no-score reason every round, end-reason and deadline text, per-seat RUN / SECURED / OUT). The P08 lab and P09 sudden death use the same HUD for the Lagsanay countdown, taya tag / state and pass-back notice, and the P09 Match result screen shows Last Cluck. The 2026-10-15 rule update suppresses ordinary awards in two-player all-finish rounds while still paying eligible Barya. Still open: TWIST label, KANG→GA→ROO, Barya carrier and next-event announcements (P11 / P12), the Lagsanay event round inside the Karera flow, event overlays, spectator identification evidence and final art.
  - **Completion note (2026-10-15):** `NextEventLabel` keeps its historical name and the live tag; the locked next-round selection shows in the new `UpNextLabel` ("NEXT R6 KANGAROO + BOMB-TAYA", "FINAL ROUND"); the bar is two lines per side so four seats fit; the Kangaroo readout is the scene-authored `kangaroo_hud.tscn` (command cards with icon, name, GET READY / NOW and ring; a KANG → GA → ROO grid) replacing the code-built DEBUG overlay on the scheduled route (the P11 lab keeps its own); the score row reads `MISS n/3` and `CHEER!`; the Round result gained `LastCluckCallout`, `TwistLine` and `NextRoundLabel`; the chart now reserves room for two-line statuses. Open findings (human review): at minimum zoom Storm cards can cover a chicken's label at the upper right; the symbol glyphs `● ▲ ■ ◆ → ↑ ↔` come from a system fallback font ([findings](evidence/p13/README.md#findings-that-need-people-or-a-decision)).

#### P13-T04

- [ ] **Verify explain current play and results in the hud**
  - **Status:** COULD-NOT-RUN — needs real spectators · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-UI-003](PRD.md#req-ui-003--explain-current-play-and-results-in-the-hud). **Dependencies:** [P13-T03](#p13-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Spectators identify phase, objective, leader, taya, winner and no-score reason; overlapping command rings stay distinct at minimum zoom and with sound/shake off.
  - **Acceptance:** Spectators identify phase, objective, leader, taya, winner and no-score reason; overlapping command rings stay distinct at minimum zoom and with sound/shake off.
  - **Evidence:** not yet available (instrument ready: [PLAYTEST Sheet C](PLAYTEST.md#sheet-c--p13-t04-spectator-identification)). **Verification result:** COULD-NOT-RUN — a person must watch the screen (sound muted, Screen shake Off, minimum zoom) and name phase, objective, leader, taya, winner and no-score reason; agent screenshot inspection is not a spectator result. **Next action:** run Sheet C with at least three non-playing observers.


#### P13-T05

- [x] **Implement Library navigation, content filtering and entry template**
  - **Status:** DONE (technical) — P13-T02 dependency covered by the D1 override (2026-10-15) · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P13-T02](#p13-t02), [P05-T02](#p05-t02).
  - **Work:** Library is reachable from title, lobby and pause/settings. Categories: How to Play, Karera, Lagsanay, Kangaroo, Items, Accessibility. Include controls/scoring, all enabled variants, looping animation, placement guides, tell/counterplay and compatible event behavior. Backlog appears only in marked development/reference mode.
  - **Acceptance:** Every enabled family/variant/event has a readable entry and controller-operable category/back navigation; disabled content is absent from release browsing; Pugad remains visual-only.
  - **Evidence:** [P13 evidence](evidence/p13/README.md); [Library test log](evidence/p13/test_logs/run_p13_library_tests.txt) (352 checks, 0 failures); `tilaok!/data/ui/library_text.tres`, `scripts/ui/ui_library_screen.gd`, `scripts/ui/ui_library_text.gd`, `scripts/ui/ui_library_page.gd`; captures `*_library_*.png`. **Procedure / expected / actual:** `run_p13_library_tests.gd` builds the Library from the live item definitions and tuning; **expected:** a page set per category with the PLACEHOLDER tag and numbers from tuning, one reachable entry per enabled family with every enabled size animated in turn, controls for all device kinds, stack and mode pages absent unless enabled, no disabled family, reference content only with `--library-dev`, gamepad category / entry / back navigation, Pugad free of item names; **actual:** all 352 checks passed. Build: `origin/main` `1d058e2` plus the P13 change set; Godot 4.7.2.stable.official.ed1daf0bf; Windows 11; 2026-10-15; profile `karera_slice`, seed 12345; 2 and 4 seats; synthetic K1/K2 keyboard seats and synthetic gamepad IDs 7101/7102 (no physical device); reviewer: engineering run (AI-assisted), no human reviewer. **Verification result:** PASSED (technical).
  - **UI shell note (2026-10-14, IN PROGRESS, no checkbox change):** scene-based placeholder shells for the Library shell (`library_screen`) exist under `tilaok!/scenes/ui/` and are reviewable in the UI Gallery harness room (SAMPLE data, PLACEHOLDER theme, evidence `docs/evidence/ui-shells/`). Remaining: all categories need real reviewed content; only Items is live from `ItemLibraryEntry`; controller-operable audit and release-content filtering evidence.
  - **Tutorial note (2026-10-14, IN PROGRESS, no checkbox change):** the How to Play page now has real (PLACEHOLDER, unreviewed) copy and a "Replay tutorial" entry that clears the session set; the other non-Items categories remain SAMPLE text. The Library is still not reachable from the Lobby. Controller-operable audit and human review remain.
  - **Completion note (2026-10-15):** categories How to Play, Karera, Lagsanay, Kangaroo, Items and Accessibility are reachable from the Title, the Lobby (Rotate control) and Pause; copy is English PLACEHOLDER written from GDD / ITEMS / PRD and describes implemented behaviour only (including both Twist stacks); Karera, Lagsanay and Kangaroo pages name the Twist rules and the Last Cluck rule. "Release browsing" means *content enabled by the active play profile*: every family currently has `release_target = false`, so a literal release filter would list nothing (the dev-mode toggle keeps that behaviour). Backlog designs in ITEMS.md have no data definitions, so reference mode lists only lab-catalog families that are not in this build's Pugad. Human copy review and final art remain open.

#### P13-T06

- [x] **Verify provide enabled-content library and animated entries**
  - **Status:** PASSED — synthetic; physical devices COULD-NOT-RUN (D1b, 2026-10-15) · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P13-T05](#p13-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Every enabled family/variant/event has a readable entry and controller-operable category/back navigation; disabled content is absent from release browsing; Pugad remains visual-only.
  - **Acceptance:** Every enabled family/variant/event has a readable entry and controller-operable category/back navigation; disabled content is absent from release browsing; Pugad remains visual-only.
  - **Evidence:** [P13 evidence](evidence/p13/README.md); [Library test log](evidence/p13/test_logs/run_p13_library_tests.txt) (352 checks, 0 failures) including a synthetic gamepad that opens the Library from the Title, steps every category, enters and leaves the entry list and backs out; captures `*_library_*.png`. **Procedure / expected / actual:** as P13-T05; **expected:** every enabled family/variant/event has a readable entry and category / back navigation works from a controller; disabled content absent from release browsing; Pugad visual-only; **actual:** passed. Build: `origin/main` `1d058e2` plus the P13 change set; Godot 4.7.2.stable.official.ed1daf0bf; Windows 11; 2026-10-15; profile `karera_slice`, seed 12345; 2 and 4 seats; synthetic K1/K2 keyboard seats and synthetic gamepad IDs 7101/7102 (no physical device); reviewer: engineering run (AI-assisted), no human reviewer. **Verification result:** PASSED (synthetic). Physical-controller Library operation is COULD-NOT-RUN (P13-T02 Sheet B step 2).


#### P13-T07

- [x] **Complete guided tutorial and just-in-time event instruction**
  - **Status:** DONE (technical) — owner waiver of the T04 / T08 human dependencies (D3, 2026-10-15) · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-TUTORIAL-001](PRD.md#req-tutorial-001--teach-the-first-round-and-later-event-rules). **Dependencies:** [P13-T06](#p13-t06), [P13-T04](#p13-t04).
  - **Work:** Guided first Karera teaches identity, move/jump, visible-item selection, claim timeout, place/rotate/validity/confirm, flag and actual results. Prompts are skippable after completion in current session; replayable help remains. First Lagsanay teaches taya/pass/timer/last survivor; first Kangaroo teaches poses, three misses and built supports.
  - **Acceptance:** A novice follows the guided loop and explains objective/input/placement; record each facilitator intervention. Session skip and help replay work; no tutorial bonus or disk completion save is invented.
  - **Evidence:** [P13 evidence](evidence/p13/README.md); [tutorial test log](evidence/p13/test_logs/run_p13_tutorial_tests.txt) (55 checks, 0 failures) plus the unchanged guided-match suites ([140 + 48 checks](evidence/tutorial/README.md)); `tilaok!/data/ui/tutorial_script.tres`, `scripts/tutorial/`. **Procedure / expected / actual:** `run_p13_tutorial_tests.gd` plays the scheduled route with forced schedule entries; **expected:** poses prompt in the Pugad and built-support prompt in the Place of the round before (or of) the first Kangaroo Main or Twist, the three-misses prompt once its commands run, each once per session, the taya prompt (Twist wording) first and handing over to Kangaroo on a stacked round, skip hides everything, replay restores it, the guided match keeps its own steps, no disk I/O; **actual:** all 55 checks passed. Build: `origin/main` `1d058e2` plus the P13 change set; Godot 4.7.2.stable.official.ed1daf0bf; Windows 11; 2026-10-15; profile `karera_slice`, seed 12345; 2 and 4 seats; synthetic K1/K2 keyboard seats and synthetic gamepad IDs 7101/7102 (no physical device); reviewer: engineering run (AI-assisted), no human reviewer. **Verification result:** PASSED (technical); a novice's comprehension is P13-T08 and is not claimed.
  - **UI shell note (2026-10-14, IN PROGRESS, no checkbox change):** scene-based placeholder shells for the Tutorial prompt box (`tutorial_prompt`) exist under `tilaok!/scenes/ui/` and are reviewable in the UI Gallery harness room (SAMPLE data, PLACEHOLDER theme, evidence `docs/evidence/ui-shells/`). Remaining: the guided first Karera script, skip/replay logic and novice sessions are not implemented.
  - **Guided-match note (2026-10-14, IN PROGRESS, no checkbox change):** the guided first match is implemented with PLACEHOLDER English copy: `TutorialCoordinator` (Lobby welcome with each seat's number and shape, Pugad claim / lost / timeout, Place with a BUILD HERE zone marker, Karera, Results text from the real result including "everyone / nobody finished"), a tutorial-only stage in which a built piece is required to reach the flag (every mode of that match shares the stage), a stronger retry hint, Pause > Skip tutorial, Library > How to Play > Replay tutorial, session-only memory (nothing written) and a once-per-session Lagsanay prompt (lifecycle route only). The 2026-10-15 rule update removes the two-player waiver and explains that Barya still pays in an all-finish round. Evidence: [tutorial evidence](evidence/tutorial/README.md) is historical for the earlier rule; current synthetic checks are in [all-finish Barya correction](evidence/p06/2026-10-15_all_finish_barya_correction.md). Remaining, so the box stays unchecked: no novice session has run, the copy is unreviewed, and the wall-slide practice cue is not added.
  - **Completion note (2026-10-15):** first Kangaroo prompts added (poses, built supports, three misses), triggered by a Kangaroo Main or Twist; a Bomb-Taya Twist now teaches the taya rules (it could not trigger the Lagsanay prompt before); the taya prompt hands the stage back after 12 s so it never covers the chickens for a whole round. The wall-slide practice cue remains a later Should extension. Copy is PLACEHOLDER and unreviewed; session skip and replay are session-only (nothing written to disk, no tutorial bonus).
  - **Tutorial copy fix (2026-10-16, no checkbox change):** when a Barya egg was dealt, the Pugad coach showed only the Barya note and hid the claim key, the timer and the claimed/lost feedback (3 failures in `run_tutorial_tests.gd` since the Barya work). Claim feedback now takes priority, and the Barya note repeats the claim key and timer (`TutorialCoordinator._pugad_variant`, `data/ui/tutorial_script.tres`). `run_tutorial_tests.gd` 142/142 and `run_p13_tutorial_tests.gd` 58/58; [stabilization evidence](evidence/stabilization/README.md). The copy is still PLACEHOLDER English awaiting UI/cultural review.

#### P13-T08

- [ ] **Verify teach the first round and later event rules**
  - **Status:** COULD-NOT-RUN — needs a real novice · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-TUTORIAL-001](PRD.md#req-tutorial-001--teach-the-first-round-and-later-event-rules). **Dependencies:** [P13-T07](#p13-t07).
  - **Work:** Record the procedure, expected and actual result, and review evidence. A novice follows the guided loop and explains objective/input/placement; record each facilitator intervention. Session skip and help replay work; no tutorial bonus or disk completion save is invented.
  - **Acceptance:** A novice follows the guided loop and explains objective/input/placement; record each facilitator intervention. Session skip and help replay work; no tutorial bonus or disk completion save is invented.
  - **Evidence:** not yet available (instrument ready and extended for Kangaroo and Bomb-Taya: [PLAYTEST novice sheet](PLAYTEST.md#p13-t08-novice-session-sheet--guided-first-match-2026-10-14) and [Sheet D](PLAYTEST.md#sheet-d--p13-t08-novice-session-guided-first-match-lagsanay-and-kangaroo)). **Verification result:** COULD-NOT-RUN — a facilitator must run a novice with an intervention log. **Next action:** run Sheet D (`-- --match-seed=3` reaches Kangaroo in round 6).
  - **Sheet note (2026-10-14, IN PROGRESS, no checkbox change):** the novice-session sheet and intervention log are ready in [PLAYTEST.md](PLAYTEST.md#p13-t08-novice-session-sheet--guided-first-match-2026-10-14); no human session has been run or is claimed.


#### P13-T09

- [x] **Implement and audit accessibility and readability controls**
  - **Status:** DONE (technical) — owner waiver of the T04 / T08 human dependencies (D3, 2026-10-15) · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ACCESS-001](PRD.md#req-access-001--maintain-color-independent-readable-play). **Dependencies:** [P13-T04](#p13-t04), [P13-T08](#p13-t08).
  - **Work:** Player identity, placement validity, taya, hazards, wave support and coin never depend on color alone. Use redundant silhouette/icon/text/motion/audio; no rapid flashing. Full/reduced/off shake. Critical cues remain understandable muted. Review minimum camera zoom, safe areas, needed language glyphs and supported resolutions.
  - **Acceptance:** QA captures minimum-zoom crowded stage with muted audio and shake off; identifies every critical cue and all four players. Check Parol overlap/readability and no strobe; document supported display/device limits.
  - **Evidence:** [P13 evidence](evidence/p13/README.md); [accessibility test log](evidence/p13/test_logs/run_p13_accessibility_tests.txt) (65 checks, 0 failures); rendered muted + shake-off minimum-zoom crowded 4-seat stage ([capture](evidence/p13/captures/1920x1080_4p_crowded_min_zoom_muted_shake_off.png)), Parol overlap ([capture](evidence/p13/captures/1920x1080_2p_parol_overlap_min_zoom.png)) and the rendered strobe measurement ([report](evidence/p13/capture_report.txt)). **Procedure / expected / actual:** shake Full / Reduced / Off is applied through the Settings object to the Kangaroo cue camera shake and the crumble jitter; Master / Music / Effects / Crowd sliders and Mute drive real buses; every sound-bearing family has a visual slot and a written tell and each Kangaroo cue has an on-screen card; stun brightening ≤ 2 peaks/s; the Parol beam sampled over 4.5 s rendered (about 740 frames, all phases) had a largest frame step 0.018, largest swing 0.029 and 0 flashes of ≥ 10 % in any second (limit 3); Filipino letters are covered by the default font; supported displays 1280×720, 1920×1080 and 1920×800 (letterbox). Build: `origin/main` `1d058e2` plus the P13 change set; Godot 4.7.2.stable.official.ed1daf0bf; Windows 11; 2026-10-15; profile `karera_slice`, seed 12345; 2 and 4 seats; synthetic K1/K2 keyboard seats and synthetic gamepad IDs 7101/7102 (no physical device); reviewer: engineering run (AI-assisted), no human reviewer. **Verification result:** PASSED (technical); the QA identification of every cue and all four players is P13-T10 and is not claimed.
  - **UI shell note (2026-10-14, IN PROGRESS, no checkbox change):** scene-based placeholder shells for shared accessibility pieces (player badge number + shape, non-colour ghost legend, theme-constant text size and safe area) exist under `tilaok!/scenes/ui/` and are reviewable in the UI Gallery harness room (SAMPLE data, PLACEHOLDER theme, evidence `docs/evidence/ui-shells/`). Remaining: shake/muted minimum-zoom audit, Parol readability, supported-resolution documentation and human review.
  - **Completion note (2026-10-15):** Screen shake never reached the match before this work (the snapshot used a default settings object); stun brightening was an 8 Hz hard flash and is now a smooth ≤ 2 Hz pulse that is steady when shake is Off. **Documented limits:** the engine default font lacks `● ▲ ■ ◆ → ↑ ↔` (system fallback on Windows; final font is human-owned); the window is fixed 1280×720 logical with no fullscreen option; Screen shake defaults to Off; at minimum zoom Storm command cards can cover a chicken's label at the upper right (the chicken stays visible).

#### P13-T10

- [ ] **Verify maintain color-independent readable play**
  - **Status:** COULD-NOT-RUN — needs a QA reviewer · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ACCESS-001](PRD.md#req-access-001--maintain-color-independent-readable-play). **Dependencies:** [P13-T09](#p13-t09).
  - **Work:** Record the procedure, expected and actual result, and review evidence. QA captures minimum-zoom crowded stage with muted audio and shake off; identifies every critical cue and all four players. Check Parol overlap/readability and no strobe; document supported display/device limits.
  - **Acceptance:** QA captures minimum-zoom crowded stage with muted audio and shake off; identifies every critical cue and all four players. Check Parol overlap/readability and no strobe; document supported display/device limits.
  - **Evidence:** not yet available (instrument ready: [PLAYTEST Sheet E](PLAYTEST.md#sheet-e--p13-t10-qa-readability-at-minimum-zoom); candidate captures in [captures](evidence/p13/captures/) are engineering captures, not the QA result). **Verification result:** COULD-NOT-RUN — a QA reviewer must identify every critical cue and all four players with sound muted and shake Off at minimum zoom. **Next action:** run Sheet E.


#### P13-T11

- [ ] **Implement the spectator cheer action and feedback**
  - **Status:** IN PROGRESS — implemented and tested; waits on P02-T04 physical keyboard session (D2, 2026-10-15) · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-UI-004](PRD.md#req-ui-004--retain-spectator-cheer-without-gameplay-effects). **Dependencies:** [P08-T06](#p08-t06), [P02-T04](#p02-t04).
  - **Work:** Eliminated players may cheer while spectating; the assigned cheer input produces modest crowd/visual feedback without obscuring active information. Prototype cooldown is 1 s. Enhanced layered crowd/tension behavior is optional, but the basic spectator action remains part of the documented flow.
  - **Acceptance:** An eliminated player can cheer using their assigned binding; repeated input respects cooldown, never moves a player, changes score/timers, triggers commands or obscures live HUD.
  - **Evidence:** [P13 evidence](evidence/p13/README.md); [cheer test log](evidence/p13/test_logs/run_p13_cheer_tests.txt) (39 checks, 0 failures); `tilaok!/scripts/match/spectator_cheer.gd`, `match_screen_presenter.gd`, `local_input_router.gd`; capture `1920x1080_4p_cheer_cue.png`. **Procedure / expected / actual:** `run_p13_cheer_tests.gd`; **expected:** eliminated and finished seats cheer with the Rotate control (R / Right Shift / West) during Play only, live seats / Pugad / Place / pause ignored, 1 s per-seat cooldown, a HUD mark in the seat's own row (no layout growth), and a 400-press spam run identical to a no-cheer run in scores, simulation clock, positions, commands, markers and all six random streams; **actual:** all 39 checks passed. Build: `origin/main` `1d058e2` plus the P13 change set; Godot 4.7.2.stable.official.ed1daf0bf; Windows 11; 2026-10-15; profile `karera_slice`, seed 12345; 2 and 4 seats; synthetic K1/K2 keyboard seats and synthetic gamepad IDs 7101/7102 (no physical device); reviewer: engineering run (AI-assisted), no human reviewer. **Verification result:** the implementation passes synthetically; the box stays unchecked because its dependency [P02-T04](#p02-t04) (physical keyboard chord / rollover validation) is genuinely open and the owner will run it. **Next action:** run the recorder ([PLAYTEST Sheet A](PLAYTEST.md#sheet-a--p02-t03--p02-t04-physical-keyboard-chords-recorder)) and report; the cheer shares the Rotate keys already in the chord matrix (C22–C24).
  - **Design note (2026-10-15):** no new key: the existing Rotate control is context-sensitive (Lobby: help; Play: cheer; Place: rotate). The router change is additive; `SpectatorCheer` holds only cooldowns; the cue is the text `CHEER!` in the seat's own score row plus a soft code-generated placeholder on the Crowd bus (registered in [ASSETS](ASSETS.md)).

#### P13-T12

- [ ] **Verify retain spectator cheer without gameplay effects**
  - **Status:** COULD-NOT-RUN — needs P13-T11 and a real device session · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-UI-004](PRD.md#req-ui-004--retain-spectator-cheer-without-gameplay-effects). **Dependencies:** [P13-T11](#p13-t11).
  - **Work:** Record the procedure, expected and actual result, and review evidence. An eliminated player can cheer using their assigned binding; repeated input respects cooldown, never moves a player, changes score/timers, triggers commands or obscures live HUD.
  - **Acceptance:** An eliminated player can cheer using their assigned binding; repeated input respects cooldown, never moves a player, changes score/timers, triggers commands or obscures live HUD.
  - **Evidence:** synthetic checks only ([cheer test log](evidence/p13/test_logs/run_p13_cheer_tests.txt)); instrument ready: [PLAYTEST Sheet F](PLAYTEST.md#sheet-f--p13-t12-cheer-check-needs-sheet-a-first). **Verification result:** COULD-NOT-RUN — an eliminated player must cheer with their assigned physical binding. **Next action:** after Sheet A, run Sheet F.


#### P13-T13

- [x] **Implement the reusable vertical results scoreboard**
  - **Status:** DONE · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay/UI (name TBD).
  - **Requirements:** [REQ-UI-003](PRD.md#req-ui-003--explain-current-play-and-results-in-the-hud); [REQ-MATCH-002](PRD.md#req-match-002--replay-return-to-lobby-and-reset-all-match-state). **Dependencies:** [P06-T08](#p06-t08), [P09-T03](#p09-t03).
  - **Work:** Add reusable `scoreboard_chart.tscn` / `score_column.tscn`, stable seat-order columns, a shared exact-target axis, player identity/chicken markers, score/delta/status labels and labelled/glyphed award tokens. Keep a bounded presentation-only history after accepted score commits; preserve integer eighth-point totals and render unknown/evicted provenance as a neutral prior total. Reveal new rows with Normal, Reduced and Off motion settings independent from Screen shake. Share the existing chicken SpriteFrames resource with the UI without adding gameplay behavior or final art.
  - **Acceptance:** Round and match result screens bind live result models; chart segments sum exactly to each displayed total, never change scoring or winner rules, preserve stable player identity/order and show scores above the target without clipping. Repeated binds do not replay a result; early advance settles it; motion setting does not affect readiness, timeout or menu behavior.
  - **Evidence:** [scoreboard verification and screenshots](evidence/scoreboard/README.md); reusable scenes/scripts under `tilaok!/scenes/ui/components/`, `tilaok!/scripts/ui/` and presentation history under `tilaok!/scripts/match/`. Godot 4.7.2 UI, scoring and lifecycle suites pass. **Verification result:** PASSED for this scoreboard implementation slice; full P13 remains open.


#### P13-T14

- [x] **Verify the results scoreboard and responsive states**
  - **Status:** DONE · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-UI-003](PRD.md#req-ui-003--explain-current-play-and-results-in-the-hud); [REQ-MATCH-002](PRD.md#req-match-002--replay-return-to-lobby-and-reset-all-match-state). **Dependencies:** [P13-T13](#p13-t13), [P09-T04](#p09-t04).
  - **Work:** Record procedure, expected/actual results and artifacts for exact segment sums, no-score/suppression, zero awards, fractional units, repeated/dead-owner awards, duplicate commits/binds, replay reset, noncontiguous seats, equal/tied scores, round-12 and sudden-death winners, above-target scores, resize/reveal, early advance and teardown. Capture rendered 2/3/4-seat, mid-reveal/settled, reduced-motion, final-result and no-score fixtures at 1280×720, 1920×1080 and 1920×800. Run UI/scoring/lifecycle/mode regressions, Godot 4.7.2 import/parse, formatter/lint, Windows export smoke and `git diff --check`.
  - **Acceptance:** All automated checks pass; captures use the requested exact viewport sizes and show no clipping/overlap at 1280×720; the target line stays exact and tied winners are called out without artificial bar height. Evidence distinguishes rendered synthetic fixtures from human or physical-device review.
  - **Evidence:** [test log, GUI captures and Windows export-smoke record](evidence/scoreboard/README.md). Scoreboard 52/0; UI binding 185/0; UI flow 198/0; mode UI 62/0; P06 97/0; P08 86/0; P09 77/0; P11 78/0; rendered P06/P08/P09/P11 routes pass. **Verification result:** PASSED for the scoreboard engineering slice. Physical controllers, novice comprehension and independent human readability review remain COULD-NOT-RUN and stay tracked in broader P13 tasks.
  - **Layout note (2026-10-15):** with long real statuses the chart's second status line could be clipped by the no-score notice at 1080p and 1280×720; `ScoreboardChart.BASELINE_BOTTOM_MARGIN` was raised from 112 to 152 and the chart minimum height to 300. Scoreboard 52/0, UI binding 185/0 and mode UI 62/0 were re-run unchanged; the original 10 scoreboard fixtures were not regenerated (new rendered results screens are in [P13 captures](evidence/p13/captures/)). The T13/T14 checkboxes and acceptance are unchanged.

### P13 reference UI restyle — approved 2026-10-17, Required presentation slice

**Goal / player-visible result:** the Lobby, Play HUD, Place, Round result, Pause and the Leave-match / Quit confirmations look like the team's Figma screens (wooden plank buttons, torn-paper and rivet panels, cream lobby cards, chalkboard results, seat pills and score chips) with the team-supplied fonts, while every behaviour, node contract, input route and scoring display stays the same.

**Approval and decisions (2026-10-17, user in chat):** Stage A plan approved; keep the code's seat shapes and colours and only restyle the UI; fonts from the supplied folder with Handlee replacing Lemonade; rivet panel for the in-game Leave match, torn paper for quitting the game; author every piece in scenes so it is visible in the 2D editor. Design source: nine PNG exports of the team Figma file (the Figma link could not be read; no connector). No GDD change.

**Entry / dependencies:** [P13-T01](#p13-t01), [P13-T03](#p13-t03), [P13-T13](#p13-t13) provide the live screens, HUD and results chart being restyled.

**Exit criteria:** T15–T17 pass on engineering evidence and T18 (human visual review and a physical keyboard/controller pass) is done by a person. **Status (2026-10-17): NOT MET** — T18 is open.

#### P13-T15

- [x] **Restyle the Theme, fonts and reusable components from the reference**
  - **Status:** DONE (technical, 2026-10-17) · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (Shanti, design); AI-assisted programming under Francis/Carlos.
  - **Requirements:** [REQ-UI-002](PRD.md#req-ui-002--complete-title-menus-settings-and-navigation), [REQ-ACCESS-001](PRD.md#req-access-001--maintain-color-independent-readable-play). **Dependencies:** [P13-T01](#p13-t01), [P13-T13](#p13-t13).
  - **Work:** restyle `tilaok_theme.tres` with tokens sampled from the reference (every earlier type name kept); bundle the supplied fonts with their licences and register them; add `plank_button`, `vine_divider`, `score_chip`, `seat_pill`, `confirm_dialog_paper` and the gallery component sheet as scenes; make the score legend scene-authored and the award line Theme-driven.
  - **Acceptance:** all new and earlier Theme types exist; Legend letter colours equal the chart colours; no Theme text type below 12 px and mid-round types at least 16 px; fonts load and ship with licence text and an ASSETS row; components keep number + shape beside colour; UI scripts build no layout and set no theme overrides; the gallery lists the component sheet.
  - **Evidence:** [ui-reference evidence](evidence/ui-reference/README.md), [delivery checks](evidence/ui-reference/delivery_checks.txt); `tilaok!/assets/ui/theme/tilaok_theme.tres`, `tilaok!/assets/fonts/`, `scenes/ui/components/plank_button.tscn`, `vine_divider.tscn`, `score_chip.tscn`, `seat_pill.tscn`, `confirm_dialog_paper.tscn`, `scenes/ui/screens/component_sheet.tscn`; font register in [ASSETS](ASSETS.md#reference-restyle-fonts-and-placeholders--2026-10-17). **Procedure / expected / actual:** `Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path tilaok! --script res://tests/run_ui_theme_tests.gd` checks every new Theme type, Legend = chart colours, font-size minimums, plank states, fonts and licence files, chip/pill identity, both dialog skins, the open-slot preview and the component sheet; **expected:** all pass; **actual:** 87 checks, 0 failures. `run_ui_tests.gd` source rule: no UI script builds layout or sets theme overrides (the two baseline offenders, `score_award_legend.gd` and `ui_award_line.gd`, now pass). Build: `main` `d837e7b` plus the restyle change set; Godot 4.7.2.stable.official.ed1daf0bf; Windows 11 Pro, Ryzen 5 5500, RX 580; 2026-10-17; SAMPLE seats 1–4; synthetic input; reviewer: engineering run (AI-assisted), no human reviewer. **Verification result:** PASSED (technical). Textures, icons and font approval are human work (P13-T18, ASSETS).

#### P13-T16

- [x] **Restyle Lobby, Play HUD, Place, Round result, Pause and both confirmations**
  - **Status:** DONE (technical, 2026-10-17) · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (Shanti, design); AI-assisted programming under Francis/Carlos.
  - **Requirements:** [REQ-UI-002](PRD.md#req-ui-002--complete-title-menus-settings-and-navigation), [REQ-UI-003](PRD.md#req-ui-003--explain-current-play-and-results-in-the-hud), [REQ-ACCESS-001](PRD.md#req-access-001--maintain-color-independent-readable-play). **Dependencies:** [P13-T15](#p13-t15), [P13-T03](#p13-t03).
  - **Work:** rebuild the six screens' scenes with the new components; Yes/No stacked (Up/Down, Left/Right still work); open lobby slots preview their fixed number + shape faded; Title quit scrim; no signal, node-name or scoring change.
  - **Acceptance:** every documented `%Unique` contract that resolved on the `d837e7b` baseline still resolves; Play HUD stays exactly 64 px; every gallery screen/state is inside 1280×720 at 1 and 4 players; existing UI, HUD, navigation, binding, mode, scoreboard and tutorial suites pass, apart from failures already present on the `d837e7b` baseline.
  - **Evidence:** [ui-reference evidence](evidence/ui-reference/README.md); `scenes/ui/screens/lobby_screen.tscn`, `play_hud.tscn`, `place_overlay.tscn`, `round_result_screen.tscn`, `pause_screen.tscn`, `title_screen.tscn`, `scenes/ui/components/confirm_dialog.tscn`, `lobby_slot.tscn`, `phase_banner.tscn`, `score_row.tscn`, `award_line.tscn`, `score_award_legend.tscn`; scripts `ui_player_badge.gd`, `ui_lobby_slot.gd`, `ui_confirm_dialog.gd`, `ui_title_screen.gd`, `ui_award_line.gd`, `score_award_legend.gd`. **Procedure / expected / actual:** `run_ui_tests.gd` (contract table, every gallery screen × state at 1 and 4 players inside 1280×720, text ≥ 12 px, HUD exactly 64 px, synthetic input, 10 open/close cycles): 487 checks, 2 failures — the stale `%Outcome1` / `%Final1` contract entries that already failed on `d837e7b` (the round/match results replaced those rows with the chart before this task); every other contract resolves. `run_p13_hud_tests.gd` first FAILED twice (4-player Kangaroo + Bomb-Taya results: title at y −18.5, countdown below 720); the Round result was tightened and the re-run is 265 / 0. `run_match_ui_tests` 190 / 0, `run_match_ui_binding_tests` 177 / 0, `run_match_ui_mode_tests` 62 / 0, `run_scoreboard_chart_tests` 52 / 0, `run_p13_navigation_tests` 205 / 0, `run_p13_tutorial_tests` 58 / 0, `run_tutorial_tests` 142 / 0. Build, engine, machine, date, input and reviewer as P13-T15. **Verification result:** PASSED (technical); human visual approval is P13-T18.

#### P13-T17

- [x] **Verify the restyle against the reference, performance and export**
  - **Status:** PASSED (engineering, synthetic, 2026-10-17); lint/format COULD-NOT-RUN · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-UI-003](PRD.md#req-ui-003--explain-current-play-and-results-in-the-hud), [REQ-ACCESS-001](PRD.md#req-access-001--maintain-color-independent-readable-play). **Dependencies:** [P13-T16](#p13-t16).
  - **Work:** run the full headless regression battery, Godot import/parse, the windowed match-UI and lifecycle suites, rendered 1920×1080 captures at 2/3/4 players beside each reference PNG with a deviation list, a frame-cost and memory sample on the heaviest screen, screen-switch cleanup and a Windows export smoke.
  - **Acceptance:** all suites pass or differ from the pre-change baseline only by documented pre-existing failures; every in-scope screen has a rendered comparison and listed deviations; frame cost within 16.67 ms and memory within 512 MiB at 1080p; node count stable over screen cycles; export starts.
  - **Evidence:** [ui-reference evidence](evidence/ui-reference/README.md) (27 renders at 1920×1080 with 2/3/4 players and 21 side-by-side JPGs, per-screen deviation list), [delivery checks](evidence/ui-reference/delivery_checks.txt). **Procedure / expected / actual:** all 41 headless suites (40 existing + `run_ui_theme_tests`), 5,212 counted checks plus the foundation harness: every suite 0 failures except `run_ui_tests` with the 2 pre-existing failures above (baseline had 4). Windowed live flow in an isolated project copy: `run_match_ui_interactive.gd` 59 / 0 and `run_p09_interactive.gd` 108 / 0. `capture_ui_reference_evidence.gd` on the heaviest screen (4-player Round result, 1920×1080, VSync off, 300 frames): median 0.452 ms, p95 0.716 ms, worst 0.882 ms, 131 draw calls, Godot static memory 118.7 MiB, video 56.4 MiB (budgets 16.67 ms / 512 MiB). Cleanup: node count stable and no new orphans over 10 cycles of all 13 gallery screens. Import/parse clean. Windows debug export and a 120-frame headless startup of the exported console exe both exit 0 (`TILAOK_FLOW_READY state=title`). gdformat/gdlint: COULD-NOT-RUN (not installed on this PC); manual line-length/whitespace scan clean. Build, engine, machine, date, input and reviewer as P13-T15. **Verification result:** PASSED for the engineering checks; synthetic input only, no physical controller, no human reviewer.

#### P13-T18

- [ ] **Human visual review of the restyle and physical device pass**
  - **Status:** COULD-NOT-RUN — needs a person and physical devices · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** Shanti (UI design review) and QA (name TBD).
  - **Requirements:** [REQ-UI-002](PRD.md#req-ui-002--complete-title-menus-settings-and-navigation), [REQ-ACCESS-001](PRD.md#req-access-001--maintain-color-independent-readable-play). **Dependencies:** [P13-T17](#p13-t17).
  - **Work:** the UI designer compares the build to the Figma file at 1080p (and at couch distance), approves or lists changes, confirms the fonts and the deviations, and drives Lobby, Pause and both confirmations with a real keyboard and a real gamepad.
  - **Acceptance:** a named reviewer records approval or a change list; physical keyboard and gamepad reach every Yes/No and Pause entry; no text is unreadable at couch distance.
  - **Evidence:** not yet available; instrument [PLAYTEST Sheet G](PLAYTEST.md#sheet-g--p13-t18-reference-restyle-review). **Verification result:** COULD-NOT-RUN — agent screenshots and synthetic input are not a human review or physical-device evidence. **Next action:** run Sheet G.

## P14 — Release presentation and provenance

**Goal / player-visible result:** The build has readable original art, animation, sound and reviewed cultural identity.

**Milestone / scope:** Feature-complete submission, then release/submission.

**Entry:** Owner assignment; final integration follows stable mechanic contracts.

**External task dependencies:** [P00-T02](#p00-t02)

**Owner roles:** Art/UI + Audio + Compliance; person names TBD. **Systems touched:** NEW team-made assets; existing ASSETS/AI_USAGE registers.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Required assets/music/cues replace unintended placeholders; licences/cultural review and credits reconcile.

**Evidence required:** Asset manifest, permissions, culture review, visual/audio QA.


#### P14-T01

- [ ] **Produce and integrate release art, animation and font assets**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ART-001](PRD.md#req-art-001--deliver-original-chicken-stage-and-interface-presentation). **Dependencies:** [P00-T02](#p00-t02).
  - **Work:** Choose final 2D direction/font with provenance. All chickens have distinct color plus markers; animate movement, hatch, placement, finish and soft comedic elimination. One barrio arena uses original Filipino setting motifs. No copied UCH art/UI/name/character/audio or gambling/gore.
  - **Acceptance:** Release contains no unintended placeholder assets, silhouettes remain clear at minimum zoom, every imported asset/font is approved and credited; cultural copy has review evidence.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P14-T02

- [ ] **Verify deliver original chicken, stage and interface presentation**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ART-001](PRD.md#req-art-001--deliver-original-chicken-stage-and-interface-presentation). **Dependencies:** [P14-T01](#p14-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Release contains no unintended placeholder assets, silhouettes remain clear at minimum zoom, every imported asset/font is approved and credited; cultural copy has review evidence.
  - **Acceptance:** Release contains no unintended placeholder assets, silhouettes remain clear at minimum zoom, every imported asset/font is approved and credited; cultural copy has review evidence.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P14-T03

- [ ] **Produce, mix and integrate essential audio and music**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Audio (name TBD).
  - **Requirements:** [REQ-AUDIO-001](PRD.md#req-audio-001--deliver-essential-sound-and-music-feedback). **Dependencies:** [P00-T02](#p00-t02).
  - **Work:** Provide suitable music and clear UI, hatch/place, movement/item tell, finish/elimination and event cues, all paired with visuals. Prefer team-made recordings. Define and document final volume-control scope; enhanced crowd layers remain Should. Shake/volume are presentation-only pause settings.
  - **Acceptance:** Muted play remains understandable; cues do not mask countdown/command information; volume/mute controls work, assets are registered and playback stops/cleans on transitions.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P14-T04

- [ ] **Verify deliver essential sound and music feedback**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-AUDIO-001](PRD.md#req-audio-001--deliver-essential-sound-and-music-feedback). **Dependencies:** [P14-T03](#p14-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Muted play remains understandable; cues do not mask countdown/command information; volume/mute controls work, assets are registered and playback stops/cleans on transitions.
  - **Acceptance:** Muted play remains understandable; cues do not mask countdown/command information; volume/mute controls work, assets are registered and playback stops/cleans on transitions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P14-T05

- [ ] **Populate and review asset licences and cultural evidence**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Compliance (name TBD).
  - **Requirements:** [REQ-ASSET-001](PRD.md#req-asset-001--maintain-asset-and-cultural-provenance). **Dependencies:** [P00-T02](#p00-t02).
  - **Work:** Register creator/source, licence/permission proof, attribution, modifications, AI assistance, cultural reviewer/date and final approval for every shipped asset. Verify title/Pugad/Karera/Lagsanay/item names and factual cards; fictional adaptations are not claimed as authentic traditional rules.
  - **Acceptance:** Shipped asset manifest matches register and credits; no missing licence/permission or unsupported cultural claim; Form 03 references agree with assistance records.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P14-T06

- [ ] **Verify maintain asset and cultural provenance**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** Compliance (name TBD).
  - **Requirements:** [REQ-ASSET-001](PRD.md#req-asset-001--maintain-asset-and-cultural-provenance). **Dependencies:** [P14-T05](#p14-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Shipped asset manifest matches register and credits; no missing licence/permission or unsupported cultural claim; Form 03 references agree with assistance records.
  - **Acceptance:** Shipped asset manifest matches register and credits; no missing licence/permission or unsupported cultural claim; Form 03 references agree with assistance records.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


## P15 — Balance and regression

**Goal / player-visible result:** Demonstrate reliable play on named hardware at bounded workload.

**Milestone / scope:** Feature-complete submission, then release/submission.

**Entry:** Relevant features complete; final gate includes all required family, event and UI gates.

**External task dependencies:** [P04-T13](#p04-t13), [P04-T22](#p04-t22), [P09-T04](#p09-t04), [P10-T09](#p10-t09), [P10-T18](#p10-t18), [P10-T27](#p10-t27), [P10-T36](#p10-t36), [P10-T45](#p10-t45), [P10-T54](#p10-t54), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10), [P13-T10](#p13-t10), [P13-T12](#p13-t12), [P14-T02](#p14-t02), [P14-T04](#p14-t04)

**Owner roles:** QA; person names TBD. **Systems touched:** Implemented build, local harnesses and PLAYTEST records.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Balance/device/full-match/regression/performance evidence reviewed; no hidden unsupported claims.

**Evidence required:** Named build/hardware, matrices, clips, metrics and defect dispositions.


#### P15-T01

- [ ] **Run documented balance and item-interaction sessions**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-QA-001](PRD.md#req-qa-001--run-balance-sessions-and-first-batch-interaction-checks). **Dependencies:** [P09-T04](#p09-t04), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10), [P04-T13](#p04-t13), [P04-T22](#p04-t22), [P10-T09](#p10-t09), [P10-T18](#p10-t18), [P10-T27](#p10-t27), [P10-T54](#p10-t54), [P10-T36](#p10-t36), [P10-T45](#p10-t45).
  - **Work:** Test 2/3/4 players with slot/device rotation, novice onboarding and clean/representative/cluttered stages. Cover bridge+trumpo, spring+Parol, block+launcher, bubble+trumpo, cleanup+blocked route. Record avoidable versus forced outcomes, no-score frequency, stalls and participant feedback. Change one coupled tuning group per experiment.
  - **Acceptance:** At least two sessions/participants support feel changes, hard defects reproduce, all five interactions have clips/notes and direct ownership results; no assertion of statistical balance from tiny samples.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P15-T02

- [ ] **Verify run balance sessions and first-batch interaction checks**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-QA-001](PRD.md#req-qa-001--run-balance-sessions-and-first-batch-interaction-checks). **Dependencies:** [P15-T01](#p15-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. At least two sessions/participants support feel changes, hard defects reproduce, all five interactions have clips/notes and direct ownership results; no assertion of statistical balance from tiny samples.
  - **Acceptance:** At least two sessions/participants support feel changes, hard defects reproduce, all five interactions have clips/notes and direct ownership results; no assertion of statistical balance from tiny samples.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P15-T03

- [ ] **Run device, outcome and repeated-match regression matrix**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-QA-002](PRD.md#req-qa-002--complete-physical-device-and-regression-coverage). **Dependencies:** [P13-T10](#p13-t10), [P09-T04](#p09-t04), [P04-T13](#p04-t13), [P04-T22](#p04-t22), [P10-T09](#p10-t09), [P10-T18](#p10-t18), [P10-T27](#p10-t27), [P10-T54](#p10-t54), [P10-T36](#p10-t36), [P10-T45](#p10-t45), [P14-T02](#p14-t02), [P14-T04](#p14-t04), [P13-T12](#p13-t12).
  - **Work:** Test 2/3/4-player gamepad/mixed/shared-keyboard supported combinations on editor and exported build, including simultaneous chords, drift, focus, unplug/reclaim, same-model devices and transition input edges. Exercise each mode/stack and score/terminal boundary, full match, sudden death and ten restarts.
  - **Acceptance:** Signed matrix distinguishes PASSED/FAILED/COULD-NOT-RUN with build/devices; no unsupported claim fills a missing physical test. Critical defects are fixed and affected regressions rerun.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P15-T04

- [ ] **Verify complete physical device and regression coverage**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-QA-002](PRD.md#req-qa-002--complete-physical-device-and-regression-coverage). **Dependencies:** [P15-T03](#p15-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Signed matrix distinguishes PASSED/FAILED/COULD-NOT-RUN with build/devices; no unsupported claim fills a missing physical test. Critical defects are fixed and affected regressions rerun.
  - **Acceptance:** Signed matrix distinguishes PASSED/FAILED/COULD-NOT-RUN with build/devices; no unsupported claim fills a missing physical test. Critical defects are fixed and affected regressions rerun.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P15-T05

- [ ] **Profile representative/stress exports and repeated cleanup**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-PERF-001](PRD.md#req-perf-001--measure-frame-time-memory-and-bounded-cleanup). **Dependencies:** [P15-T04](#p15-t04).
  - **Work:** Provisional targets: 60 FPS/16.67 ms at 1080p, 512 MiB process memory pending target-PC confirmation, 0 B/s gameplay networking. Measure base, representative four-player and worst-case round-12 stages at persistent/transient caps and repeated restarts. Record median/p95/worst frame times, memory and object counts.
  - **Acceptance:** Evidence names OS/CPU/GPU/RAM, build, resolution, duration, counts and modes; compare against confirmed budgets, investigate spikes/growth, and record any budget revision explicitly. No measured results are fabricated.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P15-T06

- [ ] **Verify measure frame time, memory and bounded cleanup**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-PERF-001](PRD.md#req-perf-001--measure-frame-time-memory-and-bounded-cleanup). **Dependencies:** [P15-T05](#p15-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Evidence names OS/CPU/GPU/RAM, build, resolution, duration, counts and modes; compare against confirmed budgets, investigate spikes/growth, and record any budget revision explicitly. No measured results are fabricated.
  - **Acceptance:** Evidence names OS/CPU/GPU/RAM, build, resolution, duration, counts and modes; compare against confirmed budgets, investigate spikes/growth, and record any budget revision explicitly. No measured results are fabricated.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


## P16 — Freeze and release candidate

**Goal / player-visible result:** Produce a tested package that another PC can run.

**Milestone / scope:** Feature-complete submission, then release/submission.

**Entry:** P15 and required presentation/provenance gates pass; Should inclusion decided.

**External task dependencies:** [P01-T10](#p01-t10), [P14-T06](#p14-t06), [P15-T02](#p15-t02), [P15-T06](#p15-t06)

**Owner roles:** Producer + Integration; person names TBD. **Systems touched:** Existing project/export preset; NEW release package and run instructions.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Content manifest frozen, critical defects closed, matching-toolchain export and clean-PC acceptance pass.

**Evidence required:** Build checksum, licence bundle, defect sign-off and clean-PC report.


#### P16-T01

- [ ] **Approve content freeze and release defect disposition**
  - **Status:** IN PROGRESS (draft input only) · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-RELEASE-001](PRD.md#req-release-001--freeze-approved-content-and-close-critical-defects). **Dependencies:** [P15-T02](#p15-t02), [P15-T06](#p15-t06), [P14-T06](#p14-t06).
  - **Work:** October 21 is feature freeze; October 22–23 stabilization. Required scope includes all eight targeted families, modes/stacks, UI/Library/tutorial and essential presentation unless explicitly revised. Decide every Should item include/defer. Included Should work inherits full release gates. No new feature after freeze without explicit scope review.
  - **Acceptance:** Dated manifest enumerates enabled variants/modes/pairs, excluded/deferred content and reviewed defects; zero unresolved crash/softlock/wrong-score/winner/device/lifecycle/onboarding blockers.
  - **Evidence:** **2026-10-16 draft (Claude, AI; not approved):** [RELEASE_MANIFEST_DRAFT](RELEASE_MANIFEST_DRAFT.md) lists the 25 dealt variants with their mode flags and weights, the modes, pairs and maps, the defined-but-not-dealt content, the Should items needing include/defer decisions, and the known-defect table from the 2026-10-16 regression ([stabilization evidence](evidence/stabilization/README.md)). The producer's dated freeze decision and defect sign-off are still required; this task stays unchecked. **Verification result:** not yet available.


#### P16-T02

- [ ] **Verify freeze approved content and close critical defects**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-RELEASE-001](PRD.md#req-release-001--freeze-approved-content-and-close-critical-defects). **Dependencies:** [P16-T01](#p16-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Dated manifest enumerates enabled variants/modes/pairs, excluded/deferred content and reviewed defects; zero unresolved crash/softlock/wrong-score/winner/device/lifecycle/onboarding blockers.
  - **Acceptance:** Dated manifest enumerates enabled variants/modes/pairs, excluded/deferred content and reviewed defects; zero unresolved crash/softlock/wrong-score/winner/device/lifecycle/onboarding blockers.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P16-T03

- [ ] **Build, package and clean-PC test the release candidate**
  - **Status:** BLOCKED (export templates) · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Integration (name TBD).
  - **Requirements:** [REQ-EXPORT-002](PRD.md#req-export-002--package-and-verify-the-final-game-on-a-clean-pc). **Dependencies:** [P16-T02](#p16-t02), [P01-T10](#p01-t10).
  - **Work:** Export with recorded engine/templates/preset/build. Package executable and required data, credits/licences, supported devices, launch/quit/restart instructions and known noncritical limits. Verify clean-PC launch without editor or paid licence, complete supported match/tutorial/restart and no gameplay network dependency.
  - **Acceptance:** Checksums and version identify the tested package; clean-PC procedure passes with real hardware; instructions reproduce launch and controls; packaged credits/provenance match assets.
  - **Evidence:** **2026-10-16 check:** no export templates are installed for Godot 4.7.stable on the development PC (`%APPDATA%/Godot/export_templates` is empty), so a current export is COULD-NOT-RUN; the P01-T10 smoke export used another toolchain. **Next action:** install the matching official 4.7.stable export templates (owner approval needed for the download), export with the existing `Windows Desktop` preset, then run the clean-PC procedure on real hardware after P16-T02. **Verification result:** not yet available.


#### P16-T04

- [ ] **Verify package and verify the final game on a clean pc**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-EXPORT-002](PRD.md#req-export-002--package-and-verify-the-final-game-on-a-clean-pc). **Dependencies:** [P16-T03](#p16-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Checksums and version identify the tested package; clean-PC procedure passes with real hardware; instructions reproduce launch and controls; packaged credits/provenance match assets.
  - **Acceptance:** Checksums and version identify the tested package; clean-PC procedure passes with real hardware; instructions reproduce launch and controls; packaged credits/provenance match assets.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


## P17 — Submission and handoff

**Goal / player-visible result:** Deliver the verified game and evidence before the deadline.

**Milestone / scope:** Feature-complete submission, then release/submission.

**Entry:** Forms/media preparation starts with P00; final capture/delivery waits for P16.

**External task dependencies:** [P00-T02](#p00-t02), [P00-T04](#p00-t04), [P16-T04](#p16-t04)

**Owner roles:** Compliance + Producer; person names TBD. **Systems touched:** Existing submission/AI/asset records; NEW forms/media/package archive.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Registration, forms, synopsis, media, package, review, receipt and operational archive complete.

**Evidence required:** Word count, durations, signed review, successful receipt and handoff rehearsal.


#### P17-T01

- [ ] **Prepare and review registration and Forms 01–03**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Compliance (name TBD).
  - **Requirements:** [REQ-SUB-001](PRD.md#req-sub-001--prepare-registration-and-official-forms). **Dependencies:** [P00-T02](#p00-t02).
  - **Work:** Start early: verify current official instructions/category, register, prepare Form 01 roles, Form 02 originality/waiver signatures and Form 03 asset/AI tool-area-extent disclosure with required signatures. The team chooses the Form 03 extent across the entire project. Preserve available prompts/history and no false authorship claims. Verify the recorded §7/§8 code-originality and disclosed-AI interpretation against current official instructions as one submission/compliance item; it is not a per-feature implementation authorization gate.
  - **Acceptance:** Compliance checks current organizer forms, category eligibility and signatures against registered members; completed forms agree with asset/AI records and actual programming provenance; the unresolved §7/§8 interpretation is checked and recorded for submission without claiming organizer approval.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P17-T02

- [ ] **Verify prepare registration and official forms**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** Compliance (name TBD).
  - **Requirements:** [REQ-SUB-001](PRD.md#req-sub-001--prepare-registration-and-official-forms). **Dependencies:** [P17-T01](#p17-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Compliance checks current organizer forms, category eligibility and signatures against registered members; completed forms agree with asset/AI records and actual programming provenance; current official guidance on the recorded §7/§8 interpretation is consulted and documented.
  - **Acceptance:** Compliance checks current organizer forms, category eligibility and signatures against registered members; completed forms agree with asset/AI records and actual programming provenance; the §7/§8 submission interpretation is recorded without representing it as approval.
  - **Evidence:** no completed forms, required signatures, current official-source verification or interpretation record is available. **Verification result:** COULD-NOT-RUN — submission/compliance evidence remains outstanding; no build or physical-device result is substituted for it.


#### P17-T03

- [ ] **Draft synopsis, storyboard and capture schedule**
  - **Status:** IN PROGRESS (AI first draft, unreviewed) · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Compliance (name TBD).
  - **Requirements:** [REQ-SUB-002](PRD.md#req-sub-002--write-the-synopsis-and-plan-media-capture-early). **Dependencies:** [P00-T04](#p00-t04).
  - **Work:** Template 01 synopsis is at most 500 words, covering premise, loop, competitive rules, theme and original work. Plan trailer/demo shot list and captions while gameplay progresses; reserve capture/review time before October 24. Final copy describes only shipped behavior.
  - **Acceptance:** Word count <=500; reviewed copy and shot list cover Pugad, Place, Karera, Lagsanay, theme and results; final-build reconciliation is scheduled before upload.
  - **Evidence:** **2026-10-16 draft (Claude, AI; disclose on Form 03):** [SYNOPSIS_DRAFT](SYNOPSIS_DRAFT.md) has a 410-word Template 01 synopsis (limit 500), a 10-shot muted-readable trailer list covering Pugad, Place, Karera, Lagsanay, Kangaroo, a stack, the theme and results, a 9-part demo outline and a capture schedule to October 24. Compliance editing and approval, cultural/native-speaker review of the marked claims, and final-build reconciliation are still required. **Verification result:** not yet available.


#### P17-T04

- [ ] **Verify write the synopsis and plan media capture early**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** Compliance (name TBD).
  - **Requirements:** [REQ-SUB-002](PRD.md#req-sub-002--write-the-synopsis-and-plan-media-capture-early). **Dependencies:** [P17-T03](#p17-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Word count <=500; reviewed copy and shot list cover Pugad, Place, Karera, Lagsanay, theme and results; final-build reconciliation is scheduled before upload.
  - **Acceptance:** Word count <=500; reviewed copy and shot list cover Pugad, Place, Karera, Lagsanay, theme and results; final-build reconciliation is scheduled before upload.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P17-T05

- [ ] **Capture and edit final trailer and demo video**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Compliance (name TBD).
  - **Requirements:** [REQ-SUB-003](PRD.md#req-sub-003--produce-captioned-trailer-and-explanatory-demo). **Dependencies:** [P17-T04](#p17-t04), [P16-T04](#p16-t04).
  - **Work:** Trailer: 1–2 minute MP4, loops and reads without sound. Demo: 3–5 minute MP4 with narration/captions showing local join, Pugad/Place, Karera/scoring, Lagsanay, item counterplay and results/restart. Use actual tested gameplay; show a supported stack clearly, never mockups passed as runtime.
  - **Acceptance:** Check duration/container/playback/caption legibility and muted trailer; footage matches release candidate, explains Lagsanay and distinguishes Main/Twist; licensed media and source captures archived.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P17-T06

- [ ] **Verify produce captioned trailer and explanatory demo**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** Compliance (name TBD).
  - **Requirements:** [REQ-SUB-003](PRD.md#req-sub-003--produce-captioned-trailer-and-explanatory-demo). **Dependencies:** [P17-T05](#p17-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Check duration/container/playback/caption legibility and muted trailer; footage matches release candidate, explains Lagsanay and distinguishes Main/Twist; licensed media and source captures archived.
  - **Acceptance:** Check duration/container/playback/caption legibility and muted trailer; footage matches release candidate, explains Lagsanay and distinguishes Main/Twist; licensed media and source captures archived.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P17-T07

- [ ] **Perform final review and submit the approved package**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-SUB-004](PRD.md#req-sub-004--review-submit-and-preserve-delivery-evidence). **Dependencies:** [P17-T02](#p17-t02), [P17-T06](#p17-t06), [P16-T04](#p16-t04).
  - **Work:** Before October 25 deadline, producer/compliance reviews registration/forms/synopsis/media/build, theme/tutorial/originality/licensing and final package identity. Submit through verified official channel with authorized team access; retain confirmation/receipt and delivered files. Submission is a separate milestone from release readiness.
  - **Acceptance:** Final review names approver/date, package hash/version and all deliverables; successful upload receipt records time/channel and archived package. Failed upload is not marked submitted.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P17-T08

- [ ] **Verify review, submit and preserve delivery evidence**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-SUB-004](PRD.md#req-sub-004--review-submit-and-preserve-delivery-evidence). **Dependencies:** [P17-T07](#p17-t07).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Final review names approver/date, package hash/version and all deliverables; successful upload receipt records time/channel and archived package. Failed upload is not marked submitted.
  - **Acceptance:** Final review names approver/date, package hash/version and all deliverables; successful upload receipt records time/channel and archived package. Failed upload is not marked submitted.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P17-T09

- [ ] **Archive delivery and rehearse the operational handoff**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-SUB-005](PRD.md#req-sub-005--hand-off-source-build-and-operating-instructions). **Dependencies:** [P17-T08](#p17-t08).
  - **Work:** Retain reproducible source revision, engine/templates/preset, build checksum, test evidence, known issues, licences/disclosure, media masters and submission receipt in team-controlled storage. Name operational owner and explain launch/devices/pause/reconnect/restart and recovery at demonstrations.
  - **Acceptance:** Another registered member can locate the archive, identify the delivered build and run the documented demo/recovery without the original implementer.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P17-T10

- [ ] **Verify hand off source, build and operating instructions**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-SUB-005](PRD.md#req-sub-005--hand-off-source-build-and-operating-instructions). **Dependencies:** [P17-T09](#p17-t09).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Another registered member can locate the archive, identify the delivered build and run the documented demo/recovery without the original implementer.
  - **Acceptance:** Another registered member can locate the archive, identify the delivered build and run the documented demo/recovery without the original implementer.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


## P18 — Conditional finals

**Goal / player-visible result:** Represent the qualified game with prepared hardware and materials.

**Milestone / scope:** Conditional finalist preparation.

**Entry:** Finalist confirmation and verified organizer/category requirements.

**External task dependencies:** [P17-T08](#p17-t08), [P17-T10](#p17-t10)

**Owner roles:** Compliance + Producer; person names TBD. **Systems touched:** NEW controlled finalist records, poster and rehearsal materials.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Qualification and organizer/category confirmation; do not activate from calendar alone.

**Exit criteria:** Required extras and timed hardware/backup/recovery rehearsal complete.

**Evidence required:** Qualification, category checklist and event-hardware rehearsal report.


#### P18-T01

- [ ] **Confirm qualification and prepare finalist documents**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** CONDITIONAL · **Owner:** Compliance (name TBD).
  - **Requirements:** [REQ-FINAL-001](PRD.md#req-final-001--prepare-qualification-dependent-finalist-materials). **Dependencies:** [P17-T08](#p17-t08).
  - **Work:** After finalist confirmation (scheduled November 9), verify category-specific extras: team name; student school/logo, school IDs, enrollment proof and endorsement; professional group/company logo and valid IDs; poster dimensions from organizers. Treat personal documents as controlled team records, not public repo content.
  - **Acceptance:** Organizer checklist and category match delivered extras, permissions and poster specifications; record submission confirmation without exposing private ID data.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P18-T02

- [ ] **Verify prepare qualification-dependent finalist materials**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** CONDITIONAL · **Owner:** Compliance (name TBD).
  - **Requirements:** [REQ-FINAL-001](PRD.md#req-final-001--prepare-qualification-dependent-finalist-materials). **Dependencies:** [P18-T01](#p18-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Organizer checklist and category match delivered extras, permissions and poster specifications; record submission confirmation without exposing private ID data.
  - **Acceptance:** Organizer checklist and category match delivered extras, permissions and poster specifications; record submission confirmation without exposing private ID data.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P18-T03

- [ ] **Rehearse hardware, backup and finalist delivery**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** CONDITIONAL · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-FINAL-002](PRD.md#req-final-002--rehearse-and-deliver-the-finalist-demonstration). **Dependencies:** [P18-T02](#p18-t02), [P17-T10](#p17-t10).
  - **Work:** Plan November 26–27 finals in General Santos City with confirmed participants/travel arrangements, actual PC/display/controllers, offline package backup, captions and reset/reconnect drill. Reverify organizer operational instructions and any permitted build changes.
  - **Acceptance:** Timed rehearsal passes on event hardware, backup launches, team knows controls/recovery and speaking roles; final delivered build and materials are recorded.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P18-T04

- [ ] **Verify rehearse and deliver the finalist demonstration**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** CONDITIONAL · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-FINAL-002](PRD.md#req-final-002--rehearse-and-deliver-the-finalist-demonstration). **Dependencies:** [P18-T03](#p18-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Timed rehearsal passes on event hardware, backup launches, team knows controls/recovery and speaking roles; final delivered build and materials are recorded.
  - **Acceptance:** Timed rehearsal passes on event hardware, backup launches, team knows controls/recovery and speaking roles; final delivered build and materials are recorded.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


## P19 — Optional scope and expansion


### Expansion workstreams and shared prerequisites

The family groups below retain their own promotion and acceptance work. Reuse each capability once; do not rebuild a movement, projectile or contact system for each family. Promotion review must name any additional capability task/dependency before implementation when a tentative mechanic requires it.

| Workstream | Families | Shared prerequisites and principal risk |
|---|---|---|
| Static/temporary construction | Hagdan, Sulok, Marupok, Baliktad | Grid/solid footprint, atomic placement, support provenance and lifecycle; seams, collapse and changing safe faces. |
| Rideable moving supports | Balsa sa Lubid, Angat-Kaing, Perya Wheel, Saranggola Ferry, Umiikot na Dram | Measured relative support/contact, bounded path/reset and safe rider release; rotating and transient support are high risk. |
| Surface and force modifiers | Palay Conveyor, Bentilador, Bomba ng Tubig, Yelo, Malagkit, Ipo-Ipo, Balsa-Bentilador | Intentional versus forced motion, velocity caps, bounds and state restoration; combined force/lethal/moving surfaces need independent enablement evidence. |
| Contact/timed/moving hazards | Tinik-Tinik, Gulat na Walis, Umiikot na Trumpo, Niyog Pendulum, Sipa ng Tsinelas, Singaw, Peryang Traysikel | First-batch outcome ledger, direct ownership, visible sweeps/tells and deterministic reset; readable counterplay before mode enablement. |
| Projectiles | Tansan Ricochet, Niyog Chute | Tsinelas collision/lifetime/cap foundation; specify bounce or terrain-following bounds and placement guides before adding those behaviors. |
| Targeting and paired traversal | Gulat na Palayok, Gulong Kuliglig, Kambal na Pinto | Stable contact/target selection, terminal exclusion and bounded cleanup; explicit target fairness, exit clearance and anti-loop contracts. Respect race-only restrictions. |


**Goal / player-visible result:** Keep every additional idea visible without inflating submission completion.

**Milestone / scope:** Optional Should and full-catalog expansion.

**Entry:** Explicit inclusion/promotion, owner/capacity and relevant shared-system gates.

**External task dependencies:** [P00-T04](#p00-t04), [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18), [P12-T04](#p12-t04)

**Owner roles:** Producer + relevant specialist; person names TBD. **Systems touched:** NEW optional family/event/presentation work only after approval.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Explicit promotion and unresolved family/event contracts; deferred by default.

**Exit criteria:** Each promoted group passes its own acceptance; unpromoted groups remain deferred. No global release blocker.

**Evidence required:** Promotion decisions, individual family tests and explicit excluded/parked dispositions.


#### P19-T01

- [x] **Record inclusion/promotion decision for Barya**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (individual name/capacity assignment remains open).
  - **Requirements:** [REQ-OPT-001](PRD.md#req-opt-001--barya). **Dependencies:** [P00-T04](#p00-t04).
  - **Work:** Record the dated, user-approved Barya-only activation and complete its behavior contract before enabling it on P12. This scope does not ratify the full release manifest or close P00-T04.
  - **Acceptance:** Include decision and behavior contract recorded; verification is assigned to the implementation's deterministic and real-physics tests, rendering, export and smoke evidence; content is enabled only after those technical checks pass. Human/device and production-asset reviews remain separate.
  - **Evidence:** [Barya activation and contract](evidence/barya/activation_contract_2026-10-15.md); [complete technical record](evidence/barya/README.md). **Verification result:** PASSED — dated decision, scoped contract and technical verification completed; no independent human review is claimed.


#### P19-T03

- [ ] **Record inclusion/promotion decision for Local session win tally**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-OPT-002](PRD.md#req-opt-002--local-session-win-tally). **Dependencies:** [P00-T04](#p00-t04).
  - **Work:** Assign owner/capacity and approve the unresolved contract before enabling this optional feature. Optional match-result win tally persists between matches only in current process/session; no account, disk save, cloud sync or migration.
  - **Acceptance:** Dated include/defer decision and contract resolve unknown behavior, scope and verification responsibilities; content remains disabled until verified.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T05

- [ ] **Record inclusion/promotion decision for Enhanced crowd and spectator cheer**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Audio (name TBD).
  - **Requirements:** [REQ-OPT-003](PRD.md#req-opt-003--enhanced-crowd-and-spectator-cheer). **Dependencies:** [P00-T04](#p00-t04).
  - **Work:** Assign owner/capacity and approve the unresolved contract before enabling this optional feature. Enhanced crowd: rooster start, trap anticipation, soft elimination/fall groan, gasp, finish/Una cheer, none/all-finish reactions, Bawi celebration, late-taya drumroll, final-two tension and winner chant. Optional player-colored fans and tension 0–1 drive ambient mix. Spectator cheer has no simulation effect and prototype 1 s cooldown.
  - **Acceptance:** Dated include/defer decision and contract resolve unknown behavior, scope and verification responsibilities; content remains disabled until verified.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T07

- [ ] **Record inclusion/promotion decision for Reviewed educational cards**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Compliance (name TBD).
  - **Requirements:** [REQ-OPT-004](PRD.md#req-opt-004--reviewed-educational-cards). **Dependencies:** [P00-T04](#p00-t04).
  - **Work:** Assign owner/capacity and approve the unresolved contract before enabling this optional feature. Optional Alam mo ba cards explain a real traditional game, region and real-life rules before its event using reliable evidence and native-speaker review. Do not describe fictional item/Kangaroo rules as verified tradition.
  - **Acceptance:** Dated include/defer decision and contract resolve unknown behavior, scope and verification responsibilities; content remains disabled until verified.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T09

- [ ] **Record inclusion/promotion decision for Langit-Lupa**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-OPT-005](PRD.md#req-opt-005--langit-lupa). **Dependencies:** [P00-T04](#p00-t04).
  - **Work:** Assign owner/capacity and approve the unresolved contract before enabling this optional feature. Named second laro ng lahi remains a Should event, not displaced by Kangaroo. Rising floor, survive to end; documented mapping is Tapos for survivors and Una for highest position. Detailed timer/height/tie/stack behavior requires a contract before implementation.
  - **Acceptance:** Dated include/defer decision and contract resolve unknown behavior, scope and verification responsibilities; content remains disabled until verified.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T11

- [ ] **Record inclusion/promotion decision for Cosmetic skins and accessories**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-OPT-006](PRD.md#req-opt-006--cosmetic-skins-and-accessories). **Dependencies:** [P00-T04](#p00-t04).
  - **Work:** Assign owner/capacity and approve the unresolved contract before enabling this optional feature. Distinct chicken color/shape identity is required; richer skins/accessories beyond the required readable set are optional. Preserve marker visibility, wholesome silhouettes and asset/cultural provenance.
  - **Acceptance:** Dated include/defer decision and contract resolve unknown behavior, scope and verification responsibilities; content remains disabled until verified.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T13

- [ ] **Record inclusion/promotion decision for Luksong Tinik / 10–20 Garter**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-BACKLOG-001](PRD.md#req-backlog-001--luksong-tinik--1020-garter). **Dependencies:** [P00-T04](#p00-t04).
  - **Work:** Assign owner/capacity and approve the unresolved contract before enabling this optional feature. Compare and choose one implementation family; define telegraph, sweep/thickness, platform interaction, avoidance and anti-camping. Existing Luksong Tinik mapping is survive all waves for Tapos, no Una.
  - **Acceptance:** Dated include/defer decision and contract resolve unknown behavior, scope and verification responsibilities; content remains disabled until verified.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T15

- [ ] **Record inclusion/promotion decision for Agawan Buko / Jackstone comparison**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-BACKLOG-002](PRD.md#req-backlog-002--agawan-buko--jackstone-comparison). **Dependencies:** [P00-T04](#p00-t04).
  - **Work:** Assign owner/capacity and approve the unresolved contract before enabling this optional feature. Agawan Buko remains coconut collection: holding at least one at end gives Tapos, most gives Una. Compare Jackstone without automatic replacement; define supply/quota by count, reachable spawns, contested collection, elimination drops and impossible-quota recovery.
  - **Acceptance:** Dated include/defer decision and contract resolve unknown behavior, scope and verification responsibilities; content remains disabled until verified.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T17

- [ ] **Record inclusion/promotion decision for Sipa**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-BACKLOG-003](PRD.md#req-backlog-003--sipa). **Dependencies:** [P00-T04](#p00-t04).
  - **Work:** Assign owner/capacity and approve the unresolved contract before enabling this optional feature. Prototype only after choosing responsibility rules that do not punish the player keeping the ball aloft. Define contact credit, equal distance, body collision, bounds/unreachable recovery and terminal scoring.
  - **Acceptance:** Dated include/defer decision and contract resolve unknown behavior, scope and verification responsibilities; content remains disabled until verified.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T19

- [ ] **Record inclusion/promotion decision for Additional stages and event pairs**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-BACKLOG-004](PRD.md#req-backlog-004--additional-stages-and-event-pairs). **Dependencies:** [P00-T04](#p00-t04).
  - **Work:** Assign owner/capacity and approve the unresolved contract before enabling this optional feature. Extra stages and unlisted Main/Twist pairs are expansion. Each pair needs written input/collision/terminal/scoring/secured-state/presentation compatibility; each stage needs protected zones, bounds/support/readability and device/performance tests.
  - **Acceptance:** Dated include/defer decision and contract resolve unknown behavior, scope and verification responsibilities; content remains disabled until verified.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T21

- [ ] **Maintain parked, brainstorm and excluded-feature ledger**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-BACKLOG-005](PRD.md#req-backlog-005--retain-parked-events-and-earlier-brainstorm-dispositions). **Dependencies:** [P00-T04](#p00-t04).
  - **Work:** Park Tumba Lata, Sikyo, Sepak Takraw and Dr. Quack Quack with cultural/mechanic review before promotion; do not equate Sikyo and Syato. Retain earlier rolling niyog, sampayan, kawali, charging tricycle, banana peel, Bomb and generic platforms/springs as uncommitted ideas. Bomb remains distinct from Walis. Agawan Base and Patintero/Tubigan remain explicitly cut.
  - **Acceptance:** Disposition ledger names every idea, relationship to catalog if any and promotion/exclusion reason; no parked/cut idea is playable by default or counted as required.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T22

- [ ] **Verify retain parked events and earlier brainstorm dispositions**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-BACKLOG-005](PRD.md#req-backlog-005--retain-parked-events-and-earlier-brainstorm-dispositions). **Dependencies:** [P19-T21](#p19-t21).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Disposition ledger names every idea, relationship to catalog if any and promotion/exclusion reason; no parked/cut idea is playable by default or counted as required.
  - **Acceptance:** Disposition ledger names every idea, relationship to catalog if any and promotion/exclusion reason; no parked/cut idea is playable by default or counted as required.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Hagdan ng Bahay — `build.house_stairs`


#### P19-T23

- [ ] **Approve Hagdan ng Bahay promotion and contract**
  - **Status:** IN PROGRESS (promotion decided; owners TBD) · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-009](PRD.md#req-item-009--hagdan-ng-bahay). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** **2026-10-16:** The user chose to promote three low-risk designs in chat, and Claude picked Hagdan ng Bahay. The tentative fields were resolved as recorded in [ITEMS](ITEMS.md#expansion-backlog-28-additional-mechanical-designs) (sizes, rotations, modes, weight 20, safe bounds as authored in the scene). Named owners and capacity are not recorded, so this task stays unchecked. **Verification result:** not yet available.


#### P19-T24

- [x] **Implement Hagdan ng Bahay definition and runtime**
  - **Status:** PASSED (promoted 2026-10-16) · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-009](PRD.md#req-item-009--hagdan-ng-bahay). **Dependencies:** [P19-T23](#p19-t23).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Multi-step footholds; can create a steep obstacle. Tell: stair silhouette. Counter: alternate jump route. Solid stepped footprint; 90° rotations. Tune tread count/height and footprint.
  - **Acceptance:** Implement 2×2 or 3×3 steps. Terrain in both modes; placer owns removable static piece; medium risk: collision seams.
  - **Evidence:** `scenes/blocks/construction/hagdan_steps_2x2.tscn` and `hagdan_steps_3x3.tscn` (family `build.house_stairs`): one solid column per step, four rotations, anchored, removable, support-eligible. [P19 promoted evidence](evidence/p19_promoted/README.md) (`tests/run_p19_promoted_tests.gd`, 25 checks, 0 failures). **Procedure / expected / actual:** place the real scene in the Item Lab and run real physics with a synthetic K1 seat; a chicken stands on each of the three 3×3 steps (feet 512 / 448 / 384 wu); a rotated 2×2 keeps its three solid cells. **Result:** PASSED (synthetic; DEBUG placeholder art). **Build:** Godot 4.7.stable.official.5b4e0cb0f, Windows 11, Item Lab (default arena, 64 wu grid), one synthetic K1 seat, 60 Hz (`--fixed-fps 60`), working tree on `fec0d3f`, 2026-10-16, reviewer: Claude (AI, automated; no human reviewer). Promotion decided by the user in chat on 2026-10-16 (see the paired approval task).


#### P19-T25

- [ ] **Present Hagdan ng Bahay in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-009](PRD.md#req-item-009--hagdan-ng-bahay). **Dependencies:** [P19-T24](#p19-t24).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** **2026-10-16:** DEBUG placeholder visuals and Library text exist in the scene; final art, audio and cultural review are the art team's. **Verification result:** not yet available.


#### P19-T26

- [ ] **Integrate Hagdan ng Bahay ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-009](PRD.md#req-item-009--hagdan-ng-bahay). **Dependencies:** [P19-T24](#p19-t24), [P19-T25](#p19-t25), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** **2026-10-16 groundwork:** mode flags drive the P12 egg filter (`run_item_mode_integration_tests.gd` covers every catalog family), and placer ownership comes from the shared ItemManager. Family-specific removal, support-provenance and event-round checks have not been run. **Verification result:** not yet available.


#### P19-T27

- [ ] **Verify Hagdan ng Bahay before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-009](PRD.md#req-item-009--hagdan-ng-bahay). **Dependencies:** [P19-T26](#p19-t26).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Sulok na Kawayan — `build.bamboo_corner`


#### P19-T28

- [ ] **Approve Sulok na Kawayan promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-010](PRD.md#req-item-010--sulok-na-kawayan). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T29

- [ ] **Implement Sulok na Kawayan definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-010](PRD.md#req-item-010--sulok-na-kawayan). **Dependencies:** [P19-T28](#p19-t28).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: L-shaped ledge/cover gives foothold and projectile defense; may occlude tells. Outline both arms; route around. Solid L footprint; four rotations. Tune arm length/clearance.
  - **Acceptance:** Implement 2×2 or 3×3 L-shape; arms grow together. Terrain; placer owns, cleanup removes; low-medium risk: multi-cell overlap validation.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T30

- [ ] **Present Sulok na Kawayan in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-010](PRD.md#req-item-010--sulok-na-kawayan). **Dependencies:** [P19-T29](#p19-t29).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T31

- [ ] **Integrate Sulok na Kawayan ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-010](PRD.md#req-item-010--sulok-na-kawayan). **Dependencies:** [P19-T29](#p19-t29), [P19-T30](#p19-t30), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T32

- [ ] **Verify Sulok na Kawayan before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-010](PRD.md#req-item-010--sulok-na-kawayan). **Dependencies:** [P19-T31](#p19-t31).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Marupok na Papag — `build.fragile_papag`


#### P19-T33

- [ ] **Approve Marupok na Papag promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-011](PRD.md#req-item-011--marupok-na-papag). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T34

- [ ] **Implement Marupok na Papag definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-011](PRD.md#req-item-011--marupok-na-papag). **Dependencies:** [P19-T33](#p19-t33).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Temporary bridge collapses after landings; visible cracks warn. Counter: cross quickly or use another route. Solid footprint, no rotation or 180°; tune landing count/recovery.
  - **Acceptance:** Implement 2×1 or 3×1 platform. Race/event; collapse state resets next Play; no kill credit from falling unless direct hazard owns it. Medium risk: simultaneous landing.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T35

- [ ] **Present Marupok na Papag in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-011](PRD.md#req-item-011--marupok-na-papag). **Dependencies:** [P19-T34](#p19-t34).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T36

- [ ] **Integrate Marupok na Papag ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-011](PRD.md#req-item-011--marupok-na-papag). **Dependencies:** [P19-T34](#p19-t34), [P19-T35](#p19-t35), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T37

- [ ] **Verify Marupok na Papag before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-011](PRD.md#req-item-011--marupok-na-papag). **Dependencies:** [P19-T36](#p19-t36).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Baliktad na Banig — `hazard.flipping_banig`


#### P19-T38

- [ ] **Approve Baliktad na Banig promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-012](PRD.md#req-item-012--baliktad-na-banig). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T39

- [ ] **Implement Baliktad na Banig definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-012](PRD.md#req-item-012--baliktad-na-banig). **Dependencies:** [P19-T38](#p19-t38).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Periodically usable/unsafe face changes after warning; tell by shape/icon. Counter: leave during warning. Defined solid top and trigger face; 180° rotation. Tune phase/duration/grace.
  - **Acceptance:** Implement Single default from grid matrix: 3×1 footprint; Active face: 3×1 active region. Both modes after Lagsanay test; resets phase; placer owns only direct elimination. Medium-high moving-collision risk.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T40

- [ ] **Present Baliktad na Banig in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-012](PRD.md#req-item-012--baliktad-na-banig). **Dependencies:** [P19-T39](#p19-t39).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T41

- [ ] **Integrate Baliktad na Banig ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-012](PRD.md#req-item-012--baliktad-na-banig). **Dependencies:** [P19-T39](#p19-t39), [P19-T40](#p19-t40), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T42

- [ ] **Verify Baliktad na Banig before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-012](PRD.md#req-item-012--baliktad-na-banig). **Dependencies:** [P19-T41](#p19-t41).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Balsa sa Lubid — `move.rope_raft`


#### P19-T43

- [ ] **Approve Balsa sa Lubid promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-013](PRD.md#req-item-013--balsa-sa-lubid). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T44

- [ ] **Implement Balsa sa Lubid definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-013](PRD.md#req-item-013--balsa-sa-lubid). **Dependencies:** [P19-T43](#p19-t43).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Shuttle crosses a gap, enabling timed boarding; endpoints pose falls. Tell: rope/endpoint pause. Counter: board at pause or jump off. Platform footprint separate bounded horizontal sweep; horizontal only. Tune speed/pause/range/cap.
  - **Acceptance:** Implement 2×1 or 3×1 raft; 5×1 or 7×1 path; both visible. Both modes; resets to endpoint/direction; no assist credit. High risk: rider carry/support lifecycle.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T45

- [ ] **Present Balsa sa Lubid in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-013](PRD.md#req-item-013--balsa-sa-lubid). **Dependencies:** [P19-T44](#p19-t44).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T46

- [ ] **Integrate Balsa sa Lubid ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-013](PRD.md#req-item-013--balsa-sa-lubid). **Dependencies:** [P19-T44](#p19-t44), [P19-T45](#p19-t45), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T47

- [ ] **Verify Balsa sa Lubid before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-013](PRD.md#req-item-013--balsa-sa-lubid). **Dependencies:** [P19-T46](#p19-t46).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Angat-Kaing — `move.basket_lift`


#### P19-T48

- [ ] **Approve Angat-Kaing promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-014](PRD.md#req-item-014--angat-kaing). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T49

- [ ] **Implement Angat-Kaing definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-014](PRD.md#req-item-014--angat-kaing). **Dependencies:** [P19-T48](#p19-t48).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Lift reaches high routes; endpoint timing risks falls. Tell: visible guide and endpoint pause. Counter: wait for basket. Solid top, bounded vertical sweep; rotate not allowed. Tune height/speed/pause.
  - **Acceptance:** Implement 2×1 lift; 2×4 or 2×6 path. Both modes subject to Lagsanay containment; reset deterministic; high risk: platform carrying/player state.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T50

- [ ] **Present Angat-Kaing in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-014](PRD.md#req-item-014--angat-kaing). **Dependencies:** [P19-T49](#p19-t49).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T51

- [ ] **Integrate Angat-Kaing ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-014](PRD.md#req-item-014--angat-kaing). **Dependencies:** [P19-T49](#p19-t49), [P19-T50](#p19-t50), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T52

- [ ] **Verify Angat-Kaing before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-014](PRD.md#req-item-014--angat-kaing). **Dependencies:** [P19-T51](#p19-t51).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Perya Wheel — `move.perya_wheel`


#### P19-T53

- [ ] **Approve Perya Wheel promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-015](PRD.md#req-item-015--perya-wheel). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T54

- [ ] **Implement Perya Wheel definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-015](PRD.md#req-item-015--perya-wheel). **Dependencies:** [P19-T53](#p19-t53).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Several rideable footholds circle an axle; transfers are risky. Tell: visible full orbit. Counter: board near low arc, dismount. Footprint is pivot/arms, sweep separate; fixed rotation direction. Tune radius/speed/platform count.
  - **Acceptance:** Implement Single default from grid matrix: 5×5 envelope footprint; Same 5×5 orbit envelope active region. Both modes only after event testing; reset angle; high risk: multi-platform collision.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T55

- [ ] **Present Perya Wheel in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-015](PRD.md#req-item-015--perya-wheel). **Dependencies:** [P19-T54](#p19-t54).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T56

- [ ] **Integrate Perya Wheel ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-015](PRD.md#req-item-015--perya-wheel). **Dependencies:** [P19-T54](#p19-t54), [P19-T55](#p19-t55), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T57

- [ ] **Verify Perya Wheel before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-015](PRD.md#req-item-015--perya-wheel). **Dependencies:** [P19-T56](#p19-t56).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Palay Conveyor — `move.palay_conveyor`


#### P19-T58

- [ ] **Approve Palay Conveyor promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-016](PRD.md#req-item-016--palay-conveyor). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T59

- [ ] **Implement Palay Conveyor definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-016](PRD.md#req-item-016--palay-conveyor). **Dependencies:** [P19-T58](#p19-t58).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Carries grounded players sideways; running against it changes traversal. Tell: belt texture and motion marks. Counter: reverse run or leave surface. Surface footprint only; 0/180° orientation. Tune velocity and acceleration.
  - **Acceptance:** Implement 3×1 or 4×1 surface. Both modes; modifier owner not trap credit unless direct lethal interaction exists. Medium dependency on grounded-state handling.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T60

- [ ] **Present Palay Conveyor in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-016](PRD.md#req-item-016--palay-conveyor). **Dependencies:** [P19-T59](#p19-t59).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T61

- [ ] **Integrate Palay Conveyor ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-016](PRD.md#req-item-016--palay-conveyor). **Dependencies:** [P19-T59](#p19-t59), [P19-T60](#p19-t60), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T62

- [ ] **Verify Palay Conveyor before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-016](PRD.md#req-item-016--palay-conveyor). **Dependencies:** [P19-T61](#p19-t61).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Bentilador — `move.bentilador`


#### P19-T63

- [ ] **Approve Bentilador promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-017](PRD.md#req-item-017--bentilador). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T64

- [ ] **Implement Bentilador definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-017](PRD.md#req-item-017--bentilador). **Dependencies:** [P19-T63](#p19-t63).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Visible airflow pushes chickens, changing jumps near hazards. Counter: cover if blocking is enabled or move out of corridor. Footprint anchor plus force rectangle; four rotations. Tune force/falloff/blocking.
  - **Acceptance:** Implement 3×3 or 5×3 air corridor, not just fan footprint. Both modes after Lagsanay and item tests; resets field state; no assist credit. Medium-high force/bounds risk.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T65

- [ ] **Present Bentilador in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-017](PRD.md#req-item-017--bentilador). **Dependencies:** [P19-T64](#p19-t64).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T66

- [ ] **Integrate Bentilador ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-017](PRD.md#req-item-017--bentilador). **Dependencies:** [P19-T64](#p19-t64), [P19-T65](#p19-t65), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T67

- [ ] **Verify Bentilador before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-017](PRD.md#req-item-017--bentilador). **Dependencies:** [P19-T66](#p19-t66).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Bomba ng Tubig — `move.water_jet`


#### P19-T68

- [ ] **Approve Bomba ng Tubig promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-018](PRD.md#req-item-018--bomba-ng-tubig). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T69

- [ ] **Implement Bomba ng Tubig definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-018](PRD.md#req-item-018--bomba-ng-tubig). **Dependencies:** [P19-T68](#p19-t68).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Timed upward water burst boosts route; can push into trap. Tell: pressure gauge and rising sound. Counter: cross between bursts. Jet corridor distinct from solid footprint; rotate 90°; tune cadence/force/duration.
  - **Acceptance:** Implement 1×3 or 1×5 jet. Both modes after safe-floor test; resets idle. Medium-high player launch dependency.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T70

- [ ] **Present Bomba ng Tubig in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-018](PRD.md#req-item-018--bomba-ng-tubig). **Dependencies:** [P19-T69](#p19-t69).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T71

- [ ] **Integrate Bomba ng Tubig ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-018](PRD.md#req-item-018--bomba-ng-tubig). **Dependencies:** [P19-T69](#p19-t69), [P19-T70](#p19-t70), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T72

- [ ] **Verify Bomba ng Tubig before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-018](PRD.md#req-item-018--bomba-ng-tubig). **Dependencies:** [P19-T71](#p19-t71).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Saranggola Ferry — `move.kite_ferry`


#### P19-T73

- [ ] **Approve Saranggola Ferry promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-019](PRD.md#req-item-019--saranggola-ferry). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T74

- [ ] **Implement Saranggola Ferry definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-019](PRD.md#req-item-019--saranggola-ferry). **Dependencies:** [P19-T73](#p19-t73).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Small rideable kite platform traverses a bounded path then despawns; supports crossing. Tell: launch spool/path. Counter: dismount before endpoint. Platform and path separate; 0/180° lane. Tune dwell/path/lifetime/cap.
  - **Acceptance:** Implement Single default from grid matrix: Kite: 2×1 footprint; Travel lane: 7×1 active region. Race/event after Lagsanay safety review; resets docked. High risk: transient platform support.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T75

- [ ] **Present Saranggola Ferry in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-019](PRD.md#req-item-019--saranggola-ferry). **Dependencies:** [P19-T74](#p19-t74).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T76

- [ ] **Integrate Saranggola Ferry ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-019](PRD.md#req-item-019--saranggola-ferry). **Dependencies:** [P19-T74](#p19-t74), [P19-T75](#p19-t75), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T77

- [ ] **Verify Saranggola Ferry before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-019](PRD.md#req-item-019--saranggola-ferry). **Dependencies:** [P19-T76](#p19-t76).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Yelo ng Sorbetero — `modifier.sorbetes_ice`


#### P19-T78

- [ ] **Approve Yelo ng Sorbetero promotion and contract**
  - **Status:** IN PROGRESS (promotion decided; owners TBD) · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-020](PRD.md#req-item-020--yelo-ng-sorbetero). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** **2026-10-16:** The user chose to promote three low-risk designs in chat, and Claude picked Yelo ng Sorbetero. The tentative fields were resolved as recorded in [ITEMS](ITEMS.md#expansion-backlog-28-additional-mechanical-designs) (sizes, rotations, modes, weight 20, safe bounds as authored in the scene). Named owners and capacity are not recorded, so this task stays unchecked. **Verification result:** not yet available.


#### P19-T79

- [x] **Implement Yelo ng Sorbetero definition and runtime**
  - **Status:** PASSED (promoted 2026-10-16) · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-020](PRD.md#req-item-020--yelo-ng-sorbetero). **Dependencies:** [P19-T78](#p19-t78).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Reduces braking for longer slides; can carry player into danger. Tell: frosty edge pattern. Counter: jump off or plan stopping distance. Surface-only footprint; 90° orientation irrelevant. Tune friction and max speed.
  - **Acceptance:** Implement 3×1 or 4×1 surface. Both modes; no trap credit; reset is static. Medium movement tuning.
  - **Evidence:** `scenes/blocks/construction/yelo_ice_3x1.tscn` and `yelo_ice_4x1.tscn` (family `modifier.sorbetes_ice`): a solid slab with BlockData `slippery`; `ChickenController._on_slippery_floor` scales braking (0.12), grip (0.6) and run speed (1.25) via new tuning keys; static, no credit. [P19 promoted evidence](evidence/p19_promoted/README.md) (`tests/run_p19_promoted_tests.gd`, 25 checks, 0 failures). **Procedure / expected / actual:** place the real scene in the Item Lab and run real physics with a synthetic K1 seat; letting go at full speed slides 323 wu on ice versus stopping at once on the floor; top speed 700 vs 560 wu/s; no elimination or credit records. **Result:** PASSED (synthetic; DEBUG placeholder art). **Build:** Godot 4.7.stable.official.5b4e0cb0f, Windows 11, Item Lab (default arena, 64 wu grid), one synthetic K1 seat, 60 Hz (`--fixed-fps 60`), working tree on `fec0d3f`, 2026-10-16, reviewer: Claude (AI, automated; no human reviewer). Promotion decided by the user in chat on 2026-10-16 (see the paired approval task).


#### P19-T80

- [ ] **Present Yelo ng Sorbetero in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-020](PRD.md#req-item-020--yelo-ng-sorbetero). **Dependencies:** [P19-T79](#p19-t79).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** **2026-10-16:** DEBUG placeholder visuals and Library text exist in the scene; final art, audio and cultural review are the art team's. **Verification result:** not yet available.


#### P19-T81

- [ ] **Integrate Yelo ng Sorbetero ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-020](PRD.md#req-item-020--yelo-ng-sorbetero). **Dependencies:** [P19-T79](#p19-t79), [P19-T80](#p19-t80), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** **2026-10-16 groundwork:** mode flags drive the P12 egg filter (`run_item_mode_integration_tests.gd` covers every catalog family), and placer ownership comes from the shared ItemManager. Family-specific removal, support-provenance and event-round checks have not been run. **Verification result:** not yet available.


#### P19-T82

- [ ] **Verify Yelo ng Sorbetero before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-020](PRD.md#req-item-020--yelo-ng-sorbetero). **Dependencies:** [P19-T81](#p19-t81).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Malagkit Patch — `modifier.malagkit_patch`


#### P19-T83

- [ ] **Approve Malagkit Patch promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-021](PRD.md#req-item-021--malagkit-patch). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T84

- [ ] **Implement Malagkit Patch definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-021](PRD.md#req-item-021--malagkit-patch). **Dependencies:** [P19-T83](#p19-t83).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Slows player/reduces jump while touching; no object attachment in v1. Tell: textured sticky patch. Counter: jump over or avoid. Surface trigger, 0/90°; tune speed/jump multipliers.
  - **Acceptance:** Implement Single default from grid matrix: 3×1 footprint; Surface effect: 3×1 active region. Both modes; no assist credit; static reset. Medium movement-state restoration risk.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T85

- [ ] **Present Malagkit Patch in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-021](PRD.md#req-item-021--malagkit-patch). **Dependencies:** [P19-T84](#p19-t84).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T86

- [ ] **Integrate Malagkit Patch ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-021](PRD.md#req-item-021--malagkit-patch). **Dependencies:** [P19-T84](#p19-t84), [P19-T85](#p19-t85), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T87

- [ ] **Verify Malagkit Patch before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-021](PRD.md#req-item-021--malagkit-patch). **Dependencies:** [P19-T86](#p19-t86).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Tinik-Tinik Strip — `hazard.toy_burr_strip`


#### P19-T88

- [ ] **Approve Tinik-Tinik Strip promotion and contract**
  - **Status:** IN PROGRESS (promotion decided; owners TBD) · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-022](PRD.md#req-item-022--tinik-tinik-strip). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** **2026-10-16:** The user chose to promote three low-risk designs in chat, and Claude picked Tinik-Tinik Strip. The tentative fields were resolved as recorded in [ITEMS](ITEMS.md#expansion-backlog-28-additional-mechanical-designs) (sizes, rotations, modes, weight 20, safe bounds as authored in the scene). Named owners and capacity are not recorded, so this task stays unchecked. **Verification result:** not yet available.


#### P19-T89

- [x] **Implement Tinik-Tinik Strip definition and runtime**
  - **Status:** PASSED (promoted 2026-10-16) · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-022](PRD.md#req-item-022--tinik-tinik-strip). **Dependencies:** [P19-T88](#p19-t88).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Narrow marked strip eliminates on contact, allowing face-level defense. Tell: soft oversized burr silhouette. Counter: jump over/route around. Thin trigger strip, four rotations; tune thickness/active faces.
  - **Acceptance:** Implement 3×1 or 4×1 strip. Both modes after wholesome-art review; placer receives direct kill credit; static reset. Medium readability risk.
  - **Evidence:** `scenes/blocks/traps/tinik_strip_3x1.tscn` and `tinik_strip_4x1.tscn` (family `hazard.toy_burr_strip`): no solid body, an 18 wu kill strip along the bottom of its cells, four rotations, static. [P19 promoted evidence](evidence/p19_promoted/README.md) (`tests/run_p19_promoted_tests.gd`, 25 checks, 0 failures). **Procedure / expected / actual:** place the real scene in the Item Lab and run real physics with a synthetic K1 seat; walking into the strip eliminates the chicken with a credit-eligible kill owned by the placer; a chicken held 40 wu above it is never touched. **Result:** PASSED (synthetic; DEBUG placeholder art). **Build:** Godot 4.7.stable.official.5b4e0cb0f, Windows 11, Item Lab (default arena, 64 wu grid), one synthetic K1 seat, 60 Hz (`--fixed-fps 60`), working tree on `fec0d3f`, 2026-10-16, reviewer: Claude (AI, automated; no human reviewer). Promotion decided by the user in chat on 2026-10-16 (see the paired approval task).


#### P19-T90

- [ ] **Present Tinik-Tinik Strip in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-022](PRD.md#req-item-022--tinik-tinik-strip). **Dependencies:** [P19-T89](#p19-t89).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** **2026-10-16:** DEBUG placeholder visuals and Library text exist in the scene; final art, audio and cultural review are the art team's. **Verification result:** not yet available.


#### P19-T91

- [ ] **Integrate Tinik-Tinik Strip ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-022](PRD.md#req-item-022--tinik-tinik-strip). **Dependencies:** [P19-T89](#p19-t89), [P19-T90](#p19-t90), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** **2026-10-16 groundwork:** mode flags drive the P12 egg filter (`run_item_mode_integration_tests.gd` covers every catalog family), and placer ownership comes from the shared ItemManager. Family-specific removal, support-provenance and event-round checks have not been run. **Verification result:** not yet available.


#### P19-T92

- [ ] **Verify Tinik-Tinik Strip before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-022](PRD.md#req-item-022--tinik-tinik-strip). **Dependencies:** [P19-T91](#p19-t91).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Gulat na Walis — `hazard.surprise_broom`


#### P19-T93

- [ ] **Approve Gulat na Walis promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-023](PRD.md#req-item-023--gulat-na-walis). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T94

- [ ] **Implement Gulat na Walis definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-023](PRD.md#req-item-023--gulat-na-walis). **Dependencies:** [P19-T93](#p19-t93).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Footstep trigger warns then raises soft bristles; bait it and cross recovery. Marked trigger area vs narrow hitbox; rotate 90°. Tune trigger radius/warning/recovery.
  - **Acceptance:** Implement Single default from grid matrix: Anchor: 1×1 footprint; Trigger: 2×2; strike: 3×1 active region. Race/event after Lagsanay floor check; owner only on direct hit; resets armed. Medium-high trigger race risk.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T95

- [ ] **Present Gulat na Walis in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-023](PRD.md#req-item-023--gulat-na-walis). **Dependencies:** [P19-T94](#p19-t94).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T96

- [ ] **Integrate Gulat na Walis ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-023](PRD.md#req-item-023--gulat-na-walis). **Dependencies:** [P19-T94](#p19-t94), [P19-T95](#p19-t95), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T97

- [ ] **Verify Gulat na Walis before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-023](PRD.md#req-item-023--gulat-na-walis). **Dependencies:** [P19-T96](#p19-t96).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Umiikot na Trumpo — `hazard.orbit_trumpo`


#### P19-T98

- [ ] **Approve Umiikot na Trumpo promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-024](PRD.md#req-item-024--umiikot-na-trumpo). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T99

- [ ] **Implement Umiikot na Trumpo definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-024](PRD.md#req-item-024--umiikot-na-trumpo). **Dependencies:** [P19-T98](#p19-t98).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Tethered top sweeps circular zone; time gap around orbit. Tell: visible tether and arc. Pivot footprint vs swept danger region; fixed orbit, 90° start phase. Tune radius/period/width.
  - **Acceptance:** Implement 3×3 or 5×5 sweep; pivot 1×1. Both modes after event test; owner direct hit; resets angle. High sweep collision risk.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T100

- [ ] **Present Umiikot na Trumpo in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-024](PRD.md#req-item-024--umiikot-na-trumpo). **Dependencies:** [P19-T99](#p19-t99).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T101

- [ ] **Integrate Umiikot na Trumpo ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-024](PRD.md#req-item-024--umiikot-na-trumpo). **Dependencies:** [P19-T99](#p19-t99), [P19-T100](#p19-t100), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T102

- [ ] **Verify Umiikot na Trumpo before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-024](PRD.md#req-item-024--umiikot-na-trumpo). **Dependencies:** [P19-T101](#p19-t101).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Niyog Pendulum — `hazard.coconut_pendulum`


#### P19-T103

- [ ] **Approve Niyog Pendulum promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-025](PRD.md#req-item-025--niyog-pendulum). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T104

- [ ] **Implement Niyog Pendulum definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-025](PRD.md#req-item-025--niyog-pendulum). **Dependencies:** [P19-T103](#p19-t103).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Padded coconut swings a predictable arc across a route. Tell: full arc and endpoint pause. Counter: pass behind pivot or time swing. Anchor footprint and arc separate; four start orientations. Tune arc/period/width.
  - **Acceptance:** Implement 3×3 or 5×5 sweep; pivot 1×1. Both modes after Lagsanay safety test; reset endpoint; medium-high mover collision risk.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T105

- [ ] **Present Niyog Pendulum in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-025](PRD.md#req-item-025--niyog-pendulum). **Dependencies:** [P19-T104](#p19-t104).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T106

- [ ] **Integrate Niyog Pendulum ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-025](PRD.md#req-item-025--niyog-pendulum). **Dependencies:** [P19-T104](#p19-t104), [P19-T105](#p19-t105), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T107

- [ ] **Verify Niyog Pendulum before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-025](PRD.md#req-item-025--niyog-pendulum). **Dependencies:** [P19-T106](#p19-t106).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Sipa ng Tsinelas — `hazard.slipper_jab`


#### P19-T108

- [ ] **Approve Sipa ng Tsinelas promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-026](PRD.md#req-item-026--sipa-ng-tsinelas). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T109

- [ ] **Implement Sipa ng Tsinelas definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-026](PRD.md#req-item-026--sipa-ng-tsinelas). **Dependencies:** [P19-T108](#p19-t108).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Pressure/contact trigger launches a short slipper jab. Tell: button compresses and arm winds up. Counter: bait then pass during cooldown. Anchor, trigger zone and fixed jab lane separate; four orientations. Tune range/warning/cooldown.
  - **Acceptance:** Implement Single default from grid matrix: Anchor: 1×1 footprint; Jab lane: 3×1 active region. Race/event; direct strike owner; reset idle. Medium-high projectile/hitbox lifecycle.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T110

- [ ] **Present Sipa ng Tsinelas in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-026](PRD.md#req-item-026--sipa-ng-tsinelas). **Dependencies:** [P19-T109](#p19-t109).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T111

- [ ] **Integrate Sipa ng Tsinelas ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-026](PRD.md#req-item-026--sipa-ng-tsinelas). **Dependencies:** [P19-T109](#p19-t109), [P19-T110](#p19-t110), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T112

- [ ] **Verify Sipa ng Tsinelas before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-026](PRD.md#req-item-026--sipa-ng-tsinelas). **Dependencies:** [P19-T111](#p19-t111).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Gulat na Palayok — `hazard.aiming_pot`


#### P19-T113

- [ ] **Approve Gulat na Palayok promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-027](PRD.md#req-item-027--gulat-na-palayok). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T114

- [ ] **Implement Gulat na Palayok definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-027](PRD.md#req-item-027--gulat-na-palayok). **Dependencies:** [P19-T113](#p19-t113).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Detects a chicken, visibly aims, then releases padded swat. Counter: bait aim then move. Footprint plus limited target range/swat lane; 90° rotate. Tune reacquire, telegraph, range.
  - **Acceptance:** Implement Single default from grid matrix: 1×1 footprint; Aim/swat area: 4×3 active region. Both modes after fairness test; direct hit attribution; resets neutral. High risk: target selection determinism.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T115

- [ ] **Present Gulat na Palayok in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-027](PRD.md#req-item-027--gulat-na-palayok). **Dependencies:** [P19-T114](#p19-t114).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T116

- [ ] **Integrate Gulat na Palayok ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-027](PRD.md#req-item-027--gulat-na-palayok). **Dependencies:** [P19-T114](#p19-t114), [P19-T115](#p19-t115), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T117

- [ ] **Verify Gulat na Palayok before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-027](PRD.md#req-item-027--gulat-na-palayok). **Dependencies:** [P19-T116](#p19-t116).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Tansan Ricochet — `hazard.tansan_ricochet`


#### P19-T118

- [ ] **Approve Tansan Ricochet promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-028](PRD.md#req-item-028--tansan-ricochet). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T119

- [ ] **Implement Tansan Ricochet definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-028](PRD.md#req-item-028--tansan-ricochet). **Dependencies:** [P19-T118](#p19-t118).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Toy cap ricochets a bounded number then expires. Tell: direction preview and bounce count icon. Counter: solid cover/leave lane. Launcher footprint, lane/sweep separate; four orientations. Tune bounce/lifetime/cap/speed.
  - **Acceptance:** Implement Single default from grid matrix: 1×1 footprint; Initial lane: 6×1; maximum bound: 6×4 active region. Both modes only after projectile cap test; launcher owns direct kill; cleanup at end. High risk: deterministic collision and transient count.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T120

- [ ] **Present Tansan Ricochet in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-028](PRD.md#req-item-028--tansan-ricochet). **Dependencies:** [P19-T119](#p19-t119).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T121

- [ ] **Integrate Tansan Ricochet ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-028](PRD.md#req-item-028--tansan-ricochet). **Dependencies:** [P19-T119](#p19-t119), [P19-T120](#p19-t120), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T122

- [ ] **Verify Tansan Ricochet before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-028](PRD.md#req-item-028--tansan-ricochet). **Dependencies:** [P19-T121](#p19-t121).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Niyog Chute — `hazard.coconut_chute`


#### P19-T123

- [ ] **Approve Niyog Chute promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-029](PRD.md#req-item-029--niyog-chute). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T124

- [ ] **Implement Niyog Chute definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-029](PRD.md#req-item-029--niyog-chute). **Dependencies:** [P19-T123](#p19-t123).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Rumble warns before coconuts roll downhill/off ledges. Counter: step out of lane or use cover. Chute anchor and terrain-following lane; rotate 180°. Tune warning, launch interval, speed, cap.
  - **Acceptance:** Implement Single default from grid matrix: Chute: 2×1 footprint; Downhill lane: up to 6×1 active region. Both modes only when direct hit attribution is stable; resets empty. High risk: terrain traversal and transient cleanup.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T125

- [ ] **Present Niyog Chute in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-029](PRD.md#req-item-029--niyog-chute). **Dependencies:** [P19-T124](#p19-t124).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T126

- [ ] **Integrate Niyog Chute ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-029](PRD.md#req-item-029--niyog-chute). **Dependencies:** [P19-T124](#p19-t124), [P19-T125](#p19-t125), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T127

- [ ] **Verify Niyog Chute before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-029](PRD.md#req-item-029--niyog-chute). **Dependencies:** [P19-T126](#p19-t126).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Singaw Steamer — `hazard.steam_burst`


#### P19-T128

- [ ] **Approve Singaw Steamer promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-030](PRD.md#req-item-030--singaw-steamer). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T129

- [ ] **Implement Singaw Steamer definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-030](PRD.md#req-item-030--singaw-steamer). **Dependencies:** [P19-T128](#p19-t128).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Cartoon steam plume blocks passage briefly; no burn imagery. Tell: valve hiss and pressure rise. Counter: cross during cooldown. Emitter footprint and plume rectangle separate; four rotations. Tune warning, reach, duty cycle.
  - **Acceptance:** Implement 2×2 or 3×2 plume. Race/event after Lagsanay test; owner on direct contact elimination; resets depressurized. Medium readability/timing risk.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T130

- [ ] **Present Singaw Steamer in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-030](PRD.md#req-item-030--singaw-steamer). **Dependencies:** [P19-T129](#p19-t129).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T131

- [ ] **Integrate Singaw Steamer ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-030](PRD.md#req-item-030--singaw-steamer). **Dependencies:** [P19-T129](#p19-t129), [P19-T130](#p19-t130), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T132

- [ ] **Verify Singaw Steamer before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-030](PRD.md#req-item-030--singaw-steamer). **Dependencies:** [P19-T131](#p19-t131).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Gulong Kuliglig — `hazard.kuliglig_swarm`


#### P19-T133

- [ ] **Approve Gulong Kuliglig promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-031](PRD.md#req-item-031--gulong-kuliglig). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T134

- [ ] **Implement Gulong Kuliglig definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-031](PRD.md#req-item-031--gulong-kuliglig). **Dependencies:** [P19-T133](#p19-t133).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Fictional noisy insect swarm pursues a visibly marked target briefly. Counter: survive until expiry/route away. Emitter and chase boundary separate; no rotation. Tune target rule, duration, speed, cap.
  - **Acceptance:** Implement Single default from grid matrix: Emitter: 1×1 footprint; Chase boundary: 5×5 active region. Lagsanay disabled initially; race only until fair target policy proves out. Direct source owns elimination. High AI/target-state risk; fictional insect art, no real-species claims.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T135

- [ ] **Present Gulong Kuliglig in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-031](PRD.md#req-item-031--gulong-kuliglig). **Dependencies:** [P19-T134](#p19-t134).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T136

- [ ] **Integrate Gulong Kuliglig ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-031](PRD.md#req-item-031--gulong-kuliglig). **Dependencies:** [P19-T134](#p19-t134), [P19-T135](#p19-t135), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T137

- [ ] **Verify Gulong Kuliglig before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-031](PRD.md#req-item-031--gulong-kuliglig). **Dependencies:** [P19-T136](#p19-t136).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Ipo-Ipo — `hazard.ipo_ipo`


#### P19-T138

- [ ] **Approve Ipo-Ipo promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-032](PRD.md#req-item-032--ipo-ipo). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T139

- [ ] **Implement Ipo-Ipo definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-032](PRD.md#req-item-032--ipo-ipo). **Dependencies:** [P19-T138](#p19-t138).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Bounded visible pull toward small elimination core; strength cap keeps escape possible. Counter: leave radius/use cover if blocking is defined. Core footprint/effect radius separate; no rotation. Tune force/radius/core.
  - **Acceptance:** Implement Single default from grid matrix: Core: 1×1 footprint; Pull radius envelope: 5×5 active region. Both modes only after projectile interaction is excluded or specified; direct core owns kill; resets field. Very high force, bounds, and readability risk.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T140

- [ ] **Present Ipo-Ipo in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-032](PRD.md#req-item-032--ipo-ipo). **Dependencies:** [P19-T139](#p19-t139).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T141

- [ ] **Integrate Ipo-Ipo ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-032](PRD.md#req-item-032--ipo-ipo). **Dependencies:** [P19-T139](#p19-t139), [P19-T140](#p19-t140), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T142

- [ ] **Verify Ipo-Ipo before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-032](PRD.md#req-item-032--ipo-ipo). **Dependencies:** [P19-T141](#p19-t141).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Kambal na Pinto — `move.kambal_na_pinto`


#### P19-T143

- [ ] **Approve Kambal na Pinto promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-033](PRD.md#req-item-033--kambal-na-pinto). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T144

- [ ] **Implement Kambal na Pinto definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-033](PRD.md#req-item-033--kambal-na-pinto). **Dependencies:** [P19-T143](#p19-t143).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Linked fantasy doors relocate a chicken to a clear partner exit. Tell: matched symbol and exit preview. Counter: avoid endpoint or use cooldown window. Pair footprint and exit clearance; rotate each exit in 90° increments. Tune cooldown/exit offset.
  - **Acceptance:** Implement Single default from grid matrix: Each door: 1×2 footprint; Exit clearance: 1×2 per door active region. Race only initially; disable in Lagsanay pending fairness. Pair ownership and removal delete both ends; high risk: pairing, anti-loop, blocked exit.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T145

- [ ] **Present Kambal na Pinto in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-033](PRD.md#req-item-033--kambal-na-pinto). **Dependencies:** [P19-T144](#p19-t144).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T146

- [ ] **Integrate Kambal na Pinto ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-033](PRD.md#req-item-033--kambal-na-pinto). **Dependencies:** [P19-T144](#p19-t144), [P19-T145](#p19-t145), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T147

- [ ] **Verify Kambal na Pinto before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-033](PRD.md#req-item-033--kambal-na-pinto). **Dependencies:** [P19-T146](#p19-t146).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Balsa-Bentilador — `move.balsa_fan`


#### P19-T148

- [ ] **Approve Balsa-Bentilador promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-034](PRD.md#req-item-034--balsa-bentilador). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T149

- [ ] **Implement Balsa-Bentilador definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-034](PRD.md#req-item-034--balsa-bentilador). **Dependencies:** [P19-T148](#p19-t148).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Rideable top with marked hazardous underside. Tell: underside icon and path. Counter: board only from safe side/dismount. Platform solid top, underside trigger, bounded path; fixed orientation. Tune path/force/danger area.
  - **Acceptance:** Implement Single default from grid matrix: Platform: 3×1 footprint; Path/air envelope: 6×4 active region. Disable Lagsanay initially; direct underside hit owner only. Resets endpoint; very high combined mover/force risk.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T150

- [ ] **Present Balsa-Bentilador in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-034](PRD.md#req-item-034--balsa-bentilador). **Dependencies:** [P19-T149](#p19-t149).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T151

- [ ] **Integrate Balsa-Bentilador ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-034](PRD.md#req-item-034--balsa-bentilador). **Dependencies:** [P19-T149](#p19-t149), [P19-T150](#p19-t150), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T152

- [ ] **Verify Balsa-Bentilador before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-034](PRD.md#req-item-034--balsa-bentilador). **Dependencies:** [P19-T151](#p19-t151).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Umiikot na Dram — `move.rotating_drum`


#### P19-T153

- [ ] **Approve Umiikot na Dram promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-035](PRD.md#req-item-035--umiikot-na-dram). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T154

- [ ] **Implement Umiikot na Dram definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-035](PRD.md#req-item-035--umiikot-na-dram). **Dependencies:** [P19-T153](#p19-t153).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Rotating drum changes standing and takeoff timing without attached contraptions. Tell: rotation arrows. Counter: ride with rotation or jump away. Cylindrical support/sweep separate; axis fixed, start angle configurable. Tune speed/radius.
  - **Acceptance:** Implement Single default from grid matrix: 3×3 footprint; Same 3×3 rotation envelope active region. Race/event after Lagsanay test; reset angle; high collision geometry risk.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T155

- [ ] **Present Umiikot na Dram in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-035](PRD.md#req-item-035--umiikot-na-dram). **Dependencies:** [P19-T154](#p19-t154).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T156

- [ ] **Integrate Umiikot na Dram ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-035](PRD.md#req-item-035--umiikot-na-dram). **Dependencies:** [P19-T154](#p19-t154), [P19-T155](#p19-t155), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T157

- [ ] **Verify Umiikot na Dram before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-035](PRD.md#req-item-035--umiikot-na-dram). **Dependencies:** [P19-T156](#p19-t156).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Peryang Traysikel — `hazard.toy_tricycle`


#### P19-T158

- [ ] **Approve Peryang Traysikel promotion and contract**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-036](PRD.md#req-item-036--peryang-traysikel). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T159

- [ ] **Implement Peryang Traysikel definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-036](PRD.md#req-item-036--peryang-traysikel). **Dependencies:** [P19-T158](#p19-t158).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Toy tricycle signals, crosses a fixed lane, waits offstage, repeats. Large body differs from small projectile. Tell: bell/headlight and lane warning. Counter: leave lane or use cover if defined. Spawn anchor and complete lane separate; 0/180° direction. Tune speed/warning/dwell/cap.
  - **Acceptance:** Implement 6×1 or 8×1 lane; body remains 2×1. Both modes only with full lane visible and safe spawn; direct body collision owner; resets offstage. High risk: bounds and large hitbox.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T160

- [ ] **Present Peryang Traysikel in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-036](PRD.md#req-item-036--peryang-traysikel). **Dependencies:** [P19-T159](#p19-t159).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T161

- [ ] **Integrate Peryang Traysikel ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-036](PRD.md#req-item-036--peryang-traysikel). **Dependencies:** [P19-T159](#p19-t159), [P19-T160](#p19-t160), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T162

- [ ] **Verify Peryang Traysikel before pool promotion**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-036](PRD.md#req-item-036--peryang-traysikel). **Dependencies:** [P19-T161](#p19-t161).
  - **Work:** Run family-specific solo and 2/3/4-player mode/stack scenarios, minimum-zoom presentation, capped lifecycle/performance, Library filtering and provenance review. Record evidence, then approve enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Approve unresolved mechanics and a named promotion before implementation; retain documented initial mode restrictions.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P19-T163

- [x] **Implement Barya behavior**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (individual name/capacity assignment remains open).
  - **Requirements:** [REQ-OPT-001](PRD.md#req-opt-001--barya). **Dependencies:** [P19-T01](#p19-t01).
  - **Work:** Add the round-scoped seeded offer, non-persistent placement, one-coin state machine, physics-step pickup, committed elimination drop/recovery, receipt scoring and cleanup. Keep the P07 route disabled and provide a P12 rollback switch.
  - **Acceptance:** Test contested pickup/drop/death/finish, one-coin cap, all-finish exception, stacked races, cleanup/retry identity and disabled seeded parity.
  - **Evidence:** [focused and rendered Barya runs](evidence/barya/README.md), [`run_barya_tests.gd`](../tilaok!/tests/run_barya_tests.gd), and [regression summary](evidence/barya/test_logs/regression_summary.txt). **Verification result:** PASSED — deterministic policy checks and Godot Area2D physics checks pass; no human/device test is claimed.


#### P19-T164

- [x] **Integrate Barya presentation and lifecycle**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Art/UI + Gameplay (individual assignments remain open).
  - **Requirements:** [REQ-OPT-001](PRD.md#req-opt-001--barya). **Dependencies:** [P19-T163](#p19-t163).
  - **Work:** Add DEBUG coin and Pugad preview, live carrier/feedback/results/history cues, conditional Library content and just-in-time tutorial copy. Preserve provenance and do not change the base release contract.
  - **Acceptance:** Confirm live state cues and award rows, enabled/disabled Library filtering, tutorial prompt, cleanup and suppression exception.
  - **Evidence:** [eight rendered loop captures](evidence/barya/README.md#rendered-captures), [P13 HUD/Library/tutorial suites](evidence/barya/test_logs/regression_summary.txt), and [asset handoff](ASSETS.md#barya-debug-placeholder--2026-10-15). **Verification result:** PASSED — synthetic engineering evidence; human UI, art, accessibility and cultural review remain open.


#### P19-T02

- [x] **Verify Barya**
  - **Status:** PASSED · **Kind:** VERIFY · **Scope:** SHOULD · **Owner:** QA (individual reviewer assignment remains open).
  - **Requirements:** [REQ-OPT-001](PRD.md#req-opt-001--barya). **Dependencies:** [P19-T164](#p19-t164).
  - **Work:** Record procedure, expected and actual results, synthetic/physics boundaries, rendering, resource measurements, export and startup smoke.
  - **Acceptance:** Contested pickup/drop/death/finish, one-coin cap, suppression exception, both Karera stacks at 2/3/4 seats, cleanup, retry, disabled pool and export route checks pass.
  - **Evidence:** [Barya verification record](evidence/barya/README.md); [all suite logs](evidence/barya/test_logs/); [performance sample](evidence/barya/barya_performance.txt); [Windows export and smoke logs](evidence/barya/test_logs/). **Verification result:** PASSED — 72 focused assertions (80 with capture-save assertions), 14 dependent suites, Godot 4.7.2 export and route/rollback startup smoke passed. Synthetic input and one developer PC only; no human/device reviewer is claimed.


#### P19-T165

- [ ] **Implement Local session win tally behavior**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-OPT-002](PRD.md#req-opt-002--local-session-win-tally). **Dependencies:** [P19-T03](#p19-t03).
  - **Work:** Optional match-result win tally persists between matches only in current process/session; no account, disk save, cloud sync or migration.
  - **Acceptance:** Replay increments only the actual winner once; lobby return retains session tally; new process clears it; disabled option does not block results.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T166

- [ ] **Integrate Local session win tally presentation and lifecycle**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Art/UI + Gameplay (name TBD).
  - **Requirements:** [REQ-OPT-002](PRD.md#req-opt-002--local-session-win-tally). **Dependencies:** [P19-T165](#p19-t165).
  - **Work:** Connect enabled-content filtering, player instructions/Library, feedback, ownership/reset where relevant and provenance. Do not change the base release contract implicitly.
  - **Acceptance:** Replay increments only the actual winner once; lobby return retains session tally; new process clears it; disabled option does not block results.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T04

- [ ] **Verify local session win tally**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** SHOULD · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-OPT-002](PRD.md#req-opt-002--local-session-win-tally). **Dependencies:** [P19-T166](#p19-t166).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Replay increments only the actual winner once; lobby return retains session tally; new process clears it; disabled option does not block results.
  - **Acceptance:** Replay increments only the actual winner once; lobby return retains session tally; new process clears it; disabled option does not block results.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P19-T167

- [ ] **Implement Enhanced crowd and spectator cheer behavior**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Audio (name TBD).
  - **Requirements:** [REQ-OPT-003](PRD.md#req-opt-003--enhanced-crowd-and-spectator-cheer). **Dependencies:** [P19-T05](#p19-t05).
  - **Work:** Enhanced crowd: rooster start, trap anticipation, soft elimination/fall groan, gasp, finish/Una cheer, none/all-finish reactions, Bawi celebration, late-taya drumroll, final-two tension and winner chant. Optional player-colored fans and tension 0–1 drive ambient mix. Spectator cheer has no simulation effect and prototype 1 s cooldown.
  - **Acceptance:** Each enabled reaction triggers once at the correct moment; no rapid spam/overload, critical cues remain audible/visible and all crowd assets are registered.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T168

- [ ] **Integrate Enhanced crowd and spectator cheer presentation and lifecycle**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Art/UI + Gameplay (name TBD).
  - **Requirements:** [REQ-OPT-003](PRD.md#req-opt-003--enhanced-crowd-and-spectator-cheer). **Dependencies:** [P19-T167](#p19-t167).
  - **Work:** Connect enabled-content filtering, player instructions/Library, feedback, ownership/reset where relevant and provenance. Do not change the base release contract implicitly.
  - **Acceptance:** Each enabled reaction triggers once at the correct moment; no rapid spam/overload, critical cues remain audible/visible and all crowd assets are registered.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T06

- [ ] **Verify enhanced crowd and spectator cheer**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** SHOULD · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-OPT-003](PRD.md#req-opt-003--enhanced-crowd-and-spectator-cheer). **Dependencies:** [P19-T168](#p19-t168).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Each enabled reaction triggers once at the correct moment; no rapid spam/overload, critical cues remain audible/visible and all crowd assets are registered.
  - **Acceptance:** Each enabled reaction triggers once at the correct moment; no rapid spam/overload, critical cues remain audible/visible and all crowd assets are registered.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P19-T169

- [ ] **Implement Reviewed educational cards behavior**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Compliance (name TBD).
  - **Requirements:** [REQ-OPT-004](PRD.md#req-opt-004--reviewed-educational-cards). **Dependencies:** [P19-T07](#p19-t07).
  - **Work:** Optional Alam mo ba cards explain a real traditional game, region and real-life rules before its event using reliable evidence and native-speaker review. Do not describe fictional item/Kangaroo rules as verified tradition.
  - **Acceptance:** Every public claim has reviewed evidence/date; cards are concise/readable and do not misrepresent the implemented adaptation.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T170

- [ ] **Integrate Reviewed educational cards presentation and lifecycle**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Art/UI + Gameplay (name TBD).
  - **Requirements:** [REQ-OPT-004](PRD.md#req-opt-004--reviewed-educational-cards). **Dependencies:** [P19-T169](#p19-t169).
  - **Work:** Connect enabled-content filtering, player instructions/Library, feedback, ownership/reset where relevant and provenance. Do not change the base release contract implicitly.
  - **Acceptance:** Every public claim has reviewed evidence/date; cards are concise/readable and do not misrepresent the implemented adaptation.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T08

- [ ] **Verify reviewed educational cards**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** SHOULD · **Owner:** Compliance (name TBD).
  - **Requirements:** [REQ-OPT-004](PRD.md#req-opt-004--reviewed-educational-cards). **Dependencies:** [P19-T170](#p19-t170).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Every public claim has reviewed evidence/date; cards are concise/readable and do not misrepresent the implemented adaptation.
  - **Acceptance:** Every public claim has reviewed evidence/date; cards are concise/readable and do not misrepresent the implemented adaptation.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P19-T171

- [ ] **Implement Langit-Lupa behavior**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-OPT-005](PRD.md#req-opt-005--langit-lupa). **Dependencies:** [P19-T09](#p19-t09).
  - **Work:** Named second laro ng lahi remains a Should event, not displaced by Kangaroo. Rising floor, survive to end; documented mapping is Tapos for survivors and Una for highest position. Detailed timer/height/tie/stack behavior requires a contract before implementation.
  - **Acceptance:** Approve unresolved rules, then test 2/3/4 players, reachable/blocked layouts, terminal/scoring/reset and tutorial/Library before enablement.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T172

- [ ] **Integrate Langit-Lupa presentation and lifecycle**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Art/UI + Gameplay (name TBD).
  - **Requirements:** [REQ-OPT-005](PRD.md#req-opt-005--langit-lupa). **Dependencies:** [P19-T171](#p19-t171).
  - **Work:** Connect enabled-content filtering, player instructions/Library, feedback, ownership/reset where relevant and provenance. Do not change the base release contract implicitly.
  - **Acceptance:** Approve unresolved rules, then test 2/3/4 players, reachable/blocked layouts, terminal/scoring/reset and tutorial/Library before enablement.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T10

- [ ] **Verify langit-lupa**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** SHOULD · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-OPT-005](PRD.md#req-opt-005--langit-lupa). **Dependencies:** [P19-T172](#p19-t172).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Approve unresolved rules, then test 2/3/4 players, reachable/blocked layouts, terminal/scoring/reset and tutorial/Library before enablement.
  - **Acceptance:** Approve unresolved rules, then test 2/3/4 players, reachable/blocked layouts, terminal/scoring/reset and tutorial/Library before enablement.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P19-T173

- [ ] **Implement Cosmetic skins and accessories behavior**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-OPT-006](PRD.md#req-opt-006--cosmetic-skins-and-accessories). **Dependencies:** [P19-T11](#p19-t11).
  - **Work:** Distinct chicken color/shape identity is required; richer skins/accessories beyond the required readable set are optional. Preserve marker visibility, wholesome silhouettes and asset/cultural provenance.
  - **Acceptance:** Optional cosmetics cannot obscure chicken number/shape or hazards, affect collisions, or imply gameplay advantages.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T174

- [ ] **Integrate Cosmetic skins and accessories presentation and lifecycle**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Art/UI + Gameplay (name TBD).
  - **Requirements:** [REQ-OPT-006](PRD.md#req-opt-006--cosmetic-skins-and-accessories). **Dependencies:** [P19-T173](#p19-t173).
  - **Work:** Connect enabled-content filtering, player instructions/Library, feedback, ownership/reset where relevant and provenance. Do not change the base release contract implicitly.
  - **Acceptance:** Optional cosmetics cannot obscure chicken number/shape or hazards, affect collisions, or imply gameplay advantages.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T12

- [ ] **Verify cosmetic skins and accessories**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** SHOULD · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-OPT-006](PRD.md#req-opt-006--cosmetic-skins-and-accessories). **Dependencies:** [P19-T174](#p19-t174).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Optional cosmetics cannot obscure chicken number/shape or hazards, affect collisions, or imply gameplay advantages.
  - **Acceptance:** Optional cosmetics cannot obscure chicken number/shape or hazards, affect collisions, or imply gameplay advantages.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P19-T175

- [ ] **Implement Luksong Tinik / 10–20 Garter behavior**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-BACKLOG-001](PRD.md#req-backlog-001--luksong-tinik--1020-garter). **Dependencies:** [P19-T13](#p19-t13).
  - **Work:** Compare and choose one implementation family; define telegraph, sweep/thickness, platform interaction, avoidance and anti-camping. Existing Luksong Tinik mapping is survive all waves for Tapos, no Una.
  - **Acceptance:** Approved comparison and contract precede code; 2/3/4-player avoidance, scoring, reset and help pass.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T176

- [ ] **Integrate Luksong Tinik / 10–20 Garter presentation and lifecycle**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI + Gameplay (name TBD).
  - **Requirements:** [REQ-BACKLOG-001](PRD.md#req-backlog-001--luksong-tinik--1020-garter). **Dependencies:** [P19-T175](#p19-t175).
  - **Work:** Connect enabled-content filtering, player instructions/Library, feedback, ownership/reset where relevant and provenance. Do not change the base release contract implicitly.
  - **Acceptance:** Approved comparison and contract precede code; 2/3/4-player avoidance, scoring, reset and help pass.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T14

- [ ] **Verify luksong tinik / 10–20 garter**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-BACKLOG-001](PRD.md#req-backlog-001--luksong-tinik--1020-garter). **Dependencies:** [P19-T176](#p19-t176).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Approved comparison and contract precede code; 2/3/4-player avoidance, scoring, reset and help pass.
  - **Acceptance:** Approved comparison and contract precede code; 2/3/4-player avoidance, scoring, reset and help pass.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P19-T177

- [ ] **Implement Agawan Buko / Jackstone comparison behavior**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-BACKLOG-002](PRD.md#req-backlog-002--agawan-buko--jackstone-comparison). **Dependencies:** [P19-T15](#p19-t15).
  - **Work:** Agawan Buko remains coconut collection: holding at least one at end gives Tapos, most gives Una. Compare Jackstone without automatic replacement; define supply/quota by count, reachable spawns, contested collection, elimination drops and impossible-quota recovery.
  - **Acceptance:** Resolve ties and collection/ownership rules, then verify all counts, clutter, drops and impossible quotas before enablement.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T178

- [ ] **Integrate Agawan Buko / Jackstone comparison presentation and lifecycle**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI + Gameplay (name TBD).
  - **Requirements:** [REQ-BACKLOG-002](PRD.md#req-backlog-002--agawan-buko--jackstone-comparison). **Dependencies:** [P19-T177](#p19-t177).
  - **Work:** Connect enabled-content filtering, player instructions/Library, feedback, ownership/reset where relevant and provenance. Do not change the base release contract implicitly.
  - **Acceptance:** Resolve ties and collection/ownership rules, then verify all counts, clutter, drops and impossible quotas before enablement.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T16

- [ ] **Verify agawan buko / jackstone comparison**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-BACKLOG-002](PRD.md#req-backlog-002--agawan-buko--jackstone-comparison). **Dependencies:** [P19-T178](#p19-t178).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Resolve ties and collection/ownership rules, then verify all counts, clutter, drops and impossible quotas before enablement.
  - **Acceptance:** Resolve ties and collection/ownership rules, then verify all counts, clutter, drops and impossible quotas before enablement.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P19-T179

- [ ] **Implement Sipa behavior**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-BACKLOG-003](PRD.md#req-backlog-003--sipa). **Dependencies:** [P19-T17](#p19-t17).
  - **Work:** Prototype only after choosing responsibility rules that do not punish the player keeping the ball aloft. Define contact credit, equal distance, body collision, bounds/unreachable recovery and terminal scoring.
  - **Acceptance:** Approved responsibility and recovery contract plus 2/3/4-player fairness/reset evidence precedes pool inclusion.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T180

- [ ] **Integrate Sipa presentation and lifecycle**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI + Gameplay (name TBD).
  - **Requirements:** [REQ-BACKLOG-003](PRD.md#req-backlog-003--sipa). **Dependencies:** [P19-T179](#p19-t179).
  - **Work:** Connect enabled-content filtering, player instructions/Library, feedback, ownership/reset where relevant and provenance. Do not change the base release contract implicitly.
  - **Acceptance:** Approved responsibility and recovery contract plus 2/3/4-player fairness/reset evidence precedes pool inclusion.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T18

- [ ] **Verify sipa**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-BACKLOG-003](PRD.md#req-backlog-003--sipa). **Dependencies:** [P19-T180](#p19-t180).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Approved responsibility and recovery contract plus 2/3/4-player fairness/reset evidence precedes pool inclusion.
  - **Acceptance:** Approved responsibility and recovery contract plus 2/3/4-player fairness/reset evidence precedes pool inclusion.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P19-T181

- [ ] **Implement Additional stages and event pairs behavior**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-BACKLOG-004](PRD.md#req-backlog-004--additional-stages-and-event-pairs). **Dependencies:** [P19-T19](#p19-t19).
  - **Work:** Extra stages and unlisted Main/Twist pairs are expansion. Each pair needs written input/collision/terminal/scoring/secured-state/presentation compatibility; each stage needs protected zones, bounds/support/readability and device/performance tests.
  - **Acceptance:** New content remains disabled until a named promotion and complete compatibility/quality evidence; no silent third concurrent event.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T182

- [ ] **Integrate Additional stages and event pairs presentation and lifecycle**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI + Gameplay (name TBD).
  - **Requirements:** [REQ-BACKLOG-004](PRD.md#req-backlog-004--additional-stages-and-event-pairs). **Dependencies:** [P19-T181](#p19-t181).
  - **Work:** Connect enabled-content filtering, player instructions/Library, feedback, ownership/reset where relevant and provenance. Do not change the base release contract implicitly.
  - **Acceptance:** New content remains disabled until a named promotion and complete compatibility/quality evidence; no silent third concurrent event.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T20

- [ ] **Verify additional stages and event pairs**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** EXPANSION · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-BACKLOG-004](PRD.md#req-backlog-004--additional-stages-and-event-pairs). **Dependencies:** [P19-T182](#p19-t182).
  - **Work:** Record the procedure, expected and actual result, and review evidence. New content remains disabled until a named promotion and complete compatibility/quality evidence; no silent third concurrent event.
  - **Acceptance:** New content remains disabled until a named promotion and complete compatibility/quality evidence; no silent third concurrent event.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


## Traceability matrix

All requirements have both implementation/non-code deliverables and verification. Task dependencies, not a phase-wide barrier, determine safe order.

| PRD requirement | Implementation / non-code tasks | Verification tasks | Scope |
|---|---|---|---|
| [REQ-PROD-001](PRD.md#req-prod-001--confirm-registered-owners-and-available-capacity) | [P00-T01](#p00-t01) | [P00-T02](#p00-t02) | REQUIRED |
| [REQ-PROD-002](PRD.md#req-prod-002--ratify-the-release-manifest-and-document-authority) | [P00-T03](#p00-t03) | [P00-T04](#p00-t04) | REQUIRED |
| [REQ-PROD-003](PRD.md#req-prod-003--resolve-toolchain-and-hardware-facts) | [P00-T05](#p00-t05) | [P00-T06](#p00-t06) | REQUIRED |
| [REQ-TECH-001](PRD.md#req-tech-001--establish-team-directed-project-responsibilities) | [P01-T01](#p01-t01) | [P01-T02](#p01-t02) | REQUIRED |
| [REQ-CONFIG-001](PRD.md#req-config-001--centralize-provisional-configuration-and-profiles) | [P01-T03](#p01-t03) | [P01-T04](#p01-t04) | REQUIRED |
| [REQ-CONFIG-002](PRD.md#req-config-002--validate-content-pools-and-deterministic-diagnostics) | [P01-T05](#p01-t05) | [P01-T06](#p01-t06) | REQUIRED |
| [REQ-TECH-002](PRD.md#req-tech-002--provide-lifecycle-and-diagnostic-harnesses) | [P01-T07](#p01-t07) | [P01-T08](#p01-t08) | REQUIRED |
| [REQ-EXPORT-001](PRD.md#req-export-001--prove-an-early-pc-export-path) | [P01-T09](#p01-t09) | [P01-T10](#p01-t10) | REQUIRED |
| [REQ-INPUT-001](PRD.md#req-input-001--assign-devices-and-fixed-chicken-identity) | [P02-T01](#p02-t01) | [P02-T02](#p02-t02) | REQUIRED |
| [REQ-INPUT-002](PRD.md#req-input-002--implement-phase-specific-bindings-and-shared-keyboard-fallback) | [P02-T03](#p02-t03) | [P02-T04](#p02-t04) | REQUIRED |
| [REQ-INPUT-003](PRD.md#req-input-003--consume-held-presses-across-phase-transitions) | [P02-T05](#p02-t05) | [P02-T06](#p02-t06) | REQUIRED |
| [REQ-INPUT-004](PRD.md#req-input-004--pause-and-reclaim-disconnected-seats-safely) | [P02-T07](#p02-t07) | [P02-T08](#p02-t08) | REQUIRED |
| [REQ-MOVE-001](PRD.md#req-move-001--implement-responsive-run-and-jump-only) | [P02-T09](#p02-t09) | [P02-T10](#p02-t10) | REQUIRED |
| [REQ-MOVE-002](PRD.md#req-move-002--separate-body-collision-contact-and-intentional-input) | [P02-T11](#p02-t11) | [P02-T12](#p02-t12) | REQUIRED |
| [REQ-MOVE-003](PRD.md#req-move-003--contain-players-and-expose-invalid-escapes) | [P02-T13](#p02-t13) | [P02-T14](#p02-t14) | REQUIRED |
| [REQ-MOVE-004](PRD.md#req-move-004--slide-on-eligible-walls-and-kick-away-with-a-fresh-jump-press) | [P02-T15](#p02-t15), [P02-T17](#p02-t17), [P02-T19](#p02-t19), [P02-T21](#p02-t21) | [P02-T16](#p02-t16), [P02-T18](#p02-t18), [P02-T20](#p02-t20), [P02-T22](#p02-t22) | SHOULD |
| [REQ-MOVE-005](PRD.md#req-move-005--sneak-into-a-one-tile-body-and-glide-while-holding-jump) | [P02-T24](#p02-t24) | [P02-T26](#p02-t26) | SHOULD |
| [REQ-STAGE-004](PRD.md#req-stage-004--64-px-tile-stage-and-scene-authored-stage-blocks) | [P02-T23](#p02-t23), [P02-T25](#p02-t25) | [P02-T26](#p02-t26) | SHOULD |
| [REQ-STAGE-005](PRD.md#req-stage-005--scene-authored-block-catalog-with-kill-and-stun-hitboxes) | [P02-T27](#p02-t27), [P02-T28](#p02-t28), [P02-T30](#p02-t30), [P02-T31](#p02-t31), [P02-T32](#p02-t32) | [P02-T29](#p02-t29) | SHOULD |
| [REQ-STAGE-001](PRD.md#req-stage-001--build-one-protected-barrio-graybox-arena) | [P03-T01](#p03-t01) | [P03-T02](#p03-t02) | REQUIRED |
| [REQ-STAGE-002](PRD.md#req-stage-002--frame-active-players-and-unfinished-placement-pointers) | [P03-T03](#p03-t03) | [P03-T04](#p03-t04) | REQUIRED |
| [REQ-STAGE-003](PRD.md#req-stage-003--track-actual-supporting-contact-and-construction-provenance) | [P03-T05](#p03-t05) | [P03-T06](#p03-t06) | REQUIRED |
| [REQ-ITEMSYS-001](PRD.md#req-itemsys-001--define-item-metadata-and-bounded-regions) | [P04-T01](#p04-t01) | [P04-T02](#p04-t02) | REQUIRED |
| [REQ-ITEMSYS-002](PRD.md#req-itemsys-002--implement-persistent-items-and-bounded-transient-lifecycle) | [P04-T03](#p04-t03) | [P04-T04](#p04-t04) | REQUIRED |
| [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews) | [P05-T01](#p05-t01), [P04-T10](#p04-t10), [P04-T19](#p04-t19), [P10-T06](#p10-t06), [P10-T15](#p10-t15), [P10-T24](#p10-t24), [P10-T33](#p10-t33), [P10-T42](#p10-t42), [P10-T51](#p10-t51) | [P05-T02](#p05-t02) | REQUIRED |
| [REQ-PUGAD-002](PRD.md#req-pugad-002--resolve-simultaneous-egg-claims-and-timeouts) | [P05-T03](#p05-t03) | [P05-T04](#p05-t04) | REQUIRED |
| [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons) | [P05-T05](#p05-t05), [P04-T10](#p04-t10), [P04-T19](#p04-t19), [P10-T06](#p10-t06), [P10-T15](#p10-t15), [P10-T24](#p10-t24), [P10-T33](#p10-t33), [P10-T42](#p10-t42), [P10-T51](#p10-t51) | [P05-T06](#p05-t06) | REQUIRED |
| [REQ-PLACE-002](PRD.md#req-place-002--commit-placement-and-cleanup-atomically) | [P05-T07](#p05-t07) | [P05-T08](#p05-t08) | REQUIRED |
| [REQ-PLACE-003](PRD.md#req-place-003--handle-phase-timing-and-persistent-construction) | [P05-T09](#p05-t09) | [P05-T10](#p05-t10) | REQUIRED |
| [REQ-RACE-001](PRD.md#req-race-001--resolve-karera-finish-failure-and-deadlines) | [P06-T01](#p06-t01) | [P06-T02](#p06-t02) | REQUIRED |
| [REQ-SCORE-001](PRD.md#req-score-001--record-one-terminal-outcome-and-direct-attribution) | [P06-T03](#p06-t03) | [P06-T04](#p06-t04) | REQUIRED |
| [REQ-SCORE-002](PRD.md#req-score-002--calculate-race-awards-and-suppression-exactly) | [P06-T05](#p06-t05) | [P06-T06](#p06-t06) | REQUIRED |
| [REQ-SCORE-003](PRD.md#req-score-003--store-elimination-placement-ties-without-rounding) | [P06-T07](#p06-t07) | [P06-T08](#p06-t08) | REQUIRED |
| [REQ-UI-001](PRD.md#req-ui-001--provide-minimal-join-round-results-and-next-round-flow) | [P05-T11](#p05-t11) | [P05-T12](#p05-t12) | REQUIRED |
| [REQ-SLICE-001](PRD.md#req-slice-001--demonstrate-the-first-playable-buildrace-loop) | [P07-T01](#p07-t01) | [P07-T02](#p07-t02) | REQUIRED |
| [REQ-SLICE-002](PRD.md#req-slice-002--extend-slice-coverage-to-three-and-four-players) | [P07-T03](#p07-t03) | [P07-T04](#p07-t04) | REQUIRED |
| [REQ-LAG-001](PRD.md#req-lag-001--implement-opening-taya-contact-passing-and-countdown) | [P08-T01](#p08-t01) | [P08-T02](#p08-t02) | REQUIRED |
| [REQ-LAG-002](PRD.md#req-lag-002--resolve-lagsanay-eliminations-and-placements) | [P08-T03](#p08-t03) | [P08-T04](#p08-t04) | REQUIRED |
| [REQ-LAG-003](PRD.md#req-lag-003--select-exactly-one-last-cluck-winner) | [P08-T05](#p08-t05) | [P08-T06](#p08-t06) | REQUIRED |
| [REQ-MATCH-001](PRD.md#req-match-001--finish-matches-and-run-tied-player-sudden-death) | [P09-T01](#p09-t01) | [P09-T02](#p09-t02) | REQUIRED |
| [REQ-MATCH-002](PRD.md#req-match-002--replay-return-to-lobby-and-reset-all-match-state) | [P09-T03](#p09-t03), [P13-T13](#p13-t13) | [P09-T04](#p09-t04), [P13-T14](#p13-t14) | REQUIRED |
| [REQ-KANG-001](PRD.md#req-kang-001--present-and-schedule-independent-kangaroo-commands) | [P11-T01](#p11-t01), [P11-T13](#p11-t13) | [P11-T02](#p11-t02) | REQUIRED |
| [REQ-KANG-002](PRD.md#req-kang-002--evaluate-freeze-from-intentional-input) | [P11-T03](#p11-t03) | [P11-T04](#p11-t04) | REQUIRED |
| [REQ-KANG-003](PRD.md#req-kang-003--evaluate-rising-wave-with-actual-built-support) | [P11-T05](#p11-t05) | [P11-T06](#p11-t06) | REQUIRED |
| [REQ-KANG-004](PRD.md#req-kang-004--evaluate-pair-only-hug-deterministically) | [P11-T07](#p11-t07) | [P11-T08](#p11-t08) | REQUIRED |
| [REQ-KANG-005](PRD.md#req-kang-005--integrate-failure-markers-elimination-and-cleanup) | [P11-T09](#p11-t09) | [P11-T10](#p11-t10) | REQUIRED |
| [REQ-KANG-006](PRD.md#req-kang-006--implement-no-elimination-acceleration-and-slipper-storm) | [P11-T11](#p11-t11) | [P11-T12](#p11-t12) | REQUIRED |
| [REQ-EVENT-001](PRD.md#req-event-001--select-and-announce-the-required-event-schedule) | [P12-T01](#p12-t01) | [P12-T02](#p12-t02) | REQUIRED |
| [REQ-EVENT-002](PRD.md#req-event-002--review-unresolved-simultaneous-terminal-ordering) | [P12-T03](#p12-t03) | [P12-T04](#p12-t04) | REQUIRED |
| [REQ-STACK-001](PRD.md#req-stack-001--integrate-karera-with-lagsanay-pressure) | [P12-T05](#p12-t05) | [P12-T06](#p12-t06) | REQUIRED |
| [REQ-STACK-002](PRD.md#req-stack-002--integrate-karera-with-kangaroo-pressure) | [P12-T07](#p12-t07) | [P12-T08](#p12-t08) | REQUIRED |
| [REQ-STACK-003](PRD.md#req-stack-003--integrate-kangaroo-with-lagsanay-pressure) | [P12-T09](#p12-t09) | [P12-T10](#p12-t10) | REQUIRED |
| [REQ-UI-002](PRD.md#req-ui-002--complete-title-menus-settings-and-navigation) | [P13-T01](#p13-t01) | [P13-T02](#p13-t02) | REQUIRED |
| [REQ-UI-003](PRD.md#req-ui-003--explain-current-play-and-results-in-the-hud) | [P13-T03](#p13-t03), [P13-T13](#p13-t13) | [P13-T04](#p13-t04), [P13-T14](#p13-t14) | REQUIRED |
| [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries) | [P13-T05](#p13-t05), [P04-T12](#p04-t12), [P04-T21](#p04-t21), [P10-T08](#p10-t08), [P10-T17](#p10-t17), [P10-T26](#p10-t26), [P10-T35](#p10-t35), [P10-T44](#p10-t44), [P10-T53](#p10-t53) | [P13-T06](#p13-t06) | REQUIRED |
| [REQ-TUTORIAL-001](PRD.md#req-tutorial-001--teach-the-first-round-and-later-event-rules) | [P13-T07](#p13-t07) | [P13-T08](#p13-t08) | REQUIRED |
| [REQ-ACCESS-001](PRD.md#req-access-001--maintain-color-independent-readable-play) | [P13-T09](#p13-t09) | [P13-T10](#p13-t10) | REQUIRED |
| [REQ-ART-001](PRD.md#req-art-001--deliver-original-chicken-stage-and-interface-presentation) | [P14-T01](#p14-t01) | [P14-T02](#p14-t02) | REQUIRED |
| [REQ-AUDIO-001](PRD.md#req-audio-001--deliver-essential-sound-and-music-feedback) | [P14-T03](#p14-t03) | [P14-T04](#p14-t04) | REQUIRED |
| [REQ-ASSET-001](PRD.md#req-asset-001--maintain-asset-and-cultural-provenance) | [P14-T05](#p14-t05) | [P14-T06](#p14-t06) | REQUIRED |
| [REQ-QA-001](PRD.md#req-qa-001--run-balance-sessions-and-first-batch-interaction-checks) | [P15-T01](#p15-t01) | [P15-T02](#p15-t02) | REQUIRED |
| [REQ-QA-002](PRD.md#req-qa-002--complete-physical-device-and-regression-coverage) | [P15-T03](#p15-t03) | [P15-T04](#p15-t04) | REQUIRED |
| [REQ-PERF-001](PRD.md#req-perf-001--measure-frame-time-memory-and-bounded-cleanup) | [P15-T05](#p15-t05) | [P15-T06](#p15-t06) | REQUIRED |
| [REQ-RELEASE-001](PRD.md#req-release-001--freeze-approved-content-and-close-critical-defects) | [P16-T01](#p16-t01) | [P16-T02](#p16-t02) | REQUIRED |
| [REQ-EXPORT-002](PRD.md#req-export-002--package-and-verify-the-final-game-on-a-clean-pc) | [P16-T03](#p16-t03) | [P16-T04](#p16-t04) | REQUIRED |
| [REQ-SUB-001](PRD.md#req-sub-001--prepare-registration-and-official-forms) | [P17-T01](#p17-t01) | [P17-T02](#p17-t02) | REQUIRED |
| [REQ-SUB-002](PRD.md#req-sub-002--write-the-synopsis-and-plan-media-capture-early) | [P17-T03](#p17-t03) | [P17-T04](#p17-t04) | REQUIRED |
| [REQ-SUB-003](PRD.md#req-sub-003--produce-captioned-trailer-and-explanatory-demo) | [P17-T05](#p17-t05) | [P17-T06](#p17-t06) | REQUIRED |
| [REQ-SUB-004](PRD.md#req-sub-004--review-submit-and-preserve-delivery-evidence) | [P17-T07](#p17-t07) | [P17-T08](#p17-t08) | REQUIRED |
| [REQ-SUB-005](PRD.md#req-sub-005--hand-off-source-build-and-operating-instructions) | [P17-T09](#p17-t09) | [P17-T10](#p17-t10) | REQUIRED |
| [REQ-FINAL-001](PRD.md#req-final-001--prepare-qualification-dependent-finalist-materials) | [P18-T01](#p18-t01) | [P18-T02](#p18-t02) | CONDITIONAL |
| [REQ-FINAL-002](PRD.md#req-final-002--rehearse-and-deliver-the-finalist-demonstration) | [P18-T03](#p18-t03) | [P18-T04](#p18-t04) | CONDITIONAL |
| [REQ-OPT-001](PRD.md#req-opt-001--barya) | [P19-T01](#p19-t01), [P19-T163](#p19-t163), [P19-T164](#p19-t164) | [P19-T02](#p19-t02) | SHOULD |
| [REQ-OPT-002](PRD.md#req-opt-002--local-session-win-tally) | [P19-T03](#p19-t03), [P19-T165](#p19-t165), [P19-T166](#p19-t166) | [P19-T04](#p19-t04) | SHOULD |
| [REQ-OPT-003](PRD.md#req-opt-003--enhanced-crowd-and-spectator-cheer) | [P19-T05](#p19-t05), [P19-T167](#p19-t167), [P19-T168](#p19-t168) | [P19-T06](#p19-t06) | SHOULD |
| [REQ-OPT-004](PRD.md#req-opt-004--reviewed-educational-cards) | [P19-T07](#p19-t07), [P19-T169](#p19-t169), [P19-T170](#p19-t170) | [P19-T08](#p19-t08) | SHOULD |
| [REQ-OPT-005](PRD.md#req-opt-005--langit-lupa) | [P19-T09](#p19-t09), [P19-T171](#p19-t171), [P19-T172](#p19-t172) | [P19-T10](#p19-t10) | SHOULD |
| [REQ-OPT-006](PRD.md#req-opt-006--cosmetic-skins-and-accessories) | [P19-T11](#p19-t11), [P19-T173](#p19-t173), [P19-T174](#p19-t174) | [P19-T12](#p19-t12) | SHOULD |
| [REQ-BACKLOG-001](PRD.md#req-backlog-001--luksong-tinik--1020-garter) | [P19-T13](#p19-t13), [P19-T175](#p19-t175), [P19-T176](#p19-t176) | [P19-T14](#p19-t14) | EXPANSION |
| [REQ-BACKLOG-002](PRD.md#req-backlog-002--agawan-buko--jackstone-comparison) | [P19-T15](#p19-t15), [P19-T177](#p19-t177), [P19-T178](#p19-t178) | [P19-T16](#p19-t16) | EXPANSION |
| [REQ-BACKLOG-003](PRD.md#req-backlog-003--sipa) | [P19-T17](#p19-t17), [P19-T179](#p19-t179), [P19-T180](#p19-t180) | [P19-T18](#p19-t18) | EXPANSION |
| [REQ-BACKLOG-004](PRD.md#req-backlog-004--additional-stages-and-event-pairs) | [P19-T19](#p19-t19), [P19-T181](#p19-t181), [P19-T182](#p19-t182) | [P19-T20](#p19-t20) | EXPANSION |
| [REQ-BACKLOG-005](PRD.md#req-backlog-005--retain-parked-events-and-earlier-brainstorm-dispositions) | [P19-T21](#p19-t21) | [P19-T22](#p19-t22) | EXPANSION |
| [REQ-UI-004](PRD.md#req-ui-004--retain-spectator-cheer-without-gameplay-effects) | [P13-T11](#p13-t11) | [P13-T12](#p13-t12) | REQUIRED |
| [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack) | [P04-T05](#p04-t05), [P04-T06](#p04-t06), [P04-T07](#p04-t07), [P04-T08](#p04-t08), [P04-T10](#p04-t10), [P04-T11](#p04-t11), [P04-T12](#p04-t12) | [P04-T09](#p04-t09), [P04-T13](#p04-t13) | REQUIRED |
| [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan) | [P04-T14](#p04-t14), [P04-T15](#p04-t15), [P04-T16](#p04-t16), [P04-T17](#p04-t17), [P04-T19](#p04-t19), [P04-T20](#p04-t20), [P04-T21](#p04-t21) | [P04-T18](#p04-t18), [P04-T22](#p04-t22) | REQUIRED |
| [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon) | [P10-T01](#p10-t01), [P10-T02](#p10-t02), [P10-T03](#p10-t03), [P10-T04](#p10-t04), [P10-T06](#p10-t06), [P10-T07](#p10-t07), [P10-T08](#p10-t08) | [P10-T05](#p10-t05), [P10-T09](#p10-t09) | REQUIRED |
| [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles) | [P10-T10](#p10-t10), [P10-T11](#p10-t11), [P10-T12](#p10-t12), [P10-T13](#p10-t13), [P10-T15](#p10-t15), [P10-T16](#p10-t16), [P10-T17](#p10-t17) | [P10-T14](#p10-t14), [P10-T18](#p10-t18) | REQUIRED |
| [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse) | [P10-T19](#p10-t19), [P10-T20](#p10-t20), [P10-T21](#p10-t21), [P10-T22](#p10-t22), [P10-T24](#p10-t24), [P10-T25](#p10-t25), [P10-T26](#p10-t26) | [P10-T23](#p10-t23), [P10-T27](#p10-t27) | REQUIRED |
| [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher) | [P10-T28](#p10-t28), [P10-T29](#p10-t29), [P10-T30](#p10-t30), [P10-T31](#p10-t31), [P10-T33](#p10-t33), [P10-T34](#p10-t34), [P10-T35](#p10-t35) | [P10-T32](#p10-t32), [P10-T36](#p10-t36) | REQUIRED |
| [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup) | [P10-T37](#p10-t37), [P10-T38](#p10-t38), [P10-T39](#p10-t39), [P10-T40](#p10-t40), [P10-T42](#p10-t42), [P10-T43](#p10-t43), [P10-T44](#p10-t44) | [P10-T41](#p10-t41), [P10-T45](#p10-t45) | REQUIRED |
| [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak) | [P10-T46](#p10-t46), [P10-T47](#p10-t47), [P10-T48](#p10-t48), [P10-T49](#p10-t49), [P10-T51](#p10-t51), [P10-T52](#p10-t52), [P10-T53](#p10-t53) | [P10-T50](#p10-t50), [P10-T54](#p10-t54) | REQUIRED |
| [REQ-ITEM-009](PRD.md#req-item-009--hagdan-ng-bahay) | [P19-T23](#p19-t23), [P19-T24](#p19-t24), [P19-T25](#p19-t25), [P19-T26](#p19-t26) | [P19-T27](#p19-t27) | EXPANSION |
| [REQ-ITEM-010](PRD.md#req-item-010--sulok-na-kawayan) | [P19-T28](#p19-t28), [P19-T29](#p19-t29), [P19-T30](#p19-t30), [P19-T31](#p19-t31) | [P19-T32](#p19-t32) | EXPANSION |
| [REQ-ITEM-011](PRD.md#req-item-011--marupok-na-papag) | [P19-T33](#p19-t33), [P19-T34](#p19-t34), [P19-T35](#p19-t35), [P19-T36](#p19-t36) | [P19-T37](#p19-t37) | EXPANSION |
| [REQ-ITEM-012](PRD.md#req-item-012--baliktad-na-banig) | [P19-T38](#p19-t38), [P19-T39](#p19-t39), [P19-T40](#p19-t40), [P19-T41](#p19-t41) | [P19-T42](#p19-t42) | EXPANSION |
| [REQ-ITEM-013](PRD.md#req-item-013--balsa-sa-lubid) | [P19-T43](#p19-t43), [P19-T44](#p19-t44), [P19-T45](#p19-t45), [P19-T46](#p19-t46) | [P19-T47](#p19-t47) | EXPANSION |
| [REQ-ITEM-014](PRD.md#req-item-014--angat-kaing) | [P19-T48](#p19-t48), [P19-T49](#p19-t49), [P19-T50](#p19-t50), [P19-T51](#p19-t51) | [P19-T52](#p19-t52) | EXPANSION |
| [REQ-ITEM-015](PRD.md#req-item-015--perya-wheel) | [P19-T53](#p19-t53), [P19-T54](#p19-t54), [P19-T55](#p19-t55), [P19-T56](#p19-t56) | [P19-T57](#p19-t57) | EXPANSION |
| [REQ-ITEM-016](PRD.md#req-item-016--palay-conveyor) | [P19-T58](#p19-t58), [P19-T59](#p19-t59), [P19-T60](#p19-t60), [P19-T61](#p19-t61) | [P19-T62](#p19-t62) | EXPANSION |
| [REQ-ITEM-017](PRD.md#req-item-017--bentilador) | [P19-T63](#p19-t63), [P19-T64](#p19-t64), [P19-T65](#p19-t65), [P19-T66](#p19-t66) | [P19-T67](#p19-t67) | EXPANSION |
| [REQ-ITEM-018](PRD.md#req-item-018--bomba-ng-tubig) | [P19-T68](#p19-t68), [P19-T69](#p19-t69), [P19-T70](#p19-t70), [P19-T71](#p19-t71) | [P19-T72](#p19-t72) | EXPANSION |
| [REQ-ITEM-019](PRD.md#req-item-019--saranggola-ferry) | [P19-T73](#p19-t73), [P19-T74](#p19-t74), [P19-T75](#p19-t75), [P19-T76](#p19-t76) | [P19-T77](#p19-t77) | EXPANSION |
| [REQ-ITEM-020](PRD.md#req-item-020--yelo-ng-sorbetero) | [P19-T78](#p19-t78), [P19-T79](#p19-t79), [P19-T80](#p19-t80), [P19-T81](#p19-t81) | [P19-T82](#p19-t82) | EXPANSION |
| [REQ-ITEM-021](PRD.md#req-item-021--malagkit-patch) | [P19-T83](#p19-t83), [P19-T84](#p19-t84), [P19-T85](#p19-t85), [P19-T86](#p19-t86) | [P19-T87](#p19-t87) | EXPANSION |
| [REQ-ITEM-022](PRD.md#req-item-022--tinik-tinik-strip) | [P19-T88](#p19-t88), [P19-T89](#p19-t89), [P19-T90](#p19-t90), [P19-T91](#p19-t91) | [P19-T92](#p19-t92) | EXPANSION |
| [REQ-ITEM-023](PRD.md#req-item-023--gulat-na-walis) | [P19-T93](#p19-t93), [P19-T94](#p19-t94), [P19-T95](#p19-t95), [P19-T96](#p19-t96) | [P19-T97](#p19-t97) | EXPANSION |
| [REQ-ITEM-024](PRD.md#req-item-024--umiikot-na-trumpo) | [P19-T98](#p19-t98), [P19-T99](#p19-t99), [P19-T100](#p19-t100), [P19-T101](#p19-t101) | [P19-T102](#p19-t102) | EXPANSION |
| [REQ-ITEM-025](PRD.md#req-item-025--niyog-pendulum) | [P19-T103](#p19-t103), [P19-T104](#p19-t104), [P19-T105](#p19-t105), [P19-T106](#p19-t106) | [P19-T107](#p19-t107) | EXPANSION |
| [REQ-ITEM-026](PRD.md#req-item-026--sipa-ng-tsinelas) | [P19-T108](#p19-t108), [P19-T109](#p19-t109), [P19-T110](#p19-t110), [P19-T111](#p19-t111) | [P19-T112](#p19-t112) | EXPANSION |
| [REQ-ITEM-027](PRD.md#req-item-027--gulat-na-palayok) | [P19-T113](#p19-t113), [P19-T114](#p19-t114), [P19-T115](#p19-t115), [P19-T116](#p19-t116) | [P19-T117](#p19-t117) | EXPANSION |
| [REQ-ITEM-028](PRD.md#req-item-028--tansan-ricochet) | [P19-T118](#p19-t118), [P19-T119](#p19-t119), [P19-T120](#p19-t120), [P19-T121](#p19-t121) | [P19-T122](#p19-t122) | EXPANSION |
| [REQ-ITEM-029](PRD.md#req-item-029--niyog-chute) | [P19-T123](#p19-t123), [P19-T124](#p19-t124), [P19-T125](#p19-t125), [P19-T126](#p19-t126) | [P19-T127](#p19-t127) | EXPANSION |
| [REQ-ITEM-030](PRD.md#req-item-030--singaw-steamer) | [P19-T128](#p19-t128), [P19-T129](#p19-t129), [P19-T130](#p19-t130), [P19-T131](#p19-t131) | [P19-T132](#p19-t132) | EXPANSION |
| [REQ-ITEM-031](PRD.md#req-item-031--gulong-kuliglig) | [P19-T133](#p19-t133), [P19-T134](#p19-t134), [P19-T135](#p19-t135), [P19-T136](#p19-t136) | [P19-T137](#p19-t137) | EXPANSION |
| [REQ-ITEM-032](PRD.md#req-item-032--ipo-ipo) | [P19-T138](#p19-t138), [P19-T139](#p19-t139), [P19-T140](#p19-t140), [P19-T141](#p19-t141) | [P19-T142](#p19-t142) | EXPANSION |
| [REQ-ITEM-033](PRD.md#req-item-033--kambal-na-pinto) | [P19-T143](#p19-t143), [P19-T144](#p19-t144), [P19-T145](#p19-t145), [P19-T146](#p19-t146) | [P19-T147](#p19-t147) | EXPANSION |
| [REQ-ITEM-034](PRD.md#req-item-034--balsa-bentilador) | [P19-T148](#p19-t148), [P19-T149](#p19-t149), [P19-T150](#p19-t150), [P19-T151](#p19-t151) | [P19-T152](#p19-t152) | EXPANSION |
| [REQ-ITEM-035](PRD.md#req-item-035--umiikot-na-dram) | [P19-T153](#p19-t153), [P19-T154](#p19-t154), [P19-T155](#p19-t155), [P19-T156](#p19-t156) | [P19-T157](#p19-t157) | EXPANSION |
| [REQ-ITEM-036](PRD.md#req-item-036--peryang-traysikel) | [P19-T158](#p19-t158), [P19-T159](#p19-t159), [P19-T160](#p19-t160), [P19-T161](#p19-t161) | [P19-T162](#p19-t162) | EXPANSION |

## Documentation delivery and implementation boundary

The original PRD/tracker documentation could be complete while gameplay tasks remained open. This policy correction changes documentation and dependency wording; it does not complete gameplay tasks or P00 ownership/capacity gates. Francis and Carlos are recorded as development leads; Shanti handles UI design and game audio; Jorge and Ivie handle game maps and assets. Registration, remaining assignments/capacity and some physical-device facts remain unknown. Those gaps do not impose a project-wide AI-use approval gate. The P02 diagnostic movement/input room already exists; future implementation follows approved scope and genuine technical dependencies.

Documentation verification results are recorded below and summarized in `AI_USAGE.md`. A complete match is not implemented; P01/P02 harnesses and diagnostic rooms have separate evidence above. This documentation correction ran no gameplay tests. Official form/channel/eligibility rechecks remain submission tasks, not claims that current organizer instructions were independently verified here.

## Documentation verification — October 13, 2026 (original PRD/tracker delivery)

These are historical results from the original PRD/tracker documentation delivery, before P01/P02 implementation. They do not describe current task counts or check any game task above.

| Check | Result | Evidence / limit |
|---|---|---|
| Requirement/task IDs and traceability | PASSED | Parsed rendered Markdown: 116 unique requirements, 393 unique tasks, 116 matrix rows; every requirement has work and verification references. |
| Dependencies and scope separation | PASSED | 393-node, 708-edge graph resolves without cycles; no required task depends on deferred Should, expansion or finalist work. |
| Catalog and variants | PASSED | 36 unique design IDs matched to ITEMS: eight required families and 28 expansion groups; approved variants explicitly listed; Barya separate. |
| Lifecycle and delivery coverage | PASSED | Reviewed screens/input/reconnect, seed slice/full match, all three modes/stacks, scoring/ties, Library/tutorial, eight-family lifecycle coverage, presentation/accessibility, quality/export and competition/finalist deliverables. |
| Evidence and source authority | PASSED | All 393 tasks unchecked, initial evidence unavailable; current rules, untested defaults, unknown facts and inactive R1–R4 remain distinct. |
| Local links and anchors | PASSED | Local Markdown target and anchor validation across root/docs, including PRD contents and task/requirement links. External website availability was not tested. |
| Preservation and allowed changes | PASSED | SHA-256 checks of 25 recorded source/reference files unchanged; 16 protected merged-spec/project paths unchanged; exactly eight intended documentation files changed/added. |
| Whitespace and conflict markers | PASSED | git diff --check plus explicit scans of both untracked new documents. |
| Gameplay, controllers, balance, performance and final export | COULD-NOT-RUN | No suitable runnable game exists; target engine/templates, actual devices and named target hardware remain implementation gates. No runtime checks were run merely to validate prose. |

Temporary document assembly/validation tools and their output were kept outside the repository for that historical delivery. At that time, no game code, production asset, prompt file, commit or push was produced.

## Documentation verification — AI workflow correction (October 13, 2026)

These checks cover this policy and tracker correction only. Documentation verification is not gameplay testing.

| Check | Result | Evidence / limit |
|---|---|---|
| Full policy contradiction search | PASSED | Searched all 19 project-owned Markdown files for team-written/team-authored wording, authorship, exception/permission, ownership, eligibility and Form 03 terms. Remaining programming-authorship mentions are current provenance safeguards, scoped P01/P02 history, external §7/§8 notes, genuine human-review/ownership requirements, or unrelated gameplay uses of “exception.” |
| Standing workflow consistency | PASSED | AGENTS.md and CLAUDE.md contain the canonical operational policy. Francis/Carlos development roles and AI-assisted programming are recorded; AI_USAGE identifies generated P01/P02 programming and does not select/sign Form 03 extent. |
| Competition-rule separation | PASSED | COMPETITION.md retains the local §7/§8 summary, labels the old internal interpretation as superseded, and makes no organizer-approval or eligibility claim. The source PDF/stable official URL is unavailable in this checkout, so the rule text was not independently rechecked here. |
| Markdown links and anchors | PASSED | Validated local file targets and anchors across all 19 project-owned Markdown files. |
| Requirement/task IDs and counts | PASSED | 116 unique requirements and 393 unique task IDs; task scopes count Required 207, Should 24, Conditional 4, Expansion 158. Checkboxes remain 17/393 (P00 0/6, P01 9/10, P02 8/14); this correction checked no gameplay or review item. |
| Dependencies | PASSED | All referenced task IDs resolve and the dependency graph has no cycles. P01-T02 is no longer an implementation dependency. The P01-T01/P00-T06 and P02-T05/P02-T03 relationships are documented against their already-verified technical implementation subsets; residual owner/device and physical-keyboard acceptance remain open. |
| Requested policy checks | PASSED | AGENTS and CLAUDE permit approved core-gameplay programming without another phase exception; current names/roles, AI disclosure, external-rule uncertainty, human review, synthetic-vs-physical limits and P02 implementation status are explicit. |
| Whitespace and change scope | PASSED | `git diff --check` passed. Final review found Markdown-only edits; no gameplay source, assets, engine configuration or unrelated files changed. |
| Gameplay/runtime verification | COULD-NOT-RUN | No gameplay tests were run for this documentation correction. Existing P02 synthetic evidence does not substitute for open physical controller, keyboard-rollover, reconnect or exported interactive-input checks. |

## Documentation verification — production role clarification (October 13, 2026)

These checks cover the user-supplied UI, audio and game-asset role clarification. They do not change gameplay scope or complete P00.

| Check | Result | Evidence / limit |
|---|---|---|
| Current roles and names | PASSED | PRODUCTION.md, AI_USAGE.md, PRD.md and P00 records list Francis/Carlos as development leads, Shanti for UI design and game audio, and Jorge/Ivie for maps, characters, obstacles, traps, effects and related game assets. No surnames or legal identities were inferred. |
| Human asset/audio production | PASSED | Current assignments specify human-created UI, audio and game assets without AI generation. No asset completion or human review is claimed. |
| P00 ownership/capacity status | PASSED | P00-T01/T02 remain unchecked and P00 remains 0/6; registration, capacity, reviewer/backups and remaining workstream coverage remain incomplete. |
| Tracker scope and gameplay state | PASSED | No task IDs, dependencies or checkboxes were changed; total remains 17/393 checked (P01 9/10, P02 8/14). |
| Gameplay/runtime verification | COULD-NOT-RUN | This was a documentation-only role update; no game or asset production was performed or tested. |

## Documentation verification — approved wall-movement plan update (October 13, 2026)

This dated scope change records the user's approval of the separate Should-scope wall-slide/wall-jump extension after Stage A. It does not alter the historical run/jump implementation evidence and does not claim playable wall movement.

| Check | Result | Evidence / limit |
|---|---|---|
| Requirement/task IDs | PASSED | 117 unique PRD requirement headings and 401 unique PHASETASK task headings. New IDs are REQ-MOVE-004 and P02-T15–T22. |
| Requirement-to-task traceability | PASSED | 117 unique traceability rows cover all 117 requirements; every row links to existing implementation/non-code and verification tasks. REQ-MOVE-004 maps to P02-T15/T17/T19/T21 and P02-T16/T18/T20/T22. |
| Dependencies and cycles | PASSED | Parsed 728 task dependency edges; every referenced task exists and the dependency graph has no cycles. No new task depends on unrelated physical-device acceptance or unimplemented full event code. |
| Scope and checked totals | PASSED | Actual task records count Required 209, Should 42, Conditional 4, Expansion 158 (413 total); 162/413 records are checked, including the four technically verified Barya records under Should scope. P02 is 22/32; physical-device and human review remain open. P00-T04 remains blocked and the full release manifest is not ratified by the scoped Barya decision. |
| Markdown links and anchors | PASSED | Checked 2,423 local Markdown file/anchor links across 20 project-owned Markdown files in this checkout; no missing target or anchor found. |
| Baseline wording and support distinction | PASSED | Searched current “no wall jump” / “run and jump only” wording. Remaining occurrences describe the dated original P02 baseline and are labeled historical; current GDD/PRD/defaults describe the approved unimplemented extension. Wall contact is explicitly excluded from grounded support and Rising-wave qualification. |
| Whitespace | PASSED | `git diff --check` returned exit code 0 with no diagnostics. |
| Change boundary | PASSED | Final changed-file list is limited to README and 12 Markdown documents. No gameplay code, scene, test, game tuning resource, or asset changed. |
| Runtime wall-movement verification | NOT RUN | Correctly outside this documentation task because no wall-slide/jump implementation exists. Future real-physics, rendered, device and human feel checks are specified in PLAYTEST and P02-T15–T22. |
