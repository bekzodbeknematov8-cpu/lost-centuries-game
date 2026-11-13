extends Node
## Mukofotli reklama xizmati.
## Hozircha SINOV rejimi: haqiqiy AdMob plagini 7-bosqichda ulanadi. Sinov rejimida
## 3 soniyalik "Reklama (sinov)" oynasi ko'rsatiladi va mukofot beriladi.
## Reklama har doim ixtiyoriy: o'yinchi o'zi tugmani bosgandagina ko'rsatiladi.

signal finished(rewarded: bool)

const MOCK_SECONDS := 3.0

var _layer: CanvasLayer
var _label: Label
var _left := 0.0
var _cb: Callable


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func is_real() -> bool:
	return false


func show_rewarded(cb: Callable) -> void:
	_cb = cb
	_left = MOCK_SECONDS
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(bg)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 32)
	_layer.add_child(_label)
	set_process(true)


func _process(delta: float) -> void:
	_left -= delta
	_label.text = tr("AD_MOCK") % maxi(1, ceili(_left))
	if _left <= 0.0:
		set_process(false)
		_layer.queue_free()
		finished.emit(true)
		if _cb.is_valid():
			_cb.call(true)
