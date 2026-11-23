class_name Painter
extends RefCounted
## Barcha grafika kod orqali chiziladi (original "flat" uslub, tashqi rasm kerak emas).

const SKIN := Color(0.86, 0.66, 0.48)
const DARK := Color(0.16, 0.11, 0.08)
const STEEL := Color(0.78, 0.8, 0.84)
const WOOD := Color(0.48, 0.31, 0.16)
const GOLD := Color(1.0, 0.8, 0.25)

## O'yinchi libosi (Libos bo'limi): bo'sh bo'lsa standart ranglar ishlatiladi.
static var player_outfit: Array = []
static var style_v2 := true   ## Batafsilroq (realga yaqin) piyoda askar chizmasi

## Tomon ranglari: [ko'ylak, plash/bezak, shim, dubulg'a]
const TEAM_COLORS := [
	[Color(0.16, 0.42, 0.72), Color(0.95, 0.78, 0.25), Color(0.22, 0.2, 0.26)],
	[Color(0.72, 0.18, 0.16), Color(0.2, 0.17, 0.14), Color(0.3, 0.22, 0.18)],
]


static func team_colors(team: int) -> Array:
	if team == 0 and player_outfit.size() >= 4:
		return player_outfit
	return TEAM_COLORS[team]


static func outfit_colors(o: Dictionary) -> Array:
	var c := func(k: String) -> Color: return Color(o[k][0], o[k][1], o[k][2])
	return [c.call("tunic"), c.call("trim"), c.call("pants"), c.call("helm")]


static func draw_unit(ci: CanvasItem, u: UnitState, pos: Vector2, scale_f: float, t: float) -> void:
	var alpha := 1.0
	var rot := 0.0
	var sy := 1.0
	if not u.is_alive():
		# Tabiiyroq yiqilish: orqaga biroz uchib, yerga tushib, bir marta sakraydi (qonsiz)
		var k := clampf(u.dead_time / 0.45, 0.0, 1.0)
		var ease := 1.0 - pow(1.0 - k, 3.0)
		rot = -ease * PI * 0.5
		pos += Vector2(-u.facing * 14.0 * ease, 0.0) * scale_f
		if u.dead_time > 0.45 and u.dead_time < 0.65:
			pos.y -= sin((u.dead_time - 0.45) / 0.2 * PI) * 4.0 * scale_f
		alpha = clampf(1.0 - (u.dead_time - 1.6) / 1.2, 0.0, 1.0)
	elif style_v2:
		if u.hurt_flash > 0.0:
			# Zarba yeganda chayqalish: orqaga og'ish va siljish
			var hk := u.hurt_flash / 0.15
			rot = -0.12 * hk
			pos.x -= u.facing * 4.0 * hk * scale_f
		elif not u.moving and u.attack_anim <= 0.0:
			# Nafas olish: turgan askar biroz ko'tarilib-tushadi
			sy = 1.0 + sin(t * 2.4 + float(u.id) * 1.7) * 0.015
			if u.cooldown > 0.0 and u.cooldown < 0.25 and not u.is_ranged() and not u.is_worker():
				# Zarbadan oldin shaylanish: orqaga tortilish
				rot = -0.07
	var cols: Array = team_colors(u.team)
	var flash := u.hurt_flash > 0.0
	ci.draw_set_transform(pos, rot * u.facing, Vector2(u.facing * scale_f, scale_f * sy))
	var walk := sin(u.walk_phase) if u.moving else 0.0
	var swing := 0.0
	if u.attack_anim > 0.0:
		swing = sin((1.0 - u.attack_anim / 0.35) * PI)
	if u.type == "elephant":
		_draw_elephant(ci, u, cols, walk, swing, alpha, flash, t)
	elif is_mounted(u):
		_draw_horse(ci, u, walk, alpha, t)
		ci.draw_set_transform(pos + Vector2(0, -34 * scale_f).rotated(rot * u.facing), rot * u.facing, Vector2(u.facing * scale_f, scale_f))
		if u.hero:
			_draw_cape(ci, u, alpha, t)
		_draw_rider(ci, u, cols, swing, alpha, flash)
	else:
		_draw_person(ci, u, cols, walk, swing, alpha, flash, t)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if u.is_alive() and u.stun > 0.0:
		var top := pos + Vector2(0, unit_top(u) * scale_f)
		for i in 3:
			var ang := t * 5.0 + i * TAU / 3.0
			_star(ci, top + Vector2(cos(ang) * 14.0, sin(ang) * 4.0), 4.0, Color(1, 0.9, 0.3))


static func unit_top(u: UnitState) -> float:
	## Askar boshining tepasi (hayrat yulduzchalari va HP chizig'i uchun).
	if u.type == "elephant":
		return -150.0
	return -118.0 if is_mounted(u) else -95.0


