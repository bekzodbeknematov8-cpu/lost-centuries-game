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
	check(c.order.size() == 6, "6 ta kampaniya bo'lishi kerak")
	var maps := load_json("res://data/maps.json")
	for cid in c.order:
		check(maps.has(cid) and maps[cid].regions.size() == c.campaigns[cid].levels.size(), "%s: xarita viloyatlari mos emas" % cid)
		check(ResourceLoader.exists("res://assets/maps/%s.png" % cid) and ResourceLoader.exists("res://assets/maps/%s_idx.png" % cid), "%s: xarita rasmi yo'q" % cid)
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
	check(Campaign.next_level_id(c, "chingiz_01#24") == "chingiz_01", "24-leveldan keyin boss bo'lishi kerak")
	check(Campaign.next_level_id(c, "chingiz_01#9") == "chingiz_01#10", "9-leveldan keyin 10-level")
	check(Campaign.next_level_id(c, "chingiz_01") == "chingiz_02#1", "bossdan keyin keyingi viloyat")
	check(Campaign.next_level_id(c, "chingiz_10") == "", "oxirgi bossdan keyin bo'sh bo'lishi kerak")
	stars["chingiz_01"] = 1
	check(Campaign.region_unlocked(c, stars, "chingiz", 1), "boss yengilgach 2-viloyat ochilishi kerak")
	# 2 viloyat zabt + yetarli yulduz -> 2-kampaniya
	for ri in 2:
		for lv in Campaign.region_levels(c, "chingiz", ri):
			stars[lv.id] = 1
	check(not Campaign.campaign_unlocked(c, stars, "jaloliddin"), "50 yulduz yetmasligi kerak (75 talab)")
	for ri in 2:
		for lv in Campaign.region_levels(c, "chingiz", ri):
			stars[lv.id] = 2
	check(Campaign.campaign_unlocked(c, stars, "jaloliddin"), "100 yulduz va 2 viloyat bilan ochilishi kerak")


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
	check(total == 250 * c.order.size(), "har kampaniyada 250 level bo'lishi kerak, %d bor" % total)
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
			levels_before += Campaign.level_count(c) * Campaign.unlock_after(c)
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


# --- Sandiqlar va kunlik mukofot --------------------------------------------

func chests() -> Dictionary:
	return load_json("res://data/chests.json")


func test_chest_odds_and_rolls() -> void:
	var c := chests()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for kind in c.order:
		var sum := 0.0
		for o in Rewards.odds(c.chests[kind]):
			sum += float(o.percent)
		check(absf(sum - 100.0) < 0.01, "%s: ehtimollar yig'indisi 100%% emas" % kind)
		var counts := {}
		for i in 400:
			for r in Rewards.roll_chest(c.chests[kind], ["caravan", "healing"], rng):
				counts[r.type] = int(counts.get(r.type, 0)) + 1
		for d in c.chests[kind].drops:
			check(int(counts.get(d.type, 0)) > 0, "%s: %s hech tushmadi" % [kind, d.type])
	var rolls := Rewards.roll_chest(c.chests.gold, ["caravan"], rng)
	check(rolls.size() == int(c.chests.gold.rolls), "sandiqdan noto'g'ri sonda mukofot")


func test_daily_streak() -> void:
	var st := Rewards.daily_status("", 0, "2026-03-01", 7)
	check(st.can_claim and st.day == 0 and st.streak == 1, "birinchi kun noto'g'ri")
	st = Rewards.daily_status("2026-03-01", 1, "2026-03-01", 7)
	check(not st.can_claim, "bir kunda ikki marta olish mumkin bo'lmasligi kerak")
	st = Rewards.daily_status("2026-03-01", 1, "2026-03-02", 7)
	check(st.can_claim and st.day == 1 and st.streak == 2, "ketma-ket kun seriyani oshirishi kerak")
	st = Rewards.daily_status("2026-03-01", 5, "2026-03-04", 7)
	check(st.day == 0 and st.streak == 1, "kun o'tkazib yuborilsa seriya qaytadan boshlanishi kerak")
	st = Rewards.daily_status("2026-02-28", 7, "2026-03-01", 7)
	check(st.day == 0 and st.streak == 8, "7 kundan keyin tsikl qaytadan boshlanishi kerak")


