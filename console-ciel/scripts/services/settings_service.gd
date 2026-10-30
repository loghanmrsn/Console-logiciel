extends Node
const InputMapping=preload('res://scripts/input_setup.gd')

signal settings_changed(settings: Dictionary)

const OPTIONAL_KEYS := ["appearance_style", "background_color", "button_color", "home_layout", "music_track", "bindings"]
const APPEARANCE_STYLES := ["profile", "brume", "sable", "sauge", "nuit", "aurore"]
const MUSIC_TRACKS := {"menu": "Piano doux", "ambient": "Ambiance calme", "electro": "Électro légère", "chiptune": "Rétro 8 bits"}
var _selected_track := "menu"
var defaults: Dictionary = {"master": 75, "music": 35, "effects": 65, "fullscreen": false, "large_text": false, "reduce_motion": false, "reduce_transparency": false, "deadzone": 0.25, "appearance_style": "profile", "background_color": "", "button_color": "", "home_layout": "split", "music_track": "menu", "bindings": {}}
var current: Dictionary = defaults.duplicate(true)
var committed: Dictionary = defaults.duplicate(true)
var storage_root: String = ""
var force_write_failure: bool = false
var _music_player: AudioStreamPlayer
var _effect_player: AudioStreamPlayer
var _launch_fullscreen: bool = false

func _ready() -> void:
	# Godot consumes engine flags before get_cmdline_args(). Capture the initial
	# real window mode before applying saved preferences, for --fullscreen.
	if DisplayServer.get_name() != "headless":
		_launch_fullscreen = DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	_ensure_audio()

func _exit_tree() -> void:
	for player in [_music_player, _effect_player]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null

func _root() -> String:
	if not storage_root.is_empty():
		return storage_root
	return SaveService.root_path

func _path() -> String:
	return _root().path_join("settings.cfg")

func _ok(data: Variant = null) -> Dictionary:
	return {"ok": true, "error": "", "data": data}

func _fail(message: String) -> Dictionary:
	return {"ok": false, "error": message, "data": null, "backup_available": _read(_path() + ".bak").ok}

func _storage_fail(message: String) -> Dictionary:
	SaveService.record_storage_error(message)
	return _fail(message)

func _normalize(values: Dictionary) -> Dictionary:
	var result := defaults.duplicate(true)
	for key in defaults:
		if not values.has(key):
			continue
		var value: Variant = values[key]
		if key in ["master", "music", "effects"]:
			if not (value is int or value is float) or not is_finite(float(value)) or float(value) != floor(float(value)) or float(value) < 0 or float(value) > 100:
				return {"ok": false, "error": "Le volume doit être un entier de 0 à 100 : " + key, "data": null}
			result[key] = int(value)
		elif key == "music_track":
			if not value is String or value not in MUSIC_TRACKS: return {"ok": false, "error": "Musique inconnue.", "data": null}
			result[key] = value
		elif key == "bindings":
			if not InputMapping.valid_bindings(value): return {"ok": false, "error": "Commandes personnalisées invalides.", "data": null}
			result[key] = value.duplicate(true)
		elif key == "deadzone":
			if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0.1 or float(value) > 0.6:
				return {"ok": false, "error": "La zone morte doit être comprise entre 0,10 et 0,60.", "data": null}
			result[key] = float(value)
		elif key == "appearance_style":
			if not value is String or value not in APPEARANCE_STYLES:
				return {"ok": false, "error": "Style d’apparence inconnu.", "data": null}
			result[key] = value
		elif key in ["background_color", "button_color"]:
			if not value is String or not _valid_rgb(value):
				return {"ok": false, "error": "Utilisez une couleur au format #RRGGBB : " + key, "data": null}
			result[key] = value.to_upper() if not value.is_empty() else ""
		elif key == "home_layout":
			if not value is String or value not in ["split", "carousel"]:
				return {"ok": false, "error": "Disposition de l’accueil inconnue.", "data": null}
			result[key] = value
		else:
			if not value is bool:
				return {"ok": false, "error": "Réglage booléen invalide : " + key, "data": null}
			result[key] = value
	return _ok(result)

