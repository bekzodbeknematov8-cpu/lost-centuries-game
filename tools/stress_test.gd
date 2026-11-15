extends SceneTree
## Simulyatsiya og'irlik sinovi: N ta jangchi bilan bitta qadam necha ms davom etadi.
##   godot --headless --path . -s res://tools/stress_test.gd -- --units=150
func _init():
	var defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var hd = JSON.parse_string(FileAccess.get_file_as_string("res://data/heroes.json"))
	var n := 150
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--units="): n = int(a.split("=")[1])
	var s := BattleSim.new()
	s.setup(defs, {"seed": 5, "heroes": ["temur", "chingiz"]}, hd)
	var kinds := ["swordsman", "spearman", "archer", "cavalry"]
	for i in n:
		var u := s.spawn_unit(i % 2, kinds[(i / 2) % kinds.size()])
		u.x += s.teams[i % 2].dir * float(i / 2) * 6.0
	s.set_stance(0, TeamState.Stance.ATTACK)
	s.set_stance(1, TeamState.Stance.ATTACK)
	var worst := 0.0
	var total := 0.0
	var steps := 2400
	for i in steps:
		var t0 := Time.get_ticks_usec()
		s.step()
		s.events.clear()
		var dt := (Time.get_ticks_usec() - t0) / 1000.0
		total += dt
		worst = maxf(worst, dt)
	print("SIM steps=%d units_start=%d units_end=%d avg_step_ms=%.3f worst_ms=%.3f (byudjet 33ms/qadam)" % [steps, n, s.units.size(), total / steps, worst])
	quit()
