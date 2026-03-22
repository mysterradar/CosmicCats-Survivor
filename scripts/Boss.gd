extends CharacterBody2D

signal died

@export var max_health: float = 2000.0
var current_health: float
var player = null
var is_dead = false
var phase := 1

enum State {FOLLOW, ATTACK_RAIN, CHARGE}
var current_state = State.FOLLOW
var state_timer := 0.0

var teleport_scene = preload("res://scenes/TeleportEffect.tscn")
var boss_sprite: Sprite2D = null

func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemies")

	_apply_level_scaling()
	current_health = max_health

	_setup_visual()

	var effect = teleport_scene.instantiate()
	get_tree().current_scene.add_child(effect)
	effect.global_position = global_position

	scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 1.5).set_trans(Tween.TRANS_BOUNCE)

func _setup_visual():
	boss_sprite = Sprite2D.new()
	boss_sprite.texture = load("res://assets/sprites/enemy_dreadnought.png")
	boss_sprite.scale = Vector2(0.32, 0.32)
	$BossVisual.add_child(boss_sprite)

func _apply_level_scaling():
	var level := 1
	if GlobalManager: level = GlobalManager.current_selected_level
	max_health = max_health * (1.0 + level * 0.4)

func _physics_process(delta):
	if is_dead or not player: return

	# Transition phase 2 à 50% HP
	if phase == 1 and current_health < max_health * 0.5:
		phase = 2
		_enter_phase2()

	state_timer += delta
	var proj_interval := 0.55 if phase == 1 else 0.28

	match current_state:
		State.FOLLOW:
			var dir = (player.global_position - global_position).normalized()
			velocity = dir * (80.0 if phase == 1 else 130.0)
			if state_timer > 5.0:
				change_state(State.ATTACK_RAIN)

		State.ATTACK_RAIN:
			velocity = velocity.lerp(Vector2.ZERO, delta * 2.0)
			if fmod(state_timer, proj_interval) < delta:
				spawn_projectile()
			if state_timer > 4.0:
				change_state(State.CHARGE)

		State.CHARGE:
			if state_timer < 0.5:
				var dir = (player.global_position - global_position).normalized()
				velocity = dir * (420.0 if phase == 1 else 580.0)
			if state_timer > 2.0:
				change_state(State.FOLLOW)

	move_and_slide()

func _enter_phase2():
	if boss_sprite:
		var tween = create_tween()
		tween.tween_property(boss_sprite, "modulate", Color(1.6, 0.4, 0.4), 0.6)

func change_state(new_state):
	current_state = new_state
	state_timer = 0.0

func spawn_projectile():
	if not player: return

	var proj = Area2D.new()
	proj.collision_layer = 0
	proj.collision_mask = 1

	# Glow extérieur
	var glow = Polygon2D.new()
	var glow_col = Color(1.0, 0.5, 0.1, 0.35) if phase == 1 else Color(1.0, 0.1, 0.2, 0.4)
	glow.color = glow_col
	glow.polygon = _circle_pts(20, 10)
	proj.add_child(glow)

	# Corps principal
	var body = Polygon2D.new()
	body.color = Color(1.0, 0.55, 0.1, 0.95) if phase == 1 else Color(1.0, 0.15, 0.15, 0.95)
	body.polygon = _circle_pts(11, 10)
	proj.add_child(body)

	# Noyau blanc
	var core = Polygon2D.new()
	core.color = Color(1, 1, 1, 0.9)
	core.polygon = _circle_pts(5, 8)
	proj.add_child(core)

	# Collision
	var cshape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 11.0
	cshape.shape = circle
	proj.add_child(cshape)

	var dmg := 15.0 if phase == 1 else 28.0
	var spread := 0.25 if phase == 1 else 0.55
	var dir = (player.global_position - global_position).normalized()
	dir = dir.rotated(randf_range(-spread, spread))
	var travel := dir * 600.0

	proj.body_entered.connect(func(body_hit):
		if body_hit.is_in_group("player") and body_hit.has_method("take_damage"):
			body_hit.take_damage(dmg)
		if is_instance_valid(proj): proj.queue_free()
	)

	get_parent().add_child(proj)
	proj.global_position = global_position

	var tween = create_tween()
	tween.tween_property(proj, "global_position", proj.global_position + travel, 2.5)
	tween.finished.connect(func(): if is_instance_valid(proj): proj.queue_free())

func _circle_pts(r: float, n: int) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in n:
		var a = TAU * i / n
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	return pts

func take_damage(amount: float):
	current_health -= amount
	modulate = Color(10, 10, 10)
	await get_tree().create_timer(0.05).timeout
	modulate = Color(1.6, 0.4, 0.4) if phase == 2 else Color(1, 1, 1)
	if current_health <= 0:
		die()

func die():
	if is_dead: return
	is_dead = true
	if AchievementManager:
		AchievementManager.track_stat("boss_kills", 1)
	emit_signal("died")
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await tween.finished
	queue_free()
