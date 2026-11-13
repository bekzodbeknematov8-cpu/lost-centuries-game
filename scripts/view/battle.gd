extends Node2D
## Jang sahnasi: simulyatsiyani yuritadi, hamma narsani chizadi, ovoz va effektlarni chiqaradi.

const GROUND_Y := 468.0
const LANE_DEPTH := 70.0
const VIEW_H := 720.0

var sim := BattleSim.new()
var enemy_ai: AIController
var hud: Node
var cam: Camera2D
var t := 0.0
var _acc := 0.0
var _effects: Array[Dictionary] = []
var _shake := 0.0
var _noise := FastNoiseLite.new()
var _ended := false
var _cam_target_x := 0.0
var _follow := true
var auto_player: AIController = null   ## Avtomatik sinov/demo rejimi uchun
var level: Dictionary = {}              ## Kampaniya bosqichi (bo'sh bo'lsa erkin jang)


func _ready() -> void:
	_noise.seed = 7
	_noise.frequency = 0.004
	var diff := GameState.difficulty
	var ai_p: Dictionary = GameData.ai.get(diff, GameData.ai.easy)
	var my_hero := GameState.hero
	var enemy_hero := ""
	if GameState.level_id != "":
		var bc := Campaign.battle_config(GameData.campaigns, GameState.level_id, GameData.ai, randi())
		level = bc.level
		ai_p = bc.ai
		my_hero = str(bc.cfg.heroes[0])
		enemy_hero = str(bc.cfg.heroes[1])
		sim.setup(GameData.units, bc.cfg, GameData.heroes)
	else:
		var others: Array = GameData.heroes.keys().filter(func(h: String) -> bool: return h != my_hero and bool(GameData.heroes[h].get("selectable", true)))
		enemy_hero = others[randi() % others.size()]
		sim.setup(GameData.units, {
			"seed": randi(),
			"start_gold": 350,
			"income_mult": [1.0, float(ai_p.get("income_mult", 1.0))],
			"start_units": [["worker", "worker"], ["worker", "worker"]],
			"heroes": [my_hero, enemy_hero],
		}, GameData.heroes)
	enemy_ai = AIController.new(1, ai_p, randi())
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	cam.position = Vector2(sim.teams[0].castle_x + 500.0, VIEW_H * 0.5)
	_cam_target_x = cam.position.x
	hud = preload("res://scripts/ui/hud.gd").new()
	hud.battle = self
	add_child(hud)
	Sfx.play_music("battle")
	if OS.get_cmdline_user_args().has("--autoplay"):
		auto_player = AIController.new(0, GameData.ai.normal, 3)
	if not level.is_empty():
		var loc := TranslationServer.get_locale().substr(0, 2)
		var title: String = level.name.get(loc, level.name.en)
		if level.get("objective", "destroy") == "survive":
			hud.show_objective(tr("OBJ_SURVIVE") % int(level.survive))
		else:
			hud.show_objective(tr("OBJ_DESTROY"))
		_banner(title, 3.0)
	elif enemy_hero != "":
		_banner(tr(str(GameData.heroes[my_hero].name)) + "  VS  " + tr(str(GameData.heroes[enemy_hero].name)), 3.0)


func _banner(text: String, life: float) -> void:
	hud.show_banner(text, life)


func _process(delta: float) -> void:
	t += delta
	_acc += minf(delta, 0.1)
	while _acc >= BattleSim.STEP:
		_acc -= BattleSim.STEP
		enemy_ai.update(sim, BattleSim.STEP)
		if auto_player:
			auto_player.update(sim, BattleSim.STEP)
		sim.step()
		for e in sim.pop_events():
			_on_event(e)
	if auto_player and OS.get_cmdline_user_args().has("--control") and t > 25.0 and sim.controlled_unit() == null:
		sim.take_control(0)
		sim.control_dir = 1
		sim.control_attack = true
	if auto_player and OS.get_cmdline_user_args().has("--force_ability") and sim.ability_ready(0) and sim.ability_targets(0) >= 1:
		sim.use_ability(0)
		var h := sim.hero_of(0)
		if h:
			focus_x(h.x + 200.0)
	if OS.get_cmdline_user_args().has("--force_win") and sim.time > 6.0 and sim.winner < 0:
		sim.teams[1].castle_hp = 0.0
	_update_effects(delta)
	_update_camera(delta)
	if sim.winner >= 0 and not _ended:
		_ended = true
		Sfx.stop_music()
		Sfx.play("victory" if sim.winner == 0 else "defeat", 1.0, 0.0)
		var won := sim.winner == 0
		var result := {"won": won, "stars": 0, "coins": 0, "new_stars": 0, "level": level}
		if not level.is_empty():
			var castle := sim.teams[0].castle_hp / sim.teams[0].castle_max_hp
			result.stars = Campaign.compute_stars(level, won, castle, sim.time)
			result.coins = Campaign.coins_for(level, result.stars)
			result.new_stars = GameState.record_result(str(level.id), result.stars, result.coins)
		hud.show_end(won, result)
	queue_redraw()


