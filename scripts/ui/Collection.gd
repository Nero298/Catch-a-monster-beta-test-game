extends Control
## Team screen only: choose and maintain the three monsters used in TD.

const BG_TEXTURE := "res://assets/sprites/backgrounds/forest_battlefield.png"
const TAN := Color("#B89567")

var monster_list: VBoxContainer
var selected_idx := -1
var info_label: Label
var team_slots: HBoxContainer
var status_label: Label
var gold_label: Label

func _ready() -> void:
    _build_ui()
    _refresh()

func _panel(alpha := 0.95) -> StyleBoxFlat:
    return UITheme.flat(Color(TAN.r, TAN.g, TAN.b, alpha), TAN, 8, 3)

func _label(text: String, size := 15, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var l := UITheme.label(text, size, align)
    return l

func _button(text: String, size := 14) -> Button:
    return UITheme.button(text, Vector2(0, 44), size)

func _build_ui() -> void:
    for c in get_children():
        c.queue_free()
    var bg := TextureRect.new()
    bg.texture = load(BG_TEXTURE) if ResourceLoader.exists(BG_TEXTURE) else null
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var shade := ColorRect.new()
    shade.color = Color(0.05, 0.035, 0.02, 0.44)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(shade)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 24)
    margin.add_theme_constant_override("margin_right", 24)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_bottom", 18)
    add_child(margin)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 10)
    margin.add_child(root)

    var top := HBoxContainer.new()
    root.add_child(top)
    var back := _button("BACK", 14)
    back.custom_minimum_size.x = 130
    back.pressed.connect(_on_back)
    top.add_child(back)
    var title := _label("TEAM", 30, HORIZONTAL_ALIGNMENT_CENTER)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(title)
    gold_label = _label("COIN %d" % GameManager.gold, 16, HORIZONTAL_ALIGNMENT_RIGHT)
    top.add_child(gold_label)

    var main := HBoxContainer.new()
    main.size_flags_vertical = Control.SIZE_EXPAND_FILL
    main.add_theme_constant_override("separation", 12)
    root.add_child(main)

    var left := PanelContainer.new()
    left.custom_minimum_size.x = 460
    left.add_theme_stylebox_override("panel", _panel(0.96))
    main.add_child(left)
    var lv := VBoxContainer.new()
    lv.add_theme_constant_override("separation", 8)
    left.add_child(lv)
    lv.add_child(_label("OWNED MONSTERS", 16))
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    lv.add_child(scroll)
    monster_list = VBoxContainer.new()
    monster_list.add_theme_constant_override("separation", 6)
    scroll.add_child(monster_list)

    var right := PanelContainer.new()
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.add_theme_stylebox_override("panel", _panel(0.96))
    main.add_child(right)
    var rv := VBoxContainer.new()
    rv.add_theme_constant_override("separation", 10)
    right.add_child(rv)
    rv.add_child(_label("ACTIVE TEAM  (MAX 3)", 16, HORIZONTAL_ALIGNMENT_CENTER))
    team_slots = HBoxContainer.new()
    team_slots.alignment = BoxContainer.ALIGNMENT_CENTER
    team_slots.add_theme_constant_override("separation", 12)
    rv.add_child(team_slots)

    var control_row := HBoxContainer.new()
    control_row.add_theme_constant_override("separation", 8)
    rv.add_child(control_row)
    var add_btn := _button("ADD TO TEAM")
    add_btn.pressed.connect(_on_add)
    control_row.add_child(add_btn)
    var remove_btn := _button("REMOVE")
    remove_btn.pressed.connect(_on_remove)
    control_row.add_child(remove_btn)
    var swap_hint := _label("Select a monster, then add it to an empty slot.", 12, HORIZONTAL_ALIGNMENT_CENTER)
    rv.add_child(swap_hint)

    info_label = _label("Select a monster", 13)
    info_label.custom_minimum_size.y = 150
    info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    rv.add_child(info_label)
    status_label = _label("Team is locked once you enter battle.", 12, HORIZONTAL_ALIGNMENT_CENTER)
    rv.add_child(status_label)

func _refresh() -> void:
    _refresh_list()
    _refresh_slots()
    _refresh_info()
    if is_instance_valid(gold_label): gold_label.text = "COIN %d" % GameManager.gold

