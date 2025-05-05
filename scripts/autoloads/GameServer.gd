extends Node
## Defines RPC calls happening server side to handle parties and players


var players: Dictionary[int, Player] = {} ## The list of players : peer_id -> [Player]
var parties: Dictionary[String, Party] = {} ## The list of parties : party_id -> [Party]


#region Basic methods to manipulate/retrieve party/player
## When starting the party, the server tells both clients to load the board
## and they can reshuffle their deck
func start_party(party_id: String) -> void:
    var party: Party = get_party(party_id)
    if party == null:
        return

    for player: Player in party.players.values():
        GameManager.start_game.rpc_id(player.id, player.hand.units)
        player.state.current = StateManager.EState.RESHUFFLE


func add_player(peer_id: int) -> void:
    print(peer_id, " added to the server")
    players[peer_id] = Player.new(peer_id)


func remove_player(peer_id: int) -> void:
    var player := get_player(peer_id)
    var party := player.party
    if party != null:
        # Notify the other player that the game is over to put it back in the lobby
        var opponent := player.opponent
        if is_instance_valid(opponent):
            GameManager.notify_party_stopped.rpc_id(opponent.id)
        party.players.erase(peer_id)
        print("Party %s is over" % party.id)
        parties.erase(party.id)
        party.free()
    player.free()
    players.erase(peer_id)
    print("%d removed from the server" % peer_id)


func get_current_player() -> Player:
    if not multiplayer.is_server():
        return null

    var player_id := multiplayer.get_remote_sender_id()
    return get_player(player_id)


func get_player(player_id: int) -> Player:
    return players.get(player_id)


func get_party(party_id: String) -> Party:
    return parties.get(party_id)


#endregion


#region RPC methods called by the client to create/join/cancel a party
@rpc("any_peer")
func create_party() -> void:
    # Only the server can initialize a party
    if not multiplayer.is_server():
        return

    var player_id := multiplayer.get_remote_sender_id()
    if not players.has(player_id):
        print("Player %d not found" % player_id)
        return

    print("%d wants to create a party" % player_id)
    var party: Party = Party.new(get_player(player_id));
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
        print("Player %d not found" % player_id)
        return

    # Find the index of the first available party to join
    var party_to_join: Party = parties.get(id)
    if party_to_join != null and party_to_join.status == Party.EStatus.CREATED:
        party_to_join.join(get_player(player_id))
    else:
        # The party does not exist anymore
        GameManager.party_not_found.rpc_id(player_id)


@rpc("any_peer")
func cancel_party() -> void:
    var player: Player = get_current_player()

    print("Cancel party %s" % player.party.id)
    parties.erase(player.party.id)
    player.party.free()
    GameManager.notify_party_cancelled.rpc_id(player.id)

#endregion
