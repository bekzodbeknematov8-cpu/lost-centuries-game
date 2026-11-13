extends Control
## Kampaniya ekrani: qahramonning tarixiy xaritasi (viloyatlar) + tanlangan viloyat levellari.

const MAP_W := 1000.0
const MAP_H := 600.0
const SHADER := preload("res://assets/shaders/region_map.gdshader")

var _cid := ""
var _region := 0
var _sel := ""
var _t := 0.0
var _tabs: Array = []
var _stars_label: Label
var _coins_label: Label
var _map: TextureRect
var _mat: ShaderMaterial
var _idx_img: Image
var _overlay: Control
var _panel_title: Label
var _panel_sub: Label
var _levels: Control
var _info: Label
var _play_btn: Button


class Tab:
	extends Button
	var cid: String
	var active := false
	var locked := false
	var _u := UnitState.new()
	var _t := 0.0

	func _init(id: String) -> void:
		cid = id
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(200, 60)
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
		Painter.draw_unit(self, _u, Vector2(30, 56), 0.4, _t)
		var font := get_theme_default_font()
		var col := Painter.GOLD if not locked else Color(0.6, 0.55, 0.5)
		var nm := tr(str(_u.def.name))
		var fs := 15
		while fs > 10 and font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > size.x - 64:
			fs -= 1
		draw_string(font, Vector2(58, 26), nm, HORIZONTAL_ALIGNMENT_LEFT, size.x - 62, fs, col)
		var sub: String
		if locked:
			sub = tr("NEED_STARS") % int(GameData.campaigns.campaigns[cid].require_stars)
		else:
			var st := Campaign.campaign_stars(GameData.campaigns, GameState.progress.stars, cid)
			sub = "★ %d / %d" % [st, Campaign.all_levels(GameData.campaigns, cid).size() * 3]
		draw_string(font, Vector2(58, 48), sub, HORIZONTAL_ALIGNMENT_LEFT, size.x - 62, 13, UITheme.PARCHMENT)


