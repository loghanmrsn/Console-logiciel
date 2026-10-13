extends Node

## Closing the app and powering off the operating system are distinct operations.
var can_shutdown: bool = false
var shutdown_status: String = "Arrêt système non configuré"

func is_pi() -> bool:
	if OS.get_name() != "Linux":
		return false
	var model_path := "/proc/device-tree/model"
	if not FileAccess.file_exists(model_path):
		return false
	var file := FileAccess.open(model_path, FileAccess.READ)
	if file == null:
		return false
	return "Raspberry Pi" in file.get_as_text()

func platform_description() -> String:
	return "%s · %s%s" % [OS.get_name(), Engine.get_architecture_name(), " · Raspberry Pi détecté" if is_pi() else ""]

func request_shutdown() -> Dictionary:
	return {"ok": false, "error": shutdown_status}

func user_data_directory() -> String:
	# Report the path selected by Godot, including redirected Windows APPDATA.
	return OS.get_user_data_dir()

func application_log_directory() -> String:
	return user_data_directory().path_join("logs")