func test_chest_store_flow() -> void:
	var c := chests()
	var path := "user://test_chest.json"
	var st := ProgressStore.new(path)
	var rng := RandomNumberGenerator.new()
	check(st.open_chest(c, "silver", ["caravan"], rng).is_empty(), "sandiqsiz ochildi")
	st.data.coins = 300
	check(st.buy_chest(c, "silver") and int(st.data.coins) == 0, "kumush sandiq sotilmadi")
	check(not st.buy_chest(c, "gold"), "la'lsiz oltin sandiq sotildi")
	var got := st.open_chest(c, "silver", ["caravan"], rng)
	check(got.size() == 2 and int(st.data.chests.silver) == 0, "sandiq ochilmadi yoki sarflanmadi")
	check(st.grant_star_milestones(c, 60) == 2 and st.grant_star_milestones(c, 70) == 0, "yulduz sovg'alari noto'g'ri")
	var r := st.claim_daily(c, "2026-03-01")
	check(not r.is_empty() and st.claim_daily(c, "2026-03-01").is_empty(), "kunlik mukofot noto'g'ri")
	var st2 := ProgressStore.new(path)
	st2.load_file()
	check(int(st2.data.chests.gold) == 2 and st2.data.daily_last == "2026-03-01", "sandiq/kunlik holat saqlanmadi")
	DirAccess.remove_absolute(path)


# --- Libos ------------------------------------------------------------------

func test_outfits() -> void:
	var d := load_json("res://data/outfits.json")
	var path := "user://test_outfit.json"
	var st := ProgressStore.new(path)
	check(not st.equip_outfit("temuriy"), "sotib olinmagan libos kiyildi")
	check(not st.buy_outfit(d, "temuriy"), "tangasiz sotildi")
	st.data.coins = 1000
	check(st.buy_outfit(d, "temuriy") and int(st.data.coins) == 200, "libos sotilmadi")
	check(not st.buy_outfit(d, "temuriy"), "libos ikki marta sotildi")
	check(not st.buy_outfit(d, "oltin"), "la'lsiz oltin libos sotildi")
	check(st.equip_outfit("temuriy"), "libos kiyilmadi")
	var st2 := ProgressStore.new(path)
	st2.load_file()
	check(st2.data.outfit == "temuriy" and "temuriy" in st2.data.outfits, "libos saqlanmadi")
	DirAccess.remove_absolute(path)
	var cols := Painter.outfit_colors(d.outfits.oltin)
	Painter.player_outfit = cols
	check(Painter.team_colors(0)[3] == cols[3] and Painter.team_colors(1) == Painter.TEAM_COLORS[1], "libos ranglari noto'g'ri qo'llandi")
	Painter.player_outfit = []


# --- Bozor ------------------------------------------------------------------

func test_market_products() -> void:
	var m := load_json("res://data/market.json")
	var path := "user://test_market.json"
	var st := ProgressStore.new(path)
	check(st.grant_product(m, "starter"), "boshlang'ich to'plam berilmadi")
	check(int(st.data.gems) == 200 and int(st.data.chests.gold) == 1 and "temuriy" in st.data.outfits, "to'plam tarkibi noto'g'ri")
	check(not st.grant_product(m, "starter"), "bir martalik to'plam ikki marta sotildi")
	check(st.buy_with_gems(m, "res_archer") and int(st.data.reserves.archer) == 100 and int(st.data.gems) == 140, "zaxira paketi sotilmadi")
	check(not st.buy_with_gems(m, "gems_s"), "IAP mahsulot la'lga sotildi")
	check(st.grant_product(m, "no_ads") and bool(st.data.no_ads), "reklamasiz yoqilmadi")
	for i in int(m.ad_gems.daily_limit):
		check(st.claim_ad_gems(m, "2026-04-01"), "reklama la'li berilmadi")
	check(not st.claim_ad_gems(m, "2026-04-01"), "reklama la'li chegarasi ishlamadi")
	check(st.take_reserve("archer", 5) == 5 and int(st.data.reserves.archer) == 95, "zaxira olinmadi")
	var st2 := ProgressStore.new(path)
	st2.load_file()
	check(int(st2.data.reserves.archer) == 95 and bool(st2.data.no_ads) and "starter" in st2.data.bought_once, "bozor holati saqlanmadi")
	DirAccess.remove_absolute(path)


func test_reserve_respects_pop_cap() -> void:
	var s := new_sim({"pop_cap": 8})
	check(s.call_reserve(0, "archer", 5) == 5, "zaxira chaqirilmadi")
	check(s.call_reserve(0, "archer", 5) == 3, "aholi chegarasi hisobga olinmadi")
	check(s.call_reserve(0, "cavalry", 5) == 0, "to'la qo'shinga zaxira qo'shildi")


# --- O'rgatish --------------------------------------------------------------

