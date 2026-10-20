# NLB-P03 Android client — engineering evidence, 2026-10-20

**Acceptance: 1/3 tasks. Phase: PARTIAL and held at the P02 exit gate.** Follow-ups corrected the 13-character Lobby ID high-digit range (`A`–`H`) and changed the room QR/access code to one reusable credential for the active room lifetime. Desktop/session tests cover the screenshot's E-prefixed ID, boundary values and repeated joins with one code, but actual Windows-host/Android compatibility, permission UX, invitation paths and failure-state acceptance remain unverified on Android. T03 is not run: no physical phone is connected. P02-T03 is not complete because real Wi-Fi/no-internet LAN evidence is missing. Nothing here claims networked gameplay.

## Build and package

- Revision under test: `34a5012` plus the current Lobby ID range correction.
- Engine: Godot 4.7.2 `4.7.2.stable.official.ed1daf0bf`.
- Java: Temurin OpenJDK 17.0.18. Android SDK platform 36, build-tools 36.1.0, NDK 29.0.14206865. The exact NDK package was installed after explicit user approval. The initial Gradle resolution temporarily selected Build Tools 34; that package was removed and the final preset pins 36.1.0.
- APK: `build/tilaok-android-debug.apk`, see [latest Lobby ID range export record](lobby-id-range-followup-apk.log) for byte size and SHA-256.
- Identity: `org.hoplyxd.tilaok.debug`, `Tilaok! LAN Client`, version code 3 / `0.3.2-debug`; min API 24, target/compile API 36, landscape; `arm64-v8a` and `armeabi-v7a`.
- Signing: Godot debug signing; no keystore or password is in source control. The APK contains the Godot asset pack and scanner plugin and does not require editor streaming. Build artifacts are ignored.
- Reproducible build from repo root (first creates ignored scanner AARs, then exports):

```powershell
$env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
Push-Location 'tilaok!\addons\tilaok_qr_scanner\android'
try { .\gradlew.bat :plugin:testDebugUnitTest :plugin:assemble --console=plain } finally { Pop-Location }
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --export-debug 'Android LAN Client (Debug)' '../build/tilaok-android-debug.apk'
```

The initial export exited successfully. `apksigner verify` reports v2 signature valid; `aapt` reports CAMERA and INTERNET; the merged APK manifest registers the Godot v2 scanner plugin; APK contents include plugin/decoder classes and Godot arm64/armv7 libraries. Full initial logs: [export](android-export-final.log), [merged manifest](apk-manifest-final.txt), [package inspection](apk-inspection-final.txt), [SDK packages](android-sdk-packages-final.log), [Java](java-toolchain-final.log), [Gradle build/unit tests](scanner-gradle-final.log), [initial hash and size](apk-hash-final.log). The `0.3.1-debug` export is recorded in [invitation follow-up APK verification](reusable-invitation-apk.log); the `0.3.2-debug` build is recorded in [Lobby ID range follow-up](lobby-id-range-followup-apk.log).

## Scanner provenance and behavior

The in-app scanner is a Godot Android v2 plugin at `tilaok!/addons/tilaok_qr_scanner/`. It uses CameraX 1.5.1 (camera, camera2, lifecycle, view) and ZXing core 3.5.3. ZXing decodes locally from copied Y-luma frames; no image, token or QR content is uploaded or persisted. Camera permission is requested only when scanning starts. The lobby probes the bridge with Godot Android's `JNISingleton.has_java_method("startScan")` API, binds scanner signals first, then starts the permission/camera flow; generic `Object.has_method()` does not detect Java plugin methods and caused the earlier immediate “QR scanner could not start” message. The overlay provides cancel/back, denial/permanent-denial/unavailable errors, lifecycle cancellation, serialized analysis and one-success-per-visible-scan guarding. The plugin has no native `.so` dependency and is not ABI-specific; the packaged Godot engine supports arm64-v8a and armeabi-v7a. See [asset provenance](../../../ASSETS.md#android-scanner-provenance--nlb-p03-2026-10-20) and the [plugin source README](../../../tilaok!/addons/tilaok_qr_scanner/README.md) for sources and licenses. Google ML Kit was deliberately not selected because its terms describe service metrics; the chosen decoder is local-only.

Godot 4.7 Android v2 plugin integration requires the Gradle export path. Runtime dependency resolution is from Maven Central and Google Maven during build; the installed APK scanner does not require network access. The plugin does not request camera permission at app launch and releases the camera analyzer on cancel, success, pause and teardown.

## Implemented but not fully accepted

