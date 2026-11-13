extends CanvasLayer
## Jang ekranidagi boshqaruv paneli. Barcha elementlar koddan quriladi.

var battle: Node   ## battle.gd
var _gold_label: Label
var _pop_label: Label
var _hp_bars: Array[ProgressBar] = []
var _unit_buttons: Array = []
var _stance_buttons: Array[Button] = []
var _control_btn: Button
var _control_pad: Control
var _attack_btn: Button
var _end_panel: PanelContainer
var _pause_panel: PanelContainer
var _hint: Label
var _hint_time := 7.0
var _queue_bar: ProgressBar
var _root: Control


class CoinIcon:
	extends Control
	func _init() -> void:
		custom_minimum_size = Vector2(30, 30)
	func _draw() -> void:
		draw_circle(size * 0.5, 13.0, Color(0.75, 0.55, 0.1))
		draw_circle(size * 0.5, 10.0, Painter.GOLD)
		draw_circle(size * 0.5 + Vector2(-3, -3), 3.0, Color(1, 1, 0.85))


class UnitButton:
	extends Button
	var type: String
	var battle: Node
	var _u := UnitState.new()
	var _t := 0.0

	func _init(unit_type: String, b: Node) -> void:
		type = unit_type
		battle = b
		custom_minimum_size = Vector2(104, 118)
		_u.type = type
		_u.def = GameData.units[type]
		_u.team = 0
		_u.facing = 1
		_u.hp = 1.0
		_u.max_hp = 1.0
		_u.cooldown = 0.0

	func _process(delta: float) -> void:
		_t += delta
		disabled = not battle.sim.can_train(0, type)
		queue_redraw()

	func _draw() -> void:
		var sc := 0.62 if type == "cavalry" else 0.82
		Painter.draw_unit(self, _u, Vector2(50, 84 if type != "cavalry" else 80), sc, _t)
		var font := get_theme_default_font()
		var cost := int(_u.def.cost)
		var col := Painter.GOLD if not disabled else Color(0.85, 0.4, 0.35)
		draw_string_outline(font, Vector2(0, 110), str(cost), HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, 4, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(0, 110), str(cost), HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, col)
		draw_string_outline(font, Vector2(0, 20), tr(str(_u.def.name)), HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, 3, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(0, 20), tr(str(_u.def.name)), HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, UITheme.PARCHMENT)
		var team: TeamState = battle.sim.teams[0]
		var n := team.queue.count(type)
		if n > 0:
			draw_circle(Vector2(size.x - 14, 14), 12.0, Color(0.8, 0.2, 0.15))
			draw_string(font, Vector2(size.x - 26, 21), str(n), HORIZONTAL_ALIGNMENT_CENTER, 24, 17, Color.WHITE)
			if team.queue[0] == type:
				var k := team.train_progress / float(_u.def.train_time)
				draw_rect(Rect2(8, size.y - 8, (size.x - 16) * k, 4), Color(0.4, 0.9, 0.4))


class MiniMap:
	extends Control
	## Butun jang maydonining kichik xaritasi. Bosib/surib kamerani ko'chirish mumkin.
	var battle: Node

	func _init(b: Node) -> void:
		battle = b
		custom_minimum_size = Vector2(480, 30)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(_d: float) -> void:
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		var pressed: bool = (event is InputEventMouseButton and event.pressed) or event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
		if event is InputEventScreenTouch and event.pressed or event is InputEventScreenDrag:
			pressed = true
		if pressed:
			battle.focus_x(clampf(event.position.x / size.x, 0.0, 1.0) * BattleSim.WORLD_LEN)
			accept_event()

	func _draw() -> void:
		var sim: BattleSim = battle.sim
		var k := size.x / BattleSim.WORLD_LEN
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
		draw_rect(Rect2(Vector2(0, size.y - 6), Vector2(size.x, 6)), Color(0.55, 0.47, 0.3, 0.8))
		for t in sim.teams:
			var col: Color = Painter.TEAM_COLORS[t.index][0]
			draw_rect(Rect2(t.castle_x * k - 6, 4, 12, size.y - 8), col.lightened(0.3))
			draw_circle(Vector2(t.mine_x * k, size.y - 6), 3.0, Painter.GOLD)
		for u in sim.units:
			if not u.is_alive():
				continue
			var c: Color = Painter.TEAM_COLORS[u.team][0].lightened(0.35)
			var y := 8.0 + u.lane * (size.y - 18.0)
			draw_rect(Rect2(u.x * k - 1.5, y, 3, 4 if u.is_worker() else 6), c)
		var vw: float = battle.view_width()
		var cx: float = battle.cam.position.x
		draw_rect(Rect2((cx - vw * 0.5) * k, 1, vw * k, size.y - 2), Color(1, 0.9, 0.5, 0.9), false, 2.0)


