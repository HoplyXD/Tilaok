class_name TransientBudget
extends RefCounted

## Bounded transient workload for item projectiles, bubbles and cosmetic effects.
## Saturation suppresses new spawns; an existing captive is never evicted.
## Slots are granted in a rotating order over stable emitter IDs, never callback order.

enum Kind { PROJECTILE, BUBBLE, VFX }

var _cap := {}
var _ttl := {}
var _per_emitter := {}
var _per_player := {}
var _active := {}
var _cursor := {}
var _captives := {}
var _now := 0.0
var _next_handle := 1


func configure(tuning: GameplayTuning) -> void:
	_cap = {
		Kind.PROJECTILE: tuning.item_projectile_cap,
		Kind.BUBBLE: tuning.item_bubble_cap,
		Kind.VFX: tuning.item_vfx_cap,
	}
	_ttl = {
		Kind.PROJECTILE: tuning.item_projectile_ttl_s,
		Kind.BUBBLE: tuning.item_bubble_ttl_s,
		Kind.VFX: tuning.item_vfx_ttl_s,
	}
	_per_emitter = {
		Kind.PROJECTILE: tuning.item_projectiles_per_emitter,
		Kind.BUBBLE: tuning.item_bubbles_per_emitter,
		Kind.VFX: tuning.item_vfx_cap,
	}
	_per_player = {Kind.BUBBLE: tuning.item_bubbles_per_player}
	_active = {Kind.PROJECTILE: {}, Kind.BUBBLE: {}, Kind.VFX: {}}
	_cursor = {Kind.PROJECTILE: 0, Kind.BUBBLE: 0, Kind.VFX: 0}
	_captives.clear()
	_now = 0.0
	_next_handle = 1


## requests: Array of {emitter_id: String, player_id: String (optional)}.
## Returns granted slots as {handle, emitter_id, kind}. Result order is the rotating order.
func allocate(kind: Kind, requests: Array[Dictionary]) -> Array[Dictionary]:
	var granted: Array[Dictionary] = []
	var by_emitter := {}
	for request in requests:
		var emitter_id := str(request.get("emitter_id", ""))
		if emitter_id.is_empty() or by_emitter.has(emitter_id):
			continue
		by_emitter[emitter_id] = request
	var order: Array = by_emitter.keys()
	order.sort()
	var count := order.size()
	if count == 0:
		return granted
	var start := int(_cursor[kind]) % count
	_cursor[kind] = (int(_cursor[kind]) + 1) % count
	var active: Dictionary = _active[kind]
	for offset in range(count):
		var emitter_id: String = order[(start + offset) % count]
		if active.size() >= int(_cap[kind]):
			break
		if _emitter_count(kind, emitter_id) >= int(_per_emitter[kind]):
			continue
		var player_id := str((by_emitter[emitter_id] as Dictionary).get("player_id", ""))
		if (
			kind == Kind.BUBBLE
			and not player_id.is_empty()
			and _player_count(kind, player_id) >= int(_per_player[Kind.BUBBLE])
		):
			continue
		var handle := _next_handle
		_next_handle += 1
		active[handle] = {
			"emitter_id": emitter_id,
			"player_id": player_id,
			"expires_at": _now + float(_ttl[kind]),
		}
		granted.append({"handle": handle, "emitter_id": emitter_id, "kind": kind})
	return granted


func is_active(kind: Kind, handle: int) -> bool:
	return (_active[kind] as Dictionary).has(handle)


## Attaches a captive to an active bubble. A bubble holding a captive does not time out.
func register_captive(handle: int, player_id: String) -> bool:
	if player_id.is_empty() or _captives.has(player_id):
		return false
	if not is_active(Kind.BUBBLE, handle):
		return false
	_captives[player_id] = handle
	return true


## Releases a handle. Returns the captive player ID that was safely released, or "".
func release(kind: Kind, handle: int) -> String:
	var active: Dictionary = _active[kind]
	if not active.has(handle):
		return ""
	active.erase(handle)
	for player_id in _captives.keys():
		if int(_captives[player_id]) == handle and kind == Kind.BUBBLE:
			_captives.erase(player_id)
			return str(player_id)
	return ""


func release_captive(player_id: String) -> bool:
	return _captives.erase(player_id)


## Advances time and releases expired, non-captive handles. Returns the expired handles.
func advance(delta: float) -> Array[Dictionary]:
	_now += delta
	var expired: Array[Dictionary] = []
	for kind in _active.keys():
		var active: Dictionary = _active[kind]
		for handle in active.keys():
			if float((active[handle] as Dictionary).expires_at) > _now:
				continue
			if kind == Kind.BUBBLE and _handle_has_captive(int(handle)):
				continue
			active.erase(handle)
			expired.append({"kind": kind, "handle": handle})
	return expired


## Round end, removal or restart: drops every transient and returns released captive IDs.
func clear_all() -> PackedStringArray:
	var released := PackedStringArray()
	for player_id in _captives.keys():
		released.append(str(player_id))
	released.sort()
	_captives.clear()
	for kind in _active.keys():
		(_active[kind] as Dictionary).clear()
	return released


## Releases everything owned by an emitter (owner removal). Returns released captive IDs.
func release_emitter(emitter_id: String) -> PackedStringArray:
	var released := PackedStringArray()
	for kind in _active.keys():
		var active: Dictionary = _active[kind]
		for handle in active.keys():
			if str((active[handle] as Dictionary).emitter_id) != emitter_id:
				continue
			var captive := release(kind as Kind, int(handle))
			if not captive.is_empty():
				released.append(captive)
	return released


func count(kind: Kind) -> int:
	return (_active[kind] as Dictionary).size()


func captive_count() -> int:
	return _captives.size()


func total_count() -> int:
	var total := 0
	for kind in _active.keys():
		total += (_active[kind] as Dictionary).size()
	return total


func _emitter_count(kind: Kind, emitter_id: String) -> int:
	var found := 0
	for entry in (_active[kind] as Dictionary).values():
		if str((entry as Dictionary).emitter_id) == emitter_id:
			found += 1
	return found


func _player_count(kind: Kind, player_id: String) -> int:
	var found := 0
	for entry in (_active[kind] as Dictionary).values():
		if str((entry as Dictionary).player_id) == player_id:
			found += 1
	return found


func _handle_has_captive(handle: int) -> bool:
	for captive_handle in _captives.values():
		if int(captive_handle) == handle:
			return true
	return false
