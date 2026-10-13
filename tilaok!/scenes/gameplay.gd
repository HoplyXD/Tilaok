extends Node2D


@onready var Chicken1 = $Chicken
@onready var Chicken2 = $Chicken2
@onready var Flag = $Flag
@onready var Score1 = $Player1Score
@onready var Score2 = $Player2Score
var Player1: int = 0
var Player2: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Score1.text == "Player 1: " && Player1
	Score2.text == "Player 2: " && Player2

func _on_flag_child_entered_tree(node: Node) -> void:
	if node.name == "Chicken1":
		print("Chicken1")
		Player1 += 1
	if node.name == "Chicken2":
		print("Chicken2")
		Player2 += 1
