extends CharacterBody2D

signal died

@export var max_health: float = 2500.0
var current_health: float
var player = null
var is_dead = false
var phase   := 1

var state_timer := 0.0
var is_dashing  := false
enum State { DRIFT, GATLING, DASH }
var current_state = State.DRIFT

var explosion_scene = preload("res://scenes/ExplosionEffect.tscn")
var missile_scene   = preload("res://scenes/SardineMissile.tscn")

static var _sprite_tex: Texture2D = null
static var _bullet_tex: Texture2D = null

func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemies")
	var level := 1
	if GlobalManager: level = GlobalManager.current_selected_level
	max_health *= (1.0 + level * 0.4)
	current_health = max_health
	_setup_visual()
	scale = Vector2(0.1, 0.1)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 1.2).set_trans(Tween.TRANS_BOUNCE)

func _setup_visual():
	if not _sprite_tex:
		_sprite_tex = load("res://assets/sprites/boss_mouse_mech.png")
	var sp = Sprite2D.new(); sp.texture = _sprite_tex; sp.scale = Vector2(0.60, 0.60)
	add_child(sp)

func _physics_process(delta):
	if is_dead or not player: return
	if phase == 1 and current_health < max_health * 0.5:
		phase = 2; _enter_phase2()
	state_timer += delta
	match current_state:
		State.DRIFT:
			var dist = global_position.distance_to(player.global_position)
			var dir  = (player.global_position - global_position).normalized()
			velocity = dir * 70.0 if dist > 300 else velocity.lerp(Vector2.ZERO, delta * 3.0)
			if state_timer > 2.5: _change_state(State.GATLING)
		State.GATLING:
			velocity = velocity.lerp(Vector2.ZERO, delta * 3.0)
			var interval = 0.5 if phase == 1 else 0.3
			if fmod(state_timer, interval) < delta: _fire_gatling()
			var dur = 4.0 if phase == 1 else 3.0
			if state_timer > dur: _change_state(State.DASH if phase == 2 else State.DRIFT)
		State.DASH:
			if state_timer < 0.4:
				velocity = (player.global_position - global_position).normalized() * 500.0
			else:
				velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
				if phase == 2 and fmod(state_timer, 0.6) < delta: _fire_missile()
			if state_timer > 2.5: _change_state(State.GATLING)
	move_and_slide()

func _change_state(s): current_state = s; state_timer = 0.0

func _enter_phase2():
	if _sprite_tex: modulate = Color(1.2, 0.5, 0.3)

func _fire_gatling():
	if not player: return
	if not _bullet_tex: _bullet_tex = load("res://assets/sprites/fx_bullet.png")
	var base_dir = (player.global_position - global_position).normalized()
	for i in 8:
		var angle = lerp(-0.65, 0.65, float(i) / 7.0)
		var dir   = base_dir.rotated(angle)
		var proj  = Area2D.new(); proj.collision_layer = 0; proj.collision_mask = 1
		var sp    = Sprite2D.new(); sp.texture = _bullet_tex; sp.scale = Vector2(0.10, 0.10); proj.add_child(sp)
		var cs    = CollisionShape2D.new(); var cc = CircleShape2D.new(); cc.radius = 9.0; cs.shape = cc; proj.add_child(cs)
		proj.body_entered.connect(func(b):
			if b.is_in_group("player") and b.has_method("take_damage"): b.take_damage(10.0)
			if is_instance_valid(proj): proj.queue_free()
		)
		get_parent().add_child(proj)
		proj.global_position = global_position + dir * 130.0
		var tw = proj.create_tween()
		tw.tween_property(proj, "global_position", proj.global_position + dir * 650.0, 1.5)
		tw.finished.connect(func(): if is_instance_valid(proj): proj.queue_free())

func _fire_missile():
	if not player: return
	var missile = missile_scene.instantiate()
	missile.target = player
	missile.global_position = global_position
	get_parent().add_child(missile)

func take_damage(amount: float):
	current_health -= amount
	modulate = Color(6, 6, 6)
	await get_tree().create_timer(0.05).timeout
	if not is_instance_valid(self): return
	modulate = Color(1.5, 0.4, 0.3) if phase == 2 else Color(1, 1, 1)
	if current_health <= 0: die()

func die():
	if is_dead: return
	is_dead = true
	if AchievementManager: AchievementManager.track_stat("boss_kills", 1)
	for i in 6:
		var expl = explosion_scene.instantiate(); expl.large = true
		get_parent().add_child(expl)
		expl.global_position = global_position + Vector2(randf_range(-120, 120), randf_range(-120, 120))
	emit_signal("died")
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(2.8, 2.8), 0.9).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.9)
	await tw.finished
	queue_free()
