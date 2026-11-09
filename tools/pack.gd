extends SceneTree
## Упаковывает каждый мод из D:/ShotMOD/mods в dist/<id>-<версия>.zip (mod.json — в корне архива).
## Запуск: node tools/godot_isolated.js --headless --script D:/ShotMOD/tools/pack.gd

const MODS := "D:/ShotMOD/mods"
const DIST := "D:/ShotMOD/dist"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(DIST)
	for old in DirAccess.get_files_at(DIST):
		if old.ends_with(".zip"):
			DirAccess.remove_absolute(DIST.path_join(old))
	var failed := 0
	var total := 0
	for id in DirAccess.get_directories_at(MODS):
		if id.begins_with("_") or not FileAccess.file_exists(MODS.path_join(id).path_join("mod.json")):
			continue
		var manifest = JSON.parse_string(FileAccess.get_file_as_string(MODS.path_join(id).path_join("mod.json")))
		var out := DIST.path_join("%s-%s.zip" % [id, manifest.get("version", "1.0.0")])
		var packer := ZIPPacker.new()
		if packer.open(out) != OK:
			push_error("не открылся " + out)
			failed += 1
			continue
		var count := _add_dir(packer, MODS.path_join(id), "")
		packer.close()
		# Проверка: архив читается и mod.json лежит в корне.
		var reader := ZIPReader.new()
		var ok := reader.open(out) == OK and reader.get_files().has("mod.json") and reader.get_files().size() == count
		reader.close()
		print("%s %s: %d файлов, %d КБ" % ["OK  " if ok else "FAIL", out.get_file(), count, FileAccess.get_file_as_bytes(out).size() / 1024])
		total += 1
		failed += 0 if ok else 1
	print("упаковано: %d, ошибок: %d" % [total, failed])
	quit(1 if failed else 0)


func _add_dir(packer: ZIPPacker, abs_dir: String, rel: String) -> int:
	var count := 0
	for file in DirAccess.get_files_at(abs_dir):
		packer.start_file(rel + file)
		packer.write_file(FileAccess.get_file_as_bytes(abs_dir.path_join(file)))
		packer.close_file()
		count += 1
	for dir in DirAccess.get_directories_at(abs_dir):
		count += _add_dir(packer, abs_dir.path_join(dir), rel + dir + "/")
	return count
