class_name LobbyViewModel
extends RefCounted

const SHAPE_MARKS := {"CIRCLE": "●", "TRIANGLE": "▲", "SQUARE": "■", "DIAMOND": "◆"}


static func can_start(registry: PlayerSeatRegistry) -> bool:
	return registry != null and registry.all_joined_ready_and_connected()


static func seat_rows(registry: PlayerSeatRegistry) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if registry == null:
		return rows
	for seat in registry.joined_seats():
		var shape := str(seat.shape)
		(
			rows
			. append(
				{
					"seat": int(seat.seat),
					"identity": int(seat.identity),
					"shape": shape,
					"mark": str(SHAPE_MARKS.get(shape, "◆")),
					"color": seat.color,
					"ready": bool(seat.ready),
					"connected": bool(seat.connected),
					"device_kind": str(seat.device_kind),
				}
			)
		)
	return rows
