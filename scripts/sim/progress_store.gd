class_name ProgressStore
extends RefCounted
## Kampaniya progressini (yulduzlar, tangalar) saqlash/yuklash. Autoload'larga bog'liq emas.

const VERSION := 1

var path: String
const AD_DAILY_LIMIT := 5

var data: Dictionary = {"version": VERSION, "stars": {}, "coins": 0, "gems": 0, "best_wave": 0, "ad_day": "", "ad_count": 0, "upgrades": {}, "heroes": [], "tactics": {}, "starter_given": false, "chests": {}, "daily_last": "", "daily_streak": 0, "star_milestones": 0, "outfit": "classic", "outfits": ["classic"], "reserves": {}, "no_ads": false, "bought_once": [], "adgem_day": "", "adgem_count": 0}


func _init(file_path: String) -> void:
	path = file_path


func load_file() -> void:
	data = {"version": VERSION, "stars": {}, "coins": 0, "gems": 0, "best_wave": 0, "ad_day": "", "ad_count": 0, "upgrades": {}, "heroes": [], "tactics": {}, "starter_given": false, "chests": {}, "daily_last": "", "daily_streak": 0, "star_milestones": 0, "outfit": "classic", "outfits": ["classic"], "reserves": {}, "no_ads": false, "bought_once": [], "adgem_day": "", "adgem_count": 0}
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
	if p.get("tactics") is Dictionary:
		for k in p.tactics:
			data.tactics[str(k)] = maxi(0, int(p.tactics[k]))
	data.starter_given = bool(p.get("starter_given", false))
	if p.get("chests") is Dictionary:
		for k in p.chests:
			data.chests[str(k)] = maxi(0, int(p.chests[k]))
	data.daily_last = str(p.get("daily_last", ""))
	data.daily_streak = maxi(0, int(p.get("daily_streak", 0)))
	data.star_milestones = maxi(0, int(p.get("star_milestones", 0)))
	data.outfit = str(p.get("outfit", "classic"))
	if p.get("reserves") is Dictionary:
		for k in p.reserves:
			data.reserves[str(k)] = maxi(0, int(p.reserves[k]))
	data.no_ads = bool(p.get("no_ads", false))
	if p.get("bought_once") is Array:
		for x in p.bought_once:
			data.bought_once.append(str(x))
	data.adgem_day = str(p.get("adgem_day", ""))
	data.adgem_count = maxi(0, int(p.get("adgem_count", 0)))
	if p.get("outfits") is Array:
		for o in p.outfits:
			if not (str(o) in data.outfits):
				data.outfits.append(str(o))
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


func give_starter_tactics(tac_data: Dictionary) -> void:
	## Yangi o'yinchiga bir martalik boshlang'ich hiylalar.
	if bool(data.get("starter_given", false)):
		return
	for k in tac_data.get("starter", {}):
		data.tactics[k] = int(data.tactics.get(k, 0)) + int(tac_data.starter[k])
	data.starter_given = true
	save_file()


func buy_tactic(tac_data: Dictionary, id: String) -> bool:
	if not tac_data.tactics.has(id):
		return false
	if not spend_coins(int(tac_data.tactics[id].price)):
		return false
	data.tactics[id] = int(data.tactics.get(id, 0)) + 1
	save_file()
	return true


func consume_tactic(id: String) -> bool:
	if int(data.tactics.get(id, 0)) <= 0:
		return false
	data.tactics[id] = int(data.tactics[id]) - 1
	save_file()
	return true


# --- Sandiqlar va mukofotlar ------------------------------------------------

func open_chest(chest_data: Dictionary, kind: String, tactic_ids: Array, rng: RandomNumberGenerator) -> Array:
	if int(data.chests.get(kind, 0)) <= 0:
		return []
	data.chests[kind] = int(data.chests[kind]) - 1
	var rewards := Rewards.roll_chest(chest_data.chests[kind], tactic_ids, rng)
	for r in rewards:
		Rewards.apply(data, r)
	save_file()
	return rewards


