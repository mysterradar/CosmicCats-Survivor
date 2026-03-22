extends Node2D

var stars = []
var nebulae = []
var asteroids = []
var redraw_timer: float = 0.0
const REDRAW_INTERVAL = 0.05  # 20 fps pour les étoiles

func setup(screen_size: Vector2, base_color: Color):
	stars.clear()
	# 150 étoiles
	for i in 150:
		stars.append({
			"pos": Vector2(randf_range(0, screen_size.x), randf_range(0, screen_size.y)),
			"size": randf_range(1.0, 3.0),
			"phase": randf_range(0.0, TAU),
			"speed": randf_range(0.5, 2.0)
		})

	# 3 nébuleuses
	for i in 3:
		var neb = Polygon2D.new()
		neb.color = Color.from_hsv(
			fmod(base_color.h + i * 0.15, 1.0), 0.5, 0.6, 0.12
		)
		neb.polygon = _blob_polygon(
			Vector2(randf_range(100, screen_size.x - 100),
					randf_range(100, screen_size.y - 100)),
			randf_range(80, 160), 10
		)
		neb.z_index = -1
		add_child(neb)
		nebulae.append(neb)

	# 4 astéroïdes
	for i in 4:
		var ast = Polygon2D.new()
		ast.color = Color(0.3, 0.28, 0.25, 0.8)
		ast.polygon = _rock_polygon(randf_range(12, 28), 8)
		ast.position = Vector2(randf_range(0, screen_size.x),
							   randf_range(0, screen_size.y))
		ast.z_index = -1
		add_child(ast)
		asteroids.append({"node": ast, "drift": Vector2(randf_range(-20, 20), randf_range(-8, 8))})

	queue_redraw()

func _process(delta):
	redraw_timer += delta
	if redraw_timer >= REDRAW_INTERVAL:
		redraw_timer = 0.0
		for s in stars:
			s["phase"] += s["speed"] * delta
		queue_redraw()
	# Dérive des astéroïdes
	var sz = get_viewport_rect().size
	for a in asteroids:
		a["node"].position += a["drift"] * delta
		if a["node"].position.x > sz.x + 40: a["node"].position.x = -40
		elif a["node"].position.x < -40: a["node"].position.x = sz.x + 40

func _draw():
	for s in stars:
		var alpha = 0.3 + 0.7 * (0.5 + 0.5 * sin(s["phase"]))
		draw_circle(s["pos"], s["size"], Color(1, 1, 1, alpha))

func _blob_polygon(center: Vector2, radius: float, n: int) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in n:
		var a = TAU * i / n
		var r = radius * randf_range(0.6, 1.4)
		pts.append(center + Vector2(cos(a) * r, sin(a) * r))
	return pts

func _rock_polygon(radius: float, n: int) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in n:
		var a = TAU * i / n
		var r = radius * randf_range(0.7, 1.3)
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	return pts
