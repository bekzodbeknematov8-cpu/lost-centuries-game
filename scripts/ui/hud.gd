extends CanvasLayer
## Jang ekranidagi boshqaruv paneli. Barcha elementlar koddan quriladi.
## Hamma tugmalar ekranning pastki qismida (yer qatlami ustida) joylashgan,
## shunda jang maydoni to'liq ochiq qoladi.

const BAR_H := 128.0

var battle: Node   ## battle.gd
var _gold_label: Label
var _pop_label: Label
var _hp_bars: Array[ProgressBar] = []
var _stance_buttons: Array = []
var _command_box: HBoxContainer
var _move_box: HBoxContainer
var _attack_btn: Button
var _end_panel: PanelContainer
var _pause_panel: PanelContainer
var _hint: Label
var _hint_time := 7.0
var _banner: Label
var _banner_time := 0.0
var _root: Control
var _objective: Label
var _end_result: Dictionary = {}
var _next_btn: Button
var _ad_btn: Button


# --- Kichik chizilgan elementlar -----------------------------------------------

class CoinIcon:
	extends Control
	func _init() -> void:
		custom_minimum_size = Vector2(30, 30)
	func _draw() -> void:
		draw_circle(size * 0.5, 13.0, Color(0.75, 0.55, 0.1))
		draw_circle(size * 0.5, 10.0, Painter.GOLD)
		draw_circle(size * 0.5 + Vector2(-3, -3), 3.0, Color(1, 1, 0.85))


class IconButton:
	## Dumaloq, yarim shaffof tugma; ikonka kod bilan chiziladi.
	extends Button
	var icon_kind := ""
	var caption := ""
	var active := false
	var hold_cb: Callable

	func _init(kind: String, cap: String, sz := 74.0) -> void:
		icon_kind = kind
		caption = cap
		custom_minimum_size = Vector2(sz, sz)
		focus_mode = Control.FOCUS_NONE
		var r := int(sz * 0.5)
		add_theme_stylebox_override("normal", UITheme.box(Color(0.16, 0.1, 0.06, 0.78), Color(0.86, 0.6, 0.2, 0.7), r, 2))
		add_theme_stylebox_override("hover", UITheme.box(Color(0.22, 0.14, 0.08, 0.85), UITheme.ACCENT, r, 2))
		add_theme_stylebox_override("pressed", UITheme.box(Color(0.55, 0.33, 0.1, 0.9), UITheme.ACCENT, r, 3))
		add_theme_stylebox_override("disabled", UITheme.box(Color(0.15, 0.13, 0.12, 0.6), Color(0.4, 0.36, 0.3, 0.6), r, 2))

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5 - Vector2(0, 6 if caption != "" else 0)
		var col := Color(1, 0.9, 0.55) if active else UITheme.PARCHMENT
		if disabled:
			col = Color(0.55, 0.5, 0.45)
		if active:
			draw_arc(size * 0.5, size.x * 0.5 - 2, 0, TAU, 32, Color(1, 0.8, 0.3, 0.9), 3.0)
		var s := size.x / 74.0
		match icon_kind:
			"attack":
				for i in 2:
					var o := Vector2(-8 + i * 12, 0) * s
					draw_colored_polygon(PackedVector2Array([c + o + Vector2(-6, -12) * s, c + o + Vector2(6, 0) * s, c + o + Vector2(-6, 12) * s, c + o + Vector2(-1, 0) * s]), col)
			"retreat":
				for i in 2:
					var o := Vector2(8 - i * 12, 0) * s
					draw_colored_polygon(PackedVector2Array([c + o + Vector2(6, -12) * s, c + o + Vector2(-6, 0) * s, c + o + Vector2(6, 12) * s, c + o + Vector2(1, 0) * s]), col)
			"defend":
				var sh := PackedVector2Array([c + Vector2(-12, -14) * s, c + Vector2(12, -14) * s, c + Vector2(12, 0) * s, c + Vector2(0, 15) * s, c + Vector2(-12, 0) * s])
				draw_colored_polygon(sh, col)
				draw_line(c + Vector2(0, -10) * s, c + Vector2(0, 9) * s, Color(0.3, 0.2, 0.1), 3.0)
			"control":
				# Toj — qahramonni boshqarish
				draw_colored_polygon(PackedVector2Array([c + Vector2(-14, 8) * s, c + Vector2(-14, -8) * s, c + Vector2(-7, 0) * s, c + Vector2(0, -12) * s, c + Vector2(7, 0) * s, c + Vector2(14, -8) * s, c + Vector2(14, 8) * s]), col)
			"release":
				draw_line(c + Vector2(-10, -10) * s, c + Vector2(10, 10) * s, col, 4.0)
				draw_line(c + Vector2(10, -10) * s, c + Vector2(-10, 10) * s, col, 4.0)
			"left", "right":
				var d := -1.0 if icon_kind == "left" else 1.0
				draw_colored_polygon(PackedVector2Array([c + Vector2(14 * d, 0) * s, c + Vector2(-10 * d, -16) * s, c + Vector2(-10 * d, 16) * s]), col)
			"strike":
				# Qilich
				draw_line(c + Vector2(-14, 14) * s, c + Vector2(12, -12) * s, col, 5.0)
				draw_line(c + Vector2(-16, 4) * s, c + Vector2(-4, 16) * s, Painter.GOLD, 4.0)
			"pause":
				draw_rect(Rect2(c + Vector2(-9, -11) * s, Vector2(6, 22) * s), col)
				draw_rect(Rect2(c + Vector2(3, -11) * s, Vector2(6, 22) * s), col)
		if caption != "":
			var font := get_theme_default_font()
			draw_string_outline(font, Vector2(0, size.y - 9), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, 3, Color(0, 0, 0, 0.8))
			draw_string(font, Vector2(0, size.y - 9), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, col)


