'use strict';
// Конструктор уровней для модов: из «кусков» (ровно, яма, холм, шипы, пила, огонь, платформы)
// собирает проходимый горизонтальный уровень, расставляет врагов и аптечки, а валидатор игры
// проверяет результат. Уровень получается из seed — тот же seed даёт ту же карту.
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const { Grid } = require('./lvlib.js');

const VALIDATOR = process.env.SHOOTIN_VALIDATOR || 'D:/shootin/tools/validate_levels.js';

// Простой воспроизводимый генератор случайных чисел.
function rng(seed) {
  let s = (seed >>> 0) || 1;
  return () => { s = (Math.imul(s, 1664525) + 1013904223) >>> 0; return s / 4294967296; };
}

const FLOOR = 18;      // верхний ряд пола
const STAND = 17;      // ряд, на котором стоят персонажи

class Level {
  constructor({ width, seed = 1, height = 20 }) {
    this.w = width;
    this.h = height;
    this.rand = rng(seed);
    this.g = new Grid(width, height);
    this.g.floor(FLOOR, 0, width - 1);
    this.x = 0;
    this.unsafe = new Set();   // колонки, где опасно ставить врагов и аптечки
    this.raised = new Set();   // колонки холмов
    this.hazards = [];
  }
  pick(list) { return list[Math.floor(this.rand() * list.length)]; }
  between(a, b) { return a + Math.floor(this.rand() * (b - a + 1)); }
  mark(x0, x1) { for (let x = x0; x <= x1; x++) this.unsafe.add(x); }

  flat(n) { this.x += n; return this; }
  pit(n) {
    const x0 = this.x;
    this.g.clear(x0, FLOOR, x0 + n - 1, FLOOR + 1);
    this.mark(x0 - 3, x0 + n + 2);
    this.x += n;
    return this;
  }
  mound(n, h) {
    const x0 = this.x;
    this.g.rect(x0, STAND - h + 1, x0 + n - 1, STAND, '#');
    for (let x = x0; x < x0 + n; x++) this.raised.add(x);
    this.mark(x0 - 2, x0 + n + 1);
    this.x += n;
    return this;
  }
  spikes(n) {
    const x0 = this.x;
    this.g.hline(STAND, x0, x0 + n - 1, '^');
    this.mark(x0 - 3, x0 + n + 2);
    this.x += n;
    return this;
  }
  saw() {
    this.g.set(this.x + 2, STAND, 'o');
    this.mark(this.x - 1, this.x + 6);
    this.x += 5;
    return this;
  }
  fire() {
    this.g.set(this.x + 1, FLOOR, 'f');
    this.mark(this.x - 2, this.x + 4);
    this.x += 3;
    return this;
  }
  // Шипастый шар под потолком-блоком: проходи под ним, когда он качнулся в сторону.
  ball() {
    const cx = this.x + 3;
    this.g.set(cx, 13, '#');
    this.g.set(cx, 14, '*');
    this.mark(this.x - 1, this.x + 7);
    this.x += 7;
    return this;
  }
  // Дощечка над землёй: rise клеток над полом (2 — запрыгнуть с земли), apple — аптечка на ней.
  platform(len, { rise = 2, apple = true, at = this.x } = {}) {
    const row = FLOOR - rise;
    this.g.plat(row, at, at + len - 1);
    if (apple) this.g.set(at + Math.floor(len / 2), row - 1, '+');
    return this;
  }
  // Лесенка из двух ярусов дощечек (вторая — для верхней аптечки).
  stairs(len = 4, apple = true) {
    const x0 = this.x;
    this.g.plat(FLOOR - 2, x0, x0 + len - 1);
    this.g.plat(FLOOR - 4, x0 + len + 1, x0 + 2 * len);
    if (apple) this.g.set(x0 + len + 1 + Math.floor(len / 2), FLOOR - 5, '+');
    this.x += 2 * len + 1;
    return this;
  }

  // Колонки, где можно ставить врагов (ровный пол, вдали от опасностей, не у старта и не у выхода).
  safeColumns(from = 12, to = this.w - 8) {
    const out = [];
    for (let x = from; x < to; x++) {
      if (this.unsafe.has(x) || this.raised.has(x)) continue;
      if (this.g.get(x, STAND) !== '.' || !this.g.solidAt(x, FLOOR)) continue;
      out.push(x);
    }
    return out;
  }
  // Ставит count врагов символа sym на случайные безопасные колонки (не ближе spacing друг к другу).
  enemies(sym, count, { spacing = 3, from = 12, to = this.w - 8 } = {}) {
    this.taken = this.taken || [];
    const cols = this.safeColumns(from, to);
    let placed = 0;
    let guard = 0;
    while (placed < count && guard++ < 400 && cols.length) {
      const x = cols[Math.floor(this.rand() * cols.length)];
      if (this.taken.some((t) => Math.abs(t - x) < spacing)) continue;
      this.g.set(x, STAND, sym);
      this.taken.push(x);
      placed++;
    }
    return this;
  }
  // Летающий враг (мышь, око) в воздухе над колонкой.
  flyer(sym, count, { rows = [10, 14] } = {}) {
    for (let i = 0; i < count; i++) {
      const x = this.between(14, this.w - 10);
      this.g.set(x, this.between(rows[0], rows[1]), sym);
    }
    return this;
  }
  apples(count) {
    const cols = this.safeColumns(6, this.w - 6);
    for (let i = 0; i < count && cols.length; i++) {
      const x = cols[Math.floor((i + 0.5) * cols.length / count)];
      if (this.g.get(x, STAND) === '.') this.g.set(x, STAND, '+');
    }
    return this;
  }
  start(x = 2) { this.g.set(x, STAND, 'P'); return this; }
  exit(x = this.w - 3) { this.g.set(x, STAND, 'E'); return this; }
}

