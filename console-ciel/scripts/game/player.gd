extends CharacterBody2D
## Physics keeps the feet solid; interpolation smooths the rendered character.
const SPEED := 190.0
const SPRINT_MULTIPLIER := 1.10
const ACCELERATION := 2400.0
var controls_enabled := true
var reserve_map_arrow := false
var facing := Vector2.DOWN
var accent := Color("527fa3")
var sprite: AnimatedSprite2D
var _direction := "down"

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var collider := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	collider.shape = circle
	add_child(collider)
	sprite = AnimatedSprite2D.new()
	sprite.name = "CharacterAnimation"
	sprite.position = Vector2(0, -23)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction in ["down", "up", "left", "right"]:
		frames.add_animation(direction)
		frames.set_animation_speed(direction, 10)
		for pose in [0, 1, 0, 2]:
			frames.add_frame(direction, load("res://assets/art/character/" + direction + "_" + str(pose) + ".svg"))
	sprite.sprite_frames = frames
	# Supersampled SVGs keep their original 64 × 72 world footprint.
	sprite.scale = Vector2.ONE * (.78 * 64.0 / frames.get_frame_texture("down", 0).get_width())
	add_child(sprite)
	_update_animation(false)

func _physics_process(delta: float) -> void:
	var router := get_node_or_null("/root/SceneRouter")
	if not controls_enabled or not is_visible_in_tree() or (router != null and not router.gameplay_allowed()):
		velocity = Vector2.ZERO
		_update_animation(false)
		return
	var direction := Input.get_vector("game_left", "game_walk_right" if reserve_map_arrow else "game_right", "game_up", "game_down")
	if direction.length_squared() > .001:
		facing = direction.normalized()
		# Keep the current axis near diagonals instead of flickering left/down
		# with tiny stick variations. A clear axis change still turns at once.
		var horizontal := absf(facing.x)
		var vertical := absf(facing.y)
		if horizontal > vertical + .12 or (_direction in ["left", "right"] and horizontal >= vertical - .12):
			_direction = "right" if facing.x > 0 else "left"
		else:
			_direction = "down" if facing.y > 0 else "up"
		velocity = velocity.move_toward(direction * SPEED * (SPRINT_MULTIPLIER if Input.is_action_pressed("game_sprint") else 1.0), ACCELERATION * delta)
	else:
		# Stop immediately on release; acceleration must never create drift.
		velocity = Vector2.ZERO
	move_and_slide()
	_update_animation(get_position_delta().length_squared() > .0001)

func _update_animation(walking: bool) -> void:
	if sprite == null: return
	var settings := get_node_or_null("/root/SettingsService")
	var reduced: bool = settings != null and settings.current.get("reduce_motion", false)
	sprite.self_modulate = Color.WHITE.lerp(accent, .12)
	if sprite.animation != _direction: sprite.animation = _direction
	if walking and not reduced:
		sprite.play()
		sprite.speed_scale = clampf(velocity.length() / SPEED, .35, SPRINT_MULTIPLIER)
	else:
		sprite.stop()
		sprite.frame = 0
