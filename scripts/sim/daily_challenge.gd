class_name DailyChallenge
extends RefCounted
## Kunlik sinov jangi: har kuni sana bo'yicha bitta o'zgacha qoida (deterministik).
## Mukofot kuniga bir marta, g'alaba qilinganda. Holat: progress.daily_ch = {"day": "YYYY-MM-DD", "won": bool}.

const TERRAINS := ["steppe", "desert", "mountain", "green"]


static func day_index(date: String) -> int:
	return int(Time.get_unix_time_from_datetime_string(date + "T00:00:00") / 86400)


static func rule_id(def: Dictionary, date: String) -> String:
	## Ketma-ket ikki kunda bir xil qoida chiqmaydi (kunlar bo'yicha aralashtirilgan tartib).
	var ids: Array = def.rules.keys()
	ids.sort()
	var d := day_index(date)
	var cycle := d / ids.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4241 + cycle * 977
	var order := ids.duplicate()
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = order[i]
		order[i] = order[j]
		order[j] = t
	return str(order[posmod(d, ids.size())])


static func enemy_hero(hero_defs: Dictionary, player_hero: String, date: String) -> String:
	var others: Array = []
	for h in hero_defs:
		if h != player_hero and bool(hero_defs[h].get("selectable", true)):
			others.append(h)
	others.sort()
	if others.is_empty():
		return ""
	return others[posmod(day_index(date) * 7 + 3, others.size())]


static func terrain(date: String) -> String:
	return TERRAINS[posmod(day_index(date) * 5 + 1, TERRAINS.size())]


static func battle_config(def: Dictionary, date: String, ai_profiles: Dictionary, hero_defs: Dictionary, player_hero: String, seed_value: int) -> Dictionary:
	var rid := rule_id(def, date)
	var rule: Dictionary = def.rules[rid]
	var rc: Dictionary = rule.cfg
	var cfg := {
		"seed": seed_value,
		"start_gold": [400, 400],
		"start_units": [["worker", "worker"], ["worker", "worker"]],
		"heroes": [player_hero, enemy_hero(hero_defs, player_hero, date)],
	}
	for k in rc:
		if k == "no_heroes":
			cfg.heroes = ["", ""]
		else:
			cfg[k] = rc[k]
	var ai_p: Dictionary = ai_profiles.get(str(def.get("ai", "normal")), ai_profiles.normal).duplicate(true)
	if cfg.has("survive_time"):
		ai_p.attack_ratio = 0.9
		ai_p.min_attack_value = 350
	return {"cfg": cfg, "ai": ai_p, "rule": rid, "terrain": terrain(date)}


static func done_today(p: Dictionary, date: String) -> bool:
	var d: Dictionary = p.get("daily_ch", {})
	return str(d.get("day", "")) == date and bool(d.get("won", false))


static func record(def: Dictionary, p: Dictionary, date: String, won: bool) -> Dictionary:
	## Natija: {"reward": bool}. Mukofot faqat kunning birinchi g'alabasida.
	if not won or done_today(p, date):
		return {"reward": false}
	p.daily_ch = {"day": date, "won": true}
	for r in def.reward:
		Rewards.apply(p, r)
	return {"reward": true}
