#!/usr/bin/env bash
# Assemble the Wacky Games portal: landing page at / plus each game in its
# own subfolder. Add a build+copy block per game as the collection grows.
set -euo pipefail
cd "$(dirname "$0")"

rm -rf dist
mkdir -p dist

# portal landing page
cp -R site/ dist/

# game 1: wackyShooter -> /shooter/
(cd ../wackyShooter && npm run build)
mkdir -p dist/shooter
cp -R ../wackyShooter/dist/ dist/shooter/

# game 2: Crazy Café -> /cafe/
(cd ../crazyCafe && npm run build)
mkdir -p dist/cafe
cp -R ../crazyCafe/dist/ dist/cafe/

# game 3: Fruit Clicker -> /fruit/
(cd ../fruitClicker && npm run build)
mkdir -p dist/fruit
cp -R ../fruitClicker/dist/ dist/fruit/

echo "dist/ ready — deploy with:"
echo "  npx wrangler pages deploy dist --project-name wackygames --branch main"