static func _draw_elephant(ci: CanvasItem, u: UnitState, cols: Array, walk: float, swing: float, a: float, flash: bool, t: float) -> void:
	## Jangovar fil: kulrang tana, xartumi, oq qoziq tishlari, ustida jamoa rangidagi kajava va fil haydovchi.
	var skin := Color(0.52, 0.5, 0.5)
	var dark := skin.darkened(0.25)
	# Oyoqlar (yurganda navbatma-navbat)
	for i in 4:
		var lx := -32.0 + i * 20.0
		var off := walk * 6.0 * (1.0 if i % 2 == 0 else -1.0)
		ci.draw_rect(Rect2(Vector2(lx + off - 7, -38), Vector2(15, 38)), _c(dark if i % 2 == 0 else skin, a, flash))
	# Tana
	var body := PackedVector2Array()
	for i in 20:
		var ang := TAU * i / 20.0
		body.append(Vector2(-6 + cos(ang) * 48.0, -62 + sin(ang) * 30.0))
	ci.draw_colored_polygon(body, _c(skin, a, flash))
	if style_v2:
		# Qorin soyasi, terining burmalari, kontur
		var belly := PackedVector2Array()
		for i in 11:
			var ang2 := PI * i / 10.0
			belly.append(Vector2(-6 + cos(ang2) * 46.0, -62 + sin(ang2) * 28.0))
		ci.draw_colored_polygon(belly, _c(dark, a * 0.6))
		for w in 3:
			ci.draw_arc(Vector2(-22 + w * 16, -60), 12.0, PI * 0.2, PI * 0.8, 6, _c(dark.darkened(0.1), a * 0.6), 1.5)
		var ob := body.duplicate()
		ob.append(body[0])
		ci.draw_polyline(ob, _c(DARK, a * 0.55), 1.8, true)
	# Bosh va quloq
	ci.draw_circle(Vector2(40, -74), 20.0, _c(skin, a, flash))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(30, -88), Vector2(18, -84), Vector2(16, -62), Vector2(28, -58)]), _c(dark, a, flash))
	ci.draw_circle(Vector2(48, -80), 2.2, _c(DARK, a))
	# Xartum (hujumda ko'tariladi)
	var tr_end := Vector2(62, -30).lerp(Vector2(78, -92), swing)
	ci.draw_polyline(PackedVector2Array([Vector2(54, -70), Vector2(60, -52).lerp(Vector2(70, -80), swing), tr_end]), _c(skin, a, flash), 9.0, true)
	# Qoziq tishlar
	ci.draw_line(Vector2(50, -62), Vector2(68, -50), _c(Color(0.97, 0.95, 0.88), a), 4.0, true)
	# Kajava (jamoa rangida) va haydovchi
	var tunic: Color = cols[0]
	var trim: Color = cols[1]
	ci.draw_rect(Rect2(Vector2(-34, -100), Vector2(46, 14)), _c(trim, a))
	ci.draw_rect(Rect2(Vector2(-30, -116), Vector2(38, 18)), _c(tunic, a, flash))
	ci.draw_line(Vector2(-30, -116), Vector2(8, -116), _c(GOLD, a), 3.0)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-36, -84), Vector2(14, -84), Vector2(18, -60), Vector2(-40, -60)]), _c(tunic.darkened(0.15), a))
	ci.draw_line(Vector2(-38, -72), Vector2(16, -72), _c(trim, a), 3.0)
	var head := Vector2(-11, -126)
	ci.draw_circle(head, 7.5, _c(SKIN, a, flash))
	_draw_headgear(ci, "archer", head, cols, a)


static func is_mounted(u: UnitState) -> bool:
	return u.type == "cavalry" or bool(u.def.get("mount", false))


static func _star(ci: CanvasItem, p: Vector2, r: float, c: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(p + Vector2.from_angle(-PI / 2 + i * PI / 5) * rr)
	ci.draw_colored_polygon(pts, c)


static func _look_color(u: UnitState, key: String, fallback: Color) -> Color:
	var look: Dictionary = u.def.get("look", {})
	if look.has(key):
		var a: Array = look[key]
		return Color(a[0], a[1], a[2])
	return fallback


static func _draw_cape(ci: CanvasItem, u: UnitState, a: float, t: float) -> void:
	var c := _look_color(u, "cape", Color(0.5, 0.1, 0.1))
	var wave := sin(t * 6.0) * 4.0
	var flow := 1.0 if u.moving else 0.4
	var pts := PackedVector2Array([Vector2(-4, -40), Vector2(6, -40), Vector2(-14, -14 + wave), Vector2(-34 * flow - 8, -8 - wave), Vector2(-22 * flow - 6, -30)])
	ci.draw_colored_polygon(pts, _c(c, a))


static func _limb(ci: CanvasItem, a0: Vector2, a1: Vector2, a2: Vector2, w: float, col: Color, a: float, flash: bool) -> void:
	## Ikki bo'g'imli a'zo (son-boldir yoki yelka-bilak) va bo'g'imdagi yumaloqlik, qora chegara bilan.
	ci.draw_line(a0, a1, _c(DARK, a * 0.55), w + 2.5, true)
	ci.draw_line(a1, a2, _c(DARK, a * 0.55), w + 2.5, true)
	ci.draw_line(a0, a1, _c(col, a, flash), w, true)
	ci.draw_line(a1, a2, _c(col.darkened(0.08), a, flash), w * 0.9, true)
	ci.draw_circle(a1, w * 0.5, _c(col, a, flash))


static func _draw_body_v2(ci: CanvasItem, u: UnitState, cols: Array, walk: float, a: float, flash: bool) -> void:
	## Batafsilroq piyoda: tizzalari bukiladigan oyoqlar, soyali to'n, kamar, sovut (askarlarda), yuz va soqol.
	var tunic: Color = cols[0]
	var trim: Color = cols[1]
	var pants: Color = cols[2]
	var boot := Color(0.24, 0.16, 0.1)
	var hip := Vector2(0, -31)
	# Oyoqlar: qadam fazasiga qarab tizza bukiladi (orqa oyoq qoraroq)
	for side: float in [-1.0, 1.0]:
		var ph: float = walk * side
		var foot := Vector2(ph * 12.0, 0)
		var knee := Vector2(ph * 5.0 + 3.0, -15.0 - absf(ph) * 2.5)
		var pc: Color = pants if side > 0 else pants.darkened(0.25)
		_limb(ci, hip, knee, foot + Vector2(0, -5), 6.5, pc, a, flash)
		# Etik
		ci.draw_colored_polygon(PackedVector2Array([foot + Vector2(-3, -9), foot + Vector2(4, -9), foot + Vector2(9, 0), foot + Vector2(-4, 0)]), _c(boot if side > 0 else boot.darkened(0.2), a))
	# Orqa qo'l (soyada)
	var shoulder := Vector2(0, -54)
	_limb(ci, shoulder + Vector2(-4, 1), shoulder + Vector2(-9, 13), shoulder + Vector2(-6, 24), 5.0, tunic.darkened(0.35), a, flash)
	# To'n: old (yorug') va orqa (soya) qismlar, etak kengroq
	var back := PackedVector2Array([Vector2(-11, -59), Vector2(2, -59), Vector2(0, -22), Vector2(-15, -24)])
	var front := PackedVector2Array([Vector2(1, -59), Vector2(11, -58), Vector2(15, -23), Vector2(-1, -22)])
	ci.draw_colored_polygon(back, _c(tunic.darkened(0.22), a, flash))
	ci.draw_colored_polygon(front, _c(tunic, a, flash))
	var outline := PackedVector2Array([Vector2(-11, -59), Vector2(11, -58), Vector2(15, -23), Vector2(-15, -24), Vector2(-11, -59)])
	ci.draw_polyline(outline, _c(DARK, a * 0.6), 1.5, true)
	# Yoqa va old hoshiya
	ci.draw_line(Vector2(-6, -59), Vector2(4, -46), _c(trim, a), 2.5)
	ci.draw_line(Vector2(4, -46), Vector2(3, -24), _c(trim.darkened(0.1), a), 2.0)
	# Sovut plastinkalari (jangchilarda)
	if u.type in ["swordsman", "spearman"]:
		for r in 3:
			var y := -55.0 + r * 6.0
			for c in 4:
				var x := -9.0 + c * 5.0 + (2.5 if r % 2 == 1 else 0.0)
				ci.draw_rect(Rect2(Vector2(x, y), Vector2(4.2, 5.0)), _c(STEEL.darkened(0.15 + 0.05 * (c % 2)), a, flash))
		ci.draw_line(Vector2(-11, -38), Vector2(12, -38), _c(DARK, a * 0.4), 1.0)
	# Kamar va to'qa
	ci.draw_line(Vector2(-13, -33), Vector2(13, -32), _c(Color(0.35, 0.22, 0.12), a), 4.0)
	ci.draw_rect(Rect2(Vector2(1, -35), Vector2(4, 5)), _c(GOLD.darkened(0.15), a))
	# Bo'yin va bosh: soyali yuz, burun, ko'z, mo'ylov/soqol
	var head := Vector2(1, -67)
	ci.draw_rect(Rect2(head + Vector2(-2.5, 5), Vector2(5, 5)), _c(SKIN.darkened(0.15), a, flash))
	ci.draw_circle(head, 8.8, _c(DARK, a * 0.5))
	ci.draw_circle(head, 8.2, _c(SKIN, a, flash))
	ci.draw_circle(head + Vector2(-2.5, 1.5), 6.0, _c(SKIN.darkened(0.08), a * 0.6, flash))
	ci.draw_colored_polygon(PackedVector2Array([head + Vector2(7.5, -1), head + Vector2(10.5, 2.5), head + Vector2(7.5, 3)]), _c(SKIN.darkened(0.12), a, flash))
	ci.draw_circle(head + Vector2(4.5, -1.5), 1.3, _c(DARK, a))
	ci.draw_line(head + Vector2(3, -4), head + Vector2(6.5, -4.3), _c(DARK, a * 0.8), 1.2)
	if u.type != "worker" or u.id % 2 == 0:
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(1, 4), head + Vector2(8, 4.5), head + Vector2(5, 10), head + Vector2(1, 8)]), _c(Color(0.22, 0.15, 0.1), a))
	ci.draw_line(head + Vector2(4, 4), head + Vector2(9, 5.5), _c(Color(0.2, 0.13, 0.08), a), 1.6)


