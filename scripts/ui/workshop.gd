extends Control
## Ustaxona: tangaga doimiy yaxshilanishlar va qahramonlarni ochish.

var _t := 0.0
var _coins: Label
var _cards: Array = []
var _hero_rows: Array = []
var _msg: Label
var _msg_t := 0.0


class UpgradeCard:
	extends PanelContainer
	var id: String
	var screen: Node
	var _btn: Button
	var _desc: Label
	var _icon: Control

	func _init(upg_id: String, s: Node) -> void:
		id = upg_id
		screen = s
		custom_minimum_size = Vector2(250, 170)
		add_theme_stylebox_override("panel", UITheme.box(Color(0.93, 0.85, 0.66), Color(0.55, 0.38, 0.18), 12, 3))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		add_child(v)
		var top := HBoxContainer.new()
		v.add_child(top)
		_icon = Control.new()
		_icon.custom_minimum_size = Vector2(44, 44)
		_icon.draw.connect(_draw_icon)
		top.add_child(_icon)
		var name := Label.new()
		name.text = tr(str(GameData.upgrades.upgrades[id].name))
		name.add_theme_color_override("font_color", Color(0.3, 0.16, 0.06))
		name.add_theme_constant_override("outline_size", 0)
		name.add_theme_font_size_override("font_size", 19)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		top.add_child(name)
		var pips := Control.new()
		pips.custom_minimum_size = Vector2(0, 14)
		pips.draw.connect(func() -> void: _draw_pips(pips))
		v.add_child(pips)
		_desc = Label.new()
		_desc.add_theme_color_override("font_color", Color(0.35, 0.22, 0.1))
		_desc.add_theme_constant_override("outline_size", 0)
		_desc.add_theme_font_size_override("font_size", 14)
		_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(_desc)
		_btn = Button.new()
		_btn.custom_minimum_size = Vector2(0, 42)
		_btn.add_theme_font_size_override("font_size", 18)
		_btn.add_theme_stylebox_override("normal", UITheme.box(Color(0.2, 0.45, 0.2), Painter.GOLD, 10, 2))
		_btn.add_theme_stylebox_override("hover", UITheme.box(Color(0.25, 0.55, 0.25), Painter.GOLD, 10, 2))
		_btn.pressed.connect(func() -> void: screen.buy(id))
		v.add_child(_btn)
		refresh()

	func level() -> int:
		return int(GameState.progress.get("upgrades", {}).get(id, 0))

	func refresh() -> void:
		var u: Dictionary = GameData.upgrades.upgrades[id]
		var lvl := level()
		var per := float(u.per_level)
		var val := ("+%d" % int(per * lvl)) if per >= 1.0 else ("+%d%%" % int(round(per * lvl * 100.0)))
		_desc.text = tr(str(u.desc)) + "\n" + tr("UPG_NOW") % val
		var c := Upgrades.cost(GameData.upgrades, id, lvl)
		if c < 0:
			_btn.text = tr("UPG_MAX")
			_btn.disabled = true
		else:
			_btn.text = "◉ %d" % c
			_btn.disabled = int(GameState.progress.coins) < c
		queue_redraw()
		for ch in get_children():
			ch.queue_redraw()

	func _draw_pips(ci: Control) -> void:
		var u: Dictionary = GameData.upgrades.upgrades[id]
		var mx := int(u.max)
		var w := ci.size.x / mx
		for i in mx:
			var col := Painter.GOLD if i < level() else Color(0.72, 0.62, 0.45)
			ci.draw_rect(Rect2(i * w + 1, 2, w - 3, 10), col)

	func _draw_icon() -> void:
		var c := _icon.size * 0.5
		var ink := Color(0.35, 0.2, 0.08)
		_icon.draw_circle(c, 21.0, Color(0.8, 0.62, 0.3))
		match str(GameData.upgrades.upgrades[id].icon):
			"shield":
				_icon.draw_colored_polygon(PackedVector2Array([c + Vector2(-11, -12), c + Vector2(11, -12), c + Vector2(11, 1), c + Vector2(0, 13), c + Vector2(-11, 1)]), ink)
			"sword":
				_icon.draw_line(c + Vector2(-11, 11), c + Vector2(11, -11), ink, 5.0)
				_icon.draw_line(c + Vector2(-12, 3), c + Vector2(-3, 12), ink, 4.0)
			"pick":
				_icon.draw_line(c + Vector2(-10, 12), c + Vector2(6, -6), ink, 4.0)
				_icon.draw_arc(c + Vector2(6, -6), 11.0, PI * 0.9, PI * 1.9, 8, ink, 4.0)
			"castle":
				_icon.draw_rect(Rect2(c + Vector2(-12, -6), Vector2(24, 18)), ink)
				for i in 3:
					_icon.draw_rect(Rect2(c + Vector2(-12 + i * 9, -12), Vector2(6, 6)), ink)
			"coin":
				_icon.draw_circle(c, 11.0, Painter.GOLD)
				_icon.draw_arc(c, 11.0, 0, TAU, 16, ink, 2.0)
			"crown":
				_icon.draw_colored_polygon(PackedVector2Array([c + Vector2(-13, 8), c + Vector2(-13, -7), c + Vector2(-6, 0), c + Vector2(0, -11), c + Vector2(6, 0), c + Vector2(13, -7), c + Vector2(13, 8)]), ink)


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
	title.text = tr("WORKSHOP")
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Painter.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	_coins = Label.new()
	_coins.add_theme_font_size_override("font_size", 28)
	top.add_child(_coins)

	var body := HBoxContainer.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 20
	body.offset_right = -20
	body.offset_top = 80
	body.offset_bottom = -16
	body.add_theme_constant_override("separation", 18)
	add_child(body)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(grid)
	for id in GameData.upgrades.order:
		var card := UpgradeCard.new(id, self)
		grid.add_child(card)
		_cards.append(card)

	var heroes := PanelContainer.new()
	heroes.custom_minimum_size = Vector2(330, 0)
	body.add_child(heroes)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 8)
	heroes.add_child(hv)
	var ht := Label.new()
	ht.text = tr("HEROES")
	ht.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ht.add_theme_font_size_override("font_size", 26)
	ht.add_theme_color_override("font_color", Painter.GOLD)
	hv.add_child(ht)
	for hid in ["chingiz", "jaloliddin", "temur", "boyazid"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		hv.add_child(row)
		var portrait := Control.new()
		portrait.custom_minimum_size = Vector2(70, 82)
		var u := UnitState.new()
		u.type = hid
		u.def = GameData.heroes[hid]
		u.facing = 1
		u.hp = 1.0
		u.max_hp = 1.0
		u.hero = true
		portrait.draw.connect(func() -> void: Painter.draw_unit(portrait, u, Vector2(32, 78), 0.62, _t))
		row.add_child(portrait)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var nl := Label.new()
		nl.text = tr(str(GameData.heroes[hid].name))
		nl.add_theme_font_size_override("font_size", 17)
		nl.add_theme_color_override("font_color", Painter.GOLD)
		info.add_child(nl)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 40)
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(func() -> void: buy_hero(hid))
		info.add_child(btn)
		_hero_rows.append([hid, btn, portrait])
	_msg = Label.new()
	_msg.anchor_left = 0.5
	_msg.anchor_right = 0.5
	_msg.anchor_top = 1.0
	_msg.anchor_bottom = 1.0
	_msg.offset_left = -300
	_msg.offset_right = 300
	_msg.offset_top = -60
	_msg.offset_bottom = -24
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.add_theme_font_size_override("font_size", 22)
	add_child(_msg)
	_refresh()
	Sfx.play_music("menu")


