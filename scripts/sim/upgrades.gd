class_name Upgrades
extends RefCounted
## Ustaxona: tangaga sotib olinadigan doimiy yaxshilanishlar va qahramonlarni ochish.
## Faqat o'yinchi tomoniga (team 0) ta'sir qiladi. Autoload'larga bog'liq emas (test qilish oson).


static func cost(data: Dictionary, id: String, current_level: int) -> int:
	var u: Dictionary = data.upgrades[id]
	if current_level >= int(u.max):
		return -1
	return int(round(float(u.base_cost) * pow(float(u.growth), current_level) / 10.0)) * 10


static func effects(data: Dictionary, levels: Dictionary) -> Dictionary:
	## Daraja lug'atidan BattleSim uchun ko'paytuvchilarni hisoblaydi.
	var lv := func(id: String) -> int: return clampi(int(levels.get(id, 0)), 0, int(data.upgrades[id].max))
	var per := func(id: String) -> float: return float(data.upgrades[id].per_level)
	return {
		"hp_mult": 1.0 + lv.call("army_hp") * per.call("army_hp"),
		"dmg_mult": 1.0 + lv.call("army_dmg") * per.call("army_dmg"),
		"income_mult": 1.0 + lv.call("miners") * per.call("miners"),
		"castle_mult": 1.0 + lv.call("castle") * per.call("castle"),
		"start_gold_add": int(lv.call("start_gold") * per.call("start_gold")),
		"hero_mult": 1.0 + lv.call("hero_power") * per.call("hero_power"),
		"ability_cd_mult": 1.0 - lv.call("hero_power") * 0.03,
	}


static func hero_owned(data: Dictionary, owned: Array, hero: String, campaign_open: bool) -> bool:
	## Qahramon ochiq: bepul (narx 0), sotib olingan yoki uning kampaniyasi ochilgan.
	return int(data.hero_prices.get(hero, 0)) == 0 or hero in owned or campaign_open