# --- Kamera -------------------------------------------------------------------

func view_width() -> float:
	return get_viewport_rect().size.x


func _update_camera(delta: float) -> void:
	var cu := sim.controlled_unit()
	if cu:
		_cam_target_x = cu.x + cu.facing * 120.0
	var half := view_width() * 0.5
	_cam_target_x = clampf(_cam_target_x, half, BattleSim.WORLD_LEN - half)
	cam.position.x = lerpf(cam.position.x, _cam_target_x, minf(1.0, delta * 8.0))
	cam.position.x = clampf(cam.position.x, half, BattleSim.WORLD_LEN - half)
	_shake = maxf(0.0, _shake - delta * 2.5)
	cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * 10.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		_cam_target_x -= event.relative.x * 1.3
		cam.position.x = _cam_target_x
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cam_target_x -= 120.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cam_target_x += 120.0
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_A, KEY_LEFT: sim.control_dir = -1
			KEY_D, KEY_RIGHT: sim.control_dir = 1
			KEY_SPACE: sim.control_attack = true
	elif event is InputEventKey and not event.pressed:
		match event.keycode:
			KEY_A, KEY_LEFT, KEY_D, KEY_RIGHT: sim.control_dir = 0
			KEY_SPACE: sim.control_attack = false


func focus_x(x: float) -> void:
	_cam_target_x = x


# --- Hodisalar: ovoz va effektlar ----------------------------------------------

func _vol_at(x: float) -> float:
	var d := absf(x - cam.position.x)
	return clampf(1.15 - d / (view_width() * 0.85), 0.12, 1.0)


func _unit_y(lane: float) -> float:
	return GROUND_Y + 12.0 + lane * LANE_DEPTH


