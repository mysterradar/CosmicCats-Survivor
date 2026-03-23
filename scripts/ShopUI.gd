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
	],
	"weapons": [
		{"key":"piercing_bullet",  "name":"Balles Perçantes",   "icon":"🎯", "base_cost":600,  "desc":"Balles traversent 1 ennemi", "wave_req":5},
		{"key":"missile_cluster",  "name":"Missiles Cluster",   "icon":"🚀", "base_cost":1000, "desc":"Missiles se séparent en 3", "wave_req":10},
		{"key":"plasma_overcharge","name":"Plasma Surchargé",   "icon":"⚛️", "base_cost":1500, "desc":"PlasmaBlade +50% taille",   "wave_req":15},
	],
	"pilot": [
		{"key":"xp_boost_perm",  "name":"XP Boost Pilote",      "icon":"🐱", "base_cost":300,  "desc":"+20% XP chat/partie"},
		{"key":"fur_drop",       "name":"Fur Drop",              "icon":"🪶", "base_cost":500,  "desc":"+50% Poils droppés"},
		{"key":"passive_amp",    "name":"Amplificateur Passif",  "icon":"✨", "base_cost":1000, "desc":"Passive chat +5% /niv"},
	],
	"ship": [
		{"key":"hull_reinforcement","name":"Coque Renforcée",    "icon":"🔩", "base_cost":400, "desc":"+50 HP max/niv"},
		{"key":"engine_boost",     "name":"Propulseurs Améliorés","icon":"🔥","base_cost":400, "desc":"+30 vitesse/niv"},
		{"key":"weapon_slot",      "name":"Slot Arme",           "icon":"⚔️", "base_cost":800, "desc":"+1 sardine orbitante au départ"},
	],
}

const TAB_NAMES = ["⚔️ Combat", "🛡️ Défense", "⚡ Mobilité", "🎯 Armes", "🐱 Pilote", "🚀 Vaisseau"]
const TAB_KEYS  = ["combat", "defense", "mobility", "weapons", "pilot", "ship"]
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
	var maxed = current_level >= 10
	var wave_req = upg.get("wave_req", 0)
	var wave_reached = 0
	if SaveManager: wave_reached = SaveManager.data["stats"].get("wave_reached", 0)
	var locked_by_wave = wave_req > 0 and wave_reached < wave_req

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
	stars.text = "★".repeat(current_level) + "☆".repeat(10 - current_level)
	stars.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	vbox.add_child(stars)

	var btn = Button.new()
	if maxed:
		btn.text = "✅ MAX"
		btn.disabled = true
	elif locked_by_wave:
		btn.text     = "🔒 Vague %d requise" % wave_req
		btn.disabled = true
	else:
		btn.text     = "🍪 %d" % cost
		btn.disabled = kibble < cost
	btn.pressed.connect(_on_buy.bind(upg["key"], cost))
	vbox.add_child(btn)

	return card

func _on_buy(key: String, cost: int):
	if not SaveManager or not SaveManager.data: return
	if SaveManager.data.get("cosmic_kibble", 0) < cost: return
	var level = SaveManager.data["perm_upgrades"].get(key, 0)
	if level >= 10: return
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