func buy_chest(chest_data: Dictionary, kind: String) -> bool:
	var c: Dictionary = chest_data.chests[kind]
	if int(c.price_coins) > 0:
		if not spend_coins(int(c.price_coins)):
			return false
	elif int(c.price_gems) > 0:
		if int(data.gems) < int(c.price_gems):
			return false
		data.gems = int(data.gems) - int(c.price_gems)
	Rewards.apply(data, {"type": "chest", "id": kind, "count": 1})
	save_file()
	return true


func claim_daily(chest_data: Dictionary, today: String) -> Dictionary:
	var st := Rewards.daily_status(str(data.daily_last), int(data.daily_streak), today, chest_data.daily.size())
	if not st.can_claim:
		return {}
	var reward: Dictionary = chest_data.daily[st.day]
	Rewards.apply(data, reward)
	data.daily_last = today
	data.daily_streak = st.streak
	save_file()
	return reward


func grant_star_milestones(chest_data: Dictionary, total_stars: int) -> int:
	## Har star_milestone yulduzda bitta oltin sandiq. Yangi berilganlar sonini qaytaradi.
	var reached := total_stars / int(chest_data.star_milestone)
	var new_count := reached - int(data.star_milestones)
	if new_count <= 0:
		return 0
	data.star_milestones = reached
	Rewards.apply(data, {"type": "chest", "id": "gold", "count": new_count})
	save_file()
	return new_count


# --- Libos ---------------------------------------------------------------------

func buy_outfit(out_data: Dictionary, id: String) -> bool:
	if id in data.outfits or not out_data.outfits.has(id):
		return false
	var o: Dictionary = out_data.outfits[id]
	if int(o.price_gems) > 0:
		if int(data.gems) < int(o.price_gems):
			return false
		data.gems = int(data.gems) - int(o.price_gems)
	elif not spend_coins(int(o.price_coins)):
		return false
	data.outfits.append(id)
	save_file()
	return true


func equip_outfit(id: String) -> bool:
	if not (id in data.outfits):
		return false
	data.outfit = id
	save_file()
	return true


# --- Bozor ---------------------------------------------------------------------

func product_available(market: Dictionary, id: String) -> bool:
	var p: Dictionary = market.products[id]
	return not (bool(p.get("once", false)) and id in data.bought_once)


func grant_product(market: Dictionary, id: String) -> bool:
	## To'lov tasdiqlangandan keyin chaqiriladi (IAP yoki reklama).
	if not product_available(market, id):
		return false
	var p: Dictionary = market.products[id]
	for c in p.contents:
		Rewards.apply(data, c)
	if bool(p.get("once", false)):
		data.bought_once.append(id)
	save_file()
	return true


func buy_with_gems(market: Dictionary, id: String) -> bool:
	var p: Dictionary = market.products[id]
	if str(p.kind) != "gems" or int(data.gems) < int(p.gems):
		return false
	data.gems = int(data.gems) - int(p.gems)
	for c in p.contents:
		Rewards.apply(data, c)
	save_file()
	return true


func adgems_left(market: Dictionary, today: String) -> int:
	if str(data.adgem_day) != today:
		return int(market.ad_gems.daily_limit)
	return maxi(0, int(market.ad_gems.daily_limit) - int(data.adgem_count))


func claim_ad_gems(market: Dictionary, today: String) -> bool:
	if adgems_left(market, today) <= 0:
		return false
	if str(data.adgem_day) != today:
		data.adgem_day = today
		data.adgem_count = 0
	data.adgem_count = int(data.adgem_count) + 1
	data.gems = int(data.gems) + int(market.ad_gems.amount)
	save_file()
	return true


func take_reserve(type: String, n: int) -> int:
	var have := int(data.reserves.get(type, 0))
	var k := mini(have, n)
	data.reserves[type] = have - k
	save_file()
	return k
