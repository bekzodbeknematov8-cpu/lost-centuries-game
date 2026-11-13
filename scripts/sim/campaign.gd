class_name Campaign
extends RefCounted
## Kampaniya mantig'i: viloyatlar, levellar, yulduzlar va ochilish shartlari.
##
## Tuzilma: kampaniya (qahramon) -> viloyatlar (campaigns.json dagi har bir tarixiy bosqich = viloyat bossi)
##          -> har viloyatda REGION_LEVELS ta level: (REGION_LEVELS-1) ta avtomatik yaratilgan + oxirida boss.
## Level ID: boss = "temur_03", oddiy level = "temur_03#4" (1..REGION_LEVELS-1).
## Saqlash formatidan mustaqil (stars: {level_id: 0..3}), shuning uchun testlash oson.

const DEFAULT_PLAYER_GOLD := 350
const STAR_CASTLE_2 := 0.5    ## 2-yulduz: qal'a kamida 50% butun
const STAR_CASTLE_3 := 0.8    ## 3-yulduz: qal'a kamida 80% butun YOKI par vaqtdan tez
const REGION_LEVELS := 10     ## 1.0 da har viloyatda 10 level (keyin 25 gacha)
const UNLOCK_AFTER_REGION := 4  ## Keyingi kampaniya: oldingisining shuncha viloyati zabt etilgach

static var _cache: Dictionary = {}


# --- Tuzilma -----------------------------------------------------------------

static func regions(data: Dictionary, cid: String) -> Array:
	return data.campaigns[cid].levels


static func region_levels(data: Dictionary, cid: String, ri: int) -> Array:
	var key := "%s/%d" % [cid, ri]
	if _cache.has(key):
		return _cache[key]
	var regs: Array = regions(data, cid)
	var boss: Dictionary = regs[ri]
	var prev_income := float(regs[ri - 1].get("enemy_income", 1.0)) if ri > 0 else float(boss.get("enemy_income", 1.0)) * 0.85
	var out: Array = []
	for n in range(1, REGION_LEVELS):
		out.append(_generate(boss, ri, n, prev_income))
	out.append(boss)
	_cache[key] = out
	return out


static func _generate(boss: Dictionary, ri: int, n: int, prev_income: float) -> Dictionary:
	## Viloyat shablonidan oddiy level: qiyinlik oldingi bossdan shu bossgacha silliq oshadi.
	var k := float(n) / REGION_LEVELS
	var boss_income := float(boss.get("enemy_income", 1.0))
	var ai := str(boss.get("ai", "normal"))
	if n < 6 and ai == "hard":
		ai = "normal"
	if n < 3 and ai == "normal" and ri == 0:
		ai = "easy"
	var lv := {
		"id": "%s#%d" % [boss.id, n],
		"region": boss.id,
		"index": n,
		"name": boss.name,
		"ai": ai,
		"enemy_income": snappedf(lerpf(prev_income * 0.95, boss_income, k), 0.001),
		"par": int(boss.get("par", 300)) - 40 + n * 4,
		"enemy_castle": int(float(boss.get("enemy_castle", 2000)) * (0.8 + 0.015 * n)),
	}
	if boss.has("allowed"):
		lv.allowed = boss.allowed
	if boss.has("enemy_allowed"):
		lv.enemy_allowed = boss.enemy_allowed
	# Xilma-xillik: ba'zi levellar mudofaa, ba'zilarida dushman oldinroq boshlaydi yoki sizga qo'shimcha oltin
	match n % 5:
		4:
			lv.objective = "survive"
			lv.survive = 120 + 6 * n + 6 * ri
			lv.par = lv.survive
		2:
			lv.enemy_gold = 480
		3:
			lv.player_gold = 480
	return lv


static func all_levels(data: Dictionary, cid: String) -> Array:
	var out: Array = []
	for ri in regions(data, cid).size():
		out.append_array(region_levels(data, cid, ri))
	return out


static func campaign_of(data: Dictionary, level_id: String) -> String:
	var base := level_id.get_slice("#", 0)
	for cid in data.order:
		for b in data.campaigns[cid].levels:
			if b.id == base:
				return cid
	return ""


static func region_index(data: Dictionary, level_id: String) -> int:
	var cid := campaign_of(data, level_id)
	if cid == "":
		return -1
	var base := level_id.get_slice("#", 0)
	var regs: Array = regions(data, cid)
	for i in regs.size():
		if regs[i].id == base:
			return i
	return -1


