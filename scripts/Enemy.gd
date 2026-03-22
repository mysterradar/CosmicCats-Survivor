extends CharacterBody2D

signal died

enum Type {NORMAL, SCOUT, WARRIOR}
@export var enemy_type: Type = Type.NORMAL

@export var speed: float = 100.0
@export var damage: float = 10.0
@export var max_health: float = 20.0
var current_health: float
var is_elite: bool = false

var player = null
var gem_scene = preload("res://scenes/ExperienceGem.tscn")
var kibble_scene = preload("res://scenes/KibbleItem.tscn")
var animation_timer = 0.0

func _ready():
	player = get_tree().get_first_node_in_group("player")
	animation_timer = randf() * 2.0
	setup_mouse_visual()
	current_health = max_health

func setup_mouse_visual():
	for child in get_children():
		if child is Polygon2D or child is Line2D: child.queue_free()

	match enemy_type:
		Type.SCOUT:
			speed = 220.0; max_health = 10.0; damage = 5.0
			_draw_scout()
		Type.WARRIOR:
			speed = 60.0; max_health = 80.0; damage = 20.0; scale = Vector2(1.5, 1.5)
			_draw_warrior()
		Type.NORMAL:
			_draw_normal()

	if is_elite:
		max_health *= 5; scale *= 1.5; modulate = Color(1.5, 1.2, 0)

func _draw_normal():
	# Corps elliptique rouge
	var body = Polygon2D.new()
	body.color = Color("#e05555")
	body.polygon = _ellipse_points(12, 15, 10)
	add_child(body)
	# Oreilles
	_add_ear(-8, -14, Color("#c04040"), Color("#ff9999"))
	_add_ear(8,  -14, Color("#c04040"), Color("#ff9999"))
	# Yeux
	_add_eye(-5, -8)
	_add_eye(5,  -8)
	# Museau + nez
	_add_muzzle(0, -2, Color("#e05555"))
	# Moustaches
	_add_whiskers(Color(1, 1, 1, 0.6))
	# Queue
	var tail = Line2D.new()
	tail.width = 2.5
	tail.default_color = Color("#c04040")
	tail.points = PackedVector2Array([Vector2(12, 5), Vector2(18, 5), Vector2(18, -4)])
	add_child(tail)

func _draw_scout():
	# Corps effilé cyan
	var body = Polygon2D.new()
	body.color = Color("#44aadd")
	body.polygon = _ellipse_points(9, 14, 10)
	add_child(body)
	# Oreilles pointues
	_add_ear_pointed(-6, -13, Color("#3388bb"))
	_add_ear_pointed(6,  -13, Color("#3388bb"))
	# Yeux grands
	_add_eye(-5, -7, 4.0)
	_add_eye(5,  -7, 4.0)
	# Museau
	_add_muzzle(0, -1, Color("#44aadd"))
	# Traînées vitesse
	for i in 3:
		var line = Line2D.new()
		line.width = 1.5
		line.default_color = Color(0.3, 0.8, 1.0, 0.6 - i * 0.18)
		line.points = PackedVector2Array([Vector2(-11, -5 + i*5), Vector2(-20, -5 + i*5)])
		add_child(line)

func _draw_warrior():
	# Corps hexagonal orange
	var body = Polygon2D.new()
	body.color = Color("#e08030")
	body.polygon = PackedVector2Array([
		Vector2(0,-18), Vector2(14,-9), Vector2(14,9),
		Vector2(0,18), Vector2(-14,9), Vector2(-14,-9)
	])
	add_child(body)
	# Épaulières
	var sp_l = Polygon2D.new(); sp_l.color = Color("#ffc060")
	sp_l.polygon = PackedVector2Array([Vector2(-14,-9), Vector2(-22,-4), Vector2(-18,4)])
	add_child(sp_l)
	var sp_r = Polygon2D.new(); sp_r.color = Color("#ffc060")
	sp_r.polygon = PackedVector2Array([Vector2(14,-9), Vector2(22,-4), Vector2(18,4)])
	add_child(sp_r)
	# Oreilles larges
	_add_ear(-10, -16, Color("#c06020"), Color("#ffaad4"))
	_add_ear(10,  -16, Color("#c06020"), Color("#ffaad4"))
	# Yeux rouges + sourcils froncés
	_add_eye(-6, -8, 3.5, Color("#330000"), Color("#ff4400"))
	_add_eye(6,  -8, 3.5, Color("#330000"), Color("#ff4400"))
	var brow_l = Line2D.new(); brow_l.width = 2.5; brow_l.default_color = Color("#333333")
	brow_l.points = PackedVector2Array([Vector2(-11,-13), Vector2(-2,-11)]); add_child(brow_l)
	var brow_r = Line2D.new(); brow_r.width = 2.5; brow_r.default_color = Color("#333333")
	brow_r.points = PackedVector2Array([Vector2(11,-13), Vector2(2,-11)]); add_child(brow_r)
	# Museau
	_add_muzzle(0, -2, Color("#e08030"))
	# Queue épaisse
	var tail = Line2D.new(); tail.width = 5; tail.default_color = Color("#c06020")
	tail.points = PackedVector2Array([Vector2(14,6), Vector2(20,6)]); add_child(tail)

