extends Node2D

signal enemy_killed(pos: Vector2)

enum Phase {WAVE, BOSS_FIGHT, WAVE_COMPLETE, COMPLETE, DEFEAT}

@export var enemy_spawn_rate: float = 1.0

@onready var player           = $Player
@onready var spawn_timer      = $SpawnTimer
@onready var enemies_node     = $Enemies
@onready var score_label      = $CanvasLayer/ScoreLabel
@onready var kibble_label     = $CanvasLayer/KibbleLabel
@onready var combo_label      = $CanvasLayer/ComboLabel
@onready var virtual_joystick = $CanvasLayer/VirtualJoystick
@onready var xp_bar           = $CanvasLayer/XPBar
@onready var level_label      = $CanvasLayer/LevelLabel
@onready var upgrade_ui       = $CanvasLayer/UpgradeUI
@onready var boss_health_bar  = $CanvasLayer/BossHealthBar
@onready var game_over_ui     = $CanvasLayer/GameOverUI
@onready var boss_warning     = $CanvasLayer/BossWarning
@onready var wave_label       = $CanvasLayer/WaveLabel
@onready var planet_sprite    = $BackgroundLayer/PlanetSprite
@onready var space_bg         = $BackgroundLayer/SpaceBackground

var enemy_scene               = preload("res://scenes/Enemy.tscn")
var boss_planet_scene         = preload("res://scenes/Boss.tscn")
var boss_mouse_artillery_scene: PackedScene = null
var boss_mouse_mech_scene: PackedScene = null
var explosion_scene           = preload("res://scenes/ExplosionEffect.tscn")

var screen_size: Vector2
var score           = 0
var time_elapsed    = 0.0
var active_boss     = null
var difficulty_mult = 1.0

var current_phase: Phase = Phase.WAVE
var wave_count: int = 1
const MAX_WAVES = 20
var wave_duration: float = 40.0
var wave_kill_count: int = 0
var wave_kill_target: int = 20

var combo_count = 0
var combo_timer = 0.0
const COMBO_TIMEOUT = 2.0

# Passive kill_explosion — référence au joueur actif
var _kill_explosion_active := false

func _ready():
	screen_size = get_viewport_rect().size
	if player and virtual_joystick:
		player.joystick = virtual_joystick
		player.leveled_up.connect(_on_player_leveled_up)
		player.died.connect(_on_player_died)
	setup_world_visuals()
	if GlobalManager:    difficulty_mult = GlobalManager.get_difficulty_multiplier()
	if upgrade_ui:       upgrade_ui.skill_selected.connect(_on_skill_selected)
	spawn_timer.wait_time = enemy_spawn_rate
	spawn_timer.start()
	update_score(0)
	_update_wave_hud()
	# Chargement conditionnel des boss non encore créés dans l'éditeur
	if ResourceLoader.exists("res://scenes/BossMouseArtillery.tscn"):
		boss_mouse_artillery_scene = load("res://scenes/BossMouseArtillery.tscn")
	if ResourceLoader.exists("res://scenes/BossMouseMech.tscn"):
		boss_mouse_mech_scene = load("res://scenes/BossMouseMech.tscn")
	# Passive kill_explosion
	if CatManager and CatManager.get_active_cat_data().get("passive_id") == "kill_explosion":
		_kill_explosion_active = true

func setup_world_visuals():
	var level := 1
	if GlobalManager: level = GlobalManager.current_selected_level
	wave_duration = max(20.0, 40.0 - wave_count * 1.0)
	wave_kill_target = 15 + wave_count * 3
	# Planète de fond : change selon la vague (1-9 en cycle)
	if planet_sprite:
		var planet_idx = ((wave_count - 1) % 9) + 1
		planet_sprite.texture = load("res://assets/sprites/planet_stage%d.png" % planet_idx)
		planet_sprite.visible = true
	var hue = fmod(wave_count * 0.13, 1.0)
	if space_bg: space_bg.color = Color.from_hsv(hue, 0.4, 0.03)
	var star_field_script = load("res://scripts/StarField.gd")
	var star_field = Node2D.new(); star_field.set_script(star_field_script)
	$BackgroundLayer.add_child(star_field); star_field.setup(screen_size, space_bg.color if space_bg else Color(0.01, 0.01, 0.03))

func _process(delta):
	time_elapsed += delta
	if SaveManager and SaveManager.data.has("stats"):
		SaveManager.data["stats"]["play_time"] += delta
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0: reset_combo()
	_update_hud()
	match current_phase:
		Phase.WAVE:       _process_wave(delta)
		Phase.BOSS_FIGHT: _process_boss_fight(delta)
		_: pass

