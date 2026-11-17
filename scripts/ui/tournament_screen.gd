extends Control
## Turnir: sarkarda tanlash, 8 raundli zinapoya, boshlash/davom ettirish.

const HEROES := ["chingiz", "jaloliddin", "temur", "boyazid", "bobur", "alp"]

var _t := 0.0
var _hero := ""
var _hero_btns: Dictionary = {}
var _ladder: Control
var _info: Label
var _go: Button
var _give_up: Button
var _coins: Label


static func _unit(id: String, team: int) -> UnitState:
	var u := UnitState.new()
	u.type = id
	u.def = GameData.heroes[id]
	u.team = team
	u.facing = 1 if team == 0 else -1
	u.hp = 1.0
	u.max_hp = 1.0
	u.hero = true
	return u


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.make()
	var t: Dictionary = GameState.progress.tournament
	_hero = str(t.hero) if bool(t.active) else GameState.hero
	if not GameState.hero_owned(_hero):
		_hero = "chingiz"
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
		Transition.go("res://scenes/mode_select.tscn"))
	top.add_child(back)
	var title := Label.new()
	title.text = tr("MODE_TOURNAMENT")
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Painter.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	_coins = Label.new()
	_coins.add_theme_font_size_override("font_size", 24)
	top.add_child(_coins)

	# Sarkarda tanlash
	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hb.offset_top = 74
	hb.offset_left = 40
	hb.offset_right = -40
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 12)
	add_child(hb)
	for h in HEROES:
		var b := Button.new()
		b.custom_minimum_size = Vector2(186, 46)
		b.text = tr(str(GameData.heroes[h].name))
		b.clip_text = true
		b.pressed.connect(func() -> void:
			if bool(GameState.progress.tournament.active) or not GameState.hero_owned(h):
				Sfx.play("deny", 0.6)
				return
			Sfx.play("click", 0.7)
			_hero = h
			_refresh())
		hb.add_child(b)
		_hero_btns[h] = b

	# Zinapoya
	_ladder = Control.new()
	_ladder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ladder.offset_top = 130
	_ladder.offset_bottom = -170
	_ladder.offset_left = 30
	_ladder.offset_right = -30
	_ladder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ladder.draw.connect(_draw_ladder)
	add_child(_ladder)

	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -160
	bottom.offset_bottom = -12
	bottom.offset_left = 120
	bottom.offset_right = -120
	bottom.add_theme_constant_override("separation", 8)
	add_child(bottom)
	_info = Label.new()
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.add_theme_font_size_override("font_size", 17)
	bottom.add_child(_info)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	bottom.add_child(row)
	_give_up = Button.new()
	_give_up.text = tr("TOURN_GIVE_UP")
	_give_up.custom_minimum_size = Vector2(220, 60)
	_give_up.pressed.connect(func() -> void:
		Sfx.play("horn_retreat", 0.7, 0.02)
		GameState.give_up_tournament()
		_refresh())
	row.add_child(_give_up)
	_go = Button.new()
	_go.custom_minimum_size = Vector2(340, 64)
	_go.add_theme_font_size_override("font_size", 26)
	_go.add_theme_stylebox_override("normal", UITheme.box(Color(0.55, 0.15, 0.08), Painter.GOLD))
	_go.add_theme_stylebox_override("hover", UITheme.box(Color(0.65, 0.2, 0.1), Painter.GOLD))
	_go.pressed.connect(_play)
	row.add_child(_go)
	_refresh()
	Sfx.play_music("menu")


func _refresh() -> void:
	var t: Dictionary = GameState.progress.tournament
	var active := bool(t.active)
	_coins.text = "◉ %d" % int(GameState.progress.coins)
	for h in HEROES:
		var b: Button = _hero_btns[h]
		var owned := GameState.hero_owned(h)
		b.disabled = (active and h != _hero) or not owned
		b.text = tr(str(GameData.heroes[h].name))
		var bfs := 22
		var bf := b.get_theme_default_font()
		while bfs > 11 and bf.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, bfs).x > b.custom_minimum_size.x - 34:
			bfs -= 1
		b.add_theme_font_size_override("font_size", bfs)
		b.add_theme_stylebox_override("normal", UITheme.box(Color(0.5, 0.3, 0.08) if h == _hero else Color(0.25, 0.15, 0.08), Painter.GOLD if h == _hero else Color(0.5, 0.38, 0.2), 10, 3 if h == _hero else 2))
	_give_up.visible = active
	_go.text = (tr("TOURN_CONTINUE") % (int(t.round) + 1)) if active else tr("TOURN_START")
	_info.text = tr("TOURN_RULES") + "\n" + tr("TOURN_BEST") % [int(t.best), Tournament.rounds(GameData.tournament)]
	if int(t.champion) > 0:
		_info.text += "   ·   " + tr("TOURN_CHAMP_COUNT") % int(t.champion)
	_ladder.queue_redraw()


