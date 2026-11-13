extends Control
## Rejim tanlash: Kampaniya, Erkin jang, Cheksiz mudofaa, Turnir, Haftalik vazifalar.

var _t := 0.0
var _diff_panel: PanelContainer


class ModeCard:
	extends Button
	var kind := ""
	var title := ""
	var sub := ""
	var locked := false
	var _t := 0.0

	func _init(k: String, ttl: String, s: String, lock := false) -> void:
		kind = k
		title = ttl
		sub = s
		locked = lock
		custom_minimum_size = Vector2(212, 330)
		focus_mode = Control.FOCUS_NONE
		for st in ["normal", "hover", "pressed", "disabled"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _draw() -> void:
		var hov := is_hovered() and not locked
		var r := Rect2(Vector2.ZERO, size)
		draw_style_box(UITheme.box(Color(0.14, 0.08, 0.05), Painter.GOLD if hov else Color(0.7, 0.5, 0.2), 14, 4), r)
		var art := Rect2(8, 8, size.x - 16, size.y - 96)
		var bgc := {"campaign": Color(0.85, 0.75, 0.55), "skirmish": Color(0.62, 0.22, 0.14), "endless": Color(0.25, 0.3, 0.45),
			"tournament": Color(0.55, 0.38, 0.1), "weekly": Color(0.22, 0.42, 0.3)}
		draw_rect(art, bgc.get(kind, Color.GRAY))
		var c := art.get_center()
		var g := Painter.GOLD
		match kind:
			"campaign":
				for i in 6:
					draw_line(Vector2(art.position.x + 10, art.position.y + 30 + i * 32), Vector2(art.end.x - 10, art.position.y + 26 + i * 32), Color(0.7, 0.58, 0.38), 1.0)
				var path := [c + Vector2(-70, 70), c + Vector2(-30, 30), c + Vector2(10, 50), c + Vector2(40, -10), c + Vector2(60, -60)]
				for i in path.size() - 1:
					for k in 6:
						if k % 2 == 0:
							draw_circle(path[i].lerp(path[i + 1], (k + 0.5) / 6.0), 3.0, Color(0.5, 0.12, 0.08))
				draw_line(c + Vector2(60, -60), c + Vector2(60, -110), Color(0.3, 0.18, 0.08), 4.0)
				draw_colored_polygon(PackedVector2Array([c + Vector2(62, -110), c + Vector2(100, -104 + sin(_t * 4) * 3), c + Vector2(62, -86)]), Color(0.75, 0.15, 0.1))
			"skirmish":
				for s in [-1, 1]:
					var a := Vector2(c.x - 60 * s, c.y + 70)
					var b := Vector2(c.x + 60 * s, c.y - 70)
					draw_line(a, b, Color(0.9, 0.92, 0.95), 8.0)
					draw_line(a + Vector2(14 * s, -10), a + Vector2(-6 * s, 14), g, 6.0)
				draw_circle(c, 34.0, Color(0.3, 0.15, 0.08))
				draw_circle(c, 28.0, g)
				draw_circle(c, 10.0, Color(0.6, 0.15, 0.1))
			"endless":
				draw_rect(Rect2(c + Vector2(-40, -40), Vector2(80, 120)), Color(0.6, 0.55, 0.5))
				for i in 4:
					draw_rect(Rect2(c + Vector2(-40 + i * 22, -54), Vector2(14, 14)), Color(0.6, 0.55, 0.5))
				draw_rect(Rect2(c + Vector2(-14, 40), Vector2(28, 40)), Color(0.25, 0.15, 0.1))
				for i in 3:
					var y := c.y - 60 + i * 50 + sin(_t * 3 + i) * 4
					draw_line(Vector2(art.end.x - 10, y), Vector2(c.x + 50, y + 10), Color(0.85, 0.3, 0.25), 4.0)
					draw_colored_polygon(PackedVector2Array([Vector2(c.x + 50, y + 10), Vector2(c.x + 64, y), Vector2(c.x + 62, y + 18)]), Color(0.85, 0.3, 0.25))
			"tournament":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-40, -60), c + Vector2(40, -60), c + Vector2(28, 0), c + Vector2(-28, 0)]), g)
				draw_rect(Rect2(c + Vector2(-8, 0), Vector2(16, 30)), g)
				draw_rect(Rect2(c + Vector2(-34, 30), Vector2(68, 16)), g)
			"weekly":
				draw_rect(Rect2(c + Vector2(-55, -50), Vector2(110, 100)), Color(0.95, 0.9, 0.8))
				draw_rect(Rect2(c + Vector2(-55, -50), Vector2(110, 24)), Color(0.75, 0.2, 0.15))
				for i in 7:
					draw_circle(c + Vector2(-40 + (i % 4) * 27, -5 + (i / 4) * 30), 8.0, g if i < 3 else Color(0.7, 0.65, 0.55))
		if locked:
			draw_rect(art, Color(0, 0, 0, 0.55))
			draw_arc(c + Vector2(0, -14), 16.0, PI, TAU, 14, Color(0.9, 0.85, 0.75), 5.0)
			draw_rect(Rect2(c + Vector2(-22, -14), Vector2(44, 34)), Color(0.9, 0.85, 0.75))
		var font := get_theme_default_font()
		draw_rect(Rect2(8, size.y - 86, size.x - 16, 78), Color(0.2, 0.3, 0.55) if not locked else Color(0.25, 0.25, 0.28))
		var fs := 26
		while fs > 14 and font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > size.x - 24:
			fs -= 1
		draw_string_outline(font, Vector2(0, size.y - 50), title, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, 5, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(0, size.y - 50), title, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, g)
		draw_string(font, Vector2(0, size.y - 22), sub, HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, UITheme.PARCHMENT)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.make()
	var back := Button.new()
	back.text = "‹ " + tr("BACK")
	back.position = Vector2(16, 12)
	back.custom_minimum_size = Vector2(130, 52)
	back.pressed.connect(func() -> void:
		Sfx.play("click", 0.7)
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	add_child(back)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	row.add_theme_constant_override("separation", 18)
	add_child(row)
	var best := int(GameState.progress.get("best_wave", 0))
	var cards := [
		["campaign", tr("MENU_CAMPAIGN"), tr("MODE_CAMPAIGN_SUB"), false, _campaign],
		["skirmish", tr("MENU_SKIRMISH"), tr("MODE_SKIRMISH_SUB"), false, _skirmish],
		["endless", tr("MENU_ENDLESS"), tr("BEST_WAVE") % best if best > 0 else tr("MODE_ENDLESS_SUB"), false, _endless],
		["tournament", tr("MODE_TOURNAMENT"), tr("COMING_SOON"), true, _locked],
		["weekly", tr("MODE_WEEKLY"), tr("COMING_SOON"), true, _locked],
	]
	for cd in cards:
		var card := ModeCard.new(cd[0], cd[1], cd[2], cd[3])
		card.pressed.connect(cd[4])
		row.add_child(card)
	_build_difficulty()
	Sfx.play_music("menu")


func _build_difficulty() -> void:
	_diff_panel = PanelContainer.new()
	_diff_panel.set_anchors_preset(Control.PRESET_CENTER)
	_diff_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_diff_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_diff_panel.visible = false
	add_child(_diff_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_diff_panel.add_child(v)
	var t := Label.new()
	t.text = tr("CHOOSE_DIFFICULTY")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", Painter.GOLD)
	v.add_child(t)
	for d in [["MENU_PLAY_EASY", "easy"], ["MENU_PLAY_NORMAL", "normal"], ["MENU_PLAY_HARD", "hard"]]:
		var b := Button.new()
		b.text = tr(d[0])
		b.custom_minimum_size = Vector2(360, 60)
		b.pressed.connect(func() -> void:
			Sfx.play("click", 0.7)
			GameState.difficulty = d[1]
			GameState.mode = "skirmish"
			GameState.level_id = ""
			get_tree().change_scene_to_file("res://scenes/hero_select.tscn"))
		v.add_child(b)
	var close := Button.new()
	close.text = tr("BACK")
	close.custom_minimum_size = Vector2(360, 50)
	close.pressed.connect(func() -> void: _diff_panel.visible = false)
	v.add_child(close)


func _campaign() -> void:
	Sfx.play("click", 0.7)
	get_tree().change_scene_to_file("res://scenes/campaign_map.tscn")


func _skirmish() -> void:
	Sfx.play("click", 0.7)
	_diff_panel.visible = true


func _endless() -> void:
	Sfx.play("click", 0.7)
	GameState.mode = "endless"
	GameState.level_id = ""
	get_tree().change_scene_to_file("res://scenes/hero_select.tscn")


func _locked() -> void:
	Sfx.play("deny", 0.6)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	MenuArt.backdrop(self, size, _t)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.25))
