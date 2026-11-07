'use strict';
// «Храм ловушек»: шесть уровней без врагов — только пилы, огонь, шары, шипы и ямы.
const { Mod } = require('../lib/modkit.js');
const kit = require('../lib/levelkit.js');

module.exports = function build() {
  const mod = new Mod('trap_temple', {
    name: 'Храм ловушек',
    kind: 'levels',
    tagline: 'Шесть уровней-испытаний: пилы, огненные плиты, шипастые шары, шипы и ямы. Врагов почти нет — только твоя ловкость и тайминг.',
    campaignTitle: 'Храм ловушек',
    about: [
      'Каждый следующий зал плотнее набит ловушками. Пила ездит по полу, огонь вспыхивает по расписанию, шар качается на цепи — запомни ритм и проходи в паузах.',
      'Ловушки ранят и врагов, так что мыши, залетающие в последних залах, сами иногда попадают под них.',
    ],
    features: ['6 уровней нарастающей сложности', 'пилы, огненные ловушки, шипастые шары, шипы, ямы, дощечки', 'в начале — тренировочные залы, в конце — «Зал смерти»', 'аптечки лежат перед самыми опасными участками'],
    credits: 'Карты и описание — автор мода. Графика — из игры ShootIn.',
  });
  const levels = [
    { slug: 'saw_yard', title: 'Двор пил', theme: 'wood', length: 90, hazards: { saw: 3, pit: 1, platform: 1, spikes: 0.3, mound: 0.5 }, apples: 4 },
    { slug: 'fire_halls', title: 'Огненные плиты', theme: 'clay', length: 100, hazards: { fire: 3, saw: 1, pit: 1, platform: 1, mound: 0.5 }, apples: 4 },
    { slug: 'pendulums', title: 'Маятники', theme: 'brick', length: 100, hazards: { ball: 3, spikes: 1, pit: 1, platform: 1 }, apples: 4 },
    { slug: 'spike_bridge', title: 'Шипастый мост', theme: 'stone', length: 110, hazards: { spikes: 3, pit: 2, saw: 1, mound: 1, stairs: 1 }, apples: 5 },
    { slug: 'trap_maze', title: 'Всё сразу', theme: 'crypt', length: 120, hazards: { saw: 2, fire: 2, ball: 2, spikes: 1.5, pit: 1.5, mound: 1, platform: 1 }, flyers: { b: 3 }, apples: 5, gap: [5, 8] },
    { slug: 'death_hall', title: 'Зал смерти', theme: 'jade', length: 140, hazards: { saw: 2.5, fire: 2.5, ball: 2.5, spikes: 2, pit: 2, mound: 1, platform: 1, stairs: 1 }, flyers: { b: 5 }, apples: 7, gap: [4, 7] },
  ];
  levels.forEach((l, i) => {
    kit.makeRun(mod.p(mod.levelPath(i + 1, l.slug)), { title: l.title, theme: l.theme, length: l.length, seed: 100 + i * 31, hazards: l.hazards, flyers: l.flyers, apples: l.apples, gap: l.gap });
  });
  mod.finish();
  return mod;
};
