extends Node2D

var CAPS: Array = ["cap1", "cap2", "cap3"]
var ITEMS: Array = ["barrel", "box", "cow", "duck", "hay", "hen", "goat"]
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _balance: int = 10
var _free_caps: Array = []
var _free_items: Array = []
var _dock_caps: Cargo = Cargo.new(3)
var _dock_items: Cargo = Cargo.new(12)
var _boat_caps: Cargo = Cargo.new(1)
var _boat_items: Cargo = Cargo.new(6)
var _moving: bool = false
var _arriving: bool = false
var _distance: int = 0
var _dock_id: int = 0
onready var _dock: Sprite = $"%Dock"
onready var _dock_cap_container: GridContainer = $"%DockCapContainer"
onready var _dock_item_container: GridContainer = $"%DockItemContainer"
onready var _boat_cap_container: GridContainer = $"%BoatCapContainer"
onready var _boat_item_container: GridContainer = $"%BoatItemContainer"
onready var _boat_wheel: AnimatedSprite = $"%BoatWheel"
onready var _boat_path_follow: PathFollow2D = $"%BoatPathFollow"
onready var _river_miles: Node = $"%RiverMiles"
onready var _mile_label: Label = $"%MileLabel"
onready var _game_over_panel: Panel = $"%GameOverPanel"
onready var _reason_label: Label = $"%ReasonLabel"
onready var _go_button: TextureButton = $"%GoButton"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	_rng.randomize()
	_init_container(_dock_caps, _dock_cap_container)
	_init_container(_dock_items, _dock_item_container)
	_init_container(_boat_caps, _boat_cap_container)
	_init_container(_boat_items, _boat_item_container)
	_init_dock()
	_boat_items.add_new_item("wood", 0, 0, -1)
	_boat_items.add_new_item("wood", 0, 0, -1)

func _init_dock() -> void:
	_dock_caps.clear()
	_dock_items.clear()
	var value: int = 0
	if not _boat_caps.is_full() or _boat_caps.get_item(0).get_destination() == _dock_id:
		if _free_caps.size() < 2:
			_free_caps = CAPS.duplicate()
			_free_caps.shuffle()
			if _boat_caps.is_full():
				_free_caps.erase(_boat_caps.get_item(0).get_name())
		value = _rng.randi_range(1, 3)
		_dock_caps.add_new_item(_free_caps.pop_front(), _dock_id, value, -value * 2)
		value += _rng.randi_range(1, 3)
		_dock_caps.add_new_item(_free_caps.pop_front(), _dock_id, value, -value * 2)
	for _i in range(_rng.randi_range(0, 4)):
		_dock_items.add_new_item("wood", 0, 0, -1)
	if _free_items.size() < 2:
		_free_items = ITEMS.duplicate()
		_free_items.shuffle()
		for item in _boat_items.get_items():
			_free_items.erase(item.get_name())
	var item: String = ""
	value = _rng.randi_range(1, 3)
	if _river_miles.get_child(value).get_node("Item").texture == null:
		item = _free_items.pop_front()
		for _i in range(1, 5):
			_dock_items.add_new_item(item, _dock_id, value, value)
	value += _rng.randi_range(1, 2)
	if _river_miles.get_child(value).get_node("Item").texture == null:
		item = _free_items.pop_front()
		for _i in range(1, 5):
			_dock_items.add_new_item(item, _dock_id, value, value)
	_update_river_miles()
	_mile_label.text = str(_dock_id) + "m"
		
func _process(_delta) -> void:
	if not _moving: return
	_boat_path_follow.offset += 8
	print(int(_boat_path_follow.offset / 8))
	if int(_boat_path_follow.offset / 8) == 281:
		_moving = false
		_arriving = false
		_boat_wheel.stop()
		_auto_remove_items()
		_reset_miles()
		_check_game_over()
	elif int(_boat_path_follow.offset / 8) == 1:
		_arriving = true
		_dock_id += 1
		_init_dock()
	for mile in _river_miles.get_children():
		if mile.position.x > 0:
			mile.position.x -= 0.05

func _check_game_over() -> void:
	if not _boat_caps.is_full() and _balance + _dock_caps.get_item(0).get_price() < 0:
		_game_over("Can't afford captain!")
		return
	for item in _boat_items.get_items():
		if item.get_name() == "wood":
			return
	for item in _dock_items.get_items():
		if item.get_name() == "wood" and _balance > 0:
			return
	_game_over("Ran out of wood!")

func _game_over(text: String) -> void:
	_game_over_panel.show()
	_reason_label.text = text
	
func _auto_remove_items() -> void:
	if _boat_caps.get_item(0).get_destination() == _dock_id:
		_boat_caps.remove(0)
	var burned: bool = false
	var items: Array = _boat_items.get_items()
	var i: int = items.size()
	while i > 0:
		i -= 1
		if items[i].get_name() == "wood":
			if burned == false:
				_boat_items.remove(i)
				burned = true
		elif items[i].get_destination() == _dock_id:
			_update_balance(items[i].get_price())
			_boat_items.remove(i)

func _reset_miles() -> void:
	for i in range(_river_miles.get_children().size()):
		var mile_to_reset = _river_miles.get_children()[i]
		mile_to_reset.position.x = (i + 1) * 64
	_update_river_miles()

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
			items_buttons[i].texture_normal = load("res://assets/" + items.get_item(i).get_name() + "big.png")
			items_buttons[i].get_node("%ValueLabel").text = str(items.get_item(i).get_price())
			items_buttons[i].get_node("%ValuePanel").show()
		else:
			items_buttons[i].texture_normal = load("res://assets/no_item.png")
			items_buttons[i].get_node("%ValuePanel").hide()
	_go_button.disabled = not _is_ready_to_go()

func _update_river_miles() -> void:
	for mile in _river_miles.get_children():
		mile.get_node("Cap").texture = null
		mile.get_node("Item").texture = null
	var items: Array = _dock_items.get_items() + _dock_caps.get_items() + _boat_items.get_items() + _boat_caps.get_items()
	if _moving:
		items = _boat_items.get_items() + _boat_caps.get_items()
	for item in items:
		if item.get_name() == "wood": continue
		var mile_id: int = item.get_destination() - _dock_id
		if not _arriving:
			mile_id -= 1
		var mile: Sprite = _river_miles.get_child(mile_id)
		var mile_icon = mile.get_node("Item")
		if item.get_name().begins_with("cap"):
			mile_icon = mile.get_node("Cap")
		mile_icon.texture = load("res://assets/" + item.get_name() + ".png")

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
	if item.get_price() < 0:
		if multiplier == -1 and -item.get_price() > _balance: return
		_update_balance(item.get_price() * -multiplier)
	items.move(i, target)

func _on_go_button_pressed() -> void:
	_go_button.disabled = true
	_moving = true
	_boat_wheel.play()
	_update_river_miles()
	_update_container(_dock_cap_container)
	_update_container(_dock_item_container)
	_update_container(_boat_cap_container)
	_update_container(_boat_item_container)

func _is_ready_to_go() -> bool:
	return _boat_caps.has_any_item() and _boat_items.has_type_of_item("wood")

func _on_restart_pressed():
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()
