extends Node


signal players_ready # Both players have joined the game
signal reshuffle_deck # Re-trigger the card distribution at the beginning

signal instruction_updated(instruction: String) # Update the text label at the bottom
signal can_go_back(bool) # Tells the go back button to hide
signal add_event(aux: String, event: String) # Add a log in the game log panel

signal hand_size_updated(size: int) # The number of cards in the hand got updated

signal no_support_played # The player did not try to block the current support and passed

signal attack_validated # The current attack is being applied
signal attack_cancelled # The current attack is being cancelled

signal archer_attacked(card: Card) # Some damage has been dealt by an archer
signal card_killed(card: Card) # A card died on the battlefield

signal first_reserve_card_removed # The card most left of the reserve is being picked for recruitment
signal battlefield_card_switched(card: Card, to: Card.BoardArea) # A card is being moved on the battlefield

signal update_action_menu # A condition has changed and may have enabled/disabled an action from the menu

# When a card is clicked, it will emit a signal depending on where it lies on the board.
signal hand_card_clicked(card: Card)
signal reserve_card_clicked(card: Card)
signal battlefield_card_clicked(card: Card)
signal enemy_battlefield_card_clicked(card: Card)


# The list of all available states with their associated texts
var States: Dictionary = {
	State.Name.WAITING_FOR_PLAYER: State.new("Waiting for opponent", false),
	State.Name.RESHUFFLE: State.new("Need to reshuffle your hand ?", true),
	State.Name.INIT_BATTLEFIELD: State.new("Init battlefield", true),
	State.Name.INIT_RESERVE: State.new("Init reserve", true),
	State.Name.START_TURN: State.new("Start turn", false),
	State.Name.ACTION_CHOICE: State.new("Action choice", false),
	State.Name.RECRUIT: State.new("Recruit a unit", false),
	State.Name.SUPPORT: State.new("Play a support by adding it to your reserve", false),
	State.Name.KING_SUPPORT: State.new("Choose what unit your king is playing as", false),
	State.Name.MOVE_UNIT: State.new("Move a unit on the battlefield", false),
	State.Name.ARCHER_ATTACK: State.new("Choose a target to hit with your archer", false),
	State.Name.SUPPORT_BLOCK: State.new("You can block the enemy support by using a wizard or a king", false),
	State.Name.ATTACK: State.new("Attack a unit on the enemy battlefield", false),
	State.Name.ATTACK_BLOCK: State.new("You can block the enemy attack by using a guard or a king", false),
	State.Name.FINISH_TURN: State.new("Finish turn", false),
}


# All the types of units that can be played with their respective properties
var CardTypes: Dictionary = {
	CardType.UnitType.King: CardType.new(CardType.UnitType.King, "King", 1, 5, 4, [Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)]),
	CardType.UnitType.Soldier: CardType.new(CardType.UnitType.Soldier, "Soldier", 0, 2, 1, [Vector2(0, 1)]),
	CardType.UnitType.Archer: CardType.new(CardType.UnitType.Archer, "Archer", 1, 2, 1, [Vector2(-2, 1), Vector2(2, 1), Vector2(-1, 2), Vector2(1, 2)]),
	CardType.UnitType.Guard: CardType.new(CardType.UnitType.Guard, "Guard", 1, 3, 2, [Vector2(0, 1)]),
	CardType.UnitType.Wizard: CardType.new(CardType.UnitType.Wizard, "Wizard", 1, 2, 1, [Vector2(0, 1), Vector2(0, 2), Vector2(0, 3)]),
	CardType.UnitType.Monk: CardType.new(CardType.UnitType.Monk, "Monk", 1, 2, 2, [Vector2(-1, 1), Vector2(1, 1), Vector2(-2, 2), Vector2(2, 2)])
}


const CARD_SCENE: PackedScene = preload("res://scenes/card.tscn") # The template to create a card

# Input map constant
const LEFT_CLICK: String = "left_click"

var _current_state: State.Name = State.Name.WAITING_FOR_PLAYER
var previous_state: State.Name = State.Name.WAITING_FOR_PLAYER
var picked_card: Card = null

var _attack_info: Dictionary = {} # The state of the ongoing attack, storing the attacker and its target
var _attack_bonus: int = 0 # Bonus applied to every card attack after a soldier has been used as a support

# When using a support, we first let the enemy try to block it, so we have to save 
# what we're currently trying to do
var _pending_support: CardType = null

# Count the number of killed units on both sides because it can be used to decide who wins at the end.
var _dead_units: int = 0
var _dead_enemies: int = 0


# The local multiplayer server port
const PORT = 1234
var enet_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

var peer_id: int = 0
var first_player: bool = false

# Useful when having having a support loop to know who is actually playing.
var _my_turn: bool = false

# Handle a way to get back to the action choice menu in case of misclick
var _can_go_back: bool = false

# Follow what we've done in the current turn to toggle possible actions
var has_attacked: bool = false :
	set(attacked):
		has_attacked = attacked
		update_action_menu.emit()
	get:
		return has_attacked

var has_recruited: bool = false :
	set(recruited):
		has_recruited = recruited
		update_action_menu.emit()
	get:
		return has_recruited

var is_attack_available: bool = false :
	set(available):
		is_attack_available = available
		update_action_menu.emit()
	get:
		return is_attack_available

var is_support_available: bool = false :
	set(available):
		is_support_available = available
		update_action_menu.emit()
	get:
		return is_support_available


