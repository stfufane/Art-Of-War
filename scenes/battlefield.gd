class_name Battlefield
extends Control


var _attacking_card: Card = null

@onready var _enemy_container: Control = $EnemyContainer
@onready var _player_container: Control = $PlayerContainer


func _ready():
	# Setup the battlefield when players are ready.
	Game.players_ready.connect(setup)

	Game.battlefield_card_clicked.connect(_card_clicked)
	Game.enemy_battlefield_card_clicked.connect(_enemy_card_clicked)

	# Disengage the cards at the beginning of the turn.
	Game.States[State.Name.START_TURN].started.connect(disengage_cards)


func setup() -> void:
	# Connect all the card nodes to react to click and hover
	for placeholder in _player_container.get_children():
		placeholder.card_placeholder_clicked.connect(_placeholder_clicked)
		placeholder.mouse_entered.connect(_mouse_entered.bind(placeholder))
		placeholder.mouse_exited.connect(_mouse_exited.bind(placeholder))


func disengage_cards() -> void:
	for placeholder in _player_container.get_children():
		placeholder.disengage_card()


func all_highlights_off() -> void:
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


func _mouse_entered(placeholder_hovered: CardPlaceholder) -> void:
	if placeholder_hovered.has_card():
		return
	
	match Game.get_state():
		State.Name.INIT_BATTLEFIELD, State.Name.RECRUIT:
			if placeholder_available(placeholder_hovered):
				placeholder_hovered.set_text("Place card here")
			else:
				placeholder_hovered.set_text("Can't place card here")
		_:
			pass


func _mouse_exited(placeholder_hovered: CardPlaceholder) -> void:
	placeholder_hovered.set_text("")


# Click on a placeholder to put a card on it
func _placeholder_clicked(clicked_placeholder: CardPlaceholder) -> void:
	# We can't put a card if there's already one there.
	if !placeholder_available(clicked_placeholder):
		return
	
	match Game.get_state():
		State.Name.INIT_BATTLEFIELD, State.Name.RECRUIT:
			# We can't put a card if there's no card in hand
			if Game.picked_card == null:
				return

			# Take the card that was picked in the hand
			clicked_placeholder.set_card(Game.picked_card)
			Game.picked_card = null

			# Notify the opponent so it adds the card to his battlefield
			add_enemy_card.rpc(clicked_placeholder.get_current_card()._unit_type, clicked_placeholder.name)

			# Go to the next state
			if Game.get_state() == State.Name.INIT_BATTLEFIELD:
				Game.end_state()
			else:
				Game.start_state(State.Name.FINISH_TURN)
		_:
			pass


# Click on a card to attack with it
func _card_clicked(clicked_card: Card) -> void:
	all_highlights_off()
	if _attacking_card != null:
		_attacking_card.stop_flash()

	if Game.get_state() != State.Name.ATTACK:
		return

	if clicked_card == _attacking_card:
		_attacking_card = null
		return

	_attacking_card = clicked_card
	_attacking_card.start_flash()

	# Highlight the enemy cards that are within reach of the selected card
	var attack_range: PackedVector2Array = clicked_card.get_attack_range()
	var card_coords: Vector2 = clicked_card.placeholder.coords
	for enemy in _enemy_container.get_children():
		for coords in attack_range:
			if card_coords + coords == enemy.coords:
				enemy.toggle_highlight()


func _enemy_card_clicked(clicked_card: Card):
	if Game.get_state() != State.Name.ATTACK || _attacking_card == null:
		return
	
	# Check that the card is within reach of the attacking card
	var enemy_placeholder: CardPlaceholder = clicked_card.placeholder
	var enemy_coords: Vector2 = enemy_placeholder.coords
	var attacking_card_coords: Vector2 = _attacking_card.placeholder.coords
	for coords in _attacking_card.get_attack_range():
		if enemy_coords == attacking_card_coords + coords:
			all_highlights_off()
			Game.enemy_attack_block(_attacking_card, enemy_placeholder)
			break


### 
# Network functions that are called to reflect local actions on the opponent's battlefield
###

@rpc("any_peer")
func add_enemy_card(type: CardType.UnitType, placeholder_name: String):
	var enemy_card = Game.create_card_instance(type)
	var enemy_placeholder: CardPlaceholder = $EnemyContainer.get_node(placeholder_name)
	enemy_placeholder.set_card(enemy_card)
	enemy_card.rotation_degrees = 180 # Mirror it on the enemy side

