class_name KingSupportMenu
extends PanelContainer


func _ready():
	Game.States[State.Name.KING_SUPPORT].started.connect(show)
	Game.States[State.Name.KING_SUPPORT].ended.connect(hide)


func _on_soldier_button_pressed():
	Game.enemy_support_block(CardType.UnitType.Soldier)


func _on_archer_button_pressed():
	Game.enemy_support_block(CardType.UnitType.Archer)


func _on_monk_button_pressed():
	Game.enemy_support_block(CardType.UnitType.Monk)