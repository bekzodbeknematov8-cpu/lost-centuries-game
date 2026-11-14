class_name Rewards
extends RefCounted
## Sandiqlar, kunlik mukofot va yulduz sovg'alari mantig'i (autoload'larga bog'liq emas).


static func odds(chest: Dictionary) -> Array:
	## Har bir tushish turi ehtimoli (%), Google Play talabiga ko'ra ochiq ko'rsatiladi.
	var total := 0.0
	for d in chest.drops:
		total += float(d.weight)
	var out := []
	for d in chest.drops:
		out.append({"type": d.type, "percent": 100.0 * float(d.weight) / total, "drop": d})
	return out


static func roll_chest(chest: Dictionary, tactic_ids: Array, rng: RandomNumberGenerator) -> Array:
	var out := []
	var total := 0.0
	for d in chest.drops:
		total += float(d.weight)
	for i in int(chest.rolls):
		var r := rng.randf() * total
		var pick: Dictionary = chest.drops[0]
		for d in chest.drops:
			r -= float(d.weight)
			if r <= 0.0:
				pick = d
				break
		match str(pick.type):
			"coins", "gems":
				out.append({"type": pick.type, "amount": rng.randi_range(int(pick.min), int(pick.max))})
			"tactic":
				out.append({"type": "tactic", "id": tactic_ids[rng.randi() % tactic_ids.size()], "count": int(pick.count)})
	return out


static func apply(data: Dictionary, reward: Dictionary) -> void:
	## Mukofotni progress lug'atiga qo'shadi.
	match str(reward.type):
		"coins":
			data.coins = int(data.get("coins", 0)) + int(reward.amount)
		"gems":
			data.gems = int(data.get("gems", 0)) + int(reward.amount)
		"tactic":
			if not data.has("tactics"):
				data.tactics = {}
			data.tactics[reward.id] = int(data.tactics.get(reward.id, 0)) + int(reward.count)
		"reserve":
			if not data.has("reserves"):
				data.reserves = {}
			data.reserves[reward.id] = int(data.reserves.get(reward.id, 0)) + int(reward.count)
		"outfit":
			if not data.has("outfits"):
				data.outfits = ["classic"]
			if not (str(reward.id) in data.outfits):
				data.outfits.append(str(reward.id))
		"no_ads":
			data.no_ads = true
		"chest":
			if not data.has("chests"):
				data.chests = {}
			data.chests[reward.id] = int(data.chests.get(reward.id, 0)) + int(reward.count)


static func day_number(date: String) -> int:
	return int(Time.get_unix_time_from_datetime_string(date + "T12:00:00") / 86400)


static func daily_status(last: String, streak: int, today: String, cycle: int) -> Dictionary:
	## can_claim: bugun olish mumkinmi; day: tsikldagi kun (0..cycle-1); streak: olingandan keyingi seriya.
	if last == today:
		return {"can_claim": false, "day": (maxi(streak, 1) - 1) % cycle, "streak": streak}
	var consecutive := last != "" and day_number(today) - day_number(last) == 1
	var new_streak := streak + 1 if consecutive else 1
	return {"can_claim": true, "day": (new_streak - 1) % cycle, "streak": new_streak}
