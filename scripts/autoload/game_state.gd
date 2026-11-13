extends Node
## O'yinchi tanlovlari va sozlamalari (saqlanadi).

const SETTINGS_PATH := "user://settings.json"

var difficulty: String = "easy"
var settings: Dictionary = {
	"locale": "uz",
	"music_volume": 0.7,
	"sfx_volume": 0.9,
}


const LOCALES := ["uz", "en", "ru", "tr"]


func _ready() -> void:
	_load_translations()
	load_settings()
	TranslationServer.set_locale(str(settings.locale))


func _load_translations() -> void:
	## data/strings.json dan barcha tillar uchun tarjimalarni ro'yxatdan o'tkazadi.
	var strings := GameData.load_json("res://data/strings.json")
	for loc in LOCALES:
		var tr_obj := Translation.new()
		tr_obj.locale = loc
		for key in strings:
			var entry: Dictionary = strings[key]
			tr_obj.add_message(key, str(entry.get(loc, entry.get("en", key))))
		TranslationServer.add_translation(tr_obj)


func next_locale() -> void:
	var i := LOCALES.find(str(settings.locale))
	set_locale(LOCALES[(i + 1) % LOCALES.size()])


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	if parsed is Dictionary:
		for k in parsed:
			settings[k] = parsed[k]


func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings))


func set_locale(loc: String) -> void:
	settings.locale = loc
	TranslationServer.set_locale(loc)
	save_settings()
