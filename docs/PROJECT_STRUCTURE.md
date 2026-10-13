# Project structure and responsibility map

P01 foundation layout for the Godot 4.7 project. The current harness is a local development entry point; it does not implement player controls, items, scoring, phases, or events.

| Area | P01 path | Responsibility and current state |
|---|---|---|
| Project entry | `tilaok!/project.godot`, `tilaok!/scenes/harness/` | Starts the foundation diagnostic harness. |
| Configuration | `tilaok!/scripts/config/` | Typed provisional tuning, presentation settings, immutable-at-run-start snapshots, and seven labeled profiles. |
| Content diagnostics | `tilaok!/scripts/diagnostics/` | Catalog validation, verified-content eligibility, normalized weights, and independent seeded diagnostic RNG streams. No gameplay content is enabled. |
| Harness | `tilaok!/scripts/harness/`, `tilaok!/scenes/harness/` | Local profile/seed identity, validation, fixture open/close, scenario reset, full harness reload, exit, and paused presentation configuration. Diagnostics do not enter a player HUD. |
| Fixture rooms | `tilaok!/scenes/fixtures/` | Movement, item, and event placeholders test room load/unload and display explicit notices. They contain no P02+ mechanics. |
| Foundation checks | `tilaok!/tests/` | Headless configuration, eligibility, deterministic stream, and fixture cleanup checks. |
| Future responsibilities | `scripts/input`, `movement`, `match`, `stage`, `items`, `events`, `scoring`, `presentation` | Proposed ownership boundaries only; no implementation is claimed in P01. |

## Authorship and review

At the user's explicit direction for P01, OpenAI Codex authored the foundation scripts, scenes, and focused checks. This is an exception to the repository's team-authored-code acceptance wording. Codex-authored work is not labeled team-authored, and this exception does not establish that AI-authored code satisfies the competition's team-code originality rule. A registered team member must review and understand the work before it is represented as accepted project code. The team must disclose this assistance on DOST Form 03.

## Running the foundation

From the repository root, use the explicit Godot 4.7.2 executable recorded in `docs/PRODUCTION.md`:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!' --editor
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --script 'res://tests/run_foundation_tests.gd'
```

Windows export preset output is `build/tilaok-p01.exe`; generated build output is ignored by Git.
