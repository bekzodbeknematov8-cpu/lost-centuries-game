extends Control
## Bosh menyu: O'YNASH + Hiylalar / Libos / Sandiqlar / Bozor + pastki ikonkalar.

var _t := 0.0
var _heroes: Array[UnitState] = []
var _settings: PanelContainer
var _toast: Label
var _toast_t := 0.0
var _coins: Label
var _gems: Label


class CurrencyIcon:
	## Tanga (dumaloq oltin) yoki la'l (qizil qirrali tosh).
	extends Control
	var gem := false

	func _init(is_gem: bool) -> void:
		gem = is_gem
		custom_minimum_size = Vector2(26, 26)

	func _draw() -> void:
		var c := size * 0.5
		if gem:
			var pts := PackedVector2Array([c + Vector2(-11, -4), c + Vector2(-6, -10), c + Vector2(6, -10), c + Vector2(11, -4), c + Vector2(0, 11)])
			draw_colored_polygon(pts, Color(0.85, 0.12, 0.28))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -10), c + Vector2(6, -10), c + Vector2(3, -4), c + Vector2(-3, -4)]), Color(1, 0.55, 0.65))
			draw_line(c + Vector2(-11, -4), c + Vector2(11, -4), Color(0.55, 0.05, 0.15), 1.5)
		else:
			draw_circle(c, 11.0, Color(0.75, 0.55, 0.1))
			draw_circle(c, 8.5, Painter.GOLD)
			draw_circle(c + Vector2(-3, -3), 2.5, Color(1, 1, 0.85))


class RoundIcon:
	## Pastki dumaloq ikonkalar (taqvim, toj, kubok, sozlamalar).
	extends Button
	var kind := ""

	func _init(k: String) -> void:
		kind = k
		custom_minimum_size = Vector2(76, 76)
		focus_mode = Control.FOCUS_NONE
		for st in ["normal", "hover", "pressed"]:
			var bg := Color(0.16, 0.1, 0.06, 0.82) if st != "pressed" else Color(0.4, 0.25, 0.1, 0.9)
			add_theme_stylebox_override(st, UITheme.box(bg, Color(0.86, 0.6, 0.2, 0.8), 38, 3))

	func _draw() -> void:
		var c := size * 0.5
		var g := Painter.GOLD
		match kind:
			"daily":
				draw_rect(Rect2(c + Vector2(-17, -13), Vector2(34, 30)), g)
				draw_rect(Rect2(c + Vector2(-17, -13), Vector2(34, 9)), Color(0.75, 0.2, 0.15))
				for i in 2:
					draw_line(c + Vector2(-9 + i * 18, -18), c + Vector2(-9 + i * 18, -10), Color(0.3, 0.2, 0.1), 3.0)
				draw_string(get_theme_default_font(), c + Vector2(-17, 13), str(Time.get_date_dict_from_system().day), HORIZONTAL_ALIGNMENT_CENTER, 34, 15, Color(0.3, 0.18, 0.08))
			"crown":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-18, 10), c + Vector2(-18, -10), c + Vector2(-9, 0), c + Vector2(0, -15), c + Vector2(9, 0), c + Vector2(18, -10), c + Vector2(18, 10)]), g)
			"trophy":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-14, -16), c + Vector2(14, -16), c + Vector2(10, 2), c + Vector2(-10, 2)]), g)
				draw_arc(c + Vector2(-14, -8), 7.0, PI * 0.5, PI * 1.5, 8, g, 3.0)
				draw_arc(c + Vector2(14, -8), 7.0, -PI * 0.5, PI * 0.5, 8, g, 3.0)
				draw_rect(Rect2(c + Vector2(-3, 2), Vector2(6, 8)), g)
				draw_rect(Rect2(c + Vector2(-11, 10), Vector2(22, 6)), g)
			"gear":
				for i in 8:
					var a := TAU * i / 8.0
					draw_line(c + Vector2.from_angle(a) * 10.0, c + Vector2.from_angle(a) * 19.0, g, 7.0)
				draw_circle(c, 13.0, g)
				draw_circle(c, 5.0, Color(0.16, 0.1, 0.06))


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.make()
	for h in ["temur", "chingiz"]:
		var u := UnitState.new()
		u.type = h
		u.def = GameData.heroes[h]
		u.team = 0
		u.facing = 1
		u.hp = 1.0
		u.max_hp = 1.0
		u.hero = true
		_heroes.append(u)
	_build()
	Sfx.play_music("menu")