func test_tutorial_steps_progress() -> void:
	var c := camp()
	var hd := load_json("res://data/heroes.json")
	var bc := Campaign.battle_config(c, "chingiz_01#1", ai_params, 1)
	var s := BattleSim.new()
	s.setup(defs, bc.cfg, hd)
	var ctx := {"start_workers": 2, "step_time": 0.0}
	check(not TutorialLogic.step_done(0, s, ctx), "0-qadam darhol bajarilmasligi kerak")
	s.train(0, "worker")
	check(TutorialLogic.step_done(0, s, ctx), "ishchi yollash qadamni tugatmadi")
	s.teams[0].gold = 1000
	s.train(0, "swordsman")
	check(TutorialLogic.step_done(1, s, ctx), "qilichboz qadami tugamadi")
	ctx.step_time = 50.0
	check(TutorialLogic.step_done(2, s, ctx), "kutish qadami vaqt bo'yicha tugamadi")
	check(not TutorialLogic.step_done(3, s, ctx), "hujum bosilmasdan qadam o'tdi")
	s.set_stance(0, TeamState.Stance.ATTACK)
	check(TutorialLogic.step_done(3, s, ctx), "hujum qadami tugamadi")
	check(TutorialLogic.enemy_paused(1) and not TutorialLogic.enemy_paused(3), "dushman pauza qoidasi noto'g'ri")


# --- Saqlash slotlari -------------------------------------------------------

func test_save_slots() -> void:
	var path := "user://test_slots.json"
	var st := ProgressStore.new(path)
	check(st.data.slots.size() == 3, "3 ta slot bo'lishi kerak")
	st.create_slot(1, "hard")
	st.record_result("chingiz_01#1", 3, 50)
	check(int(st.data.slots[1].stars.get("chingiz_01#1", 0)) == 3, "yulduz aktiv slotga yozilmadi")
	check(st.data.slots[0].stars.is_empty(), "yulduz boshqa slotga tushib qoldi")
	st.select_slot(0)
	check(st.data.stars.is_empty() and int(st.data.coins) == 50, "slot almashganda yulduzlar/tangalar noto'g'ri")
	var st2 := ProgressStore.new(path)
	st2.load_file()
	check(int(st2.data.slots[1].stars.get("chingiz_01#1", 0)) == 3 and st2.data.slots[1].difficulty == "hard", "slot saqlanmadi")
	st2.select_slot(1)
	check(int(st2.data.stars.get("chingiz_01#1", 0)) == 3, "aktiv slot yulduzlari yuklanmadi")
	st2.delete_slot(1)
	check(not bool(st2.data.slots[1].used) and st2.data.slots[1].stars.is_empty(), "slot o'chirilmadi")
	# Eski formatdan ko'chirish
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "stars": {"chingiz_01#1": 2}, "coins": 9}))
	f.close()
	var st3 := ProgressStore.new(path)
	st3.load_file()
	check(int(st3.data.stars.get("chingiz_01#1", 0)) == 2 and bool(st3.data.slots[0].used), "eski progress 1-slotga ko'chirilmadi")
	DirAccess.remove_absolute(path)


func test_difficulty_scales_enemy() -> void:
	var c := camp()
	var n := Campaign.battle_config(c, "temur_03#2", ai_params, 1, "normal")
	var l := Campaign.battle_config(c, "temur_03#2", ai_params, 1, "legend")
	check(float(l.cfg.income_mult[1]) > float(n.cfg.income_mult[1]) and int(l.cfg.castle_hp[1]) > int(n.cfg.castle_hp[1]), "Afsona qiyinroq emas")


# --- Yutuqlar ---------------------------------------------------------------

func test_achievements() -> void:
	var ach := load_json("res://data/achievements.json")
	check(ach.order.size() >= 15, "kamida 15 ta yutuq bo'lishi kerak")
	for id in ach.order:
		check(ach.list.has(id), "%s: ta'rif yo'q" % id)
	var path := "user://test_ach.json"
	var st := ProgressStore.new(path)
	check(not Achievements.claimable(ach, st.data, "first_win"), "g'alabasiz yutuq ochildi")
	st.record_battle(true, 12)
	check(Achievements.metric(st.data, "kills") == 12, "o'ldirishlar sanalmadi")
	check(st.claim_achievement(ach, "first_win") and int(st.data.coins) == 50, "yutuq mukofoti berilmadi")
	check(not st.claim_achievement(ach, "first_win"), "yutuq ikki marta olindi")
	st.data.slots[1].stars = {"chingiz_01": 3, "chingiz_02": 2}
	check(Achievements.metric(st.data, "bosses") == 2, "bosslar boshqa slotdan sanalmadi")
	check(Achievements.claimable(ach, st.data, "heroes_4", 4) and not Achievements.claimable(ach, st.data, "heroes_4", 2), "qahramonlar yutug'i noto'g'ri")
	var st2 := ProgressStore.new(path)
	st2.load_file()
	check("first_win" in st2.data.ach_claimed and int(st2.data.stats.wins) == 1, "yutuqlar saqlanmadi")
	DirAccess.remove_absolute(path)


# --- Performance ---------------------------------------------------------------

