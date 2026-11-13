extends Control
## Jangdan oldin qahramon tanlash ekrani.

const ORDER := ["chingiz", "jaloliddin", "temur", "boyazid"]

var _t := 0.0
var _cards: Array = []
var _desc: Label
var _selected := ""


class HeroCard:
	extends Button
	var hero_id: String
	var selected := false
	var _u := UnitState.new()
	var _t := 0.0

	func _init(id: String) -> void:
		hero_id = id
		custom_minimum_size = Vector2(210, 250)
		focus_mode = Control.FOCUS_NONE
		_u.type = id
		_u.def = GameData.heroes[id]
		_u.team = 0
		_u.facing = 1
		_u.hp = 1.0
		_u.max_hp = 1.0
		_u.hero = true
		_u.moving = true

	func _process(delta: float) -> void:
		_t += delta
		_u.walk_phase += delta * (6.0 if selected else 0.0)
		_u.moving = selected
		queue_redraw()

	func _draw() -> void:
		var bg := Color(0.3, 0.16, 0.08, 0.92) if selected else Color(0.16, 0.1, 0.06, 0.85)
		draw_style_box(UITheme.box(bg, Painter.GOLD if selected else Color(0.6, 0.45, 0.2), 16, 4 if selected else 2), Rect2(Vector2.ZERO, size))
		var cape := Painter._look_color(_u, "cape", Color.RED)
		draw_circle(Vector2(size.x * 0.5, 115), 70.0, Color(cape.r, cape.g, cape.b, 0.35))
		Painter.draw_unit(self, _u, Vector2(size.x * 0.5 - 6, 180), 1.15, _t)
		var font := get_theme_default_font()
		var name := tr(str(_u.def.name))
		var fs := 21
		while fs > 12 and font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > size.x - 14:
			fs -= 1
		draw_string_outline(font, Vector2(0, 214), name, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, 5, Color(0, 0, 0, 0.85))
		draw_string(font, Vector2(0, 214), name, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Painter.GOLD)
		var ab := tr(str(_u.def.ability.name))
		draw_string_outline(font, Vector2(0, 238), ab, HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, 3, Color(0, 0, 0, 0.85))
		draw_string(font, Vector2(0, 238), ab, HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, UITheme.PARCHMENT)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.make()
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.add_theme_constant_override("separation", 14)
	add_child(v)
	var title := Label.new()
	title.text = tr("CHOOSE_HERO")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Painter.GOLD)
	title.add_theme_constant_override("outline_size", 10)
	v.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)
	for id in ORDER:
		var c := HeroCard.new(id)
		c.pressed.connect(_select.bind(id))
		row.add_child(c)
		_cards.append(c)
	_desc = Label.new()
	_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(880, 84)
	_desc.add_theme_font_size_override("font_size", 20)
	v.add_child(_desc)
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 16)
	v.add_child(btns)
	var back := Button.new()
	back.text = tr("BACK")
	back.custom_minimum_size = Vector2(180, 62)
	back.pressed.connect(func() -> void:
		Sfx.play("click", 0.7)
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	btns.add_child(back)
	var go := Button.new()
	go.text = tr("TO_BATTLE")
	go.custom_minimum_size = Vector2(260, 62)
	go.add_theme_font_size_override("font_size", 28)
	go.add_theme_stylebox_override("normal", UITheme.box(Color(0.55, 0.15, 0.08), Painter.GOLD))
	go.add_theme_stylebox_override("hover", UITheme.box(Color(0.65, 0.2, 0.1), Painter.GOLD))
	go.pressed.connect(_start)
	btns.add_child(go)
	_select(GameState.hero if GameState.hero in ORDER else "temur", false)


func _select(id: String, sound := true) -> void:
	if sound:
		Sfx.play("click", 0.7)
	_selected = id
	for c in _cards:
		c.selected = c.hero_id == id
	var h: Dictionary = GameData.heroes[id]
	_desc.text = "%s — %s\n%s: %s" % [tr(str(h.name)), tr(str(h.title)), tr(str(h.ability.name)), tr(str(h.ability.desc))]


func _start() -> void:
	Sfx.play("horn_attack", 0.8, 0.0)
	GameState.hero = _selected
	get_tree().change_scene_to_file("res://scenes/battle.tscn")


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var top := Color(0.25, 0.12, 0.08)
	var bot := Color(0.62, 0.32, 0.16)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]), PackedColorArray([top, top, bot, bot]))
	for i in 24:
		var x := fmod(i * 97.0 + _t * (8.0 + i % 5), w + 40.0) - 20.0
		var y := h - fmod(i * 53.0 + _t * (14.0 + i % 7), h)
		draw_circle(Vector2(x, y), 1.5 + (i % 3), Color(1, 0.75, 0.35, 0.35))
