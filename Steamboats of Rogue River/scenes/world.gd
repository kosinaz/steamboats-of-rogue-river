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
var _available_upgrades: Array = ["ropes", "crate", "haybasket", "cage", "tarp"]
var _bought_upgrades: Array = []
var _bought_upgrades_for: Array = []
var _upgrade_to_buy: String = ""
var _wood_deal: bool = false
var _current_damage: TextureButton = null
var _full_repair: bool = false
var _full_damage: bool = false
var _records: ConfigFile = ConfigFile.new()
var _chimney_stopping: bool = false
onready var _dock: Sprite = $"%Dock"
onready var _dock_cap_container: GridContainer = $"%DockCapContainer"
onready var _dock_item_container: GridContainer = $"%DockItemContainer"
onready var _boat_cap_container: GridContainer = $"%BoatCapContainer"
onready var _boat_item_container: GridContainer = $"%BoatItemContainer"
onready var _boat_wheel: AnimatedSprite = $"%BoatWheel"
onready var _cage: Sprite = $"%Cage"
onready var _crate: Sprite = $"%Crate"
onready var _haybasket: Sprite = $"%Haybasket"
onready var _ropes: Sprite = $"%Ropes"
onready var _tarp: Sprite = $"%Tarp"
onready var _damage1: TextureButton = $"%Damage1"
onready var _damage2: TextureButton = $"%Damage2"
onready var _damage3: TextureButton = $"%Damage3"
onready var _boat_path_follow: PathFollow2D = $"%BoatPathFollow"
onready var _river_miles: Node = $"%RiverMiles"
onready var _mile_label: Label = $"%MileLabel"
onready var _game_over_panel: Panel = $"%GameOverPanel"
onready var _reason_label: Label = $"%ReasonLabel"
onready var _current_mile_label: Label = $"%CurrentMileLabel"
onready var _record_mile_label: Label = $"%RecordMileLabel"
onready var _encounter_panel: Panel = $"%EncounterPanel"
onready var _encounter_label: Label = $"%EncounterLabel"
onready var _boat2: Sprite = $"%Boat2"
onready var _go_button: TextureButton = $"%GoButton"
onready var _encounter_button1: Button = $"%EncounterButton1"
onready var _encounter_button_label: RichTextLabel = $"%EncounterButtonLabel"
onready var _encounter_button2: Button = $"%EncounterButton2"
onready var _music_player: AudioStreamPlayer2D = $"%MusicPlayer"
onready var _chimney1: AnimatedSprite = $"%Chimney1"
onready var _chimney2: AnimatedSprite = $"%Chimney2"

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
		value = _rng.randi_range(1, 2)
		_dock_caps.add_new_item(_free_caps.pop_front(), _dock_id, value, -value * 2)
		value = _rng.randi_range(4, 6)
		_dock_caps.add_new_item(_free_caps.pop_front(), _dock_id, value, -value * 2 + 1)
	for _i in range(_rng.randi_range(0, 6)):
		_dock_items.add_new_item("wood", 0, 0, -1)
	if _rng.randi_range(1, 2) == 1 and _available_upgrades.size() > 0:
		_dock_items.add_new_item(_available_upgrades[_rng.randi_range(0, _available_upgrades.size() - 1)], 0, 0, -5)
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
	_init_repairs()
	_go_button.disabled = not _is_ready_to_go()

func _init_repairs() -> void:
	_damage1.disabled = true
	_damage2.disabled = true
	_damage3.disabled = true
	if _moving: return
	for item in _boat_items.get_items():
		if item.get_name() == "wood":
			_damage1.disabled = not _damage1.visible
			_damage2.disabled = not _damage2.visible
			_damage3.disabled = not _damage3.visible
			return

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
	_current_mile_label.text = str(_dock_id) + " miles"
	var record = _records.get_value("mile", "record", 0)
	if int(record) < _dock_id:
		_records.set_value("mile", "record", _dock_id)
		record = _records.get_value("mile", "record")
	_record_mile_label.text =  str(record) + " miles"
	
func _auto_remove_items() -> void:
	if _boat_caps.get_item(0).get_destination() == _dock_id:
		_boat_caps.remove(0)
	var items: Array = _boat_items.get_items()
	var i: int = items.size()
	while i > 0:
		i -= 1
		if items[i].get_name() != "wood" and items[i].get_destination() == _dock_id:
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
			if _bought_upgrades_for.has(items.get_item(i).get_name()):
				items_buttons[i].texture_normal = load("res://assets/" + items.get_item(i).get_name() + "upgraded.png")
			else:
				items_buttons[i].texture_normal = load("res://assets/" + items.get_item(i).get_name() + "big.png")
			items_buttons[i].get_node("%ValueLabel").text = str(items.get_item(i).get_price())
			items_buttons[i].get_node("%ValuePanel").show()
		else:
			items_buttons[i].texture_normal = load("res://assets/no_item.png")
			items_buttons[i].get_node("%ValuePanel").hide()
	_go_button.disabled = not _is_ready_to_go()
	_init_repairs()