class LevelGrid:
	## Viloyatdagi levellar: 2 qator x 5, oxirgisi (boss) toj bilan.
	extends Control
	var owner_screen: Node
	var _t := 0.0

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func node_pos(i: int) -> Vector2:
		var cols := 5
		var cw := size.x / cols
		return Vector2(cw * (i % cols) + cw * 0.5, 44.0 + (i / cols) * 92.0)

	func _gui_input(event: InputEvent) -> void:
		var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed)
		if not pressed:
			return
		var lvls: Array = owner_screen.current_levels()
		for i in lvls.size():
			if event.position.distance_to(node_pos(i)) < 30.0:
				owner_screen.select_level(lvls[i].id)
				accept_event()
				return

	func _draw() -> void:
		var lvls: Array = owner_screen.current_levels()
		var stars: Dictionary = GameState.progress.stars
		var font := get_theme_default_font()
		for i in lvls.size():
			var lv: Dictionary = lvls[i]
			var p := node_pos(i)
			var unlocked := Campaign.level_unlocked(GameData.campaigns, stars, lv.id)
			var st := int(stars.get(lv.id, 0))
			var boss := Campaign.is_boss(lv.id)
			var col := Color(0.62, 0.2, 0.12) if unlocked else Color(0.42, 0.38, 0.34)
			if lv.get("objective", "destroy") == "survive" and unlocked:
				col = Color(0.2, 0.4, 0.6)
			if boss and unlocked:
				col = Color(0.55, 0.12, 0.45)
			var r := 27.0 if boss else 23.0
			if lv.id == owner_screen._sel:
				draw_circle(p, r + 7.0 + sin(_t * 5.0) * 2.0, Color(1, 0.85, 0.3, 0.85))
			draw_circle(p, r + 3.0, Color(0.2, 0.12, 0.05))
			draw_circle(p, r, col)
			if boss:
				draw_colored_polygon(PackedVector2Array([p + Vector2(-11, -r + 2), p + Vector2(-11, -r - 10), p + Vector2(-5, -r - 4), p + Vector2(0, -r - 13), p + Vector2(5, -r - 4), p + Vector2(11, -r - 10), p + Vector2(11, -r + 2)]), Painter.GOLD)
			if unlocked:
				draw_string(font, p + Vector2(-20, 8), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 40, 22, Color(1, 0.95, 0.85))
			else:
				draw_arc(p + Vector2(0, -4), 6.0, PI, TAU, 10, Color(0.8, 0.77, 0.72), 2.5)
				draw_rect(Rect2(p + Vector2(-8, -4), Vector2(16, 12)), Color(0.8, 0.77, 0.72))
			for k in 3:
				_star(p + Vector2((k - 1) * 15.0, r + 14.0), 7.0, Painter.GOLD if k < st else Color(0.5, 0.44, 0.36, 0.85))

	func _star(c: Vector2, r: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 10:
			var rr := r if i % 2 == 0 else r * 0.45
			pts.append(c + Vector2.from_angle(-PI / 2 + i * PI / 5) * rr)
		draw_colored_polygon(pts, col)


class MapOverlay:
	## Xarita ustida: viloyat nomlari, zabt yo'li, bayroq, qulflar.
	extends Control
	var owner_screen: Node
	var _t := 0.0

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _draw() -> void:
		owner_screen.draw_overlay(self, _t)


# --- Qurish ------------------------------------------------------------------

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.make()
	GameState.level_id = ""
	GameState.mode = "campaign"
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 12
	top.offset_right = -12
	top.offset_top = 8
	top.add_theme_constant_override("separation", 10)
	add_child(top)
	var back := Button.new()
	back.text = "‹ " + tr("BACK")
	back.custom_minimum_size = Vector2(120, 50)
	back.pressed.connect(func() -> void:
		Sfx.play("click", 0.7)
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	top.add_child(back)
	for cid in GameData.campaigns.order:
		var tb := Tab.new(cid)
		tb.pressed.connect(_select_campaign.bind(cid))
		top.add_child(tb)
		_tabs.append(tb)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	var res := VBoxContainer.new()
	top.add_child(res)
	_stars_label = Label.new()
	_stars_label.add_theme_font_size_override("font_size", 20)
	res.add_child(_stars_label)
	_coins_label = Label.new()
	_coins_label.add_theme_font_size_override("font_size", 20)
	res.add_child(_coins_label)

	# Xarita (chapda)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UITheme.box(Color(0.35, 0.22, 0.1), Color(0.75, 0.55, 0.25), 10, 4))
	frame.anchor_left = 0.0
	frame.anchor_right = 0.66
	frame.anchor_top = 0.0
	frame.anchor_bottom = 1.0
	frame.offset_left = 12
	frame.offset_top = 70
	frame.offset_right = -6
	frame.offset_bottom = -12
	add_child(frame)
	_map = TextureRect.new()
	_map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_map.mouse_filter = Control.MOUSE_FILTER_STOP
	_map.gui_input.connect(_on_map_input)
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_map.material = _mat
	frame.add_child(_map)
	_overlay = MapOverlay.new()
	_overlay.owner_screen = self
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map.add_child(_overlay)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Viloyat paneli (o'ngda)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.66
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 6
	panel.offset_top = 70
	panel.offset_right = -12
	panel.offset_bottom = -12
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	_panel_title = Label.new()
	_panel_title.add_theme_font_size_override("font_size", 28)
	_panel_title.add_theme_color_override("font_color", Painter.GOLD)
	_panel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_panel_title)
	_panel_sub = Label.new()
	_panel_sub.add_theme_font_size_override("font_size", 16)
	_panel_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_panel_sub)
	_levels = LevelGrid.new()
	_levels.owner_screen = self
	_levels.custom_minimum_size = Vector2(0, 200)
	_levels.mouse_filter = Control.MOUSE_FILTER_STOP
	v.add_child(_levels)
	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 15)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_info)
	_play_btn = Button.new()
	_play_btn.text = tr("TO_BATTLE")
	_play_btn.custom_minimum_size = Vector2(0, 66)
	_play_btn.add_theme_font_size_override("font_size", 28)
	_play_btn.add_theme_stylebox_override("normal", UITheme.box(Color(0.55, 0.15, 0.08), Painter.GOLD))
	_play_btn.add_theme_stylebox_override("hover", UITheme.box(Color(0.65, 0.2, 0.1), Painter.GOLD))
	_play_btn.pressed.connect(_play)
	v.add_child(_play_btn)

	var start: String = GameData.campaigns.order[0]
	for cid in GameData.campaigns.order:
		if Campaign.campaign_unlocked(GameData.campaigns, GameState.progress.stars, cid):
			start = cid
	_select_campaign(start, false)
	Sfx.play_music("menu")


# --- Tanlash -----------------------------------------------------------------

func current_levels() -> Array:
	if _cid == "":
		return []
	return Campaign.region_levels(GameData.campaigns, _cid, _region)


