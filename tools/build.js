'use strict';
// Собирает моды: node tools/build.js [id ...]  (без аргументов — все из tools/mods/)
const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, 'mods');
const only = process.argv.slice(2).filter((a) => !a.startsWith('--') && a !== process.argv[process.argv.indexOf('--author') + 1]);
const files = fs.readdirSync(dir).filter((f) => f.endsWith('.js')).sort();
let failed = 0;
const catalogFile = path.join(__dirname, '..', 'build', 'catalog.json');
let catalog = {};
try { catalog = JSON.parse(fs.readFileSync(catalogFile, 'utf8')); } catch (e) { /* первый запуск */ }
for (const f of files) {
  const id = f.replace(/\.js$/, '');
  if (only.length && !only.includes(id) && !(id === 'script_mods' && only.some((o) => fs.existsSync(path.join(__dirname, '..', 'src', o))))) continue;
  const t = Date.now();
  try {
    const out = require(path.join(dir, f))();
    for (const mod of [].concat(out)) { catalog[mod.id] = { id: mod.id, name: mod.meta.name, kind: mod.meta.kind, tagline: mod.meta.tagline, levels: mod.levelFiles.length, features: mod.meta.features || [] }; console.log(`✔ ${mod.id}: ${mod.levelFiles.length} уровней (${Date.now() - t} мс)`); }
  } catch (e) {
    failed++;
    console.log(`✘ ${id}: ${e.message}`);
  }
}
fs.mkdirSync(path.dirname(catalogFile), { recursive: true });
fs.writeFileSync(catalogFile, JSON.stringify(catalog, null, 1));
process.exit(failed ? 1 : 0);
