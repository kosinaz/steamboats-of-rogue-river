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
var _dock_id: int = -1
var _boat_tween: SceneTreeTween = null
var _wheel_tween: SceneTreeTween = null
var _mile_tween: SceneTreeTween = null
var _encounter_id: int = 0
var _item_to_erase: Item = null
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
onready var _encounter_panel: Panel = $"%EncounterPanel"
onready var _encounter_label: Label = $"%EncounterLabel"
onready var _boat2: Sprite = $"%Boat2"
onready var _go_button: TextureButton = $"%GoButton"
onready var _encounter_button1: Button = $"%EncounterButton1"
onready var _encounter_button_label: RichTextLabel = $"%EncounterButtonLabel"
onready var _encounter_button2: Button = $"%EncounterButton2"

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
	_dock_id += 1
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
		value = _rng.randi_range(4, 6)
		_dock_caps.add_new_item(_free_caps.pop_front(), _dock_id, value, -value * 2 + 1)
	for _i in range(_rng.randi_range(0, 4)):
		_dock_items.add_new_item("wood", 0, 0, -1)
	if _free_items.size() < 2:
		_free_items = ITEMS.duplicate()
		_free_items.shuffle()
		for item in _boat_items.get_items():
			_free_items.erase(item.get_name())
	var item: String = ""
	value = _rng.randi_range(1, 2)
	if _river_miles.get_child(value).get_node("Item").texture == null:
		item = _free_items.pop_front()
		for _i in range(1, 5):
			_dock_items.add_new_item(item, _dock_id, value, value)
	value += _rng.randi_range(1, 3)
	if _river_miles.get_child(value).get_node("Item").texture == null:
		item = _free_items.pop_front()
		for _i in range(1, 3):
			_dock_items.add_new_item(item, _dock_id, value, value + (1 if value > 3 else 0))
	_update_river_miles()
	_mile_label.text = str(_dock_id) + "m"

func _start_arriving() -> void:
	_arriving = true

func _arrive() -> void:
	_moving = false
	_arriving = false
	_auto_remove_items()
	_reset_miles()
	_check_game_over()

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
	_update_river_miles()
	_update_container(_dock_cap_container)
	_update_container(_dock_item_container)
	_update_container(_boat_cap_container)
	_update_container(_boat_item_container)
	_init_encounter()
	
	_boat_tween = get_tree().create_tween()
# warning-ignore:return_value_discarded
	_boat_tween.set_ease(Tween.EASE_IN_OUT)
# warning-ignore:return_value_discarded
	_boat_tween.set_trans(Tween.TRANS_SINE)
# warning-ignore:return_value_discarded
	_boat_tween.tween_property(_boat_path_follow, "unit_offset", 0.875, 8)
# warning-ignore:return_value_discarded
	_boat_tween.tween_callback(self, "_show_encounter")

	_mile_tween = get_tree().create_tween()
# warning-ignore:return_value_discarded
	_mile_tween.set_ease(Tween.EASE_IN_OUT)
# warning-ignore:return_value_discarded
	_mile_tween.set_trans(Tween.TRANS_SINE)
# warning-ignore:return_value_discarded
	_mile_tween.tween_property(_river_miles, "position:x", -28, 8)
	
	_wheel_tween = get_tree().create_tween()
# warning-ignore:return_value_discarded
	_wheel_tween.tween_property(_boat_wheel, "speed_scale", 0, 0)
# warning-ignore:return_value_discarded
	_wheel_tween.tween_property(_boat_wheel, "speed_scale", 3, 1)
# warning-ignore:return_value_discarded
	_wheel_tween.tween_interval(5.5)
# warning-ignore:return_value_discarded
	_wheel_tween.tween_property(_boat_wheel, "speed_scale", 0, 2)


func _continue_the_ride() -> void:
	_boat_tween = get_tree().create_tween()
# warning-ignore:return_value_discarded
	_boat_tween.set_ease(Tween.EASE_IN)
# warning-ignore:return_value_discarded
	_boat_tween.tween_property(_boat_path_follow, "unit_offset", 1, 2)
# warning-ignore:return_value_discarded
	_boat_tween.tween_property(_boat_path_follow, "unit_offset", 0, 0)
# warning-ignore:return_value_discarded
	_boat_tween.set_ease(Tween.EASE_OUT)
# warning-ignore:return_value_discarded
	_boat_tween.tween_callback(self, "_start_arriving")
# warning-ignore:return_value_discarded
	_boat_tween.tween_callback(self, "_init_dock")
