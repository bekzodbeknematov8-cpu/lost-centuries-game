class_name ProgressStore
extends RefCounted
## Kampaniya progressini (yulduzlar, tangalar) saqlash/yuklash. Autoload'larga bog'liq emas.

const VERSION := 1

var path: String
const AD_DAILY_LIMIT := 5

var data: Dictionary = {"version": VERSION, "stars": {}, "coins": 0, "gems": 0, "best_wave": 0, "ad_day": "", "ad_count": 0, "upgrades": {}, "heroes": []}


func _init(file_path: String) -> void:
	path = file_path


func load_file() -> void:
	data = {"version": VERSION, "stars": {}, "coins": 0, "gems": 0, "best_wave": 0, "ad_day": "", "ad_count": 0, "upgrades": {}, "heroes": []}
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
	if p.get("upgrades") is Dictionary:
		for k in p.upgrades:
			data.upgrades[str(k)] = maxi(0, int(p.upgrades[k]))
	if p.get("heroes") is Array:
		for h in p.heroes:
			if not (str(h) in data.heroes):
				data.heroes.append(str(h))
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


func spend_coins(amount: int) -> bool:
	if amount < 0 or int(data.coins) < amount:
		return false
	data.coins = int(data.coins) - amount
	save_file()
	return true


func buy_upgrade(upg_data: Dictionary, id: String) -> bool:
	var lvl := int(data.upgrades.get(id, 0))
	var price := Upgrades.cost(upg_data, id, lvl)
	if price < 0 or not spend_coins(price):
		return false
	data.upgrades[id] = lvl + 1
	save_file()
	return true


func buy_hero(upg_data: Dictionary, hero: String) -> bool:
	if hero in data.heroes:
		return false
	var price := int(upg_data.hero_prices.get(hero, 0))
	if not spend_coins(price):
		return false
	data.heroes.append(hero)
	save_file()
	return true
