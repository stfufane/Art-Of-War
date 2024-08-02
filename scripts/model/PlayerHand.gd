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

func clear() -> void:
    units.clear()
    update_hand_ui()


func update_hand_ui() -> void:
    GameManager.update_hand.rpc_id(player.id, units)