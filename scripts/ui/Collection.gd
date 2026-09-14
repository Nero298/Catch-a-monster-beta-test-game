extends Control
## Monster collection with touch-friendly team slots + actual drag/drop reordering.

var monster_list: VBoxContainer
var selected_idx := -1
var info_label: Label
var team_slots: HBoxContainer
var inventory_label: Label
var hatch_label: Label
var hatch_bar: ProgressBar
var status_label: Label

func _ready() -> void:
    _build_ui()
    _refresh()
    set_process(true)

func _style_box(bg: Color, border: Color = Color.TRANSPARENT, radius := 16, width := 0) -> StyleBoxFlat:
    var b := StyleBoxFlat.new()
    b.bg_color = bg
    b.border_color = border
    b.set_border_width_all(width)
    b.set_corner_radius_all(radius)
    b.content_margin_left = 16
    b.content_margin_right = 16
    b.content_margin_top = 12
    b.content_margin_bottom = 12
    return b

func _button(text: String, size := 15) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(0, 48)
    b.add_theme_font_size_override("font_size", size)
    b.add_theme_stylebox_override("normal", _style_box(Color("#18253a"), Color("#38506d"), 12, 1))
    b.add_theme_stylebox_override("hover", _style_box(Color("#233a58"), Color("#72c9f2"), 12, 2))
    return b

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#07111e")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 26)
    margin.add_theme_constant_override("margin_right", 26)
    margin.add_theme_constant_override("margin_top", 20)
    margin.add_theme_constant_override("margin_bottom", 20)
    add_child(margin)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 10)
    margin.add_child(root)

    var top := HBoxContainer.new()
    root.add_child(top)
    var title := Label.new()
    title.text = "COLLECTION"
    title.add_theme_font_size_override("font_size", 28)
    top.add_child(title)
    var top_spacer := Control.new()
    top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(top_spacer)
    var gold := Label.new()
    gold.text = "✦ %d GOLD" % GameManager.gold
    gold.add_theme_font_size_override("font_size", 18)
    top.add_child(gold)

    var columns := HBoxContainer.new()
    columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
    columns.add_theme_constant_override("separation", 12)
    root.add_child(columns)

    var left := PanelContainer.new()
    left.custom_minimum_size = Vector2(420, 0)
    left.add_theme_stylebox_override("panel", _style_box(Color("#0d1928"), Color("#29415a"), 16, 1))
    columns.add_child(left)
    var lv := VBoxContainer.new()
    lv.add_theme_constant_override("separation", 8)
    left.add_child(lv)
    lv.add_child(_mk_label("OWNED MONSTERS", 15))
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    lv.add_child(scroll)
    monster_list = VBoxContainer.new()
    monster_list.add_theme_constant_override("separation", 6)
    monster_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(monster_list)

    var right := PanelContainer.new()
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.add_theme_stylebox_override("panel", _style_box(Color("#0d1928"), Color("#29415a"), 16, 1))
    columns.add_child(right)
    var rv := VBoxContainer.new()
    rv.add_theme_constant_override("separation", 8)
    right.add_child(rv)
    rv.add_child(_mk_label("ACTIVE TEAM • 3 SLOTS", 15))
    team_slots = HBoxContainer.new()
    team_slots.alignment = BoxContainer.ALIGNMENT_CENTER
    team_slots.add_theme_constant_override("separation", 12)
    rv.add_child(team_slots)

    var controls := HBoxContainer.new()
    controls.add_theme_constant_override("separation", 8)
    rv.add_child(controls)
    var add_btn := _button("ADD TO TEAM")
    add_btn.pressed.connect(_on_add)
    controls.add_child(add_btn)
    var remove_btn := _button("REMOVE")
    remove_btn.pressed.connect(_on_remove)
    controls.add_child(remove_btn)
    var feed_btn := _button("FEED")
    feed_btn.pressed.connect(_on_feed)
    controls.add_child(feed_btn)

    info_label = _mk_label("Select a monster", 13)
    info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info_label.custom_minimum_size.y = 96
    rv.add_child(info_label)

    inventory_label = _mk_label("Inventory", 12)
    inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    rv.add_child(inventory_label)

    var hatch_panel := PanelContainer.new()
    hatch_panel.add_theme_stylebox_override("panel", _style_box(Color("#101f30"), Color("#315170"), 12, 1))
    rv.add_child(hatch_panel)
    var hatch_v := VBoxContainer.new()
    hatch_v.add_theme_constant_override("separation", 5)
    hatch_panel.add_child(hatch_v)
    hatch_label = _mk_label("Hatch idle", 12)
    hatch_v.add_child(hatch_label)
    hatch_bar = ProgressBar.new()
    hatch_bar.custom_minimum_size.y = 22
    hatch_bar.show_percentage = true
    hatch_v.add_child(hatch_bar)
    var hatch_buttons := HBoxContainer.new()
    hatch_buttons.add_theme_constant_override("separation", 8)
    hatch_v.add_child(hatch_buttons)
    var start := _button("START HATCH", 13)
    start.pressed.connect(_on_start_hatch)
    hatch_buttons.add_child(start)
    var finish := _button("FINISH", 13)
    finish.pressed.connect(_on_finish_hatch)
    hatch_buttons.add_child(finish)
    var speed := _button("SPEED UP", 13)
    speed.pressed.connect(_on_speed_hatch)
    hatch_buttons.add_child(speed)

    status_label = _mk_label("Drag a filled team slot onto another slot to swap.", 11, HORIZONTAL_ALIGNMENT_CENTER)
    rv.add_child(status_label)

    var bottom := HBoxContainer.new()
    root.add_child(bottom)
    var back := _button("← BACK", 14)
    back.custom_minimum_size = Vector2(130, 46)
    back.pressed.connect(_on_back)
    bottom.add_child(back)

