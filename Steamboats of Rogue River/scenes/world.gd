extends Node2D

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _balance: int = 10
var _dock_caps: Cargo = Cargo.new(3)
var _dock_items: Cargo = Cargo.new(12)
var _boat_caps: Cargo = Cargo.new(1)
var _boat_items: Cargo = Cargo.new(6)
var _moving: bool = false
onready var _dock: TileMap = $"%Dock"
onready var _dock_cap_container: GridContainer = $"%DockCapContainer"
onready var _dock_item_container: GridContainer = $"%DockItemContainer"
onready var _boat_cap_container: GridContainer = $"%BoatCapContainer"
onready var _boat_item_container: GridContainer = $"%BoatItemContainer"
onready var _river_miles: Node = $"%RiverMiles"
onready var _go_button: TextureButton = $"%GoButton"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_rng.randomize()
	_init_container(_dock_caps, _dock_cap_container)
	_init_container(_dock_items, _dock_item_container)
	_init_container(_boat_caps, _boat_cap_container)
	_init_container(_boat_items, _boat_item_container)
	_dock_caps.add_new_item("cap1", -5)
	_dock_caps.add_new_item("cap2", -6)
	for _i in range(_rng.randi_range(2, 4)):
		_dock_items.add_new_item("wood", -1)
	for _i in range(_rng.randi_range(1, 3)):
		_dock_items.add_new_item("crate", 2)
	for _i in range(_rng.randi_range(1, 3)):
		_dock_items.add_new_item("barrel", 4)
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

func _init_container(cargo: Cargo, container: GridContainer) -> void:
	# warning-ignore:return_value_discarded
	cargo.connect("updated", self, "_update_container", [container])
	var item_button_packed_scene: PackedScene = load("res://scenes/item_button.tscn")
	for i in range(cargo.get_size()):
		var item_button: TextureButton = item_button_packed_scene.instance()
		container.add_child(item_button)
		# warning-ignore:return_value_discarded
		item_button.connect("pressed", self, "_on_item_button_pressed", [container, i])

func _update_container(container: GridContainer) -> void:
	var items = null
	match container:
		_dock_cap_container: 
			items = _dock_caps
		_dock_item_container: 
			items = _dock_items
		_boat_cap_container: 
			items = _boat_caps
		_boat_item_container: 
			items = _boat_items
	for i in range(container.get_children().size()):
		if items.get_item(i):
			container.get_children()[i].texture_normal = load("res://assets/" + items.get_item(i).item_name + "big.png")
		else:
			container.get_children()[i].texture_normal = load("res://assets/no_item.png")
	_go_button.disabled = not _is_ready_to_go()

func _update_river_miles() -> void:
	for mile in _river_miles.get_children():
		mile.get_node("Item").texture = null
	var items = _dock_items.get_items() + _dock_caps.get_items()
	if _moving:
		items = _boat_items.get_items() + _boat_caps.get_items()
	for item in items:
		if item.item_name == "wood": continue
		# warning-ignore:narrowing_conversion
		var mile = _river_miles.get_child(abs(item.value) - 1)
		mile.get_node("Item").texture = load("res://assets/" + item.item_name + ".png")

func _arrive(item: Sprite) -> void:
	_moving = false
	print(item)

func _update_balance(value: int):
	_balance += value
	$"%BalanceLabel".text = "$" + str(_balance)
	
func _on_item_button_pressed(container: GridContainer, i: int) -> void:
	if _moving: return
	var items = null
	var target = null
	var multiplier = 1
	match container:
		_dock_cap_container: 
			items = _dock_caps
			target = _boat_caps
			multiplier = -1
		_dock_item_container: 
			items = _dock_items
			target = _boat_items
			multiplier = -1
		_boat_cap_container: 
			items = _boat_caps
			target = _dock_caps
		_boat_item_container: 
			items = _boat_items
			target = _dock_items
	var item = items.get_item(i)
	if item == null: return
	if target.is_full(): return
	if item.value < 0:
		if multiplier == -1 and -item.value > _balance: return
		_update_balance(item.value * -multiplier)
	items.move(i, target)

func _on_go_button_pressed() -> void:
	_go_button.disabled = true
	_moving = true
	_update_river_miles()

func _is_ready_to_go() -> bool:
	return _boat_caps.has_any_item() and _boat_items.has_type_of_item("wood")
