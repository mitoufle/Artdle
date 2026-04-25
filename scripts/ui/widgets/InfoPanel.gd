extends PanelContainer

@onready var title_label: RichTextLabel = $MarginContainer/HBoxContainer/TitleLabel
@onready var body_label: RichTextLabel = $MarginContainer/HBoxContainer/BodyLabel
@onready var footer_label: RichTextLabel = $MarginContainer/HBoxContainer/FooterLabel

func _ready() -> void:
    GameState.hover_info_pushed.connect(set_content)
    GameState.hover_info_cleared.connect(clear)
    clear()

func set_content(title: String, body: String, footer: String) -> void:
    if title_label == null:
        return
    title_label.text = title
    body_label.text = body
    footer_label.text = footer

func clear() -> void:
    if title_label == null:
        return
    title_label.text = ""
    body_label.text = ""
    footer_label.text = ""
