# 🔄 Diagramme de Flux du Jeu - Artdle

## 📊 **Flux Principal des Ressources**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CLIC MANUEL   │───▶│  INSPIRATION    │───▶│   EXPÉRIENCE    │
│  (ClickerMgr)   │    │  (CurrencyMgr)  │    │ (ExperienceMgr) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AUTOCLIC      │───▶│      OR         │───▶│   NIVEAU UP     │
│  (ClickerMgr)   │    │  (CurrencyMgr)  │    │ (ExperienceMgr) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  VENTE TOILE    │───▶│   RENOMMÉE      │───▶│ POINTS COMPÉTENCE│
│ (CanvasMgr)     │    │  (CurrencyMgr)  │    │ (ExperienceMgr) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🏭 **Flux de Craft et Équipement**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     CRAFT       │───▶│   ITEMS         │───▶│   ÉQUIPEMENT    │
│  (CraftMgr)     │    │(InventoryMgr)   │    │(InventoryMgr)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   COÛT OR       │───▶│   BONUS STATS   │───▶│ BONUS GLOBALS   │
│  (CurrencyMgr)  │    │(InventoryMgr)   │    │(CurrencyBonusMgr)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## ⬆️ **Flux d'Ascension et Compétences**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ASCENSION     │───▶│ POINTS ASCENSION│───▶│   COMPÉTENCES   │
│ (AscensionMgr)  │    │ (AscensionMgr)  │    │ (SkillTreeMgr)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   RESET GAME    │───▶│ AMÉLIORATIONS   │───▶│ BONUS PERMANENTS│
│ (AscensionMgr)  │    │ (SkillTreeMgr)  │    │ (SkillTreeMgr)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔄 **Flux de Bonus et Multiplicateurs**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ITEMS ÉQUIPÉS │───▶│  BONUS CALCULÉS │───▶│ MULTIPLICATEURS │
│(InventoryMgr)   │    │(InventoryMgr)   │    │(CurrencyBonusMgr)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   STATS ITEMS   │───▶│ BONUS PAR TYPE   │───▶│ GAINS FINAUX    │
│(InventoryMgr)   │    │(CurrencyBonusMgr)│    │(CurrencyMgr)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 💰 **Flux des Devises**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  GAIN DE BASE   │───▶│ BONUS ÉQUIPEMENT│───▶│  GAIN FINAL     │
│ (Tous les mgr)  │    │(CurrencyBonusMgr)│    │ (CurrencyMgr)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   VALIDATION    │───▶│ FORMATAGE GRAND │───▶│  AFFICHAGE UI   │
│(CurrencyMgr)    │    │   NOMBRES       │    │ (UIFormatter)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🎯 **Flux de Feedback Visuel**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GAIN RESSOURCE│───▶│  FLOATING TEXT  │───▶│  FEEDBACK UI    │
│ (Tous les mgr)  │    │ (FloatingText)  │    │ (FeedbackMgr)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MONTANT RÉEL  │───▶│   ANIMATION     │───▶│   ICÔNE RESSOURCE│
│(CurrencyBonusMgr)│    │ (FloatingText)  │    │ (FloatingText)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔄 **Flux de Sauvegarde**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ÉTAT JEU      │───▶│  SÉRIALISATION  │───▶│   FICHIER SAVE  │
│ (GameState)     │    │  (SaveManager)  │    │ (SaveManager)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CHARGEMENT    │───▶│ DÉSÉRIALISATION │───▶│  RESTAURATION   │
│ (SaveManager)   │    │  (SaveManager)  │    │ (GameState)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🎮 **Flux de Navigation**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ACCUEIL       │───▶│   PAINTING      │───▶│   ASCENDANCY    │
│ (AccueilView)   │    │ (PaintingView)  │    │ (AscendancyView)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   NOUVELLE PARTIE│───▶│   POPUPS        │───▶│   RETOUR        │
│ (AccueilView)   │    │ (Canvas/Inv/Craft)│    │ (Toutes vues)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔧 **Flux de Gestion des Erreurs**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ERREUR        │───▶│   VALIDATION    │───▶│   CORRECTION    │
│ (Tous les mgr)  │    │(DataValidator)  │    │ (Tous les mgr)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   LOGGING       │───▶│   NOTIFICATION  │───▶│   RÉCUPÉRATION  │
│ (GameLogger)    │    │ (FeedbackMgr)   │    │ (Tous les mgr)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📊 **Résumé des Interactions**

### **Managers Principaux :**
- **GameState** : Point central, coordonne tous les autres
- **CurrencyManager** : Gère toutes les devises
- **ExperienceManager** : Gère l'expérience et les niveaux
- **InventoryManager** : Gère les items et équipements
- **CraftManager** : Gère le craft d'items
- **ClickerManager** : Gère les clics et autoclics
- **CanvasManager** : Gère les toiles et leur vente
- **AscensionManager** : Gère l'ascension
- **SkillTreeManager** : Gère les compétences
- **PassiveIncomeManager** : Gère les revenus passifs

### **Managers Utilitaires :**
- **CurrencyBonusManager** : Applique les bonus d'équipement
- **BigNumberManager** : Gère les grands nombres
- **UIFormatter** : Formate l'affichage des nombres
- **SaveManager** : Gère la sauvegarde
- **DataValidator** : Valide les données
- **GameLogger** : Gère les logs
- **FeedbackManager** : Gère le feedback visuel

### **Points d'Entrée :**
1. **Clic** → ClickerManager → CurrencyManager → ExperienceManager
2. **Vente** → CanvasManager → CurrencyManager → ExperienceManager
3. **Craft** → CraftManager → InventoryManager → CurrencyManager
4. **Équipement** → InventoryManager → CurrencyBonusManager
5. **Ascension** → AscensionManager → Reset des managers
6. **Compétences** → SkillTreeManager → Bonus permanents

### **Points de Sortie :**
1. **Feedback visuel** → FloatingText → UI
2. **Sauvegarde** → SaveManager → Fichier
3. **Navigation** → SceneManager → Changement de vue
4. **Logs** → GameLogger → Console
