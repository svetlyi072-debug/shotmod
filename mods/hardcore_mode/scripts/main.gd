extends ModScript
## «Хардкорный режим»: сложность фиксируется (по умолчанию «Сложная»: умные враги, щита нет), а смерть —
## конец забега: после неё можно только начать игру с 1 уровня или выйти в меню.
## Настройки (меню «Моды» → этот мод):
##   difficulty  — какая сложность в забеге (сложная / нормальная / лёгкая / как выбрано в меню);
##   final_clear — на последнем уровне мало убить главного босса, нужно победить всех врагов;
##   ultra       — «ультра-хардкор»: любой полученный урон сразу убивает.
## Требует игру с API модов 2 (ShootIn 1.1.0 и новее).

## Номер варианта настройки «difficulty» (см. mod.json) → сложность игры: Game.Difficulty.HARD = 2,
## NORMAL = 1, EASY = 0; -1 — не фиксировать, сложность выбирает игрок в меню.
const DIFFICULTIES := [2, 1, 0, -1]

## Здоровье игрока на прошлом шаге: по нему видно, что игрок получил урон.
var _prev_health := -1
## Уровень уже начался (до этого моды вроде «Хардкор» ещё меняют здоровье при появлении игрока).
var _armed := false


func _mod_ready() -> void:
	_apply_rules()
	if not Game.player_health_changed.is_connected(_on_health_changed):
		Game.player_health_changed.connect(_on_health_changed)


## Игрок поменял настройку в меню «Моды» — новые правила действуют со следующего забега.
func _setting_changed(_id: String, _value) -> void:
	_apply_rules()


func _apply_rules() -> void:
	lock_difficulty(DIFFICULTIES[int(get_setting("difficulty"))])
	set_permadeath(true)


func _player_spawned(_player) -> void:
	_armed = false
	_prev_health = -1


func _level_started(level) -> void:
	var player = get_player()
	_prev_health = player.health if player != null else -1
	_armed = true
	var text := "ХАРДКОР: умрёшь — начнёшь с 1 уровня"
	if get_setting("ultra"):
		text += " · УЛЬТРА: любой урон убивает"
	hint(text)
	if get_setting("final_clear") and Game.is_last_level():
		level.require_clear_all(true)
		# Первую подсказку сменит эта: на финальном уровне важно знать правило сразу.
		get_tree().create_timer(3.0, false).timeout.connect(func() -> void:
			hint("ФИНАЛ: мало победить главного босса — надо убить всех врагов"))


## Здоровье изменилось: если стало меньше (а игрок жив) и включён ультра-хардкор — игрок погибает.
func _on_health_changed(current: int, _maximum: int) -> void:
	var lost := _armed and _prev_health >= 0 and current < _prev_health
	_prev_health = current
	if not lost or current <= 0 or not get_setting("ultra"):
		return
	var player = get_player()
	if player != null and not player.is_dead():
		hint("УЛЬТРА-ХАРДКОР: любой урон убивает")
		# Отложенно: игра ещё не закончила разбирать это попадание (отбрасывание, состояние).
		player.call_deferred("kill")
