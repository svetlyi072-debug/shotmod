extends SceneTree
## Проверка мода «Спидран-таймер»: режим «Вся игра» (забег от 1 уровня до финала, повтор уровня, сброс на первом
## уровне, рекорд забега, разница с рекордом, возобновление после выхода, забег не с 1 уровня) и режим «Один уровень».
## Запуск: node tools/godot_isolated.js --headless --script D:/ShotMOD/tools/test_speedrun.gd
## Код выхода 0 — всё хорошо. Данные игрока (сохранения, настройки, моды, рекорды) прячутся и возвращаются.

const MOD_ID := "speedrun_timer"

var fails := 0
var game
var mods
var hints: Array = []


func check(cond: bool, msg: String) -> void:
	print(("OK   " if cond else "FAIL ") + msg)
	if not cond:
		fails += 1


func frames(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame


## Узел скрипта мода (после mods.rescan() узел новый).
func timer_node():
	for node in mods._scripts:
		if is_instance_valid(node) and node.mod.id == MOD_ID:
			return node
	return null


func complete_level() -> void:
	var player = get_first_node_in_group("player")
	game.complete_level(player.power if player != null else 0)
	await frames(2)


func last_hint() -> String:
	return hints.back() if not hints.is_empty() else ""


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	game = root.get_node("Game")
	mods = root.get_node("Mods")
	var user_state = load("D:/ShotMOD/tools/user_state.gd")
	user_state.backup(mods)  # данные игрока (сохранения, настройки, моды, рекорды) спрятаны до конца проверки
	# Если проверка зависнет (ошибка внутри await), через 4 минуты вернуть данные игрока и выйти.
	create_timer(240.0, true, false, true).timeout.connect(func() -> void:
		print("ТАЙМАУТ: проверка зависла, данные игрока возвращены")
		user_state.restore(mods)
		quit(3))
	mods.extra_dirs.append("D:/ShotMOD/mods")
	await frames(2)
	mods.rescan()
	game.hint.connect(func(text: String) -> void: hints.append(text))

	var mod = mods.get_mod(MOD_ID)
	check(mod != null and mod.ok() and mod.has_scripts(), "мод найден, скрипт на месте")
	if mod == null:
		user_state.restore(mods)
		print("ИТОГ: мод не найден — собери его: node tools/build.js speedrun_timer")
		quit(1)
		return
	check(mod.api == 2 and mod.problems.is_empty() and mod.settings.size() == 2, "api 2, две настройки, проблем нет (%s)" % str(mod.problems))
	check(mods.get_setting(MOD_ID, "mode") == 0 and mods.get_setting(MOD_ID, "delta") == true, "по умолчанию: «Вся игра», разница с рекордом включена")
	mods.grant_script_consent(mod)
	mods.set_enabled(mod, true)
	await frames(2)
	var t = timer_node()
	check(t != null and t._mode == 0, "режим «Вся игра»")

	# --- Забег с первого уровня ---
	game.leave_campaign()
	game.game_completed = false
	game.start_new_game(1)
	await frames(60)
	check(t._run_active and t._run_full and t._run_level == 0, "забег начат с 1 уровня")
	check(t._run_time > 0.7 and t._run_time < 2.0, "таймер забега идёт: %.2f с за секунду игры" % t._run_time)
	check("уровень 1/34" in t._sub.text, "под таймером номер уровня (%s)" % t._sub.text.replace("\n", " | "))

	await complete_level()
	check(not t._running and last_hint().begins_with("Уровень 1:"), "уровень пройден, таймер стоит, подсказка с временем: «%s»" % last_hint())
	var stopped: float = t._run_time
	await frames(30)
	check(is_equal_approx(stopped, t._run_time), "пока идёт переход между уровнями, время не копится")

	game.go_to_level(1)
	await frames(40)
	check(t._run_time > stopped + 0.4 and t._time < 1.5 and t._run_time - t._time > 0.4, "2 уровень: забег продолжается (%.2f), время уровня с нуля (%.2f)" % [t._run_time, t._time])

	# --- Повтор уровня: забег не сбрасывается ---
	var before_retry: float = t._run_time
	current_scene.get_tree().reload_current_scene()
	await frames(40)
	check(t._run_time >= before_retry and t._time < 1.2, "повтор 2 уровня: забег продолжается (%.2f → %.2f), попытка с нуля (%.2f)" % [before_retry, t._run_time, t._time])

	# --- Первый уровень начинает забег заново ---
	game.go_to_level(0)
	await frames(30)
	check(t._run_time < 1.2 and t._splits.is_empty() and t._run_full, "на 1 уровне забег начинается заново (%.2f)" % t._run_time)

	# --- Полный забег: рекорд забега ---
	var last: int = game.level_count() - 1
	for i in range(0, last + 1):
		if i > 0:
			game.go_to_level(i)
		await frames(20)
		await complete_level()
	check(game.game_completed, "забег дошёл до финала")
	check(last_hint().begins_with("ЗАБЕГ ПРОЙДЕН") and "НОВЫЙ РЕКОРД" in last_hint(), "первый забег — рекорд: «%s»" % last_hint())
	var data: Dictionary = mods.load_mod_data(mod)
	var key := "|1"
	check(data.get("runs", {}).has(key) and data["runs"][key]["splits"].size() == game.level_count(), "рекорд забега и время каждого уровня (%d) сохранены" % data.get("runs", {}).get(key, {}).get("splits", []).size())
	check(not data.has("run"), "после финала незаконченного забега не осталось")

	# --- Разница с лучшим забегом ---
	game.game_completed = false
	game.start_new_game(1)
	await frames(30)
	await complete_level()
	check("к рекорду" in last_hint() and ("+" in last_hint() or "−" in last_hint()), "после уровня — разница с рекордом: «%s»" % last_hint())
	mods.set_setting(MOD_ID, "delta", false)
	check(t._delta == false, "настройка «Разница с лучшим забегом» выключена")
	game.start_new_game(1)
	await frames(30)
	await complete_level()
	check(not ("к рекорду" in last_hint()), "без настройки разницы нет: «%s»" % last_hint())
	mods.set_setting(MOD_ID, "delta", true)

	# --- Возобновление после выхода из игры ---
	game.start_new_game(1)
	await frames(20)
	await complete_level()
	game.go_to_level(1)
	await frames(50)
	var stored: float = float(mods.load_mod_data(mod).get("run", {}).get("time", -1.0))
	check(stored > 0.0 and int(mods.load_mod_data(mod).get("run", {}).get("level", -1)) == 1, "на 2 уровне забег записан на диск (время %.2f)" % stored)
	mods.rescan()  # «закрыли игру»: состояние скрипта потеряно
	await frames(2)
	t = timer_node()
	check(t != null and not t._run_active, "после перезапуска игры таймер пуст")
	game.go_to_level(1)  # «Продолжить»
	await frames(30)
	check(t._run_active and t._run_full and t._run_time >= stored and t._run_time < stored + 1.5, "«Продолжить»: забег возобновлён с %.2f (сейчас %.2f)" % [stored, t._run_time])

	# --- Забег не с первого уровня ---
	mods.rescan()
	await frames(2)
	t = timer_node()
	game.go_to_level(6)
	await frames(30)
	check(t._run_active and not t._run_full and "*" in t._label.text, "зашли с 7 уровня: таймер идёт, помечен «*», рекорд не засчитывается (%s)" % t._label.text)

	# --- Режим «Один уровень» ---
	mods.set_setting(MOD_ID, "mode", 1)
	check(t._mode == 1, "переключено на «Один уровень»")
	game.go_to_level(0)
	await frames(50)
	check(t._time > 0.6 and "01:" not in t._label.text and t._label.text == t._format(t._time), "режим уровня: таймер уровня (%s)" % t._label.text)
	await complete_level()
	check(last_hint().begins_with("Время "), "режим уровня: подсказка «Время …»: «%s»" % last_hint())
	mods.set_setting(MOD_ID, "mode", 0)

	user_state.restore(mods)
	print("ИТОГ: %s (%d ошибок)" % ["ВСЁ ХОРОШО" if fails == 0 else "ЕСТЬ ОШИБКИ", fails])
	quit(1 if fails else 0)
