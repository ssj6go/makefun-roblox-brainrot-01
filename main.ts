// Brainrot Bay: the entrypoint for make.fun's roblox-brainrot-01 bounty
// (Node 22, standard library only). The game is this directory's Rojo
// project, built into game.rbxl with `rojo build default.project.json
// --output game.rbxl`, and this program hands it in: it copies game.rbxl,
// src/, screenshots/ and PLAY.json from beside this file to /output and
// writes /output/dossier.json, the summary the judge reads, with the
// vendored make.fun library.
//
// Before copying, it validates the entry against the gate's own caps so
// a broken hand-in fails here, loudly, instead of at the scorer: the
// place must be a binary .rbxl within 32 MiB, PLAY.json must parse with
// its three fields, and there must be 3 or 4 screenshots, each within
// 256 KiB. Every check prints one line to stderr; nothing printed or
// written depends on the clock, so two runs write the same bytes.
//
// Every name under /output starts with a letter, a digit or _ and holds
// only letters, digits, . _ and -: the grader fails an entry whose
// output holds any other, so a file such as .gitkeep or .DS_Store copied
// in fails it. So src/ and screenshots/ are copied without any name
// that starts with a dot, at any depth.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// The gate's caps for this bounty (reference/gate.json), in bytes.
const PLACE_MAX_BYTES = 32 * 1024 * 1024;
const SCREENSHOT_MAX_BYTES = 256 * 1024;
const SCREENSHOT_MIN_COUNT = 3;
const SCREENSHOT_MAX_COUNT = 4;

/** cpSync's filter: leave out every file and directory whose name starts with a dot (.gitkeep, .DS_Store, .git). */
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

function fail(message: string): never {
  throw new Error(`Brainrot Bay entry invalid: ${message}`);
}

function log(message: string): void {
  console.error(`[brainrot-bay] ${message}`);
}

// --- Validate the place: a binary Roblox place, within the size cap. ---
const placePath = join(here, 'game.rbxl');
if (!existsSync(placePath)) fail('game.rbxl is missing; run rojo build first');
const placeBytes = statSync(placePath).size;
if (placeBytes > PLACE_MAX_BYTES) fail(`game.rbxl is ${placeBytes} bytes, over the ${PLACE_MAX_BYTES} cap`);
const placeHead = readFileSync(placePath).subarray(0, 14);
if (placeHead.toString('latin1') !== '<roblox!\x89\xff\r\n\x1a\n') {
  fail('game.rbxl does not open with the binary Roblox magic; the XML format (.rbxlx) is refused');
}
log(`place game.rbxl: ${placeBytes} bytes, binary format`);

// --- Validate PLAY.json: it must parse and name a place and a universe. ---
const playPath = join(here, 'PLAY.json');
if (!existsSync(playPath)) fail('PLAY.json is missing');
let play: unknown;
try {
  play = JSON.parse(readFileSync(playPath, 'utf8'));
} catch {
  fail('PLAY.json does not parse as JSON');
}
const playObj = play as { url?: unknown; place_id?: unknown; universe_id?: unknown };
if (typeof playObj.url !== 'string' || typeof playObj.place_id !== 'number' || typeof playObj.universe_id !== 'number') {
  fail('PLAY.json must hold url (string), place_id (number) and universe_id (number)');
}
if (playObj.place_id === 0 || playObj.universe_id === 0) {
  log('PLAY.json still names place 0: the experience is not published yet; entry_link_file will fail until it is');
} else {
  log(`play link: place ${playObj.place_id}, universe ${playObj.universe_id}`);
}

// --- Validate the screenshots: 3 or 4 images, each within the size cap. ---
const shotsDir = join(here, 'screenshots');
if (!existsSync(shotsDir)) fail('screenshots/ is missing');
const shots = readdirSync(shotsDir).filter((name) => !name.startsWith('.')).sort();
if (shots.length < SCREENSHOT_MIN_COUNT || shots.length > SCREENSHOT_MAX_COUNT) {
  fail(`screenshots/ holds ${shots.length} files, need ${SCREENSHOT_MIN_COUNT} to ${SCREENSHOT_MAX_COUNT}`);
}
for (const name of shots) {
  const bytes = statSync(join(shotsDir, name)).size;
  if (bytes > SCREENSHOT_MAX_BYTES) fail(`screenshots/${name} is ${bytes} bytes, over the ${SCREENSHOT_MAX_BYTES} cap`);
  if (!/\.(png|jpg|jpeg)$/i.test(name)) fail(`screenshots/${name} is not a PNG or JPEG`);
}
log(`screenshots: ${shots.length} files (${shots.join(', ')}), each within ${SCREENSHOT_MAX_BYTES} bytes`);

// --- Copy the entry, leaving dotted names behind at every depth. ---
copyFileSync(placePath, join(out, 'game.rbxl'));
copyFileSync(playPath, join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
cpSync(shotsDir, join(out, 'screenshots'), { recursive: true, filter: notDotted });
log(`copied game.rbxl, PLAY.json, src/ and screenshots/ to ${out}`);

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes the bytes; the others refuse an entry the
// scorer would refuse (more than 4 screenshots or one over 256 KiB; a place of more than 500000 instances, whose
// scripts' sources come to over 8 MiB or whose scripts' paths come to over 1048576 characters, in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
);
log('wrote dossier.json');
