extends Node2D

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _balance: int = 10 setget _set_balance
var _dock_items: Cargo = Cargo.new()
var _boat_items: Cargo = Cargo.new()
var _moving: bool = false
onready var _dock: TileMap = $"%Dock"
onready var _dock_container: GridContainer = $"%DockContainer"
onready var _boat_container: GridContainer = $"%BoatContainer"
onready var _river_miles: Node = $"%RiverMiles"
onready var _go_button: TextureButton = $"%GoButton"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_rng.randomize()
	# warning-ignore:return_value_discarded
	_dock_items.connect("added", self, "_update_container", [_dock_container])
	# warning-ignore:return_value_discarded
	_dock_items.connect("added", self, "_update_river_miles")
	# warning-ignore:return_value_discarded
	_boat_items.connect("added", self, "_update_container", [_boat_container])
	for i in range(15):
		var button: TextureButton = load("res://scenes/item_button.tscn").instance()
		_dock_container.add_child(button)
		# warning-ignore:return_value_discarded
		button.connect("pressed", self, "_on_item_pressed", [_dock_container, i])
	for i in range(6):
		var button: TextureButton = load("res://scenes/item_button.tscn").instance()
		_boat_container.add_child(button)
		# warning-ignore:return_value_discarded
		button.connect("pressed", self, "_on_item_pressed", [_boat_container, i])
	_dock_items.add_new_item("cap1", -5)
	_dock_items.add_new_item("cap2", -6)
	for _i in range(_rng.randi_range(2, 4)):
		_dock_items.add_new_item("wood", -1)
	for _i in range(_rng.randi_range(1, 3)):
		_dock_items.add_new_item("crate", 1)
	for _i in range(_rng.randi_range(1, 3)):
		_dock_items.add_new_item("barrel", 2)
		
func _process(_delta) -> void:
	if not _moving: return
	if _dock.position.x > -576 * 2:
		_dock.position.x -= 4
	else:
		_dock.position.x = -576
	for mile in _river_miles.get_children():
		if mile.position.x < 0:
			for mile_to_reset in _river_miles.get_children():
				mile_to_reset.position.x += 64
			break
		else:
			mile.position.x -= 0.1

func _update_container(container: GridContainer) -> void:
	var items = _dock_items if _dock_container == container else _boat_items
	for i in range(container.get_children().size()):
		if items.get_item(i):
			container.get_children()[i].texture_normal = load("res://assets/" + items.get_item(i).item_name + "big.png")
		else:
			container.get_children()[i].texture_normal = load("res://assets/no_item.png")

func _update_river_miles() -> void:
	for item in _dock_items.get_items():
		# warning-ignore:narrowing_conversion
		var mile = _river_miles.get_child(abs(item.value) - 1)
		mile.get_node("Item").texture = load("res://assets/" + item.item_name + ".png")

func _arrive(item: Sprite) -> void:
	_moving = false
	print(item)

func _set_balance(value):
	_balance = value
	$"%BalanceLabel".text = "$" + str(_balance)
	
func _on_item_pressed(container: GridContainer, idx: int) -> void:
	if _dock_container == container:
		_dock_items.move(idx, _boat_items)
	else:
		_boat_items.move(idx, _dock_items)

func _on_go_button_pressed():
	_go_button.disabled = true
	_moving = true
