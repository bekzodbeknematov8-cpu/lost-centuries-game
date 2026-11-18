extends Control
## Kunlik sinov: bugungi qoida, raqib, mukofot; sarkarda tanlash va jangga kirish.

const HEROES := ["chingiz", "jaloliddin", "temur", "boyazid", "bobur", "alp"]

var _t := 0.0
var _hero := ""
var _hero_btns: Dictionary = {}
var _info: Label
var _status: Label
var _art: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.make()
	_hero = GameState.hero if GameState.hero_owned(GameState.hero) else "chingiz"
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
	title.text = tr("MODE_DAILY")
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Painter.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(130, 0)
	top.add_child(sp)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(900, 470)
	panel.add_theme_stylebox_override("panel", UITheme.box(Color(0.2, 0.12, 0.06, 0.95), Painter.GOLD, 16, 3))
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var rid := DailyChallenge.rule_id(GameData.daily_challenge, GameState.today())
	var rule: Dictionary = GameData.daily_challenge.rules[rid]
	var rn := Label.new()
	rn.text = tr(str(rule.name))
	rn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rn.add_theme_font_size_override("font_size", 34)
	rn.add_theme_color_override("font_color", Painter.GOLD)
	v.add_child(rn)
	var rd := Label.new()
	rd.text = tr(str(rule.desc))
	rd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rd.add_theme_font_size_override("font_size", 20)
	v.add_child(rd)
	_art = Control.new()
	_art.custom_minimum_size = Vector2(0, 120)
	_art.draw.connect(_draw_art)
	v.add_child(_art)
	_info = Label.new()
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.add_theme_font_size_override("font_size", 18)
	v.add_child(_info)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 8)
	v.add_child(hb)
	for h in HEROES:
		var b := Button.new()
		b.custom_minimum_size = Vector2(140, 42)
		b.pressed.connect(func() -> void:
			if not GameState.hero_owned(h):
				Sfx.play("deny", 0.6)
				return
			Sfx.play("click", 0.7)
			_hero = h
			_refresh())
		hb.add_child(b)
		_hero_btns[h] = b
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 18)
	v.add_child(_status)
	var go := Button.new()
	go.text = tr("TO_BATTLE")
	go.custom_minimum_size = Vector2(320, 62)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.add_theme_font_size_override("font_size", 26)
	go.add_theme_stylebox_override("normal", UITheme.box(Color(0.55, 0.15, 0.08), Painter.GOLD))
	go.add_theme_stylebox_override("hover", UITheme.box(Color(0.65, 0.2, 0.1), Painter.GOLD))
	go.pressed.connect(_play)
	v.add_child(go)
	_refresh()
	Sfx.play_music("menu")


func _refresh() -> void:
	var today := GameState.today()
	var eh := DailyChallenge.enemy_hero(GameData.heroes, _hero, today)
	var rid := DailyChallenge.rule_id(GameData.daily_challenge, today)
	var no_heroes := bool(GameData.daily_challenge.rules[rid].cfg.get("no_heroes", false))
	_info.text = "" if no_heroes else tr("DC_ENEMY") % tr(str(GameData.heroes[eh].name))
	var rw := ""
	for r in GameData.daily_challenge.reward:
		rw += Rewards.short_text(r) + "  "
	if DailyChallenge.done_today(GameState.progress, today):
		_status.text = "✓ " + tr("DC_DONE")
		_status.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	else:
		_status.text = tr("DC_REWARD") % rw.strip_edges()
		_status.add_theme_color_override("font_color", UITheme.PARCHMENT)
	var font := get_theme_default_font()
	for h in HEROES:
		var b: Button = _hero_btns[h]
		var fit := UITheme.fit_text(font, tr(str(GameData.heroes[h].name)), 124.0, 18, 11)
		b.text = fit[0]
		b.add_theme_font_size_override("font_size", fit[1])
		b.disabled = not GameState.hero_owned(h)
		b.add_theme_stylebox_override("normal", UITheme.box(Color(0.5, 0.3, 0.08) if h == _hero else Color(0.25, 0.15, 0.08), Painter.GOLD if h == _hero else Color(0.5, 0.38, 0.2), 10, 3 if h == _hero else 2))
	_art.queue_redraw()


func _draw_art() -> void:
	## O'yinchi va raqib sarkardalari yuzma-yuz.
	var today := GameState.today()
	var c := _art.size * 0.5
	var mine := UnitState.new()
	mine.type = _hero
	mine.def = GameData.heroes[_hero]
	mine.team = 0
	mine.facing = 1
	mine.hp = 1.0
	mine.max_hp = 1.0
	mine.hero = true
	Painter.draw_unit(_art, mine, c + Vector2(-110, 50), 0.9, _t)
	var eh := DailyChallenge.enemy_hero(GameData.heroes, _hero, today)
	var rid := DailyChallenge.rule_id(GameData.daily_challenge, today)
	if eh != "" and not bool(GameData.daily_challenge.rules[rid].cfg.get("no_heroes", false)):
		var en := UnitState.new()
		en.type = eh
		en.def = GameData.heroes[eh]
		en.team = 1
		en.facing = -1
		en.hp = 1.0
		en.max_hp = 1.0
		en.hero = true
		Painter.draw_unit(_art, en, c + Vector2(110, 50), 0.9, _t)
	var font := get_theme_default_font()
	_art.draw_string_outline(font, c + Vector2(-30, 10), "VS", HORIZONTAL_ALIGNMENT_CENTER, 60, 34, 6, Color(0, 0, 0, 0.8))
	_art.draw_string(font, c + Vector2(-30, 10), "VS", HORIZONTAL_ALIGNMENT_CENTER, 60, 34, Painter.GOLD)


func _play() -> void:
	Sfx.play("horn_attack", 0.8, 0.0)
	GameState.mode = "daily"
	GameState.level_id = ""
	GameState.hero = _hero
	Transition.go("res://scenes/battle.tscn")


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	_art.queue_redraw()


func _draw() -> void:
	MenuArt.backdrop(self, size, _t)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
