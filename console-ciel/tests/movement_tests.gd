extends SceneTree
var checks := 0
var failures: Array[String] = []
var world

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("MOVEMENT_FAIL : ", message)

func _run() -> void:
	await process_frame
	var settings = root.get_node("SettingsService")
	settings.storage_root = "user://tests/movement_%s" % OS.get_process_id()
	world = load("res://scenes/investigation_world.tscn").instantiate()
	root.add_child(world)
	world.restore_progress({"room_id": "courtyard", "checkpoint_id": "from_first", "completed_missions": ["lighting", "lock", "computer"]})
	await physics_frame
	await physics_frame
	_check(ProjectSettings.get_setting("physics/common/physics_interpolation"), "Interpolation physique activée")
	_check(world.process_physics_priority > world.player.process_physics_priority, "La caméra suit après le déplacement du joueur")
	_check(world.camera.process_callback == Camera2D.CAMERA2D_PROCESS_PHYSICS, "Caméra et personnage utilisent la même horloge")
	var player = world.player
	player.position = Vector2(900, 980)
	player.reset_physics_interpolation()
	world.set_controls_enabled(true)
	var start: Vector2 = player.position
	Input.action_press("game_right")
	await physics_frame
	await physics_frame
	_check(player.velocity.x > 0 and player.velocity.x <= player.SPEED, "Accélération positive bornée")
	for step in range(20): await physics_frame
	_check(player.position.x > start.x + 40 and player.velocity.length() <= player.SPEED + .01, "La marche avance sans dépasser la vitesse prévue")
	Input.action_release("game_right")
	await physics_frame
	await physics_frame
	var stopped: Vector2 = player.position
	for step in range(5): await physics_frame
	_check(player.velocity == Vector2.ZERO and player.position == stopped, "Relâcher arrête immédiatement sans glisser")
	_check(player.sprite.frame == 0 and not player.sprite.is_playing(), "Pose neutre immobile")
	var size: Vector2 = player.sprite.sprite_frames.get_frame_texture("down", 0).get_size() * player.sprite.scale
	_check(size.is_equal_approx(Vector2(64, 72) * .78), "Le suréchantillonnage ne change pas la taille du personnage")
	for direction in ["down", "up", "left", "right"]:
		for index in range(4):
			var texture: Texture2D = player.sprite.sprite_frames.get_frame_texture(direction, index)
			_check(texture.get_image().has_mipmaps() and texture.get_width() == 128, "Texture filtrée en haute définition : " + direction + str(index))
	Input.action_press("game_right")
	world.set_controls_enabled(false)
	for step in range(5): await physics_frame
	_check(player.position == stopped and player.velocity == Vector2.ZERO, "Pause stoppe les déplacements même avec une touche maintenue")
	Input.action_release("game_right")
	world.restore_checkpoint()
	_check(player.position == world._chapter_checkpoints().from_first, "Reprise au checkpoint sans déplacement résiduel")
	world.free()
	print("MOVEMENT : %d assertions, %d échec(s)." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
