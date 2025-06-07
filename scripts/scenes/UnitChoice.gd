class_name UnitChoice
extends VBoxContainer

signal unit_number_updated

@export var unit_type: Unit.EUnitType

@onready var unit_texture: TextureRect = $UnitTexture
@onready var plus_button: Button = $Plus
@onready var minus_button: Button = $Minus
@onready var unit_number: Label = $UnitNumber

var unit_count: int = 4:
    set(u):
        unit_count = u
        unit_number_updated.emit()
        unit_number.text = str(unit_count)


func _ready() -> void:
    var unit := GameManager.UNIT_RESOURCES[unit_type] as Unit
    var image: CompressedTexture2D = load("res://resources/icons/" + unit.resource_name + ".png")
    unit_texture.texture = image
    plus_button.pressed.connect(_on_plus_pressed)
    minus_button.pressed.connect(_on_minus_pressed)


func _on_plus_pressed() -> void:
    unit_count += 1


func _on_minus_pressed() -> void:
    if unit_count == 0:
        return
    unit_count -= 1