// Случайный «забег»: слева направо из кусков. difficulty 0..3 — как часто и какие опасности.
function run(spec) {
  const lv = new Level({ width: spec.length, seed: spec.seed });
  const hz = Object.assign({ pit: 1, mound: 1, spikes: 0.5, saw: 0.5, fire: 0.5, ball: 0, platform: 1, stairs: 0.5 }, spec.hazards || {});
  const kinds = Object.keys(hz).filter((k) => hz[k] > 0);
  const total = kinds.reduce((a, k) => a + hz[k], 0);
  lv.start().flat(10);
  let guard = 0;
  while (lv.x < spec.length - 16 && guard++ < 200) {
    let r = lv.rand() * total;
    let kind = kinds[0];
    for (const k of kinds) { r -= hz[k]; if (r <= 0) { kind = k; break; } }
    switch (kind) {
      case 'pit': lv.pit(lv.between(2, 3)); break;
      case 'mound': lv.mound(lv.between(2, 4), lv.between(1, 2)); break;
      case 'spikes': lv.spikes(lv.between(1, 2)); break;
      case 'saw': lv.saw(); break;
      case 'fire': lv.fire(); break;
      case 'ball': lv.ball(); break;
      case 'platform': lv.platform(lv.between(5, 8), { rise: 2, at: lv.x }); lv.flat(lv.between(2, 3)); break;
      case 'stairs': lv.stairs(4); break;
    }
    lv.flat(lv.between(spec.gap ? spec.gap[0] : 6, spec.gap ? spec.gap[1] : 10));
  }
  lv.exit(spec.length - 3);
  for (const [sym, n] of Object.entries(spec.enemies || {})) lv.enemies(sym, n);
  for (const [sym, n] of Object.entries(spec.flyers || {})) lv.flyer(sym, n);
  lv.apples(spec.apples === undefined ? Math.max(3, Math.floor(spec.length / 22)) : spec.apples);
  return lv;
}

function header(spec) {
  const lines = [`title: ${spec.title}`, `theme: ${spec.theme || 'grass'}`];
  if (spec.requireClear) lines.push('require_clear: yes');
  for (const [k, v] of Object.entries(spec.extra || {})) lines.push(`${k}: ${v}`);
  return lines.join('\n');
}

function writeTxt(file, spec, rows) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${header(spec)}\n\n${rows.join('\n')}\n`);
}

// Запускает валидатор игры на файле уровня. Возвращает {ok, clean, text}.
function validate(file) {
  const r = spawnSync('node', [VALIDATOR, file], { encoding: 'utf8' });
  const text = (r.stdout || '') + (r.stderr || '');
  return { ok: r.status === 0 && !text.includes('[ОШИБКА]'), clean: !text.includes('[ок, но]') && !text.includes('[ОШИБКА]'), text };
}

// Собирает забег и пересобирает с другим seed, пока валидатор не скажет «чисто».
function makeRun(file, spec, tries = 40) {
  let last = '';
  for (let i = 0; i < tries; i++) {
    const lv = run(Object.assign({}, spec, { seed: (spec.seed || 1) + i * 7919 }));
    writeTxt(file, spec, lv.g.rows());
    const v = validate(file);
    last = v.text;
    if (v.clean) return lv;
  }
  throw new Error(`не удалось собрать «${spec.title}» (${file}):\n${last}`);
}

// Арена босса: ширина w, босс/боссы по символам и колонкам, дощечки и аптечки.
// extras: [[x, y, sym]...] — любые добавочные символы.
function arena(file, spec) {
  const w = spec.width || 48;
  const g = new Grid(w, 20);
  if (spec.ceiling !== false) g.rect(0, 0, w - 1, 1, '#');
  g.floor(FLOOR, 0, w - 1);
  g.put(2, STAND, 'P');
  for (const p of spec.platforms || []) { g.plat(p.row, p.x0, p.x1); if (p.apple !== false) g.put(Math.floor((p.x0 + p.x1) / 2), p.row - 1, '+'); }
  for (const [x, sym] of spec.bosses || []) g.put(x, spec.bossRow === undefined ? STAND : spec.bossRow, sym);
  for (const [x, y, sym] of spec.extras || []) g.put(x, y, sym);
  for (const x of spec.apples || []) g.put(x, STAND, '+');
  if (spec.exit) g.put(spec.exit, STAND, 'E');
  writeTxt(file, spec, g.rows());
  const v = validate(file);
  if (!v.clean) throw new Error(`арена «${spec.title}»:\n${v.text}`);
  return g;
}

module.exports = { Level, run, makeRun, arena, validate, writeTxt, rng, FLOOR, STAND, Grid };
