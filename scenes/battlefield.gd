class_name Battlefield
extends Control


var _attacking_card: Card = null
var _moved_card: Card = null

@onready var _enemy_container: Control = $EnemyContainer
@onready var _player_container: Control = $PlayerContainer


func _ready():
	# Setup the battlefield when players are ready.
	Game.players_ready.connect(setup)

	Game.battlefield_card_clicked.connect(_card_clicked)
	Game.enemy_battlefield_card_clicked.connect(_enemy_card_clicked)
	Game.card_killed.connect(_enemy_card_killed)
	Game.attack_validated.connect(_attack_ended)
	Game.attack_cancelled.connect(_attack_ended)

	# Disengage the cards at the beginning of the turn.
	Game.States[State.Name.START_TURN].started.connect(disengage_cards)

	# Before the player chooses an action, check if he can attack.
	Game.States[State.Name.ACTION_CHOICE].started.connect(start_action)


func setup() -> void:
	# Connect all the card nodes to react to click and hover
	for placeholder in _player_container.get_children():
		placeholder.card_placeholder_clicked.connect(_placeholder_clicked)
		placeholder.mouse_entered.connect(_mouse_entered.bind(placeholder))
		placeholder.mouse_exited.connect(_mouse_exited.bind(placeholder))


func start_action() -> void:
	Game.is_attack_available = is_attack_available()
	_moved_card = null


func disengage_cards() -> void:
	for placeholder in _player_container.get_children():
		placeholder.disengage_card()
		disengage_enemy_card.rpc(placeholder.name)


func all_highlights_off() -> void:
	for enemy_placeholder in _enemy_container.get_children():
		enemy_placeholder.highlight_off()


func all_flashes_off() -> void:
	for placeholder in _player_container.get_children():
		if placeholder.has_card():
			placeholder.get_current_card().stop_flash()
	for enemy_placeholder in _enemy_container.get_children():
		if enemy_placeholder.has_card():
			enemy_placeholder.get_current_card().stop_flash()


func has_enemy_units() -> bool:
	for placeholder in _enemy_container.get_children():
		if placeholder.has_card():
			return true
	return false


# Check if a placeholder is available for a card to be placed on it
func placeholder_available(placeholder: CardPlaceholder) -> bool:
	# First line is always available if there's no card already
	if placeholder.coords.y == -1:
		if placeholder.get_current_card() == null:
			return true
	else:
		# Second line is available if there's a card on the first line
		# Except if we're moving a card and want to swap it.
		var front_card = get_placeholder(placeholder.coords + Vector2(0, 1)).get_current_card()
		if front_card != null and front_card != _moved_card and placeholder.get_current_card() == null:
			return true

	return false


func get_placeholder(coords: Vector2) -> CardPlaceholder:
	for placeholder in _player_container.get_children():
		if placeholder.coords == coords:
			return placeholder
	return null


func get_enemy_placeholder(coords: Vector2) -> CardPlaceholder:
	for placeholder in _enemy_container.get_children():
		if placeholder.coords == coords:
			return placeholder
	return null


# Check that at least one card can attack an enemy card.
func is_attack_available() -> bool:
	for placeholder in _player_container.get_children():
		if !placeholder.has_card():
			continue
		if placeholder.get_current_card()._engaged:
			continue
		var attack_range: PackedVector2Array = placeholder.get_current_card().get_attack_range()
		var card_coords: Vector2 = placeholder.coords
		for enemy in _enemy_container.get_children():
			if !enemy.has_card():
				continue
			for coords in attack_range:
				if card_coords + coords == enemy.coords:
					return true
	return false


func validate_picked_card_added(clicked_placeholder: CardPlaceholder, clicked_card: Card = null) -> void:
	# Send a signal to the opponent to remove the card from his reserve
	if Game.picked_card._picked_from == Card.BoardArea.Reserve:
		Game.first_reserve_card_removed.emit()

	# You can switch card with one of the battlefield except during conscription
	if clicked_card != null and Game.get_state() != State.Name.CONSCRIPTION:
		# Put back the clicked card to the reserve or the hand.
		Game.battlefield_card_switched.emit(clicked_card, Game.picked_card._picked_from)

	# Take the card that was picked in the hand
	clicked_placeholder.set_card(Game.picked_card)
	Game.add_event.emit("have", "added a " + str(Game.picked_card._type) + " to the battlefied")
	Game.picked_card = null

	# Notify the opponent so it adds the card to his battlefield
	set_enemy_card.rpc(clicked_placeholder.get_current_card()._unit_type, clicked_placeholder.name, clicked_placeholder.get_current_card()._engaged)

	# Go to the next state
	match Game.get_state():
		State.Name.INIT_BATTLEFIELD:
			Game.end_state()
		State.Name.RECRUIT:
			# You can still play a support if you want but not attack neither recruit again.
			Game.has_recruited = true
			Game.start_state(State.Name.ACTION_CHOICE)
		State.Name.CONSCRIPTION:
			# The state will change when two units are recruited.
			Game.conscripted_units += 1


