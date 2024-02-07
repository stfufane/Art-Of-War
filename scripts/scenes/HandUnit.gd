class_name HandUnit extends Control

@export var unit: Unit

@onready var tiltable: TiltableUnit = $TiltableUnit

func _ready() -> void:
	tiltable.unit = unit
	gui_input.connect(_on_gui_input)


func _on_gui_input(event: InputEvent) -> void:
	if !event.is_action_pressed(GameManager.LEFT_CLICK):
		return
	Events.hand_unit_clicked.emit(self)
