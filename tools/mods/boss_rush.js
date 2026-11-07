'use strict';
// «Босс-раш»: девять арен подряд — все восемь боссов игры и тройной финал.
const { Mod } = require('../lib/modkit.js');
const kit = require('../lib/levelkit.js');

module.exports = function build() {
  const mod = new Mod('boss_rush', {
    name: 'Босс-раш',
    kind: 'levels',
    tagline: 'Все восемь боссов ShootIn подряд — без беготни по уровням, только бои. В финале сразу трое.',
    campaignTitle: 'Босс-раш',
    about: [
      'Девять арен, одна за другой. На каждой — один босс и несколько аптечек. Здоровье в начале арены полное, а шкала силы переходит дальше, как в основной игре.',
      'Порядок: Король-гриб → Костяной рыцарь → Око бездны → Огненный червь → Тёмный колдун → Древний слизень → Царь-Панцирь → Король зомби → **«Тройная угроза»** (Костяной рыцарь, Король зомби и Око бездны одновременно).',
    ],
    features: ['9 арен', 'используются только боссы и ловушки самой игры — мод не добавляет картинок и кода', 'Лёгкая / Нормальная / Сложная сложности работают как обычно'],
    notes: ['Умер — арена начинается заново (клавиша R). Прогресс по раундам сохраняется: «Продолжить» вернёт на последний раунд.'],
    credits: 'Карты и описание — автор мода. Все персонажи и графика — из игры ShootIn.',
  });

  const rounds = [
    { slug: 'mushroom', title: 'Король-гриб', theme: 'grass', boss: 'M', x: 38, plat: [[16, 6, 11], [16, 22, 27]], apples: [4, 16] },
    { slug: 'bone_knight', title: 'Костяной рыцарь', theme: 'crypt', boss: 'N', x: 40, width: 50, plat: [[16, 6, 13], [14, 15, 25], [16, 27, 33]], apples: [4, 14] },
    { slug: 'abyss_eye', title: 'Око бездны', theme: 'stone', boss: 'O', x: 30, y: 8, width: 50, plat: [[16, 6, 12], [14, 14, 28], [16, 30, 36]], apples: [4, 40] },
    { slug: 'fire_worm', title: 'Огненный червь', theme: 'clay', boss: 'W', x: 46, width: 56, ceiling: false, plat: [[16, 6, 12], [16, 22, 28], [16, 34, 40]], apples: [4, 16, 30] },
    { slug: 'dark_wizard', title: 'Тёмный колдун', theme: 'brick', boss: 'V', x: 40, width: 50, plat: [[16, 6, 12], [16, 28, 34]], apples: [4, 16] },
    { slug: 'ancient_slime', title: 'Древний слизень', theme: 'jade', boss: 'B', x: 46, width: 56, plat: [[16, 6, 12], [14, 14, 30], [16, 32, 38]], apples: [4, 16, 42] },
    { slug: 'shellback_king', title: 'Царь-Панцирь', theme: 'stone', boss: 'K', x: 41, width: 48, plat: [[16, 5, 9], [14, 11, 35], [16, 31, 35]], apples: [7, 22], skipPlatApples: true },
    { slug: 'zombie_king', title: 'Король зомби', theme: 'crypt', boss: 'Z', x: 40, width: 48, plat: [[16, 8, 12], [14, 15, 32], [16, 35, 39]], apples: [4, 24] },
  ];

  rounds.forEach((r, i) => {
    const file = mod.p(mod.levelPath(i + 1, r.slug));
    kit.arena(file, {
      title: r.title, theme: r.theme, width: r.width || 48, ceiling: r.ceiling,
      bosses: [[r.x, r.boss]].map(([x, sym]) => [x, sym]),
      bossRow: r.y,
      platforms: r.plat.map(([row, x0, x1]) => ({ row, x0, x1, apple: !r.skipPlatApples })),
      apples: r.apples,
      extra: { win_boss: r.boss },
    });
  });

  // Финал: «клещи» — рыцарь и король зомби с двух сторон, сверху око. Нужно победить всех и дойти до выхода.
  const finalFile = mod.p(mod.levelPath(9, 'triple_threat'));
  kit.arena(finalFile, {
    title: 'Тройная угроза', theme: 'crypt', width: 96, requireClear: true,
    bosses: [[52, 'N'], [66, 'Z']],
    extras: [[59, 8, 'O']],
    platforms: [
      { row: 16, x0: 8, x1: 13 }, { row: 16, x0: 20, x1: 25 },
      { row: 16, x0: 44, x1: 49 }, { row: 14, x0: 51, x1: 56, apple: false }, { row: 12, x0: 58, x1: 63 },
      { row: 14, x0: 65, x1: 70, apple: false }, { row: 16, x0: 72, x1: 77 },
    ],
    apples: [4, 30, 38, 82, 90], exit: 93,
    extra: { boss_leash: 'yes', boss_arena: 'N=22 Z=22 O=24' },
  });
  mod.finish();
  return mod;
};
