# Migrates a map scene's "Blocks" TileMapLayer from assets/tiles/blocks_tileset.tres (the debug
# placeholder sprite sheet, 64 px) to assets/tiles/map_tiles_tileset.tres (Map Tiles.png, 256 px).
#
# What it changes, per scene:
#   * the Blocks layer's TileSet ext_resource,
#   * every painted cell's source id and atlas coordinates (tile_map_data is a base64
#     PackedByteArray of 12-byte records: int16 x, y, source_id, atlas_x, atlas_y, alternative),
#   * adds scale = Vector2(0.25, 0.25) so a 256 px art tile still covers one 64 px stage tile.
#
# Cell meaning is preserved, not the artwork:
#   old (0,0) ground   -> Grass tile (3,0)
#   old (2,0) platform -> Grass tile (3,0)
#   old (1,0) boundary -> Stone tile (2,5)   (the only old tile with no_wall_slide = true)
#
# Terrains are NOT assigned here: the Blocks layer only stores source + atlas coords, and which
# terrain a tile belongs to lives in the TileSet. Assign Grass/Stone/Water in the TileSet editor.
#
# Usage:  powershell -File tools/migrate_blocks_to_map_tiles.ps1 [-WhatIf]
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string] $ProjectRoot = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'

$NewTilesetPath = 'res://assets/tiles/map_tiles_tileset.tres'
$NewTilesetUid = 'uid://ds7qv2mxk1n4w'
$OldTilesetPath = 'res://assets/tiles/blocks_tileset.tres'
$NewSourceId = 0

# old "atlas_x,atlas_y" -> new atlas coords
$TileMap = @{
    '0,0' = @(3, 0)   # ground   -> Grass
    '2,0' = @(3, 0)   # platform -> Grass
    '1,0' = @(2, 5)   # boundary -> Stone (not climbable)
}

$scenes = Get-ChildItem (Join-Path $ProjectRoot 'scenes/maps') -Filter '*.tscn'
foreach ($scene in $scenes) {
    $text = Get-Content $scene.FullName -Raw

    # --- locate the Blocks node and its tile_map_data -------------------------------------
    $blocksIdx = $text.IndexOf('[node name="Blocks"')
    if ($blocksIdx -lt 0) { Write-Host "skip $($scene.Name): no Blocks node"; continue }
    $tail = $text.Substring($blocksIdx)
    $dataMatch = [regex]::Match($tail, 'tile_map_data = PackedByteArray\("([^"]*)"\)')
    if (-not $dataMatch.Success) { Write-Host "skip $($scene.Name): no tile_map_data"; continue }

    $bytes = [Convert]::FromBase64String($dataMatch.Groups[1].Value)
    if ((($bytes.Length - 2) % 12) -ne 0) {
        throw "$($scene.Name): tile_map_data is not a whole number of 12-byte records"
    }
    $cellCount = ($bytes.Length - 2) / 12

    # --- rewrite source id + atlas coords in place ----------------------------------------
    $converted = 0
    $unknown = @{}
    for ($i = 0; $i -lt $cellCount; $i++) {
        $o = 2 + $i * 12
        $ax = [BitConverter]::ToInt16($bytes, $o + 6)
        $ay = [BitConverter]::ToInt16($bytes, $o + 8)
        $key = "$ax,$ay"
        if (-not $TileMap.ContainsKey($key)) {
            $unknown[$key] = $true
            continue
        }
        $new = $TileMap[$key]
        [Array]::Copy([BitConverter]::GetBytes([int16]$NewSourceId), 0, $bytes, $o + 4, 2)
        [Array]::Copy([BitConverter]::GetBytes([int16]$new[0]), 0, $bytes, $o + 6, 2)
        [Array]::Copy([BitConverter]::GetBytes([int16]$new[1]), 0, $bytes, $o + 8, 2)
        $converted++
    }
    if ($unknown.Count -gt 0) {
        throw "$($scene.Name): unmapped old atlas coords: $($unknown.Keys -join '; ')"
    }

    $newData = 'tile_map_data = PackedByteArray("' + [Convert]::ToBase64String($bytes) + '")'
    $tail = $tail.Remove($dataMatch.Index, $dataMatch.Length).Insert($dataMatch.Index, $newData)

    # --- make one 256 px art tile cover one 64 px stage tile ------------------------------
    if ($tail -notmatch '(?m)^scale = Vector2\(0\.25, 0\.25\)') {
        $insertAt = $tail.IndexOf($newData)
        $tail = $tail.Insert($insertAt, "scale = Vector2(0.25, 0.25)`n")
    }

    $text = $text.Substring(0, $blocksIdx) + $tail

    # --- point the TileSet ext_resource at the new tileset --------------------------------
    # The uid attribute is optional: tutorial.tscn stores the ext_resource with a path only.
    $pattern = '\[ext_resource type="TileSet" (?:uid="[^"]*" )?path="' +
        [regex]::Escape($OldTilesetPath) + '"'
    $replacement = '[ext_resource type="TileSet" uid="' + $NewTilesetUid + '" path="' +
        $NewTilesetPath + '"'
    $before = $text
    $text = [regex]::Replace($text, $pattern, $replacement)
    if ($text -eq $before) {
        throw "$($scene.Name): the Blocks TileSet ext_resource for $OldTilesetPath was not found"
    }

    if ($PSCmdlet.ShouldProcess($scene.Name, "migrate $converted cells")) {
        # UTF-8 with no BOM: Windows PowerShell's -Encoding UTF8 would prepend one, and Godot
        # scene files are written without it.
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($scene.FullName, $text, $utf8NoBom)
    }
    Write-Host "$($scene.Name): $converted/$cellCount cells migrated"
}
