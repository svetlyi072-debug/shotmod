extends ModScript
## «Полоски здоровья и урон»: полоска здоровья над раненым врагом, всплывающие цифры урона и счётчик убийств.

var _hp := {}            # id врага → здоровье в прошлом кадре
var _player_hp := -1
var _kills := 0
var _layer: CanvasLayer
var _label: Label


## Полоска здоровья над врагом: видна, только когда он ранен.
class HpBar extends Node2D:
	var target: Node = null
	var width := 34.0
	var _shown := -1

	func _process(_delta: float) -> void:
		if not is_instance_valid(target):
			queue_free()
			return
		if target.health != _shown:
			_shown = target.health
			queue_redraw()

	func _draw() -> void:
		if target == null or target.health >= target.max_health or target.health <= 0:
			return
		var ratio := clampf(float(target.health) / float(target.max_health), 0.0, 1.0)
		draw_rect(Rect2(-width / 2.0 - 1.0, -1.0, width + 2.0, 6.0), Color(0.0, 0.0, 0.0, 0.75))
		draw_rect(Rect2(-width / 2.0, 0.0, width * ratio, 4.0), Color(0.9, 0.2, 0.2).lerp(Color(0.3, 0.9, 0.3), ratio))


## Число урона: поднимается вверх и гаснет.
class FloatText extends Node2D:
	var text := ""
	var color := Color.WHITE
	var _age := 0.0

	func _ready() -> void:
		z_index = 20

	func _process(delta: float) -> void:
		_age += delta
		position.y -= 30.0 * delta
		modulate.a = clampf(1.0 - (_age - 0.4) / 0.5, 0.0, 1.0)
		if _age > 0.9:
			queue_free()

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		draw_string_outline(font, Vector2(-24.0, 0.0), text, HORIZONTAL_ALIGNMENT_CENTER, 48.0, 16, 5, Color.BLACK)
		draw_string(font, Vector2(-24.0, 0.0), text, HORIZONTAL_ALIGNMENT_CENTER, 48.0, 16, color)


func _mod_ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 5
	add_child(_layer)
	_label = Label.new()
	_label.position = Vector2(16.0, 98.0)
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 5)
	_layer.add_child(_label)
	_update_label()


func _level_started(_level) -> void:
	_kills = 0
	_hp.clear()
	_update_label()


func _enemy_spawned(enemy, _symbol) -> void:
	if enemy is Boss:
		return  # у боссов есть своя большая полоска
	var bar := HpBar.new()
	bar.target = enemy
	bar.position = Vector2(0.0, -enemy.get_body_rect().size.y - 12.0)
	enemy.add_child(bar)


func _enemy_killed(enemy, _power_reward) -> void:
	_kills += 1
	_update_label()
	var id: int = enemy.get_instance_id()
	if _hp.has(id):
		_text_at(enemy.global_position + Vector2(0.0, -enemy.get_body_rect().size.y - 8.0), "-%d" % _hp[id], Color(1.0, 0.9, 0.3))
		_hp.erase(id)


func _process(_delta: float) -> void:
	var level = get_level()
	_layer.visible = level != null
	if level == null:
		_hp.clear()
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var id: int = enemy.get_instance_id()
		var health: int = enemy.health
		if _hp.has(id) and health < _hp[id]:
			_text_at(enemy.global_position + Vector2(0.0, -enemy.get_body_rect().size.y - 8.0), "-%d" % (_hp[id] - health), Color(1.0, 0.9, 0.3))
		_hp[id] = health
	var player = get_player()
	if player != null:
		if _player_hp >= 0 and player.health < _player_hp:
			_text_at(player.global_position + Vector2(0.0, -64.0), "-%d" % (_player_hp - player.health), Color(1.0, 0.35, 0.35))
		_player_hp = player.health


func _text_at(world: Vector2, text: String, color: Color) -> void:
	var level = get_level()
	if level == null:
		return
	var floating := FloatText.new()
	floating.text = text
	floating.color = color
	level.get_node("Entities").add_child(floating)
	floating.global_position = world


func _update_label() -> void:
	_label.text = "Убито: %d" % _kills
