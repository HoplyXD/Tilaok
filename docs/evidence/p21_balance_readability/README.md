# P21 balance and readability evidence

**Status:** IN PROGRESS; implementation and headless checks recorded, no final balance or rendered acceptance claim.

## Source changes

Base revision inspected before this slice: `2cc6e46edfae517a0ab874ffb92caa080cdcdf8a` (`main`); verification used the modified working tree on the same Desktop checkout. Date: 2026-10-23. Engine: `Godot_v4.7.2-stable_win64_console.exe`, version `4.7.2.stable.official.ed1daf0bf`, project target 4.7. Editor import/parse completed with exit 0 and no warnings/errors (`import-parse.log`). Synthetic tests do not represent human input or a reviewer.

Timer changes, based on the committed defaults at the base revision:

| Window | Old | New provisional |
|---|---:|---:|
| Pugad selection | 8 s | 15 s |
| Karera hard cap / first-finisher window | 60 / 15 s | 120 / 30 s |
| Lagsanay taya with 2 / 3 / 4 alive | 7 / 10 / 15 s | 20 / 25 / 30 s |
| Kangaroo telegraph / response / reset | 1 / 3 / 0.75 s | 2 / 6 / 1.5 s |
| Kangaroo accelerated response / reset floors | 1 / 0.5 s effective in old controller | 3 / 0.75 s, centrally configured |
| Storm threshold / landing interval / response | 8 commands / 0.5 / 1 s | 16 commands / 1.5 / at least 3 s |

These are starting values only. The P12 normal-match runtime snapshot test checks the values before test acceleration. No profile resource overrides these gameplay settings; `GameplayTuning` is constructed for the room and copied as the match snapshot.

## Acceptance state

- Timer defaults/floors: P06 102/0, P08 86/0, P11 78/0, P12 59/0, including runtime timer snapshot, forced stale mixed-entry, Lagsanay pause/resume and Kangaroo command-clock pause/resume.
- Standalone schedule: P12 500 seeded schedules, 100 stale compatibility-row seeds and full 2/3/4-seat matches; 59 checks / 0 failures. The expected fail-closed missing-Lagsanay diagnostic is printed by its refusal scenario.
- Rising Wave: default, `tutorial`, `map1`, `map2` and every `MapCatalog` map were covered at three vertical offsets; completed eligible support, base-only, stale, removed, airborne/no-support, unreachable geometry and bounded fallback are checked by P11 (78/0). Reach feasibility estimates movement range, jump rise, width and current player position; it does not ray/path-test obstacles or trajectory.
- Overhead markers/Library: P13 HUD 145/0, Library 407/0, and tutorial 56/0; 2/4 synthetic seats, ownership, 0/1/2/3 failure states, side-panel removal, overlap lanes and inverse zoom at close/wide camera scales, and stale-pair Library/tutorial rejection checked. These are headless logic/UI checks, not rendered readability evidence.
- Construction/scoring/Barya/terminal precedence: P06/P12 checks pass. Offline live-build suite: 78 checks, 72 pass and 6 fail, all six in existing per-seat HUD control-hint expectations; the suite's pause/GO/job-boundary/cancel/commit checks pass, including one second, just under two seconds, and completion at two seconds.
- Named-file tooling: `gdlint` reports no problems on 30 named scripts; `gdformat --check` reports 30 files unchanged. `git diff --check` status is recorded separately after the final documentation edits.

## Rendered / human testing

**COULD-NOT-RUN:** no approved rendered session was started. No desktop, mouse, keyboard, focus, or another person's game was taken over. Rendered two/four-player close/wide camera captures, physical input checks, in-game actor/round cleanup, human review and reviewer identity remain open. The overhead markers and Rising line have not been visually inspected in a running game.

## Performance

Targets retained, not measured: 60 FPS / 16.67 ms at 1080p, 512 MiB process memory, 0 B/s gameplay networking.

## Logs and build

The log files in this directory preserve the actual headless outputs. The tests use synthetic fixtures; P12's full match uses seed `12345`; its expected missing-mode refusal logs an error-level diagnostic, and Godot reports 7 ObjectDB instances / 2 resources in use at process shutdown after the 59/0 success summary; P11 enumerates the default layout plus `tutorial`, `map1` and `map2`; P13 HUD covers 2 and 4 seats. No human reviewer is claimed.

Windows Desktop debug export completed, not launched: `build/tilaok-offline-live-build-20261023-p21.exe` (103,076,864 bytes) with `build/tilaok-offline-live-build-20261023-p21.pck` (6,620,656 bytes). The previous known-good `20261022-r3` pair remains in place. SHA-256 EXE: `39C7BC5E257083B14A195B72FE656DE51608E9E2F0287C83FBCED10411738C0B`; PCK: `4D6454D027DA7D094AC12E5FC648A9C8E0F57E02938B6B874198FD395D835646`. This export was made from the final verified working tree after fast-forwarding five upstream audio commits; it has not been launched or rendered. PowerShell launch command from repository root: `& ".\build\tilaok-offline-live-build-20261023-p21.exe"`. Manual check: start a local 2-player keyboard match, compare the timer values above, complete a player-built support before a Rising prompt, and confirm KANG / GA / ROO stay above the chickens through movement and camera zoom.
