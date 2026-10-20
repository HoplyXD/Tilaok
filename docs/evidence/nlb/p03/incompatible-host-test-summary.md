# P03 deliberate compatibility mismatch host — 2026-10-20

- Purpose: test that the installed Android client rejects a Windows host built with different gameplay content.
- Baseline host digest: `876982d7f38bc5b5ed80749e643f68dbeb28d231bae64ab0b2530fe301937ba6`.
- Test host digest, read back from the exported Windows PCK with Godot 4.7.2: `efa11e4de05cd5f3a9aa0ea4006537296691aa399dd829fa5c681b44eace8d75`.
- Difference: a temporary extra map scene was included only while exporting this test host. It has since been removed from the project; the source project digest returned to the baseline value.
- Export command: `D:\Downloads\Godot_v4.7.2-stable_win64_console.exe --headless --path 'tilaok!' --export-debug 'Windows Desktop' '../build/tilaok-p03-mismatch-host.exe'`.
- Test host executable: `build/tilaok-p03-mismatch-host.exe` (SHA-256 `E07745E6DB1D5D104E039F6BF27A96806761861377D201B4DFAF737A90579E9B`). Its companion PCK is `build/tilaok-p03-mismatch-host.pck` (SHA-256 `1D91A1BCD0D6F7338F09A5F61CD5C224393BB09933545E6EF47CC132BA709895`). These ignored build files are a temporary diagnostic and are not part of the normal Windows build.
- Export and packaged-digest logs: [incompatible-host-export.log](incompatible-host-export.log).
- Physical test result (2026-10-20): USER-REPORTED PASS for the phone's rejection display. The user launched this test host, scanned its fresh QR with the installed phone app, and reported that the phone displayed a mismatch message. The user has not yet reported whether the host showed no seat assignment, so that part of the acceptance remains unconfirmed. No ADB device was connected here; no screenshot or host log was retained. The normal host and Android APK remain unchanged.
