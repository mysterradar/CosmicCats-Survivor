extends Control

@onready var tap_label = $TapLabel

var _ready_to_go := false

func _ready():
	if SaveManager:
		SaveManager.load_game()

	modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): _ready_to_go = true)

	# Pulsation du label "appuyer"
	var pulse = create_tween().set_loops()
	pulse.tween_property(tap_label, "modulate:a", 0.2, 0.9).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(tap_label, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)

func _input(event):
	if not _ready_to_go:
		return
	if event is InputEventScreenTouch and event.pressed:
		_go()
	elif event is InputEventMouseButton and event.pressed:
		_go()

func _go():
	_ready_to_go = false
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
