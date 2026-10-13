# Future Lagsanay / event-stack wall-movement escape and stalling procedure (P02-T21)

**Status:** WRITTEN, NOT EXECUTED. Lagsanay, Kangaroo and the event stacks are unimplemented, so nothing here depends on them and nothing here is a result. Run this at each event's own gate, only if the wall feature is kept at the October 21 freeze. The controller never depends on event code.

## Preconditions

- Event implemented and individually verified; wall feature enabled (`wall_movement_enabled = true`) in a named test profile; seed and build recorded; 2, 3 and 4 players in separate runs.
- Use the P03 graybox with at least one built tall wall and one built shaft (width 64 wu) and a built wall-only pocket.

## Lagsanay (bomb-taya tag)

| Case | Procedure | Fail condition |
|---|---|---|
| Escape | Taya chases a runner who alternates kicks in a shaft for the full timer | Runner is unreachable for longer than one full timer cycle with no counterplay |
| Pass-back | Overlap near a wall at pass time; check pass-back immunity vs. kicks | Wall kick creates a repeated pass or double pass in one step |
| Stall | Hold slide on a wall for the whole timer | Timer expiry cannot occur, or a taya cannot ever reach a sliding chicken |
| Containment | Max kick + max launch (480/900) | Leaves visible bounds; fall elimination is created |
| Opening freeze | Press jump beside a wall during the opening freeze | Any motion before the freeze ends |

## Karera + Lagsanay / Karera + Kangaroo / Kangaroo + Lagsanay

| Case | Procedure | Fail condition |
|---|---|---|
| Shortcut | Repeatedly attempt to reach the flag via walls skipping the intended route | Immutable protection or protected goal clearance bypassed |
| Freeze | Press jump for a wall kick during a Freeze command | Intentional-input telemetry is missing or wrong (kick must still count as intent) |
| Rising wave | Stand on a wall-slide above the line; also land on built support above it | Wall contact qualifies as support or provenance |
| Hug | Slide near a partner during Hug evaluation | Wall movement moves players into or out of contact outside input rules |
| Capture/bubble | Kick while captured or just released | Kick during capture, or overwrite of the release motion |

## Recording

Record build/revision, engine, date, profile/seed, player count, devices (synthetic vs physical), procedure, expected/actual, outcome (PASSED/FAILED/COULD-NOT-RUN) and reviewer. Intended shortcuts go to the balance review; bounds escapes, immutable-protection bypasses and event-contract violations are defects.
