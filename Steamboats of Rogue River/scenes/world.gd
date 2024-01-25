extends Node2D


var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _balance: int = 10
var _dock_caps: Cargo = Cargo.new(3)
var _dock_items: Cargo = Cargo.new(12)
var _boat_caps: Cargo = Cargo.new(1)
var _boat_items: Cargo = Cargo.new(6)
var _river: Array = ["crate", "barrel", "vase", "chest", "ball", "fish"]
var _current_items: Array = []
var _moving: bool = false
var _arriving: bool = false
var _distance: int = 0
onready var _dock: TileMap = $"%Dock"
onready var _dock_cap_container: GridContainer = $"%DockCapContainer"
onready var _dock_item_container: GridContainer = $"%DockItemContainer"
onready var _boat_cap_container: GridContainer = $"%BoatCapContainer"
onready var _boat_item_container: GridContainer = $"%BoatItemContainer"
onready var _river_miles: Node = $"%RiverMiles"
onready var _go_button: TextureButton = $"%GoButton"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	_rng.randomize()
	_init_container(_dock_caps, _dock_cap_container)
	_init_container(_dock_items, _dock_item_container)
	_init_container(_boat_caps, _boat_cap_container)
	_init_container(_boat_items, _boat_item_container)
	_river.shuffle()
	for i in range(6):
		_current_items.append(_river[i])
	_current_items.shuffle()
	_init_dock()

func _init_dock() -> void:
	_dock_caps.clear()
	_dock_items.clear()
	if not _boat_caps.is_full() or _boat_caps.get_item(0).distance == 1:
		_dock_caps.add_new_item("cap1", -1)
		_dock_caps.add_new_item("cap2", -2)
	for _i in range(_rng.randi_range(1, 6)):
		_dock_items.add_new_item("wood", -1)
	for _i in range(_rng.randi_range(1, _current_items.size() - 1)):
		var item = _current_items.pop_front()
		if item == null:
			break
		for _j in range(_rng.randi_range(1, 6)):
			_dock_items.add_new_item(item, _river.find(item) + 1)
	_update_river_miles()
		
func _process(_delta) -> void:
	if _arriving and _dock.position.x == 0:
		_moving = false
		_arriving = false
		_distance = 0
		_decrease_distance()
		for i in range(_river_miles.get_children().size()):
			var mile_to_reset = _river_miles.get_children()[i]
			mile_to_reset.position.x = (i + 1) * 64
			
	if not _moving: return
	if _dock.position.x >= -576 * 2:
		_dock.position.x -= 4
		if _distance == 0:
			_dock.position.y -=1
		if _distance == 1:
			_init_dock()
		if _distance == 6:
			if _arriving == false: 
				_dock.position.x = 576 * 2
				_arriving = true
			_dock.position.y += 1
	else:
		_dock.position.x = -576
		_distance += 1
	for mile in _river_miles.get_children():
		if mile.position.x > 0:
			mile.position.x -= 0.05

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
	var items: Cargo = null
	match container:
		_dock_cap_container: 
			items = _dock_caps
		_dock_item_container: 
			items = _dock_items
		_boat_cap_container: 
			items = _boat_caps
		_boat_item_container: 
			items = _boat_items
	var items_buttons: Array = container.get_children()
	for i in range(items_buttons.size()):
		if items.get_item(i):
			items_buttons[i].texture_normal = load("res://assets/" + items.get_item(i).item_name + "big.png")
			items_buttons[i].get_node("%ValuePanel").show()
			items_buttons[i].get_node("%ValueLabel").text = str(items.get_item(i).value)
		else:
			items_buttons[i].texture_normal = load("res://assets/no_item.png")
			items_buttons[i].get_node("%ValuePanel").hide()
	_go_button.disabled = not _is_ready_to_go()

func _update_river_miles() -> void:
	for mile in _river_miles.get_children():
		mile.get_node("Cap").texture = null
		mile.get_node("Item").texture = null
	var items: Array = _dock_items.get_items() + _dock_caps.get_items() + _boat_items.get_items() + _boat_caps.get_items()
	for item in items:
		if item.item_name == "wood": continue
		if item.item_name.begins_with("cap"):
			var mile: Sprite = _river_miles.get_child(item.distance)
			mile.get_node("Cap").texture = load("res://assets/" + item.item_name + ".png")
		else:
			var mile: Sprite = _river_miles.get_child(_river.find(item.item_name))
			mile.get_node("Item").texture = load("res://assets/" + item.item_name + ".png")

func _decrease_distance() -> void:
	_boat_caps.get_item(0).distance -= 1
	if _boat_caps.get_item(0).distance == 0:
		_boat_caps.clear()
	_update_river_miles()

func _update_balance(value: int) -> void:
	_balance += value
	$"%BalanceLabel".text = "$" + str(_balance)
	
func _on_item_button_pressed(container: GridContainer, i: int) -> void:
	if _moving: return
	var items: Cargo = null
	var target: Cargo = null
	var multiplier: int = 1
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
	var item: Item = items.get_item(i)
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
	_update_container(_dock_cap_container)
	_update_container(_dock_item_container)
	_update_container(_boat_cap_container)
	_update_container(_boat_item_container)

func _is_ready_to_go() -> bool:
	return _boat_caps.has_any_item() and _boat_items.has_type_of_item("wood") and not _moving
