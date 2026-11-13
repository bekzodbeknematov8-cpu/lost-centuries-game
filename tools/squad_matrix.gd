extends SceneTree
## Teng narxli otryadlar to'qnashuvi (har ikki tomonda almashtirib), natija: qator g'alaba foizi.
##   godot --headless --path . -s res://tools/squad_matrix.gd
func _init():
	var defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var types = ["swordsman","spearman","archer","cavalry"]
	var budget = 1650.0
	print("           sword spear arch  cav")
	for a in types:
		var row = "%-10s" % a
		for b in types:
			var wins = 0.0
			var n = 0
			for seed in 4:
				for side in 2:
					var s := BattleSim.new(); s.setup(defs, {"seed": seed, "start_units": [[],[]]})
					var ta = side; var tb = 1 - side
					for k in int(budget / defs[a].cost):
						var u = s.spawn_unit(ta, a); u.x = 1600 - s.teams[ta].dir * (300 + k * 12)
					for k in int(budget / defs[b].cost):
						var u = s.spawn_unit(tb, b); u.x = 1600 - s.teams[tb].dir * (300 + k * 12)
					s.teams[0].stance = TeamState.Stance.ATTACK; s.teams[1].stance = TeamState.Stance.ATTACK
					for i in int(120 / BattleSim.STEP):
						s.step(); s.events.clear()
						if s.alive_units(0).is_empty() or s.alive_units(1).is_empty(): break
					var va = s.army_value(ta); var vb = s.army_value(tb)
					wins += 1.0 if va > vb else (0.5 if va == vb else 0.0)
					n += 1
			row += "  %3d%%" % int(wins / n * 100)
		print(row)
	quit()
