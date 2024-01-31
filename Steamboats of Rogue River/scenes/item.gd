class_name Item
extends Node

## The id and image of the item.
var _item_name: String = ""

## The price of the item.
var _price: int = 0

## The distance it will stay on the boat.
var _distance: int = 0

## The id of the dock where the item can be picked up.
var _dock: int = 0

func _init(new_item_name, new_dock, new_distance, new_price) -> void:
	_item_name = new_item_name
	_dock = new_dock
	_price = new_price
	_distance = new_distance
	
func get_name() -> String:
	return _item_name
	
func get_price() -> int:
	return _price
	
func get_dock() -> int:
	return _dock
	
func get_destination() -> int:
	return _dock + _distance
