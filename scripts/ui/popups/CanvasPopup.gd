extends PopupPanel

const GAMBLE_LEVELS: Array = [0, 10, 100, 1000, 10000]
const GAMBLE_LABELS: Array = ["Off", "10", "100", "1k", "10k"]

@onready var _style_slider: HSlider = $MarginContainer/VBoxContainer/Tabs/Configuration/StyleRow/StyleSlider
@onready var _style_header: Label = $MarginContainer/VBoxContainer/Tabs/Configuration/StyleRow/StyleLabel
@onready var _palette_slider: HSlider = $MarginContainer/VBoxContainer/Tabs/Configuration/PaletteRow/PaletteSlider
@onready var _palette_header: Label = $MarginContainer/VBoxContainer/Tabs/Configuration/PaletteRow/PaletteLabel
@onready var _subject_picker: OptionButton = $MarginContainer/VBoxContainer/Tabs/Configuration/SubjectRow/SubjectPicker
@onready var _gamble_level: OptionButton = $MarginContainer/VBoxContainer/Tabs/Configuration/GambleRow/GambleLevel
@onready var _upgrade_tier: Button = $MarginContainer/VBoxContainer/Tabs/Improvement/UpgradeTier
@onready var _buy_style: Button = $MarginContainer/VBoxContainer/Tabs/Improvement/BuyStyle
@onready var _buy_palette: Button = $MarginContainer/VBoxContainer/Tabs/Improvement/BuyPalette
@onready var _close_btn: Button = $MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
    _refresh_all()
    _style_slider.value_changed.connect(_on_style_changed)
    _palette_slider.value_changed.connect(_on_palette_changed)
    _subject_picker.item_selected.connect(_on_subject_changed)
    _gamble_level.item_selected.connect(_on_gamble_changed)
    _upgrade_tier.pressed.connect(_on_upgrade_tier)
    _buy_style.pressed.connect(_on_buy_style)
    _buy_palette.pressed.connect(_on_buy_palette)
    _close_btn.pressed.connect(queue_free)
    # Targeted signals avoid rebuilding the 20-item subject picker on every gold tick (I3).
    GameState.currency.changed.connect(_on_currency_changed)
    GameState.subject_mastery.mastery_changed.connect(_on_mastery_changed)
    GameState.skill_tree.node_unlocked.connect(_on_skill_node_unlocked)

func _refresh_all() -> void:
    _refresh_sliders_and_headers()
    _refresh_gamble_picker()
    _refresh_subject_picker(GameState.canvas_config)
    _refresh_improvement(GameState.canvas_config)

func _refresh_sliders_and_headers() -> void:
    var cfg: CanvasConfig = GameState.canvas_config
    _style_slider.max_value = max(1, cfg.style_current_ceiling)
    _style_slider.value = cfg.style
    _style_header.text = "Style: %d / %d (cap %d)" % [cfg.style, cfg.style_current_ceiling, GameState.skill_tree.style_cap()]
    _palette_slider.max_value = max(1, cfg.palette_current_ceiling)
    _palette_slider.value = cfg.palette
    _palette_header.text = "Palette: %d / %d (cap %d)" % [cfg.palette, cfg.palette_current_ceiling, GameState.skill_tree.palette_cap()]
    _gamble_level.selected = _gamble_index_for_state(cfg)

func _refresh_gamble_picker() -> void:
    # Rebuild only when always-gamble unlock state actually changes (cheap check via item_count).
    var want_count: int = GAMBLE_LABELS.size() + (1 if GameState.skill_tree.always_gamble_unlocked() else 0)
    if _gamble_level.item_count == want_count:
        return
    _gamble_level.clear()
    for label in GAMBLE_LABELS:
        _gamble_level.add_item(label)
    if GameState.skill_tree.always_gamble_unlocked():
        _gamble_level.add_item("Always (auto)")

func _gamble_index_for_state(cfg: CanvasConfig) -> int:
    if cfg.auto_gamble:
        return GAMBLE_LABELS.size()  # the "Always" entry, appended after the levels
    return GAMBLE_LEVELS.find(cfg.gamble_n_inspi)

