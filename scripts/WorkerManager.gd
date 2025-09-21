extends Node
class_name WorkerManager

## Painter Office Worker Management System
## Manages workers, jobs, and office currency

signal worker_hired(worker: Worker)
signal worker_fired(worker: Worker)
signal job_completed(job: Job, worker: Worker, bonus: Dictionary)
signal office_currency_changed(new_amount: int)

#==============================================================================
# Worker Data Structure
#==============================================================================
class Worker:
	var id: String
	var name: String
	var tier: WorkerTier
	var level: int = 1
	var experience: int = 0
	var experience_to_next_level: int = 100
	
	# Base stats (0-100)
	var efficiency: int = 50      # How fast they complete jobs
	var creativity: int = 50      # Bonus to job rewards
	var reliability: int = 50     # Chance to complete job successfully
	var specialization: int = 50  # Bonus to specific job types
	
	# Current assignment
	var assigned_job: String = ""
	var job_start_time: float = 0.0
	var job_progress: float = 0.0
	
	func _init(worker_id: String, worker_name: String, worker_tier: WorkerTier):
		id = worker_id
		name = worker_name
		tier = worker_tier
		_roll_base_stats()
	
	func _roll_base_stats():
		# Roll stats based on tier
		var base_stat = tier.base_stat_value
		var variance = tier.stat_variance
		
		efficiency = base_stat + randi_range(-variance, variance)
		creativity = base_stat + randi_range(-variance, variance)
		reliability = base_stat + randi_range(-variance, variance)
		specialization = base_stat + randi_range(-variance, variance)
		
		# Clamp stats to valid range
		efficiency = clamp(efficiency, 1, 100)
		creativity = clamp(creativity, 1, 100)
		reliability = clamp(reliability, 1, 100)
		specialization = clamp(specialization, 1, 100)
	
	func get_total_efficiency() -> float:
		return (efficiency + creativity + specialization) / 3.0
	
	func can_complete_job() -> bool:
		return randf() < (reliability / 100.0)
	
	func add_experience(amount: int):
		experience += amount
		while experience >= experience_to_next_level:
			level_up()
	
	func level_up():
		experience -= experience_to_next_level
		level += 1
		experience_to_next_level = int(experience_to_next_level * 1.2)  # 20% increase per level
		
		# Increase stats on level up
		var stat_increase = 2 + (tier.tier_level * 0.5)  # Higher tier = more stats per level
		efficiency = min(100, efficiency + int(stat_increase))
		creativity = min(100, creativity + int(stat_increase))
		reliability = min(100, reliability + int(stat_increase))
		specialization = min(100, specialization + int(stat_increase))

#==============================================================================
# Worker Tier Data
#==============================================================================
class WorkerTier:
	var tier_name: String
	var tier_level: int
	var base_stat_value: int
	var stat_variance: int
	var hire_cost: int
	var daily_wage: int
	var max_workers: int
	
	func _init(name: String, level: int, base_stat: int, variance: int, cost: int, wage: int, max: int):
		tier_name = name
		tier_level = level
		base_stat_value = base_stat
		stat_variance = variance
		hire_cost = cost
		daily_wage = wage
		max_workers = max

#==============================================================================
# Job Data Structure
#==============================================================================
class Job:
	var job_id: String
	var job_name: String
	var job_type: JobType
	var base_duration: float  # Base time to complete in seconds
	var base_reward: int      # Base office currency reward
	var stat_bonus: Dictionary  # Permanent stat bonuses when completed
	var required_efficiency: int  # Minimum efficiency to attempt job
	
	func _init(id: String, name: String, type: JobType, duration: float, reward: int, bonus: Dictionary, req_eff: int):
		job_id = id
		job_name = name
		job_type = type
		base_duration = duration
		base_reward = reward
		stat_bonus = bonus
		required_efficiency = req_eff

#==============================================================================
# Job Types
#==============================================================================
enum JobType {
	CANVAS_SPEED,      # Increases canvas fill speed
	PIXEL_GAIN,        # Increases pixel gain per click
	AUTOCLICK_POWER,   # Increases autoclick power
	AUTOCLICK_SPEED,   # Increases autoclick speed
	WORKSHOP_SPEED,    # Increases workshop crafting speed
	CANVAS_STORAGE,    # Increases canvas storage capacity
	FAME_GAIN,         # Increases fame gain
	ASCENDANCY_GAIN    # Increases ascendancy point gain
}

#==============================================================================
# Manager State
#==============================================================================
var office_currency: int = 0
var workers: Array[Worker] = []
var available_jobs: Array[Job] = []
var completed_jobs: Array[String] = []  # Track completed job IDs for permanent bonuses

