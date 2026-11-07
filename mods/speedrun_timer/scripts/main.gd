extends ModScript
## «Спидран-таймер»: время прохождения уровня в углу экрана, рекорды сохраняются между запусками.

var _time := 0.0
var _running := false
var _best := {}
var _layer: CanvasLayer
var _label: Label


func _mod_ready() -> void:
	_best = load_data().get("best", {})
	_layer = CanvasLayer.new()
	_layer.layer = 5
	add_child(_layer)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_label.offset_right = -16.0
	_label.offset_bottom = -52.0
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	_layer.add_child(_label)


func _level_started(_level) -> void:
	_time = 0.0
	_running = true


func _process(delta: float) -> void:
	var level = get_level()
	_layer.visible = level != null
	if level == null:
		return
	if _running and not Game.is_game_over:
		_time += delta
	var best = _best.get(_key(level), null)
	_label.text = _format(_time) + ("\nрекорд " + _format(float(best)) if best != null else "")


func _level_completed() -> void:
	if not _running:
		return
	_running = false
	var level = get_level()
	if level == null:
		return
	var key := _key(level)
	var best = _best.get(key, null)
	if best == null or _time < float(best):
		_best[key] = _time
		save_data({"best": _best})
		hint("Время %s — НОВЫЙ РЕКОРД!" % _format(_time))
	else:
		hint("Время %s (рекорд %s)" % [_format(_time), _format(float(best))])


func _player_died() -> void:
	_running = false


## Ключ рекорда: кампания, название уровня и сложность.
func _key(level) -> String:
	return "%s|%s|%d" % [Game.campaign_id, level.title, Game.difficulty]


func _format(seconds: float) -> String:
	var whole := int(seconds)
	return "%02d:%02d.%02d" % [whole / 60, whole % 60, int((seconds - whole) * 100.0)]
