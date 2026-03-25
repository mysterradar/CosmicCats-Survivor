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
	},
	"cats":       {},   # rempli par migration
	"cosmic_fur": 0,
	"active_cat": "minou_cosmique",
}

func _default_cats_data() -> Dictionary:
	return {
		"minou_cosmique":    { "unlocked": true,  "xp": 0, "level": 1, "stage": 1 },
		"felix_furieux":     { "unlocked": true,  "xp": 0, "level": 1, "stage": 1 },
		"comete":            { "unlocked": false, "xp": 0, "level": 1, "stage": 1 },
		"capitaine_sardine": { "unlocked": false, "xp": 0, "level": 1, "stage": 1 },
		"zero_gravite":      { "unlocked": false, "xp": 0, "level": 1, "stage": 1 },
		"nebula":            { "unlocked": false, "xp": 0, "level": 1, "stage": 1 },
		"astro":             { "unlocked": false, "xp": 0, "level": 1, "stage": 1 },
	}

func _ready():
	load_game()

func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_game():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			var parse_result = JSON.parse_string(json_string)
			if parse_result is Dictionary:
				# Fusion top-level (écrase les sous-dicts — la migration ci-dessous DOIT rester après)
				for key in parse_result.keys():
					data[key] = parse_result[key]
				# Cas particulier du renommage cheese -> kibble
				if parse_result.has("cosmic_cheese"):
					data["cosmic_kibble"] = parse_result["cosmic_cheese"]
				file.close()
				# ⚠️ Migration APRÈS la fusion : patch les clés manquantes dans les sous-dicts
				# Ne PAS déplacer ces blocs avant la boucle de fusion ci-dessus.
				for k in data["perm_upgrades"]:
					if not data["perm_upgrades"].has(k):
						data["perm_upgrades"][k] = 0
				for k in ["health_bonus","damage_bonus","speed_bonus","fire_rate_bonus","shield_bonus","xp_radius_bonus"]:
					if not data["perm_upgrades"].has(k):
						data["perm_upgrades"][k] = 0
				if not data.has("stats"):
					data["stats"] = {"kills":0,"games_played":0,"best_score":0,"play_time":0.0}
				else:
					for k in ["kills","games_played","best_score"]:
						if not data["stats"].has(k): data["stats"][k] = 0
					if not data["stats"].has("play_time"):
						data["stats"]["play_time"] = 0.0
					else:
						data["stats"]["play_time"] = float(data["stats"]["play_time"])
				# Migration v0.5 — chats pilotes
				if not (data.get("cats") is Dictionary) or data["cats"].is_empty():
					data["cats"] = _default_cats_data()
				else:
					# Ajouter les nouveaux chats manquants
					var defaults := _default_cats_data()
					for cat_id in defaults:
						if not data["cats"].has(cat_id):
							data["cats"][cat_id] = defaults[cat_id]
				if not data.has("cosmic_fur"):  data["cosmic_fur"] = 0
				if not data.has("active_cat") or not data["cats"].has(data["active_cat"]):
					data["active_cat"] = "minou_cosmique"
				# Migration wave_reached
				if not data["stats"].has("wave_reached"): data["stats"]["wave_reached"] = 0
				# Migration nouvelles upgrades shop
				for k in ["piercing_bullet","missile_cluster","plasma_overcharge",
						  "xp_boost_perm","fur_drop","passive_amp",
						  "hull_reinforcement","engine_boost","weapon_slot"]:
					if not data["perm_upgrades"].has(k): data["perm_upgrades"][k] = 0
	else:
		save_game()

func add_kibble(amount: int):
	data["cosmic_kibble"] = data.get("cosmic_kibble", 0) + amount
	save_game()

func unlock_next_level(level_id: int):
	if level_id > data["unlocked_level"]:
		data["unlocked_level"] = level_id
		save_game()