static func _c(c: Color, a: float, flash := false) -> Color:
	var out := c.lerp(Color.WHITE, 0.6) if flash else c
	out.a *= a
	return out


static func _draw_person(ci: CanvasItem, u: UnitState, cols: Array, walk: float, swing: float, a: float, flash: bool, t: float) -> void:
	var tunic: Color = cols[0]
	var trim: Color = cols[1]
	var pants: Color = cols[2]
	var shoulder := Vector2(0, -54)
	var head := Vector2(1, -67)
	if style_v2:
		_draw_body_v2(ci, u, cols, walk, a, flash)
	else:
		# Oyoqlar
		var hip := Vector2(0, -30)
		ci.draw_line(hip, Vector2(walk * 11.0, 0), _c(pants, a), 6.0, true)
		ci.draw_line(hip, Vector2(-walk * 11.0, 0), _c(pants.darkened(0.25), a), 6.0, true)
		ci.draw_circle(Vector2(walk * 11.0 + 2, -1), 3.5, _c(DARK, a))
		ci.draw_circle(Vector2(-walk * 11.0 + 2, -1), 3.5, _c(DARK, a))
		# Orqa qo'l
		ci.draw_line(shoulder, shoulder + Vector2(-8, 18), _c(tunic.darkened(0.3), a, flash), 5.0, true)
		# Gavda (to'n)
		var body := PackedVector2Array([Vector2(-10, -58), Vector2(10, -58), Vector2(13, -26), Vector2(-13, -26)])
		ci.draw_colored_polygon(body, _c(tunic, a, flash))
		ci.draw_line(Vector2(-12, -34), Vector2(12, -34), _c(trim, a), 3.0)
		ci.draw_line(Vector2(0, -58), Vector2(0, -34), _c(trim.darkened(0.1), a), 2.0)
		# Bosh
		ci.draw_circle(head, 8.5, _c(SKIN, a, flash))
		ci.draw_circle(head + Vector2(4, -1), 1.3, _c(DARK, a))
	_draw_headgear(ci, u.type, head, cols, a)
	# Qurol va old qo'l
	match u.type:
		"worker":
			var ang := lerpf(-1.9, 0.5, swing)
			var hand := shoulder + Vector2(10, 8)
			ci.draw_line(shoulder, hand, _c(SKIN, a, flash), 5.0, true)
			var tip := hand + Vector2.from_angle(ang) * 30.0
			ci.draw_line(hand, tip, _c(WOOD, a), 3.5, true)
			var perp := Vector2.from_angle(ang + PI * 0.5) * 9.0
			ci.draw_line(tip - perp, tip + perp, _c(STEEL.darkened(0.3), a), 4.0, true)
			if u.carrying > 0:
				ci.draw_circle(Vector2(-12, -46), 9.0, _c(Color(0.62, 0.48, 0.3), a))
				ci.draw_circle(Vector2(-12, -52), 3.0, _c(GOLD, a))
		"swordsman":
			var ang2 := lerpf(-2.2, 0.35, swing)
			var hand2 := shoulder + Vector2(9, 10)
			ci.draw_line(shoulder, hand2, _c(SKIN, a, flash), 5.0, true)
			var dir2 := Vector2.from_angle(ang2)
			ci.draw_line(hand2, hand2 + dir2 * 34.0, _c(STEEL, a), 4.0, true)
			ci.draw_line(hand2 - dir2.orthogonal() * 6.0, hand2 + dir2.orthogonal() * 6.0, _c(GOLD, a), 3.0)
			# Kichik dumaloq qalqon orqada
			ci.draw_circle(Vector2(-11, -44), 9.0, _c(trim.darkened(0.2), a))
			ci.draw_circle(Vector2(-11, -44), 3.0, _c(STEEL, a))
		"spearman":
			var thrust := swing * 16.0
			var hand3 := shoulder + Vector2(8 + thrust, 6)
			ci.draw_line(shoulder, hand3, _c(SKIN, a, flash), 5.0, true)
			ci.draw_line(hand3 + Vector2(-30, 3), hand3 + Vector2(44, -3), _c(WOOD, a), 3.5, true)
			ci.draw_colored_polygon(PackedVector2Array([hand3 + Vector2(44, -7), hand3 + Vector2(58, -3.5), hand3 + Vector2(44, 1)]), _c(STEEL, a))
			# Katta qalqon oldinda
			var sh := PackedVector2Array([Vector2(8, -60), Vector2(20, -56), Vector2(20, -30), Vector2(8, -24), Vector2(-2, -30), Vector2(-2, -56)])
			ci.draw_colored_polygon(sh, _c(trim, a))
			ci.draw_polyline(sh + PackedVector2Array([sh[0]]), _c(DARK, a * 0.6), 2.0)
			ci.draw_circle(Vector2(9, -42), 3.5, _c(tunic, a))
		"archer":
			var draw_k := 1.0 - clampf(u.cooldown / maxf(0.01, float(u.def.cooldown)), 0.0, 1.0)
			var bow_c := shoulder + Vector2(18, 2)
			ci.draw_line(shoulder, bow_c, _c(SKIN, a, flash), 5.0, true)
			ci.draw_arc(bow_c, 20.0, -1.3, 1.3, 14, _c(WOOD, a), 3.5, true)
			var top := bow_c + Vector2.from_angle(-1.3) * 20.0
			var bot := bow_c + Vector2.from_angle(1.3) * 20.0
			var pull := bow_c + Vector2(-6.0 - 10.0 * draw_k, 0)
			ci.draw_line(top, pull, _c(Color(0.9, 0.9, 0.85), a), 1.2)
			ci.draw_line(pull, bot, _c(Color(0.9, 0.9, 0.85), a), 1.2)
			if draw_k > 0.3:
				ci.draw_line(pull, pull + Vector2(30, 0), _c(WOOD.lightened(0.2), a), 2.0)
			ci.draw_line(shoulder, pull, _c(SKIN.darkened(0.1), a, flash), 4.0, true)
			# O'qdon
			ci.draw_rect(Rect2(-14, -60, 7, 22), _c(WOOD.darkened(0.2), a))
		"musketeer":
			# Uzun miltiq: yog'och qo'ndoq va po'lat stvol; o'q uzganda chaqnash va tutun
			var recoil := swing * 4.0
			var hand4 := shoulder + Vector2(10 - recoil, 6)
			ci.draw_line(shoulder, hand4, _c(SKIN, a, flash), 5.0, true)
			ci.draw_line(hand4 + Vector2(-16, 4), hand4 + Vector2(8, 0), _c(WOOD, a), 5.0, true)
			ci.draw_line(hand4 + Vector2(6, 0), hand4 + Vector2(46, -3), _c(STEEL.darkened(0.2), a), 3.0, true)
			if u.attack_anim > 0.2:
				var mz := hand4 + Vector2(50, -3)
				ci.draw_circle(mz, 6.0, _c(Color(1.0, 0.85, 0.4), a))
				ci.draw_circle(mz + Vector2(8, -4), 9.0, _c(Color(0.75, 0.73, 0.7, 0.6), a))
			# Porox xaltasi
			ci.draw_circle(Vector2(-10, -36), 5.0, _c(WOOD.darkened(0.3), a))
	if u.controlled and u.is_alive():
		var pulse := 0.6 + 0.4 * sin(t * 6.0)
		ci.draw_arc(Vector2(0, 2), 22.0, 0, TAU, 24, Color(1, 0.85, 0.2, pulse), 3.0)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-7, -96), Vector2(7, -96), Vector2(0, -86)]), Color(1, 0.85, 0.2, pulse))


