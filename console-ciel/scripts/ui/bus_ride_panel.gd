extends VBoxContainer
## Deterministic phases; the saved ticket is never charged by the animation.
signal finished
var destination := ""
var elapsed := 0.0
var _done := false
var status: Label
var cabin: Control
var progress: ProgressBar
const Cabin = preload("res://scripts/ui/bus_cabin_visual.gd")
func _ready() -> void:
	name="bus_ride_panel"
	var title := Label.new()
	title.text="Bus CIEL · "+destination
	title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	add_child(title)
	status=Label.new()
	status.name="bus_ride_status"
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	add_child(status)
	cabin=Cabin.new()
	cabin.custom_minimum_size=Vector2(0,300)
	cabin.destination=destination
	cabin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_child(cabin)
	progress=ProgressBar.new()
	progress.max_value=6
	progress.show_percentage=false
	add_child(progress)
	var skip := Button.new()
	skip.name="bus_ride_finish"
	skip.text="Passer l’animation · billet déjà payé"
	skip.pressed.connect(finish)
	add_child(skip)
	_fit_cabin()
	get_viewport().size_changed.connect(_fit_cabin)
	advance(0)
func _fit_cabin() -> void:
	if cabin != null: cabin.custom_minimum_size.y = 210 if get_viewport_rect().size.x<900 or get_viewport_rect().size.y<600 else 300
func _process(delta: float) -> void:
	if not is_visible_in_tree() or _done: return
	if SettingsService.current.reduce_motion: finish(); return
	advance(delta)
func advance(delta: float) -> void:
	if _done: return
	elapsed += maxf(delta,0)
	var phase := 0 if elapsed<1.2 else (1 if elapsed<2.2 else (2 if elapsed<4.8 else 3))
	var starts := [0.0,1.2,2.2,4.8]
	var lengths := [1.2,1.0,2.6,1.2]
	cabin.phase=phase
	cabin.amount=clampf((elapsed-starts[phase])/lengths[phase],0,1)
	cabin.scenery=elapsed if phase==2 else 0
	status.text=["Embarquement...", "Paiement validé · 1 € = 10 points", "En attente de destination... · vous êtes assis dans le bus", "Arrivée · descente du bus..."][phase]
	progress.value=elapsed
	cabin.queue_redraw()
	if elapsed>=6: finish()
func finish() -> void:
	if _done: return
	_done=true
	finished.emit()
