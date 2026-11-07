'use strict';
// «Преисподняя»: огненные враги, босс «Владыка пламени» и четыре уровня.
const { Mod } = require('../lib/modkit.js');
const kit = require('../lib/levelkit.js');
const art = require('../lib/art.js');
const { sprite } = require('../lib/packs.js');

module.exports = function build() {
  const mod = new Mod('inferno_pack', {
    name: 'Преисподняя',
    kind: 'pack',
    tagline: 'Огненные скелеты, бесы с огненными шарами, лавовые воины, пепельные мертвецы из праха — и босс «Владыка пламени» с огненным дождём. Четыре уровня.',
    campaignTitle: 'Преисподняя',
    about: [
      'Новые враги с новой графикой (перекрашенные спрайты игры в цвета огня) и боссом, чьи атаки описаны данными: удар, веер огненных шаров, огненный дождь с красными метками, ударная волна, призыв бесов и таран.',
      'Огненные ловушки в этом аду на каждом шагу — враги их тоже боятся.',
    ],
    features: [
      '**Огненный скелет** (`F`) — быстрый, рубит мечом',
      '**Бес** (`I`) — держит дистанцию и бросает огненные шары',
      '**Лавовый воин** (`S`) — медленный, крепкий, бьёт тяжело',
      '**Пепельный** (`Q`) — лежит в прахе и встаёт, когда подойдёшь',
      '**Владыка пламени** (`L`) — босс',
      '4 уровня: «Врата ада», «Лавовые мосты», «Пепельный зал» (зачистка), «Трон Владыки»',
    ],
    notes: ['Символы врагов можно использовать в своих уровнях: этот мод их определяет (см. папку `enemies/`).'],
  });

  art.make(mod, [
    ...['idle', 'walk', 'attack', 'attack3', 'take_hit', 'death'].map((f) => ({ from: 'skeleton', file: f, name: `fskel_${f}`, preset: 'fire' })),
    ...['idle', 'run', 'attack', 'attack3', 'take_hit', 'death'].map((f) => ({ from: 'goblin', file: f, name: `imp_${f}`, preset: 'fire' })),
    ...[['Idle', 'idle'], ['Run', 'run'], ['Attack1', 'attack'], ['Attack2', 'attack2'], ['Take Hit', 'hit'], ['Death', 'death']].map(([f, n]) => ({ from: 'knight', file: f, name: `lava_${n}`, preset: 'fire' })),
    ...['idle', 'walk', 'attack', 'take_hit', 'death'].map((f) => ({ from: 'skeleton', file: f, name: `ash_${f}`, preset: 'blood' })),
  ]);

  mod.json('enemies/fire_skeleton.json', {
    id: 'fire_skeleton', name: 'Огненный скелет', symbol: 'F',
    stats: { health: 45, reward: 15, speed: 2.6, aggro_range: 7, attack_range: 1.6, attack_damage: 14, attack_cooldown: 1.3, attack_duration: 0.5, attack_hit_time: 0.28, dodge_chance: 0.3 },
    sprite: sprite(mod, [150, 150], 1.25, {
      idle: ['fskel_idle', 0.8], move: ['fskel_walk', 0.55], attack: ['fskel_attack', 0.5], hurt: ['fskel_take_hit', 0.3], death: ['fskel_death', 0.6],
    }),
  });
  mod.json('enemies/imp.json', {
    id: 'imp', name: 'Бес', symbol: 'I',
    stats: { health: 30, reward: 20, speed: 3.2, aggro_range: 9, attack_range: 1.2, attack_damage: 9, attack_cooldown: 1.2, attack_duration: 0.5, attack_hit_time: 0.3, dodge_chance: 0.4 },
    throw: { projectile: 'fireball', damage: 10, cooldown: 2.8, min_range: 3, max_range: 8, scale: 0.9, explode_radius: 1.1, duration: 0.6, release_time: 0.4 },
    sprite: sprite(mod, [150, 150], 1.3, {
      idle: ['imp_idle', 0.7], move: ['imp_run', 0.55], attack: ['imp_attack', 0.5], throw: ['imp_attack3', 0.6], hurt: ['imp_take_hit', 0.3], death: ['imp_death', 0.6],
    }),
  });
  mod.json('enemies/lava_warrior.json', {
    id: 'lava_warrior', name: 'Лавовый воин', symbol: 'S',
    stats: { health: 110, reward: 30, speed: 2.0, aggro_range: 6, attack_range: 1.6, attack_damage: 18, attack_cooldown: 1.8, attack_duration: 0.55, attack_hit_time: 0.3, dodge_chance: 0.0 },
    sprite: sprite(mod, [180, 180], 1.15, {
      idle: ['lava_idle', 1.2], move: ['lava_run', 0.8], attack: ['lava_attack', 0.55], hurt: ['lava_hit', 0.3], death: ['lava_death', 1.1],
    }),
  });
  mod.json('enemies/ashen.json', {
    id: 'ashen', name: 'Пепельный', symbol: 'Q',
    stats: { health: 40, reward: 20, speed: 3.0, aggro_range: 8, attack_range: 1.5, attack_damage: 12, attack_cooldown: 1.3, attack_duration: 0.5, attack_hit_time: 0.28, dodge_chance: 0.0 },
    dormant: { wake_range: 2.2, wake_time: 0.8, lying_height: 12 },
    sprite: sprite(mod, [150, 150], 1.25, {
      closed: ['ash_death', 1, { first: 3, count: 1 }], wake: ['ash_death', 0.8, { reverse: true }],
      idle: ['ash_idle', 0.8], move: ['ash_walk', 0.5], attack: ['ash_attack', 0.5], hurt: ['ash_take_hit', 0.3], death: ['ash_death', 0.6],
    }),
  });
  mod.json('bosses/flame_lord.json', {
    id: 'flame_lord', name: 'Владыка пламени', symbol: 'L',
    stats: { health: 300, smart_health_multiplier: 1.5, speed: 2.2, stop_distance: 2.2, arena: 14, activation_range: 14, enrage_at: 0.5, max_minions: 4 },
    sprite: sprite(mod, [180, 180], 2.0, {
      idle: ['lava_idle', 1.2], run: ['lava_run', 0.8], attack: ['lava_attack', 0.5], attack2: ['lava_attack2', 0.5], hit: ['lava_hit', 0.3], death: ['lava_death', 1.1],
    }),
    attacks: [
      { type: 'melee', range: 2.5, damage: 18, interval: 1.5, windup: 0.3, animation: 'attack' },
      { type: 'projectile', pattern: 'fan', projectile: 'fireball', count: 3, enraged_count: 5, spread: 12, speed: 9, damage: 10, interval: 5, min_range: 3, windup: 0.35, gap: 0, scale: 1.4, mouth: [1.6, -1.6], animation: 'attack2' },
      { type: 'projectile', pattern: 'rain', projectile: 'fireball', waves: 2, wave_gap: 1.4, width: 9, spacing: 1.9, damage: 10, interval: 13, windup: 0.6, scale: 1.3, animation: 'attack2' },
      { type: 'shockwave', radius: 9, speed: 9, damage: 18, interval: 9, windup: 0.4, animation: 'attack2' },
      { type: 'summon', enemy: 'I', count: 2, interval: 16, windup: 0.6, near_player: true, animation: 'attack' },
      { type: 'charge', speed: 11, damage: 22, interval: 10, windup: 0.7, max_time: 1.5 },
    ],
  });

  const run = (i, slug, spec) => kit.makeRun(mod.p(mod.levelPath(i, slug)), Object.assign({ seed: 900 + i * 13 }, spec));
  run(1, 'hell_gates', { title: 'Врата ада', theme: 'brick', length: 100, enemies: { F: 6, I: 3, Q: 2 }, hazards: { fire: 3, pit: 1, mound: 1, platform: 1, spikes: 0.5, saw: 0.3 } });
  run(2, 'lava_bridges', { title: 'Лавовые мосты', theme: 'clay', length: 120, enemies: { F: 4, I: 4, S: 2, Q: 2 }, hazards: { fire: 2.5, pit: 2, mound: 1, platform: 1, stairs: 1, saw: 0.5 } });
  {
    const f = mod.p(mod.levelPath(3, 'ash_hall'));
    const g = new kit.Grid(68, 20);
    g.rect(0, 0, 67, 1, '#');
    g.floor(18, 0, 67);
    g.rect(22, 16, 23, 17, '#'); g.rect(44, 16, 45, 17, '#');
    g.plat(16, 4, 11); g.put(7, 15, '+'); g.plat(14, 26, 42); g.put(34, 13, '+'); g.plat(16, 56, 63); g.put(59, 15, '+');
    g.put(2, 17, 'P'); g.put(65, 17, 'E');
    for (const x of [10, 16, 30, 36, 50, 54, 60]) g.put(x, 17, 'Q');
    for (const x of [20, 40, 62]) g.put(x, 17, 'F');
    for (const x of [28, 48]) g.put(x, 17, 'S');
    for (const [x, y] of [[9, 15], [34, 13], [61, 15]]) g.put(x, y, 'I');
    g.put(5, 17, '+'); g.put(57, 17, '+'); g.put(34, 17, '+');
    kit.writeTxt(f, { title: 'Пепельный зал', theme: 'brick', requireClear: true }, g.rows());
    const v = kit.validate(f); if (!v.clean) throw new Error(v.text);
  }
  kit.arena(mod.p(mod.levelPath(4, 'flame_throne')), {
    title: 'Трон Владыки', theme: 'clay', width: 56, ceiling: false,
    bosses: [[46, 'L']], platforms: [{ row: 16, x0: 6, x1: 12 }, { row: 16, x0: 20, x1: 26 }, { row: 16, x0: 32, x1: 38 }],
    apples: [4, 16, 30], extra: { win_boss: 'L' },
  });
  mod.finish();
  return mod;
};