func test_fast_nearest_matches_bruteforce() -> void:
	## Saralangan qidiruv indeksi oddiy to'liq aylanib chiqish bilan bir xil natija berishi kerak.
	var s := new_sim({"start_gold": 0})
	var kinds := ["swordsman", "spearman", "archer", "cavalry"]
	for i in 120:
		var u := s.spawn_unit(i % 2, kinds[i % 4])
		u.x = 600.0 + float((i * 7919) % 1600)
	s.set_stance(0, TeamState.Stance.ATTACK)
	s.set_stance(1, TeamState.Stance.ATTACK)
	var bad := 0
	for k in 90:
		s.step()
		s._build_index()
		for u in s.units:
			if not u.is_alive():
				continue
			var best: UnitState = null
			var best_d := INF
			for e in s.units:
				if e.team == u.team or not e.is_alive() or absf(e.x - u.x) > 650.0:
					continue
				if absf(e.x - u.x) < best_d:
					best_d = absf(e.x - u.x)
					best = e
			if s._nearest_enemy(u, u.x, 650.0) != best:
				bad += 1
	check(bad == 0, "tez qidiruv %d marta boshqa nishon tanladi" % bad)


func test_stress_150_units_step_fast() -> void:
	var s := new_sim({"start_gold": 0})
	var kinds := ["swordsman", "spearman", "archer", "cavalry"]
	for i in 150:
		var u := s.spawn_unit(i % 2, kinds[(i / 2) % 4])
		u.x += s.teams[i % 2].dir * float(i / 2) * 6.0
	s.set_stance(0, TeamState.Stance.ATTACK)
	s.set_stance(1, TeamState.Stance.ATTACK)
	var t0 := Time.get_ticks_msec()
	run(s, 60.0)
	var ms := Time.get_ticks_msec() - t0
	check(ms < 20000, "150 birlik 60 s sinov juda sekin: %d ms" % ms)


# --- Fathlar: 25 level/viloyat va eski saqlashlar ---------------------------------

func test_thousand_levels() -> void:
	var c := camp()
	var total := 0
	for cid in c.order:
		total += Campaign.all_levels(c, cid).size()
	check(Campaign.level_count(c) == 25, "har viloyatda 25 level bo'lishi kerak")
	check(total == 25 * 10 * c.order.size(), "jami %d level kutilgan: %d" % [250 * c.order.size(), total])
	var ids := {}
	for cid in c.order:
		for lv in Campaign.all_levels(c, cid):
			check(not ids.has(lv.id), "takror level ID: %s" % lv.id)
			ids[lv.id] = true
	# Eski (10 levelli) ID'lar hammasi hali ham mavjud
	for cid in c.order:
		for b in Campaign.regions(c, cid):
			for n in range(1, 10):
				check(ids.has("%s#%d" % [b.id, n]), "eski level yo'qoldi: %s#%d" % [b.id, n])


func test_old_save_keeps_progress() -> void:
	## 1.0 saqlashi: chingizda 4 viloyat (10 leveldan) zabt etilgan, jaloliddinda o'ynalgan,
	## yulduzlar yangi talabdan (75) kam. Hech narsa yopilib qolmasligi kerak.
	var c := camp()
	var st := {}
	for ri in 4:
		var b: String = Campaign.regions(c, "chingiz")[ri].id
		for n in range(1, 10):
			st["%s#%d" % [b, n]] = 1
		st[b] = 1
	var jb: String = Campaign.regions(c, "jaloliddin")[0].id
	st[jb + "#1"] = 2
	check(Campaign.total_stars(st) < 75, "test sharti: yulduz kam bo'lishi kerak")
	check(Campaign.campaign_unlocked(c, st, "jaloliddin"), "eski saqlashda ochilgan kampaniya yopilib qoldi")
	check(Campaign.level_unlocked(c, st, jb + "#2"), "jaloliddin keyingi leveli ochiq bo'lishi kerak")
	var b3: String = Campaign.regions(c, "chingiz")[3].id
	check(Campaign.region_unlocked(c, st, "chingiz", 4), "zabt etilgan viloyatdan keyingisi ochiq bo'lishi kerak")
	check(Campaign.level_unlocked(c, st, b3 + "#10"), "yangi #10 level #9 dan keyin ochiq bo'lishi kerak")
	check(not Campaign.level_unlocked(c, st, b3 + "#11"), "#11 hali yopiq bo'lishi kerak")
	# Yangi o'yinchi: jaloliddin faqat 2 viloyat + 75 yulduzdan keyin
	var fresh := {}
	check(not Campaign.campaign_unlocked(c, fresh, "jaloliddin"), "yangi o'yinchida jaloliddin yopiq")


