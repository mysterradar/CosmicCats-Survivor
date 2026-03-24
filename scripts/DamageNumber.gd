extends Marker2D

func setup(amount: float, is_critical: bool = false):
	var lbl = Label.new()
	lbl.text = str(int(amount))
	lbl.add_theme_font_size_override("font_size", 24 if not is_critical else 40)
	lbl.modulate = Color(1, 1, 1) if not is_critical else Color(1, 1, 0)
	add_child(lbl)
	
	var tween = create_tween().set_parallel(true)
	# Monte et disparait
	tween.tween_property(self, "position:y", position.y - 100, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	await tween.finished
	queue_free()
