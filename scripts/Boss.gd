extends CharacterBody2D

signal died

@export var max_health: float = 2000.0
var current_health: float
var player     = null
var is_dead    = false
var phase      := 1
var is_legendary := false
var _tele_timer: Timer = null

enum State {DRIFT, ATTACK_RAIN, CHARGE}
var current_state = State.DRIFT
var state_timer   = 0.0

var teleport_scene  = preload("res://scenes/TeleportEffect.tscn")
var explosion_scene = preload("res://scenes/ExplosionEffect.tscn")

# Référence au corps principal pour les effets de phase
var planet_body: Polygon2D = null

static var _bullet_tex: Texture2D = null


func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemies")

	_apply_level_scaling()
	current_health = max_health

	_setup_visual()

	# Effet d'apparition
	scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 1.8) \
		.set_trans(Tween.TRANS_BOUNCE)

	var effect = teleport_scene.instantiate()
	get_tree().current_scene.add_child(effect)
	effect.global_position = global_position


# ─────────────────────────────────────────────
#  VISUEL PROCÉDURAL — PLANÈTE MILITAIRE
# ─────────────────────────────────────────────

func _setup_visual():
	var vis    = $BossVisual
	var base_r := 195.0   # rayon planète (correspond ~collision 210)

	# ── Corps tournant (séparé du visage qui reste droit) ──
	var rotator = Node2D.new()
	vis.add_child(rotator)

	# Corps principal — vert militaire foncé
	planet_body = Polygon2D.new()
	planet_body.polygon = _make_circle(0, 0, base_r, 72, 0.025)
	planet_body.color   = Color(0.21, 0.31, 0.16)
	rotator.add_child(planet_body)

	# Taches de camouflage
	var camo_cols = [Color(0.17, 0.25, 0.13), Color(0.26, 0.37, 0.19),
	                 Color(0.14, 0.21, 0.10), Color(0.29, 0.40, 0.22)]
	for i in 10:
		var ang  = randf_range(0, TAU)
		var dist = randf_range(0.0, base_r * 0.55)
		var cr   = randf_range(25, 70)
		var blob = Polygon2D.new()
		blob.polygon = _make_circle(cos(ang) * dist, sin(ang) * dist, cr, 18, 0.12)
		blob.color   = camo_cols[i % camo_cols.size()]
		rotator.add_child(blob)

	# Cratères d'impact
	for i in 7:
		var ang  = randf_range(0, TAU)
		var dist = randf_range(0.0, base_r * 0.75)
		var cr   = randf_range(12, 35)
		var crater = Polygon2D.new()
		crater.polygon = _make_circle(cos(ang) * dist, sin(ang) * dist, cr, 14, 0.06)
		crater.color   = Color(0.13, 0.19, 0.09)
		rotator.add_child(crater)

	# Tourelles latérales (3 autour)
	for i in 3:
		var ang   = PI / 2 + TAU * i / 3
		var tx    = cos(ang) * base_r
		var ty    = sin(ang) * base_r
		var td    = Vector2(tx, ty).normalized()
		var perp  = Vector2(-td.y, td.x)
		_add_turret(rotator, tx, ty, td, perp, 16.0, 40.0)

	# ── Visage (ne tourne PAS) ──
	var face = Node2D.new()
	vis.add_child(face)

	# Ombre volumétrique (lumière haut-gauche → ombre côté droit)
	var shadow = Polygon2D.new()
	var shadow_pts = PackedVector2Array()
	shadow_pts.append(Vector2(0, -base_r))
	for i in range(1, 37):
		var a = -PI / 2.0 + PI * float(i) / 36.0
		shadow_pts.append(Vector2(cos(a) * base_r, sin(a) * base_r))
	shadow_pts.append(Vector2(0, base_r))
	shadow.polygon = shadow_pts
	shadow.color = Color(0.0, 0.0, 0.0, 0.30)
	face.add_child(shadow)

	# Reflet spéculaire haut-gauche
	var specular = Polygon2D.new()
	specular.polygon = _make_circle(-base_r * 0.38, -base_r * 0.38, base_r * 0.28, 20, 0.0)
	specular.color = Color(0.55, 0.80, 0.42, 0.18)
	face.add_child(specular)

	# Yeux — blancs
	for ex in [-65.0, 65.0]:
		var eye_w = Polygon2D.new()
		eye_w.polygon = _make_circle(ex, -30.0, 30.0, 20, 0.0)
		eye_w.color   = Color(0.92, 0.92, 0.82)
		face.add_child(eye_w)

		# Pupille — en colère (légèrement vers le centre)
		var px = ex + sign(-ex) * 6.0
		var pupil = Polygon2D.new()
		pupil.polygon = _make_circle(px, -25.0, 15.0, 16, 0.0)
		pupil.color   = Color(0.08, 0.04, 0.02)
		face.add_child(pupil)

		# Reflet
		var refl = Polygon2D.new()
		refl.polygon = _make_circle(px - 5, -30.0, 5.0, 10, 0.0)
		refl.color   = Color(1, 1, 1, 0.9)
		face.add_child(refl)

	# Sourcils épais et en V (signe de colère)
	for side in [-1.0, 1.0]:
		var brow = Polygon2D.new()
		var bx   = side * 65.0
		var by   = -64.0
		brow.polygon = PackedVector2Array([
			Vector2(bx - 32 * side, by + side * 12 - 8),
			Vector2(bx + 30 * side, by - side * 6  - 8),
			Vector2(bx + 30 * side, by - side * 6  + 3),
			Vector2(bx - 32 * side, by + side * 12 + 3),
		])
		brow.color = Color(0.10, 0.06, 0.03)
		face.add_child(brow)

	# Bouche — grimace militaire (trait droit légèrement courbé vers le bas)
	var mouth = Line2D.new()
	mouth.width = 9.0
	mouth.default_color = Color(0.10, 0.06, 0.03)
	var mpts = PackedVector2Array()
	for i in 14:
		var t = float(i) / 13
		var mx = lerp(-52.0, 52.0, t)
		var my = 52.0 + sin(t * PI) * 14.0   # grimace concave
		mpts.append(Vector2(mx, my))
	mouth.points = mpts
	face.add_child(mouth)

	# Moustache militaire
	for side in [-1.0, 1.0]:
		var mus = Line2D.new()
		mus.width = 6.0
		mus.default_color = Color(0.10, 0.06, 0.03)
		mus.points = PackedVector2Array([
			Vector2(side * 8, 30),
			Vector2(side * 35, 26),
			Vector2(side * 55, 32),
		])
		face.add_child(mus)

	# Étoile militaire (or) au centre bas
	var star = Polygon2D.new()
	star.polygon = _make_star(0, 100, 22, 10, 5)
	star.color   = Color(1.0, 0.82, 0.10)
	face.add_child(star)

	# ── Canon principal (en haut, ne tourne pas) ──
	var cannon_base = Polygon2D.new()
	cannon_base.polygon = _make_circle(0, -base_r + 15, 28, 16, 0.0)
	cannon_base.color   = Color(0.38, 0.38, 0.38)
	face.add_child(cannon_base)

	var barrel = Polygon2D.new()
	barrel.color = Color(0.32, 0.32, 0.32)
	barrel.polygon = PackedVector2Array([
		Vector2(-12, -base_r - 75), Vector2(12, -base_r - 75),
		Vector2(14,  -base_r +  5), Vector2(-14, -base_r +  5),
	])
	face.add_child(barrel)

	# Anneau atmosphérique
	var ring = Line2D.new()
	ring.default_color = Color(0.55, 0.75, 0.35, 0.22)
	ring.width = 14.0
	ring.points = _make_circle(0, 0, base_r + 30, 48, 0.0)
	face.add_child(ring)

	# Rotation lente du corps (camouflage tourne)
	var rot = create_tween().set_loops()
	rot.tween_property(rotator, "rotation_degrees", 360.0, 28.0) \
		.set_trans(Tween.TRANS_LINEAR)


