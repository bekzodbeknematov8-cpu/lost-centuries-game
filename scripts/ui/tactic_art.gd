class_name TacticArt
extends RefCounted
## Hiyla ikonkalari (kodda chiziladi).


static func draw(ci: CanvasItem, icon: String, c: Vector2, s: float) -> void:
	var g := Painter.GOLD
	var ink := Color(0.25, 0.14, 0.06)
	match icon:
		"coin":
			for i in 3:
				ci.draw_circle(c + Vector2((i - 1) * 7.0, 5.0 - i * 5.0) * s, 9.0 * s, Color(0.7, 0.5, 0.1))
				ci.draw_circle(c + Vector2((i - 1) * 7.0, 5.0 - i * 5.0) * s, 7.0 * s, g)
		"pick":
			ci.draw_line(c + Vector2(-10, 12) * s, c + Vector2(6, -6) * s, Color(0.55, 0.35, 0.18), 4.0 * s)
			ci.draw_arc(c + Vector2(6, -6) * s, 11.0 * s, PI * 0.9, PI * 1.9, 8, Color(0.8, 0.82, 0.86), 4.0 * s)
			ci.draw_circle(c + Vector2(9, 9) * s, 4.0 * s, g)
		"heart":
			ci.draw_circle(c + Vector2(-5, -3) * s, 7.0 * s, Color(0.85, 0.2, 0.25))
			ci.draw_circle(c + Vector2(5, -3) * s, 7.0 * s, Color(0.85, 0.2, 0.25))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-11.5, 0) * s, c + Vector2(11.5, 0) * s, c + Vector2(0, 13) * s]), Color(0.85, 0.2, 0.25))
			ci.draw_line(c + Vector2(-4, -2) * s, c + Vector2(4, -2) * s, Color.WHITE, 2.5 * s)
			ci.draw_line(c + Vector2(0, -6) * s, c + Vector2(0, 2) * s, Color.WHITE, 2.5 * s)
		"shield":
			for i in 3:
				var o := Vector2((i - 1) * 9.0, 0) * s
				ci.draw_colored_polygon(PackedVector2Array([c + o + Vector2(-6, -11) * s, c + o + Vector2(6, -11) * s, c + o + Vector2(6, 3) * s, c + o + Vector2(0, 11) * s, c + o + Vector2(-6, 3) * s]), Color(0.3, 0.45, 0.75).lightened(i * 0.1))
		"drum":
			ci.draw_rect(Rect2(c + Vector2(-11, -6) * s, Vector2(22, 14) * s), Color(0.6, 0.3, 0.15))
			ci.draw_circle(c + Vector2(0, -6) * s, 11.0 * s, Color(0.95, 0.88, 0.7))
			ci.draw_line(c + Vector2(6, -16) * s, c + Vector2(14, -22) * s, ink, 3.0 * s)
		"tower":
			ci.draw_rect(Rect2(c + Vector2(-8, -8) * s, Vector2(16, 20) * s), Color(0.65, 0.6, 0.55))
			for i in 3:
				ci.draw_rect(Rect2(c + Vector2(-8 + i * 6, -12) * s, Vector2(4, 4) * s), Color(0.65, 0.6, 0.55))
			for i in 3:
				ci.draw_line(c + Vector2(10, -6 + i * 6) * s, c + Vector2(18, -10 + i * 6) * s, Color(0.85, 0.3, 0.25), 2.0 * s)
