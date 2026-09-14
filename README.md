# Catch a Monster — 0.2.3

A Godot 4.3 mobile landscape prototype combining horizontal tower defense, monster catching, training, evolution and dungeon runs.

## Current playable loop

1. Launch → Main Menu.
2. First launch → choose exactly **1 of 3 starters**.
3. Choose **Defense / Hunt / Dungeon**.
4. Combat runs left → right: wild monsters spawn from the left, your team defends the castle from the right.
5. Hunt battles can open the Catch panel after an enemy is defeated.
6. Collection lets you feed monsters, hatch boss eggs and rearrange your active team with **drag & drop**.
7. All progress is saved locally with a backup JSON file.

## Main-menu GUI layout

The landscape screen is divided into five areas:

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│ Trainer card / local save                          ✦ GOLD                   │
│                                                                              │
│                         CATCH A MONSTER                                     │
│                    DEFEND • HUNT • CATCH • RAISE                            │
│                                                                              │
│ ┌─────────────────────┐      ┌───────────────────────────────────────────┐  │
│ │ ACTIVE TEAM         │      │                 PLAY                       │  │
│ │ [Slot1] [Slot2]     │      │     Defense / Hunt / Dungeon              │  │
│ │ [Slot3]             │      │                                           │  │
│ │                     │      │  COLLECTION   SHOP   SETTINGS             │  │
│ └─────────────────────┘      └───────────────────────────────────────────┘  │
│                    Version • Android landscape • local save                │
└──────────────────────────────────────────────────────────────────────────────┘
```

Buttons are intentionally large for touch. The first-launch Play button becomes **Start Adventure** until a starter is selected.

## Combat GUI layout

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│ CASTLE HP                         WAVE 3 / 10                    ✦ GOLD       │
├──────────────┐                                                       ┌───────┤
│ ACTIVE TEAM  │       enemy ← ← ←        battlefield       → → →     │castle │
│ SLOT 1       │                                                       │       │
│ SLOT 2       │                                             monsters  │       │
│ SLOT 3       │                                                       │       │
├──────────────┴───────────────────────────────────────────────────────┴───────┤
│ PAUSE     AUTO: OFF             [ SKILL 1 ] [ SKILL 2 ] [ SKILL 3 ]        │
└──────────────────────────────────────────────────────────────────────────────┘
```

When a catch is available, the Catch panel appears in the center with Basic / Great / Ultra Ball choices. Results and pause use modal panels above the combat HUD.

## Monster data

Monster, skill, ball, item and island data are stored in JSON under `data/`.

The four intended first-class examples are:

- Chamander — Fire starter
- Glazadon — Water starter
- Sproutusk — Grass starter
- Slime — basic wild enemy

Each monster has exactly 3 skill IDs. The Unit scene uses a 5-frame spritesheet and an `AnimationPlayer` with explicit `idle`, `attack`, `hit`, `death` and `spawn` tracks.

## Team drag & drop

Open **Collection**. Filled team slots can be dragged onto another filled slot to swap their positions. This changes the saved `player_team` order used by combat.

## Local save

The game saves to:

```text
user://CatchAMonster_Data/player_save.json
user://CatchAMonster_Data/player_save_backup.json
```

Using `user://` is deliberate: it is the portable Godot save location for the current app profile. The exact physical Android filesystem path is platform-managed; the project does not request broad storage access just to save game progress.

## Android build on GitHub Actions

The repository contains `.github/workflows/build-android.yml`.

The workflow:

- uses **Godot 4.3-stable**;
- installs **OpenJDK 17**;
- installs Android platform 34 + build-tools 34.0.0 + NDK 23.2.8568313 + CMake 3.10.2.4988404;
- installs the Godot 4.3 Android export templates;
- creates a CI debug keystore;
- writes Godot `EditorSettings` for Java/Android SDK/debug signing;
- imports project resources;
- exports `build/CatchAMonster.apk` with the `Android` preset;
- checks that the APK is non-empty and prints SHA-256;
- uploads the APK as `CatchAMonster-APK`.

Godot's 4.3 documentation specifies OpenJDK 17 and the Android SDK, and documents `GODOT_ANDROID_KEYSTORE_DEBUG_PATH`, `..._USER` and `..._PASSWORD` as export environment variables. The 4.3 documentation also lists the same SDK package versions used by this workflow. citeturn654737search0turn654737search2

### GitHub steps

1. Create a GitHub repository.
2. Upload the **contents** of this ZIP so `project.godot` is in the repository root.
3. Open **Actions → Build Android APK**.
4. Use **Run workflow**, or push to a branch/tag.
5. Download the `CatchAMonster-APK` artifact.

`--export-debug` is used because it is the intended CI/testing build. A release APK requires your own production keystore and release credentials.

## Manual Godot export

Open the project in Godot 4.3, ensure Android export templates are installed, select the `Android` preset, and export a debug APK for testing.

## Asset notes

The ZIP contains working monster spritesheets, monster icons, a battlefield background, ball icons, VFX and WAV audio. The four requested core monster sprites are already included. Some later-world monster entries currently reuse core sprites as placeholders; those are deliberately isolated in `data/monsters.json` and can be replaced without changing gameplay code.

No external asset download is required to build the current APK.

## Project structure

```text
Catch-a-monster-beta-test-game-FIXED/
├── project.godot
├── export_presets.cfg
├── .github/workflows/build-android.yml
├── assets/
├── data/
├── scenes/
└── scripts/
```

## Version

**0.2.3**
