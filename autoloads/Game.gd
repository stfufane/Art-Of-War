extends Node


signal players_ready # Both players have joined the game
signal reshuffle_deck # Re-trigger the card distribution at the beginning

signal instruction_updated(instruction: String) # Update the text label at the bottom
signal go_back_enabled(bool) # Tells the go back button to hide
signal add_log(aux: String, event: String) # Add a log in the game log panel

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
signal kingdom_card_clicked(card: Card)
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
	State.Name.CONSCRIPTION: State.new("You must recruit 2 units to repopulate the battlefield", false),
	State.Name.FINISH_TURN: State.new("Finish turn", false),
	State.Name.GAME_OVER: State.new("Game Over :)", true)
}

const UNITS: Dictionary = {
	CardUnit.UnitType.King: preload("res://model/cards/king.tres"),
	CardUnit.UnitType.Soldier: preload("res://model/cards/soldier.tres"),
	CardUnit.UnitType.Guard: preload("res://model/cards/guard.tres"),
	CardUnit.UnitType.Wizard: preload("res://model/cards/wizard.tres"),
	CardUnit.UnitType.Monk: preload("res://model/cards/monk.tres"),
	CardUnit.UnitType.Archer: preload("res://model/cards/archer.tres")
}

enum GameEnd {
	UNDECIDED,
	WIN,
	LOSE,
	TIE
}

var peer_id: int = 0
var enemy_id: int = 0
var first_player: bool = false

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
var _pending_support: Dictionary = {}

# Count the number of killed units on both sides because it can be used to decide who wins at the end.
var _dead_units: int = 0
var _dead_enemies: int = 0

# Useful when having having a support loop to know who is actually playing.
var _my_turn: bool = false

var game_end: GameEnd = GameEnd.UNDECIDED :
	set = set_game_end

# Handle a way to get back to the action choice menu in case of misclick
var can_go_back: bool = false :
	set(enabled):
		can_go_back = enabled
		go_back_enabled.emit(enabled)

# Follow what we've done in the current turn to toggle possible actions
var has_attacked: bool = false :
	set(attacked):
		has_attacked = attacked
		update_action_menu.emit()

var has_recruited: bool = false :
	set(recruited):
		has_recruited = recruited
		update_action_menu.emit()

var is_attack_available: bool = false :
	set(available):
		is_attack_available = available
		update_action_menu.emit()

var is_support_available: bool = false :
	set(available):
		is_support_available = available
		update_action_menu.emit()

var conscripted_units: int = 0 :
	set(nb):
		conscripted_units = nb
		if conscripted_units == 2:
			conscription_done()
			conscripted_units = 0 # Reset the counter


# Setup can be called by server only when 2 players have joined.
func setup() -> void:
	print("Setup Player ", peer_id)
	players_ready.emit()
	if first_player:
		start_state(State.Name.RESHUFFLE)
	else:
		instruction_updated.emit("Waiting for the other player")

	# When the turn starts, pass _my_turn to true and pass it to false for the enemy.
	States[State.Name.START_TURN].started.connect(start_turn)
	States[State.Name.ACTION_CHOICE].ended.connect(func(): can_go_back = true)


func create_card_instance(unit_type: CardUnit.UnitType) -> Card:
	var card_instance = CARD_SCENE.instantiate()
	card_instance.unit = UNITS[unit_type]
	return card_instance


func start_turn() -> void:
	_my_turn = true
	has_attacked = false
	has_recruited = false
	_attack_bonus = 0
	set_enemy_turn.rpc_id(enemy_id)


func start_state(state: State.Name, going_back: bool = false) -> void:
	if !going_back:
		States[_current_state].ended.emit()

	previous_state = _current_state
	_current_state = state
	instruction_updated.emit(States[state].instruction)

	# Avoid sending RPCs to the server when the server is the one calling this function.
	if state != State.Name.WAITING_FOR_PLAYER:
		if state == State.Name.GAME_OVER:
			set_enemy_state.rpc_id(enemy_id, State.Name.GAME_OVER)
		else:
			set_enemy_state.rpc_id(enemy_id, State.Name.WAITING_FOR_PLAYER)

	States[state].started.emit()


