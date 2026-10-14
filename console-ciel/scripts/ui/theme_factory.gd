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

const AppearancePalette = preload('res://scripts/ui/appearance_palette.gd')

static func build(settings: Dictionary, palette: Dictionary) -> Theme:
	var t: Theme = load('res://themes/console_theme.tres').duplicate()
	var colors := AppearancePalette.resolve(settings, palette)
	for key in colors:
		t.set_color(key, 'Appearance', Color(colors[key]))
	var foreground := Color(colors.foreground)
	var muted := Color(colors.muted)
	var surface := Color(colors.panel)
	var button_surface := Color(colors.button)
	var accent := Color(colors.accent)
	var secondary := Color(colors.secondary)
	var opaque: bool = settings.get('reduce_transparency', false)
	var dark := AppearancePalette.luminance(foreground) > 0.5
	var border := foreground.lerp(surface, 0.80)
	var focus_color := accent if AppearancePalette.contrast_ratio(accent, surface) >= 3.0 else foreground
	t.set_color('focus', 'Appearance', focus_color)
	var font_size := 22 if settings.get('large_text', false) else 18
	t.default_font_size = font_size
	for kind in ['Label', 'Button', 'LineEdit', 'CheckBox', 'CheckButton', 'OptionButton', 'TabBar', 'PopupMenu', 'LinkButton', 'RichTextLabel', 'TextEdit']:
		for key in ['font_color', 'font_focus_color', 'font_hover_color', 'font_pressed_color', 'font_hover_pressed_color']:
			t.set_color(key, kind, foreground)
		t.set_color('font_disabled_color', kind, muted)
		t.set_font_size('font_size', kind, font_size)
	t.set_color('default_color', 'RichTextLabel', foreground)
	for variation in ['SecondaryLabel', 'MutedLabel']:
		t.set_type_variation(variation, 'Label')
		t.set_color('font_color', variation, muted)
	var focus := panel(Color(0, 0, 0, 0), 14, focus_color)
	focus.set_border_width_all(3)
	focus.shadow_size = 0
	for kind in ['Button', 'OptionButton', 'CheckButton', 'CheckBox']:
		for state in ['normal', 'hover', 'pressed', 'hover_pressed', 'disabled']:
			var fill := button_surface
			if state == 'hover':
				fill = button_surface.lightened(0.08) if dark else button_surface.darkened(0.04)
			elif state in ['pressed', 'hover_pressed']:
				fill = button_surface.darkened(0.08) if dark else button_surface.darkened(0.09)
			elif state == 'disabled':
				fill = surface.lerp(Color(colors.background), 0.35)
			var box := panel(fill, 14, border)
			box.content_margin_top = 9
			box.content_margin_bottom = 9
			box.shadow_size = 3
			t.set_stylebox(state, kind, box)
			var color_name: String = 'font_color' if state == 'normal' else 'font_' + state + '_color'
			t.set_color(color_name, kind, AppearancePalette.readable_text(fill))
		t.set_stylebox('focus', kind, focus)
		t.set_color('font_focus_color', kind, AppearancePalette.readable_text(button_surface))
	# Editors and popup menus remain reading surfaces when buttons use a bright color.
	for state in ['normal', 'read_only']:
		t.set_stylebox(state, 'LineEdit', panel(surface, 14, border))
	t.set_stylebox('focus', 'LineEdit', focus)
	t.set_color('font_color', 'LineEdit', foreground)
	t.set_color('font_uneditable_color', 'LineEdit', muted)
	t.set_color('font_placeholder_color', 'LineEdit', muted)
	t.set_color('caret_color', 'LineEdit', foreground)
	t.set_color('selection_color', 'LineEdit', secondary)
	t.set_color('font_selected_color', 'LineEdit', foreground)
	t.set_stylebox('panel', 'PopupMenu', panel(surface, 14, border))
	t.set_stylebox('hover', 'PopupMenu', panel(secondary, 9, border))
	t.set_color('font_hover_color', 'PopupMenu', foreground)
	t.set_color('font_separator_color', 'PopupMenu', muted)
	t.set_stylebox('panel', 'PanelContainer', panel(Color(surface, 1.0 if opaque else 0.96), 22, border))
	t.set_stylebox('panel', 'Panel', panel(surface, 22, border))
	for definition in [['PrimaryButton', 'Button'], ['NavigationButton', 'Button'], ['NavigationSelected', 'NavigationButton'], ['NavigationPanel', 'PanelContainer'], ['HeroPanel', 'PanelContainer'], ['HUDPanel', 'PanelContainer']]:
		t.set_type_variation(definition[0], definition[1])
	for state in ['normal', 'hover', 'pressed', 'hover_pressed', 'disabled']:
		var fill := accent
		if state == 'hover': fill = accent.lightened(0.07)
		if state in ['pressed', 'hover_pressed']: fill = accent.darkened(0.08)
		if state == 'disabled': fill = surface.lerp(Color(colors.background), 0.35)
		var primary := panel(fill, 16, border)
		primary.content_margin_top = 13
		primary.content_margin_bottom = 13
		t.set_stylebox(state, 'PrimaryButton', primary)
		t.set_color('font_color' if state == 'normal' else 'font_' + state + '_color', 'PrimaryButton', AppearancePalette.readable_text(fill))
	t.set_color('font_focus_color', 'PrimaryButton', AppearancePalette.readable_text(accent))
	var primary_focus: StyleBoxFlat = focus.duplicate()
	# Foreground focus stays visible even when the chosen accent equals the button fill.
	primary_focus.border_color = AppearancePalette.readable_text(accent)
	t.set_stylebox('focus', 'PrimaryButton', primary_focus)
	var nav_panel := panel(Color(surface, 1.0 if opaque else 0.80), 44, border)
	nav_panel.content_margin_top = 6
	nav_panel.content_margin_bottom = 6
	nav_panel.content_margin_left = 8
	nav_panel.content_margin_right = 8
	nav_panel.shadow_color = Color(0, 0, 0, 0.22 if dark else 0.10)
	nav_panel.shadow_size = 16
	nav_panel.shadow_offset = Vector2(0, 5)
	nav_panel.border_width_top = 2
	t.set_stylebox('panel', 'NavigationPanel', nav_panel)
	for state in ['normal', 'hover', 'pressed', 'hover_pressed', 'disabled']:
		var fill := Color(0, 0, 0, 0)
		if state == 'hover': fill = Color(secondary, 1.0 if opaque else 0.72)
		if state in ['pressed', 'hover_pressed']: fill = secondary
		var box := panel(fill, 36, Color(0, 0, 0, 0))
		box.shadow_size = 0
		box.content_margin_left = 6
		box.content_margin_right = 6
		box.content_margin_top = 4
		box.content_margin_bottom = 4
		t.set_stylebox(state, 'NavigationButton', box)
		t.set_color('font_color' if state == 'normal' else 'font_' + state + '_color', 'NavigationButton', foreground)
	for state in ['normal', 'hover', 'pressed', 'hover_pressed']:
		var active := panel(secondary, 36, border)
		active.shadow_size = 0
		active.content_margin_top = 4
		active.content_margin_bottom = 4
		active.content_margin_left = 6
		active.content_margin_right = 6
		t.set_stylebox(state, 'NavigationSelected', active)
		t.set_color('font_color' if state == 'normal' else 'font_' + state + '_color', 'NavigationSelected', foreground)
	var nav_focus := panel(Color(0, 0, 0, 0), 36, focus_color)
	nav_focus.set_border_width_all(3)
	nav_focus.shadow_size = 0
	t.set_stylebox('focus', 'NavigationButton', nav_focus)
	var hero_panel := panel(secondary, 28, border)
	hero_panel.content_margin_left = 28
	hero_panel.content_margin_right = 28
	hero_panel.content_margin_top = 24
	hero_panel.content_margin_bottom = 24
	t.set_stylebox('panel', 'HeroPanel', hero_panel)
	var hud_panel := panel(surface, 16, border)
	hud_panel.content_margin_left = 12
	hud_panel.content_margin_right = 12
	hud_panel.content_margin_top = 10
	hud_panel.content_margin_bottom = 10
	hud_panel.shadow_size = 4
	t.set_stylebox('panel', 'HUDPanel', hud_panel)
	for entry in [['slider', foreground.lerp(surface, 0.80)], ['grabber_area', focus_color], ['grabber_area_highlight', focus_color]]:
		var track := StyleBoxFlat.new()
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
