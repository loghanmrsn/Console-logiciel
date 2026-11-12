extends CharacterBody3D
## Reusable actor for the 3D migration. Wardrobe never changes this capsule.
const Model=preload("res://scripts/character/character_model.gd")
const HEIGHT:=1.70
const RADIUS:=.23
const SPEED:=2.4
var model: Node3D
var phase:=0.0
var controls_enabled:=true
var motion_enabled := true
var smooth_turning := false
var animate_rest := false
var collider: CollisionShape3D
func _ready() -> void:
	collision_layer=2;collision_mask=1
	collider=CollisionShape3D.new()
	var capsule=CapsuleShape3D.new();capsule.radius=RADIUS;capsule.height=HEIGHT
	collider.shape=capsule;collider.position.y=HEIGHT*.5;add_child(collider)
	model=Model.new();model.configure(CharacterService.current().appearance);add_child(model)
func _physics_process(delta: float) -> void:
	if not motion_enabled:
		velocity = Vector3.ZERO
		return
	var allowed=controls_enabled and SceneRouter.gameplay_allowed()
	var direction=Input.get_vector("game_left","game_right","game_up","game_down") if allowed else Vector2.ZERO
	var speed=SPEED*(1.1 if Input.is_action_pressed("game_sprint") else 1.0)
	velocity.x=move_toward(velocity.x,direction.x*speed,delta*18) if direction!=Vector2.ZERO else 0.0
	velocity.z=move_toward(velocity.z,direction.y*speed,delta*18) if direction!=Vector2.ZERO else 0.0
	velocity.y=0 if is_on_floor() else velocity.y-9.8*delta
	move_and_slide()
	var moving=Vector2(velocity.x,velocity.z).length_squared()>.001
	var actual_motion := Vector2(get_real_velocity().x, get_real_velocity().z)
	moving = actual_motion.length_squared() > .01
	if moving:
		var facing := atan2(actual_motion.x, actual_motion.y)
		model.rotation.y = lerp_angle(model.rotation.y, facing, 1.0-exp(-18.0*delta)) if smooth_turning else facing
		phase += delta * actual_motion.length() / SPEED
	elif animate_rest:
		phase += delta
	model.pose(moving and not SettingsService.current.reduce_motion,phase)
	if animate_rest and not moving and not SettingsService.current.reduce_motion:
		model.breathe(phase)
