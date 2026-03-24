extends Control

@onready var kibble_label    = $TopBar/CheeseLabel
@onready var enemy_display   = $Carousel/EnemyDisplay
@onready var level_name_lbl  = $Carousel/LevelInfo/LevelName
@onready var status_lbl      = $Carousel/LevelInfo/StatusLabel
@onready var reward_lbl      = $Carousel/LevelInfo/RewardLabel
@onready var play_btn        = $PlayButton
@onready var shop_ui         = $UILYR/ShopUI
@onready var settings_ui     = $UILYR/SettingsUI
@onready var mission_ui      = $UILYR/MissionUI
@onready var stats_ui        = $UILYR/StatsUI
@onready var achievements_panel = $UILYR/AchievementsPanel
@onready var cat_sprite    = $CockpitZone/CatSprite
@onready var cat_name_lbl  = $CockpitZone/CatNameLabel
@onready var cat_xp_bar    = $CockpitZone/CatXPBar
@onready var cat_pilot_ui  = $UILYR/CatPilotUI

var current_view_level = 1
const MAX_LEVELS = 10
var float_tween: Tween = null

var _enemy_textures: Array = []

func _ready():
	_enemy_textures = [
		load("res://assets/sprites/enemy_scout.png"),
		load("res://assets/sprites/enemy_artillery.png"),
		load("res://assets/sprites/enemy_cruiser.png"),
		load("res://assets/sprites/enemy_dreadnought.png"),
	]

	update_ui()
	update_level_view()

	if shop_ui and not shop_ui.shop_closed.is_connected(update_ui):
		shop_ui.shop_closed.connect(update_ui)
	if cat_pilot_ui: cat_pilot_ui.closed.connect(update_ui)

	# Animation d'entrée fade-in
	modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.4)

func update_ui():
	if SaveManager and SaveManager.data:
		var kibbles = SaveManager.data.get("cosmic_kibble", 0)
		kibble_label.text = "🍪 %d" % kibbles

	# Cockpit chat actif
	if CatManager and SaveManager:
		var cat_id  = CatManager.get_active_cat_id()
		var cat_def = CatManager.get_active_cat_data()
		var stage   = CatManager.get_cat_stage(cat_id)
		var level   = CatManager.get_cat_level(cat_id)
		var xp      = CatManager.get_cat_xp(cat_id)
		var needed  = CatManager.xp_needed_for_level(level)
		if cat_name_lbl: cat_name_lbl.text = "%s — Niv. %d" % [cat_def["name"], level]
		if cat_xp_bar:
			cat_xp_bar.max_value = needed
			cat_xp_bar.value     = xp
		if cat_sprite:
			var stage_sprites = cat_def.get("sprite_stage", [])
			if stage_sprites.size() >= stage:
				cat_sprite.texture = load(stage_sprites[stage - 1])
			# Idle animation (only start once)
			if not cat_sprite.has_meta("anim_started"):
				cat_sprite.set_meta("anim_started", true)
				var idle = create_tween().set_loops()
				idle.tween_property(cat_sprite, "scale", Vector2(1.03, 1.03), 0.8).set_trans(Tween.TRANS_SINE)
				idle.tween_property(cat_sprite, "scale", Vector2(0.97, 0.97), 0.8).set_trans(Tween.TRANS_SINE)

func update_level_view():
	level_name_lbl.text = "NIVEAU  %d" % current_view_level
	if GlobalManager:
		reward_lbl.text = "💎 %d croquettes" % GlobalManager.get_level_reward()
	update_enemy_visual()

	if SaveManager and SaveManager.data:
		var unlocked = SaveManager.data.get("unlocked_level", 1)
		if current_view_level < unlocked:
			status_lbl.text = "✅  TERMINÉ"
			status_lbl.modulate = Color(0.4, 1.0, 0.6)
			play_btn.disabled = false
			play_btn.text = "⚔  REJOUER"
		elif current_view_level == unlocked:
			status_lbl.text = "▶  EN COURS"
			status_lbl.modulate = Color(0.3, 0.85, 1.0)
			play_btn.disabled = false
			play_btn.text = "⚔  ATTAQUER"
		else:
			status_lbl.text = "🔒  VERROUILLÉ"
			status_lbl.modulate = Color(1.0, 0.35, 0.35)
			play_btn.disabled = true
			play_btn.text = "🔒  BLOQUÉ"

func update_enemy_visual():
	var idx := 0
	if current_view_level >= 9:   idx = 3
	elif current_view_level >= 6: idx = 2
	elif current_view_level >= 3: idx = 1

	enemy_display.texture = _enemy_textures[idx]

	# Pop-in scale
	enemy_display.scale = Vector2(0.5, 0.5)
	var pop = create_tween()
	pop.tween_property(enemy_display, "scale", Vector2(1.0, 1.0), 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Flottement infini
	if float_tween: float_tween.kill()
	var base_y = enemy_display.position.y
	float_tween = create_tween().set_loops()
	float_tween.tween_property(enemy_display, "position:y", base_y - 20.0, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(enemy_display, "position:y", base_y, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_prev_pressed():
	if current_view_level > 1:
		current_view_level -= 1
		update_level_view()

func _on_next_pressed():
	if current_view_level < MAX_LEVELS:
		current_view_level += 1
		update_level_view()

func _on_play_pressed():
	if GlobalManager:
		GlobalManager.current_selected_level = current_view_level
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")

func _on_upgrade_button_pressed():
	if shop_ui: shop_ui.open()

func _on_settings_button_pressed():
	if settings_ui: settings_ui.open()

func _on_mission_button_pressed():
	if mission_ui: mission_ui.open()

func _on_stats_button_pressed():
	if stats_ui: stats_ui.open()

func _on_achievements_button_pressed():
	if achievements_panel:
		achievements_panel.visible = true
		_refresh_achievements()

func _refresh_achievements():
	var list = achievements_panel.get_node_or_null("Panel/ScrollContainer/VBox")
	if not list: return
	for child in list.get_children(): child.queue_free()
	if not AchievementManager: return
	for a in AchievementManager.achievements:
		var lbl = Label.new()
		if a.unlocked:
			lbl.text = "✅ %s — %s" % [a.title, a.desc]
			lbl.modulate = Color(1, 1, 1)
		else:
			lbl.text = "🔒 ???"
			lbl.modulate = Color(0.4, 0.4, 0.4)
		list.add_child(lbl)

func _on_pilote_button_pressed():
	if cat_pilot_ui: cat_pilot_ui.open()
