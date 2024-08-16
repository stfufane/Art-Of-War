class_name Party
extends Object
## Represents a game taking place between two players
##
## It's initialized by the first player, which generates an ID,
## then the second player joins and the game can begin.
## The state of the two players will be checked here to know who wins.

## Manages the different states of the party
enum EStatus {
    CREATED,
    STARTED,
    OVER
}

## A random 6 characters id to join a party
var id: String = Party.generate_id()
## The current status of the party
var status: EStatus = EStatus.CREATED

## The 2 players : id -> [Player]
var players: Dictionary = {}
var first_player: Player = null
var second_player: Player = null
## Whose turn is it
var current_player: int = 0

## The battlefield where the game takes place
var battlefield: PartyBattlefield = null


func _init(player: Player) -> void:
    player.first = true
    first_player = player
    add_player(player)


## Called when one of the players get disconnected from the server
## or if the game is over
func terminate() -> void:
    status = EStatus.OVER


func add_player(player: Player) -> void:
    if players.size() > 1:
        return

    player.setup()
    players[player.id] = player
    print("Add player ", player.id, " to party ", id)
    if players.size() == 2:
        status = EStatus.STARTED


func remove_player(peer_id: int) -> void:
    players.erase(peer_id)
    terminate()


func join(new_player: Player) -> void:
    if status != EStatus.CREATED:
        return

    print(new_player.id, " is joining party ", id)
    add_player(new_player)
    second_player = new_player

    # Initialize the battlefield
    battlefield = PartyBattlefield.new(self)

    # Reference the opponents for the two players
    first_player.opponent = second_player
    second_player.opponent = first_player

    # Start the game for the two players
    print("Starting party for player ", first_player.id, " and ", second_player.id)
    for player: Player in players.values():
        player.init_party()
        player.party = self

    GameServer.start_party(id)


## Creates a new game id that is unique in the game server
static func generate_id() -> String:
    const ID_CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    const ID_SIZE := 6
    var random_id: String = ""
    # Ensure we're generating a unique ID
    while random_id.is_empty() or GameServer.parties.has(random_id):
        for i in range(ID_SIZE):
            random_id += ID_CHARS[randi() % ID_CHARS.length()]
    return random_id


func init_kingdoms() -> void:
    for player: Player in players.values():
        player.init_kingdom()


## Compares the two players' kingdoms to see which units are winning on both sides
func update_kingdom_status() -> void:
    for unit_type: Unit.EUnitType in Unit.EUnitType.values():
        if unit_type == Unit.EUnitType.King:
            continue
        if first_player.kingdom.units[unit_type] == second_player.kingdom.units[unit_type]:
            first_player.kingdom.status[unit_type] = KingdomUnit.EStatus.Equal
            second_player.kingdom.status[unit_type] = KingdomUnit.EStatus.Equal
        elif first_player.kingdom.units[unit_type] < second_player.kingdom.units[unit_type]:
            first_player.kingdom.status[unit_type] = KingdomUnit.EStatus.Down
            second_player.kingdom.status[unit_type] = KingdomUnit.EStatus.Up
        else:
            first_player.kingdom.status[unit_type] = KingdomUnit.EStatus.Up
            second_player.kingdom.status[unit_type] = KingdomUnit.EStatus.Down

    # Notify the players with the new data
    GameManager.update_kingdom.rpc_id(first_player.id, first_player.kingdom.status)
    GameManager.update_kingdom.rpc_id(second_player.id, second_player.kingdom.status)


## Checks if one player is victorious based on their kingdom's populations
func check_kingdom_status() -> bool:
    var first_player_kingdom: Array[KingdomUnit.EStatus] = first_player.kingdom.status.values()
    var nb_up: int = first_player_kingdom.count(KingdomUnit.EStatus.Up)
    var nb_down: int = first_player_kingdom.count(KingdomUnit.EStatus.Down)
    if nb_up >= 4:
        first_player.state.has_won = true
        return true
    if nb_down >= 4:
        second_player.state.has_won = true
        return true
    return false
