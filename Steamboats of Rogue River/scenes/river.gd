class_name River
extends Node

var CAPS: Array = ["cap1", "cap2", "cap3", "cap4", "cap5", "cap6"]
var ITEMS: Array = ["anchor", "ball", "barrel", "bottles", "bowl", "cannon", "canoe", "chest", "crate", "fish", "sack", "vase"]
var _caps: Array = []
var _items: Array = []
var _map: Array = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	randomize()
	_caps = CAPS.duplicate()
	_caps.shuffle()
	_items = ITEMS.duplicate()
	_items.shuffle()
	for dock_id in range(6):
		_init_dock(dock_id)
	_add_caps()

func _init_dock(dock_id) -> void:
	var dock = Dock.new(dock_id)
	dock.add_items("wood", -1, _rng.randi_range(1, 6))
	var value = _rng.randi_range(1, 3)
	dock.add_items(_items.pop_front(), value, _rng.randi_range(1, 5))
	value += _rng.randi_range(1, 3)
	dock.add_items(_items.pop_front(), value, _rng.randi_range(1, 5))
	_map.append(dock)

func _add_caps() -> void:
	var value = _rng.randi_range(3, 4)
	_map[0].add_cap(_caps.pop_front(), value)
	value += _rng.randi_range(1, 2)
	_map[0].add_cap(_caps.pop_front(), value)

func get_dock_caps(dock_id) -> Cargo:
	return _map[dock_id].get_caps()

func get_dock_items(dock_id) -> Cargo:
	return _map[dock_id].get_items()
