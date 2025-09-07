# 📚 Documentation des Skills - Artdle

## 🎯 Vue d'ensemble

Le système de skills d'Artdle permet d'acheter des améliorations permanentes avec des points d'ascension. Chaque skill a des effets uniques et certains évoluent dynamiquement avec le niveau du joueur.

---

## 🌳 Structure du Skill Tree

```
Devotion (root) - Revenu passif d'inspiration
├── Icon influence - Débloque la peinture
    └── Capitalist - Prix de vente des canvas ↑
        ├── Swift brush - Autoclick
        ├── Storage room - Stockage de canvas
        ├── Taylorism - Gains de peinture ↑
        └── Megalomania - Canvas plus grands
```

---

## 🔥 Skills Détaillés

### **Devotion** (Skill Racine)
**Type:** PASSIVE - Revenu passif  
**Coût:** 1 point d'ascension (×2 par niveau)  
**Achats multiples:** ✅ (5 niveaux maximum)

#### **Effets par Niveau**

| Niveau | Effet | Description |
|--------|-------|-------------|
| **1** | Revenu de base | 1 inspiration toutes les 5 secondes |
| **2** | Scaling de niveau | Multiplie le gain par votre niveau actuel |
| **3** | Rythme amélioré | Intervalle réduit selon le niveau (0.2 par niveau) |
| **4** | Gain doublé | Double le gain passif total |
| **5** | Conservation | Garde 0.1% d'inspiration lors de l'ascension |

#### **Formules de Calcul**
- **Niveau 1:** `1 inspiration / 5 secondes`
- **Niveau 2:** `niveau × 1 inspiration / 5 secondes`
- **Niveau 3:** `niveau × 1 inspiration / max(0.1, 5.0 - niveau × 0.2) secondes`
- **Niveau 4:** `niveau × 2 inspiration / max(0.1, 5.0 - niveau × 0.2) secondes`
- **Niveau 5:** `niveau × 2 inspiration / max(0.1, 5.0 - niveau × 0.2) secondes + 0.1% conservé`

#### **Exemples de Progression**
```
Niveau 10:
- Niveau 1: 1 inspiration/5s
- Niveau 2: 10 inspiration/5s
- Niveau 3: 10 inspiration/3s
- Niveau 4: 20 inspiration/3s
- Niveau 5: 20 inspiration/3s + conservation

Niveau 50:
- Niveau 1: 1 inspiration/5s
- Niveau 2: 50 inspiration/5s
- Niveau 3: 50 inspiration/0.1s (500 inspiration/s!)
- Niveau 4: 100 inspiration/0.1s (1000 inspiration/s!)
- Niveau 5: 100 inspiration/0.1s + conservation
```

---

### **Icon influence**
**Type:** UNLOCK - Déblocage  
**Coût:** 2 points d'ascension  
**Achats multiples:** ❌  
**Prérequis:** Devotion

#### **Effet**
- Débloque le système de peinture
- Permet d'accéder aux autres skills

---

### **Capitalist**
**Type:** UPGRADE - Amélioration  
**Coût:** 2 points d'ascension (×2 par niveau)  
**Achats multiples:** ✅ (illimité)  
**Prérequis:** Icon influence

#### **Effet**
- **Niveau 1:** +10% prix de vente des canvas
- **Niveau 2:** +20% prix de vente des canvas
- **Niveau 3:** +30% prix de vente des canvas
- **Formule:** `+10% × niveau`

#### **Exemple**
```
Niveau 5: +50% prix de vente
Canvas de base: 100 gold → 150 gold
```

---

### **Swift brush**
**Type:** UNLOCK - Déblocage  
**Coût:** 10 points d'ascension  
**Achats multiples:** ❌  
**Prérequis:** Capitalist

#### **Effet**
- Débloque l'autoclick
- Permet de générer des pixels automatiquement
- Vitesse de base configurable

---

### **Storage room**
**Type:** UNLOCK - Déblocage  
**Coût:** 15 points d'ascension  
**Achats multiples:** ❌  
**Prérequis:** Capitalist

#### **Effet**
- Débloque le stockage de canvas
- Permet de stocker les canvas terminés
- Vente en lot possible

---

### **Taylorism**
**Type:** UPGRADE - Amélioration  
**Coût:** 2 points d'ascension (×2 par niveau)  
**Achats multiples:** ✅ (illimité)  
**Prérequis:** Capitalist

#### **Effet**
- **Niveau 1:** +5% gains d'or et d'inspiration en peignant
- **Niveau 2:** +10% gains d'or et d'inspiration en peignant
- **Niveau 3:** +15% gains d'or et d'inspiration en peignant
- **Formule:** `+5% × niveau`

