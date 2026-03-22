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
var shield_ring: Line2D = null

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
	for child in ship_visual.get_children():
		if child is Polygon2D or child is Line2D: child.queue_free()
	ship_visual.modulate = Color(1, 1, 1)
	if lv < 5: _draw_ship_tier1()
	elif lv < 10: _draw_ship_tier2()
	elif lv < 15: _draw_ship_tier3()
	else: _draw_ship_tier4()
	# Anneau bouclier (masqué par défaut)
	shield_ring = Line2D.new()
	shield_ring.default_color = Color(0.2, 0.9, 1.0, 0.85)
	shield_ring.width = 3.0
	shield_ring.points = _sv_ellipse(42, 42, 28)
	shield_ring.closed = true
	shield_ring.visible = shield_active
	ship_visual.add_child(shield_ring)

func _draw_ship_tier1():
	# Fighter Scout — mech-cat compact, grands panneaux œil dominants
	var H = Color("#141840"); var M = Color("#1a2258")
	var W = Color("#182080"); var C = Color(0.0, 0.8, 1.0, 0.5)
	var EI = Color("#ff88cc")
	# Corps 7 côtés
	_svp(H, PackedVector2Array([Vector2(0,-44),Vector2(16,-8),Vector2(14,10),Vector2(10,34),
	                             Vector2(-10,34),Vector2(-14,10),Vector2(-16,-8)]))
	_svp(M, PackedVector2Array([Vector2(0,-36),Vector2(11,-6),Vector2(10,8),Vector2(7,26),
	                             Vector2(-7,26),Vector2(-10,8),Vector2(-11,-6)]))
	# Ailes sweepées
	_svp(W, PackedVector2Array([Vector2(-14,10),Vector2(-38,24),Vector2(-28,34),Vector2(-10,34)]))
	_svp(W, PackedVector2Array([Vector2(14,10), Vector2(38,24), Vector2(28,34), Vector2(10,34)]))
	# PANNEAUX ŒIL — feature dominante (gauche)
	_svp(Color(0.0,0.3,0.65,0.95), PackedVector2Array([
		Vector2(-15,-24),Vector2(-3,-30),Vector2(-2,-10),Vector2(-14,-6)]))
	_svp(Color(0.25,0.82,1.0,0.75), PackedVector2Array([
		Vector2(-13,-26),Vector2(-8,-30),Vector2(-7,-19),Vector2(-12,-16)]))
	# Droite
	_svp(Color(0.0,0.3,0.65,0.95), PackedVector2Array([
		Vector2(15,-24),Vector2(3,-30),Vector2(2,-10),Vector2(14,-6)]))
	_svp(Color(0.25,0.82,1.0,0.75), PackedVector2Array([
		Vector2(13,-26),Vector2(8,-30),Vector2(7,-19),Vector2(12,-16)]))
	# OREILLES — fins structurelles proéminentes
	_svp(M,  PackedVector2Array([Vector2(-10,-34),Vector2(-22,-58),Vector2(-4,-40)]))
	_svp(M,  PackedVector2Array([Vector2(10,-34), Vector2(22,-58), Vector2(4,-40)]))
	_svp(EI, PackedVector2Array([Vector2(-10,-36),Vector2(-18,-54),Vector2(-6,-40)]))
	_svp(EI, PackedVector2Array([Vector2(10,-36), Vector2(18,-54), Vector2(6,-40)]))
	# Canon + réacteur
	_svp(M, PackedVector2Array([Vector2(-3,-40),Vector2(3,-40),Vector2(2,-54),Vector2(-2,-54)]))
	_svp(Color(0.0,0.6,1.0,0.7), _sv_ellipse_at(6, 4, 8, Vector2(0, 34)))
	# Glow
	_svl(PackedVector2Array([Vector2(0,-44),Vector2(16,-8),Vector2(14,10),Vector2(10,34),
	                          Vector2(-10,34),Vector2(-14,10),Vector2(-16,-8)]), C, 1.0)
	_svl(PackedVector2Array([Vector2(-14,10),Vector2(-38,24),Vector2(-28,34),Vector2(-10,34)]), C, 1.0)
	_svl(PackedVector2Array([Vector2(14,10), Vector2(38,24), Vector2(28,34), Vector2(10,34)]),  C, 1.0)

