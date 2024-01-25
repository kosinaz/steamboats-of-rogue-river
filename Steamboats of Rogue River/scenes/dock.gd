class_name Dock
extends Node

var _caps: Cargo = Cargo.new(3)
var _items: Cargo = Cargo.new(12)
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(items: Array) -> void:
	for _i in range(_rng.randi_range(1, 6)):
		_items.add_new_item("wood", -1)
	var value = _rng.randi_range(1, 3)
	for _i in range(_rng.randi_range(1, 6)):
		_items.add_new_item(items[0], value)
	value += _rng.randi_range(1, 3)
	for _i in range(_rng.randi_range(1, 6)):
		_items.add_new_item(items[1], value)