# Worker tiers
var worker_tiers: Array[WorkerTier] = []

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready():
	_initialize_worker_tiers()
	_initialize_jobs()
	_initialize_office_currency()

func _process(delta):
	_update_job_progress(delta)

#==============================================================================
# Initialization
#==============================================================================
func _initialize_worker_tiers():
	worker_tiers = [
		WorkerTier.new("Apprentice", 1, 30, 10, 100, 10, 3),      # Basic workers
		WorkerTier.new("Painter", 2, 45, 15, 500, 25, 5),        # Mid-tier workers
		WorkerTier.new("Master", 3, 60, 20, 2000, 50, 3),        # High-tier workers
		WorkerTier.new("Legend", 4, 75, 25, 10000, 100, 2),      # Elite workers
		WorkerTier.new("Mythic", 5, 90, 30, 50000, 200, 1)       # Legendary workers
	]

func _initialize_jobs():
	available_jobs = [
		# Canvas Speed Jobs
		Job.new("canvas_speed_1", "Speed Training", JobType.CANVAS_SPEED, 300.0, 50, {"canvas_fill_speed": 0.05}, 20),
		Job.new("canvas_speed_2", "Efficiency Workshop", JobType.CANVAS_SPEED, 600.0, 100, {"canvas_fill_speed": 0.1}, 40),
		Job.new("canvas_speed_3", "Master Speed Course", JobType.CANVAS_SPEED, 1200.0, 200, {"canvas_fill_speed": 0.2}, 70),
		
		# Pixel Gain Jobs
		Job.new("pixel_gain_1", "Brush Technique", JobType.PIXEL_GAIN, 300.0, 50, {"pixel_gain": 0.05}, 20),
		Job.new("pixel_gain_2", "Advanced Techniques", JobType.PIXEL_GAIN, 600.0, 100, {"pixel_gain": 0.1}, 40),
		Job.new("pixel_gain_3", "Master Brushwork", JobType.PIXEL_GAIN, 1200.0, 200, {"pixel_gain": 0.2}, 70),
		
		# Autoclick Power Jobs
		Job.new("autoclick_power_1", "Click Training", JobType.AUTOCLICK_POWER, 300.0, 50, {"autoclick_power": 0.05}, 20),
		Job.new("autoclick_power_2", "Power Workshop", JobType.AUTOCLICK_POWER, 600.0, 100, {"autoclick_power": 0.1}, 40),
		Job.new("autoclick_power_3", "Master Click Training", JobType.AUTOCLICK_POWER, 1200.0, 200, {"autoclick_power": 0.2}, 70),
		
		# Add more job types...
	]

func _initialize_office_currency():
	office_currency = 1000  # Starting currency

#==============================================================================
# Worker Management
#==============================================================================
func hire_worker(tier_index: int) -> bool:
	if tier_index < 0 or tier_index >= worker_tiers.size():
		return false
	
	var tier = worker_tiers[tier_index]
	
	# Check if we can afford it
	if office_currency < tier.hire_cost:
		return false
	
	# Check if we have space for more workers of this tier
	var current_tier_workers = workers.filter(func(w): return w.tier.tier_level == tier.tier_level)
	if current_tier_workers.size() >= tier.max_workers:
		return false
	
	# Create new worker
	var worker_names = _get_worker_names_for_tier(tier.tier_level)
	var worker_name = worker_names[randi() % worker_names.size()]
	var worker_id = "worker_%d_%d" % [tier.tier_level, workers.size()]
	
	var worker = Worker.new(worker_id, worker_name, tier)
	workers.append(worker)
	
	# Deduct cost
	office_currency -= tier.hire_cost
	office_currency_changed.emit(office_currency)
	
	worker_hired.emit(worker)
	if GameState.logger:
		GameState.logger.info("Hired %s %s for %d office currency" % [tier.tier_name, worker_name, tier.hire_cost])
	
	return true

func fire_worker(worker: Worker) -> bool:
	if not worker in workers:
		return false
	
	# Remove from current job if assigned
	if worker.assigned_job != "":
		_unassign_worker_from_job(worker)
	
	workers.erase(worker)
	worker_fired.emit(worker)
	if GameState.logger:
		GameState.logger.info("Fired worker %s" % worker.name)
	
	return true

func assign_worker_to_job(worker: Worker, job: Job) -> bool:
	if worker.assigned_job != "":
		return false  # Already assigned
	
	if worker.get_total_efficiency() < job.required_efficiency:
		return false  # Not efficient enough
	
	worker.assigned_job = job.job_id
	worker.job_start_time = Time.get_unix_time_from_system()
	worker.job_progress = 0.0
	
	if GameState.logger:
		GameState.logger.info("Assigned %s to %s" % [worker.name, job.job_name])
	return true

