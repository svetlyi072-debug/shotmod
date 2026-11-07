'use strict';
// Помощники для сборки модов: папка мода, mod.json, README, спрайты.
const fs = require('fs');
const path = require('path');
const config = require('../config.js');

const ROOT = path.resolve(__dirname, '..', '..');

function readPngSize(file) {
  const b = fs.readFileSync(file);
  if (b.readUInt32BE(0) !== 0x89504e47) throw new Error('не PNG: ' + file);
  return { w: b.readUInt32BE(16), h: b.readUInt32BE(20) };
}

class Mod {
  constructor(id, meta) {
    this.id = id;
    this.meta = meta;
    this.dir = path.join(ROOT, 'mods', id);
    fs.rmSync(this.dir, { recursive: true, force: true });
    fs.mkdirSync(this.dir, { recursive: true });
    this.levelFiles = [];
    this.manifestExtra = {};
  }
  p(rel) { return path.join(this.dir, rel); }
  write(rel, text) { fs.mkdirSync(path.dirname(this.p(rel)), { recursive: true }); fs.writeFileSync(this.p(rel), text); }
  json(rel, obj) { this.write(rel, JSON.stringify(obj, null, 2) + '\n'); }
  copy(src, rel) { fs.mkdirSync(path.dirname(this.p(rel)), { recursive: true }); fs.copyFileSync(src, this.p(rel)); }
  // Уровень: путь внутри мода levels/NN_name.txt; возвращает относительный путь.
  levelPath(index, slug) {
    const rel = `levels/${String(index).padStart(2, '0')}_${slug}.txt`;
    this.levelFiles.push(rel);
    return rel;
  }
  // Спрайт из картинок в sprites/: anims — {имя: [файл, fps, дополнительно]}; размеры кадра берутся из файлов.
  sprite(anims, { frame, scale = 1, extra = {} } = {}) {
    const out = {};
    for (const [name, spec] of Object.entries(anims)) {
      const [file, fps, more] = spec;
      out[name] = Object.assign({ file: `sprites/${file}.png`, fps }, more || {});
    }
    let size = frame;
    if (!size) {
      const first = Object.values(anims)[0][0];
      const { h } = readPngSize(this.p(`sprites/${first}.png`));
      size = [h, h];
    }
    return Object.assign({ frame: size, scale, animations: out }, extra);
  }
  finish(extra = {}) {
    const m = this.meta;
    const manifest = Object.assign({
      id: this.id, name: m.name, version: config.version, author: config.author,
      description: m.tagline, api: 1,
    }, this.manifestExtra, extra);
    if (this.levelFiles.length && !manifest.campaign) {
      manifest.campaign = { title: m.campaignTitle || m.name, levels: this.levelFiles };
    }
    this.json('mod.json', manifest);
    this.write('README.md', readme(this, manifest));
    return manifest;
  }
}

function readme(mod, manifest) {
  const m = mod.meta;
  const lines = [];
  lines.push(`# ${m.name}`, '', `**Мод для ShootIn** · версия ${manifest.version} · автор ${manifest.author}`, '', m.tagline, '');
  if (m.about) lines.push(...[].concat(m.about).flatMap((p) => [p, '']));
  if (m.features && m.features.length) { lines.push('## Что внутри', '', ...m.features.map((f) => `- ${f}`), ''); }
  lines.push('## Как установить', '',
    '1. Запусти игру → **Моды** → **Установить из файла…** и выбери скачанный `.zip` (или **Скачать и установить**, если у тебя есть ссылка).',
    '2. Поставь галочку у мода' + (m.kind === 'script' ? ' и подтверди предупреждение: мод содержит скрипты (их можно прочитать — это обычный текст).' : '.'),
  );
  if (m.kind === 'levels' || m.kind === 'pack') lines.push('3. Выбери мод в списке → **Играть** → сложность.');
  lines.push('', 'Распаковывать архив не нужно — игра читает его сама.', '');
  if (m.notes && m.notes.length) { lines.push('## Заметки', '', ...m.notes.map((f) => `- ${f}`), ''); }
  lines.push('## Лицензия и авторы', '', m.credits || config.credits, '');
  return lines.join('\n');
}

module.exports = { Mod, readPngSize, ROOT, config };