class UnitButton:
	extends Button
	var type: String
	var battle: Node
	var _u := UnitState.new()
	var _t := 0.0

	func _init(unit_type: String, b: Node) -> void:
		type = unit_type
		battle = b
		custom_minimum_size = Vector2(92, 112)
		focus_mode = Control.FOCUS_NONE
		_u.type = type
		_u.def = GameData.units[type]
		_u.team = 0
		_u.facing = 1
		_u.hp = 1.0
		_u.max_hp = 1.0
		_u.cooldown = 0.0
		add_theme_stylebox_override("normal", UITheme.box(Color(0.2, 0.13, 0.08, 0.85), Color(0.86, 0.6, 0.2, 0.8), 12, 2))
		add_theme_stylebox_override("disabled", UITheme.box(Color(0.15, 0.13, 0.12, 0.7), Color(0.4, 0.36, 0.3, 0.6), 12, 2))

	func _process(delta: float) -> void:
		_t += delta
		disabled = not battle.sim.can_train(0, type)
		queue_redraw()

	func _draw() -> void:
		var sc := 0.56 if type == "cavalry" else 0.74
		Painter.draw_unit(self, _u, Vector2(size.x * 0.5 - 2, 80 if type != "cavalry" else 77), sc, _t)
		var font := get_theme_default_font()
		var cost := int(_u.def.cost)
		var col := Painter.GOLD if not disabled else Color(0.85, 0.4, 0.35)
		draw_string_outline(font, Vector2(0, 104), str(cost), HORIZONTAL_ALIGNMENT_CENTER, size.x, 19, 4, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(0, 104), str(cost), HORIZONTAL_ALIGNMENT_CENTER, size.x, 19, col)
		draw_string_outline(font, Vector2(0, 18), tr(str(_u.def.name)), HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, 3, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(0, 18), tr(str(_u.def.name)), HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, UITheme.PARCHMENT)
		var team: TeamState = battle.sim.teams[0]
		var n := team.queue.count(type)
		if n > 0:
			draw_circle(Vector2(size.x - 12, 12), 11.0, Color(0.8, 0.2, 0.15))
			draw_string(font, Vector2(size.x - 24, 18), str(n), HORIZONTAL_ALIGNMENT_CENTER, 24, 15, Color.WHITE)
			if team.queue[0] == type:
				var k := team.train_progress / float(_u.def.train_time)
				draw_rect(Rect2(8, size.y - 7, (size.x - 16) * k, 4), Color(0.4, 0.9, 0.4))


