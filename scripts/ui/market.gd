extends Control
## Bozor: la'l paketlari, reklamasiz, boshlang'ich to'plam, zaxira qo'shin, bepul la'l (reklama).

var _t := 0.0
var _gems: Label
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
	title.text = tr("MENU_MARKET")
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
	if not Billing.is_real():
		var note := Label.new()
		note.text = tr("BILLING_NOTE")
		note.set_anchors_preset(Control.PRESET_TOP_WIDE)
		note.offset_top = 66
		note.offset_bottom = 92
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.add_theme_font_size_override("font_size", 15)
		note.modulate = Color(1, 0.9, 0.7)
		add_child(note)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 16
	scroll.offset_right = -16
	scroll.offset_top = 104
	scroll.offset_bottom = -20
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	scroll.add_child(row)
	for id in GameData.market.order:
		row.add_child(_card(id))
	_msg = Label.new()
	_msg.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_msg.offset_left = -300
	_msg.offset_right = 300
	_msg.offset_top = -40
	_msg.offset_bottom = -10
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.add_theme_font_size_override("font_size", 22)
	add_child(_msg)
	_refresh()
	Sfx.play_music("menu")
	if OS.get_cmdline_user_args().has("--auto_buy"):   # avtomatik sinov
		_buy.call_deferred("starter")
		_buy.call_deferred("res_cavalry")


func _card(id: String) -> PanelContainer:
	var p: Dictionary = GameData.market.products[id]
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(230, 560)
	panel.add_theme_stylebox_override("panel", UITheme.box(Color(0.95, 0.88, 0.7), Color(0.55, 0.38, 0.18), 14, 3))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var nm := Label.new()
	nm.text = tr(str(p.name))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.add_theme_color_override("font_color", Color(0.3, 0.15, 0.05))
	nm.add_theme_constant_override("outline_size", 0)
	nm.add_theme_font_size_override("font_size", 21)
	v.add_child(nm)
	var art := Control.new()
	art.custom_minimum_size = Vector2(0, 190)
	art.draw.connect(func() -> void: _draw_art(art, id))
	v.add_child(art)
	var desc := Label.new()
	desc.text = _desc(id)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_color_override("font_color", Color(0.35, 0.22, 0.1))
	desc.add_theme_constant_override("outline_size", 0)
	desc.add_theme_font_size_override("font_size", 15)
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 56)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_stylebox_override("normal", UITheme.box(Color(0.42, 0.16, 0.5), Painter.GOLD, 10, 2))
	btn.add_theme_stylebox_override("hover", UITheme.box(Color(0.5, 0.2, 0.6), Painter.GOLD, 10, 2))
	btn.pressed.connect(_buy.bind(id))
	v.add_child(btn)
	_cards.append([id, btn])
	return panel


func _desc(id: String) -> String:
	var p: Dictionary = GameData.market.products[id]
	var lines: Array = [tr(str(p.desc))]
	for c in p.contents:
		match str(c.type):
			"gems": lines.append("♦ %d %s" % [int(c.amount), tr("GEMS")])
			"reserve": lines.append("%d × %s" % [int(c.count), tr(str(GameData.units[c.id].name))])
			"chest", "tactic": lines.append(preload("res://scripts/ui/chests_screen.gd").reward_text(c))
			"outfit": lines.append(tr("MENU_OUTFITS") + ": " + tr(str(GameData.outfits.outfits[c.id].name)))
	return "\n".join(lines)