#### **Exemple**
```
Niveau 10: +50% gains
Peinture normale: 100 inspiration → 150 inspiration
```

---

### **Megalomania**
**Type:** UNLOCK - Déblocage  
**Coût:** 25 points d'ascension  
**Achats multiples:** ❌  
**Prérequis:** Capitalist

#### **Effet**
- Débloque les améliorations de taille de canvas
- Permet de peindre des canvas plus grands
- Plus de pixels = plus de gains

---

## 🎮 Guide d'Utilisation

### **Ordre d'Achat Recommandé**

#### **Début de Partie**
1. **Devotion** (niveau 1) - Revenu passif de base
2. **Icon influence** - Débloquer la peinture
3. **Capitalist** (niveau 1-2) - Améliorer les gains

#### **Milieu de Partie**
4. **Swift brush** - Autoclick pour automatiser
5. **Storage room** - Stockage pour optimiser
6. **Taylorism** (niveau 1-3) - Améliorer les gains

#### **Fin de Partie**
7. **Devotion** (niveaux 2-5) - Revenu passif puissant
8. **Megalomania** - Canvas plus grands
9. **Capitalist** (niveaux élevés) - Prix de vente maximum
10. **Taylorism** (niveaux élevés) - Gains maximum

### **Stratégies par Style de Jeu**

#### **🎯 Style Passif**
- **Focus:** Devotion (tous niveaux)
- **Avantage:** Revenu automatique
- **Inconvénient:** Progression lente

#### **⚡ Style Actif**
- **Focus:** Swift brush + Taylorism
- **Avantage:** Gains élevés
- **Inconvénient:** Nécessite de jouer

#### **💰 Style Économique**
- **Focus:** Capitalist + Storage room
- **Avantage:** Optimisation des gains
- **Inconvénient:** Nécessite de la planification

---

## 🔧 Détails Techniques

### **Système de Scaling Dynamique**

#### **Devotion - Mise à jour automatique**
- **Signal:** `level_changed` de ExperienceManager
- **Fonction:** `update_devotion_passive_income()`
- **Fréquence:** À chaque gain d'XP

#### **Calculs en Temps Réel**
```gdscript
# Niveau 2: Scaling de niveau
base_amount *= player_level

# Niveau 3: Rythme amélioré
base_interval = max(0.1, 5.0 - (player_level * 0.2))

# Niveau 4: Gain doublé
base_amount *= 2.0
```

### **Système de Sauvegarde**

#### **Données Sauvées**
- **Skills débloqués:** `skill_tree.unlocked_skills`
- **Niveaux des skills:** `skill_tree.skill_levels`
- **Sources de revenus passifs:** `passive_income.sources`

#### **Restauration**
- **Skills:** Re-application des effets
- **Revenus passifs:** Re-création des sources
- **UI:** Mise à jour automatique

---

## 🎯 Conseils d'Optimisation

### **Points d'Ascension**
- **Gagner:** Ascension avec de la renommée
- **Coût:** Augmente exponentiellement
- **Stratégie:** Ascensionner régulièrement

### **Devotion - Maximisation**
- **Niveau 2:** Essentiel pour le scaling
- **Niveau 3:** Très puissant aux niveaux élevés
- **Niveau 4:** Double l'efficacité
- **Niveau 5:** Conservation à l'ascension

### **Synergies**
- **Capitalist + Taylorism:** Gains maximum
- **Swift brush + Devotion:** Automatisation complète
- **Storage room + Capitalist:** Vente optimisée

---

## 📊 Tableau de Coûts

| Skill | Niveau 1 | Niveau 2 | Niveau 3 | Niveau 4 | Niveau 5 |
|-------|----------|----------|----------|----------|----------|
| **Devotion** | 1 | 2 | 4 | 8 | 16 |
| **Capitalist** | 2 | 4 | 8 | 16 | 32 |
| **Taylorism** | 2 | 4 | 8 | 16 | 32 |

**Total pour Devotion niveau 5:** 31 points d'ascension

---

## 🚀 Prochaines Améliorations

### **Skills Prévus**
- **Nouveaux skills** basés sur le gameplay
- **Synergies** entre skills
- **Skills conditionnels** (prérequis multiples)

### **Système**
- **Reset de skills** avec remboursement partiel
- **Presets** de builds
- **Statistiques** détaillées

---

*Documentation mise à jour le: $(date)*  
*Version: 1.0*  
*Jeu: Artdle*

