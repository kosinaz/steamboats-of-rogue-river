class_name Cargo
extends Node

signal added(item)

var _items: Array = []

func add(item: Item) -> void:
	_items.append(item)
	emit_signal("added")

func add_new_item(new_item_name, new_value) -> void:
	var item = Item.new().set_attributes(new_item_name, new_value)
	add(item)

func move(idx: int, target: Cargo) -> void:
	if _items.size() <= idx: return
	target.add(_items[idx])
	_items.remove(idx)
	emit_signal("added")
	target.emit_signal("added")

func get_item(i: int) -> Item:
	if _items.size() > i:
		return _items[i]
	return null

func get_items() -> Array:
	return _items
