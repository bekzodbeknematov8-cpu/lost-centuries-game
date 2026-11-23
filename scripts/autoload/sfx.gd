extends Node
## Ovoz effektlari va musiqa.
## Har bir ovozning bir nechta varianti bor (name_1.wav, name_2.wav ...);
## har safar tasodifiy variant va biroz farqli balandlik (pitch) bilan chalinadi.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const POOL_SIZE := 14
const MAX_SAME_PER_FRAME := 2

## Ovozlar balandligini tenglash (RMS o'lchovi asosida, maqsad ~0.15).
const GAIN := {
	"deny": 0.45, "click": 0.75, "coin": 0.8, "arrow_flesh": 0.8, "hit_flesh": 0.8,
	"castle_hit": 0.85, "horn_attack": 0.85, "horn_enemy": 0.85, "drum": 0.85,
	"arrow_metal": 1.2, "horse": 1.25, "pick": 1.25, "sword_clash": 1.2, "thunder": 1.25,
	"defeat": 1.15, "spear_hit": 1.1, "shout": 0.8,
}

var _streams: Dictionary = {}       ## nom -> [AudioStream]
var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _amb: AudioStreamPlayer        ## Fon shovqini (masalan, uzoqdagi jang), takrorlanadi
var _amb_level := 0.0
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
	_amb = AudioStreamPlayer.new()
	add_child(_amb)


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
	var vol := volume * float(GAIN.get(name, 1.0)) * float(GameState.settings.get("sfx_volume", 1.0))
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


func play_ambient(name: String) -> void:
	var path := "%s%s.wav" % [SFX_DIR, name]
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamWAV:
		var w := stream as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.get_length() * w.mix_rate)
	_amb.stream = stream
	_amb_level = 0.0
	_amb.volume_db = -80.0
	_amb.play()


func set_ambient_level(level: float) -> void:
	## 0..1 — jang qizg'inligi; keskin sakramasligi uchun silliqlanadi.
	_amb_level = lerpf(_amb_level, clampf(level, 0.0, 1.0), 0.05)
	var v := _amb_level * 0.6 * float(GameState.settings.get("sfx_volume", 1.0))
	_amb.volume_db = linear_to_db(maxf(v, 0.0001))


func stop_ambient() -> void:
	_amb.stop()


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