static func _draw_hero_head(ci: CanvasItem, u: UnitState, head: Vector2, a: float) -> void:
	var look: Dictionary = u.def.get("look", {})
	var plume := _look_color(u, "plume", Color.WHITE)
	match str(look.get("helm", "")):
		"fur":
			# Mo'g'ulcha mo'ynali qalpoq va uchli tepa
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-9, -3), head + Vector2(9, -3), head + Vector2(6, -14), head + Vector2(0, -24), head + Vector2(-6, -14)]), _c(Color(0.6, 0.12, 0.1), a))
			ci.draw_line(head + Vector2(-11, -3), head + Vector2(11, -3), _c(Color(0.45, 0.32, 0.2), a), 6.0)
			ci.draw_line(head + Vector2(0, -24), head + Vector2(0, -32), _c(GOLD, a), 2.5)
			ci.draw_line(head + Vector2(0, -30), head + Vector2(-8, -24), _c(plume, a), 3.0)
		"turban_helm":
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-9.5, -2), head + Vector2(9.5, -2), head + Vector2(4, -13), head + Vector2(0, -22), head + Vector2(-4, -13)]), _c(STEEL, a))
			ci.draw_line(head + Vector2(-10, -4), head + Vector2(10, -4), _c(Color(0.95, 0.95, 0.9), a), 6.0)
			ci.draw_line(head + Vector2(0, -22), head + Vector2(-6, -30), _c(Color(0.15, 0.6, 0.35), a), 4.0)
		"gold_dome":
			ci.draw_circle(head + Vector2(0, -5), 10.0, _c(GOLD.darkened(0.05), a))
			ci.draw_rect(Rect2(head + Vector2(-10.5, -5), Vector2(21, 5)), _c(Color(0.15, 0.3, 0.7), a))
			ci.draw_line(head + Vector2(0, -15), head + Vector2(0, -22), _c(GOLD, a), 3.0)
			ci.draw_circle(head + Vector2(0, -23), 2.5, _c(Color(0.9, 0.2, 0.2), a))
			ci.draw_line(head + Vector2(0, -21), head + Vector2(-9, -27), _c(plume, a), 3.0)
		"seljuk_cap":
			# Baland uchli qalpoq, oltin hoshiya va orqaga tushuvchi lenta
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-10, -3), head + Vector2(10, -3), head + Vector2(5, -18), head + Vector2(1, -29), head + Vector2(-4, -18)]), _c(Color(0.62, 0.16, 0.12), a))
			ci.draw_line(head + Vector2(-11, -4), head + Vector2(11, -4), _c(GOLD, a), 4.0)
			ci.draw_circle(head + Vector2(1, -29), 2.5, _c(GOLD, a))
			ci.draw_line(head + Vector2(-9, -5), head + Vector2(-16, 8), _c(plume, a), 3.0)
			ci.draw_line(head + Vector2(-7, -5), head + Vector2(-13, 10), _c(plume.darkened(0.15), a), 2.5)
		"bobur_turban":
			# Temuriylar uslubidagi yashil salla, oq bog'ich va oltin jig'a
			var tp := PackedVector2Array()
			for i in 18:
				var ang := TAU * i / 18.0
				tp.append(head + Vector2(cos(ang) * 11.5, -11.0 + sin(ang) * 9.0))
			ci.draw_colored_polygon(tp, _c(Color(0.12, 0.45, 0.28), a))
			ci.draw_line(head + Vector2(-11, -8), head + Vector2(11, -14), _c(Color(0.96, 0.94, 0.86), a), 3.0)
			ci.draw_line(head + Vector2(-10, -14), head + Vector2(10, -8), _c(Color(0.96, 0.94, 0.86), a), 2.0)
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-3, -19), head + Vector2(3, -19), head + Vector2(0, -25)]), _c(GOLD, a))
			ci.draw_circle(head + Vector2(0, -18), 2.5, _c(Color(0.85, 0.15, 0.2), a))
			ci.draw_line(head + Vector2(1, -22), head + Vector2(-5, -32), _c(plume, a), 2.5)
		"white_turban":
			var pts := PackedVector2Array()
			for i in 18:
				var ang := TAU * i / 18.0
				pts.append(head + Vector2(cos(ang) * 11.0, -12.0 + sin(ang) * 11.0))
			ci.draw_colored_polygon(pts, _c(Color(0.97, 0.96, 0.92), a))
			ci.draw_circle(head + Vector2(0, -20), 4.0, _c(Color(0.75, 0.12, 0.12), a))
			ci.draw_line(head + Vector2(3, -14), head + Vector2(6, -27), _c(plume, a), 2.5)
			ci.draw_circle(head + Vector2(3, -13), 2.0, _c(Color(0.2, 0.6, 0.9), a))
		_:
			_draw_headgear(ci, "cavalry", head, team_colors(u.team), a)