static func level_by_id(data: Dictionary, level_id: String) -> Dictionary:
	var cid := campaign_of(data, level_id)
	if cid == "":
		return {}
	for lv in region_levels(data, cid, region_index(data, level_id)):
		if lv.id == level_id:
			return lv
	return {}


static func is_boss(level_id: String) -> bool:
	return not level_id.contains("#")


static func next_level_id(data: Dictionary, level_id: String) -> String:
	var cid := campaign_of(data, level_id)
	if cid == "":
		return ""
	var flat := all_levels(data, cid)
	for i in flat.size():
		if flat[i].id == level_id and i + 1 < flat.size():
			return flat[i + 1].id
	return ""


# --- Jang sozlamasi ------------------------------------------------------------

static func battle_config(data: Dictionary, level_id: String, ai_profiles: Dictionary, seed_value: int) -> Dictionary:
	## Leveldan BattleSim.setup() uchun cfg va dushman AI parametrlarini quradi.
	var lv := level_by_id(data, level_id)
	var cid := campaign_of(data, level_id)
	var ai_p: Dictionary = ai_profiles.get(str(lv.get("ai", "normal")), ai_profiles.normal).duplicate(true)
	if lv.get("objective", "destroy") == "survive":
		# Mudofaa levellarida dushman tajovuzkorroq.
		ai_p.attack_ratio = 0.9
		ai_p.min_attack_value = 350
	var all_units := ["worker", "swordsman", "spearman", "archer", "cavalry"]
	var eh := str(lv.get("enemy_hero", ""))
	var cfg := {
		"seed": seed_value,
		"start_gold": [int(lv.get("player_gold", DEFAULT_PLAYER_GOLD)), int(lv.get("enemy_gold", 300))],
		"castle_hp": [int(lv.get("player_castle", 2000)), int(lv.get("enemy_castle", 2000))],
		"income_mult": [1.0, float(lv.get("enemy_income", 1.0))],
		"start_units": [["worker", "worker"], ["worker", "worker"]],
		"allowed": [lv.get("allowed", all_units), lv.get("enemy_allowed", all_units)],
		"heroes": [str(data.campaigns[cid].hero), eh if eh != "" else "sardor"],
		"survive_time": float(lv.get("survive", 0.0)) if lv.get("objective", "destroy") == "survive" else 0.0,
	}
	return {"cfg": cfg, "ai": ai_p, "level": lv}


# --- Yulduzlar va ochilish -----------------------------------------------------

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
	for lv in all_levels(data, cid):
		s += int(stars.get(lv.id, 0))
	return s


static func region_conquered(data: Dictionary, stars: Dictionary, cid: String, ri: int) -> bool:
	return int(stars.get(regions(data, cid)[ri].id, 0)) > 0


static func campaign_unlocked(data: Dictionary, stars: Dictionary, cid: String) -> bool:
	## Ochilish: oldingi kampaniyaning UNLOCK_AFTER_REGION ta viloyati zabt etilgan va jami yulduz yetarli.
	var idx: int = data.order.find(cid)
	if idx <= 0:
		return idx == 0
	var prev: String = data.order[idx - 1]
	var need_region := mini(UNLOCK_AFTER_REGION, regions(data, prev).size()) - 1
	return region_conquered(data, stars, prev, need_region) and total_stars(stars) >= int(data.campaigns[cid].require_stars)


static func region_unlocked(data: Dictionary, stars: Dictionary, cid: String, ri: int) -> bool:
	if not campaign_unlocked(data, stars, cid):
		return false
	return ri == 0 or region_conquered(data, stars, cid, ri - 1)


static func level_unlocked(data: Dictionary, stars: Dictionary, level_id: String) -> bool:
	var cid := campaign_of(data, level_id)
	if cid == "":
		return false
	var ri := region_index(data, level_id)
	if not region_unlocked(data, stars, cid, ri):
		return false
	var lvls: Array = region_levels(data, cid, ri)
	for i in lvls.size():
		if lvls[i].id == level_id:
			return i == 0 or int(stars.get(lvls[i - 1].id, 0)) > 0
	return false


static func coins_for(level: Dictionary, stars: int) -> int:
	## Jang mukofoti: yulduz va level og'irligiga qarab; boss levellari ko'proq beradi.
	if stars <= 0:
		return 10
	var base := 30 + int(float(level.get("par", 300)) / 12.0)
	if is_boss(str(level.get("id", ""))):
		base *= 2
	return base + stars * 15
