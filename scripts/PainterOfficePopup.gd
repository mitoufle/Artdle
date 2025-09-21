extends PopupPanel

## Painter Office UI - Manages workers, jobs, and office currency

#==============================================================================
# UI References
#==============================================================================
@onready var office_currency_label: Label = $VBoxContainer/Header/OfficeCurrency
@onready var worker_tiers_container: VBoxContainer = $VBoxContainer/TabContainer/Workers/HireSection/WorkerTiersContainer
@onready var workers_list: VBoxContainer = $VBoxContainer/TabContainer/Workers/CurrentWorkersSection/WorkersList
@onready var jobs_list: VBoxContainer = $VBoxContainer/TabContainer/Jobs/JobsList
@onready var close_button: Button = $VBoxContainer/CloseButton

#==============================================================================
# State
#==============================================================================
var worker_ui_elements: Array[Control] = []
var job_ui_elements: Array[Control] = []

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready():
	close_button.pressed.connect(_on_close_button_pressed)
	GameState.worker_manager.office_currency_changed.connect(_on_office_currency_changed)
	GameState.worker_manager.worker_hired.connect(_on_worker_hired)
	GameState.worker_manager.worker_fired.connect(_on_worker_fired)
	GameState.worker_manager.job_completed.connect(_on_job_completed)
	
	# Popup centering is handled by initial_position = 2 in the scene
	
	_update_office_currency_display()
	_create_worker_tier_buttons()
	_update_workers_display()
	_update_jobs_display()

#==============================================================================
# UI Updates
#==============================================================================
func _update_office_currency_display():
	var currency = GameState.worker_manager.get_office_currency()
	office_currency_label.text = "Office Currency: %s" % BigNumberManager.format_number(currency)

func _create_worker_tier_buttons():
	# Clear existing buttons
	for child in worker_tiers_container.get_children():
		child.queue_free()
	
	var tiers = GameState.worker_manager.get_worker_tiers()
	for i in range(tiers.size()):
		var tier = tiers[i]
		var button = _create_tier_button(tier, i)
		worker_tiers_container.add_child(button)

func _create_tier_button(tier: WorkerManager.WorkerTier, tier_index: int) -> Button:
	var button = Button.new()
	button.text = "Hire %s (%s)" % [tier.tier_name, BigNumberManager.format_number(tier.hire_cost)]
	button.pressed.connect(_on_hire_worker_pressed.bind(tier_index))
	
	# Disable if can't afford
	if GameState.worker_manager.get_office_currency() < tier.hire_cost:
		button.disabled = true
	
	return button

func _update_workers_display():
	# Clear existing worker UI elements
	for element in worker_ui_elements:
		element.queue_free()
	worker_ui_elements.clear()
	
	var workers = GameState.worker_manager.get_workers()
	for worker in workers:
		var worker_ui = _create_worker_ui(worker)
		workers_list.add_child(worker_ui)
		worker_ui_elements.append(worker_ui)

func _create_worker_ui(worker: WorkerManager.Worker) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	
	# Worker info
	var info_label = Label.new()
	info_label.text = "%s (Level %d) - %s" % [worker.name, worker.level, worker.tier.tier_name]
	container.add_child(info_label)
	
	# Stats
	var stats_label = Label.new()
	stats_label.text = "Efficiency: %d | Creativity: %d | Reliability: %d | Specialization: %d" % [
		worker.efficiency, worker.creativity, worker.reliability, worker.specialization
	]
	container.add_child(stats_label)
	
	# Experience
	var exp_label = Label.new()
	exp_label.text = "Experience: %d/%d" % [worker.experience, worker.experience_to_next_level]
	container.add_child(exp_label)
	
	# Job assignment
	var job_label = Label.new()
	if worker.assigned_job != "":
		var job = GameState.worker_manager._get_job_by_id(worker.assigned_job)
		if job:
			job_label.text = "Assigned to: %s (%.1f%%)" % [job.job_name, worker.job_progress * 100]
		else:
			job_label.text = "Assigned to: Unknown Job"
	else:
		job_label.text = "No job assigned"
	container.add_child(job_label)
	
	# Action buttons
	var button_container = HBoxContainer.new()
	
	var assign_button = Button.new()
	assign_button.text = "Assign Job"
	assign_button.pressed.connect(_on_assign_job_pressed.bind(worker))
	button_container.add_child(assign_button)
	
	var fire_button = Button.new()
	fire_button.text = "Fire"
	fire_button.pressed.connect(_on_fire_worker_pressed.bind(worker))
	button_container.add_child(fire_button)
	
	container.add_child(button_container)
	
	# Add separator
	var separator = HSeparator.new()
	container.add_child(separator)
	
	return container