# warning-ignore:return_value_discarded
	_boat_tween.tween_property(_boat_path_follow, "unit_offset", 0.5, 9)
# warning-ignore:return_value_discarded
	_boat_tween.tween_callback(self, "_arrive")
	
	_mile_tween = get_tree().create_tween()
# warning-ignore:return_value_discarded
	_mile_tween.tween_property(_river_miles, "position:x", -64, 11)
# warning-ignore:return_value_discarded
	_mile_tween.tween_property(_river_miles, "position:x", 0, 0)
	
	_wheel_tween = get_tree().create_tween()
# warning-ignore:return_value_discarded
	_wheel_tween.tween_property(_boat_wheel, "speed_scale", 3, 1)
# warning-ignore:return_value_discarded
	_wheel_tween.tween_interval(8.5)
# warning-ignore:return_value_discarded
	_wheel_tween.tween_property(_boat_wheel, "speed_scale", 0, 2)

func _is_ready_to_go() -> bool:
	return _boat_caps.has_any_item() and _boat_items.has_type_of_item("wood")

func _init_encounter() -> void:
	_encounter_label.text = "Calm waters, no issues. We are ready to continue our ride!"
	_encounter_button_label.bbcode_text = "[center]Let's go"
	_item_to_erase = null
	_boat2.hide()
	_encounter_button2.hide()
	for item in _boat_items.get_items():
		match item.get_name():
			"wood":
				if _rng.randi_range(1, 10) == 1:
					_boat2.show()
					_encounter_button2.show()
					_encounter_label.text = "Ahoy Matey! I ran out of wood. Could you help me out? I'd pay double!"
					_encounter_button_label.bbcode_text = "[center]Yes (-1[img]res://assets/wood.png[/img] +$2)"
					_item_to_erase = item
					break
			"barrel":
				if _rng.randi_range(1, 5) == 1:
					_encounter_label.text = "One of our barrels has fallen over due to these crushing waves and fell into the water! Only if we had some spare ropes!"
					_encounter_button_label.bbcode_text = "[center]Ok (-1[img]res://assets/barrel.png[/img])"
					_item_to_erase = item
					break
			"box":
				if _rng.randi_range(1, 5) == 1:
					_encounter_label.text = "This doubledecker rain has melted away one of our thin paper boxes! Some wooden crates would have sure helped here."
					_encounter_button_label.bbcode_text = "[center]Ok (-1[img]res://assets/box.png[/img])"
					_item_to_erase = item
					break
			"hay":
				if _rng.randi_range(1, 5) == 1:
					_encounter_label.text = "The high wind has blown down our hay! Next time some good old tarp will surely take care of it."
					_encounter_button_label.bbcode_text = "[center]Ok (-1[img]res://assets/hay.png[/img])"
					_item_to_erase = item
					break
			"hen":
				if _rng.randi_range(1, 5) == 1:
					_encounter_label.text = "A majestic bald eagle has snatched away one of our hens. We'll need to put them behind bars."
					_encounter_button_label.bbcode_text = "[center]Ok (-1[img]res://assets/hen.png[/img])"
					_item_to_erase = item
					break
			"duck":
				if _rng.randi_range(1, 5) == 1:
					_encounter_label.text = "A duck has escaped the cage and flew away. We'll need some iron bars on these cages next time."
					_encounter_button_label.bbcode_text = "[center]Ok (-1[img]res://assets/duck.png[/img])"
					_item_to_erase = item
					break
			"goat":
				if _rng.randi_range(1, 5) == 1:
					_encounter_label.text = "This musical goat has ate the sheets and now he can't stop singing. Nobody will pay for him anymore. I wish we bought some hay for him instead."
					_encounter_button_label.bbcode_text = "[center]Ok (-1[img]res://assets/goat.png[/img])"
					_item_to_erase = item
					break
			"cow":
				if _rng.randi_range(1, 5) == 1:
					_encounter_label.text = "The cow was mooing so hard that now she became as thin as a rake. Next time we need to bring some hay for her."
					_encounter_button_label.bbcode_text = "[center]Ok (-1[img]res://assets/cow.png[/img])"
					_item_to_erase = item
					break

func _show_encounter() -> void:
	_encounter_panel.show()

func _on_restart_pressed() -> void:
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()

func _on_yes_pressed() -> void:
	_encounter_panel.hide()
	if not _item_to_erase == null:
		if _item_to_erase.get_name() == "wood":
			_update_balance(2)
		_boat_items.erase(_item_to_erase)
	_continue_the_ride()

func _on_no_pressed() -> void:
	_encounter_panel.hide()
	_continue_the_ride()
