extends Control
## Yutuqlar: ko'rsatkich, progress va mukofotni olish.

var _t := 0.0
var _rows: Array = []
var _coins: Label
var _gems: Label


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
		Transition.go("res://scenes/main_menu.tscn"))
	top.add_child(back)
	var title := Label.new()
	title.text = tr("ACHIEVEMENTS")
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
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 60
	scroll.offset_right = -60
	scroll.offset_top = 80
	scroll.offset_bottom = -16
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	for id in GameData.achievements.order:
		list.add_child(_row(id))
	_refresh()
	Sfx.play_music("menu")


func _row(id: String) -> PanelContainer:
	var a: Dictionary = GameData.achievements.list[id]
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(0, 84)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(icon)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var nm := Label.new()
	nm.text = tr("ACH_" + id.to_upper())
	nm.add_theme_font_size_override("font_size", 21)
	nm.add_theme_color_override("font_color", Painter.GOLD)
	v.add_child(nm)
	var desc := Label.new()
	var mkey := "MET_" + str(a.metric).to_upper()
	if int(a.target) == 1 and tr(mkey + "_1") != mkey + "_1":
		desc.text = tr(mkey + "_1")
	else:
		desc.text = tr(mkey) % int(a.target)
	desc.add_theme_font_size_override("font_size", 15)
	v.add_child(desc)
	var pb := ProgressBar.new()
	pb.custom_minimum_size = Vector2(0, 18)
	pb.show_percentage = false
	pb.max_value = float(a.target)
	pb.add_theme_stylebox_override("fill", UITheme.fill(Color(0.3, 0.7, 0.3)))
	v.add_child(pb)
	var rw := Label.new()
	var r: Dictionary = a.reward
	rw.text = ("◉ %d" if str(r.type) == "coins" else "♦ %d") % int(r.amount)
	rw.custom_minimum_size = Vector2(90, 0)
	rw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rw.add_theme_font_size_override("font_size", 22)
	h.add_child(rw)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(150, 54)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_stylebox_override("normal", UITheme.box(Color(0.2, 0.45, 0.2), Painter.GOLD, 10, 2))
	btn.pressed.connect(func() -> void:
		if GameState.claim_achievement(id):
			Sfx.play("victory", 0.6, 0.0)
		_refresh())
	h.add_child(btn)
	_rows.append([id, icon, pb, btn])
	return p


func _refresh() -> void:
	_coins.text = "◉ %d" % int(GameState.progress.coins)
	_gems.text = "♦ %d" % int(GameState.progress.gems)
	var ho := GameState.heroes_owned_count()
	for r in _rows:
		var id: String = r[0]
		var a: Dictionary = GameData.achievements.list[id]
		var val := Achievements.metric(GameState.progress, str(a.metric), ho)
		var done: bool = id in GameState.progress.ach_claimed
		var ready := Achievements.claimable(GameData.achievements, GameState.progress, id, ho)
		r[2].value = mini(val, int(a.target))
		var btn: Button = r[3]
		if done:
			btn.text = "✓ " + tr("CLAIMED")
			btn.disabled = true
		elif ready:
			btn.text = tr("CLAIM")
			btn.disabled = false
		else:
			btn.text = "%d / %d" % [mini(val, int(a.target)), int(a.target)]
			btn.disabled = true
		var icon: Control = r[1]
		for c in icon.draw.get_connections():
			icon.draw.disconnect(c.callable)
		icon.draw.connect(func() -> void:
			var c := icon.size * 0.5
			var col := Painter.GOLD if done or ready else Color(0.5, 0.45, 0.4)
			icon.draw_circle(c, 30.0, Color(0.2, 0.12, 0.06))
			icon.draw_colored_polygon(PackedVector2Array([c + Vector2(-16, -18), c + Vector2(16, -18), c + Vector2(11, 2), c + Vector2(-11, 2)]), col)
			icon.draw_rect(Rect2(c + Vector2(-3, 2), Vector2(6, 9)), col)
			icon.draw_rect(Rect2(c + Vector2(-12, 11), Vector2(24, 6)), col)
			if done:
				icon.draw_line(c + Vector2(-8, -8), c + Vector2(-2, -2), Color(0.1, 0.4, 0.1), 4.0)
				icon.draw_line(c + Vector2(-2, -2), c + Vector2(9, -14), Color(0.1, 0.4, 0.1), 4.0))
		icon.queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	MenuArt.backdrop(self, size, _t)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