func _update_river_miles() -> void:
	for mile in _river_miles.get_children():
		mile.get_node("Cap").texture = null
		mile.get_node("Item").texture = null
	var items: Array = _dock_items.get_items() + _dock_caps.get_items() + _boat_items.get_items() + _boat_caps.get_items()
	if _moving:
		items = _boat_items.get_items() + _boat_caps.get_items()
	for item in items:
		if item.get_name() == "wood": continue
		if _available_upgrades.has(item.get_name()): continue
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
	if _available_upgrades.has(item.get_name()):
		items.remove(i)
		_buy_upgrade(item.get_name())
	else:
		items.move(i, target)

func _buy_upgrade(upgrade_name: String) -> void:
	_available_upgrades.erase(upgrade_name)
	_bought_upgrades.append(upgrade_name)
	match upgrade_name:
		"cage": 
			_cage.show()
			_bought_upgrades_for.append("hen")
			_bought_upgrades_for.append("duck")
		"crate": 
			_crate.show()
			_bought_upgrades_for.append("box")
		"haybasket": 
			_haybasket.show()
			_bought_upgrades_for.append("cow")
			_bought_upgrades_for.append("goat")
		"ropes": 
			_ropes.show()
			_bought_upgrades_for.append("barrel")
		"tarp": 
			_tarp.show()
			_bought_upgrades_for.append("hay")
	_update_container(_boat_item_container)

func _on_go_button_pressed() -> void:
	_go_button.disabled = true
	_moving = true
	_update_river_miles()
	_update_container(_dock_cap_container)
	_update_container(_dock_item_container)
	_update_container(_boat_cap_container)
	_update_container(_boat_item_container)
	for item in _boat_items.get_items():
		if item.get_name() == "wood":
			_boat_items.erase(item)
			break
	_init_encounter()
	_chimney1.play()
	_chimney_stopping = false
	
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
	_wheel_tween.tween_callback(self, "_stop_chimney")
# warning-ignore:return_value_discarded
	_wheel_tween.tween_property(_boat_wheel, "speed_scale", 0, 2)

func _continue_the_ride() -> void:
	_chimney1.play()
	_chimney_stopping = false
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
	_wheel_tween.tween_callback(self, "_stop_chimney")
# warning-ignore:return_value_discarded
	_wheel_tween.tween_property(_boat_wheel, "speed_scale", 0, 2)

func _is_ready_to_go() -> bool:
	return _boat_caps.has_any_item() and _boat_items.has_type_of_item("wood") and not _moving

