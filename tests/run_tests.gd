extends SceneTree
## Avtomatik testlar. Ishga tushirish:
##   godot --headless --path . -s res://tests/run_tests.gd
## Xato bo'lsa, chiqish kodi 1 bo'ladi (CI uchun).

var defs: Dictionary
var ai_params: Dictionary
var failures: Array[String] = []
var current := ""


func _init() -> void:
	defs = load_json("res://data/units.json")
	ai_params = load_json("res://data/ai.json")
	var tests := []
	for m in get_method_list():
		if str(m.name).begins_with("test_"):
			tests.append(str(m.name))
	tests.sort()
	var passed := 0
	for name in tests:
		current = name
		var before := failures.size()
		call(name)
		if failures.size() == before:
			passed += 1
			print("  OK   ", name)
		else:
			print("  FAIL ", name)
	print("\n%d/%d test o'tdi" % [passed, tests.size()])
	for f in failures:
		print("  - ", f)
	quit(0 if failures.is_empty() else 1)


static func load_json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append("%s: %s" % [current, msg])


func new_sim(cfg := {}) -> BattleSim:
	var s := BattleSim.new()
	if not cfg.has("start_units"):
		cfg["start_units"] = [[], []]
	s.setup(defs, cfg)
	return s


func run(sim: BattleSim, seconds: float, ais: Array = []) -> void:
	var n := int(seconds / BattleSim.STEP)
	for i in n:
		for a in ais:
			a.update(sim, BattleSim.STEP)
		sim.step()
		sim.pop_events()
		if sim.winner >= 0:
			return


# --- Iqtisod ----------------------------------------------------------------

func test_train_costs_gold_and_spawns() -> void:
	var s := new_sim({"start_gold": 500})
	check(s.train(0, "swordsman"), "yollash muvaffaqiyatsiz")
	check(is_equal_approx(s.teams[0].gold, 375.0), "oltin to'g'ri ayirilmadi: %s" % s.teams[0].gold)
	run(s, 4.5)
	check(s.alive_units(0).size() == 1, "askar paydo bo'lmadi")
	check(s.teams[0].pop == 1, "aholi soni noto'g'ri")


func test_cannot_train_without_gold() -> void:
	var s := new_sim({"start_gold": 50})
	check(not s.train(0, "swordsman"), "oltin yetmasa ham yollandi")


func test_queue_limit() -> void:
	var s := new_sim({"start_gold": 10000})
	for i in 7:
		s.train(0, "worker")
	check(s.teams[0].queue.size() == BattleSim.MAX_QUEUE, "navbat chegarasi ishlamadi")


func test_pop_cap() -> void:
	var s := new_sim({"start_gold": 100000, "pop_cap": 3})
	s.train(0, "cavalry")
	check(s.train(0, "worker"), "3-joy band bo'lmasligi kerak edi")
	check(not s.train(0, "worker"), "aholi chegarasidan oshib ketdi")


func test_disallowed_unit() -> void:
	var s := new_sim({"start_gold": 1000, "allowed": ["worker", "swordsman"]})
	check(not s.train(0, "cavalry"), "ruxsat etilmagan birlik yollandi")


func test_worker_mines_gold() -> void:
	var s := new_sim({"start_gold": 0, "start_units": [["worker"], []]})
	s.teams[0].passive_income = 0.0
	run(s, 30.0)
	check(s.teams[0].gold >= 40.0, "ishchi oltin keltirmadi: %s" % s.teams[0].gold)


# --- Jang -------------------------------------------------------------------

func test_hit_sounds_differ_by_collision() -> void:
	check(BattleSim.hit_sound("sword", "metal") == "sword_clash", "qilich-qilich")
	check(BattleSim.hit_sound("sword", "shield") == "sword_shield", "qilich-qalqon")
	check(BattleSim.hit_sound("arrow", "shield") == "arrow_shield", "o'q-qalqon")
	check(BattleSim.hit_sound("arrow", "cloth") == "arrow_flesh", "o'q-mato")
	check(BattleSim.hit_sound("spear", "metal") == "spear_hit", "nayza")


func test_spear_bonus_vs_cavalry() -> void:
	var s := new_sim()
	var sp := s.spawn_unit(0, "spearman")
	var cav := s.spawn_unit(1, "cavalry")
	var sw := s.spawn_unit(1, "swordsman")
	check(s._damage_against(sp, cav.def.tags) > s._damage_against(sp, sw.def.tags) * 2.0,
		"nayzachi otliqqa qarshi kuchli emas")


