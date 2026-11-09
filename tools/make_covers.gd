extends SceneTree
## Обложки модов 630×500 для страниц публикации: кадр из игры (или тёмный фон) + название и описание.
## Запуск (окно нужно ради рендера):
##   node tools/godot_isolated.js --resolution 630x500 --script D:/ShotMOD/tools/make_covers.gd
## Берёт build/catalog.json и build/shots/<id>_cover.png, кладёт результат в covers/<id>.png.

const CATALOG := "D:/ShotMOD/build/catalog.json"
const SHOTS := "D:/ShotMOD/build/shots/"
const OUT := "D:/ShotMOD/covers/"
const KIND_LABEL := {"levels": "ПАК УРОВНЕЙ", "pack": "ВРАГИ · БОСС · УРОВНИ", "script": "МОД СО СКРИПТОМ"}
const KIND_COLOR := {"levels": Color(1.0, 0.85, 0.35), "pack": Color(1.0, 0.55, 0.3), "script": Color(0.45, 0.85, 1.0)}

var _view: SubViewport
var _bg: TextureRect
var _badge: Label
var _title: Label
var _tagline: Label
var _emblem: Label


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	_build()
	var ids := catalog.keys()
	ids.sort()
	for id in ids:
		var entry: Dictionary = catalog[id]
		var kind: String = entry["kind"]
		_badge.text = " " + KIND_LABEL.get(kind, "МОД") + " "
		_badge.add_theme_color_override("font_color", Color.BLACK)
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = KIND_COLOR.get(kind, Color.WHITE)
		badge_style.set_corner_radius_all(6)
		_badge.add_theme_stylebox_override("normal", badge_style)
		_title.text = entry["name"]
		_tagline.text = entry["tagline"]
		var shot: String = SHOTS + str(id) + "_cover.png"
		if FileAccess.file_exists(shot):
			var img := Image.load_from_file(shot)
			# Игровая часть кадра без HUD: y 100…630, по центру ширины.
			var crop := img.get_region(Rect2i(306, 100, 668, 530))
			_bg.texture = ImageTexture.create_from_image(crop)
			_emblem.visible = false
		else:
			_bg.texture = null
			_emblem.visible = true
			_emblem.text = "{ }"
			_emblem.add_theme_color_override("font_color", KIND_COLOR.get(kind, Color.WHITE))
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		_view.get_texture().get_image().save_png(OUT + id + ".png")
		print("обложка ", id)
	quit()


func _build() -> void:
	_view = SubViewport.new()
	_view.size = Vector2i(630, 500)
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_view)
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.add_child(ui)
	var back := ColorRect.new()
	back.color = Color(0.1, 0.09, 0.16)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(back)
	_bg = TextureRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ui.add_child(_bg)
	_emblem = Label.new()
	_emblem.set_anchors_preset(Control.PRESET_FULL_RECT)
	_emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_emblem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_emblem.offset_top = -80.0
	_emblem.add_theme_font_size_override("font_size", 190)
	ui.add_child(_emblem)
	# Затемнение снизу, чтобы текст читался.
	var shade := TextureRect.new()
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.82), Color(0, 0, 0, 0.93)])
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 256
	shade.texture = tex
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.anchor_top = 0.42
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	ui.add_child(shade)
	_badge = Label.new()
	_badge.position = Vector2(16, 14)
	_badge.add_theme_font_size_override("font_size", 15)
	ui.add_child(_badge)
	var column := VBoxContainer.new()
	column.anchor_top = 1.0
	column.anchor_bottom = 1.0
	column.anchor_right = 1.0
	column.offset_left = 20.0
	column.offset_right = -20.0
	column.offset_top = -170.0
	column.offset_bottom = -16.0
	column.grow_vertical = Control.GROW_DIRECTION_BEGIN
	column.add_theme_constant_override("separation", 6)
	column.alignment = BoxContainer.ALIGNMENT_END
	ui.add_child(column)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 46)
	_title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_title.add_theme_constant_override("outline_size", 10)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_title)
	_tagline = Label.new()
	_tagline.add_theme_font_size_override("font_size", 16)
	_tagline.add_theme_color_override("font_outline_color", Color.BLACK)
	_tagline.add_theme_constant_override("outline_size", 5)
	_tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tagline.custom_minimum_size = Vector2(590, 0)
	column.add_child(_tagline)