# --- Helpers ---

func _ellipse_points(rx: float, ry: float, n: int) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in n:
		var a = TAU * i / n
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts

func _add_ear(x: float, y: float, col_outer: Color, col_inner: Color):
	var outer = Polygon2D.new(); outer.color = col_outer
	outer.polygon = PackedVector2Array([Vector2(x-5,y), Vector2(x,y-10), Vector2(x+5,y)])
	add_child(outer)
	var inner = Polygon2D.new(); inner.color = col_inner
	inner.polygon = PackedVector2Array([Vector2(x-3,y-1), Vector2(x,y-7), Vector2(x+3,y-1)])
	add_child(inner)

func _add_ear_pointed(x: float, y: float, col: Color):
	var ear = Polygon2D.new(); ear.color = col
	ear.polygon = PackedVector2Array([Vector2(x-4,y), Vector2(x,y-14), Vector2(x+4,y)])
	add_child(ear)

func _add_eye(x: float, y: float, r: float = 3.5,
		iris_col: Color = Color("#1a6600"), pupil_col: Color = Color("#111111")):
	var white = Polygon2D.new(); white.color = Color.WHITE
	white.polygon = _ellipse_points(r, r, 8); white.position = Vector2(x, y); add_child(white)
	var iris = Polygon2D.new(); iris.color = iris_col
	iris.polygon = _ellipse_points(r*0.7, r*0.7, 8); iris.position = Vector2(x, y); add_child(iris)
	var pupil = Polygon2D.new(); pupil.color = pupil_col
	pupil.polygon = _ellipse_points(r*0.42, r*0.42, 8); pupil.position = Vector2(x, y); add_child(pupil)
	var reflet = Polygon2D.new(); reflet.color = Color.WHITE
	reflet.polygon = _ellipse_points(r*0.22, r*0.22, 6)
	reflet.position = Vector2(x - r*0.25, y - r*0.25); add_child(reflet)

func _add_muzzle(x: float, y: float, base_col: Color):
	var muzzle = Polygon2D.new(); muzzle.color = base_col.lightened(0.2)
	muzzle.polygon = _ellipse_points(5, 3.5, 8); muzzle.position = Vector2(x, y); add_child(muzzle)
	var nose = Polygon2D.new(); nose.color = Color("#ff6699")
	nose.polygon = _ellipse_points(2, 1.5, 6); nose.position = Vector2(x, y - 1.5); add_child(nose)

func _add_whiskers(col: Color):
	var offsets = [[-3,-3,-18,-5],[-3,-1,-18,0],[3,-3,18,-5],[3,-1,18,0]]
	for o in offsets:
		var w = Line2D.new(); w.width = 1.0; w.default_color = col
		w.points = PackedVector2Array([Vector2(o[0],o[1]), Vector2(o[2],o[3])])
		add_child(w)

func _physics_process(delta):
	if player and is_instance_valid(player):
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		
		animation_timer += delta * 10.0
		var s = 1.0 + sin(animation_timer) * 0.1
		scale.x = s
		scale.y = 2.0 - s
		
		# Animation queue supprimée — visuels cartoon sans nœud "Tail" nommé
		move_and_slide()
		
		# DÉTECTION DES DÉGÂTS SUR LE JOUEUR
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider.is_in_group("player"):
				if collider.has_method("take_damage"):
					collider.take_damage(damage * delta)

func take_damage(amount: float):
	current_health -= amount
	modulate = Color(5, 5, 5)
	await get_tree().create_timer(0.05).timeout
	modulate = Color(1, 1, 1)
	if current_health <= 0: die()

func die():
	var gem = gem_scene.instantiate()
	get_parent().add_child(gem)
	gem.global_position = global_position
	if randf() < 0.2:
		var kibble = kibble_scene.instantiate()
		get_parent().add_child(kibble)
		kibble.global_position = global_position
	if MissionManager: MissionManager.track_stat("kill_mice", 1)
	emit_signal("died")
	queue_free()