func move_card_behind(placeholder: CardPlaceholder, enemy: bool) -> void:
	var behind_placeholder: CardPlaceholder = null
	if enemy:
		behind_placeholder = get_enemy_placeholder(placeholder.coords + Vector2(0, 1))
	else:
		behind_placeholder = get_placeholder(placeholder.coords + Vector2(0, -1))
	
	if behind_placeholder != null and behind_placeholder.has_card():
		placeholder.set_card(behind_placeholder.get_current_card()) # it will reparent the card


func _mouse_entered(placeholder_hovered: CardPlaceholder) -> void:
	if placeholder_hovered.has_card():
		return
	
	match Game.get_state():
		State.Name.INIT_BATTLEFIELD, State.Name.RECRUIT, State.Name.MOVE_UNIT, State.Name.CONSCRIPTION:
			if placeholder_available(placeholder_hovered):
				placeholder_hovered.set_text("Place card here")
			else:
				placeholder_hovered.set_text("Can't place card here")


func _mouse_exited(placeholder_hovered: CardPlaceholder) -> void:
	placeholder_hovered.set_text("")


# Click on a placeholder to put a card on it
func _placeholder_clicked(clicked_placeholder: CardPlaceholder) -> void:
	match Game.get_state():
		State.Name.INIT_BATTLEFIELD, State.Name.RECRUIT, State.Name.CONSCRIPTION:
			# We can't put a card if there's already one there or if there's no card in hand
			if Game.picked_card != null and placeholder_available(clicked_placeholder):
				validate_picked_card_added(clicked_placeholder)

		State.Name.MOVE_UNIT:
			if _moved_card == null or !placeholder_available(clicked_placeholder):
				return
			
			_moved_card.stop_flash()
			var moved_from: CardPlaceholder = _moved_card.get_parent()
			move_card_behind(moved_from, false)

			# Remove the card remotely on the enemy battlefield
			remove_enemy_card.rpc(moved_from.name)
			# Move the card to the new placeholder
			clicked_placeholder.set_card(_moved_card)
			Game.add_event.emit("have", "moved a " + str(_moved_card._type) + " on the battlefield")
			# And notify the enemy with the new card's position
			set_enemy_card.rpc(_moved_card._unit_type, clicked_placeholder.name, _moved_card._engaged)
			Game.start_state(State.Name.ACTION_CHOICE)


# Click on a card to attack with it
func _card_clicked(clicked_card: Card) -> void:
	all_highlights_off()
	var clicked_placeholder: CardPlaceholder = clicked_card.get_parent()

	match Game.get_state():
		State.Name.ATTACK:
			Game.can_go_back = false
			if _attacking_card != null:
				_attacking_card.stop_flash()

			if clicked_card == _attacking_card:
				_attacking_card = null
				Game.can_go_back = true
				return

			_attacking_card = clicked_card
			_attacking_card.start_flash()

			# Highlight the enemy cards that are within reach of the selected card
			var attack_range: PackedVector2Array = clicked_card.get_attack_range()
			var card_coords: Vector2 = clicked_placeholder.coords
			for enemy in _enemy_container.get_children():
				for coords in attack_range:
					if card_coords + coords == enemy.coords:
						enemy.toggle_highlight()

		State.Name.RECRUIT, State.Name.CONSCRIPTION:
			if Game.picked_card != null:
				validate_picked_card_added(clicked_placeholder, clicked_card)

		State.Name.MOVE_UNIT:
			# Define the card we want to move
			if _moved_card == null:
				_moved_card = clicked_card
				_moved_card.start_flash()
				return

			# If we click on the same card, cancel the move
			if _moved_card == clicked_card:
				_moved_card.stop_flash()
				_moved_card = null
				return

			# If we have selected a card, swap with the new one.
			var moved_placeholder: CardPlaceholder = _moved_card.get_parent()
			Game.add_event.emit("have", "switched the " + str(_moved_card._type) + 
				" with the " + str(clicked_card._type))
			moved_placeholder.set_card(clicked_card)
			set_enemy_card.rpc(clicked_card._unit_type, moved_placeholder.name, clicked_card._engaged)
			clicked_placeholder.set_card(_moved_card)
			set_enemy_card.rpc(_moved_card._unit_type, clicked_placeholder.name, _moved_card._engaged)
			_moved_card.stop_flash()
			Game.start_state(State.Name.ACTION_CHOICE)


