'use strict';
// Графика для модов: перекраска спрайтов игры (tools/recolor.gd через Godot) или копия как есть.
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const { readPngSize } = require('./modkit.js');

const GODOT = process.env.GODOT || 'C:/Users/Admin/Desktop/Godot_v4.3-stable_win64.exe';
const GAME = 'D:/shootin';
const A = GAME + '/assets/';
const D = GAME + '/design/source/luizmelo/';
const SRC = {
  skeleton: (n) => `${A}monsters_creatures_fantasy/skeleton/${n}.png`,
  goblin: (n) => `${A}monsters_creatures_fantasy/goblin/${n}.png`,
  mushroom: (n) => `${A}monsters_creatures_fantasy/mushroom/${n}.png`,
  rat: (n) => `${A}monsters_creatures_fantasy_2/rat/${n}.png`,
  wizard: (n) => `${A}evil_wizard_2/${n}.png`,
  king: (n) => `${D}medieval_king_2/${n}.png`,
  knight: (n) => `${D}hero_knight/${n}.png`,
  zombie: (n) => `${A}zombie/${n}.png`,
};
const FRAME_W = { skeleton: 150, goblin: 150, mushroom: 150, rat: 70, wizard: 250, king: 160, knight: 180, zombie: 160 };

// Путь с прямыми слэшами (Godot на Windows принимает оба, но JSON-путь так надёжнее).
const toSlash = (p) => p.split(path.sep).join('/');

// items: [{from: 'skeleton', file: 'idle', name: 'sk_idle', preset: 'fire'|'none'}]
function make(mod, items) {
  const jobs = [];
  for (const it of items) {
    const src = SRC[it.from](it.file);
    const dst = mod.p(`sprites/${it.name}.png`);
    fs.mkdirSync(path.dirname(dst), { recursive: true });
    if (!it.preset || it.preset === 'none') fs.copyFileSync(src, dst);
    else jobs.push({ src, dst: toSlash(dst), preset: it.preset });
  }
  if (jobs.length) {
    const jf = path.join(__dirname, '..', '..', 'build', `jobs_${mod.id}.json`);
    fs.mkdirSync(path.dirname(jf), { recursive: true });
    fs.writeFileSync(jf, JSON.stringify({ jobs }));
    const r = spawnSync(GODOT, ['--headless', '--path', GAME, '--script', 'D:/ShotMOD/tools/recolor.gd', '--', toSlash(jf)], { encoding: 'utf8' });
    if (r.status !== 0) throw new Error('перекраска не удалась:\n' + (r.stdout || '') + (r.stderr || ''));
  }
}

// Число кадров в готовой полосе.
function frames(mod, name, frameW) { return readPngSize(mod.p(`sprites/${name}.png`)).w / frameW; }
// fps, при котором анимация из n кадров идёт seconds секунд.
function fps(n, seconds) { return Math.max(1, Math.round((n / seconds) * 10) / 10); }

module.exports = { make, frames, fps, SRC, FRAME_W };
