class_name ShuffleHand extends Panel

const FAR_BELOW: int = 800
const FAR_ABOVE: int = -400

@export var slide_speed: float = 0.8
@export var slide_shift: float = 0.2


var sprite_size: float = 0.0
var is_animating: bool = false


@onready var hand_units := $HandUnits as Control
@onready var reshuffle_button := $HBoxContainer/ReshuffleButton as Button
@onready var play_button := $HBoxContainer/PlayButton as Button

## for TESTING purposes
@onready var is_running_locally: bool = get_parent().name == "root"


func _ready() -> void:
	sprite_size = hand_units.size.x / 3.0
	Events.hand_reshuffled.connect(update_hand)
	reshuffle_button.pressed.connect(request_reshuffle)
	play_button.pressed.connect(request_play)
	
	# TESTING
	if is_running_locally:
		update_hand(3)


func animate_falling() -> void:
	if not hand_units.get_children().is_empty():
		for texture: TextureRect in hand_units.get_children():
			var fall_tween := create_tween()
			fall_tween.tween_property(texture, "position", Vector2(texture.position.x, FAR_BELOW), slide_speed).set_trans(Tween.TRANS_QUAD)
			fall_tween.tween_callback(texture.queue_free)
			await get_tree().create_timer(slide_shift).timeout


func update_hand(reshuffle_attempts: int) -> void:
	is_animating = true
	animate_falling()
	
	reshuffle_button.text = "Reshuffle (" + str(reshuffle_attempts) + ")"
	if reshuffle_attempts == 0:
		reshuffle_button.disabled = true
	
	var unit_idx: int = 0
	for unit in GameManager.units.slice(0, 3) as Array[Unit.EUnitType]: # Exclude the king
		var unit_resource := GameManager.UNIT_RESOURCES[unit] as Unit
		assert(unit_resource is Unit, "Did not retrieve a valid unit")
		var unit_name := unit_resource.name
		var image: CompressedTexture2D = load("res://resources/sprites/" + unit_name + ".png")
		var new_texture := TextureRect.new()
		new_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		new_texture.size = Vector2(sprite_size, sprite_size)
		new_texture.position = Vector2(unit_idx * sprite_size, FAR_ABOVE)
		new_texture.texture = image
		hand_units.add_child(new_texture)
		unit_idx += 1
		var tween := create_tween()
		tween.tween_property(new_texture, "position", Vector2(new_texture.position.x, 0), slide_speed).set_trans(Tween.TRANS_QUAD)
		await get_tree().create_timer(slide_shift).timeout
	# Little extra wait before allowing interactions again
	await get_tree().create_timer(slide_shift).timeout
	is_animating = false


func request_reshuffle() -> void:
	if is_animating:
		return
	
	if is_running_locally:
		update_hand(3)
		return
	ActionsManager.run.rpc_id(1, Action.Code.RESHUFFLE_HAND)


func request_play() -> void:
	if is_animating:
		return
	ActionsManager.run.rpc_id(1, Action.Code.VALIDATE_HAND)