func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UITheme.make()
	add_child(_root)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_top()
	_build_units()
	_build_stances()
	_build_control_pad()
	_build_end_panel()
	_build_pause_panel()
	_hint = Label.new()
	_hint.text = tr("HINT_START")
	_hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hint.position = Vector2(-450, 104)
	_hint.size = Vector2(900, 40)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 24)
	_root.add_child(_hint)


func _build_top() -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 16
	bar.offset_right = -16
	bar.offset_top = 10
	bar.add_theme_constant_override("separation", 14)
	_root.add_child(bar)
	var res := PanelContainer.new()
	var rh := HBoxContainer.new()
	rh.add_theme_constant_override("separation", 8)
	res.add_child(rh)
	rh.add_child(CoinIcon.new())
	_gold_label = Label.new()
	_gold_label.custom_minimum_size = Vector2(70, 0)
	_gold_label.add_theme_font_size_override("font_size", 26)
	rh.add_child(_gold_label)
	_pop_label = Label.new()
	_pop_label.add_theme_font_size_override("font_size", 20)
	rh.add_child(_pop_label)
	bar.add_child(res)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(spacer)
	for i in 2:
		var pb := ProgressBar.new()
		pb.custom_minimum_size = Vector2(230, 26)
		pb.show_percentage = false
		pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pb.add_theme_stylebox_override("fill", UITheme.fill(Painter.TEAM_COLORS[i][0].lightened(0.15)))
		if i == 1:
			pb.fill_mode = ProgressBar.FILL_END_TO_BEGIN
		bar.add_child(pb)
		_hp_bars.append(pb)
		if i == 0:
			var vs := Label.new()
			vs.text = "VS"
			vs.add_theme_font_size_override("font_size", 22)
			bar.add_child(vs)
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(spacer2)
	var mm := MiniMap.new(battle)
	mm.set_anchors_preset(Control.PRESET_CENTER_TOP)
	mm.grow_horizontal = Control.GROW_DIRECTION_BOTH
	mm.offset_top = 62
	mm.offset_left = -240
	mm.offset_right = 240
	mm.offset_bottom = 92
	_root.add_child(mm)
	var pause := Button.new()
	pause.text = "II"
	pause.custom_minimum_size = Vector2(60, 56)
	pause.pressed.connect(_on_pause)
	bar.add_child(pause)


func _build_units() -> void:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.offset_bottom = -10
	_root.add_child(box)
	for type in ["worker", "swordsman", "spearman", "archer", "cavalry"]:
		var b := UnitButton.new(type, battle)
		b.pressed.connect(_on_train.bind(type))
		box.add_child(b)
		_unit_buttons.append(b)


func _build_stances() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	col.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	col.grow_vertical = Control.GROW_DIRECTION_BOTH
	col.offset_right = -14
	col.offset_top = -40
	_root.add_child(col)
	var defs := [["STANCE_ATTACK", TeamState.Stance.ATTACK, ">>"], ["STANCE_DEFEND", TeamState.Stance.DEFEND, "[ ]"], ["STANCE_RETREAT", TeamState.Stance.RETREAT, "<<"]]
	for d in defs:
		var b := Button.new()
		b.text = "%s  %s" % [d[2], tr(d[0])]
		b.custom_minimum_size = Vector2(190, 62)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_stance.bind(d[1]))
		col.add_child(b)
		_stance_buttons.append(b)
	_control_btn = Button.new()
	_control_btn.text = tr("CONTROL")
	_control_btn.custom_minimum_size = Vector2(190, 62)
	_control_btn.pressed.connect(_on_control)
	col.add_child(_control_btn)


