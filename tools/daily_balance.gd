extends SceneTree
## Kunlik sinov qoidalari qiyinligi: "o'rta" bot o'yinchi o'rnida, har qoida uchun N jang.
##   godot --headless --path . -s res://tools/daily_balance.gd -- --games=8
func _init():
	var defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var ai = JSON.parse_string(FileAccess.get_file_as_string("res://data/ai.json"))
	var hd = JSON.parse_string(FileAccess.get_file_as_string("res://data/heroes.json"))
	var dc = JSON.parse_string(FileAccess.get_file_as_string("res://data/daily_challenge.json"))
	var games := 8
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--games="): games = int(a.split("=")[1])
	var heroes := ["chingiz", "jaloliddin", "temur", "boyazid", "bobur", "alp"]
	for rid in dc.rules:
		var date := ""
		for i in 60:
			var dd := Time.get_date_string_from_unix_time(1780000000 + i * 86400)
			if DailyChallenge.rule_id(dc, dd) == rid:
				date = dd
				break
		var w := 0
		for g in games:
			var bc := DailyChallenge.battle_config(dc, date, ai, hd, heroes[g % heroes.size()], 500 + g)
			var s := BattleSim.new()
			s.setup(defs, bc.cfg, hd)
			var pa := AIController.new(0, ai.normal, g * 7 + 1)
			var pb := AIController.new(1, bc.ai, g * 7 + 2)
			for k in int(1200.0 / BattleSim.STEP):
				pa.update(s, BattleSim.STEP)
				pb.update(s, BattleSim.STEP)
				s.step()
				s.events.clear()
				if s.winner >= 0: break
			if s.winner == 0: w += 1
		print("DC %-16s %d%%" % [rid, int(100.0 * w / games)])
	quit()