func _draw_art(ci: Control, id: String) -> void:
	var c := ci.size * 0.5
	var p: Dictionary = GameData.market.products[id]
	ci.draw_circle(c, 80.0, Color(1, 0.85, 0.5, 0.35))
	var gem := func(pos: Vector2, s: float) -> void:
		ci.draw_colored_polygon(PackedVector2Array([pos + Vector2(-14, -5) * s, pos + Vector2(-8, -13) * s, pos + Vector2(8, -13) * s, pos + Vector2(14, -5) * s, pos + Vector2(0, 15) * s]), Color(0.85, 0.12, 0.28))
		ci.draw_colored_polygon(PackedVector2Array([pos + Vector2(-8, -13) * s, pos + Vector2(8, -13) * s, pos + Vector2(4, -5) * s, pos + Vector2(-4, -5) * s]), Color(1, 0.55, 0.65))
	match id:
		"gems_s":
			gem.call(c, 2.2)
		"gems_m":
			for i in 5:
				gem.call(c + Vector2((i - 2) * 22.0, (i % 2) * 14.0), 1.6)
		"gems_l":
			for i in 9:
				gem.call(c + Vector2((i % 3 - 1) * 34.0, (i / 3 - 1) * 30.0), 1.5)
		"starter":
			ChestArt.draw(ci, c + Vector2(0, 20), 1.0, Painter.GOLD, 0.6, 0.6)
			gem.call(c + Vector2(-50, -40), 1.2)
		"no_ads":
			ci.draw_rect(Rect2(c + Vector2(-40, -55), Vector2(80, 110)), Color(0.2, 0.2, 0.25))
			ci.draw_rect(Rect2(c + Vector2(-34, -45), Vector2(68, 85)), Color(0.85, 0.9, 0.95))
			ci.draw_arc(c, 62.0, 0, TAU, 32, Color(0.8, 0.1, 0.1), 9.0)
			ci.draw_line(c + Vector2(-44, 44), c + Vector2(44, -44), Color(0.8, 0.1, 0.1), 9.0)
		"res_archer", "res_sword", "res_cavalry":
			var u := UnitState.new()
			u.type = str(p.contents[0].id)
			u.def = GameData.units[u.type]
			u.facing = 1
			u.hp = 1.0
			u.max_hp = 1.0
			for k in 3:
				Painter.draw_unit(ci, u, c + Vector2((k - 1) * 46.0, 60.0 - (k % 2) * 12.0), 1.1 if u.type != "cavalry" else 0.85, _t)
		"ad_gems":
			ci.draw_rect(Rect2(c + Vector2(-38, -60), Vector2(76, 120)), Color(0.15, 0.15, 0.2))
			ci.draw_rect(Rect2(c + Vector2(-32, -50), Vector2(64, 95)), Color(0.3, 0.6, 0.85))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, -16), c + Vector2(16, 0), c + Vector2(-10, 16)]), Color.WHITE)
			gem.call(c + Vector2(40, 50), 1.3)


func _buy(id: String) -> void:
	var p: Dictionary = GameData.market.products[id]
	match str(p.kind):
		"iap":
			if not GameState.product_available(id):
				return
			Billing.purchase(id, p, func(ok: bool) -> void:
				if ok and GameState.grant_product(id):
					Sfx.play("victory", 0.6, 0.0)
					_flash(tr("PURCHASE_OK"))
				_refresh())
		"gems":
			if GameState.buy_with_gems(id):
				Sfx.play("coin", 0.9, 0.0)
				_flash(tr("PURCHASE_OK"))
			else:
				Sfx.play("deny", 0.7)
				_flash(tr("NOT_ENOUGH"))
			_refresh()
		"ad":
			if GameState.adgems_left() <= 0:
				Sfx.play("deny", 0.7)
				return
			Ads.show_rewarded(func(ok: bool) -> void:
				if ok and GameState.claim_ad_gems():
					Sfx.play("coin", 1.0, 0.0)
					_flash(tr("PURCHASE_OK"))
				_refresh())


func _flash(text: String) -> void:
	_msg.text = text
	_msg_t = 2.0


func _refresh() -> void:
	_coins.text = "◉ %d" % int(GameState.progress.coins)
	_gems.text = "♦ %d" % int(GameState.progress.gems)
	for c in _cards:
		var id: String = c[0]
		var btn: Button = c[1]
		var p: Dictionary = GameData.market.products[id]
		match str(p.kind):
			"iap":
				var avail := GameState.product_available(id)
				btn.text = Billing.price_text(p) if avail else "✓ " + tr("BOUGHT")
				btn.disabled = not avail
			"gems":
				btn.text = "♦ %d" % int(p.gems)
				btn.disabled = int(GameState.progress.gems) < int(p.gems)
			"ad":
				var left := GameState.adgems_left()
				btn.text = "▶ " + tr("FREE") + " (%d/%d)" % [left, int(GameData.market.ad_gems.daily_limit)]
				btn.disabled = left <= 0


func _process(delta: float) -> void:
	_t += delta
	if _msg_t > 0.0:
		_msg_t -= delta
		_msg.modulate.a = clampf(_msg_t * 2.0, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	# Bozor rastasi: chiziqli soyabon va g'isht devor
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0.55, 0.35, 0.22))
	for y in range(0, int(h), 28):
		for x in range(-30 + (y / 28 % 2) * 30, int(w), 60):
			draw_rect(Rect2(x + 2, y + 2, 56, 24), Color(0.62, 0.4, 0.25))
	var aw := 54.0
	var i := 0
	var x2 := 0.0
	while x2 < w:
		draw_colored_polygon(PackedVector2Array([Vector2(x2, 0), Vector2(x2 + aw, 0), Vector2(x2 + aw, 70), Vector2(x2 + aw * 0.5, 92), Vector2(x2, 70)]), Color(0.75, 0.15, 0.12) if i % 2 == 0 else Color(0.95, 0.88, 0.75))
		x2 += aw
		i += 1
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.2))
