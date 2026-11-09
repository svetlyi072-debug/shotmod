extends ModScript
## «Хардкор»: по умолчанию — «Сложная» сложность, но смерть — конец забега: после неё игру придётся начать
## с 1 уровня (или выйти в меню), а сохранение «Продолжить» стирается.
## Настройки (меню «Моды» → этот мод) — каждую можно включить или оставить выключенной:
##   difficulty  — сложность забега (сложная / нормальная / лёгкая / как выбрано в меню);
##   permadeath  — «одна жизнь»: смерть стирает сохранение и начинает игру заново;
##   final_clear — на последнем уровне мало убить главного босса, нужно победить всех врагов;
##   ultra       — «ультра-хардкор»: любой полученный урон сразу убивает;
##   tough       — крепкие враги: здоровье ×1,5, удары по игроку на 50% больнее, у игрока 70 здоровья и половина щита.
## Требует игру с API модов 2 (ShootIn 1.1.0 и новее).

## Номер варианта настройки «difficulty» (см. mod.json) → сложность игры: Game.Difficulty.HARD = 2,
## NORMAL = 1, EASY = 0; -1 — не фиксировать, сложность выбирает игрок в меню.
const DIFFICULTIES := [2, 1, 0, -1]

# Усиления настройки «tough».
const ENEMY_HEALTH_FACTOR := 1.5
const EXTRA_DAMAGE_FACTOR := 0.5
const PLAYER_HEALTH := 70
const SHIELD_FACTOR := 0.5

## Здоровье игрока на прошлом шаге: по нему видно, что игрок получил урон.
var _prev_health := -1
## Уровень уже начался (до этого другие моды ещё меняют здоровье при появлении игрока).
var _armed := false
## То же для усилений «tough» (добавляют урон сверху).
var _tough_last_health := -1


func _mod_ready() -> void:
	_apply_rules()
	if not Game.player_health_changed.is_connected(_on_health_changed):
		Game.player_health_changed.connect(_on_health_changed)


## Игрок поменял настройку в меню «Моды» — новые правила действуют со следующего забега.
func _setting_changed(_id: String, _value) -> void:
	_apply_rules()


func _apply_rules() -> void:
	lock_difficulty(DIFFICULTIES[int(get_setting("difficulty"))])
	set_permadeath(bool(get_setting("permadeath")))


func _player_spawned(player) -> void:
	_armed = false
	_prev_health = -1
	_tough_last_health = -1
	if get_setting("tough"):
		player.max_health = PLAYER_HEALTH
		player.health = PLAYER_HEALTH
		player.shield_max = int(player.shield_max * SHIELD_FACTOR)
		player.shield = minf(player.shield, float(player.shield_max))
		Game.player_health_changed.emit(player.health, player.max_health)
		_tough_last_health = player.health


func _enemy_spawned(enemy, _symbol) -> void:
	if get_setting("tough"):
		enemy.max_health = int(round(enemy.max_health * ENEMY_HEALTH_FACTOR))
		enemy.health = enemy.max_health


func _level_started(level) -> void:
	var player = get_player()
	_prev_health = player.health if player != null else -1
	_armed = true
	var parts: Array[String] = []
	if get_setting("permadeath"):
		parts.append("умрёшь — начнёшь с 1 уровня")
	if get_setting("ultra"):
		parts.append("УЛЬТРА: любой урон убивает")
	if get_setting("tough"):
		parts.append("враги крепче, бьют больнее")
	hint("ХАРДКОР" + (": " + " · ".join(parts) if not parts.is_empty() else ""))
	if get_setting("final_clear") and Game.is_last_level():
		level.require_clear_all(true)
		# Первую подсказку сменит эта: на финальном уровне важно знать правило сразу.
		get_tree().create_timer(3.0, false).timeout.connect(func() -> void:
			hint("ФИНАЛ: мало победить главного босса — надо убить всех врагов"))


func _physics_process(_delta: float) -> void:
	if not get_setting("tough"):
		return
	var player = get_player()
	if player == null or player.is_dead():
		return
	if _tough_last_health >= 0 and player.health < _tough_last_health:
		# Игрок получил удар: добавляем ещё половину потерянного.
		var lost: int = _tough_last_health - player.health
		var extra := int(round(lost * EXTRA_DAMAGE_FACTOR))
		if extra > 0:
			player.health = maxi(player.health - extra, 0)
			Game.player_health_changed.emit(player.health, player.max_health)
			if player.health == 0:
				player.kill()
	_tough_last_health = player.health


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
