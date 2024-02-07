class_name Reserve extends UnitsHolder


func _ready() -> void:
	super()
	default_unit = preload("res://scenes/characters/ReserveUnit.tscn")
	Events.reserve_unit_clicked.connect(unit_clicked)


func set_selected_unit(unit: Control) -> void:
	super(unit)
	GameManager.selected_reserve_unit = unit


func unit_clicked(unit: Control) -> void:
	super(unit)
	match StateManager.current_state:
		StateManager.EState.RECRUIT:
			toggle_unit_tilt(unit)
