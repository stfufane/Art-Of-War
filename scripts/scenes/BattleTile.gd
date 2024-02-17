class_name BattleTile extends TextureRect


@export var coords: Vector2
@export var id: int ## To identify the tile and mirror it with the enemy tiles
@export var side: Battlefield.ESide = Battlefield.ESide.PLAYER

var unit: Unit = null

@onready var unit_sprite := $UnitSprite as TextureRect

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	if side == Battlefield.ESide.PLAYER:
		mouse_entered.connect(func() -> void: self_modulate = Color(5.0, 5.0, 5.0, 1.0))
		mouse_exited.connect(func() -> void: self_modulate = Color(1.0, 1.0, 1.0, 1.0))


func set_unit(unit_type: Unit.EUnitType) -> void:
	unit = GameManager.UNIT_RESOURCES[unit_type]
	unit_sprite.texture = load("res://resources/sprites/" + unit.name + ".png")
	if side == Battlefield.ESide.ENEMY:
		unit_sprite.flip_h = true


func _on_gui_input(event: InputEvent) -> void:
	if !event.is_action_pressed(GameManager.LEFT_CLICK):
		return
	Events.battle_tile_clicked.emit(self)
