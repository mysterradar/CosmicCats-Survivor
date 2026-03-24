extends Area2D

@export var speed: float = 700.0
@export var damage: float = 10.0
var direction: Vector2 = Vector2.ZERO
var target: Node2D = null
var initialized = false
var pierce_remaining: int = 0

func _ready():
	if SaveManager:
		pierce_remaining = SaveManager.data["perm_upgrades"].get("piercing_bullet", 0)

func _physics_process(delta):
	if not initialized:
		if is_instance_valid(target):
			direction = (target.global_position - global_position).normalized()
			look_at(target.global_position)
			initialized = true
		else:
			# Si pas de cible après un court instant, on détruit la balle
			return

	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		if pierce_remaining > 0:
			pierce_remaining -= 1   # traverse cet ennemi, continue
		else:
			queue_free()            # détruit au prochain ennemi (ou immédiatement si pas de piercing)

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
