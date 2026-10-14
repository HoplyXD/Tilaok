class_name SeededDiagnosticStreams
extends RefCounted

var egg := RandomNumberGenerator.new()
var event := RandomNumberGenerator.new()
var tie := RandomNumberGenerator.new()
var taya := RandomNumberGenerator.new()
var cosmetic := RandomNumberGenerator.new()


func seed_all(seed_value: int) -> void:
	egg.seed = seed_value + 101
	event.seed = seed_value + 211
	tie.seed = seed_value + 307
	taya.seed = seed_value + 353
	cosmetic.seed = seed_value + 401


func choose_weighted(
	catalog: DiagnosticContentCatalog, kind: String, stream: RandomNumberGenerator
) -> DiagnosticContentEntry:
	var pool := catalog.eligible_entries(kind)
	var total := 0.0
	for entry in pool:
		total += entry.weight
	if pool.is_empty() or total <= 0.0:
		return null
	var selected_weight := stream.randf() * total
	for entry in pool:
		selected_weight -= entry.weight
		if selected_weight < 0.0:
			return entry
	return pool.back()
