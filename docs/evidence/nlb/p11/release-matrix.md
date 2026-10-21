# NLB-P11-T03 — Consolidated release matrix and session sheets

**Status (2026-10-21): nothing here has been run. Every result is `COULD-NOT-RUN` — preparatory source only; deferred while the shared laptop is in use; requires physical phones, human participants and an actual reviewer.** No row is PASSED or FAILED, no matrix cell is VERIFIED, and an agent can never complete this task. Synthetic clients, headless processes and the scale/fault runners are engineering evidence only and are **never** counted as phones or participants.

Related: [P11 README](README.md) · [tracker](../../../PHASETASK_NETWORKED_LIVE_BUILD.md) · [contract v1 §7](../p00/protocol-measurement-contract-v1.md) · [P07 compatibility matrix](../p07/compatibility-matrix.md). The networked build stays opt-in; filling this matrix does not promote it (promotion needs a separate recorded team scope decision).

## How to fill it

- A row is filled only from an actual run. Allowed results: `PASSED`, `FAILED`, `COULD-NOT-RUN` (with a reason). Preserve failed runs; fix and add a new row, never overwrite.
- Every row records the **required fields** (below) in its session sheet, with a raw artifact path and the **actual reviewer's** name.
- Thresholds are PROPOSED until the team records hardware and approves them (host 60 Hz / 16.67 ms at 1080p; phone ≥30 FPS and p95 ≤33.3 ms at 720p; ≤100 ms p95 end-to-end; 512 MiB; ≤10 s join; ≤5 s reclaim). There is **no** bandwidth, battery or thermal threshold: those are evidence only. A PASS needs the report generator's rule: complete hardware record, long enough run, non-synthetic source.

### Required record fields (contract v1 §7, `protocol-measurement-contract-v1.md:131`)

build/revision (and `BuildIdentity.BUILD_ID`) · engine · date · platform/OS · device model · battery/thermal state · profile/seed · seat count and input type · map/stage/load · network topology and conditions · duration · procedure · expected/actual · raw artifact path · **actual reviewer**. The hardware record file read by `tests/tools/nlb_p11_report.gd` uses the same keys (`build`, `engine`, `date`, `platform_os`, `device_model`, `battery_thermal_state`, `profile_seed`, `seat_count_input_type`, `map_stage_load`, `network_topology`, `duration_s`, `procedure`, `raw_artifact_path`, `reviewer`).

## A. Entry gates and open upstream work (all block promotion)

| Item | State at 2026-10-21 | Evidence |
|---|---|---|
| P03-T02 (phone lobby, invitation) | open — USER-REPORTED PASS, retained evidence incomplete | [P03](../p03/README.md) |
| P03-T03 (install and join with a real phone) | open — USER-REPORTED PASS, retained evidence incomplete | [P03](../p03/README.md) |
| P04 T01–T03 | open — COULD-NOT-RUN | [P04](../p04/README.md) |
| P05-T02, P05-T03 | open | [P05](../p05/README.md) |
| P06 T01–T03 | open — COULD-NOT-RUN | [P06](../p06/README.md) |
| P07 T01–T03 | open — COULD-NOT-RUN (no content cell VERIFIED) | [P07](../p07/README.md) |
| P08 T01–T03 | open — COULD-NOT-RUN | [P08](../p08/README.md) |
| P09 T01–T03 (P09-T03 gates P11-T01) | open — COULD-NOT-RUN | [P09](../p09/README.md) |
| P10 T01–T03 (P10-T03 gates P11-T01; needs humans) | open — COULD-NOT-RUN | [P10](../p10/README.md) |
| P11 T01–T03 | open — COULD-NOT-RUN, preparatory source | [P11](README.md) |

## B. Carry-over gaps not fixed (promotion blockers until fixed or the team accepts them in a recorded decision)

| # | Gap | Source | Decision |
|---|---|---|---|
| 1 | Kangaroo main rounds are not wired to the disconnect elimination | P08 README, P09 README | _unrecorded_ |
| 2 | Event rounds use `joined_seats()`; Karera uses `original_seat_indices` | P09 README | _unrecorded_ |
| 3 | `SESSION_CLOSE` may not flush if the host process is killed | P09 README | _unrecorded_ |
| 4 | A host with no local seat has no in-game resume control | P08 README | _unrecorded_ |
| 5 | No reconnect/leave button on the phone HUD beyond the results screens | P09 README | _unrecorded_ |
| 6 | Reclaim after a Wi-Fi drop waits for host loss detection | P08 README | _unrecorded_ |
| 7 | Reclaim token travels in clear text on the trusted LAN (by design) | P08 README | _unrecorded_ |
| 8 | In-place replay depends on `reset_room()` for non-default arenas | P09 README | _unrecorded_ |
| 9 | A mid-replay peer loss shrinks the roster after the room restarted | P09 README | _unrecorded_ |