class AbilityButton:
	## Qahramon portreti, maxsus kuch nomi va qayta tiklanish soati.
	extends Button
	var battle: Node
	var _u := UnitState.new()
	var _t := 0.0

	func _init(b: Node) -> void:
		battle = b
		custom_minimum_size = Vector2(112, 112)
		focus_mode = Control.FOCUS_NONE
		add_theme_stylebox_override("normal", UITheme.box(Color(0.35, 0.12, 0.08, 0.85), UITheme.ACCENT, 56, 3))
		add_theme_stylebox_override("hover", UITheme.box(Color(0.45, 0.16, 0.1, 0.9), UITheme.ACCENT, 56, 3))
		add_theme_stylebox_override("pressed", UITheme.box(Color(0.7, 0.35, 0.1, 0.95), UITheme.ACCENT, 56, 3))
		add_theme_stylebox_override("disabled", UITheme.box(Color(0.16, 0.12, 0.1, 0.75), Color(0.45, 0.4, 0.3), 56, 3))

	func _process(delta: float) -> void:
		_t += delta
		var sim: BattleSim = battle.sim
		var team := sim.teams[0]
		visible = team.hero_type != ""
		if not visible:
			return
		if _u.type != team.hero_type:
			_u.type = team.hero_type
			_u.def = sim.heroes[team.hero_type]
			_u.team = 0
			_u.facing = 1
			_u.hp = 1.0
			_u.max_hp = 1.0
			_u.hero = true
		disabled = not sim.ability_ready(0)
		queue_redraw()

	func _draw() -> void:
		if _u.def.is_empty():
			return
		var sim: BattleSim = battle.sim
		var team := sim.teams[0]
		Painter.draw_unit(self, _u, Vector2(size.x * 0.5 - 4, 92), 0.62, _t)
		var font := get_theme_default_font()
		var c := size * 0.5
		var hero_alive := sim.hero_of(0) != null
		if not hero_alive:
			draw_circle(c, size.x * 0.5 - 3, Color(0, 0, 0, 0.55))
			var txt := "%d" % ceili(team.hero_respawn)
			draw_string_outline(font, Vector2(0, c.y + 12), txt, HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, 5, Color.BLACK)
			draw_string(font, Vector2(0, c.y + 12), txt, HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, UITheme.PARCHMENT)
		elif team.ability_cd > 0.0:
			var a: Dictionary = _u.def.ability
			var k := team.ability_cd / float(a.cooldown)
			var pts := PackedVector2Array([c])
			for i in 33:
				pts.append(c + Vector2.from_angle(-PI / 2 + TAU * k * i / 32.0) * (size.x * 0.5 - 3))
			if k > 0.01:
				draw_colored_polygon(pts, Color(0, 0, 0, 0.55))
			var txt2 := "%d" % ceili(team.ability_cd)
			draw_string_outline(font, Vector2(0, c.y + 10), txt2, HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, 5, Color.BLACK)
			draw_string(font, Vector2(0, c.y + 10), txt2, HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, UITheme.PARCHMENT)
		else:
			var pulse := 0.5 + 0.5 * sin(_t * 5.0)
			draw_arc(c, size.x * 0.5 - 2, 0, TAU, 40, Color(1, 0.85, 0.3, 0.6 + 0.4 * pulse), 4.0)
		var name := tr(str(_u.def.ability.name))
		draw_string_outline(font, Vector2(0, size.y - 6), name, HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, 3, Color(0, 0, 0, 0.9))
		draw_string(font, Vector2(0, size.y - 6), name, HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, Painter.GOLD)


