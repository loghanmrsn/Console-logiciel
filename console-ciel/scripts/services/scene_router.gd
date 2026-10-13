extends Node

signal screen_requested(screen: String)

var current_screen: String = "boot"
var previous_screen: String = "boot"
var remembered_focus: Dictionary = {}
var _release_locked := false
var _locked_until_msec: int = 0

func _process(_delta: float) -> void:
	# Le relâchement doit être observé même pendant un défi ou un menu de pause.
	# Sinon le prochain appui peut être pris pour celui qui ouvrait la scène.
	if _release_locked: gameplay_allowed()

func remember(screen: String, control: Control) -> void:
	if is_instance_valid(control):
		remembered_focus[screen] = String(control.name)

func focus_key(screen: String) -> String:
	return str(remembered_focus.get(screen, ""))

func go(screen: String) -> void:
	previous_screen = current_screen
	current_screen = screen
	lock_until_release()
	screen_requested.emit(screen)

## Prevent the same press from entering a scene and interacting immediately.
func lock_until_release() -> void:
	_release_locked = true
	_locked_until_msec = Time.get_ticks_msec() + 200

func gameplay_allowed() -> bool:
	if not _release_locked:
		return true
	if Time.get_ticks_msec() < _locked_until_msec:
		return false
	for action in ["ui_accept", "ui_cancel", "game_interact", "pause"]:
		if InputMap.has_action(action) and Input.is_action_pressed(action):
			return false
	_release_locked = false
	return true
