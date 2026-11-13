class_name UITheme
extends RefCounted
## Yagona vizual uslub: charm va oltin ranglar, yumaloq burchaklar.

const PARCHMENT := Color(0.96, 0.89, 0.72)
const LEATHER := Color(0.28, 0.18, 0.11)
const ACCENT := Color(0.86, 0.6, 0.2)


static func box(bg: Color, border: Color, radius := 14, border_w := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	s.shadow_color = Color(0, 0, 0, 0.25)
	s.shadow_size = 4
	return s


static func make() -> Theme:
	var th := Theme.new()
	th.default_font_size = 22
	th.set_stylebox("normal", "Button", box(LEATHER, ACCENT))
	th.set_stylebox("hover", "Button", box(LEATHER.lightened(0.12), ACCENT.lightened(0.2)))
	th.set_stylebox("pressed", "Button", box(ACCENT.darkened(0.2), ACCENT.lightened(0.3)))
	th.set_stylebox("disabled", "Button", box(Color(0.25, 0.22, 0.2, 0.85), Color(0.4, 0.36, 0.3)))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", PARCHMENT)
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", Color.WHITE)
	th.set_color("font_disabled_color", "Button", Color(0.6, 0.55, 0.5))
	th.set_stylebox("panel", "PanelContainer", box(Color(0.18, 0.12, 0.08, 0.86), ACCENT, 16, 3))
	th.set_stylebox("panel", "Panel", box(Color(0.18, 0.12, 0.08, 0.86), ACCENT, 16, 3))
	th.set_color("font_color", "Label", PARCHMENT)
	th.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.8))
	th.set_constant("outline_size", "Label", 4)
	var bg := box(Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.6), 6, 2)
	bg.content_margin_top = 0
	bg.content_margin_bottom = 0
	th.set_stylebox("background", "ProgressBar", bg)
	return th


static func fill(col: Color) -> StyleBoxFlat:
	var s := box(col, col.lightened(0.3), 6, 0)
	s.shadow_size = 0
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	return s
