extends Control
## Hiylalar: jangda bir martalik kuchlarni tangaga sotib olish.

var _t := 0.0
var _coins: Label
var _cards: Array = []
var _msg: Label
var _msg_t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.make()
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_right = -16
	top.offset_top = 10
	add_child(top)
	var back := Button.new()
	back.text = "‹ " + tr("BACK")
	back.custom_minimum_size = Vector2(130, 52)
	back.pressed.connect(func() -> void:
		Sfx.play("click", 0.7)
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	top.add_child(back)
	var title := Label.new()
	title.text = tr("MENU_TACTICS")
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Painter.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	_coins = Label.new()
	_coins.add_theme_font_size_override("font_size", 28)
	top.add_child(_coins)
	var hint := Label.new()
	hint.text = tr("TACTICS_HINT") % int(GameData.tactics.per_battle)
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_top = 70
	hint.offset_bottom = 100
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	add_child(hint)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.set_anchors_preset(Control.PRESET_CENTER)
	grid.grow_horizontal = Control.GROW_DIRECTION_BOTH
	grid.grow_vertical = Control.GROW_DIRECTION_BOTH
	grid.offset_top = 40
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	add_child(grid)
	for id in GameData.tactics.order:
		grid.add_child(_card(id))
	_msg = Label.new()
	_msg.anchor_left = 0.5
	_msg.anchor_right = 0.5
	_msg.anchor_top = 1.0
	_msg.anchor_bottom = 1.0
	_msg.offset_left = -300
	_msg.offset_right = 300
	_msg.offset_top = -50
	_msg.offset_bottom = -16
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.add_theme_font_size_override("font_size", 22)
	add_child(_msg)
	_refresh()
	Sfx.play_music("menu")


func _card(id: String) -> PanelContainer:
	var d: Dictionary = GameData.tactics.tactics[id]
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(330, 190)
	p.add_theme_stylebox_override("panel", UITheme.box(Color(0.9, 0.86, 0.74), Color(0.3, 0.4, 0.6), 12, 3))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var ic := Control.new()
	ic.custom_minimum_size = Vector2(56, 56)
	ic.draw.connect(func() -> void:
		ic.draw_circle(ic.size * 0.5, 26.0, Color(0.25, 0.35, 0.55))
		TacticArt.draw(ic, str(d.icon), ic.size * 0.5, 1.3))
	top.add_child(ic)
	var nv := VBoxContainer.new()
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(nv)
	var name := Label.new()
	name.text = tr(str(d.name))
	name.add_theme_color_override("font_color", Color(0.15, 0.2, 0.35))
	name.add_theme_constant_override("outline_size", 0)
	name.add_theme_font_size_override("font_size", 21)
	nv.add_child(name)
	var owned := Label.new()
	owned.add_theme_color_override("font_color", Color(0.35, 0.25, 0.1))
	owned.add_theme_constant_override("outline_size", 0)
	owned.add_theme_font_size_override("font_size", 16)
	nv.add_child(owned)
	var desc := Label.new()
	desc.text = tr(str(d.desc))
	desc.add_theme_color_override("font_color", Color(0.3, 0.22, 0.12))
	desc.add_theme_constant_override("outline_size", 0)
	desc.add_theme_font_size_override("font_size", 15)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc)
	var btn := Button.new()
	btn.text = "◉ %d" % int(d.price)
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_stylebox_override("normal", UITheme.box(Color(0.2, 0.45, 0.2), Painter.GOLD, 10, 2))
	btn.add_theme_stylebox_override("hover", UITheme.box(Color(0.25, 0.55, 0.25), Painter.GOLD, 10, 2))
	btn.pressed.connect(func() -> void:
		if GameState.buy_tactic(id):
			Sfx.play("coin", 0.9, 0.0)
			_flash(tr("TACTIC_BOUGHT"))
		else:
			Sfx.play("deny", 0.7)
			_flash(tr("NOT_ENOUGH_COINS"))
		_refresh())
	v.add_child(btn)
	_cards.append([id, owned, btn])
	return p


func _flash(text: String) -> void:
	_msg.text = text
	_msg_t = 2.0


func _refresh() -> void:
	_coins.text = "◉ %d" % int(GameState.progress.coins)
	for c in _cards:
		c[1].text = tr("OWNED_N") % GameState.tactic_count(c[0])
		c[2].disabled = int(GameState.progress.coins) < int(GameData.tactics.tactics[c[0]].price)


func _process(delta: float) -> void:
	_t += delta
	if _msg_t > 0.0:
		_msg_t -= delta
		_msg.modulate.a = clampf(_msg_t * 2.0, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0.12, 0.18, 0.32))
	var x := -60.0
	var i := 0
	while x < w + 60.0:
		if i % 2 == 0:
			draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 60, 0), Vector2(x + 48, h), Vector2(x - 12, h)]), Color(0.16, 0.24, 0.4))
		x += 60.0
		i += 1
	for k in 30:
		var px := fmod(k * 131.0 + _t * 10.0, w)
		var py := fmod(k * 71.0, h)
		draw_circle(Vector2(px, py), 1.5 + (k % 3), Color(1, 0.9, 0.6, 0.25 + 0.15 * sin(_t * 2.0 + k)))
