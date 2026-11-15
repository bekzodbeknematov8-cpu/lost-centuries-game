extends Control
## Kampaniya saqlash slotlari: 3 ta, har birida progress % va qiyinlik.

var _t := 0.0
var _diff_panel: PanelContainer
var _confirm: PanelContainer
var _pending := -1
var _row: HBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.make()
	var back := Button.new()
	back.text = "‹ " + tr("BACK")
	back.position = Vector2(16, 12)
	back.custom_minimum_size = Vector2(130, 52)
	back.pressed.connect(func() -> void:
		Sfx.play("click", 0.7)
		get_tree().change_scene_to_file("res://scenes/mode_select.tscn"))
	add_child(back)
	var title := Label.new()
	title.text = tr("CAMPAIGN")
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 70
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Painter.GOLD)
	title.add_theme_constant_override("outline_size", 12)
	add_child(title)
	_row = HBoxContainer.new()
	_row.set_anchors_preset(Control.PRESET_CENTER)
	_row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_row.grow_vertical = Control.GROW_DIRECTION_BOTH
	_row.offset_top = 50
	_row.add_theme_constant_override("separation", 26)
	add_child(_row)
	_build_cards()
	_build_difficulty()
	_build_confirm()
	Sfx.play_music("menu")


func _total_levels() -> int:
	var n := 0
	for cid in GameData.campaigns.order:
		n += Campaign.all_levels(GameData.campaigns, cid).size()
	return n


func _build_cards() -> void:
	for c in _row.get_children():
		c.queue_free()
	var slots: Array = GameState.progress.slots
	var total := _total_levels()
	for i in slots.size():
		var sl: Dictionary = slots[i]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(300, 300)
		var active: bool = i == int(GameState.progress.active_slot) and bool(sl.used)
		card.add_theme_stylebox_override("panel", UITheme.box(Color(0.3, 0.18, 0.08, 0.95), Painter.GOLD if active else Color(0.75, 0.55, 0.25), 16, 5 if active else 3))
		_row.add_child(card)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 10)
		card.add_child(v)
		var pic := Control.new()
		pic.custom_minimum_size = Vector2(0, 110)
		pic.draw.connect(func() -> void:
			var r := Rect2(Vector2.ZERO, pic.size)
			var sky := Color(0.15, 0.2, 0.4) if bool(sl.used) else Color(0.35, 0.25, 0.15)
			pic.draw_rect(r, sky)
			if bool(sl.used):
				pic.draw_circle(Vector2(r.size.x * 0.8, 30), 14.0, Color(0.95, 0.95, 0.85))
				for k in 12:
					pic.draw_circle(Vector2(fmod(k * 53.0, r.size.x), fmod(k * 29.0, 60.0) + 6), 1.5, Color(1, 1, 1, 0.7))
			pic.draw_rect(Rect2(0, r.size.y - 30, r.size.x, 30), Color(0.25, 0.4, 0.2))
			MenuArt.registan(pic, Vector2(r.size.x * 0.5, r.size.y - 26), 0.28, Color(0.12, 0.08, 0.1)))
		v.add_child(pic)
		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 22)
		v.add_child(lbl)
		if bool(sl.used):
			var done := 0
			for k in sl.stars:
				if int(sl.stars[k]) > 0:
					done += 1
			var pct := 100.0 * done / maxf(1.0, total)
			lbl.text = tr("SLOT_N") % (i + 1)
			var pb := ProgressBar.new()
			pb.custom_minimum_size = Vector2(0, 24)
			pb.max_value = 100.0
			pb.show_percentage = false
			pb.value = pct
			pb.add_theme_stylebox_override("fill", UITheme.fill(Color(0.3, 0.7, 0.3)))
			v.add_child(pb)
			var info := Label.new()
			info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			info.add_theme_font_size_override("font_size", 17)
			info.text = "%.0f%%  ·  ★ %d  ·  %s" % [pct, Campaign.total_stars(sl.stars), tr("DIFF_" + str(sl.difficulty).to_upper())]
			v.add_child(info)
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 8)
			v.add_child(h)
			var go := Button.new()
			go.text = tr("CONTINUE")
			go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			go.custom_minimum_size = Vector2(0, 52)
			go.add_theme_stylebox_override("normal", UITheme.box(Color(0.55, 0.15, 0.08), Painter.GOLD))
			go.pressed.connect(_continue.bind(i))
			h.add_child(go)
			var del := Button.new()
			del.text = "✕"
			del.custom_minimum_size = Vector2(52, 52)
			del.pressed.connect(func() -> void:
				Sfx.play("click", 0.7)
				_pending = i
				_confirm.visible = true)
			h.add_child(del)
		else:
			lbl.text = tr("SLOT_EMPTY")
			var sp := Control.new()
			sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
			v.add_child(sp)
			var nb := Button.new()
			nb.text = tr("NEW_CAMPAIGN")
			nb.custom_minimum_size = Vector2(0, 56)
			nb.add_theme_stylebox_override("normal", UITheme.box(Color(0.2, 0.4, 0.6), Painter.GOLD))
			nb.pressed.connect(func() -> void:
				Sfx.play("click", 0.7)
				_pending = i
				_diff_panel.visible = true)
			v.add_child(nb)


