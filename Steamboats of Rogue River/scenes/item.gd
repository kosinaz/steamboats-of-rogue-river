class_name Item
extends Node

## The id and image of the item.
var _item_name: String = ""

## The price of the item and the distance it will stay on the boat.
var _value: int = 0

## The id of the dock where the item can be picked up.
var _dock: int = 0

func _init(new_item_name, new_dock, new_value) -> void:
	_item_name = new_item_name
	_dock = new_dock
	_value = new_value
	
func _get_name() -> String:
	return _item_name
	
func _get_value() -> int:
	return _value
	
func _get_dock() -> int:
	return _dock
	
func _get_destination() -> int:
	return _dock + int(abs(_value))