class StarRow:
	## Uchta yulduz; to'ldirilganlari ketma-ket "chaqnab" paydo bo'ladi.
	extends Control
	var count := 0
	var _t := 0.0
	var _played := 0

	func _init() -> void:
		custom_minimum_size = Vector2(300, 96)

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_t += delta
		var shown := mini(count, int(_t / 0.45))
		if shown > _played:
			_played = shown
			Sfx.play("coin", 0.8, 0.0)
		queue_redraw()

	func reset(n: int) -> void:
		count = n
		_t = 0.0
		_played = 0

	func _draw() -> void:
		for i in 3:
			var c := Vector2(size.x * 0.5 + (i - 1) * 92.0, 52.0 - (10.0 if i == 1 else 0.0))
			var lit := i < count and _t >= (i + 1) * 0.45
			var r := 38.0 if i == 1 else 32.0
			if lit:
				var k := clampf((_t - (i + 1) * 0.45) / 0.2, 0.0, 1.0)
				r *= 1.0 + 0.25 * (1.0 - k)
			_star(c, r + 4.0, Color(0.25, 0.15, 0.05))
			_star(c, r, Painter.GOLD if lit else Color(0.35, 0.3, 0.25))
			if lit:
				_star(c + Vector2(-r * 0.15, -r * 0.2), r * 0.35, Color(1, 1, 0.85, 0.7))

	func _star(c: Vector2, r: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 10:
			var rr := r if i % 2 == 0 else r * 0.45
			pts.append(c + Vector2.from_angle(-PI / 2 + i * PI / 5) * rr)
		draw_colored_polygon(pts, col)


class TacticButton:
	## Jangdagi hiyla tugmasi: ikonka va qolgan son.
	extends Button
	var id: String
	var battle: Node

	func _init(tid: String, b: Node) -> void:
		id = tid
		battle = b
		custom_minimum_size = Vector2(60, 60)
		focus_mode = Control.FOCUS_NONE
		add_theme_stylebox_override("normal", UITheme.box(Color(0.15, 0.22, 0.38, 0.85), Color(0.6, 0.75, 1.0, 0.8), 30, 2))
		add_theme_stylebox_override("hover", UITheme.box(Color(0.2, 0.3, 0.5, 0.9), Color(0.7, 0.85, 1.0), 30, 2))
		add_theme_stylebox_override("pressed", UITheme.box(Color(0.3, 0.45, 0.7, 0.95), Color(0.8, 0.9, 1.0), 30, 2))
		add_theme_stylebox_override("disabled", UITheme.box(Color(0.15, 0.15, 0.18, 0.6), Color(0.4, 0.4, 0.45, 0.6), 30, 2))

	func _process(_d: float) -> void:
		visible = GameState.tactic_count(id) > 0
		disabled = not battle.sim.can_use_tactic(0)
		queue_redraw()

	func _draw() -> void:
		TacticArt.draw(self, str(GameData.tactics.tactics[id].icon), size * 0.5, 1.15)
		var n := GameState.tactic_count(id)
		draw_circle(Vector2(size.x - 9, 9), 10.0, Color(0.8, 0.2, 0.15))
		draw_string(get_theme_default_font(), Vector2(size.x - 21, 15), str(n), HORIZONTAL_ALIGNMENT_CENTER, 24, 14, Color.WHITE)


class ReserveButton:
	## Zaxira qo'shin: bosilganda 5 ta askar keladi (bir jangda 10 tagacha).
	extends Button
	var type: String
	var battle: Node
	var _u := UnitState.new()

	func _init(t: String, b: Node) -> void:
		type = t
		battle = b
		custom_minimum_size = Vector2(60, 60)
		focus_mode = Control.FOCUS_NONE
		_u.type = t
		_u.def = GameData.units[t]
		_u.facing = 1
		_u.hp = 1.0
		_u.max_hp = 1.0
		add_theme_stylebox_override("normal", UITheme.box(Color(0.45, 0.12, 0.1, 0.85), Painter.GOLD, 30, 2))
		add_theme_stylebox_override("hover", UITheme.box(Color(0.55, 0.16, 0.12, 0.9), Painter.GOLD, 30, 2))
		add_theme_stylebox_override("disabled", UITheme.box(Color(0.15, 0.15, 0.18, 0.6), Color(0.4, 0.4, 0.45, 0.6), 30, 2))

	func _process(_d: float) -> void:
		visible = int(GameState.progress.get("reserves", {}).get(type, 0)) > 0
		disabled = battle.sim.teams[0].reserves_used >= int(GameData.market.reserve_per_battle) or battle.sim.winner >= 0
		queue_redraw()

	func _draw() -> void:
		Painter.draw_unit(self, _u, Vector2(size.x * 0.5, size.y - 8), 0.45 if type != "cavalry" else 0.36, 0.0)
		var n := int(GameState.progress.get("reserves", {}).get(type, 0))
		draw_circle(Vector2(size.x - 9, 9), 11.0, Color(0.2, 0.45, 0.2))
		draw_string(get_theme_default_font(), Vector2(size.x - 23, 14), str(n), HORIZONTAL_ALIGNMENT_CENTER, 28, 12, Color.WHITE)


class MiniMap:
	extends Control
	## Butun jang maydonining kichik xaritasi. Bosib/surib kamerani ko'chirish mumkin.
	var battle: Node

	func _init(b: Node) -> void:
		battle = b
		custom_minimum_size = Vector2(440, 26)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(_d: float) -> void:
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		var pressed: bool = (event is InputEventMouseButton and event.pressed) or (event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0)
		if (event is InputEventScreenTouch and event.pressed) or event is InputEventScreenDrag:
			pressed = true
		if pressed:
			battle.focus_x(clampf(event.position.x / size.x, 0.0, 1.0) * BattleSim.WORLD_LEN)
			accept_event()

	func _draw() -> void:
		var sim: BattleSim = battle.sim
		var k := size.x / BattleSim.WORLD_LEN
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35))
		draw_rect(Rect2(Vector2(0, size.y - 5), Vector2(size.x, 5)), Color(0.55, 0.47, 0.3, 0.7))
		for t in sim.teams:
			var col: Color = Painter.team_colors(t.index)[0]
			draw_rect(Rect2(t.castle_x * k - 5, 3, 10, size.y - 6), col.lightened(0.3))
			draw_circle(Vector2(t.mine_x * k, size.y - 5), 3.0, Painter.GOLD)
		for u in sim.units:
			if not u.is_alive():
				continue
			var c: Color = Painter.team_colors(u.team)[0].lightened(0.35)
			var y := 6.0 + u.lane * (size.y - 16.0)
			if u.hero:
				draw_circle(Vector2(u.x * k, size.y * 0.5), 5.0, Painter.GOLD)
				draw_circle(Vector2(u.x * k, size.y * 0.5), 3.0, c)
			else:
				draw_rect(Rect2(u.x * k - 1.5, y, 3, 4 if u.is_worker() else 6), c)
		var vw: float = battle.view_width()
		var cx: float = battle.cam.position.x
		draw_rect(Rect2((cx - vw * 0.5) * k, 1, vw * k, size.y - 2), Color(1, 0.9, 0.5, 0.9), false, 2.0)


