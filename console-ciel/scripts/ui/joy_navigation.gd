extends Node
const DemoScene=preload('res://scripts/game/demo_game.gd')
## Répétition de navigation manette. Le clavier conserve les événements natifs.
## Les axes/boutons physiques sont définis uniquement par InputSetup.

const INITIAL_REPEAT_DELAY := 0.35
const REPEAT_INTERVAL := 0.14
const DIRECTIONS := ["ui_up", "ui_down", "ui_left", "ui_right"]
const SIDES := {
	"ui_up": SIDE_TOP,
	"ui_down": SIDE_BOTTOM,
	"ui_left": SIDE_LEFT,
	"ui_right": SIDE_RIGHT
}

var _joy_mode := false
var _held_direction := ""
var _repeat_remaining := INITIAL_REPEAT_DELAY

func _ready() -> void:
	var controllers := get_node_or_null("/root/ControllerService")
	if controllers != null:
		controllers.active_controller_changed.connect(_active_controller_changed)

func _active_controller_changed(_device: int) -> void:
	_joy_mode = false
	_reset_hold()

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		_joy_mode = false
		_reset_hold()
		return
	if not (event is InputEventJoypadMotion or event is InputEventJoypadButton):
		return
	var controllers := get_node_or_null("/root/ControllerService")
	if controllers == null or not controllers.accepts_event(event):
		return
	var directional := false
	var pressed := false
	for action in DIRECTIONS:
		if event.is_action(action):
			directional = true
			pressed = pressed or event.is_action_pressed(action)
	if not directional or (not pressed and not _joy_mode):
		return
	var owner := get_viewport().gui_get_focus_owner()
	if _native_popup_active(owner):
		_reset_hold()
		return
	if _game_controls_active(owner):
		_joy_mode = false
		_reset_hold()
		return
	# L'événement manette original ne doit pas produire un second déplacement natif.
	get_viewport().set_input_as_handled()
	_joy_mode = true
	_update_direction(owner)

func _process(delta: float) -> void:
	if not _joy_mode:
		return
	var owner := get_viewport().gui_get_focus_owner()
	if not is_instance_valid(owner) or _game_controls_active(owner) or _native_popup_active(owner):
		_reset_hold()
		return
	if _update_direction(owner) or _held_direction.is_empty():
		return
	_repeat_remaining -= delta
	if _repeat_remaining <= 0.0:
		_move(owner, _held_direction)
		# Une frame lente ne provoque pas une rafale de changements de focus.
		_repeat_remaining = REPEAT_INTERVAL

func _reset_hold() -> void:
	_held_direction = ""
	_repeat_remaining = INITIAL_REPEAT_DELAY

func _update_direction(owner: Control) -> bool:
	var direction := _read_direction()
	if direction == _held_direction:
		return false
	_held_direction = direction
	_repeat_remaining = INITIAL_REPEAT_DELAY
	if not direction.is_empty() and is_instance_valid(owner):
		_move(owner, direction)
	return true

func _read_direction() -> String:
	var direction := ""
	var strength := 0.0
	for action in DIRECTIONS:
		if Input.is_action_pressed(action):
			var candidate := Input.get_action_strength(action)
			if candidate > strength:
				strength = candidate
				direction = action
	return direction

func _move(owner: Control, action: String) -> void:
	if not is_instance_valid(owner) or not owner.is_visible_in_tree():
		return
	if owner is Slider and action in ["ui_left", "ui_right"]:
		if owner.editable:
			var increment: float = owner.step if owner.step > 0.0 else maxf((owner.max_value - owner.min_value) / 100.0, 0.01)
			owner.value += increment * (-1.0 if action == "ui_left" else 1.0)
		return
	var path=owner.get_focus_neighbor(int(SIDES[action]))
	var neighbor: Control=owner.get_node_or_null(path) as Control if not path.is_empty() else owner.find_valid_focus_neighbor(int(SIDES[action]))
	if not is_instance_valid(neighbor) or neighbor == owner:
		return
	neighbor.grab_focus()

func _game_controls_active(owner: Control) -> bool:
	if SceneRouter.current_screen != "game" or not is_instance_valid(owner):
		return false
	var ancestor: Node = owner
	while ancestor != null:
		if ancestor is DemoScene:
			return not ancestor.paused
		ancestor = ancestor.get_parent()
	return false

func _native_popup_active(owner: Control) -> bool:
	return is_instance_valid(owner) and owner is OptionButton and owner.get_popup().visible
