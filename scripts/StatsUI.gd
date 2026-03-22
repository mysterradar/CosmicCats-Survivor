extends Control

func _ready():
	visible = false

func open():
	visible = true
	_refresh()

func _refresh():
	if not SaveManager or not SaveManager.data: return
	var s = SaveManager.data.get("stats", {})
	var pt = s.get("play_time", 0.0)
	$Panel/VBox/KillsLabel.text    = "🗡️ Kills totaux : %d"    % s.get("kills", 0)
	$Panel/VBox/GamesLabel.text    = "🎮 Parties jouées : %d"  % s.get("games_played", 0)
	$Panel/VBox/ScoreLabel.text    = "🏅 Meilleur score : %d"  % s.get("best_score", 0)
	$Panel/VBox/TimeLabel.text     = "⏱️ Temps de jeu : %dh%02dm" % [int(pt / 3600), int(fmod(pt, 3600) / 60)]

func _on_close_pressed():
	visible = false