## C. Device inventory (fill before any run)

| Device ID | Model | Android / OS | SoC / RAM | Resolution used | Wi-Fi AP and band | Battery % at start | Thermal state at start | Ambient note |
|---|---|---|---|---|---|---|---|---|
| phone-A | _unrecorded_ | | | | | | | |
| phone-B | _unrecorded_ | | | | | | | |
| phone-C | _unrecorded_ | | | | | | | |
| phone-D | _unrecorded_ | | | | | | | |
| host-PC | _unrecorded_ | Windows | | 1080p | | | | |

The phone minimum hardware is unknown until the team selects and records devices.

## D. Seat-mix × build matrix (required cases)

Build under test: exported Windows host (release preset) + installed Android client (release preset) from one recorded revision; hashes recorded in the [P11 README template](README.md#hash-and-size-recording-template-fill-after-a-real-export).

| ID | Seats (host PC + phones/other) | Required | Result | Session sheet | Reviewer |
|---|---|---|---|---|---|
| S2 | 2 players: host + 1 phone | yes | COULD-NOT-RUN | _none_ | |
| S3 | 3 players: host + 2 phones | yes | COULD-NOT-RUN | | |
| S4 | 4 players: host + 3 phones | yes | COULD-NOT-RUN | | |
| S4P | 4 phones (host has no local seat) | yes (resume-control gap #4 applies) | COULD-NOT-RUN | | |
| M-K+P | keyboard + phone | yes | COULD-NOT-RUN | | |
| M-G+P | gamepad + phone | yes | COULD-NOT-RUN | | |
| M-K+G+P | keyboard + gamepad + phone(s) up to 4 | yes | COULD-NOT-RUN | | |
| L-OFF | local-only fallback (offline route, no network, no phones) | yes | COULD-NOT-RUN | | |
| L-FLIP | offline route → host lobby → back to offline, no leftover session | yes | COULD-NOT-RUN | | |

## E. Content cells

One row per **enabled** cell copied from the [P07 compatibility matrix](../p07/compatibility-matrix.md) at test time (modes, maps, items, stacks). The policy is default-deny: DISABLED cells are expected to be refused (record the refusal as the check); ENGINEERING cells need the dev-only host override and cannot be a required pass; a cell becomes VERIFIED only through a reviewed matrix change that cites real evidence, never by this document.

| Cell ID (from P07) | Status in P07 | Seats × device | Result | Session sheet | Reviewer |
|---|---|---|---|---|---|
| _copy each enabled cell here_ | | | COULD-NOT-RUN | | |

## F. Fault injection (development build, synthetic first, then a physical phone)

Profiles come from `tests/run_nlb_p11_fault_runner.gd`. Synthetic runs are engineering evidence only; the physical re-run is the required case.

| ID | Profile (`--nlb-fault=`) | Synthetic result | Physical-phone result | Notes |
|---|---|---|---|---|
| F0 | baseline (none) | COULD-NOT-RUN | COULD-NOT-RUN | |
| F1 | `loss=5,seed=7` | COULD-NOT-RUN | COULD-NOT-RUN | |
| F2 | `delay=20,jitter=30,seed=7` | COULD-NOT-RUN | COULD-NOT-RUN | |
| F3 | `reorder=10,duplicate=5,seed=7` | COULD-NOT-RUN | COULD-NOT-RUN | duplicates count toward the kick threshold |
| F4 | `loss=10,jitter=50,reorder=10,duplicate=5,seed=7` | COULD-NOT-RUN | COULD-NOT-RUN | |
| F5 | Wi-Fi drop and restore (reclaim ≤5 s from restoration) | n/a | COULD-NOT-RUN | gap #6 applies |
| F6 | Android app killed (token lost, by design) | n/a | COULD-NOT-RUN | |
| F7 | malformed / spoofed / rate-limited traffic bounded (abuse suite) | COULD-NOT-RUN | n/a | |

## G. Ten match/replay cycles

| ID | Seats | Synthetic (scale runner `cycles`) | Physical | Per-cycle teardown counts attached? |
|---|---|---|---|---|
| C2 | 2 | COULD-NOT-RUN | COULD-NOT-RUN | |
| C3 | 3 | COULD-NOT-RUN | COULD-NOT-RUN | |
| C4 | 4 | COULD-NOT-RUN | COULD-NOT-RUN | |

Pass requires no orphan/stale objects, stuck input, seat/score carryover or unexplained count growth (contract v1 §7 "Ten-cycle cleanup"); the report generator flags strictly growing counters, and a human reviews final-minus-initial.

## H. Performance profiles (non-synthetic hardware only for PASS)

| ID | Profile | Source | Result | Telemetry file | Hardware record | Reviewer |
|---|---|---|---|---|---|---|
| P-H2/H3/H4 | host frame, 2/3/4 seats, 1080p, crowded stage, 2 min warm-up + 10 min (exported windowed Windows build) | `--nlb-telemetry` + report | COULD-NOT-RUN | | | |
| P-P | phone frame, 720p landscape, same crowded scene, 2 min + 10 min per selected device | on-device telemetry + report | COULD-NOT-RUN | | | |
| P-RTT | RTT / traffic / cadence evidence, 2/3/4 clients, 10 min idle and gameplay | telemetry | COULD-NOT-RUN | | | |
| P-E2E | end-to-end ≤100 ms p95 | external high-speed capture | COULD-NOT-RUN | | | |
| P-MEM | RSS ≤512 MiB, host and phone, 10 min + 10 cycles | external sampler | COULD-NOT-RUN | | | |
| P-JOIN | join ≤10 s, 20 trials per device | telemetry `join` events | COULD-NOT-RUN | | | |
| P-RECL | reclaim ≤5 s, 20 trials per device | telemetry `reclaim` events | COULD-NOT-RUN | | | |
| P-THERM | 30-minute battery/thermal sample (evidence only, no threshold) | `nlb_p11_thermal_sampler.ps1` | COULD-NOT-RUN | | | |

## I. Human sessions

| ID | Session | Participants (real people) | Result | Session sheet | Reviewer |
|---|---|---|---|---|---|
| H-TOUCH | touch readability and reach on each target phone (per the P10 protocol) | _none recorded_ | COULD-NOT-RUN | [P10 protocol](../p10/README.md) | |
| H-NOVICE-1 | novice session, phone seat | _none recorded_ | COULD-NOT-RUN | | |
| H-NOVICE-2 | novice session, mixed device | _none recorded_ | COULD-NOT-RUN | | |
| H-NOVICE-3 | novice session, 4 players | _none recorded_ | COULD-NOT-RUN | | |

## J. Session sheet template (copy per run)

| Field | Value |
|---|---|
| Matrix row ID | |
| Build / revision / `BuildIdentity.BUILD_ID` | |
| Windows host artifact SHA-256 · APK SHA-256 | |
| Engine | Godot 4.7.2 stable |
| Date and start/end time | |
| Platform / OS · device model | |
| Battery % start/end · thermal state start/end | |
| Profile / seed · map/stage/load (crowded fixture on/off) | |
| Seat count and input type per seat | |
| Network topology · AP · band · injected conditions | |
| Duration | |
| Procedure | |
| Expected | |
| Actual | |
| Result (PASSED / FAILED / COULD-NOT-RUN + reason) | |
| Raw artifact paths (telemetry, report, logs, video) | |
| Participants (humans only) | |
| **Actual reviewer** | |
| Anomalies / follow-ups | |

## K. Promotion-blocker rules

The networked build is **not** promoted while any of these holds (and promotion additionally needs a separate recorded team scope decision):

1. Any required row above is FAILED or COULD-NOT-RUN, or lacks an actual reviewer.
2. Any open task in section A is still open.
3. Any carry-over gap in section B has no recorded fix or recorded team acceptance.
4. A required result rests on synthetic clients, headless processes or the scale/fault runners.
5. A performance budget outcome lacks a complete hardware record or a long-enough, non-truncated run.
6. Release artifacts have no recorded hash/size, or were not exported with `--export-release`.
7. Any matrix content cell is marked VERIFIED without a reviewed matrix change citing real evidence.
8. The offline fallback rows (L-OFF, L-FLIP) are not PASSED.

This document records the blockers; it does not decide them.