# --- Qurish ------------------------------------------------------------------

func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UITheme.make()
	add_child(_root)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_top()
	_build_bottom()
	_build_tactics()
	_build_end_panel()
	_build_pause_panel()
	_hint = _center_label(24, 96)
	_hint.text = tr("HINT_START")
	_objective = _center_label(20, 70)
	_objective.visible = false
	_banner = _center_label(34, 150)
	_banner.add_theme_color_override("font_color", Painter.GOLD)
	_banner.add_theme_constant_override("outline_size", 8)
	_banner.visible = false


func _center_label(font_size: int, y: float) -> Label:
	var l := Label.new()
	l.anchor_left = 0.5
	l.anchor_right = 0.5
	l.offset_left = -450
	l.offset_right = 450
	l.offset_top = y
	l.offset_bottom = y + 40
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	_root.add_child(l)
	return l


func _build_top() -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 14
	bar.offset_right = -14
	bar.offset_top = 8
	bar.add_theme_constant_override("separation", 12)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bar)
	var res := PanelContainer.new()
	res.add_theme_stylebox_override("panel", UITheme.box(Color(0.16, 0.1, 0.06, 0.75), Color(0.86, 0.6, 0.2, 0.7), 14, 2))
	var rh := HBoxContainer.new()
	rh.add_theme_constant_override("separation", 8)
	res.add_child(rh)
	rh.add_child(CoinIcon.new())
	_gold_label = Label.new()
	_gold_label.custom_minimum_size = Vector2(62, 0)
	_gold_label.add_theme_font_size_override("font_size", 24)
	rh.add_child(_gold_label)
	_pop_label = Label.new()
	_pop_label.add_theme_font_size_override("font_size", 18)
	rh.add_child(_pop_label)
	bar.add_child(res)
	bar.add_child(_spacer())
	var mid := VBoxContainer.new()
	mid.add_theme_constant_override("separation", 4)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(mid)
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 10)
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(hp_row)
	for i in 2:
		var pb := ProgressBar.new()
		pb.custom_minimum_size = Vector2(205, 20)
		pb.show_percentage = false
		pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pb.add_theme_stylebox_override("fill", UITheme.fill(Painter.team_colors(i)[0].lightened(0.15)))
		if i == 1:
			pb.fill_mode = ProgressBar.FILL_END_TO_BEGIN
		hp_row.add_child(pb)
		_hp_bars.append(pb)
		if i == 0:
			var vs := Label.new()
			vs.text = "VS"
			vs.add_theme_font_size_override("font_size", 18)
			hp_row.add_child(vs)
	mid.add_child(MiniMap.new(battle))
	bar.add_child(_spacer())
	var pause := IconButton.new("pause", "", 52.0)
	pause.pressed.connect(_on_pause)
	pause.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bar.add_child(pause)


