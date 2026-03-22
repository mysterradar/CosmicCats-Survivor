extends Control

signal shop_closed

@onready var kibble_label = $Panel/TopBar/KibbleLabel
@onready var tab_bar = $Panel/TabBar
@onready var item_grid = $Panel/ScrollContainer/ItemGrid

const UPGRADES = {
    "combat": [
        {"key":"damage_bonus",   "name":"Puissance Plasma", "icon":"⚡", "base_cost":300, "desc":"+20% dégâts/niv"},
        {"key":"fire_rate_bonus","name":"Cadence de Tir",   "icon":"🔫", "base_cost":250, "desc":"-15% délai tir/niv"},
    ],
    "defense": [
        {"key":"health_bonus",   "name":"Santé Max",        "icon":"❤️",  "base_cost":200, "desc":"+30 PV/niv"},
        {"key":"shield_bonus",   "name":"Bouclier Renforcé","icon":"🛡️",  "base_cost":250, "desc":"-1s cooldown bouclier/niv"},
    ],
    "mobility": [
        {"key":"speed_bonus",    "name":"Hyper Réacteurs",  "icon":"💨", "base_cost":250, "desc":"+50 vitesse/niv"},
        {"key":"xp_radius_bonus","name":"Rayon XP",         "icon":"🧲", "base_cost":200, "desc":"+40px rayon aspiration/niv"},
    ]
}

const TAB_NAMES = ["⚔️ Combat", "🛡️ Défense", "⚡ Mobilité"]
const TAB_KEYS  = ["combat", "defense", "mobility"]
var current_tab = 0

func _ready():
    visible = false

func open():
    visible = true
    update_ui()

func update_ui():
    if SaveManager and SaveManager.data:
        kibble_label.text = "🍪 %d Croquettes" % SaveManager.data.get("cosmic_kibble", 0)
    _update_tabs()
    _build_grid()

func _update_tabs():
    for i in tab_bar.get_child_count():
        var btn = tab_bar.get_child(i)
        btn.modulate = Color(1,1,1) if i == current_tab else Color(0.5,0.5,0.5)

func _build_grid():
    for child in item_grid.get_children():
        child.queue_free()
    var upgrades = UPGRADES[TAB_KEYS[current_tab]]
    for upg in upgrades:
        item_grid.add_child(_make_card(upg))

func _make_card(upg: Dictionary) -> Control:
    var current_level = 0
    if SaveManager and SaveManager.data.has("perm_upgrades"):
        current_level = SaveManager.data["perm_upgrades"].get(upg["key"], 0)
    var cost = upg["base_cost"] * (current_level + 1)
    var kibble = SaveManager.data.get("cosmic_kibble", 0) if SaveManager else 0
    var maxed = current_level >= 5

    var card = PanelContainer.new()
    var vbox = VBoxContainer.new()
    card.add_child(vbox)

    var title = Label.new()
    title.text = "%s %s" % [upg["icon"], upg["name"]]
    title.add_theme_color_override("font_color", Color(0.8, 0.7, 1.0))
    vbox.add_child(title)

    var desc = Label.new()
    desc.text = upg["desc"]
    desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
    desc.add_theme_font_size_override("font_size", 11)
    vbox.add_child(desc)

    var stars = Label.new()
    stars.text = "★".repeat(current_level) + "☆".repeat(5 - current_level)
    stars.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
    vbox.add_child(stars)

    var btn = Button.new()
    if maxed:
        btn.text = "✅ MAX"
        btn.disabled = true
    else:
        btn.text = "🍪 %d" % cost
        btn.disabled = kibble < cost
    btn.pressed.connect(_on_buy.bind(upg["key"], cost))
    vbox.add_child(btn)

    return card

func _on_buy(key: String, cost: int):
    if not SaveManager or not SaveManager.data: return
    if SaveManager.data.get("cosmic_kibble", 0) < cost: return
    var level = SaveManager.data["perm_upgrades"].get(key, 0)
    if level >= 5: return
    SaveManager.data["cosmic_kibble"] -= cost
    SaveManager.data["perm_upgrades"][key] = level + 1
    SaveManager.save_game()
    update_ui()

func _on_tab_pressed(idx: int):
    current_tab = idx
    update_ui()

func _on_back_button_pressed():
    visible = false
    emit_signal("shop_closed")
