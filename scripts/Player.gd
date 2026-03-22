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
	# Supprimer les anciens visuels
	for child in ship_visual.get_children():
		if child is Polygon2D or child is Line2D: child.queue_free()
	ship_visual.modulate = Color(1, 1, 1)

	if lv < 5:
		_draw_ship_tier1()
	elif lv < 10:
		_draw_ship_tier2()
	elif lv < 15:
		_draw_ship_tier3()
	else:
		_draw_ship_tier4()

func _draw_ship_tier1():
	# Tier 1 : Chasseur Félin bleu
	_add_ship_body(Color("#2244aa"), PackedVector2Array([
		Vector2(0,-30), Vector2(18,15), Vector2(12,30), Vector2(-12,30), Vector2(-18,15)
	]))
	_add_ship_wings(Color("#1a3388"), [
		PackedVector2Array([Vector2(-18,15), Vector2(-28,24), Vector2(-12,30)]),
		PackedVector2Array([Vector2(18,15),  Vector2(28,24),  Vector2(12,30)])
	])
	_add_cat_cockpit(Vector2(0,-6), 13.0, Color("#0d1f55"), Color("#4488ff"), Color("#4488ff"),
	                 Color("#ffcc99"), Color("#1a6600"))
	_add_ship_cannons([Vector2(0,-32)], Color("#3355bb"))
	_add_thrusters([Vector2(0,30)], Color("#4466ff"))
	_add_cat_ears(Vector2(0,-6), Color("#1a3388"), Color("#ff99cc"))

func _draw_ship_tier2():
	# Tier 2 : Intercepteur Cosmique violet
	_add_ship_body(Color("#6622bb"), PackedVector2Array([
		Vector2(0,-35), Vector2(22,14), Vector2(16,38), Vector2(-16,38), Vector2(-22,14)
	]))
	_add_ship_wings(Color("#4411aa"), [
		PackedVector2Array([Vector2(-22,14), Vector2(-36,26), Vector2(-16,38)]),
		PackedVector2Array([Vector2(22,14),  Vector2(36,26),  Vector2(16,38)])
	])
	_add_cat_cockpit(Vector2(0,-8), 15.0, Color("#2d0a66"), Color("#9955ff"), Color("#bb88ff"),
	                 Color("#f0bb88"), Color("#0066aa"))
	_add_cat_ears(Vector2(0,-8), Color("#4411aa"), Color("#ffaadd"))
	_add_ship_cannons([Vector2(-7,-38), Vector2(7,-38)], Color("#8844ff"))
	_add_thrusters([Vector2(-10,38), Vector2(10,38)], Color("#cc88ff"))

func _draw_ship_tier3():
	# Tier 3 : Destroyer Stellaire cyan
	_add_ship_body(Color("#116677"), PackedVector2Array([
		Vector2(0,-42), Vector2(28,10), Vector2(22,44), Vector2(-22,44), Vector2(-28,10)
	]))
	_add_ship_wings(Color("#0a5566"), [
		PackedVector2Array([Vector2(-28,10), Vector2(-46,30), Vector2(-22,44)]),
		PackedVector2Array([Vector2(28,10),  Vector2(46,30),  Vector2(22,44)])
	])
	# Ailettes secondaires
	_add_ship_wings(Color("#0d6677"), [
		PackedVector2Array([Vector2(-20,0), Vector2(-36,12), Vector2(-28,22)]),
		PackedVector2Array([Vector2(20,0),  Vector2(36,12),  Vector2(28,22)])
	])
	_add_cat_cockpit(Vector2(0,-10), 17.0, Color("#083344"), Color("#44ffee"), Color("#44ffee"),
	                 Color("#eecc99"), Color("#008866"))
	_add_cat_ears(Vector2(0,-10), Color("#0a5566"), Color("#aaffee"))
	_add_ship_cannons([Vector2(-7,-44), Vector2(0,-46), Vector2(7,-44)], Color("#22ddcc"))
	_add_thrusters([Vector2(-16,44), Vector2(0,44), Vector2(16,44)], Color("#44ffee"))