func _draw_ship_tier2():
	# Cruiser Escort — medium, grands œil + 4 oreilles + pods d'aile
	var H = Color("#141840"); var M = Color("#1e2870")
	var W = Color("#1a2890"); var C = Color(0.0, 0.8, 1.0, 0.55)
	var EI = Color("#ff88cc"); var POD = Color("#252e90")
	_svp(H, PackedVector2Array([Vector2(0,-50),Vector2(20,-6),Vector2(18,12),Vector2(14,40),
	                             Vector2(-14,40),Vector2(-18,12),Vector2(-20,-6)]))
	_svp(M, PackedVector2Array([Vector2(0,-42),Vector2(14,-4),Vector2(12,10),Vector2(9,32),
	                             Vector2(-9,32),Vector2(-12,10),Vector2(-14,-4)]))
	# Ailes + panneaux intérieurs
	_svp(W,   PackedVector2Array([Vector2(-18,12),Vector2(-46,26),Vector2(-40,40),Vector2(-14,40)]))
	_svp(W,   PackedVector2Array([Vector2(18,12), Vector2(46,26), Vector2(40,40), Vector2(14,40)]))
	_svp(POD, PackedVector2Array([Vector2(-18,12),Vector2(-30,18),Vector2(-26,32),Vector2(-14,32)]))
	_svp(POD, PackedVector2Array([Vector2(18,12), Vector2(30,18), Vector2(26,32), Vector2(14,32)]))
	_svp(H, PackedVector2Array([Vector2(-44,24),Vector2(-50,28),Vector2(-46,36),Vector2(-40,32)]))
	_svp(H, PackedVector2Array([Vector2(44,24), Vector2(50,28), Vector2(46,36), Vector2(40,32)]))
	# PANNEAUX ŒIL (grands)
	_svp(Color(0.0,0.3,0.65,0.95), PackedVector2Array([
		Vector2(-18,-28),Vector2(-4,-36),Vector2(-3,-12),Vector2(-17,-8)]))
	_svp(Color(0.25,0.82,1.0,0.75), PackedVector2Array([
		Vector2(-16,-31),Vector2(-9,-36),Vector2(-8,-22),Vector2(-14,-18)]))
	_svp(Color(0.0,0.3,0.65,0.95), PackedVector2Array([
		Vector2(18,-28),Vector2(4,-36),Vector2(3,-12),Vector2(17,-8)]))
	_svp(Color(0.25,0.82,1.0,0.75), PackedVector2Array([
		Vector2(16,-31),Vector2(9,-36),Vector2(8,-22),Vector2(14,-18)]))
	# Grandes oreilles + mini-fins
	_svp(M,  PackedVector2Array([Vector2(-12,-38),Vector2(-26,-64),Vector2(-4,-44)]))
	_svp(M,  PackedVector2Array([Vector2(12,-38), Vector2(26,-64), Vector2(4,-44)]))
	_svp(EI, PackedVector2Array([Vector2(-12,-40),Vector2(-21,-60),Vector2(-7,-44)]))
	_svp(EI, PackedVector2Array([Vector2(12,-40), Vector2(21,-60), Vector2(7,-44)]))
	_svp(M, PackedVector2Array([Vector2(-20,-4),Vector2(-28,-14),Vector2(-22,0)]))
	_svp(M, PackedVector2Array([Vector2(20,-4), Vector2(28,-14), Vector2(22,0)]))
	# 3 cannons + réacteurs
	_svp(M, PackedVector2Array([Vector2(-3,-46), Vector2(3,-46), Vector2(2,-60), Vector2(-2,-60)]))
	_svp(M, PackedVector2Array([Vector2(-16,-44),Vector2(-12,-44),Vector2(-13,-58),Vector2(-15,-58)]))
	_svp(M, PackedVector2Array([Vector2(16,-44), Vector2(12,-44), Vector2(13,-58), Vector2(15,-58)]))
	_svp(Color(0.0,0.6,1.0,0.7), _sv_ellipse_at(6, 4, 8, Vector2(-9, 40)))
	_svp(Color(0.0,0.6,1.0,0.7), _sv_ellipse_at(6, 4, 8, Vector2(9, 40)))
	# Glow
	_svl(PackedVector2Array([Vector2(0,-50),Vector2(20,-6),Vector2(18,12),Vector2(14,40),
	                          Vector2(-14,40),Vector2(-18,12),Vector2(-20,-6)]), C, 1.0)
	_svl(PackedVector2Array([Vector2(-18,12),Vector2(-46,26),Vector2(-40,40),Vector2(-14,40)]), C, 1.0)
	_svl(PackedVector2Array([Vector2(18,12), Vector2(46,26), Vector2(40,40), Vector2(14,40)]),  C, 1.0)

