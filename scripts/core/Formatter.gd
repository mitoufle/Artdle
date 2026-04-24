class_name Formatter
extends RefCounted

const SUFFIXES: Array[String] = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

static func short(n: BigNumber) -> String:
    var v: float = n.value
    if v < 1000.0:
        return str(int(v))
    var tier: int = 0
    while v >= 1000.0 and tier < SUFFIXES.size() - 1:
        v /= 1000.0
        tier += 1
    return "%.2f%s" % [v, SUFFIXES[tier]]
