class_name BattleTile extends TextureRect


@export var coords: Vector2
@export var id: int ## To identify the tile and mirror it with the enemy tiles
@export var side: Board.ESide = Board.ESide.PLAYER

var unit: Unit = null
var unit_engaged: bool = false :
	set(engaged):
		unit_engaged = engaged
		if unit_engaged:
			self_modulate = Color(1.0, 0.0, 0.0, 1.0)
		else:
			self_modulate = Color(1.0, 1.0, 1.0, 1.0)

@onready var unit_sprite := $UnitSprite as TextureRect

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	if side == Board.ESide.PLAYER:
		mouse_entered.connect(func() -> void: self_modulate = Color(5.0, 5.0, 5.0, 1.0))
		mouse_exited.connect(func() -> void: self_modulate = Color(1.0, 1.0, 1.0, 1.0))


func set_unit(unit_type: Unit.EUnitType) -> void:
	unit = GameManager.UNIT_RESOURCES[unit_type]
	unit_sprite.texture = load("res://resources/sprites/" + unit.name + ".png")
	if side == Board.ESide.ENEMY:
		unit_sprite.flip_h = true


func _on_gui_input(event: InputEvent) -> void:
	if !event.is_action_pressed(GameManager.LEFT_CLICK):
		return
	Events.battle_tile_clicked.emit(self)