func _draw_ship_tier4():
	# Tier 4 : Cuirassé Royal or
	_add_ship_body(Color("#aa7700"), PackedVector2Array([
		Vector2(0,-48), Vector2(32,8), Vector2(26,48), Vector2(-26,48), Vector2(-32,8)
	]))
	_add_ship_wings(Color("#886600"), [
		PackedVector2Array([Vector2(-32,8), Vector2(-54,30), Vector2(-26,48)]),
		PackedVector2Array([Vector2(32,8),  Vector2(54,30),  Vector2(26,48)])
	])
	_add_ship_wings(Color("#775500"), [
		PackedVector2Array([Vector2(-22,-4), Vector2(-44,8), Vector2(-34,18)]),
		PackedVector2Array([Vector2(22,-4),  Vector2(44,8),  Vector2(34,18)])
	])
	_add_cat_cockpit(Vector2(0,-12), 20.0, Color("#5a3a00"), Color("#ffcc00"), Color("#ffcc00"),
	                 Color("#f5cc99"), Color("#886600"))
	_add_cat_ears(Vector2(0,-12), Color("#886600"), Color("#ffaadd"))
	_add_crown(Vector2(0,-32))
	_add_ship_cannons([Vector2(-10,-50), Vector2(-3,-52), Vector2(3,-52), Vector2(10,-50)], Color("#ffcc00"))
	_add_thrusters([Vector2(-20,48), Vector2(0,50), Vector2(20,48)], Color("#ffee44"))
	ship_visual.modulate = Color(1.25, 1.05, 0.5)  # glow doré

# --- Helpers vaisseaux ---

func _add_ship_body(col: Color, pts: PackedVector2Array):
	var p = Polygon2D.new(); p.color = col; p.polygon = pts; ship_visual.add_child(p)

func _add_ship_wings(col: Color, wings: Array):
	for w in wings:
		var p = Polygon2D.new(); p.color = col; p.polygon = w; ship_visual.add_child(p)

func _add_cat_cockpit(center: Vector2, radius: float,
                      bg_col: Color, glow_col: Color, rim_col: Color,
                      fur_col: Color, iris_col: Color):
	# Fond cockpit
	var bg = Polygon2D.new(); bg.color = bg_col
	bg.polygon = _ship_ellipse(radius, radius * 1.2, 12)
	bg.position = center; ship_visual.add_child(bg)
	# Reflet vitré
	var glow = Polygon2D.new(); glow.color = Color(glow_col.r, glow_col.g, glow_col.b, 0.15)
	glow.polygon = _ship_ellipse(radius * 0.85, radius * 1.05, 12)
	glow.position = center; ship_visual.add_child(glow)
	# Tête du chat
	var head = Polygon2D.new(); head.color = fur_col
	head.polygon = _ship_ellipse(radius * 0.8, radius * 0.85, 12)
	head.position = center; ship_visual.add_child(head)
	# Yeux
	var eye_r = radius * 0.28
	var ey = center.y - radius * 0.18
	_ship_eye(Vector2(center.x - radius*0.38, ey), eye_r, iris_col)
	_ship_eye(Vector2(center.x + radius*0.38, ey), eye_r, iris_col)
	# Nez
	var nose = Polygon2D.new(); nose.color = Color("#ff6699")
	nose.polygon = _ship_ellipse(radius*0.13, radius*0.1, 6)
	nose.position = Vector2(center.x, center.y + radius*0.1); ship_visual.add_child(nose)
	# Joues roses
	for sx in [-1.0, 1.0]:
		var cheek = Polygon2D.new()
		cheek.color = Color(1, 0.6, 0.6, 0.35)
		cheek.polygon = _ship_ellipse(radius*0.28, radius*0.2, 8)
		cheek.position = Vector2(center.x + sx*radius*0.55, center.y + radius*0.15)
		ship_visual.add_child(cheek)
	# Moustaches
	for side in [-1.0, 1.0]:
		for row in [0.0, 1.0]:
			var w = Line2D.new(); w.width = 1.0
			w.default_color = Color(0.6, 0.5, 0.4, 0.65)
			var ox = side * radius * 0.2
			var oy = center.y + radius * 0.08 + row * radius * 0.12
			w.points = PackedVector2Array([
				Vector2(center.x + ox, oy),
				Vector2(center.x + side * radius * 0.95, oy - row * radius * 0.05)
			])
			ship_visual.add_child(w)
	# Contour vitre
	var rim = Line2D.new(); rim.width = 1.5
	rim.default_color = Color(rim_col.r, rim_col.g, rim_col.b, 0.4)
	rim.points = _ship_ellipse(radius, radius * 1.2, 12)
	rim.closed = true; rim.position = center; ship_visual.add_child(rim)

