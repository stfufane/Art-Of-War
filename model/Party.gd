class_name Party extends Object

enum Status {
	CREATED,
	READY,
	STARTED,
	OVER
}

const ID_CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
const ID_SIZE := 6

var id: String = Party.generate_id() # A random 6 characters id to join a party
var status: Status = Status.CREATED

# Store players peer_id
var players: Array[int] = []


func add_player(peer_id: int) -> void:
	if players.size() > 1:
		return

	players.append(peer_id)
	if players.size() == 2:
		status = Status.READY


func remove_player(peer_id: int) -> void:
	if players.has(peer_id):
		players.erase(peer_id)

	status = Status.OVER


static func generate_id() -> String:
	var random_id: String = ""
	var unique: bool = false
	# Ensure we're generating a unique ID
	while not unique:
		for i in range(ID_SIZE):
			random_id += ID_CHARS[randi() % ID_CHARS.length()]
		unique = not Network.parties.any(func(party: Party): return party.id == random_id)
	return random_id
