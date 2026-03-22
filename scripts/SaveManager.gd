extends Node

const SAVE_PATH = "user://cosmic_save.json"

var data = {
	"high_score": 0,
	"cosmic_kibble": 0,
	"unlocked_level": 1,
	"is_ad_free": false,
	"perm_upgrades": {
		"health_bonus": 0,
		"damage_bonus": 0,
		"speed_bonus": 0,
		"fire_rate_bonus": 0,
		"shield_bonus": 0,
		"xp_radius_bonus": 0
	},
	"stats": {
		"kills": 0,
		"games_played": 0,
		"best_score": 0,
		"play_time": 0.0
	}
}

func _ready():
	load_game()

func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_game():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			var parse_result = JSON.parse_string(json_string)
			if parse_result is Dictionary:
				# On fusionne pour éviter les clés manquantes
				for key in parse_result.keys():
					data[key] = parse_result[key]
				# Cas particulier du renommage cheese -> kibble
				if parse_result.has("cosmic_cheese"):
					data["cosmic_kibble"] = parse_result["cosmic_cheese"]
				# Migration récursive perm_upgrades
				var default_pu = {
					"health_bonus":0,"damage_bonus":0,"speed_bonus":0,
					"fire_rate_bonus":0,"shield_bonus":0,"xp_radius_bonus":0
				}
				if not data.has("perm_upgrades"):
					data["perm_upgrades"] = default_pu
				else:
					for k in default_pu:
						if not data["perm_upgrades"].has(k):
							data["perm_upgrades"][k] = default_pu[k]
				# Migration stats
				var default_stats = {"kills":0,"games_played":0,"best_score":0,"play_time":0.0}
				if not data.has("stats"):
					data["stats"] = default_stats
				else:
					for k in default_stats:
						if not data["stats"].has(k):
							data["stats"][k] = default_stats[k]
	else:
		save_game()

func add_kibble(amount: int):
	data["cosmic_kibble"] = data.get("cosmic_kibble", 0) + amount
	save_game()

func unlock_next_level(level_id: int):
	if level_id > data["unlocked_level"]:
		data["unlocked_level"] = level_id
		save_game()
