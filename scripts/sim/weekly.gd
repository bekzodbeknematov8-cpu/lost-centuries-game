class_name Weekly
extends RefCounted
## Haftalik vazifalar: har hafta (dushanbadan) sana bo'yicha deterministik tanlanadi.
## Progress = stats[metric] ning hafta boshidagi qiymatdan farqi (progress.weekly.base).


static func week_index(date: String) -> int:
	## "YYYY-MM-DD" -> hafta raqami (dushanbadan boshlanadi; 1970-01-01 payshanba edi).
	var days := int(Time.get_unix_time_from_datetime_string(date + "T00:00:00") / 86400)
	return int(floor((days + 3) / 7.0))


static func days_left(date: String) -> int:
	var days := int(Time.get_unix_time_from_datetime_string(date + "T00:00:00") / 86400)
	return 7 - posmod(days + 3, 7)


static func tasks_for_week(def: Dictionary, week: int) -> Array:
	## Hovuzdan tasks_per_week ta vazifa; bir xil ko'rsatkich takrorlanmaydi.
	var ids: Array = def.pool.keys()
	ids.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * week + 17
	for i in range(ids.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = ids[i]
		ids[i] = ids[j]
		ids[j] = t
	var out: Array = []
	var used := {}
	for id in ids:
		var m := str(def.pool[id].metric)
		if used.has(m):
			continue
		used[m] = true
		out.append(id)
		if out.size() >= int(def.get("tasks_per_week", 5)):
			break
	return out


static func ensure_week(p: Dictionary, date: String) -> void:
	## Yangi hafta boshlangan bo'lsa, bazani yangilaydi.
	var w := week_index(date)
	var cur: Dictionary = p.get("weekly", {})
	if int(cur.get("week", -1)) == w:
		return
	p.weekly = {"week": w, "base": (p.get("stats", {}) as Dictionary).duplicate(), "claimed": [], "bonus": false}


static func progress_of(def: Dictionary, p: Dictionary, id: String) -> int:
	var m := str(def.pool[id].metric)
	var now := int(p.get("stats", {}).get(m, 0))
	var base := int(p.get("weekly", {}).get("base", {}).get(m, 0))
	return mini(maxi(0, now - base), int(def.pool[id].target))


static func is_done(def: Dictionary, p: Dictionary, id: String) -> bool:
	return progress_of(def, p, id) >= int(def.pool[id].target)


static func claimable(def: Dictionary, p: Dictionary, id: String, date: String) -> bool:
	return id in tasks_for_week(def, week_index(date)) and is_done(def, p, id) and not (id in p.get("weekly", {}).get("claimed", []))


static func bonus_ready(def: Dictionary, p: Dictionary, date: String) -> bool:
	var w: Dictionary = p.get("weekly", {})
	if bool(w.get("bonus", false)):
		return false
	for id in tasks_for_week(def, week_index(date)):
		if not (id in w.get("claimed", [])):
			return false
	return true


static func claimable_count(def: Dictionary, p: Dictionary, date: String) -> int:
	var n := 0
	for id in tasks_for_week(def, week_index(date)):
		if claimable(def, p, id, date):
			n += 1
	return n + (1 if bonus_ready(def, p, date) else 0)
