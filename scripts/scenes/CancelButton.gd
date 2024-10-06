class_name CancelButton extends Button

func _ready() -> void:
    hide()
    pressed.connect(_on_pressed)
    Events.toggle_cancel_button.connect(_on_toggle_cancel_button)
    StateManager.get_state(StateManager.EState.ACTION_CHOICE).started.connect(hide)
    StateManager.get_state(StateManager.EState.RECRUIT).started.connect(show)
    StateManager.get_state(StateManager.EState.ATTACK).started.connect(show)


func _on_toggle_cancel_button(shown: bool) -> void:
    if shown:
        show()
    else:
        hide()


func _on_pressed() -> void:
    ActionsManager.run.rpc_id(1, Action.Code.CANCEL_ACTION)