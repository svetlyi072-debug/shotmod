extends SceneTree
## Проверяет готовые архивы из D:/ShotMOD/dist так, как их поставит игрок: установка из .zip,
## включение, загрузка всех уровней кампании, запуск скриптов. В конце всё удаляется.
## Запуск: godot --headless --path D:/shootin --script D:/ShotMOD/tools/check_dist.gd

const DIST := "D:/ShotMOD/dist"

var fails := 0


func check(cond: bool, msg: String) -> void:
	print(("OK   " if cond else "FAIL ") + msg)
	if not cond:
		fails += 1


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var mods = root.get_node("Mods")
	var game = root.get_node("Game")
	await frames(1)
	var installed: Array[String] = []
	var zips := DirAccess.get_files_at(DIST)
	for file in zips:
		if not file.ends_with(".zip"):
			continue
		var outcome: Dictionary = mods.install_zip_file(DIST.path_join(file))
		check(outcome["ok"], "установка %s: %s" % [file, outcome["message"]])
		if outcome["ok"]:
			installed.append(outcome["id"])
	for id in installed:
		var mod = mods.get_mod(id)
		if mod.has_scripts():
			mods.grant_script_consent(mod)
			mods.set_enabled(mod, true)
	var script_ids: Array[String] = []
	for id in installed:
		var mod = mods.get_mod(id)
		check(mod != null and mod.ok() and mod.active and mod.problems.is_empty() and mod.warnings.is_empty(), "«%s»: включён, проблем нет %s %s" % [id, str(mod.problems), str(mod.warnings)])
		if mod.has_scripts():
			script_ids.append(id)
	check(script_ids.size() == 11, "скриптовых модов: %d" % script_ids.size())
	# «Хардкорный режим» по умолчанию фиксирует «Сложную»: умные враги бьют игрока на старте и подбрасывают его,
	# а проверка «игрок стоит на земле» идёт на «Нормальной» — выбираем в его настройке «как выбрано в меню».
	if mods.get_mod("hardcore_mode") != null:
		mods.set_setting("hardcore_mode", "difficulty", 3)
	# Все скриптовые моды сразу — базовый уровень должен грузиться без сбоев.
	game.difficulty = 1
	game.level_index = 5
	change_scene_to_file("res://scenes/main.tscn")
	await frames(40)
	check(get_first_node_in_group("player") != null and get_nodes_in_group("enemies").size() > 0, "11 скриптовых модов одновременно: уровень загрузился, враги на месте")
	# Каждая кампания: все уровни грузятся.
	for id in installed:
		var mod = mods.get_mod(id)
		if not mod.has_campaign():
			continue
		var levels: Array = mods.campaign_levels(mod)
		game.start_campaign("mod:" + id, mod.campaign["title"], levels, 1)
		for i in levels.size():
			if i > 0:
				game.go_to_level(i)
			await frames(35)
			var p = get_first_node_in_group("player")
			# Скриптовые моды включены все сразу (лунная гравитация, хаос, двойной прыжок…), а враги у старта
			# могут успеть ударить и подбросить игрока, поэтому даём ему до 2,5 секунд приземлиться.
			var waited := 0
			while p != null and not p.is_on_floor() and waited < 150:
				await frames(5)
				waited += 5
			if p == null or not p.is_on_floor():
				check(false, "«%s» уровень %d: игрок не на земле (состояние %s, v=%s, поз=%s, здоровье %s, врагов %d)" % [id, i + 1, str(p.state) if p else "нет", str(p.velocity) if p else "-", str(p.global_position) if p else "-", str(p.health) if p else "-", get_nodes_in_group("enemies").size()])
		check(true, "«%s»: %d уровней загружены из архива" % [id, levels.size()])
		game.leave_campaign()
	# Уборка: закрыть архивы и удалить установленные файлы.
	mods._deactivate_all()
	for id in installed:
		var path := ProjectSettings.globalize_path("user://mods").path_join(id + ".zip")
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	for f in ["user://mods.cfg", "user://mod_progress.cfg", "user://mod_settings.cfg"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	var data_dir := ProjectSettings.globalize_path("user://mod_data")
	for f in DirAccess.get_files_at(data_dir) if DirAccess.dir_exists_absolute(data_dir) else PackedStringArray():
		DirAccess.remove_absolute(data_dir.path_join(f))
	game.clear_progress()
	print("ИТОГ: %s (%d ошибок)" % ["ВСЁ ХОРОШО" if fails == 0 else "ЕСТЬ ОШИБКИ", fails])
	quit(1 if fails else 0)
