class_name Reserve extends UnitsHolder

@export var side: Board.ESide = Board.ESide.PLAYER

func _ready() -> void:
    super ()
    default_unit = preload("res://scenes/characters/ReserveUnit.tscn")
    if side == Board.ESide.PLAYER:
        Events.reserve_unit_clicked.connect(unit_clicked)

    StateManager.get_state(StateManager.EState.ACTION_CHOICE).started.connect(untilt_all_units)
    Events.reset_priest_support.connect(untilt_all_units)


## Recreates the reserve from the server update
func update() -> void:
    for unit: ClickableUnit in units_container.get_children():
        remove_unit(unit)

    var units: Array[Unit.EUnitType] = GameManager.reserve if side == Board.ESide.PLAYER else GameManager.enemy_reserve
    for new_unit: Unit.EUnitType in units:
        add_unit(new_unit, side)

    set_selected_unit(null)


func set_selected_unit(unit: ClickableUnit) -> void:
    super (unit)
    GameManager.selected_reserve_unit = unit


func unit_clicked(unit: ClickableUnit) -> void:
    if side == Board.ESide.ENEMY:
        return

    super (unit)
    match StateManager.current_state:
        StateManager.EState.RECRUIT, StateManager.EState.CONSCRIPTION:
            toggle_unit_tilt(unit)
        StateManager.EState.PRIEST_SUPPORT:
            toggle_unit_tilt(unit)
            GameManager.priest_support()
        _:
            pass
