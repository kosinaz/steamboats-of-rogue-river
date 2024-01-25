class_name Dock
extends Node

var _caps: Cargo = Cargo.new(3)
var _items: Cargo = Cargo.new(12)
var _id: int = 0

func _init(id: int):
	_id = id

func add_cap(cap_name: String, value: int) -> void:
	_caps.add_new_item(cap_name, _id, value)

func add_items(item_name: String, value: int, count: int) -> void:
	for _i in range(count):
		_items.add_new_item(item_name, _id, value)

func get_caps() -> Cargo:
	return _caps

func get_items() -> Cargo:
	return _items
