'use strict';
// «Царство теней»: теневые рыцари, призрачные маги, тени из мрака и босс «Теневой властелин».
const { Mod } = require('../lib/modkit.js');
const kit = require('../lib/levelkit.js');
const art = require('../lib/art.js');
const { sprite } = require('../lib/packs.js');

module.exports = function build() {
  const mod = new Mod('shadow_realm', {
    name: 'Царство теней',
    kind: 'pack',
    tagline: 'Фиолетовый мрак: теневые рыцари, призрачные маги, тени, встающие из темноты, — и Теневой властелин с огненными… то есть теневыми шарами. Четыре уровня.',
    campaignTitle: 'Царство теней',
    about: [
      'Пак с новой графикой (спрайты игры в фиолетово-чёрной палитре) и боссом, чьи атаки описаны данными. Властелин зовёт теней из-под земли, бьёт волной и рушит на арену дождь зарядов с красными метками.',
    ],
    features: [
      '**Теневой рыцарь** (`e`) — тяжёлый воин',
      '**Призрачный маг** (`v`) — бросает заряды',
      '**Тень** (`t`) — прячется в земле и встаёт, когда подойдёшь',
      '**Теневой властелин** (`D`) — босс',
      '4 уровня: «Сумеречная дорога», «Склеп теней», «Зал зеркал» (зачистка), «Трон властелина»',
    ],
  });

  art.make(mod, [
    ...[['Idle', 'idle'], ['Run', 'run'], ['Attack1', 'attack'], ['Take Hit', 'hit'], ['Death', 'death']].map(([f, n]) => ({ from: 'knight', file: f, name: `knight_${n}`, preset: 'shadow' })),
    ...['idle', 'run', 'attack1', 'attack2', 'take_hit', 'death'].map((f) => ({ from: 'wizard', file: f, name: `mage_${f}`, preset: 'shadow' })),
    ...['idle', 'walk', 'attack', 'take_hit', 'death'].map((f) => ({ from: 'skeleton', file: f, name: `shade_${f}`, preset: 'shadow' })),
  ]);

  mod.json('enemies/shadow_knight.json', {
    id: 'shadow_knight', name: 'Теневой рыцарь', symbol: 'e',
    stats: { health: 100, reward: 28, speed: 2.1, aggro_range: 6, attack_range: 1.6, attack_damage: 17, attack_cooldown: 1.7, attack_duration: 0.55, attack_hit_time: 0.3, dodge_chance: 0.0 },
    sprite: sprite(mod, [180, 180], 1.15, { idle: ['knight_idle', 1.2], move: ['knight_run', 0.8], attack: ['knight_attack', 0.55], hurt: ['knight_hit', 0.3], death: ['knight_death', 1.1] }),
  });
  mod.json('enemies/ghost_mage.json', {
    id: 'ghost_mage', name: 'Призрачный маг', symbol: 'v',
    stats: { health: 36, reward: 24, speed: 2.4, aggro_range: 9, attack_range: 1.2, attack_damage: 8, attack_cooldown: 1.4, attack_duration: 0.5, attack_hit_time: 0.3, dodge_chance: 0.4 },
    throw: { projectile: 'bolt', damage: 12, cooldown: 3.0, min_range: 3.5, max_range: 8, scale: 1.1, explode_radius: 1.0, duration: 0.6, release_time: 0.4 },
    sprite: sprite(mod, [250, 250], 0.55, { idle: ['mage_idle', 0.9], move: ['mage_run', 0.7], attack: ['mage_attack2', 0.5], throw: ['mage_attack1', 0.6], hurt: ['mage_take_hit', 0.3], death: ['mage_death', 0.9] }),
  });
  mod.json('enemies/shade.json', {
    id: 'shade', name: 'Тень', symbol: 't',
    stats: { health: 38, reward: 20, speed: 3.0, aggro_range: 8, attack_range: 1.5, attack_damage: 12, attack_cooldown: 1.2, attack_duration: 0.5, attack_hit_time: 0.28, dodge_chance: 0.2 },
    dormant: { wake_range: 2.2, wake_time: 0.8, lying_height: 12 },
    sprite: sprite(mod, [150, 150], 1.25, {
      closed: ['shade_death', 1, { first: 3, count: 1 }], wake: ['shade_death', 0.8, { reverse: true }],
      idle: ['shade_idle', 0.8], move: ['shade_walk', 0.5], attack: ['shade_attack', 0.5], hurt: ['shade_take_hit', 0.3], death: ['shade_death', 0.6],
    }),
  });
  mod.json('bosses/shadow_lord.json', {
    id: 'shadow_lord', name: 'Теневой властелин', symbol: 'D',
    stats: { health: 280, smart_health_multiplier: 1.5, speed: 2.0, stop_distance: 4.5, arena: 14, activation_range: 14, enrage_at: 0.5, max_minions: 4 },
    sprite: sprite(mod, [250, 250], 1.0, { idle: ['mage_idle', 1.0], run: ['mage_run', 0.7], attack: ['mage_attack2', 0.5], attack2: ['mage_attack1', 0.6], hit: ['mage_take_hit', 0.3], death: ['mage_death', 1.0] }),
    attacks: [
      { type: 'melee', range: 2.4, damage: 17, interval: 1.6, windup: 0.3, animation: 'attack' },
      { type: 'projectile', pattern: 'fan', projectile: 'bolt', count: 3, enraged_count: 5, spread: 14, speed: 9, damage: 11, interval: 4.5, min_range: 3, windup: 0.4, gap: 0, scale: 1.5, mouth: [1.8, -2.2], animation: 'attack2' },
      { type: 'projectile', pattern: 'rain', projectile: 'bolt', waves: 2, wave_gap: 1.4, width: 9, spacing: 1.9, damage: 11, interval: 13, windup: 0.5, scale: 1.4, animation: 'attack2' },
      { type: 'shockwave', radius: 8, speed: 9, damage: 18, interval: 10, windup: 0.4, animation: 'attack' },
      { type: 'summon', enemy: 't', count: 2, interval: 16, windup: 0.6, near_player: true, animation: 'attack2' },
    ],
  });

  const run = (i, slug, spec) => kit.makeRun(mod.p(mod.levelPath(i, slug)), Object.assign({ seed: 1700 + i * 23 }, spec));
  run(1, 'twilight_road', { title: 'Сумеречная дорога', theme: 'crypt', length: 105, enemies: { e: 3, v: 3, t: 4 }, flyers: { b: 2 }, hazards: { pit: 1, mound: 1, platform: 1, spikes: 0.5, saw: 0.5 } });
  run(2, 'shadow_crypt', { title: 'Склеп теней', theme: 'stone', length: 120, enemies: { e: 4, v: 4, t: 6 }, flyers: { b: 3 }, hazards: { fire: 1, saw: 1, ball: 1, pit: 1, mound: 1, stairs: 1, spikes: 0.5 } });
  {
    const f = mod.p(mod.levelPath(3, 'mirror_hall'));
    const g = new kit.Grid(68, 20);
    g.rect(0, 0, 67, 1, '#');
    g.floor(18, 0, 67);
    g.rect(22, 16, 23, 17, '#'); g.rect(44, 16, 45, 17, '#');
    g.plat(16, 4, 11); g.put(7, 15, '+'); g.plat(14, 26, 42); g.put(34, 13, '+'); g.plat(16, 56, 63); g.put(59, 15, '+');
    g.put(2, 17, 'P'); g.put(65, 17, 'E');
    for (const x of [10, 16, 30, 36, 50, 54, 60]) g.put(x, 17, 't');
    for (const x of [28, 48]) g.put(x, 17, 'e');
    for (const [x, y] of [[9, 15], [34, 13], [61, 15], [24, 17]]) g.put(x, y, 'v');
    g.put(5, 17, '+'); g.put(57, 17, '+'); g.put(34, 17, '+');
    kit.writeTxt(f, { title: 'Зал зеркал', theme: 'brick', requireClear: true }, g.rows());
    const v = kit.validate(f); if (!v.clean) throw new Error(v.text);
  }
  kit.arena(mod.p(mod.levelPath(4, 'lord_throne')), {
    title: 'Трон властелина', theme: 'crypt', width: 56, ceiling: false,
    bosses: [[46, 'D']], platforms: [{ row: 16, x0: 6, x1: 12 }, { row: 16, x0: 20, x1: 26 }, { row: 16, x0: 32, x1: 38 }],
    apples: [4, 16, 30], extra: { win_boss: 'D' },
  });
  mod.finish();
  return mod;
};
