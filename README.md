# Wacky Games 🎮

The Wacky Games portal — one landing page, a button per game.

**▶️ Play: https://wackygames.com.au** (also at https://wackygames.pages.dev)

| Game | URL | Repo |
|---|---|---|
| 🍌 wackyShooter | [/shooter/](https://wackygames.com.au/shooter/) | [chrisforev/wackyShooter](https://github.com/chrisforev/wackyShooter) |
| 🍔 Crazy Café | [/cafe/](https://wackygames.com.au/cafe/) | `~/dev/LiviaGames/crazyCafe` |
| 🍊 Fruit Clicker | [/fruit/](https://wackygames.com.au/fruit/) | `~/dev/LiviaGames/fruitClicker` |
| ❓ Game 4 | coming soon | — |

## How it works

- `site/` — the static landing page (no build step, plain HTML/CSS)
- `build.sh` — builds each game from its sibling repo under `~/dev/LiviaGames/` and assembles everything into `dist/`: portal at `/`, each game in its own subfolder

Full design (DNS → Pages → game → multiplayer backend, deploy flow, credentials): [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## Build & deploy

```bash
./build.sh
npx wrangler pages deploy dist --project-name wackygames --branch main
```

## Adding a game

1. Make the game in its own folder under `~/dev/LiviaGames/` (Vite `base: './'` so it works from a subpath)
2. Add a build+copy block for it in `build.sh`
3. Add a card for it in `site/index.html` (copy the wackyShooter card, swap the link/emoji/blurb)
4. Build & deploy
