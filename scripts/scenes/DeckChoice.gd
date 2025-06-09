class_name DeckChoice
extends Panel


@onready var unit_choices_container: HBoxContainer = $UnitChoices
@onready var total_label: RichTextLabel = $ButtonsContainer/TotalLabel
@onready var start_button: Button = $ButtonsContainer/StartButton

var unit_choices: Array[UnitChoice]
var total_units: int = 20:
    set(total):
        total_units = total
        var color: String = "green" if total_units == 20 else "red"
        total_label.text = "Total : [color=%s]%d[/color]" % [color, total_units]


func _ready() -> void:
    start_button.pressed.connect(_on_start_button_pressed)
    for unit_choice: UnitChoice in unit_choices_container.get_children():
        unit_choices.append(unit_choice)
        unit_choice.unit_number_updated.connect(_on_unit_choice_updated)


func _on_unit_choice_updated() -> void:
    var new_total := 0
    for unit_choice: UnitChoice in unit_choices:
        new_total += unit_choice.unit_count
    total_units = new_total


func _on_start_button_pressed() -> void:
    if total_units != 20:
        return

    # The array index matches the enum key of the associated unit
    var nb_units: Array[int] = [0] # The first value of the enum is the king and there is none in the deck
    for unit_choice in unit_choices:
        nb_units.append(unit_choice.unit_count)
    ActionsManager.do(Action.Code.CHOOSE_DECK, [nb_units])