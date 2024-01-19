class_name Item
extends Node

## The id and image of the item.
var item_name: String = ""

## The price of the item.
var value: int = 0

## The current distance from the dock where the item will be removed.
var distance: int = 0

func set_attributes(new_item_name, new_value) -> Item:
	item_name = new_item_name
	value = new_value
	distance = new_value
	return self
