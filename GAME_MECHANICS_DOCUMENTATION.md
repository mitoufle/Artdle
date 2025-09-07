# 🎮 Documentation des Mécaniques du Jeu - Artdle

## 📋 Vue d'ensemble

Artdle est un jeu de type "idle/clicker" où le joueur peint des toiles, craft des équipements et progresse à travers différents systèmes interconnectés.

---

## 🎯 **1. SYSTÈME DE CLIC (ClickerManager)**

### **Fonctionnement :**
- **Clic manuel** : Le joueur clique pour gagner de l'inspiration
- **Autoclic** : Gain automatique d'inspiration toutes les X secondes
- **Puissance de clic** : Détermine combien d'inspiration est gagnée par clic

### **Mécaniques :**
- **Inspiration de base** : 1 point par clic
- **Autoclic** : 1 point toutes les 2 secondes (par défaut)
- **Bonus d'équipement** : Les items équipés multiplient les gains
- **Expérience** : Chaque clic donne de l'expérience

### **Calculs :**
```
Gain d'inspiration = click_power × multiplicateur_d'équipement
Gain d'expérience = 1 point par clic
```

### **Signaux :**
- `inspiration_gained` : Émis quand de l'inspiration est gagnée
- `experience_gained` : Émis quand de l'expérience est gagnée

---

## 🖼️ **2. SYSTÈME DE TOILE (CanvasManager)**

### **Fonctionnement :**
- Le joueur peint des toiles pour les vendre
- Chaque toile vendue rapporte de l'or et de la renommée
- Le prix de vente augmente avec le niveau

### **Mécaniques :**
- **Prix de base** : 100 or + 10 renommée par toile
- **Multiplicateur de niveau** : Prix × (niveau + 1)
- **Bonus d'équipement** : Les items équipés multiplient les gains
- **Expérience** : Chaque vente donne de l'expérience

### **Calculs :**
```
Prix or = 100 × (niveau + 1) × multiplicateur_d'équipement
Prix renommée = 10 × (niveau + 1) × multiplicateur_d'équipement
Gain d'expérience = 5 points par toile vendue
```

### **Signaux :**
- `canvas_sold` : Émis quand une toile est vendue
- `gold_gained` : Émis quand de l'or est gagné
- `fame_gained` : Émis quand de la renommée est gagnée

---

## 🏭 **3. SYSTÈME D'ATELIER (CraftManager)**

### **Fonctionnement :**
- Le joueur craft des équipements aléatoirement
- Chaque craft coûte des ressources et prend du temps
- Les items craftés ont des stats aléatoires

### **Mécaniques :**
- **Types d'items** : HAT, SHIRT, PANTS, SHOES, ACCESSORY
- **Tiers d'items** : TIER_1, TIER_2, TIER_3, TIER_4, TIER_5
- **Stats aléatoires** : Chaque item a des bonus différents
- **Coût de craft** : Or + renommée selon le niveau
- **Temps de craft** : 5 secondes par défaut
- **Expérience** : Chaque craft donne de l'expérience

### **Calculs :**
```
Coût or = 50 × (niveau_atelier + 1)
Coût renommée = 5 × (niveau_atelier + 1)
Temps de craft = 5 secondes
Gain d'expérience = 10 points par craft
```

### **Améliorations d'atelier :**
- **Vitesse de craft** : Réduit le temps de craft
- **Chances de qualité** : Augmente les chances d'items de meilleure qualité
- **Slots multiples** : Permet de craft plusieurs items simultanément

### **Signaux :**
- `craft_started` : Émis quand un craft commence
- `craft_progress` : Émis pendant le craft
- `craft_completed` : Émis quand un item est crafté
- `craft_finished` : Émis quand tout le craft est terminé

---

## 🎒 **4. SYSTÈME D'INVENTAIRE (InventoryManager)**

### **Fonctionnement :**
- Le joueur stocke et équipe des items
- Les items équipés donnent des bonus
- L'inventaire a une capacité limitée

### **Mécaniques :**
- **Slots d'équipement** : hat, shirt, pants, shoes, accessory
- **Capacité d'inventaire** : 20 slots par défaut
- **Stats d'items** : Chaque item a des bonus différents
- **Tiers d'items** : Déterminent la puissance des bonus

### **Types de bonus :**
- `inspiration_generation` : Multiplie les gains d'inspiration
- `coin_generation` : Multiplie les gains d'or
- `fame_generation` : Multiplie les gains de renommée
- `ascendancy_generation` : Multiplie les gains d'ascendancy
- `paint_mastery` : Multiplie les gains d'expérience
- `generation_bonus` : Bonus générique

