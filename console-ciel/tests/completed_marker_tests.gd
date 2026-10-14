extends SceneTree
## Real world targets and collision shapes with isolated profile/settings data.
## Completing an equipment task must clear its marker, latched prompt and action
## without deleting the furniture or preventing replay and elevator travel.

const FIRST := ["lighting", "lock", "computer"]
const SECOND := ["network", "addressing", "security"]

var checks := 0
var failures: Array[String] = []
var test_root := ""
var saves
var state
var settings
var profile_before: Dictionary = {}
var targets_changed: Array[Dictionary] = []
var requested: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	state = root.get_node("AppState")
	settings = root.get_node("SettingsService")
	test_root = "user://tests/completed_markers_%s_%s" % [Time.get_ticks_usec(), OS.get_process_id()]
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	var values: Dictionary = settings.committed.duplicate(true)
	values.reduce_motion = true
	_check(settings.apply_settings(values).ok, "Animation réduite enregistrée uniquement dans le dossier de test")
	var created: Dictionary = root.get_node("ProfileService").create_profile("Repères terminés")
	_check(created.ok, "Profil isolé créé pour vérifier que le monde n’altère pas l’économie")
	if not created.ok:
		await _finish()
		return
	profile_before = state.profile.duplicate(true)
	print("COMPLETED_MARKERS_DATA : ", ProjectSettings.globalize_path(test_root))
	for chapter in [1, 2]:
		var completed: Array = FIRST.duplicate() if chapter == 2 else []
		for id in SECOND if chapter == 2 else FIRST:
			await _test_completion(chapter, id, completed)
			completed.append(id)
	await _test_completed_rooms_and_replay()
	_check(state.profile == profile_before and saves.read_profile(str(profile_before.id)).data == profile_before, "Réparation visuelle, changement d’étage et rejeu du monde ne modifient aucun solde, achat ni sauvegarde de profil")
	await _finish()


func _test_completion(chapter: int, id: String, before: Array) -> void:
	var progress := _progress(chapter, id, before)
	var world := await _create_world(progress)
	var target: Node2D = world.get_interactable(id)
	_check(target != null, "Le nœud d’interaction existe avant la mission " + id)
	if target == null:
		await _free_world(world)
		return
	_check(world.target_id == id and target.highlighted and target.visible, "Le repère proche est réellement ciblé et affiché avant réussite : " + id)
	_check(world._can_reach(target, 12.0), "La ligne de vue et la portée physiques autorisent la mission active : " + id)
	var player_before: Node2D = world.player
	var collision_count := _collision_count(world)
	var decoration_count := _decoration_count(world)
	requested.clear()
	world.interact_nearest()
	_check(requested == [id], "La mission active répond à une vraie interaction de proximité : " + id)
	world.set_controls_enabled(false)
	var completed: Array = before.duplicate()
	completed.append(id)
	targets_changed.clear()
	world.restore_progress(_progress(chapter, id, completed))
	# This assertion happens synchronously: a challenge success dialog can keep
	# controls disabled, so waiting for the next physics update is not sufficient.
	_check(not target.visible and not target.highlighted, "Le marqueur disparaît immédiatement pendant le dialogue de réussite : " + id)
	_check(world.target_id.is_empty() and world._target == null and targets_changed == [{"id": "", "label": ""}], "La cible latched et le texte du prompt sont effacés immédiatement : " + id)
	_check(world.get_interactable(id) == target, "La cible terminée reste disponible par son API sans être détruite : " + id)
	_check(world.player == player_before and _collision_count(world) == collision_count and _decoration_count(world) == decoration_count, "Personnage, mobilier et toutes les collisions restent en place après " + id)
	_check(_completed_state(world, id), "Le décor conserve son vrai état réparé : " + id)
	if chapter == 1:
		await _physics_frames(2)
		_check(world.door_body.collision_layer == (0 if "lock" in completed else 1) and world.door_shape.disabled == ("lock" in completed), "La collision de la porte conserve l’état de sa mission : " + id)
	world.set_controls_enabled(true)
	requested.clear()
	world.interact_nearest()
	_check(requested.is_empty() and world.target_id.is_empty(), "Réactiver le déplacement près d’une mission terminée ne réouvre aucun défi : " + id)
	# Exercise the hysteresis branch with a stale target, even at zero distance.
	world.player.position = target.position
	world._target = target
	world.target_id = id
	_check(not world._can_reach(target, 1000.0), "Même un très grand rayon et une proximité forcée refusent la mission terminée : " + id)
	world.interact_nearest()
	_check(requested.is_empty() and world.target_id != id and world._target != target, "L’hystérésis abandonne une cible terminée persistante : " + id)
	world.restore_progress(progress)
	world.restore_checkpoint()
	await _physics_frames(3)
	_check(world.get_interactable(id) == target and target.visible and target.highlighted and world.target_id == id, "Une nouvelle partie retrouve la même cible avec son repère actif : " + id)
	requested.clear()
	world.interact_nearest()
	_check(requested == [id], "Le défi redevient interactif après restauration d’une partie non terminée : " + id)
	await _free_world(world)
	# Reload into a completely new world at the completed mission checkpoint.
	var resumed := await _create_world(_progress(chapter, id, completed))
	var resumed_target: Node2D = resumed.get_interactable(id)
	_check(resumed_target != null and not resumed_target.visible and not resumed_target.highlighted and resumed.target_id != id, "Une reprise au checkpoint terminé ne réaffiche pas le marqueur : " + id)
	_check(_completed_state(resumed, id), "Le nouvel exemplaire du monde conserve le décor réparé : " + id)
	requested.clear()
	resumed.interact_nearest()
	_check(requested.is_empty(), "La reprise n’interagit pas avec la mission déjà terminée : " + id)
	await _free_world(resumed)


