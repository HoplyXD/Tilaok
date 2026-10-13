class_name UiSampleMatch
extends Resource

## SAMPLE data so layouts can be reviewed without playing a match. Not gameplay data.

@export var round_number: int = 5
@export var main_challenge: String = "Karera"
@export var twist: String = "TWIST: Wind"
@export var timer_text: String = "0:42"
@export var next_event: String = "R8: Lagsanay"
@export var scores: PackedFloat32Array = PackedFloat32Array([4.5, 3.0, 2.25, 1.0])
@export var states: PackedStringArray = PackedStringArray(["SAFE", "RUN", "OUT", "TAYA"])
@export var outcomes: PackedStringArray = PackedStringArray(
	["1st - reached the flag", "2nd - reached the flag", "Did not finish", "Did not finish"]
)
@export var outcome_points: PackedFloat32Array = PackedFloat32Array([1.25, 1.0, 0.0, 0.0])
@export var awards: PackedStringArray = PackedStringArray(
	["Tapos +1.0", "Una +0.25", "Patibong +0.25", "Bawi +0.75"]
)
@export var award_seats: PackedInt32Array = PackedInt32Array([0, 0, 1, 1])
@export var no_score_reason: String = ""
@export var winner_seat: int = 0
@export var last_cluck: bool = true
@export var long_name: String = "Pambihirang Pagtitiis ng Mapagpakumbabang Manok"
@export var advance_seconds: float = 8.0
@export var tutorial_title: String = "Step 3 of 6"
@export var tutorial_body: String = "Pick an egg. It shows exactly what you will place."
