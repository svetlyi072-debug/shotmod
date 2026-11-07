'use strict';
// «Небесные острова»: платформинг над пропастью — острова, разделённые ямами в 3 клетки.
const { Mod } = require('../lib/modkit.js');
const kit = require('../lib/levelkit.js');

function islands(file, spec) {
  for (let attempt = 0; attempt < 60; attempt++) {
    const lv = new kit.Level({ width: spec.length, seed: spec.seed + attempt * 977 });
    lv.start().flat(9);
    let n = 0;
    while (lv.x < spec.length - 18) {
      lv.pit(3);
      const len = n % 4 === 3 ? lv.between(9, 12) : lv.between(3, 6);   // иногда — длинный остров
      if (lv.rand() < 0.35) lv.mound(2, 1); else lv.flat(len);
      if (lv.rand() < 0.4) lv.platform(lv.between(4, 6), { rise: 2, at: lv.x - 4 });
      n++;
    }
    lv.pit(3).flat(12);
    lv.exit(spec.length - 3);
    // Враги — только на длинных островах (безопасные колонки) и в воздухе.
    for (const [sym, c] of Object.entries(spec.enemies || {})) lv.enemies(sym, c, { spacing: 4 });
    for (const [sym, c] of Object.entries(spec.flyers || {})) lv.flyer(sym, c, { rows: [8, 13] });
    if (spec.boss) lv.g.set(spec.length - 14, 9, spec.boss);
    lv.apples(Math.max(4, Math.floor(spec.length / 24)));
    kit.writeTxt(file, { title: spec.title, theme: spec.theme, extra: spec.boss ? { win_boss: spec.boss, boss_arena: `${spec.boss}=16` } : {} }, lv.g.rows());
    const v = kit.validate(file);
    if (v.clean) return lv;
  }
  throw new Error('острова: не собралось ' + spec.title);
}

module.exports = function build() {
  const mod = new Mod('sky_islands', {
    name: 'Небесные острова',
    kind: 'levels',
    tagline: 'Пять уровней над пропастью: острова разной высоты, ямы по три клетки и летучие мыши. Одно неверное движение — и вниз.',
    campaignTitle: 'Небесные острова',
    about: [
      'Платформинг без передышки: между островами — пропасти, перепрыгивай их на разбеге. На длинных островах отдыхают аптечки и редкие враги, в воздухе кружат мыши.',
      'В последнем уровне ждёт Око бездны — победи его, и кампания пройдена.',
    ],
    features: ['5 уровней', 'ямы по 3 клетки — прыгай с разбега (Shift ускоряет бег)', 'летучие мыши и Око бездны'],
    credits: 'Карты и описание — автор мода. Графика — из игры ShootIn.',
  });
  const defs = [
    ['dawn', 'Рассвет', 'grass', 80, 11, {}, { b: 1 }],
    ['clouds', 'Облака', 'meadow', 100, 22, { s: 2 }, { b: 3 }],
    ['wind', 'Ветер', 'candy', 110, 33, { k: 2, s: 1 }, { b: 4 }],
    ['storm', 'Гроза', 'stone', 120, 44, { k: 2, z: 2 }, { b: 6 }],
    ['eye', 'Око бури', 'crypt', 120, 55, { k: 1 }, { b: 3 }, 'O'],
  ];
  defs.forEach(([slug, title, theme, length, seed, enemies, flyers, boss], i) => {
    islands(mod.p(mod.levelPath(i + 1, slug)), { title, theme, length, seed, enemies, flyers, boss });
  });
  mod.finish();
  return mod;
};