func _draw_ship_tier3():
	# Heavy Cruiser Command — grand, 6 cannons, pods moteur, ailes secondaires
	var H = Color("#0e1238"); var M = Color("#1a246a")
	var W = Color("#14207a"); var C = Color(0.0, 0.87, 1.0, 0.65)
	var EI = Color("#ff88cc"); var ENG = Color("#101840")
	_svp(H, PackedVector2Array([Vector2(0,-56),Vector2(24,-4),Vector2(22,14),Vector2(18,50),
	                             Vector2(-18,50),Vector2(-22,14),Vector2(-24,-4)]))
	_svp(M, PackedVector2Array([Vector2(0,-48),Vector2(17,-2),Vector2(15,12),Vector2(12,40),
	                             Vector2(-12,40),Vector2(-15,12),Vector2(-17,-2)]))
	# Ailes principales
	_svp(W, PackedVector2Array([Vector2(-22,14),Vector2(-58,28),Vector2(-52,50),Vector2(-18,50)]))
	_svp(W, PackedVector2Array([Vector2(22,14), Vector2(58,28), Vector2(52,50), Vector2(18,50)]))
	_svp(Color("#12196a"), PackedVector2Array([Vector2(-22,14),Vector2(-38,20),Vector2(-34,42),Vector2(-18,42)]))
	_svp(Color("#12196a"), PackedVector2Array([Vector2(22,14), Vector2(38,20), Vector2(34,42), Vector2(18,42)]))
	# Ailettes secondaires
	_svp(W, PackedVector2Array([Vector2(-18,-8),Vector2(-38,4), Vector2(-28,18),Vector2(-20,10)]))
	_svp(W, PackedVector2Array([Vector2(18,-8), Vector2(38,4),  Vector2(28,18), Vector2(20,10)]))
	# Pods moteur
	_svp(ENG, PackedVector2Array([Vector2(-54,24),Vector2(-60,30),Vector2(-56,44),Vector2(-50,38)]))
	_svp(ENG, PackedVector2Array([Vector2(54,24), Vector2(60,30), Vector2(56,44), Vector2(50,38)]))
	_svp(Color(0.0,0.6,1.0,0.7), _sv_ellipse_at(4, 3, 8, Vector2(-55, 42)))
	_svp(Color(0.0,0.6,1.0,0.7), _sv_ellipse_at(4, 3, 8, Vector2(55, 42)))
	# PANNEAUX ŒIL (très grands)
	_svp(Color(0.0,0.32,0.72,0.95), PackedVector2Array([
		Vector2(-21,-32),Vector2(-5,-42),Vector2(-4,-14),Vector2(-20,-10)]))
	_svp(Color(0.3,0.86,1.0,0.78), PackedVector2Array([
		Vector2(-19,-35),Vector2(-10,-42),Vector2(-9,-26),Vector2(-17,-22)]))
	_svp(Color(0.0,0.32,0.72,0.95), PackedVector2Array([
		Vector2(21,-32),Vector2(5,-42),Vector2(4,-14),Vector2(20,-10)]))
	_svp(Color(0.3,0.86,1.0,0.78), PackedVector2Array([
		Vector2(19,-35),Vector2(10,-42),Vector2(9,-26),Vector2(17,-22)]))
	# Oreilles proéminentes
	_svp(M,  PackedVector2Array([Vector2(-14,-44),Vector2(-30,-72),Vector2(-4,-50)]))
	_svp(M,  PackedVector2Array([Vector2(14,-44), Vector2(30,-72), Vector2(4,-50)]))
	_svp(EI, PackedVector2Array([Vector2(-14,-46),Vector2(-25,-68),Vector2(-8,-50)]))
	_svp(EI, PackedVector2Array([Vector2(14,-46), Vector2(25,-68), Vector2(8,-50)]))
	# 6 cannons
	for cx in [-16.0, 0.0, 16.0]:
		_svp(M, PackedVector2Array([Vector2(cx-3,-50),Vector2(cx+3,-50),Vector2(cx+2,-66),Vector2(cx-2,-66)]))
	_svp(M, PackedVector2Array([Vector2(-20,6), Vector2(-16,6), Vector2(-17,-8), Vector2(-19,-8)]))
	_svp(M, PackedVector2Array([Vector2(20,6),  Vector2(16,6),  Vector2(17,-8),  Vector2(19,-8)]))
	# Réacteurs ×3
	for rx2 in [-14.0, 0.0, 14.0]:
		_svp(Color(0.0,0.7,1.0,0.7), _sv_ellipse_at(5, 3.5, 8, Vector2(rx2, 50)))
	# Glow
	_svl(PackedVector2Array([Vector2(0,-56),Vector2(24,-4),Vector2(22,14),Vector2(18,50),
	                          Vector2(-18,50),Vector2(-22,14),Vector2(-24,-4)]), C, 1.2)
	_svl(PackedVector2Array([Vector2(-22,14),Vector2(-58,28),Vector2(-52,50),Vector2(-18,50)]), C, 1.2)
	_svl(PackedVector2Array([Vector2(22,14), Vector2(58,28), Vector2(52,50), Vector2(18,50)]),  C, 1.2)
	var ml3 = Line2D.new(); ml3.default_color = Color(0.0,0.87,1.0,0.35); ml3.width = 1.0
	ml3.points = PackedVector2Array([Vector2(0,-56), Vector2(0,50)]); ship_visual.add_child(ml3)

