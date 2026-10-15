# Barya round objective — engineering evidence (2026-10-15)

**Status:** implemented and technically verified on synthetic engineering evidence. This optional Should feature is enabled on the default P12 scheduled route after verification. P07 remains disabled; P12 has a `--barya-disabled` rollback switch. P00-T04 remains BLOCKED and this work does not ratify the release manifest.

| Field | Value |
|---|---|
| Source revision | `dc4c393` (`Implement Barya round objective`), the exact source revision used for the recorded runs; this source-reference update is documentation-only. |
| Engine | `D:\Downloads\Godot_v4.7.2-stable_win64_console.exe` — Godot 4.7.2.stable.official.ed1daf0bf |
| Date / machine | 2026-10-15 · Windows · Intel Core i5-13420H · NVIDIA GeForce RTX 4050 Laptop GPU |
| Default route | `GameFlow` selects `P12ScheduledMatchRoom` (`route=lifecycle`). P07 is `-- --match-route=first_playable`. |
| Test profile / seed | `karera_slice` · seed 12345; deterministic tests supply scenario seeds; only test runners force Main/Twist entries. |
| Seats / input | Two-seat real-loop suite; 2/3/4-seat scoring and both Karera stacks; four-seat performance sample. Synthetic keyboard/gamepad identities; no physical device. |
| Physics / review | Real Godot Area2D/PhysicsServer overlap snapshots and controller roots; terminal-event candidates are scripted by the test runner. Reviewer: Codex AI-assisted engineering run; no human reviewer. |

## Contract implemented

- Roll only after the committed P12 schedule entry is known and only for Karera, including its Bomb-Taya and Kangaroo stacks. Never offer for standalone Lagsanay/Kangaroo, Kangaroo + Lagsanay or sudden death.
- Use the independent seeded `barya` stream; default chance is 1/3. Replace one uniformly selected egg and preserve pool size. Disabled/ineligible Barya consumes no Barya randomness and preserves the baseline pool.
- One match/round/attempt-identified coin follows Pugad claim and Place. It reserves 1×1 space and respects confirmation locking, protected zones, existing item overlap and player clearance, but it never enters ItemManager, the 48-piece cap, solid/support behavior, Rising or Walis.
- Physics-step snapshot arbitration chooses the nearest eligible controller root, with lower seat index on exact ties. Carry follows the chicken and survives capture. Only a committed elimination drops at the chicken controller root; invalid cells recover to the nearest valid cell with row-major `(y, x)` distance ties, or discard when no cell exists. Same-step drops wait until the next step before pickup.
- A committed finisher carrying the coin receives four eighth-point units (+0.5) exactly once, including all-finish rounds. No finisher receives no Barya score. Results and history copy the receipt before cleanup.
- Pause freezes the objective. Aborted attempts retain the placed cell, advance the attempt identity, clear temporary carrier/receipt state and do not reroll Pugad. Normal round cleanup removes the coin. UI cues, Library filtering and tutorial copy read live objective state; presentation does not own score state.