func test_difficulty_smooth_in_25_region() -> void:
	var c := camp()
	for cid in c.order:
		for ri in Campaign.regions(c, cid).size():
			var lv: Array = Campaign.region_levels(c, cid, ri)
			for i in range(1, lv.size() - 1):
				var a := float(lv[i - 1].enemy_income)
				var b := float(lv[i].enemy_income)
				check(absf(b - a) < 0.05, "%s: keskin sakrash" % lv[i].id)


# --- Haftalik vazifalar --------------------------------------------------------

func test_weekly_selection() -> void:
	var w := load_json("res://data/weekly.json")
	var a := Weekly.tasks_for_week(w, Weekly.week_index("2026-11-16"))
	var b := Weekly.tasks_for_week(w, Weekly.week_index("2026-11-22"))   # yakshanba — o'sha hafta
	var c := Weekly.tasks_for_week(w, Weekly.week_index("2026-11-23"))   # keyingi dushanba
	check(a.size() == 5, "haftada 5 ta vazifa bo'lishi kerak")
	check(a == b, "bitta haftada vazifalar bir xil bo'lishi kerak")
	check(a != c, "yangi haftada vazifalar almashishi kerak")
	var metrics := {}
	for id in a:
		metrics[w.pool[id].metric] = true
	check(metrics.size() == 5, "bir hafta ichida ko'rsatkichlar takrorlanmasin")
	check(Weekly.days_left("2026-11-16") == 7 and Weekly.days_left("2026-11-22") == 1, "qolgan kunlar noto'g'ri")
	for wk in range(2900, 2960):
		for id in Weekly.tasks_for_week(w, wk):
			check(w.pool.has(id), "noma'lum vazifa")


func test_weekly_progress_and_claim() -> void:
	var w := load_json("res://data/weekly.json")
	var st := ProgressStore.new("user://test_weekly.json")
	st.data.stats = {"wins": 40, "kills": 900}   # o'tgan haftalardagi natijalar hisoblanmasligi kerak
	var day := "2026-11-16"
	Weekly.ensure_week(st.data, day)
	var tasks := Weekly.tasks_for_week(w, Weekly.week_index(day))
	var id: String = tasks[0]
	var t: Dictionary = w.pool[id]
	check(Weekly.progress_of(w, st.data, id) == 0, "hafta boshida progress 0 bo'lishi kerak")
	check(not st.claim_weekly(w, id, day), "bajarilmagan vazifa olinmasligi kerak")
	st.data.stats[t.metric] = int(st.data.stats.get(t.metric, 0)) + int(t.target)
	var coins := int(st.data.coins)
	var gems := int(st.data.gems)
	check(st.claim_weekly(w, id, day), "bajarilgan vazifa olinishi kerak")
	check(int(st.data.coins) > coins or int(st.data.gems) > gems or not st.data.chests.is_empty(), "mukofot berilmadi")
	check(not st.claim_weekly(w, id, day), "ikki marta olinmasligi kerak")
	check(not Weekly.bonus_ready(w, st.data, day), "bonus hali tayyor emas")
	for x in tasks:
		st.data.stats[w.pool[x].metric] = int(st.data.stats.get(w.pool[x].metric, 0)) + int(w.pool[x].target)
		st.claim_weekly(w, x, day)
	check(Weekly.bonus_ready(w, st.data, day), "hamma vazifadan keyin bonus tayyor")
	check(st.claim_weekly_bonus(w, day), "bonus olinishi kerak")
	check(not st.claim_weekly_bonus(w, day), "bonus ikki marta olinmasin")
	# Saqlash va qayta yuklash
	var st2 := ProgressStore.new("user://test_weekly.json")
	st2.load_file()
	check(bool(st2.data.weekly.bonus) and st2.data.weekly.claimed.size() == 5, "haftalik holat saqlanmadi")
	# Yangi hafta: hammasi yangilanadi
	Weekly.ensure_week(st2.data, "2026-11-23")
	check(st2.data.weekly.claimed.is_empty() and not bool(st2.data.weekly.bonus), "yangi haftada holat tozalanishi kerak")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_weekly.json"))


func test_weekly_counters_bumped() -> void:
	var st := ProgressStore.new("user://test_wcount.json")
	st.record_battle(true, 7)
	st.record_result("chingiz_01#1", 2, 10)
	st.record_result("chingiz_01#1", 3, 10)
	st.record_result("chingiz_01", 1, 10)
	st.record_wave(6, 10)
	check(int(st.data.stats.battles) == 1 and int(st.data.stats.wins) == 1, "jang hisoblagichi")
	check(int(st.data.stats.stars_gained) == 4, "yangi yulduzlar: 2+1+1 = 4, bor: %s" % st.data.stats.get("stars_gained"))
	check(int(st.data.stats.boss_wins) == 1, "boss g'alabasi hisoblanmadi")
	check(int(st.data.stats.waves) == 6, "to'lqinlar hisoblanmadi")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_wcount.json"))


