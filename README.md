# Tilaok!

**Current build:** local/offline 2–4 player play. Normal Play follows **Lobby → Pugad → shared 3-second GO → active race/event with movement and construction → results → next round**. Construction remains a visible, non-gameplay job for 2.0 seconds, freezes while paused, reserves its fixed footprint, then commits only after a fixed-step safety check. The P12 scheduled Place route remains a developer fallback. Phone/LAN, Android and QR features are retired; NLB specs and evidence are preserved as retired history in `docs/archive/retired-networked-live-build/`.

> A Filipino party platformer where chickens build the level, then try to survive it.

**Tilaok!** is a local multiplayer platformer for the DOST Level Up 3.0 Esports Game Dev Challenge. Philippine games and sports shape the events; all characters are chickens in a wholesome, skill-based reimagining of sabong.

## Run locally

From the repository root, launch with Godot 4.7.2:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --path 'tilaok!'
```

Join with a local keyboard or gamepad, ready up in the Lobby, pick an egg in Pugad, then move and build after GO. The in-game tutorial and Controls screen describe each seat's bindings. Developer-only alternatives: `-- --match-route=lifecycle` opens the scheduled Place flow; `-- --match-route=first_playable` opens the first-playable slice.

## Project documents

- [Game Design](docs/GDD.md) and [Product Requirements](docs/PRD.md)
- [Active Phase Tracker](docs/PHASETASK.md) and [Roadmap](docs/ROADMAP.md)
- [Playtest and Verification](docs/PLAYTEST.md)
- [Project Structure and Run Instructions](docs/PROJECT_STRUCTURE.md)
- [Tutorial and Controls](docs/UI_TUTORIAL.md)
- [AI Assistance Disclosure](docs/AI_USAGE.md)
- [Documentation Index](docs/INDEX.md)

## Platform

Godot 4.7.2; Windows PC; 2–4 local players using keyboard/gamepad. Gameplay traffic is architecturally absent. See the active verification record for measured results and remaining human/device review.
