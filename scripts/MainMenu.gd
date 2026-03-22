extends Control

@onready var kibble_label = $TopBar/CheeseLabel
@onready var enemy_display = $Carousel/EnemyDisplay
@onready var level_name_lbl = $Carousel/LevelInfo/LevelName
@onready var status_lbl = $Carousel/LevelInfo/StatusLabel
@onready var reward_lbl = $Carousel/LevelInfo/RewardLabel
@onready var play_btn = $PlayButton

@onready var shop_ui = $UILYR/ShopUI
@onready var settings_ui = $UILYR/SettingsUI
@onready var mission_ui = $UILYR/MissionUI
@onready var stats_ui = $UILYR/StatsUI
@onready var achievements_panel = $UILYR/AchievementsPanel

var current_view_level = 1
const MAX_LEVELS = 10

func _ready():
	update_ui()
	update_level_view()
	
	if shop_ui:
		if !shop_ui.shop_closed.is_connected(update_ui):
			shop_ui.shop_closed.connect(update_ui)

func update_ui():
	if SaveManager and SaveManager.data:
		# Accès sécurisé
		var kibbles = SaveManager.data.get("cosmic_kibble", 0)
		kibble_label.text = "Croquettes : %d" % kibbles

func update_level_view():
	level_name_lbl.text = "VAGUE %d" % current_view_level
	if GlobalManager:
		reward_lbl.text = "Récompense : %d 💎" % GlobalManager.get_level_reward()
	update_enemy_visual()
	
	if SaveManager and SaveManager.data:
		var unlocked = SaveManager.data.get("unlocked_level", 1)
		if current_view_level < unlocked:
			status_lbl.text = "TERMINÉ"
			status_lbl.modulate = Color(0.5, 0.5, 1)
			play_btn.disabled = false
			play_btn.text = "REJOUER"
		elif current_view_level == unlocked:
			status_lbl.text = "ACTUEL"
			status_lbl.modulate = Color(0, 1, 0.5)
			play_btn.disabled = false
			play_btn.text = "ATTAQUER"
		else:
			status_lbl.text = "VERROUILLÉ"
			status_lbl.modulate = Color(1, 0.2, 0.2)
			play_btn.disabled = true
			play_btn.text = "BLOQUÉ"

func update_enemy_visual():
	var t = current_view_level
	if t % 3 == 1:
		enemy_display.color = Color(1, 0.2, 0.2)
		enemy_display.polygon = PackedVector2Array([-10,-10, 10,-10, 10,10, -10,10])
	elif t % 3 == 2:
		enemy_display.color = Color(0, 0.8, 1)
		enemy_display.polygon = PackedVector2Array([0,-12, 10,8, -10,8])
	else:
		enemy_display.color = Color(1, 0.4, 0)
		enemy_display.polygon = PackedVector2Array([0,-10, 7,-7, 10,0, 7,7, 0,10, -7,7, -10,0, -7,-7])
	
	var tween = create_tween().set_loops()
	tween.tween_property(enemy_display, "position:y", -60.0, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(enemy_display, "position:y", -40.0, 1.0).set_trans(Tween.TRANS_SINE)

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