func _draw_ship_tier4():
	# Dreadnought Battleship — 3 sections, huge eye panels, 5 cannons, radar
	var H  = Color("#0a0e2a"); var M  = Color("#141880")
	var W  = Color("#10147a"); var C  = Color(0.0, 0.87, 1.0, 0.7)
	var PU = Color(0.53,0.33,0.87,0.5); var EI = Color("#ff66cc")
	var FL = Color("#0d1166")
	_svp(H, PackedVector2Array([Vector2(0,-64),Vector2(26,0),Vector2(24,16),Vector2(20,56),
	                             Vector2(-20,56),Vector2(-24,16),Vector2(-26,0)]))
	_svp(M, PackedVector2Array([Vector2(0,-56),Vector2(18,-2),Vector2(16,14),Vector2(13,46),
	                             Vector2(-13,46),Vector2(-16,14),Vector2(-18,-2)]))
	# Flancs
	_svp(FL, PackedVector2Array([Vector2(-26,0),Vector2(-40,-6),Vector2(-38,20),Vector2(-26,26)]))
	_svp(FL, PackedVector2Array([Vector2(26,0), Vector2(40,-6), Vector2(38,20), Vector2(26,26)]))
	# Grandes ailes + panneaux
	_svp(W, PackedVector2Array([Vector2(-24,16),Vector2(-68,30),Vector2(-62,56),Vector2(-20,56)]))
	_svp(W, PackedVector2Array([Vector2(24,16), Vector2(68,30), Vector2(62,56), Vector2(20,56)]))
	_svp(Color("#0e1570"), PackedVector2Array([Vector2(-24,16),Vector2(-44,22),Vector2(-40,48),Vector2(-20,48)]))
	_svp(Color("#0e1570"), PackedVector2Array([Vector2(24,16), Vector2(44,22), Vector2(40,48), Vector2(20,48)]))
	# Ailettes secondaires
	_svp(W, PackedVector2Array([Vector2(-20,-12),Vector2(-46,2), Vector2(-36,16),Vector2(-22,8)]))
	_svp(W, PackedVector2Array([Vector2(20,-12), Vector2(46,2),  Vector2(36,16), Vector2(22,8)]))
	# Pods bout d'aile
	_svp(H, PackedVector2Array([Vector2(-64,26),Vector2(-72,32),Vector2(-68,48),Vector2(-60,42)]))
	_svp(H, PackedVector2Array([Vector2(64,26), Vector2(72,32), Vector2(68,48), Vector2(60,42)]))
	_svp(Color(0.53,0.33,0.87,0.7), _sv_ellipse_at(4, 3, 8, Vector2(-66, 46)))
	_svp(Color(0.53,0.33,0.87,0.7), _sv_ellipse_at(4, 3, 8, Vector2(66, 46)))
	# PANNEAUX ŒIL (énormes)
	_svp(Color(0.0,0.28,0.65,0.95), PackedVector2Array([
		Vector2(-24,-38),Vector2(-5,-50),Vector2(-4,-16),Vector2(-22,-12)]))
	_svp(Color(0.4,0.9,1.0,0.82), PackedVector2Array([
		Vector2(-22,-42),Vector2(-11,-50),Vector2(-10,-30),Vector2(-20,-26)]))
	_svp(Color(0.0,0.28,0.65,0.95), PackedVector2Array([
		Vector2(24,-38),Vector2(5,-50),Vector2(4,-16),Vector2(22,-12)]))
	_svp(Color(0.4,0.9,1.0,0.82), PackedVector2Array([
		Vector2(22,-42),Vector2(11,-50),Vector2(10,-30),Vector2(20,-26)]))
	# Grandes oreilles structurelles
	_svp(M,  PackedVector2Array([Vector2(-16,-50),Vector2(-34,-78),Vector2(-5,-58)]))
	_svp(M,  PackedVector2Array([Vector2(16,-50), Vector2(34,-78), Vector2(5,-58)]))
	_svp(EI, PackedVector2Array([Vector2(-16,-52),Vector2(-28,-74),Vector2(-9,-57)]))
	_svp(EI, PackedVector2Array([Vector2(16,-52), Vector2(28,-74), Vector2(9,-57)]))
	# Antennes
	for ax in [[-8.0,-64.0,-14.0,-82.0],[0.0,-64.0,0.0,-84.0],[8.0,-64.0,14.0,-82.0]]:
		var ant = Line2D.new(); ant.default_color = Color(0.0,0.87,1.0,0.8); ant.width = 1.0
		ant.points = PackedVector2Array([Vector2(ax[0],ax[1]),Vector2(ax[2],ax[3])])
		ship_visual.add_child(ant)
	# Radar
	var rad = Line2D.new(); rad.default_color = Color(0.53,0.33,0.87,0.35); rad.width = 1.0
	rad.points = _sv_ellipse(22, 14, 16); rad.closed = true; rad.position = Vector2(0,-14)
	ship_visual.add_child(rad)
	# 5 cannons + 2 latéraux
	for cx in [-20.0, -10.0, 0.0, 10.0, 20.0]:
		_svp(M, PackedVector2Array([Vector2(cx-3,-58),Vector2(cx+3,-58),Vector2(cx+2,-76),Vector2(cx-2,-76)]))
	_svp(M, PackedVector2Array([Vector2(-28,2),Vector2(-24,2),Vector2(-25,-14),Vector2(-27,-14)]))
	_svp(M, PackedVector2Array([Vector2(28,2), Vector2(24,2), Vector2(25,-14), Vector2(27,-14)]))
	# Réacteurs ×4
	for rx2 in [-20.0, -7.0, 7.0, 20.0]:
		_svp(Color(0.53,0.33,0.87,0.8), _sv_ellipse_at(6, 4, 8, Vector2(rx2, 56)))
	# Glow cyan
	_svl(PackedVector2Array([Vector2(0,-64),Vector2(26,0),Vector2(24,16),Vector2(20,56),
	                          Vector2(-20,56),Vector2(-24,16),Vector2(-26,0)]), C, 1.3)
	_svl(PackedVector2Array([Vector2(-24,16),Vector2(-68,30),Vector2(-62,56),Vector2(-20,56)]), C, 1.3)
	_svl(PackedVector2Array([Vector2(24,16), Vector2(68,30), Vector2(62,56), Vector2(20,56)]),  C, 1.3)
	# Glow purple flancs
	_svl(PackedVector2Array([Vector2(-26,0),Vector2(-40,-6),Vector2(-38,20),Vector2(-26,26)]), PU, 1.0)
	_svl(PackedVector2Array([Vector2(26,0), Vector2(40,-6), Vector2(38,20), Vector2(26,26)]),  PU, 1.0)
	var ml4 = Line2D.new(); ml4.default_color = Color(0.0,0.87,1.0,0.35); ml4.width = 1.2
	ml4.points = PackedVector2Array([Vector2(0,-64), Vector2(0,56)]); ship_visual.add_child(ml4)
	ship_visual.modulate = Color(1.0, 1.0, 1.15)