func _update_jobs_display():
	# Clear existing job UI elements
	for element in job_ui_elements:
		element.queue_free()
	job_ui_elements.clear()
	
	var jobs = GameState.worker_manager.get_available_jobs()
	for job in jobs:
		var job_ui = _create_job_ui(job)
		jobs_list.add_child(job_ui)
		job_ui_elements.append(job_ui)

func _create_job_ui(job: WorkerManager.Job) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	
	# Job info
	var info_label = Label.new()
	info_label.text = "%s" % job.job_name
	container.add_child(info_label)
	
	# Job details
	var details_label = Label.new()
	details_label.text = "Duration: %.1fs | Reward: %s | Required Efficiency: %d" % [
		job.base_duration, BigNumberManager.format_number(job.base_reward), job.required_efficiency
	]
	container.add_child(details_label)
	
	# Stat bonus
	var bonus_label = Label.new()
	var bonus_text = "Permanent Bonuses: "
	for stat in job.stat_bonus:
		bonus_text += "%s +%.1f%% " % [stat, job.stat_bonus[stat] * 100]
	bonus_label.text = bonus_text
	container.add_child(bonus_label)
	
	# Add separator
	var separator = HSeparator.new()
	container.add_child(separator)
	
	return container

#==============================================================================
# Signal Handlers
#==============================================================================
func _on_close_button_pressed():
	hide()

func _on_office_currency_changed(new_amount: int):
	_update_office_currency_display()
	# Update hire buttons
	_create_worker_tier_buttons()

func _on_worker_hired(worker: WorkerManager.Worker):
	_update_workers_display()
	if GameState.logger:
		GameState.logger.info("Worker %s hired!" % worker.name)

func _on_worker_fired(worker: WorkerManager.Worker):
	_update_workers_display()
	if GameState.logger:
		GameState.logger.info("Worker %s fired!" % worker.name)

func _on_job_completed(job: WorkerManager.Job, worker: WorkerManager.Worker, bonus: Dictionary):
	_update_workers_display()
	if GameState.logger:
		GameState.logger.info("Job %s completed by %s!" % [job.job_name, worker.name])

func _on_hire_worker_pressed(tier_index: int):
	var success = GameState.worker_manager.hire_worker(tier_index)
	if success:
		if GameState.logger:
			GameState.logger.info("Successfully hired worker!")
	else:
		if GameState.logger:
			GameState.logger.warning("Failed to hire worker - insufficient currency or max workers reached")

func _on_assign_job_pressed(worker: WorkerManager.Worker):
	# Simple job assignment - assign to first available job
	var available_jobs = GameState.worker_manager.get_available_jobs_for_worker(worker)
	if available_jobs.size() > 0:
		var job = available_jobs[0]  # Assign to first available job
		var success = GameState.worker_manager.assign_worker_to_job(worker, job)
		if success:
			if GameState.logger:
				GameState.logger.info("Assigned %s to %s" % [worker.name, job.job_name])
			_update_workers_display()
		else:
			if GameState.logger:
				GameState.logger.warning("Failed to assign job")
	else:
		if GameState.logger:
			GameState.logger.warning("No available jobs for this worker")

func _on_fire_worker_pressed(worker: WorkerManager.Worker):
	var success = GameState.worker_manager.fire_worker(worker)
	if success:
		if GameState.logger:
			GameState.logger.info("Worker fired successfully!")
	else:
		if GameState.logger:
			GameState.logger.warning("Failed to fire worker")
