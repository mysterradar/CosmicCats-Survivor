extends Node

# ─── Catalogue ───────────────────────────────────────────────
# TODO: remplacer cat_stage1/2/3.png par des sprites individuels par chat
const CATS = {
	"minou_cosmique": {
		"name": "Minou Cosmique", "rarity": "COMMON", "unlock_cost": 0,
		"description": "Le chat de base. Fiable et courageux.",
		"sprite_menu": "res://assets/sprites/cats/minou_menu.png",
		"sprite_stage": [
			"res://assets/sprites/cats/minou_carousel.png",
			"res://assets/sprites/cats/minou_carousel.png",
			"res://assets/sprites/cats/minou_carousel.png",
		],
		"passive_id": "bonus_bullet",
		"damage_per_level": 0.02, "speed_per_level": 0.01, "fire_rate_per_level": 0.015,
	},
	"felix_furieux": {
		"name": "Félix Furieux", "rarity": "COMMON", "unlock_cost": 0,
		"description": "Encore plus fort quand il est blessé.",
		"sprite_menu": "res://assets/sprites/cats/felix_menu.png",
		"sprite_stage": [
			"res://assets/sprites/cats/felix_carousel.png",
			"res://assets/sprites/cats/felix_carousel.png",
			"res://assets/sprites/cats/felix_carousel.png",
		],
		"passive_id": "low_hp_rage",
		"damage_per_level": 0.025, "speed_per_level": 0.008, "fire_rate_per_level": 0.010,
	},
	"comete": {
		"name": "Comète", "rarity": "RARE", "unlock_cost": 500,
		"description": "Laisse une traînée de feu dans son sillage.",
		"sprite_menu": "res://assets/sprites/cats/comete_menu.png",
		"sprite_stage": [
			"res://assets/sprites/cats/comete_carousel.png",
			"res://assets/sprites/cats/comete_carousel.png",
			"res://assets/sprites/cats/comete_carousel.png",
		],
		"passive_id": "fire_trail",
		"damage_per_level": 0.018, "speed_per_level": 0.015, "fire_rate_per_level": 0.012,
	},
	"capitaine_sardine": {
		"name": "Capitaine Sardine", "rarity": "RARE", "unlock_cost": 500,
		"description": "Lance des missiles sardines automatiquement.",
		"sprite_menu": "res://assets/sprites/cats/capitaine_menu.png",
		"sprite_stage": [
			"res://assets/sprites/cats/capitaine_carousel.png",
			"res://assets/sprites/cats/capitaine_carousel.png",
			"res://assets/sprites/cats/capitaine_carousel.png",
		],
		"passive_id": "auto_missile",
		"damage_per_level": 0.015, "speed_per_level": 0.008, "fire_rate_per_level": 0.020,
	},
	"zero_gravite": {
		"name": "Zéro Gravité", "rarity": "LEGENDARY", "unlock_cost": 2000,
		"description": "Son bouclier se régénère deux fois plus vite.",
		"sprite_menu": "res://assets/sprites/cats/zero_menu.png",
		"sprite_stage": [
			"res://assets/sprites/cats/zero_carousel.png",
			"res://assets/sprites/cats/zero_carousel.png",
			"res://assets/sprites/cats/zero_carousel.png",
		],
		"passive_id": "fast_shield",
		"damage_per_level": 0.015, "speed_per_level": 0.010, "fire_rate_per_level": 0.015,
	},
	"nebula": {
		"name": "Nébula", "rarity": "LEGENDARY", "unlock_cost": 2000,
		"description": "Chaque ennemi vaincu explose.",
		"sprite_menu": "res://assets/sprites/cats/nebula_menu.png",
		"sprite_stage": [
			"res://assets/sprites/cats/nebula_carousel.png",
			"res://assets/sprites/cats/nebula_carousel.png",
			"res://assets/sprites/cats/nebula_carousel.png",
		],
		"passive_id": "kill_explosion",
		"damage_per_level": 0.020, "speed_per_level": 0.008, "fire_rate_per_level": 0.012,
	},
	"astro": {
		"name": "Astro", "rarity": "LEGENDARY", "unlock_cost": 2000,
		"description": "Gagne 50% d'XP en plus sur son chat pilote.",
		"sprite_menu": "res://assets/sprites/cats/astro_menu.png",
		"sprite_stage": [
			"res://assets/sprites/cats/astro_carousel.png",
			"res://assets/sprites/cats/astro_carousel.png",
			"res://assets/sprites/cats/astro_carousel.png",
		],
		"passive_id": "xp_boost",
		"damage_per_level": 0.015, "speed_per_level": 0.012, "fire_rate_per_level": 0.015,
	},
}

