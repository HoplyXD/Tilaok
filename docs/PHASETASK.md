# Tilaok! — Phased Implementation Tracker

**Version:** 1.0 · **Baseline:** October 13, 2026 · **Owner:** Producer (name TBD).

**Implementation baseline:** no gameplay scenes/scripts, no export preset, no runnable game. Project/icon skeleton only. Documentation was prepared on `feat/prd-phasetask` from main `98ef17a74166b6ac10c7930dc48a00c488fe61c9`; original dirty `feat/filipino-obstacles-events` at `791084a` is preserved. The fetched merged source includes prototype defaults and newer Library/preview contracts. Engine declares 4.7; inspected CLI 4.6.3, lint/format 4.5.0. Historical import/document checks are not current gameplay evidence.

## How to use this tracker

- [PRD](PRD.md) consolidates requirements; [GDD](GDD.md) remains gameplay authority, [ROADMAP](ROADMAP.md) scope/schedule, specialized specs detailed contracts, [PROTOTYPE_DEFAULTS](PROTOTYPE_DEFAULTS.md) untested starting values. Resolve conflicts explicitly.
- `[ ]` = not verified complete; `[x]` = complete with evidence. Planned, designed, approved or implemented-but-untested is not checked. No game task is completed by writing this file.
- Status metadata: **TODO**, **IN PROGRESS**, **BLOCKED**, **DEFERRED**. TODO tasks with unmet dependency IDs cannot start; mark BLOCKED when an actual unresolved impediment needs tracking. Deferred/conditional work needs an explicit activation decision.
- Follow task dependencies rather than requiring every earlier phase to finish. Seed-item core gates precede the slice; later seed compatibility/Library checks intentionally wait for events/UI. Phase exit criteria distinguish these gates.
- Every task names requirement(s), dependency IDs, owner role, acceptance and evidence. Person names remain TBD until assigned. Proposed systems/paths are **NEW** and are not a claim they exist.
- Completion evidence records build/commit, engine/profile/seed, date, scenario, expected/actual result, artifact location and reviewer; hardware/devices/player count when relevant. Tests use PASSED/FAILED/COULD-NOT-RUN. Missing runtime evidence stays COULD-NOT-RUN, never “passed by design.”
- A requirement is complete only when all applicable implementation and verification tasks pass. Check partial work separately. Update [PLAYTEST](PLAYTEST.md), [ASSETS](ASSETS.md) and [AI_USAGE](AI_USAGE.md) when their evidence changes.
- Scope change requires owner/date/reason and updated GDD if gameplay changes, ROADMAP, PRD, tracker, content manifest and verification. Preserve IDs/history. Eight initial families remain targeted; Bula is the first cut-review candidate, not an automatic cut.
- Decide each Should feature include/defer before freeze. Included Should tasks become release obligations; retain original IDs and record promotion. Conditional finals and unpromoted expansion never enter the required-release denominator.
- No automatic commit/push rule: commit only after explicit “commit”, named files only; push/open PR only after “push”; never merge as part of this documentation task. No AI trailers/lines in commit/PR metadata; truthful disclosure stays in dedicated docs/Form 03.

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

**20 phases · 393 tasks · 116 requirements.** Initial checked tasks: **0**. Required release/submission: **207**; Should: **24**; conditional finals: **4**; expansion: **158**. Counts come from the actual task records below, not effort estimates. Documentation completion is reported separately at the end.

