extends Node
## Ovoz effektlari va musiqa.
## Har bir ovozning bir nechta varianti bor (name_1.wav, name_2.wav ...);
## har safar tasodifiy variant va biroz farqli balandlik (pitch) bilan chalinadi.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const POOL_SIZE := 14
const MAX_SAME_PER_FRAME := 2

var _streams: Dictionary = {}       ## nom -> [AudioStream]
var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _music_name := ""
var _played_this_frame: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)


func _process(_delta: float) -> void:
	_played_this_frame.clear()


func _variants(name: String) -> Array:
	if _streams.has(name):
		return _streams[name]
	var list := []
	for i in range(1, 9):
		var path := "%s%s_%d.wav" % [SFX_DIR, name, i]
		if ResourceLoader.exists(path):
			list.append(load(path))
		else:
			break
	if list.is_empty():
		var single := "%s%s.wav" % [SFX_DIR, name]
		if ResourceLoader.exists(single):
			list.append(load(single))
	_streams[name] = list
	return list


func play(name: String, volume := 1.0, pitch_jitter := 0.08) -> void:
	var vol := volume * float(GameState.settings.get("sfx_volume", 1.0))
	if vol <= 0.01:
		return
	var n := int(_played_this_frame.get(name, 0))
	if n >= MAX_SAME_PER_FRAME:
		return
	var list := _variants(name)
	if list.is_empty():
		return
	_played_this_frame[name] = n + 1
	var player := _free_player()
	player.stream = list[_rng.randi() % list.size()]
	player.pitch_scale = 1.0 + _rng.randf_range(-pitch_jitter, pitch_jitter)
	player.volume_db = linear_to_db(vol)
	player.play()


func _free_player() -> AudioStreamPlayer:
	for p in _pool:
		if not p.playing:
			return p
	# Hammasi band bo'lsa, eng eski ovozni almashtiramiz.
	var oldest := _pool[0]
	for p in _pool:
		if p.get_playback_position() > oldest.get_playback_position():
			oldest = p
	return oldest


func play_music(name: String) -> void:
	if _music_name == name and _music.playing:
		return
	_music_name = name
	var path := "%s%s.ogg" % [MUSIC_DIR, name]
	if not ResourceLoader.exists(path):
		_music.stop()
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_music.stream = stream
	update_music_volume()
	_music.play()


func stop_music() -> void:
	_music_name = ""
	_music.stop()


func update_music_volume() -> void:
	var v := float(GameState.settings.get("music_volume", 0.7))
	_music.volume_db = linear_to_db(maxf(v, 0.0001)) - 6.0