func _valid_rgb(value: String) -> bool:
	if value.is_empty():
		return true
	if value.length() != 7 or not value.begins_with("#"):
		return false
	for character in value.substr(1):
		if character not in "0123456789abcdefABCDEF":
			return false
	return true

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "Fichier de réglages absent.", "data": null}
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return {"ok": false, "error": "Le fichier de réglages est illisible. Il est conservé.", "data": null}
	var schema: Variant = config.get_value("meta", "schema_version", 0)
	if not schema is int or schema != 1:
		return {"ok": false, "error": "Version des réglages inconnue. Le fichier est conservé.", "data": null}
	var values: Dictionary = {}
	for key in defaults:
		if not config.has_section_key("settings", key):
			if key in OPTIONAL_KEYS:
				continue
			return {"ok": false, "error": "Réglage obligatoire absent : " + key, "data": null}
		values[key] = config.get_value("settings", key)
	return _normalize(values)

func load_settings() -> Dictionary:
	var path := _path()
	if not FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			_apply(_startup_values(defaults))
			return _storage_fail("Le fichier principal des réglages manque. Une copie précédente est conservée ; choisissez une récupération.")
		committed = defaults.duplicate(true)
	else:
		var loaded := _read(path)
		if not loaded.ok:
			_apply(_startup_values(defaults))
			return _storage_fail(loaded.error)
		committed = loaded.data.duplicate(true)
	# Launcher argument wins for this startup, including Godot's own CLI options.
	committed = _startup_values(committed)
	_apply(committed)
	return _ok()

func _startup_values(values: Dictionary) -> Dictionary:
	var result := values.duplicate(true)
	if _launch_fullscreen or "--fullscreen" in OS.get_cmdline_args() or "--fullscreen" in OS.get_cmdline_user_args():
		result.fullscreen = true
	return result

func preview(values: Dictionary) -> Dictionary:
	var checked := _normalize(values)
	if not checked.ok:
		return checked
	_apply(checked.data)
	return _ok()

func cancel_preview() -> void:
	_apply(committed)

func apply_settings(values: Dictionary) -> Dictionary:
	var checked := _normalize(values)
	if not checked.ok:
		return checked
	var path := _path()
	if FileAccess.file_exists(path) and not _read(path).ok:
		return _storage_fail("Les réglages sur disque sont invalides. Choisissez une récupération avant de les remplacer.")
	if not FileAccess.file_exists(path) and FileAccess.file_exists(path + ".bak"):
		return _storage_fail("Une copie de réglages existe sans fichier principal. Choisissez une récupération avant de sauvegarder.")
	return _persist(checked.data)

func _persist(values: Dictionary) -> Dictionary:
	var path := _path()
	var config := ConfigFile.new()
	config.set_value("meta", "schema_version", 1)
	for key in defaults:
		config.set_value("settings", key, values[key])
	if force_write_failure and OS.has_feature("debug"):
		return _storage_fail("Échec d’écriture simulé (tests debug).")
	var saved := SaveService.atomic_write_text(path, config.encode_to_text())
	if not saved.ok:
		return saved
	var verified := _read(path)
	if not verified.ok:
		return _storage_fail("La vérification des réglages sauvegardés a échoué.")
	committed = values.duplicate(true)
	_apply(committed)
	return _ok()

func quarantine_settings() -> Dictionary:
	var path := _path()
	var moves: Array = []
	for source in [path, path + ".bak"]:
		if not FileAccess.file_exists(source):
			continue
		var target: String = source + ".corrupt-" + str(Time.get_unix_time_from_system()).replace(".", "-") + "-" + str(Time.get_ticks_usec())
		var code := DirAccess.rename_absolute(ProjectSettings.globalize_path(source), ProjectSettings.globalize_path(target))
		if code != OK:
			_restore_archives(moves)
			return _storage_fail("Impossible de conserver les réglages endommagés : " + error_string(code))
		moves.append({"source": source, "target": target})
	return _ok(moves)