func test_melee_fight_resolves() -> void:
	var s := new_sim()
	var a := s.spawn_unit(0, "swordsman")
	var b := s.spawn_unit(1, "worker")
	a.x = 1500.0
	b.x = 1520.0
	s.teams[0].stance = TeamState.Stance.ATTACK
	s.teams[1].stance = TeamState.Stance.RETREAT
	b.state = UnitState.State.IDLE
	for i in 300:
		s._engage(a, b, BattleSim.STEP)
		s.step()
		b.x = 1520.0
		if not b.is_alive():
			break
	check(not b.is_alive(), "qilichboz ishchini yengmadi")
	check(s.teams[1].stats.lost == 1, "yo'qotish hisoblanmadi")


func test_archer_projectile_hits() -> void:
	var s := new_sim()
	var a := s.spawn_unit(0, "archer")
	var b := s.spawn_unit(1, "swordsman")
	a.x = 1400.0
	b.x = 1650.0
	var hp0 := b.hp
	s._attack_unit(a, b)
	check(s.projectiles.size() == 1, "o'q uchmadi")
	b.x = 1650.0
	var hit := false
	for i in 40:
		s._update_projectiles(BattleSim.STEP)
		for e in s.pop_events():
			if e.type == "hit":
				hit = true
	check(hit and b.hp < hp0, "o'q nishonga tegmadi")


func test_castle_defends_itself() -> void:
	var s := new_sim()
	var e := s.spawn_unit(1, "worker")
	e.x = s.teams[0].castle_x + 200.0
	s.teams[1].stance = TeamState.Stance.RETREAT
	for i in 30:
		s._update_castle(s.teams[0], BattleSim.STEP)
	check(s.projectiles.size() >= 1, "qal'a o'q uzmadi")


func test_castle_destroy_sets_winner() -> void:
	var s := new_sim()
	s.teams[1].castle_hp = 5.0
	s._hit_castle(s.teams[1], 10.0, 3000.0)
	s.step()
	check(s.winner == 0, "g'olib aniqlanmadi")


func test_controlled_unit_moves_and_attacks() -> void:
	var s := new_sim()
	var a := s.spawn_unit(0, "swordsman")
	var b := s.spawn_unit(1, "swordsman")
	a.x = 1000.0
	b.x = 1300.0
	s.teams[1].stance = TeamState.Stance.RETREAT
	var c := s.take_control(0)
	check(c == a, "boshqaruv olinmadi")
	s.control_dir = 1
	var x0 := a.x
	for i in 10:
		s.step()
	check(a.x > x0 + 10.0, "boshqariladigan askar yurmadi")
	s.control_dir = 0
	b.x = a.x + 20.0
	s.teams[1].stance = TeamState.Stance.DEFEND
	var hp0 := b.hp
	s.control_attack = true
	for i in 3:
		s.step()
	check(b.hp < hp0, "boshqariladigan askar zarba bermadi")


# --- Butun o'yin ------------------------------------------------------------

func test_ai_vs_ai_match_finishes() -> void:
	var s := BattleSim.new()
	s.setup(defs, {"seed": 7})
	var ais := [AIController.new(0, ai_params.normal, 1), AIController.new(1, ai_params.normal, 2)]
	run(s, 900.0, ais)
	check(s.winner >= 0, "15 daqiqada o'yin tugamadi (castle %d / %d)" % [s.teams[0].castle_hp, s.teams[1].castle_hp])


func test_determinism() -> void:
	var results := []
	for k in 2:
		var s := BattleSim.new()
		s.setup(defs, {"seed": 99})
		var ais := [AIController.new(0, ai_params.normal, 5), AIController.new(1, ai_params.hard, 6)]
		run(s, 300.0, ais)
		results.append([s.winner, snappedf(s.teams[0].castle_hp, 0.01), snappedf(s.teams[1].castle_hp, 0.01), s.units.size()])
	check(results[0] == results[1], "bir xil seed turli natija berdi: %s" % [results])


