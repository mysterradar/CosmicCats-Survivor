extends Node2D

## large = true → grosse explosion (boss), false → débris (ennemi normal)
@export var large: bool = false

static var _tex_large: Texture2D = null
static var _tex_small: Texture2D = null

func _ready():
	if not _tex_large:
		_tex_large = load("res://assets/sprites/fx_explosion.png")
	if not _tex_small:
		_tex_small = load("res://assets/sprites/fx_debris.png")

	var sprite: Sprite2D = $Sprite
	sprite.texture = _tex_large if large else _tex_small
	sprite.scale   = Vector2(0.28, 0.28) if large else Vector2(0.18, 0.18)
	sprite.modulate.a = 1.0

	$Sparks.emitting = true

	# Animation : scale up puis fade out
	var tween = create_tween()
	var target_scale = sprite.scale * (1.6 if large else 1.4)
	tween.tween_property(sprite, "scale", target_scale, 0.25).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.35)
	tween.tween_callback(queue_free)