func _spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _build_bottom() -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left = 12
	bar.offset_right = -12
	bar.offset_top = -BAR_H
	bar.offset_bottom = -8
	bar.add_theme_constant_override("separation", 8)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bar)

	# Chap: buyruqlar (yoki boshqaruv paytida chap/o'ng tugmalari)
	_command_box = HBoxContainer.new()
	_command_box.add_theme_constant_override("separation", 6)
	_command_box.alignment = BoxContainer.ALIGNMENT_END
	_command_box.size_flags_vertical = Control.SIZE_SHRINK_END
	bar.add_child(_command_box)
	var defs := [["attack", "STANCE_ATTACK", TeamState.Stance.ATTACK], ["defend", "STANCE_DEFEND", TeamState.Stance.DEFEND], ["retreat", "STANCE_RETREAT", TeamState.Stance.RETREAT]]
	for d in defs:
		var b := IconButton.new(d[0], tr(d[1]))
		b.pressed.connect(_on_stance.bind(d[2]))
		_command_box.add_child(b)
		_stance_buttons.append([b, d[2]])
	var ctrl := IconButton.new("control", tr("CONTROL"))
	ctrl.pressed.connect(_on_control)
	_command_box.add_child(ctrl)

	_move_box = HBoxContainer.new()
	_move_box.add_theme_constant_override("separation", 10)
	_move_box.size_flags_vertical = Control.SIZE_SHRINK_END
	_move_box.visible = false
	bar.add_child(_move_box)
	for d in [-1, 1]:
		var b := IconButton.new("left" if d < 0 else "right", "", 104.0)
		b.button_down.connect(func() -> void: battle.sim.control_dir = d)
		b.button_up.connect(func() -> void:
			if battle.sim.control_dir == d:
				battle.sim.control_dir = 0)
		_move_box.add_child(b)
	var rel := IconButton.new("release", tr("CONTROL_RELEASE"), 74.0)
	rel.pressed.connect(_on_control)
	_move_box.add_child(rel)

	bar.add_child(_spacer())
	# O'rta: askar yollash kartalari
	var units := HBoxContainer.new()
	units.add_theme_constant_override("separation", 6)
	units.size_flags_vertical = Control.SIZE_SHRINK_END
	bar.add_child(units)
	for type in ["worker", "swordsman", "spearman", "archer", "cavalry"]:
		var b := UnitButton.new(type, battle)
		b.pressed.connect(_on_train.bind(type))
		units.add_child(b)
	bar.add_child(_spacer())

	# O'ng: zarba (boshqaruv paytida) va qahramon kuchi
	_attack_btn = IconButton.new("strike", tr("ATTACK_BTN"), 104.0)
	_attack_btn.size_flags_vertical = Control.SIZE_SHRINK_END
	_attack_btn.button_down.connect(func() -> void: battle.sim.control_attack = true)
	_attack_btn.button_up.connect(func() -> void: battle.sim.control_attack = false)
	_attack_btn.visible = false
	bar.add_child(_attack_btn)
	var ab := AbilityButton.new(battle)
	ab.size_flags_vertical = Control.SIZE_SHRINK_END
	ab.pressed.connect(_on_ability)
	bar.add_child(ab)


func _build_tactics() -> void:
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	col.grow_vertical = Control.GROW_DIRECTION_BEGIN
	col.offset_left = 14
	col.offset_bottom = -BAR_H - 14
	col.add_theme_constant_override("separation", 8)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(col)
	for id in GameData.tactics.order:
		var b := TacticButton.new(id, battle)
		b.pressed.connect(_on_tactic.bind(id))
		col.add_child(b)
	var rcol := VBoxContainer.new()
	rcol.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	rcol.grow_vertical = Control.GROW_DIRECTION_BEGIN
	rcol.offset_left = 84
	rcol.offset_bottom = -BAR_H - 14
	rcol.add_theme_constant_override("separation", 8)
	rcol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(rcol)
	for t in ["archer", "swordsman", "cavalry"]:
		var rb := ReserveButton.new(t, battle)
		rb.pressed.connect(_on_reserve.bind(t))
		rcol.add_child(rb)


func _on_reserve(type: String) -> void:
	var sim: BattleSim = battle.sim
	var left := int(GameData.market.reserve_per_battle) - sim.teams[0].reserves_used
	var want := mini(int(GameData.market.reserve_call), left)
	want = mini(want, sim.reserve_room(0, type))
	var got := GameState.take_reserve(type, want)
	if got <= 0:
		Sfx.play("deny", 0.6)
		return
	var spawned := sim.call_reserve(0, type, got)
	Sfx.play("horn_attack", 0.8, 0.0)
	show_banner(tr("RESERVE_CALLED") % [spawned, tr(str(GameData.units[type].name))], 1.6)


func _on_tactic(id: String) -> void:
	var sim: BattleSim = battle.sim
	if not sim.can_use_tactic(0) or GameState.tactic_count(id) <= 0:
		Sfx.play("deny", 0.6)
		return
	if sim.use_tactic(0, id, GameData.tactics.tactics[id]):
		GameState.consume_tactic(id)
		show_banner(tr(str(GameData.tactics.tactics[id].name)) + "!", 1.4)


func _make_center_panel() -> Array:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(620, 0)
	panel.visible = false
	_root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	return [panel, v]


