class_name BattleSim
extends RefCounted
## Jang mantig'i. Chizishdan to'liq ajratilgan, shuning uchun headless
## rejimda minglab "bot vs bot" o'yinlarini tez simulyatsiya qilish mumkin.
## step() har doim bir xil dt bilan chaqiriladi (deterministik).

const WORLD_LEN := 3200.0
const MAX_QUEUE := 5
const STEP := 1.0 / 30.0
const CASTLE_HALF_W := 70.0
const CASTLE_ARROW_RANGE := 380.0
const CASTLE_ARROW_CD := 1.8
const CASTLE_ARROW_DMG := 11.0
const DEFEND_ZONE := 430.0
const ATTACK_AGGRO := 650.0
const CORPSE_TIME := 3.0
const CONTROL_BONUS := 1.25

var defs: Dictionary = {}
var teams: Array[TeamState] = []
var units: Array[UnitState] = []
var projectiles: Array[Dictionary] = []
var events: Array[Dictionary] = []
var time: float = 0.0
var winner: int = -1
var rng := RandomNumberGenerator.new()
var control_dir: int = 0
var control_attack: bool = false

var _next_id: int = 1
var _by_id: Dictionary = {}
var _pending_hits: Array = []   ## Jang zarbalari qadam oxirida bir vaqtda qo'llanadi (adolat uchun)


func setup(unit_defs: Dictionary, cfg: Dictionary = {}) -> void:
	defs = unit_defs
	rng.seed = int(cfg.get("seed", 12345))
	teams.clear()
	units.clear()
	projectiles.clear()
	events.clear()
	_by_id.clear()
	time = 0.0
	winner = -1
	for i in 2:
		var t := TeamState.new()
		t.index = i
		t.dir = 1 if i == 0 else -1
		t.castle_x = 160.0 if i == 0 else WORLD_LEN - 160.0
		t.mine_x = t.castle_x + t.dir * 300.0
		t.gold = float(_pick(cfg, "start_gold", i, 300))
		t.castle_max_hp = float(_pick(cfg, "castle_hp", i, 2000))
		t.castle_hp = t.castle_max_hp
		t.income_mult = float(_pick(cfg, "income_mult", i, 1.0))
		t.damage_mult = float(_pick(cfg, "damage_mult", i, 1.0))
		t.pop_cap = int(_pick(cfg, "pop_cap", i, 30))
		t.allowed = _pick(cfg, "allowed", i, defs.keys())
		teams.append(t)
		var start_units: Array = _pick(cfg, "start_units", i, ["worker", "worker"])
		for k in start_units.size():
			var u := spawn_unit(i, start_units[k])
			u.x += t.dir * (20.0 + k * 25.0)


static func _pick(cfg: Dictionary, key: String, i: int, default: Variant) -> Variant:
	## cfg qiymati yoki [chap, o'ng] juftligi bo'lishi mumkin.
	if not cfg.has(key):
		return default
	var v: Variant = cfg[key]
	if v is Array and v.size() == 2 and (v[0] is Array or not (v[0] is String)):
		return v[i]
	return v


# --- Ommaviy API -----------------------------------------------------------

func get_unit(id: int) -> UnitState:
	return _by_id.get(id, null)


func can_train(team_idx: int, type: String) -> bool:
	var t := teams[team_idx]
	if not defs.has(type) or not (type in t.allowed):
		return false
	var d: Dictionary = defs[type]
	if t.gold < float(d.cost) or t.queue.size() >= MAX_QUEUE:
		return false
	return t.pop + queued_pop(team_idx) + int(d.pop) <= t.pop_cap


func queued_pop(team_idx: int) -> int:
	var s := 0
	for q in teams[team_idx].queue:
		s += int(defs[q].pop)
	return s


func train(team_idx: int, type: String) -> bool:
	if not can_train(team_idx, type):
		return false
	var t := teams[team_idx]
	t.gold -= float(defs[type].cost)
	t.queue.append(type)
	return true


func set_stance(team_idx: int, stance: int) -> void:
	if teams[team_idx].stance != stance:
		teams[team_idx].stance = stance
		events.append({"type": "stance", "team": team_idx, "stance": stance})


