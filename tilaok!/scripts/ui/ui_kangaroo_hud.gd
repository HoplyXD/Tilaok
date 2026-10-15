class_name UiKangarooHud
extends UiScreen

## The Kangaroo readout shown over a Kangaroo Main round or a Kangaroo Twist: up to two command
## cards (a Slipper Storm shows both requirements separately) and each seat's KANG -> GA -> ROO
## misses. Scene-authored and display-only; KangarooMainRound feeds it from the live controller.

const MAX_CARDS := 2
const MORE_TEXT := "+%d more command"

var cards: Array[UiKangarooCommandCard] = []
var markers: Array[Label] = []

@onready var _more_label: Label = %MoreLabel
@onready var _marker_panel: Control = %Markers


func router_phase() -> int:
	return LocalInputRouter.Phase.PLAY


func state_names() -> PackedStringArray:
	return PackedStringArray(["Hidden"])


func _on_screen_ready() -> void:
	cards = [%Card1, %Card2]
	markers = [%Marker1, %Marker2, %Marker3, %Marker4]
	clear()


## `commands` are KangarooRoundController.active_commands() rows, earliest first.
func bind_commands(commands: Array[Dictionary], active_time: float) -> void:
	for index in cards.size():
		var card := cards[index]
		card.visible = index < commands.size()
		if card.visible:
			card.bind(commands[index], active_time)
	var extra := commands.size() - cards.size()
	_more_label.visible = extra > 0
	_more_label.text = MORE_TEXT % maxi(extra, 0)


## One text row per joined seat ("P2 ▲  [KANG]  GA  ROO"); fewer rows hide the rest.
func bind_markers(rows: PackedStringArray) -> void:
	_marker_panel.visible = not rows.is_empty()
	for index in markers.size():
		markers[index].visible = index < rows.size()
		if index < rows.size():
			markers[index].text = rows[index]


func clear() -> void:
	for card in cards:
		card.visible = false
	_more_label.visible = false
	_marker_panel.visible = false
	for marker in markers:
		marker.visible = false


func command_count() -> int:
	var count := 0
	for card in cards:
		if card.visible:
			count += 1
	return count


func marker_texts() -> PackedStringArray:
	var result := PackedStringArray()
	for marker in markers:
		if marker.visible:
			result.append(marker.text)
	return result