func _init_encounter() -> void:
	_item_to_erase = null
	_encounter_label.text = "Calm waters, no issues. We are ready to continue our ride!"
	_encounter_button_label.bbcode_text = "[center]Let's go"
	_boat2.hide()
	_encounter_button2.hide()
	var encounter = _rng.randi_range(0, 15 + _dock_id)
	if encounter < 5:
		if _boat_items.get_items().size() < 5 and _balance > 0:
			_wood_deal = true
			_boat2.show()
			_encounter_button2.show()
			_encounter_label.text = "Ahoy Matey! Care to buy some wood? 2 piles for only $1!"
			_encounter_button_label.bbcode_text = "[center]Yes (-$1 +2[img]res://assets/wood.png[/img])"
			return
		for item in _boat_items.get_items():
			if item.get_name() == "wood":
				_boat2.show()
				_encounter_button2.show()
				_encounter_label.text = "Ahoy Matey! I ran out of wood. Could you help me out? I'd pay double!"
				_encounter_button_label.bbcode_text = "[center]Yes (-1[img]res://assets/wood.png[/img] +$2)"
				_item_to_erase = item
				return
		return
	if encounter < 10 and _balance > 3 and _available_upgrades.size() > 0:
		_upgrade_to_buy = _available_upgrades[_rng.randi_range(0, _available_upgrades.size() - 1)]
		_boat2.show()
		_encounter_button2.show()
		_encounter_label.text = "Ahoy Matey! We have " + _upgrade_to_buy + " which we are willing to sell to you for only $4. Deal?"
		_encounter_button_label.bbcode_text = "[center]Yes (-$4 +[img]res://assets/" + _upgrade_to_buy + ".png[/img])"
		return
	if encounter < 15 + int(_dock_id / 2.0):
		var items = _boat_items.get_items()
		var risky_items = []
		for item in items:
			if not _bought_upgrades_for.has(item.get_name()) and item.get_name() != "wood":
				risky_items.append(item)
		if risky_items.size() == 0:
			return
		risky_items.shuffle()
		_item_to_erase = risky_items[0]
		match risky_items[0].get_name():
			"barrel":
				_encounter_label.text = "One of our barrels has fallen over due to these crushing waves and fell into the water! Only if we had some spare ropes!"
				_encounter_button_label.bbcode_text = "[center]Ok (-1[img]res://assets/barrel.png[/img])"
			"box":
				_encounter_label.text = "This doubledecker rain has melted away one of our thin paper boxes! Some wooden crates would have sure helped here."
				_encounter_button_label.bbcode_text = "[center]Ok (-1[img]res://assets/box.png[/img])"
			"hay":
				_encounter_label.text = "The high wind has blown down our hay! Next time some good old tarp will surely take care of it."
				_encounter_button_label.bbcode_text = "[center]Ok (-1[img]res://assets/hay.png[/img])"
			"hen":
				_encounter_label.text = "A majestic bald eagle has snatched away one of our hens. We'll need to put them behind bars."
				_encounter_button_label.bbcode_text = "[center]Ok (-1[img]res://assets/hen.png[/img])"
			"duck":
				_encounter_label.text = "A duck has escaped the cage and flew away. We'll need some iron bars on these cages next time."
				_encounter_button_label.bbcode_text = "[center]Ok (-1[img]res://assets/duck.png[/img])"
			"goat":
				_encounter_label.text = "This musical goat has ate the sheets and now he can't stop singing. Nobody will pay for him anymore. I wish we bought some hay for him instead."
				_encounter_button_label.bbcode_text = "[center]Ok (-1[img]res://assets/goat.png[/img])"
			"cow":
				_encounter_label.text = "The cow was mooing so hard that now she became as thin as a rake. Next time we need to bring some hay for her."
				_encounter_button_label.bbcode_text = "[center]Ok (-1[img]res://assets/cow.png[/img])"
		return
	if encounter < 30:
		var damage = _rng.randi_range(0, 2)
		var damages = [_damage1, _damage2, _damage3]
		_current_damage = damages[damage]
		_encounter_label.text = "Oh no, some floating debris damaged the boat! One more impact on this spot and we are sleeping with the fishes. Unless we fix it in the next dock."
		_encounter_button_label.bbcode_text = "[center]Ok"
		return
	_full_damage = true
	_encounter_label.text = "Shiver me timbers! The water is too shallow, we are wrecked! I hope we can reach the next dock!"
	_encounter_button_label.bbcode_text = "[center]Ok"

func _show_encounter() -> void:
	if _current_damage != null and _current_damage.visible:
		_game_over("Oh no, some floating debris damaged the boat on the same spot as the last time. We are sinking!")
		return
	if _full_damage and (_damage1.visible or _damage2.visible or _damage3.visible):
		_game_over("Oh no, the water is too a shallow, we are stranded!")
		return
	_encounter_panel.show()
	
func _stop_chimney() -> void:
	_chimney_stopping = true

func _on_restart_pressed() -> void:
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()

func _on_yes_pressed() -> void:
	_encounter_panel.hide()
	if not _item_to_erase == null:
		if _item_to_erase.get_name() == "wood":
			_update_balance(2)
		_boat_items.erase(_item_to_erase)
		_item_to_erase = null
	if not _upgrade_to_buy == "":
		_update_balance(-4)
		_buy_upgrade(_upgrade_to_buy)
		_upgrade_to_buy = ""
	if _wood_deal:
		_update_balance(-1)
		_boat_items.add_new_item("wood", 0, 0, -1)
		_boat_items.add_new_item("wood", 0, 0, -1)
		_wood_deal = false
	if _current_damage != null:
		_current_damage.show()
		_current_damage = null
	if _full_damage:
		_damage1.show()
		_damage2.show()
		_damage3.show()
		_full_damage = false
	_continue_the_ride()

func _on_no_pressed() -> void:
	_encounter_panel.hide()
	_item_to_erase = null
	_upgrade_to_buy = ""
	_wood_deal = false
	_continue_the_ride()

func _on_damage_pressed(id):
	var damages = [_damage1, _damage2, _damage3]
	damages[id].hide()
	damages[id].disabled = true
	for item in _boat_items.get_items():
		if item.get_name() == "wood":
			_boat_items.erase(item)
			_init_repairs()
			return

func _on_sound_button_toggled(button_pressed):
	_music_player.playing = not button_pressed

func _on_chimney1_frame_changed():
	if _chimney1.frame == 3 and not _chimney2.playing:
		_chimney2.play()

func _on_chimney1_animation_finished():
	var smoke = _chimney1.get_node("Smoke")
	var smoke_player = smoke.get_node("AnimationPlayer")
	smoke.show()
	smoke_player.play("default")
	if _chimney_stopping:
		_chimney1.stop()

func _on_chimney2_animation_finished():
	var smoke = _chimney2.get_node("Smoke")
	var smoke_player = smoke.get_node("AnimationPlayer")
	smoke.show()
	smoke_player.play("default")
	if _chimney_stopping:
		_chimney2.stop()