func spawn_unit(team_idx: int, type: String) -> UnitState:
	var t := teams[team_idx]
	var u := UnitState.new()
	u.id = _next_id
	_next_id += 1
	u.type = type
	u.def = defs[type]
	u.team = team_idx
	u.x = t.castle_x + t.dir * 40.0
	u.lane = rng.randf()
	u.slot = rng.randf_range(-40.0, 40.0)
	u.hp = float(u.def.hp)
	u.max_hp = u.hp
	u.facing = t.dir
	u.state = UnitState.State.MINE_GO if u.is_worker() else UnitState.State.IDLE
	units.append(u)
	_by_id[u.id] = u
	t.pop += int(u.def.pop)
	t.stats.trained += 1
	return u


func alive_units(team_idx: int, include_workers := true) -> Array[UnitState]:
	var out: Array[UnitState] = []
	for u in units:
		if u.team == team_idx and u.is_alive() and (include_workers or not u.is_worker()):
			out.append(u)
	return out


func army_value(team_idx: int) -> float:
	var v := 0.0
	for u in units:
		if u.team == team_idx and u.is_alive() and not u.is_worker():
			v += u.value()
	return v


func pressure_on(team_idx: int, radius := 900.0) -> float:
	## team_idx qal'asi yaqinidagi dushman qo'shini kuchi.
	var t := teams[team_idx]
	var v := 0.0
	for u in units:
		if u.team != team_idx and u.is_alive() and not u.is_worker() and absf(u.x - t.castle_x) < radius:
			v += u.value()
	return v


func count_types(team_idx: int) -> Dictionary:
	var c := {}
	for u in units:
		if u.team == team_idx and u.is_alive():
			c[u.type] = int(c.get(u.type, 0)) + 1
	return c


func controlled_unit() -> UnitState:
	for u in units:
		if u.controlled and u.is_alive():
			return u
	return null


func take_control(team_idx: int, unit_id: int = -1) -> UnitState:
	## unit_id berilmasa, eng oldingi jangchini tanlaydi.
	release_control()
	var best: UnitState = null
	if unit_id >= 0:
		best = get_unit(unit_id)
		if best and (best.team != team_idx or not best.is_alive()):
			best = null
	else:
		var t := teams[team_idx]
		for u in alive_units(team_idx, false):
			if best == null or u.x * t.dir > best.x * t.dir:
				best = u
	if best:
		best.controlled = true
	return best


func release_control() -> void:
	for u in units:
		u.controlled = false
	control_dir = 0
	control_attack = false


# --- Asosiy sikl -------------------------------------------------------------

func step(dt: float = STEP) -> void:
	if winner >= 0:
		return
	time += dt
	for t in teams:
		_update_team(t, dt)
	# Har qadamda tartib aralashtiriladi: hech bir askar ro'yxatdagi o'rni tufayli
	# doimiy "birinchi zarba" ustunligiga ega bo'lmaydi (seed bilan deterministik).
	var order := units.duplicate()
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: UnitState = order[i]
		order[i] = order[j]
		order[j] = tmp
	for u in order:
		if u.is_alive():
			_update_unit(u, dt)
		else:
			u.dead_time += dt
	_resolve_pending_hits()
	_update_projectiles(dt)
	for t in teams:
		_update_castle(t, dt)
	_cleanup()
	for t in teams:
		if t.castle_hp <= 0.0 and winner < 0:
			t.castle_hp = 0.0
			winner = 1 - t.index
			events.append({"type": "castle_destroyed", "team": t.index, "x": t.castle_x})


func pop_events() -> Array[Dictionary]:
	var e := events
	events = []
	return e


func _update_team(t: TeamState, dt: float) -> void:
	t.gold += t.passive_income * t.income_mult * dt
	if t.queue.is_empty():
		t.train_progress = 0.0
		return
	var type: String = t.queue[0]
	if t.pop + int(defs[type].pop) > t.pop_cap:
		return
	t.train_progress += dt
	if t.train_progress >= float(defs[type].train_time):
		t.queue.pop_front()
		t.train_progress = 0.0
		var u := spawn_unit(t.index, type)
		events.append({"type": "trained", "team": t.index, "unit": type, "x": u.x})


func _update_unit(u: UnitState, dt: float) -> void:
	u.cooldown -= dt
	u.attack_anim = maxf(0.0, u.attack_anim - dt)
	u.hurt_flash = maxf(0.0, u.hurt_flash - dt)
	u.moving = false
	if u.controlled:
		_update_controlled(u, dt)
	elif u.is_worker():
		_update_worker(u, dt)
	else:
		_update_fighter(u, dt)
	if u.moving:
		u.walk_phase += dt * float(u.def.speed) * 0.09
	u.x = clampf(u.x, 20.0, WORLD_LEN - 20.0)


