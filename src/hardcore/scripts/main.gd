extends ModScript
## «Хардкор»: враги крепче на 50%, их удары больнее на 50%, у игрока 70 здоровья и половина щита.

const ENEMY_HEALTH_FACTOR := 1.5
const EXTRA_DAMAGE_FACTOR := 0.5
const PLAYER_HEALTH := 70
const SHIELD_FACTOR := 0.5

var _last_health := -1


func _level_started(_level) -> void:
	hint("ХАРДКОР: враги крепче на 50%%, бьют на 50%% больнее, здоровья %d" % PLAYER_HEALTH)


func _player_spawned(player) -> void:
	player.max_health = PLAYER_HEALTH
	player.health = PLAYER_HEALTH
	player.shield_max = int(player.shield_max * SHIELD_FACTOR)
	player.shield = minf(player.shield, float(player.shield_max))
	Game.player_health_changed.emit(player.health, player.max_health)
	_last_health = player.health


func _enemy_spawned(enemy, _symbol) -> void:
	enemy.max_health = int(round(enemy.max_health * ENEMY_HEALTH_FACTOR))
	enemy.health = enemy.max_health


func _physics_process(_delta: float) -> void:
	var player = get_player()
	if player == null or player.is_dead():
		return
	if _last_health >= 0 and player.health < _last_health:
		# Игрок получил удар: добавляем ещё половину потерянного.
		var lost: int = _last_health - player.health
		var extra := int(round(lost * EXTRA_DAMAGE_FACTOR))
		if extra > 0:
			player.health = maxi(player.health - extra, 0)
			Game.player_health_changed.emit(player.health, player.max_health)
			if player.health == 0:
				player.kill()
	_last_health = player.health
