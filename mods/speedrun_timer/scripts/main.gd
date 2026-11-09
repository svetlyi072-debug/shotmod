extends ModScript
## «Спидран-таймер»: время в углу экрана, рекорды сохраняются между запусками.
## Настройки (меню «Моды» → этот мод):
##   mode  — «Вся игра» (по умолчанию): один таймер на весь забег от 1 уровня до финала, разница с лучшим забегом
##           после каждого уровня, рекорд забега; или «Один уровень»: таймер каждого уровня и рекорд уровня;
##   delta — показывать разницу с лучшим забегом.
## Требует игру с API модов 2 (ShootIn 1.1.0 и новее).

const MODE_RUN := 0
const MODE_LEVEL := 1

## Всё, что запоминается между запусками (save_data):
##   "best" — рекорды уровней (режим «Один уровень»): ключ «кампания|уровень|сложность» → секунды;
##   "runs" — рекорды забегов: ключ «кампания|сложность» → {"total": секунды, "splits": [время на момент
##            прохождения каждого уровня]};
##   "run"  — незаконченный забег, чтобы «Продолжить» не сбрасывал таймер: {"key", "level", "time", "full", "splits"}.
var _data := {}
var _mode := MODE_RUN
var _delta := true

## Время текущей попытки уровня.
var _time := 0.0
## Забег: накопленное время, ключ, номер уровня, с 1 уровня ли начат, время на момент прохождения уровней.
var _run_active := false
var _run_time := 0.0
var _run_key := ""
var _run_level := -1
var _run_full := false
var _splits: Array = []
## Таймер идёт (уровень начат и не пройден).
var _running := false

var _layer: CanvasLayer
var _label: Label
var _sub: Label


func _mod_ready() -> void:
	_data = load_data()
	if not _data.get("best") is Dictionary:
		_data["best"] = {}
	if not _data.get("runs") is Dictionary:
		_data["runs"] = {}
	_apply_settings()
	_layer = CanvasLayer.new()
	_layer.layer = 5
	add_child(_layer)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.offset_right = -16.0
	box.offset_bottom = -52.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(box)
	_label = _make_label(28)
	box.add_child(_label)
	_sub = _make_label(16)
	box.add_child(_sub)


