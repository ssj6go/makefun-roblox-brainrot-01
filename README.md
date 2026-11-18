# Brainrot Bay — a Roblox brainrot game

[![make.fun](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/ssj6go/makefun-roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/ssj6go/makefun-roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

An entry for make.fun's ["Make the best AI Roblox brainrot game" bounty](https://make.fun/bounty/roblox-brainrot-01)
(roblox-brainrot-01): a complete 3D game built with Rojo, where the player collects absurd meme characters that each
earn money a second, keeps them on a base, and climbs a ladder of rarities, mutations and rebirths — while rival
players steal and a tsunami sweeps the map.

## The game

- **The conveyor.** Brainrots spawn at the rainbow portal and walk the belt west to east. Stand next to one and press
  **E** to buy it, then carry it home: it places itself on your base and starts earning.
- **The cast.** 14 original characters on 7 rarities — Common to Secret — from the Toaster Toad ($5/s) to the CEO of
  Frogs ($2,500/s). No names or assets are copied from any existing game.
- **Mutations.** Every spawn can roll Golden (x2), Diamond (x5) or Rainbow (x10) income.
- **Stealing.** Hold **E** on a rival's placed brainrot to steal it and run it home — but the victim's base is shielded
  afterwards, the thief is on cooldown, and the owner can **lock the base** (L) for 30 seconds.
- **The tsunami.** Every two minutes a warning sounds and a wall of water sweeps the map. Anyone caught outside their
  own base is washed back to spawn and drops what they were carrying.
- **Rebirth.** Reset cash and base for a permanent +50% income multiplier per rebirth.
- **Server-authoritative economy.** Cash, inventory, earnings and cooldowns live on the server (`src/server/`); the
  client (`src/client/`) only displays snapshots and fires button RemoteEvents. Progress saves to a DataStore.

## Layout

- `main.ts` (Node 22, standard library only) hands the game in: it validates the place, PLAY.json and screenshots
  against the gate's caps, copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output`, and writes
  `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json` (`rojo build default.project.json
  --output game.rbxl`). The static world (grass baseplate, conveyor, portal, six base platforms, spawn) is in the
  project; trees, lamps, slot pads, signs, the rainbow arch and every brainrot model are built at runtime by
  `src/server/WorldBuilder.luau`.
- `src/shared/` holds the catalog, tuning constants and formatting helpers; `src/server/` holds the game systems
  (spawner, economy, stealing, tsunami, rebirth, persistence, leaderboard); `src/client/` holds the HUD, tutorial,
  effects, home beacon and intro camera.
- `screenshots/` holds four 1280x720 renders of the game (thumbnail first); `assets/icon.png` is the 512x512 icon
  for the Creator Dashboard.
- `PLAY.json` names the published place once the experience is Public; `TOUR.json` is the optional reviewer tour.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

## About the screenshots

This build ran on a Linux VM, and Roblox Studio has no Linux build, so no Studio capture was possible here. The four
screenshots are faithful renders of this exact game, produced with Three.js from the same layout, colours, characters
and HUD the Luau scripts build — the same base positions, conveyor, portal arch, brainrot models (body, head, eyes,
accessory) and HUD panels — and each HUD figure is internally consistent with the catalog (rates, prices, rebirth
multipliers). The thumbnail (`1-thumbnail.jpg`) is a composed picture of the game's own world and characters.

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's RULES.txt,
which gives every command in order (Before you submit, then Enter).
