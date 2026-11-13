class_name MenuArt
extends RefCounted
## Menyu fonlari: kechki osmon, quyosh, Registon uslubidagi siluet, adirlar. Hammasi kodda chiziladi.

const SKY_TOP := Color(0.24, 0.12, 0.2)
const SKY_MID := Color(0.86, 0.45, 0.25)
const SKY_LOW := Color(1.0, 0.78, 0.45)


static func backdrop(ci: CanvasItem, size: Vector2, t: float) -> void:
	var w := size.x
	var h := size.y
	var horizon := h * 0.7
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, horizon * 0.55), Vector2(0, horizon * 0.55)]),
		PackedColorArray([SKY_TOP, SKY_TOP, SKY_MID, SKY_MID]))
	ci.draw_polygon(PackedVector2Array([Vector2(0, horizon * 0.55), Vector2(w, horizon * 0.55), Vector2(w, horizon), Vector2(0, horizon)]),
		PackedColorArray([SKY_MID, SKY_MID, SKY_LOW, SKY_LOW]))
	# Quyosh va nurlar
	var sun := Vector2(w * 0.62, horizon - 40.0)
	for i in 12:
		var a := TAU * i / 12.0 + t * 0.05
		ci.draw_colored_polygon(PackedVector2Array([sun, sun + Vector2.from_angle(a - 0.08) * w, sun + Vector2.from_angle(a + 0.08) * w]), Color(1, 0.9, 0.6, 0.06))
	ci.draw_circle(sun, 120.0, Color(1, 0.88, 0.55, 0.3))
	ci.draw_circle(sun, 85.0, Color(1, 0.92, 0.7))
	# Bulutlar
	for i in 5:
		var cx := fmod(i * 330.0 + t * (6.0 + i), w + 300.0) - 150.0
		var cy := 60.0 + i * 37.0
		for k in 4:
			ci.draw_circle(Vector2(cx + k * 28.0, cy + (k % 2) * 6.0), 22.0 - absf(k - 1.5) * 4.0, Color(1, 0.85, 0.75, 0.22))
	# Uzoq tog'lar
	var pts := PackedVector2Array([Vector2(0, horizon)])
	for i in 21:
		var x := w * i / 20.0
		pts.append(Vector2(x, horizon - 70.0 - sin(i * 1.3) * 28.0 - sin(i * 0.47) * 22.0))
	pts.append(Vector2(w, horizon))
	ci.draw_colored_polygon(pts, Color(0.55, 0.3, 0.25, 0.85))
	registan(ci, Vector2(w * 0.62, horizon + 6.0), 1.0, Color(0.27, 0.13, 0.12))
	# Yer
	ci.draw_rect(Rect2(0, horizon, w, h - horizon), Color(0.36, 0.2, 0.12))
	ci.draw_rect(Rect2(0, horizon, w, 6), Color(0.45, 0.26, 0.15))
	for i in 40:
		var gx := fmod(i * 97.0, w)
		var gy := horizon + 20.0 + fmod(i * 53.0, h - horizon - 20.0)
		ci.draw_line(Vector2(gx, gy), Vector2(gx - 4, gy - 9), Color(0.5, 0.36, 0.2), 2.0)


static func registan(ci: CanvasItem, base: Vector2, s: float, col: Color) -> void:
	## Uch madrasali maydon siluetini eslatuvchi original kompozitsiya: peshtoqlar, gumbazlar, minoralar.
	for side in [-1, 0, 1]:
		var cx: float = base.x + side * 190.0 * s
		var bw := (150.0 if side == 0 else 120.0) * s
		var bh := (120.0 if side == 0 else 95.0) * s
		ci.draw_rect(Rect2(cx - bw * 0.5, base.y - bh, bw, bh), col)
		# Peshtoq (baland kirish ravog'i)
		var pw := bw * 0.5
		var ph := bh * 1.35
		ci.draw_rect(Rect2(cx - pw * 0.5, base.y - ph, pw, ph), col)
		var arch := PackedVector2Array()
		for i in 13:
			var a := PI + PI * i / 12.0
			arch.append(Vector2(cx + cos(a) * pw * 0.28, base.y - ph * 0.42 + sin(a) * pw * 0.42))
		arch.append(Vector2(cx + pw * 0.28, base.y))
		arch.append(Vector2(cx - pw * 0.28, base.y))
		ci.draw_colored_polygon(arch, col.lightened(0.18))
		# Gumbaz
		var dome_c := Vector2(cx + (bw * 0.3 if side != 0 else 0.0), base.y - bh - 4.0 * s)
		var dr := (32.0 if side == 0 else 24.0) * s
		var dome := PackedVector2Array()
		for i in 17:
			var a2 := PI + PI * i / 16.0
			dome.append(dome_c + Vector2(cos(a2) * dr, sin(a2) * dr * 1.25))
		ci.draw_colored_polygon(dome, col)
		ci.draw_line(dome_c + Vector2(0, -dr * 1.25), dome_c + Vector2(0, -dr * 1.25 - 12.0 * s), col, 3.0)
		# Minoralar
		for m in [-1, 1]:
			var mx: float = cx + m * (bw * 0.5 + 6.0 * s)
			var mh := bh * 1.6
			ci.draw_rect(Rect2(mx - 6.0 * s, base.y - mh, 12.0 * s, mh), col)
			ci.draw_rect(Rect2(mx - 9.0 * s, base.y - mh - 8.0 * s, 18.0 * s, 8.0 * s), col)
			ci.draw_circle(Vector2(mx, base.y - mh - 10.0 * s), 6.0 * s, col)