func _process_wave(delta):
	if fmod(time_elapsed, 20.0) < delta:
		difficulty_mult  += 0.2
		enemy_spawn_rate  = max(0.15, enemy_spawn_rate * 0.88)
		spawn_timer.wait_time = enemy_spawn_rate
	if time_elapsed >= wave_duration * 0.85:
		if boss_warning and not boss_warning.visible and _wave_has_boss(wave_count):
			boss_warning.text = "⚠ BOSS EN APPROCHE!"
			boss_warning.visible = true
			var tw = create_tween().set_loops(6)
			tw.tween_property(boss_warning, "modulate:a", 0.3, 0.4)
			tw.tween_property(boss_warning, "modulate:a", 1.0, 0.4)
	_update_wave_hud()
	if wave_kill_count >= wave_kill_target or time_elapsed >= wave_duration:
		_end_wave()

func _end_wave():
	if current_phase != Phase.WAVE: return
	current_phase = Phase.WAVE_COMPLETE
	spawn_timer.stop()
	if _wave_has_boss(wave_count):
		_start_boss_phase()
	else:
		_show_wave_complete_then_advance()

func _show_wave_complete_then_advance():
	if boss_warning:
		boss_warning.text = "✓ VAGUE %d TERMINÉE" % wave_count
		boss_warning.modulate = Color(0.4, 1.0, 0.5, 1)
		boss_warning.visible = true
	await get_tree().create_timer(2.0).timeout
	if boss_warning: boss_warning.visible = false
	if current_phase != Phase.DEFEAT: _advance_wave()

func _wave_has_boss(wave: int) -> bool:
	return wave in [5, 10, 15, 20]

func _get_boss_scene_for_wave(wave: int) -> PackedScene:
	match wave:
		5:  return boss_mouse_artillery_scene
		10: return boss_planet_scene
		15: return boss_mouse_mech_scene
		20: return boss_planet_scene   # Planète Légendaire — même scène, phase 3 dans Boss.gd
		_:  return null

func _start_boss_phase():
	current_phase = Phase.BOSS_FIGHT
	if boss_warning:
		boss_warning.text = "⚠ BOSS VAGUE %d!" % wave_count
		boss_warning.visible = true
		boss_warning.modulate = Color(1, 1, 1, 1)
	await get_tree().create_timer(1.5).timeout
	if boss_warning: boss_warning.visible = false
	if current_phase != Phase.DEFEAT: _spawn_boss()

func _spawn_boss():
	var scene = _get_boss_scene_for_wave(wave_count)
	if not scene: _advance_wave(); return
	var boss = scene.instantiate()
	# Marquer vague 20 pour phase 3 légendaire
	if wave_count == 20 and boss.has_method("set_legendary_mode"):
		boss.set_legendary_mode()
	boss.global_position = player.global_position + Vector2(0, -screen_size.y * 0.38)
	add_child(boss)
	active_boss = boss
	boss.died.connect(_on_boss_died)

func _process_boss_fight(_delta):
	if active_boss and is_instance_valid(active_boss):
		if boss_health_bar:
			boss_health_bar.visible   = true
			boss_health_bar.max_value = active_boss.max_health
			boss_health_bar.value     = active_boss.current_health
	else:
		if boss_health_bar: boss_health_bar.visible = false

func _on_boss_died():
	update_score(10000)
	if MissionManager: MissionManager.track_stat("boss_kill")
	if boss_health_bar: boss_health_bar.visible = false
	if CatManager:
		CatManager.add_xp(50)
		CatManager.add_cosmic_fur(randi_range(5, 15))
	# Sauvegarder wave_reached
	if SaveManager:
		SaveManager.data["stats"]["wave_reached"] = max(
			SaveManager.data["stats"].get("wave_reached", 0), wave_count)
	if wave_count >= MAX_WAVES:
		current_phase = Phase.COMPLETE
		_finalize_stats(true)
		await get_tree().create_timer(2.0).timeout
		if game_over_ui: game_over_ui.open(true, score, player.run_kibble)
	else:
		current_phase = Phase.WAVE_COMPLETE
		await get_tree().create_timer(1.5).timeout
		if current_phase != Phase.DEFEAT: _advance_wave()

