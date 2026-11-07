extends SceneTree
## Проверка модов из D:/ShotMOD/mods в настоящей игре: загрузка мода, каждый уровень кампании,
## снимок экрана у врагов. Запуск (окно нужно ради снимков):
##   godot --path D:/shootin --script D:/ShotMOD/tools/check_mods.gd -- <id мода> [--no-shots]
## Для проверки без окна добавьте --headless и --no-shots.

const MODS_DIR := "D:/ShotMOD/mods"
const SHOTS := "D:/ShotMOD/build/shots/"

var fails := 0


func check(cond: bool, msg: String) -> void:
	print(("OK   " if cond else "FAIL ") + msg)
	if not cond:
		fails += 1


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func cls(node) -> String:
	if node.get_script() == null:
		return node.get_class()
	var name: String = node.get_script().get_global_name()
	return name if name != "" else "ModScriptEnemy"


func snap(file: String) -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(SHOTS + file)


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var mods = root.get_node("Mods")
	var game = root.get_node("Game")
	var args := OS.get_cmdline_user_args()
	var id: String = args[0]
	var shots := not args.has("--no-shots")
	var cover_level := -1
	if args.has("--cover"):
		cover_level = int(args[args.find("--cover") + 1]) - 1
		shots = false
	mods.extra_dirs.append(MODS_DIR)
	await frames(1)
	mods.rescan()
	var mod = mods.get_mod(id)
	check(mod != null, "мод «%s» найден" % id)
	if mod == null:
		quit(1)
		return
	if mod.has_scripts():
		mods.grant_script_consent(mod)
		mods.set_enabled(mod, true)
		mod = mods.get_mod(id)
	check(mod.ok() and mod.active, "мод включён без ошибок %s" % str(mod.errors))
	check(mod.problems.is_empty(), "нет проблем содержимого %s" % str(mod.problems))
	check(mod.warnings.is_empty(), "нет предупреждений %s" % str(mod.warnings))
	game.difficulty = 1
	if mod.has_campaign():
		var levels: Array = mods.campaign_levels(mod)
		game.start_campaign("mod:" + id, mod.campaign["title"], levels, 1)
		for i in levels.size():
			if i > 0:
				game.go_to_level(i)
			await frames(40)
			var p = get_first_node_in_group("player")
			var counts := {}
			var xs: Array = []
			for e in get_nodes_in_group("enemies"):
				counts[cls(e)] = counts.get(cls(e), 0) + 1
				xs.append(e.global_position.x)
			check(p != null and p.is_on_floor(), "уровень %d «%s»: игрок на земле, враги %s" % [i + 1, levels[i]["TITLE"], str(counts)])
			if i == cover_level and p != null:
				xs.sort()
				var focus: float = p.global_position.x
				if xs.size() > 0:
					focus = xs[xs.size() / 2] - 5.0 * 32.0
				p.global_position = Vector2(maxf(focus, 2.0 * 32.0), p.global_position.y)
				p.get_node("Camera2D").reset_smoothing()
				await frames(260)  # подпись уровня успевает погаснуть
				p.health = 100
				await snap("%s_cover.png" % id)
			if shots and p != null:
				xs.sort()
				var target: float = p.global_position.x
				if xs.size() > 0:
					target = xs[xs.size() / 3] - 6.0 * 32.0
				p.global_position = Vector2(maxf(target, 2.0 * 32.0), p.global_position.y)
				p.get_node("Camera2D").reset_smoothing()
				await frames(45)
				p.health = 100
				await snap("%s_%02d.png" % [id, i + 1])
		game.leave_campaign()
	game.clear_progress()
	for f in ["user://mods.cfg", "user://mod_progress.cfg"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	print("ИТОГ %s: %s (%d ошибок)" % [id, "ВСЁ ХОРОШО" if fails == 0 else "ЕСТЬ ОШИБКИ", fails])
	quit(1 if fails else 0)
