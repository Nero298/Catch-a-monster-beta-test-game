# Catch a Monster v0.2.13

## GUI / Battle rebuild
- Rebuilt the 16:9 hub around the exact 14-zone blueprint: top 10 HP, 9 MANA, 11 COIN, 12 GEM, 13 HUNTER, 14 DUNGEON; bottom 1 SETTINGS, 2 TEAM, 3 SHOP, 4 BATTLE, 5 INDEX, 6 EVOLUTION; 8 compact FARM; 7 remains open background.
- All main controls are custom polygon ShapeButtons with a thick, visible carved-stone frame.
- Battle is the inverted trapezoid center button; no extra “BATTLE is the main mode” helper text.
- Combat HUD now uses the same stone/tan button language.
- Combat playfield expands to the actual viewport so no dead dark strip remains on wider 16:9 screens.
- Battle now robustly creates/restores the active team, synchronizes castle HP to the team, spawns the first enemy immediately, and enlarges unit sprites for visibility.
- Pause overlay is process-mode-always and pauses/unpauses reliably.
- Tower Defense victory still grants +1 gem.
