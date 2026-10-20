# NLB-P04 source and deferred verification — 2026-10-21

## Current result

P04 implementation source and a focused test runner have been authored. **P04 remains 0/3 checked.** No Godot import/parser run, P04 test run, raw ENet channel experiment, host/client process test, fault-injection run, rendered walkthrough, export, performance sample, or phone session was performed. Record the runtime result as:

> COULD-NOT-RUN — deferred while the shared laptop is in use.

The P03-T03 dependency remains formally open. The P04 implementation does not clear it, and no P03 or P04 tracker box was checked. The source includes `run_nlb_p04_tests.gd`; a P04-specific multi-process/fault runner, rendered walkthrough, and physical-device evidence are still outstanding. All records here distinguish source presence from verified behavior.

## Authored source

- Protocol v1.2 / schema 2 measurement contract: [P00 amendment](../p00/protocol-measurement-contract-v1.2.md).
- Transport, frame families, bounded typed codecs, host input/session lifecycle, local/remote router integration, P12 match start, snapshots/state replication, detached client rendering and minimum touch controls are listed in the P04 task records in [the tracker](../../../PHASETASK_NETWORKED_LIVE_BUILD.md).
- Focused source-path checks: `tilaok!/tests/run_nlb_p04_tests.gd` (authored, not run).
- Expected multi-process runner path from the plan: `tilaok!/tests/run_nlb_p04_multi_process.gd` (not yet authored).

## Deferred test commands

Run only after the user provides a separate explicit testing window and the shared laptop is available. These commands are templates; no command below has been run for P04.

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\roman\Desktop\Vscode Projects\Tilaok\tilaok!' --script res://tests/run_nlb_p04_tests.gd
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\roman\Desktop\Vscode Projects\Tilaok\tilaok!' --script res://tests/run_nlb_p04_multi_process.gd
```

The second runner must be implemented before its command is usable. Then add the raw ENet flag/order experiment, host/client fault-injection and recovery, shared-tick convergence, repeated network teardown, rendered host/client walkthrough, and permitted Windows/Android/phone checks. Record revision, engine version, seed, topology/device details, sanitized logs, captures, and the actual reviewer. Keep host/phone performance budgets provisional and report traffic and latency segments separately; do not infer a bandwidth threshold or release-performance pass.

## P03-T03 evidence closure

The tracker currently records P03-T03 as user-reported PASS with evidence incomplete. Before treating it as a satisfied P04 dependency, retain the exact APK/build and device configuration from the reported physical run, an itemized record of join/leave/rejoin and rejection cases, plus sanitized host/phone logs and captures. If those records do not exist, repeat the physical cases during a permitted capture session. Do not recreate evidence from memory or mark the tracker complete without the artifacts and review.

## Verification log

| Item | Result | Evidence |
|---|---|---|
| Source changes and documentation authored | Present in working tree | P04 tracker and files listed above |
| `git diff --check` | Run as a source whitespace check only | No runtime or parser claim |
| P04 Godot suite | COULD-NOT-RUN — deferred while the shared laptop is in use | No output exists |
| P04 multi-process/fault suite | Not authored; not run | No output exists |
| Raw ENet channel semantics | Not run | Deferred experiment required |
| Rendered client walkthrough / device tests | Not run | No captures exist |
