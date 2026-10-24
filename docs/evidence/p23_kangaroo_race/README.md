# P23 Kangaroo race redesign evidence

**Date:** 2026-10-24 · **Engine:** Godot 4.6.3 stable via `C:\Users\roman\tools\bin\godot.cmd` · **Checkout:** Desktop `main` at the P23 starting revision; no branch/worktree.

## Current implementation summary

Standalone Kangaroo now enters the Karera flag race lifecycle and race ledger. The slipper controller schedules sequential commands, allows Hug at two living seats, evaluates Rising against the current hitbox bottom, and advances cadence after each completed command. Freeze calls the chicken's temporary control lock and the offline live-build room rejects frozen new/control placement while allowing jobs already in progress to complete. Barya policy treats standalone Kangaroo as race eligible. Current tutorial and Library copy describe the race model.

## Verification log

| Check | Result | Evidence boundary |
|---|---|---|
| Godot headless editor import/parse | PASSED, exit 0 | Script/import parse only.
| P02 movement/Freeze actor suite | PASSED, 95 checks / 0 failures | Real ChickenController in the P02 room; airborne gravity, steering lock, buffered jump release, external movement, projectile elimination, tint, terminal/reset cleanup. |
| P11 focused scheduler contract | PASSED, 19 checks / 0 failures | Synthetic controller scheduling, sole-runner command selection, exact Rising hitbox tolerance and ten controller resets; not full actor physics or human play.
| P12 scheduled-room suite | PASSED, 57 checks / 0 failures | Synthetic seats and scheduled race fixtures at 2/3/4; not rendered/device play.
| Legacy P12 stack runner | NOT CURRENT ACCEPTANCE | Three setup assertions require retired Karera + Bomb-Taya; fixture continues and emits cascading missing-seat index errors.
| P06 | PASSED, 102 checks / 0 failures | Synthetic Karera race/scoring regression. |
| P08 | PASSED, 86 checks / 0 failures | Synthetic Lagsanay regression. |
| Barya | PASSED, 72 checks / 0 failures | Includes standalone Kangaroo eligibility; runner reports three resource leaks at exit. |
| P13 Tutorial | PASSED, 58 checks / 0 failures | Current Kangaroo coaching copy and session flow. |
| P13 Library | PASSED, 425 checks / 0 failures | Current Library text and gating; synthetic UI contract. |
| Offline live-build | PASSED, 123 checks / 0 failures | Synthetic preparation/live placement and controls. |
| `gdformat --check` / named-file `gdlint` | PASSED | 15 named GDScript files; controller file-length lint suppression retained due the expanded controller. |
| `git diff --check` | PASSED | Git reports CRLF normalization warnings for modified Windows files; no whitespace errors. |
| Human, physical device, rendered review, performance | Not run | No visible application or physical test was launched; provisional budgets remain unmeasured.
| Delivery | No commit/push | User authorized implementation only; no separate delivery instruction.

Do not treat P11's old Storm, three-marker, support-only Rising or pair-only Hug evidence as current acceptance. Race-ledger scoring edge cases and the remaining actor-level Freeze/Rising/Hug matrix remain open; see P23-T01/T02. P23-T05 verification record is complete for the installed-engine and named-suite gate.