func _move_towards(u: UnitState, dest: float, dt: float, speed_mult := 1.0) -> bool:
	## true qaytaradi, agar manzilga yetgan bo'lsa.
	var dx := dest - u.x
	if absf(dx) < 4.0:
		return true
	u.facing = 1 if dx > 0 else -1
	var stepv := float(u.def.speed) * speed_mult * dt
	u.x += clampf(dx, -stepv, stepv)
	u.moving = true
	return absf(dest - u.x) < 4.0


func _update_worker(u: UnitState, dt: float) -> void:
	var t := teams[u.team]
	if t.stance == TeamState.Stance.RETREAT:
		if _move_towards(u, t.retreat_x() + u.slot * 0.3, dt):
			u.facing = t.dir
		return
	match u.state:
		UnitState.State.MINE_GO, UnitState.State.IDLE, UnitState.State.MOVE, UnitState.State.ATTACK:
			u.state = UnitState.State.MINE_GO
			if _move_towards(u, t.mine_x + u.slot * 0.6, dt):
				u.state = UnitState.State.MINING
				u.mine_timer = float(u.def.mine_time)
				u.facing = t.dir
		UnitState.State.MINING:
			var before := u.mine_timer
			u.mine_timer -= dt
			if floorf(before / 0.8) != floorf(u.mine_timer / 0.8) and u.mine_timer > 0.0:
				u.attack_anim = 0.35
				events.append({"type": "pick", "team": u.team, "x": u.x})
			if u.mine_timer <= 0.0:
				u.carrying = int(u.def.carry)
				u.state = UnitState.State.RETURN
				events.append({"type": "mined", "team": u.team, "x": u.x, "lane": u.lane})
		UnitState.State.RETURN:
			if _move_towards(u, t.castle_x + t.dir * 50.0, dt):
				var g := float(u.carrying) * t.income_mult
				t.gold += g
				t.stats.gold_mined += g
				u.carrying = 0
				u.state = UnitState.State.MINE_GO
				events.append({"type": "gold", "team": u.team, "x": u.x, "amount": int(g)})


func _update_fighter(u: UnitState, dt: float) -> void:
	var t := teams[u.team]
	var back := 70.0 if u.is_ranged() else 0.0
	match t.stance:
		TeamState.Stance.RETREAT:
			if _move_towards(u, t.retreat_x() - t.dir * back * 0.5 + u.slot * 0.4, dt, 1.1):
				u.facing = t.dir
		TeamState.Stance.DEFEND:
			var rally := t.defend_x() - t.dir * back
			var target := _nearest_enemy(u, rally, DEFEND_ZONE + float(u.def.range))
			if target:
				target = _spread_target(u, target)
			if target:
				_engage(u, target, dt)
			elif _move_towards(u, rally + u.slot, dt):
				u.facing = t.dir
		TeamState.Stance.ATTACK:
			var target := _nearest_enemy(u, u.x, ATTACK_AGGRO + float(u.def.range))
			if target:
				target = _spread_target(u, target)
			if target:
				_engage(u, target, dt)
			else:
				_engage_castle(u, teams[1 - u.team], dt)


func _nearest_enemy(u: UnitState, around: float, radius: float) -> UnitState:
	var best: UnitState = null
	var best_d := INF
	for e in units:
		if e.team == u.team or not e.is_alive():
			continue
		var d := absf(e.x - around)
		if d > radius:
			continue
		var du := absf(e.x - u.x)
		if du < best_d:
			best_d = du
			best = e
	return best


func _spread_target(u: UnitState, nearest: UnitState) -> UnitState:
	## Hamma bitta nishonga hujum qilmasligi uchun: yetib boradigan va eng yaqin nishonga
	## yaqin turgan dushmanlar orasidan barqaror (id bo'yicha) tanlaydi.
	var reach := float(u.def.range) + 2.0
	if absf(nearest.x - u.x) > reach:
		return nearest
	var window := 90.0 if u.is_ranged() else 30.0
	var cands: Array[UnitState] = []
	for e in units:
		if e.team != u.team and e.is_alive() and absf(e.x - nearest.x) < window and absf(e.x - u.x) <= reach:
			cands.append(e)
	if cands.size() <= 1:
		return nearest
	return cands[u.id % cands.size()]


