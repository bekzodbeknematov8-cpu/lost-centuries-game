class_name Campaign
extends RefCounted
## Kampaniya mantig'i: bosqich sozlamalari, yulduzlar va ochilish shartlari.
## Saqlash formatidan mustaqil (stars: {level_id: 0..3}), shuning uchun testlash oson.

const DEFAULT_PLAYER_GOLD := 350
const STAR_CASTLE_2 := 0.5    ## 2-yulduz: qal'a kamida 50% butun
const STAR_CASTLE_3 := 0.8    ## 3-yulduz: qal'a kamida 80% butun YOKI par vaqtdan tez


static func level_by_id(data: Dictionary, level_id: String) -> Dictionary:
	for cid in data.order:
		for lv in data.campaigns[cid].levels:
			if lv.id == level_id:
				return lv
	return {}


static func campaign_of(data: Dictionary, level_id: String) -> String:
	for cid in data.order:
		for lv in data.campaigns[cid].levels:
			if lv.id == level_id:
				return cid
	return ""


static func next_level_id(data: Dictionary, level_id: String) -> String:
	var cid := campaign_of(data, level_id)
	if cid == "":
		return ""
	var levels: Array = data.campaigns[cid].levels
	for i in levels.size():
		if levels[i].id == level_id and i + 1 < levels.size():
			return levels[i + 1].id
	return ""


static func battle_config(data: Dictionary, level_id: String, ai_profiles: Dictionary, seed_value: int) -> Dictionary:
	## Bosqichdan BattleSim.setup() uchun cfg va dushman AI parametrlarini quradi.
	var lv := level_by_id(data, level_id)
	var cid := campaign_of(data, level_id)
	var ai_p: Dictionary = ai_profiles.get(str(lv.get("ai", "normal")), ai_profiles.normal).duplicate(true)
	if lv.get("objective", "destroy") == "survive":
		# Mudofaa bosqichlarida dushman tajovuzkorroq.
		ai_p.attack_ratio = 0.9
		ai_p.min_attack_value = 350
	var all_units := ["worker", "swordsman", "spearman", "archer", "cavalry"]
	var cfg := {
		"seed": seed_value,
		"start_gold": [int(lv.get("player_gold", DEFAULT_PLAYER_GOLD)), int(lv.get("enemy_gold", 300))],
		"castle_hp": [int(lv.get("player_castle", 2000)), int(lv.get("enemy_castle", 2000))],
		"income_mult": [1.0, float(lv.get("enemy_income", 1.0))],
		"start_units": [["worker", "worker"], ["worker", "worker"]],
		"allowed": [lv.get("allowed", all_units), lv.get("enemy_allowed", all_units)],
		"heroes": [str(data.campaigns[cid].hero), str(lv.get("enemy_hero", "sardor")) if str(lv.get("enemy_hero", "")) != "" else "sardor"],
		"survive_time": float(lv.get("survive", 0.0)) if lv.get("objective", "destroy") == "survive" else 0.0,
	}
	return {"cfg": cfg, "ai": ai_p, "level": lv}


static func compute_stars(level: Dictionary, won: bool, castle_frac: float, time_sec: float) -> int:
	if not won:
		return 0
	var stars := 1
	if castle_frac >= STAR_CASTLE_2:
		stars = 2
		if castle_frac >= STAR_CASTLE_3 or time_sec <= float(level.get("par", 300)):
			stars = 3
	return stars


static func total_stars(stars: Dictionary) -> int:
	var s := 0
	for k in stars:
		s += int(stars[k])
	return s


static func campaign_stars(data: Dictionary, stars: Dictionary, cid: String) -> int:
	var s := 0
	for lv in data.campaigns[cid].levels:
		s += int(stars.get(lv.id, 0))
	return s


static func campaign_unlocked(data: Dictionary, stars: Dictionary, cid: String) -> bool:
	## Kampaniya ochilishi uchun: oldingi kampaniya tugatilgan bo'lishi va umumiy yulduz yetarli bo'lishi kerak.
	var idx: int = data.order.find(cid)
	if idx <= 0:
		return idx == 0
	var prev: String = data.order[idx - 1]
	var prev_levels: Array = data.campaigns[prev].levels
	var prev_done := int(stars.get(prev_levels[prev_levels.size() - 1].id, 0)) > 0
	return prev_done and total_stars(stars) >= int(data.campaigns[cid].require_stars)


static func level_unlocked(data: Dictionary, stars: Dictionary, level_id: String) -> bool:
	var cid := campaign_of(data, level_id)
	if cid == "" or not campaign_unlocked(data, stars, cid):
		return false
	var levels: Array = data.campaigns[cid].levels
	for i in levels.size():
		if levels[i].id == level_id:
			return i == 0 or int(stars.get(levels[i - 1].id, 0)) > 0
	return false


static func coins_for(level: Dictionary, stars: int) -> int:
	## Jang mukofoti (4-bosqichda tanga tizimi uchun): yulduz va bosqich og'irligiga qarab.
	if stars <= 0:
		return 10
	var base := 40 + int(float(level.get("par", 300)) / 10.0)
	return base + stars * 20
