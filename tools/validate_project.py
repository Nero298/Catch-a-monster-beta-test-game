#!/usr/bin/env python3
"""Static CI validation for Catch a Monster.

Checks the data contract and all referenced local assets before Godot export.
"""
from __future__ import annotations
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

def must_file(rel: str) -> Path | None:
    p = ROOT / rel
    if not p.is_file():
        errors.append(f"Missing file: {rel}")
        return None
    return p

def load_json(rel: str):
    p = must_file(rel)
    if p is None:
        return {}
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"Invalid JSON {rel}: {exc}")
        return {}

must_file("project.godot")
preset = must_file("export_presets.cfg")
if preset:
    txt = preset.read_text(encoding="utf-8")
    for needle in [
        '[preset.0]', 'name="Android"', 'platform="Android"',
        'package/unique_name="com.catchamonster.game"',
        'version/code=3', 'version/name="0.2.3"',
        'architectures/armeabi-v7a=true', 'architectures/arm64-v8a=true',
    ]:
        if needle not in txt:
            errors.append(f"Android preset missing: {needle}")
    if 'android_sdk_path=""' in txt:
        errors.append("export_presets.cfg must not hard-code an empty android_sdk_path")

monsters = load_json("data/monsters.json")
skills = load_json("data/skills.json")
balls = load_json("data/balls.json")
items = load_json("data/items.json")
islands = load_json("data/islands.json")

required = {"chamander", "glazadon", "sproutusk", "slime"}
missing = sorted(required - set(monsters))
if missing:
    errors.append(f"Missing core monsters: {', '.join(missing)}")
for mid, m in monsters.items():
    if not isinstance(m, dict):
        errors.append(f"Monster {mid} is not an object")
        continue
    skill_ids = m.get("skills", [])
    if len(skill_ids) != 3:
        errors.append(f"Monster {mid} must have exactly 3 skills (got {len(skill_ids)})")
    for sid in skill_ids:
        if sid not in skills:
            errors.append(f"Monster {mid} references missing skill {sid}")
    for key in ("sprite", "icon"):
        rel = m.get(key, "")
        if rel.startswith("res://"):
            local = ROOT / rel.removeprefix("res://")
            if not local.is_file():
                errors.append(f"Monster {mid} {key} missing: {rel}")

for iid, island in islands.items():
    for mid in island.get("monsters", []):
        if mid not in monsters:
            errors.append(f"Island {iid} references missing monster {mid}")
for bid, ball in balls.items():
    icon = ball.get("icon", "")
    if icon.startswith("res://") and not (ROOT / icon.removeprefix("res://")).is_file():
        errors.append(f"Ball {bid} icon missing: {icon}")

workflow = must_file(".github/workflows/build-android.yml")
if workflow:
    wt = workflow.read_text(encoding="utf-8")
    for needle in [
        "actions/setup-java@v4", "java-version: '17'", "actions/setup-android@v3",
        "--export-debug \"Android\"", "actions/upload-artifact@v4",
        "GODOT_ANDROID_KEYSTORE_DEBUG_PATH",
    ]:
        if needle not in wt:
            errors.append(f"Workflow missing expected step/config: {needle}")

# Ensure the requested old prototype anti-patterns are gone.
for rel in ["scripts/combat/Unit.gd", "scripts/combat/CombatManager.gd"]:
    p = ROOT / rel
    if p.is_file() and "create_tween(" in p.read_text(encoding="utf-8"):
        errors.append(f"Temporary tween still present in {rel}")

if errors:
    print("CI VALIDATION FAILED")
    for e in errors:
        print(" -", e)
    sys.exit(1)
print("CI VALIDATION OK")
print(f"Monsters: {len(monsters)} | Skills: {len(skills)} | Balls: {len(balls)} | Items: {len(items)} | Islands: {len(islands)}")