const XP_PER_LEVEL_BASE := 20.0
const XP_GROWTH := 1.2
const STAGE2_LEVEL := 11
const STAGE3_LEVEL := 21
const STAGE2_FUR   := 50
const STAGE3_FUR   := 150

var _xp_multiplier: float = 1.0
var _passive_amp: float   = 0.0   # bonus passive_amp du shop (0.0–0.25)

# ─── Interface publique ───────────────────────────────────────

func get_active_cat_id() -> String:
	if SaveManager: return SaveManager.data.get("active_cat", "minou_cosmique")
	return "minou_cosmique"

func get_active_cat_data() -> Dictionary:
	return CATS.get(get_active_cat_id(), CATS["minou_cosmique"])

func get_cat_save(cat_id: String) -> Dictionary:
	if SaveManager: return SaveManager.data["cats"].get(cat_id, {})
	return {}

func get_cat_level(cat_id: String) -> int:
	return get_cat_save(cat_id).get("level", 1)

func get_cat_stage(cat_id: String) -> int:
	return get_cat_save(cat_id).get("stage", 1)

func get_cat_xp(cat_id: String) -> int:
	return get_cat_save(cat_id).get("xp", 0)

func xp_needed_for_level(level: int) -> int:
	return int(XP_PER_LEVEL_BASE * pow(XP_GROWTH, level - 1))

func can_evolve(cat_id: String) -> bool:
	if not CATS.has(cat_id): return false
	var save = get_cat_save(cat_id)
	var level = save.get("level", 1)
	var stage = save.get("stage", 1)
	var fur   = SaveManager.data.get("cosmic_fur", 0) if SaveManager else 0
	if stage == 1 and level >= STAGE2_LEVEL and fur >= STAGE2_FUR: return true
	if stage == 2 and level >= STAGE3_LEVEL and fur >= STAGE3_FUR: return true
	return false

func evolve_cat(cat_id: String):
	if not can_evolve(cat_id): return
	if not SaveManager.data["cats"].has(cat_id): return
	var save  = SaveManager.data["cats"][cat_id]
	var stage = save["stage"]
	if stage == 1: SaveManager.data["cosmic_fur"] -= STAGE2_FUR; save["stage"] = 2
	elif stage == 2: SaveManager.data["cosmic_fur"] -= STAGE3_FUR; save["stage"] = 3
	SaveManager.save_game()

func unlock_cat(cat_id: String):
	if not CATS.has(cat_id): return
	var cost = CATS[cat_id]["unlock_cost"]
	if cost <= 0:
		if not SaveManager.data["cats"].has(cat_id): return
		SaveManager.data["cats"][cat_id]["unlocked"] = true
		SaveManager.save_game()
		return
	var kibble = SaveManager.data.get("cosmic_kibble", 0)
	if kibble < cost: return
	SaveManager.data["cosmic_kibble"] -= cost
	if not SaveManager.data["cats"].has(cat_id): return
	SaveManager.data["cats"][cat_id]["unlocked"] = true
	SaveManager.save_game()