### **Calculs :**
```
Bonus total = ∏(bonus_de_chaque_item_équipé)
```

### **Signaux :**
- `item_equipped` : Émis quand un item est équipé
- `item_unequipped` : Émis quand un item est déséquipé
- `inventory_changed` : Émis quand l'inventaire change

---

## ⬆️ **5. SYSTÈME D'ASCENSION (AscensionManager)**

### **Fonctionnement :**
- Le joueur peut ascensionner pour gagner des points d'ascension
- Les points d'ascension permettent d'acheter des améliorations permanentes
- L'ascension remet à zéro certains éléments du jeu

### **Mécaniques :**
- **Coût d'ascension** : 1000 renommée par défaut
- **Points d'ascension** : Gagnés lors de l'ascension
- **Améliorations** : Achetées avec les points d'ascension
- **Reset** : Remet à zéro l'expérience, l'or, la renommée

### **Calculs :**
```
Points d'ascension = niveau_actuel × 10
Coût d'ascension = 1000 × (ascensions + 1)
```

### **Signaux :**
- `ascension_completed` : Émis quand une ascension est effectuée
- `ascension_points_gained` : Émis quand des points sont gagnés

---

## 🌳 **6. SYSTÈME DE COMPÉTENCES (SkillTreeManager)**

### **Fonctionnement :**
- Le joueur dépense des points de compétence pour débloquer des améliorations
- Les compétences donnent des bonus permanents
- Les points de compétence sont gagnés en montant de niveau

### **Mécaniques :**
- **Points de compétence** : Gagnés à chaque niveau
- **Arbre de compétences** : Différentes branches d'améliorations
- **Coût des compétences** : Augmente avec le niveau de la compétence
- **Prérequis** : Certaines compétences nécessitent d'autres compétences

### **Types de compétences :**
- **Génération** : Augmente les gains de ressources
- **Efficacité** : Réduit les coûts
- **Vitesse** : Augmente la vitesse des actions
- **Capacité** : Augmente les limites

### **Signaux :**
- `skill_purchased` : Émis quand une compétence est achetée
- `skill_points_changed` : Émis quand les points de compétence changent

---

## 💰 **7. SYSTÈME DE DEVISES (CurrencyManager)**

### **Fonctionnement :**
- Gère toutes les devises du jeu
- Applique les bonus d'équipement
- Gère les très grands nombres

### **Devises :**
- **Inspiration** : Devise principale, gagnée par clic
- **Or** : Gagné en vendant des toiles
- **Renommée** : Gagnée en vendant des toiles
- **Ascendancy** : Gagnée par ascension
- **Expérience** : Gagnée par toutes les actions

### **Mécaniques :**
- **Bonus d'équipement** : Multiplie les gains
- **Gestion des grands nombres** : Utilise la notation scientifique
- **Validation** : Vérifie que les montants sont valides

### **Calculs :**
```
Gain final = gain_de_base × multiplicateur_d'équipement
```

---

## 📊 **8. SYSTÈME D'EXPÉRIENCE (ExperienceManager)**

### **Fonctionnement :**
- Le joueur gagne de l'expérience en jouant
- L'expérience permet de monter de niveau
- Chaque niveau donne des points de compétence

### **Mécaniques :**
- **Gain d'expérience** : 1 point par clic, 5 par toile vendue, 10 par craft
- **Niveaux** : Chaque niveau nécessite plus d'expérience
- **Points de compétence** : 1 point par niveau
- **Bonus d'équipement** : Multiplie les gains d'expérience

### **Calculs :**
```
Expérience nécessaire = niveau² × 100
Points de compétence = niveau_actuel
```

### **Signaux :**
- `level_up` : Émis quand le joueur monte de niveau
- `experience_gained` : Émis quand de l'expérience est gagnée

---

## 🔄 **9. SYSTÈME DE REVENUS PASSIFS (PassiveIncomeManager)**

### **Fonctionnement :**
- Génère des ressources automatiquement
- Basé sur les items équipés et les compétences
- Se déclenche toutes les X secondes

### **Mécaniques :**
- **Génération automatique** : Toutes les 5 secondes
- **Sources multiples** : Items équipés, compétences, ascensions
- **Bonus d'équipement** : Multiplie les gains
- **Feedback visuel** : Affiche les gains

### **Calculs :**
```
Gain passif = base_generation × multiplicateur_d'équipement
```

### **Signaux :**
- `passive_income_generated` : Émis quand des ressources sont générées

---

## 💾 **10. SYSTÈME DE SAUVEGARDE (SaveManager)**

### **Fonctionnement :**
- Sauvegarde automatique du jeu
- Chargement au démarrage
- Reset complet pour nouvelle partie

