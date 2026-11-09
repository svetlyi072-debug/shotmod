extends SceneTree
## Кадры для публикации мода «Хардкорный режим»: меню «Моды» с настройками и экран «Ты умер».
## Нужно окно (рендер), поэтому без --headless:
##   godot --path D:/shootin --resolution 1280x720 --script D:/ShotMOD/tools/make_hardcore_shots.gd
## Кладёт кадры в screenshots/ и обложку-заготовку в build/shots/hardcore_mode_cover.png.

const OUT := "D:/ShotMOD/screenshots/"
const COVER := "D:/ShotMOD/build/shots/hardcore_mode_cover.png"
const MOD_ID := "hardcore_mode"
const USER_FILES := ["user://progress.cfg", "user://mod_progress.cfg", "user://mods.cfg", "user://settings.cfg", "user://mod_settings.cfg"]

var _backup := {}


func frames(n: int) -> void:
	for i in n:
		await process_frame
		await physics_frame


func snap(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	image.save_png(path)
	print("кадр: ", path, " ", image.get_size())


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var game = root.get_node("Game")
	var mods = root.get_node("Mods")
	for path in USER_FILES:
		_backup[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	mods.extra_dirs.append("D:/ShotMOD/mods")
	await frames(2)
	mods.rescan()
	var mod = mods.get_mod(MOD_ID)
	mods.grant_script_consent(mod)
	mods.set_enabled(mod, true)

	# Меню «Моды»: настройки мода (в одной из них — «ультра-хардкор» включён).
	mods.set_setting(MOD_ID, "ultra", true)
	change_scene_to_file("res://scenes/ui/mods_menu.tscn")
	await frames(10)
	# Для публикации: без дубликатов-ошибок из моей среды и без личных путей на кадре.
	for i in range(mods.mods.size() - 1, -1, -1):
		if not mods.mods[i].ok():
			mods.mods.remove_at(i)
	current_scene._refresh()
	current_scene._select(MOD_ID)
	await frames(8)
	current_scene._detail_meta.text = "id: %s · версия %s · автор: %s" % [mod.id, mod.version, mod.author]
	for label in current_scene.find_children("*", "Label", true, false):
		if label.text.begins_with("Моды лежат в папке"):
			label.text = "Моды лежат в папке «mods» рядом с игрой или в данных игры"
	await frames(2)
	await snap(OUT + "hardcore_mode_settings.png")

	# Экран смерти — он же обложка.
	mods.set_setting(MOD_ID, "ultra", false)
	game.leave_campaign()
	game.difficulty = 2
	game.go_to_level(0)
	await frames(60)
	var player = get_first_node_in_group("player")
	player.kill()
	await frames(20)
	await snap(OUT + "hardcore_mode_death.png")
	await snap(COVER)

	for path in USER_FILES:
		var data = _backup.get(path)
		if data == null:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(data)
			file.close()
	quit()