func _ship_eye(pos: Vector2, r: float, iris_col: Color):
	for data in [
		[r, Color.WHITE], [r*0.72, iris_col],
		[r*0.44, Color(0.1,0.1,0.1)], [r*0.22, Color.WHITE]
	]:
		var p = Polygon2D.new(); p.color = data[1]
		p.polygon = _ship_ellipse(data[0], data[0], 8)
		p.position = pos; ship_visual.add_child(p)

func _add_cat_ears(center: Vector2, col_outer: Color, col_inner: Color):
	for sx in [-1.0, 1.0]:
		var ox = center.x + sx * 11.0; var oy = center.y - 16.0
		var outer = Polygon2D.new(); outer.color = col_outer
		outer.polygon = PackedVector2Array([Vector2(ox-5,oy), Vector2(ox,oy-12), Vector2(ox+5,oy)])
		ship_visual.add_child(outer)
		var inner = Polygon2D.new(); inner.color = col_inner
		inner.polygon = PackedVector2Array([Vector2(ox-3,oy-1), Vector2(ox,oy-8), Vector2(ox+3,oy-1)])
		ship_visual.add_child(inner)

func _add_crown(center: Vector2):
	var crown = Polygon2D.new(); crown.color = Color("#ffcc00")
	crown.polygon = PackedVector2Array([
		Vector2(center.x-14,center.y+4), Vector2(center.x-14,center.y-4),
		Vector2(center.x-8,center.y-10), Vector2(center.x-4,center.y-4),
		Vector2(center.x,center.y-14), Vector2(center.x+4,center.y-4),
		Vector2(center.x+8,center.y-10), Vector2(center.x+14,center.y-4),
		Vector2(center.x+14,center.y+4)
	])
	ship_visual.add_child(crown)
	# Gemmes couronne
	for gem_data in [[center.x, center.y-14, "#ff4444"],
	                 [center.x-14, center.y-5, "#4488ff"],
	                 [center.x+14, center.y-5, "#44ff88"]]:
		var gem = Polygon2D.new(); gem.color = Color(gem_data[2])
		gem.polygon = _ship_ellipse(2.5, 2.5, 6)
		gem.position = Vector2(gem_data[0], gem_data[1])
		ship_visual.add_child(gem)

func _add_ship_cannons(positions: Array, col: Color):
	for pos in positions:
		var c = Polygon2D.new(); c.color = col
		c.polygon = PackedVector2Array([Vector2(-3,0), Vector2(3,0), Vector2(3,12), Vector2(-3,12)])
		c.position = Vector2(pos.x, pos.y - 12); ship_visual.add_child(c)

func _add_thrusters(positions: Array, col: Color):
	for pos in positions:
		var t = Polygon2D.new()
		t.color = Color(col.r, col.g, col.b, 0.8)
		t.polygon = _ship_ellipse(5.0, 4.0, 8)
		t.position = pos; ship_visual.add_child(t)

func _ship_ellipse(rx: float, ry: float, n: int) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in n:
		var a = TAU * i / n
		pts.append(Vector2(cos(a)*rx, sin(a)*ry))
	return pts

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
	if current_health <= 0:
		is_dead = true
	ship_visual.modulate = Color(5, 5, 5)
	await get_tree().create_timer(0.05).timeout
	if not is_instance_valid(self) or not is_inside_tree(): return
	# Ne pas écraser la couleur bleue du bouclier si rechargé pendant le flash
	if not shield_active:
		ship_visual.modulate = Color(1, 1, 1)
	if is_dead:
		emit_signal("died")

func collect_kibble(amount: int):
	run_kibble += amount

func add_xp(amount: int):
	current_xp += amount
	if current_xp >= xp_to_next_level:
		level += 1
		current_xp = 0
		xp_to_next_level += 20
		emit_signal("leveled_up", level)
		setup_ship_visual(level)
