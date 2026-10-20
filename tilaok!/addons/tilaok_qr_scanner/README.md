# Tilaok QR Scanner — Android plugin

Project-authored Godot Android v2 plugin for scanning LAN lobby invitations. It opens a CameraX preview only after the player requests **Scan QR**. Camera frames are copied as Y-luma data and decoded on-device with ZXing core. The plugin emits one decoded value per active scan; success, cancel, permission denial, permanent denial, unavailable camera, pause and teardown release the analyzer/camera. It has no native library, cloud decoder, model download, telemetry or runtime network dependency. It never stores camera frames or invitation/session credentials.

## Build and test

Requires Godot 4.7.2 Android export templates, Java 17, Android platform 36, Build Tools 36.1.0 and NDK 29.0.14206865. From the repository root, first build the local debug/release AAR consumed by the Godot export plugin, then export the APK using the `Android LAN Client (Debug)` preset:

```powershell
$env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
Push-Location 'tilaok!\addons\tilaok_qr_scanner\android'
try { .\gradlew.bat :plugin:testDebugUnitTest :plugin:assemble --console=plain } finally { Pop-Location }
& 'D:\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'tilaok!' --export-debug 'Android LAN Client (Debug)' '../build/tilaok-android-debug.apk'
```

The generated AARs under `bin/`, Gradle caches/build directories, APK and other package outputs are ignored and are not source. `gradlew` and its wrapper JAR are retained for reproducible builds; dependency versions are pinned in Gradle files. Godot then resolves the runtime artifacts from Google Maven and Maven Central. The APK currently targets API 36 and includes `arm64-v8a` and `armeabi-v7a` Godot engine libraries; the plugin itself is Kotlin/Java and has no ABI-specific native code.

## Provenance and licenses

- Plugin Kotlin, Godot bridge, scanner overlay, lifecycle and luma-frame adapter are authored for this project.
- Build structure follows `m4gr3d/Godot-Android-Plugin-Template` commit `089491f255d37d3d0d06bcaea588c4f980ea8327`; its retained MIT notice is `android/LICENSE-GODOT-PLUGIN-TEMPLATE`. The template's wrapper structure is adapted; no template game/plugin feature code is included.
- CameraX 1.5.1 (`camera-camera2`, `camera-lifecycle`, `camera-view`), AndroidX Activity 1.10.1, and AndroidX Fragment 1.8.6 are Apache-2.0, from Google Maven.
- ZXing core 3.5.3 is Apache-2.0, from Maven Central.
- Godot Android compile API 4.7.2 stable is compile-only and comes from Godot's Maven repository.

All Android camera/QR processing occurs locally. Camera permission is requested at scan start, not startup. If denied, cancelled or unavailable, the client can continue with Lobby ID or manual IP:port. A user-selected candidate is still subject to ENet compatibility, invitation proof and host approval. Physical-device permission/camera verification is tracked in NLB-P03 and is not claimed by desktop decoder tests.
