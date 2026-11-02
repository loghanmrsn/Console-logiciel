extends VBoxContainer
## Deterministic phases; the saved ticket is never charged by the animation.
signal finished
var destination := ""
var elapsed := 0.0
var _done := false
var status: Label
var cabin: Control
var progress: ProgressBar
class Cabin extends Control:
	var phase := 0
	var amount := 0.0
	var scenery := 0.0
	const WALK = preload("res://assets/art/character/down_1.svg")
	const GUEST = preload("res://assets/art/character/down_0.svg")
	func _draw() -> void:
		var width := size.x
		draw_rect(Rect2(0,0,width,size.y),Color("d8e5e2"))
		for index in range(4):
			var x := 18+index*(width-36)/4
			draw_rect(Rect2(x,18,(width-60)/4,58),Color("8ab4bf"))
			draw_line(Vector2(x+4,28),Vector2(x+44,64),Color("d6e6df"),3)
			var tree_x := x+fposmod(scenery*45,(width-60)/4)
			draw_circle(Vector2(tree_x,52),12,Color("81a187"))
		draw_rect(Rect2(0,90,width,size.y-90),Color("c5c5b5"))
		for x in [width*.28,width*.52,width*.74]:
			draw_rect(Rect2(x-26,112,52,80),Color("466c78"))
			draw_line(Vector2(x-23,130),Vector2(x+23,130),Color("85a2a5"),7)
		draw_rect(Rect2(8,125,50,110),Color("637e80"))
		draw_rect(Rect2(width-62,125,54,110),Color("637e80"))
		var seat := Vector2(width*.52,150)
		var guest := seat
		if phase == 0: guest=Vector2(32,220).lerp(seat,amount)
		if phase == 3: guest=seat.lerp(Vector2(width-38,220),amount)
		var texture: Texture2D = WALK if phase in [0,3] and int(amount*12)%2 == 1 else GUEST
		draw_texture_rect(texture,Rect2(guest-Vector2(19,37),Vector2(38,43)),false)
		if phase in [1,2]:
			draw_rect(Rect2(seat+Vector2(-21,4),Vector2(42,12)),Color("557c87"))
			for x in [-9,9]:
				draw_line(seat+Vector2(x,12),seat+Vector2(x,24),Color("405b68"),5)
				draw_circle(seat+Vector2(x+2,25),4,Color("304a55"))
		if phase == 1:
			var card := (seat+Vector2(14,-12)).lerp(Vector2(width-95,123),amount)
			draw_rect(Rect2(card,Vector2(26,16)),Color("9fbeab"))
			draw_rect(Rect2(card+Vector2(4,5),Vector2(6,6)),Color("e5d5a9"))
		if phase == 1:
			draw_rect(Rect2(width-135,95,90,64),Color("344e58"))
			draw_string(ThemeDB.fallback_font,Vector2(width-125,134),"1 €",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("b8dda8"))
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
	cabin.custom_minimum_size=Vector2(0,255)
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
	advance(0)
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
