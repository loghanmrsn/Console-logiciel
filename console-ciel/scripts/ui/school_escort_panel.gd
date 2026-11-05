extends VBoxContainer
## Presentation only: the service has already saved the arrival atomically.
signal finished
const DURATION := 2.6
const Visual = preload("res://scripts/ui/school_escort_visual.gd")
var player_frames: SpriteFrames
var elapsed := 0.0
var _done := false
var _last_tick := 0
var scene: Control
var status: Label
func _enter_tree() -> void: _last_tick=Time.get_ticks_usec()
func _ready() -> void:
	name="school_escort_panel"
	status=Label.new()
	status.name="school_escort_status"
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	add_child(status)
	scene=Visual.new()
	scene.player_frames=player_frames
	scene.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_child(scene)
	var skip := preload("res://scripts/ui/translucent_button.gd").new()
	skip.name="school_escort_skip"
	skip.text="Passer l’animation"
	skip.pressed.connect(finish)
	add_child(skip)
	get_viewport().size_changed.connect(_fit)
	_fit()
	advance(0)
func _fit() -> void:
	scene.custom_minimum_size.y=180 if get_viewport_rect().size.y<600 else 270
func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var seconds := float(now-_last_tick)/1000000.0
	_last_tick=now
	if _done or not is_visible_in_tree(): return
	if SettingsService.current.reduce_motion: finish();return
	advance(seconds)
func advance(seconds: float) -> void:
	if _done: return
	elapsed=minf(DURATION,elapsed+maxf(seconds,0))
	status.text="Avec la surveillante · montée des escaliers" if elapsed<DURATION*.5 else "Avec la surveillante · couloir des ateliers"
	scene.set_elapsed(elapsed)
	if elapsed>=DURATION: finish()
func finish() -> void:
	if _done: return
	_done=true
	finished.emit()