func _enemy_card_clicked(clicked_card: Card):	
	match Game.get_state():
		State.Name.ATTACK:
			if _attacking_card == null:
				return
			
			# Check that the card is within reach of the attacking card
			_attacking_card.attack()
			Game.has_attacked = true
			var attack_placeholder: CardPlaceholder = _attacking_card.get_parent()
			var enemy_placeholder: CardPlaceholder = clicked_card.get_parent()
			enemy_card_attacking.rpc(attack_placeholder.name, enemy_placeholder.name) # Notify the opponent that the card is attacking
			var enemy_coords: Vector2 = enemy_placeholder.coords
			var attacking_card_coords: Vector2 = attack_placeholder.coords
			for coords in _attacking_card.get_attack_range():
				if enemy_coords == attacking_card_coords + coords:
					all_highlights_off()
					Game.add_event.emit("are", "trying to attack the " + 
						str(enemy_placeholder.get_current_card()._type) + 
						" with a " + str(_attacking_card._type))
					Game.enemy_attack_block(_attacking_card, enemy_placeholder)
					break

		State.Name.ARCHER_ATTACK:
			Game.add_event.emit("have", "dealt 1 damage to the " + str(clicked_card._type) + " with the archer")
			Game.archer_attacked.emit(clicked_card)


func _attack_ended() -> void:
	enemy_attack_ended.rpc()


func _enemy_card_killed(killed_card: Card) -> void:
	var placeholder: CardPlaceholder = killed_card.get_parent() as CardPlaceholder
	placeholder.remove_card()
	# Check if there was a card in the row behind and move it forward if it's the case
	move_card_behind(placeholder, true)

	# Reflect the change on the enemy's board
	remove_card.rpc(placeholder.name)


### 
# Network functions that are called to reflect local actions on the opponent's battlefield
###

@rpc("any_peer")
func set_enemy_card(type: CardType.UnitType, placeholder_name: String, engaged: bool):
	var enemy_card = Game.create_card_instance(type)
	if engaged:
		enemy_card.engage()
	var enemy_placeholder: CardPlaceholder = _enemy_container.get_node(NodePath(placeholder_name))
	if enemy_placeholder.has_card():
		enemy_placeholder.remove_card()
	enemy_placeholder.set_card(enemy_card)
	enemy_card.rotation_degrees += 180 # Mirror it on the enemy side


@rpc("any_peer")
func remove_enemy_card(placeholder_name: String):
	var enemy_placeholder: CardPlaceholder = _enemy_container.get_node(NodePath(placeholder_name))
	enemy_placeholder.remove_card()
	move_card_behind(enemy_placeholder, true)


@rpc("any_peer")
func remove_card(placeholder_name: String):
	var placeholder: CardPlaceholder = _player_container.get_node(NodePath(placeholder_name))
	placeholder.remove_card()
	move_card_behind(placeholder, false)


@rpc("any_peer")
func enemy_card_attacking(placeholder_name: String, target_placeholder_name: String):
	var placeholder: CardPlaceholder = _enemy_container.get_node(NodePath(placeholder_name))
	var target_placeholder: CardPlaceholder = _player_container.get_node(NodePath(target_placeholder_name))
	var attacking_card: Card = placeholder.get_current_card()
	var target_card: Card = target_placeholder.get_current_card()
	attacking_card.engage()
	attacking_card.start_flash()
	target_card.start_flash()
	

@rpc("any_peer")
func enemy_attack_ended():
	all_flashes_off()


@rpc("any_peer")
func disengage_enemy_card(placeholder_name: String):
	var placeholder: CardPlaceholder = _enemy_container.get_node(NodePath(placeholder_name))
	if placeholder.has_card():
		var enemy_card: Card = placeholder.get_current_card()
		enemy_card.disengage()
