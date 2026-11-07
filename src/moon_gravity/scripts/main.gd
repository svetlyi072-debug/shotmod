extends ModScript
## «Лунная гравитация»: игрок прыгает в два с лишним раза выше и долго парит в воздухе.

## Во сколько раз слабее гравитация игрока и во сколько раз выше прыжок.
const GRAVITY_FACTOR := 0.45
const JUMP_FACTOR := 2.2


func _player_spawned(player) -> void:
	player._gravity *= GRAVITY_FACTOR
	player.jump_height_tiles *= JUMP_FACTOR


func _level_started(_level) -> void:
	hint("Лунная гравитация: прыгай выше и дольше (Space)")
