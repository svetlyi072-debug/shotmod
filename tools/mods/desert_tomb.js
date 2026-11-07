'use strict';
// «Гробница фараона»: песчаные мумии, скарабеи, шаманы, стражи и босс «Фараон».
const { Mod } = require('../lib/modkit.js');
const kit = require('../lib/levelkit.js');
const art = require('../lib/art.js');
const { sprite } = require('../lib/packs.js');

module.exports = function build() {
  const mod = new Mod('desert_tomb', {
    name: 'Гробница фараона',
    kind: 'pack',
    tagline: 'Пески, мумии, стаи скарабеев, песчаные шаманы, золотые стражи гробницы — и Фараон, который зовёт мумий и бьёт ударной волной. Четыре уровня.',
    campaignTitle: 'Гробница фараона',
    about: [
      'Перекрашенные в песок и золото спрайты игры, пять новых типов врагов и босс, описанный данными. Скарабеи быстрые и хрупкие, стражи — медленные и очень крепкие.',
    ],
    features: [
      '**Мумия** (`u`) — ходит и рубит',
      '**Скарабей** (`a`) — очень быстрый, кусает',
      '**Песчаный шаман** (`h`) — бросает магические заряды издалека',
      '**Страж гробницы** (`i`) — тяжёлый воин в золоте',
      '**Фараон** (`H`) — босс: удар, веер зарядов, ударная волна, призыв мумий, таран',
      '4 уровня: «Пески», «Гробница», «Крипта скарабеев» (зачистка), «Зал Фараона»',
    ],
  });

  art.make(mod, [
    ...['idle', 'walk', 'attack', 'take_hit', 'death'].map((f) => ({ from: 'skeleton', file: f, name: `mummy_${f}`, preset: 'sand' })),
    ...['idle', 'run', 'bite', 'hurt', 'death'].map((f) => ({ from: 'rat', file: f, name: `scarab_${f}`, preset: 'sand' })),
    ...['idle', 'run', 'attack', 'attack3', 'take_hit', 'death'].map((f) => ({ from: 'goblin', file: f, name: `shaman_${f}`, preset: 'sand' })),
    ...[['Idle', 'idle'], ['Run', 'run'], ['Attack1', 'attack'], ['Take Hit', 'hit'], ['Death', 'death']].map(([f, n]) => ({ from: 'knight', file: f, name: `guard_${n}`, preset: 'gold' })),
    ...[['Idle', 'idle'], ['Run', 'run'], ['Attack1', 'attack'], ['Attack2', 'attack2'], ['Attack3', 'smash'], ['Take Hit', 'hit'], ['Death', 'death']].map(([f, n]) => ({ from: 'king', file: f, name: `pharaoh_${n}`, preset: 'gold' })),
  ]);

  mod.json('enemies/mummy.json', {
    id: 'mummy', name: 'Мумия', symbol: 'u',
    stats: { health: 50, reward: 15, speed: 2.3, aggro_range: 7, attack_range: 1.6, attack_damage: 14, attack_cooldown: 1.4, attack_duration: 0.5, attack_hit_time: 0.28, dodge_chance: 0.2 },
    sprite: sprite(mod, [150, 150], 1.25, { idle: ['mummy_idle', 0.8], move: ['mummy_walk', 0.6], attack: ['mummy_attack', 0.5], hurt: ['mummy_take_hit', 0.3], death: ['mummy_death', 0.6] }),
  });
  mod.json('enemies/scarab.json', {
    id: 'scarab', name: 'Скарабей', symbol: 'a',
    stats: { health: 14, reward: 6, speed: 5.0, aggro_range: 8, attack_range: 1.0, attack_damage: 6, attack_cooldown: 0.9, attack_duration: 0.3, attack_hit_time: 0.15, dodge_chance: 0.3 },
    sprite: sprite(mod, [70, 70], 1.0, { idle: ['scarab_idle', 0.9], move: ['scarab_run', 0.5], attack: ['scarab_bite', 0.3], hurt: ['scarab_hurt', 0.25], death: ['scarab_death', 0.5] }),
  });
  mod.json('enemies/shaman.json', {
    id: 'sand_shaman', name: 'Песчаный шаман', symbol: 'h',
    stats: { health: 34, reward: 22, speed: 2.8, aggro_range: 9, attack_range: 1.2, attack_damage: 8, attack_cooldown: 1.3, attack_duration: 0.5, attack_hit_time: 0.3, dodge_chance: 0.4 },
    throw: { projectile: 'bolt', damage: 11, cooldown: 3.0, min_range: 3, max_range: 8, scale: 1.0, explode_radius: 1.0, duration: 0.6, release_time: 0.4 },
    sprite: sprite(mod, [150, 150], 1.3, { idle: ['shaman_idle', 0.7], move: ['shaman_run', 0.55], attack: ['shaman_attack', 0.5], throw: ['shaman_attack3', 0.6], hurt: ['shaman_take_hit', 0.3], death: ['shaman_death', 0.6] }),
  });
  mod.json('enemies/guard.json', {
    id: 'tomb_guard', name: 'Страж гробницы', symbol: 'i',
    stats: { health: 120, reward: 32, speed: 1.9, aggro_range: 6, attack_range: 1.7, attack_damage: 19, attack_cooldown: 1.9, attack_duration: 0.55, attack_hit_time: 0.32, dodge_chance: 0.0 },
    sprite: sprite(mod, [180, 180], 1.15, { idle: ['guard_idle', 1.2], move: ['guard_run', 0.85], attack: ['guard_attack', 0.55], hurt: ['guard_hit', 0.3], death: ['guard_death', 1.1] }),
  });
  mod.json('bosses/pharaoh.json', {
    id: 'pharaoh', name: 'Фараон', symbol: 'H',
    stats: { health: 280, smart_health_multiplier: 1.5, speed: 2.0, stop_distance: 2.2, arena: 14, activation_range: 14, enrage_at: 0.5, max_minions: 4 },
    sprite: sprite(mod, [160, 111], 1.9, { idle: ['pharaoh_idle', 1.1], run: ['pharaoh_run', 0.8], attack: ['pharaoh_attack', 0.4], attack2: ['pharaoh_attack2', 0.4], smash: ['pharaoh_smash', 0.5], hit: ['pharaoh_hit', 0.3], death: ['pharaoh_death', 0.9] }),
    attacks: [
      { type: 'melee', range: 2.3, damage: 16, interval: 1.4, windup: 0.22, animation: 'attack' },
      { type: 'projectile', pattern: 'fan', projectile: 'bolt', count: 3, enraged_count: 5, spread: 13, speed: 9, damage: 10, interval: 5, min_range: 3, windup: 0.3, gap: 0, scale: 1.4, mouth: [1.4, -1.8], animation: 'attack2' },
      { type: 'shockwave', radius: 9, speed: 9, damage: 18, interval: 8, windup: 0.3, animation: 'smash' },
      { type: 'summon', enemy: 'u', count: 2, interval: 15, windup: 0.5, near_player: true, animation: 'attack' },
      { type: 'charge', speed: 10, damage: 20, interval: 10, windup: 0.7, max_time: 1.5 },
    ],
  });

  const run = (i, slug, spec) => kit.makeRun(mod.p(mod.levelPath(i, slug)), Object.assign({ seed: 1300 + i * 19 }, spec));
  run(1, 'sands', { title: 'Пески', theme: 'clay', length: 100, enemies: { u: 5, a: 6, h: 2 }, hazards: { pit: 1.5, mound: 1.5, spikes: 0.5, platform: 1, saw: 0.4 } });
  run(2, 'tomb', { title: 'Гробница', theme: 'stone', length: 115, enemies: { u: 5, h: 3, i: 2, a: 4 }, hazards: { fire: 1.5, saw: 1.5, ball: 1, spikes: 0.7, pit: 1, mound: 1, stairs: 1 } });
  {
    const f = mod.p(mod.levelPath(3, 'scarab_crypt'));
    const g = new kit.Grid(64, 20);
    g.rect(0, 0, 63, 1, '#');
    g.floor(18, 0, 63);
    g.rect(20, 16, 21, 17, '#'); g.rect(42, 16, 43, 17, '#');
    g.plat(16, 4, 10); g.put(7, 15, '+'); g.plat(14, 24, 40); g.put(32, 13, '+'); g.plat(16, 53, 59); g.put(56, 15, '+');
    g.put(2, 17, 'P'); g.put(61, 17, 'E');
    for (const x of [12, 15, 18, 26, 29, 32, 35, 38, 46, 49, 52, 55, 58, 8]) g.put(x, 17, 'a');
    for (const x of [24, 40, 50]) g.put(x, 17, 'u');
    for (const x of [30, 45]) g.put(x, 17, 'i');
    g.put(5, 17, '+'); g.put(60, 17, '+'); g.put(33, 17, '+');
    kit.writeTxt(f, { title: 'Крипта скарабеев', theme: 'stone', requireClear: true }, g.rows());
    const v = kit.validate(f); if (!v.clean) throw new Error(v.text);
  }
  kit.arena(mod.p(mod.levelPath(4, 'pharaoh_hall')), {
    title: 'Зал Фараона', theme: 'clay', width: 56,
    bosses: [[46, 'H']], platforms: [{ row: 16, x0: 6, x1: 12 }, { row: 14, x0: 14, x1: 30 }, { row: 16, x0: 32, x1: 38 }],
    apples: [4, 24, 40], extra: { win_boss: 'H' },
  });
  mod.finish();
  return mod;
};
