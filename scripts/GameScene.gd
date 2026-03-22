extends Node2D

@export var enemy_spawn_rate: float = 1.0
@onready var player = $Player
@onready var spawn_timer = $SpawnTimer
@onready var enemies_container = $Enemies
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var kibble_label = $CanvasLayer/KibbleLabel
@onready var combo_label = $CanvasLayer/ComboLabel
@onready var virtual_joystick = $CanvasLayer/VirtualJoystick
@onready var xp_bar = $CanvasLayer/XPBar
@onready var level_label = $CanvasLayer/LevelLabel
@onready var upgrade_ui = $CanvasLayer/UpgradeUI
@onready var boss_health_bar = $CanvasLayer/BossHealthBar
@onready var game_over_ui = $CanvasLayer/GameOverUI
@onready var planet_sprite = get_node_or_null("BackgroundLayer/PlanetSprite")
@onready var space_bg = $BackgroundLayer/SpaceBackground

var enemy_scene = preload("res://scenes/Enemy.tscn")
var boss_scene = preload("res://scenes/Boss.tscn")
var screen_size
var score = 0
var time_elapsed = 0.0
var boss_spawned = false
var active_boss = null
var difficulty_mult = 1.0

# Combo System
var combo_count = 0
var combo_timer = 0.0
const COMBO_TIMEOUT = 2.0

func _ready():
	screen_size = get_viewport_rect().size
	if player and virtual_joystick:
		player.joystick = virtual_joystick
		player.leveled_up.connect(_on_player_leveled_up)
		if player.has_signal("died"):
			player.died.connect(_on_player_died)
	
	setup_world_visuals()
	
	if GlobalManager:
		difficulty_mult = GlobalManager.get_difficulty_multiplier()
	if upgrade_ui:
		upgrade_ui.skill_selected.connect(_on_skill_selected)
	spawn_timer.wait_time = enemy_spawn_rate
	spawn_timer.start()
	update_score(0)

func setup_world_visuals():
	var level = 1
	if GlobalManager: level = GlobalManager.current_selected_level

	# Sécurité pour le chargement des planètes
	var planet_idx = ((level - 1) % 8) + 1
	var path = "res://assets/sprites/planet_stage%d.png" % planet_idx
	if planet_sprite and ResourceLoader.exists(path):
		planet_sprite.texture = load(path)
		planet_sprite.scale = Vector2(0.4, 0.4) # Plus petit
		planet_sprite.position = Vector2(150, 150) # En haut à gauche

	# Couleur du fond unique par niveau
	var hue = fmod(level * 0.13, 1.0)
	space_bg.color = Color.from_hsv(hue, 0.4, 0.03)

	# Instancier StarField
	var star_field_script = load("res://scripts/StarField.gd")
	var star_field = Node2D.new()
	star_field.set_script(star_field_script)
	$BackgroundLayer.add_child(star_field)
	star_field.setup(screen_size, space_bg.color)

func _process(delta):
	time_elapsed += delta
	# Stats cumulatives
	if SaveManager and SaveManager.data.has("stats"):
		SaveManager.data["stats"]["play_time"] += delta
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0: reset_combo()
	
	if fmod(time_elapsed, 30.0) < delta:
		difficulty_mult += 0.4
		enemy_spawn_rate = max(0.1, enemy_spawn_rate * 0.8)
		spawn_timer.wait_time = enemy_spawn_rate
	
	if time_elapsed > 120.0 and not boss_spawned:
		spawn_boss()
	
	if active_boss and is_instance_valid(active_boss):
		boss_health_bar.visible = true
		boss_health_bar.max_value = active_boss.max_health
		boss_health_bar.value = active_boss.current_health
	elif boss_spawned:
		boss_health_bar.visible = false
	
	if player:
		xp_bar.max_value = player.xp_to_next_level
		xp_bar.value = player.current_xp
		level_label.text = "LV: %d" % player.level
		if kibble_label:
			kibble_label.text = "Croquettes: %d" % player.run_kibble

func _on_player_leveled_up(_new_level):
	if upgrade_ui: upgrade_ui.open()

func _on_skill_selected(skill_id):
	if player: player.apply_skill(skill_id)

func spawn_boss():
	boss_spawned = true
	spawn_timer.stop()
	var boss = boss_scene.instantiate()
	boss.global_position = player.global_position + Vector2(0, -500)
	add_child(boss)
	active_boss = boss
	boss.died.connect(_on_boss_died)

func _on_boss_died():
	update_score(10000)
	_finalize_stats(true)
	if game_over_ui:
		game_over_ui.open(true, score, player.run_kibble)

func _on_player_died():
	_finalize_stats(false)
	if game_over_ui:
		game_over_ui.open(false, score, player.run_kibble)

func _finalize_stats(_victory: bool):
	if not SaveManager or not SaveManager.data.has("stats"): return
	var s = SaveManager.data["stats"]
	s["games_played"] += 1
	s["best_score"] = max(s.get("best_score", 0), score)
	SaveManager.save_game()

func _on_spawn_timer_timeout():
	spawn_enemy()

func spawn_enemy():
	if not enemy_scene: return
	var enemy = enemy_scene.instantiate()
	var rand_type = randf()
	var current_lv = 1
	if GlobalManager: current_lv = GlobalManager.current_selected_level
	
	if rand_type < (0.1 + current_lv * 0.05): enemy.enemy_type = 1 
	elif rand_type > (0.9 - current_lv * 0.05): enemy.enemy_type = 2
	else: enemy.enemy_type = 0
	
	var spawn_pos = Vector2.ZERO
	var side = randi() % 4
	var offset = 80
	match side:
		0: spawn_pos = Vector2(randf_range(0, screen_size.x), -offset)
		1: spawn_pos = Vector2(randf_range(0, screen_size.x), screen_size.y + offset)
		2: spawn_pos = Vector2(-offset, randf_range(0, screen_size.y))
		3: spawn_pos = Vector2(screen_size.x + offset, randf_range(0, screen_size.y))
	
	if player:
		spawn_pos += player.global_position - screen_size / 2
	enemy.global_position = spawn_pos
	enemy.max_health *= difficulty_mult
	enemy.speed *= (1.0 + (difficulty_mult - 1.0) * 0.4)
	
	if randf() < 0.05:
		enemy.is_elite = true
		
	enemies_container.add_child(enemy)
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)

func _on_enemy_died():
	update_score(10)
	combo_count += 1
	combo_timer = COMBO_TIMEOUT
	update_combo_ui()
	if player and combo_count > 5:
		player.collect_kibble(int(combo_count / 5))
	# Stats
	if SaveManager and SaveManager.data.has("stats"):
		SaveManager.data["stats"]["kills"] += 1

func update_combo_ui():
	if combo_count > 1:
		combo_label.visible = true
		combo_label.text = "COMBO x%d" % combo_count
	else:
		combo_label.visible = false

func reset_combo():
	combo_count = 0
	combo_label.visible = false

func update_score(amount):
	score += amount
	if score_label:
		score_label.text = "Score: %d" % score
