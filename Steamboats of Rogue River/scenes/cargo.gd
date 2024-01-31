class_name Cargo
extends Node

signal updated()

var _items: Array = []
var _size: int = 0

func _init(size) -> void:
	_size = size

func add(item: Item) -> void:
	if is_full(): return
	_items.append(item)
	emit_signal("updated")

func add_new_item(new_item_name, new_dock, new_value) -> void:
	var item = Item.new(new_item_name, new_dock, new_value)
	add(item)

func move(id: int, target: Cargo) -> void:
	if _items.size() <= id: return
	target.add(_items[id])
	remove(id)

func remove(id: int) -> void:
	print(_items[id].get_name(), " removed")
	_items.remove(id)
	emit_signal("updated")

func get_item(i: int) -> Item:
	if _items.size() > i:
		return _items[i]
	return null

func get_items() -> Array:
	return _items
	
func get_size() -> int:
	return _size

func is_full() -> bool:
	return _size == _items.size()

func has_type_of_item(item_name: String) -> bool:
	for item in _items:
		if item.get_name() == item_name:
			return true
	return false

func has_any_item() -> bool:
	return get_item(0) != null

func clear() -> void:
	_items = []
	emit_signal("updated")
	