func start_server() -> void:
	enet_peer.create_server(PORT, 2)
	multiplayer.multiplayer_peer = enet_peer
	peer_id = multiplayer.get_unique_id()
	first_player = true
	multiplayer.peer_connected.connect(setup)


func join_server() -> void:
	enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer
	peer_id = multiplayer.get_unique_id()
	multiplayer.peer_connected.connect(setup)


func setup(_player_id: int) -> void:
	players_ready.emit()
	if first_player:
		start_state(State.Name.RESHUFFLE)
	else:
		instruction_updated.emit("Waiting for the other player")

	# When the turn starts, pass _my_turn to true and pass it to false for the enemy.
	States[State.Name.START_TURN].started.connect(start_turn)
	States[State.Name.ACTION_CHOICE].ended.connect(func(): _can_go_back = true)


func create_card_instance(unit_type: CardType.UnitType) -> Card:
	var card_instance = CARD_SCENE.instantiate()
	card_instance.set_unit_type(unit_type)
	return card_instance


func start_turn() -> void:
	_my_turn = true
	has_attacked = false
	has_recruited = false
	_attack_bonus = 0
	set_enemy_turn.rpc()


func start_state(state: State.Name, going_back: bool = false) -> void:
	previous_state = _current_state
	_current_state = state
	instruction_updated.emit(States[state].instruction)

	if !going_back:
		States[previous_state].ended.emit()

	# Avoid sending RPCs to the server when the server is the one calling this function.
	if state != State.Name.WAITING_FOR_PLAYER:
		set_enemy_state.rpc(State.Name.WAITING_FOR_PLAYER)

	States[state].started.emit()


# When a state is finished by the first player, the second player enters the same state.
# When the second player finishes the state, the first player enters the next state.
# In both cases the current player waits.
func end_state() -> void:
	if first_player and States[_current_state].happens_once:
		set_enemy_state.rpc(_current_state)
	else:
		set_enemy_state.rpc(State.get_next_state(_current_state))


# After choosing an action, a button will appear to have the option to go back.
func go_back_to_action_choice() -> void:
	if !_can_go_back:
		return
	
	start_state(previous_state, true)


# After attacking, the enemy can play a support card to block the attack.
func enemy_attack_block(attacking_card: Card, enemy_placeholder: CardPlaceholder) -> void:
	# First store the info about the attack currently in progress.
	_attack_info = {
		"attacking_card": attacking_card,
		"enemy_placeholder": enemy_placeholder
	}
	set_enemy_state.rpc(State.Name.ATTACK_BLOCK)


func process_attack_block(attack_blocked: bool, is_rpc: bool = true) -> void:
	# If attack was blocked, we can block the support with an other support until it's not possible to block anymore
	if attack_blocked:
		# After an attack has been blocked, the enemy can play a support card to block the other support.
		start_state(State.Name.SUPPORT_BLOCK)
		return

	# Otherwise we apply the attack that was in progress
	if _my_turn:
		if is_rpc:
			attack_validated.emit()
		else:
			attack_cancelled.emit()
			add_event.emit("are", "unable to play the attack, it has been blocked")

	_attack_info.clear()
	
	# We can then choose an other action.
	start_state(State.Name.ACTION_CHOICE)


func process_support_block(support_blocked: bool, is_rpc: bool = true) -> void:
	# If support was blocked, we can block it with an other support until it's not possible to block anymore
	if support_blocked:
		start_state(State.Name.SUPPORT_BLOCK)
		return
	
	# Otherwise we apply the support effect if the enemy passed (if the call is non-rpc, it means the player passed)
	if _my_turn:
		if is_rpc:
			match _pending_support.type:
				CardType.UnitType.Soldier:
					_attack_bonus += 1
					add_event.emit("have", "added a +1 bonus on the card attacks for this round.")
					start_state(State.Name.ACTION_CHOICE)
				CardType.UnitType.Monk:
					start_state(State.Name.MOVE_UNIT)
				CardType.UnitType.Archer:
					start_state(State.Name.ARCHER_ATTACK)
				CardType.UnitType.King: # King means no pending support, attack block in progress instead
					process_attack_block(false)
		else:
			if _pending_support == null:
				# We couldn't block the enemy support during an attack, the attack is cancelled
				process_attack_block(false, false)
			else:
				add_event.emit("are", "unable to play the support, it has been blocked.")
				# Start a new action
				start_state(State.Name.ACTION_CHOICE)

	_pending_support = null # Reset the pending support


func enemy_support_block(support_card: CardType) -> void:
	add_event.emit("are", "trying to play a " + str(support_card) + " as a support")
	_pending_support = support_card
	set_enemy_state.rpc(State.Name.SUPPORT_BLOCK)


#################################################################################
# Getters
#################################################################################

func get_state() -> State.Name :
	return _current_state


func get_attack_info() -> Dictionary:
	return _attack_info


func add_dead_enemy() -> void:
	_dead_enemies += 1
	add_dead_unit.rpc()


func set_can_go_back(enabled: bool) -> void:
	_can_go_back = enabled
	can_go_back.emit(enabled)


#################################################################################
# Network actions that are called to reflect local actions on the enemy board  ##
#################################################################################

@rpc("any_peer")
func set_enemy_state(state: State.Name) -> void:
	start_state(state)


@rpc("any_peer")
func set_enemy_turn() -> void:
	_my_turn = false


@rpc("any_peer")
func add_dead_unit() -> void:
	_dead_units += 1