static func _draw_headgear(ci: CanvasItem, type: String, head: Vector2, cols: Array, a: float) -> void:
	var trim: Color = cols[1]
	match type:
		"worker":
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-9, -3), head + Vector2(9, -3), head + Vector2(5, -11), head + Vector2(-6, -11)]), _c(Color(0.55, 0.42, 0.28), a))
		"musketeer":
			# Baland kigiz qalpoq
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-9, -2), head + Vector2(9, -2), head + Vector2(7, -20), head + Vector2(-5, -22)]), _c(trim.darkened(0.15), a))
			ci.draw_line(head + Vector2(-10, -3), head + Vector2(10, -3), _c(cols[0].darkened(0.3), a), 4.0)
		"archer":
			# Mo'ynali qalpoq
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-10, -2), head + Vector2(10, -2), head + Vector2(6, -14), head + Vector2(-4, -15)]), _c(cols[0].darkened(0.35), a))
			ci.draw_line(head + Vector2(-10, -2), head + Vector2(10, -2), _c(Color(0.75, 0.68, 0.55), a), 4.0)
		_:
			# Uchli dubulg'a va pat
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-9.5, -1), head + Vector2(9.5, -1), head + Vector2(5, -10), head + Vector2(0, -19), head + Vector2(-5, -10)]), _c(cols[3] if cols.size() > 3 else STEEL.darkened(0.15), a))
			ci.draw_line(head + Vector2(0, -19), head + Vector2(-4, -26), _c(trim, a), 3.0)
			ci.draw_line(head + Vector2(-9, 0), head + Vector2(-10, 7), _c(STEEL.darkened(0.3), a), 3.0)
			if style_v2:
				# Dubulg'a yaltirashi va bo'yinni yopuvchi to'r (kolchuga)
				ci.draw_line(head + Vector2(-5, -6), head + Vector2(-1, -15), _c(Color(1, 1, 1, 0.55), a), 2.0)
				ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-9.5, -1), head + Vector2(-3, -1), head + Vector2(-4, 8), head + Vector2(-10, 6)]), _c(STEEL.darkened(0.35), a))