func _build_difficulty() -> void:
	_diff_panel = PanelContainer.new()
	_diff_panel.set_anchors_preset(Control.PRESET_CENTER)
	_diff_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_diff_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_diff_panel.visible = false
	add_child(_diff_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_diff_panel.add_child(v)
	var t := Label.new()
	t.text = tr("CHOOSE_DIFFICULTY")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", Painter.GOLD)
	v.add_child(t)
	for d in ["normal", "hard", "legend"]:
		var b := Button.new()
		b.text = tr("DIFF_" + d.to_upper()) + "  —  " + tr("DIFF_" + d.to_upper() + "_DESC")
		b.custom_minimum_size = Vector2(520, 58)
		b.pressed.connect(func() -> void:
			Sfx.play("horn_attack", 0.7, 0.0)
			GameState.create_slot(_pending, d)
			get_tree().change_scene_to_file("res://scenes/campaign_map.tscn"))
		v.add_child(b)
	var close := Button.new()
	close.text = tr("BACK")
	close.custom_minimum_size = Vector2(520, 48)
	close.pressed.connect(func() -> void: _diff_panel.visible = false)
	v.add_child(close)


func _build_confirm() -> void:
	_confirm = PanelContainer.new()
	_confirm.set_anchors_preset(Control.PRESET_CENTER)
	_confirm.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_confirm.grow_vertical = Control.GROW_DIRECTION_BOTH
	_confirm.visible = false
	add_child(_confirm)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	_confirm.add_child(v)
	var t := Label.new()
	t.text = tr("SLOT_DELETE_Q")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(460, 0)
	t.add_theme_font_size_override("font_size", 22)
	v.add_child(t)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	var yes := Button.new()
	yes.text = tr("DELETE")
	yes.custom_minimum_size = Vector2(180, 54)
	yes.add_theme_stylebox_override("normal", UITheme.box(Color(0.6, 0.1, 0.08), Painter.GOLD))
	yes.pressed.connect(func() -> void:
		GameState.delete_slot(_pending)
		_confirm.visible = false
		_build_cards())
	h.add_child(yes)
	var no := Button.new()
	no.text = tr("CANCEL")
	no.custom_minimum_size = Vector2(180, 54)
	no.pressed.connect(func() -> void: _confirm.visible = false)
	h.add_child(no)


func _continue(i: int) -> void:
	Sfx.play("click", 0.7)
	GameState.select_slot(i)
	get_tree().change_scene_to_file("res://scenes/campaign_map.tscn")


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	MenuArt.backdrop(self, size, _t)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.3))