func set_active_cat(cat_id: String):
	if not SaveManager: return
	if not SaveManager.data["cats"].get(cat_id, {}).get("unlocked", false): return
	SaveManager.data["active_cat"] = cat_id
	SaveManager.save_game()

func add_xp(base_amount: int):
	var amount = int(base_amount * _xp_multiplier)
	var cat_id = get_active_cat_id()
	if not SaveManager or not SaveManager.data["cats"].has(cat_id): return
	var save = SaveManager.data["cats"][cat_id]
	save["xp"] += amount
	# Level up loop
	var needed = xp_needed_for_level(save["level"])
	while save["xp"] >= needed and save["level"] < 30:
		save["xp"]   -= needed
		save["level"] += 1
		needed = xp_needed_for_level(save["level"])
	if save["level"] >= 30:
		save["xp"] = 0
	SaveManager.save_game()

func add_cosmic_fur(amount: int):
	if not SaveManager: return
	var mult = 1.0 + SaveManager.data.get("perm_upgrades", {}).get("fur_drop", 0) * 0.10
	SaveManager.data["cosmic_fur"] += int(amount * mult)
	if MissionManager: MissionManager.track_stat("collect_fur", int(amount * mult))
	SaveManager.save_game()

func get_active_bonuses() -> Dictionary:
	var cat  = get_active_cat_data()
	var lv   = get_cat_level(get_active_cat_id())
	var amp  = 1.0 + _passive_amp
	return {
		"damage_mult":    cat["damage_per_level"]    * lv * amp,
		"speed_bonus":    cat["speed_per_level"]     * lv * amp * 50.0,
		"fire_rate_mult": cat["fire_rate_per_level"] * lv * amp,
	}

func apply_passive(player: Node):
	var cat    = get_active_cat_data()
	var amp    = _passive_amp
	match cat["passive_id"]:
		"bonus_bullet":
			var t = Timer.new(); t.name = "PassiveTimer"
			t.wait_time = max(0.5, 5.0 * (1.0 - amp)); t.autostart = true
			player.add_child(t)
			t.timeout.connect(func(): if is_instance_valid(player): player.shoot())
		"low_hp_rage":
			pass  # géré dans Player.take_damage() via CatManager.get_active_cat_data()
		"fire_trail":
			var t = Timer.new(); t.name = "PassiveTimer"
			t.wait_time = max(0.05, 0.1 * (1.0 - amp)); t.autostart = true
			player.add_child(t)
			t.timeout.connect(func():
				if not is_instance_valid(player): return
				var line = Line2D.new()
				line.add_point(Vector2.ZERO); line.add_point(Vector2(0, 20))
				line.default_color = Color(1.0, 0.4, 0.0, 0.7)
				line.width = 6.0
				player.get_tree().current_scene.add_child(line)
				line.global_position = player.global_position
				var tw = line.create_tween()
				tw.tween_property(line, "modulate:a", 0.0, 0.4)
				tw.finished.connect(line.queue_free)
			)
		"auto_missile":
			var t = Timer.new(); t.name = "PassiveTimer"
			t.wait_time = max(0.5, 3.0 * (1.0 - amp)); t.autostart = true
			player.add_child(t)
			t.timeout.connect(func():
				if not is_instance_valid(player): return
				var enemies = player.get_tree().get_nodes_in_group("enemies")
				if enemies.size() > 0: player.shoot_missile(enemies)
			)
		"fast_shield":
			player.shield_cooldown = max(1.0, player.shield_cooldown * (0.5 - amp))
		"kill_explosion":
			pass  # connecté dans GameScene._on_enemy_died()
		"xp_boost":
			_xp_multiplier = 1.5 + amp * 0.25

func reset_session():
	_xp_multiplier = 1.0
	# Lire passive_amp depuis les upgrades permanentes
	if SaveManager:
		_passive_amp = SaveManager.data["perm_upgrades"].get("passive_amp", 0) * 0.05
