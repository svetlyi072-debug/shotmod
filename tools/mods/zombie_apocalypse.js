'use strict';
// «Зомби-апокалипсис»: шесть уровней, полных мертвецов.
const { Mod } = require('../lib/modkit.js');
const kit = require('../lib/levelkit.js');

module.exports = function build() {
  const mod = new Mod('zombie_apocalypse', {
    name: 'Зомби-апокалипсис',
    kind: 'levels',
    tagline: 'Шесть уровней, кишащих мертвецами: обычные зомби, могильные (встают из земли), рыцари-мертвецы и в конце — Король зомби.',
    campaignTitle: 'Зомби-апокалипсис',
    about: [
      'Окраина, кладбище, баррикада, склеп, зал мертвецов — и трон Короля зомби. Могильные зомби лежат в земле, пока не подойдёшь ближе двух клеток; удар по ним тоже будит. Рыцарь-мертвец медленный, но бьёт тяжело.',
      'В закрытых залах («Баррикада», «Зал мертвецов») выход открывается, только когда не останется ни одного врага.',
    ],
    features: ['6 уровней', 'зомби `z`, могильные `y`, рыцари `x`, немного скелетов', 'два закрытых зала на зачистку', 'финальный босс — Король зомби'],
    credits: 'Карты и описание — автор мода. Графика — из игры ShootIn.',
  });
  const run = (i, slug, spec) => kit.makeRun(mod.p(mod.levelPath(i, slug)), Object.assign({ seed: 500 + i * 17 }, spec));

  run(1, 'outskirts', { title: 'Окраина', theme: 'meadow', length: 100, enemies: { z: 8, y: 3 }, hazards: { pit: 1, mound: 1.5, platform: 1.5, spikes: 0.3, saw: 0.3 } });
  run(2, 'graveyard', { title: 'Кладбище', theme: 'crypt', length: 110, enemies: { y: 8, z: 6, x: 2 }, hazards: { pit: 0.7, mound: 1.5, platform: 1.5, stairs: 1, fire: 0.5 } });

  // Закрытый зал 3 — «Баррикада».
  {
    const f = mod.p(mod.levelPath(3, 'barricade'));
    const { Grid } = kit;
    const g = new Grid(64, 20);
    g.rect(0, 0, 63, 1, '#');
    g.floor(18, 0, 63);
    g.rect(20, 16, 21, 17, '#'); g.rect(42, 16, 43, 17, '#');
    g.plat(16, 4, 10); g.put(7, 15, '+'); g.plat(14, 24, 40); g.plat(12, 28, 36); g.put(32, 11, '+');
    g.plat(16, 52, 58); g.put(55, 15, '+');
    g.put(2, 17, 'P'); g.put(61, 17, 'E');
    for (const x of [8, 12, 16, 28, 32, 36, 46, 50, 54]) g.put(x, 17, 'y');
    for (const x of [24, 38, 58]) g.put(x, 17, 'z');
    g.put(26, 17, 'x'); g.put(48, 17, 'x');
    g.put(30, 13, 'z');
    g.put(5, 17, '+'); g.put(59, 17, '+');
    kit.writeTxt(f, { title: 'Баррикада', theme: 'brick', requireClear: true }, g.rows());
    const v = kit.validate(f); if (!v.clean) throw new Error(v.text);
  }
  run(4, 'crypt', { title: 'Склеп', theme: 'stone', length: 120, enemies: { z: 8, y: 6, x: 4 }, hazards: { pit: 1, mound: 1, platform: 1, stairs: 1, fire: 1, saw: 1, spikes: 0.5 } });
  // Закрытый зал 5.
  {
    const f = mod.p(mod.levelPath(5, 'dead_hall'));
    const { Grid } = kit;
    const g = new Grid(72, 20);
    g.rect(0, 0, 71, 1, '#');
    g.floor(18, 0, 71);
    g.rect(24, 16, 25, 17, '#'); g.rect(46, 16, 47, 17, '#');
    g.plat(16, 4, 11); g.put(7, 15, '+'); g.plat(14, 10, 17); g.plat(14, 54, 61); g.plat(16, 60, 67); g.put(63, 15, '+');
    g.plat(14, 28, 44); g.plat(12, 31, 41); g.put(36, 11, '+');
    g.put(2, 17, 'P'); g.put(69, 17, 'E');
    for (const x of [8, 14, 20, 30, 34, 38, 42, 52, 56, 62, 66, 18]) g.put(x, 17, 'y');
    for (const x of [22, 40, 50, 58]) g.put(x, 17, 'z');
    for (const x of [28, 44]) g.put(x, 17, 'x');
    g.put(36, 13, 'k'); g.put(13, 13, 'k');
    g.put(5, 17, '+'); g.put(67, 17, '+'); g.put(36, 17, '+');
    g.put(14, 6, 'b'); g.put(36, 5, 'b'); g.put(58, 6, 'b');
    kit.writeTxt(f, { title: 'Зал мертвецов', theme: 'stone', requireClear: true }, g.rows());
    const v = kit.validate(f); if (!v.clean) throw new Error(v.text);
  }
  kit.arena(mod.p(mod.levelPath(6, 'zombie_king')), {
    title: 'Трон Короля зомби', theme: 'crypt', width: 56,
    bosses: [[48, 'Z']], platforms: [{ row: 16, x0: 8, x1: 12 }, { row: 14, x0: 14, x1: 36 }, { row: 16, x0: 38, x1: 42 }],
    extras: [[20, 17, 'y'], [26, 17, 'y'], [32, 17, 'y']],
    apples: [4, 24, 30], extra: { win_boss: 'Z' },
  });
  mod.finish();
  return mod;
};