func _make_label(size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6 if size > 20 else 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _setting_changed(_id: String, _value) -> void:
	_apply_settings()


func _apply_settings() -> void:
	_mode = int(get_setting("mode"))
	_delta = bool(get_setting("delta"))


# --- Ход игры ------------------------------------------------------------------------------------

func _level_started(_level) -> void:
	_time = 0.0
	_running = true
	if _mode == MODE_LEVEL:
		return
	var index: int = Game.level_index
	var key := _key_run()
	if index == 0:
		# Первый уровень: забег начинается заново (и когда начали игру, и когда проиграли на нём и жмут R).
		_start_run(key, 0.0, true, [])
	elif _run_active and _run_key == key and (index == _run_level or index == _run_level + 1):
		pass  # тот же забег: следующий уровень или повторная попытка этого — время идёт дальше
	else:
		var saved = _data.get("run", null)
		if saved is Dictionary and saved.get("key", "") == key and int(saved.get("level", -1)) == index:
			# «Продолжить» после выхода из игры: забег продолжается с того же времени.
			_start_run(key, float(saved.get("time", 0.0)), bool(saved.get("full", false)), saved.get("splits", []))
		else:
			_start_run(key, 0.0, false, [])  # зашли не с первого уровня — рекорд забега не засчитывается
	_run_level = index
	_save_run()


func _start_run(key: String, time: float, full: bool, splits: Array) -> void:
	_run_active = true
	_run_key = key
	_run_time = time
	_run_full = full
	_splits = splits.duplicate()


func _process(delta: float) -> void:
	var level = get_level()
	_layer.visible = level != null
	if level == null:
		return
	# Время считаем настоящими секундами: замедление времени другим модом (например, «Финальный удар») таймер не обманывает.
	var real := delta / maxf(Engine.time_scale, 0.01)
	if _running:
		if _mode == MODE_LEVEL:
			if not Game.is_game_over:
				_time += real
		else:
			_time += real
			_run_time += real  # идёт и на экране смерти: потерянное время входит в забег
	if _mode == MODE_LEVEL:
		_show_level_mode(level)
	else:
		_show_run_mode()


func _show_level_mode(level) -> void:
	var best = _data["best"].get(_key_level(level), null)
	_label.text = _format(_time)
	_sub.text = "рекорд " + _format(float(best)) if best != null else ""


func _show_run_mode() -> void:
	_label.text = _format(_run_time) + ("" if _run_full else " *")
	var lines: Array[String] = ["уровень %d/%d  %s" % [Game.level_index + 1, Game.level_count(), _format(_time)]]
	var best = _best_run()
	if _run_full and not best.is_empty():
		lines.append("рекорд забега " + _format(float(best.get("total", 0.0))))
	elif not _run_full:
		lines.append("* забег не с 1 уровня — без рекорда")
	_sub.text = "\n".join(lines)


func _level_completed() -> void:
	if not _running:
		return
	_running = false
	var level = get_level()
	if level == null:
		return
	if _mode == MODE_LEVEL:
		_finish_level_mode(level)
	else:
		_finish_run_mode()


func _finish_level_mode(level) -> void:
	var key := _key_level(level)
	var best = _data["best"].get(key, null)
	if best == null or _time < float(best):
		_data["best"][key] = _time
		save_data(_data)
		hint("Время %s — НОВЫЙ РЕКОРД!" % _format(_time))
	else:
		hint("Время %s (рекорд %s)" % [_format(_time), _format(float(best))])


func _finish_run_mode() -> void:
	var index: int = Game.level_index
	_splits.resize(index + 1)
	_splits[index] = _run_time
	var best := _best_run()
	var text := "Уровень %d: %s · забег %s" % [index + 1, _format(_time), _format(_run_time)]
	var best_splits: Array = best.get("splits", [])
	if _delta and _run_full and index < best_splits.size() and best_splits[index] != null:
		var diff: float = _run_time - float(best_splits[index])
		text += " (%s к рекорду)" % _signed(diff)
	if Game.game_completed:
		# Последний уровень: забег закончен.
		var total := _run_time
		var old_total = best.get("total", null)
		if _run_full and (old_total == null or total < float(old_total)):
			_data["runs"][_run_key] = {"total": total, "splits": _splits}
			text = "ЗАБЕГ ПРОЙДЕН: %s — НОВЫЙ РЕКОРД!" % _format(total)
		elif _run_full:
			text = "ЗАБЕГ ПРОЙДЕН: %s (рекорд %s)" % [_format(total), _format(float(old_total))]
		else:
			text = "Игра пройдена: %s (забег не с 1 уровня — рекорд не засчитан)" % _format(total)
		_run_active = false
		_data.erase("run")
		save_data(_data)
	else:
		_save_run()
	hint(text)


func _player_died() -> void:
	if _mode == MODE_LEVEL:
		_running = false


# --- Данные ------------------------------------------------------------------------------------------

func _save_run() -> void:
	_data["run"] = {"key": _run_key, "level": _run_level, "time": _run_time, "full": _run_full, "splits": _splits}
	save_data(_data)


func _best_run() -> Dictionary:
	var best = _data["runs"].get(_run_key if _run_key != "" else _key_run(), null)
	return best if best is Dictionary else {}


## Ключ рекорда забега: кампания и сложность.
func _key_run() -> String:
	return "%s|%d" % [Game.campaign_id, Game.difficulty]


## Ключ рекорда уровня: кампания, название уровня и сложность.
func _key_level(level) -> String:
	return "%s|%s|%d" % [Game.campaign_id, level.title, Game.difficulty]


func _format(seconds: float) -> String:
	var whole := int(seconds)
	if whole >= 3600:
		return "%d:%02d:%02d.%02d" % [whole / 3600, (whole / 60) % 60, whole % 60, int((seconds - whole) * 100.0)]
	return "%02d:%02d.%02d" % [whole / 60, whole % 60, int((seconds - whole) * 100.0)]


## Разница со знаком: «+3.20» (медленнее рекорда) или «−1.50» (быстрее).
func _signed(diff: float) -> String:
	var seconds := absf(diff)
	var whole := int(seconds)
	var text := "%d.%02d" % [whole, int((seconds - whole) * 100.0)]
	if whole >= 60:
		text = "%d:%02d.%02d" % [whole / 60, whole % 60, int((seconds - whole) * 100.0)]
	return ("+" if diff >= 0.0 else "−") + text