func _build() -> void:
	for c in get_children():
		c.queue_free()
	# Yuqori chap: valyutalar
	var res := HBoxContainer.new()
	res.position = Vector2(16, 12)
	res.add_theme_constant_override("separation", 10)
	add_child(res)
	_coins = _currency_chip(res, Painter.GOLD)
	_gems = _currency_chip(res, Color(0.85, 0.15, 0.3))

	# O'ng tomon: sarlavha va tugmalar
	var right := VBoxContainer.new()
	right.anchor_left = 0.42
	right.anchor_right = 1.0
	right.anchor_top = 0.0
	right.anchor_bottom = 1.0
	right.offset_top = 40
	right.offset_right = -24
	right.alignment = BoxContainer.ALIGNMENT_BEGIN
	right.add_theme_constant_override("separation", 14)
	add_child(right)
	var title := Label.new()
	title.text = tr("GAME_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", Painter.GOLD)
	title.add_theme_constant_override("outline_size", 14)
	right.add_child(title)
	var sub := Label.new()
	sub.text = tr("MENU_SUBTITLE")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 26)
	right.add_child(sub)
	var play := Button.new()
	play.text = tr("PLAY")
	play.custom_minimum_size = Vector2(340, 92)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.add_theme_font_size_override("font_size", 46)
	play.add_theme_stylebox_override("normal", UITheme.box(Color(0.72, 0.12, 0.08), Painter.GOLD, 18, 5))
	play.add_theme_stylebox_override("hover", UITheme.box(Color(0.82, 0.18, 0.1), Painter.GOLD, 18, 5))
	play.add_theme_stylebox_override("pressed", UITheme.box(Color(0.55, 0.1, 0.06), Painter.GOLD, 18, 5))
	play.pressed.connect(func() -> void:
		Sfx.play("horn_attack", 0.7, 0.0)
		get_tree().change_scene_to_file("res://scenes/mode_select.tscn"))
	right.add_child(play)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	right.add_child(row)
	for d in [["WORKSHOP", Color(0.15, 0.4, 0.65)], ["MENU_TACTICS", Color(0.8, 0.38, 0.1)], ["MENU_OUTFITS", Color(0.75, 0.62, 0.1)], ["MENU_CHESTS", Color(0.2, 0.55, 0.22)], ["MENU_MARKET", Color(0.5, 0.2, 0.6)]]:
		var b := Button.new()
		b.text = tr(d[0])
		b.custom_minimum_size = Vector2(136, 60)
		b.add_theme_font_size_override("font_size", 18)
		var col: Color = d[1]
		b.add_theme_stylebox_override("normal", UITheme.box(col, col.lightened(0.35), 12, 3))
		b.add_theme_stylebox_override("hover", UITheme.box(col.lightened(0.12), col.lightened(0.45), 12, 3))
		b.add_theme_stylebox_override("pressed", UITheme.box(col.darkened(0.2), col.lightened(0.35), 12, 3))
		if d[0] == "WORKSHOP":
			b.pressed.connect(func() -> void:
				Sfx.play("click", 0.7)
				get_tree().change_scene_to_file("res://scenes/workshop.tscn"))
		else:
			b.pressed.connect(_coming_soon)
		row.add_child(b)
	var note := Label.new()
	note.text = "%s  v%s" % [tr("PROTOTYPE_NOTE"), ProjectSettings.get_setting("application/config/version")]
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 14)
	note.modulate = Color(1, 1, 1, 0.6)
	right.add_child(note)

	# Pastki o'ng: dumaloq ikonkalar
	var icons := HBoxContainer.new()
	icons.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	icons.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	icons.grow_vertical = Control.GROW_DIRECTION_BEGIN
	icons.offset_right = -18
	icons.offset_bottom = -16
	icons.add_theme_constant_override("separation", 12)
	add_child(icons)
	for k in ["daily", "crown", "trophy", "gear"]:
		var ic := RoundIcon.new(k)
		ic.pressed.connect(_open_settings if k == "gear" else _coming_soon)
		icons.add_child(ic)

	_build_settings()
	_toast = Label.new()
	_toast.anchor_left = 0.5
	_toast.anchor_right = 0.5
	_toast.anchor_top = 1.0
	_toast.anchor_bottom = 1.0
	_toast.offset_left = -300
	_toast.offset_right = 300
	_toast.offset_top = -140
	_toast.offset_bottom = -100
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 26)
	_toast.visible = false
	add_child(_toast)