func buy(id: String) -> void:
	if GameState.buy_upgrade(id):
		Sfx.play("ready", 0.9, 0.0)
		_flash(tr("UPG_BOUGHT"))
	else:
		Sfx.play("deny", 0.7)
		_flash(tr("NOT_ENOUGH_COINS"))
	_refresh()


func buy_hero(hid: String) -> void:
	if GameState.hero_owned(hid):
		return
	if GameState.buy_hero(hid):
		Sfx.play("rally", 0.8, 0.0)
		_flash(tr("HERO_UNLOCKED") % tr(str(GameData.heroes[hid].name)))
	else:
		Sfx.play("deny", 0.7)
		_flash(tr("NOT_ENOUGH_COINS"))
	_refresh()


func _flash(text: String) -> void:
	_msg.text = text
	_msg_t = 2.0


func _refresh() -> void:
	_coins.text = "◉ %d" % int(GameState.progress.coins)
	for c in _cards:
		c.refresh()
	for r in _hero_rows:
		var hid: String = r[0]
		var btn: Button = r[1]
		if GameState.hero_owned(hid):
			btn.text = "✓ " + tr("HERO_OWNED")
			btn.disabled = true
		else:
			var price := int(GameData.upgrades.hero_prices.get(hid, 0))
			btn.text = tr("HERO_BUY") % price
			btn.disabled = int(GameState.progress.coins) < price


func _process(delta: float) -> void:
	_t += delta
	if _msg_t > 0.0:
		_msg_t -= delta
		_msg.modulate.a = clampf(_msg_t * 2.0, 0.0, 1.0)
	for r in _hero_rows:
		r[2].queue_redraw()
	queue_redraw()


func _draw() -> void:
	# Chodir ichi: chiziqli mato va gilam
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0.42, 0.16, 0.1))
	var stripe := 70.0
	var i := 0
	var x := -stripe
	while x < w + stripe:
		if i % 2 == 0:
			draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + stripe, 0), Vector2(x + stripe * 0.8, h * 0.75), Vector2(x - stripe * 0.2, h * 0.75)]), Color(0.55, 0.22, 0.12))
		x += stripe
		i += 1
	draw_rect(Rect2(0, h * 0.75, w, h * 0.25), Color(0.3, 0.12, 0.08))
	for k in 6:
		draw_rect(Rect2(40 + k * (w - 80) / 6.0, h * 0.8, (w - 80) / 6.0 - 10, 8), Color(0.75, 0.55, 0.2, 0.6))
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.18))
