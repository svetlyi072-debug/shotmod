'use strict';
// «Ледяная цитадель»: ледяные гули, ползуны, маги и босс «Ледяной лорд» (полная версия мода-примера).
const fs = require('fs');
const path = require('path');
const { Mod } = require('../lib/modkit.js');
const kit = require('../lib/levelkit.js');

const SRC = 'D:/shootin/mods/frost_crypt/';

module.exports = function build() {
  const mod = new Mod('frost_citadel', {
    name: 'Ледяная цитадель',
    kind: 'pack',
    tagline: 'Ледяные гули, ползуны из-под снега, ледяные маги — и Ледяной лорд, который бьёт ударной волной, зовёт гулей и бросается тараном. Четыре уровня.',
    campaignTitle: 'Ледяная цитадель',
    about: [
      'Полная версия мода-примера «Ледяной склеп»: те же враги и босс, но четыре уровня вместо двух. Ледяные палитры получены перекраской спрайтов игры.',
    ],
    features: [
      '**Ледяной гуль** (`G`), **Ползун** (`Q`, лежит под снегом и встаёт, когда подойдёшь), **Ледяной маг** (`J`, бросает ледяные заряды)',
      '**Ледяной лорд** (`L`) — босс',
      '4 уровня: «Заснеженный вход», «Ледяные залы», «Замёрзший зал» (зачистка), «Трон лорда»',
    ],
    notes: ['Мод написан как учебный: открой `enemies/*.json` и `bosses/lord.json` и поменяй цифры — так делаются свои враги.'],
  });
  for (const f of fs.readdirSync(SRC + 'sprites')) mod.copy(SRC + 'sprites/' + f, 'sprites/' + f);
  for (const sub of ['enemies', 'bosses']) for (const f of fs.readdirSync(SRC + sub)) mod.copy(SRC + sub + '/' + f, sub + '/' + f);

  const run = (i, slug, spec) => kit.makeRun(mod.p(mod.levelPath(i, slug)), Object.assign({ seed: 2500 + i * 31 }, spec));
  run(1, 'snow_gate', { title: 'Заснеженный вход', theme: 'stone', length: 100, enemies: { G: 6, J: 2, Q: 2 }, hazards: { pit: 1, mound: 1.5, platform: 1.5, spikes: 0.5, saw: 0.3 } });
  run(2, 'ice_halls', { title: 'Ледяные залы', theme: 'crypt', length: 120, enemies: { G: 5, J: 4, Q: 4 }, hazards: { pit: 1, mound: 1, platform: 1, stairs: 1, saw: 1, ball: 1, spikes: 0.7 } });
  {
    const f = mod.p(mod.levelPath(3, 'frozen_hall'));
    const g = new kit.Grid(66, 20);
    g.rect(0, 0, 65, 1, '#');
    g.floor(18, 0, 65);
    g.rect(22, 16, 23, 17, '#'); g.rect(42, 16, 43, 17, '#');
    g.plat(16, 4, 11); g.put(7, 15, '+'); g.plat(14, 25, 40); g.put(32, 13, '+'); g.plat(16, 54, 61); g.put(57, 15, '+');
    g.put(2, 17, 'P'); g.put(63, 17, 'E');
    for (const x of [10, 16, 30, 36, 48, 52, 58]) g.put(x, 17, 'Q');
    for (const x of [20, 28, 46]) g.put(x, 17, 'G');
    for (const [x, y] of [[8, 15], [32, 13], [58, 15], [38, 17]]) g.put(x, y, 'J');
    g.put(5, 17, '+'); g.put(56, 17, '+'); g.put(33, 17, '+');
    kit.writeTxt(f, { title: 'Замёрзший зал', theme: 'stone', requireClear: true }, g.rows());
    const v = kit.validate(f); if (!v.clean) throw new Error(v.text);
  }
  kit.arena(mod.p(mod.levelPath(4, 'lord_throne')), {
    title: 'Трон лорда', theme: 'crypt', width: 52,
    bosses: [[42, 'L']], platforms: [{ row: 16, x0: 6, x1: 12 }, { row: 14, x0: 14, x1: 30 }, { row: 16, x0: 32, x1: 38 }],
    apples: [4, 22, 36], extra: { win_boss: 'L' },
  });
  mod.finish();
  return mod;
};