func test_difficulty_order() -> void:
	## Qiyin bot oson botni ko'pincha yengishi kerak.
	var hard_wins := 0
	var n := 10
	for k in n:
		var s := BattleSim.new()
		s.setup(defs, {"seed": 1000 + k, "income_mult": [ai_params.hard.income_mult, ai_params.easy.income_mult]})
		var ais := [AIController.new(0, ai_params.hard, k * 2 + 1), AIController.new(1, ai_params.easy, k * 2 + 2)]
		run(s, 900.0, ais)
		if s.winner == 0:
			hard_wins += 1
	check(hard_wins >= 8, "qiyin bot faqat %d/%d marta yutdi" % [hard_wins, n])


# --- Qahramonlar ------------------------------------------------------------

func hero_sim(h0: String, h1: String = "") -> BattleSim:
	var s := BattleSim.new()
	s.setup(defs, {"start_units": [[], []], "heroes": [h0, h1]}, load_json("res://data/heroes.json"))
	return s


func place_enemies(s: BattleSim, type: String, xs: Array) -> Array:
	var out := []
	for x in xs:
		var e := s.spawn_unit(1, type)
		e.x = x
		out.append(e)
	s.teams[1].stance = TeamState.Stance.RETREAT
	return out


func test_hero_spawns_and_respawns() -> void:
	var s := hero_sim("temur")
	var h := s.hero_of(0)
	check(h != null and h.hero, "qahramon paydo bo'lmadi")
	check(s.teams[0].pop == 0, "qahramon aholi joyini egallamasligi kerak")
	s._kill(h, null)
	check(s.hero_of(0) == null, "qahramon o'lmadi")
	run(s, BattleSim.HERO_RESPAWN + 1.0)
	check(s.hero_of(0) != null, "qahramon qayta tug'ilmadi")


func test_ability_cooldown() -> void:
	var s := hero_sim("temur")
	s.teams[0].ability_cd = 0.0
	check(s.use_ability(0), "maxsus kuch ishlamadi")
	check(not s.use_ability(0), "qayta tiklanish vaqti ishlamadi")


func test_arrow_rain_hits_group() -> void:
	var s := hero_sim("chingiz")
	var h := s.hero_of(0)
	h.x = 1000.0
	var es := place_enemies(s, "swordsman", [1300.0, 1330.0, 1360.0])
	s.teams[0].ability_cd = 0.0
	s.teams[0].stance = TeamState.Stance.RETREAT
	check(s.ability_targets(0) >= 3, "o'q yomg'iri nishonlarni ko'rmadi")
	s.use_ability(0)
	for i in 120:
		for e in es:
			e.x = clampf(e.x, 1290.0, 1370.0)
		s.step()
	var hurt := 0
	for e in es:
		if e.hp < e.max_hp:
			hurt += 1
	check(hurt == 3, "o'q yomg'iri faqat %d dushmanga tegdi" % hurt)


func test_leap_moves_and_stuns() -> void:
	var s := hero_sim("jaloliddin")
	var h := s.hero_of(0)
	h.x = 1000.0
	var es := place_enemies(s, "spearman", [1280.0, 1300.0])
	s.teams[0].ability_cd = 0.0
	s.use_ability(0)
	for i in 20:
		s.step()
	check(h.x > 1200.0, "sakrash qahramonni siljitmadi: %s" % h.x)
	check(es[0].stun > 0.0 or es[1].stun > 0.0, "dushman hayratlanmadi")
	check(es[0].hp < es[0].max_hp, "sakrash zarar bermadi")


func test_rally_buffs_army() -> void:
	var s := hero_sim("temur")
	var a := s.spawn_unit(0, "swordsman")
	a.hp = 50.0
	s.teams[0].ability_cd = 0.0
	var d0 := s._damage_against(a, ["infantry"])
	s.use_ability(0)
	var mult := float(s.heroes.temur.ability.damage_mult)
	check(s._damage_against(a, ["infantry"]) >= d0 * mult - 0.01 and mult > 1.0, "kuch berish ishlamadi")
	check(a.hp > 50.0, "davolash ishlamadi")


func test_lightning_hits_line() -> void:
	var s := hero_sim("boyazid")
	var h := s.hero_of(0)
	h.x = 1000.0
	var es := place_enemies(s, "archer", [1100.0, 1250.0, 1400.0])
	s.teams[0].ability_cd = 0.0
	s.use_ability(0)
	for i in 20:
		s.step()
	var hit := 0
	for e in es:
		if e.hp < e.max_hp:
			hit += 1
	check(hit == 3, "yashin hujumi faqat %d dushmanga tegdi" % hit)


