extends SceneTree
## Jang tempi: birinchi to'qnashuv (birinchi "hit") va jang davomiyligi, bot vs bot.
##   godot --headless --path . -s res://tools/tempo_report.gd -- --games=8
func _init():
	var defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var ai = JSON.parse_string(FileAccess.get_file_as_string("res://data/ai.json"))
	var hd = JSON.parse_string(FileAccess.get_file_as_string("res://data/heroes.json"))
	var camp = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaigns.json"))
	var games := 8
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--games="): games = int(a.split("=")[1])
	var tot_first := 0.0
	var tot_len := 0.0
	var n := 0
	for lid in ["chingiz_01#1", "chingiz_01#5", "chingiz_03", "jaloliddin_02#10", "temur_05#3", "boyazid_07", "bobur_04#12", "alp_09"]:
		var fsum := 0.0
		var lsum := 0.0
		var wins := 0
		for g in games:
			var bc := Campaign.battle_config(camp, lid, ai, 900 + g)
			var s := BattleSim.new()
			s.setup(defs, bc.cfg, hd)
			var pa := AIController.new(0, ai.normal, g * 7 + 1)
			var pb := AIController.new(1, bc.ai, g * 7 + 2)
			var first := -1.0
			for k in int(1200.0 / BattleSim.STEP):
				pa.update(s, BattleSim.STEP)
				pb.update(s, BattleSim.STEP)
				s.step()
				if first < 0.0:
					for e in s.events:
						if e.type == "hit":
							first = s.time
							break
				s.events.clear()
				if s.winner >= 0: break
			if s.winner == 0: wins += 1
			fsum += first
			lsum += s.time
		print("TEMPO %-18s birinchi to'qnashuv %5.1f s   jang %5.1f s   bot g'alaba %d%%" % [lid, fsum / games, lsum / games, int(100.0 * wins / games)])
		tot_first += fsum / games
		tot_len += lsum / games
		n += 1
	print("TEMPO O'RTACHA: birinchi to'qnashuv %.1f s, jang %.1f s (%.1f daqiqa)" % [tot_first / n, tot_len / n, tot_len / n / 60.0])
	quit()
