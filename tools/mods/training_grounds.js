'use strict';
// «Полигон»: короткие учебные уровни — по одному на каждого врага игры.
const { Mod } = require('../lib/modkit.js');
const kit = require('../lib/levelkit.js');

module.exports = function build() {
  const mod = new Mod('training_grounds', {
    name: 'Полигон',
    kind: 'levels',
    tagline: 'Учебка для новичков: двенадцать коротких уровней, в каждом — один вид врага или ловушек и подсказка в названии, как с ним справиться.',
    campaignTitle: 'Полигон',
    about: [
      'Не знаешь, как победить скелета или что делать с катящимся панцирником? Здесь каждый враг получает свой небольшой зал: два-три противника, аптечки и подсказка в названии уровня.',
      'Последний зал — «Экзамен»: все враги вперемешку.',
    ],
    features: ['12 коротких уровней', 'слизни, мыши, скелеты, гоблины, грибники, крысы, мимики, панцирники, зомби, могильные зомби и рыцари, ловушки', 'идеально для первого знакомства с игрой'],
    credits: 'Карты и описание — автор мода. Графика — из игры ShootIn.',
  });
  const { Grid } = kit;
  const lessons = [
    ['slimes', 'Слизни — прыгай или стреляй (ЛКМ)', 'grass', { s: [3, 17, 25, 33] }],
    ['bats', 'Мыши пикируют — бей снизу (J)', 'stone', {}, { b: [[14, 8], [26, 6], [38, 9]] }],
    ['skeletons', 'Скелет в щите — заходи со спины', 'crypt', { k: [20, 34] }],
    ['goblins', 'Гоблин бросает бомбы — не стой на месте', 'wood', { g: [22, 36] }],
    ['mushrooms', 'Грибники медленные — бей и отступай', 'jade', { m: [18, 28, 38] }],
    ['rats', 'Крысы быстрые — встречай ударом', 'clay', { r: [16, 24, 32, 40] }],
    ['mimics', 'Сундук может кусаться', 'brick', { c: [18, 34] }],
    ['panzers', 'Панцирник катится — встань на платформу', 'stone', { p: [24] }],
    ['zombies', 'Могильные встают, когда подойдёшь', 'crypt', { z: [18], y: [28, 34], x: [42] }],
    ['traps', 'Ловушки ранят и врагов — заманивай', 'wood', { s: [22, 36] }, {}, true],
    ['shield', 'Щит (H) гасит удар — но ненадолго', 'meadow', { z: [22], k: [34] }],
    ['exam', 'Экзамен: все враги вперемешку', 'crypt', { s: [14], k: [22], z: [30], g: [38], r: [46] }, { b: [[26, 7]] }],
  ];
  lessons.forEach(([slug, title, theme, ground, flyers, traps], i) => {
    const f = mod.p(mod.levelPath(i + 1, slug));
    const w = slug === 'exam' ? 64 : 52;
    const g = new Grid(w, 20);
    g.rect(0, 0, w - 1, 1, '#');
    g.floor(18, 0, w - 1);
    g.put(2, 17, 'P'); g.put(w - 3, 17, 'E');
    g.put(7, 17, '+'); g.put(Math.floor(w / 2), 17, '+');
    g.plat(16, 8, 13);
    g.plat(16, w - 14, w - 9); g.put(w - 12, 15, '+');
    if (slug === 'panzers') { g.plat(14, 18, 36); g.plat(16, 12, 17); g.plat(16, 37, 42); g.put(27, 13, '+'); }
    for (const [sym, xs] of Object.entries(ground)) for (const x of xs) g.put(x, 17, sym);
    for (const [sym, list] of Object.entries(flyers || {})) for (const [x, y] of list) g.put(x, y, sym);
    if (traps) { g.put(18, 17, 'o'); g.put(Math.floor(w / 2) + 6, 18, 'f'); }
    kit.writeTxt(f, { title, theme, requireClear: !['traps'].includes(slug) }, g.rows());
    const v = kit.validate(f);
    if (!v.clean) throw new Error(title + '\n' + v.text);
  });
  mod.finish();
  return mod;
};
