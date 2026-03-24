extends Control

@onready var mission_list = $Panel/VBoxContainer/ScrollContainer/MissionList

func _ready():
	visible = false
	if MissionManager:
		MissionManager.mission_updated.connect(refresh_list)

func open():
	visible = true
	refresh_list()

func refresh_list():
	for child in mission_list.get_children():
		child.queue_free()
	
	if not MissionManager: return
	
	for m in MissionManager.missions:
		var h_box = HBoxContainer.new()
		h_box.custom_minimum_size = Vector2(0, 100)
		
		var v_box = VBoxContainer.new()
		v_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var title_lbl = Label.new()
		var completions = m.get("completions", 0)
		if completions > 0:
			title_lbl.text = "%s (x%d)" % [m.title, completions]
		else:
			title_lbl.text = m.title
		title_lbl.add_theme_font_size_override("font_size", 22)
		
		var progress_lbl = Label.new()
		var desc_formatted = m.desc % m.goal if "%d" in m.desc else m.desc
		progress_lbl.text = "%s (%d/%d)" % [desc_formatted, m.progress, m.goal]
		progress_lbl.modulate = Color(0.7, 0.7, 0.7)
		
		var prog_bar = ProgressBar.new()
		prog_bar.min_value = 0
		prog_bar.max_value = m.goal
		prog_bar.value = m.progress
		prog_bar.custom_minimum_size = Vector2(0, 10)
		prog_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		v_box.add_child(title_lbl)
		v_box.add_child(progress_lbl)
		v_box.add_child(prog_bar)
		
		var action_btn = Button.new()
		action_btn.custom_minimum_size = Vector2(150, 50)
		action_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		if m.claimed:
			action_btn.text = "REÇU"
			action_btn.disabled = true
		elif m.progress >= m.goal:
			action_btn.text = "RÉCUPÉRER"
			action_btn.modulate = Color(0, 1, 0)
			action_btn.pressed.connect(_on_claim_pressed.bind(m.id))
		else:
			action_btn.text = "EN COURS"
			action_btn.disabled = true
			
		h_box.add_child(v_box)
		h_box.add_child(action_btn)
		mission_list.add_child(h_box)

func _on_claim_pressed(mission_id):
	if MissionManager.claim_reward(mission_id):
		# Petit son ou effet ici ?
		refresh_list()

func _on_back_button_pressed():
	visible = false
