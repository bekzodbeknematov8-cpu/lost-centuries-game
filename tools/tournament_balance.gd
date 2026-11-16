extends SceneTree
## Turnir qiyinligi: "o'rta" bot o'yinchi o'rnida har raundni o'ynaydi.
##   godot --headless --path . -s res://tools/tournament_balance.gd -- --games=8
func _init():
	var defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var ai = JSON.parse_string(FileAccess.get_file_as_string("res://data/ai.json"))
	var hd = JSON.parse_string(FileAccess.get_file_as_string("res://data/heroes.json"))
	var td = JSON.parse_string(FileAccess.get_file_as_string("res://data/tournament.json"))
	var games := 8
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--games="): games = int(a.split("=")[1])
	var heroes := ["chingiz", "jaloliddin", "temur", "boyazid"]
	var chain := 1.0
	for i in td.rounds.size():
		var w := 0
		for g in games:
			var h: String = heroes[g % heroes.size()]
			var bc := Tournament.battle_config(td, i, ai, hd, h, 300 + g)
			var s := BattleSim.new()
			s.setup(defs, bc.cfg, hd)
			var pa := AIController.new(0, ai.normal, g * 11 + 1)
			var pb := AIController.new(1, bc.ai, g * 11 + 2)
			for k in int(1200.0 / BattleSim.STEP):
				pa.update(s, BattleSim.STEP)
				pb.update(s, BattleSim.STEP)
				s.step()
				s.events.clear()
				if s.winner >= 0: break
			if s.winner == 0: w += 1
		chain *= float(w) / games
		print("raund %d: %d%% (8 raundni ketma-ket yutish ehtimoli shu yergacha: %d%%)" % [i + 1, int(100.0 * w / games), int(chain * 100)])
	quit()
