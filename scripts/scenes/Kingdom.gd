class_name Kingdom extends Node2D

const ONE = preload("res://resources/graphics/plus_one.png")

@export var sprite_size: float = 16.0

@onready var units: Dictionary = {
	Unit.EUnitType.Soldier: $Soldier as KingdomUnit,
	Unit.EUnitType.Guard: $Guard as KingdomUnit,
	Unit.EUnitType.Monk: $Monk as KingdomUnit,
	Unit.EUnitType.Archer: $Archer as KingdomUnit,
	Unit.EUnitType.Wizard: $Wizard as KingdomUnit
}

@onready var test_button := $Test as Button


func _ready() -> void:
	Events.update_kingdom.connect(_on_kingdom_updated)
	if get_parent().name == "root":
		test_button.show()
		test_button.pressed.connect(_test)


func _on_kingdom_updated(units_status: Dictionary) -> void:
	for unit in units_status.keys() as Array[Unit.EUnitType]:
		units[unit].status = units_status[unit] as KingdomUnit.EStatus


#region Test methods
## TESTING: Move a 1 sprite to a random unit of the kingdom
func _test() -> void:
	var new_texture := TextureRect.new()
	new_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	new_texture.size = Vector2(sprite_size, sprite_size)
	new_texture.position = test_button.position
	new_texture.texture = ONE
	add_child(new_texture)
	var target_unit = units.keys().pick_random()
	var tween := create_tween()
	tween.tween_property(new_texture, "position", units[target_unit].position, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		new_texture.queue_free()
		flash(target_unit)
	)


func flash(unit: Unit.EUnitType) -> void:
	units[unit].flash()

#endregion
