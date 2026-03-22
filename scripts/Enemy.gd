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
var explosion_scene = preload("res://scenes/ExplosionEffect.tscn")
var animation_timer = 0.0

static var _textures: Array = []

func _ready():
	player = get_tree().get_first_node_in_group("player")
	animation_timer = randf() * 2.0
	setup_mouse_visual()
	current_health = max_health

func setup_mouse_visual():
	for child in get_children():
		if child is Polygon2D or child is Line2D or child is Sprite2D:
			child.queue_free()

	if _textures.is_empty():
		_textures = [
			load("res://assets/sprites/enemy_scout.png"),
			load("res://assets/sprites/enemy_artillery.png"),
			load("res://assets/sprites/enemy_cruiser.png"),
			load("res://assets/sprites/enemy_dreadnought.png"),
		]

	match enemy_type:
		Type.SCOUT:
			speed = 220.0; max_health = 10.0; damage = 5.0
			_add_sprite(_textures[0], Vector2(0.18, 0.18))
		Type.NORMAL:
			_add_sprite(_textures[1], Vector2(0.20, 0.20))
		Type.WARRIOR:
			speed = 60.0; max_health = 80.0; damage = 20.0
			_add_sprite(_textures[2], Vector2(0.22, 0.22))

	if is_elite:
		max_health *= 5; scale *= 1.5; modulate = Color(1.5, 1.2, 0)

func _add_sprite(tex: Texture2D, sc: Vector2):
	var s = Sprite2D.new()
	s.texture = tex
	s.scale = sc
	add_child(s)

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
	# Explosion de débris
	var expl = explosion_scene.instantiate()
	expl.large = false
	get_parent().add_child(expl)
	expl.global_position = global_position

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
