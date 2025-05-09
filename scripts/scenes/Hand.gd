class_name Hand extends UnitsHolder


func _ready() -> void:
	super ()
	default_unit = preload("res://scenes/characters/HandUnit.tscn")
	Events.hand_unit_clicked.connect(unit_clicked)
	Events.hand_updated.connect(update_hand)


## Recreates the hand from the server update
func update_hand() -> void:
	for unit: ClickableUnit in units_container.get_children():
		remove_unit(unit)
	
	for new_unit: Unit.EUnitType in GameManager.units:
		add_unit(new_unit)
	
	set_selected_unit(null)


func set_selected_unit(unit: ClickableUnit) -> void:
	super (unit)
	GameManager.selected_hand_unit = unit


func unit_clicked(unit: ClickableUnit) -> void:
	super (unit)
	match StateManager.current_state:
		StateManager.EState.INIT_BATTLEFIELD, StateManager.EState.INIT_RESERVE:
			toggle_unit_tilt(unit)
			if StateManager.current_state == StateManager.EState.INIT_RESERVE:
				ActionsManager.do(Action.Code.INIT_RESERVE, [unit.unit.type])
		
		StateManager.EState.RECRUIT, StateManager.EState.CONSCRIPTION:
			# Recruitment must be made from the reserve if it's not empty
			if not GameManager.reserve.is_empty():
				return
			toggle_unit_tilt(unit)
		
		StateManager.EState.SUPPORT:
			# Can't use a support if the reserve is full
			if GameManager.is_reserve_full():
				return
			
			match unit.unit.type:
				Unit.EUnitType.Soldier:
					ActionsManager.do(Action.Code.SOLDIER_SUPPORT)
				Unit.EUnitType.Archer, Unit.EUnitType.Priest, Unit.EUnitType.King:
					ActionsManager.do(Action.Code.SUPPORT_CHOICE, [unit.unit.type])
				_:
					pass

		StateManager.EState.FINISH_TURN:
			ActionsManager.do(Action.Code.ADD_TO_KINGDOM, [unit.unit.type])
		
		_:
			pass
