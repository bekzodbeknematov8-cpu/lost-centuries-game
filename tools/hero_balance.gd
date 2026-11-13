extends SceneTree
## Qahramonlar balansi: har juftlik uchun o'rta AI vs o'rta AI, tomonlar almashtiriladi.
##   godot --headless --path . -s res://tools/hero_balance.gd -- --games=6
func _init():
	var defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var ai = JSON.parse_string(FileAccess.get_file_as_string("res://data/ai.json"))
	var hd = JSON.parse_string(FileAccess.get_file_as_string("res://data/heroes.json"))
	var games := 6
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--games="): games = int(a.split("=")[1])
	var names = hd.keys()
	var line = "%-11s" % ""
	for n in names: line += "%-11s" % n
	print(line + "  (qator g'alaba foizi)")
	for a_h in names:
		line = "%-11s" % a_h
		for b_h in names:
			var w = 0.0
			for g in games:
				var side = g % 2
				var hs = [a_h, b_h] if side == 0 else [b_h, a_h]
				var s := BattleSim.new()
				s.setup(defs, {"seed": 900 + g, "heroes": hs}, hd)
				var ais = [AIController.new(0, ai.normal, g * 3 + 1), AIController.new(1, ai.normal, g * 3 + 2)]
				for i in int(1200.0 / BattleSim.STEP):
					for x in ais: x.update(s, BattleSim.STEP)
					s.step(); s.events.clear()
					if s.winner >= 0: break
				var a_team = side
				if s.winner == a_team: w += 1.0
				elif s.winner < 0: w += 0.5
			line += "%-11s" % ("%d%%" % int(w / games * 100))
		print(line)
	quit()
