class_name Hand extends UnitsHolder


func _ready() -> void:
	super()
	default_unit = preload("res://scenes/characters/HandUnit.tscn")
	Events.hand_unit_clicked.connect(unit_clicked)
	Events.hand_updated.connect(update_hand)
	Events.update_battlefield.connect(_on_unit_added_to_battlefield)


## Recreates the hand from the server update
func update_hand() -> void:
	for unit: Control in units_container.get_children():
		remove_unit(unit)
	
	for new_unit: Unit.EUnitType in GameManager.units:
		add_unit(new_unit)


func set_selected_unit(unit: Control) -> void:
	super(unit)
	GameManager.selected_hand_unit = unit


## The selected unit has been added to the battlefield, it can be removed
func _on_unit_added_to_battlefield(_id, unit_type: Unit.EUnitType) -> void:
	# Check that it matches
	if selected_unit.unit.type == unit_type:
		selected_unit.queue_free()
	else:
		# Otherwise remove the first unit that matches the type
		for unit: HandUnit in units_container.get_children():
			if unit.unit_type == unit_type:
				unit.queue_free()
				break
	# Reset the selected unit in both cases
	set_selected_unit(null)


func unit_clicked(unit: Control) -> void:
	super(unit)
	match StateManager.current_state:
		StateManager.EState.INIT_BATTLEFIELD, StateManager.EState.INIT_RESERVE:
			toggle_unit_tilt(unit)
			if StateManager.current_state == StateManager.EState.INIT_RESERVE:
				GameServer.run_action.rpc_id(1, Action.Code.ADD_RESERVE_UNIT, { "unit_type": unit.unit.type })
