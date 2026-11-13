extends Node
## Avtomatik sinov uchun yordamchi: skrinshotlar olish va o'yinni o'zi o'ynatish.
## Faqat buyruq qatori argumentlari berilganda ishlaydi, oddiy o'yinchiga ta'sir qilmaydi:
##   godot --path . -- --scene=res://scenes/battle.tscn --diff=normal --autoplay \
##         --shots=/tmp/out --times=2,10,30 --speed=4

var _shots_dir := ""
var _times: Array[float] = []
var _elapsed := 0.0
var _idx := 0


func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var parts := a.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	if args.is_empty():
		set_process(false)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	if args.has("diff"):
		GameState.difficulty = args.diff
	if args.has("level"):
		GameState.level_id = args.level
	if args.has("hero"):
		GameState.hero = args.hero
	if args.has("locale"):
		GameState.set_locale(args.locale)
	if args.has("speed"):
		Engine.time_scale = float(args.speed)
	if args.has("shots"):
		_shots_dir = args.shots
		DirAccess.make_dir_recursive_absolute(_shots_dir)
		for t in str(args.get("times", "3")).split(","):
			_times.append(float(t))
	if args.has("scene"):
		get_tree().change_scene_to_file.call_deferred(args.scene)
	if not _times.is_empty() or args.has("quit_after"):
		if args.has("quit_after"):
			_times.append(float(args.quit_after))


func _process(delta: float) -> void:
	_elapsed += delta
	if _idx >= _times.size() or _elapsed < _times[_idx]:
		return
	_idx += 1
	if _shots_dir != "":
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/shot_%02d.png" % [_shots_dir, _idx])
		print("SHOT ", _idx, " t=", snappedf(_elapsed, 0.1))
	if _idx >= _times.size():
		get_tree().quit()
