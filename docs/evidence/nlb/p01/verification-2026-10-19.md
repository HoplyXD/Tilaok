# NLB-P01 — Seat actions and simulation authority

**Result:** PASSED for the scoped offline/host action and authority foundation. **Run date:** 2026-10-19 (Asia/Manila). **Checkout:** `main`, implementation based on `29b017a683307dd1b3ebb7a9df0215f300ecd292`; the changes were uncommitted during verification. **Engine:** Godot `4.7.2.stable.official.ed1daf0bf`. **Reviewer:** Codex, implementation author; no independent human review is recorded. **Input:** synthetic logical events and synthetic keyboard seats; no physical keyboard/gamepad or Android evidence. **Transport:** none. **Current game route remains offline.**

## Scope delivered

- One shared per-seat logical action path supports the existing keyboard and gamepad aliases and host-injected remote actions/axes. Remote sources are host-bound to one of four seats; source identifiers are bounded and cannot nominate a seat. Host spectating uses no seat.
- Phase changes clear fresh edges and repeat state; one-shot held actions remain blocked until release. Revocation clears the mapped source's held, pressed, and axis state.
- `SimulationAuthority` defines offline authority, host authority, and client presentation. Invalid explicit role configuration fails closed. The offline flow defaults to offline authority.
- Actor physics/lifecycle, item and transient state, stage/support registries, phase/lifecycle, event/RNG, race outcomes, and score/Barya commit paths are gated. Client presentation receives detached values and cannot use the tested production write APIs to commit state. Client pause remains a presentation request; offline and trusted host-local pause retain the existing behavior.
- No RPC, transport, Android client, live placement, new default route, game rule, or score value was added.

## Action mapping and ownership matrix

| Source | Movement | Jump / sneak | Context and menus | Ownership |
|---|---|---|---|---|
| K1 | A / D; W is phase-dependent up/jump | Space or W holds jump/glide; S sneaks | E/F ready or confirm; R aliases Help in Lobby and Cheer in Play; G backs out | Local keyboard layout is assigned one seat in join order |
| K2 | Left / Right; Up is phase-dependent up/jump | Right Ctrl or Up holds jump/glide; Down sneaks | Enter ready/confirm; Right Shift aliases Help/Cheer; Backspace backs out | Local keyboard layout is assigned one seat in join order |
| K3 | J / L; I is phase-dependent up/jump | I holds jump/glide; K sneaks | O ready/confirm; P aliases Help/Cheer; U backs out | Local keyboard layout is assigned one seat in join order |
| K4 | Numpad 4 / 6; Numpad 8 is phase-dependent up/jump | Numpad 8 holds jump/glide; Numpad 2 sneaks | Numpad 0 ready/confirm; Numpad 5 aliases Help/Cheer; Numpad period backs out | Local keyboard layout is assigned one seat in join order |
| Gamepad | D-pad and left stick, retaining existing thresholds/repeats | A maps to jump in Play; the existing directional down input sneaks | A confirms/claims by phase; B backs out; X aliases rotate/help/cheer; Start requests pause | Connected gamepad ID maps to one seat; host spectator is independent |
| Injected remote source | Shared left/right action or finite horizontal axis in [-1, 1] | `jump` held edge; `down` is sneak; held jump preserves glide | Allowlisted `confirm`, `back`, `rotate`, `pause`, `ready`, `claim`, `cheer`, `help` | Host-side registry binds opaque bounded source ID to a seat; source payload has no seat field |

Focused mapping evidence covers K1–K4 left/right/sneak/jump, opposing-direction intent, exactly-once jump edge consumption, gamepad d-pad/jump/contextual alias/Start pause, and host spectator seat occupancy. Existing controls and match-UI regressions cover readiness, navigation, menus and route integration. Synthetic gamepad input is not physical-device evidence.

## Authority boundary matrix