func _refresh_subject_picker(cfg: CanvasConfig) -> void:
    _subject_picker.clear()
    var threshold: int = _hint_threshold()
    var idx: int = 0
    for sid in Subjects.all_ids():
        var subject: Dictionary = Subjects.get_subject(sid)
        var name: String = String(subject.get("name", sid))
        if GameState.subject_mastery.is_unlocked(sid):
            _subject_picker.add_item(name, idx)
            _subject_picker.set_item_metadata(idx, sid)
            if sid == cfg.current_subject:
                _subject_picker.selected = idx
            idx += 1
        elif GameState.subject_mastery.has_hint(sid, threshold):
            _subject_picker.add_item("? (%s)" % _hint_text_for(sid, threshold), idx)
            _subject_picker.set_item_metadata(idx, "")
            _subject_picker.set_item_disabled(idx, true)
            idx += 1

func _hint_threshold() -> int:
    # Skill-tree Subject Hint nodes lower the parent-mastery threshold for revealing
    # a `?` subject's prereqs. Each unlock peels one tier off (default 3 → 2 → 1).
    return max(1, SubjectMastery.HINT_HALF_TIER - GameState.skill_tree.subject_hint_count())

func _hint_text_for(sid: String, threshold: int) -> String:
    var subject: Dictionary = Subjects.get_subject(sid)
    var revealed: Array = []
    for p in (subject["parents"] as Array):
        if GameState.subject_mastery.tier_of(p["subject_id"]) >= threshold:
            revealed.append(String(Subjects.get_subject(p["subject_id"])["name"]))
    return ", ".join(revealed) if revealed.size() > 0 else "?"

func _refresh_improvement(cfg: CanvasConfig) -> void:
    var s_cap: int = GameState.skill_tree.style_cap()
    var p_cap: int = GameState.skill_tree.palette_cap()
    var tier: int = GameState._canvas_tier
    if tier >= CanvasTiers.MAX_TIER:
        _upgrade_tier.text = "Canvas tier %d (max)" % tier
        _upgrade_tier.disabled = true
    else:
        var tier_cost: BigNumber = CanvasTiers.upgrade_cost(tier)
        _upgrade_tier.text = "Canvas tier %d → %d (%s gold)" % [tier, tier + 1, Formatter.short(tier_cost)]
        _upgrade_tier.disabled = not GameState.currency.get_amount("gold").gte(tier_cost)
    _buy_style.text = "Style ceiling +1 (%s gold)" % Formatter.short(BigNumber.from_float(CanvasConfig.style_ceiling_cost(cfg.style_current_ceiling)))
    _buy_style.disabled = cfg.style_current_ceiling >= s_cap
    _buy_palette.text = "Palette ceiling +1 (%s gold)" % Formatter.short(BigNumber.from_float(CanvasConfig.palette_ceiling_cost(cfg.palette_current_ceiling)))
    _buy_palette.disabled = cfg.palette_current_ceiling >= p_cap

func _on_style_changed(v: float) -> void:
    GameState.canvas_config.set_style(int(v))
    _refresh_sliders_and_headers()

func _on_palette_changed(v: float) -> void:
    GameState.canvas_config.set_palette(int(v))
    _refresh_sliders_and_headers()

func _on_subject_changed(idx: int) -> void:
    var sid: String = String(_subject_picker.get_item_metadata(idx))
    if sid != "":
        GameState.canvas_config.set_subject(sid)

func _on_gamble_changed(idx: int) -> void:
    if idx < GAMBLE_LEVELS.size():
        GameState.canvas_config.set_gamble(GAMBLE_LEVELS[idx])
    else:
        GameState.canvas_config.set_auto_gamble()

func _on_upgrade_tier() -> void:
    var tier: int = GameState._canvas_tier
    if tier >= CanvasTiers.MAX_TIER:
        return
    var cost: BigNumber = CanvasTiers.upgrade_cost(tier)
    if GameState.currency.spend("gold", cost):
        GameState.upgrade_canvas_tier()
    # currency.changed signal will refresh improvement buttons; tier text needs explicit update.
    _refresh_improvement(GameState.canvas_config)

func _on_buy_style() -> void:
    GameState.buy_style_ceiling()
    # currency.changed handler updates buttons; ceiling change needs slider/header update.
    _refresh_sliders_and_headers()

func _on_buy_palette() -> void:
    GameState.buy_palette_ceiling()
    _refresh_sliders_and_headers()

func _on_currency_changed(_kind: String, _v: float) -> void:
    # Cheap: just the gold-gated buttons. NO subject picker rebuild.
    _refresh_improvement(GameState.canvas_config)

func _on_mastery_changed(_sid: String, _tier: int, _xp: int) -> void:
    _refresh_subject_picker(GameState.canvas_config)

func _on_skill_node_unlocked(_node_id: String) -> void:
    # Caps, hint threshold, and always-gamble unlock can all change via skill tree.
    _refresh_all()
