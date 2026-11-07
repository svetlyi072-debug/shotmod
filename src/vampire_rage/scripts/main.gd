extends ModScript
## «Жажда крови»: за каждого убитого врага игрок лечится, за босса — сильнее.
## Счёт убийств за всё время сохраняется между запусками игры.

## Сколько здоровья даёт обычный враг и босс.
const HEAL_ENEMY := 3
const HEAL_BOSS := 25
## Каждые столько убийств показывается подсказка.
const HINT_EVERY := 10

var kills := 0


func _mod_ready() -> void:
	kills = int(load_data().get("kills", 0))
	log_message("Жажда крови подключена. Убито за всё время: %d" % kills)


func _level_started(_level) -> void:
	hint("Жажда крови: за каждого убитого врага +%d здоровья" % HEAL_ENEMY)


func _enemy_killed(enemy, _power_reward) -> void:
	kills += 1
	var player = get_player()  # без типа: у игрока есть heal()
	if player != null and not player.is_dead():
		var amount := HEAL_BOSS if enemy is Boss else HEAL_ENEMY
		player.heal(amount)
	if kills % HINT_EVERY == 0:
		hint("Убито врагов за всё время: %d" % kills)
		save_data({"kills": kills})


func _boss_defeated() -> void:
	save_data({"kills": kills})
	hint("Босс повержен! Жажда крови утолена (+%d здоровья)" % HEAL_BOSS)