func _refresh_list() -> void:
    for c in monster_list.get_children(): c.queue_free()
    for i in range(GameManager.owned_monsters.size()):
        var m: Dictionary = GameManager.owned_monsters[i]
        var btn := _button("%s    Lv.%d    %s" % [m.get("name", "Monster"), m.get("level", 1), m.get("rank", "E")], 13)
        btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
        btn.pressed.connect(_select.bind(i))
        monster_list.add_child(btn)

func _refresh_slots() -> void:
    for c in team_slots.get_children(): c.queue_free()
    for i in range(3):
        var slot := PanelContainer.new()
        slot.custom_minimum_size = Vector2(165, 210)
        slot.add_theme_stylebox_override("panel", _panel(0.90))
        team_slots.add_child(slot)
        var v := VBoxContainer.new()
        slot.add_child(v)
        v.add_child(_label("SLOT %d" % (i + 1), 12, HORIZONTAL_ALIGNMENT_CENTER))
        var tex := TextureRect.new()
        tex.custom_minimum_size = Vector2(100, 100)
        tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        v.add_child(tex)
        var nm := "EMPTY"
        if i < GameManager.player_team.size():
            var m: Dictionary = GameManager.player_team[i]
            nm = "%s\nLv.%d" % [m.get("name", "Monster"), m.get("level", 1)]
            var path := str(m.get("icon", ""))
            if ResourceLoader.exists(path): tex.texture = load(path)
        v.add_child(_label(nm, 12, HORIZONTAL_ALIGNMENT_CENTER))
        var use := _button("SELECT", 12)
        use.custom_minimum_size.y = 36
        use.pressed.connect(_slot_select.bind(i))
        v.add_child(use)

func _select(idx: int) -> void:
    selected_idx = idx
    _refresh_info()

func _slot_select(idx: int) -> void:
    if idx >= GameManager.player_team.size():
        return
    var uid = GameManager.player_team[idx].get("uid", "")
    for i in range(GameManager.owned_monsters.size()):
        if GameManager.owned_monsters[i].get("uid", "") == uid:
            selected_idx = i
            _refresh_info()
            return

func _refresh_info() -> void:
    if selected_idx < 0 or selected_idx >= GameManager.owned_monsters.size():
        info_label.text = "Select a monster from the left.\n\nChoose up to three monsters for Tower Defense."
        return
    var m: Dictionary = GameManager.owned_monsters[selected_idx]
    info_label.text = "%s\nRank %s   Lv.%d\nHP %d   ATK %d   DEF %d   SPD %d\n\n%s" % [m.get("name", "Monster"), m.get("rank", "E"), m.get("level", 1), m.get("max_hp", 0), m.get("atk", 0), m.get("def", 0), m.get("spd", 0), m.get("description", "")]

func _on_add() -> void:
    if selected_idx < 0 or selected_idx >= GameManager.owned_monsters.size():
        status_label.text = "Select a monster first."
        return
    if GameManager.player_team.size() >= 3:
        status_label.text = "Team is full. Remove one first."
        return
    var m: Dictionary = GameManager.owned_monsters[selected_idx]
    for t in GameManager.player_team:
        if t.get("uid", "") == m.get("uid", ""):
            status_label.text = "That monster is already in the team."
            return
    GameManager.player_team.append(m.duplicate(true))
    GameManager.recalculate_base_hp_from_team()
    SaveManager.save_game()
    status_label.text = "%s added to Team." % m.get("name", "Monster")
    _refresh()

func _on_remove() -> void:
    if selected_idx < 0 or selected_idx >= GameManager.owned_monsters.size():
        status_label.text = "Select a team monster first."
        return
    var uid = GameManager.owned_monsters[selected_idx].get("uid", "")
    for i in range(GameManager.player_team.size() - 1, -1, -1):
        if GameManager.player_team[i].get("uid", "") == uid:
            GameManager.player_team.remove_at(i)
            GameManager.recalculate_base_hp_from_team()
            SaveManager.save_game()
            status_label.text = "Monster removed from Team."
            _refresh()
            return
    status_label.text = "That monster is not in the Team."

func _on_back() -> void:
    AudioManager.play_sfx("button")
    SceneManager.go_main_menu()
