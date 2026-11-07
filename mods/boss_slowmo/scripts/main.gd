extends ModScript
## «Финальный удар»: когда побеждён босс, время на секунду замедляется — как в кино.

## Во сколько раз замедлить и на сколько реальных секунд.
const SLOW_SCALE := 0.25
const SLOW_SECONDS := 1.4


func _boss_defeated() -> void:
	hint("ФИНАЛЬНЫЙ УДАР!")
	Engine.time_scale = SLOW_SCALE
	# Таймер идёт в реальном времени (последний параметр — игнорировать замедление).
	get_tree().create_timer(SLOW_SECONDS, true, false, true).timeout.connect(_restore)


func _restore() -> void:
	Engine.time_scale = 1.0


func _player_died() -> void:
	_restore()


func _exit_tree() -> void:
	Engine.time_scale = 1.0