func _select_campaign(cid: String, sound := true) -> void:
	var stars: Dictionary = GameState.progress.stars
	if not Campaign.campaign_unlocked(GameData.campaigns, stars, cid):
		Sfx.play("deny", 0.6)
		_info.text = tr("UNLOCK_RULE_REGIONS") % [Campaign.UNLOCK_AFTER_REGION, int(GameData.campaigns.campaigns[cid].require_stars)]
		return
	if sound:
		Sfx.play("click", 0.7)
	_cid = cid
	_map.texture = load("res://assets/maps/%s.png" % cid)
	var idx_tex: Texture2D = load("res://assets/maps/%s_idx.png" % cid)
	_idx_img = idx_tex.get_image()
	_mat.set_shader_parameter("idx_tex", idx_tex)
	var hero_cape: Array = GameData.heroes[GameData.campaigns.campaigns[cid].hero].look.cape
	_mat.set_shader_parameter("tint", Color(hero_cape[0], hero_cape[1], hero_cape[2]))
	# Birinchi zabt etilmagan ochiq viloyat
	var regs: Array = Campaign.regions(GameData.campaigns, cid)
	_region = 0
	for ri in regs.size():
		if Campaign.region_unlocked(GameData.campaigns, stars, cid, ri):
			_region = ri
			if not Campaign.region_conquered(GameData.campaigns, stars, cid, ri):
				break
	_select_region(_region, false)


func _select_region(ri: int, sound := true) -> void:
	var stars: Dictionary = GameState.progress.stars
	if not Campaign.region_unlocked(GameData.campaigns, stars, _cid, ri):
		Sfx.play("deny", 0.6)
		_info.text = tr("REGION_LOCKED")
		return
	if sound:
		Sfx.play("click", 0.7)
	_region = ri
	var lvls := current_levels()
	_sel = lvls[0].id
	for lv in lvls:
		if Campaign.level_unlocked(GameData.campaigns, stars, lv.id):
			_sel = lv.id
			if int(stars.get(lv.id, 0)) == 0:
				break
	_update_panel()


func select_level(lid: String) -> void:
	_sel = lid
	if Campaign.level_unlocked(GameData.campaigns, GameState.progress.stars, lid):
		Sfx.play("click", 0.7)
	else:
		Sfx.play("deny", 0.6)
	_update_panel()


func _loc_name(names: Dictionary) -> String:
	var loc := TranslationServer.get_locale().substr(0, 2)
	return str(names.get(loc, names.en))


func _update_panel() -> void:
	var stars: Dictionary = GameState.progress.stars
	var boss: Dictionary = Campaign.regions(GameData.campaigns, _cid)[_region]
	_panel_title.text = _loc_name(boss.name)
	var done := 0
	for lv in current_levels():
		if int(stars.get(lv.id, 0)) > 0:
			done += 1
	_panel_sub.text = tr("REGION_PROGRESS") % [_region + 1, done, current_levels().size()]
	var lv := Campaign.level_by_id(GameData.campaigns, _sel)
	var idx: int = int(lv.get("index", Campaign.REGION_LEVELS))
	var desc := ""
	if Campaign.is_boss(_sel):
		desc = "♛ " + tr("BOSS_LEVEL") + "\n"
	else:
		desc = tr("LEVEL_N") % idx + "\n"
	if lv.get("objective", "destroy") == "survive":
		desc += tr("OBJ_SURVIVE") % int(lv.survive)
	else:
		desc += tr("OBJ_DESTROY")
	if str(lv.get("enemy_hero", "")) != "":
		desc += "\n" + tr("ENEMY_HERO") % tr(str(GameData.heroes[lv.enemy_hero].name))
	desc += "\n" + tr("STARS_RULE")
	_info.text = desc
	_play_btn.disabled = not Campaign.level_unlocked(GameData.campaigns, stars, _sel)


func _play() -> void:
	Sfx.play("horn_attack", 0.8, 0.0)
	GameState.level_id = _sel
	GameState.hero = str(GameData.campaigns.campaigns[_cid].hero)
	get_tree().change_scene_to_file("res://scenes/battle.tscn")


# --- Xarita koordinatalari va bosish ------------------------------------------

func _map_rect() -> Rect2:
	## TextureRect ichida xarita chizilgan to'rtburchak (nisbat saqlangan, markazda).
	var s := _map.size
	var k := minf(s.x / MAP_W, s.y / MAP_H)
	var sz := Vector2(MAP_W, MAP_H) * k
	return Rect2((s - sz) * 0.5, sz)


func _to_screen(p: Array) -> Vector2:
	var r := _map_rect()
	return r.position + Vector2(float(p[0]) / MAP_W, float(p[1]) / MAP_H) * r.size