func _mk_label(text: String, size: int, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.horizontal_alignment = align
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    return l

func _refresh() -> void:
    _refresh_monster_list()
    _refresh_team_slots()
    _refresh_info()
    _refresh_inventory()
    _update_hatch()

func _refresh_monster_list() -> void:
    for child in monster_list.get_children():
        child.queue_free()
    for i in range(GameManager.owned_monsters.size()):
        var m: Dictionary = GameManager.owned_monsters[i]
        var btn := Button.new()
        btn.custom_minimum_size = Vector2(0, 64)
        btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
        btn.text = "%s   Lv.%d • %s   HP %d  ATK %d" % [m.get("name", "?"), m.get("level", 1), m.get("rank", "E"), m.get("max_hp", 0), m.get("atk", 0)]
        btn.add_theme_font_size_override("font_size", 13)
        var active := false
        for t in GameManager.player_team:
            if t.get("uid") == m.get("uid"):
                active = true
                break
        btn.add_theme_stylebox_override("normal", _style_box(Color("#173124") if active else Color("#111f31"), Color("#61b893") if active else Color("#2f475d"), 12, 1))
        btn.pressed.connect(_select.bind(i))
        monster_list.add_child(btn)

func _refresh_team_slots() -> void:
    for child in team_slots.get_children():
        child.queue_free()
    for i in range(3):
        var slot = preload("res://scripts/ui/TeamSlot.gd").new()
        slot.custom_minimum_size = Vector2(145, 160)
        var data: Dictionary = GameManager.player_team[i] if i < GameManager.player_team.size() else {}
        slot.setup(i, data)
        slot.swap_requested.connect(_swap_slots)
        slot.pressed_slot.connect(_slot_clicked)
        slot.add_theme_stylebox_override("panel", _style_box(Color("#132338"), Color("#365a79"), 14, 1))
        team_slots.add_child(slot)

func _select(idx: int) -> void:
    selected_idx = idx
    _refresh_info()

func _slot_clicked(idx: int) -> void:
    if idx < GameManager.player_team.size():
        var uid = GameManager.player_team[idx].get("uid", "")
        for i in range(GameManager.owned_monsters.size()):
            if GameManager.owned_monsters[i].get("uid", "") == uid:
                selected_idx = i
                _refresh_info()
                return

func _refresh_info() -> void:
    if selected_idx < 0 or selected_idx >= GameManager.owned_monsters.size():
        info_label.text = "Select a monster from the list.\nAdd it to the team, feed it, or drag team slots to reorder."
        return
    var m: Dictionary = GameManager.owned_monsters[selected_idx]
    info_label.text = "%s  •  Rank %s  •  Lv.%d\nEXP %d / %d\nHP %d  ATK %d  DEF %d  SPD %d\nSkills: %s" % [m.get("name", "?"), m.get("rank", "E"), m.get("level", 1), m.get("exp", 0), m.get("exp_to_next", 50), m.get("max_hp", 0), m.get("atk", 0), m.get("def", 0), m.get("spd", 0), ", ".join(m.get("skills", []))]

func _refresh_inventory() -> void:
    var parts: Array[String] = []
    for k in GameManager.inventory.keys():
        parts.append("%s x%d" % [k, GameManager.inventory[k]])
    for k in GameManager.balls.keys():
        parts.append("%s x%d (Lv%d)" % [k.capitalize(), GameManager.balls[k], GameManager.ball_levels.get(k, 1)])
    inventory_label.text = "INVENTORY: " + (", ".join(parts) if not parts.is_empty() else "Empty")

func _on_add() -> void:
    if selected_idx < 0 or selected_idx >= GameManager.owned_monsters.size():
        return
    if GameManager.player_team.size() >= 3:
        status_label.text = "Team is full — drag slots to reorder."
        return
    var m: Dictionary = GameManager.owned_monsters[selected_idx]
    for t in GameManager.player_team:
        if t.get("uid") == m.get("uid"):
            status_label.text = "That monster is already in your team."
            return
    GameManager.player_team.append(m.duplicate(true))
    SaveManager.save_game()
    AudioManager.play_sfx("button")
    status_label.text = "Added to team."
    _refresh()

func _on_remove() -> void:
    if selected_idx < 0 or selected_idx >= GameManager.owned_monsters.size():
        return
    var uid = GameManager.owned_monsters[selected_idx].get("uid", "")
    for i in range(GameManager.player_team.size() - 1, -1, -1):
        if GameManager.player_team[i].get("uid") == uid:
            GameManager.player_team.remove_at(i)
            break
    SaveManager.save_game()
    status_label.text = "Removed from team."
    _refresh()

func _swap_slots(from_index: int, to_index: int) -> void:
    if from_index < 0 or to_index < 0 or from_index >= GameManager.player_team.size() or to_index >= GameManager.player_team.size():
        return
    var tmp = GameManager.player_team[from_index]
    GameManager.player_team[from_index] = GameManager.player_team[to_index]
    GameManager.player_team[to_index] = tmp
    SaveManager.save_game()
    AudioManager.play_sfx("button")
    status_label.text = "Team order updated."
    _refresh()

func _on_feed() -> void:
    if selected_idx < 0 or selected_idx >= GameManager.owned_monsters.size():
        return
    var used := false
    if GameManager.inventory.get("premium_food", 0) > 0:
        used = GameManager.use_item("premium_food", 1)
    elif GameManager.inventory.get("meat", 0) > 0:
        used = GameManager.use_item("meat", 1)
    if not used:
        status_label.text = "No food. Buy some in Shop."
        return
    var m: Dictionary = GameManager.owned_monsters[selected_idx]
    m["exp"] = m.get("exp", 0) + 40
    while m["exp"] >= m.get("exp_to_next", 50):
        m["exp"] -= m["exp_to_next"]
        m["level"] = m.get("level", 1) + 1
        m["exp_to_next"] = DataManager._exp_for_level(m["level"])
        m["max_hp"] = int(m["max_hp"] * 1.08)
        m["hp"] = m["max_hp"]
        m["atk"] = int(m["atk"] * 1.07)
        m["def"] = int(m["def"] * 1.06)
        m["spd"] = int(m["spd"] * 1.04)
        AudioManager.play_sfx("level_up")
    for t in GameManager.player_team:
        if t.get("uid") == m.get("uid"):
            for k in ["level", "exp", "max_hp", "hp", "atk", "def", "spd"]:
                t[k] = m[k]
    SaveManager.save_game()
    status_label.text = "Fed %s." % m.get("name", "monster")
    _refresh()

func _update_hatch() -> void:
    if GameManager.hatching_egg.is_empty():
        var eggs = GameManager.inventory.get("boss_egg", 0)
        hatch_label.text = "BOSS EGG • %d available" % eggs
        hatch_bar.visible = false
    else:
        var p := GameManager.get_hatch_progress()
        hatch_label.text = "HATCHING • %.0f%%" % (p * 100.0)
        hatch_bar.visible = true
        hatch_bar.value = p * 100.0

func _process(_delta: float) -> void:
    if is_instance_valid(hatch_bar) and not GameManager.hatching_egg.is_empty():
        var p := GameManager.get_hatch_progress()
        hatch_bar.visible = true
        hatch_bar.value = p * 100.0
        hatch_label.text = "HATCHING • %.0f%%" % (p * 100.0)

func _on_start_hatch() -> void:
    status_label.text = "Boss Egg hatch started." if GameManager.start_hatch("boss_egg") else "Need a Boss Egg or finish the current hatch."
    _refresh()

func _on_finish_hatch() -> void:
    var mon = GameManager.finish_hatch()
    status_label.text = "Hatched %s!" % mon.get("name", "monster") if not mon.is_empty() else "Hatch is not finished yet."
    if not mon.is_empty():
        AudioManager.play_sfx("level_up")
    _refresh()

func _on_speed_hatch() -> void:
    status_label.text = "Hatch speed boosted." if GameManager.speed_up_hatch() else "Need Premium Food or 80 Gold."
    _refresh()

func _on_back() -> void:
    AudioManager.play_sfx("button")
    SceneManager.go_mode_select()
