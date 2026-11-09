extends RefCounted
## Защита данных игрока на время проверок. Проверки запускаются на тех же данных, что и настоящая игра
## (папка user://: сохранения, настройки, моды), поэтому перед началом всё прячется в user://test_backup, а в конце
## возвращается. Копии лежат на диске, так что если проверка оборвалась (ошибка, таймаут), следующий запуск сам вернёт
## всё на место (restore() в начале backup()).
##
## Использование в проверке (SceneTree-скрипт):
##   var user_state = load("D:/ShotMOD/tools/user_state.gd")
##   user_state.backup(mods)      # в начале; mods — узел автозагрузки Mods (чтобы закрыть открытые архивы)
##   user_state.restore(mods)     # перед quit()
## Что прячется: сохранения и настройки (*.cfg из FILES), .zip-моды из user://mods (чтобы чужая копия мода с тем же id
## не подменяла проверяемый) и папка user://mod_data.

const BACKUP := "user://test_backup"
const FILES := ["progress.cfg", "mod_progress.cfg", "mods.cfg", "settings.cfg", "mod_settings.cfg"]
const MANIFEST := "manifest.json"


static func _abs(path: String) -> String:
	return ProjectSettings.globalize_path(path)


static func _copy(from: String, to: String) -> void:
	var file := FileAccess.open(to, FileAccess.WRITE)
	file.store_buffer(FileAccess.get_file_as_bytes(from))
	file.close()


## Прячет данные игрока. Если с прошлого раза остались копии (проверка оборвалась) — сначала возвращает их.
static func backup(mods = null) -> void:
	# Windows не даёт переименовать .zip, пока игра держит его открытым, поэтому сначала закрываем архивы модов.
	if mods != null:
		mods._deactivate_all()
	if DirAccess.dir_exists_absolute(_abs(BACKUP)):
		restore(mods)
	DirAccess.make_dir_recursive_absolute(_abs(BACKUP + "/mods"))
	var manifest := {"files": [], "zips": [], "mod_data": false}
	if DirAccess.dir_exists_absolute(_abs("user://mod_data")):
		DirAccess.rename_absolute(_abs("user://mod_data"), _abs(BACKUP + "/mod_data"))
		manifest["mod_data"] = true
	for name in FILES:
		var path: String = "user://" + name
		if FileAccess.file_exists(path):
			_copy(path, BACKUP + "/" + name)
			manifest["files"].append(name)
			DirAccess.remove_absolute(_abs(path))
	if DirAccess.dir_exists_absolute(_abs("user://mods")):
		for file in DirAccess.get_files_at(_abs("user://mods")):
			if file.get_extension().to_lower() == "zip":
				DirAccess.rename_absolute(_abs("user://mods/" + file), _abs(BACKUP + "/mods/" + file))
				manifest["zips"].append(file)
	var manifest_file := FileAccess.open(BACKUP + "/" + MANIFEST, FileAccess.WRITE)
	manifest_file.store_string(JSON.stringify(manifest))
	manifest_file.close()


## Возвращает данные игрока на место и убирает копии. Файлы, которых до проверки не было, удаляются.
static func restore(mods = null) -> void:
	if mods != null:
		mods._deactivate_all()
	if not FileAccess.file_exists(BACKUP + "/" + MANIFEST):
		return
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(BACKUP + "/" + MANIFEST))
	if not manifest is Dictionary:
		return
	for name in FILES:
		var path: String = "user://" + name
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(_abs(path))
		if manifest["files"].has(name):
			_copy(BACKUP + "/" + name, path)
	# Моды, поставленные самой проверкой, убираем; моды игрока возвращаем.
	if DirAccess.dir_exists_absolute(_abs("user://mods")):
		for file in DirAccess.get_files_at(_abs("user://mods")):
			if file.get_extension().to_lower() == "zip":
				DirAccess.remove_absolute(_abs("user://mods/" + file))
	DirAccess.make_dir_recursive_absolute(_abs("user://mods"))
	for file in manifest["zips"]:
		DirAccess.rename_absolute(_abs(BACKUP + "/mods/" + file), _abs("user://mods/" + file))
	# Данные модов (рекорды, счётчики): то, что записала проверка, выбрасываем, данные игрока возвращаем.
	var data_dir := _abs("user://mod_data")
	if DirAccess.dir_exists_absolute(data_dir):
		for file in DirAccess.get_files_at(data_dir):
			DirAccess.remove_absolute(data_dir.path_join(file))
		DirAccess.remove_absolute(data_dir)
	if manifest.get("mod_data", false):
		DirAccess.rename_absolute(_abs(BACKUP + "/mod_data"), data_dir)
	# Копии удаляем.
	for name in manifest["files"]:
		DirAccess.remove_absolute(_abs(BACKUP + "/" + name))
	DirAccess.remove_absolute(_abs(BACKUP + "/" + MANIFEST))
	DirAccess.remove_absolute(_abs(BACKUP + "/mods"))
	DirAccess.remove_absolute(_abs(BACKUP))