func test_hero_battle_finishes() -> void:
	var hd := load_json("res://data/heroes.json")
	var names := hd.keys()
	for k in names.size():
		var s := BattleSim.new()
		s.setup(defs, {"seed": 300 + k, "heroes": [names[k], names[(k + 1) % names.size()]]}, hd)
		var ais := [AIController.new(0, ai_params.normal, 1), AIController.new(1, ai_params.normal, 2)]
		run(s, 900.0, ais)
		check(s.winner >= 0, "%s vs %s: o'yin tugamadi" % [names[k], names[(k + 1) % names.size()]])


# --- Kampaniya --------------------------------------------------------------

func camp() -> Dictionary:
	return load_json("res://data/campaigns.json")


func test_campaign_data_valid() -> void:
	var c := camp()
	var hd := load_json("res://data/heroes.json")
	var facts := load_json("res://data/facts.json")
	check(c.order.size() == 4, "4 ta kampaniya bo'lishi kerak")
	for cid in c.order:
		var levels: Array = c.campaigns[cid].levels
		check(levels.size() == 10, "%s: 10 ta bosqich bo'lishi kerak" % cid)
		check(hd.has(c.campaigns[cid].hero), "%s: qahramon topilmadi" % cid)
		for lv in levels:
			for loc in ["uz", "en", "ru", "tr"]:
				check(lv.name.has(loc), "%s: %s nomi yo'q" % [lv.id, loc])
				check(facts.has(lv.id) and str(facts[lv.id].get(loc, "")) != "", "%s: %s fakti yo'q" % [lv.id, loc])
			var eh := str(lv.get("enemy_hero", ""))
			check(eh == "" or hd.has(eh), "%s: dushman qahramoni noto'g'ri" % lv.id)
			check(str(lv.get("ai", "")) in ["easy", "normal", "hard"], "%s: AI profili noto'g'ri" % lv.id)


func test_stars_rules() -> void:
	var lv := {"par": 300}
	check(Campaign.compute_stars(lv, false, 1.0, 10.0) == 0, "yutqazganda yulduz yo'q")
	check(Campaign.compute_stars(lv, true, 0.3, 900.0) == 1, "g'alaba = 1 yulduz")
	check(Campaign.compute_stars(lv, true, 0.6, 900.0) == 2, "qal'a 50%+ = 2 yulduz")
	check(Campaign.compute_stars(lv, true, 0.85, 900.0) == 3, "qal'a 80%+ = 3 yulduz")
	check(Campaign.compute_stars(lv, true, 0.6, 250.0) == 3, "tez g'alaba = 3 yulduz")


func test_unlock_rules() -> void:
	var c := camp()
	var stars := {}
	var first: String = Campaign.region_levels(c, "chingiz", 0)[0].id
	check(Campaign.level_unlocked(c, stars, first), "birinchi level ochiq bo'lishi kerak")
	check(not Campaign.level_unlocked(c, stars, "chingiz_01#2"), "2-level yopiq bo'lishi kerak")
	check(not Campaign.region_unlocked(c, stars, "chingiz", 1), "2-viloyat yopiq bo'lishi kerak")
	check(not Campaign.campaign_unlocked(c, stars, "jaloliddin"), "2-kampaniya yopiq bo'lishi kerak")
	stars[first] = 1
	check(Campaign.level_unlocked(c, stars, "chingiz_01#2"), "g'alabadan keyin keyingi level ochilishi kerak")
	check(Campaign.next_level_id(c, "chingiz_01#9") == "chingiz_01", "9-leveldan keyin boss bo'lishi kerak")
	check(Campaign.next_level_id(c, "chingiz_01") == "chingiz_02#1", "bossdan keyin keyingi viloyat")
	check(Campaign.next_level_id(c, "chingiz_10") == "", "oxirgi bossdan keyin bo'sh bo'lishi kerak")
	stars["chingiz_01"] = 1
	check(Campaign.region_unlocked(c, stars, "chingiz", 1), "boss yengilgach 2-viloyat ochilishi kerak")
	# 4 viloyat zabt + yetarli yulduz -> 2-kampaniya
	for ri in 4:
		for lv in Campaign.region_levels(c, "chingiz", ri):
			stars[lv.id] = 1
	check(not Campaign.campaign_unlocked(c, stars, "jaloliddin"), "40 yulduz yetmasligi kerak (60 talab)")
	for ri in 4:
		for lv in Campaign.region_levels(c, "chingiz", ri):
			stars[lv.id] = 2
	check(Campaign.campaign_unlocked(c, stars, "jaloliddin"), "80 yulduz va 4 viloyat bilan ochilishi kerak")