static func _draw_horse(ci: CanvasItem, u: UnitState, walk: float, a: float, t: float) -> void:
	var coat := Color(0.45, 0.3, 0.2) if u.team == 0 else Color(0.25, 0.2, 0.18)
	match u.type:
		"chingiz": coat = Color(0.78, 0.76, 0.72)
		"jaloliddin": coat = Color(0.15, 0.12, 0.12)
		"temur": coat = Color(0.55, 0.3, 0.15)
		"boyazid": coat = Color(0.92, 0.9, 0.86)
		"bobur": coat = Color(0.4, 0.22, 0.12)
		"alp": coat = Color(0.62, 0.52, 0.4)
	var gallop := u.walk_phase * 1.3 if u.moving else 0.0
	var legs: Array[Vector2] = [Vector2(-22, -26), Vector2(-15, -26), Vector2(15, -26), Vector2(22, -26)]
	for i in 4:
		var ph := gallop + i * 1.4
		var swingx := sin(ph) * 9.0 if u.moving else 0.0
		var knee := legs[i] + Vector2(swingx * 0.5, 13)
		var hoof := legs[i] + Vector2(swingx, 26)
		var col := coat.darkened(0.25 if i % 2 == 0 else 0.0)
		if style_v2:
			_limb(ci, legs[i], knee, hoof + Vector2(0, -3), 5.0, col, a, u.hurt_flash > 0.0)
			ci.draw_colored_polygon(PackedVector2Array([hoof + Vector2(-3, -4), hoof + Vector2(4, -4), hoof + Vector2(5, 1), hoof + Vector2(-3, 1)]), _c(DARK, a))
		else:
			ci.draw_line(legs[i], knee, _c(col, a), 5.0, true)
			ci.draw_line(knee, hoof, _c(col, a), 4.0, true)
			ci.draw_circle(hoof, 2.5, _c(DARK, a))
	var bob := sin(gallop * 2.0) * 2.0 if u.moving else 0.0
	var body := PackedVector2Array()
	for i in 20:
		var ang := TAU * i / 20.0
		body.append(Vector2(cos(ang) * 30.0, -36 + bob + sin(ang) * 12.0))
	ci.draw_colored_polygon(body, _c(coat, a, u.hurt_flash > 0.0))
	# Bo'yin va bosh
	var neck := PackedVector2Array([Vector2(20, -42 + bob), Vector2(30, -66 + bob), Vector2(40, -64 + bob), Vector2(32, -38 + bob)])
	ci.draw_colored_polygon(neck, _c(coat, a, u.hurt_flash > 0.0))
	var headp := PackedVector2Array([Vector2(30, -68 + bob), Vector2(50, -58 + bob), Vector2(48, -52 + bob), Vector2(32, -58 + bob)])
	ci.draw_colored_polygon(headp, _c(coat.darkened(0.1), a))
	if style_v2:
		# Kontur, qorin soyasi, orqa yaltirashi
		var outl := body.duplicate()
		outl.append(body[0])
		ci.draw_polyline(outl, _c(DARK, a * 0.55), 1.6, true)
		var belly := PackedVector2Array()
		for i in 11:
			var ang := PI * i / 10.0
			belly.append(Vector2(cos(ang) * 28.0, -36 + bob + sin(ang) * 11.0))
		ci.draw_colored_polygon(belly, _c(coat.darkened(0.18), a * 0.7))
		ci.draw_arc(Vector2(-4, -36 + bob), 24.0, PI * 1.15, PI * 1.6, 8, _c(coat.lightened(0.25), a * 0.7), 2.5)
		var hp2 := headp.duplicate()
		hp2.append(headp[0])
		ci.draw_polyline(hp2, _c(DARK, a * 0.55), 1.4, true)
		# Ko'z, burun teshigi, quloq, jilov
		ci.draw_circle(Vector2(38, -63 + bob), 1.6, _c(DARK, a))
		ci.draw_circle(Vector2(48, -56 + bob), 1.2, _c(DARK, a * 0.8))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(31, -67 + bob), Vector2(33, -75 + bob), Vector2(36, -67 + bob)]), _c(coat.darkened(0.2), a))
		ci.draw_line(Vector2(44, -57 + bob), Vector2(12, -50 + bob), _c(Color(0.3, 0.18, 0.1), a), 1.5)
		# Yol (bo'yindagi qora tuklar)
		for k in 5:
			var mp := Vector2(22, -48 + bob).lerp(Vector2(31, -70 + bob), k / 4.0)
			ci.draw_line(mp, mp + Vector2(-6, 3 + sin(t * 6.0 + k) * 1.5), _c(DARK, a), 3.0, true)
		# Dum: shamolda tebranuvchi to'liq dum
		var sw := sin(t * 7.0) * 3.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-28, -44 + bob), Vector2(-24, -38 + bob), Vector2(-36, -16 + bob + sw), Vector2(-44, -20 + bob + sw)]), _c(DARK.lightened(0.05), a))
	else:
		ci.draw_line(Vector2(22, -48 + bob), Vector2(30, -70 + bob), _c(DARK, a), 4.0)
		# Dum
		ci.draw_line(Vector2(-29, -40 + bob), Vector2(-40, -22 + bob + sin(t * 8.0) * 3.0), _c(DARK, a), 5.0, true)
	# Egar yopqichi
	var cols: Array = team_colors(u.team)
	ci.draw_rect(Rect2(-12, -48 + bob, 24, 12), _c(cols[1], a))
	if u.hero:
		# Bezakli yopqich (bayroq rangi va oltin hoshiya)
		var cape := _look_color(u, "cape", cols[0])
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-26, -44 + bob), Vector2(14, -44 + bob), Vector2(10, -24 + bob), Vector2(-22, -24 + bob)]), _c(cape, a))
		ci.draw_line(Vector2(-22, -24 + bob), Vector2(10, -24 + bob), _c(GOLD, a), 2.5)
		for i in 4:
			ci.draw_circle(Vector2(-18 + i * 8, -22 + bob), 2.0, _c(GOLD, a))


static func _draw_rider(ci: CanvasItem, u: UnitState, cols: Array, swing: float, a: float, flash: bool) -> void:
	var tunic: Color = cols[0]
	var head := Vector2(1, -50)
	if style_v2:
		# Oyoq uzangida, etik bilan
		_limb(ci, Vector2(-2, -14), Vector2(8, -2), Vector2(4, 10), 6.0, cols[2], a, flash)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(1, 6), Vector2(8, 6), Vector2(11, 13), Vector2(0, 13)]), _c(Color(0.24, 0.16, 0.1), a))
		# Soyali gavda va kontur
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-9, -43), Vector2(1, -43), Vector2(0, -12), Vector2(-11, -12)]), _c(tunic.darkened(0.22), a, flash))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -43), Vector2(9, -42), Vector2(11, -12), Vector2(-1, -12)]), _c(tunic, a, flash))
		ci.draw_polyline(PackedVector2Array([Vector2(-9, -43), Vector2(9, -42), Vector2(11, -12), Vector2(-11, -12), Vector2(-9, -43)]), _c(DARK, a * 0.6), 1.5, true)
		ci.draw_line(Vector2(-10, -24), Vector2(10, -23), _c(Color(0.35, 0.22, 0.12), a), 3.5)
		ci.draw_line(Vector2(-4, -43), Vector2(4, -30), _c(cols[1], a), 2.5)
		# Yuz
		ci.draw_rect(Rect2(head + Vector2(-2.5, 5), Vector2(5, 5)), _c(SKIN.darkened(0.15), a, flash))
		ci.draw_circle(head, 8.6, _c(DARK, a * 0.5))
		ci.draw_circle(head, 8.0, _c(SKIN, a, flash))
		ci.draw_circle(head + Vector2(-2.5, 1.5), 5.8, _c(SKIN.darkened(0.08), a * 0.6, flash))
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(7.2, -1), head + Vector2(10.2, 2.5), head + Vector2(7.2, 3)]), _c(SKIN.darkened(0.12), a, flash))
		ci.draw_circle(head + Vector2(4.5, -1.5), 1.3, _c(DARK, a))
		ci.draw_line(head + Vector2(3, -4), head + Vector2(6.5, -4.3), _c(DARK, a * 0.8), 1.2)
		if not u.hero:
			ci.draw_line(head + Vector2(4, 4), head + Vector2(9, 5.5), _c(Color(0.2, 0.13, 0.08), a), 1.6)
	else:
		var body := PackedVector2Array([Vector2(-8, -42), Vector2(8, -42), Vector2(10, -12), Vector2(-10, -12)])
		ci.draw_colored_polygon(body, _c(tunic, a, flash))
		ci.draw_line(Vector2(-4, -14), Vector2(6, 2), _c(cols[2], a), 6.0, true)
		ci.draw_circle(head, 8.0, _c(SKIN, a, flash))
		ci.draw_circle(head + Vector2(4, -1), 1.3, _c(DARK, a))
	if u.hero:
		# Soqol va hero bosh kiyimi
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-2, 3), head + Vector2(8, 3), head + Vector2(4, 13), head + Vector2(-1, 9)]), _c(Color(0.22, 0.15, 0.1), a))
		_draw_hero_head(ci, u, head, a)
	else:
		_draw_headgear(ci, "cavalry", head, cols, a)
	var shoulder := Vector2(0, -38)
	if str(u.def.get("weapon", "")) == "bow":
		var draw_k := 1.0 - clampf(u.cooldown / maxf(0.01, float(u.def.cooldown)), 0.0, 1.0)
		var bow_c := shoulder + Vector2(18, 0)
		ci.draw_line(shoulder, bow_c, _c(SKIN, a, flash), 5.0, true)
		ci.draw_arc(bow_c, 20.0, -1.3, 1.3, 14, _c(WOOD, a), 3.5, true)
		var top := bow_c + Vector2.from_angle(-1.3) * 20.0
		var bot := bow_c + Vector2.from_angle(1.3) * 20.0
		var pull := bow_c + Vector2(-6.0 - 10.0 * draw_k, 0)
		ci.draw_line(top, pull, _c(Color(0.9, 0.9, 0.85), a), 1.2)
		ci.draw_line(pull, bot, _c(Color(0.9, 0.9, 0.85), a), 1.2)
		ci.draw_line(shoulder, pull, _c(SKIN.darkened(0.1), a, flash), 4.0, true)
		return
	var ang := lerpf(-2.4, 0.4, swing)
	var hand := shoulder + Vector2(9, 8)
	ci.draw_line(shoulder, hand, _c(SKIN, a, flash), 5.0, true)
	# Egri qilich (sabre)
	var pts := PackedVector2Array()
	for i in 8:
		var k := i / 7.0
		pts.append(hand + Vector2.from_angle(ang + k * 0.35) * (k * 36.0))
	ci.draw_polyline(pts, _c(STEEL, a), 3.5, true)


