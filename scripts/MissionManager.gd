extends Node

signal mission_updated

var missions = [
	{"id":"kill_mice",     "title":"Chasseur de Souris",    "desc":"Tuer %d souris",                "goal":50,    "progress":0, "reward":500,  "claimed":false, "completions":0},
	{"id":"collect_kibble","title":"Gros Appétit",          "desc":"Ramasser %d croquettes",        "goal":100,   "progress":0, "reward":800,  "claimed":false, "completions":0},
	{"id":"reach_wave",    "title":"Surfeur de Vagues",     "desc":"Atteindre la vague %d",         "goal":5,     "progress":0, "reward":1000, "claimed":false, "completions":0},
	{"id":"kill_elites",   "title":"Chasseur d'Élites",     "desc":"Vaincre %d ennemis élites",     "goal":10,    "progress":0, "reward":1200, "claimed":false, "completions":0},
	{"id":"deal_damage",   "title":"Dégâts Massifs",        "desc":"Infliger %d dégâts",            "goal":10000, "progress":0, "reward":600,  "claimed":false, "completions":0},
	{"id":"collect_fur",   "title":"Collectionneur",        "desc":"Ramasser %d Poils Cosmiques",   "goal":20,    "progress":0, "reward":700,  "claimed":false, "completions":0},
	{"id":"use_shield",    "title":"Bouclier Solide",       "desc":"Bloquer %d coups avec le bouclier","goal":20, "progress":0, "reward":900,  "claimed":false, "completions":0},
	{"id":"boss_kill",     "title":"Exterminateur",         "desc":"Vaincre %d boss",               "goal":3,     "progress":0, "reward":2000, "claimed":false, "completions":0},
]

func _ready():
	load_missions()

func track_stat(id: String, amount: int = 1, mode: String = "add"):
	for m in missions:
		if m.id == id and not m.claimed:
			if mode == "max":
				m.progress = max(m.progress, amount)
			else:
				m.progress = min(m.goal, m.progress + amount)
			emit_signal("mission_updated")
			save_missions()

func claim_reward(mission_id: String):
	for m in missions:
		if m.id == mission_id and m.progress >= m.goal and not m.claimed:
			if SaveManager:
				SaveManager.add_kibble(m.reward)
			# Renouvellement : objectif et récompense croissants
			# m.claimed reste false — c'est m.progress >= m.goal qui gate le bouton "RÉCUPÉRER"
			# Le reset immédiat empêche le double-claim car progress retombe à 0
			m.completions = m.get("completions", 0) + 1
			m.progress    = 0
			m.goal        = int(m.goal * 1.5)
			m.reward      = int(m.reward * 1.4)
			m.claimed     = false
			emit_signal("mission_updated")
			save_missions()
			return true
	return false

func save_missions():
	var file = FileAccess.open("user://missions.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(missions))

func load_missions():
	if FileAccess.file_exists("user://missions.json"):
		var file = FileAccess.open("user://missions.json", FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if data is Array:
				var expected_ids = missions.map(func(m): return m.id)
				var loaded_ids   = data.map(func(m): return m.get("id", ""))
				if loaded_ids == expected_ids:
					# Structure valide : restaurer progress/goal/reward/completions
					for i in data.size():
						missions[i]["progress"]   = data[i].get("progress", 0)
						missions[i]["claimed"]    = data[i].get("claimed", false)
						missions[i]["goal"]       = data[i].get("goal", missions[i]["goal"])
						missions[i]["reward"]     = data[i].get("reward", missions[i]["reward"])
						missions[i]["completions"]= data[i].get("completions", 0)
				# Sinon (ancienne structure / IDs différents) : garder les defaults