func _add_turret(parent: Node2D, tx: float, ty: float,
                 td: Vector2, perp: Vector2, hw: float, blen: float):
	# Socle de tourelle
	var base = Polygon2D.new()
	base.color = Color(0.40, 0.40, 0.38)
	base.polygon = PackedVector2Array([
		Vector2(tx, ty) + perp * hw - td * hw,
		Vector2(tx, ty) - perp * hw - td * hw,
		Vector2(tx, ty) - perp * hw + td * hw,
		Vector2(tx, ty) + perp * hw + td * hw,
	])
	parent.add_child(base)
	# Canon de tourelle
	var gun = Polygon2D.new()
	gun.color = Color(0.30, 0.30, 0.30)
	gun.polygon = PackedVector2Array([
		Vector2(tx, ty) + perp * 5 + td * hw,
		Vector2(tx, ty) - perp * 5 + td * hw,
		Vector2(tx, ty) - perp * 5 + td * (hw + blen),
		Vector2(tx, ty) + perp * 5 + td * (hw + blen),
	])
	parent.add_child(gun)


# ─────────────────────────────────────────────
#  HELPERS GÉOMÉTRIQUES
# ─────────────────────────────────────────────

func _make_circle(cx: float, cy: float, r: float, n: int,
                  jitter: float = 0.0) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in n:
		var a  = TAU * i / n
		var jr = 1.0 + randf_range(-jitter, jitter)
		pts.append(Vector2(cx + cos(a) * r * jr, cy + sin(a) * r * jr))
	return pts


