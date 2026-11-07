'use strict';
// «Лагерь гоблинов»: громилы, сапёры с бомбами, шаманы и вождь Гракс.
const { Mod } = require('../lib/modkit.js');
const kit = require('../lib/levelkit.js');
const art = require('../lib/art.js');
const { sprite } = require('../lib/packs.js');

module.exports = function build() {
  const mod = new Mod('goblin_warcamp', {
    name: 'Лагерь гоблинов',
    kind: 'pack',
    tagline: 'Красные громилы, сапёры с бомбами, шаманы со спорами и вождь Гракс, который швыряет бомбы дугой и зовёт гоблинов. Четыре уровня.',
    campaignTitle: 'Лагерь гоблинов',
    about: [
      'Гоблинский пак: враги собраны из спрайтов гоблина игры (громилы — красные, шаманы — ядовито-зелёные). Вождь Гракс в три раза крупнее обычного гоблина и командует всей бандой.',
    ],
    features: [
      '**Громила** (`a`) — крупный, крепкий, бьёт тяжело',
      '**Сапёр** (`u`) — швыряет бомбы по дуге',
      '**Шаман** (`h`) — кидает ядовитые споры',
      '**Вождь Гракс** (`X`) — босс: удар, дождь бомб, топот, призыв гоблинов и громил, таран',
      '4 уровня: «Частокол», «Лагерь», «Оружейная» (зачистка), «Шатёр вождя»',
    ],
    notes: ['В «Шатре вождя» Гракс зовёт и встроенных гоблинов (`g`), и своих громил (`a`).'],
  });

  art.make(mod, [
    ...['idle', 'run', 'attack', 'take_hit', 'death'].map((f) => ({ from: 'goblin', file: f, name: `brute_${f}`, preset: 'blood' })),
    ...['idle', 'run', 'attack', 'attack3', 'take_hit', 'death'].map((f) => ({ from: 'goblin', file: f, name: `sapper_${f}`, preset: 'none' })),
    ...['idle', 'run', 'attack', 'attack3', 'take_hit', 'death'].map((f) => ({ from: 'goblin', file: f, name: `shaman_${f}`, preset: 'toxic' })),
  ]);

  mod.json('enemies/brute.json', {
    id: 'brute', name: 'Громила', symbol: 'a',
    stats: { health: 90, reward: 28, speed: 2.4, aggro_range: 7, attack_range: 1.6, attack_damage: 17, attack_cooldown: 1.5, attack_duration: 0.55, attack_hit_time: 0.32, dodge_chance: 0.0 },
    sprite: sprite(mod, [150, 150], 2.0, { idle: ['brute_idle', 0.8], move: ['brute_run', 0.7], attack: ['brute_attack', 0.55], hurt: ['brute_take_hit', 0.3], death: ['brute_death', 0.7] }),
  });
  mod.json('enemies/sapper.json', {
    id: 'sapper', name: 'Сапёр', symbol: 'u',
    stats: { health: 28, reward: 22, speed: 3.0, aggro_range: 9, attack_range: 1.2, attack_damage: 9, attack_cooldown: 1.1, attack_duration: 0.5, attack_hit_time: 0.3, dodge_chance: 0.4 },
    throw: { projectile: 'bomb', damage: 13, cooldown: 3.0, min_range: 3, max_range: 7, scale: 0.9, explode_radius: 1.3, duration: 0.6, release_time: 0.4 },
    sprite: sprite(mod, [150, 150], 1.3, { idle: ['sapper_idle', 0.7], move: ['sapper_run', 0.55], attack: ['sapper_attack', 0.5], throw: ['sapper_attack3', 0.6], hurt: ['sapper_take_hit', 0.3], death: ['sapper_death', 0.6] }),
  });
  mod.json('enemies/shaman.json', {
    id: 'goblin_shaman', name: 'Шаман', symbol: 'h',
    stats: { health: 32, reward: 24, speed: 2.8, aggro_range: 9, attack_range: 1.2, attack_damage: 8, attack_cooldown: 1.3, attack_duration: 0.5, attack_hit_time: 0.3, dodge_chance: 0.4 },
    throw: { projectile: 'spore', damage: 11, cooldown: 3.2, min_range: 3, max_range: 8, scale: 1.2, explode_radius: 1.1, duration: 0.6, release_time: 0.4 },
    sprite: sprite(mod, [150, 150], 1.35, { idle: ['shaman_idle', 0.7], move: ['shaman_run', 0.55], attack: ['shaman_attack', 0.5], throw: ['shaman_attack3', 0.6], hurt: ['shaman_take_hit', 0.3], death: ['shaman_death', 0.6] }),
  });
  mod.json('bosses/grax.json', {
    id: 'grax', name: 'Вождь Гракс', symbol: 'X',
    stats: { health: 300, smart_health_multiplier: 1.5, speed: 2.3, stop_distance: 2.4, arena: 14, activation_range: 14, enrage_at: 0.5, max_minions: 5 },
    sprite: sprite(mod, [150, 150], 3.0, { idle: ['brute_idle', 0.9], run: ['brute_run', 0.7], attack: ['brute_attack', 0.5], hit: ['brute_take_hit', 0.3], death: ['brute_death', 0.9] }),
    attacks: [
      { type: 'melee', range: 2.8, damage: 19, interval: 1.5, windup: 0.3, animation: 'attack' },
      { type: 'projectile', pattern: 'lob', projectile: 'bomb', count: 3, enraged_count: 5, spread_tiles: 1.8, flight_time: 1.0, damage: 14, explode_radius: 1.4, interval: 6, min_range: 3, windup: 0.4, gap: 0.15, scale: 1.2, mouth: [1.6, -2.5], animation: 'attack' },
      { type: 'shockwave', radius: 9, speed: 9, damage: 18, interval: 9, windup: 0.4, animation: 'attack' },
      { type: 'summon', enemy: 'g', count: 2, interval: 14, windup: 0.5, near_player: true, animation: 'attack' },
      { type: 'summon', enemy: 'a', count: 1, interval: 22, windup: 0.5, near_player: true, animation: 'attack' },
      { type: 'charge', speed: 10, damage: 22, interval: 11, windup: 0.8, max_time: 1.5 },
    ],
  });

  const run = (i, slug, spec) => kit.makeRun(mod.p(mod.levelPath(i, slug)), Object.assign({ seed: 2100 + i * 29 }, spec));
  run(1, 'palisade', { title: 'Частокол', theme: 'wood', length: 100, enemies: { a: 2, u: 4, g: 4, h: 1 }, hazards: { pit: 1, mound: 1.5, platform: 1.5, spikes: 0.5, saw: 0.3 } });
  run(2, 'camp', { title: 'Лагерь', theme: 'meadow', length: 115, enemies: { a: 3, u: 4, h: 3, g: 3 }, hazards: { pit: 1, mound: 1, platform: 1, stairs: 1, fire: 1, saw: 1, spikes: 0.5 } });
  {
    const f = mod.p(mod.levelPath(3, 'armory'));
    const g = new kit.Grid(64, 20);
    g.rect(0, 0, 63, 1, '#');
    g.floor(18, 0, 63);
    g.rect(20, 16, 21, 17, '#'); g.rect(42, 16, 43, 17, '#');
    g.plat(16, 4, 10); g.put(7, 15, '+'); g.plat(14, 24, 40); g.put(32, 13, '+'); g.plat(16, 53, 59); g.put(56, 15, '+');
    g.put(2, 17, 'P'); g.put(61, 17, 'E');
    for (const x of [24, 40, 50]) g.put(x, 17, 'a');
    for (const x of [12, 30, 46]) g.put(x, 17, 'g');
    for (const [x, y] of [[8, 15], [32, 13], [57, 15]]) g.put(x, y, 'u');
    for (const x of [16, 36, 54]) g.put(x, 17, 'h');
    g.put(5, 17, '+'); g.put(60, 17, '+'); g.put(33, 17, '+');
    kit.writeTxt(f, { title: 'Оружейная', theme: 'wood', requireClear: true }, g.rows());
    const v = kit.validate(f); if (!v.clean) throw new Error(v.text);
  }
  kit.arena(mod.p(mod.levelPath(4, 'chief_tent')), {
    title: 'Шатёр вождя', theme: 'wood', width: 56,
    bosses: [[46, 'X']], platforms: [{ row: 16, x0: 6, x1: 12 }, { row: 14, x0: 14, x1: 30 }, { row: 16, x0: 32, x1: 38 }],
    apples: [4, 22, 40], extra: { win_boss: 'X' },
  });
  mod.finish();
  return mod;
};
