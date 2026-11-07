extends ModScript
## «Яблоки с врагов»: с убитых врагов иногда выпадают яблоки-аптечки, с боссов — два.

## Шанс выпадения с обычного врага.
const DROP_CHANCE := 0.3

var _told := false


func _level_started(_level) -> void:
	if not _told:
		_told = true
		hint("Яблоки с врагов: с убитых иногда выпадают аптечки")


func _enemy_killed(enemy, _power_reward) -> void:
	var level = get_level()
	if level == null:
		return
	var drops := 2 if enemy is Boss else (1 if randf() < DROP_CHANCE else 0)
	for i in drops:
		var x := floori(enemy.global_position.x / Game.TILE) + (i * 2 - 1 if drops > 1 else 0)
		var y := floori((enemy.global_position.y - 1.0) / Game.TILE)
		# Яблоко падает на пол (летающих врагов тоже касается).
		var guard := 0
		while not level.is_floor_cell(Vector2i(x, y + 1)) and guard < 16 and y < level.map_height() - 1:
			y += 1
			guard += 1
		if level.is_solid_cell(Vector2i(x, y)):
			y -= 1
		if y < level.map_height() - 1 and level.is_floor_cell(Vector2i(x, y + 1)):
			spawn("+", x, y)
