# P22 — Shared preparation BUILD evidence

**Run date:** 2026-10-23 (Asia/Manila)  
**Starting revision:** `036ad32` on `main`; checkout already contains unrelated user changes and overlapping input/presenter/test/document edits, all preserved.  
**Engine:** installed `godot` wrapper, Godot 4.6.3.stable.official.7d41c59c4. The project documentation targets Godot 4.7.2; this run used the installed 4.6.3 engine.  
**Input:** synthetic seats and headless test fixtures. No rendered or human play session was run.

| Check | Result | Evidence |
|---|---|---|
| Editor import/parse | PASSED, exit 0 | [import-parse.log](import-parse.log) |
| Offline live-build suite | PASSED, 123 checks / 0 failures | [offline-live-build-tests.log](offline-live-build-tests.log) |
| P12 schedule/event regression | PASSED, 59 checks / 0 failures | [run_p12_tests.gd.log](run_p12_tests.gd.log) |
| P13 tutorial regression | PASSED, 58 checks / 0 failures | [run_p13_tutorial_tests.gd.log](run_p13_tutorial_tests.gd.log) |
| Ten-cycle reset/replay lifecycle audit | PASSED, 10 cycles / 0 failures, 2 synthetic seats | [audit_offline_live_build_resets.gd.log](audit_offline_live_build_resets.gd.log) |
| Broad legacy tutorial suite | FAILED, 17 checks; it assumes the old Pugad→Place flow and outdated timer/copy expectations | [run_tutorial_tests.gd.log](run_tutorial_tests.gd.log) |
| Tutorial gate route search | COULD-NOT-RUN to completion; stopped after it stalled at `NO_BUILD_PROGRESS arena.floor attempts=0` before summary | [run_tutorial_gate_tests.gd.log](run_tutorial_gate_tests.gd.log) |
| `gdformat --check` | PASSED, 11 changed GDScript files unchanged after formatting | [gdformat.log](gdformat.log), [format pass](gdformat-write.log) |
| `gdlint` | PASSED, 11 named GDScript files, no problems | [gdlint.log](gdlint.log) |
| `git diff --check` | PASSED, no whitespace errors; Git reported existing CRLF normalization warnings on dirty files | [diff-check.log](diff-check.log) |

The focused suite covers the default 10-second preparation duration across 600 simulation ticks, pause exclusion, final-boundary queued confirmation, GO admission rejection, invalid-placement inventory retention, inert preparation completion during GO, one/several/all early-build choices, single-item accounting in 2/3/4-seat mixed choices, and activation of the same prepared pieces at PLAY. The reset audit was adapted from its stale direct Pugad→GO assumption to cross BUILD and GO before each of ten resets. P13 tutorial checks confirm the preparation copy and preserve the fallback Place copy.

The broad legacy tutorial failures are retained as evidence, not counted as passing. No performance numbers were collected; provisional targets remain 60 FPS / 16.67 ms at 1080p and 512 MiB. No export, rendered capture, physical controller, novice comprehension, independent human review, commit or push was performed.

## Follow-up — BUILD countdown and direct PLAY transition

**Run date:** 2026-10-24 (Asia/Manila)
**Starting revision:** `6480271` on `main`; working tree was clean before this follow-up.
**Engine:** Godot 4.6.3.stable.official.7d41c59c4.
**Scope:** BUILD has a side-HUD timer, a full-screen 3–2–1 only during its last three seconds, and immediately starts active Play with a brief GO! cue. The separate three-second GET READY countdown is reserved for pause resume. No rendered or human session was run.

| Check | Result | Evidence |
|---|---|---|
| Editor import/parse | PASSED, exit 0, no ERROR/WARNING lines | [revised-flow-import-parse.log](revised-flow-import-parse.log) |
| Offline live-build suite | PASSED, 123 checks / 0 failures, exit 0 | [revised-flow-offline-live-build-tests.log](revised-flow-offline-live-build-tests.log) |
| P12 schedule/event regression | PASSED, 59 checks / 0 failures, exit 0; expected missing-mode refusal is logged by its negative test | [revised-flow-p12-tests.log](revised-flow-p12-tests.log) |
| P13 tutorial regression | PASSED, 58 checks / 0 failures, exit 0 | [revised-flow-p13-tutorial-tests.log](revised-flow-p13-tutorial-tests.log) |
| Ten-cycle reset audit | PASSED, 10 cycles / 0 failures, exit 0 | [revised-flow-reset-audit.log](revised-flow-reset-audit.log) |
| Named-file `gdformat --check` | PASSED, 7 files unchanged | [revised-flow-gdformat.log](revised-flow-gdformat.log) |
| Named-file `gdlint` | PASSED, no problems | [revised-flow-gdlint.log](revised-flow-gdlint.log) |
| `git diff --check` | PASSED after removing trailing Markdown hard-break spaces; Git warns of existing CRLF/LF normalization on dirty files | [revised-flow-diff-check.log](revised-flow-diff-check.log) |

The focused suite verifies the full BUILD timer has no full-screen overlay, the 3-second threshold shows the screen count, pause freezes BUILD, the final queued placement resolves before direct PLAY, a saved item remains placeable during active play, and a preparation job crossing the boundary completes during Play. The reset audit also exposed a floating-point edge at exactly two seconds; completion now compares elapsed time with a 1 μs tolerance. Godot's headless test exits report ObjectDB/resource cleanup warnings after passing assertions; those warnings are retained in the raw logs. The P13 suite also emits a Forward+ volumetric-fog warning under the headless compatibility renderer.

The earlier BUILD→GO logs above remain historical and are not evidence for the revised boundary. No performance measurements, rendered playtest, physical-input session, novice session, independent human review, commit or push is claimed.
