extends Control

signal closed

@onready var carousel    = $Panel/ScrollContainer/HBox
@onready var fur_label   = $Panel/TopBar/FurLabel
@onready var close_btn   = $Panel/TopBar/CloseButton

func _ready():
	visible = false

func open():
	visible = true
	_build_carousel()

func _build_carousel():
	for child in carousel.get_children(): child.queue_free()
	if not CatManager or not SaveManager: return
	fur_label.text = "🪶 %d Poils Cosmiques" % SaveManager.data.get("cosmic_fur", 0)
	for cat_id in CatManager.CATS:
		carousel.add_child(_make_card(cat_id))

func _make_card(cat_id: String) -> Control:
	var cat_def  = CatManager.CATS[cat_id]
	var save     = CatManager.get_cat_save(cat_id)
	var unlocked = save.get("unlocked", false)
	var level    = save.get("level", 1)
	var stage    = save.get("stage", 1)
	var is_active = CatManager.get_active_cat_id() == cat_id

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 280)
	if is_active:
		card.add_theme_stylebox_override("panel", _highlighted_style())

	var vbox = VBoxContainer.new()
	card.add_child(vbox)

	# Sprite
	var sprite = TextureRect.new()
	sprite.custom_minimum_size = Vector2(100, 100)
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var stage_sprites = cat_def.get("sprite_stage", [])
	if stage_sprites.size() >= stage:
		sprite.texture = load(stage_sprites[stage - 1])
	vbox.add_child(sprite)

	# Nom + rareté
	var name_lbl = Label.new()
	name_lbl.text = cat_def["name"]
	name_lbl.add_theme_color_override("font_color", _rarity_color(cat_def["rarity"]))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var rarity_lbl = Label.new()
	rarity_lbl.text = cat_def["rarity"]
	rarity_lbl.add_theme_font_size_override("font_size", 10)
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rarity_lbl)

	# Niveau
	var level_lbl = Label.new()
	level_lbl.text = "Niv. %d — Stade %d" % [level, stage]
	level_lbl.add_theme_font_size_override("font_size", 10)
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_lbl)

	# Passive
	var passive_lbl = Label.new()
	passive_lbl.text = cat_def["description"]
	passive_lbl.add_theme_font_size_override("font_size", 9)
	passive_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	passive_lbl.custom_minimum_size = Vector2(160, 0)
	vbox.add_child(passive_lbl)

	if not unlocked:
		# Overlay verrouillé
		var cost_lbl = Label.new()
		cost_lbl.text = "🔒 %d 🍪" % cat_def["unlock_cost"]
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(cost_lbl)
		var unlock_btn = Button.new()
		unlock_btn.text = "Déverrouiller"
		var kibble = SaveManager.data.get("cosmic_kibble", 0)
		unlock_btn.disabled = kibble < cat_def["unlock_cost"]
		unlock_btn.pressed.connect(func():
			CatManager.unlock_cat(cat_id)
			_build_carousel()
		)
		vbox.add_child(unlock_btn)
	else:
		# Bouton évoluer
		if CatManager.can_evolve(cat_id):
			var fur_cost = CatManager.STAGE2_FUR if stage == 1 else CatManager.STAGE3_FUR
			var evo_btn = Button.new()
			evo_btn.text = "🪶 Évoluer (%d)" % fur_cost
			evo_btn.pressed.connect(func():
				CatManager.evolve_cat(cat_id)
				_build_carousel()
			)
			vbox.add_child(evo_btn)

		# Bouton sélectionner
		if not is_active:
			var sel_btn = Button.new()
			sel_btn.text = "✅ Sélectionner"
			sel_btn.pressed.connect(func():
				CatManager.set_active_cat(cat_id)
				_build_carousel()
			)
			vbox.add_child(sel_btn)
		else:
			var active_lbl = Label.new()
			active_lbl.text = "▶ Actif"
			active_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
			active_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(active_lbl)

	return card

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"COMMON":    return Color(0.8, 0.8, 0.8)
		"RARE":      return Color(0.3, 0.6, 1.0)
		"LEGENDARY": return Color(1.0, 0.7, 0.1)
	return Color(1, 1, 1)

func _highlighted_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.2, 0.3, 0.15, 0.8)
	s.border_color = Color(0.5, 1.0, 0.3)
	s.set_border_width_all(2)
	return s

func _on_close_button_pressed():
	visible = false
	emit_signal("closed")
