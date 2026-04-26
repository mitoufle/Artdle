extends PopupPanel

const GAMBLE_LEVELS: Array = [0, 10, 100, 1000, 10000]
const GAMBLE_LABELS: Array = ["Off", "10", "100", "1k", "10k"]

@onready var _style_slider: HSlider = $MarginContainer/VBoxContainer/Tabs/Configuration/StyleRow/StyleSlider
@onready var _style_header: Label = $MarginContainer/VBoxContainer/Tabs/Configuration/StyleRow/StyleLabel
@onready var _palette_slider: HSlider = $MarginContainer/VBoxContainer/Tabs/Configuration/PaletteRow/PaletteSlider
@onready var _palette_header: Label = $MarginContainer/VBoxContainer/Tabs/Configuration/PaletteRow/PaletteLabel
@onready var _subject_picker: OptionButton = $MarginContainer/VBoxContainer/Tabs/Configuration/SubjectRow/SubjectPicker
@onready var _gamble_level: OptionButton = $MarginContainer/VBoxContainer/Tabs/Configuration/GambleRow/GambleLevel
@onready var _buy_style: Button = $MarginContainer/VBoxContainer/Tabs/Improvement/BuyStyle
@onready var _buy_palette: Button = $MarginContainer/VBoxContainer/Tabs/Improvement/BuyPalette
@onready var _close_btn: Button = $MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
    _gamble_level.clear()
    for label in GAMBLE_LABELS:
        _gamble_level.add_item(label)
    _refresh_from_state()
    _style_slider.value_changed.connect(_on_style_changed)
    _palette_slider.value_changed.connect(_on_palette_changed)
    _subject_picker.item_selected.connect(_on_subject_changed)
    _gamble_level.item_selected.connect(_on_gamble_changed)
    _buy_style.pressed.connect(_on_buy_style)
    _buy_palette.pressed.connect(_on_buy_palette)
    _close_btn.pressed.connect(queue_free)
    GameState.currency.changed.connect(_on_currency_changed)

func _refresh_from_state() -> void:
    var cfg: CanvasConfig = GameState.canvas_config
    _style_slider.max_value = max(1, cfg.style_current_ceiling)
    _style_slider.value = cfg.style
    _style_header.text = "Style: %d / %d (cap %d)" % [cfg.style, cfg.style_current_ceiling, GameState.skill_tree.style_cap()]
    _palette_slider.max_value = max(1, cfg.palette_current_ceiling)
    _palette_slider.value = cfg.palette
    _palette_header.text = "Palette: %d / %d (cap %d)" % [cfg.palette, cfg.palette_current_ceiling, GameState.skill_tree.palette_cap()]
    _refresh_subject_picker(cfg)
    _gamble_level.selected = GAMBLE_LEVELS.find(cfg.gamble_n_inspi)
    _refresh_improvement(cfg)

func _refresh_subject_picker(cfg: CanvasConfig) -> void:
    _subject_picker.clear()
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
        elif GameState.subject_mastery.has_hint(sid):
            _subject_picker.add_item("? (%s)" % _hint_text_for(sid), idx)
            _subject_picker.set_item_metadata(idx, "")
            _subject_picker.set_item_disabled(idx, true)
            idx += 1

func _hint_text_for(sid: String) -> String:
    var subject: Dictionary = Subjects.get_subject(sid)
    var revealed: Array = []
    for p in (subject["parents"] as Array):
        if GameState.subject_mastery.tier_of(p["subject_id"]) >= SubjectMastery.HINT_HALF_TIER:
            revealed.append(String(Subjects.get_subject(p["subject_id"])["name"]))
    return ", ".join(revealed) if revealed.size() > 0 else "?"

func _refresh_improvement(cfg: CanvasConfig) -> void:
    var s_cap: int = GameState.skill_tree.style_cap()
    var p_cap: int = GameState.skill_tree.palette_cap()
    _buy_style.text = "Style ceiling +1 (%s g)" % Formatter.short(BigNumber.from_float(CanvasConfig.style_ceiling_cost(cfg.style_current_ceiling)))
    _buy_style.disabled = cfg.style_current_ceiling >= s_cap
    _buy_palette.text = "Palette ceiling +1 (%s g)" % Formatter.short(BigNumber.from_float(CanvasConfig.palette_ceiling_cost(cfg.palette_current_ceiling)))
    _buy_palette.disabled = cfg.palette_current_ceiling >= p_cap

func _on_style_changed(v: float) -> void:
    GameState.canvas_config.set_style(int(v))
    _refresh_from_state()

func _on_palette_changed(v: float) -> void:
    GameState.canvas_config.set_palette(int(v))
    _refresh_from_state()

func _on_subject_changed(idx: int) -> void:
    var sid: String = String(_subject_picker.get_item_metadata(idx))
    if sid != "":
        GameState.canvas_config.set_subject(sid)

func _on_gamble_changed(idx: int) -> void:
    GameState.canvas_config.set_gamble(GAMBLE_LEVELS[idx])

func _on_buy_style() -> void:
    GameState.buy_style_ceiling()
    _refresh_from_state()

func _on_buy_palette() -> void:
    GameState.buy_palette_ceiling()
    _refresh_from_state()

func _on_currency_changed(_kind: String, _v: float) -> void:
    _refresh_from_state()
