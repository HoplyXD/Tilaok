class_name KangarooCommandInstance
extends RefCounted

## Immutable command definition. The round controller keeps mutable progress next to this object;
## presentation and scoring can retain the definition without changing what was announced.

var command_id: int:
	get:
		return _command_id
var command: int:
	get:
		return _command
var command_name: String:
	get:
		return _command_name
var is_storm: bool:
	get:
		return _is_storm
var band: int:
	get:
		return _band
var wave_y: float:
	get:
		return _wave_y
var telegraph_start_at: float:
	get:
		return _telegraph_start_at
var response_start_at: float:
	get:
		return _response_start_at
var response_end_at: float:
	get:
		return _response_end_at

var _command_id: int
var _command: int
var _command_name: String
var _is_storm: bool
var _band: int
var _wave_y: float
var _telegraph_start_at: float
var _response_start_at: float
var _response_end_at: float


func _init(
	new_command_id: int,
	new_command: int,
	new_command_name: String,
	new_is_storm: bool,
	new_band: int,
	new_wave_y: float,
	new_telegraph_start_at: float,
	new_response_start_at: float,
	new_response_end_at: float
) -> void:
	_command_id = new_command_id
	_command = new_command
	_command_name = new_command_name
	_is_storm = new_is_storm
	_band = new_band
	_wave_y = new_wave_y
	_telegraph_start_at = new_telegraph_start_at
	_response_start_at = new_response_start_at
	_response_end_at = new_response_end_at