The full dated decision and boundaries are in [the scoped activation contract](activation_contract_2026-10-15.md). Code-drawn coin and egg-preview geometry is a DEBUG placeholder with human replacement ownership recorded in [ASSETS.md](../../ASSETS.md#barya-debug-placeholder--2026-10-15). No final art, audio, external asset, UCH material or production asset was generated or imported.

## Automated and physics results

The standalone regression command is:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --fixed-fps 60 --path 'tilaok!' --script 'res://tests/run_barya_tests.gd'
```

It passed **72 checks, 0 failures**. The rendered run adds the eight capture-save assertions and passed **80 checks, 0 failures**:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_barya_tests.gd' -- --capture-barya
```

Checks cover probability boundaries, seeded sampling and disabled parity, offer eligibility, unchanged egg count, one coin maximum, claim/placement/timeout/protected-area and capacity behavior, deterministic pickup/drop ties, identity/retry, scoring suppression and all-finish payout for 2/3/4 seats, and a real Godot-physics round loop. That loop exercises contested pickup, attachment during movement, capture, committed death drop/recovery, the same-step reclaim gate, subsequent pickup, committed finish, result/history receipt and cleanup. See [the focused log](test_logs/run_barya_tests.txt) and [rendered runner log](test_logs/run_barya_rendered_capture.txt).

Fourteen regression suites passed with zero failures. Counts and full process logs are in [regression summary](test_logs/regression_summary.txt): Barya 72, P05 137, placement/claim 15, blocks 111, P06 102, P09 77, P12 61, P12 stack 47, P12 pairs 285, P07 591, P13 HUD 265, Library 368, tutorial 58 and scoreboard chart 52. These are engineering checks, not human/device acceptance.

## Rendered captures

The runner saves eight 1280×720 views from the live scene tree. The pickup overlap and carry/drop state uses the real Godot physics server; input and test terminal candidates are synthetic.

| Capture | View |
|---|---|
| [01-pugad-offer.png](captures/01-pugad-offer.png) | Pugad Barya egg offer and number/shape identity. |
| [02-place-locked.png](captures/02-place-locked.png) | Picker's 1×1 objective and first-confirm reservation feedback. |
| [03-play-coin-available.png](captures/03-play-coin-available.png) | Placed coin in the Karera stage. |
| [04-carried.png](captures/04-carried.png) | Coin attached to the selected chicken after contested pickup. |
| [05-death-drop-recovered.png](captures/05-death-drop-recovered.png) | Controller-root death drop recovered from a protected cell. |
| [06-reclaimed.png](captures/06-reclaimed.png) | Second player carries the recovered coin. |
| [07-finish-secured.png](captures/07-finish-secured.png) | Committed finisher secures the Barya receipt. |
| [08-results-award.png](captures/08-results-award.png) | Results and history show Barya +0.5 (four eighths). |

## Performance and cleanup

[The repeatable performance script](../../../tilaok!/tests/capture_barya_performance.gd) runs the default P12 room at 1280×720 windowed, v-sync off, four synthetic seats, forced Karera + Kangaroo, a carried coin and 41 persistent construction pieces after Place. It warms 120 frames and measures 300 rendered frames. On this local PC: median **1.976 ms**, p95 **2.836 ms**, worst **3.881 ms**, static memory **120.55 MiB**, and **0 orphan nodes** after cleanup. The synchronous objective cleanup call took **5 µs**; its queued `free` drained after one process and physics frame. The 16.67 ms and 512 MiB local budgets passed. This single machine sample does not establish target-PC acceptance.

Artifacts: [performance report](barya_performance.txt), [runner log](test_logs/capture_barya_performance_run.txt).

## Import, lint, export and startup smoke

Godot 4.7.2 headless editor import/parse passed. The changed GDScript passed `gdformat --check` and `gdlint`. The Windows Desktop debug export completed to ignored local output `build/tilaok-barya-verify.exe` plus its PCK and console wrapper. The exported console wrapper exited 0 and logged:

- default player route: `TILAOK_FLOW_READY ... route=lifecycle`;
- direct P12 harness room: `P12_SCHEDULED_MATCH_READY ... barya_enabled=true`;
- same P12 harness room with `--barya-disabled`: `... barya_enabled=false`;
- P07 route: `TILAOK_FLOW_READY ... route=first_playable`.

These are startup smokes, not a clean-PC export acceptance. See [import](test_logs/editor_import.txt), [format](test_logs/gdformat_check.txt), [lint](test_logs/gdlint.txt), [export](test_logs/windows_export.txt) and the [default](test_logs/export_smoke_default.txt), [P12](test_logs/export_smoke_p12.txt), [rollback](test_logs/export_smoke_p12_rollback.txt) and [P07](test_logs/export_smoke_p07.txt) logs.

After pushing, the clean Desktop `codex/docs-event-catalog` checkout was verified as an ancestor and fast-forwarded to `536dc12`; the branch name and its 59 commits ahead of its tracking remote were preserved. Godot 4.7.2 headless editor import/parse and a 120-frame default-route launch both exited 0; the latter reported `route=lifecycle`. See the [Desktop smoke log](test_logs/desktop_smoke_2026-10-15.txt).

## Reproduce

From the repository root, using the explicit Godot 4.7.2 executable:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --editor --path 'tilaok!' --quit
$changed = git status --porcelain | ForEach-Object { $_.Substring(3) } | Where-Object { $_ -like '*.gd' }
gdformat --check $changed
gdlint $changed
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --fixed-fps 60 --path 'tilaok!' --script 'res://tests/run_barya_tests.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/run_barya_tests.gd' -- --capture-barya
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --script 'res://tests/capture_barya_performance.gd'
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --export-debug 'Windows Desktop' '../build/tilaok-barya-verify.exe'
```

For exported startup smoke, run `build/tilaok-barya-verify.console.exe` with the arguments and current directory shown by the four smoke logs; this enables stdout from the debug export's console wrapper. The screen captures and physics simulations use synthetic input. No human review, physical keyboard/gamepad, accessibility review, cultural review, player comprehension session, final art/audio review or independent QA session is claimed. Keep these gates open in [PLAYTEST.md](../../PLAYTEST.md) and the tracker.
