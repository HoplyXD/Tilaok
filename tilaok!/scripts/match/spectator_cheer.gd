class_name SpectatorCheer
extends RefCounted

## The spectator cheer (REQ-UI-004): a chicken that is out or has finished may cheer during Play.
## Presentation only: it holds one cooldown clock per seat and nothing else. It never reads or
## writes a score, a timer, a position, a command or a random stream.

signal cheered(seat_index: int)

const COOLDOWN_SECONDS := 1.0
const SHOW_SECONDS := 1.0
const SAMPLE_RATE := 22050
const CUE_SECONDS := 0.45

var cooldown_seconds := COOLDOWN_SECONDS
var _remaining: Dictionary = {}


## Counts every seat's cooldown down; call with the presentation delta while the game runs.
func advance(delta: float) -> void:
	for seat in _remaining.keys():
		var left := maxf(0.0, float(_remaining[seat]) - delta)
		if left <= 0.0:
			_remaining.erase(seat)
		else:
			_remaining[seat] = left


## True (and the cooldown starts) when the seat is eligible and not cooling down.
func request(seat_index: int, eligible: bool) -> bool:
	if not eligible or is_cooling(seat_index):
		return false
	_remaining[seat_index] = cooldown_seconds
	cheered.emit(seat_index)
	return true


func is_cooling(seat_index: int) -> bool:
	return float(_remaining.get(seat_index, 0.0)) > 0.0


func remaining(seat_index: int) -> float:
	return float(_remaining.get(seat_index, 0.0))


func reset() -> void:
	_remaining.clear()


## A short soft crowd "yay": noise swelling with a rising hum (code-generated PLACEHOLDER audio;
## the final crowd recording belongs to the audio owner). Deterministic, no random streams.
static func make_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	var count := int(SAMPLE_RATE * CUE_SECONDS)
	var data := PackedByteArray()
	data.resize(count * 2)
	var seed_value := 12345
	for index in count:
		var t := float(index) / float(count)
		var envelope := sin(PI * t) * 0.8
		seed_value = (seed_value * 1103515245 + 12345) & 0x7fffffff
		var noise := float(seed_value % 2000) / 1000.0 - 1.0
		var hum := sin(TAU * (330.0 + 220.0 * t) * float(index) / float(SAMPLE_RATE))
		var sample := int((noise * 0.45 + hum * 0.35) * envelope * 4800.0)
		var unsigned_sample := sample & 0xffff
		data[index * 2] = unsigned_sample & 0xff
		data[index * 2 + 1] = (unsigned_sample >> 8) & 0xff
	stream.data = data
	return stream
