extends CharacterBody2D

signal leveled_up(new_level: int)
signal died

@export var speed: float = 450.0
@export var max_health: float = 100.0
var current_health: float

var level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 50

@onready var weapon_timer = $WeaponTimer
@onready var health_bar = $HealthBar
@onready var ship_visual = $ShipVisual

# Scènes d'armes
var bullet_scene = preload("res://scenes/Bullet.tscn")
var missile_scene = preload("res://scenes/SardineMissile.tscn")
var orbiting_scene = preload("res://scenes/OrbitingSardine.tscn")
var blade_scene = preload("res://scenes/PlasmaBlade.tscn")

var joystick = null
var is_dead = false
var run_kibble = 0
var has_vacuum = false
var damage_mult = 1.0
var shield_cooldown: float = 10.0
var shield_timer: float = 0.0
var shield_active: bool = false

# Stats de déblocage
var missile_unlocked = false
var missiles_per_shot = 1
var missile_timer = 0.0
const MISSILE_INTERVAL = 1.5

func _ready():
	# Appliquer les upgrades permanentes depuis SaveManager
	if SaveManager and SaveManager.data.has("perm_upgrades"):
		var pu = SaveManager.data["perm_upgrades"]
		damage_mult      += pu.get("damage_bonus",    0) * 0.20
		max_health       += pu.get("health_bonus",    0) * 30.0
		speed            += pu.get("speed_bonus",     0) * 50.0
		shield_cooldown   = max(1.0, 10.0 - pu.get("shield_bonus", 0) * 1.0)
		var fr = pu.get("fire_rate_bonus", 0)
		weapon_timer.wait_time = max(0.08, weapon_timer.wait_time * pow(0.85, fr))
		# Dupliquer la shape avant modification (Resource partagée en Godot 4)
		$Magnet/CollisionShape2D.shape = $Magnet/CollisionShape2D.shape.duplicate()
		$Magnet/CollisionShape2D.shape.radius += pu.get("xp_radius_bonus", 0) * 40.0

	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	weapon_timer.start()
	setup_ship_visual(level)

func setup_ship_visual(lv: int):
	pass  # TODO Task 7

func _physics_process(delta):
	if is_dead: return

	# Recharge du bouclier (float timer — pas de nœud Timer)
	if not shield_active:
		shield_timer += delta
		if shield_timer >= shield_cooldown:
			shield_active = true
			shield_timer = 0.0
			if ship_visual: ship_visual.modulate = Color(0.5, 0.8, 2.0)  # feedback bleu

	# Gestion des missiles (uniquement si débloqués)
	if missile_unlocked:
		missile_timer += delta
		if missile_timer >= MISSILE_INTERVAL:
			var enemies = get_tree().get_nodes_in_group("enemies")
			if enemies.size() > 0:
				shoot_missile(enemies)
				missile_timer = 0.0
	
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if joystick and is_instance_valid(joystick):
		if joystick.output != Vector2.ZERO:
			direction = joystick.output
	
	velocity = direction * speed
	move_and_slide()
	
	# Animation visuelle
	ship_visual.rotation = lerp_angle(ship_visual.rotation, direction.x * 0.4, 0.1)
	if direction != Vector2.ZERO:
		$ShipVisual/Thruster.emitting = true
	else:
		$ShipVisual/Thruster.emitting = false

func shoot():
	if is_dead: return
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() > 0:
		var nearest = get_nearest_enemy(enemies)
		if nearest:
			var bullet = bullet_scene.instantiate()
			get_tree().current_scene.add_child(bullet)
			bullet.global_position = global_position
			bullet.target = nearest

func get_nearest_enemy(enemies):
	var nearest = null
	var min_dist = INF
	for e in enemies:
		if is_instance_valid(e):
			var d = global_position.distance_to(e.global_position)
			if d < min_dist:
				min_dist = d
				nearest = e
	return nearest

func shoot_missile(enemies):
	for i in range(missiles_per_shot):
		var target = enemies.pick_random()
		if is_instance_valid(target):
			var missile = missile_scene.instantiate()
			get_tree().current_scene.add_child(missile)
			missile.global_position = global_position
			missile.target = target
		await get_tree().create_timer(0.1).timeout

func apply_skill(skill_id):
	match skill_id:
		"damage": damage_mult += 0.3
		"speed": speed += 50.0
		"fire_rate": weapon_timer.wait_time = max(0.1, weapon_timer.wait_time * 0.7)
		"magnet": $Magnet/CollisionShape2D.shape.radius += 150.0
		"missiles": 
			if not missile_unlocked: missile_unlocked = true
			else: missiles_per_shot += 1
		"orbit": spawn_orbiting_sardine()
		"shield": pass # À implémenter visuellement
		"blade": spawn_plasma_blade()
		"vacuum": has_vacuum = true

func spawn_plasma_blade():
	var b = blade_scene.instantiate()
	add_child(b)
	b.position = Vector2.ZERO

func spawn_orbiting_sardine():
	var s = orbiting_scene.instantiate()
	add_child(s)

func _on_weapon_timer_timeout():
	shoot()

func take_damage(amount: float):
	if is_dead: return
	# Bouclier absorbe le coup — check AVANT le await pour éviter race condition
	if shield_active:
		shield_active = false
		ship_visual.modulate = Color(1, 1, 1)
		return
	current_health -= amount
	if health_bar: health_bar.value = current_health
	ship_visual.modulate = Color(5, 5, 5)
	await get_tree().create_timer(0.05).timeout
	# Ne pas écraser la couleur bleue du bouclier si rechargé pendant le flash
	if not shield_active:
		ship_visual.modulate = Color(1, 1, 1)
	if current_health <= 0:
		is_dead = true
		get_tree().reload_current_scene()

func collect_kibble(amount: int):
	run_kibble += amount

func add_xp(amount: int):
	current_xp += amount
	if current_xp >= xp_to_next_level:
		level += 1
		current_xp = 0
		xp_to_next_level += 20
		emit_signal("leveled_up", level)
