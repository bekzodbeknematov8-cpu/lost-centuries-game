extends SceneTree
## Kampaniya qiyinligi: har bosqichda "o'rta" bot o'yinchi o'rnida o'ynaydi.
##   godot --headless --path . -s res://tools/campaign_balance.gd -- --games=4 [--campaign=chingiz] [--out=docs/campaign-balance.md]
## Har viloyatdan 3 level (1-, 5- va boss) sinaladi. Maqsad: 1-kampaniya ~90%+, oxirgisi ~50-70% g'alaba; o'rtacha >= 2 yulduz yaqinida.
func _init():
	var defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var ai = JSON.parse_string(FileAccess.get_file_as_string("res://data/ai.json"))
	var hd = JSON.parse_string(FileAccess.get_file_as_string("res://data/heroes.json"))
	var camp = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaigns.json"))
	var games := 4
	var only := ""
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--games="): games = int(a.split("=")[1])
		if a.begins_with("--campaign="): only = a.split("=")[1]
		if a.begins_with("--out="): out = a.split("=")[1]
	var lines: Array[String] = ["# Kampaniya qiyinligi (bot = o'rta AI o'yinchi o'rnida, %d jang/bosqich)\n" % games, "| Bosqich | G'alaba | O'rt. yulduz | O'rt. vaqt |", "|---|---|---|---|"]
	for cid in camp.order:
		if only != "" and cid != only: continue
		var cw := 0.0
		var cs := 0.0
		var sample: Array = []
		for ri in Campaign.regions(camp, cid).size():
			var rl: Array = Campaign.region_levels(camp, cid, ri)
			sample.append(rl[0])
			sample.append(rl[4])
			sample.append(rl[rl.size() - 1])
		for lv in sample:
			var wins := 0
			var stars := 0
			var tsum := 0.0
			for g in games:
				var bc := Campaign.battle_config(camp, lv.id, ai, 700 + g)
				var s := BattleSim.new()
				s.setup(defs, bc.cfg, hd)
				var pa := AIController.new(0, ai.normal, g * 5 + 1)
				var pb := AIController.new(1, bc.ai, g * 5 + 2)
				for i in int(1200.0 / BattleSim.STEP):
					pa.update(s, BattleSim.STEP)
					pb.update(s, BattleSim.STEP)
					s.step(); s.events.clear()
					if s.winner >= 0: break
				var won := s.winner == 0
				if won: wins += 1
				stars += Campaign.compute_stars(lv, won, s.teams[0].castle_hp / s.teams[0].castle_max_hp, s.time)
				tsum += s.time
			cw += float(wins) / games
			cs += float(stars) / games
			var line := "| %s | %d%% | %.1f | %d:%02d |" % [lv.id, int(100.0 * wins / games), float(stars) / games, int(tsum / games) / 60, int(tsum / games) % 60]
			lines.append(line)
			print(line)
		var summary := "| **%s jami** | **%d%%** | **%.1f** | |" % [cid, int(cw * 100.0 / sample.size()), cs / sample.size()]
		lines.append(summary)
		print(summary)
	if out != "":
		var f := FileAccess.open("res://" + out, FileAccess.WRITE)
		f.store_string("\n".join(lines) + "\n")
	quit()
