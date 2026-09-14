# Asset status

The current ZIP does not depend on external asset downloads for its playable core.

## Core production-ready placeholders

These are included and wired into the game:

- `assets/sprites/monsters/chamander.png`
- `assets/sprites/monsters/glazadon.png`
- `assets/sprites/monsters/sproutusk.png`
- `assets/sprites/monsters/slime.png`
- matching 64×64 monster icons
- `assets/sprites/backgrounds/forest_battlefield.png`
- ball icons and spark effect
- SFX and short BGM WAV files

## Known placeholder reuse

Later monsters such as `wolf`, `bat`, `golem`, `dragon_whelp` and `boss_inferno` currently reuse core sprites. This is intentional so the project has no missing resources while the combat/data pipeline is being expanded.

Replace only the `sprite` and `icon` paths in `data/monsters.json` when dedicated art is available.
