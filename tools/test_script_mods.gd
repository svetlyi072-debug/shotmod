extends SceneTree
## Проверка скриптовых модов из D:/ShotMOD/mods в настоящей игре (по одному, на встроенных уровнях).
## Запуск: godot --headless --path D:/shootin --script D:/ShotMOD/tools/test_script_mods.gd

var fails := 0
var game
var mods


func check(cond: bool, msg: String) -> void:
	print(("OK   " if cond else "FAIL ") + msg)
	if not cond:
		fails += 1


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func cls(node) -> String:
	return node.get_script().get_global_name() if node.get_script() else ""


func open_level(index: int):
	game.leave_campaign()
	game.difficulty = 1
	game.level_index = index
	change_scene_to_file("res://scenes/main.tscn")
	await frames(30)
	return get_first_node_in_group("player")


## Включает только один скриптовый мод (остальные скриптовые — выкл.).
func only(id: String) -> void:
	for m in mods.mods:
		if m.has_scripts() and m.id != id and m.enabled:
			mods.set_enabled(m, false)
	var mod = mods.get_mod(id)
	mods.grant_script_consent(mod)
	mods.set_enabled(mod, true)


func script_of(id: String):
	for node in mods._scripts:
		if is_instance_valid(node) and node.mod.id == id:
			return node
	return null


func kill(enemy) -> void:
	enemy.take_damage(99999, enemy.global_position + Vector2(-20, 0))


