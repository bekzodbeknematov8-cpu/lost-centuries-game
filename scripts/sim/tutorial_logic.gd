class_name TutorialLogic
extends RefCounted
## O'rgatuvchi qadamlar va ularning bajarilish shartlari (simulyatsiya holatiga qarab).
## target: HUD dagi qaysi tugma yoritiladi.

const STEPS := [
	{"text": "TUT_WORKER", "target": "unit:worker"},
	{"text": "TUT_SWORD", "target": "unit:swordsman"},
	{"text": "TUT_ARMY", "target": ""},
	{"text": "TUT_ATTACK", "target": "stance:attack"},
	{"text": "TUT_ABILITY", "target": "ability"},
	{"text": "TUT_CONTROL", "target": "control"},
	{"text": "TUT_FINISH", "target": ""},
]


static func step_done(step: int, sim: BattleSim, ctx: Dictionary) -> bool:
	var t := sim.teams[0]
	match step:
		0:
			return t.queue.has("worker") or int(sim.count_types(0).get("worker", 0)) > int(ctx.get("start_workers", 2))
		1:
			return t.queue.has("swordsman") or int(sim.count_types(0).get("swordsman", 0)) > 0
		2:
			var army := 0
			for k in ["swordsman", "spearman", "archer", "cavalry"]:
				army += int(sim.count_types(0).get(k, 0))
			return army >= 3 or float(ctx.get("step_time", 0.0)) > 45.0
		3:
			return t.stance == TeamState.Stance.ATTACK
		4:
			return t.ability_cd > 0.0 and float(ctx.get("step_time", 0.0)) > 0.5 or sim.hero_of(0) == null
		5:
			return sim.controlled_unit() != null or float(ctx.get("step_time", 0.0)) > 12.0
		6:
			return float(ctx.get("step_time", 0.0)) > 5.0
	return true


static func enemy_paused(step: int) -> bool:
	## Dushman o'yinchi hujum tugmasini o'rganguncha (3-qadam) kutib turadi.
	return step < 3
