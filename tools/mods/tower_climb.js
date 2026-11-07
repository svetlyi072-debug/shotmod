'use strict';
// «Башни»: четыре вертикальных уровня — карабкайся вверх по лесенке из платформ.
const { Mod } = require('../lib/modkit.js');
const kit = require('../lib/levelkit.js');
const { Grid } = kit;

// Башня: шахта шириной 20 между скалами. Платформы по 8 клеток через каждые 2 ряда, влево-вправо.
function tower(file, spec) {
  for (let attempt = 0; attempt < 60; attempt++) {
    const rand = kit.rng(spec.seed + attempt * 313);
    const W = 30, steps = spec.steps, H = 14 + 2 * steps;
    const g = new Grid(W, H);
    g.rect(0, 0, 4, H - 1, '#'); g.rect(25, 0, 29, H - 1, '#');      // скалы по бокам
    g.rect(5, H - 2, 24, H - 1, '#');                                 // пол внизу
    g.put(7, H - 3, 'P');
    const rows = [];
    for (let k = 0; k < steps; k++) {
      const row = H - 4 - 2 * k;
      const left = k % 2 === 0;
      const x0 = left ? 6 : 16;
      g.plat(row, x0, x0 + 7);
      rows.push({ row, x0, left });
    }
    const topRow = H - 4 - 2 * steps;
    g.plat(topRow, 5, 24);
    // Враги и аптечки на платформах (не на первых двух и не на последней).
    rows.forEach((r, k) => {
      if (k < 2) return;
      if (k % 4 === 0) g.put(r.x0 + 3, r.row - 1, '+');
      else for (const [sym, p] of Object.entries(spec.enemies || {})) {
        if (rand() < p && g.get(r.x0 + 2 + Math.floor(rand() * 4), r.row - 1) === '.') { g.put(r.x0 + 2 + Math.floor(rand() * 4), r.row - 1, sym); break; }
      }
    });
    for (let i = 0; i < (spec.bats || 0); i++) g.put(7 + Math.floor(rand() * 16), H - 10 - Math.floor(rand() * (H - 22)), 'b');
    g.put(14, H - 4, '+');
    if (spec.boss) { g.put(spec.bossX || 14, topRow - 1 - 5, spec.boss); }
    g.put(spec.exitX || 22, topRow - 1, 'E');
    kit.writeTxt(file, { title: spec.title, theme: spec.theme, extra: spec.boss ? { win_boss: spec.boss, boss_arena: `${spec.boss}=10` } : {} }, g.rows());
    const v = kit.validate(file);
    if (v.clean) return;
  }
  throw new Error('башня не собралась: ' + spec.title);
}

module.exports = function build() {
  const mod = new Mod('tower_climb', {
    name: 'Башни',
    kind: 'levels',
    tagline: 'Четыре высокие башни: карабкайся по платформам вверх, пока враги ждут на каждом ярусе. Наверху — выход, а в последней башне ещё и Око бездны.',
    campaignTitle: 'Башни',
    about: [
      'Вертикальные уровни: платформы чередуются слева и справа через каждые два ряда. Упал — не страшно, внизу сплошной пол, но подниматься придётся заново.',
      'Враги стоят на ярусах, аптечки — через каждые четыре платформы.',
    ],
    features: ['4 башни: 12, 16, 20 и 24 яруса', 'скелеты, зомби, гоблины, грибники, мыши', 'босс — Око бездны'],
    credits: 'Карты и описание — автор мода. Графика — из игры ShootIn.',
  });
  const defs = [
    ['first', 'Подъём', 'grass', 12, 7, { s: 0.5, k: 0.4 }, 1],
    ['bones', 'Костяная лестница', 'crypt', 16, 17, { k: 0.5, z: 0.4 }, 3],
    ['spire', 'Шпиль', 'wood', 20, 27, { g: 0.5, m: 0.4, k: 0.3 }, 4],
    ['sky', 'Небесный трон', 'stone', 24, 37, { z: 0.5, k: 0.4, g: 0.3 }, 5, 'O'],
  ];
  defs.forEach(([slug, title, theme, steps, seed, enemies, bats, boss], i) => {
    tower(mod.p(mod.levelPath(i + 1, slug)), { title, theme, steps, seed, enemies, bats, boss });
  });
  mod.finish();
  return mod;
};
