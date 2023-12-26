class_name Party
extends Object

enum Status {
	CREATED,
	READY,
	STARTED,
	OVER
}

var status: Status = Status.CREATED
var id: int = 0

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
