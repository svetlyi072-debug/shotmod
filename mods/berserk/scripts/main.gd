extends ModScript
## «Берсерк»: убивай врагов подряд — каждое убийство в течение 4 секунд после прошлого усиливает
## урон и скорость (до ×2 урона и +30% к бегу). Нет убийств 4 секунды — всё сбрасывается.

const COMBO_WINDOW := 4.0
const MAX_COMBO := 10
const DAMAGE_PER_STACK := 0.1
const SPEED_PER_STACK := 0.03

var _combo := 0
var _timer := 0.0
var _base := {}
var _layer: CanvasLayer
var _label: Label


func _mod_ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 5
	add_child(_layer)
	_label = Label.new()
	_label.position = Vector2(16.0, 124.0)
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	_layer.add_child(_label)
	_label.visible = false


func _level_started(_level) -> void:
	hint("Берсерк: убивай врагов подряд — урон и скорость растут")


func _player_spawned(player) -> void:
	_combo = 0
	_base = {"attack_damage": player.attack_damage, "shoot_damage": player.shoot_damage, "run_speed_tiles": player.run_speed_tiles}
	_apply()


func _enemy_killed(_enemy, _power_reward) -> void:
	_combo = mini(_combo + 1, MAX_COMBO)
	_timer = COMBO_WINDOW
	_apply()
	if _combo == 5 or _combo == MAX_COMBO:
		hint("БЕРСЕРК ×%d!" % _combo)


func _process(delta: float) -> void:
	if _combo > 0:
		_timer -= delta
		if _timer <= 0.0:
			_combo = 0
			_apply()
	_label.visible = _combo > 0 and get_level() != null


func _apply() -> void:
	_label.text = "БЕРСЕРК ×%d" % _combo
	var player = get_player()
	if player == null or _base.is_empty():
		return
	var damage_factor := 1.0 + DAMAGE_PER_STACK * _combo
	player.attack_damage = int(round(_base["attack_damage"] * damage_factor))
	player.shoot_damage = int(round(_base["shoot_damage"] * damage_factor))
	player.run_speed_tiles = _base["run_speed_tiles"] * (1.0 + SPEED_PER_STACK * _combo)