func _test_completed_rooms_and_replay() -> void:
	var all_missions: Array = FIRST.duplicate()
	all_missions.append_array(SECOND)
	var world := await _create_world(_progress(1, "elevator", all_missions))
	for chapter in [1, 2, 1, 2]:
		world.restore_progress(_progress(chapter, "elevator", all_missions))
		world.restore_checkpoint()
		await _physics_frames(3)
		_check(world.chapter_id == chapter and world.elevator_unlocked, "L’étage %d terminé est restauré avec l’ascenseur débloqué" % chapter)
		for id in SECOND if chapter == 2 else FIRST:
			var target: Node2D = world.get_interactable(id)
			_check(target != null and not target.visible and not target.highlighted and not world._can_reach(target, 1000.0), "Aller-retour entre étages terminés conserve la mission masquée : " + id)
		var elevator: Node2D = world.get_interactable("elevator")
		_check(elevator != null and elevator.visible and elevator.highlighted and world.target_id == "elevator", "L’ascenseur reste ciblable après toutes les réussites à l’étage %d" % chapter)
		requested.clear()
		world.interact_nearest()
		_check(requested == ["elevator"], "L’ascenseur reste interactif après toutes les réussites à l’étage %d" % chapter)
	world.restore_progress(_progress(1, "entrance", []))
	await _physics_frames(3)
	_check(not world.elevator_unlocked and not world.lighting_restored and not world.door_open and not world.computer_repaired, "Recommencer rétablit les pannes et verrouille l’ascenseur")
	for id in FIRST:
		var target: Node2D = world.get_interactable(id)
		world.player.position = world.CHECKPOINTS[id] if id != "computer" else Vector2(581, 340)
		await _physics_frames(3)
		_check(target != null and target.visible, "Recommencer restaure un marqueur potentiel pour " + id)
	# The elevator stays inspectable while locked; the service/dialog explains
	# why chapter two cannot be entered yet, rather than hiding the furnishing.
	world.player.position = world.CHECKPOINTS.elevator
	await _physics_frames(3)
	requested.clear()
	world.interact_nearest()
	_check(world.target_id == "elevator" and requested == ["elevator"] and not world.elevator_unlocked, "L’ascenseur verrouillé demeure examinable pendant le rejeu")
	await _free_world(world)


func _create_world(progress: Dictionary) -> Node2D:
	# Autoload names are registered after a SceneTree --script is parsed.
	var world: Node2D = load("res://scripts/game/investigation_world.gd").new()
	world.restore_progress(progress)
	world.target_changed.connect(func(id: String, label: String): targets_changed.append({"id": id, "label": label}))
	world.interaction_requested.connect(func(id: String): requested.append(id))
	root.add_child(world)
	await _physics_frames(3)
	await process_frame
	return world


func _free_world(world: Node2D) -> void:
	root.remove_child(world)
	world.queue_free()
	await process_frame
	await process_frame


func _progress(chapter: int, checkpoint: String, completed: Array) -> Dictionary:
	return {"room_id": "room_02" if chapter == 2 else "room_01", "checkpoint_id": checkpoint, "completed_missions": completed.duplicate()}


func _completed_state(world: Node2D, id: String) -> bool:
	match id:
		"lighting": return world.lighting_restored and world._cabinet_sprite.texture == world.Art.TEXTURES.electrical_on
		"lock": return world.door_open and world._reader_sprite.texture == world.Art.TEXTURES.reader_on and world._open_door.visible and not world._closed_door.visible
		"computer": return world.computer_repaired and world._monitor_sprite.texture == world.Art.TEXTURES.monitor_on
		"network": return world.network_restored and world._network_sprite.modulate == Color("b9d9bc")
		"addressing": return world.addressing_restored and world._addressing_sprite.modulate == Color("b9d9bc")
		"security": return world.security_restored and world._security_sprite.modulate == Color("b9d9bc")
	return false


func _collision_count(node: Node) -> int:
	var count := 1 if node is CollisionShape2D else 0
	for child in node.get_children():
		count += _collision_count(child)
	return count


func _decoration_count(node: Node) -> int:
	var count := 1 if node is Sprite2D else 0
	for child in node.get_children():
		count += _decoration_count(child)
	return count


func _physics_frames(count: int) -> void:
	for index in range(count):
		await physics_frame


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("COMPLETED_MARKERS_FAIL : " + message)


func _remove_tree(path: String) -> void:
	if test_root.is_empty() or not path.begins_with(test_root):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for filename in directory.get_files():
		directory.remove(filename)
	for dirname in directory.get_directories():
		_remove_tree(path.path_join(dirname))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _finish() -> void:
	state.clear_profile()
	for player in [settings._music_player, settings._effect_player]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	_remove_tree(test_root)
	await process_frame
	print("COMPLETED_MARKERS : %d assertions, %d échec(s)." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
