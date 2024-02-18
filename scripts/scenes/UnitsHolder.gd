class_name UnitsHolder extends Node2D

var selected_unit: ClickableUnit = null
var default_unit: PackedScene = null


@onready var units_container: VBoxContainer = $UnitsContainer
@onready var test_button: Button = $Button


func _ready() -> void:
	if get_parent().name == "root":
		test_button.show()
		test_button.pressed.connect(test)


## TESTING: add a random unit
func test() -> void:
	var random_unit: Unit.EUnitType = GameManager.UNIT_RESOURCES.keys().pick_random()
	add_unit(random_unit)


## Instantiate a unit in the container
func add_unit(type: Unit.EUnitType) -> void:
	var new_unit = default_unit.instantiate()
	new_unit.unit = GameManager.UNIT_RESOURCES[type]
	units_container.add_child(new_unit)


func remove_unit(unit: ClickableUnit) -> void:
	units_container.remove_child(unit)
	unit.queue_free()


func set_selected_unit(unit: ClickableUnit) -> void:
	selected_unit = unit


func toggle_unit_tilt(unit: ClickableUnit) -> void:
	set_selected_unit(null)
	for u: ClickableUnit in units_container.get_children():
		if u != unit and u.tiltable.tilted:
			u.tiltable.untilt()
	unit.tiltable.toggle_tilt()
	if unit.tiltable.tilted:
		set_selected_unit(unit)


func unit_clicked(unit: ClickableUnit) -> void:
	if get_parent().name == "root":
		toggle_unit_tilt(unit)
		return
