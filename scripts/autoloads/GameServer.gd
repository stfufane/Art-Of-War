extends Node
## Defines actions and RPC calls happening server side
##
## The in-game actions must be registered here so they can
## be called from anywhere.


var players: Dictionary = {} ## The list of players : peer_id -> Player
var parties: Dictionary = {} ## The list of parties : party_id -> Party

## A collection of [Action] objects associated to their [enum Action.Code]
var actions: Dictionary = {}


func register_actions() -> void:
	if not multiplayer.is_server():
		return
	Player.register_actions()


func register_action(code: Action.Code, action: Action) -> void:
	actions[code] = action.with_code(code)


@rpc("any_peer")
func run_action(code: Action.Code, data: Variant = null) -> void:
	assert(actions.has(code), "Could not find the action with code " + Action.Code.keys()[code] + ", did you register it?")
	var action := actions.get(code) as Action
	action.run(data)


#region basic methods to manipulate/retrieve party/player
## When starting the party, the server tells both clients to load the board
## and they can reshuffle their deck
func start_party(party_id: String) -> void:
	var party: Party = get_party(party_id)
	if party == null:
		return

	for player: Player in party.players.values():
		GameManager.start_game.rpc_id(player.id, player.hand)
		player.current_state = StateManager.EState.RESHUFFLE


func add_player(peer_id: int) -> void:
	print(peer_id, " added to the server")
	players[peer_id] = Player.new(peer_id)


func remove_player(peer_id: int) -> void:
	print(peer_id, " removed from the server")
	players.erase(peer_id)


func get_current_party() -> Party:
	if not multiplayer.is_server():
		return null

	return get_current_player().party


func get_current_player() -> Player:
	if not multiplayer.is_server():
		return null
	
	var player_id := multiplayer.get_remote_sender_id()
	return players[player_id] as Player ## Can return null as well


func get_player(player_id: int) -> Player:
	return players.get(player_id) as Player

func get_party(party_id: String) -> Party:
	return parties.get(party_id) as Party

func get_first_player(party_id: String) -> Player:
	return get_party(party_id).first_player

func get_second_player(party_id: String) -> Player:
	return get_party(party_id).second_player

#endregion


#region RPC methods called by the client to create/join/cancel a party
@rpc("any_peer")
func create_party() -> void:
	# Only the server can initialize a party
	if not multiplayer.is_server():
		return

	var player_id := multiplayer.get_remote_sender_id()
	if not players.has(player_id):
		print("Player ", player_id, " not found")
		return

	print("%d wants to create a party" % player_id)
	var party: Party = Party.new(players.get(player_id));
	players[player_id].party = party
	parties[party.id] = party
	GameManager.notify_party_created.rpc_id(player_id, party.id)


@rpc("any_peer")
func join_party(id: String) -> void:
	# Only the server can handle parties
	if not multiplayer.is_server():
		return

	var player_id := multiplayer.get_remote_sender_id()
	print("%d wants to join party %s" % [player_id, id])

	if not players.has(player_id):
		print("Player ", player_id, " not found")
		return

	# Find the index of the first available party to join
	var party_to_join: Party = parties.get(id)
	if party_to_join != null and party_to_join.status == Party.EStatus.CREATED:
		party_to_join.join(players.get(player_id))
	else:
		# The party does not exist anymore
		GameManager.party_not_found.rpc_id(player_id)


@rpc("any_peer")
func cancel_party() -> void:
	var player: Player = get_current_player()

	print("Cancel party ", player.party.id)
	parties.erase(player.party.id)
	GameManager.notify_party_cancelled.rpc_id(player.id)

#endregion
