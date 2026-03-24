extends Area2D

@export var rotation_speed: float = 5.0
@export var damage: float = 20.0
var player = null

func _ready():
	player = get_tree().get_first_node_in_group("player")
	var overcharge_level = 0
	if SaveManager:
		overcharge_level = SaveManager.data["perm_upgrades"].get("plasma_overcharge", 0)
	var target_scale = 1.0 + overcharge_level * 0.50
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(target_scale, target_scale), 0.5)

func _process(delta):
	# La lame tourne sur elle-même
	rotation += rotation_speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			# On multiplie par le bonus du joueur si dispo
			var final_dmg = damage
			if player: final_dmg *= player.damage_mult
			body.take_damage(final_dmg)