func _on_map_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed)
	if not pressed or _idx_img == null:
		return
	var r := _map_rect()
	var uv: Vector2 = (event.position - r.position) / r.size
	if uv.x < 0 or uv.y < 0 or uv.x >= 1 or uv.y >= 1:
		return
	var px := Vector2i(int(uv.x * _idx_img.get_width()), int(uv.y * _idx_img.get_height()))
	var ri := int(round(_idx_img.get_pixelv(px).r * 255.0)) - 1
	if ri >= 0:
		_select_region(ri)


func draw_overlay(ci: CanvasItem, t: float) -> void:
	if _cid == "":
		return
	var stars: Dictionary = GameState.progress.stars
	var regs: Array = GameData.maps[_cid].regions
	var font := get_theme_default_font()
	# Zabt yo'li (nuqtali)
	for i in regs.size() - 1:
		if not Campaign.region_conquered(GameData.campaigns, stars, _cid, i):
			break
		var a := _to_screen(regs[i].center)
		var b := _to_screen(regs[i + 1].center)
		var n := int(a.distance_to(b) / 12.0)
		for k in n:
			if k % 2 == 0:
				ci.draw_circle(a.lerp(b, (k + 0.5) / n), 3.0, Color(0.45, 0.1, 0.08, 0.9))
	var flag_ri := -1
	for i in regs.size():
		var p := _to_screen(regs[i].center)
		var unlocked := Campaign.region_unlocked(GameData.campaigns, stars, _cid, i)
		var conquered := Campaign.region_conquered(GameData.campaigns, stars, _cid, i)
		if unlocked and not conquered and flag_ri < 0:
			flag_ri = i
		var name := _loc_name(GameData.campaigns.campaigns[_cid].levels[i].name)
		var col := Color(0.18, 0.1, 0.05) if unlocked else Color(0.3, 0.28, 0.26)
		ci.draw_string_outline(font, p + Vector2(-90, 22), name, HORIZONTAL_ALIGNMENT_CENTER, 180, 15, 4, Color(1, 0.95, 0.85, 0.75))
		ci.draw_string(font, p + Vector2(-90, 22), name, HORIZONTAL_ALIGNMENT_CENTER, 180, 15, col)
		if conquered:
			ci.draw_circle(p, 8.0, Painter.GOLD)
			ci.draw_circle(p, 5.0, Color(0.2, 0.5, 0.2))
		elif unlocked:
			ci.draw_circle(p, 8.0, Color(0.75, 0.15, 0.1))
		else:
			ci.draw_arc(p + Vector2(0, -3), 5.0, PI, TAU, 10, Color(0.25, 0.22, 0.2), 2.0)
			ci.draw_rect(Rect2(p + Vector2(-6, -3), Vector2(12, 9)), Color(0.25, 0.22, 0.2))
		if i == _region:
			ci.draw_arc(p, 14.0 + sin(t * 5.0) * 2.0, 0, TAU, 24, Color(1, 0.85, 0.3), 3.0)
	if flag_ri >= 0:
		# Qahramon bayrog'i
		var fp := _to_screen(regs[flag_ri].center) + Vector2(0, -6)
		var cape: Array = GameData.heroes[GameData.campaigns.campaigns[_cid].hero].look.cape
		ci.draw_line(fp, fp + Vector2(0, -46), Color(0.25, 0.15, 0.08), 4.0)
		var wave := sin(t * 4.0) * 3.0
		ci.draw_colored_polygon(PackedVector2Array([fp + Vector2(2, -46), fp + Vector2(34, -42 + wave), fp + Vector2(30, -30 + wave), fp + Vector2(34, -18 + wave), fp + Vector2(2, -22)]), Color(cape[0], cape[1], cape[2]))
		ci.draw_circle(fp + Vector2(16, -33 + wave * 0.5), 5.0, Painter.GOLD)


func _process(delta: float) -> void:
	_t += delta
	var stars: Dictionary = GameState.progress.stars
	_stars_label.text = "★ %d" % Campaign.total_stars(stars)
	_coins_label.text = "◉ %d" % int(GameState.progress.coins)
	for tb in _tabs:
		tb.active = tb.cid == _cid
		tb.locked = not Campaign.campaign_unlocked(GameData.campaigns, stars, tb.cid)
	if _cid != "":
		var st := PackedFloat32Array()
		st.resize(16)
		for i in Campaign.regions(GameData.campaigns, _cid).size():
			var s := 0.0
			if Campaign.region_unlocked(GameData.campaigns, stars, _cid, i):
				s = 1.0
				if Campaign.region_conquered(GameData.campaigns, stars, _cid, i):
					s = 2.0
			if i == _region:
				s = 3.0
			st[i] = s
		_mat.set_shader_parameter("states", st)
		_mat.set_shader_parameter("time", _t)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.2, 0.11, 0.06))
