class_name AIController
extends RefCounted
## Dushman qo'mondoni. Bir xil kod o'yinchi tomonida ham ishlaydi
## (bot vs bot simulyatsiyalari va balans testlari uchun).

var team_idx: int = 1
var params: Dictionary = {}
var rng := RandomNumberGenerator.new()
var _think_cd: float = 0.0
var _next_unit: String = ""

const COUNTERS := {
	"cavalry": "spearman",
	"swordsman": "archer",
	"spearman": "archer",
	"archer": "cavalry",
}


func _init(idx: int, p: Dictionary, seed_value: int = 1) -> void:
	team_idx = idx
	params = p
	rng.seed = seed_value
	_think_cd = rng.randf_range(0.0, float(p.get("think_interval", 1.0)))


func update(sim: BattleSim, dt: float) -> void:
	_think_cd -= dt
	if _think_cd > 0.0:
		return
	_think_cd = float(params.get("think_interval", 1.0))
	_think_economy_and_army(sim)
	_think_stance(sim)


func _think_economy_and_army(sim: BattleSim) -> void:
	var t := sim.teams[team_idx]
	var counts := sim.count_types(team_idx)
	var workers := int(counts.get("worker", 0))
	for q in t.queue:
		if q == "worker":
			workers += 1
	if workers < int(params.get("target_workers", 4)) and sim.can_train(team_idx, "worker"):
		sim.train(team_idx, "worker")
		return
	if t.queue.size() >= 2:
		return
	if _next_unit == "" or not (_next_unit in t.allowed):
		_next_unit = _choose_unit(sim)
	if _next_unit != "" and sim.can_train(team_idx, _next_unit):
		sim.train(team_idx, _next_unit)
		_next_unit = ""


func _choose_unit(sim: BattleSim) -> String:
	var t := sim.teams[team_idx]
	if rng.randf() < float(params.get("counter_chance", 0.0)):
		var enemy_counts := sim.count_types(1 - team_idx)
		var top := ""
		var top_n := 0
		for k in enemy_counts:
			if k != "worker" and int(enemy_counts[k]) > top_n:
				top_n = int(enemy_counts[k])
				top = k
		if top != "" and COUNTERS.has(top) and COUNTERS[top] in t.allowed:
			return COUNTERS[top]
	var weights: Dictionary = params.get("weights", {})
	var total := 0.0
	for k in weights:
		if k in t.allowed:
			total += float(weights[k])
	if total <= 0.0:
		return ""
	var r := rng.randf() * total
	for k in weights:
		if not (k in t.allowed):
			continue
		r -= float(weights[k])
		if r <= 0.0:
			return k
	return ""


func _think_stance(sim: BattleSim) -> void:
	var t := sim.teams[team_idx]
	var mine := sim.army_value(team_idx)
	var theirs := sim.army_value(1 - team_idx)
	var threat := sim.pressure_on(team_idx)
	var ratio := float(params.get("attack_ratio", 1.3))
	var min_v := float(params.get("min_attack_value", 800))
	var full := t.pop + sim.queued_pop(team_idx) >= t.pop_cap - 1

	if t.stance == TeamState.Stance.ATTACK:
		if mine < theirs * 0.75 and not full:
			sim.set_stance(team_idx, TeamState.Stance.DEFEND)
		return
	if threat > 0.0 and mine < threat * 1.6:
		sim.set_stance(team_idx, TeamState.Stance.DEFEND)
		return
	if (mine >= min_v and mine >= theirs * ratio) or (full and mine > 0.0):
		sim.set_stance(team_idx, TeamState.Stance.ATTACK)
	else:
		sim.set_stance(team_idx, TeamState.Stance.DEFEND)