func _engage(u: UnitState, target: UnitState, dt: float) -> void:
	var dx := target.x - u.x
	var reach := float(u.def.range)
	if absf(dx) > reach:
		_move_towards(u, target.x - signf(dx) * reach * 0.9, dt)
	else:
		u.facing = 1 if dx >= 0 else -1
		if u.cooldown <= 0.0:
			_attack_unit(u, target)


func _engage_castle(u: UnitState, enemy: TeamState, dt: float) -> void:
	var front := enemy.castle_x + enemy.dir * CASTLE_HALF_W
	var dx := front - u.x
	var reach := float(u.def.range)
	if absf(dx) > reach:
		_move_towards(u, front - signf(dx) * reach * 0.9 + u.slot * 0.2, dt)
	else:
		u.facing = 1 if dx >= 0 else -1
		if u.cooldown <= 0.0:
			_attack_castle(u, enemy)


func _update_controlled(u: UnitState, dt: float) -> void:
	if control_dir != 0:
		_move_towards(u, u.x + control_dir * 1000.0, dt, 1.1)
	if control_attack and u.cooldown <= 0.0:
		var reach := float(u.def.range) + 12.0
		var target: UnitState = null
		var best := INF
		for e in units:
			if e.team == u.team or not e.is_alive():
				continue
			var dx := e.x - u.x
			if signf(dx) != float(u.facing) and absf(dx) > 8.0:
				continue
			if absf(dx) <= reach and absf(dx) < best:
				best = absf(dx)
				target = e
		var enemy := teams[1 - u.team]
		var front := enemy.castle_x + enemy.dir * CASTLE_HALF_W
		if target:
			_attack_unit(u, target)
		elif absf(front - u.x) <= reach and signf(front - u.x) == float(u.facing):
			_attack_castle(u, enemy)
		else:
			# Havoga zarba: javob hissi uchun animatsiya va ovoz.
			u.cooldown = float(u.def.cooldown)
			u.attack_anim = 0.35
			events.append({"type": "swing", "team": u.team, "x": u.x, "weapon": u.def.weapon})


func _damage_against(att: UnitState, target_tags: Array) -> float:
	var dmg := float(att.def.damage) * teams[att.team].damage_mult
	var bonus: Dictionary = att.def.get("bonus", {})
	for tag in target_tags:
		if bonus.has(tag):
			dmg *= float(bonus[tag])
	if att.controlled:
		dmg *= CONTROL_BONUS
	return dmg


func _attack_unit(u: UnitState, target: UnitState) -> void:
	u.cooldown = float(u.def.cooldown) * rng.randf_range(0.92, 1.08)
	u.attack_anim = 0.35
	if u.def.has("projectile"):
		_fire(u.team, u.x, 58.0, target.id, -1, _damage_against(u, target.def.get("tags", [])), u.def.projectile, u.id)
	else:
		_pending_hits.append([target, _damage_against(u, target.def.get("tags", [])), str(u.def.weapon), u])


func _resolve_pending_hits() -> void:
	## Bir qadamda berilgan barcha zarbalar birga qo'llanadi, shunda ro'yxat tartibi
	## hech bir tomonga ustunlik bermaydi.
	var hits := _pending_hits
	_pending_hits = []
	for h in hits:
		var target: UnitState = h[0]
		if target.state == UnitState.State.DEAD:
			continue
		_apply_damage_no_kill(target, h[1], h[2])
	for h in hits:
		var target2: UnitState = h[0]
		if target2.state != UnitState.State.DEAD and target2.hp <= 0.0:
			_kill(target2, h[3])


func _attack_castle(u: UnitState, enemy: TeamState) -> void:
	u.cooldown = float(u.def.cooldown) * rng.randf_range(0.92, 1.08)
	u.attack_anim = 0.35
	var dmg := _damage_against(u, ["castle"])
	if u.def.has("projectile"):
		_fire(u.team, u.x, 58.0, -1, enemy.index, dmg * 0.6, u.def.projectile, u.id)
	else:
		_hit_castle(enemy, dmg, u.x)