func _advance_wave():
	wave_count += 1
	if MissionManager: MissionManager.track_stat("reach_wave", wave_count, "max")
	if CatManager: CatManager.add_xp(20)
	difficulty_mult   = 1.0 + (wave_count - 1) * 0.15
	enemy_spawn_rate  = max(0.15, 1.0 - wave_count * 0.04)
	wave_duration     = max(20.0, 40.0 - wave_count * 1.0)
	wave_kill_count   = 0
	wave_kill_target  = 15 + wave_count * 3
	time_elapsed      = 0.0
	spawn_timer.wait_time = enemy_spawn_rate
	spawn_timer.start()
	current_phase = Phase.WAVE
	_update_wave_hud()

func _update_wave_hud():
	if wave_label:
		if current_phase == Phase.WAVE:
			wave_label.text = "Vague %d/%d  —  %d/%d ennemis" % [wave_count, MAX_WAVES, wave_kill_count, wave_kill_target]
		else:
			wave_label.text = "Vague %d/%d" % [wave_count, MAX_WAVES]

func _on_spawn_timer_timeout():
	if current_phase == Phase.WAVE: spawn_enemy()

func spawn_enemy():
	if not enemy_scene: return
	var enemy = enemy_scene.instantiate()
	var rand_type = randf()
	var current_lv = 1
	if GlobalManager: current_lv = GlobalManager.current_selected_level
	if rand_type < (0.1 + current_lv * 0.05):    enemy.enemy_type = 1
	elif rand_type > (0.9 - current_lv * 0.05):  enemy.enemy_type = 2
	else:                                          enemy.enemy_type = 0
	var spawn_pos = Vector2.ZERO; var offset = 80
	match randi() % 4:
		0: spawn_pos = Vector2(randf_range(0, screen_size.x), -offset)
		1: spawn_pos = Vector2(randf_range(0, screen_size.x), screen_size.y + offset)
		2: spawn_pos = Vector2(-offset, randf_range(0, screen_size.y))
		3: spawn_pos = Vector2(screen_size.x + offset, randf_range(0, screen_size.y))
	if player: spawn_pos += player.global_position - screen_size / 2
	enemy.global_position  = spawn_pos
	enemy.max_health      *= difficulty_mult
	enemy.speed           *= (1.0 + (difficulty_mult - 1.0) * 0.4)
	if randf() < 0.05: enemy.is_elite = true
	enemies_node.add_child(enemy)
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died.bind(enemy))

func _on_enemy_died(enemy: Node):
	var pos = enemy.global_position if is_instance_valid(enemy) else Vector2.ZERO
	enemy_killed.emit(pos)
	wave_kill_count += 1
	# Passive kill_explosion
	if _kill_explosion_active:
		var expl = explosion_scene.instantiate()
		add_child(expl); expl.global_position = pos
	update_score(10)
	combo_count += 1; combo_timer = COMBO_TIMEOUT
	update_combo_ui()
	if player and combo_count > 5: player.collect_kibble(int(combo_count / 5))
	if SaveManager and SaveManager.data.has("stats"):
		SaveManager.data["stats"]["kills"] += 1
	if CatManager: CatManager.add_xp(5)
	# Drop Poils Cosmiques (élites)
	if is_instance_valid(enemy) and enemy.get("is_elite") and randf() < 0.05:
		if CatManager: CatManager.add_cosmic_fur(randi_range(1, 3))

func _on_player_died():
	current_phase = Phase.DEFEAT
	_finalize_stats(false)
	if CatManager: CatManager.reset_session()
	if game_over_ui: game_over_ui.open(false, score, player.run_kibble)

func _on_player_leveled_up(_new_level):
	if upgrade_ui: upgrade_ui.open()

func _on_skill_selected(skill_id):
	if player: player.apply_skill(skill_id)

func _finalize_stats(_victory: bool):
	if not SaveManager or not SaveManager.data.has("stats"): return
	var s = SaveManager.data["stats"]
	s["games_played"] += 1
	s["best_score"]    = max(s.get("best_score", 0), score)
	SaveManager.save_game()

func _update_hud():
	if player:
		xp_bar.max_value = player.xp_to_next_level
		xp_bar.value     = player.current_xp
		level_label.text = "LV: %d" % player.level
		if kibble_label: kibble_label.text = "Croquettes: %d" % player.run_kibble

func update_combo_ui():
	if combo_count > 1:
		combo_label.visible = true
		combo_label.text    = "COMBO x%d" % combo_count
	else:
		combo_label.visible = false

func reset_combo():
	combo_count = 0; combo_label.visible = false

func update_score(amount):
	score += amount
	if score_label: score_label.text = "Score: %d" % score