# --- Turnir --------------------------------------------------------------------

func test_tournament_flow() -> void:
	var td := load_json("res://data/tournament.json")
	var hd := load_json("res://data/heroes.json")
	var p := {"coins": 0, "gems": 0, "chests": {}, "tournament": Tournament.default_state()}
	check(Tournament.rounds(td) == 8, "turnirda 8 raund")
	Tournament.start(p, "temur")
	var total := 0
	for i in 7:
		var r := Tournament.result(td, p, true)
		total += int(r.coins)
		check(not bool(r.finished) and int(p.tournament.round) == i + 1, "raund %d dan keyin davom etishi kerak" % (i + 1))
	var last := Tournament.result(td, p, true)
	check(bool(last.champion) and bool(last.finished), "8-raunddan keyin chempion")
	check(int(p.tournament.champion) == 1 and int(p.tournament.best) == 8, "chempionlik hisoblanmadi")
	check(int(p.gems) == 15 and int(p.chests.get("gold", 0)) == 1, "chempion mukofoti berilmadi")
	check(int(p.coins) == total + int(last.coins), "tangalar noto'g'ri")
	# Yangi turnir: 2-raundda yutqazish
	Tournament.start(p, "chingiz")
	Tournament.result(td, p, true)
	var lost := Tournament.result(td, p, false)
	check(bool(lost.finished) and not bool(p.tournament.active), "mag'lubiyat turnirni tugatishi kerak")
	check(int(p.tournament.best) == 8, "rekord kamaymasligi kerak")
	var again := Tournament.result(td, p, true)
	check(int(again.coins) == 0, "tugagan turnirda mukofot berilmasin")


func test_tournament_configs() -> void:
	var td := load_json("res://data/tournament.json")
	var hd := load_json("res://data/heroes.json")
	var prev := 0.0
	for h in ["chingiz", "jaloliddin", "temur", "boyazid"]:
		for i in 8:
			var bc := Tournament.battle_config(td, i, ai_params, hd, h, 5)
			check(str(bc.cfg.heroes[1]) != h and str(bc.cfg.heroes[1]) != "", "raqib sarkarda o'yinchi bilan bir xil")
			check(bool(hd[str(bc.cfg.heroes[1])].get("selectable", true)), "raqib tanlanadigan sarkarda bo'lishi kerak")
	# AI darajasi kamaymaydi; bir xil daraja ichida daromad*qal'a kamaymaydi
	var lvl := {"easy": 0, "normal": 1, "hard": 2}
	var prev_ai := 0
	for i in 8:
		var r: Dictionary = td.rounds[i]
		var a := int(lvl[str(r.ai)])
		var score := float(r.income) * float(r.castle)
		check(a >= prev_ai, "%d-raundda AI darajasi pasaydi" % (i + 1))
		if a == prev_ai:
			check(score >= prev, "%d-raund oldingisidan oson bo'lmasligi kerak" % (i + 1))
		prev_ai = a
		prev = score


func test_tournament_save_load() -> void:
	var st := ProgressStore.new("user://test_tourn.json")
	st.start_tournament("boyazid")
	st.tournament_result(load_json("res://data/tournament.json"), true)
	var st2 := ProgressStore.new("user://test_tourn.json")
	st2.load_file()
	check(bool(st2.data.tournament.active) and int(st2.data.tournament.round) == 1 and str(st2.data.tournament.hero) == "boyazid", "turnir holati saqlanmadi")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_tourn.json"))


# --- Bobur: To'p zarbasi --------------------------------------------------------------

func test_cannon_blasts_hit_and_push() -> void:
	var s := hero_sim("bobur")
	var h := s.hero_of(0)
	h.x = 1000.0
	var es := place_enemies(s, "swordsman", [1260.0, 1300.0, 1350.0, 1420.0])
	var far: UnitState = place_enemies(s, "swordsman", [2200.0])[0]
	var x0: Array = []
	for e in es:
		x0.append(e.x)
	s.teams[0].ability_cd = 0.0
	check(s.ability_targets(0) >= 3, "AI uchun nishonlar soni hisoblanmadi: %d" % s.ability_targets(0))
	check(s.use_ability(0), "maxsus kuch ishlamadi")
	var blasts := 0
	var pushed := 0
	for i in int(2.5 / BattleSim.STEP):
		var before: Array = []
		for e in es:
			before.append(e.x)
		s.step()
		for ev in s.pop_events():
			if ev.type == "cannon_blast":
				blasts += 1
				for k in es.size():
					if absf(es[k].x - float(before[k])) > 20.0:
						pushed += 1
	check(blasts == 3, "3 ta portlash kutilgan: %d" % blasts)
	var hurt := 0
	for i in es.size():
		if es[i].hp < es[i].max_hp or not es[i].is_alive():
			hurt += 1
	check(hurt >= 3, "portlash dushmanlarga tegmadi (%d)" % hurt)
	check(pushed >= 1, "dushmanlar itarilmadi")
	check(far.hp == far.max_hp, "uzoqdagi dushmanga tegmasligi kerak")


