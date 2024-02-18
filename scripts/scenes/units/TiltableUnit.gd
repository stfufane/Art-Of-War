class_name TiltableUnit extends Control

var unit: Unit:
	set(u):
		unit = u
		sprite.texture = load("res://resources/sprites/" + unit.name + ".png")

var tilted: bool = false

@onready var sprite: Sprite2D = $Sprite
@onready var animation: AnimationPlayer = $Sprite/AnimationPlayer


func _ready() -> void:
	mouse_entered.connect(func() -> void: if not tilted: animation.play("hovered"))
	mouse_exited.connect(func() -> void: if not tilted: animation.stop())


func toggle_tilt() -> void:
	if tilted:
		untilt()
	else:
		tilt()


func tilt() -> void:
	scale = Vector2(1.4, 1.4)
	position.y = -12
	tilted = true
	if not animation.is_playing():
		animation.play("hovered")


func untilt() -> void:
	scale = Vector2.ONE
	position.y = 0
	tilted = false
	if animation.is_playing():
		animation.stop()