func _play() -> void:
	var t: Dictionary = GameState.progress.tournament
	if not bool(t.active):
		GameState.start_tournament(_hero)
	Sfx.play("horn_attack", 0.8, 0.0)
	GameState.mode = "tournament"
	GameState.level_id = ""
	GameState.hero = str(GameState.progress.tournament.hero)
	Transition.go("res://scenes/battle.tscn")


func _draw_ladder() -> void:
	var t: Dictionary = GameState.progress.tournament
	var n := Tournament.rounds(GameData.tournament)
	var cur := int(t.round) if bool(t.active) else -1
	var sz := _ladder.size
	var font := get_theme_default_font()
	var step := sz.x / (n + 1)
	# Yo'l
	var base_y := sz.y * 0.62
	for i in n:
		var x := step * (i + 0.5)
		var y := base_y - float(i) * sz.y * 0.05
		var x2 := step * (i + 1.5)
		var y2 := base_y - float(i + 1) * sz.y * 0.05
		_ladder.draw_line(Vector2(x, y), Vector2(x2, y2), Color(0.95, 0.8, 0.45, 0.6) if i < int(t.round) and bool(t.active) else Color(0.5, 0.42, 0.32, 0.6), 5.0)
	for i in n:
		var r: Dictionary = GameData.tournament.rounds[i]
		var p := Vector2(step * (i + 0.5), base_y - float(i) * sz.y * 0.05)
		var done := bool(t.active) and i < int(t.round)
		var is_cur := i == cur
		var col := Color(0.3, 0.5, 0.25) if done else (Color(0.62, 0.2, 0.12) if is_cur else Color(0.3, 0.24, 0.2))
		if is_cur:
			_ladder.draw_circle(p, 40.0 + sin(_t * 5.0) * 3.0, Color(1, 0.85, 0.3, 0.8))
		_ladder.draw_circle(p, 36.0, Color(0.15, 0.08, 0.04))
		_ladder.draw_circle(p, 33.0, col)
		# Raqib sarkarda
		var eh := Tournament.enemy_hero(GameData.heroes, _hero, i)
		if eh != "":
			var u := _unit(eh, 1)
			Painter.draw_unit(_ladder, u, p + Vector2(4, 22), 0.42, _t)
		_ladder.draw_string(font, p + Vector2(-60, -48), tr("TOURN_ROUND") % (i + 1), HORIZONTAL_ALIGNMENT_CENTER, 120, 16, Painter.GOLD)
		_ladder.draw_string(font, p + Vector2(-60, 60), "◉ %d" % int(r.coins), HORIZONTAL_ALIGNMENT_CENTER, 120, 16, UITheme.PARCHMENT)
		_ladder.draw_string(font, p + Vector2(-70, 80), tr("AI_" + str(r.ai).to_upper()), HORIZONTAL_ALIGNMENT_CENTER, 140, 13, Color(0.85, 0.75, 0.6))
		if done:
			_ladder.draw_line(p + Vector2(-14, 0), p + Vector2(-4, 12), Color(0.9, 1, 0.8), 6.0)
			_ladder.draw_line(p + Vector2(-4, 12), p + Vector2(16, -12), Color(0.9, 1, 0.8), 6.0)
	# Kubok
	var cp := Vector2(step * (n + 0.5), base_y - float(n) * sz.y * 0.05)
	var g := Painter.GOLD
	_ladder.draw_circle(cp, 46.0, Color(1, 0.85, 0.3, 0.15 + 0.1 * sin(_t * 3.0)))
	_ladder.draw_colored_polygon(PackedVector2Array([cp + Vector2(-26, -34), cp + Vector2(26, -34), cp + Vector2(18, 4), cp + Vector2(-18, 4)]), g)
	_ladder.draw_rect(Rect2(cp + Vector2(-6, 4), Vector2(12, 18)), g)
	_ladder.draw_rect(Rect2(cp + Vector2(-22, 22), Vector2(44, 10)), g)
	_ladder.draw_string(font, cp + Vector2(-80, 58), tr("TOURN_PRIZE"), HORIZONTAL_ALIGNMENT_CENTER, 160, 15, Painter.GOLD)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	_ladder.queue_redraw()


func _draw() -> void:
	MenuArt.backdrop(self, size, _t)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
