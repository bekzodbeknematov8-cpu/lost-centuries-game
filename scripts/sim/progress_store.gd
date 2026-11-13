class_name ProgressStore
extends RefCounted
## Kampaniya progressini (yulduzlar, tangalar) saqlash/yuklash. Autoload'larga bog'liq emas.

const VERSION := 1

var path: String
var data: Dictionary = {"version": VERSION, "stars": {}, "coins": 0}


func _init(file_path: String) -> void:
	path = file_path


func load_file() -> void:
	data = {"version": VERSION, "stars": {}, "coins": 0}
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		push_warning("progress fayli buzilgan, yangidan boshlanadi")
		return
	var p: Dictionary = parsed
	if p.get("stars") is Dictionary:
		for k in p.stars:
			data.stars[str(k)] = clampi(int(p.stars[k]), 0, 3)
	data.coins = maxi(0, int(p.get("coins", 0)))


func save_file() -> void:
	## Avval vaqtinchalik faylga yoziladi, keyin almashtiriladi (yozish uzilsa ham buzilmaydi).
	data.version = VERSION
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()
	DirAccess.rename_absolute(tmp, path)


func record_result(level_id: String, stars: int, coins: int) -> int:
	## Natijani yozadi; yangi qo'shilgan yulduzlar sonini qaytaradi.
	var old := int(data.stars.get(level_id, 0))
	if stars > old:
		data.stars[level_id] = stars
	data.coins = int(data.coins) + coins
	save_file()
	return maxi(0, stars - old)
