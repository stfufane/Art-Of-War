class_name BlockMenu extends PanelContainer

# This button will display guard or wizard depending on whether we're blocking an attack or a support.
@onready var guard_wizard_button: Button = $MarginContainer/HBoxContainer/GuardWizardButton
@onready var king_button: Button = $MarginContainer/HBoxContainer/KingButton
@onready var pass_button: Button = $MarginContainer/HBoxContainer/PassButton


func _ready() -> void:
    guard_wizard_button.pressed.connect(_on_guard_wizard_button_pressed)
    king_button.pressed.connect(_on_king_button_pressed)
    pass_button.pressed.connect(_on_pass_button_pressed)

    StateManager.get_state(StateManager.EState.WAITING_FOR_PLAYER).started.connect(hide)
    StateManager.get_state(StateManager.EState.ACTION_CHOICE).started.connect(hide)
    StateManager.get_state(StateManager.EState.ATTACK_BLOCK).started.connect(_attack_block_started)
    StateManager.get_state(StateManager.EState.SUPPORT_BLOCK).started.connect(_support_block_started)


func _attack_block_started() -> void:
    show()
    guard_wizard_button.text = "Guard"


func _support_block_started() -> void:
    show()
    guard_wizard_button.text = "Wizard"


func _on_king_button_pressed() -> void:
    if StateManager.current_state == StateManager.EState.ATTACK_BLOCK:
        # The player is blocking an attack
        ActionsManager.run.rpc_id(1, Action.Code.BLOCK_ATTACK, [Unit.EUnitType.King])
    elif StateManager.current_state == StateManager.EState.SUPPORT_BLOCK:
        # The player is blocking a support
        ActionsManager.run.rpc_id(1, Action.Code.BLOCK_SUPPORT, [Unit.EUnitType.King])


func _on_guard_wizard_button_pressed() -> void:
    if StateManager.current_state == StateManager.EState.ATTACK_BLOCK:
        # The player is blocking an attack
        ActionsManager.run.rpc_id(1, Action.Code.BLOCK_ATTACK, [Unit.EUnitType.Guard])
    elif StateManager.current_state == StateManager.EState.SUPPORT_BLOCK:
        # The player is blocking a support
        ActionsManager.run.rpc_id(1, Action.Code.BLOCK_SUPPORT, [Unit.EUnitType.Wizard])


func _on_pass_button_pressed() -> void:
    if StateManager.current_state == StateManager.EState.ATTACK_BLOCK:
        ActionsManager.run.rpc_id(1, Action.Code.NO_ATTACK_BLOCK)
    elif StateManager.current_state == StateManager.EState.SUPPORT_BLOCK:
        ActionsManager.run.rpc_id(1, Action.Code.NO_SUPPORT_BLOCK)