# --- Qal'a, kon, fon ---------------------------------------------------------

static func draw_castle(ci: CanvasItem, team: TeamState, ground_y: float, t: float) -> void:
	var x := team.castle_x
	var cols: Array = team_colors(team.index)
	var k := clampf(team.castle_hp / team.castle_max_hp, 0.0, 1.0)
	var stone := Color(0.72, 0.62, 0.48) if team.index == 0 else Color(0.6, 0.52, 0.45)
	var w := 140.0
	var h := 190.0
	if k <= 0.0:
		# Vayrona
		for i in 9:
			var rx := x - w * 0.6 + i * w * 0.15
			ci.draw_circle(Vector2(rx, ground_y - 8 - (i % 3) * 7), 16.0 - (i % 4) * 2.0, stone.darkened(0.15 * (i % 3)))
		return
	var base := Rect2(x - w * 0.5, ground_y - h, w, h)
	ci.draw_rect(base, stone)
	# Toshlar: qatorlar va qatma-qat tikuvlar (g'isht terimi), ba'zi toshlar och/to'q
	for row in 9:
		var yy := ground_y - h + 20.0 * row + 10.0
		ci.draw_line(Vector2(x - w * 0.5, yy), Vector2(x + w * 0.5, yy), stone.darkened(0.12), 1.5)
		var off := 0.0 if row % 2 == 0 else 14.0
		var bx := x - w * 0.5 + off
		var n := 0
		while bx < x + w * 0.5 - 4.0:
			ci.draw_line(Vector2(bx, yy), Vector2(bx, yy + 20.0), stone.darkened(0.1), 1.2)
			if (row * 7 + n * 3) % 5 == 0:
				ci.draw_rect(Rect2(bx + 1.5, yy + 1.5, 25.0, 17.0), stone.lightened(0.06))
			elif (row * 5 + n * 11) % 7 == 0:
				ci.draw_rect(Rect2(bx + 1.5, yy + 1.5, 25.0, 17.0), stone.darkened(0.06))
			bx += 28.0
			n += 1
	# Hajm: o'ng chet soyali, chap chet yorug'
	ci.draw_rect(Rect2(x + w * 0.5 - 18.0, ground_y - h, 18.0, h), Color(0, 0, 0, 0.12))
	ci.draw_rect(Rect2(x - w * 0.5, ground_y - h, 10.0, h), Color(1, 1, 1, 0.08))
	# Shinaklar (o'q otish tirqishlari)
	for sx in [-42.0, 42.0]:
		ci.draw_rect(Rect2(x + sx - 3.0, ground_y - h + 40.0, 6.0, 20.0), DARK)
	# Minoralar
	for side in [-1, 1]:
		var tx: float = x + side * (w * 0.5 + 6.0)
		var tower := Rect2(tx - 26.0, ground_y - h - 50.0, 52.0, h + 50.0)
		ci.draw_rect(tower, stone.darkened(0.06))
		for c in 3:
			ci.draw_rect(Rect2(tx - 26.0 + c * 19.0, ground_y - h - 64.0, 14.0, 16.0), stone.darkened(0.06))
		ci.draw_rect(Rect2(tx - 5.0, ground_y - h - 20.0, 10.0, 20.0), DARK)
	# Tishli devor
	for c in 6:
		ci.draw_rect(Rect2(x - w * 0.5 + c * 25.0 + 4.0, ground_y - h - 14.0, 16.0, 14.0), stone)
	# Darvoza
	var gate := PackedVector2Array()
	gate.append(Vector2(x - 28.0, ground_y))
	for i in 11:
		var ang := PI + PI * i / 10.0
		gate.append(Vector2(x + cos(ang) * 28.0, ground_y - 62.0 + sin(ang) * 28.0))
	gate.append(Vector2(x + 28.0, ground_y))
	ci.draw_colored_polygon(gate, Color(0.25, 0.16, 0.1))
	for i in 5:
		ci.draw_line(Vector2(x - 20.0 + i * 10.0, ground_y - 85.0), Vector2(x - 20.0 + i * 10.0, ground_y), Color(0.15, 0.1, 0.06), 2.0)
	# Bayroq
	var pole_top := Vector2(x, ground_y - h - 110.0)
	ci.draw_line(Vector2(x, ground_y - h - 14.0), pole_top, DARK, 4.0)
	var flag := PackedVector2Array()
	var fdir := float(team.dir)
	for i in 7:
		var fx := i * 10.0
		flag.append(pole_top + Vector2(fx * fdir, sin(t * 4.0 + i * 0.7) * 3.0 * (i / 6.0)))
	for i in range(6, -1, -1):
		var fx2 := i * 10.0
		flag.append(pole_top + Vector2(fx2 * fdir, 34.0 + sin(t * 4.0 + i * 0.7) * 3.0 * (i / 6.0)))
	ci.draw_colored_polygon(flag, cols[0])
	ci.draw_circle(pole_top + Vector2(30.0 * fdir, 17.0), 7.0, cols[1])
	# Devorga osilgan jamoa bayrog'i (shamolda biroz tebranadi)
	var bw := sin(t * 2.0) * 2.0
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 18, ground_y - h + 6), Vector2(x + 18, ground_y - h + 6),
		Vector2(x + 18 + bw, ground_y - h + 62), Vector2(x + bw, ground_y - h + 52), Vector2(x - 18 + bw, ground_y - h + 62)]), cols[0])
	ci.draw_circle(Vector2(x + bw * 0.5, ground_y - h + 30), 7.0, cols[1])
	ci.draw_line(Vector2(x - 20, ground_y - h + 6), Vector2(x + 20, ground_y - h + 6), WOOD, 3.0)
	# Shikastlanish yoriqlari
	if k < 0.75:
		ci.draw_polyline(PackedVector2Array([Vector2(x - 40, ground_y - 160), Vector2(x - 30, ground_y - 130), Vector2(x - 42, ground_y - 100)]), DARK, 3.0)
	if k < 0.5:
		ci.draw_polyline(PackedVector2Array([Vector2(x + 30, ground_y - 180), Vector2(x + 44, ground_y - 140), Vector2(x + 32, ground_y - 110), Vector2(x + 40, ground_y - 80)]), DARK, 3.0)
	if k < 0.25:
		ci.draw_polyline(PackedVector2Array([Vector2(x - 10, ground_y - 190), Vector2(x + 5, ground_y - 150), Vector2(x - 8, ground_y - 120)]), DARK, 4.0)
	# Shikastlangan qal'adan tutun ko'tariladi (qancha ko'p shikast — shuncha quyuq)
	if k < 0.6:
		var dens := 1.0 - k / 0.6
		for i in 6:
			var ph := fposmod(t * 0.35 + i / 6.0, 1.0)
			var p := Vector2(x - 30.0 + float((i * 23) % 60) + sin(t + i) * 6.0, ground_y - h - 10.0 - ph * 140.0)
			ci.draw_circle(p, 10.0 + ph * 22.0, Color(0.3, 0.28, 0.27, 0.45 * (1.0 - ph) * (0.4 + 0.6 * dens)))