func _build_end_panel() -> void:
	var r := _make_center_panel()
	_end_panel = r[0]
	var v: VBoxContainer = r[1]
	var title := Label.new()
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	v.add_child(title)
	var stars := StarRow.new()
	stars.name = "Stars"
	stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(stars)
	var stats := Label.new()
	stats.name = "Stats"
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.custom_minimum_size = Vector2(640, 0)
	stats.add_theme_font_size_override("font_size", 18)
	v.add_child(stats)
	_ad_btn = Button.new()
	_ad_btn.custom_minimum_size = Vector2(420, 58)
	_ad_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_ad_btn.add_theme_font_size_override("font_size", 20)
	_ad_btn.add_theme_stylebox_override("normal", UITheme.box(Color(0.12, 0.38, 0.18), Painter.GOLD))
	_ad_btn.add_theme_stylebox_override("hover", UITheme.box(Color(0.16, 0.46, 0.22), Painter.GOLD))
	_ad_btn.pressed.connect(_on_ad)
	_ad_btn.visible = false
	v.add_child(_ad_btn)
	var fact := PanelContainer.new()
	fact.name = "Fact"
	fact.add_theme_stylebox_override("panel", UITheme.box(Color(0.93, 0.85, 0.66), Color(0.55, 0.38, 0.18), 10, 2))
	var fl := Label.new()
	fl.name = "FactText"
	fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fl.custom_minimum_size = Vector2(640, 0)
	fl.add_theme_color_override("font_color", Color(0.25, 0.15, 0.08))
	fl.add_theme_constant_override("outline_size", 0)
	fl.add_theme_font_size_override("font_size", 18)
	fact.add_child(fl)
	v.add_child(fact)
	var row := _button_row([["RESTART", _on_restart], ["MENU", _on_menu]])
	_next_btn = Button.new()
	_next_btn.text = tr("NEXT_LEVEL")
	_next_btn.custom_minimum_size = Vector2(220, 64)
	_next_btn.add_theme_stylebox_override("normal", UITheme.box(Color(0.55, 0.15, 0.08), Painter.GOLD))
	_next_btn.add_theme_stylebox_override("hover", UITheme.box(Color(0.65, 0.2, 0.1), Painter.GOLD))
	_next_btn.pressed.connect(_on_next)
	row.add_child(_next_btn)
	v.add_child(row)


func _build_pause_panel() -> void:
	var r := _make_center_panel()
	_pause_panel = r[0]
	var v: VBoxContainer = r[1]
	var title := Label.new()
	title.text = tr("PAUSED")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	v.add_child(title)
	v.add_child(_button_row([["RESUME", _on_pause], ["RESTART", _on_restart], ["MENU", _on_menu]]))


func _button_row(items: Array) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 16)
	for it in items:
		var b := Button.new()
		b.text = tr(it[0])
		b.custom_minimum_size = Vector2(180, 64)
		b.pressed.connect(it[1])
		h.add_child(b)
	return h


# --- Yangilash ---------------------------------------------------------------

func _process(delta: float) -> void:
	var sim: BattleSim = battle.sim
	var team := sim.teams[0]
	_gold_label.text = str(int(team.gold))
	_pop_label.text = "%d/%d" % [team.pop, team.pop_cap]
	for i in 2:
		_hp_bars[i].max_value = sim.teams[i].castle_max_hp
		_hp_bars[i].value = sim.teams[i].castle_hp
	for sb in _stance_buttons:
		sb[0].active = sb[1] == team.stance
	var controlling := sim.controlled_unit() != null
	_command_box.visible = not controlling
	_move_box.visible = controlling
	_attack_btn.visible = controlling
	if _hint_time > 0.0:
		_hint_time -= delta
		_hint.modulate.a = clampf(_hint_time, 0.0, 1.0)
		_hint.visible = _hint_time > 0.0
	if _objective.visible and sim.survive_time > 0.0 and sim.winner < 0:
		var left := maxi(0, ceili(sim.survive_time - sim.time))
		_objective.text = tr("OBJ_SURVIVE_LEFT") % [left / 60, left % 60]
	if _banner_time > 0.0:
		_banner_time -= delta
		_banner.modulate.a = clampf(_banner_time * 2.0, 0.0, 1.0)
		_banner.visible = _banner_time > 0.0


func show_banner(text: String, life: float) -> void:
	_banner.text = text
	_banner_time = life
	_banner.visible = true


func _on_train(type: String) -> void:
	if battle.sim.train(0, type):
		Sfx.play("click", 0.6)
	else:
		Sfx.play("deny", 0.6)


func _on_stance(stance: int) -> void:
	Sfx.play("click", 0.6)
	battle.sim.set_stance(0, stance)