# --- Alp Arslon: Saljuq chopqini -----------------------------------------------------

func test_raid_summons_and_leaves() -> void:
	var s := hero_sim("alp")
	var h := s.hero_of(0)
	h.x = 1000.0
	place_enemies(s, "swordsman", [1300.0, 1350.0, 1400.0])
	var pop0 := s.teams[0].pop
	var n0 := s.alive_units(0).size()
	s.teams[0].ability_cd = 0.0
	check(s.ability_targets(0) >= 3, "AI uchun nishonlar soni: %d" % s.ability_targets(0))
	check(s.use_ability(0), "maxsus kuch ishlamadi")
	var summoned: Array = []
	for u in s.units:
		if u.team == 0 and u.life > 0.0:
			summoned.append(u)
	check(summoned.size() == 4, "4 ta otliq kamonchi chaqirilishi kerak: %d" % summoned.size())
	check(s.teams[0].pop == pop0, "chaqirilganlar aholi chegarasini egallamasligi kerak")
	for u in summoned:
		check(Painter.is_mounted(u) and u.is_ranged(), "chaqirilgan askar otliq kamonchi bo'lishi kerak")
	var lost0 := int(s.teams[0].stats.lost)
	var left := 0
	for i in int(16.5 / BattleSim.STEP):
		s.step()
		for ev in s.pop_events():
			if ev.type == "summon_leave":
				left += 1
	var still := 0
	for u in s.units:
		if u.team == 0 and u.is_alive() and u.life > 0.0:
			still += 1
	check(still == 0, "15 soniyadan keyin chaqirilganlar ketishi kerak")
	var killed_summons := 4 - left
	check(int(s.teams[0].stats.lost) - lost0 == killed_summons, "ketib qolganlar yo'qotish hisoblanmasligi kerak")


