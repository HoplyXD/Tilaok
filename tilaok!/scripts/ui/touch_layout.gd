class_name TouchLayout
extends RefCounted

## NLB-P10 pure phone layout math. It takes a viewport, a safe rect, a dpi and the window size and
## returns rects, so a test can check every aspect ratio without a display. Every number below is a
## PROPOSAL that stays unmeasured until the NLB-P10-T03 sessions on real Android hardware.

## Android's logical dp baseline: 160 dpi is 1 dp per physical pixel.
const REFERENCE_DPI := 160.0
## PROPOSED touch target floor (spec §5 "proposed floor") and a comfort ceiling.
const MIN_TARGET_DP := 44.0
const MAX_TARGET_DP := 96.0
## Never go below this many viewport pixels, whatever the dpi reports.
const MIN_TARGET_PX := 44.0
## PROPOSAL (UI_HANDOFF): a 5 % theme margin inside the OS safe area (64 x 36 at 1280 x 720).
const SAFE_INSET_FRACTION := 0.05
const ZONE_WIDTH_FRACTION := 0.28
const MAX_ZONE_WIDTH_FRACTION := 0.40
const BAND_HEIGHT_FRACTION := 0.30
const MAX_BAND_HEIGHT_FRACTION := 0.45
## Controls in flow order: the first id sits on the bottom row, nearest the thumbs.
const BASE_IDS := ["jump", "sneak", "cheer", "claim", "back", "pause"]
const LIVE_IDS := ["build", "rotate", "place", "cancel"]


## Viewport pixels per dp: dpi scale times how much the stretch mode shrank the window.
static func dp_px(dpi: float, viewport: Vector2, window: Vector2) -> float:
	var density := dpi / REFERENCE_DPI if dpi > 0.0 else 1.0
	var stretch := viewport.x / window.x if window.x > 0.0 else 1.0
	return maxf(0.01, density * stretch)


static func control_ids(live: bool) -> Array:
	var ids := BASE_IDS.duplicate()
	if live:
		ids.append_array(LIVE_IDS)
	return ids


## Returns {inner, dp_px, min_target_px, button_px, gap, move_zone, aim_zone, buttons}.
## `safe_rect` is in viewport pixels; an empty rect means the whole viewport is safe.
static func compute(
	viewport: Vector2, safe_rect: Rect2, dpi: float, window: Vector2, live: bool
) -> Dictionary:
	var full := Rect2(Vector2.ZERO, viewport)
	var safe := full
	if safe_rect.has_area():
		safe = safe_rect.intersection(full)
	var inset := viewport * SAFE_INSET_FRACTION
	var inner := Rect2(safe.position + inset, safe.size - inset * 2.0)
	var density := dp_px(dpi, viewport, window)
	var min_px := maxf(MIN_TARGET_DP * density, MIN_TARGET_PX)
	var button_px := clampf(viewport.y * 0.11, min_px, maxf(min_px, MAX_TARGET_DP * density))
	var gap := maxf(6.0, 4.0 * density)
	var zone_w := clampf(inner.size.x * ZONE_WIDTH_FRACTION, button_px * 2.0, inner.size.x * MAX_ZONE_WIDTH_FRACTION)
	var ids := control_ids(live)
	var middle_w := inner.size.x - zone_w * 2.0 - gap * 2.0
	var columns := clampi(int(floor((middle_w + gap) / (button_px + gap))), 1, ids.size())
	var rows := int(ceil(float(ids.size()) / float(columns)))
	var block_w := columns * (button_px + gap) - gap
	var start_x := inner.position.x + zone_w + gap + (middle_w - block_w) * 0.5
	var buttons := {}
	for index in ids.size():
		var column := index % columns
		var row := floori(float(index) / float(columns))
		buttons[ids[index]] = Rect2(
			Vector2(start_x + column * (button_px + gap), inner.end.y - button_px - row * (button_px + gap)),
			Vector2(button_px, button_px)
		)
	var band_h := minf(
		maxf(inner.size.y * BAND_HEIGHT_FRACTION, rows * (button_px + gap)),
		inner.size.y * MAX_BAND_HEIGHT_FRACTION
	)
	var band_top := inner.end.y - band_h
	return {
		"inner": inner,
		"dp_px": density,
		"min_target_px": min_px,
		"button_px": button_px,
		"gap": gap,
		"move_zone": Rect2(Vector2(inner.position.x, band_top), Vector2(zone_w, band_h)),
		"aim_zone": Rect2(Vector2(inner.end.x - zone_w, band_top), Vector2(zone_w, band_h)) if live else Rect2(),
		"buttons": buttons,
	}
