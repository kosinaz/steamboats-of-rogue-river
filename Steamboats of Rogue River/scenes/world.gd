extends Node2D

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _balance: int = 10 setget _set_balance
var _moving: bool = false
onready var _dock: TileMap = $"%Dock"
onready var _dock_container: GridContainer = $"%DockContainer"
onready var _boat_container: GridContainer = $"%BoatContainer"
onready var _go_button: TextureButton = $"%GoButton"



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_rng.randomize()
	_add_item("res://scenes/cap1.tscn", -5)
	_add_item("res://scenes/cap2.tscn", -6)
	for _i in range(_rng.randi_range(2, 4)):
		_add_item("res://scenes/wood.tscn", -1)
	for _i in range(_rng.randi_range(1, 3)):
		_add_item("res://scenes/crate.tscn", 1)
	for _i in range(_rng.randi_range(1, 3)):
		_add_item("res://scenes/barrel.tscn", 2)
		
func _process(_delta) -> void:
	if not _moving: return
	if _dock.position.x > -576 * 2:
		_dock.position.x -= 4
	else:
		_dock.position.x = -576

func _set_balance(value):
	_balance = value
	$"%BalanceLabel".text = "$" + str(_balance)

func _add_item(path: String, value: int) -> void:
	var item: Node = load(path).instance()
	_dock_container.add_child(item)
	# warning-ignore:return_value_discarded
	item.connect("pressed", self, "_on_item_pressed", [item, value])
	
	
func _on_item_pressed(item: Node, value: int) -> void:
	if _dock_container.is_a_parent_of(item):
		if value < 0:
			if _balance + value < 0: return
			self._balance += value
		_dock_container.remove_child(item)
		_boat_container.add_child(item)
			
	elif _boat_container.is_a_parent_of(item):
		if value < 0:
			self._balance -= value
		_boat_container.remove_child(item)
		_dock_container.add_child(item)


func _on_go_button_pressed():
	_go_button.disabled = true
	_moving = true
