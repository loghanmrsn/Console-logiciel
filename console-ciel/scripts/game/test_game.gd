extends Control
## Emplacement demandé par l’utilisateur, en attendant les vrais jeux.
const GlassButton = preload('res://scripts/ui/translucent_button.gd')
signal menu_requested
var game_definition: Dictionary = {}
var heading: Label

func configure(definition: Dictionary) -> void:
	game_definition = definition.duplicate(true)
	if is_instance_valid(heading):
		heading.text = game_definition.get('name', 'Jeu de test')

func _ready() -> void:
	name = 'test_game_placeholder'
	custom_minimum_size = Vector2(0, 250)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var column = VBoxContainer.new()
	column.add_theme_constant_override('separation', 16)
	panel.add_child(column)
	heading = Label.new()
	heading.name = 'test_game_title'
	heading.text = game_definition.get('name', 'Jeu de test')
	heading.add_theme_font_size_override('font_size', 28)
	column.add_child(heading)
	var message = Label.new()
	message.name = 'test_game_status'
	message.text = 'Jeu en préparation\nCet emplacement permet de tester la boutique et votre bibliothèque.\nLe vrai jeu sera ajouté ici lorsqu’il sera prêt.'
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(message)
	var button = GlassButton.new()
	button.name = 'test_game_back'
	button.text = 'Revenir à mes jeux'
	button.pressed.connect(func(): menu_requested.emit())
	column.add_child(button)
