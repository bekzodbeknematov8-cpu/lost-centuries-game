class_name Achievements
extends RefCounted
## Yutuqlar: progress lug'atidan ko'rsatkichlarni hisoblaydi (autoload'larga bog'liq emas).


static func metric(p: Dictionary, name: String, heroes_owned := 1) -> int:
	var stats: Dictionary = p.get("stats", {})
	match name:
		"wins", "kills", "chests", "tactics", "daily":
			return int(stats.get(name, 0))
		"stars":
			var best := 0
			for sl in p.get("slots", []):
				best = maxi(best, Campaign.total_stars(sl.get("stars", {})))
			return maxi(best, Campaign.total_stars(p.get("stars", {})))
		"bosses":
			var seen := {}
			for sl in p.get("slots", []):
				for k in sl.get("stars", {}):
					if Campaign.is_boss(str(k)) and int(sl.stars[k]) > 0:
						seen[k] = true
			return seen.size()
		"best_wave":
			return int(p.get("best_wave", 0))
		"upgrades":
			var n := 0
			var ups: Dictionary = p.get("upgrades", {})
			for k in ups:
				n += int(ups[k])
			return n
		"outfits":
			return p.get("outfits", []).size()
		"heroes":
			return heroes_owned
	return 0


static func claimable(def: Dictionary, p: Dictionary, id: String, heroes_owned := 1) -> bool:
	return not (id in p.get("ach_claimed", [])) and metric(p, str(def.list[id].metric), heroes_owned) >= int(def.list[id].target)
