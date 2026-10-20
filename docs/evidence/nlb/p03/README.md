# NLB-P03 partial engineering evidence — 2026-10-20

**Result: 0/3 tasks accepted. P03 is PARTIAL and its prerequisite gate remains open.** This package records implemented code and PC-only checks without claiming camera scanning, physical Android installation, a real Wi-Fi join, or completion of NLB-P02.

## Environment

- Repository: `main` at the user's current working revision; exact delivered revision is recorded in Git when it is shipped.
- Engine: Godot 4.7.2 stable, `4.7.2.stable.official.ed1daf0bf`.
- Windows export: Android SDK `%LOCALAPPDATA%\Android\Sdk`, platform 36, build-tools 36.1.0, OpenJDK Temurin 17.0.18. NDK 28.2 is installed; the Godot Gradle template specifies NDK 29.0.14206865, which is not installed. No SDK package was installed or replaced. See [`android-sdk-packages.log`](android-sdk-packages.log) and [`java-toolchain.log`](java-toolchain.log).
- `adb devices -l`: no connected physical device. An emulator image is installed but was not used as physical acceptance evidence. No physical Android model, Android version, ABI, screen, renderer, installation, or phone capture is claimed. See [`adb-device-check.log`](adb-device-check.log).
- Available host address for local multiprocess tests was WSL virtual IPv4 `172.28.192.1`, not a phone-reachable Wi-Fi LAN.

## Candidate Android export (not P03-T01 acceptance)

Reproducible command from the repository root:

```powershell
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --export-debug 'Android LAN Client (Debug)' '../build/tilaok-android-debug.apk'
```

Export completed successfully with Godot's prebuilt Android template. The ignored, self-contained APK is `build/tilaok-android-debug.apk` (63,976,988 bytes; SHA-256 `E7A7D73E81DAAA1DB2D34471CABE0140BC71E11CEE64B5911D98AF822348D838`). `apkanalyzer` reports application ID `org.hoplyxd.tilaok.debug`, version code 1, version `0.3.0-debug`, min SDK 24, target SDK 36, landscape (`screenOrientation=0`), and manifest permissions `android.permission.INTERNET` and `android.permission.CAMERA`. `apksigner verify` passes; it is signed using Godot's machine-local debug key (no signing key or password is in the repository). Packaged engine ABIs are `arm64-v8a` and `armeabi-v7a`; `assets.sparsepck` is inside the APK. Full export output and manifest/signature inspection are in [`android-export.log`](android-export.log) and [`apk-inspection.txt`](apk-inspection.txt).

This candidate does **not** package a camera/decoder plugin. The camera permission is present in the manifest but there is no runtime scanner permission flow or scanner singleton in the APK. The UI explicitly falls back to Lobby ID/manual entry when `TilaokQrScanner` is unavailable. Therefore it is not the completed Android client requested by T01/T02 and has not been installed on a phone.

## Implemented and verified locally

- Android launch selects `CLIENT_PRESENTATION`, skips local game/harness setup and routes to a client-only lobby. Session teardown restores that client role and does not create an offline local seat.
- The phone layout removes the desktop 900-pixel minimum and hides host controls. It includes QR scanner integration hooks, bounded Lobby ID lookup with validation/no-result timeout, manual address/port plus a separate credential, connection status, host-provided identity/readiness, leave and retry.
- `InvitationUri` accepts only the bounded `tilaok://join` schema and validates unique fields, Lobby ID, IPv4, port, wire version, digest, credential and session epoch. QR content only supplies a candidate endpoint and proof credential; host compatibility, proof, approval and assignment remain in the existing raw ENet manager.
- The manager synchronizes validated client seat/readiness state, checks the invitation's host session epoch, times out unreachable connections, and cleans up abusive-peer bookkeeping after a malformed-frame flood.

Checks:

| Check | Result | Evidence |
|---|---|---|
| Godot import/script parse | PASSED | [`import-parse.log`](import-parse.log) |
| Invitation, client authority, and host/join UI checks | PASSED — 35 checks | [`p03-focused-tests.log`](p03-focused-tests.log) |
| Existing P02 raw ENet/admission tests, including owned 120-frame malformed flood | PASSED — 69 checks | [`p02-focused-tests.log`](p02-focused-tests.log) |
| P02 separate-process leave/rehost regression | PASSED — 10 cycles; zero seats, peers, candidate cache | [`p02-multi-process-regression.log`](p02-multi-process-regression.log) |
| P01 authority/input regression | PASSED | [`p01-focused-regression.log`](p01-focused-regression.log) |
| P05 offline live-build regression | PASSED — 49 checks | [`windows-offline-route-regression.log`](windows-offline-route-regression.log) |
| Existing Windows controls regression | PASSED — 13 checks | [`windows-controls-regression.log`](windows-controls-regression.log) |
| Default Windows route launch smoke | PASSED — opens Title, route `lifecycle` | [`windows-default-launch-smoke.log`](windows-default-launch-smoke.log) |
| gdlint and gdformat check | PASSED | [`gdlint.log`](gdlint.log), [`gdformat.log`](gdformat.log) |
| `git diff --check` | PASSED | [`git-diff-check.log`](git-diff-check.log) |
| APK export, signature and manifest | PASSED as a candidate export | [`android-export.log`](android-export.log), [`apk-inspection.txt`](apk-inspection.txt); missing scanner integration prevents T01 acceptance. |
| Physical install, permission behavior, same-Wi-Fi join, QR/Lobby ID/manual phone flows | COULD-NOT-RUN | No physical Android device is available; no synthetic/emulator evidence substitutes for this gate. |
| Real Wi-Fi/no-internet P02 prerequisite | COULD-NOT-RUN | Only WSL virtual IPv4 was available; P02-T03 remains unchecked. |

Known invalid resource UID warnings in the P02 test logs are due to the pre-existing unrelated deleted `tilaok!/tests/run_ledge_climb_tests.gd.uid`; the working-tree deletion is preserved.

## Remaining gates

1. The stage-A prerequisite check cannot close P02-T03 without a real reachable Wi-Fi/no-internet LAN run. P02 remains 2/3 and P03's phase entry gate remains unsatisfied.
2. The required camera scanner is not packaged. A Godot v2 Android plugin requires a Gradle export and needs dependency/source/license/ABI/offline provenance. The installed SDK lacks NDK 29.0.14206865 specified by the Godot template; that package was not installed pending the user's explicit approval.
3. No authorized physical Android phone is connected. T03 cannot be completed without installing the final exact APK and performing the same-Wi-Fi join/leave/rejoin and fallback/error cases on that phone.

Android 17 / API 37 requires `ACCESS_LOCAL_NETWORK` at runtime for apps targeting API 37+. This candidate targets API 36, for which Android documentation says `INTERNET` retains implicit LAN access. Revisit the permission before raising target SDK; do not add/request it prematurely.

## Sources

- [Godot 4.7 Android plugin guide](https://docs.godotengine.org/en/4.7/tutorials/platform/android/android_plugin.html) — v2 plugin packaging uses the Gradle build.
- [Godot 4.7 Gradle build guide](https://docs.godotengine.org/en/4.7/tutorials/export/android_gradle_build.html) — template/plugin integration workflow.
- [Android local network permission](https://developer.android.com/privacy-and-security/local-network-permission) — API 37 target requirement and API 36 behavior.