func test_region_levels_structure() -> void:
	var c := camp()
	var total := 0
	for cid in c.order:
		var flat := Campaign.all_levels(c, cid)
		total += flat.size()
		var ids := {}
		for lv in flat:
			check(not ids.has(lv.id), "takroriy level ID: %s" % lv.id)
			ids[lv.id] = true
			check(Campaign.level_by_id(c, lv.id).id == lv.id, "level_by_id topmadi: %s" % lv.id)
	check(total == 400, "jami 400 level bo'lishi kerak, %d bor" % total)
	# Qiyinlik viloyat ichida silliq oshadi
	var lv1: Dictionary = Campaign.region_levels(c, "temur", 5)[0]
	var lv9: Dictionary = Campaign.region_levels(c, "temur", 5)[8]
	check(float(lv9.enemy_income) >= float(lv1.enemy_income), "viloyat ichida qiyinlik oshishi kerak")


func test_star_requirements_reasonable() -> void:
	## Talab: o'rtacha ~2 yulduz/level dan oshmasin (juda qiyin bo'lmasin).
	var c := camp()
	for i in range(1, c.order.size()):
		var need := int(c.campaigns[c.order[i]].require_stars)
		var levels_before := 0
		for j in i:
			levels_before += Campaign.REGION_LEVELS * Campaign.UNLOCK_AFTER_REGION
		check(need <= levels_before * 2, "%s: yulduz talabi juda yuqori (%d)" % [c.order[i], need])


func test_survive_objective() -> void:
	var s := BattleSim.new()
	s.setup(defs, {"start_units": [[], []], "survive_time": 5.0})
	run(s, 6.0)
	check(s.winner == 0, "mudofaa vaqti tugaganda o'yinchi yutishi kerak")


func test_every_level_builds() -> void:
	var c := camp()
	var hd := load_json("res://data/heroes.json")
	for cid in c.order:
		for lv in Campaign.all_levels(c, cid):
			var bc := Campaign.battle_config(c, lv.id, ai_params, 1)
			var s := BattleSim.new()
			s.setup(defs, bc.cfg, hd)
			check(s.hero_of(0) != null, "%s: o'yinchi qahramoni yo'q" % lv.id)
			check(s.teams[0].allowed.size() >= 2, "%s: yollash ro'yxati bo'sh" % lv.id)
			for k in 10:
				s.step()


func test_first_level_winnable_by_bot() -> void:
	var c := camp()
	var hd := load_json("res://data/heroes.json")
	var wins := 0
	for k in 4:
		var bc := Campaign.battle_config(c, "chingiz_01#1", ai_params, 50 + k)
		var s := BattleSim.new()
		s.setup(defs, bc.cfg, hd)
		var ais := [AIController.new(0, ai_params.normal, k + 1), AIController.new(1, bc.ai, k + 7)]
		run(s, 900.0, ais)
		if s.winner == 0:
			wins += 1
	check(wins >= 3, "1-bosqich juda qiyin: bot %d/4 yutdi" % wins)


