'use strict';
// Общие настройки сборки модов. Автора можно поменять здесь (или флагом: node tools/build.js --author "Имя").
const argv = process.argv.slice(2);
const authorIdx = argv.indexOf('--author');

module.exports = {
  author: authorIdx >= 0 ? argv[authorIdx + 1] : 'ShootIn',
  version: '1.0.0',
  // Строка про лицензию и авторов графики — попадает в README каждого мода (можно переопределить у мода).
  credits: 'Код, карты и описания мода — автор мода (см. mod.json). Графика (если есть) — перекрашенные спрайты наборов ' +
    'LuizMelo (Monsters Creatures Fantasy, Medieval King Pack 2, Hero Knight, Evil Wizard 2; CC0) — ' +
    'https://luizmelo.itch.io/. Мод создан для игры ShootIn. Перед публикацией проверь выбранную лицензию.',
  gameAssets: 'D:/shootin/assets',
  gameDesign: 'D:/shootin/design/source/luizmelo',
};
