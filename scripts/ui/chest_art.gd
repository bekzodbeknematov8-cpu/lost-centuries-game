class_name ChestArt
extends RefCounted
## Sandiq rasmi (kodda). open_k: 0 = yopiq, 1 = qopqoq to'liq ochiq.


static func draw(ci: CanvasItem, c: Vector2, s: float, col: Color, open_k := 0.0, glow := 0.0) -> void:
	var wood := Color(0.45, 0.25, 0.12)
	var dark := Color(0.22, 0.12, 0.06)
	if glow > 0.0:
		for i in 3:
			ci.draw_circle(c + Vector2(0, -20) * s, (60.0 + i * 22.0) * s, Color(1, 0.85, 0.4, 0.12 * glow))
	# Quti
	var body := Rect2(c + Vector2(-50, -10) * s, Vector2(100, 55) * s)
	ci.draw_rect(body, wood)
	ci.draw_rect(Rect2(body.position, Vector2(body.size.x, 8 * s)), wood.darkened(0.2))
	for x in [-50, -10, 30]:
		ci.draw_rect(Rect2(c + Vector2(x, -10) * s, Vector2(20, 55) * s), col)
	ci.draw_rect(body, dark, false, 3.0 * s)
	# Ichidan nur (ochilganda)
	if open_k > 0.0:
		ci.draw_rect(Rect2(c + Vector2(-46, -14) * s, Vector2(92, 6) * s), Color(1, 0.9, 0.5, open_k))
		for i in 5:
			var a := -PI * 0.5 + (i - 2) * 0.28
			ci.draw_line(c + Vector2(0, -12) * s, c + (Vector2(0, -12) + Vector2.from_angle(a) * 90.0 * open_k) * s, Color(1, 0.9, 0.5, 0.6 * open_k), 6.0 * s)
	# Qopqoq (yuqoriga ko'tariladi)
	var lid_y := -10.0 - 40.0 * open_k
	var lid := PackedVector2Array()
	for i in 13:
		var a2 := PI + PI * i / 12.0
		lid.append(c + Vector2(cos(a2) * 50.0, lid_y + sin(a2) * 26.0) * s)
	ci.draw_colored_polygon(lid, wood.lightened(0.08))
	ci.draw_polyline(lid, dark, 3.0 * s)
	for x2 in [-40.0, 0.0, 40.0]:
		var top_y := lid_y - sqrt(maxf(0.0, 1.0 - pow(x2 / 50.0, 2))) * 26.0
		ci.draw_line(c + Vector2(x2, lid_y) * s, c + Vector2(x2, top_y) * s, col, 10.0 * s)
	# Qulf
	if open_k < 0.5:
		ci.draw_rect(Rect2(c + Vector2(-9, -16) * s, Vector2(18, 20) * s), col.darkened(0.2))
		ci.draw_circle(c + Vector2(0, -8) * s, 3.0 * s, dark)
