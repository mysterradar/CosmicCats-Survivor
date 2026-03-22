extends Area2D

@export var xp_amount: int = 10
@export var attract_speed: float = 800.0
var player = null
var attracted: bool = false   # état d'aspiration courant

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if not player: return
	var dist = global_position.distance_to(player.global_position)
	var should_attract = dist < 200 or bool(player.get("has_vacuum"))

	# Guard bidirectionnel : ne set emitting que si l'état change
	if should_attract != attracted:
		attracted = should_attract
		$Trail.emitting = attracted

	if attracted:
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * attract_speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("add_xp"):
			body.add_xp(xp_amount)
		$Trail.emitting = false
		# Flash de collecte : scale bounce puis disparition
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.06)
		tween.tween_callback(queue_free)
