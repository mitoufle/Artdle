class_name Icons
extends RefCounted

# Registry: id → resource path. Extend as new game elements need icons.
const ICONS: Dictionary = {
    "gold":           "res://artdleAsset/Currency/coin.png",
    "fame":           "res://artdleAsset/Currency/fame.png",
    "inspiration":    "res://artdleAsset/Inspiration.png",
    "paint_mastery":  "res://artdleAsset/Currency/Painting_mastery.png",
}

static func has(id: String) -> bool:
    return ICONS.has(id)

static func bbcode(id: String, height: int = 16) -> String:
    if not ICONS.has(id):
        push_warning("Icons.bbcode: unknown id '%s'" % id)
        return ""
    return "[img height=%d]%s[/img]" % [height, ICONS[id]]