| State owner | Offline / host | Client presentation |
|---|---|---|
| Seat registry | Local join, ready, disconnect/reclaim, clear; host additionally assigns/revokes remote sources | Seat join, ready, clear, remote ownership denied |
| Actors and physics | Tick and lifecycle writes allowed | Tick skipped; tested velocity, transform, elimination and reset calls denied |
| Items, hazards, transient budget | Place, activate, remove, reset, timers, allocation and cleanup allowed | Tested item lifecycle and transient allocation/advance/release/clear denied |
| Arena/support | Construction ownership and physics support writes allowed | Tested arena registration and support finalization/clear denied |
| Match phases/events | Phase timers, schedule, event draw/advance and lifecycle allowed | Tested phase/lifecycle/event start denied; RNG state unchanged on refused schedule |
| Race, score and Barya | Resolve terminal outcomes and commit once allowed | Tested race begin, Barya state/receipt and event score paths denied |
| Presentation/pause | Detached snapshot read; global pause allowed for offline/trusted local host | Detached nested snapshots; no authoritative simulation tick or global pause write |

The authority API is an in-process boundary for future integration, not a security boundary against arbitrary code running in the same process. No remote protocol or client runtime is claimed.

## Verification commands and results

| Check | Result | Evidence |
|---|---|---|
| Godot editor import/script parse | PASSED | [tool checks](tool-checks-2026-10-19.log) |
| Focused P01 suite | PASSED — final rerun 65 checks, 0 failures | [raw selected regression output](regression-output-2026-10-19.log) |
| Offline controls, P05/P06/P08/P09, P12/P12 pairs/stack, Barya, Match UI/bindings/modes | PASSED — 1,380 distinct checks, 0 failures | [raw selected regression output](regression-output-2026-10-19.log) |
| Rendered offline route | PASSED — Lobby → Pugad → Place → Play → results → next-round Pugad; 6 PNGs saved | [capture console log](rendered-route-2026-10-19.log); captures under [`captures/`](captures/) |
| `gdformat --check` on changed GDScript | PASSED — all 32 changed/new scripts already formatted | [tool checks](tool-checks-2026-10-19.log) |
| `gdlint` on changed GDScript | PASSED — no problems found | [tool checks](tool-checks-2026-10-19.log) |
| `git diff --check` | PASSED | [tool checks](tool-checks-2026-10-19.log) |
| Full tutorial gate search | COULD-NOT-RUN — base route passed, but its later search remained CPU-active for several minutes; stopped to avoid an unbounded wait | `run_tutorial_gate_tests.gd` was attempted with its documented `--quick` option; quick mode skips only the no-build search and still enters the long placement solution search |
| `run_ui_tests.gd` supplemental screen-contract runner | FAILED — 2/501 checks: `%Outcome1` and `%Final1` expected as `UiScoreRow`; those scene checks are outside P01 and those scene files were not changed | [raw output](run-ui-tests-2026-10-19.log). This was not rerun against a pristine checkout, so baseline status is not asserted |
| Physical keyboard rollover/gamepad reconnect, Android device, performance/load budget | COULD-NOT-RUN — no physical input/device session or P01 load benchmark was performed | Synthetic test evidence is labeled above; this record does not claim hardware or performance acceptance |

The rendered route was windowed using Godot's Compatibility renderer on an NVIDIA GeForce RTX 4050 Laptop GPU (OpenGL 3.3). The capture runner used two synthetic local keyboard seats and a deterministic seed `12345`; it forced the race hard-cap transition to results and started the next round. This is route/render evidence, not a human playtest or performance benchmark.

## Reset/teardown observations

The focused runner performs ten source assignment/revoke and lobby-reset cycles and passes checks for cleared source ownership and held movement. Existing P12 pair regressions perform ten full-match restarts and passed; the runner reported stable node count (2,178 → 2,178) and engine object count 6,177 → 6,186. That small object-count delta was not investigated as part of P01, so no claim of zero object growth is made.

## Source and disclosure

Implementation and evidence tooling were authored by OpenAI Codex under the standing AI-assisted programming workflow and the user's explicit NLB-P01 implementation request. No production art/audio was generated. No human review or Form 03 selection is claimed. See [AI_USAGE.md](../../../AI_USAGE.md) and the [P01 tracker](../../../PHASETASK_NETWORKED_LIVE_BUILD.md#nlb-p01--local-actionseat-abstraction-and-authority-boundary).
