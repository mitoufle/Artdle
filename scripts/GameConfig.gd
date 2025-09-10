extends Node
class_name GameConfig

## Configuration centralisée pour le jeu Artdle
## Toutes les constantes et valeurs de configuration sont définies ici

#==============================================================================
# Currency Defaults
#==============================================================================
const DEFAULT_INSPIRATION: float = 0.0
const DEFAULT_GOLD: float = 0.0
const DEFAULT_FAME: float = 0.0
const DEFAULT_ASCENDANCY_POINTS: float = 0.0
const DEFAULT_ASCEND_LEVEL: float = 0.0
const DEFAULT_PAINT_MASTERY: float = 0.0
const DEFAULT_EXPERIENCE: float = 0.0
const DEFAULT_LEVEL: int = 1
const DEFAULT_EXPERIENCE_TO_NEXT_LEVEL: float = 100.0

#==============================================================================
# Canvas Configuration
#==============================================================================
const BASE_CANVAS_SIZE: int = 32
const BASE_SELL_PRICE: int = 1000
const BASE_FAME_PER_CANVAS: int = 5
const BASE_FAME_PER_LEVEL: int = 1
const BASE_RESOLUTION_LEVEL: int = 1
const BASE_FILL_SPEED_LEVEL: int = 1
const BASE_CANVAS_STORAGE_LEVEL: int = 0

# Canvas Upgrade Costs
const BASE_RESOLUTION_UPGRADE_COST: int = 10000
const BASE_FILL_SPEED_UPGRADE_COST: int = 50
const BASE_CANVAS_STORAGE_UPGRADE_COST: int = 200

# Canvas Upgrade Multipliers
const RESOLUTION_COST_MULTIPLIER: float = 10.0
const FILL_SPEED_COST_MULTIPLIER: float = 1.2
const CANVAS_STORAGE_COST_MULTIPLIER: float = 1.5
const SELL_PRICE_MULTIPLIER: float = 1.8
const BULK_SELL_PRICE_MULTIPLIER: float = 1.1

#==============================================================================
# Clicker Configuration
#==============================================================================
const BASE_CLICK_POWER: int = 1
const BASE_AUTOCLICK_SPEED: float = 0.0

# Clicker Upgrade Costs
const CLICK_POWER_UPGRADE_COST: int = 10
const AUTOCLICK_SPEED_UPGRADE_COST: int = 50

#==============================================================================
# Ascension Configuration
#==============================================================================
const BASE_ASCENDANCY_COST: float = 1000.0
const ASCENDANCY_COST_MULTIPLIER: float = 2.0
const ASCENDANCY_POINTS_PER_ASCENSION: float = 1.0
const ASCEND_LEVELS_PER_ASCENSION: float = 1.0

#==============================================================================
# Experience Configuration
#==============================================================================
const EXPERIENCE_MULTIPLIER: float = 1.5
const EXPERIENCE_PER_CLICK: float = 1.0
const EXPERIENCE_PER_CANVAS_SOLD: float = 5.0

#==============================================================================
# UI Configuration
#==============================================================================
const VIEW_UNLOCK_LEVELS = {
	"PaintingView": 2,
	"AscendancyView": 5
}

#==============================================================================
# Canvas Pixel Configuration
#==============================================================================
const PIXEL_ALPHA_MIN: float = 0.6
const PIXEL_ALPHA_MAX: float = 1.0
const PIXEL_ALPHA_SNAP: float = 0.01

#==============================================================================
# Error Messages
#==============================================================================
const ERROR_INVALID_CURRENCY = "Currency amount must be a positive number"
const ERROR_INVALID_CONTAINER = "Scene container reference is invalid"
const ERROR_FAILED_SCENE_LOAD = "Failed to load scene at path: %s"
const ERROR_INVALID_SCENE_RESOURCE = "Scene resource is null"
