extends RefCounted

static func panel(color: Color, radius: int = 22, border: Color = Color('#ffffff')) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_border_width_all(1)
	s.border_color = border
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 16
	s.content_margin_bottom = 16
	s.shadow_color = Color(0.15, 0.22, 0.28, 0.055)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 3)
	return s

static func build(settings: Dictionary, palette: Dictionary) -> Theme:
	var t: Theme = load('res://themes/console_theme.tres').duplicate()
	var accent = Color(palette.get('accent', '#527FA3'))
	var opaque = settings.get('reduce_transparency', false)
	var font_size = 22 if settings.get('large_text', false) else 18
	t.default_font_size = font_size
	for kind in ['Label', 'Button', 'LineEdit', 'CheckButton', 'OptionButton', 'TabBar']:
		t.set_color('font_color', kind, Color('#25313C'))
		t.set_color('font_focus_color', kind, Color('#25313C'))
		t.set_color('font_hover_color', kind, Color('#25313C'))
		t.set_color('font_pressed_color', kind, Color('#25313C'))
		t.set_color('font_disabled_color', kind, Color('#52616F'))
	var normal = panel(Color(1, 1, 1, 1.0 if opaque else 0.94), 14, Color('#D9E2E9'))
	var hover = panel(Color('#F5F9FC'), 14, accent.lightened(0.45))
	var pressed = panel(accent.lightened(0.80), 14, accent)
	var focus = panel(Color(0, 0, 0, 0), 14, accent)
	focus.set_border_width_all(3)
	focus.shadow_size = 0
	for kind in ['Button', 'OptionButton', 'CheckButton', 'LineEdit']:
		t.set_stylebox('normal', kind, normal)
		t.set_stylebox('hover', kind, hover)
		t.set_stylebox('pressed', kind, pressed)
		t.set_stylebox('focus', kind, focus)
		t.set_stylebox('disabled', kind, panel(Color('#E8EDF1'), 14, Color('#D3DCE3')))
		t.set_font_size('font_size', kind, font_size)
	# Button padding must not inherit the larger card padding.
	for box in [normal, hover, pressed, t.get_stylebox('disabled', 'Button')]:
		box.content_margin_top = 9
		box.content_margin_bottom = 9
		box.shadow_size = 3
	t.set_stylebox('panel', 'PanelContainer', panel(Color(1, 1, 1, 1.0 if opaque else 0.94)))
	t.set_type_variation('PrimaryButton','Button')
	t.set_type_variation('NavigationButton','Button')
	t.set_type_variation('NavigationSelected','NavigationButton')
	t.set_type_variation('NavigationPanel','PanelContainer')
	t.set_type_variation('HeroPanel','PanelContainer')
	t.set_type_variation('HUDPanel','PanelContainer')
	for state in ['normal','hover','pressed','disabled']:
		var primary=panel(accent.darkened(.12 if state=='pressed' else 0.0),16,accent)
		primary.content_margin_top=13; primary.content_margin_bottom=13
		t.set_stylebox(state,'PrimaryButton',primary)
		t.set_color('font_'+('color' if state=='normal' else state+'_color'),'PrimaryButton',Color.WHITE)
	t.set_color('font_focus_color','PrimaryButton',Color.WHITE)
	var primary_focus=focus.duplicate()
	primary_focus.border_color=Color('#25313C')
	t.set_stylebox('focus','PrimaryButton',primary_focus)
	# One luminous glass capsule; accessibility uses a genuinely opaque surface.
	var nav_panel=panel(Color(1,1,1,1.0 if opaque else .74),44,Color(1,1,1,1.0 if opaque else .95))
	nav_panel.content_margin_top=6;nav_panel.content_margin_bottom=6
	nav_panel.content_margin_left=8;nav_panel.content_margin_right=8
	nav_panel.shadow_color=Color(.18,.30,.38,.12)
	nav_panel.shadow_size=16
	nav_panel.shadow_offset=Vector2(0,5)
	nav_panel.border_width_top=2
	t.set_stylebox('panel','NavigationPanel',nav_panel)
	for state in ['normal','hover','pressed','disabled']:
		var surface=Color(1,1,1,0)
		if state=='hover':surface=Color(1,1,1,1.0 if opaque else .58)
		if state=='pressed':surface=accent.lightened(.86)
		var box=panel(surface,36,Color(1,1,1,0))
		box.shadow_size=0;box.content_margin_left=6;box.content_margin_right=6
		box.content_margin_top=4;box.content_margin_bottom=4
		t.set_stylebox(state,'NavigationButton',box)
	var active_nav=panel(accent.lightened(.88),36,Color(1,1,1,1.0 if opaque else .9))
	active_nav.bg_color.a=1.0 if opaque else .86
	active_nav.shadow_size=0;active_nav.set_border_width_all(1)
	active_nav.content_margin_top=4;active_nav.content_margin_bottom=4
	active_nav.content_margin_left=6;active_nav.content_margin_right=6
	t.set_stylebox('normal','NavigationSelected',active_nav)
	var active_hover=active_nav.duplicate()
	active_hover.bg_color=accent.lightened(.82)
	active_hover.bg_color.a=1.0 if opaque else .96
	t.set_stylebox('hover','NavigationSelected',active_hover)
	# This independent outline is visible on any selected or unselected tab.
	var nav_focus=panel(Color(0,0,0,0),36,accent.darkened(.12))
	nav_focus.set_border_width_all(3)
	nav_focus.shadow_size=0
	t.set_stylebox('focus','NavigationButton',nav_focus)
	var hero_panel=panel(Color('#E6EEF0') if opaque else Color(.90,.94,.95,.91),28,Color('#D0DFE2'))
	hero_panel.content_margin_left=28;hero_panel.content_margin_right=28
	hero_panel.content_margin_top=24;hero_panel.content_margin_bottom=24
	t.set_stylebox('panel','HeroPanel',hero_panel)
	var hud_panel=panel(Color(1,1,1,1 if opaque else .93),16,Color('#D7E2DD'))
	hud_panel.content_margin_left=12;hud_panel.content_margin_right=12
	hud_panel.content_margin_top=10;hud_panel.content_margin_bottom=10
	hud_panel.shadow_size=4
	t.set_stylebox('panel','HUDPanel',hud_panel)
	for entry in [['slider', Color('#DCE5EC')], ['grabber_area', accent], ['grabber_area_highlight', accent.darkened(0.15)]]:
		var track = StyleBoxFlat.new()
		track.bg_color = entry[1]
		track.set_corner_radius_all(3)
		track.content_margin_top = 3
		track.content_margin_bottom = 3
		t.set_stylebox(entry[0], 'HSlider', track)
	t.set_stylebox('focus', 'HSlider', focus)
	t.set_constant('separation', 'VBoxContainer', 12)
	t.set_constant('separation', 'HBoxContainer', 12)
	t.set_constant('h_separation', 'GridContainer', 14)
	t.set_constant('v_separation', 'GridContainer', 14)
	return t
