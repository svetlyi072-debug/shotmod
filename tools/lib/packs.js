'use strict';
// Общие куски паков врагов и боссов.
const art = require('./art.js');

// Описывает анимацию из полосы: duration — за сколько секунд проиграть (для ударов — под attack_duration).
function anim(mod, name, frameW, { seconds, fps, loop } = {}) {
  const n = art.frames(mod, name, frameW);
  const spec = [name, fps !== undefined ? fps : art.fps(n, seconds || n / 8)];
  if (loop !== undefined) spec.push({ loop });
  return spec;
}

// Спрайт врага из набора полос: map — {роль: [имя файла, секунд | {fps}]}
function sprite(mod, frame, scale, map, extra = {}) {
  const anims = {};
  for (const [role, [name, t, opts]] of Object.entries(map)) {
    const n = art.frames(mod, name, frame[0]);
    const entry = [name, typeof t === 'number' ? art.fps(n, t) : t.fps];
    const more = Object.assign({}, opts || {});
    if (more && Object.keys(more).length) entry.push(more);
    anims[role] = entry;
  }
  return mod.sprite(anims, { frame, scale, extra });
}

module.exports = { anim, sprite };
