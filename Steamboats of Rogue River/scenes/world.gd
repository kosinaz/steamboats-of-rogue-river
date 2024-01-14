extends Node2D

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var balance: int = 10
onready var balance_label: Label = $"%BalanceLabel"
onready var dock_container: GridContainer = $"%DockContainer"
onready var boat_container: GridContainer = $"%BoatContainer"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	balance_label.text = "$" + str(balance)
	rng.randomize()
	_add_item("res://scenes/cap1.tscn", -5)
	_add_item("res://scenes/cap2.tscn", -6)
	for _i in range(rng.randi_range(2, 4)):
		_add_item("res://scenes/wood.tscn", -1)
	for _i in range(rng.randi_range(1, 3)):
		_add_item("res://scenes/crate.tscn", 1)
	for _i in range(rng.randi_range(1, 3)):
		_add_item("res://scenes/barrel.tscn", 2)

func _add_item(path: String, value: int) -> void:
	var item: Node = load(path).instance()
	dock_container.add_child(item)
	# warning-ignore:return_value_discarded
	item.connect("pressed", self, "_on_item_pressed", [item, value])
	
	
func _on_item_pressed(item: Node, value: int) -> void:
	if dock_container.is_a_parent_of(item):
		if value < 0:
			if balance + value < 0: return
			balance += value
			balance_label.text = "$" + str(balance)
		dock_container.remove_child(item)
		boat_container.add_child(item)
			
	elif boat_container.is_a_parent_of(item):
		if value < 0:
			balance -= value
			balance_label.text = "$" + str(balance)
		boat_container.remove_child(item)
		dock_container.add_child(item)
