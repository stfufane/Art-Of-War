class_name HostMenu extends PanelContainer


@onready var party_id_label: Label = $MarginContainer/VBoxContainer/HSplitContainer/PartyID
@onready var cancel_button: Button = $MarginContainer/VBoxContainer/CancelButton
@onready var copy_button: Button = $MarginContainer/VBoxContainer/HSplitContainer/CopyButton


func _ready() -> void:
	GameManager.party_created.connect(_on_party_created)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	copy_button.gui_input.connect(_on_copy_icon_clicked)


func _on_cancel_button_pressed() -> void:
	hide()
	GameServer.cancel_party.rpc_id(1)


func _on_party_created(party_id: String) -> void:
	show()
	party_id_label.text = party_id


func _on_copy_icon_clicked(event: InputEvent) -> void:
	if event.is_action_pressed(GameManager.LEFT_CLICK):
		DisplayServer.clipboard_set(party_id_label.text)