func test_progress_save_load() -> void:
	var path := "user://test_progress.json"
	var st := ProgressStore.new(path)
	check(st.record_result("test_level", 2, 50) == 2, "yangi yulduzlar soni noto'g'ri")
	check(st.record_result("test_level", 1, 10) == 0, "eski rekord saqlanishi kerak")
	var st2 := ProgressStore.new(path)
	st2.load_file()
	check(int(st2.data.stars.get("test_level", 0)) == 2, "saqlangan yulduz yuklanmadi")
	check(int(st2.data.coins) == 60, "saqlangan tanga yuklanmadi")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{buzilgan json")
	f.close()
	st2.load_file()
	check(st2.data.stars.is_empty(), "buzilgan fayl xavfsiz o'qilishi kerak")
	DirAccess.remove_absolute(path)


# --- Cheksiz mudofaa va reklama ---------------------------------------------

func test_endless_waves_grow() -> void:
	var s := BattleSim.new()
	s.setup(defs, {"start_units": [[], []], "endless": true}, load_json("res://data/heroes.json"))
	s.teams[0].castle_hp = 1.0e9
	run(s, BattleSim.FIRST_WAVE + 1.0)
	check(s.wave == 1, "1-to'lqin kelmadi")
	var n1 := s.alive_units(1).size()
	check(n1 >= 1, "to'lqinda askar yo'q")
	check(BattleSim.wave_budget(10) > BattleSim.wave_budget(2) * 3.0, "to'lqinlar yetarlicha kuchaymaydi")
	s.teams[1].castle_hp = 100.0
	s._hit_castle(s.teams[1], 500.0, 0.0)
	check(s.teams[1].castle_hp == 100.0, "cheksiz rejimda dushman qal'asi buzilmasligi kerak")


func test_endless_ends_when_castle_falls() -> void:
	var s := BattleSim.new()
	s.setup(defs, {"start_units": [[], []], "endless": true, "castle_hp": [300, 2000]})
	run(s, 400.0)
	check(s.winner == 1, "qal'a qulaganda o'yin tugashi kerak")
	check(s.wave >= 1, "kamida bitta to'lqin bo'lishi kerak")


func test_ad_daily_limit() -> void:
	var path := "user://test_ads.json"
	var st := ProgressStore.new(path)
	check(st.ads_left("2026-01-01") == ProgressStore.AD_DAILY_LIMIT, "kun boshida limit to'liq bo'lishi kerak")
	for i in ProgressStore.AD_DAILY_LIMIT:
		check(st.note_ad_reward("2026-01-01", 10), "reklama mukofoti berilmadi")
	check(not st.note_ad_reward("2026-01-01", 10), "kunlik chegaradan oshib ketdi")
	check(int(st.data.coins) == 10 * ProgressStore.AD_DAILY_LIMIT, "reklama tangalari noto'g'ri")
	check(st.ads_left("2026-01-02") == ProgressStore.AD_DAILY_LIMIT, "yangi kunda limit tiklanishi kerak")
	check(st.record_wave(7, 100) and not st.record_wave(5, 10), "rekord mantiqi noto'g'ri")
	var st2 := ProgressStore.new(path)
	st2.load_file()
	check(int(st2.data.best_wave) == 7 and int(st2.data.ad_count) == ProgressStore.AD_DAILY_LIMIT, "rekord/reklama holati saqlanmadi")
	DirAccess.remove_absolute(path)


func test_gems_persist() -> void:
	var path := "user://test_gems.json"
	var st := ProgressStore.new(path)
	st.data.gems = 25
	st.save_file()
	var st2 := ProgressStore.new(path)
	st2.load_file()
	check(int(st2.data.gems) == 25, "la'l saqlanmadi")
	DirAccess.remove_absolute(path)


# --- Ustaxona ---------------------------------------------------------------

func upg() -> Dictionary:
	return load_json("res://data/upgrades.json")


func test_upgrade_costs_grow_and_cap() -> void:
	var d := upg()
	for id in d.order:
		var prev := 0
		for lvl in int(d.upgrades[id].max):
			var c := Upgrades.cost(d, id, lvl)
			check(c > prev, "%s: narx o'smayapti (%d)" % [id, lvl])
			prev = c
		check(Upgrades.cost(d, id, int(d.upgrades[id].max)) == -1, "%s: maksimumdan keyin sotilmasligi kerak" % id)


func test_upgrades_affect_battle() -> void:
	var d := upg()
	var eff := Upgrades.effects(d, {"army_hp": 10, "army_dmg": 5, "castle": 4, "start_gold": 2, "hero_power": 5})
	var s := BattleSim.new()
	s.setup(defs, {"start_units": [[], []], "start_gold": 300, "heroes": ["temur", "temur"], "upgrades": [eff, {}]}, load_json("res://data/heroes.json"))
	var a := s.spawn_unit(0, "swordsman")
	var b := s.spawn_unit(1, "swordsman")
	check(a.max_hp > b.max_hp * 1.4, "HP yaxshilanishi ishlamadi")
	check(s._damage_against(a, ["infantry"]) > s._damage_against(b, ["infantry"]) * 1.15, "zarar yaxshilanishi ishlamadi")
	check(s.teams[0].castle_max_hp > s.teams[1].castle_max_hp, "qal'a yaxshilanishi ishlamadi")
	check(s.teams[0].gold == 400.0, "boshlang'ich oltin yaxshilanishi ishlamadi: %s" % s.teams[0].gold)
	check(s.hero_of(0).max_hp > s.hero_of(1).max_hp, "qahramon yaxshilanishi ishlamadi")


func test_buy_upgrade_and_hero() -> void:
	var d := upg()
	var path := "user://test_shop.json"
	var st := ProgressStore.new(path)
	st.data.coins = 200
	check(st.buy_upgrade(d, "army_hp"), "yetarli tangada sotib olinmadi")
	check(int(st.data.upgrades.army_hp) == 1 and int(st.data.coins) == 200 - Upgrades.cost(d, "army_hp", 0), "daraja yoki tanga noto'g'ri")
	check(not st.buy_upgrade(d, "hero_power"), "tanga yetmasa sotilmasligi kerak")
	check(not st.buy_hero(d, "temur"), "tanga yetmasa qahramon sotilmasligi kerak")
	st.data.coins = 5000
	check(st.buy_hero(d, "temur") and not st.buy_hero(d, "temur"), "qahramon ikki marta sotildi")
	check(Upgrades.hero_owned(d, st.data.heroes, "temur", false), "sotib olingan qahramon ochiq emas")
	check(Upgrades.hero_owned(d, [], "chingiz", false), "bepul qahramon ochiq bo'lishi kerak")
	check(Upgrades.hero_owned(d, [], "boyazid", true), "kampaniyasi ochiq qahramon ochiq bo'lishi kerak")
	check(not Upgrades.hero_owned(d, [], "boyazid", false), "yopiq qahramon ochiq bo'lib qoldi")
	var st2 := ProgressStore.new(path)
	st2.load_file()
	check(int(st2.data.upgrades.get("army_hp", 0)) == 1 and "temur" in st2.data.heroes, "xaridlar saqlanmadi")
	DirAccess.remove_absolute(path)


# --- Hiylalar ---------------------------------------------------------------

func tac() -> Dictionary:
	return load_json("res://data/tactics.json")


func test_tactics_effects() -> void:
	var d := tac()
	var s := new_sim({"start_gold": 100})
	check(s.use_tactic(0, "caravan", d.tactics.caravan) and s.teams[0].gold == 400.0, "karvon oltin bermadi")
	var a := s.spawn_unit(0, "swordsman")
	a.hp = 20.0
	s.use_tactic(0, "healing", d.tactics.healing)
	check(a.hp > 20.0 + a.max_hp * 0.4, "shifo ishlamadi")
	s.use_tactic(0, "shield_wall", d.tactics.shield_wall)
	var hp0 := a.hp
	s._apply_damage_no_kill(a, 52.0, "sword")
	check(absf((hp0 - a.hp) - (52.0 - float(a.def.armor)) * 0.6) < 0.01, "qalqon devori zararni kamaytirmadi")
	check(not s.use_tactic(0, "war_drum", d.tactics.war_drum), "bir jangda 3 tadan ko'p hiyla ishlatildi")
	check(s.teams[1].tactics_used == 0, "hiyla boshqa tomonga ta'sir qildi")


func test_tactics_timed_expire() -> void:
	var d := tac()
	var s := new_sim()
	s.use_tactic(0, "fast_mining", d.tactics.fast_mining)
	s.use_tactic(0, "tower_volley", d.tactics.tower_volley)
	check(s.teams[0].mine_mult == 2.0 and s.teams[0].tower_rate == 3.0, "vaqtli hiyla ishlamadi")
	run(s, 31.0)
	check(s.teams[0].mine_mult == 1.0 and s.teams[0].tower_rate == 1.0, "vaqtli hiyla tugamadi")


func test_tactics_store() -> void:
	var d := tac()
	var path := "user://test_tac.json"
	var st := ProgressStore.new(path)
	st.give_starter_tactics(d)
	st.give_starter_tactics(d)
	check(int(st.data.tactics.caravan) == 2, "boshlang'ich hiylalar ikki marta berildi")
	check(not st.buy_tactic(d, "war_drum"), "tangasiz sotildi")
	st.data.coins = 500
	check(st.buy_tactic(d, "war_drum") and int(st.data.tactics.war_drum) == 1, "hiyla sotilmadi")
	check(st.consume_tactic("war_drum") and not st.consume_tactic("war_drum"), "sarflash noto'g'ri")
	var st2 := ProgressStore.new(path)
	st2.load_file()
	check(int(st2.data.tactics.get("caravan", 0)) == 2 and bool(st2.data.starter_given), "hiylalar saqlanmadi")
	DirAccess.remove_absolute(path)
