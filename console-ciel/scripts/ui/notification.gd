extends PanelContainer
var label: Label
var dismiss_timer: Timer
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	label=Label.new()
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	dismiss_timer=Timer.new()
	dismiss_timer.one_shot=true
	dismiss_timer.wait_time=6.0
	dismiss_timer.timeout.connect(hide)
	add_child(dismiss_timer)
	hide()
func show_message(message: String) -> void:
	label.text=message
	show()
	dismiss_timer.start(clampf(3.0+message.length()/18.0,6.0,12.0))
