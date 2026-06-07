# Wacky Games — Architecture

How all the pieces of https://wackygames.com.au fit together.

## The big picture

```
                     👧 Player types wackygames.com.au
                                  │
              ┌───────────────────▼────────────────────┐
              │  DNS — "where is this site?"           │
              │  VentraIP (registrar) delegates to     │
              │  Cloudflare's nameservers              │
              │  (ines / quentin .ns.cloudflare.com).  │
              │  Cloudflare DNS answers with a CNAME:  │
              │  wackygames.com.au → wackygames        │
              │  .pages.dev (and www → same), proxied. │
              └───────────────────┬────────────────────┘
                                  │
              ┌───────────────────▼────────────────────┐
              │  CLOUDFLARE PAGES (project: wackygames)│
              │  Static files only:                    │
              │   /          → portal landing page     │
              │   /shooter/  → wackyShooter (built JS) │
              │   /<game2>/  → future games…           │
              │  Served from Cloudflare's global CDN.  │
              └───────────────────┬────────────────────┘
                                  │ downloads once, then runs
                                  │ entirely in the browser
              ┌───────────────────▼────────────────────┐
              │  PHASER GAME (player's browser)        │
              │  - all art generated at runtime        │
              │  - physics/enemies simulated locally   │
              │  - progress saved to localStorage      │
              │  - polls version.json → auto-updates   │
              │    at the menu, never mid-run          │
              └───────────────────┬────────────────────┘
                                  │ multiplayer only:
              ┌───────────────────▼────────────────────┐
              │  CLOUDFLARE WORKER (wackyshooter-mp)   │
              │  workers.dev URL, Durable Objects:     │
              │  - Lobby DO  = public server list      │
              │  - Room DO   = one per game, ≤4 players│
              │    relays JSON over WebSockets         │
              └────────────────────────────────────────┘
```

## Components

| Piece | Lives in | Runs on | What it does |
|---|---|---|---|
| Portal page | `wackyGames/site/` | Cloudflare Pages | Landing page with a card per game |
| wackyShooter | `wackyShooter/` (own repo) | player's browser | The actual game (Phaser 3 + TypeScript) |
| Multiplayer backend | `wackyShooter/server/` | Cloudflare Workers + Durable Objects | Room list + WebSocket message relay |
| DNS / domain | Cloudflare zone `wackygames.com.au` | Cloudflare edge | Points the domain at Pages, proxied + HTTPS |

GitHub (account **chrisforev**): `chrisforev/wackyGames` (portal) and
`chrisforev/wackyShooter` (game + multiplayer server).

## Key design decisions

1. **The website is just files.** `npm run build` turns the game into static
   HTML/JS; Pages copies them to a global CDN. No servers to maintain, free
   hosting, fast everywhere.

2. **The game runs on the player's device.** After loading, singleplayer
   needs no network. Saves live in `localStorage` (per browser, per device):
   high score, autosaved run (CONTINUE), multiplayer name/color profile.

3. **Multiplayer is host-authoritative relay.** The Worker never simulates
   the game — it's a postman. The first player in a room is the **host**:
   their browser runs the enemies/chests/stages and broadcasts compact
   snapshots (~10/s). Other clients mirror what they're told and send back
   their own position plus "I hit enemy #N" claims. If the host leaves, the
   next player is promoted and inherits the simulation. Each message is
   stamped `from: <playerId>` by the Room DO.

4. **Auto-update without breaking runs.** Every deploy embeds a build id and
   writes `version.json`. Running games poll it (60s + on tab focus) and
   reload only at the menu/game-over screens; the autosaved run means even a
   mid-run reload loses nothing.

5. **One portal, many games.** Each game is its own repo built with
   `base: './'` so it works from any subpath. `wackyGames/build.sh` builds
   each sibling game repo and assembles `dist/` (portal at `/`, games in
   subfolders). Adding a game = new card in `site/index.html` + a build block
   in `build.sh`.

## Deploy flow

```
edit game code
  → npm run typecheck            (in wackyShooter)
  → browser smoke test           (playwright-core, window.__game hooks)
  → ./build.sh                   (in wackyGames: builds shooter, assembles dist/)
  → npx wrangler pages deploy dist --project-name wackygames  --branch main
  → npx wrangler pages deploy dist --project-name wackyshooter --branch main
      (run from wackyShooter/ with its own dist; keeps the old URL fresh)
  → git commit + push both repos
multiplayer server changes:
  → cd wackyShooter/server && npx wrangler deploy
```

Live URLs: **wackygames.com.au** (canonical), wackygames.pages.dev (same
deployment), wackyshooter.pages.dev (standalone game, original QR code).

## Credentials & permissions

- **Wrangler OAuth token** — `~/Library/Preferences/.wrangler/config/default.toml`
  (mode `600`, auto-refreshing). Can deploy Workers/Pages and read zones.
  **Cannot** create zones, edit DNS records, or run activation checks — those
  are dashboard-only, by design. Revoke: `npx wrangler logout`.
- **GitHub** — `gh` CLI tokens in `~/.config/gh/hosts.yml`; `gh` is git's
  credential helper. Two accounts: chrisforev (Livia's games), LovelyCookie
  (other projects); switch with `gh auth switch`.
- The domain registration itself lives at **VentraIP** (vip.ventraip.com.au);
  only the nameserver delegation points at Cloudflare.
