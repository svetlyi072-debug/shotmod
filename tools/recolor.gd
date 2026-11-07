extends SceneTree
## Перекрашивает спрайты игры в новые палитры для модов.
## Запуск (из папки игры, где лежат assets/):
##   godot --headless --path D:/shootin --script D:/ShotMOD/tools/recolor.gd -- D:/ShotMOD/build/jobs.json
## jobs.json: {"jobs": [{"src": "абсолютный путь к PNG", "dst": "куда сохранить", "preset": "fire"}, ...]}
## Палитры — в PRESETS: градиент от тёмного к светлому и «акцентный» оттенок для насыщенных
## пикселей (кожа, одежда), чтобы детали не сливались в один цвет.

const PRESETS := {
	# Огонь: уголь → тёмно-красный → оранжевый → жёлтый.
	"fire": {"ramp": ["1c0500", "7a1a00", "ff6a00", "ffe08a"], "accent": 0.07, "mix": 0.55},
	# Песок и золото.
	"sand": {"ramp": ["24190a", "7a5a1c", "d8b04a", "fff2bd"], "accent": 0.11, "mix": 0.5},
	# Тени: чёрный → фиолетовый → сиреневый.
	"shadow": {"ramp": ["06030c", "2b1a4a", "6a3fa8", "d6bcff"], "accent": 0.78, "mix": 0.6},
	# Лёд.
	"frost": {"ramp": ["04142a", "1f4e8c", "5fb0e8", "eaf8ff"], "accent": 0.56, "mix": 0.55},
	# Яд.
	"toxic": {"ramp": ["0a1a05", "2a6a10", "7ad02a", "efffa0"], "accent": 0.27, "mix": 0.55},
	# Кровь и ржавчина (красные гоблины).
	"blood": {"ramp": ["1a0606", "6b1414", "c8402a", "ffb08a"], "accent": 0.0, "mix": 0.5},
	# Золотой правитель: тёмная бронза → золото.
	"gold": {"ramp": ["1c1204", "6e4a0c", "e0a828", "fff3a8"], "accent": 0.12, "mix": 0.5},
	# Ночной синий (стража).
	"night": {"ramp": ["03060f", "16284f", "3d66c4", "c4d8ff"], "accent": 0.62, "mix": 0.55},
}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("нужен путь к jobs.json")
		quit(1)
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var failed := 0
	for job in data["jobs"]:
		if not recolor_file(job["src"], job["dst"], job["preset"]):
			failed += 1
	print("готово: %d картинок, ошибок %d" % [data["jobs"].size(), failed])
	quit(1 if failed else 0)


func recolor_file(src: String, dst: String, preset_name: String) -> bool:
	var img := Image.load_from_file(src)
	if img == null:
		push_error("нет картинки " + src)
		return false
	if not PRESETS.has(preset_name):
		push_error("нет палитры " + preset_name)
		return false
	img.convert(Image.FORMAT_RGBA8)
	var preset: Dictionary = PRESETS[preset_name]
	var ramp: Array[Color] = []
	for hex in preset["ramp"]:
		ramp.append(Color(hex))
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				img.set_pixel(x, y, tint(c, ramp, float(preset["accent"]), float(preset["mix"])))
	DirAccess.make_dir_recursive_absolute(dst.get_base_dir())
	return img.save_png(dst) == OK


func sample(ramp: Array[Color], t: float) -> Color:
	t = clampf(t, 0.0, 1.0) * (ramp.size() - 1)
	var i := mini(int(t), ramp.size() - 2)
	return ramp[i].lerp(ramp[i + 1], t - i)


func tint(c: Color, ramp: Array[Color], accent: float, mix: float) -> Color:
	var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	var base := sample(ramp, pow(lum, 0.9) * 1.08)
	if c.s > 0.22 and lum > 0.12:
		var warm := Color.from_hsv(accent, minf(c.s * 1.1, 0.95), minf(c.v * 1.1 + 0.05, 1.0))
		base = base.lerp(warm, mix)
	return Color(base.r, base.g, base.b, c.a)
