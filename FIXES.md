# Fixes applied (2026-09-14)

## Root cause of green/blue screen after Godot logo
The previous source zip was **missing critical UI scripts** that the main scene and menus require:
- `scripts/ui/MainMenu.gd`
- `scripts/ui/ModeSelect.gd`
- `scripts/ui/StarterSelect.gd`
- `scripts/ui/HuntSelect.gd`
- `scripts/ui/Settings.gd`
- `scripts/ui/Shop.gd`
- `scripts/ui/TeamSlot.gd`

Without `MainMenu.gd`, the engine loaded the splash then failed the main scene → stuck on clear color.

## Additional fixes in this package
1. Restored full set of UI + combat scripts from the fixed tree.
2. Restored all monster sprites (`chamander`, `glazadon`, `sproutusk`, `slime` + icons).
3. Fixed mixed tab/space indentation in `SaveManager.gd`, `MainMenu.gd`, `Collection.gd`, `TeamSlot.gd` (Godot 4 rejects mixed indent in one file).
4. Added missing `MainMenu._update_gold()` which was called from `_ready()` and would throw at runtime.
5. Re-ran static validation (`tools/validate_project.py`) — OK.
6. Ensured Android export preset + Godot 4.3 mobile renderer settings.

## How to build APK
- Open this folder in **Godot 4.3** (same as CI).
- Project → Export → Android (preset already configured).
- Or push to GitHub and run the `build-android.yml` workflow.

## Note
Do not open an incomplete copy that only has partial `scripts/ui/`. Always use this full tree.
