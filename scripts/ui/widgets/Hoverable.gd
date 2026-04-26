extends Node

@export var title: String = ""
@export var body: String = ""
@export var footer: String = ""

# Optional. Must return Array of length 3 — [title, body, footer].
# Set from code after instantiating; not @export because Callables aren't editable in the inspector.
var content_provider: Callable = Callable()

func _ready() -> void:
	var p = get_parent()
	if not (p is Control):
		push_error("Hoverable: parent is not a Control (got %s)" % p)
		return
	p.mouse_entered.connect(_on_mouse_entered)
	p.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	var t: String = title
	var b: String = body
	var f: String = footer
	if content_provider.is_valid():
		var arr: Array = content_provider.call()
		if arr.size() != 3:
			push_warning("Hoverable.content_provider returned %d elements, expected 3" % arr.size())
		t = arr[0] if arr.size() > 0 else ""
		b = arr[1] if arr.size() > 1 else ""
		f = arr[2] if arr.size() > 2 else ""
	GameState.push_hover_info(t, b, f)

func _on_mouse_exited() -> void:
	GameState.clear_hover_info()
