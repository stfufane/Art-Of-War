class_name WaitingMenu extends PanelContainer

@onready var party_id_label: Label = $MarginContainer/VBoxContainer/HSplitContainer/PartyID
@onready var cancel_button: Button = $MarginContainer/VBoxContainer/CancelButton
@onready var copy_container: MarginContainer = $MarginContainer/VBoxContainer/HSplitContainer/CopyIconContainer


func _ready():
	Network.party_created.connect(_on_party_created)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	copy_container.gui_input.connect(_on_copy_icon_clicked)


func _on_cancel_button_pressed() -> void:
	hide()
	Network.cancel_party()


func _on_party_created(party_id: String) -> void:
	show()
	party_id_label.text = party_id


func _on_copy_icon_clicked(event: InputEvent) -> void:
	if event.is_action_pressed(Game.LEFT_CLICK):
		DisplayServer.clipboard_set(party_id_label.text)