func _unassign_worker_from_job(worker: Worker):
	worker.assigned_job = ""
	worker.job_start_time = 0.0
	worker.job_progress = 0.0

#==============================================================================
# Job Processing
#==============================================================================
func _update_job_progress(delta: float):
	for worker in workers:
		if worker.assigned_job == "":
			continue
		
		var job = _get_job_by_id(worker.assigned_job)
		if not job:
			continue
		
		# Calculate progress based on worker efficiency and job duration
		var efficiency_multiplier = worker.get_total_efficiency() / 100.0
		var progress_rate = (1.0 / job.base_duration) * efficiency_multiplier
		worker.job_progress += progress_rate * delta
		
		# Check if job is completed
		if worker.job_progress >= 1.0:
			_complete_job(worker, job)

func _complete_job(worker: Worker, job: Job):
	# Check if worker successfully completes the job
	if not worker.can_complete_job():
		if GameState.logger:
			GameState.logger.info("%s failed to complete %s" % [worker.name, job.job_name])
		_unassign_worker_from_job(worker)
		return
	
	# Calculate rewards
	var base_reward = job.base_reward
	var creativity_bonus = worker.creativity / 100.0
	var total_reward = int(base_reward * (1.0 + creativity_bonus))
	
	# Add office currency
	office_currency += total_reward
	office_currency_changed.emit(office_currency)
	
	# Add experience to worker
	var exp_gain = base_reward / 2  # Experience based on job reward
	worker.add_experience(exp_gain)
	
	# Apply permanent stat bonuses if not already completed
	if not job.job_id in completed_jobs:
		_apply_job_bonuses(job)
		completed_jobs.append(job.job_id)
	
	# Unassign worker
	_unassign_worker_from_job(worker)
	
	job_completed.emit(job, worker, {"office_currency": total_reward, "experience": exp_gain})
	if GameState.logger:
		GameState.logger.info("%s completed %s! Gained %d office currency and %d experience" % [worker.name, job.job_name, total_reward, exp_gain])

func _apply_job_bonuses(job: Job):
	# Apply permanent stat bonuses to the game
	for stat in job.stat_bonus:
		var bonus = job.stat_bonus[stat]
		_apply_permanent_bonus(stat, bonus)

func _apply_permanent_bonus(stat: String, bonus: float):
	# Apply bonuses to appropriate managers
	match stat:
		"canvas_fill_speed":
			GameState.canvas_manager.add_fill_speed_bonus(bonus)
		"pixel_gain":
			GameState.currency_bonus_manager.add_pixel_gain_bonus(bonus)
		"autoclick_power":
			GameState.clicker_manager.add_click_power_bonus(bonus)
		"autoclick_speed":
			GameState.clicker_manager.add_autoclick_speed_bonus(bonus)
		"workshop_speed":
			GameState.craft_manager.add_workshop_speed_bonus(bonus)
		"canvas_storage":
			GameState.canvas_manager.add_storage_bonus(bonus)
		"fame_gain":
			GameState.currency_bonus_manager.add_fame_gain_bonus(bonus)
		"ascendancy_gain":
			GameState.currency_bonus_manager.add_ascendancy_gain_bonus(bonus)

#==============================================================================
# Utility Functions
#==============================================================================
func _get_job_by_id(job_id: String) -> Job:
	for job in available_jobs:
		if job.job_id == job_id:
			return job
	return null

func _get_worker_names_for_tier(tier_level: int) -> Array[String]:
	match tier_level:
		1: return ["Alex", "Sam", "Jordan", "Casey", "Riley"]
		2: return ["Morgan", "Taylor", "Avery", "Quinn", "Blake"]
		3: return ["Sage", "River", "Phoenix", "Skyler", "Rowan"]
		4: return ["Atlas", "Orion", "Luna", "Nova", "Zephyr"]
		5: return ["Artemis", "Apollo", "Athena", "Zeus", "Hera"]
		_: return ["Worker"]

func get_available_workers_for_tier(tier_index: int) -> Array[Worker]:
	var tier = worker_tiers[tier_index]
	return workers.filter(func(w): return w.tier.tier_level == tier.tier_level)

func get_available_jobs_for_worker(worker: Worker) -> Array[Job]:
	return available_jobs.filter(func(j): return worker.get_total_efficiency() >= j.required_efficiency)

#==============================================================================
# Public API
#==============================================================================
func get_office_currency() -> int:
	return office_currency

func add_office_currency(amount: int):
	office_currency += amount
	office_currency_changed.emit(office_currency)

func get_worker_tiers() -> Array[WorkerTier]:
	return worker_tiers

func get_workers() -> Array[Worker]:
	return workers

func get_available_jobs() -> Array[Job]:
	return available_jobs

func get_completed_jobs() -> Array[String]:
	return completed_jobs