func _on_control() -> void:
	Sfx.play("click", 0.6)
	if battle.sim.controlled_unit():
		battle.sim.release_control()
	elif battle.sim.take_control(0):
		_hint.text = tr("HINT_CONTROL")
		_hint_time = 3.0
	else:
		Sfx.play("deny", 0.6)


func _on_ability() -> void:
	if not battle.sim.use_ability(0):
		Sfx.play("deny", 0.6)


func on_control_lost() -> void:
	pass


func show_objective(text: String) -> void:
	_objective.text = text
	_objective.visible = true


func show_end(victory: bool, result: Dictionary = {}) -> void:
	_end_result = result
	_objective.visible = false
	var title: Label = _end_panel.find_child("Title", true, false)
	title.text = tr("VICTORY") if victory else tr("DEFEAT")
	title.add_theme_color_override("font_color", Painter.GOLD if victory else Color(0.9, 0.35, 0.3))
	var team: TeamState = battle.sim.teams[0]
	var secs := int(battle.sim.time)
	var stats: Label = _end_panel.find_child("Stats", true, false)
	stats.text = tr("STATS_FMT") % [team.stats.trained, team.stats.killed, int(team.stats.gold_mined), "%d:%02d" % [secs / 60, secs % 60]]
	var lv: Dictionary = result.get("level", {})
	var star_row: StarRow = _end_panel.find_child("Stars", true, false)
	var fact: PanelContainer = _end_panel.find_child("Fact", true, false)
	star_row.visible = not lv.is_empty()
	fact.visible = false
	_next_btn.visible = false
	_ad_btn.visible = false
	if result.get("endless", false):
		title.text = tr("ENDLESS_OVER")
		title.add_theme_color_override("font_color", Painter.GOLD)
		stats.text = tr("WAVES_SURVIVED") % int(result.waves)
		if result.get("record", false):
			stats.text += "   ★ " + tr("NEW_RECORD")
		stats.text += "\n" + tr("COINS_EARNED") % int(result.coins)
	if int(result.get("coins", 0)) > 0 and GameState.ads_left() > 0:
		_ad_btn.text = "▶  " + tr("AD_DOUBLE") % [int(result.coins), GameState.ads_left()]
		if bool(GameState.progress.get("no_ads", false)):
			_ad_btn.text = "✦  " + tr("AD_DOUBLE_NOADS") % int(result.coins)
		_ad_btn.disabled = false
		_ad_btn.visible = true
	if not lv.is_empty():
		star_row.reset(int(result.stars))
		if int(result.coins) > 0:
			stats.text += "\n" + tr("COINS_EARNED") % int(result.coins)
		for ch in result.get("chests", []):
			stats.text += "\n🎁 " + tr("CHEST_REWARD") % tr(str(GameData.chests.chests[ch].name))
		if not victory:
			stats.text += "\n" + tr("HINT_DEFEAT")
		var f: Dictionary = GameData.facts.get(str(lv.id), {})
		if victory and not f.is_empty():
			var loc := TranslationServer.get_locale().substr(0, 2)
			var fl: Label = fact.find_child("FactText", true, false)
			fl.text = tr("DID_YOU_KNOW") + " " + str(f.get(loc, f.en))
			fact.visible = true
		var nxt := Campaign.next_level_id(GameData.campaigns, str(lv.id))
		_next_btn.visible = victory and nxt != ""
	_end_panel.visible = true


func _on_ad() -> void:
	_ad_btn.disabled = true
	var bonus := int(_end_result.get("coins", 0))
	if bool(GameState.progress.get("no_ads", false)):
		if GameState.reward_ad(bonus):
			Sfx.play("coin", 1.0, 0.0)
			_ad_btn.text = tr("AD_DONE") % (bonus * 2)
		return
	Ads.show_rewarded(func(ok: bool) -> void:
		if ok and GameState.reward_ad(bonus):
			Sfx.play("coin", 1.0, 0.0)
			_ad_btn.text = tr("AD_DONE") % (bonus * 2)
		else:
			_ad_btn.text = tr("AD_LIMIT"))


func _on_next() -> void:
	var lv: Dictionary = _end_result.get("level", {})
	var nxt := Campaign.next_level_id(GameData.campaigns, str(lv.get("id", "")))
	get_tree().paused = false
	if nxt != "":
		GameState.level_id = nxt
		get_tree().reload_current_scene()


func _on_pause() -> void:
	Sfx.play("click", 0.6)
	var p := not get_tree().paused
	get_tree().paused = p
	_pause_panel.visible = p


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu() -> void:
	get_tree().paused = false
	if GameState.level_id != "":
		get_tree().change_scene_to_file("res://scenes/campaign_map.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/mode_select.tscn")