func _make_star(cx: float, cy: float, outer_r: float,
                inner_r: float, points: int) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in points * 2:
		var a = TAU * i / (points * 2) - PI / 2.0
		var rc = outer_r if i % 2 == 0 else inner_r
		pts.append(Vector2(cx + cos(a) * rc, cy + sin(a) * rc))
	return pts


# ─────────────────────────────────────────────
#  LOGIQUE DE COMBAT
# ─────────────────────────────────────────────

func _apply_level_scaling():
	var level := 1
	if GlobalManager: level = GlobalManager.current_selected_level
	max_health = max_health * (1.0 + level * 0.4)


func _physics_process(delta):
	if is_dead or not player: return

	if phase == 1 and current_health < max_health * 0.5:
		phase = 2
		_enter_phase2()

	if is_legendary and phase == 2 and current_health < max_health * 0.25:
		phase = 3
		_enter_phase3()

	state_timer += delta
	var proj_interval := 0.65 if phase == 1 else (0.35 if phase == 2 else 0.2)

	match current_state:
		State.DRIFT:
			var dist = global_position.distance_to(player.global_position)
			var dir  = (player.global_position - global_position).normalized()
			var spd  := 50.0 if phase == 1 else 80.0
			velocity  = dir * spd if dist > 280 else velocity.lerp(Vector2.ZERO, delta * 3.0)
			if state_timer > 5.0: change_state(State.ATTACK_RAIN)

		State.ATTACK_RAIN:
			velocity = velocity.lerp(Vector2.ZERO, delta * 2.5)
			if fmod(state_timer, proj_interval) < delta: spawn_projectile()
			if state_timer > 4.5: change_state(State.CHARGE)

		State.CHARGE:
			if state_timer < 0.6:
				velocity = (player.global_position - global_position).normalized() \
				         * (270.0 if phase == 1 else 400.0)
			else:
				velocity = velocity.lerp(Vector2.ZERO, delta * 4.0)
			if state_timer > 2.2: change_state(State.DRIFT)

	move_and_slide()


func set_legendary_mode():
	is_legendary = true
	max_health *= 1.5   # boss final plus costaud


