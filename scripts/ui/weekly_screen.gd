extends Control
## Haftalik vazifalar: 5 ta vazifa, har biri uchun mukofot va hammasi uchun bonus sandiq.

var _t := 0.0
var _rows: Array = []
var _coins: Label
var _gems: Label
var _left: Label
var _bonus_btn: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.make()
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_right = -16
	top.offset_top = 10
	top.add_theme_constant_override("separation", 16)
	add_child(top)
	var back := Button.new()
	back.text = "‹ " + tr("BACK")
	back.custom_minimum_size = Vector2(130, 52)
	back.pressed.connect(func() -> void:
		Sfx.play("click", 0.7)
		Transition.go("res://scenes/mode_select.tscn"))
	top.add_child(back)
	var title := Label.new()
	title.text = tr("MODE_WEEKLY")
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Painter.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	_coins = Label.new()
	_coins.add_theme_font_size_override("font_size", 24)
	top.add_child(_coins)
	_gems = Label.new()
	_gems.add_theme_font_size_override("font_size", 24)
	_gems.add_theme_color_override("font_color", Color(1, 0.55, 0.65))
	top.add_child(_gems)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 90
	v.offset_right = -90
	v.offset_top = 74
	v.offset_bottom = -12
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	_left = Label.new()
	_left.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_left.add_theme_font_size_override("font_size", 18)
	v.add_child(_left)
	for id in GameState.weekly_tasks():
		v.add_child(_row(id))
	# Bonus: hamma vazifa bajarilsa oltin sandiq
	var bp := PanelContainer.new()
	bp.custom_minimum_size = Vector2(0, 72)
	bp.add_theme_stylebox_override("panel", UITheme.box(Color(0.3, 0.2, 0.08, 0.95), Painter.GOLD, 12, 3))
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 14)
	bp.add_child(bh)
	var chest := Control.new()
	chest.custom_minimum_size = Vector2(70, 60)
	chest.draw.connect(func() -> void:
		var col: Array = GameData.chests.chests[str(GameData.weekly.bonus.id)].color
		ChestArt.draw(chest, chest.size * 0.5 + Vector2(0, 8), 0.42, Color(col[0], col[1], col[2]), 0.0, 0.6 + 0.4 * sin(_t * 3.0)))
	bh.add_child(chest)
	var bl := Label.new()
	bl.text = tr("WEEKLY_BONUS") % tr(str(GameData.chests.chests[str(GameData.weekly.bonus.id)].name))
	bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bl.add_theme_font_size_override("font_size", 19)
	bl.add_theme_color_override("font_color", Painter.GOLD)
	bh.add_child(bl)
	_bonus_btn = Button.new()
	_bonus_btn.custom_minimum_size = Vector2(150, 50)
	_bonus_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bonus_btn.pressed.connect(func() -> void:
		if GameState.claim_weekly_bonus():
			Sfx.play("victory", 0.7, 0.0)
		_refresh())
	bh.add_child(_bonus_btn)
	v.add_child(bp)
	_rows.append(["", chest, null, null])
	_refresh()
	Sfx.play_music("menu")


static func reward_text(r: Dictionary) -> String:
	match str(r.type):
		"coins":
			return "◉ %d" % int(r.amount)
		"gems":
			return "♦ %d" % int(r.amount)
		"chest":
			return "▣ ×%d" % int(r.get("count", 1))
	return ""


func _row(id: String) -> PanelContainer:
	var t: Dictionary = GameData.weekly.pool[id]
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(0, 74)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(56, 56)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(icon)
	var vv := VBoxContainer.new()
	vv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vv.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(vv)
	var desc := Label.new()
	desc.text = tr("MET_" + str(t.metric).to_upper()) % int(t.target)
	desc.add_theme_font_size_override("font_size", 19)
	vv.add_child(desc)
	var pb := ProgressBar.new()
	pb.custom_minimum_size = Vector2(0, 16)
	pb.show_percentage = false
	pb.max_value = float(t.target)
	pb.add_theme_stylebox_override("fill", UITheme.fill(Color(0.3, 0.7, 0.3)))
	vv.add_child(pb)
	var rw := Label.new()
	rw.text = reward_text(t.reward)
	rw.custom_minimum_size = Vector2(90, 0)
	rw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rw.add_theme_font_size_override("font_size", 22)
	if str(t.reward.type) == "gems":
		rw.add_theme_color_override("font_color", Color(1, 0.55, 0.65))
	h.add_child(rw)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(150, 50)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_stylebox_override("normal", UITheme.box(Color(0.2, 0.45, 0.2), Painter.GOLD, 10, 2))
	btn.pressed.connect(func() -> void:
		if GameState.claim_weekly(id):
			Sfx.play("coin", 0.9, 0.0)
		_refresh())
	h.add_child(btn)
	_rows.append([id, icon, pb, btn])
	return p