func test_fit_text() -> void:
	var font := ThemeDB.fallback_font
	var r := UITheme.fit_text(font, "Qisqa", 400.0, 15, 10)
	check(r[0] == "Qisqa" and int(r[1]) == 15, "qisqa matn o'zgarmasligi kerak")
	var long := "Джалаладдин Мангуберди Джалаладдин Мангуберди"
	var r2 := UITheme.fit_text(font, long, 90.0, 15, 10)
	check(int(r2[1]) == 10 and str(r2[0]).ends_with("…"), "uzun matn kichrayib, '…' bilan tugashi kerak")
	check(font.get_string_size(str(r2[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x <= 90.0, "matn kenglikka sig'ishi kerak")


# --- Yangi askarlar: miltiqchi va jangovar fil -------------------------------------

func test_new_units_unlock_by_stars() -> void:
	var c := camp()
	var none := Campaign.unlocked_units(defs, {})
	check(not ("musketeer" in none) and not ("elephant" in none), "boshida yangi askarlar yopiq bo'lishi kerak")
	var st := {}
	for lv in Campaign.all_levels(c, "chingiz").slice(0, 40):
		st[lv.id] = 3
	var some := Campaign.unlocked_units(defs, st)
	check("musketeer" in some and not ("elephant" in some), "120 yulduzda faqat miltiqchi ochiladi")
	for lv in Campaign.all_levels(c, "chingiz").slice(40, 90):
		st[lv.id] = 3
	check("elephant" in Campaign.unlocked_units(defs, st), "270 yulduzda fil ham ochiladi")
	# Kampaniyada dushman: Bobur kampaniyasida fil va miltiqchi, Chingizda yo'q
	var b := Campaign.battle_config(c, "bobur_09#7", ai_params, 1)
	check("elephant" in b.cfg.allowed[1], "Panipatda dushman fil ishlatadi")
	check(not ("elephant" in Campaign.battle_config(c, "bobur_05", ai_params, 1).cfg.allowed[1]), "Qandahorda fil bo'lmasligi kerak")
	var ch := Campaign.battle_config(c, "chingiz_05", ai_params, 1)
	check(not ("elephant" in ch.cfg.allowed[1]), "Chingiz kampaniyasida fil bo'lmasligi kerak")


func test_elephant_tramples() -> void:
	var s := new_sim({"start_units": [[], []]})
	var el := s.spawn_unit(0, "elephant")
	el.x = 1000.0
	var es := place_enemies(s, "swordsman", [1040.0, 1045.0, 1050.0, 1055.0])
	for e in es:
		e.stun = 5.0
	s.set_stance(0, TeamState.Stance.ATTACK)
	for i in int(2.0 / BattleSim.STEP):
		s.step()
		s.events.clear()
	var hurt := 0
	for e in es:
		if e.hp < e.max_hp:
			hurt += 1
	check(hurt >= 3, "fil bir zarbada bir nechta dushmanga tegishi kerak (%d)" % hurt)


func test_counters_new_units() -> void:
	## Teng narxli otryadlar: nayzachi filni, miltiqchi filni yengadi; otliq miltiqchini yengadi.
	check(squad_fight("spearman", "elephant") > 0.5, "nayzachi filni yengishi kerak")
	check(squad_fight("musketeer", "elephant") > 0.5, "miltiqchi filni yengishi kerak")
	check(squad_fight("cavalry", "musketeer") > 0.5, "otliq miltiqchini yengishi kerak")
	check(squad_fight("elephant", "swordsman") > 0.5, "fil qilichbozni yengishi kerak")


func squad_fight(a: String, b: String) -> float:
	var wins := 0.0
	for seed in 2:
		for side in 2:
			var s := BattleSim.new()
			s.setup(defs, {"seed": seed, "start_units": [[], []]})
			var ta := side
			var tb := 1 - side
			for k in int(1650.0 / float(defs[a].cost)):
				var u := s.spawn_unit(ta, a)
				u.x = 1600 - s.teams[ta].dir * (300 + k * 12)
			for k in int(1650.0 / float(defs[b].cost)):
				var u := s.spawn_unit(tb, b)
				u.x = 1600 - s.teams[tb].dir * (300 + k * 12)
			s.teams[0].stance = TeamState.Stance.ATTACK
			s.teams[1].stance = TeamState.Stance.ATTACK
			for i in int(120 / BattleSim.STEP):
				s.step()
				s.events.clear()
				if s.alive_units(0).is_empty() or s.alive_units(1).is_empty():
					break
			wins += 1.0 if s.army_value(ta) > s.army_value(tb) else 0.0
	return wins / 4.0


# --- Kunlik sinov --------------------------------------------------------------------

func test_daily_challenge_rules() -> void:
	var dc := load_json("res://data/daily_challenge.json")
	var hd := load_json("res://data/heroes.json")
	check(DailyChallenge.rule_id(dc, "2026-11-18") == DailyChallenge.rule_id(dc, "2026-11-18"), "bir kunda qoida bir xil")
	var seen := {}
	var prev := ""
	for i in 40:
		var date := Time.get_date_string_from_unix_time(1780000000 + i * 86400)
		var r := DailyChallenge.rule_id(dc, date)
		check(dc.rules.has(r), "noma'lum qoida")
		check(r != prev, "ketma-ket ikki kun bir xil qoida: %s" % date)
		prev = r
		seen[r] = true
	check(seen.size() == dc.rules.size(), "40 kunda hamma qoidalar chiqishi kerak")
	for rid in dc.rules:
		# Har bir qoida bilan jang quriladi va oxiriga yetadi
		var s := BattleSim.new()
		var date := ""
		for i in 60:
			var dd := Time.get_date_string_from_unix_time(1780000000 + i * 86400)
			if DailyChallenge.rule_id(dc, dd) == rid:
				date = dd
				break
		var bc := DailyChallenge.battle_config(dc, date, ai_params, hd, "temur", 7)
		s.setup(defs, bc.cfg, hd)
		if bool(dc.rules[rid].cfg.get("no_heroes", false)):
			check(s.hero_of(0) == null and s.hero_of(1) == null, "sarkardasiz qoidada sarkarda bo'lmasligi kerak")
		var ais := [AIController.new(0, ai_params.normal, 1), AIController.new(1, bc.ai, 2)]
		for k in int(900.0 / BattleSim.STEP):
			for a in ais:
				a.update(s, BattleSim.STEP)
			s.step()
			s.events.clear()
			if s.winner >= 0:
				break
		check(s.winner >= 0, "%s: jang 15 daqiqada tugamadi" % rid)


func test_daily_challenge_reward_once() -> void:
	var dc := load_json("res://data/daily_challenge.json")
	var p := {"coins": 0, "gems": 0, "chests": {}}
	check(not bool(DailyChallenge.record(dc, p, "2026-11-18", false).reward), "mag'lubiyatda mukofot yo'q")
	check(bool(DailyChallenge.record(dc, p, "2026-11-18", true).reward), "birinchi g'alabada mukofot")
	var c1 := int(p.coins)
	check(not bool(DailyChallenge.record(dc, p, "2026-11-18", true).reward) and int(p.coins) == c1, "bir kunda ikki marta mukofot berilmasin")
	check(bool(DailyChallenge.record(dc, p, "2026-11-19", true).reward), "ertasi kuni yana mukofot")
