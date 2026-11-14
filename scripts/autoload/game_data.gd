extends Node
## O'yin ma'lumotlarini (JSON) bir marta yuklaydi.

var units: Dictionary = {}
var ai: Dictionary = {}
var heroes: Dictionary = {}
var campaigns: Dictionary = {}
var facts: Dictionary = {}
var maps: Dictionary = {}
var upgrades: Dictionary = {}
var tactics: Dictionary = {}


func _init() -> void:
	units = load_json("res://data/units.json")
	ai = load_json("res://data/ai.json")
	heroes = load_json("res://data/heroes.json")
	campaigns = load_json("res://data/campaigns.json")
	facts = load_json("res://data/facts.json")
	maps = load_json("res://data/maps.json")
	upgrades = load_json("res://data/upgrades.json")
	tactics = load_json("res://data/tactics.json")


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