static func draw_mine(ci: CanvasItem, x: float, ground_y: float, t: float) -> void:
	var rock := Color(0.42, 0.38, 0.36)
	var pts := PackedVector2Array([Vector2(x - 70, ground_y), Vector2(x - 55, ground_y - 40), Vector2(x - 20, ground_y - 62),
		Vector2(x + 15, ground_y - 55), Vector2(x + 50, ground_y - 35), Vector2(x + 72, ground_y)])
	ci.draw_colored_polygon(pts, rock)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 20, ground_y - 62), Vector2(x + 15, ground_y - 55), Vector2(x - 2, ground_y - 30)]), rock.lightened(0.15))
	var nuggets: Array[Vector2] = [Vector2(-30, -30), Vector2(5, -40), Vector2(30, -20), Vector2(-8, -15), Vector2(-45, -12)]
	for i in nuggets.size():
		var p: Vector2 = Vector2(x, ground_y) + nuggets[i]
		ci.draw_circle(p, 5.0, GOLD)
		var tw := sin(t * 3.0 + i * 1.7)
		if tw > 0.7:
			var s := (tw - 0.7) * 25.0
			ci.draw_line(p + Vector2(-s, 0), p + Vector2(s, 0), Color(1, 1, 0.8, 0.9), 1.5)
			ci.draw_line(p + Vector2(0, -s), p + Vector2(0, s), Color(1, 1, 0.8, 0.9), 1.5)


static func draw_projectile(ci: CanvasItem, p: Dictionary, ground_y: float) -> void:
	var k := clampf(p.t / p.dur, 0.0, 1.0)
	if str(p.kind) == "bullet":
		# Miltiq o'qi: deyarli to'g'ri chiziq, qisqa iz
		var bp := Vector2(p.x, ground_y - lerpf(float(p.h0), 50.0, k))
		var bd := signf(float(p.tx) - float(p.from_x))
		ci.draw_line(bp - Vector2(bd * 14.0, 0), bp, Color(1, 0.9, 0.6, 0.5), 2.0)
		ci.draw_circle(bp, 2.2, DARK)
		return
	var arc := 4.0 * k * (1.0 - k) * minf(140.0, absf(p.tx - p.from_x) * 0.3)
	var h := lerpf(float(p.h0), 40.0, k) + arc
	var pos := Vector2(p.x, ground_y - h)
	var k2 := minf(1.0, k + 0.03)
	var arc2 := 4.0 * k2 * (1.0 - k2) * minf(140.0, absf(p.tx - p.from_x) * 0.3)
	var nxt := Vector2(lerpf(p.from_x, p.tx, k2), ground_y - (lerpf(float(p.h0), 40.0, k2) + arc2))
	var d := (nxt - pos).normalized()
	if d == Vector2.ZERO:
		d = Vector2(signf(p.tx - p.from_x), 0)
	ci.draw_line(pos - d * 16.0, pos + d * 6.0, WOOD.lightened(0.2), 2.0, true)
	ci.draw_line(pos - d * 16.0, pos - d * 11.0 + d.orthogonal() * 3.0, Color(0.95, 0.95, 0.9), 1.5)
	ci.draw_line(pos - d * 16.0, pos - d * 11.0 - d.orthogonal() * 3.0, Color(0.95, 0.95, 0.9), 1.5)