func _on_event(e: Dictionary) -> void:
	var x: float = e.get("x", 0.0)
	match e.type:
		"hit":
			var snd: String = e.sound
			Sfx.play(snd, _vol_at(x) * 0.8)
			var y := _unit_y(e.get("lane", 0.5)) - 45.0
			if snd in ["sword_clash", "arrow_metal", "sword_shield"]:
				_add_sparks(Vector2(x, y), 6 if snd == "sword_clash" else 4)
			else:
				_add_dust(Vector2(x, y + 20.0), 2)
		"death":
			Sfx.play("death", _vol_at(x) * 0.7)
			if e.unit == "cavalry":
				Sfx.play("horse", _vol_at(x) * 0.6)
			_add_dust(Vector2(x, _unit_y(e.get("lane", 0.5))), 5)
			if e.get("controlled", false):
				hud.on_control_lost()
		"shoot":
			Sfx.play("bow", _vol_at(x) * 0.45)
		"miss":
			Sfx.play("arrow_ground", _vol_at(x) * 0.3)
		"castle_hit":
			Sfx.play("castle_hit", _vol_at(x) * (0.5 if e.weapon == "arrow" else 0.8))
			if e.team == 0:
				_shake = minf(1.0, _shake + 0.15)
			_add_debris(Vector2(x, GROUND_Y - randf_range(40.0, 160.0)))
		"castle_destroyed":
			Sfx.play("castle_fall", 1.0, 0.0)
			_shake = 1.5
			for i in 12:
				_add_debris(Vector2(x + randf_range(-80, 80), GROUND_Y - randf_range(20.0, 200.0)))
			focus_x(x)
		"gold":
			if e.team == 0:
				Sfx.play("coin", _vol_at(x) * 0.35)
				_effects.append({"kind": "text", "pos": Vector2(x, GROUND_Y - 30.0), "t": 0.0, "life": 1.0, "text": "+%d" % e.amount, "color": Painter.GOLD})
		"pick":
			if absf(x - cam.position.x) < view_width() * 0.6:
				Sfx.play("pick", _vol_at(x) * 0.22)
		"trained":
			if e.team == 0:
				Sfx.play("ready", 0.5)
		"swing":
			Sfx.play("swing", _vol_at(x) * 0.6)
		"stance":
			if e.team == 0:
				match e.stance:
					TeamState.Stance.ATTACK: Sfx.play("horn_attack", 0.8, 0.02)
					TeamState.Stance.RETREAT: Sfx.play("horn_retreat", 0.7, 0.02)
					_: Sfx.play("drum", 0.7, 0.02)
			elif e.stance == TeamState.Stance.ATTACK:
				Sfx.play("horn_enemy", 0.55, 0.02)
		"control_kill":
			_shake = minf(1.0, _shake + 0.12)
		"ability":
			match str(e.id):
				"arrow_rain":
					Sfx.play("arrow_rain", 0.9, 0.03)
				"leap":
					Sfx.play("leap", 0.9, 0.03)
					_add_dust(Vector2(x, _unit_y(0.55)), 6)
				"lightning":
					Sfx.play("thunder", 1.0, 0.03)
					_effects.append({"kind": "lightning", "from": x, "to": float(e.to), "t": 0.0, "life": 0.6, "seed": randi()})
					_shake = minf(1.2, _shake + 0.5)
				"rally":
					Sfx.play("rally", 1.0, 0.0)
					_effects.append({"kind": "ring", "pos": Vector2(x, _unit_y(0.55) - 40.0), "t": 0.0, "life": 1.2, "color": Painter.GOLD})
			if e.team == 0:
				hud.show_banner(tr(str(GameData.heroes[e.hero].ability.name)) + "!", 1.6)
			else:
				hud.show_banner(tr(str(GameData.heroes[e.hero].name)) + ": " + tr(str(GameData.heroes[e.hero].ability.name)), 1.6)
		"leap_land":
			Sfx.play("castle_hit", _vol_at(x) * 0.7)
			_shake = minf(1.2, _shake + 0.6)
			_effects.append({"kind": "ring", "pos": Vector2(x, _unit_y(0.55)), "t": 0.0, "life": 0.6, "color": Color(0.85, 0.75, 0.55)})
			_add_dust(Vector2(x, _unit_y(0.55)), 10)
		"rain_tick":
			Sfx.play("arrow_flesh", _vol_at(x) * 0.5)
			for i in 9:
				_effects.append({"kind": "fall_arrow", "pos": Vector2(x + randf_range(-200, 200) - (1.0 if e.team == 0 else -1.0) * 110.0, GROUND_Y - 300.0 - randf() * 80.0), "t": 0.0, "life": 0.42, "dir": 1.0 if e.team == 0 else -1.0})
		"hero_down":
			Sfx.play("hero_down", 0.9, 0.0)
			hud.show_banner(tr("HERO_DOWN") % tr(str(GameData.heroes[e.hero].name)), 2.5)
		"hero_spawn":
			if sim.time > 1.0:
				Sfx.play("horn_attack" if e.team == 0 else "horn_enemy", 0.6, 0.02)


func _add_sparks(p: Vector2, n: int) -> void:
	for i in n:
		_effects.append({"kind": "spark", "pos": p, "vel": Vector2.from_angle(randf() * TAU) * randf_range(80, 220), "t": 0.0, "life": randf_range(0.15, 0.3)})


func _add_dust(p: Vector2, n: int) -> void:
	for i in n:
		_effects.append({"kind": "dust", "pos": p + Vector2(randf_range(-12, 12), 0), "vel": Vector2(randf_range(-30, 30), randf_range(-40, -10)), "t": 0.0, "life": randf_range(0.5, 0.9), "r": randf_range(6, 12)})


func _add_debris(p: Vector2) -> void:
	for i in 3:
		_effects.append({"kind": "debris", "pos": p, "vel": Vector2(randf_range(-120, 120), randf_range(-220, -60)), "t": 0.0, "life": 0.9, "r": randf_range(3, 6)})


func _update_effects(delta: float) -> void:
	var keep: Array[Dictionary] = []
	for fx in _effects:
		fx.t += delta
		if fx.t >= fx.life:
			continue
		match fx.kind:
			"spark", "dust":
				fx.pos += fx.vel * delta
			"debris":
				fx.vel.y += 600.0 * delta
				fx.pos += fx.vel * delta
			"text":
				fx.pos.y -= 40.0 * delta
			"fall_arrow":
				fx.pos += Vector2(fx.dir * 260.0, 900.0) * delta
		keep.append(fx)
	_effects = keep


