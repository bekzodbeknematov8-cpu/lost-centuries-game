class_name Tournament
extends RefCounted
## Turnir: ketma-ket 8 jang, qiyinlik oshib boradi; bitta mag'lubiyat turnirni tugatadi.
## Holat progress.tournament da: {active, hero, round (0..), best, champion}.


static func rounds(def: Dictionary) -> int:
	return def.rounds.size()


static func enemy_hero(hero_defs: Dictionary, player_hero: String, round: int) -> String:
	## Raqib sarkarda: o'yinchidan boshqa tanlanadigan sarkardalar navbat bilan.
	var others: Array = []
	for h in hero_defs:
		if h != player_hero and bool(hero_defs[h].get("selectable", true)):
			others.append(h)
	others.sort()
	if others.is_empty():
		return ""
	return others[round % others.size()]


static func battle_config(def: Dictionary, round: int, ai_profiles: Dictionary, hero_defs: Dictionary, player_hero: String, seed_value: int) -> Dictionary:
	var r: Dictionary = def.rounds[clampi(round, 0, def.rounds.size() - 1)]
	var ai_p: Dictionary = ai_profiles.get(str(r.ai), ai_profiles.normal).duplicate(true)
	var cfg := {
		"seed": seed_value,
		"start_gold": [350, int(r.get("enemy_gold", 300))],
		"castle_hp": [2000, int(r.castle)],
		"income_mult": [1.0, float(r.income)],
		"start_units": [["worker", "worker"], ["worker", "worker"]],
		"heroes": [player_hero, enemy_hero(hero_defs, player_hero, round)],
	}
	return {"cfg": cfg, "ai": ai_p, "round": r}


static func default_state() -> Dictionary:
	return {"active": false, "hero": "", "round": 0, "best": 0, "champion": 0}


static func start(p: Dictionary, hero: String) -> void:
	var t: Dictionary = p.get("tournament", default_state())
	t.active = true
	t.hero = hero
	t.round = 0
	p.tournament = t


static func give_up(p: Dictionary) -> void:
	if p.has("tournament"):
		p.tournament.active = false


static func result(def: Dictionary, p: Dictionary, won: bool) -> Dictionary:
	## Jang natijasini qayd etadi va mukofot beradi. Qaytaradi: {round, coins, finished, champion}.
	var t: Dictionary = p.get("tournament", default_state())
	var out := {"round": int(t.round) + 1, "coins": 0, "finished": true, "champion": false}
	if not bool(t.active):
		return out
	if won:
		out.coins = int(def.rounds[int(t.round)].coins)
		p.coins = int(p.get("coins", 0)) + int(out.coins)
		t.round = int(t.round) + 1
		t.best = maxi(int(t.best), int(t.round))
		if int(t.round) >= def.rounds.size():
			t.active = false
			t.champion = int(t.champion) + 1
			for rw in def.champion:
				Rewards.apply(p, rw)
			out.champion = true
		else:
			out.finished = false
	else:
		t.active = false
	p.tournament = t
	return out
