class_name CancelButton extends Button

func _ready() -> void:
    hide()
    pressed.connect(_on_pressed)
    Events.state_changed.connect(_on_state_changed)


func _on_state_changed(state: StateManager.EState) -> void:
    if ActionCheck.CANCELLABLE_STATES.has(state):
        show()
    else:
        hide()


func _on_pressed() -> void:
    ActionsManager.do(Action.Code.CANCEL_ACTION)