extends SceneTree
## Balans simulyatori: minglab "bot vs bot" jang o'tkazib, hisobot chiqaradi.
##   godot --headless --path . -s res://tools/balance.gd -- --games=20 --out=docs/balance-report.md

var defs: Dictionary
var ai: Dictionary


func _init() -> void:
	defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	ai = JSON.parse_string(FileAccess.get_file_as_string("res://data/ai.json"))
	var args := {}
	for a in OS.get_cmdline_user_args():
		var p := a.trim_prefix("--").split("=", true, 1)
		args[p[0]] = p[1] if p.size() > 1 else "1"
	var games := int(args.get("games", "20"))
	var lines: Array[String] = []
	lines.append("# Balans hisoboti\n")
	lines.append("Har bir juftlik uchun %d ta bot-vs-bot jang (chap tomon = qator).\n" % games)

	if not args.has("units_only"):
		_difficulty_table(lines, games)
	_unit_table(lines, games)
	if args.has("out"):
		var f := FileAccess.open("res://" + str(args.out), FileAccess.WRITE)
		f.store_string("\n".join(lines) + "\n")
	quit()


func _difficulty_table(lines: Array[String], games: int) -> void:
	lines.append("## Qiyinlik darajalari\n")
	lines.append("| Chap \\ O'ng | easy | normal | hard |")
	lines.append("|---|---|---|---|")
	for a_name in ["easy", "normal", "hard"]:
		var row := "| %s |" % a_name
		for b_name in ["easy", "normal", "hard"]:
			var r := _series(ai[a_name], ai[b_name], games, {})
			row += " %d%% (%s) |" % [int(r.win * 100), _fmt_time(r.avg_time)]
		lines.append(row)
		print(row)


func _unit_table(lines: Array[String], games: int) -> void:
	lines.append("\n## Bir turdagi qo'shinlar (tosh-qaychi-qog'oz tekshiruvi)\n")
	var types := ["swordsman", "spearman", "archer", "cavalry"]
	lines.append("| Chap \\ O'ng | " + " | ".join(types) + " |")
	lines.append("|---|---|---|---|---|")
	for a_t in types:
		var row2 := "| %s |" % a_t
		for b_t in types:
			var pa: Dictionary = ai.normal.duplicate(true)
			pa.weights = {a_t: 1}
			pa.counter_chance = 0.0
			var pb: Dictionary = ai.normal.duplicate(true)
			pb.weights = {b_t: 1}
			pb.counter_chance = 0.0
			var r2 := _series(pa, pb, games, {})
			row2 += " %d%% |" % int(r2.win * 100)
		lines.append(row2)
		print(row2)
	lines.append("\nIzoh: 50% atrofidagi qiymat — teng kuch. Diagonal ~50% bo'lishi kerak.")
	lines.append("Har bir birlik kamida bitta boshqa birlikka qarshi kuchli, kamida bittasiga qarshi zaif bo'lishi kerak.")


func _series(pa: Dictionary, pb: Dictionary, games: int, cfg: Dictionary) -> Dictionary:
	var wins := 0.0
	var total_time := 0.0
	for g in games:
		var s := BattleSim.new()
		var c := cfg.duplicate()
		c.seed = 5000 + g
		c.income_mult = [float(pa.get("income_mult", 1.0)), float(pb.get("income_mult", 1.0))]
		s.setup(defs, c)
		var a := AIController.new(0, pa, g * 7 + 1)
		var b := AIController.new(1, pb, g * 7 + 3)
		var steps := int(1200.0 / BattleSim.STEP)
		for i in steps:
			a.update(s, BattleSim.STEP)
			b.update(s, BattleSim.STEP)
			s.step()
			s.events.clear()
			if s.winner >= 0:
				break
		if s.winner == 0:
			wins += 1.0
		elif s.winner < 0:
			wins += 0.5
		total_time += s.time
	return {"win": wins / games, "avg_time": total_time / games}


func _fmt_time(sec: float) -> String:
	return "%d:%02d" % [int(sec) / 60, int(sec) % 60]
