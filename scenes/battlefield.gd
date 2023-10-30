class_name Battlefield
extends Control

signal card_added

var _attacking_card: Card = null

@onready var _enemy_container: Control = $EnemyContainer
@onready var _player_container: Control = $PlayerContainer


func setup():
	# Connect all the card nodes to react to click and hover
	for placeholder in _player_container.get_children():
		placeholder.card_placeholder_clicked.connect(_placeholder_clicked)
		placeholder.mouse_entered.connect(_mouse_entered.bind(placeholder))
		placeholder.mouse_exited.connect(_mouse_exited.bind(placeholder))


func disengage_cards():
	for placeholder in _player_container.get_children():
		placeholder.disengage_card()


func all_highlights_off():
	for enemy_placeholder in _enemy_container.get_children():
		enemy_placeholder.highlight_off()


# Check if a placeholder is available for a card to be placed on it
func placeholder_available(placeholder: CardPlaceholder) -> bool:
	# First line is always available if there's no card already
	if placeholder.coords.y == -1:
		if placeholder.get_current_card() == null:
			return true
	else:
		# Second line is available if there's a card on the first line
		var front_card = get_placeholder(placeholder.coords + Vector2(0, 1)).get_current_card()
		if front_card != null and placeholder.get_current_card() == null:
			return true

	return false


func get_placeholder(coords: Vector2) -> CardPlaceholder:
	for placeholder in _player_container.get_children():
		if placeholder.coords == coords:
			return placeholder
	return null


func _mouse_entered(placeholder_hovered: CardPlaceholder):
	match Game.get_state():
		State.Name.INIT_BATTLEFIELD, State.Name.RECRUIT:
			if placeholder_available(placeholder_hovered):
				placeholder_hovered.set_text("Place card here")
			else:
				placeholder_hovered.set_text("Can't place card here")
		_:
			pass


func _mouse_exited(placeholder_hovered: CardPlaceholder):
	if placeholder_hovered.get_current_card() == null:
		placeholder_hovered.set_text("")


# Click on a placeholder to put a card on it
func _placeholder_clicked(id: int):
	var clicked_placeholder: CardPlaceholder = instance_from_id(id)
	# We can't put a card if there's already one there.
	if !placeholder_available(clicked_placeholder):
		return
	
	match Game.get_state():
		State.Name.INIT_BATTLEFIELD, State.Name.RECRUIT:
			# We can't put a card if there's no card in hand
			if Game.picked_card == null:
				return
			
			card_added.emit()
			# Take the card that was picked in the hand and remove previous connected signals
			clicked_placeholder.set_card(Game.picked_card)
			Game.picked_card.remove_click_connections()
			Game.picked_card = null

			clicked_placeholder.connect_click(_card_clicked)
			# Notify the opponent so it adds the card to his battlefield
			add_enemy_card.rpc(clicked_placeholder.get_current_card()._unit_type, clicked_placeholder.name)
		_:
			pass


# Click on a card to attack with it
func _card_clicked(id: int):
	all_highlights_off()
	if _attacking_card != null:
		_attacking_card.stop_flash()

	var clicked_card: Card = instance_from_id(id)
	if Game.get_state() != State.Name.ATTACK:
		return

	if clicked_card == _attacking_card:
		_attacking_card = null
		return

	_attacking_card = clicked_card
	_attacking_card.start_flash()

	var placeholder: CardPlaceholder = instance_from_id(clicked_card.placeholder_id)
	# Highlight the enemy cards that are within reach of the selected card
	var attack_range: PackedVector2Array = clicked_card.get_attack_range()
	var card_coords: Vector2 = placeholder.coords
	for enemy in _enemy_container.get_children():
		for coords in attack_range:
			if card_coords + coords == enemy.coords:
				enemy.toggle_highlight()


func _enemy_card_clicked(id: int):
	if Game.get_state() != State.Name.ATTACK || _attacking_card == null:
		return
	
	# Check that the card is within reach of the attacking card
	var clicked_card: Card = instance_from_id(id)
	var attack_range = _attacking_card.get_attack_range()
	var enemy_coords: Vector2 = instance_from_id(clicked_card.placeholder_id).coords
	var attacking_card_coords: Vector2 = instance_from_id(_attacking_card.placeholder_id).coords
	for coords in attack_range:
		if enemy_coords == attacking_card_coords + coords:
			_attacking_card.attack()
			_attacking_card = null
			all_highlights_off()
			# TODO: Store the ongoing attack to know if it can be applied or not
			# Check if the opponent blocks the attack
			Game.enemy_support()
			break


### 
# Network functions that are called to reflect local actions on the opponent's battlefield
###

@rpc("any_peer")
func add_enemy_card(type: CardType.UnitType, placeholder_name: String):
	var enemy_card = Game.create_card_instance(type)
	var enemy_placeholder: CardPlaceholder = $EnemyContainer.get_node(placeholder_name)
	enemy_placeholder.set_card(enemy_card)
	enemy_placeholder.connect_click(_enemy_card_clicked)
	enemy_card.rotation_degrees = 180 # Mirror it on the enemy side

