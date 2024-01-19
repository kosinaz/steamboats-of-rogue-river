extends Node2D

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _balance: int = 10
var _dock_items: Cargo = Cargo.new(15)
var _boat_items: Cargo = Cargo.new(6)
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
	_dock_items.connect("updated", self, "_update_container", [_dock_container])
	# warning-ignore:return_value_discarded
	_boat_items.connect("updated", self, "_update_container", [_boat_container])
	var item_button_packed_scene: PackedScene = load("res://scenes/item_button.tscn")
	for i in range(_dock_items.get_size()):
		var item_button: TextureButton = item_button_packed_scene.instance()
		_dock_container.add_child(item_button)
		# warning-ignore:return_value_discarded
		item_button.connect("pressed", self, "_on_item_button_pressed", [_dock_container, i])
	for i in range(_boat_items.get_size()):
		var item_button: TextureButton = item_button_packed_scene.instance()
		_boat_container.add_child(item_button)
		# warning-ignore:return_value_discarded
		item_button.connect("pressed", self, "_on_item_button_pressed", [_boat_container, i])
	_dock_items.add_new_item("cap1", -5)
	_dock_items.add_new_item("cap2", -6)
	for _i in range(_rng.randi_range(2, 4)):
		_dock_items.add_new_item("wood", -1)
	for _i in range(_rng.randi_range(1, 3)):
		_dock_items.add_new_item("crate", 1)
	for _i in range(_rng.randi_range(1, 3)):
		_dock_items.add_new_item("barrel", 2)
	_update_river_miles()
		
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
	for mile in _river_miles.get_children():
		mile.get_node("Item").texture = null
	var items = _boat_items if _moving else _dock_items
	for item in items.get_items():
		if item.item_name == "wood": continue
		# warning-ignore:narrowing_conversion
		var mile = _river_miles.get_child(abs(item.value) - 1)
		mile.get_node("Item").texture = load("res://assets/" + item.item_name + ".png")

func _arrive(item: Sprite) -> void:
	_moving = false
	print(item)

func _update_balance(value):
	_balance += value
	$"%BalanceLabel".text = "$" + str(_balance)
	
func _on_item_button_pressed(container: GridContainer, i: int) -> void:
	if _dock_container == container:
		var item = _dock_items.get_item(i)
		if item == null: return
		if _boat_items.is_full(): return
		if item.value < 0:
			if -item.value > _balance: return
			_update_balance(item.value)
		_dock_items.move(i, _boat_items)
	else:
		var item = _boat_items.get_item(i)
		if item == null: return
		if item.value < 0:
			_update_balance(-item.value)
		_boat_items.move(i, _dock_items)

func _on_go_button_pressed():
	_go_button.disabled = true
	_moving = true
	_update_river_miles()
