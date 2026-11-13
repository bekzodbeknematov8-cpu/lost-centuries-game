extends Control
## Bosh menyu.

var _t := 0.0
var _demo: Array[UnitState] = []
var _lang_btn: Button
var _sound_btn: Button
var _music_btn: Button
var _content: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.make()
	# Fonda yurib turgan jangchilar
	var types := ["swordsman", "spearman", "archer", "cavalry", "swordsman", "archer"]
	for i in types.size():
		var u := UnitState.new()
		u.type = types[i]
		u.def = GameData.units[types[i]]
		u.team = i % 2
		u.facing = 1 if u.team == 0 else -1
		u.hp = 1.0
		u.max_hp = 1.0
		u.moving = true
		u.walk_phase = i * 1.3
		u.x = 200.0 + i * 160.0
		u.lane = float(i % 3) / 2.0
		_demo.append(u)
	_build()
	Sfx.play_music("menu")


func _build() -> void:
	if _content:
		_content.queue_free()
	_content = VBoxContainer.new()
	_content.set_anchors_preset(Control.PRESET_CENTER)
	_content.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_content.grow_vertical = Control.GROW_DIRECTION_BOTH
	_content.add_theme_constant_override("separation", 12)
	_content.offset_top = -40
	add_child(_content)
	var title := Label.new()
	title.text = tr("GAME_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 86)
	title.add_theme_color_override("font_color", Painter.GOLD)
	title.add_theme_constant_override("outline_size", 12)
	_content.add_child(title)
	var sub := Label.new()
	sub.text = tr("MENU_SUBTITLE")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 28)
	_content.add_child(sub)
	_content.add_child(_gap(10))
	for d in [["MENU_PLAY_EASY", "easy"], ["MENU_PLAY_NORMAL", "normal"], ["MENU_PLAY_HARD", "hard"]]:
		var b := Button.new()
		b.text = tr(d[0])
		b.custom_minimum_size = Vector2(380, 64)
		b.add_theme_font_size_override("font_size", 28)
		b.pressed.connect(_start.bind(d[1]))
		_content.add_child(b)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	_content.add_child(row)
	_lang_btn = _small_btn(row, tr("MENU_LANGUAGE"), _on_lang)
	_sound_btn = _small_btn(row, "", _on_sound)
	_music_btn = _small_btn(row, "", _on_music)
	_refresh_toggles()
	var note := Label.new()
	note.text = "%s  v%s" % [tr("PROTOTYPE_NOTE"), ProjectSettings.get_setting("application/config/version")]
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 16)
	note.modulate = Color(1, 1, 1, 0.7)
	_content.add_child(note)


func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _small_btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _refresh_toggles() -> void:
	var s: Dictionary = GameState.settings
	_sound_btn.text = "%s: %s" % [tr("MENU_SOUND"), tr("ON") if float(s.sfx_volume) > 0.0 else tr("OFF")]
	_music_btn.text = "%s: %s" % [tr("MENU_MUSIC"), tr("ON") if float(s.music_volume) > 0.0 else tr("OFF")]


func _start(diff: String) -> void:
	Sfx.play("click", 0.7)
	GameState.difficulty = diff
	get_tree().change_scene_to_file("res://scenes/battle.tscn")


func _on_lang() -> void:
	Sfx.play("click", 0.7)
	GameState.next_locale()
	_build()


func _on_sound() -> void:
	GameState.settings.sfx_volume = 0.0 if float(GameState.settings.sfx_volume) > 0.0 else 0.9
	GameState.save_settings()
	Sfx.play("click", 0.7)
	_refresh_toggles()


func _on_music() -> void:
	GameState.settings.music_volume = 0.0 if float(GameState.settings.music_volume) > 0.0 else 0.7
	GameState.save_settings()
	Sfx.update_music_volume()
	_refresh_toggles()


func _process(delta: float) -> void:
	_t += delta
	for u in _demo:
		u.walk_phase += delta * float(u.def.speed) * 0.09
		u.x += u.facing * float(u.def.speed) * delta * 0.5
		var w := size.x
		if u.x > w + 80.0:
			u.x = -80.0
		elif u.x < -80.0:
			u.x = w + 80.0
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var top := Color(0.35, 0.18, 0.12)
	var mid := Color(0.95, 0.62, 0.32)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.72), Vector2(0, h * 0.72)]),
		PackedColorArray([top, top, mid, mid]))
	draw_circle(Vector2(w * 0.5, h * 0.62), 160.0, Color(1, 0.85, 0.5, 0.35))
	var pts := PackedVector2Array([Vector2(0, h)])
	for i in 17:
		var x := w * i / 16.0
		pts.append(Vector2(x, h * 0.64 - sin(i * 1.7) * 30.0 - sin(i * 0.6) * 25.0))
	pts.append(Vector2(w, h))
	draw_colored_polygon(pts, Color(0.45, 0.25, 0.16))
	draw_rect(Rect2(0, h * 0.78, w, h * 0.22), Color(0.33, 0.2, 0.13))
	for u in _demo:
		Painter.draw_unit(self, u, Vector2(u.x, h * 0.86 + u.lane * 40.0), 0.9, _t)
