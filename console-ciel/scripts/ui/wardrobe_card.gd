extends "res://scripts/ui/translucent_button.gd"
## One cached picture per item. Only the selected article gets a live 3D view.
var item: Dictionary
func configure(entry: Dictionary,owned: bool,equipped: bool,selected: bool) -> void:
	item=entry.duplicate()
	name="wardrobe_card_"+entry.slot+"_"+entry.id
	custom_minimum_size=Vector2(150,190)
	tooltip_text=entry.name+" · "+("Gratuit" if entry.price==0 else "%d points"%entry.price)
	toggle_mode=true;button_pressed=selected
	if selected:theme_type_variation="NavigationSelected"
	var margin=MarginContainer.new()
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,12)
	add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col=VBoxContainer.new();col.add_theme_constant_override("separation",5);margin.add_child(col)
	var picture=TextureRect.new();picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.custom_minimum_size.y=106;picture.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var path="res://assets/character3d/shop/"+entry.slot+"_"+entry.id+".webp"
	if ResourceLoader.exists(path):picture.texture=load(path)
	col.add_child(picture)
	var title=Label.new();title.text=entry.name;title.add_theme_font_size_override("font_size",16);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;col.add_child(title)
	var price=Label.new();price.text="✓ Équipé" if equipped else ("✓ Acheté" if owned and entry.price>0 else ("Gratuit" if entry.price==0 else "%d points"%entry.price));price.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;price.add_theme_font_size_override("font_size",14);col.add_child(price)
	_ignore_mouse(margin)
func _ignore_mouse(node: Node) -> void:
	if node is Control:node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():_ignore_mouse(child)
