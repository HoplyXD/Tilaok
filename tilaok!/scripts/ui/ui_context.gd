class_name UiContext
extends RefCounted

## Everything a screen needs to show itself in the gallery: seats, device kind, prompt glyphs and
## SAMPLE match values. Live games build the same dictionaries from PlayerSeatRegistry.

const SAMPLE_4P_PATH := "res://data/ui/sample_match_4p.tres"
const SAMPLE_2P_PATH := "res://data/ui/sample_match_2p.tres"
const PROMPT_MAP_PATH := "res://data/ui/prompt_map.tres"
const LIBRARY_TEXT_PATH := "res://data/ui/library_text.tres"
const DEVICE_KINDS := ["k1", "k2", "gamepad"]

var seats: Array[Dictionary] = []
var player_count := 4
var device_kind := "k1"
var prompt_map: UiPromptMap
var sample: UiSampleMatch
var library_text: UiLibraryText
var definitions: ItemDefinitions
var tuning: GameplayTuning
var settings: PresentationSettings
var owner_seat := 0


static func make(count: int, device: String) -> UiContext:
	var ctx := UiContext.new()
	ctx.tuning = GameplayTuning.new()
	ctx.definitions = ItemDefinitions.load_all(ctx.tuning)
	ctx.settings = PresentationSettings.new()
	ctx.prompt_map = load(PROMPT_MAP_PATH) as UiPromptMap
	ctx.library_text = load(LIBRARY_TEXT_PATH) as UiLibraryText
	ctx.configure(count, device)
	return ctx


func configure(count: int, device: String) -> void:
	player_count = clampi(count, 1, PlayerSeatRegistry.MAX_SEATS)
	device_kind = device if device in DEVICE_KINDS else "k1"
	sample = load(SAMPLE_2P_PATH if player_count <= 2 else SAMPLE_4P_PATH) as UiSampleMatch
	seats = sample_seats(player_count)


static func sample_seats(count: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in PlayerSeatRegistry.MAX_SEATS:
		var joined := index < count
		var kind := "keyboard" if index < 2 else "gamepad"
		(
			result
			. append(
				{
					"seat": index,
					"identity": index + 1,
					"shape": PlayerSeatRegistry.SHAPES[index],
					"color": PlayerSeatRegistry.COLORS[index],
					"joined": joined,
					"connected": joined,
					"device_kind": kind if joined else "",
					"device_id": index - 2 if index >= 2 else -1,
					"keyboard_layout": ("K%d" % (index + 1)) if index < 2 and joined else "",
					"ready": joined and index % 2 == 0,
				}
			)
		)
	return result


## Prompt-map device key for a seat dictionary.
static func device_for_seat(seat: Dictionary) -> String:
	if str(seat.get("device_kind", "")) == "gamepad":
		return "gamepad"
	return "k2" if str(seat.get("keyboard_layout", "")) == "K2" else "k1"


func joined_seats() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for seat in seats:
		if bool(seat.joined):
			result.append(seat)
	return result