# --- Chizish ------------------------------------------------------------------

func _draw() -> void:
	var vw := view_width()
	var left := cam.position.x - vw * 0.5 - 20.0
	var right := cam.position.x + vw * 0.5 + 20.0
	_draw_background(left, right)
	for team in sim.teams:
		Painter.draw_mine(self, team.mine_x, GROUND_Y + 30.0, t)
		Painter.draw_castle(self, team, GROUND_Y + 25.0, t)
	# Jangchilar chuqurlik bo'yicha tartiblanadi (orqadagilar avval).
	var visible: Array[UnitState] = []
	for u in sim.units:
		if u.x > left - 80.0 and u.x < right + 80.0:
			visible.append(u)
	visible.sort_custom(func(a: UnitState, b: UnitState) -> bool:
		if a.is_alive() != b.is_alive():
			return not a.is_alive()
		return a.lane < b.lane)
	for u in visible:
		var pos := Vector2(u.x, _unit_y(u.lane))
		# Soya
		draw_set_transform(pos, 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, 30.0 if u.type == "cavalry" else 16.0, Color(0, 0, 0, 0.18))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var sc := 1.2 if u.hero else 1.0
		if u.is_alive() and sim.teams[u.team].buff_time > 0.0:
			draw_set_transform(pos, 0.0, Vector2(1.0, 0.3))
			draw_arc(Vector2.ZERO, 26.0, 0, TAU, 24, Color(1, 0.85, 0.3, 0.5 + 0.3 * sin(t * 8.0)), 4.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		Painter.draw_unit(self, u, pos, sc, t)
		if u.hero and u.is_alive():
			var font := ThemeDB.fallback_font
			var name := tr(str(u.def.name))
			var col := Color(0.75, 0.88, 1.0) if u.team == 0 else Color(1.0, 0.7, 0.65)
			draw_string_outline(font, pos + Vector2(-110, -150), name, HORIZONTAL_ALIGNMENT_CENTER, 220, 16, 4, Color(0, 0, 0, 0.7))
			draw_string(font, pos + Vector2(-110, -150), name, HORIZONTAL_ALIGNMENT_CENTER, 220, 16, col)
		if u.is_alive() and (u.hp < u.max_hp or u.hero):
			var top := (-140.0 if u.hero else (-112.0 if Painter.is_mounted(u) else -98.0))
			var w := 54.0 if u.hero else 34.0
			draw_rect(Rect2(pos.x - w * 0.5, pos.y + top, w, 5), Color(0, 0, 0, 0.5))
			var col := Color(0.3, 0.85, 0.35) if u.team == 0 else Color(0.95, 0.3, 0.25)
			draw_rect(Rect2(pos.x - w * 0.5, pos.y + top, w * u.hp / u.max_hp, 5), col)
	for p in sim.projectiles:
		Painter.draw_projectile(self, p, GROUND_Y + 50.0)
	_draw_effects()


func _draw_background(left: float, right: float) -> void:
	var cx := cam.position.x
	# Osmon
	var sky_top := Color(0.98, 0.72, 0.42)
	var sky_bot := Color(1.0, 0.9, 0.68)
	draw_polygon(PackedVector2Array([Vector2(left, -50), Vector2(right, -50), Vector2(right, GROUND_Y), Vector2(left, GROUND_Y)]),
		PackedColorArray([sky_top, sky_top, sky_bot, sky_bot]))
	# Quyosh
	var sun := Vector2(cx + 260.0 - cx * 0.08, 170.0)
	draw_circle(sun, 70.0, Color(1, 0.95, 0.75, 0.5))
	draw_circle(sun, 52.0, Color(1, 0.96, 0.82))
	# Uzoq tog'lar (sekin harakatlanadi - parallaks)
	_draw_hills(left, right, 0.85, GROUND_Y - 170.0, 140.0, Color(0.84, 0.6, 0.5), 0.0)
	_draw_hills(left, right, 0.65, GROUND_Y - 80.0, 90.0, Color(0.72, 0.5, 0.38), 500.0)
	_draw_hills(left, right, 0.4, GROUND_Y - 20.0, 50.0, Color(0.6, 0.48, 0.3), 1300.0)
	# Yer
	draw_rect(Rect2(left, GROUND_Y - 5.0, right - left, VIEW_H - GROUND_Y + 60.0), Color(0.63, 0.55, 0.33))
	draw_rect(Rect2(left, GROUND_Y + 95.0, right - left, VIEW_H), Color(0.56, 0.48, 0.28))
	# O't va toshlar
	var start := int(floor(left / 37.0))
	var end := int(ceil(right / 37.0))
	for i in range(start, end):
		var h := absi(i * 7919) % 100
		var gx := i * 37.0 + (h % 17)
		var gy := GROUND_Y + 5.0 + float(h) * 1.4
		if h % 3 == 0:
			draw_line(Vector2(gx, gy), Vector2(gx - 4, gy - 10), Color(0.45, 0.48, 0.22), 2.0)
			draw_line(Vector2(gx, gy), Vector2(gx + 3, gy - 12), Color(0.5, 0.52, 0.25), 2.0)
		elif h % 7 == 0:
			draw_circle(Vector2(gx, gy), 4.0, Color(0.5, 0.45, 0.38))


func _draw_hills(left: float, right: float, factor: float, base_y: float, amp: float, col: Color, seed_off: float) -> void:
	var cx := cam.position.x
	var pts := PackedVector2Array()
	pts.append(Vector2(left, GROUND_Y + 5.0))
	var x := left
	while x <= right + 40.0:
		var m := x - cx * factor + seed_off
		var n := _noise.get_noise_1d(m) * 0.7 + _noise.get_noise_1d(m * 3.1) * 0.3
		pts.append(Vector2(x, base_y - (n + 0.5) * amp))
		x += 30.0
	pts.append(Vector2(right + 40.0, GROUND_Y + 5.0))
	draw_colored_polygon(pts, col)


func _draw_effects() -> void:
	var font := ThemeDB.fallback_font
	for fx in _effects:
		var k: float = fx.t / fx.life
		match fx.kind:
			"spark":
				var v: Vector2 = fx.vel
				draw_line(fx.pos, fx.pos - v * 0.04, Color(1, 0.9, 0.4, 1.0 - k), 2.0)
			"dust":
				draw_circle(fx.pos, fx.r * (1.0 + k), Color(0.75, 0.68, 0.55, 0.45 * (1.0 - k)))
			"debris":
				draw_circle(fx.pos, fx.r, Color(0.55, 0.48, 0.4, 1.0 - k))
			"fall_arrow":
				var d := Vector2(fx.dir * 260.0, 900.0).normalized()
				draw_line(fx.pos - d * 22.0, fx.pos, Painter.WOOD.lightened(0.2), 2.0)
				draw_line(fx.pos - d * 22.0, fx.pos - d * 16.0 + d.orthogonal() * 4.0, Color(0.95, 0.95, 0.9), 1.5)
			"ring":
				var rc: Color = fx.color
				rc.a = 1.0 - k
				draw_set_transform(fx.pos, 0.0, Vector2(1.0, 0.35))
				draw_arc(Vector2.ZERO, 30.0 + k * 220.0, 0, TAU, 40, rc, 6.0 * (1.0 - k) + 1.0)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"lightning":
				var rng := RandomNumberGenerator.new()
				rng.seed = fx.seed + int(fx.t * 20.0)
				var pts := PackedVector2Array()
				var n := 14
				for i in n + 1:
					var px: float = lerpf(fx.from, fx.to, float(i) / n)
					pts.append(Vector2(px, _unit_y(0.55) - 60.0 + rng.randf_range(-35, 35)))
				draw_polyline(pts, Color(1, 1, 0.8, 1.0 - k), 7.0)
				draw_polyline(pts, Color(0.6, 0.8, 1.0, 0.8 * (1.0 - k)), 3.0)
				if k < 0.25:
					var vw := view_width()
					draw_rect(Rect2(cam.position.x - vw, 0, vw * 2, VIEW_H), Color(1, 1, 1, 0.25 * (1.0 - k * 4.0)))
			"text":
				var c: Color = fx.color
				c.a = 1.0 - k
				draw_string_outline(font, fx.pos, fx.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 22, 4, Color(0, 0, 0, 0.6 * (1.0 - k)))
				draw_string(font, fx.pos, fx.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 22, c)
