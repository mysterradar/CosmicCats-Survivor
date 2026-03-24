extends Area2D

@export var speed: float = 400.0
@export var damage: float = 25.0
@export var turn_speed: float = 5.0 # Vitesse de rotation pour le guidage

var target: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var _cluster: bool = false

func _ready():
	# Au lancement, le missile va un peu vers le haut avant de chercher sa cible
	velocity = Vector2.UP.rotated(randf_range(-0.5, 0.5)) * speed

	if SaveManager:
		_cluster = SaveManager.data["perm_upgrades"].get("missile_cluster", 0) > 0

func _physics_process(delta):
	if is_instance_valid(target):
		# Calcul de la direction vers l'ennemi
		var target_dir = (target.global_position - global_position).normalized()
		var current_dir = velocity.normalized()
		
		# Rotation progressive vers la cible (Guidage)
		var new_dir = current_dir.lerp(target_dir, turn_speed * delta).normalized()
		velocity = new_dir * speed
		look_at(global_position + velocity)
	
	global_position += velocity * delta

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		explode()

func explode():
	if _cluster:
		var scene = get_tree().current_scene
		var base_dir = velocity.normalized() if velocity != Vector2.ZERO else Vector2.UP
		for angle_deg in [-30, 30]:
			var mini = load("res://scenes/SardineMissile.tscn").instantiate()
			mini._cluster = false          # pas de récursion
			scene.add_child(mini)
			mini.global_position = global_position
			mini.velocity = base_dir.rotated(deg_to_rad(angle_deg)) * speed
			# TTL : détruire le mini-missile après 2s
			var ttl = mini.get_tree().create_timer(2.0)
			ttl.timeout.connect(func(): if is_instance_valid(mini): mini.queue_free())
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
