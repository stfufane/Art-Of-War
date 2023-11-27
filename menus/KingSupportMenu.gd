class_name KingSupportMenu
extends PanelContainer

@onready var soldier_button: Button = $MarginContainer/VBoxContainer/SoldierButton
@onready var archer_button: Button = $MarginContainer/VBoxContainer/ArcherButton
@onready var monk_button: Button = $MarginContainer/VBoxContainer/MonkButton


func _ready():
	soldier_button.pressed.connect(_on_soldier_button_pressed)
	archer_button.pressed.connect(_on_archer_button_pressed)
	monk_button.pressed.connect(_on_monk_button_pressed)
	
	Game.States[State.Name.KING_SUPPORT].started.connect(show)
	Game.States[State.Name.KING_SUPPORT].ended.connect(hide)


func _on_soldier_button_pressed():
	Game.enemy_support_block(Game.CardTypes[CardType.UnitType.Soldier])


func _on_archer_button_pressed():
	Game.enemy_support_block(Game.CardTypes[CardType.UnitType.Archer])


func _on_monk_button_pressed():
	Game.enemy_support_block(Game.CardTypes[CardType.UnitType.Monk])