func _currency_chip(parent: Control, col: Color) -> Label:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.box(Color(0.12, 0.07, 0.04, 0.8), Color(0.86, 0.6, 0.2, 0.7), 14, 2))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	var icon := CurrencyIcon.new(col != Painter.GOLD)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(icon)
	var l := Label.new()
	l.add_theme_font_size_override("font_size", 22)
	l.custom_minimum_size = Vector2(60, 0)
	h.add_child(l)
	parent.add_child(p)
	return l


func _build_settings() -> void:
	_settings = PanelContainer.new()
	_settings.set_anchors_preset(Control.PRESET_CENTER)
	_settings.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_settings.grow_vertical = Control.GROW_DIRECTION_BOTH
	_settings.custom_minimum_size = Vector2(460, 0)
	_settings.visible = false
	add_child(_settings)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_settings.add_child(v)
	var t := Label.new()
	t.text = tr("SETTINGS")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 36)
	t.add_theme_color_override("font_color", Painter.GOLD)
	v.add_child(t)
	var s: Dictionary = GameState.settings
	for item in [
		[tr("MENU_LANGUAGE"), _on_lang],
		["%s: %s" % [tr("MENU_SOUND"), tr("ON") if float(s.sfx_volume) > 0.0 else tr("OFF")], _on_sound],
		["%s: %s" % [tr("MENU_MUSIC"), tr("ON") if float(s.music_volume) > 0.0 else tr("OFF")], _on_music],
		[tr("CLOSE"), func() -> void:
			Sfx.play("click", 0.7)
			_settings.visible = false],
	]:
		var b := Button.new()
		b.text = item[0]
		b.custom_minimum_size = Vector2(420, 58)
		b.pressed.connect(item[1])
		v.add_child(b)


func _open_settings() -> void:
	Sfx.play("click", 0.7)
	_settings.visible = true


func _coming_soon() -> void:
	Sfx.play("click", 0.7)
	_toast.text = tr("COMING_SOON")
	_toast_t = 1.8
	_toast.visible = true


func _rebuild_keep_settings() -> void:
	_build()
	_settings.visible = true


func _on_lang() -> void:
	Sfx.play("click", 0.7)
	GameState.next_locale()
	_rebuild_keep_settings()


func _on_sound() -> void:
	GameState.settings.sfx_volume = 0.0 if float(GameState.settings.sfx_volume) > 0.0 else 0.9
	GameState.save_settings()
	Sfx.play("click", 0.7)
	_rebuild_keep_settings()


func _on_music() -> void:
	GameState.settings.music_volume = 0.0 if float(GameState.settings.music_volume) > 0.0 else 0.7
	GameState.save_settings()
	Sfx.update_music_volume()
	_rebuild_keep_settings()


func _process(delta: float) -> void:
	_t += delta
	for i in _heroes.size():
		_heroes[i].walk_phase += delta * (2.0 + i)
		_heroes[i].moving = fmod(_t + i * 2.0, 6.0) < 1.2
	if _coins:
		_coins.text = str(int(GameState.progress.get("coins", 0)))
		_gems.text = str(int(GameState.progress.get("gems", 0)))
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t * 2.0, 0.0, 1.0)
		_toast.visible = _toast_t > 0.0
	queue_redraw()


func _draw() -> void:
	MenuArt.backdrop(self, size, _t)
	# Katta qahramonlar (chapda)
	var base_y := size.y * 0.7 + 150.0
	Painter.draw_unit(self, _heroes[1], Vector2(size.x * 0.12, base_y - 30.0), 2.3, _t)
	Painter.draw_unit(self, _heroes[0], Vector2(size.x * 0.26, base_y), 2.9, _t)
