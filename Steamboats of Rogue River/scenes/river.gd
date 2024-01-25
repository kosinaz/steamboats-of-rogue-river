class_name River
extends Node

var CAPS: Array = ["cap1", "cap2", "cap3", "cap4", "cap5", "cap6"]
var ITEMS: Array = ["anchor", "ball", "barrel", "bottles", "bowl", "cannon", "canoe", "chest", "crate", "fish", "sack", "vase"]
var _map: Array = []

func _init() -> void:
	randomize()
	var caps = CAPS.duplicate()
	caps.shuffle()
	var items = ITEMS.duplicate()
	items.shuffle()
	for _i in range(6):
		_map.append(Dock.new([items.pop_front(), items.pop_front()]))
