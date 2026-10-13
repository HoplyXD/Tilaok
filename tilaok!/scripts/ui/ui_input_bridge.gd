class_name UiInputBridge
extends Node

## Forwards LocalInputRouter navigation/actions to the active screen. The screen decides whether
## the seat owns it. Screen changes go through router.set_phase(), so held presses are consumed by
## the router exactly as for gameplay phases.

signal action_forwarded(seat_index: int, action_name: String)

const ACCEPT_ACTIONS := ["ready", "claim", "confirm"]

var router: LocalInputRouter
var screen: UiScreen


func attach(input_router: LocalInputRouter) -> void:
	detach()
	router = input_router
	router.navigation_step.connect(_on_navigation_step)
	router.action_pressed.connect(_on_action_pressed)


func detach() -> void:
	if router != null and is_instance_valid(router):
		if router.navigation_step.is_connected(_on_navigation_step):
			router.navigation_step.disconnect(_on_navigation_step)
		if router.action_pressed.is_connected(_on_action_pressed):
			router.action_pressed.disconnect(_on_action_pressed)
	router = null


func set_screen(next_screen: UiScreen) -> void:
	screen = next_screen
	if router != null and screen != null:
		router.set_phase(screen.router_phase() as LocalInputRouter.Phase)


func _exit_tree() -> void:
	detach()


func _on_navigation_step(seat_index: int, direction: String) -> void:
	if screen != null and is_instance_valid(screen):
		screen.navigate(seat_index, direction)


func _on_action_pressed(seat_index: int, action_name: String) -> void:
	if screen == null or not is_instance_valid(screen) or seat_index < 0:
		return
	if action_name in ACCEPT_ACTIONS:
		screen.accept(seat_index)
	elif action_name == "back":
		screen.back(seat_index)
	else:
		return
	action_forwarded.emit(seat_index, action_name)