func _refresh() -> void:
	var p: Dictionary = GameState.progress
	var today := GameState.today()
	_coins.text = "◉ %d" % int(p.coins)
	_gems.text = "♦ %d" % int(p.gems)
	_left.text = tr("WEEKLY_DAYS_LEFT") % Weekly.days_left(today)
	for r in _rows:
		var id: String = r[0]
		if id == "":
			continue
		var t: Dictionary = GameData.weekly.pool[id]
		var val := Weekly.progress_of(GameData.weekly, p, id)
		var done: bool = id in p.weekly.get("claimed", [])
		var ready := Weekly.claimable(GameData.weekly, p, id, today)
		r[2].value = val
		var btn: Button = r[3]
		if done:
			btn.text = "✓ " + tr("CLAIMED")
			btn.disabled = true
		elif ready:
			btn.text = tr("CLAIM")
			btn.disabled = false
		else:
			btn.text = "%d / %d" % [val, int(t.target)]
			btn.disabled = true
		var icon: Control = r[1]
		for c in icon.draw.get_connections():
			icon.draw.disconnect(c.callable)
		var metric := str(t.metric)
		icon.draw.connect(func() -> void:
			var c := icon.size * 0.5
			var col := Painter.GOLD if done or ready else Color(0.62, 0.56, 0.48)
			icon.draw_circle(c, 27.0, Color(0.2, 0.12, 0.06))
			_metric_icon(icon, c, metric, col)
			if done:
				icon.draw_line(c + Vector2(4, 10), c + Vector2(10, 16), Color(0.3, 0.9, 0.3), 4.0)
				icon.draw_line(c + Vector2(10, 16), c + Vector2(22, 2), Color(0.3, 0.9, 0.3), 4.0))
		icon.queue_redraw()
	if bool(p.weekly.get("bonus", false)):
		_bonus_btn.text = "✓ " + tr("CLAIMED")
		_bonus_btn.disabled = true
	elif Weekly.bonus_ready(GameData.weekly, p, today):
		_bonus_btn.text = tr("CLAIM")
		_bonus_btn.disabled = false
	else:
		var n := 0
		for id in GameState.weekly_tasks():
			if id in p.weekly.get("claimed", []):
				n += 1
		_bonus_btn.text = "%d / %d" % [n, GameState.weekly_tasks().size()]
		_bonus_btn.disabled = true


static func _metric_icon(ci: CanvasItem, c: Vector2, metric: String, col: Color) -> void:
	match metric:
		"wins", "boss_wins":
			# Bayroq
			ci.draw_line(c + Vector2(-10, 16), c + Vector2(-10, -16), col, 3.0)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, -16), c + Vector2(14, -10), c + Vector2(-10, -3)]), col)
		"kills", "battles":
			# Qilichlar
			ci.draw_line(c + Vector2(-13, 13), c + Vector2(13, -13), col, 4.0)
			ci.draw_line(c + Vector2(13, 13), c + Vector2(-13, -13), col, 4.0)
		"stars_gained":
			var pts := PackedVector2Array()
			for i in 10:
				pts.append(c + Vector2.from_angle(-PI / 2 + i * PI / 5) * (16.0 if i % 2 == 0 else 7.0))
			ci.draw_colored_polygon(pts, col)
		"waves":
			ci.draw_rect(Rect2(c + Vector2(-11, -8), Vector2(22, 22)), col)
			for i in 3:
				ci.draw_rect(Rect2(c + Vector2(-11 + i * 8, -15), Vector2(6, 7)), col)
		"chests":
			ci.draw_rect(Rect2(c + Vector2(-14, -6), Vector2(28, 18)), col)
			ci.draw_rect(Rect2(c + Vector2(-14, -13), Vector2(28, 6)), col.darkened(0.25))
		"tactics":
			ci.draw_circle(c, 14.0, col)
			ci.draw_circle(c, 7.0, Color(0.2, 0.12, 0.06))
		_:
			ci.draw_circle(c, 12.0, col)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _rows.size() > 0 and _rows[_rows.size() - 1][0] == "":
		(_rows[_rows.size() - 1][1] as Control).queue_redraw()


func _draw() -> void:
	MenuArt.backdrop(self, size, _t)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