func _build_control_pad() -> void:
	_control_pad = Control.new()
	_control_pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	_control_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_control_pad.visible = false
	_root.add_child(_control_pad)
	var arrows := HBoxContainer.new()
	arrows.add_theme_constant_override("separation", 12)
	arrows.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	arrows.grow_vertical = Control.GROW_DIRECTION_BEGIN
	arrows.offset_left = 16
	arrows.offset_bottom = -150
	_control_pad.add_child(arrows)
	for d in [-1, 1]:
		var b := Button.new()
		b.text = "<" if d < 0 else ">"
		b.add_theme_font_size_override("font_size", 44)
		b.custom_minimum_size = Vector2(110, 110)
		b.button_down.connect(func() -> void: battle.sim.control_dir = d)
		b.button_up.connect(func() -> void:
			if battle.sim.control_dir == d:
				battle.sim.control_dir = 0)
		arrows.add_child(b)
	_attack_btn = Button.new()
	_attack_btn.text = tr("ATTACK_BTN")
	_attack_btn.add_theme_font_size_override("font_size", 28)
	_attack_btn.custom_minimum_size = Vector2(150, 150)
	_attack_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_attack_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_attack_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_attack_btn.offset_right = -20
	_attack_btn.offset_bottom = -20
	_attack_btn.add_theme_stylebox_override("normal", UITheme.box(Color(0.6, 0.15, 0.1), UITheme.ACCENT, 75))
	_attack_btn.add_theme_stylebox_override("pressed", UITheme.box(Color(0.85, 0.3, 0.15), UITheme.ACCENT, 75))
	_attack_btn.add_theme_stylebox_override("hover", UITheme.box(Color(0.7, 0.2, 0.12), UITheme.ACCENT, 75))
	_attack_btn.button_down.connect(func() -> void: battle.sim.control_attack = true)
	_attack_btn.button_up.connect(func() -> void: battle.sim.control_attack = false)
	_control_pad.add_child(_attack_btn)


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
	var stats := Label.new()
	stats.name = "Stats"
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.custom_minimum_size = Vector2(580, 0)
	v.add_child(stats)
	v.add_child(_button_row([["RESTART", _on_restart], ["MENU", _on_menu]]))


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


func _process(delta: float) -> void:
	var sim: BattleSim = battle.sim
	var team := sim.teams[0]
	_gold_label.text = str(int(team.gold))
	_pop_label.text = "  %d/%d" % [team.pop, team.pop_cap]
	for i in 2:
		_hp_bars[i].max_value = sim.teams[i].castle_max_hp
		_hp_bars[i].value = sim.teams[i].castle_hp
	for i in _stance_buttons.size():
		var active: bool = [TeamState.Stance.ATTACK, TeamState.Stance.DEFEND, TeamState.Stance.RETREAT][i] == team.stance
		_stance_buttons[i].modulate = Color(1.25, 1.15, 0.8) if active else Color(0.85, 0.85, 0.85)
	var controlling := sim.controlled_unit() != null
	_control_pad.visible = controlling
	_control_btn.text = tr("CONTROL_RELEASE") if controlling else tr("CONTROL")
	if _hint_time > 0.0:
		_hint_time -= delta
		_hint.modulate.a = clampf(_hint_time, 0.0, 1.0)
		_hint.visible = _hint_time > 0.0


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


func on_control_lost() -> void:
	_control_pad.visible = false


func show_end(victory: bool) -> void:
	_control_pad.visible = false
	var title: Label = _end_panel.find_child("Title", true, false)
	title.text = tr("VICTORY") if victory else tr("DEFEAT")
	title.add_theme_color_override("font_color", Painter.GOLD if victory else Color(0.9, 0.35, 0.3))
	var team: TeamState = battle.sim.teams[0]
	var secs := int(battle.sim.time)
	var stats: Label = _end_panel.find_child("Stats", true, false)
	stats.text = tr("STATS_FMT") % [team.stats.trained, team.stats.killed, int(team.stats.gold_mined), "%d:%02d" % [secs / 60, secs % 60]]
	_end_panel.visible = true


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
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
