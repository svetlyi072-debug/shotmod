extends ModScript
## «Режим хаоса»: каждые 25 секунд случается что-то странное — прыжки, скорость, урон, нашествие врагов, яблоки.

## Пауза между событиями и сколько длится эффект (секунды).
const INTERVAL := 25.0
const DURATION := 12.0
## Какие встроенные враги приходят при «нашествии».
const INVADERS := ["s", "k", "z", "g", "r"]

const EFFECTS := ["moon", "heavy", "sprint", "power", "weak", "invasion", "apples"]

var _timer := INTERVAL
var _left := 0.0
var _effect := ""
var _saved := {}


func _level_started(_level) -> void:
	_stop_effect()
	_timer = 10.0
	hint("Режим хаоса: каждые %d секунд случается что-то странное" % int(INTERVAL))


func _process(delta: float) -> void:
	var player = get_player()
	if player == null or player.is_dead() or Game.is_game_over:
		return
	if _effect != "":
		_left -= delta
		if _left <= 0.0:
			_stop_effect()
	_timer -= delta
	if _timer <= 0.0:
		_timer = INTERVAL
		_start_effect(player)


func _start_effect(player) -> void:
	_stop_effect()
	var kind: String = EFFECTS[randi() % EFFECTS.size()]
	match kind:
		"moon":
			_remember(player, ["_gravity", "jump_height_tiles"])
			player._gravity *= 0.5
			player.jump_height_tiles *= 1.9
			_announce("ЛУННЫЕ НОГИ: прыжки выше", true)
		"heavy":
			_remember(player, ["run_speed_tiles"])
			player.run_speed_tiles *= 0.6
			_announce("ТЯЖЁЛЫЕ НОГИ: бежишь медленнее", true)
		"sprint":
			_remember(player, ["run_speed_tiles"])
			player.run_speed_tiles *= 1.5
			_announce("СПРИНТЕР: бежишь быстрее", true)
		"power":
			_remember(player, ["attack_damage", "shoot_damage"])
			player.attack_damage *= 2
			player.shoot_damage *= 2
			_announce("СИЛА: твой урон ×2", true)
		"weak":
			_remember(player, ["attack_damage", "shoot_damage"])
			player.attack_damage = maxi(player.attack_damage / 2, 1)
			player.shoot_damage = maxi(player.shoot_damage / 2, 1)
			_announce("СЛАБОСТЬ: твой урон вдвое меньше", true)
		"invasion":
			var came := 0
			for i in 3:
				if _spawn_near(player, INVADERS[randi() % INVADERS.size()]):
					came += 1
			_announce("НАШЕСТВИЕ: рядом появились враги (%d)" % came, false)
		"apples":
			for i in 2:
				_spawn_near(player, "+")
			_announce("ЯБЛОЧНЫЙ ДОЖДЬ: рядом лежат аптечки", false)


## Запоминает значения свойств игрока, чтобы вернуть их, когда эффект закончится.
func _remember(player, props: Array) -> void:
	_saved = {"player": player}
	for prop in props:
		_saved[prop] = player.get(prop)


func _announce(text: String, timed: bool) -> void:
	_effect = text if timed else ""
	_left = DURATION if timed else 0.0
	hint("ХАОС! " + text)


func _stop_effect() -> void:
	var player = _saved.get("player")
	if player != null and is_instance_valid(player):
		for key in _saved:
			if key != "player":
				player.set(key, _saved[key])
	_saved = {}
	_effect = ""


## Ставит врага или предмет на пол в 5–10 клетках от игрока. true — получилось.
func _spawn_near(player, symbol: String) -> bool:
	var level = get_level()
	if level == null:
		return false
	var here := Vector2i(floori(player.global_position.x / Game.TILE), floori((player.global_position.y - 1.0) / Game.TILE))
	for attempt in 24:
		var side := 1 if randf() < 0.5 else -1
		var tx: int = here.x + side * randi_range(5, 10)
		for dy in range(-4, 5):
			var ty: int = here.y + dy
			var free: bool = not level.is_solid_cell(Vector2i(tx, ty)) and not level.is_solid_cell(Vector2i(tx, ty - 1))
			if free and level.is_floor_cell(Vector2i(tx, ty + 1)) and not level.is_spike_cell(Vector2i(tx, ty)):
				return spawn(symbol, tx, ty) != null
	return false
