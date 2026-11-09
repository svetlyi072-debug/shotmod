extends SceneTree
## Проверка мода «Хардкорный режим» в настоящей игре: настройки (чтение, запись, проверка описания),
## фиксация сложности, смерть = конец забега, ультра-хардкор и «в финале убить всех врагов».
## Запуск: godot --headless --path D:/shootin --script D:/ShotMOD/tools/test_hardcore_mode.gd
## Код выхода 0 — всё хорошо. Сохранения и настройки игрока возвращаются на место.

const MOD_ID := "hardcore_mode"

var fails := 0
var game
var mods


func check(cond: bool, msg: String) -> void:
	print(("OK   " if cond else "FAIL ") + msg)
	if not cond:
		fails += 1


## Физический и обычный кадр: события ввода и отложенные вызовы выполняются между ними.
func frames(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame


func open_level(index: int, difficulty: int = 1):
	game.leave_campaign()
	game.difficulty = difficulty
	game.game_completed = false  # прошлая проверка могла «пройти игру»
	game.go_to_level(index)
	await frames(30)
	return get_first_node_in_group("player")


func press_restart() -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = &"restart"
		event.pressed = pressed
		Input.parse_input_event(event)


func hud():
	return current_scene.get_node("HUD")


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	game = root.get_node("Game")
	mods = root.get_node("Mods")
	_save_user_files()
	seed(11)
	mods.extra_dirs.append("D:/ShotMOD/mods")
	await frames(2)
	mods.rescan()

	# --- Описание мода и настройки ---
	var mod = mods.get_mod(MOD_ID)
	check(mod != null and mod.ok() and mod.has_scripts(), "мод найден, скрипт на месте")
	if mod == null:
		print("ИТОГ: мод не найден — собери его: node tools/build.js hardcore_mode")
		quit(1)
		return
	check(mod.api == 2 and mod.problems.is_empty(), "api 2, проблем нет (%s)" % str(mod.problems))
	check(mod.settings.size() == 3, "в моде три настройки (%d)" % mod.settings.size())
	check(mods.get_setting(MOD_ID, "difficulty") == 0, "по умолчанию сложность — «Сложная» (вариант 0)")
	check(mods.get_setting(MOD_ID, "final_clear") == false and mods.get_setting(MOD_ID, "ultra") == false, "финал и ультра по умолчанию выключены")
	check(mods.get_setting(MOD_ID, "нет_такой") == null, "неизвестная настройка даёт null")
	mods.set_setting(MOD_ID, "difficulty", 99)
	check(mods.get_setting(MOD_ID, "difficulty") == 3, "значение вне диапазона приводится к ближайшему допустимому")
	mods.set_setting(MOD_ID, "ultra", true)
	mods._load_settings()
	check(mods.get_setting(MOD_ID, "ultra") == true and mods.get_setting(MOD_ID, "difficulty") == 3, "выбранное запоминается в файле и читается заново")
	mods.set_setting(MOD_ID, "ultra", false)
	mods.set_setting(MOD_ID, "difficulty", 0)

	await _test_bad_settings()

	# --- Включение ---
	mods.grant_script_consent(mod)
	mods.set_enabled(mod, true)
	await frames(2)
	check(mods.permadeath_active(), "включённый мод включил «смерть — конец забега»")
	check(mods.forced_difficulty() == 2, "сложность зафиксирована: «Сложная»")

	# --- Сложность ---
	game.start_new_game(0)
	await frames(30)
	check(game.difficulty == 2 and not game.player_has_shield(), "новая игра на «Лёгкой» стала «Сложной», щита нет")
	mods.set_setting(MOD_ID, "difficulty", 1)
	check(mods.forced_difficulty() == 1, "смена настройки сразу меняет фиксацию (_setting_changed)")
	game.start_new_game(0)
	await frames(30)
	check(game.difficulty == 1 and game.player_has_shield(), "вариант «Нормальная»: сложность 1, щит есть")
	mods.set_setting(MOD_ID, "difficulty", 3)
	game.start_new_game(0)
	await frames(30)
	check(mods.forced_difficulty() == -1 and game.difficulty == 0, "вариант «Как выбрано в меню»: сложность не трогается")
	mods.set_setting(MOD_ID, "difficulty", 0)

	# --- Смерть = конец забега ---
	var player = await open_level(2, 2)
	check(player != null and game.level_index == 2 and not game.saved_progress().is_empty(), "забег на уровне 3, прогресс сохранён")
	press_restart()
	await frames(20)
	check(get_first_node_in_group("player") == player and game.level_index == 2, "R при живом игроке ничего не перезапускает")
	player.kill()
	await frames(10)
	check(game.is_game_over and hud()._message_box.visible, "после смерти — сообщение на экране")
	check(game.saved_progress().is_empty(), "после смерти сохранение «Продолжить» стёрто")
	check("с 1 уровня" in hud()._sub_message.text, "в сообщении сказано, что игра начнётся с 1 уровня")
	press_restart()
	await frames(40)
	check(game.level_index == 0 and not game.is_game_over, "R после смерти начинает игру с 1 уровня")
	check(game.difficulty == 2, "сложность осталась «Сложной»")

	player = await open_level(5, 2)
	hud()._restart_level()  # «Начать заново» из паузы
	await frames(40)
	check(game.level_index == 0, "перезапуск из паузы тоже начинает с 1 уровня")

	# --- Урон: обычный и ультра ---
	player = await open_level(0, 2)
	var health_before: int = player.health
	player.take_damage(5, player.global_position + Vector2(30, 0))
	await frames(10)
	check(not player.is_dead() and player.health < health_before, "без ультра-хардкора урон просто отнимает здоровье (%d → %d)" % [health_before, player.health])
	mods.set_setting(MOD_ID, "ultra", true)
	player = await open_level(0, 2)
	player.take_damage(1, player.global_position + Vector2(30, 0))
	await frames(10)
	check(player.is_dead() and game.is_game_over, "ультра-хардкор: даже 1 единица урона — смерть")
	player = await open_level(0, 2)
	player.heal(1)
	await frames(5)
	check(not player.is_dead(), "ультра-хардкор: лечение смерти не вызывает")
	mods.set_setting(MOD_ID, "ultra", false)

	# --- Финал: убить всех врагов ---
	var last: int = game.level_count() - 1
	mods.set_setting(MOD_ID, "final_clear", false)
	player = await open_level(last, 2)
	var level = get_first_node_in_group("level")
	check(level != null and not level.require_clear and level.win_boss != null, "финал по умолчанию: враги не обязательны, главный босс есть")
	var boss = level.win_boss
	boss.take_damage(999999, boss.global_position + Vector2(-20, 0))
	await frames(20)
	check(game.game_completed, "без настройки победа над Древним слизнем сразу завершает игру")

	mods.set_setting(MOD_ID, "final_clear", true)
	player = await open_level(last, 2)
	level = get_first_node_in_group("level")
	check(level.require_clear and level.win_requires_clear, "настройка «в финале убить всех» включила условие на уровне")
	check(hud()._enemies_label.visible, "в HUD виден счётчик врагов")
	var total: int = get_nodes_in_group("enemies").size()
	check(total > 1, "на финальном уровне много врагов (%d)" % total)
	boss = level.win_boss
	boss.take_damage(999999, boss.global_position + Vector2(-20, 0))
	await frames(30)
	var left: int = get_nodes_in_group("enemies").size()
	check(not game.game_completed and not game.is_game_over and left > 0, "главный босс убит, но враги остались (%d) — игра не закончилась" % left)
	var guard := 0
	while get_nodes_in_group("enemies").size() > 0 and guard < 20:
		for enemy in get_nodes_in_group("enemies"):
			enemy.die()
		await frames(5)
		guard += 1
	await frames(20)
	check(get_nodes_in_group("enemies").is_empty() and game.game_completed, "когда не осталось ни одного врага — победа")
	mods.set_setting(MOD_ID, "final_clear", false)

	# --- Выключение мода ---
	mods.set_enabled(mod, false)
	await frames(2)
	check(not mods.permadeath_active() and mods.forced_difficulty() == -1, "выключенный мод не оставляет правил")
	player = await open_level(1, 1)
	press_restart()
	await frames(30)
	check(game.level_index == 1 and not game.is_game_over, "без мода R снова перезапускает уровень")

	_restore_user_files()
	print("ИТОГ: %s (%d ошибок)" % ["ВСЁ ХОРОШО" if fails == 0 else "ЕСТЬ ОШИБКИ", fails])
	quit(1 if fails else 0)


## Мод с испорченным описанием настроек: плохие пропускаются с сообщением, хорошая остаётся, мод работает.
func _test_bad_settings() -> void:
	var dir := ProjectSettings.globalize_path("user://settings_test_mods")
	DirAccess.make_dir_recursive_absolute(dir)
	var manifest := {
		"id": "settings_probe", "name": "Проверка настроек", "version": "1.0.0", "api": 2,
		"settings": [
			{"id": "Плохой Id", "type": "bool"},
			{"id": "unknown", "type": "color"},
			{"id": "one", "type": "choice", "options": ["единственный"]},
			{"id": "wide", "type": "number", "min": 5, "max": 1},
			{"id": "good", "type": "number", "min": 0, "max": 10, "step": 0.5, "default": 3.3},
			{"id": "good", "type": "bool"},
		],
	}
	var path := dir.path_join("settings_probe.zip")
	var packer := ZIPPacker.new()
	packer.open(path)
	packer.start_file("mod.json")
	packer.write_file(JSON.stringify(manifest).to_utf8_buffer())
	packer.close_file()
	packer.close()
	mods.extra_dirs.append(dir)
	mods.rescan()
	var probe = mods.get_mod("settings_probe")
	check(probe != null and probe.ok(), "мод с испорченными настройками всё равно загружается")
	if probe != null:
		check(probe.settings.size() == 1 and probe.problems.size() == 5, "оставлена одна верная настройка, на пять плохих — пять сообщений (%d / %d)" % [probe.settings.size(), probe.problems.size()])
		check(is_equal_approx(float(mods.get_setting("settings_probe", "good")), 3.5), "number: значение по умолчанию 3,3 приведено к шагу 0,5 → 3,5")
	mods.extra_dirs.erase(dir)
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(dir)
	mods.rescan()


const USER_FILES := ["user://progress.cfg", "user://mod_progress.cfg", "user://mods.cfg", "user://settings.cfg", "user://mod_settings.cfg"]
var _backup := {}


func _save_user_files() -> void:
	for path in USER_FILES:
		_backup[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null


func _restore_user_files() -> void:
	for path in USER_FILES:
		var data = _backup.get(path)
		if data == null:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(data)
			file.close()
