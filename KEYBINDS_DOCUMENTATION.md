# ⌨️ Documentation des Raccourcis Clavier (Keybinds)

## 📋 Vue d'ensemble

Ce document répertorie tous les raccourcis clavier disponibles dans le projet Artdle, organisés par catégorie et fonctionnalité.

## 🎮 Raccourcis de Test et Développement

### **Système de Sauvegarde** (`QuickSaveTest.gd`)

| Touche | Fonction | Description | Fichier |
|--------|----------|-------------|---------|
| **1** | `test_save()` | Sauvegarde l'état actuel du jeu | `scripts/QuickSaveTest.gd` |
| **2** | `test_load()` | Charge la dernière sauvegarde | `scripts/QuickSaveTest.gd` |
| **3** | `test_clear()` | Supprime le fichier de sauvegarde | `scripts/QuickSaveTest.gd` |
| **4** | `test_info()` | Affiche les informations de sauvegarde | `scripts/QuickSaveTest.gd` |
| **5** | `reset_game_completely()` | **RESET COMPLET** du jeu (confirmation requise) | `scripts/QuickSaveTest.gd` |
| **6** | `give_ascendancy_points()` | Donne 50 points d'ascension pour tester | `scripts/QuickSaveTest.gd` |
| **7** | `test_feedback()` | Teste le système de feedback visuel | `scripts/QuickSaveTest.gd` |
| **Ctrl+9** | `activate_devotion()` | Active/améliore le skill Devotion (5 niveaux, revenu passif) | `scripts/QuickSaveTest.gd` |
| **0** | `test_with_data()` | Ajoute des données de test et sauvegarde | `scripts/QuickSaveTest.gd` |

### **Test de Persistance** (`TestSavePersistence.gd`)

| Touche | Fonction | Description | Fichier |
|--------|----------|-------------|---------|
| **8** | `test_save_persistence()` | Test complet de persistance des données | `scripts/TestSavePersistence.gd` |

### **Test Barre d'XP** (`TestXPBarFix.gd`)

| Touche | Fonction | Description | Fichier |
|--------|----------|-------------|---------|
| **9** | `test_xp_bar_initialization()` | Test manuel de la barre d'XP | `scripts/TestXPBarFix.gd` |

## 🎯 Raccourcis de Jeu

### **Navigation Principale** (`Main.gd`)

| Touche | Fonction | Description | Fichier |
|--------|----------|-------------|---------|
| **Boutons UI** | Navigation | Accueil, Peinture, Ascendancy | `scripts/Main.gd` |

### **Vue d'Accueil** (`AccueilView.gd`)

| Touche | Fonction | Description | Fichier |
|--------|----------|-------------|---------|
| **Bouton Debug** | `_on_debug_pressed()` | Ajoute des devises de debug | `scripts/views/AccueilView.gd` |

### **Vue de Peinture** (`PaintingView.gd`)

| Touche | Fonction | Description | Fichier |
|--------|----------|-------------|---------|
| **Bouton Debug** | `_on_debug_pressed()` | Ajoute des devises de debug | `scripts/views/PaintingView.gd` |

## 🔧 Raccourcis de Développement

### **Système de Reset**

| Touche | Fonction | Description | Sécurité |
|--------|----------|-------------|----------|
| **5** | Reset Complet | Remet tout le jeu à zéro | Double confirmation + timeout 5s |

### **Système de Sauvegarde**

| Touche | Fonction | Description | Sécurité |
|--------|----------|-------------|----------|
| **1** | Sauvegarder | Sauvegarde immédiate | Aucune |
| **2** | Charger | Chargement immédiat | Aucune |
| **3** | Supprimer | Suppression immédiate | Aucune |
| **4** | Infos | Affichage des infos | Aucune |

## 📊 Catégorisation par Priorité

### **🔴 Critique (Développement)**
- **5** : Reset complet (avec confirmation)
- **1-4** : Gestion de sauvegarde

### **🟡 Important (Test)**
- **0** : Test avec données
- **8** : Test de persistance
- **9** : Test barre d'XP

### **🟢 Standard (Jeu)**
- **Boutons UI** : Navigation normale
- **Boutons Debug** : Ajout de devises

## 🛡️ Sécurité et Confirmation

### **Reset Complet (F5)**
```gdscript
# Système de double confirmation
1. Premier F5 → Demande confirmation
2. Deuxième F5 (dans 5s) → Exécute le reset
3. Timeout → Annule automatiquement
```

### **Aucune Confirmation Requise**
- F1, F2, F3, F4 : Actions de sauvegarde
- F10, F11, F12 : Tests de développement
- Boutons de navigation : Actions normales

## 📁 Fichiers Concernés

### **Scripts Principaux**
- `scripts/QuickSaveTest.gd` - F1, F2, F3, F4, F5, F10
- `scripts/TestSavePersistence.gd` - F11
- `scripts/TestXPBarFix.gd` - F12
- `scripts/Main.gd` - Navigation principale

### **Vues de Jeu**
- `scripts/views/AccueilView.gd` - Boutons debug
- `scripts/views/PaintingView.gd` - Boutons debug
- `scripts/views/AscendancyView.gd` - Boutons debug

## 🎯 Utilisation Recommandée

### **Pour les Tests**
1. **F10** → Ajouter des données de test
2. **F1** → Sauvegarder
3. **F2** → Charger pour vérifier
4. **F4** → Vérifier les infos de sauvegarde

### **Pour le Développement**
1. **F12** → Tester la barre d'XP
2. **F11** → Test de persistance complet
3. **F5** → Reset si nécessaire (avec confirmation)

### **Pour le Jeu Normal**
- Utiliser les boutons UI pour la navigation
- Les raccourcis F1-F12 sont invisibles pour l'utilisateur final

## ⚠️ Notes Importantes

### **Conflits Évités**
- **Touches F** : Évitées (utilisées par Godot Editor)
- **Touches numériques 0-9** : Utilisées pour les tests
- **Boutons UI** : Pas de conflit avec les raccourcis

### **Développement vs Production**
- **Tous les raccourcis numériques 0-9** : Développement uniquement
- **Boutons UI** : Production
- **Scripts de test** : Peuvent être désactivés en production

## 🔄 Mise à Jour

Ce document doit être mis à jour à chaque ajout de nouveau raccourci clavier dans le projet.

**Dernière mise à jour** : $(date)
**Version** : 1.0