func _fire(team_idx: int, from_x: float, height: float, target_id: int, castle_team: int, dmg: float, kind: String, shooter: int) -> void:
	var tx: float
	if target_id >= 0:
		tx = get_unit(target_id).x
	else:
		tx = teams[castle_team].castle_x
	var dist := absf(tx - from_x)
	projectiles.append({
		"team": team_idx, "from_x": from_x, "x": from_x, "h0": height,
		"target": target_id, "castle": castle_team, "tx": tx,
		"dmg": dmg, "kind": kind, "t": 0.0, "dur": maxf(0.25, dist / 620.0),
		"shooter": shooter,
	})
	events.append({"type": "shoot", "team": team_idx, "x": from_x, "kind": kind})


func _update_projectiles(dt: float) -> void:
	var keep: Array[Dictionary] = []
	for p in projectiles:
		p.t += dt
		if p.target >= 0:
			var tu := get_unit(p.target)
			if tu and tu.is_alive():
				p.tx = tu.x
		var k := minf(1.0, p.t / p.dur)
		p.x = lerpf(p.from_x, p.tx, k)
		if p.t < p.dur:
			keep.append(p)
			continue
		if p.castle >= 0:
			_hit_castle(teams[p.castle], p.dmg, p.x, "arrow")
		else:
			var tu2 := get_unit(p.target)
			if tu2 and tu2.is_alive() and absf(tu2.x - p.x) < 40.0:
				_apply_damage(tu2, p.dmg, "arrow", get_unit(p.shooter))
			else:
				events.append({"type": "miss", "x": p.x, "kind": p.kind})
	projectiles = keep


func _apply_damage(target: UnitState, raw: float, weapon: String, attacker: UnitState) -> void:
	_apply_damage_no_kill(target, raw, weapon)
	if target.hp <= 0.0:
		_kill(target, attacker)


func _apply_damage_no_kill(target: UnitState, raw: float, weapon: String) -> void:
	var dmg := maxf(1.0, raw - float(target.def.armor))
	target.hp -= dmg
	target.hurt_flash = 0.15
	events.append({
		"type": "hit", "x": target.x, "lane": target.lane, "team": target.team,
		"sound": hit_sound(weapon, str(target.def.armor_type)), "dmg": dmg,
	})


static func hit_sound(weapon: String, armor_type: String) -> String:
	## Har bir to'qnashuv turi uchun alohida ovoz.
	match weapon:
		"arrow":
			match armor_type:
				"shield": return "arrow_shield"
				"metal": return "arrow_metal"
				_: return "arrow_flesh"
		"sword", "sabre":
			match armor_type:
				"shield": return "sword_shield"
				"metal": return "sword_clash"
				_: return "hit_flesh"
		"spear":
			return "sword_shield" if armor_type == "shield" else "spear_hit"
		_:
			return "hit_flesh"


func _kill(u: UnitState, attacker: UnitState) -> void:
	u.state = UnitState.State.DEAD
	u.hp = 0.0
	u.dead_time = 0.0
	var t := teams[u.team]
	t.pop -= int(u.def.pop)
	t.stats.lost += 1
	teams[1 - u.team].stats.killed += 1
	events.append({"type": "death", "x": u.x, "lane": u.lane, "team": u.team, "unit": u.type,
		"controlled": u.controlled})
	if u.controlled:
		u.controlled = false
		control_dir = 0
		control_attack = false
	if attacker != null and attacker.controlled:
		events.append({"type": "control_kill", "x": u.x})


func _hit_castle(t: TeamState, dmg: float, x: float, weapon := "melee") -> void:
	t.castle_hp -= dmg
	events.append({"type": "castle_hit", "team": t.index, "x": x, "weapon": weapon, "dmg": dmg})


func _update_castle(t: TeamState, dt: float) -> void:
	## Qal'a minorasidagi kamonchilar yaqinlashgan dushmanga o'q uzadi.
	t.castle_shot_cd -= dt
	if t.castle_shot_cd > 0.0:
		return
	var best: UnitState = null
	var best_d := CASTLE_ARROW_RANGE
	for e in units:
		if e.team == t.index or not e.is_alive():
			continue
		var d := absf(e.x - t.castle_x)
		if d < best_d:
			best_d = d
			best = e
	if best:
		t.castle_shot_cd = CASTLE_ARROW_CD
		_fire(t.index, t.castle_x, 150.0, best.id, -1, CASTLE_ARROW_DMG, "arrow", -1)


func _cleanup() -> void:
	var keep: Array[UnitState] = []
	for u in units:
		if not u.is_alive() and u.dead_time > CORPSE_TIME:
			_by_id.erase(u.id)
		else:
			keep.append(u)
	units = keep
