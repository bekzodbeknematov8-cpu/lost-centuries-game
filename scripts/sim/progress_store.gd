class_name ProgressStore
extends RefCounted
## Kampaniya progressini (yulduzlar, tangalar) saqlash/yuklash. Autoload'larga bog'liq emas.

const VERSION := 1

var path: String
const AD_DAILY_LIMIT := 5

var data: Dictionary = {"version": VERSION, "stars": {}, "coins": 0, "gems": 0, "best_wave": 0, "ad_day": "", "ad_count": 0}


func _init(file_path: String) -> void:
	path = file_path


func load_file() -> void:
	data = {"version": VERSION, "stars": {}, "coins": 0, "gems": 0, "best_wave": 0, "ad_day": "", "ad_count": 0}
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
	data.gems = maxi(0, int(p.get("gems", 0)))
	data.best_wave = maxi(0, int(p.get("best_wave", 0)))
	data.ad_day = str(p.get("ad_day", ""))
	data.ad_count = maxi(0, int(p.get("ad_count", 0)))


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


func record_wave(waves: int, coins: int) -> bool:
	## Cheksiz mudofaa natijasi; yangi rekord bo'lsa true.
	var rec := waves > int(data.best_wave)
	if rec:
		data.best_wave = waves
	data.coins = int(data.coins) + coins
	save_file()
	return rec


func ads_left(today: String) -> int:
	if str(data.ad_day) != today:
		return AD_DAILY_LIMIT
	return maxi(0, AD_DAILY_LIMIT - int(data.ad_count))


func note_ad_reward(today: String, bonus_coins: int) -> bool:
	## Reklama mukofoti (2× uchun qo'shimcha tangalar). Kunlik chegaradan oshsa false.
	if ads_left(today) <= 0:
		return false
	if str(data.ad_day) != today:
		data.ad_day = today
		data.ad_count = 0
	data.ad_count = int(data.ad_count) + 1
	data.coins = int(data.coins) + bonus_coins
	save_file()
	return true
