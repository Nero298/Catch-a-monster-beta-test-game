# Fixes v0.2.4 (2026-09-14)

## Critical gameplay / layout
1. **Player LEFT, enemies RIGHT** — Spawn/PlayerSpawn/Castle flipped. Enemies march left toward base.
2. **Wave counter bug (Wave 85/8)** — `_on_wave_cleared` could fire every frame during await; added `wave_transitioning` guard.
3. **Skill buttons stuck after one use** — Skill labels now refresh every frame; cooldown UI shows name + remaining time; disabled only while CD > 0.
4. **Pause locks all input** — PauseMenu + ResultPanel use `process_mode = ALWAYS` so buttons work while tree is paused.
5. **Sprite “2-frame jitter”** — Single-image sprites no longer treated as 5-frame sheets; idle/attack use scale bob only. Sheets still animate if width ≥ 128.

## Flow / UX
6. After starter select → **Main Menu hub** (not Mode Select).
7. Main Menu redesigned: team preview + **Defense (default)**, Hunt, Dungeon, Collection, Shop, Settings.
8. Starter cards show HP/ATK/DEF/SPD + skill names.
9. Combat team slots show real monster names/levels.

## Visual
10. Softened castle wall visual on the left (defend target, not random right column).
11. Main menu cards / accents closer to GrowCastle-style panels.

## How to rebuild APK
Godot **4.3** → Export → Android, or GitHub Actions `build-android.yml`.

## GUI redesign / TD focus
- Replaced the main hub UI with a single tan/white visual language and geometric button layout.
- Main hub zones now follow the requested 1-14 order: Settings, Team, Shop, Battle, Index, Evolution, Background, Farm, Mana, Team HP, Coin, Gem, Hunter, Dungeon.
- Battle is the only active game mode from the main hub; unfinished features display a Coming Soon panel.
- Battle is a geometric pentagon/trapezoid CTA with quadrilateral companion buttons.
- Team back returns directly to MainMenu instead of the retired Mode Select screen.
- Shop uses the forest background and tan card layout with item names above BUY buttons.
- Team selection is performed only before entering battle; the battle HUD has no team-changing control.
- Castle HP is the aggregate current/max HP of the active battle team, not a fixed 1000 HP base.
- Player and enemy Unit visuals are forced visible and rendered above the battlefield to fix missing monster/slime visuals.