func _restore_archives(moves: Array) -> bool:
	var restored := true
	for move in moves:
		if FileAccess.file_exists(move.source):
			restored = false
			continue
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(move.target), ProjectSettings.globalize_path(move.source)) != OK:
			restored = false
	return restored

func recover_settings(choice: String = "backup") -> Dictionary:
	if choice == "defaults":
		var archived := quarantine_settings()
		if not archived.ok:
			return archived
		var result := apply_settings(defaults)
		if not result.ok:
			_restore_archives(archived.data)
		return result
	if choice != "backup":
		return _fail("Choix de récupération inconnu.")
	var path := _path()
	var backup := _read(path + ".bak")
	if not backup.ok:
		return _storage_fail("Aucune copie précédente valide des réglages n’est disponible.")
	# Keep the valid .bak at its original path until the restored main is verified.
	# If writing fails, restore the archived main so the choice can be retried.
	var moves: Array = []
	if FileAccess.file_exists(path):
		var target := path + ".corrupt-" + str(Time.get_ticks_usec())
		var code := DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(target))
		if code != OK:
			return _storage_fail("Impossible de conserver le document principal avant récupération.")
		moves.append({"source": path, "target": target})
	var result := _persist(backup.data)
	if not result.ok:
		if not _restore_archives(moves):
			return _storage_fail(result.error + " Le document d’origine reste dans sa copie .corrupt ; la .bak valide est conservée.")
	return result

func _apply(values: Dictionary) -> void:
	current = values.duplicate(true)
	_ensure_audio()
	for pair in [["Master", "master"], ["Music", "music"], ["Effects", "effects"]]:
		var index := AudioServer.get_bus_index(pair[0])
		var amount: int = current[pair[1]]
		AudioServer.set_bus_mute(index, amount == 0)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(float(amount) / 100.0, 0.0001)))
	InputMapping.apply_bindings(current.bindings, float(current.deadzone))
	InputMapping.set_deadzone(float(current.deadzone))
	_select_music(str(current.music_track))
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if current.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		DisplayServer.window_set_mode(mode)
	settings_changed.emit(current.duplicate(true))

func _ensure_audio() -> void:
	for bus in ["Music", "Effects"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")
	if not is_inside_tree() or is_instance_valid(_music_player):
		return
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MenuMusic"
	_music_player.bus = "Music"
	add_child(_music_player)
	_effect_player = AudioStreamPlayer.new()
	_effect_player.name = "InterfaceEffects"
	_effect_player.bus = "Effects"
	add_child(_effect_player)
	_music_player.stream = _load_sound("res://assets/audio/menu.wav")
	if _music_player.stream != null:
		if _music_player.stream is AudioStreamWAV:
			_music_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			_music_player.stream.loop_begin = 0
			_music_player.stream.loop_end = _music_player.stream.data.size() / 2
	_effect_player.stream = _load_sound("res://assets/audio/confirm.wav")

func _load_sound(path: String) -> AudioStreamWAV:
	# Source projects can run before the editor creates imported sample caches.
	if FileAccess.file_exists(path):
		return AudioStreamWAV.load_from_file(path)
	# Exported packs contain the imported resource and its remapping.
	if ResourceLoader.exists(path):
		return load(path) as AudioStreamWAV
	return null

func play_music() -> void:
	# Headless uses a dummy output. Keep bus configuration testable without
	# creating playback resources that cannot produce sound in that mode.
	if DisplayServer.get_name() == "headless":
		return
	_ensure_audio()
	if is_instance_valid(_music_player) and _music_player.stream != null and not _music_player.playing:
		_music_player.play()

func stop_music() -> void:
	if is_instance_valid(_music_player):
		_music_player.stop()

func play_effect() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_ensure_audio()
	if is_instance_valid(_effect_player) and _effect_player.stream != null:
		_effect_player.play()

func _select_music(track: String) -> void:
	if track == _selected_track or not is_instance_valid(_music_player): return
	var stream := _load_sound("res://assets/audio/" + track + ".wav")
	if stream == null: return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	var playing := _music_player.playing
	_music_player.stop()
	_music_player.stream = stream
	_selected_track = track
	if playing: _music_player.play()
