class_name PlayerHand extends RefCounted

var player: Player = null
var units: Array[Unit.EUnitType] = []

func _init(p: Player) -> void:
    player = p


func add_unit(unit: Unit.EUnitType) -> void:
    units.append(unit)
    update_hand_ui()


func remove_unit(unit: Unit.EUnitType) -> void:
    units.erase(unit)
    update_hand_ui()


func has(unit_type: Unit.EUnitType) -> bool:
    return units.has(unit_type)


# You can't have more than 5 units in your hand at the end of a turn
func is_full() -> bool:
    return units.size() > 5


func size() -> int:
    return units.size()


func clear() -> void:
    units.clear()
    update_hand_ui()


func update_hand_ui() -> void:
    GameManager.update_hand.rpc_id(player.id, units)