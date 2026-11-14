extends Control
## Libos: qo'shin kiyim to'plamlari (faqat ko'rinish, kuch bermaydi).

var _t := 0.0
var _preview := ""
var _units: Array[UnitState] = []
var _cards: Array = []
var _coins: Label
var _gems: Label
var _msg: Label
var _msg_t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.make()
	_preview = str(GameState.progress.get("outfit", "classic"))
	for type in ["worker", "swordsman", "spearman", "archer", "cavalry"]:
		var u := UnitState.new()
		u.type = type
		u.def = GameData.units[type]
		u.team = 0
		u.facing = 1
		u.hp = 1.0
		u.max_hp = 1.0
		_units.append(u)
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
		GameState.apply_outfit()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	top.add_child(back)
	var title := Label.new()
	title.text = tr("MENU_OUTFITS")
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
	var note := Label.new()
	note.text = tr("OUTFIT_NOTE")
	note.set_anchors_preset(Control.PRESET_TOP_WIDE)
	note.offset_top = 66
	note.offset_bottom = 92
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 16)
	add_child(note)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	row.offset_bottom = -16
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	for id in GameData.outfits.order:
		row.add_child(_card(id))
	_msg = Label.new()
	_msg.set_anchors_preset(Control.PRESET_CENTER)
	_msg.offset_left = -300
	_msg.offset_right = 300
	_msg.offset_top = 10
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.add_theme_font_size_override("font_size", 24)
	add_child(_msg)
	_refresh()
	Sfx.play_music("menu")


func _card(id: String) -> PanelContainer:
	var o: Dictionary = GameData.outfits.outfits[id]
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(190, 170)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var sw := Control.new()
	sw.custom_minimum_size = Vector2(0, 52)
	var cols := Painter.outfit_colors(o)
	sw.draw.connect(func() -> void:
		for i in 4:
			var c := Vector2(sw.size.x * 0.5 + (i - 1.5) * 34.0, 26)
			sw.draw_circle(c, 15.0, Color(0, 0, 0, 0.4))
			sw.draw_circle(c, 13.0, cols[i]))
	v.add_child(sw)
	var nm := Label.new()
	nm.text = tr(str(o.name))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 18)
	nm.add_theme_color_override("font_color", Painter.GOLD)
	v.add_child(nm)
	var look := Button.new()
	look.text = tr("PREVIEW")
	look.custom_minimum_size = Vector2(0, 34)
	look.add_theme_font_size_override("font_size", 15)
	look.pressed.connect(func() -> void:
		Sfx.play("click", 0.7)
		_preview = id
		_refresh())
	v.add_child(look)
	var act := Button.new()
	act.custom_minimum_size = Vector2(0, 40)
	act.add_theme_font_size_override("font_size", 16)
	act.pressed.connect(_act.bind(id))
	v.add_child(act)
	_cards.append([id, p, act])
	return p


func _act(id: String) -> void:
	_preview = id
	if id in GameState.progress.outfits:
		GameState.equip_outfit(id)
		Sfx.play("ready", 0.8, 0.0)
		_flash(tr("OUTFIT_EQUIPPED"))
	elif GameState.buy_outfit(id):
		GameState.equip_outfit(id)
		Sfx.play("coin", 0.9, 0.0)
		_flash(tr("OUTFIT_EQUIPPED"))
	else:
		Sfx.play("deny", 0.7)
		_flash(tr("NOT_ENOUGH"))
	_refresh()


func _flash(text: String) -> void:
	_msg.text = text
	_msg_t = 2.0


func _refresh() -> void:
	_coins.text = "◉ %d" % int(GameState.progress.coins)
	_gems.text = "♦ %d" % int(GameState.progress.gems)
	var equipped := str(GameState.progress.get("outfit", "classic"))
	for c in _cards:
		var id: String = c[0]
		var o: Dictionary = GameData.outfits.outfits[id]
		var act: Button = c[2]
		var owned: bool = id in GameState.progress.outfits
		var sel := id == _preview
		c[1].add_theme_stylebox_override("panel", UITheme.box(Color(0.18, 0.11, 0.06, 0.9), Painter.GOLD if sel else Color(0.55, 0.4, 0.2), 12, 4 if sel else 2))
		if id == equipped:
			act.text = "✓ " + tr("EQUIPPED")
			act.disabled = true
		elif owned:
			act.text = tr("EQUIP")
			act.disabled = false
		else:
			act.text = ("◉ %d" % int(o.price_coins)) if int(o.price_gems) == 0 else ("♦ %d" % int(o.price_gems))
			act.disabled = false
	# Ko'rinish: tanlangan libosni vaqtincha qo'llash
	if _preview == "classic":
		Painter.player_outfit = []
	else:
		Painter.player_outfit = Painter.outfit_colors(GameData.outfits.outfits[_preview])


func _process(delta: float) -> void:
	_t += delta
	if _msg_t > 0.0:
		_msg_t -= delta
		_msg.modulate.a = clampf(_msg_t * 2.0, 0.0, 1.0)
	for i in _units.size():
		_units[i].walk_phase += delta * 4.0
		_units[i].moving = fmod(_t + i, 5.0) < 1.5
		_units[i].attack_anim = 0.3 if fmod(_t * 0.7 + i * 0.6, 3.0) < 0.3 else 0.0
	queue_redraw()


func _exit_tree() -> void:
	GameState.apply_outfit()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.55), Vector2(0, h * 0.55)]),
		PackedColorArray([Color(0.45, 0.65, 0.9), Color(0.45, 0.65, 0.9), Color(0.85, 0.9, 0.95), Color(0.85, 0.9, 0.95)]))
	var pts := PackedVector2Array([Vector2(0, h)])
	for i in 17:
		pts.append(Vector2(w * i / 16.0, h * 0.5 - sin(i * 0.9) * 22.0 - sin(i * 0.37) * 18.0))
	pts.append(Vector2(w, h))
	draw_colored_polygon(pts, Color(0.48, 0.62, 0.32))
	# O'tovlar
	for k in 3:
		var yx := w * (0.15 + k * 0.35)
		var yy := h * 0.5 - 4.0
		draw_rect(Rect2(yx - 34, yy - 30, 68, 32), Color(0.92, 0.88, 0.78))
		draw_colored_polygon(PackedVector2Array([Vector2(yx - 40, yy - 28), Vector2(yx, yy - 58), Vector2(yx + 40, yy - 28)]), Color(0.85, 0.8, 0.68))
		draw_rect(Rect2(yx - 8, yy - 22, 16, 24), Color(0.55, 0.25, 0.15))
		draw_line(Vector2(yx - 36, yy - 18), Vector2(yx + 36, yy - 18), Color(0.7, 0.2, 0.15), 3.0)
	draw_rect(Rect2(0, h * 0.62, w, h * 0.38), Color(0.4, 0.55, 0.26))
	# Askarlar safi
	for i in _units.size():
		var x := w * (0.2 + i * 0.15)
		var y := h * 0.58
		draw_set_transform(Vector2(x, y), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, 40.0, Color(0, 0, 0, 0.2))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		Painter.draw_unit(self, _units[i], Vector2(x, y), 2.1 if _units[i].type != "cavalry" else 1.7, _t)