func _enter_phase2():
	if planet_body:
		var tw = create_tween()
		tw.tween_property(planet_body, "color", Color(0.38, 0.14, 0.10), 0.8)
	# Flash d'alarme
	var alarm = create_tween().set_loops(8)
	alarm.tween_property($BossVisual, "modulate", Color(1.5, 0.3, 0.3, 1), 0.2)
	alarm.tween_property($BossVisual, "modulate", Color(1, 1, 1, 1), 0.2)


func _enter_phase3():
	if planet_body:
		var tw = create_tween()
		tw.tween_property(planet_body, "color", Color(0.55, 0.05, 0.05), 0.5)
	# Téléportation aléatoire toutes les 3s
	_tele_timer = Timer.new(); add_child(_tele_timer)
	_tele_timer.wait_time = 3.0
	_tele_timer.timeout.connect(_random_teleport)
	_tele_timer.start()
	# Flash d'alarme rouge intense
	var alarm = create_tween().set_loops(12)
	alarm.tween_property($BossVisual, "modulate", Color(2.0, 0.1, 0.1, 1), 0.15)
	alarm.tween_property($BossVisual, "modulate", Color(1, 1, 1, 1), 0.15)

func _random_teleport():
	if not player or is_dead: return
	var offset = Vector2(randf_range(-300, 300), randf_range(-300, 300))
	global_position = player.global_position + offset


func change_state(new_state):
	current_state = new_state
	state_timer   = 0.0


func spawn_projectile():
	if not player: return
	if not _bullet_tex:
		_bullet_tex = load("res://assets/sprites/fx_bullet.png")

	var shots    := 3 if phase == 1 else (5 if phase == 2 else 7)
	var spread   := 0.35 if phase == 1 else (0.58 if phase == 2 else 0.75)
	var base_dir = (player.global_position - global_position).normalized()

	for i in range(shots):
		var angle_off = lerp(-spread, spread, float(i) / max(shots - 1, 1))
		var dir = base_dir.rotated(angle_off)

		var proj = Area2D.new()
		proj.collision_layer = 0
		proj.collision_mask  = 1

		var sp = Sprite2D.new()
		sp.texture = _bullet_tex
		sp.scale   = Vector2(0.12, 0.12)
		proj.add_child(sp)

		var cs = CollisionShape2D.new()
		var cc = CircleShape2D.new()
		cc.radius = 11.0
		cs.shape  = cc
		proj.add_child(cs)

		var dmg    := 14.0 if phase == 1 else 26.0
		var travel = dir * 650.0

		proj.body_entered.connect(func(b):
			if b.is_in_group("player") and b.has_method("take_damage"):
				b.take_damage(dmg)
			if is_instance_valid(proj): proj.queue_free()
		)

		get_parent().add_child(proj)
		proj.global_position = global_position + dir * 220.0
		if sp: sp.rotation = travel.angle()

		var tw = proj.create_tween()
		tw.tween_property(proj, "global_position",
		                  proj.global_position + travel, 2.2)
		tw.finished.connect(func():
			if is_instance_valid(proj): proj.queue_free()
		)


func take_damage(amount: float):
	current_health -= amount
	modulate = Color(6, 6, 6)
	await get_tree().create_timer(0.05).timeout
	if not is_instance_valid(self): return
	modulate = Color(1.5, 0.4, 0.3) if phase == 2 else Color(1, 1, 1)
	if current_health <= 0:
		die()


func die():
	if is_dead: return
	is_dead = true

	if AchievementManager:
		AchievementManager.track_stat("boss_kills", 1)

	for i in 6:
		var expl = explosion_scene.instantiate()
		expl.large = true
		get_parent().add_child(expl)
		expl.global_position = global_position \
			+ Vector2(randf_range(-140, 140), randf_range(-140, 140))

	emit_signal("died")

	var tw = create_tween()
	tw.tween_property(self, "scale",      Vector2(2.8, 2.8), 0.9).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.9)
	await tw.finished
	queue_free()
