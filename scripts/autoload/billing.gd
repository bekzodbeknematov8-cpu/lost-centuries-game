extends Node
## Ilova ichidagi xaridlar xizmati.
## Hozircha SINOV rejimi: haqiqiy Google Play Billing plagini 7-bosqichda ulanadi.
## Sinov rejimida tasdiq oynasi ko'rsatiladi va xarid muvaffaqiyatli deb hisoblanadi; haqiqiy pul olinmaydi.

var _layer: CanvasLayer
var _cb: Callable


func is_real() -> bool:
	return false


func price_text(product: Dictionary) -> String:
	## Haqiqiy rejimda mahalliy narx (masalan, so'mda) Play Billing'dan keladi.
	return "$%.2f" % float(product.get("usd", 0.0))


func purchase(product_id: String, product: Dictionary, cb: Callable) -> void:
	_cb = cb
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(bg)
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.theme = UITheme.make()
	_layer.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	var l := Label.new()
	l.text = tr("BILLING_TEST") % [tr(str(product.name)), price_text(product)]
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 22)
	v.add_child(l)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	for ok in [true, false]:
		var b := Button.new()
		b.text = tr("BUY") if ok else tr("CANCEL")
		b.custom_minimum_size = Vector2(170, 56)
		b.pressed.connect(_finish.bind(ok))
		row.add_child(b)
	if OS.get_cmdline_user_args().has("--auto_buy"):
		_finish.call_deferred(true)


func _finish(ok: bool) -> void:
	if is_instance_valid(_layer):
		_layer.queue_free()
	if _cb.is_valid():
		_cb.call(ok)
