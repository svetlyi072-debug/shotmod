'use strict';
// Запускает Godot с ОТДЕЛЬНОЙ папкой данных (подменяет APPDATA), чтобы проверки не трогали настоящие
// сохранения, настройки и установленные моды игрока (%APPDATA%\Godot\app_userdata\ShootIn).
//
//   node tools/godot_isolated.js --headless --script D:/ShotMOD/tools/test_hardcore.gd
//   node tools/godot_isolated.js --resolution 1280x720 --script D:/ShotMOD/tools/make_hardcore_shots.gd
//
// Всё после имени скрипта передаётся Godot как есть; игра берётся из D:/shootin (переменная SHOOTIN), Godot — из
// переменной GODOT (по умолчанию на рабочем столе). Папка данных проверок: <temp>/shootin-test-appdata (её можно удалять).
const path = require('path');
const os = require('os');
const fs = require('fs');
const cp = require('child_process');

const GODOT = process.env.GODOT || path.join(os.homedir(), 'Desktop', 'Godot_v4.3-stable_win64.exe');
const GAME = process.env.SHOOTIN || 'D:/shootin';
const appdata = path.join(os.tmpdir(), 'shootin-test-appdata');
fs.mkdirSync(appdata, { recursive: true });

const r = cp.spawnSync(GODOT, ['--path', GAME, ...process.argv.slice(2)], {
  stdio: 'inherit',
  env: Object.assign({}, process.env, { APPDATA: appdata, XDG_CONFIG_HOME: '', XDG_DATA_HOME: '' }),
});
process.exit(r.status === null ? 1 : r.status);
