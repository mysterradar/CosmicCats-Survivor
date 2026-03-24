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
    - Menu de sélection de niveaux (Vagues 1 à 10).
    - Sauvegarde persistante des récompenses et niveaux.
    - **Aspirateur Cosmique** : Compétence pour attirer tout l'XP.

### 👾 Ennemis & Boss
- **Horde** : Souris aliens (sprites enemy_scout/artillery/cruiser) avec Squash & Stretch.
- **Difficulté** : PV des monstres +40% toutes les 30 secondes.
- **Boss Final** : "Le Grand Gruyère" apparaît à 2 minutes.

### 🛍️ ShopUI — Upgrades Armes Connectées au Gameplay (v0.6)
- ✅ **Piercing Bullet** : balles traversent N ennemis (implémenté dans Bullet.gd)
- ✅ **Missile Cluster** : missiles se séparent en 2 mini-missiles à ±30° avec TTL (SardineMissile.gd)
- ✅ **Plasma Overcharge** : PlasmaBlade scale dynamique selon niveau upgrade (PlasmaBlade.gd)

### 🐱 CatPilotUI — Système XP (v0.6)
- ✅ Chaque carte chat affiche ProgressBar XP + label "XP : X / Y"
- ✅ Guard level 30 → affiche "XP : MAX" en doré
- ✅ Progression visuelle claire du niveau d'upgrade

### 📋 MissionUI — 8 Missions Renouvelables (v0.6)
- ✅ **8 missions** au lieu de 3 : kill_mice, collect_kibble, reach_wave, kill_elites, deal_damage, collect_fur, use_shield, boss_kill
- ✅ **Renouvellement automatique** : objectif ×1.5, récompense ×1.4 au claim
- ✅ ProgressBar par mission + compteur (xN)
- ✅ **Migration save robuste** : anciennes saves ignorées proprement
- ✅ Nouvelles stats trackées dans Enemy.gd, Player.gd, CatManager.gd, GameScene.gd

### 🚀 Vaisseaux
- 4 tiers de vaisseaux (ship_t1 → ship_t4) débloqués par niveau.
- Sprites violet/bleu avec cockpit chat.

### 🖼️ Interface & Visuels (session Mars 2026)
- ✅ **MainMenu** refait : fond nébuleuse animée (shader), champ d'étoiles, titre "🐱 COSMIC CATS vs ALIEN MICE"
- ✅ **EnemyDisplay** : vrai sprite souris (Sprite2D) dans le carousel + animation flottement
- ✅ **Boutons stylisés** : violet foncé + bordure violette, bouton ATTAQUER orange/feu
- ✅ **Bug bouclier fix** : Line2D correctement fermé (append premier point), width 6px
- ✅ **Bug souris = points fix** : scales sprites corrigés (0.18 → 1.0-1.4)
- ✅ **Enemy.tscn** nettoyé : ancien Polygon2D supprimé

---

## 📝 Notes de Design
- **Monnaie** : Croquettes Cosmiques (pas fromage).
- **Joystick** : invisible et flottant pour expérience mobile optimale.
- **Style visuel cible** : fond violet profond, sprites cartoon, UI propre (ref: Muse/cell-survivor).

## 🚀 Prochaines Étapes
- [ ] **Audio** : Sons UI + musique d'ambiance
- [ ] **Tutorial / Onboarding** : Guide initial pour nouveaux joueurs
- [ ] Variantes visuelles souris (Scout plus rapide/petite, Guerrière plus grande).
- [ ] Effets particules aspiration XP peaufinage.
- [ ] Animations entrée/sortie menus UI.
