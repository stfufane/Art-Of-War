class_name BattleTile
extends TextureRect


@export var coords: Vector2
@export var id: int ## To identify the tile and mirror it with the enemy tiles
@export var side: Board.ESide = Board.ESide.PLAYER


var unit: Unit = null
var hovered: bool = false

var unit_engaged: bool = false:
    set(engaged):
        unit_engaged = engaged
        if unit_engaged:
            self_modulate = Color(1.0, 0.7, 0.6, 1.0)
        else:
            reset_color()


@onready var unit_sprite := $UnitSprite as TextureRect


func _ready() -> void:
    gui_input.connect(_on_gui_input)
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)


func set_unit(unit_type: Unit.EUnitType) -> void:
    # TODO: handle the reset of the tile when we remove a unit.
    unit = GameManager.UNIT_RESOURCES[unit_type]
    unit_sprite.texture = load("res://resources/sprites/" + unit.name + ".png")
    if side == Board.ESide.ENEMY:
        unit_sprite.flip_h = true


func reset_color() -> void:
    self_modulate = Color(1.0, 1.0, 1.0, 1.0)


func toggle_range_hint(state: bool) -> void:
    # Skip hovered tiles, they're handled already
    if side == Board.ESide.PLAYER and hovered:
        return

    if state:
        self_modulate = Color(5.0, 3.2, 3.5, 1.0)
    else:
        reset_color()


func _on_mouse_entered() -> void:
    hovered = true
    if side == Board.ESide.PLAYER and unit == null:
        self_modulate = Color(5.0, 5.0, 5.0, 1.0)
    Events.battle_tile_hovered.emit(self, true)


func _on_mouse_exited() -> void:
    hovered = false
    if side == Board.ESide.PLAYER:
        reset_color()
    Events.battle_tile_hovered.emit(self, false)


func _on_gui_input(event: InputEvent) -> void:
    if !event.is_action_pressed(GameManager.LEFT_CLICK):
        return
    Events.battle_tile_clicked.emit(self)