# When a state is finished by the first player, the second player enters the same state.
# When the second player finishes the state, the first player enters the next state.
# In both cases the current player waits.
func end_state() -> void:
	if first_player and States[_current_state].happens_once:
		set_enemy_state.rpc_id(enemy_id, _current_state)
	else:
		set_enemy_state.rpc_id(enemy_id, State.get_next_state(_current_state))


# After choosing an action, a button will appear to have the option to go back.
func go_back_to_action_choice() -> void:
	if !can_go_back:
		return

	start_state(previous_state, true)


# After attacking, the enemy can play a support card to block the attack.
func enemy_attack_block(attacking_card: Card, enemy_placeholder: CardPlaceholder) -> void:
	# First store the info about the attack currently in progress.
	_attack_info = {
		"attacking_card": attacking_card,
		"enemy_placeholder": enemy_placeholder
	}
	set_enemy_state.rpc_id(enemy_id, State.Name.ATTACK_BLOCK)


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
			# The following action will depend of the result of the attack
		else:
			attack_cancelled.emit()
			add_log.emit("are", "unable to play the attack, it has been blocked")
			# We can then choose an other action.
			start_state(State.Name.ACTION_CHOICE)

	_attack_info.clear()


func process_support_block(support_blocked: bool, is_rpc: bool = true) -> void:
	# If support was blocked, we can block it with an other support until it's not possible to block anymore
	if support_blocked:
		start_state(State.Name.SUPPORT_BLOCK)
		return

	if !_my_turn:
		return

	# Otherwise we apply the support effect if the enemy passed (if the call is non-rpc, it means the player passed)
	if is_rpc:
		if _pending_support.is_empty():
			# We couldn't block the enemy support during an attack, the attack is cancelled
			process_attack_block(false)
		else:
			match _pending_support.type:
				CardUnit.UnitType.Soldier:
					_attack_bonus += 1
					add_log.emit("have", "added a +1 bonus on the card attacks for this round.")
					start_state(State.Name.ACTION_CHOICE)
				CardUnit.UnitType.Monk:
					start_state(State.Name.MOVE_UNIT)
				CardUnit.UnitType.Archer:
					start_state(State.Name.ARCHER_ATTACK)
	else:
		if _pending_support.is_empty():
			# We couldn't block the enemy support during an attack, the attack is cancelled
			process_attack_block(false, false)
		else:
			add_log.emit("are", "unable to play the support, it has been blocked.")
			# Start a new action
			start_state(State.Name.ACTION_CHOICE)

	_pending_support.clear() # Reset the pending support


func enemy_support_block(support_type: CardUnit.UnitType) -> void:
	add_log.emit("are", "trying to play a " + UNITS[support_type].name + " as a support")
	_pending_support = { "type": support_type }
	set_enemy_state.rpc_id(enemy_id, State.Name.SUPPORT_BLOCK)


# After conscription has been done, the first player can resume his turn.
func conscription_done() -> void:
	set_enemy_state.rpc_id(enemy_id, State.Name.ACTION_CHOICE)


func set_game_end(end) -> void:
	# Avoid infinite loop
	if game_end != GameEnd.UNDECIDED:
		return

	game_end = end
	match game_end:
		GameEnd.WIN:
			set_other_game_end.rpc_id(enemy_id, GameEnd.LOSE)
			add_log.emit("have", "won")
		GameEnd.LOSE:
			set_other_game_end.rpc_id(enemy_id, GameEnd.WIN)
			add_log.emit("have", "lost")
		GameEnd.TIE:
			set_other_game_end.rpc_id(enemy_id, GameEnd.TIE)

#################################################################################
# Getters
#################################################################################

func get_state() -> State.Name :
	return _current_state


func get_attack_info() -> Dictionary:
	return _attack_info


func add_dead_enemy() -> void:
	_dead_enemies += 1
	add_dead_unit.rpc_id(enemy_id)


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


@rpc("any_peer")
func set_other_game_end(end: GameEnd) -> void:
	game_end = end
