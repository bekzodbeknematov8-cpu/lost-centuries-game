extends Control
## Sandiqlar: sotib olish, ochish va ehtimollarni ko'rish.

var _t := 0.0
var _kind := "silver"
var _open_t := -1.0
var _rewards: Array = []
var _rows: Array = []
var _coins: Label
var _gems: Label
var _open_btn: Button
var _odds: PanelContainer
var _odds_label: Label
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
	top.add_theme_constant_override("separation", 16)
	add_child(top)
	var back := Button.new()
	back.text = "‹ " + tr("BACK")
	back.custom_minimum_size = Vector2(130, 52)
	back.pressed.connect(func() -> void:
		Sfx.play("click", 0.7)
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	top.add_child(back)
	var title := Label.new()
	title.text = tr("MENU_CHESTS")
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

	var list := VBoxContainer.new()
	list.position = Vector2(24, 90)
	list.add_theme_constant_override("separation", 12)
	add_child(list)
	for kind in GameData.chests.order:
		var c: Dictionary = GameData.chests.chests[kind]
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(330, 120)
		list.add_child(p)
		var h := HBoxContainer.new()
		p.add_child(h)
		var art := Control.new()
		art.custom_minimum_size = Vector2(100, 100)
		var col := Color(c.color[0], c.color[1], c.color[2])
		art.draw.connect(func() -> void: ChestArt.draw(art, Vector2(50, 62), 0.75, col))
		h.add_child(art)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		var nm := Label.new()
		nm.text = tr(str(c.name))
		nm.add_theme_font_size_override("font_size", 20)
		nm.add_theme_color_override("font_color", Painter.GOLD)
		v.add_child(nm)
		var owned := Label.new()
		owned.add_theme_font_size_override("font_size", 15)
		v.add_child(owned)
		var hb := HBoxContainer.new()
		v.add_child(hb)
		var sel := Button.new()
		sel.text = tr("SELECT")
		sel.pressed.connect(func() -> void:
			Sfx.play("click", 0.7)
			_kind = kind
			_open_t = -1.0
			_rewards = []
			_refresh())
		hb.add_child(sel)
		var buy := Button.new()
		buy.text = ("◉ %d" % int(c.price_coins)) if int(c.price_coins) > 0 else ("♦ %d" % int(c.price_gems))
		buy.add_theme_stylebox_override("normal", UITheme.box(Color(0.2, 0.45, 0.2), Painter.GOLD, 10, 2))
		buy.pressed.connect(func() -> void:
			if GameState.buy_chest(kind):
				Sfx.play("coin", 0.9, 0.0)
			else:
				Sfx.play("deny", 0.7)
				_flash(tr("NOT_ENOUGH"))
			_refresh())
		hb.add_child(buy)
		_rows.append([kind, owned, buy])

	_open_btn = Button.new()
	_open_btn.custom_minimum_size = Vector2(300, 70)
	_open_btn.anchor_left = 0.62
	_open_btn.anchor_right = 0.62
	_open_btn.anchor_top = 1.0
	_open_btn.anchor_bottom = 1.0
	_open_btn.offset_left = -150
	_open_btn.offset_right = 150
	_open_btn.offset_top = -100
	_open_btn.offset_bottom = -30
	_open_btn.add_theme_font_size_override("font_size", 28)
	_open_btn.add_theme_stylebox_override("normal", UITheme.box(Color(0.55, 0.15, 0.08), Painter.GOLD))
	_open_btn.add_theme_stylebox_override("hover", UITheme.box(Color(0.65, 0.2, 0.1), Painter.GOLD))
	_open_btn.pressed.connect(_open)
	add_child(_open_btn)
	var info := Button.new()
	info.text = "i  " + tr("ODDS")
	info.anchor_left = 1.0
	info.anchor_right = 1.0
	info.anchor_top = 1.0
	info.anchor_bottom = 1.0
	info.offset_left = -190
	info.offset_right = -20
	info.offset_top = -86
	info.offset_bottom = -36
	info.pressed.connect(func() -> void:
		Sfx.play("click", 0.7)
		_odds.visible = not _odds.visible
		_update_odds())
	add_child(info)
	_odds = PanelContainer.new()
	_odds.anchor_left = 1.0
	_odds.anchor_right = 1.0
	_odds.anchor_top = 1.0
	_odds.anchor_bottom = 1.0
	_odds.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_odds.offset_left = -360
	_odds.offset_right = -20
	_odds.offset_bottom = -100
	_odds.visible = false
	add_child(_odds)
	_odds_label = Label.new()
	_odds_label.add_theme_font_size_override("font_size", 17)
	_odds.add_child(_odds_label)
	_msg = Label.new()
	_msg.anchor_left = 0.62
	_msg.anchor_right = 0.62
	_msg.offset_left = -250
	_msg.offset_right = 250
	_msg.offset_top = 80
	_msg.offset_bottom = 110
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.add_theme_font_size_override("font_size", 22)
	add_child(_msg)
	_refresh()
	Sfx.play_music("menu")
	if OS.get_cmdline_user_args().has("--open_chest"):   # avtomatik sinov uchun
		_odds.visible = true
		_update_odds()
		_open.call_deferred()


func _update_odds() -> void:
	var c: Dictionary = GameData.chests.chests[_kind]
	var lines := [tr(str(c.name)) + " — " + tr("ODDS_ROLLS") % int(c.rolls)]
	for o in Rewards.odds(c):
		var d: Dictionary = o.drop
		var what := ""
		match str(o.type):
			"coins": what = tr("RW_COINS_RANGE") % [int(d.min), int(d.max)]
			"gems": what = tr("RW_GEMS_RANGE") % [int(d.min), int(d.max)]
			"tactic": what = tr("RW_TACTIC_N") % int(d.count)
		lines.append("• %s — %.0f%%" % [what, o.percent])
	_odds_label.text = "\n".join(lines)


func _open() -> void:
	var got := GameState.open_chest(_kind)
	if got.is_empty():
		Sfx.play("deny", 0.7)
		_flash(tr("NO_CHEST"))
		return
	Sfx.play("victory", 0.7, 0.0)
	_rewards = got
	_open_t = 0.0
	_refresh()


static func reward_text(r: Dictionary) -> String:
	match str(r.type):
		"coins": return "◉ +%d" % int(r.amount)
		"gems": return "♦ +%d" % int(r.amount)
		"tactic": return "%s ×%d" % [TranslationServer.translate(str(GameData.tactics.tactics[r.id].name)), int(r.count)]
		"chest": return "%s ×%d" % [TranslationServer.translate(str(GameData.chests.chests[r.id].name)), int(r.count)]
	return ""


func _flash(text: String) -> void:
	_msg.text = text
	_msg_t = 2.0


func _refresh() -> void:
	_coins.text = "◉ %d" % int(GameState.progress.coins)
	_gems.text = "♦ %d" % int(GameState.progress.gems)
	for r in _rows:
		var n := int(GameState.progress.chests.get(r[0], 0))
		r[1].text = tr("OWNED_N") % n
	var n2 := int(GameState.progress.chests.get(_kind, 0))
	_open_btn.text = tr("OPEN_CHEST") % n2
	_open_btn.disabled = n2 <= 0
	if _odds.visible:
		_update_odds()


func _process(delta: float) -> void:
	_t += delta
	if _open_t >= 0.0:
		_open_t += delta
	if _msg_t > 0.0:
		_msg_t -= delta
		_msg.modulate.a = clampf(_msg_t * 2.0, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0.28, 0.12, 0.3))
	var x := -70.0
	var i := 0
	while x < w + 70.0:
		if i % 2 == 0:
			draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 70, 0), Vector2(x + 56, h), Vector2(x - 14, h)]), Color(0.35, 0.16, 0.36))
		x += 70.0
		i += 1
	var c: Dictionary = GameData.chests.chests[_kind]
	var col := Color(c.color[0], c.color[1], c.color[2])
	var center := Vector2(w * 0.62, h * 0.55)
	draw_circle(center + Vector2(0, 60), 150.0, Color(0, 0, 0, 0.2))
	var k := clampf(_open_t / 0.6, 0.0, 1.0) if _open_t >= 0.0 else 0.0
	var bob := sin(_t * 2.0) * 4.0 if _open_t < 0.0 else 0.0
	ChestArt.draw(self, center + Vector2(0, bob), 2.2, col, k, 1.0 if _open_t >= 0.0 else 0.4)
	# Mukofot kartalari
	if _open_t > 0.5 and not _rewards.is_empty():
		var font := get_theme_default_font()
		var n := _rewards.size()
		for j in n:
			var appear := clampf((_open_t - 0.5 - j * 0.25) / 0.3, 0.0, 1.0)
			if appear <= 0.0:
				continue
			var cx := center.x + (j - (n - 1) * 0.5) * 170.0
			var cy := center.y - 210.0 - 20.0 * (1.0 - appear)
			var r := Rect2(cx - 78, cy - 34, 156, 68)
			draw_style_box(UITheme.box(Color(0.95, 0.88, 0.7, appear), Color(0.6, 0.4, 0.15, appear), 10, 3), r)
			draw_string(font, Vector2(r.position.x, cy + 8), reward_text(_rewards[j]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 18, Color(0.3, 0.15, 0.05, appear))
