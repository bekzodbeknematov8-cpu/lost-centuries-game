extends Control
## Kampaniya xaritasi: 4 qahramon kampaniyasi, har birida 10 bosqich.

var _cid := ""
var _sel := ""
var _t := 0.0
var _info_name: Label
var _info_desc: Label
var _play_btn: Button
var _tabs: Array = []
var _stars_label: Label
var _coins_label: Label
var _map_rect := Rect2()


class Tab:
	extends Button
	var cid: String
	var active := false
	var locked := false
	var need := 0
	var _u := UnitState.new()
	var _t := 0.0

	func _init(id: String) -> void:
		cid = id
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(250, 78)
		var hero: String = GameData.campaigns.campaigns[id].hero
		_u.type = hero
		_u.def = GameData.heroes[hero]
		_u.team = 0
		_u.facing = 1
		_u.hp = 1.0
		_u.max_hp = 1.0
		_u.hero = true
		add_theme_stylebox_override("normal", UITheme.box(Color(0.18, 0.11, 0.06, 0.9), Color(0.6, 0.45, 0.2), 12, 2))
		add_theme_stylebox_override("hover", UITheme.box(Color(0.24, 0.15, 0.08, 0.95), UITheme.ACCENT, 12, 2))
		add_theme_stylebox_override("pressed", UITheme.box(Color(0.3, 0.18, 0.08, 0.95), UITheme.ACCENT, 12, 2))

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _draw() -> void:
		if active:
			draw_style_box(UITheme.box(Color(0.42, 0.22, 0.08, 0.95), Painter.GOLD, 12, 3), Rect2(Vector2.ZERO, size))
		Painter.draw_unit(self, _u, Vector2(40, 72), 0.5, _t)
		var font := get_theme_default_font()
		var c: Dictionary = GameData.campaigns.campaigns[cid]
		var loc := TranslationServer.get_locale().substr(0, 2)
		var col := Painter.GOLD if not locked else Color(0.6, 0.55, 0.5)
		draw_string(font, Vector2(78, 32), str(c.name.get(loc, c.name.en)), HORIZONTAL_ALIGNMENT_LEFT, size.x - 84, 17, col)
		var sub := str(c.years)
		if locked:
			sub = tr("NEED_STARS") % need
		draw_string(font, Vector2(78, 56), sub, HORIZONTAL_ALIGNMENT_LEFT, size.x - 84, 14, UITheme.PARCHMENT)
		if locked:
			_lock(Vector2(size.x - 22, 22))

	func _lock(p: Vector2) -> void:
		draw_arc(p + Vector2(0, -4), 6.0, PI, TAU, 10, Color(0.8, 0.75, 0.7), 2.5)
		draw_rect(Rect2(p + Vector2(-8, -4), Vector2(16, 12)), Color(0.8, 0.75, 0.7))


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.make()
	GameState.level_id = ""
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_right = -16
	top.offset_top = 10
	top.add_theme_constant_override("separation", 12)
	add_child(top)
	var back := Button.new()
	back.text = "‹ " + tr("BACK")
	back.custom_minimum_size = Vector2(140, 54)
	back.pressed.connect(func() -> void:
		Sfx.play("click", 0.7)
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	top.add_child(back)
	var title := Label.new()
	title.text = tr("CAMPAIGN")
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Painter.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	_stars_label = Label.new()
	_stars_label.add_theme_font_size_override("font_size", 24)
	top.add_child(_stars_label)
	_coins_label = Label.new()
	_coins_label.add_theme_font_size_override("font_size", 24)
	top.add_child(_coins_label)

	var tabs := HBoxContainer.new()
	tabs.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tabs.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tabs.offset_top = 74
	tabs.add_theme_constant_override("separation", 10)
	add_child(tabs)
	for cid in GameData.campaigns.order:
		var tb := Tab.new(cid)
		tb.pressed.connect(_select_campaign.bind(cid))
		tabs.add_child(tb)
		_tabs.append(tb)

	var info := PanelContainer.new()
	info.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	info.offset_left = 16
	info.offset_right = -16
	info.offset_top = -112
	info.offset_bottom = -10
	add_child(info)
	var ih := HBoxContainer.new()
	ih.add_theme_constant_override("separation", 16)
	info.add_child(ih)
	var iv := VBoxContainer.new()
	iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ih.add_child(iv)
	_info_name = Label.new()
	_info_name.add_theme_font_size_override("font_size", 26)
	_info_name.add_theme_color_override("font_color", Painter.GOLD)
	iv.add_child(_info_name)
	_info_desc = Label.new()
	_info_desc.add_theme_font_size_override("font_size", 17)
	_info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	iv.add_child(_info_desc)
	_play_btn = Button.new()
	_play_btn.text = tr("TO_BATTLE")
	_play_btn.custom_minimum_size = Vector2(230, 72)
	_play_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_play_btn.add_theme_font_size_override("font_size", 28)
	_play_btn.add_theme_stylebox_override("normal", UITheme.box(Color(0.55, 0.15, 0.08), Painter.GOLD))
	_play_btn.add_theme_stylebox_override("hover", UITheme.box(Color(0.65, 0.2, 0.1), Painter.GOLD))
	_play_btn.pressed.connect(_play)
	ih.add_child(_play_btn)

	# Oxirgi ochiq kampaniyani tanlaymiz
	var start: String = GameData.campaigns.order[0]
	for cid in GameData.campaigns.order:
		if Campaign.campaign_unlocked(GameData.campaigns, GameState.progress.stars, cid):
			start = cid
	_select_campaign(start, false)
	Sfx.play_music("menu")


func _select_campaign(cid: String, sound := true) -> void:
	var stars: Dictionary = GameState.progress.stars
	if not Campaign.campaign_unlocked(GameData.campaigns, stars, cid):
		Sfx.play("deny", 0.6)
		var c: Dictionary = GameData.campaigns.campaigns[cid]
		_info_name.text = tr("LOCKED")
		_info_desc.text = tr("UNLOCK_RULE") % int(c.require_stars)
		_play_btn.disabled = true
		return
	if sound:
		Sfx.play("click", 0.7)
	_cid = cid
	# Birinchi tugallanmagan ochiq bosqich
	var levels: Array = GameData.campaigns.campaigns[cid].levels
	_sel = levels[0].id
	for lv in levels:
		if Campaign.level_unlocked(GameData.campaigns, stars, lv.id):
			_sel = lv.id
			if int(stars.get(lv.id, 0)) == 0:
				break
	_update_info()


func _update_info() -> void:
	var lv := Campaign.level_by_id(GameData.campaigns, _sel)
	var loc := TranslationServer.get_locale().substr(0, 2)
	var idx: int = GameData.campaigns.campaigns[_cid].levels.find(lv) + 1
	_info_name.text = "%d. %s" % [idx, lv.name.get(loc, lv.name.en)]
	var desc: String
	if lv.get("objective", "destroy") == "survive":
		desc = tr("OBJ_SURVIVE") % int(lv.survive)
	else:
		desc = tr("OBJ_DESTROY")
	if str(lv.get("enemy_hero", "")) != "":
		desc += "   •   " + tr("ENEMY_HERO") % tr(str(GameData.heroes[lv.enemy_hero].name))
	desc += "   •   " + tr("STARS_RULE")
	_info_desc.text = desc
	_play_btn.disabled = not Campaign.level_unlocked(GameData.campaigns, GameState.progress.stars, _sel)


func _play() -> void:
	Sfx.play("horn_attack", 0.8, 0.0)
	GameState.level_id = _sel
	GameState.hero = str(GameData.campaigns.campaigns[_cid].hero)
	get_tree().change_scene_to_file("res://scenes/battle.tscn")


func _node_pos(i: int) -> Vector2:
	var r := _map_rect
	var x := r.position.x + 70.0 + (r.size.x - 140.0) * i / 9.0
	var y := r.position.y + r.size.y * 0.5 + sin(i * 1.15 + 0.4) * r.size.y * 0.28
	return Vector2(x, y)


func _gui_input(event: InputEvent) -> void:
	var pos := Vector2.INF
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pos = event.position
	if pos == Vector2.INF or _cid == "":
		return
	var levels: Array = GameData.campaigns.campaigns[_cid].levels
	for i in levels.size():
		if pos.distance_to(_node_pos(i)) < 34.0:
			_sel = levels[i].id
			if Campaign.level_unlocked(GameData.campaigns, GameState.progress.stars, _sel):
				Sfx.play("click", 0.7)
			else:
				Sfx.play("deny", 0.6)
			_update_info()
			accept_event()
			return


func _process(delta: float) -> void:
	_t += delta
	var stars: Dictionary = GameState.progress.stars
	_stars_label.text = "★ %d" % Campaign.total_stars(stars)
	_coins_label.text = "◉ %d" % int(GameState.progress.coins)
	for tb in _tabs:
		tb.active = tb.cid == _cid
		tb.locked = not Campaign.campaign_unlocked(GameData.campaigns, stars, tb.cid)
		tb.need = int(GameData.campaigns.campaigns[tb.cid].require_stars)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0.2, 0.11, 0.06))
	_map_rect = Rect2(40, 166, w - 80, h - 166 - 130)
	var r := _map_rect
	# Eski qog'oz xarita
	draw_style_box(UITheme.box(Color(0.9, 0.8, 0.6), Color(0.45, 0.3, 0.15), 18, 4), r)
	for i in 7:
		var y := r.position.y + 20.0 + i * r.size.y / 7.0
		draw_line(Vector2(r.position.x + 20, y + sin(i * 2.0) * 6.0), Vector2(r.end.x - 20, y - sin(i * 1.3) * 6.0), Color(0.75, 0.62, 0.42, 0.35), 1.0)
	if _cid == "":
		return
	# Tog' va daraxt belgilar
	for i in 9:
		var mx := r.position.x + 40.0 + i * (r.size.x - 80.0) / 8.0 + 30.0
		var my := r.position.y + (r.size.y * 0.16 if i % 2 == 0 else r.size.y * 0.86)
		draw_colored_polygon(PackedVector2Array([Vector2(mx - 18, my + 10), Vector2(mx, my - 14), Vector2(mx + 18, my + 10)]), Color(0.6, 0.47, 0.3, 0.5))
	var levels: Array = GameData.campaigns.campaigns[_cid].levels
	var stars: Dictionary = GameState.progress.stars
	var font := get_theme_default_font()
	# Yo'l (shtrix chiziq)
	for i in levels.size() - 1:
		var a := _node_pos(i)
		var b := _node_pos(i + 1)
		var n := 10
		for k in n:
			if k % 2 == 0:
				draw_line(a.lerp(b, float(k) / n), a.lerp(b, float(k + 1) / n), Color(0.45, 0.25, 0.1, 0.8), 4.0)
	for i in levels.size():
		var lv: Dictionary = levels[i]
		var p := _node_pos(i)
		var unlocked := Campaign.level_unlocked(GameData.campaigns, stars, lv.id)
		var st := int(stars.get(lv.id, 0))
		var boss := str(lv.get("enemy_hero", "")) != "" or i == levels.size() - 1
		var col := Color(0.65, 0.2, 0.12) if unlocked else Color(0.5, 0.45, 0.4)
		if lv.get("objective", "destroy") == "survive" and unlocked:
			col = Color(0.2, 0.4, 0.6)
		var rad := 30.0 if boss else 25.0
		if lv.id == _sel:
			draw_circle(p, rad + 9.0 + sin(_t * 5.0) * 2.0, Color(1, 0.85, 0.3, 0.8))
		draw_circle(p, rad + 3.0, Color(0.25, 0.14, 0.06))
		draw_circle(p, rad, col)
		if unlocked:
			draw_string(font, p + Vector2(-20, 8), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 40, 24, Color(1, 0.95, 0.85))
		else:
			draw_arc(p + Vector2(0, -5), 7.0, PI, TAU, 10, Color(0.85, 0.82, 0.78), 3.0)
			draw_rect(Rect2(p + Vector2(-9, -5), Vector2(18, 14)), Color(0.85, 0.82, 0.78))
		for k in 3:
			var sp := p + Vector2((k - 1) * 17.0, rad + 16.0)
			_star(sp, 8.0, Painter.GOLD if k < st else Color(0.55, 0.48, 0.38, 0.8))


func _star(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2.from_angle(-PI / 2 + i * PI / 5) * rr)
	draw_colored_polygon(pts, col)
