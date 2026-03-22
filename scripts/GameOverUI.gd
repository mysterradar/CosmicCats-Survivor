extends Control

@onready var title_label = $Panel/VBoxContainer/Title
@onready var score_label = $Panel/VBoxContainer/FinalScore
@onready var rewards_label = $Panel/VBoxContainer/RewardsLabel
@onready var restart_button = $Panel/VBoxContainer/RestartButton
@onready var ad_button = $Panel/VBoxContainer/AdDoubleButton

var current_total_earned = 0

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.text = "RETOUR AU MENU"

func open(is_victory: bool, score: int, player_kibble: int = 0):
	get_tree().paused = true
	visible = true
	
	current_total_earned = player_kibble
	
	if is_victory:
		title_label.text = "VICTOIRE COSMIQUE !"
		title_label.modulate = Color(0, 1, 0.5)
		if GlobalManager:
			current_total_earned += GlobalManager.get_level_reward()
			SaveManager.unlock_next_level(GlobalManager.current_selected_level + 1)
	else:
		title_label.text = "CHAT-TASTROPHE..."
		title_label.modulate = Color(1, 0.2, 0.2)
		current_total_earned += int(float(score) / 10.0)
	
	SaveManager.add_kibble(current_total_earned)
	rewards_label.text = "Butin total : +%d Croquettes" % current_total_earned
	score_label.text = "Score de la partie : %d" % score
	
	# Le bouton de pub est actif si le No Ads n'est pas acheté
	ad_button.visible = !SaveManager.data.is_ad_free
	ad_button.disabled = false

func _on_ad_double_button_pressed():
	# Simulation du visionnage d'une pub
	ad_button.disabled = true
	print("Simulation : Visionnage pub en cours...")
	
	# Après la pub (simulée ici par un timer)
	await get_tree().create_timer(1.0).timeout
	
	# On ajoute une deuxième fois le gain
	SaveManager.add_kibble(current_total_earned)
	current_total_earned *= 2
	rewards_label.text = "BUTIN DOUBLÉ : +%d Croquettes !" % current_total_earned
	rewards_label.modulate = Color(1, 1, 0) # Jaune brillant

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