### **Mécaniques :**
- **Sauvegarde automatique** : Toutes les 30 secondes
- **Sauvegarde manuelle** : Sur demande
- **Chargement** : Au démarrage du jeu
- **Reset** : Remet tout à zéro

### **Données sauvegardées :**
- Toutes les devises
- Niveau et expérience
- Items et équipements
- Compétences achetées
- Ascensions effectuées
- Progression de l'atelier

---

## 🎨 **11. SYSTÈME D'INTERFACE UTILISATEUR**

### **Vues principales :**
- **AccueilView** : Écran d'accueil avec clic et nouvelle partie
- **PaintingView** : Vue principale avec atelier et inventaire
- **AscendancyView** : Vue d'ascension

### **Popups :**
- **CanvasPopup** : Gestion des toiles
- **InventoryPopup** : Gestion de l'inventaire et équipements
- **CraftPopup** : Atelier de craft

### **Composants :**
- **BottomBar** : Affichage des devises
- **CurrencyDisplay** : Affichage d'une devise
- **FloatingText** : Feedback visuel des gains

---

## 🔧 **12. SYSTÈME DE BONUS (CurrencyBonusManager)**

### **Fonctionnement :**
- Applique les bonus d'équipement aux gains de devises
- Multiplie les gains selon les items équipés
- Gère différents types de bonus

### **Types de bonus :**
- **Inspiration** : `inspiration_generation`, `generation_bonus`
- **Or** : `coin_generation`, `generation_bonus`
- **Renommée** : `fame_generation`, `generation_bonus`
- **Ascendancy** : `ascendancy_generation`, `generation_bonus`
- **Expérience** : `paint_mastery`, `generation_bonus`

### **Calculs :**
```
Multiplicateur = ∏(bonus_de_chaque_item_équipé)
Gain final = gain_de_base × multiplicateur
```

---

## 📈 **13. SYSTÈME DE GRANDS NOMBRES (BigNumberManager)**

### **Fonctionnement :**
- Gère les très grands nombres
- Utilise la notation scientifique
- Évite les overflows de float

### **Mécaniques :**
- **Formatage** : K, M, B, T, Q, QQ, etc.
- **Calculs sûrs** : Addition, multiplication, division
- **Validation** : Vérifie que les nombres sont valides

### **Notation :**
- **K** : 1,000
- **M** : 1,000,000
- **B** : 1,000,000,000
- **T** : 1,000,000,000,000
- **Q** : 1,000,000,000,000,000
- **QQ** : 1,000,000,000,000,000,000

---

## 🎯 **14. FLUX DE JEU PRINCIPAL**

### **Démarrage :**
1. Chargement de la sauvegarde
2. Initialisation des managers
3. Affichage de l'AccueilView

### **Boucle de jeu :**
1. **Clic** → Inspiration + Expérience
2. **Vente de toile** → Or + Renommée + Expérience
3. **Craft** → Items + Expérience
4. **Équipement** → Bonus aux gains
5. **Ascension** → Points d'ascension
6. **Compétences** → Améliorations permanentes

### **Progression :**
1. **Court terme** : Clic et vente de toiles
2. **Moyen terme** : Craft et équipement
3. **Long terme** : Ascension et compétences

---

## 🔗 **15. INTERACTIONS ENTRE SYSTÈMES**

### **Dépendances :**
- **ClickerManager** → **CurrencyManager** → **ExperienceManager**
- **CanvasManager** → **CurrencyManager** → **ExperienceManager**
- **CraftManager** → **InventoryManager** → **CurrencyManager**
- **InventoryManager** → **CurrencyBonusManager** → **Tous les gains**

### **Signaux croisés :**
- Tous les gains de devises passent par **CurrencyBonusManager**
- Tous les gains d'expérience passent par **ExperienceManager**
- Tous les items passent par **InventoryManager**

---

## 📝 **16. CONFIGURATION (GameConfig)**

### **Constantes principales :**
- **DEFAULT_INSPIRATION** : 0.0
- **DEFAULT_GOLD** : 0.0
- **DEFAULT_FAME** : 0.0
- **DEFAULT_EXPERIENCE** : 0.0
- **DEFAULT_LEVEL** : 1

### **Paramètres de jeu :**
- **EXPERIENCE_PER_CLICK** : 1
- **EXPERIENCE_PER_CANVAS** : 5
- **EXPERIENCE_PER_CRAFT** : 10
- **AUTOCLICK_INTERVAL** : 2.0

---

Cette documentation couvre tous les systèmes du jeu et leurs interactions. Chaque système est documenté avec ses mécaniques, calculs et signaux.
