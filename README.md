# Catch a Monster

**Mobile 2D Landscape Defense + Monster Catching & Raising**  
Godot 4.3+ | GDScript | Landscape | Android ready

Inspired by:
- **GrowWorld / GrowCastle** – horizontal combat, units on right, enemies from left, protect castle
- **Catch a Monster & Evomon** (Roblox) – catch, raise, evolve, dungeon

---

## Version 0.2.2

### Features

- **Starter Selection**: Choose **1 of 3** starters (Flame Pup / Aqua Fin / Leaf Sprout)
- **Horizontal Combat** (GrowWorld style)
  - Player monsters stand on the right (up to 3 team slots)
  - Wild enemies spawn from the left and move right
  - Protect the Castle – lose when Castle HP = 0 or team wiped
- **Modes**
  - Defense Mode (waves)
  - Hunt Mode (choose Island → different monster pools → catch after defeat)
  - Dungeon Mode (15 waves, mini-boss 5/10, final boss 15, Easy→Nightmare)
- **Monster System**
  - Rank E → SS, Level, EXP, HP/ATK/DEF/SPD
  - Exactly 3 skills per monster
  - Feed for EXP + stats
  - Evolution items + Boss Egg hatch system
- **Catch System**
  - After defeating wild monster in Hunt → throw Ball
  - Success rate = Ball type + Ball level + monster Rank + remaining HP
- **Shop**
  - Buy Balls, food, evolution stones
  - Upgrade Balls (increases catch rate, cost scales with level)
- **Team Management**
  - Collection screen: add/remove up to 3 monsters into active team
- **Local Save**
  - `user://CatchAMonster_Data/player_save.json` (no server needed)
- **UI**
  - Large touch buttons, landscape HUD, Pause menu, Result screen, Settings
- **GitHub Actions**
  - Ready-to-use workflow to build Android APK automatically

---

## Project Structure

```
CatchAMonster/
├── project.godot
├── export_presets.cfg          # Android preset (v0.2.0)
├── .github/workflows/
│   └── build-android.yml       # Auto-build APK on GitHub
├── assets/                     # Place free sprites/SFX/BGM here
├── scenes/
│   ├── menus/   MainMenu, StarterSelect, ModeSelect, HuntSelect, DungeonSelect
│   ├── combat/  CombatScene, Unit
│   └── ui/      Collection, Shop, Settings
├── scripts/
│   ├── autoload/  GameManager, SaveManager, DataManager, AudioManager, SceneManager
│   ├── combat/    Unit.gd, CombatManager.gd
│   └── ui/        ...
└── resources/     (ready for .tres migration)
```

---

## How to Open & Run (Desktop)

1. Install **Godot 4.3+** from https://godotengine.org
2. Open Godot → **Import** → select `project.godot`
3. Press **F5** – starts at Main Menu
4. First run: choose 1 starter → Mode Select → play

### Controls
- Large buttons (touch / mouse)
- Skill 1/2/3 + Unit 1/2/3 selector
- Pause / Auto Battle
- Hunt: after enemy dies → Catch UI → choose Ball

---

## Save Data Location

```
user://CatchAMonster_Data/player_save.json
```

Godot maps `user://` to:
- Android: `/data/data/com.catchamonster.game/files/`
- Windows: `%APPDATA%/Godot/app_userdata/Catch a Monster/`
- Linux: `~/.local/share/godot/app_userdata/Catch a Monster/`

---

## Export Android APK – Two Ways

### A. Manual (Godot Editor)

1. Install Android SDK + Export Templates  
   (Editor → Manage Export Templates → Download 4.3)
2. Project → Export → **Android** preset (already configured)
3. Set your keystore (or use debug for testing)
4. Export Project → `.apk`

Minimum: Android 5.0+, landscape orientation.

### B. GitHub Actions (recommended for CI)

1. Create a new GitHub repository
2. Upload this whole project (or push the zip contents)
3. Go to **Actions** tab → select **Build Android APK**
4. Click **Run workflow** (manual dispatch)  
   *or* push a tag: `git tag v0.2.1 && git push origin v0.2.1`
5. When the job finishes, download the artifact **CatchAMonster-APK**

The workflow:
- Uses Godot 4.3-stable + export templates
- Builds a debug-signed APK
- Uploads it as a downloadable artifact (kept 14 days)

> Note: For release signing you need to add your own keystore as a GitHub Secret and adjust the workflow. The current workflow produces a debug APK suitable for testing.

---

## Assets (included)

- 4 monster spritesheets (Flame Pup, Aqua Fin, Leaf Sprout, Slime) with idle/attack/hit/death frames
- Ball icons, spark effect
- WAV SFX + short BGM loops
- Data in `data/*.json` (data-driven)

## Adding / Replacing Assets

Current version uses **colored placeholders** so the game runs without external downloads.

Recommended free sources:
- https://kenney.nl
- https://opengameart.org
- https://itch.io/game-assets/free
- https://craftpix.net/freebies
- https://freesound.org

Steps:
1. Put sprites under `assets/sprites/monsters/`, `assets/sprites/ui/` etc.
2. In `Unit.gd` `_update_visual()` load texture by monster id and show Sprite2D.
3. Create AnimationPlayer tracks: idle, attack, hit, death, spawn.
4. Put SFX under `assets/audio/sfx/` and BGM under `assets/audio/bgm/`, then load them in `AudioManager.gd`.

See `ASSETS_PLACEHOLDERS.md` for details.

---

## Data-Driven Notes

Monsters, skills, balls, items and islands are currently registered in `DataManager.gd`.  
The `resources/` folders are prepared so you can later move each entry to a `.tres` Resource and only load them – no long hard-coded dictionaries.

---

## Credits & License

- Design inspired by GrowCastle / GrowWorld (Wokzy), Catch a Monster & Evomon (Roblox)
- Engine: Godot 4
- Code: original for this project
- Free assets: credit original authors when you add them

You are free to use, modify and publish (MIT-style for the code).

---

**Version**: 0.2.2  
Upload this folder to GitHub → run the Action → download APK.
