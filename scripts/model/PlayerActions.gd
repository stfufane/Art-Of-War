class_name PlayerActions
## List of static functions used by the Action runner
##
## The check methods take the player as an argument and return a boolean
## The do methods take the player and the data (optional) as arguments

#region Action checks run before the action is executed

static func check_reshuffle(player: Player, _data: Variant) -> bool:
	return player.state.current == StateManager.EState.RESHUFFLE and player.reshuffle_attempts > 0


static func check_validate_hand(player: Player, _data: Variant) -> bool:
	return player.state.current == StateManager.EState.RESHUFFLE and not player.state.hand_ready


static func check_init_battlefield(player: Player, data: Variant) -> bool:
	return player.state.current == StateManager.EState.INIT_BATTLEFIELD \
		and not player.state.battlefield_ready\
		and player.party.battlefield.can_set_unit(player.id, data)


static func check_init_reserve(player: Player, _data: Variant) -> bool:
	return player.state.current == StateManager.EState.INIT_RESERVE and not player.state.reserve_ready

#endregion

#region Actions that are called if the check was ok.

static func do_reshuffle(player: Player, _data: Variant) -> void:
	player.reshuffle_deck()


static func do_validate_hand(player: Player, _data: Variant) -> void:
	player.validate_hand()


static func do_init_battlefield(player: Player, data: Variant) -> void:
	player.init_battlefield(data)


static func do_init_reserve(player: Player, data: Variant) -> void:
	player.init_reserve(data)

#endregion
