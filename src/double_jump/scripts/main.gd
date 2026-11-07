extends ModScript
## «Двойной прыжок»: второй раз нажми Space в воздухе — и прыгнешь ещё раз.

## Сколько дополнительных прыжков в воздухе и какая у них сила (доля обычного прыжка).
const AIR_JUMPS := 1
const AIR_JUMP_POWER := 0.9

var _used := 0


func _level_started(_level) -> void:
	_used = 0
	hint("Двойной прыжок: нажми Space ещё раз в воздухе")


func _physics_process(_delta: float) -> void:
	var player = get_player()
	if player == null or player.is_dead():
		return
	if player.is_on_floor():
		_used = 0
		return
	if Input.is_action_just_pressed("jump") and _used < AIR_JUMPS and player.state != Player.State.HURT:
		_used += 1
		var speed: float = sqrt(2.0 * player._gravity * Game.tiles(player.jump_height_tiles)) * AIR_JUMP_POWER
		player.velocity.y = -speed
