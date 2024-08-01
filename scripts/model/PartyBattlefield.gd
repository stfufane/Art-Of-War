class_name PartyBattlefield extends RefCounted

var party: Party = null

var player_tiles: Dictionary = {}

func _init(p: Party) -> void:
	party = p
	player_tiles = {
		p.first_player.id: PlayerTiles.new(),
		p.second_player.id: PlayerTiles.new()
	}


func can_set_unit(player_id: int, tile_id: int) -> bool:
	return player_tiles[player_id].can_set_unit(tile_id)


func set_unit(player: Player, tile_id: int, unit: Unit) -> void:
	player_tiles[player.id].set_unit(tile_id, unit)
	update_battlefield_ui(player, tile_id, unit.type)


func reset_units(player_id: int) -> void:
	for tile in player_tiles[player_id].tiles.values() as Array[UnitTile]:
		tile.reset_hp()


func update_battlefield_ui(player: Player, tile_id: int, unit_type: Unit.EUnitType) -> void:
	GameManager.update_battlefield.rpc_id(player.id, Board.ESide.PLAYER, tile_id, unit_type)
	GameManager.update_battlefield.rpc_id(player.opponent.id, Board.ESide.ENEMY, tile_id, unit_type)


class UnitTile:
	var id: int
	var position: Vector2
	var hp: int = 0
	var unit: Unit = null:
		set(u):
			unit = u
			if u != null:
				hp = u.defense
	var engaged: bool = false:
		set(e):
			engaged = e
			if e:
				hp = unit.defense_engaged

	func _init(tile_id: int, tile_position: Vector2) -> void:
		id = tile_id
		position = tile_position

	func reset_hp() -> void:
		if unit != null:
			hp = unit.defense


## The two sides of the battlefield are mirrored horizontally so they can be represented by the same class
## The x origin is the center of the battlefield
class PlayerTiles:
	var tiles: Dictionary = {}

	func _init() -> void:
		tiles[0] = UnitTile.new(0, Vector2(1, 0))
		tiles[1] = UnitTile.new(1, Vector2(1, 1))
		tiles[2] = UnitTile.new(2, Vector2(1, 2))
		tiles[3] = UnitTile.new(3, Vector2(2, 0))
		tiles[4] = UnitTile.new(4, Vector2(2, 1))
		tiles[5] = UnitTile.new(5, Vector2(2, 2))


	func can_set_unit(tile_id: int) -> bool:
		assert(tiles.has(tile_id), "Invalid tile id %d" % tile_id)
		if tiles[tile_id].unit != null:
			return false
		# You can't put a tile on the back row if the front row is empty
		if tile_id > 2:
			if tiles[tile_id - 3].unit == null:
				return false
		return true


	func set_unit(tile_id: int, unit: Unit) -> void:
		tiles[tile_id].unit = unit
