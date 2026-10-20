# NLB-P03 Android client — engineering evidence, 2026-10-20

**Acceptance: 1/3 tasks formally evidenced. Phase: PARTIAL; P02 entry gate passes.** Follow-ups corrected the 13-character Lobby ID high-digit range (`A`–`H`) and changed the room QR/access code to one reusable credential for the active room lifetime. On 2026-10-20, the user reported completing a physical-phone join test and confirmed that ready/unready toggles were visible in the host view. They identified the phone as a Tecno Spark 20 Pro running Android 14, then confirmed the PC host connected to the phone's hotspot with mobile data off and the same phone joined that host. This user report closes the P02 no-internet entry gate. No post-fix screenshots, sanitized device/host logs, exact hardware variant, ABI, renderer, screen details, or full T02/T03 test-case record were supplied, so P03 formal task acceptance remains incomplete. Nothing here claims networked gameplay.

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
| Follow-up Android decoder unit test | PASSED | [`scanner-unit-followup.log`](scanner-unit-followup.log); Gradle `:plugin:testDebugUnitTest` build succeeded on revision `c4640a4`. |
| Godot P03 focused parser/client/UI/package source checks | PASSED — 61 assertions | [Lobby ID range follow-up](lobby-id-range-followup-p03-tests.log); tests the reported E-prefixed ID and A/H/I/7 boundary, but these are source/desktop checks, not Android runtime proof. |
| Follow-up P03 focused parser/client/UI/package checks | PASSED — 61 assertions | [`p03-verification-followup-tests.log`](p03-verification-followup-tests.log), Godot 4.7.2 on revision `c4640a4`. |
| P01 focused regression | PASSED | [P01 regression](p01-focused-regression-final.log). |
| P02 focused suite | PASSED — 74 checks | [Reusable invitation follow-up](reusable-invitation-p02-tests.log), including two approved joins using one code, leave/rejoin, malformed-frame cleanup and capacity; synthetic/local processes only. |
| Follow-up P02 admission suite | PASSED — 74 checks | [`p02-verification-followup-tests.log`](p02-verification-followup-tests.log); includes synthetic wrong-digest rejection. |
| P02 ten-process lifecycle regression | PASSED — 10 cycles | [Reusable invitation follow-up](reusable-invitation-p02-multiprocess.log); combined with the user's physical hotspot report, P02's exit gate passes. |
| P05 offline route regression | PASSED — 49 checks | [P05 regression](p05-offline-regression-final.log). |
| Windows host export/startup and digest | PASSED as a Windows artifact | [host export](windows-host-export-final.log), [host startup](windows-host-startup-final.log), [exported digest](windows-exported-compatibility-final.log); the Android resource digest comparison is not passed. |
| Exact Android APK package/signature check | PASSED as a package artifact | [`apk-integrity-followup.log`](apk-integrity-followup.log): `0.3.2-debug`, package ID, CAMERA/INTERNET permissions, APK Signature Scheme v2 and package size/hash. This does not verify runtime behavior. |
| Android manifest digest comparison | COULD-NOT-RUN | [`android-packed-compatibility.log`](android-packed-compatibility.log) records a failed attempt to run the project digest script against Godot's sparse Android resource pack; that pack cannot be loaded as a standalone project. It is not a digest result. The user's successful compatible join is reported separately, while the physical mismatch-build rejection remains unverified. |
| Camera permission UI, actual camera scan, all three joins and Android error/retry states | USER-REPORTED PASS; evidence incomplete | User reports successful physical-phone testing after the Lobby ID correction and confirms host-visible ready/unready. No post-fix capture/log or per-case matrix was supplied; permission-denial and failure cases remain unsubstantiated in retained evidence. |
| Exact APK install and physical same-Wi-Fi lobby join/leave/fresh-invite rejoin | USER-REPORTED PASS; evidence incomplete | User reports all tested flows working on a Tecno Spark 20 Pro running Android 14, including a PC host on that phone's hotspot and the same phone joining as client. Mobile-data state, exact device variant, ABI, APK/build identity, Android API, renderer, screen configuration, install output and sanitized captures/logs are not retained. `adb devices -l` was empty on the development PC, so this was not independently captured locally. |
| P02 real Wi-Fi/no-internet prerequisite | USER-REPORTED PASS | User confirms the same Tecno phone provided the hotspot and joined the Windows host while mobile data was off. |
| Local ADB phone inspection | COULD-NOT-RUN | [`physical-device-followup-check.log`](physical-device-followup-check.log) shows `adb devices -l` returned no connected devices; the physical join report came from the user. |

Physical details currently reported by the user: Tecno Spark 20 Pro; Android 14 (API 34); phone hotspot with mobile data off, Windows host as a hotspot client, and the phone app joining that host. Code/package details are Godot 4.7.2, GL Compatibility renderer, landscape, app version `0.3.2-debug` (version code 3), and code revision `82de6d6` (APK SHA-256 `228DCDF3EDB92F0C7798C422FA668D53859B1AC7C25D324683BD5CBBE03483A5`). Exact device variant (the user's message included the ambiguous suffix “56”), installed ABI, exact screen mode/dimensions, and post-fix captures/sanitized host/device logs remain unknown. The user reports that all tested flows work, including readiness reflected on the host, but the full per-case physical matrix is not itemized in retained evidence. The proposed phone memory/FPS/touch targets are not measured by this lobby package. API 36 target retains LAN access through INTERNET; re-evaluate Android's local-network runtime permission before moving to target API 37 or later.

## Remaining gates

1. On the physical phone, itemize which invitation paths and permission/error/lifecycle cases were exercised; record device ABI, screen configuration and exact APK installed; retain sanitized phone/host captures/logs if available.
2. Verify the Android packaged digest against the Windows host and test rejection of a deliberately incompatible content build; the current Android sparse-pack diagnostic failed and the synthetic wrong-digest test does not replace this check.
3. Check P03-T02/T03 only after their remaining acceptance evidence is captured and reviewed.

## Official references

- [Godot 4.7 Android plugin guide](https://docs.godotengine.org/en/4.7/tutorials/platform/android/android_plugin.html)
- [Godot 4.7 Gradle export guide](https://docs.godotengine.org/en/4.7/tutorials/export/android_gradle_build.html)
- [AndroidX CameraX releases](https://developer.android.com/jetpack/androidx/releases/camera)
- [ZXing source and Apache-2.0 license](https://github.com/zxing/zxing)
- [Android local network permission](https://developer.android.com/privacy-and-security/local-network-permission)
