extends SceneTree
## Grafika uslublarini yonma-yon solishtirish: chapda eski, o'ngda yangi (Painter.style_v2).
##   xvfb-run -a godot --path . --rendering-driver opengl3 -s res://tools/art_preview.gd -- --out=/tmp/art.png
class Board:
	extends Node2D
	var t := 0.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.62, 0.78, 0.9))
		draw_rect(Rect2(0, 430, 1280, 290), Color(0.5, 0.58, 0.32))
		draw_line(Vector2(640, 20), Vector2(640, 700), Color(0, 0, 0, 0.3), 3.0)
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(0, 50), "ESKI", HORIZONTAL_ALIGNMENT_CENTER, 640, 34, Color(0.1, 0.1, 0.1))
		draw_string(font, Vector2(640, 50), "YANGI", HORIZONTAL_ALIGNMENT_CENTER, 640, 34, Color(0.1, 0.1, 0.1))
		var types := ["swordsman", "archer", "cavalry", "musketeer"]
		for side in 2:
			Painter.style_v2 = side == 1
			for i in types.size():
				for team in 2:
					var u := UnitState.new()
					u.type = types[i]
					u.def = defs[types[i]]
					u.team = team
					u.facing = 1 if team == 0 else -1
					u.hp = 1.0
					u.max_hp = 1.0
					u.moving = true
					u.walk_phase = 0.9 + i
					u.id = i
					var x := 90.0 + side * 640.0 + i * 150.0 + team * 40.0
					var y := 400.0 if team == 0 else 640.0
					draw_set_transform(Vector2(x, y + 6), 0.0, Vector2(1.0, 0.3))
					draw_circle(Vector2.ZERO, 22.0, Color(0, 0, 0, 0.2))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
					Painter.draw_unit(self, u, Vector2(x, y), 2.0, t)
		Painter.style_v2 = true


var _frames := 0
var _out := "/tmp/art.png"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.split("=")[1]
	var b := Board.new()
	root.add_child(b)


func _process(_d: float) -> bool:
	_frames += 1
	if _frames == 5:
		root.get_texture().get_image().save_png(_out)
		print("SAVED ", _out)
		return true
	return false