- Android startup chooses explicit `CLIENT_PRESENTATION`, routes to a landscape client lobby and never creates a local chicken/offline authority.
- Entry UI supports camera QR, bounded Lobby ID lookup and manual IP:port with a separate access code. All paths use the existing raw ENet protocol 1.1 challenge/proof, compatibility check, host approval, host assignment and host-confirmed readiness. Both QR and manual lookup accept the full 13-character positive 63-bit Base32 range, with `A`–`H` as the first character.
- Invitation parsing accepts only bounded `tilaok://join` fields, including canonical expiry marker `expires=0`, and rejects duplicate/unsupported/malformed values. One 128-bit access code and QR stay active for every player until the host stops or rehosts. Each connection performs a fresh one-use HMAC challenge; the code is not consumed by joins, leave/rejoin, rejection or full capacity. Host approval, compatibility, seat capacity and server assignment remain mandatory. Manual Lobby ID lookup requires all 13 host-displayed Base32 characters; a failed length check now reports the number entered.
- Client state is stored for presentation and cleared on leave/retry. Existing host join UI and Windows offline route remain unchanged.
- The exported Windows host reports canonical digest `876982d7f38bc5b5ed80749e643f68dbeb28d231bae64ab0b2530fe301937ba6` for `karera_slice` / engine `4.7.2-stable (official)` ([log](windows-exported-compatibility-final.log)). The Android export uses a sparse resource pack that cannot be mounted as a standalone Windows PCK; Android packaged-resource digest equality and deliberate incompatibility rejection are not verified and must be tested on the installed Android client before T02 passes.

## Checks

| Check | Result | Evidence / limit |
|---|---|---|
| Android Gradle plugin build and decoder unit tests | PASSED — two tests | [`scanner-unit-test-summary.txt`](scanner-unit-test-summary.txt); generated QR frame decode and invalid luma dimensions. |
| Godot P03 focused parser/client/UI/package source checks | PASSED — 61 assertions | [Lobby ID range follow-up](lobby-id-range-followup-p03-tests.log); tests the reported E-prefixed ID and A/H/I/7 boundary, but these are source/desktop checks, not Android runtime proof. |
| P01 focused regression | PASSED | [P01 regression](p01-focused-regression-final.log). |
| P02 focused suite | PASSED — 74 checks | [Reusable invitation follow-up](reusable-invitation-p02-tests.log), including two approved joins using one code, leave/rejoin, malformed-frame cleanup and capacity; synthetic/local processes only. |
| P02 ten-process lifecycle regression | PASSED — 10 cycles | [Reusable invitation follow-up](reusable-invitation-p02-multiprocess.log); real Wi-Fi/no-internet acceptance remains open. |
| P05 offline route regression | PASSED — 49 checks | [P05 regression](p05-offline-regression-final.log). |
| Windows host export/startup and digest | PASSED as a Windows artifact | [host export](windows-host-export-final.log), [host startup](windows-host-startup-final.log), [exported digest](windows-exported-compatibility-final.log); the Android resource digest comparison is not passed. |
| Camera permission UI, actual camera scan, all three joins and Android error/retry states | COULD-NOT-RUN | No connected Android device; desktop checks do not substitute. |
| Exact APK install and physical same-Wi-Fi lobby join/leave/fresh-invite rejoin | COULD-NOT-RUN | `adb devices -l` returned no devices. No emulator or forwarding used. |
| P02 real Wi-Fi/no-internet prerequisite | COULD-NOT-RUN | Only WSL virtual networking was available for local processes; no real reachable Wi-Fi/no-internet test occurred. |

No physical model, OS/API, ABI, renderer, screen, reviewer, phone capture or successful install is recorded because none was observed. The proposed phone memory/FPS/touch targets are not measured by this lobby package. API 36 target retains LAN access through INTERNET; re-evaluate Android's local-network runtime permission before moving to target API 37 or later.

## Remaining gates

1. Close P02-T03 using its real Wi-Fi/no-internet and abuse acceptance; do not bypass the P03 phase dependency.
2. On an authorized physical phone, install APK version `0.3.2-debug`; verify permission grant/deny/permanent deny, QR scan/cancel, all three join paths, compatibility rejection, approval/decline/full/unreachable/shutdown, host-confirmed seat/readiness, and repeated leave/rejoin cleanup using the same room invitation.
3. Verify the digest produced from actual packaged Android resources matches the exported Windows host for identical content, and rejects a deliberately incompatible build.
4. Preserve P03-T02 and T03 checkboxes as open until their complete acceptance evidence exists.

## Official references

- [Godot 4.7 Android plugin guide](https://docs.godotengine.org/en/4.7/tutorials/platform/android/android_plugin.html)
- [Godot 4.7 Gradle export guide](https://docs.godotengine.org/en/4.7/tutorials/export/android_gradle_build.html)
- [AndroidX CameraX releases](https://developer.android.com/jetpack/androidx/releases/camera)
- [ZXing source and Apache-2.0 license](https://github.com/zxing/zxing)
- [Android local network permission](https://developer.android.com/privacy-and-security/local-network-permission)
