extends CharacterBody2D
## Feet collide, body draws above them; four directional walk / idle states.
const SPEED := 190.0
var controls_enabled := true
var facing := Vector2.DOWN
var accent := Color("527fa3")
var sprite: AnimatedSprite2D
var _direction='down'
func _ready() -> void:
 collision_layer=2;collision_mask=1
 var collider=CollisionShape2D.new()
 var circle=CircleShape2D.new();circle.radius=10.0
 collider.shape=circle;add_child(collider)
 sprite=AnimatedSprite2D.new()
 sprite.name='CharacterAnimation'
 sprite.position=Vector2(0,-23)
 sprite.scale=Vector2(.78,.78)
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 var frames=SpriteFrames.new();frames.remove_animation('default')
 for direction in ['down','up','left','right']:
  frames.add_animation(direction);frames.set_animation_speed(direction,7)
  for pose in [0,1,0,2]: frames.add_frame(direction,load('res://assets/art/character/'+direction+'_'+str(pose)+'.svg'))
 sprite.sprite_frames=frames;add_child(sprite)
 _update_animation(false)
func _physics_process(_delta: float) -> void:
 var router=get_node_or_null('/root/SceneRouter')
 if not controls_enabled or not is_visible_in_tree() or (router!=null and not router.gameplay_allowed()):
  velocity=Vector2.ZERO;_update_animation(false);return
 var direction=Input.get_vector('game_left','game_right','game_up','game_down')
 if direction.length_squared()>.001:
  facing=direction.normalized()
  _direction=('right' if facing.x>0 else 'left') if absf(facing.x)>absf(facing.y) else ('down' if facing.y>0 else 'up')
 velocity=direction*SPEED
 move_and_slide()
 _update_animation(velocity.length_squared()>1)
func _update_animation(walking: bool) -> void:
 if sprite==null:return
 var settings=get_node_or_null('/root/SettingsService')
 var reduced=settings!=null and settings.current.get('reduce_motion',false)
 sprite.self_modulate=Color.WHITE.lerp(accent,.12)
 if sprite.animation!=_direction:sprite.animation=_direction
 if walking and not reduced:sprite.play()
 else:sprite.stop();sprite.frame=0
