<#
NLB-P11-T01 battery / thermal / memory sampler (authored, NEVER RUN while the laptop is shared).

Godot has no battery or thermal API, so this PC-side script polls an attached, user-authorised
Android phone over adb once a minute during an approved test window. It does not install anything,
does not start the adb server on its own initiative (run it only inside the approved window), and
never writes the device serial or any network address: only the label you pass in.

Usage (deferred; start only after the user says testing is safe and the phone is in the session):
  powershell -ExecutionPolicy Bypass -File tests/tools/nlb_p11_thermal_sampler.ps1 `
    -DeviceLabel "phone-A" -Serial "<adb serial>" -Minutes 30 `
    -OutFile ..\build\nlb_p11\phone-A-thermal.csv -Package org.hoplyxd.tilaok

Output CSV columns:
  utc,minute,battery_level_pct,battery_temp_tenths_c,battery_status,plugged,thermal_status,rss_kb_or_pss_kb,memory_kind
Record ambient temperature, brightness, radio state and screen-on state by hand in the hardware
record; adb cannot know them. battery/thermal has NO pass threshold: this is evidence collection.
#>
param(
    [Parameter(Mandatory = $true)][string]$DeviceLabel,
    [Parameter(Mandatory = $true)][string]$Serial,
    [int]$Minutes = 30,
    [Parameter(Mandatory = $true)][string]$OutFile,
    [string]$Package = "org.hoplyxd.tilaok"
)

$ErrorActionPreference = "Stop"
$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) { throw "adb not found at $adb" }
if ($Minutes -lt 1 -or $Minutes -gt 120) { throw "Minutes must be 1..120" }

$outDir = Split-Path -Parent $OutFile
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force $outDir | Out-Null }
"utc,minute,battery_level_pct,battery_temp_tenths_c,battery_status,plugged,thermal_status,memory_kb,memory_kind" |
    Set-Content -Path $OutFile -Encoding utf8
Write-Host "NLB_P11_THERMAL start label=$DeviceLabel minutes=$Minutes (serial not recorded)"

function Get-Field([string[]]$lines, [string]$key) {
    $hit = $lines | Where-Object { $_ -match "^\s*$key\s*:" } | Select-Object -First 1
    if ($null -eq $hit) { return "" }
    return ($hit -split ":", 2)[1].Trim()
}

for ($minute = 0; $minute -le $Minutes; $minute++) {
    $battery = & $adb -s $Serial shell dumpsys battery
    $thermal = & $adb -s $Serial shell dumpsys thermalservice
    $meminfo = & $adb -s $Serial shell dumpsys meminfo $Package
    $thermalStatus = ($thermal | Where-Object { $_ -match "Thermal Status" } | Select-Object -First 1)
    if ($null -eq $thermalStatus) { $thermalStatus = "unavailable" } else { $thermalStatus = $thermalStatus.Trim() -replace ",", ";" }
    $memoryKb = ""
    $memoryKind = "unavailable"
    $rssLine = $meminfo | Where-Object { $_ -match "TOTAL RSS" } | Select-Object -First 1
    $pssLine = $meminfo | Where-Object { $_ -match "^\s*TOTAL\s+\d" } | Select-Object -First 1
    if ($rssLine -match "TOTAL RSS:\s*(\d+)") { $memoryKb = $Matches[1]; $memoryKind = "rss" }
    elseif ($pssLine -match "TOTAL\s+(\d+)") { $memoryKb = $Matches[1]; $memoryKind = "pss" }
    $row = @(
        (Get-Date).ToUniversalTime().ToString("o"), $minute,
        (Get-Field $battery "level"), (Get-Field $battery "temperature"),
        (Get-Field $battery "status"), ((Get-Field $battery "AC powered") + "/" + (Get-Field $battery "USB powered")),
        $thermalStatus, $memoryKb, $memoryKind
    ) -join ","
    Add-Content -Path $OutFile -Value $row -Encoding utf8
    if ($minute -lt $Minutes) { Start-Sleep -Seconds 60 }
}
Write-Host "NLB_P11_THERMAL done rows=$($Minutes + 1) out=$OutFile"