func enemies_of(klass: String) -> Array:
	return get_nodes_in_group("enemies").filter(func(e): return cls(e) == klass)


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	game = root.get_node("Game")
	mods = root.get_node("Mods")
	seed(7)
	mods.extra_dirs.append("D:/ShotMOD/mods")
	await frames(1)
	mods.rescan()

	var script_ids := ["vampire_rage", "hardcore", "moon_gravity", "double_jump", "chaos_mode", "hud_plus", "speedrun_timer", "apple_drops", "boss_slowmo", "berserk"]
	for id in script_ids:
		var m = mods.get_mod(id)
		check(m != null and m.ok() and m.has_scripts(), "мод «%s» найден, скрипты на месте" % id)

	# ---------- Жажда крови ----------
	only("vampire_rage")
	var p = await open_level(5)
	check(mods.get_mod("vampire_rage").active and mods.get_mod("vampire_rage").problems.is_empty(), "«Жажда крови» загружена без проблем %s" % str(mods.get_mod("vampire_rage").problems))
	var victim = get_nodes_in_group("enemies")[0]
	p.health = 50
	kill(victim)
	await frames(3)
	check(p.health == 53, "убийство врага лечит на 3 (%d)" % p.health)
	var kills_before: int = script_of("vampire_rage").kills

	# ---------- Хардкор ----------
	only("hardcore")
	p = await open_level(0)
	var slime = enemies_of("Slime")[0]
	check(p.max_health == 70 and p.health == 70, "хардкор: у игрока 70 здоровья (%d)" % p.health)
	check(slime.max_health == 30, "хардкор: у слизня 30 вместо 20 (%d)" % slime.max_health)
	p.take_damage(10, p.global_position + Vector2(30, 0))
	await frames(3)
	check(p.health == 55, "хардкор: удар на 10 снимает 15 (%d)" % p.health)
	p.health = 70
	await frames(2)
	p.take_damage(200, p.global_position + Vector2(30, 0))
	await frames(5)
	check(p.is_dead(), "хардкор: смертельный удар убивает")

	# ---------- Лунная гравитация ----------
	only("moon_gravity")
	p = await open_level(0)
	var base_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	check(absf(p._gravity - base_gravity * 0.45) < 0.1 and absf(p.jump_height_tiles - 5.5) < 0.01, "лунная гравитация: g=%.0f, прыжок %.1f клетки" % [p._gravity, p.jump_height_tiles])
	var peak := 99999.0
	var start_y: float = p.global_position.y
	Input.action_press("jump")
	for i in 120:
		await physics_frame
		Input.action_release("jump")
		peak = minf(peak, p.global_position.y)
	check(start_y - peak > 32.0 * 4.8, "лунный прыжок поднимает больше 4,8 клетки (%.1f)" % ((start_y - peak) / 32.0))

	# ---------- Двойной прыжок ----------
	only("double_jump")
	p = await open_level(0)
	p.global_position += Vector2(0, -32.0 * 6)  # повисеть в воздухе
	p.velocity = Vector2.ZERO
	await frames(10)
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	await physics_frame
	var vy_after: float = p.velocity.y
	check(vy_after < -200.0, "двойной прыжок: в воздухе Space подбрасывает вверх (vy=%.0f)" % vy_after)
	await frames(30)
	var falling_before: float = p.velocity.y
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	await physics_frame
	var vy_third: float = p.velocity.y
	check(falling_before > 0.0 and vy_third > 0.0, "двойной прыжок: третьего прыжка нет (падение %.0f → %.0f)" % [falling_before, vy_third])
	# На земле счётчик сбрасывается.
	await frames(200)
	p.global_position += Vector2(0, -32.0 * 4)
	p.velocity = Vector2.ZERO
	await frames(2)
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	await physics_frame
	var vy_again: float = p.velocity.y
	check(vy_again < -200.0, "двойной прыжок: после приземления снова доступен (vy=%.0f)" % vy_again)

	# ---------- Режим хаоса ----------
	only("chaos_mode")
	p = await open_level(0)
	var chaos = script_of("chaos_mode")
	var base := {"jump": p.jump_height_tiles, "speed": p.run_speed_tiles, "attack": p.attack_damage, "shoot": p.shoot_damage, "gravity": p._gravity}
	var changed := 0
	var spawned := 0
	for i in 40:
		var enemies_before: int = get_nodes_in_group("enemies").size()
		var pickups_before: int = get_nodes_in_group("health_pickups").size()
		chaos._start_effect(p)
		await frames(2)
		var differs: bool = p.jump_height_tiles != base["jump"] or p.run_speed_tiles != base["speed"] or p.attack_damage != base["attack"] or p.shoot_damage != base["shoot"]
		if differs:
			changed += 1
		if get_nodes_in_group("enemies").size() > enemies_before or get_nodes_in_group("health_pickups").size() > pickups_before:
			spawned += 1
		chaos._stop_effect()
		var restored: bool = p.jump_height_tiles == base["jump"] and p.run_speed_tiles == base["speed"] and p.attack_damage == base["attack"] and p.shoot_damage == base["shoot"] and absf(p._gravity - base["gravity"]) < 0.01
		if not restored:
			check(false, "хаос: эффект не откатился на итерации %d" % i)
			break
	check(changed >= 10 and spawned >= 3, "хаос: эффекты меняют игрока (%d раз) и приводят врагов/яблоки (%d раз), всё откатывается" % [changed, spawned])
	var timer_before: float = chaos._timer
	await frames(60)
	check(chaos._timer < timer_before, "хаос: таймер событий идёт")

	# ---------- Полоски здоровья и урон ----------
	only("hud_plus")
	p = await open_level(0)
	var target = enemies_of("Slime")[0]
	var bar_count := 0
	for child in target.get_children():
		if child.get_script() != null and not (child is CollisionShape2D):
			bar_count += 1
	check(bar_count >= 1, "над врагом висит полоска здоровья")
	var texts_before: int = p.get_parent().get_children().filter(func(n): return n.get_script() != null).size()
	target.take_damage(5, target.global_position + Vector2(-20, 0))
	await frames(3)
	var level_entities = current_scene.get_node("Level/Entities")
	var float_count := 0
	for n in level_entities.get_children():
		if n.get_script() != null and n.get("text") != null and str(n.get("text")).begins_with("-"):
			float_count += 1
	check(float_count >= 1, "при попадании всплывает число урона")
	var hud_script = script_of("hud_plus")
	kill(target)
	await frames(3)
	check(hud_script._label.text == "Убито: 1", "счётчик убийств: «%s»" % hud_script._label.text)

	# ---------- Спидран-таймер ----------
	only("speedrun_timer")
	p = await open_level(0)
	var timer_mod = script_of("speedrun_timer")
	await frames(60)
	check(timer_mod._time > 0.8 and timer_mod._time < 1.6, "таймер идёт: %.2f с за секунду игры" % timer_mod._time)
	var hint_text := [""]
	game.hint.connect(func(text: String): hint_text[0] = text)
	game.complete_level(p.power)
	await frames(3)
	check(hint_text[0].contains("РЕКОРД"), "первое прохождение — рекорд: «%s»" % hint_text[0])
	check(not timer_mod._running, "после прохождения таймер остановлен")
	check(mods.load_mod_data(mods.get_mod("speedrun_timer")).get("best", {}).size() == 1, "рекорд сохранён на диск")

	# ---------- Яблоки с врагов ----------
	only("apple_drops")
	p = await open_level(5)
	var pickups_start: int = get_nodes_in_group("health_pickups").size()
	var dead := 0
	for e in get_nodes_in_group("enemies").duplicate():
		kill(e)
		dead += 1
	await frames(5)
	var pickups_end: int = get_nodes_in_group("health_pickups").size()
	check(dead >= 5 and pickups_end > pickups_start, "из %d убитых выпали яблоки (+%d)" % [dead, pickups_end - pickups_start])
	# Босс: два яблока.
	p = await open_level(25)
	var boss = enemies_of("ZombieKing")[0]
	var before_boss: int = get_nodes_in_group("health_pickups").size()
	boss._activate()
	kill(boss)
	await frames(5)
	check(get_nodes_in_group("health_pickups").size() - before_boss == 2, "с босса выпадают два яблока (%d)" % (get_nodes_in_group("health_pickups").size() - before_boss))

	# ---------- Финальный удар ----------
	only("boss_slowmo")
	p = await open_level(25)
	boss = enemies_of("ZombieKing")[0]
	boss._activate()
	kill(boss)
	await frames(3)
	check(Engine.time_scale == 0.25, "победа над боссом замедляет время (%.2f)" % Engine.time_scale)
	await create_timer(1.9, true, false, true).timeout
	check(Engine.time_scale == 1.0, "время возвращается (%.2f)" % Engine.time_scale)

	# ---------- Берсерк ----------
	only("berserk")
	p = await open_level(5)
	var base_attack: int = 10
	check(p.attack_damage == base_attack, "берсерк: урон до комбо %d" % p.attack_damage)
	var victims = get_nodes_in_group("enemies").duplicate()
	for i in 3:
		kill(victims[i])
		await frames(2)
	check(p.attack_damage == 13 and p.run_speed_tiles > 5.2, "берсерк: комбо ×3 → урон 13, бег %.2f" % p.run_speed_tiles)
	await frames(260)
	check(p.attack_damage == 10 and absf(p.run_speed_tiles - 5.0) < 0.001, "берсерк: комбо сбрасывается через 4 с")

	# ---------- Уборка ----------
	for id in script_ids:
		var m = mods.get_mod(id)
		if m.enabled:
			mods.set_enabled(m, false)
	game.leave_campaign()
	game.clear_progress()
	mods.extra_dirs.clear()
	mods._deactivate_all()
	for f in ["user://mods.cfg", "user://mod_progress.cfg"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	var data_dir := ProjectSettings.globalize_path("user://mod_data")
	for f in ["speedrun_timer.json", "vampire_rage.json"]:
		if FileAccess.file_exists(data_dir.path_join(f)):
			DirAccess.remove_absolute(data_dir.path_join(f))
	print("ИТОГ: %s (%d ошибок)" % ["ВСЁ ХОРОШО" if fails == 0 else "ЕСТЬ ОШИБКИ", fails])
	quit(1 if fails else 0)