| Phase | Purpose | Tasks | Scope |
|---|---|---:|---|
| [P00](#p00--baseline-and-production-readiness) — Baseline and production readiness | Own the decisions and establish what can actually be built. | 6 | Required |
| [P01](#p01--project-foundations) — Project foundations | Launch an original harness and establish an early export path. | 10 | Required |
| [P02](#p02--inputs-and-controller) — Inputs and controller | Players control only their own readable chicken and recover from device loss. | 14 | Required |
| [P03](#p03--graybox-stage-and-camera) — Graybox stage and camera | Players can traverse one bounded stage and remain visible. | 6 | Required |
| [P04](#p04--item-infrastructure-and-construction-seeds) — Item infrastructure and construction seeds | Kaing and Tulay make the initial buildable course. | 22 | Required |
| [P05](#p05--lobby-pugad-and-construction-loop) — Lobby, Pugad and construction loop | Players join, recognize eggs and commit fair shared construction. | 12 | Required |
| [P06](#p06--karera-and-scoring) — Karera and scoring | A race ends once and its result is understandable. | 8 | Required |
| [P07](#p07--first-playable-gate) — First playable gate | Demonstrate a truthful build/race slice, then expand device counts. | 4 | Required |
| [P08](#p08--lagsanay) — Lagsanay | Independent tag elimination yields one winner. | 6 | Required |
| [P09](#p09--complete-match-lifecycle) — Complete match lifecycle | A match and tied-player sudden death finish and restart cleanly. | 4 | Required |
| [P10](#p10--remaining-initial-items) — Remaining initial items | Add the six individually verified families after construction seeds. | 54 | Required |
| [P11](#p11--kangaroo-independently) — Kangaroo independently | Players read and respond to three commands through escalation. | 13 | Required |
| [P12](#p12--scheduling-and-stacks) — Scheduling and stacks | The announced challenge and optional compatible Twist execute with one scoring family. | 10 | Required |
| [P13](#p13--complete-ux-and-onboarding) — Complete UX and onboarding | New players can learn, navigate, read results and browse enabled content. | 12 | Required |
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

**Blocking decisions / conditional scope:** The user is handling team assignment/capacity privately; no team facts are stored. Producer and integration-owner identities are therefore not recorded. Exact export-template compatibility, export setup, keyboard details, and physical controller inventory/testing remain unresolved. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Owners, scope manifest and confirmed toolchain/device records unblock their respective workstreams.

**Evidence required:** Documentation baseline, role-sheet disposition, tool versions, observed/reported device inventory, actual import/export outputs and explicit unknowns. **P00 exit: NOT SATISFIED.** All six task checkboxes remain open; phase summary counts are unchanged.

**Evidence assessment:** October 13, 2026, 13:01 Asia/Manila; source revision `fa6145839bff96ecb6e1afdb112e804bfb72260f` before P00 edits. This timestamp/revision applies to the six task records below; import commands and exact run times are preserved in their linked logs.


#### P00-T01

- [ ] **Record team roles, reviewers and available hours**
  - **Status:** BLOCKED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Producer (name not recorded).
  - **Requirements:** [REQ-PROD-001](PRD.md#req-prod-001--confirm-registered-owners-and-available-capacity). **Dependencies:** None.
  - **Work:** Record primary and reviewer/backup for production/integration, team-authored gameplay, art/UI, audio, QA/balance and compliance/media, plus per-person capacity through October 25 without double-counting. The user directed on October 13 that they will handle the team privately and that names/hours are not to be documented in the repository. The existing TBD role-sheet template is preserved.
  - **Acceptance:** A dated role/capacity sheet names registered members, review responsibilities and available hours through October 25; no invented names.
  - **Evidence:** User direction recorded in `PRODUCTION.md`; no roster, registration, owner, reviewer, or hour data was supplied or added. **Procedure / expected / actual:** reviewed the existing role sheet and applied the user's privacy direction; expected confirmed assignments/capacity, actual no repository record by request. **Verification result:** COULD-NOT-RUN — team facts remain privately managed and are intentionally absent. **Reviewer:** not recorded. **Next action:** user completes team assignment/capacity work privately; no repository evidence is requested by this task.


#### P00-T02

- [ ] **Verify confirm registered owners and available capacity**
  - **Status:** BLOCKED · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** Producer (name not recorded).
  - **Requirements:** [REQ-PROD-001](PRD.md#req-prod-001--confirm-registered-owners-and-available-capacity). **Dependencies:** [P00-T01](#p00-t01).
  - **Work:** Independently verify registered membership, role coverage, reviewer arrangement, date range, and non-duplicated person-level hours from a confirmed role sheet.
  - **Acceptance:** A dated role/capacity sheet names registered members, review responsibilities and available hours through October 25; no invented names.
  - **Evidence:** T01 has no repository role/capacity artifact by user direction. **Procedure / expected / actual:** dependency and available evidence checked; expected a dated role/capacity sheet and registration confirmation, actual neither is available here. **Verification result:** COULD-NOT-RUN — dependent team facts are privately managed. **Reviewer:** not recorded. **Next action:** no repository verification until the user requests team facts be documented.


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

**Phase roll-up:** ✅ Foundation implementation and local verification complete (P01-T01, P01-T03–T10: 9/10 tasks PASSED). ⏳ P01-T02 remains COULD-NOT-RUN pending registered-team authorship review, so the full phase is not yet closed.

**Goal / player-visible result:** Launch an original harness and establish an early export path.

**Milestone / scope:** First playable and foundational delivery.

**Entry:** P00-T06 remains the toolchain gate. Its matching template/import/export evidence is now present, while named-owner and physical-device evidence remain open. P00-T02 remains open, but is not a prerequisite to authoring this foundation; team acceptance still requires its private team facts.

P01 implementation proceeded under the user's explicit Codex-authorship exception while team review is pending. Implementation and local runtime checks do not count as registered-team authorship review or competition eligibility approval.

**External task dependencies:** [P00-T06](#p00-t06). P00-T02 is not a prerequisite for P01 implementation by user decision; it remains open for team acceptance and competition eligibility review.

**Owner roles:** Integration; person names TBD. **Systems touched:** NEW project organization, config resources, harness and export preset.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Entry scene, config/profile validation, diagnostic harness and initial smoke export pass.

**Evidence required:** Team-authorship review, import/export logs, profile validation results.


#### P01-T01

- [x] **Create the project structure and responsibility map**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (person name not recorded).
  - **Requirements:** [REQ-TECH-001](PRD.md#req-tech-001--establish-team-authored-project-responsibilities). **Dependencies:** [P00-T06](#p00-t06); P00-T02 dependency removed for implementation by user decision.
  - **Work:** Created a runnable harness, responsibility map, typed configuration/diagnostics layout and test fixtures. No future gameplay responsibility is represented as implemented.
  - **Evidence:** [project map](PROJECT_STRUCTURE.md), [Godot import](evidence/p01-import-godot-4.7.2-2026-10-13.log), [runtime smoke](evidence/p01-runtime-smoke-2026-10-13.log). **Procedure / expected / actual:** opened the project in Godot 4.7.2 and ran the harness; expected a working diagnostic entry and clear scope labels, actual build/profile/seed identity and controls displayed without script errors. Codex authored this P01 work under the user's explicit exception. It is not labeled team-authored and does not establish competition compliance. **Verification result:** PASSED for project structure/launch; team authorship review remains P01-T02. **Reviewer:** Codex for implementation/runtime evidence; no registered team reviewer recorded.


#### P01-T02

- [ ] **Verify establish team-authored project responsibilities**
  - **Status:** COULD-NOT-RUN · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (person name not recorded).
  - **Requirements:** [REQ-TECH-001](PRD.md#req-tech-001--establish-team-authored-project-responsibilities). **Dependencies:** [P01-T01](#p01-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Project opens with a team-authored entry scene; responsibility map and authorship review exist; no copied tutorial/template/open-source core mechanics.
  - **Acceptance:** Project opens with a team-authored entry scene; responsibility map and authorship review exist; no copied tutorial/template/open-source core mechanics.
  - **Evidence:** [authorship disclosure and limitation](PROJECT_STRUCTURE.md#authorship-and-review); no team reviewer artifact is available. **Procedure / expected / actual:** inspected authored project files and disclosure; expected registered team member review and confirmation of competition eligibility, actual Codex authorship is recorded but team review and eligibility confirmation have not occurred. **Verification result:** COULD-NOT-RUN — user explicitly authorized the exception for implementation, not a claim that it satisfies competition rules. **Reviewer:** not recorded.


#### P01-T03

- [x] **Author configuration resources and labeled test profiles**
  - **Status:** PASSED · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (person name not recorded).
  - **Requirements:** [REQ-CONFIG-001](PRD.md#req-config-001--centralize-provisional-configuration-and-profiles). **Dependencies:** [P01-T02](#p01-t02).
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
  - **Requirements:** [REQ-TECH-002](PRD.md#req-tech-002--provide-lifecycle-and-diagnostic-harnesses). **Dependencies:** [P01-T02](#p01-t02).
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
  - **Requirements:** [REQ-EXPORT-001](PRD.md#req-export-001--prove-an-early-pc-export-path). **Dependencies:** [P01-T02](#p01-t02).
  - **Work:** Use the confirmed target engine and matching templates to export a minimal runnable P01 harness early; repeat with the final release later. The P01 harness is Codex-authored under the explicit documented exception, not represented as team-authored. A successful editor import alone is not export or gameplay evidence.
  - **Acceptance:** A versioned smoke export launches and exits on the intended PC; record engine/templates, preset, build and logs. Missing templates block the check.
  - **Evidence:** [template install](evidence/p01-template-install-2026-10-13.log), [export log](evidence/p01-export-godot-4.7.2-2026-10-13.log), [exported runtime](evidence/p01-export-runtime-2026-10-13.log). **Procedure / expected / actual:** installed the matching official 4.7.2 templates in the versioned Godot path; exported with the Windows Desktop preset; expected an executable that starts and exits, actual the app opened a responsive `Tilaok!` window and exited after a clean close request. The archive was installed by extracting its verified `templates/` subtree into the standard version path; the editor template-manager UI was not used. **Verification result:** PASSED for local target-PC smoke export. The executable contains Codex-authored foundation code under the disclosed exception; no competition eligibility claim is made. **Reviewer:** Codex (implementation author); no registered team reviewer recorded.


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

**External task dependencies:** [P01-T02](#p01-t02), [P01-T04](#p01-t04)

**Owner roles:** Gameplay; person names TBD. **Systems touched:** NEW input, chicken controller, sensors and pause/reconnect flow.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Movement/input/contact/bounds and pause/reclaim scenarios pass on recorded devices.

**Evidence required:** Measured arc, device chords, slot isolation and reconnect captures.


#### P02-T01

- [ ] **Implement isolated device assignment and player markers**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-INPUT-001](PRD.md#req-input-001--assign-devices-and-fixed-chicken-identity). **Dependencies:** [P01-T02](#p01-t02).
  - **Work:** Support 2–4 local seats, gamepads first. A device joins one seat; join and ready require separate fresh presses. Number/shape stay fixed until lobby return: prototype 1 circle, 2 triangle, 3 square, 4 diamond. Color supplements identity.
  - **Acceptance:** Two identical gamepads and mixed input never control another seat, double-join or ready on the joining press; identifiers persist through phases and reconnect.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P02-T02

- [ ] **Verify assign devices and fixed chicken identity**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-INPUT-001](PRD.md#req-input-001--assign-devices-and-fixed-chicken-identity). **Dependencies:** [P02-T01](#p02-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Two identical gamepads and mixed input never control another seat, double-join or ready on the joining press; identifiers persist through phases and reconnect.
  - **Acceptance:** Two identical gamepads and mixed input never control another seat, double-join or ready on the joining press; identifiers persist through phases and reconnect.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P02-T03

- [ ] **Implement phase bindings and opt-in keyboard seats**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-INPUT-002](PRD.md#req-input-002--implement-phase-specific-bindings-and-shared-keyboard-fallback). **Dependencies:** [P02-T02](#p02-t02).
  - **Work:** Use the provisional binding table below. Release target is 2–4 players on verified gamepads/mixed devices. Two keyboard seats require explicit shared-keyboard mode and physical rollover validation; four-player keyboard-only is not promised. Stick digital parity/deadzone/repeat values remain prototype settings.
  - **Acceptance:** Each phase action works only for its assigned seat; no lost simultaneous supported chords. Unavailable/failed keyboard combinations are documented, remapped or excluded from supported claims.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P02-T04

- [ ] **Verify implement phase-specific bindings and shared keyboard fallback**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-INPUT-002](PRD.md#req-input-002--implement-phase-specific-bindings-and-shared-keyboard-fallback). **Dependencies:** [P02-T03](#p02-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Each phase action works only for its assigned seat; no lost simultaneous supported chords. Unavailable/failed keyboard combinations are documented, remapped or excluded from supported claims.
  - **Acceptance:** Each phase action works only for its assigned seat; no lost simultaneous supported chords. Unavailable/failed keyboard combinations are documented, remapped or excluded from supported claims.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P02-T05

- [ ] **Gate input edges and pointer repeat by phase**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-INPUT-003](PRD.md#req-input-003--consume-held-presses-across-phase-transitions). **Dependencies:** [P02-T04](#p02-t04).
  - **Work:** Consume existing press edges on transitions; release is required before claim/confirm/rotate/jump/ready. Held direction may continue; jump buffers clear. Ignore OS key repeat for one-shot actions. Prototype placement repeat is one cell then 0.25 s delay at 8 cells/s; menu/Pugad repeats at 6/s.
  - **Acceptance:** Holding jump/confirm through every transition creates no unintended next action; diagonal pointer movement gains no speed; unsupported rotations give a disabled cue.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P02-T06

- [ ] **Verify consume held presses across phase transitions**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-INPUT-003](PRD.md#req-input-003--consume-held-presses-across-phase-transitions). **Dependencies:** [P02-T05](#p02-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Holding jump/confirm through every transition creates no unintended next action; diagonal pointer movement gains no speed; unsupported rotations give a disabled cue.
  - **Acceptance:** Holding jump/confirm through every transition creates no unintended next action; diagonal pointer movement gains no speed; unsupported rotations give a disabled cue.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P02-T07

- [ ] **Implement shared pause, reconnect and all-ready resume**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-INPUT-004](PRD.md#req-input-004--pause-and-reclaim-disconnected-seats-safely). **Dependencies:** [P02-T02](#p02-t02), [P02-T06](#p02-t06).
  - **Work:** Any participant may pause; focus loss/device disconnect pauses all simulation, timers, immunity, physics, hazards and event windows. Preserve slot/score/taya/position. Reclaim missing slots using unassigned devices and visible slot confirmation. All participants ready, all missing seats reclaimed, then a paused 3 s resume countdown. Status changes cancel readiness.
  - **Acceptance:** Unplug/replug including identical controllers preserves identity and timer values; assigned devices cannot steal seats; focus changes cancel resume; no simulation progresses during pause/countdown.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P02-T08

- [ ] **Verify pause and reclaim disconnected seats safely**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-INPUT-004](PRD.md#req-input-004--pause-and-reclaim-disconnected-seats-safely). **Dependencies:** [P02-T07](#p02-t07).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Unplug/replug including identical controllers preserves identity and timer values; assigned devices cannot steal seats; focus changes cancel resume; no simulation progresses during pause/countdown.
  - **Acceptance:** Unplug/replug including identical controllers preserves identity and timer values; assigned devices cannot steal seats; focus changes cancel resume; no simulation progresses during pause/countdown.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P02-T09

- [ ] **Implement and instrument the initial run/jump controller**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-MOVE-001](PRD.md#req-move-001--implement-responsive-run-and-jump-only). **Dependencies:** [P02-T04](#p02-t04), [P01-T04](#p01-t04).
  - **Work:** Normal Play controls are left/right and jump, without dash, wall jump, double jump or drop-through. Prototype uses 32 wu grid, 24×48 collider, 96 wu jump apex at 0.32 s, 280 wu/s run speed, variable jump, coyote/buffer, acceleration/braking and launch limits from the defaults register. These are starting values, not balance claims.
  - **Acceptance:** Measure full/short jumps, braking, reversal and 64 wu gap/rise trials; investigate apex deviations above 2 wu or one physics step; consume each buffered jump once and never auto-repeat held jump.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P02-T10

- [ ] **Verify implement responsive run and jump only**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-MOVE-001](PRD.md#req-move-001--implement-responsive-run-and-jump-only). **Dependencies:** [P02-T09](#p02-t09).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Measure full/short jumps, braking, reversal and 64 wu gap/rise trials; investigate apex deviations above 2 wu or one physics step; consume each buffered jump once and never auto-repeat held jump.
  - **Acceptance:** Measure full/short jumps, braking, reversal and 64 wu gap/rise trials; investigate apex deviations above 2 wu or one physics step; consume each buffered jump once and never auto-repeat held jump.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P02-T11

- [ ] **Implement contact sensing and movement-state ownership**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-MOVE-002](PRD.md#req-move-002--separate-body-collision-contact-and-intentional-input). **Dependencies:** [P02-T10](#p02-t10).
  - **Work:** Chicken bodies pass through in Karera, Lagsanay and Kangaroo; independent sensors support tag/Hug. Forced movement is distinct from intentional input. Prototype precedence is terminal > opening taya freeze > capture > forced motion > locomotion. A lower state cannot reactivate a secured/eliminated player.
  - **Acceptance:** Overlap creates no pushing; intentional input is observable while captured; launch clears coyote state and is not shortened by jump release; terminal states ignore later movement/capture.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P02-T12

- [ ] **Verify separate body collision, contact and intentional input**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-MOVE-002](PRD.md#req-move-002--separate-body-collision-contact-and-intentional-input). **Dependencies:** [P02-T11](#p02-t11).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Overlap creates no pushing; intentional input is observable while captured; launch clears coyote state and is not shortened by jump release; terminal states ignore later movement/capture.
  - **Acceptance:** Overlap creates no pushing; intentional input is observable while captured; launch clears coyote state and is not shortened by jump release; terminal states ignore later movement/capture.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P02-T13

- [ ] **Implement bounds and diagnostic containment recovery**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-MOVE-003](PRD.md#req-move-003--contain-players-and-expose-invalid-escapes). **Dependencies:** [P02-T12](#p02-t12).
  - **Work:** Visible floor/side/ceiling bounds contain ordinary and forced movement. Lagsanay has no fall elimination. Prototype unexpected race-only escape fails once; containment failure with Lagsanay or standalone Kangaroo pauses as a defect and restarts the round from pre-round scores and unchanged construction.
  - **Acceptance:** Maximum launches cannot bypass bounds; injected breach cannot repeatedly award score, teleport an active taya while time runs, or convert a Lagsanay fall into elimination. Recovery is labeled a prototype safeguard.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P02-T14

- [ ] **Verify contain players and expose invalid escapes**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-MOVE-003](PRD.md#req-move-003--contain-players-and-expose-invalid-escapes). **Dependencies:** [P02-T13](#p02-t13).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Maximum launches cannot bypass bounds; injected breach cannot repeatedly award score, teleport an active taya while time runs, or convert a Lagsanay fall into elimination. Recovery is labeled a prototype safeguard.
  - **Acceptance:** Maximum launches cannot bypass bounds; injected breach cannot repeatedly award score, teleport an active taya while time runs, or convert a Lagsanay fall into elimination. Recovery is labeled a prototype safeguard.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


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


#### P03-T01

- [ ] **Build the arena and protected-zone data**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-STAGE-001](PRD.md#req-stage-001--build-one-protected-barrio-graybox-arena). **Dependencies:** [P02-T10](#p02-t10), [P02-T14](#p02-t14).
  - **Work:** Start with solid floor, left spawn, right flag, few base platforms and fixed bounds. Base/floor/spawn/goal are indestructible; hidden event goal clearance remains protected. Use the provisional 1024×512 wu graybox only after controller measurement. Layouts created by players need not remain solvable.
  - **Acceptance:** Base route is traversable before construction; bounds/protected zones are visible in tests; no placement/removal changes immutable geometry. Paper reachability is confirmed by actual collision trials.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P03-T02

- [ ] **Verify build one protected barrio graybox arena**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-STAGE-001](PRD.md#req-stage-001--build-one-protected-barrio-graybox-arena). **Dependencies:** [P03-T01](#p03-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Base route is traversable before construction; bounds/protected zones are visible in tests; no placement/removal changes immutable geometry. Paper reachability is confirmed by actual collision trials.
  - **Acceptance:** Base route is traversable before construction; bounds/protected zones are visible in tests; no placement/removal changes immutable geometry. Paper reachability is confirmed by actual collision trials.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P03-T03

- [ ] **Implement bounded dynamic camera and readability probes**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-STAGE-002](PRD.md#req-stage-002--frame-active-players-and-unfinished-placement-pointers). **Dependencies:** [P03-T02](#p03-t02).
  - **Work:** Play frames live unfinished chickens; eliminated/secured chickens are excluded. Place frames unconfirmed pointers including item extents. Ease framing changes with bounded zoom/pan; zoom out fast enough for launches. Empty sets hold safe framing. HUD remains screen-sized.
  - **Acceptance:** At 2/3/4 players, maximum separation/high construction/launches keep relevant targets visible and readable; finishing/confirming removes the correct target without unsafe snapping.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P03-T04

- [ ] **Verify frame active players and unfinished placement pointers**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-STAGE-002](PRD.md#req-stage-002--frame-active-players-and-unfinished-placement-pointers). **Dependencies:** [P03-T03](#p03-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. At 2/3/4 players, maximum separation/high construction/launches keep relevant targets visible and readable; finishing/confirming removes the correct target without unsafe snapping.
  - **Acceptance:** At 2/3/4 players, maximum separation/high construction/launches keep relevant targets visible and readable; finishing/confirming removes the correct target without unsafe snapping.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P03-T05

- [ ] **Implement supporting-surface provenance and invalidation**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-STAGE-003](PRD.md#req-stage-003--track-actual-supporting-contact-and-construction-provenance). **Dependencies:** [P03-T02](#p03-t02), [P02-T12](#p02-t12).
  - **Work:** Track player-built provenance and explicit wave-support eligibility on authored surfaces. Actual upward supporting contact after movement/destruction is required; stale grounded/coyote/sensor states are insufficient. Prototype upward normal is within 45 degrees, v1 horizontal tops; numeric epsilon is untested.
  - **Acceptance:** Support row matrix distinguishes base, Kaing, one-way bridge, launch, moving/removed surface, bubble, projectile, side contact and airborne state; missing eligibility metadata fails content validation.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P03-T06

- [ ] **Verify track actual supporting contact and construction provenance**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-STAGE-003](PRD.md#req-stage-003--track-actual-supporting-contact-and-construction-provenance). **Dependencies:** [P03-T05](#p03-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Support row matrix distinguishes base, Kaing, one-way bridge, launch, moving/removed surface, bubble, projectile, side contact and airborne state; missing eligibility metadata fails content validation.
  - **Acceptance:** Support row matrix distinguishes base, Kaing, one-way bridge, launch, moving/removed surface, bubble, projectile, side contact and airborne state; missing eligibility metadata fails content validation.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


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


#### P04-T01

- [ ] **Implement shared item definitions and validation**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEMSYS-001](PRD.md#req-itemsys-001--define-item-metadata-and-bounded-regions). **Dependencies:** [P01-T04](#p01-t04), [P03-T02](#p03-t02).
  - **Work:** Item definitions use stable catalog IDs and explicit family/variant, footprint, solid/trigger, sweep/lane/effect regions, rotations, ownership, safe start, removal, event eligibility and preview/Library presentation. Centralize all tunables. Only approved variants may enter pools.
  - **Acceptance:** Definition validation rejects missing required fields, unbounded regions and undocumented variants; effect regions remain distinct from occupied grid cells.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P04-T02

- [ ] **Verify define item metadata and bounded regions**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEMSYS-001](PRD.md#req-itemsys-001--define-item-metadata-and-bounded-regions). **Dependencies:** [P04-T01](#p04-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Definition validation rejects missing required fields, unbounded regions and undocumented variants; effect regions remain distinct from occupied grid cells.
  - **Acceptance:** Definition validation rejects missing required fields, unbounded regions and undocumented variants; effect regions remain distinct from occupied grid cells.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P04-T03

- [ ] **Implement shared lifecycle, caps and teardown**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEMSYS-002](PRD.md#req-itemsys-002--implement-persistent-items-and-bounded-transient-lifecycle). **Dependencies:** [P04-T02](#p04-t02), [P01-T08](#p01-t08).
  - **Work:** Items are inert in Place except Walis edit; reset deterministic position/direction/phase at Play with configurable grace. Persist placed construction across rounds and remove it on match reset. Clear timers/signals/projectiles/captures on appropriate removal/death/end/restart. Prototype caps: 48 persistent, 16 projectiles, 4 bubbles, 32 VFX; saturation suppresses spawns rather than evicting captives.
  - **Acceptance:** Ten reset cycles retain only intended construction and no transient state. Saturation/removal releases references and captives safely; spawn allocation follows reviewed rotating order, not callback order.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P04-T04

- [ ] **Verify implement persistent items and bounded transient lifecycle**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEMSYS-002](PRD.md#req-itemsys-002--implement-persistent-items-and-bounded-transient-lifecycle). **Dependencies:** [P04-T03](#p04-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Ten reset cycles retain only intended construction and no transient state. Saturation/removal releases references and captives safely; spawn allocation follows reviewed rotating order, not callback order.
  - **Acceptance:** Ten reset cycles retain only intended construction and no transient state. Saturation/removal releases references and captives safely; spawn allocation follows reviewed rotating order, not callback order.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Hollow Blocks / Kaing Stack — `build.hollow_blocks`


#### P04-T05

- [ ] **Define Hollow Blocks / Kaing Stack configuration and variants**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04).
  - **Work:** Author the family definition from the catalog; expose tuning keys and keep precision/effect regions distinct.
  - **Acceptance:** Definition lists 1×1, 1×3 column, 2×3 stack; prototype slice initially 1×1 and 2×3 only. Regions, rotations, safe start, owner and mode flags are explicit.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P04-T06

- [ ] **Build Hollow Blocks / Kaing Stack scene and collision regions**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack). **Dependencies:** [P04-T05](#p04-t05).
  - **Work:** Create original scene/solid/sensor regions and visible bounds; verify the family-specific placement and rotation contract.
  - **Acceptance:** One-cell and 2×3-cell variants in a single family; 90° rotation where footprint changes. Solid full footprint, no trigger. No overlap with protected geometry or other solids; projectile occlusion uses actual solid volume. Footprint and item cap are tunables.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P04-T07

- [ ] **Implement Hollow Blocks / Kaing Stack mechanic and feedback**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack). **Dependencies:** [P04-T06](#p04-t06).
  - **Work:** Implement the family behavior, tell and counterplay without copying reference code/art; use centralized timing/force settings.
  - **Acceptance:** Solid construction pieces create footholds, walls, routes, and projectile cover. Danger is route obstruction or hiding a tell. Tell: strong distinct crate silhouette and placement ghost. Counter: jump around/over, use another route, or Walis Cleanup. UCH basic-block inspiration; original barrio treatment.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P04-T08

- [ ] **Implement Hollow Blocks / Kaing Stack ownership and cleanup**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack). **Dependencies:** [P04-T07](#p04-t07).
  - **Work:** Preserve direct-source ownership/no-assist rules; implement inactive Place, deterministic Play reset, persistent removal and reference/transient teardown.
  - **Acceptance:** Usable in race and event rounds including Lagsanay. Owner is placer; removable by Walis Cleanup; persists until removed, no moving state. Needs original crate/block sprites and sound. Low relative risk; depends on placement grid/collision and cleanup. Cultural check: “kaing” use/context.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P04-T09

- [ ] **Verify Hollow Blocks / Kaing Stack core behavior in its harness**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack). **Dependencies:** [P04-T08](#p04-t08).
  - **Work:** Run isolated collision/behavior/reset cases before exposing the family to a selectable pool; this is not the later event-compatibility gate.
  - **Acceptance:** Check all configured variants, rotations, collider boundaries, tell/counterplay, deterministic reset and removal. Capture actual results and known limits.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P04-T10

- [ ] **Add Hollow Blocks / Kaing Stack egg animation and placement ghost**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack), [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews), [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P04-T09](#p04-t09), [P05-T02](#p05-t02), [P05-T06](#p05-t06).
  - **Work:** Produce/register original visual preview assets; reuse shared preview infrastructure and preserve claimed variant identity.
  - **Acceptance:** Preview/ghost show 1×1, 1×3 column, 2×3 stack; prototype slice initially 1×1 and 2×3 only. Include relevant sweep/lane/effect and non-color validity; no Pugad names/descriptions.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P04-T11

- [ ] **Integrate Hollow Blocks / Kaing Stack with events and scoring**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack). **Dependencies:** [P04-T09](#p04-t09), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04).
  - **Work:** Apply catalog mode restrictions; unsafe capture/force chains block pairing enablement. Walis is construction-only, never a Play hazard.
  - **Acceptance:** Document enabled modes and support eligibility; verify direct credit/no credit and family-specific hazards or forces in independent modes and supported stacks.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P04-T12

- [ ] **Write and animate the Hollow Blocks / Kaing Stack Library entry**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack), [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P04-T10](#p04-t10).
  - **Work:** Author entry data/assets against the shared Library schema; integration is checked when the Library shell is available.
  - **Acceptance:** Entry includes name, looping animation, sizes, placement, tell/counterplay, controls and permitted modes; release filter exposes only enabled content.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P04-T13

- [ ] **Verify Hollow Blocks / Kaing Stack release enablement**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-001](PRD.md#req-item-001--hollow-blocks--kaing-stack). **Dependencies:** [P04-T11](#p04-t11), [P04-T12](#p04-t12), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Test harness plus 2/3/4-player integration, exact preview/ghost, Library, bounds, source credit, support and ten lifecycle resets. Register artifacts and unresolved defects before enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Tulay na Kawayan — `build.bamboo_bridge`


#### P04-T14

- [ ] **Define Tulay na Kawayan configuration and variants**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04).
  - **Work:** Author the family definition from the catalog; expose tuning keys and keep precision/effect regions distinct.
  - **Acceptance:** Definition lists 3×1, 4×1, 5×1; prototype starts horizontal 4×1; vertical 1×3/1×4/1×5 only after controller-support gate. Regions, rotations, safe start, owner and mode flags are explicit.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P04-T15

- [ ] **Build Tulay na Kawayan scene and collision regions**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan). **Dependencies:** [P04-T14](#p04-t14).
  - **Work:** Create original scene/solid/sensor regions and visible bounds; verify the family-specific placement and rotation contract.
  - **Acceptance:** One-way solid top, non-solid underside/sides; horizontal/vertical rotation in 90° steps if the movement model supports both. Footprint distinct from top collision strip. Length, thickness, allowed rotations are tunables.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P04-T16

- [ ] **Implement Tulay na Kawayan mechanic and feedback**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan). **Dependencies:** [P04-T15](#p04-t15).
  - **Work:** Implement the family behavior, tell and counterplay without copying reference code/art; use centralized timing/force settings.
  - **Acceptance:** One-way thin bridge creates a route; its underside can be passed through, so it may be missed or become an ambush landing. Tell: narrow bamboo silhouette and one-way arrow on ghost. Counter: approach from below to pass through, or use another path. Inspired by the general utility-platform role; one-way behavior is Tilaok’s adaptation.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P04-T17

- [ ] **Implement Tulay na Kawayan ownership and cleanup**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan). **Dependencies:** [P04-T16](#p04-t16).
  - **Work:** Preserve direct-source ownership/no-assist rules; implement inactive Place, deterministic Play reset, persistent removal and reference/transient teardown.
  - **Acceptance:** Race and event terrain; enabled in Lagsanay only after safe-floor compatibility review. Placer owns it; cleanup removes it, otherwise persists. Static reset. Needs original bridge art. Medium risk because one-way collision must match run/jump-only controls. Verify material/name culturally; no “traditional rule” claim.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P04-T18

- [ ] **Verify Tulay na Kawayan core behavior in its harness**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan). **Dependencies:** [P04-T17](#p04-t17).
  - **Work:** Run isolated collision/behavior/reset cases before exposing the family to a selectable pool; this is not the later event-compatibility gate.
  - **Acceptance:** Check all configured variants, rotations, collider boundaries, tell/counterplay, deterministic reset and removal. Capture actual results and known limits.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P04-T19

- [ ] **Add Tulay na Kawayan egg animation and placement ghost**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan), [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews), [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P04-T18](#p04-t18), [P05-T02](#p05-t02), [P05-T06](#p05-t06).
  - **Work:** Produce/register original visual preview assets; reuse shared preview infrastructure and preserve claimed variant identity.
  - **Acceptance:** Preview/ghost show 3×1, 4×1, 5×1; prototype starts horizontal 4×1; vertical 1×3/1×4/1×5 only after controller-support gate. Include relevant sweep/lane/effect and non-color validity; no Pugad names/descriptions.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P04-T20

- [ ] **Integrate Tulay na Kawayan with events and scoring**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan). **Dependencies:** [P04-T18](#p04-t18), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04).
  - **Work:** Apply catalog mode restrictions; unsafe capture/force chains block pairing enablement. Walis is construction-only, never a Play hazard.
  - **Acceptance:** Document enabled modes and support eligibility; verify direct credit/no credit and family-specific hazards or forces in independent modes and supported stacks.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P04-T21

- [ ] **Write and animate the Tulay na Kawayan Library entry**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan), [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P04-T19](#p04-t19).
  - **Work:** Author entry data/assets against the shared Library schema; integration is checked when the Library shell is available.
  - **Acceptance:** Entry includes name, looping animation, sizes, placement, tell/counterplay, controls and permitted modes; release filter exposes only enabled content.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P04-T22

- [ ] **Verify Tulay na Kawayan release enablement**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-002](PRD.md#req-item-002--tulay-na-kawayan). **Dependencies:** [P04-T20](#p04-t20), [P04-T21](#p04-t21), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Test harness plus 2/3/4-player integration, exact preview/ghost, Library, bounds, source credit, support and ten lifecycle resets. Register artifacts and unresolved defects before enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


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

- [ ] **Build reusable animated egg previews and variant handoff**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews). **Dependencies:** [P04-T02](#p04-t02).
  - **Work:** Every egg shows a short looping visual preview of its exact item and variant without names/descriptions. Claiming preserves variant identity through hatch to placement ghost. Library is the deliberate space for descriptions.
  - **Acceptance:** For every enabled variant, capture matching egg/ghost pairs; animation shows shape/effect extent and no descriptive name/text; no hidden size substitution.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P05-T02

- [ ] **Verify show exact-variant animated egg previews**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews). **Dependencies:** [P05-T01](#p05-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. For every enabled variant, capture matching egg/ghost pairs; animation shows shape/effect extent and no descriptive name/text; no hidden size substitution.
  - **Acceptance:** For every enabled variant, capture matching egg/ghost pairs; animation shows shape/effect extent and no descriptive name/text; no hidden size substitution.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P05-T03

- [ ] **Implement claim arbitration, hatch and timeout assignment**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-PUGAD-002](PRD.md#req-pugad-002--resolve-simultaneous-egg-claims-and-timeouts). **Dependencies:** [P05-T02](#p05-t02), [P02-T06](#p02-t06), [P01-T06](#p01-t06), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Pugad is simultaneous, one egg per player and one owner per egg. Approximate defaults: players+2 eggs and 8 s. Earlier claims win; prototype indistinguishable same-step claims use a seeded equal lottery; timeout assigns remaining eggs without replacement. Losing claimants receive a non-color cue and may choose again.
  - **Acceptance:** Contested claims and simultaneous timeout never duplicate eggs or ownership; selection uses eligible pool only and leaves each player with at most one item.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P05-T04

- [ ] **Verify resolve simultaneous egg claims and timeouts**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-PUGAD-002](PRD.md#req-pugad-002--resolve-simultaneous-egg-claims-and-timeouts). **Dependencies:** [P05-T03](#p05-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Contested claims and simultaneous timeout never duplicate eggs or ownership; selection uses eligible pool only and leaves each player with at most one item.
  - **Acceptance:** Contested claims and simultaneous timeout never duplicate eggs or ownership; selection uses eligible pool only and leaves each player with at most one item.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P05-T05

- [ ] **Implement placement ghosts, guides and validity feedback**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P05-T04](#p05-t04), [P03-T04](#p03-t04).
  - **Work:** Move/rotate/confirm a visible grid-snapped ghost. Show exact variant, footprint and relevant sweep/lane/effect, protected areas and non-color validity cues. Projectile/rolling guides show first blocker, predicted bounds or full possible envelope if an exact path is unreliable.
  - **Acceptance:** Every allowed orientation and boundary gives the correct ghost and actionable protected-zone/player/bounds/solid-conflict/item-rule reason; no misleading exact trajectory.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P05-T06

- [ ] **Verify preview grid placement with actionable rejection reasons**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P05-T05](#p05-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Every allowed orientation and boundary gives the correct ghost and actionable protected-zone/player/bounds/solid-conflict/item-rule reason; no misleading exact trajectory.
  - **Acceptance:** Every allowed orientation and boundary gives the correct ghost and actionable protected-zone/player/bounds/solid-conflict/item-rule reason; no misleading exact trajectory.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P05-T07

- [ ] **Implement snapshot-based atomic stage edits**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-PLACE-002](PRD.md#req-place-002--commit-placement-and-cleanup-atomically). **Dependencies:** [P05-T06](#p05-t06), [P04-T04](#p04-t04).
  - **Work:** Confirm submits a pending edit against one phase snapshot. At resolution union Walis targets from that snapshot, remove eligible prior construction, validate remaining placements and reject entire conflicting solid sets; commit valid edits together. Never remove same-phase new pieces or protected geometry. Allow solid/trigger intersections only with readable danger regions.
  - **Acceptance:** Permuting callbacks/submission order yields identical committed layout; overlapping cleanup executes once; rejected sets get no partial placement. Unsupported movers reset/remove safely without crushing.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P05-T08

- [ ] **Verify commit placement and cleanup atomically**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-PLACE-002](PRD.md#req-place-002--commit-placement-and-cleanup-atomically). **Dependencies:** [P05-T07](#p05-t07).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Permuting callbacks/submission order yields identical committed layout; overlapping cleanup executes once; rejected sets get no partial placement. Unsupported movers reset/remove safely without crushing.
  - **Acceptance:** Permuting callbacks/submission order yields identical committed layout; overlapping cleanup executes once; rejected sets get no partial placement. Unsupported movers reset/remove safely without crushing.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P05-T09

- [ ] **Connect phase transitions, placement timeout and persistence**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-PLACE-003](PRD.md#req-place-003--handle-phase-timing-and-persistent-construction). **Dependencies:** [P05-T08](#p05-t08).
  - **Work:** Approximate Place duration 15 s. Timeout commits the pointer item only if valid, otherwise discards it. Remove Pugad UI/collision from Play, reset items safely, retain construction until cleanup/match reset and retain removal in later rounds.
  - **Acceptance:** Timeout, discard, confirmation and reset cannot create duplicates; repeated rounds retain exact valid construction and do not resurrect removed objects.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P05-T10

- [ ] **Verify handle phase timing and persistent construction**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-PLACE-003](PRD.md#req-place-003--handle-phase-timing-and-persistent-construction). **Dependencies:** [P05-T09](#p05-t09).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Timeout, discard, confirmation and reset cannot create duplicates; repeated rounds retain exact valid construction and do not resurrect removed objects.
  - **Acceptance:** Timeout, discard, confirmation and reset cannot create duplicates; repeated rounds retain exact valid construction and do not resurrect removed objects.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P05-T11

- [ ] **Build minimal lobby, instructional prompts and results shell**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-UI-001](PRD.md#req-ui-001--provide-minimal-join-round-results-and-next-round-flow). **Dependencies:** [P02-T06](#p02-t06).
  - **Work:** Lobby supports 2–4 joined ready seats with fixed markers; fewer than two cannot start. Round result explains outcomes, awards, no-score reason and total. Prototype result advance is all-ready or 8 s. Provide basic join/move/jump/egg/place hints early.
  - **Acceptance:** New participants can join and identify themselves; results explain actual awards; next round consumes held presses and retains construction correctly.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P05-T12

- [ ] **Verify provide minimal join, round results and next-round flow**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-UI-001](PRD.md#req-ui-001--provide-minimal-join-round-results-and-next-round-flow). **Dependencies:** [P05-T11](#p05-t11), [P06-T08](#p06-t08).
  - **Work:** Record the procedure, expected and actual result, and review evidence. New participants can join and identify themselves; results explain actual awards; next round consumes held presses and retains construction correctly.
  - **Acceptance:** New participants can join and identify themselves; results explain actual awards; next round consumes held presses and retains construction correctly.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


## P06 — Karera and scoring

**Goal / player-visible result:** A race ends once and its result is understandable.

**Milestone / scope:** First playable and foundational delivery.

**Entry:** P05 construction loop available.

**External task dependencies:** [P05-T10](#p05-t10)

**Owner roles:** Gameplay; person names TBD. **Systems touched:** NEW race controller, outcome ledger, score calculator and results binding.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Race deadlines, terminal ledger and exact scoring cases pass; later hazard integration remains explicit.

**Evidence required:** 2/3/4-player outcome/scoring tables and duplicate-event tests.


#### P06-T01

- [ ] **Implement Karera objectives and round deadlines**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-RACE-001](PRD.md#req-race-001--resolve-karera-finish-failure-and-deadlines). **Dependencies:** [P05-T10](#p05-t10).
  - **Work:** Race to the flag; death eliminates for this round, return next round. End when all players finish/fail, or at the earlier of the provisional 60 s hard cap and 15 s after first finish. Remaining runners fail at deadline. Finished players are secured against later effects.
  - **Acceptance:** Exercise none/some/all finish, both deadlines, last-frame finish and no live runners; resolve the round once and show the applicable reason.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P06-T02

- [ ] **Verify resolve karera finish, failure and deadlines**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-RACE-001](PRD.md#req-race-001--resolve-karera-finish-failure-and-deadlines). **Dependencies:** [P06-T01](#p06-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Exercise none/some/all finish, both deadlines, last-frame finish and no live runners; resolve the round once and show the applicable reason.
  - **Acceptance:** Exercise none/some/all finish, both deadlines, last-frame finish and no live runners; resolve the round once and show the applicable reason.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P06-T03

- [ ] **Implement terminal event ledger and attribution resolver**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-SCORE-001](PRD.md#req-score-001--record-one-terminal-outcome-and-direct-attribution). **Dependencies:** [P06-T02](#p06-t02).
  - **Work:** Each player has one terminal outcome and one award application per round. Earliest recorded hazard contact owns a kill; indistinguishable contacts use stable item ID. Goal versus death uses event time; indistinguishable elimination wins. Self-kill and setup assists earn no Patibong. Event elimination is never trap credit.
  - **Acceptance:** Replay duplicated/reordered callbacks, competing hazards and goal/death ties; one outcome remains and direct ownership is stable. Actual hazard integration is retested when P10 hazards exist.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P06-T04

- [ ] **Verify record one terminal outcome and direct attribution**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-SCORE-001](PRD.md#req-score-001--record-one-terminal-outcome-and-direct-attribution). **Dependencies:** [P06-T03](#p06-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Replay duplicated/reordered callbacks, competing hazards and goal/death ties; one outcome remains and direct ownership is stable. Actual hazard integration is retested when P10 hazards exist.
  - **Acceptance:** Replay duplicated/reordered callbacks, competing hazards and goal/death ties; one outcome remains and direct ownership is stable. Actual hazard integration is retested when P10 hazards exist.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P06-T05

- [ ] **Implement exact scoring and race award explanations**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-SCORE-002](PRD.md#req-score-002--calculate-race-awards-and-suppression-exactly). **Dependencies:** [P06-T04](#p06-t04).
  - **Work:** Tapos 1.0 per finish; Una +0.25 for earliest finish, all exact indistinguishable first finishers receive it; Bayani +0.5 sole finisher; Patibong +0.25 per directly killed opponent subject to race scoring; Bawi +0.75 if at least 3 points behind leader at round start and finishing. All/none finish suppresses points in 3/4-player races; 2-player waiver permits normal awards. Optional Barya +0.5 for its finisher survives all-finish suppression.
  - **Acceptance:** Table-driven 2/3/4-player cases cover all/none/sole/multiple finishes, exact-first ties, dead trap owner, self kill, underdog snapshot and coin exception; totals are exact and awarded once.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P06-T06

- [ ] **Verify calculate race awards and suppression exactly**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-SCORE-002](PRD.md#req-score-002--calculate-race-awards-and-suppression-exactly). **Dependencies:** [P06-T05](#p06-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Table-driven 2/3/4-player cases cover all/none/sole/multiple finishes, exact-first ties, dead trap owner, self kill, underdog snapshot and coin exception; totals are exact and awarded once.
  - **Acceptance:** Table-driven 2/3/4-player cases cover all/none/sole/multiple finishes, exact-first ties, dead trap owner, self kill, underdog snapshot and coin exception; totals are exact and awarded once.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P06-T07

- [ ] **Implement exact placement arithmetic and score formatting**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-SCORE-003](PRD.md#req-score-003--store-elimination-placement-ties-without-rounding). **Dependencies:** [P06-T06](#p06-t06).
  - **Work:** Use eighth-point units or equivalent exact rational storage. Current legal non-winning groups include 4-player places 3–4 =0.125, 2–3 =0.375, 2–4 =0.25 and 3-player places 2–3 =0.25. First place is never averaged when all remaining players die: Last Cluck applies. Prototype lower loser allocation follows recorded order then averages exactly tied lower groups.
  - **Acceptance:** Enumerate every legal group and compare exact totals at 10 points and underdog threshold; display eighth fractions or sufficient decimals. No claim that eighths cover arbitrary future scoring tables.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P06-T08

- [ ] **Verify store elimination placement ties without rounding**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-SCORE-003](PRD.md#req-score-003--store-elimination-placement-ties-without-rounding). **Dependencies:** [P06-T07](#p06-t07).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Enumerate every legal group and compare exact totals at 10 points and underdog threshold; display eighth fractions or sufficient decimals. No claim that eighths cover arbitrary future scoring tables.
  - **Acceptance:** Enumerate every legal group and compare exact totals at 10 points and underdog threshold; display eighth fractions or sufficient decimals. No claim that eighths cover arbitrary future scoring tables.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


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
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-SLICE-001](PRD.md#req-slice-001--demonstrate-the-first-playable-buildrace-loop). **Dependencies:** [P05-T12](#p05-t12), [P06-T08](#p06-t08), [P04-T09](#p04-t09), [P04-T18](#p04-t18), [P04-T10](#p04-t10), [P04-T19](#p04-t19).
  - **Work:** First slice uses only verified Kaing/Tulay in labeled karera_slice. Two players complete Lobby→Pugad→Place→Karera→results→next round twice; stage persists through ten round resets. Early match ties may show pending sudden-death coverage, never a complete-match claim.
  - **Acceptance:** Record two complete rounds and ten resets with no duplicate placement/score, plus guided first-loop comprehension; missing Lagsanay/sudden death remains explicit.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P07-T02

- [ ] **Verify demonstrate the first playable build/race loop**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-SLICE-001](PRD.md#req-slice-001--demonstrate-the-first-playable-buildrace-loop). **Dependencies:** [P07-T01](#p07-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Record two complete rounds and ten resets with no duplicate placement/score, plus guided first-loop comprehension; missing Lagsanay/sudden death remains explicit.
  - **Acceptance:** Record two complete rounds and ten resets with no duplicate placement/score, plus guided first-loop comprehension; missing Lagsanay/sudden death remains explicit.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P07-T03

- [ ] **Run multiplayer slice and device-isolation sessions**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-SLICE-002](PRD.md#req-slice-002--extend-slice-coverage-to-three-and-four-players). **Dependencies:** [P07-T02](#p07-t02), [P02-T08](#p02-t08).
  - **Work:** Run three rounds at each supported count, rotating slots/devices and exercising maximum camera separation, simultaneous keys, pause/disconnect/reclaim. Construction-only all-finish zero-score rounds are expected and are not release balance evidence.
  - **Acceptance:** 2/3/4-player matrix identifies devices and all unavailable combinations; no cross-controlled seat or hidden live player; pause/reclaim preserves state.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P07-T04

- [ ] **Verify extend slice coverage to three and four players**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-SLICE-002](PRD.md#req-slice-002--extend-slice-coverage-to-three-and-four-players). **Dependencies:** [P07-T03](#p07-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. 2/3/4-player matrix identifies devices and all unavailable combinations; no cross-controlled seat or hidden live player; pause/reclaim preserves state.
  - **Acceptance:** 2/3/4-player matrix identifies devices and all unavailable combinations; no cross-controlled seat or hidden live player; pause/reclaim preserves state.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


## P08 — Lagsanay

**Goal / player-visible result:** Independent tag elimination yields one winner.

**Milestone / scope:** Feature-complete submission, then release/submission.

**Entry:** P07 input/loop gates and exact outcome arithmetic available.

**External task dependencies:** [P02-T12](#p02-t12), [P06-T08](#p06-t08), [P07-T04](#p07-t04)

**Owner roles:** Gameplay; person names TBD. **Systems touched:** NEW tag mode and placement/Last Cluck integration.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Passing, immunity/head start, elimination tables and Last Cluck pass at 2/3/4 players.

**Evidence required:** Independent-mode results; real trap credit verified after hazards exist.


#### P08-T01

- [ ] **Implement taya lifecycle, head start and tag arbitration**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-LAG-001](PRD.md#req-lag-001--implement-opening-taya-contact-passing-and-countdown). **Dependencies:** [P07-T04](#p07-t04), [P02-T12](#p02-t12).
  - **Work:** Choose random taya; first taya freezes hazard-immune about 3 s before countdown starts. Others disperse from shared spawn. Pass by sensor contact; nearest eligible candidate then lowest slot on exact distance tie. Prototype ongoing overlap checks permit at most one global pass per step, 1 s previous-taya immunity; pass does not reset countdown.
  - **Acceptance:** 2/3/4-player tests include stationary overlap, multiple candidates, immunity expiry, opening hazard contact and no opening tag; recorded countdown never resets on pass.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P08-T02

- [ ] **Verify implement opening taya, contact passing and countdown**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-LAG-001](PRD.md#req-lag-001--implement-opening-taya-contact-passing-and-countdown). **Dependencies:** [P08-T01](#p08-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. 2/3/4-player tests include stationary overlap, multiple candidates, immunity expiry, opening hazard contact and no opening tag; recorded countdown never resets on pass.
  - **Acceptance:** 2/3/4-player tests include stationary overlap, multiple candidates, immunity expiry, opening hazard contact and no opening tag; recorded countdown never resets on pass.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P08-T03

- [ ] **Implement elimination placement scoring and taya reassignment**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-LAG-002](PRD.md#req-lag-002--resolve-lagsanay-eliminations-and-placements). **Dependencies:** [P08-T02](#p08-t02), [P06-T08](#p06-t08).
  - **Work:** Timeout eliminates taya; trap death eliminates directly. Reassign random live taya if needed, with prototype timers 15/10/7 s at 4/3/2 alive. Last survivor wins. Placements: 4 players 1/.5/.25/0; 3 players 1/.5/0; 2 players 1/0. Patibong applies to direct hazards, Bawi to an underdog winner. No too-easy/too-hard suppression.
  - **Acceptance:** Timeout/trap/taya death and simultaneous earlier deaths produce one placement set; verify all player-count tables and Bawi/Patibong with direct hazard tests when available.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P08-T04

- [ ] **Verify resolve lagsanay eliminations and placements**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-LAG-002](PRD.md#req-lag-002--resolve-lagsanay-eliminations-and-placements). **Dependencies:** [P08-T03](#p08-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Timeout/trap/taya death and simultaneous earlier deaths produce one placement set; verify all player-count tables and Bawi/Patibong with direct hazard tests when available.
  - **Acceptance:** Timeout/trap/taya death and simultaneous earlier deaths produce one placement set; verify all player-count tables and Bawi/Patibong with direct hazard tests when available.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P08-T05

- [ ] **Implement Last Cluck resolution and explanation**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-LAG-003](PRD.md#req-lag-003--select-exactly-one-last-cluck-winner). **Dependencies:** [P08-T04](#p08-t04).
  - **Work:** If all remaining chickens are eliminated in the same physics tick, latest recorded elimination time wins; exactly identical time uses lowest player slot. Remaining losers take lower placements, with the provisional exact-tie allocation documented separately. Brief freeze frame and Last Cluck callout explain the result.
  - **Acceptance:** Exercise 2/3/4 all-remaining eliminations, distinguishable times and exact ties; one winner only, no averaged first and no duplicate award; correct explanation appears.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P08-T06

- [ ] **Verify select exactly one last cluck winner**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-LAG-003](PRD.md#req-lag-003--select-exactly-one-last-cluck-winner). **Dependencies:** [P08-T05](#p08-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Exercise 2/3/4 all-remaining eliminations, distinguishable times and exact ties; one winner only, no averaged first and no duplicate award; correct explanation appears.
  - **Acceptance:** Exercise 2/3/4 all-remaining eliminations, distinguishable times and exact ties; one winner only, no averaged first and no duplicate award; correct explanation appears.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


## P09 — Complete match lifecycle

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

- [ ] **Implement match termination and sudden-death routing**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-MATCH-001](PRD.md#req-match-001--finish-matches-and-run-tied-player-sudden-death). **Dependencies:** [P08-T06](#p08-t06).
  - **Work:** Check totals at round end: first to 10 or highest after round 12. Multiple above 10 are ordered by total; equal leaders enter Lagsanay only among tied players, no Twist, producing exactly one winner. Full match release retains guaranteed event schedule; development override is not release behavior.
  - **Acceptance:** Verify threshold, round-12, unequal simultaneous threshold crossings and 2/3/4 tied-player sudden death; exactly one match winner and no extra score table.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P09-T02

- [ ] **Verify finish matches and run tied-player sudden death**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-MATCH-001](PRD.md#req-match-001--finish-matches-and-run-tied-player-sudden-death). **Dependencies:** [P09-T01](#p09-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Verify threshold, round-12, unequal simultaneous threshold crossings and 2/3/4 tied-player sudden death; exactly one match winner and no extra score table.
  - **Acceptance:** Verify threshold, round-12, unequal simultaneous threshold crossings and 2/3/4 tied-player sudden death; exactly one match winner and no extra score table.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P09-T03

- [ ] **Implement match results, replay and complete teardown**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-MATCH-002](PRD.md#req-match-002--replay-return-to-lobby-and-reset-all-match-state). **Dependencies:** [P09-T02](#p09-t02).
  - **Work:** Match results show final scores/winner with replay and lobby choices. Prototype menu owner selects action and all players freshly ready. Leaving mid-match confirms whole-group return to lobby, never silently changes scoring player count. New match clears construction, scores, captures, transients, event state and ready edges.
  - **Acceptance:** Ten complete restarts show no retained score/timer/immunity/capture or object growth; replay/lobby/quit routes work after ordinary and sudden-death endings.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P09-T04

- [ ] **Verify replay, return to lobby and reset all match state**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-MATCH-002](PRD.md#req-match-002--replay-return-to-lobby-and-reset-all-match-state). **Dependencies:** [P09-T03](#p09-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Ten complete restarts show no retained score/timer/immunity/capture or object growth; replay/lobby/quit routes work after ordinary and sudden-death endings.
  - **Acceptance:** Ten complete restarts show no retained score/timer/immunity/capture or object growth; replay/lobby/quit routes work after ordinary and sudden-death endings.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


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


### Gulong Talon — `move.tire_spring`


#### P10-T01

- [ ] **Define Gulong Talon configuration and variants**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Author the family definition from the catalog; expose tuning keys and keep precision/effect regions distinct.
  - **Acceptance:** Definition lists Single 2×2 default; transformed launch normal at 0/90/180/270 degrees. Regions, rotations, safe start, owner and mode flags are explicit.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T02

- [ ] **Build Gulong Talon scene and collision regions**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon). **Dependencies:** [P10-T01](#p10-t01).
  - **Work:** Create original scene/solid/sensor regions and visible bounds; verify the family-specific placement and rotation contract.
  - **Acceptance:** 2×2 logical footprint proposal; top is launch trigger, body is solid support. Rotation 0/90/180/270; direction follows the transformed launch normal. Force, jump bonus, footprint, cooldown, and grace are tunables.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T03

- [ ] **Implement Gulong Talon mechanic and feedback**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon). **Dependencies:** [P10-T02](#p10-t02).
  - **Work:** Implement the family behavior, tell and counterplay without copying reference code/art; use centralized timing/force settings.
  - **Acceptance:** Contact bounce launches a chicken; timed jump input boosts height. It creates a useful shortcut but can throw players into hazards. Tell: visible compression/coil and bounce arc cue. Counter: approach slowly, decline the boost, or time the jump. Spring is verified community-wiki reference pattern; tire/playful presentation and tuning are original.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T04

- [ ] **Implement Gulong Talon ownership and cleanup**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon). **Dependencies:** [P10-T03](#p10-t03).
  - **Work:** Preserve direct-source ownership/no-assist rules; implement inactive Place, deterministic Play reset, persistent removal and reference/transient teardown.
  - **Acceptance:** Race and Lagsanay; Lagsanay force must not bypass solid-floor containment. Placer owns trap attribution only if the spring impact itself eliminates; otherwise no assist credit. Resets force/cooldown at Play. Needs original tire animation/audio and movement-state interface. Medium-high risk: player launch state and ceiling/bounds safety.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T05

- [ ] **Verify Gulong Talon core behavior in its harness**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon). **Dependencies:** [P10-T04](#p10-t04).
  - **Work:** Run isolated collision/behavior/reset cases before exposing the family to a selectable pool; this is not the later event-compatibility gate.
  - **Acceptance:** Check all configured variants, rotations, collider boundaries, tell/counterplay, deterministic reset and removal. Capture actual results and known limits.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P10-T06

- [ ] **Add Gulong Talon egg animation and placement ghost**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon), [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews), [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P10-T05](#p10-t05), [P05-T02](#p05-t02), [P05-T06](#p05-t06).
  - **Work:** Produce/register original visual preview assets; reuse shared preview infrastructure and preserve claimed variant identity.
  - **Acceptance:** Preview/ghost show Single 2×2 default; transformed launch normal at 0/90/180/270 degrees. Include relevant sweep/lane/effect and non-color validity; no Pugad names/descriptions.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T07

- [ ] **Integrate Gulong Talon with events and scoring**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon). **Dependencies:** [P10-T05](#p10-t05), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04).
  - **Work:** Apply catalog mode restrictions; unsafe capture/force chains block pairing enablement. Walis is construction-only, never a Play hazard.
  - **Acceptance:** Document enabled modes and support eligibility; verify direct credit/no credit and family-specific hazards or forces in independent modes and supported stacks.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T08

- [ ] **Write and animate the Gulong Talon Library entry**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon), [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P10-T06](#p10-t06).
  - **Work:** Author entry data/assets against the shared Library schema; integration is checked when the Library shell is available.
  - **Acceptance:** Entry includes name, looping animation, sizes, placement, tell/counterplay, controls and permitted modes; release filter exposes only enabled content.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T09

- [ ] **Verify Gulong Talon release enablement**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-003](PRD.md#req-item-003--gulong-talon). **Dependencies:** [P10-T07](#p10-t07), [P10-T08](#p10-t08), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Test harness plus 2/3/4-player integration, exact preview/ghost, Library, bounds, source credit, support and ten lifecycle resets. Register artifacts and unresolved defects before enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Trumpo sa Riles — `hazard.rail_trumpo`


#### P10-T10

- [ ] **Define Trumpo sa Riles configuration and variants**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Author the family definition from the catalog; expose tuning keys and keep precision/effect regions distinct.
  - **Acceptance:** Definition lists 4×1, 5×1, 6×1 rails; sweep matches visible length. Regions, rotations, safe start, owner and mode flags are explicit.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T11

- [ ] **Build Trumpo sa Riles scene and collision regions**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles). **Dependencies:** [P10-T10](#p10-t10).
  - **Work:** Create original scene/solid/sensor regions and visible bounds; verify the family-specific placement and rotation contract.
  - **Acceptance:** Place a bounded rail segment; footprint is anchor/rail; sweep is separate and shown in preview. Rotate in 90° increments, with deterministic start direction. Speed, pause, rail length, hitbox width, grace are tunables. No off-camera or unbounded path.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T12

- [ ] **Implement Trumpo sa Riles mechanic and feedback**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles). **Dependencies:** [P10-T11](#p10-t11).
  - **Work:** Implement the family behavior, tell and counterplay without copying reference code/art; use centralized timing/force settings.
  - **Acceptance:** A playful spinning top travels along a short visible rail, pauses at ends, and eliminates on contact. Safe gaps/endpoint pauses allow timing. Tell: rail, rotation, endpoint pause and audio cue. Counter: cross during pause/gap or route above/below. Verified inspiration: Linear Saw’s back-and-forth path; original trumpo, safe timing, and tuning.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T13

- [ ] **Implement Trumpo sa Riles ownership and cleanup**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles). **Dependencies:** [P10-T12](#p10-t12).
  - **Work:** Preserve direct-source ownership/no-assist rules; implement inactive Place, deterministic Play reset, persistent removal and reference/transient teardown.
  - **Acceptance:** Race and event terrain; Lagsanay enabled only after playtest. Owner gets Patibong only for direct contact elimination. Resets to start endpoint and deterministic direction each Play; cleanup releases mover. Needs original top/rail animations, sound, and mover lifecycle. Medium-high risk: collision ordering and sweeps.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T14

- [ ] **Verify Trumpo sa Riles core behavior in its harness**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles). **Dependencies:** [P10-T13](#p10-t13).
  - **Work:** Run isolated collision/behavior/reset cases before exposing the family to a selectable pool; this is not the later event-compatibility gate.
  - **Acceptance:** Check all configured variants, rotations, collider boundaries, tell/counterplay, deterministic reset and removal. Capture actual results and known limits.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P10-T15

- [ ] **Add Trumpo sa Riles egg animation and placement ghost**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles), [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews), [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P10-T14](#p10-t14), [P05-T02](#p05-t02), [P05-T06](#p05-t06).
  - **Work:** Produce/register original visual preview assets; reuse shared preview infrastructure and preserve claimed variant identity.
  - **Acceptance:** Preview/ghost show 4×1, 5×1, 6×1 rails; sweep matches visible length. Include relevant sweep/lane/effect and non-color validity; no Pugad names/descriptions.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T16

- [ ] **Integrate Trumpo sa Riles with events and scoring**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles). **Dependencies:** [P10-T14](#p10-t14), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04).
  - **Work:** Apply catalog mode restrictions; unsafe capture/force chains block pairing enablement. Walis is construction-only, never a Play hazard.
  - **Acceptance:** Document enabled modes and support eligibility; verify direct credit/no credit and family-specific hazards or forces in independent modes and supported stacks.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T17

- [ ] **Write and animate the Trumpo sa Riles Library entry**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles), [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P10-T15](#p10-t15).
  - **Work:** Author entry data/assets against the shared Library schema; integration is checked when the Library shell is available.
  - **Acceptance:** Entry includes name, looping animation, sizes, placement, tell/counterplay, controls and permitted modes; release filter exposes only enabled content.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T18

- [ ] **Verify Trumpo sa Riles release enablement**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-004](PRD.md#req-item-004--trumpo-sa-riles). **Dependencies:** [P10-T16](#p10-t16), [P10-T17](#p10-t17), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Test harness plus 2/3/4-player integration, exact preview/ghost, Library, bounds, source credit, support and ten lifecycle resets. Register artifacts and unresolved defects before enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Parol Pulse — `hazard.parol_pulse`


#### P10-T19

- [ ] **Define Parol Pulse configuration and variants**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Author the family definition from the catalog; expose tuning keys and keep precision/effect regions distinct.
  - **Acceptance:** Definition lists 3–6 cell fixture span; both fixtures and entire beam previewed. Regions, rotations, safe start, owner and mode flags are explicit.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T20

- [ ] **Build Parol Pulse scene and collision regions**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse). **Dependencies:** [P10-T19](#p10-t19).
  - **Work:** Create original scene/solid/sensor regions and visible bounds; verify the family-specific placement and rotation contract.
  - **Acceptance:** Two endpoint anchors define span and collision width; endpoints/beam shown in preview. Horizontal/vertical orientation only. Default proposal: solids block the beam; define and show occlusion. Cycle, charge time (inside inactive 1.5s), width, range and grace are tunables.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T21

- [ ] **Implement Parol Pulse mechanic and feedback**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse). **Dependencies:** [P10-T20](#p10-t20).
  - **Work:** Implement the family behavior, tell and counterplay without copying reference code/art; use centralized timing/force settings.
  - **Acceptance:** Two visible fixtures project a timed light barrier; crossing active span eliminates. A 3-second cycle has 1.5s active and 1.5s inactive; charge-up occupies the final part of inactive time, so it does not extend the cycle. Tell: fixture icons, brightness ramp, non-flashing shape change and audio cue. Counter: cross during safe interval or use cover if cover truly blocks it. Original Tilaok proposal; not UCH reference.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T22

- [ ] **Implement Parol Pulse ownership and cleanup**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse). **Dependencies:** [P10-T21](#p10-t21).
  - **Work:** Preserve direct-source ownership/no-assist rules; implement inactive Place, deterministic Play reset, persistent removal and reference/transient teardown.
  - **Acceptance:** Race and event; Lagsanay only after readability and balance pass. Placer owns direct elimination. Resets phase to inactive/charge at Play start. Needs distinct beam art/audio, overlap readability test. Medium risk; verify at minimum zoom and with multiple emitters. No rapid strobe.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T23

- [ ] **Verify Parol Pulse core behavior in its harness**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse). **Dependencies:** [P10-T22](#p10-t22).
  - **Work:** Run isolated collision/behavior/reset cases before exposing the family to a selectable pool; this is not the later event-compatibility gate.
  - **Acceptance:** Check all configured variants, rotations, collider boundaries, tell/counterplay, deterministic reset and removal. Capture actual results and known limits.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P10-T24

- [ ] **Add Parol Pulse egg animation and placement ghost**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse), [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews), [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P10-T23](#p10-t23), [P05-T02](#p05-t02), [P05-T06](#p05-t06).
  - **Work:** Produce/register original visual preview assets; reuse shared preview infrastructure and preserve claimed variant identity.
  - **Acceptance:** Preview/ghost show 3–6 cell fixture span; both fixtures and entire beam previewed. Include relevant sweep/lane/effect and non-color validity; no Pugad names/descriptions.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T25

- [ ] **Integrate Parol Pulse with events and scoring**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse). **Dependencies:** [P10-T23](#p10-t23), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04).
  - **Work:** Apply catalog mode restrictions; unsafe capture/force chains block pairing enablement. Walis is construction-only, never a Play hazard.
  - **Acceptance:** Document enabled modes and support eligibility; verify direct credit/no credit and family-specific hazards or forces in independent modes and supported stacks.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T26

- [ ] **Write and animate the Parol Pulse Library entry**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse), [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P10-T24](#p10-t24).
  - **Work:** Author entry data/assets against the shared Library schema; integration is checked when the Library shell is available.
  - **Acceptance:** Entry includes name, looping animation, sizes, placement, tell/counterplay, controls and permitted modes; release filter exposes only enabled content.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T27

- [ ] **Verify Parol Pulse release enablement**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-005](PRD.md#req-item-005--parol-pulse). **Dependencies:** [P10-T25](#p10-t25), [P10-T26](#p10-t26), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Test harness plus 2/3/4-player integration, exact preview/ghost, Library, bounds, source credit, support and ten lifecycle resets. Register artifacts and unresolved defects before enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Tsinelas Launcher — `hazard.slipper_launcher`


#### P10-T28

- [ ] **Define Tsinelas Launcher configuration and variants**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Author the family definition from the catalog; expose tuning keys and keep precision/effect regions distinct.
  - **Acceptance:** Definition lists 4×1 or 6×1 lane; 1×1 launcher; 0/180 degrees. Regions, rotations, safe start, owner and mode flags are explicit.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T29

- [ ] **Build Tsinelas Launcher scene and collision regions**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher). **Dependencies:** [P10-T28](#p10-t28).
  - **Work:** Create original scene/solid/sensor regions and visible bounds; verify the family-specific placement and rotation contract.
  - **Acceptance:** One-cell launcher footprint plus distinct visible lane/hitbox, 0/180° rotation. No projectile spawn inside solid/player/protected area. Fire delay, speed, lifetime, cap, cooldown, hitbox, target policy are tunables.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T30

- [ ] **Implement Tsinelas Launcher mechanic and feedback**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher). **Dependencies:** [P10-T29](#p10-t29).
  - **Work:** Implement the family behavior, tell and counterplay without copying reference code/art; use centralized timing/force settings.
  - **Acceptance:** Telegraphs then fires a slipper along a straight lane; hit eliminates. Solids block the projectile. Tell: barrel/aim lane, charge animation and sound. Counter: cover, dodge, or cross outside firing lane. Projectile-launcher pattern is broad reference; slipper, timing, and cover interactions are original.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T31

- [ ] **Implement Tsinelas Launcher ownership and cleanup**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher). **Dependencies:** [P10-T30](#p10-t30).
  - **Work:** Preserve direct-source ownership/no-assist rules; implement inactive Place, deterministic Play reset, persistent removal and reference/transient teardown.
  - **Acceptance:** Race and event; Lagsanay only after body/tag and projectile balance checks. Launcher placer owns direct hit. Projectile has bounded lifetime and is removed at round end/removal. Needs original slipper sprite/animation and projectile pooling if profiling supports it. Medium-high risk: projectile collision ordering and cleanup. No weapon realism.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T32

- [ ] **Verify Tsinelas Launcher core behavior in its harness**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher). **Dependencies:** [P10-T31](#p10-t31).
  - **Work:** Run isolated collision/behavior/reset cases before exposing the family to a selectable pool; this is not the later event-compatibility gate.
  - **Acceptance:** Check all configured variants, rotations, collider boundaries, tell/counterplay, deterministic reset and removal. Capture actual results and known limits.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P10-T33

- [ ] **Add Tsinelas Launcher egg animation and placement ghost**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher), [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews), [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P10-T32](#p10-t32), [P05-T02](#p05-t02), [P05-T06](#p05-t06).
  - **Work:** Produce/register original visual preview assets; reuse shared preview infrastructure and preserve claimed variant identity.
  - **Acceptance:** Preview/ghost show 4×1 or 6×1 lane; 1×1 launcher; 0/180 degrees. Include relevant sweep/lane/effect and non-color validity; no Pugad names/descriptions.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T34

- [ ] **Integrate Tsinelas Launcher with events and scoring**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher). **Dependencies:** [P10-T32](#p10-t32), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04).
  - **Work:** Apply catalog mode restrictions; unsafe capture/force chains block pairing enablement. Walis is construction-only, never a Play hazard.
  - **Acceptance:** Document enabled modes and support eligibility; verify direct credit/no credit and family-specific hazards or forces in independent modes and supported stacks.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T35

- [ ] **Write and animate the Tsinelas Launcher Library entry**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher), [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P10-T33](#p10-t33).
  - **Work:** Author entry data/assets against the shared Library schema; integration is checked when the Library shell is available.
  - **Acceptance:** Entry includes name, looping animation, sizes, placement, tell/counterplay, controls and permitted modes; release filter exposes only enabled content.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T36

- [ ] **Verify Tsinelas Launcher release enablement**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-007](PRD.md#req-item-007--tsinelas-launcher). **Dependencies:** [P10-T34](#p10-t34), [P10-T35](#p10-t35), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Test harness plus 2/3/4-player integration, exact preview/ghost, Library, bounds, source credit, support and ten lifecycle resets. Register artifacts and unresolved defects before enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Walis Cleanup — `utility.walis_cleanup`


#### P10-T37

- [ ] **Define Walis Cleanup configuration and variants**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Author the family definition from the catalog; expose tuning keys and keep precision/effect regions distinct.
  - **Acceptance:** Definition lists 3×3 or 5×5 cleanup area; no solid footprint. Regions, rotations, safe start, owner and mode flags are explicit.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T38

- [ ] **Build Walis Cleanup scene and collision regions**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup). **Dependencies:** [P10-T37](#p10-t37).
  - **Work:** Create original scene/solid/sensor regions and visible bounds; verify the family-specific placement and rotation contract.
  - **Acceptance:** Bounded radius/region with preview; no rotation needed. Never targets base geometry, spawn/goal clearance, hidden event goal, or same-phase newly submitted pieces. Resolve as one removal set, then validate other placements against resulting snapshot; no callback-order dependence. Radius and eligible item categories are tunables.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T39

- [ ] **Implement Walis Cleanup mechanic and feedback**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup). **Dependencies:** [P10-T38](#p10-t38).
  - **Work:** Implement the family behavior, tell and counterplay without copying reference code/art; use centralized timing/force settings.
  - **Acceptance:** During Place only, removes player-built pieces inside a previewed bounded area. Restores a route obstructed by accumulated stage clutter. No Play-phase behavior, no direct damage, no trap credit. Tell: broom preview outlines every exact target and protected exclusion. Counterplay is to place thoughtfully; cleanup is limited by one item use and fixed radius. Broad inspiration from UCH Bomb’s removal role; one-shot construction edit is original.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T40

- [ ] **Implement Walis Cleanup ownership and cleanup**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup). **Dependencies:** [P10-T39](#p10-t39).
  - **Work:** Preserve direct-source ownership/no-assist rules; implement inactive Place, deterministic Play reset, persistent removal and reference/transient teardown.
  - **Acceptance:** Construction-only in race and event rounds; no Lagsanay Play effect. Owner is cleaner for edit audit only, never Patibong. Removed objects do not return on reset. Needs clear ghost/target list and protected-zone outlines. Medium risk: atomic simultaneous edit semantics and support cleanup.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T41

- [ ] **Verify Walis Cleanup core behavior in its harness**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup). **Dependencies:** [P10-T40](#p10-t40).
  - **Work:** Run isolated collision/behavior/reset cases before exposing the family to a selectable pool; this is not the later event-compatibility gate.
  - **Acceptance:** Check all configured variants, rotations, collider boundaries, tell/counterplay, deterministic reset and removal. Capture actual results and known limits.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P10-T42

- [ ] **Add Walis Cleanup egg animation and placement ghost**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup), [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews), [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P10-T41](#p10-t41), [P05-T02](#p05-t02), [P05-T06](#p05-t06).
  - **Work:** Produce/register original visual preview assets; reuse shared preview infrastructure and preserve claimed variant identity.
  - **Acceptance:** Preview/ghost show 3×3 or 5×5 cleanup area; no solid footprint. Include relevant sweep/lane/effect and non-color validity; no Pugad names/descriptions.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T43

- [ ] **Integrate Walis Cleanup with events and scoring**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup). **Dependencies:** [P10-T41](#p10-t41), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04).
  - **Work:** Apply catalog mode restrictions; unsafe capture/force chains block pairing enablement. Walis is construction-only, never a Play hazard.
  - **Acceptance:** Document enabled modes and support eligibility; verify direct credit/no credit and family-specific hazards or forces in independent modes and supported stacks.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T44

- [ ] **Write and animate the Walis Cleanup Library entry**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup), [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P10-T42](#p10-t42).
  - **Work:** Author entry data/assets against the shared Library schema; integration is checked when the Library shell is available.
  - **Acceptance:** Entry includes name, looping animation, sizes, placement, tell/counterplay, controls and permitted modes; release filter exposes only enabled content.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T45

- [ ] **Verify Walis Cleanup release enablement**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-008](PRD.md#req-item-008--walis-cleanup). **Dependencies:** [P10-T43](#p10-t43), [P10-T44](#p10-t44), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Test harness plus 2/3/4-player integration, exact preview/ghost, Library, bounds, source credit, support and ten lifecycle resets. Register artifacts and unresolved defects before enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


### Bula-Bulaklak — `hazard.bubble_planter`


#### P10-T46

- [ ] **Define Bula-Bulaklak configuration and variants**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18), [P10-T05](#p10-t05), [P10-T14](#p10-t14), [P10-T23](#p10-t23), [P10-T32](#p10-t32), [P10-T41](#p10-t41).
  - **Work:** Author the family definition from the catalog; expose tuning keys and keep precision/effect regions distinct.
  - **Acceptance:** Definition lists 1×3 or 1×5 bubble path; 1×1 emitter; fixed upward direction. Regions, rotations, safe start, owner and mode flags are explicit.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T47

- [ ] **Build Bula-Bulaklak scene and collision regions**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak). **Dependencies:** [P10-T46](#p10-t46).
  - **Work:** Create original scene/solid/sensor regions and visible bounds; verify the family-specific placement and rotation contract.
  - **Acceptance:** Emitter footprint separate from bubble trigger/path; vertical fixed path, no rotation in v1. One captive per bubble and one bubble per player. Cadence, path, capture time (~2s), release velocity, grace, bubble cap are tunables. Stop/resolve against ceiling and bounds; release at nearest safe non-overlapping position with bounded velocity. If no safe location exists, release at last safe point with zero velocity.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T48

- [ ] **Implement Bula-Bulaklak mechanic and feedback**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak). **Dependencies:** [P10-T47](#p10-t47).
  - **Work:** Implement the family behavior, tell and counterplay without copying reference code/art; use centralized timing/force settings.
  - **Acceptance:** Emits one bubble at a time along a fixed upward path/cadence. Captures one live chicken for about 2s; no control while held; never eliminates itself. It can displace a player into another trap or past a route. Tell: visible bubble path, cadence and captive icon. Counter: time the gap or let another direct hazard be avoided after release. Original Tilaok proposal; no plant identification or educational claim.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T49

- [ ] **Implement Bula-Bulaklak ownership and cleanup**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak). **Dependencies:** [P10-T48](#p10-t48).
  - **Work:** Preserve direct-source ownership/no-assist rules; implement inactive Place, deterministic Play reset, persistent removal and reference/transient teardown.
  - **Acceptance:** Race: captive must be released before goal completion; captured player can be hit by external traps. Lagsanay: timer continues and captive remains taggable; disable in Lagsanay if capture-to-elimination is unavoidable. Exclude dead/finished/already-captured players; simultaneous captures resolved by stable player ID and bubble ID; short immunity prevents immediate re-capture. Bubble gives no Patibong; actual eliminating trap does. Remove bubble/captive state on death/end/restart/emitter removal. Needs custom player-state lifecycle and cage-free release tests; highest risk, last in A.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T50

- [ ] **Verify Bula-Bulaklak core behavior in its harness**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak). **Dependencies:** [P10-T49](#p10-t49).
  - **Work:** Run isolated collision/behavior/reset cases before exposing the family to a selectable pool; this is not the later event-compatibility gate.
  - **Acceptance:** Check all configured variants, rotations, collider boundaries, tell/counterplay, deterministic reset and removal. Capture actual results and known limits.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P10-T51

- [ ] **Add Bula-Bulaklak egg animation and placement ghost**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak), [REQ-PUGAD-001](PRD.md#req-pugad-001--show-exact-variant-animated-egg-previews), [REQ-PLACE-001](PRD.md#req-place-001--preview-grid-placement-with-actionable-rejection-reasons). **Dependencies:** [P10-T50](#p10-t50), [P05-T02](#p05-t02), [P05-T06](#p05-t06).
  - **Work:** Produce/register original visual preview assets; reuse shared preview infrastructure and preserve claimed variant identity.
  - **Acceptance:** Preview/ghost show 1×3 or 1×5 bubble path; 1×1 emitter; fixed upward direction. Include relevant sweep/lane/effect and non-color validity; no Pugad names/descriptions.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T52

- [ ] **Integrate Bula-Bulaklak with events and scoring**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak). **Dependencies:** [P10-T50](#p10-t50), [P08-T06](#p08-t06), [P11-T12](#p11-t12), [P12-T04](#p12-t04).
  - **Work:** Apply catalog mode restrictions; unsafe capture/force chains block pairing enablement. Walis is construction-only, never a Play hazard.
  - **Acceptance:** Document enabled modes and support eligibility; verify direct credit/no credit and family-specific hazards or forces in independent modes and supported stacks.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T53

- [ ] **Write and animate the Bula-Bulaklak Library entry**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak), [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P10-T51](#p10-t51).
  - **Work:** Author entry data/assets against the shared Library schema; integration is checked when the Library shell is available.
  - **Acceptance:** Entry includes name, looping animation, sizes, placement, tell/counterplay, controls and permitted modes; release filter exposes only enabled content.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P10-T54

- [ ] **Verify Bula-Bulaklak release enablement**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ITEM-006](PRD.md#req-item-006--bula-bulaklak). **Dependencies:** [P10-T52](#p10-t52), [P10-T53](#p10-t53), [P13-T06](#p13-t06), [P12-T06](#p12-t06), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Test harness plus 2/3/4-player integration, exact preview/ghost, Library, bounds, source credit, support and ten lifecycle resets. Register artifacts and unresolved defects before enablement.
  - **Acceptance:** Exercise every approved enabled variant/rotation, valid/invalid placement, readable tell and counterplay, direct attribution, round/reset/removal and permitted event interactions. Complete the targeted family and applicable variants; conditional orientations require recorded support evidence.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


## P11 — Kangaroo independently

**Goal / player-visible result:** Players read and respond to three commands through escalation.

**Milestone / scope:** Feature-complete submission, then release/submission.

**Entry:** P08 outcome infrastructure and P03 actual support contact available.

**External task dependencies:** [P02-T12](#p02-t12), [P03-T06](#p03-t06), [P08-T06](#p08-t06)

**Owner roles:** Gameplay; person names TBD. **Systems touched:** NEW slipper presenter, scheduler, command evaluators and pressure controller.

**Documentation/assets:** Keep linked source contracts, enabled-content manifest, test evidence and relevant asset/disclosure records current; original assets or documented permitted sources only.

**Blocking decisions / conditional scope:** Named owner and prerequisite evidence; engine/devices where relevant. R1–R4 remain inactive; terminal-order gaps require review. No implicit scope cuts.

**Exit criteria:** Individual commands, markers, pressure/Storm and cleanup pass; R1–R4 remain inactive.

**Evidence required:** Support/command tables, overlap limits and Last Cluck captures.


#### P11-T01

- [ ] **Build the non-colliding slipper presenter and command cues**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-KANG-001](PRD.md#req-kang-001--present-and-schedule-independent-kangaroo-commands). **Dependencies:** [P08-T06](#p08-t06), [P03-T06](#p03-t06).
  - **Work:** Create original normal/sole-up/sideways poses, landing animation, text/icon, audio and timing ring. Integrate full/reduced/off shake without any collision or simulation pause.
  - **Acceptance:** Each command has a distinct pose/icon/audio/ring and remains readable muted with shake off; presenter has no gameplay collision.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P11-T13

- [ ] **Implement Kangaroo command selection and base cadence**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-KANG-001](PRD.md#req-kang-001--present-and-schedule-independent-kangaroo-commands). **Dependencies:** [P11-T01](#p11-t01).
  - **Work:** Select equal-weight commands, telegraph/respond/evaluate/reset on the source timings; pre-telegraph Hug reroll at two survivors has no command/pressure effect. Stop selecting at one survivor.
  - **Acceptance:** Seeded selection checks distribution and two-survivor reroll; no commands after a sole survivor; presenter never collides; full/reduced/off shake preserves comprehension.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P11-T02

- [ ] **Verify present and schedule independent kangaroo commands**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-KANG-001](PRD.md#req-kang-001--present-and-schedule-independent-kangaroo-commands). **Dependencies:** [P11-T13](#p11-t13).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Seeded selection checks distribution and two-survivor reroll; no commands after a sole survivor; presenter never collides; full/reduced/off shake preserves comprehension.
  - **Acceptance:** Seeded selection checks distribution and two-survivor reroll; no commands after a sole survivor; presenter never collides; full/reduced/off shake preserves comprehension.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P11-T03

- [ ] **Implement the Freeze command evaluator**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-KANG-002](PRD.md#req-kang-002--evaluate-freeze-from-intentional-input). **Dependencies:** [P11-T02](#p11-t02), [P02-T12](#p02-t12).
  - **Work:** During response, intentional run/jump fails Freeze. Shared deadzone and prototype .10 s release grace filter drift/release. Opposing run buttons still count as intent. Passive motion, launch, wind or tag contact does not fail; deliberate run/jump while captured still counts.
  - **Acceptance:** Test drift, held/released inputs, opposite keys, forced motion, capture and passive tag; input intent and movement outcome cannot be confused.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P11-T04

- [ ] **Verify evaluate freeze from intentional input**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-KANG-002](PRD.md#req-kang-002--evaluate-freeze-from-intentional-input). **Dependencies:** [P11-T03](#p11-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Test drift, held/released inputs, opposite keys, forced motion, capture and passive tag; input intent and movement outcome cannot be confused.
  - **Acceptance:** Test drift, held/released inputs, opposite keys, forced motion, capture and passive tag; input intent and movement outcome cannot be confused.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P11-T05

- [ ] **Implement wave presentation, support evaluation and drain**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-KANG-003](PRD.md#req-kang-003--evaluate-rising-wave-with-actual-built-support). **Dependencies:** [P11-T02](#p11-t02), [P03-T06](#p03-t06).
  - **Work:** Select equal-probability middle-low/middle/middle-high world bands, never camera-relative or rerolled for an impossible layout. Telegraph target line then raise/drain wave. At evaluation require actual grounded player-built eligible support above line; base, airborne, jumping through, bubble or coyote state fails. Prototype bands/tolerance remain untested.
  - **Acceptance:** Test every support-table state just above/on/below each band, destroyed/moving support on evaluation tick and another player’s platform; empty layout remains intentionally unsolvable; drain clears.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P11-T06

- [ ] **Verify evaluate rising wave with actual built support**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-KANG-003](PRD.md#req-kang-003--evaluate-rising-wave-with-actual-built-support). **Dependencies:** [P11-T05](#p11-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Test every support-table state just above/on/below each band, destroyed/moving support on evaluation tick and another player’s platform; empty layout remains intentionally unsolvable; drain clears.
  - **Acceptance:** Test every support-table state just above/on/below each band, destroyed/moving support on evaluation tick and another player’s platform; empty layout remains intentionally unsolvable; drain clears.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P11-T07

- [ ] **Implement pair selection and Hug evaluation**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-KANG-004](PRD.md#req-kang-004--evaluate-pair-only-hug-deterministically). **Dependencies:** [P11-T02](#p11-t02), [P02-T12](#p02-t12).
  - **Work:** At evaluation pair live eligible chickens by shortest contact first, equal-distance player-slot order; one partner maximum. Paired chickens pass and unpaired fail. Contact only at evaluation matters. Three clustered chickens leave one unpaired; four may form two pairs. R2 group-contact alternative remains inactive.
  - **Acceptance:** Verify all-contact three, two pairs of four, split groups, equal distances, entry/exit at evaluation, removed players and the two-survivor pre-telegraph reroll.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P11-T08

- [ ] **Verify evaluate pair-only hug deterministically**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-KANG-004](PRD.md#req-kang-004--evaluate-pair-only-hug-deterministically). **Dependencies:** [P11-T07](#p11-t07).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Verify all-contact three, two pairs of four, split groups, equal distances, entry/exit at evaluation, removed players and the two-survivor pre-telegraph reroll.
  - **Acceptance:** Verify all-contact three, two pairs of four, split groups, equal distances, entry/exit at evaluation, removed players and the two-survivor pre-telegraph reroll.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P11-T09

- [ ] **Integrate Kangaroo markers and terminal lifecycle**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-KANG-005](PRD.md#req-kang-005--integrate-failure-markers-elimination-and-cleanup). **Dependencies:** [P11-T04](#p11-t04), [P11-T06](#p11-t06), [P11-T08](#p11-t08).
  - **Work:** Failed commands add KANG, GA, ROO markers; third eliminates. Traps eliminate directly. Remove terminal players from future command/tag eligibility. Last survivor uses Lagsanay placement/Bawi/Patibong rules; command failures do not earn trap credit. Resolve once through shared outcome infrastructure.
  - **Acceptance:** Test first/second/third failures, overlapping failures and trap same-step review cases; no fourth marker or duplicate placement. End/removal/restart clears scheduler, rings, wave and markers.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P11-T10

- [ ] **Verify integrate failure markers, elimination and cleanup**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-KANG-005](PRD.md#req-kang-005--integrate-failure-markers-elimination-and-cleanup). **Dependencies:** [P11-T09](#p11-t09).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Test first/second/third failures, overlapping failures and trap same-step review cases; no fourth marker or duplicate placement. End/removal/restart clears scheduler, rings, wave and markers.
  - **Acceptance:** Test first/second/third failures, overlapping failures and trap same-step review cases; no fourth marker or duplicate placement. End/removal/restart clears scheduler, rings, wave and markers.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P11-T11

- [ ] **Implement acceleration, Storm overlap and reset**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-KANG-006](PRD.md#req-kang-006--implement-no-elimination-acceleration-and-slipper-storm). **Dependencies:** [P11-T10](#p11-t10).
  - **Work:** After every two completed commands without elimination reduce next response .5 s and reset .15 s, minimum 1 s response and zero reset. After eight enter Storm: landing every .5 s, 1 s command, maximum two active; delay a third. At two survivors force overlapping Freeze plus Rising pairs; Hug rerolls. Any elimination resets pressure/cadence. R3 non-overlap proposal remains inactive.
  - **Acceptance:** Check each acceleration boundary, active cap, delayed landing, two-survivor overlap, elimination reset and all-remaining Last Cluck; reproduce unavoidable-choice risks without claiming balance.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P11-T12

- [ ] **Verify implement no-elimination acceleration and slipper storm**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-KANG-006](PRD.md#req-kang-006--implement-no-elimination-acceleration-and-slipper-storm). **Dependencies:** [P11-T11](#p11-t11).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Check each acceleration boundary, active cap, delayed landing, two-survivor overlap, elimination reset and all-remaining Last Cluck; reproduce unavoidable-choice risks without claiming balance.
  - **Acceptance:** Check each acceleration boundary, active cap, delayed landing, two-survivor overlap, elimination reset and all-remaining Last Cluck; reproduce unavoidable-choice risks without claiming balance.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


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


#### P12-T01

- [ ] **Implement schedule, compatibility pool and prior-Pugad announcement**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-EVENT-001](PRD.md#req-event-001--select-and-announce-the-required-event-schedule). **Dependencies:** [P11-T12](#p11-t12), [P01-T06](#p01-t06).
  - **Work:** Round 1 Karera; rounds 4/8/12 standalone Lagsanay. Other eligible rounds use Karera 70%, Lagsanay 20%, Kangaroo 10%. Only non-guaranteed rounds roll a Twist: 0% rounds 1–4, 10% 5–7, 20% 8–10, 30% 11–12. No self-stack, maximum one Twist, none in sudden death. Lock next round and announce Main then Twist during preceding Pugad; tutorial override only guided first Karera.
  - **Acceptance:** Seeded table covers all 12 rounds, guaranteed-round precedence, prior announcement consistency, zero/one compatible options and required missing-mode rejection.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P12-T02

- [ ] **Verify select and announce the required event schedule**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-EVENT-001](PRD.md#req-event-001--select-and-announce-the-required-event-schedule). **Dependencies:** [P12-T01](#p12-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Seeded table covers all 12 rounds, guaranteed-round precedence, prior announcement consistency, zero/one compatible options and required missing-mode rejection.
  - **Acceptance:** Seeded table covers all 12 rounds, guaranteed-round precedence, prior announcement consistency, zero/one compatible options and required missing-mode rejection.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P12-T03

- [ ] **Resolve the event terminal-order decision table**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-EVENT-002](PRD.md#req-event-002--review-unresolved-simultaneous-terminal-ordering). **Dependencies:** [P08-T06](#p08-t06), [P11-T10](#p11-t10).
  - **Work:** Preserve recorded-time hazard/goal and exact-tie rules, one terminal outcome and Main-only scoring. Before integration document unresolved ordering among command evaluation, timeout, pass, goal and support destruction where existing sources do not fully determine a case. Keep proposed rule replacements inactive.
  - **Acceptance:** A team-reviewed decision table resolves each uncovered same-step case with source or explicit approval and corresponding scenario; no callback-order dependence or silently invented PRD rule.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P12-T04

- [ ] **Verify review unresolved simultaneous terminal ordering**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-EVENT-002](PRD.md#req-event-002--review-unresolved-simultaneous-terminal-ordering). **Dependencies:** [P12-T03](#p12-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. A team-reviewed decision table resolves each uncovered same-step case with source or explicit approval and corresponding scenario; no callback-order dependence or silently invented PRD rule.
  - **Acceptance:** A team-reviewed decision table resolves each uncovered same-step case with source or explicit approval and corresponding scenario; no callback-order dependence or silently invented PRD rule.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P12-T05

- [ ] **Integrate and expose the Karera + Lagsanay pair**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-STACK-001](PRD.md#req-stack-001--integrate-karera-with-lagsanay-pressure). **Dependencies:** [P08-T06](#p08-t06), [P06-T02](#p06-t02), [P06-T08](#p06-t08).
  - **Work:** Flag remains active, bodies pass through, tag sensor works. Finishers become secured and leave taya/target/hazard eligibility. Finishing taya transfers to random unfinished live runner or resolves if none. Prototype reassignment preserves remaining countdown and gives no new opening freeze. Use race-only scoring/suppression and optional Barya.
  - **Acceptance:** 2/3/4 players: current taya finishes, last live runner finishes/dies, secured exclusion, timeout/goal conflict and direct trap awards; no placement score added.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P12-T06

- [ ] **Verify integrate karera with lagsanay pressure**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-STACK-001](PRD.md#req-stack-001--integrate-karera-with-lagsanay-pressure). **Dependencies:** [P12-T05](#p12-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. 2/3/4 players: current taya finishes, last live runner finishes/dies, secured exclusion, timeout/goal conflict and direct trap awards; no placement score added.
  - **Acceptance:** 2/3/4 players: current taya finishes, last live runner finishes/dies, secured exclusion, timeout/goal conflict and direct trap awards; no placement score added.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P12-T07

- [ ] **Integrate the Karera + Kangaroo pair**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-STACK-002](PRD.md#req-stack-002--integrate-karera-with-kangaroo-pressure). **Dependencies:** [P11-T12](#p11-t12), [P12-T04](#p12-t04), [P06-T02](#p06-t02).
  - **Work:** Karera controls round end and scoring. Kangaroo third failure eliminates unfinished runners; secured finishers receive no commands/hazards. Flag and optional Barya stay available; command failure gives no Patibong and no extra score table.
  - **Acceptance:** 2/3/4 players complete all commands under race deadlines; secured finishers never gain markers, failed runners cannot finish later, race suppression and terminal ordering hold.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P12-T08

- [ ] **Verify integrate karera with kangaroo pressure**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-STACK-002](PRD.md#req-stack-002--integrate-karera-with-kangaroo-pressure). **Dependencies:** [P12-T07](#p12-t07).
  - **Work:** Record the procedure, expected and actual result, and review evidence. 2/3/4 players complete all commands under race deadlines; secured finishers never gain markers, failed runners cannot finish later, race suppression and terminal ordering hold.
  - **Acceptance:** 2/3/4 players complete all commands under race deadlines; secured finishers never gain markers, failed runners cannot finish later, race suppression and terminal ordering hold.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P12-T09

- [ ] **Integrate the Kangaroo + Lagsanay pair**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-STACK-003](PRD.md#req-stack-003--integrate-kangaroo-with-lagsanay-pressure). **Dependencies:** [P11-T12](#p11-t12), [P12-T04](#p12-t04), [P08-T06](#p08-t06).
  - **Work:** Kangaroo is Main; Bomb-Taya passes/counts continuously including Freeze. Either third failure, timeout or trap can eliminate; last survivor wins with Lagsanay placement family only. R4 pausing the taya countdown during Freeze remains inactive.
  - **Acceptance:** 2/3/4 players exercise low-countdown Freeze, tag during forced movement, multiple terminal causes, Storm and Last Cluck; one award table and continuous taya time.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P12-T10

- [ ] **Verify integrate kangaroo with lagsanay pressure**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-STACK-003](PRD.md#req-stack-003--integrate-kangaroo-with-lagsanay-pressure). **Dependencies:** [P12-T09](#p12-t09).
  - **Work:** Record the procedure, expected and actual result, and review evidence. 2/3/4 players exercise low-countdown Freeze, tag during forced movement, multiple terminal causes, Storm and Last Cluck; one award table and continuous taya time.
  - **Acceptance:** 2/3/4 players exercise low-countdown Freeze, tag during forced movement, multiple terminal causes, Storm and Last Cluck; one award table and continuous taya time.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


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


#### P13-T01

- [ ] **Complete all menu routes and settings controls**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-UI-002](PRD.md#req-ui-002--complete-title-menus-settings-and-navigation). **Dependencies:** [P09-T04](#p09-t04), [P02-T08](#p02-t08).
  - **Work:** Title offers local match, Library, settings and quit; lobby offers ready/leave/help; pause offers help/Library/settings/resume and confirmed return to lobby. Results offer replay/lobby. Menu ownership follows prototype pause rules. Development builds expose a build label, never internal seeds on player HUD.
  - **Acceptance:** Gamepad and keyboard traverse every screen/back/quit route without traps or accidental game input; opening Library from pause keeps simulation paused and preserves return context.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P13-T02

- [ ] **Verify complete title, menus, settings and navigation**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-UI-002](PRD.md#req-ui-002--complete-title-menus-settings-and-navigation). **Dependencies:** [P13-T01](#p13-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Gamepad and keyboard traverse every screen/back/quit route without traps or accidental game input; opening Library from pause keeps simulation paused and preserves return context.
  - **Acceptance:** Gamepad and keyboard traverse every screen/back/quit route without traps or accidental game input; opening Library from pause keeps simulation paused and preserves return context.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P13-T03

- [ ] **Complete HUD, result explanations and event overlays**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-UI-003](PRD.md#req-ui-003--explain-current-play-and-results-in-the-hud). **Dependencies:** [P12-T02](#p12-t02), [P12-T08](#p12-t08), [P12-T10](#p12-t10).
  - **Work:** Show round/Main Challenge, subordinate TWIST label, exact score totals, relevant deadlines, number/shape, alive/secured/eliminated/taya state, KANG→GA→ROO and enabled Barya carrier. Explain suppressed awards, Last Cluck and next-round selection. No internal IDs/collision shapes/seeds.
  - **Acceptance:** Spectators identify phase, objective, leader, taya, winner and no-score reason; overlapping command rings stay distinct at minimum zoom and with sound/shake off.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P13-T04

- [ ] **Verify explain current play and results in the hud**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-UI-003](PRD.md#req-ui-003--explain-current-play-and-results-in-the-hud). **Dependencies:** [P13-T03](#p13-t03).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Spectators identify phase, objective, leader, taya, winner and no-score reason; overlapping command rings stay distinct at minimum zoom and with sound/shake off.
  - **Acceptance:** Spectators identify phase, objective, leader, taya, winner and no-score reason; overlapping command rings stay distinct at minimum zoom and with sound/shake off.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P13-T05

- [ ] **Implement Library navigation, content filtering and entry template**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P13-T02](#p13-t02), [P05-T02](#p05-t02).
  - **Work:** Library is reachable from title, lobby and pause/settings. Categories: How to Play, Karera, Lagsanay, Kangaroo, Items, Accessibility. Include controls/scoring, all enabled variants, looping animation, placement guides, tell/counterplay and compatible event behavior. Backlog appears only in marked development/reference mode.
  - **Acceptance:** Every enabled family/variant/event has a readable entry and controller-operable category/back navigation; disabled content is absent from release browsing; Pugad remains visual-only.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P13-T06

- [ ] **Verify provide enabled-content library and animated entries**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-LIB-001](PRD.md#req-lib-001--provide-enabled-content-library-and-animated-entries). **Dependencies:** [P13-T05](#p13-t05).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Every enabled family/variant/event has a readable entry and controller-operable category/back navigation; disabled content is absent from release browsing; Pugad remains visual-only.
  - **Acceptance:** Every enabled family/variant/event has a readable entry and controller-operable category/back navigation; disabled content is absent from release browsing; Pugad remains visual-only.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P13-T07

- [ ] **Complete guided tutorial and just-in-time event instruction**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-TUTORIAL-001](PRD.md#req-tutorial-001--teach-the-first-round-and-later-event-rules). **Dependencies:** [P13-T06](#p13-t06), [P13-T04](#p13-t04).
  - **Work:** Guided first Karera teaches identity, move/jump, visible-item selection, claim timeout, place/rotate/validity/confirm, flag and actual results. Prompts are skippable after completion in current session; replayable help remains. First Lagsanay teaches taya/pass/timer/last survivor; first Kangaroo teaches poses, three misses and built supports.
  - **Acceptance:** A novice follows the guided loop and explains objective/input/placement; record each facilitator intervention. Session skip and help replay work; no tutorial bonus or disk completion save is invented.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P13-T08

- [ ] **Verify teach the first round and later event rules**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-TUTORIAL-001](PRD.md#req-tutorial-001--teach-the-first-round-and-later-event-rules). **Dependencies:** [P13-T07](#p13-t07).
  - **Work:** Record the procedure, expected and actual result, and review evidence. A novice follows the guided loop and explains objective/input/placement; record each facilitator intervention. Session skip and help replay work; no tutorial bonus or disk completion save is invented.
  - **Acceptance:** A novice follows the guided loop and explains objective/input/placement; record each facilitator intervention. Session skip and help replay work; no tutorial bonus or disk completion save is invented.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P13-T09

- [ ] **Implement and audit accessibility and readability controls**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ACCESS-001](PRD.md#req-access-001--maintain-color-independent-readable-play). **Dependencies:** [P13-T04](#p13-t04), [P13-T08](#p13-t08).
  - **Work:** Player identity, placement validity, taya, hazards, wave support and coin never depend on color alone. Use redundant silhouette/icon/text/motion/audio; no rapid flashing. Full/reduced/off shake. Critical cues remain understandable muted. Review minimum camera zoom, safe areas, needed language glyphs and supported resolutions.
  - **Acceptance:** QA captures minimum-zoom crowded stage with muted audio and shake off; identifies every critical cue and all four players. Check Parol overlap/readability and no strobe; document supported display/device limits.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P13-T10

- [ ] **Verify maintain color-independent readable play**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-ACCESS-001](PRD.md#req-access-001--maintain-color-independent-readable-play). **Dependencies:** [P13-T09](#p13-t09).
  - **Work:** Record the procedure, expected and actual result, and review evidence. QA captures minimum-zoom crowded stage with muted audio and shake off; identifies every critical cue and all four players. Check Parol overlap/readability and no strobe; document supported display/device limits.
  - **Acceptance:** QA captures minimum-zoom crowded stage with muted audio and shake off; identifies every critical cue and all four players. Check Parol overlap/readability and no strobe; document supported display/device limits.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P13-T11

- [ ] **Implement the spectator cheer action and feedback**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-UI-004](PRD.md#req-ui-004--retain-spectator-cheer-without-gameplay-effects). **Dependencies:** [P08-T06](#p08-t06), [P02-T04](#p02-t04).
  - **Work:** Eliminated players may cheer while spectating; the assigned cheer input produces modest crowd/visual feedback without obscuring active information. Prototype cooldown is 1 s. Enhanced layered crowd/tension behavior is optional, but the basic spectator action remains part of the documented flow.
  - **Acceptance:** An eliminated player can cheer using their assigned binding; repeated input respects cooldown, never moves a player, changes score/timers, triggers commands or obscures live HUD.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P13-T12

- [ ] **Verify retain spectator cheer without gameplay effects**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-UI-004](PRD.md#req-ui-004--retain-spectator-cheer-without-gameplay-effects). **Dependencies:** [P13-T11](#p13-t11).
  - **Work:** Record the procedure, expected and actual result, and review evidence. An eliminated player can cheer using their assigned binding; repeated input respects cooldown, never moves a player, changes score/timers, triggers commands or obscures live HUD.
  - **Acceptance:** An eliminated player can cheer using their assigned binding; repeated input respects cooldown, never moves a player, changes score/timers, triggers commands or obscures live HUD.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


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
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-RELEASE-001](PRD.md#req-release-001--freeze-approved-content-and-close-critical-defects). **Dependencies:** [P15-T02](#p15-t02), [P15-T06](#p15-t06), [P14-T06](#p14-t06).
  - **Work:** October 21 is feature freeze; October 22–23 stabilization. Required scope includes all eight targeted families, modes/stacks, UI/Library/tutorial and essential presentation unless explicitly revised. Decide every Should item include/defer. Included Should work inherits full release gates. No new feature after freeze without explicit scope review.
  - **Acceptance:** Dated manifest enumerates enabled variants/modes/pairs, excluded/deferred content and reviewed defects; zero unresolved crash/softlock/wrong-score/winner/device/lifecycle/onboarding blockers.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P16-T02

- [ ] **Verify freeze approved content and close critical defects**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-RELEASE-001](PRD.md#req-release-001--freeze-approved-content-and-close-critical-defects). **Dependencies:** [P16-T01](#p16-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Dated manifest enumerates enabled variants/modes/pairs, excluded/deferred content and reviewed defects; zero unresolved crash/softlock/wrong-score/winner/device/lifecycle/onboarding blockers.
  - **Acceptance:** Dated manifest enumerates enabled variants/modes/pairs, excluded/deferred content and reviewed defects; zero unresolved crash/softlock/wrong-score/winner/device/lifecycle/onboarding blockers.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P16-T03

- [ ] **Build, package and clean-PC test the release candidate**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Integration (name TBD).
  - **Requirements:** [REQ-EXPORT-002](PRD.md#req-export-002--package-and-verify-the-final-game-on-a-clean-pc). **Dependencies:** [P16-T02](#p16-t02), [P01-T10](#p01-t10).
  - **Work:** Export with recorded engine/templates/preset/build. Package executable and required data, credits/licences, supported devices, launch/quit/restart instructions and known noncritical limits. Verify clean-PC launch without editor or paid licence, complete supported match/tutorial/restart and no gameplay network dependency.
  - **Acceptance:** Checksums and version identify the tested package; clean-PC procedure passes with real hardware; instructions reproduce launch and controls; packaged credits/provenance match assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


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
  - **Work:** Start early: verify current official instructions/category, register, prepare Form 01 roles, Form 02 originality/waiver signatures and Form 03 asset/AI tool-area-extent disclosure with required signatures. Team chooses extent across the entire project. Preserve prompts/history and no false authorship claims.
  - **Acceptance:** Compliance checks current organizer forms, category eligibility and signatures against registered members; completed forms agree with asset/AI records and actual team-authored work.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P17-T02

- [ ] **Verify prepare registration and official forms**
  - **Status:** TODO · **Kind:** VERIFY · **Scope:** REQUIRED · **Owner:** Compliance (name TBD).
  - **Requirements:** [REQ-SUB-001](PRD.md#req-sub-001--prepare-registration-and-official-forms). **Dependencies:** [P17-T01](#p17-t01).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Compliance checks current organizer forms, category eligibility and signatures against registered members; completed forms agree with asset/AI records and actual team-authored work.
  - **Acceptance:** Compliance checks current organizer forms, category eligibility and signatures against registered members; completed forms agree with asset/AI records and actual team-authored work.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


#### P17-T03

- [ ] **Draft synopsis, storyboard and capture schedule**
  - **Status:** TODO · **Kind:** IMPLEMENT · **Scope:** REQUIRED · **Owner:** Compliance (name TBD).
  - **Requirements:** [REQ-SUB-002](PRD.md#req-sub-002--write-the-synopsis-and-plan-media-capture-early). **Dependencies:** [P00-T04](#p00-t04).
  - **Work:** Template 01 synopsis is at most 500 words, covering premise, loop, competitive rules, theme and original work. Plan trailer/demo shot list and captions while gameplay progresses; reserve capture/review time before October 24. Final copy describes only shipped behavior.
  - **Acceptance:** Word count <=500; reviewed copy and shot list cover Pugad, Place, Karera, Lagsanay, theme and results; final-build reconciliation is scheduled before upload.
  - **Evidence:** not yet available. **Verification result:** not yet available.


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

- [ ] **Record inclusion/promotion decision for Barya**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-OPT-001](PRD.md#req-opt-001--barya). **Dependencies:** [P00-T04](#p00-t04).
  - **Work:** Assign owner/capacity and approve the unresolved contract before enabling this optional feature. Race-only optional pickup: about 1-in-3 Pugad appearance replacing one egg; one per round, picker places it, carrier visible, drop on death for others, finish while carrying earns +0.5 even in all-finish suppressed round; remove at round end, never persist as a 37th obstacle.
  - **Acceptance:** Dated include/defer decision and contract resolve unknown behavior, scope and verification responsibilities; content remains disabled until verified.
  - **Evidence:** not yet available. **Verification result:** not yet available.


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
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-009](PRD.md#req-item-009--hagdan-ng-bahay). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T24

- [ ] **Implement Hagdan ng Bahay definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-009](PRD.md#req-item-009--hagdan-ng-bahay). **Dependencies:** [P19-T23](#p19-t23).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Multi-step footholds; can create a steep obstacle. Tell: stair silhouette. Counter: alternate jump route. Solid stepped footprint; 90° rotations. Tune tread count/height and footprint.
  - **Acceptance:** Implement 2×2 or 3×3 steps. Terrain in both modes; placer owns removable static piece; medium risk: collision seams.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T25

- [ ] **Present Hagdan ng Bahay in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-009](PRD.md#req-item-009--hagdan-ng-bahay). **Dependencies:** [P19-T24](#p19-t24).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T26

- [ ] **Integrate Hagdan ng Bahay ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-009](PRD.md#req-item-009--hagdan-ng-bahay). **Dependencies:** [P19-T24](#p19-t24), [P19-T25](#p19-t25), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


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
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-020](PRD.md#req-item-020--yelo-ng-sorbetero). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T79

- [ ] **Implement Yelo ng Sorbetero definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-020](PRD.md#req-item-020--yelo-ng-sorbetero). **Dependencies:** [P19-T78](#p19-t78).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Reduces braking for longer slides; can carry player into danger. Tell: frosty edge pattern. Counter: jump off or plan stopping distance. Surface-only footprint; 90° orientation irrelevant. Tune friction and max speed.
  - **Acceptance:** Implement 3×1 or 4×1 surface. Both modes; no trap credit; reset is static. Medium movement tuning.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T80

- [ ] **Present Yelo ng Sorbetero in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-020](PRD.md#req-item-020--yelo-ng-sorbetero). **Dependencies:** [P19-T79](#p19-t79).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T81

- [ ] **Integrate Yelo ng Sorbetero ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-020](PRD.md#req-item-020--yelo-ng-sorbetero). **Dependencies:** [P19-T79](#p19-t79), [P19-T80](#p19-t80), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


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
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Producer (name TBD).
  - **Requirements:** [REQ-ITEM-022](PRD.md#req-item-022--tinik-tinik-strip). **Dependencies:** [P04-T02](#p04-t02), [P04-T04](#p04-t04), [P04-T09](#p04-t09), [P04-T18](#p04-t18).
  - **Work:** Review this family’s catalog benefit, danger, counterplay, tunables and risk; keep it disabled until promotion. Shared prerequisites are P04-T02, P04-T04, P04-T09, P04-T18.
  - **Acceptance:** A named scope decision resolves all tentative fields in this family, owners/capacity, safe bounds and allowed modes before code.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T89

- [ ] **Implement Tinik-Tinik Strip definition and runtime**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-022](PRD.md#req-item-022--tinik-tinik-strip). **Dependencies:** [P19-T88](#p19-t88).
  - **Work:** Author original scene/collision/runtime and lifecycle following this family contract: Narrow marked strip eliminates on contact, allowing face-level defense. Tell: soft oversized burr silhouette. Counter: jump over/route around. Thin trigger strip, four rotations; tune thickness/active faces.
  - **Acceptance:** Implement 3×1 or 4×1 strip. Both modes after wholesome-art review; placer receives direct kill credit; static reset. Medium readability risk.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T90

- [ ] **Present Tinik-Tinik Strip in Pugad, Place and Library**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Art/UI (name TBD).
  - **Requirements:** [REQ-ITEM-022](PRD.md#req-item-022--tinik-tinik-strip). **Dependencies:** [P19-T89](#p19-t89).
  - **Work:** Create preview/ghost/runtime feedback/audio and descriptive Library data; record licences and cultural review; Pugad remains visual-only.
  - **Acceptance:** Exact variants and relevant trajectory/envelope are visible; readable tell/counterplay and animated Library entry use approved licensed assets.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T91

- [ ] **Integrate Tinik-Tinik Strip ownership, cleanup and mode flags**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** EXPANSION · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-ITEM-022](PRD.md#req-item-022--tinik-tinik-strip). **Dependencies:** [P19-T89](#p19-t89), [P19-T90](#p19-t90), [P12-T04](#p12-t04).
  - **Work:** Use shared item/event infrastructure; test interaction with cover, mover/force/capture/projectile systems relevant to this family, without assuming missing rules.
  - **Acceptance:** Ownership, safe reset/removal, support provenance and mode restrictions match the catalog; unverified pairs remain disabled.
  - **Evidence:** not yet available. **Verification result:** not yet available.


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

- [ ] **Implement Barya behavior**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Gameplay (name TBD).
  - **Requirements:** [REQ-OPT-001](PRD.md#req-opt-001--barya). **Dependencies:** [P19-T01](#p19-t01).
  - **Work:** Race-only optional pickup: about 1-in-3 Pugad appearance replacing one egg; one per round, picker places it, carrier visible, drop on death for others, finish while carrying earns +0.5 even in all-finish suppressed round; remove at round end, never persist as a 37th obstacle.
  - **Acceptance:** Test contested pickup/drop/death/finish, one-coin cap, suppression exception, stacked races, cleanup and disabled pool.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T164

- [ ] **Integrate Barya presentation and lifecycle**
  - **Status:** DEFERRED · **Kind:** IMPLEMENT · **Scope:** SHOULD · **Owner:** Art/UI + Gameplay (name TBD).
  - **Requirements:** [REQ-OPT-001](PRD.md#req-opt-001--barya). **Dependencies:** [P19-T163](#p19-t163).
  - **Work:** Connect enabled-content filtering, player instructions/Library, feedback, ownership/reset where relevant and provenance. Do not change the base release contract implicitly.
  - **Acceptance:** Test contested pickup/drop/death/finish, one-coin cap, suppression exception, stacked races, cleanup and disabled pool.
  - **Evidence:** not yet available. **Verification result:** not yet available.


#### P19-T02

- [ ] **Verify barya**
  - **Status:** DEFERRED · **Kind:** VERIFY · **Scope:** SHOULD · **Owner:** QA (name TBD).
  - **Requirements:** [REQ-OPT-001](PRD.md#req-opt-001--barya). **Dependencies:** [P19-T164](#p19-t164).
  - **Work:** Record the procedure, expected and actual result, and review evidence. Test contested pickup/drop/death/finish, one-coin cap, suppression exception, stacked races, cleanup and disabled pool.
  - **Acceptance:** Test contested pickup/drop/death/finish, one-coin cap, suppression exception, stacked races, cleanup and disabled pool.
  - **Evidence:** not yet available. **Verification result:** COULD-NOT-RUN — prerequisite build/device or review artifact not yet available.


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
| [REQ-TECH-001](PRD.md#req-tech-001--establish-team-authored-project-responsibilities) | [P01-T01](#p01-t01) | [P01-T02](#p01-t02) | REQUIRED |
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
| [REQ-MATCH-002](PRD.md#req-match-002--replay-return-to-lobby-and-reset-all-match-state) | [P09-T03](#p09-t03) | [P09-T04](#p09-t04) | REQUIRED |
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
| [REQ-UI-003](PRD.md#req-ui-003--explain-current-play-and-results-in-the-hud) | [P13-T03](#p13-t03) | [P13-T04](#p13-t04) | REQUIRED |
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

The PRD/tracker documentation can be complete while every gameplay checkbox remains open. The documentation task does not execute P00 decisions on behalf of the team or any later implementation task. First unblocked team action: confirm the registered owners/capacity and actual engine/device inventory in P00. First gameplay experiment after readiness: team-author the movement room, measure full/short jump and braking with two assigned inputs, and test the proposed 64 wu gap/rise targets.

Documentation verification results are recorded in AI_USAGE after checks. Gameplay/controller/performance/export checks remain COULD-NOT-RUN because no suitable runnable game exists. Official form/channel/eligibility rechecks remain submission tasks, not claims that current organizer instructions were independently verified by this documentation work.

## Documentation verification — October 13, 2026

These results concern this documentation delivery only. They do not check any game task above.

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

Temporary document assembly/validation tools and their output were kept outside the repository. The reviewable artifacts are these Markdown documents and the narrow approved consistency/navigation/disclosure edits. No game code, production asset, prompt file, commit or push was produced.
