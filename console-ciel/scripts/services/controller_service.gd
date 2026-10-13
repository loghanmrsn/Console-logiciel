extends Node
## One controller drives named actions. Raw diagnostics remain visible for all.
## Keep the current controller until unplugged, then choose the lowest device ID.
## Reconnection selects a device but never resumes the investigation.
const InputMapping := preload("res://scripts/input_setup.gd")

signal active_controller_changed(device: int)
signal controller_connection_changed(device: int, connected: bool, was_active: bool)

var active_device := -1
var _devices: Array[int] = []
var _debug_devices: Array[int] = []
var _debug_override := false

func _ready() -> void:
	Input.joy_connection_changed.connect(_connection_changed)
	refresh()

func _exit_tree() -> void:
	if Input.joy_connection_changed.is_connected(_connection_changed):
		Input.joy_connection_changed.disconnect(_connection_changed)

func connected_devices() -> Array[int]:
	return _devices.duplicate()

func controller_name(device: int = -2) -> String:
	if device == -2:
		device = active_device
	if device < 0 or device not in _devices:
		return "Aucune manette active"
	if _debug_override:
		return "Manette virtuelle de test #%d (debug)" % device
	return Input.get_joy_name(device)

func accepts_event(event: InputEvent) -> bool:
	return not (event is InputEventJoypadMotion or event is InputEventJoypadButton) or (active_device >= 0 and event.device == active_device)

func refresh() -> void:
	_devices.clear()
	for device in (_debug_devices if _debug_override else Input.get_connected_joypads()):
		_devices.append(device)
	_devices.sort()
	if active_device not in _devices:
		_set_active(_devices[0] if not _devices.is_empty() else -1)

func _set_active(device: int) -> void:
	if device == active_device:
		InputMapping.bind_controller(device)
		return
	active_device = device
	InputMapping.bind_controller(device)
	active_controller_changed.emit(device)

func _connection_changed(device: int, connected: bool) -> void:
	var was_active := device == active_device
	refresh()
	controller_connection_changed.emit(device, connected, was_active)

## Tests explicitly declare virtual devices before injecting raw events. These
## helpers are unavailable in exported release builds and have no delivery UI.
func debug_set_devices(devices: Array) -> bool:
	if not OS.is_debug_build():
		return false
	for device in devices:
		if not device is int or device < 0 or device == InputMapping.NO_CONTROLLER_DEVICE:
			return false
	_debug_devices.clear()
	for device in devices:
		if device not in _debug_devices:
			_debug_devices.append(device)
	_debug_override = true
	refresh()
	return true

func debug_connection_changed(device: int, connected: bool) -> bool:
	if not OS.is_debug_build() or not _debug_override or device < 0:
		return false
	var was_active := device == active_device
	if connected and device not in _debug_devices:
		_debug_devices.append(device)
	elif not connected:
		_debug_devices.erase(device)
	refresh()
	controller_connection_changed.emit(device, connected, was_active)
	return true

func debug_clear_devices() -> bool:
	if not OS.is_debug_build():
		return false
	_debug_devices.clear()
	_debug_override = false
	refresh()
	return true
