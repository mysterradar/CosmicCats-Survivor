# 📊 Journal de Bord : Cosmic Cats vs Alien Mice

**Concept :** Action Roguelike / Survivor mobile. Le joueur incarne un chat cosmique qui évolue en combattant des vagues de souris aliens avant d'affronter le Boss final "Le Grand Gruyère".

**Référence visuelle :** `C:\Projet perso\Muse\extracted` (cell-survivor.apk)

---

## ✅ État Actuel (v0.6 — Mars 2026)

### 🎮 Gameplay
- **Déplacement** : Joystick Dynamique et Invisible (n'importe où sur l'écran).
- **Combat** : Tir auto, Sardines-Missiles, Lame de Plasma (Compétence), Sardines Orbitantes.
- **Défense** : Bouclier d'Énergie (1 coup / 10s).
- **Progression Roguelike** :
    - Système de "Croquettes Cosmiques" (Monnaie).
    - Menu de sélection de niveaux (Niveaux 1 à 10).
    - Sauvegarde persistante des récompenses et niveaux.
    - **Aspirateur Cosmique** : Compétence pour attirer tout l'XP.

### 👾 Ennemis & Boss
- **Horde** : Souris aliens (sprites enemy_scout/artillery/cruiser) avec Squash & Stretch.
- **Difficulté** : PV des monstres +40% toutes les 30 secondes.
- **Boss Final** : "Le Grand Gruyère" — planète militaire procédurale, 3 phases.

### 🛍️ ShopUI — Upgrades Armes Connectées au Gameplay (v0.6)
- ✅ **Piercing Bullet** : balles traversent N ennemis (Bullet.gd)
- ✅ **Missile Cluster** : missiles se séparent en 2 mini-missiles à ±30° avec TTL (SardineMissile.gd)
- ✅ **Plasma Overcharge** : PlasmaBlade scale dynamique selon niveau upgrade (PlasmaBlade.gd)

### 🐱 CatPilotUI — Système XP (v0.6)
- ✅ Chaque carte chat affiche ProgressBar XP + label "XP : X / Y"
- ✅ Guard level 30 → affiche "XP : MAX" en doré
- ✅ Progression visuelle claire du niveau d'upgrade

### 📋 MissionUI — 8 Missions Renouvelables (v0.6)
- ✅ **8 missions** : kill_mice, collect_kibble, reach_wave, kill_elites, deal_damage, collect_fur, use_shield, boss_kill
- ✅ **Renouvellement automatique** : objectif ×1.5, récompense ×1.4 au claim
- ✅ ProgressBar par mission + compteur (xN)

### 🚀 Vaisseaux
- 3 tiers actifs (ship_t1 → ship_t3) débloqués par niveau joueur (lv 1/5/10/15).
- ship_t2 : nouveau sprite portrait centré, nettoyé, scale 0.40.

### 🖼️ Interface & Visuels
- ✅ **MainMenu** refait : fond nébuleuse animée, champ d'étoiles, titre stylisé
- ✅ **CockpitZone** : HBox compact (sprite + nom + XP + bouton) au-dessus du bouton ATTAQUER
- ✅ **Boutons stylisés** : violet foncé + bordure, bouton ATTAQUER orange/feu

---

## 📝 Notes de Design
- **Monnaie** : Croquettes Cosmiques (pas fromage).
- **Joystick** : invisible et flottant pour expérience mobile optimale.
- **Style visuel cible** : fond violet profond, sprites cartoon, UI propre (ref: Muse/cell-survivor).

---

## 🐛 Bugfixes (post-v0.6 — Mars 2026)

### Gameplay & Save
- ✅ **Fin de partie par niveau** : victoire déclenchée au boss du niveau sélectionné (level 1-2→wave5, 3-5→wave10, 6-8→wave15, 9-10→wave20)
- ✅ **NIVEAU vs VAGUE** : menu principal renommé "NIVEAU X"
- ✅ **DamageNumber tween** : TRANS_OUT → TRANS_SINE + EASE_OUT (n'existe pas en Godot 4)
- ✅ **Sauvegarde croquettes** : SaveManager.save_game() manquait file.close() — données non flushées sur disque (affectait kibble, upgrades, XP pilotes, niveaux débloqués)

### Visuels
- ✅ **Shader bg_remove retiré** : tous les sprites PNG sont RGBA — le shader supprimait des pixels valides
- ✅ **CatPilotUI mobile** : panel adaptatif 96% écran (était fixe 700×500)
- ✅ **Sprite pilote ratio 2:3** : wrapper Control fixe pour bloquer l'expansion dans VBox
- ✅ **CockpitZone** : repositionné en HBox compact pour éviter chevauchement avec le carousel
- ✅ **ship_t2** : pivoté portrait, centré (dx=0 dy=0), artefacts nettoyés, scale 0.40
- ✅ **ship_t3** : artefacts blancs nettoyés (924px)

### 🐱 Sprites Pilotes (post-v0.6 — Mars 2026)
- ✅ **Dossier** `assets/sprites/cats/` — sprites individuels par chat
- ✅ **Champ `sprite_menu`** dans CatManager (90×135 menu) + `sprite_stage` (80×120 carousel)
- ✅ **7/7 chats** avec sprites individuels :
  - Minou Cosmique → kitten_astronaut
  - Félix Furieux → ninja_cat
  - Comète → Comet
  - Capitaine Sardine → SArdine
  - Zéro Gravité → warrior_cat
  - Nébula → cosmic_cat_god
  - Astro → Astro (recadré portrait)

---

## 🚀 Prochaines Étapes
- [ ] **ship_t3** : nouveau sprite portrait (format ~280×450px, nez vers le haut)
- [ ] **Audio** : Sons UI + musique d'ambiance
- [ ] **Tutorial / Onboarding** : Guide initial pour nouveaux joueurs
- [ ] Variantes visuelles souris (Scout plus rapide/petite, Guerrière plus grande).
- [ ] Effets particules aspiration XP peaufinage.
- [ ] Animations entrée/sortie menus UI.
