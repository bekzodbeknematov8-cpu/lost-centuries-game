extends Node
## O'yinchi tanlovlari va sozlamalari (saqlanadi).

const SETTINGS_PATH := "user://settings.json"
const PROGRESS_PATH := "user://progress.json"
const PROGRESS_VERSION := 1

var difficulty: String = "easy"
var hero: String = "temur"
var level_id: String = ""          ## "" = erkin jang, aks holda kampaniya bosqichi
var mode: String = "skirmish"      ## "skirmish" | "campaign" | "endless"
var progress: Dictionary = {"version": PROGRESS_VERSION, "stars": {}, "coins": 0, "gems": 0, "best_wave": 0, "ad_day": "", "ad_count": 0, "upgrades": {}, "heroes": [], "tactics": {}, "starter_given": false, "chests": {}, "daily_last": "", "daily_streak": 0, "star_milestones": 0, "outfit": "classic", "outfits": ["classic"]}
var _store := ProgressStore.new(PROGRESS_PATH)
var settings: Dictionary = {
	"locale": "uz",
	"music_volume": 0.7,
	"sfx_volume": 0.9,
}


const LOCALES := ["uz", "en", "ru", "tr"]


func _ready() -> void:
	_load_translations()
	load_settings()
	load_progress()
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


# --- Kampaniya progressi ------------------------------------------------------

func load_progress() -> void:
	_store.load_file()
	_store.give_starter_tactics(GameData.tactics)
	progress = _store.data
	apply_outfit()


func save_progress() -> void:
	_store.data = progress
	_store.save_file()


func record_result(lid: String, stars: int, coins: int) -> int:
	_store.data = progress
	return _store.record_result(lid, stars, coins)


func record_wave(waves: int, coins: int) -> bool:
	_store.data = progress
	return _store.record_wave(waves, coins)


static func today() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


func ads_left() -> int:
	_store.data = progress
	return _store.ads_left(today())


func reward_ad(bonus_coins: int) -> bool:
	_store.data = progress
	return _store.note_ad_reward(today(), bonus_coins)


# --- Ustaxona ------------------------------------------------------------------

func buy_upgrade(id: String) -> bool:
	_store.data = progress
	return _store.buy_upgrade(GameData.upgrades, id)


func buy_hero(hero: String) -> bool:
	_store.data = progress
	return _store.buy_hero(GameData.upgrades, hero)


func hero_owned(hero: String) -> bool:
	var cid := hero   # kampaniya ID = qahramon ID
	var open: bool = GameData.campaigns.campaigns.has(cid) and Campaign.campaign_unlocked(GameData.campaigns, progress.stars, cid)
	return Upgrades.hero_owned(GameData.upgrades, progress.get("heroes", []), hero, open)


func upgrade_effects() -> Dictionary:
	return Upgrades.effects(GameData.upgrades, progress.get("upgrades", {}))


# --- Hiylalar ------------------------------------------------------------------

func buy_tactic(id: String) -> bool:
	_store.data = progress
	return _store.buy_tactic(GameData.tactics, id)


func consume_tactic(id: String) -> bool:
	_store.data = progress
	return _store.consume_tactic(id)


func tactic_count(id: String) -> int:
	return int(progress.get("tactics", {}).get(id, 0))


# --- Sandiqlar va kunlik mukofot ----------------------------------------------

func open_chest(kind: String) -> Array:
	_store.data = progress
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return _store.open_chest(GameData.chests, kind, GameData.tactics.order, rng)


func buy_chest(kind: String) -> bool:
	_store.data = progress
	return _store.buy_chest(GameData.chests, kind)


func daily_status() -> Dictionary:
	return Rewards.daily_status(str(progress.daily_last), int(progress.daily_streak), today(), GameData.chests.daily.size())


func claim_daily() -> Dictionary:
	_store.data = progress
	return _store.claim_daily(GameData.chests, today())


func grant_star_milestones() -> int:
	_store.data = progress
	return _store.grant_star_milestones(GameData.chests, Campaign.total_stars(progress.stars))


func give_boss_chest() -> void:
	_store.data = progress
	Rewards.apply(progress, {"type": "chest", "id": str(GameData.chests.boss_chest), "count": 1})
	_store.save_file()


# --- Libos ---------------------------------------------------------------------

func apply_outfit() -> void:
	var id := str(progress.get("outfit", "classic"))
	if GameData.outfits.outfits.has(id) and id != "classic":
		Painter.player_outfit = Painter.outfit_colors(GameData.outfits.outfits[id])
	else:
		Painter.player_outfit = []


func buy_outfit(id: String) -> bool:
	_store.data = progress
	return _store.buy_outfit(GameData.outfits, id)


func equip_outfit(id: String) -> bool:
	_store.data = progress
	var ok := _store.equip_outfit(id)
	apply_outfit()
	return ok
