class_name PresentationApplier
extends RefCounted

## Applies the player's presentation settings (session only, nothing is saved): the Master, Music,
## Effects and Crowd bus volumes, the Mute switch, and the Screen shake level that presentation-only
## effects read (stage-block crumble jitter, stun brightening). It never touches a rule, a clock or
## a score. default_bus_layout.tres defines the buses.

const BUS_MASTER := &"Master"
const BUS_MUSIC := &"Music"
const BUS_EFFECTS := &"Effects"
const BUS_CROWD := &"Crowd"
const SILENT_DB := -80.0
const SHAKE_FULL := 0
const SHAKE_REDUCED := 1
const SHAKE_OFF := 2
const REDUCED_SCALE := 0.34

## The Screen shake level every presentation-only effect reads (default Off, like the setting).
static var shake_mode := SHAKE_OFF


static func apply(settings: PresentationSettings) -> void:
	if settings == null:
		return
	shake_mode = settings.screen_shake
	_set_bus(BUS_MASTER, settings.master_volume, settings.muted)
	_set_bus(BUS_MUSIC, settings.music_volume, false)
	_set_bus(BUS_EFFECTS, settings.effects_volume, false)
	_set_bus(BUS_CROWD, settings.crowd_volume, false)


## Back to the defaults a fresh launch has: full volume, unmuted, shake off.
static func reset() -> void:
	apply(PresentationSettings.new())


## 1.0 at Full, a third at Reduced and 0 at Off: the amplitude presentation effects use.
static func shake_scale() -> float:
	match shake_mode:
		SHAKE_FULL:
			return 1.0
		SHAKE_REDUCED:
			return REDUCED_SCALE
	return 0.0


static func bus_volume_db(bus: StringName) -> float:
	var index := AudioServer.get_bus_index(bus)
	return AudioServer.get_bus_volume_db(index) if index >= 0 else SILENT_DB


static func bus_muted(bus: StringName) -> bool:
	var index := AudioServer.get_bus_index(bus)
	return AudioServer.is_bus_mute(index) if index >= 0 else false


static func _set_bus(bus: StringName, volume: float, muted: bool) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	var db := SILENT_DB if volume <= 0.0 else maxf(SILENT_DB, linear_to_db(volume))
	AudioServer.set_bus_volume_db(index, db)
	AudioServer.set_bus_mute(index, muted)
