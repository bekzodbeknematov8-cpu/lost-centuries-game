extends Node
## O'yin ma'lumotlarini (JSON) bir marta yuklaydi.

var units: Dictionary = {}
var ai: Dictionary = {}
var heroes: Dictionary = {}


func _init() -> void:
	units = load_json("res://data/units.json")
	ai = load_json("res://data/ai.json")
	heroes = load_json("res://data/heroes.json")


static func load_json(path: String) -> Dictionary:
	var res: Variant = load(path)
	if res is JSON:
		return (res as JSON).data
	var txt := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(txt)
	if parsed is Dictionary:
		return parsed
	push_error("JSON yuklanmadi: %s" % path)
	return {}