# --- Helpers visuels vaisseau ---

func _svp(col: Color, pts: PackedVector2Array):
	var p = Polygon2D.new(); p.color = col; p.polygon = pts
	ship_visual.add_child(p)

func _svl(pts: PackedVector2Array, col: Color, width: float = 1.5):
	var l = Line2D.new(); l.default_color = col; l.width = width
	l.points = pts; l.closed = true
	ship_visual.add_child(l)

func _sv_ellipse(rx: float, ry: float, n: int = 12) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in n:
		var a = TAU * i / n
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts

func _sv_ellipse_at(rx: float, ry: float, n: int, offset: Vector2) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in n:
		var a = TAU * i / n
		pts.append(Vector2(cos(a) * rx + offset.x, sin(a) * ry + offset.y))
	return pts

func _physics_process(delta):
	if is_dead: return

	# Recharge du bouclier (float timer — pas de nœud Timer)
	if not shield_active:
		shield_timer += delta
		if shield_timer >= shield_cooldown:
			shield_active = true
			shield_timer = 0.0
			if shield_ring: shield_ring.visible = true

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
	b.z_index = -20
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
		if shield_ring: shield_ring.visible = false
		return
	current_health -= amount
	if health_bar: health_bar.value = current_health
	if current_health <= 0:
		is_dead = true
	ship_visual.modulate = Color(5, 5, 5)
	await get_tree().create_timer(0.05).timeout
	if not is_instance_valid(self) or not is_inside_tree(): return
	# Ne pas écraser la couleur bleue du bouclier si rechargé pendant le flash
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
