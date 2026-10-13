class_name ItemVisualSlot
extends Resource

## One replaceable presentation slot. Artists swap the file named by `frames`/`sound` (or edit this
## resource in the inspector); no code names a file. Every shipped slot starts as PLACEHOLDER.

@export var slot_id := ""
## Looping frames; a single frame is a still image.
@export var frames: Array[Texture2D] = []
@export var fps := 4.0
@export var sound: AudioStream
## Offset added to the drawn rectangle, in world units.
@export var pivot := Vector2.ZERO
## Drawn size in grid cells; Vector2.ZERO means "fill the region the slot is drawn into".
@export var size_cells := Vector2.ZERO
@export var placeholder := true
@export var final_owner := ""
@export var source_note := ""


func frame_at(seconds: float) -> Texture2D:
	if frames.is_empty():
		return null
	var index := int(floor(maxf(0.0, seconds) * maxf(fps, 0.001))) % frames.size()
	return frames[index]
