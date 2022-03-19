extends Control

const Token = preload("res://nodes/Token.tscn")
const Tile = preload("res://nodes/Tile.tscn")
const TileScript = preload("res://scripts/Tile.gd")
const PAWN_IMG = preload('res://images/chess_pawn.png')
const DICE_IMGS = [preload('res://images/dice_0.png'), preload('res://images/dice_1.png')]
const PLAYER_COLORS = [Color(0.10, 0.25, 0.45), Color(0.45, 0.16, 0.15)]
const PLAYER_NAMES = ['Player One', 'Player Two']
const P_ONE = 0
const P_TWO = 1
const TOKEN_COUNT = 7

export(NodePath) var tiles_container
export(NodePath) var message_label
export(NodePath) var menu_button

signal player_switched
signal dice_set
signal token_moved
signal game_over

# The current roll: numbers 0-4.
var cur_roll

# The current player: 0 or 1
var cur_player

# Holds tile objects
var tiles = []
var player_tiles = [[], []]

# Holds tokens objects
var player_tokens = [[], []]

# The index of the currently selected token in main tiles list
var selected_tile_i = -1


################ INITIALIZATION FUNCTIONS ################

func _ready():
	cur_player = P_ONE
	_init_tiles()
	_init_tokens()
	_init_counters()
	set_message("%s's turn" % PLAYER_NAMES[cur_player], PLAYER_COLORS[cur_player])
	rpc("roll_dice") # starts the game

# Creates each player's list of tiles.
func _init_tiles():
	# start (exclusive) tiles
	for i in range(2):
		player_tiles[i].append(Tile.instance().init([i], TileScript.TYPE_START))
		for _j in range(3):
			player_tiles[i].append(Tile.instance().init([i]))
		player_tiles[i].append(Tile.instance().init([i], TileScript.TYPE_REROLL))
	
	# middle (shared) tiles
	for _i in range(3):
		var t = Tile.instance().init(range(2))
		for j in range(2):
			player_tiles[j].append(t)
	var middle_reroll = Tile.instance().init(range(2), TileScript.TYPE_REROLL)
	for i in range(2):
		player_tiles[i].append(middle_reroll)
	for _i in range(4):
		var t = Tile.instance().init(range(2))
		for j in range(2):
			player_tiles[j].append(t)
	
	# last (exclusive) tiles
	for i in range(2):
		player_tiles[i].append(Tile.instance().init([i]))
		player_tiles[i].append(Tile.instance().init([i], TileScript.TYPE_REROLL))
		player_tiles[i].append(Tile.instance().init([i], TileScript.TYPE_END))
	
	# in order to set up the board correctly, tiles must be added from top left
	# to bottom right...this is really ugly I know ＞︿＜
	var order = [
		[0,  4], [0,  5], [1,  4],
		[0,  3], [0,  6], [1,  3],
		[0,  2], [0,  7], [1,  2],
		[0,  1], [0,  8], [1,  1],
		[0,  0], [0,  9], [1,  0],
		[0, 15], [0, 10], [1, 15],
		[0, 14], [0, 11], [1, 14],
		[0, 13], [0, 12], [1, 13]
	]
	for i in order:
		var tile = player_tiles[i[0]][i[1]] # ＞︿＜
		if not tile in tiles:
			tiles.append(tile)
			tile.connect("pressed", self, "tile_pressed", [tile])
			get_node(tiles_container).add_child(tile)

# Creates each player's list of tokens and
# adds them to their respective start tiles.
func _init_tokens():
	for i in range(2):
		for j in range(TOKEN_COUNT):
			var t = Token.instance().init(i, PLAYER_COLORS[i])
			t.name = 'token%d%d' % [i, j]
			player_tokens[i].append(t)
			player_tiles[i].front().add_token(t)

# Sets the color of player token counters.
func _init_counters():
	for n in get_tree().get_nodes_in_group('player_one_counter'):
		n.modulate = PLAYER_COLORS[P_ONE]
	for n in get_tree().get_nodes_in_group('player_two_counter'):
		n.modulate = PLAYER_COLORS[P_TWO]


################ GAME LOGIC ################

# Calls move_token() only if move is valid.
#
# @param	from_tile_i: the index of the tile's current location
#			in the current player's list of tiles
# @param	to_tile_i: the index of the tile's desired location
#			in the current player's list of tiles
# @return	true if the move is valid, otherwise false
func attempt_move(from_tile_i, to_tile_i):
	if is_move_valid(from_tile_i, to_tile_i):
		deselect_tile(selected_tile_i)
		rpc("move_token", from_tile_i, to_tile_i)

# Returns true if the desired move is valid. A move is valid if there is a token
# at the "from" tile, that token is owned by the current player, and the "to"
# tile is empty or is a start/end tile.
#
# @param	from_tile_i: the index of the tile's current location
#			in the current player's list of tiles
# @param	to_tile_i: the index of the tile's desired location
#			in the current player's list of tiles
# @return	true if the move is valid, otherwise false
func is_move_valid(from_tile_i, to_tile_i):
	var from = tiles[from_tile_i]
	var to = tiles[to_tile_i]
	return (not from.empty()) \
		and from.top().player == cur_player \
		and (to.empty() or to_tile_i == player_tiles[cur_player].size() - 1) \
		and (player_tiles[cur_player].find(to) - player_tiles[cur_player].find(from) == cur_roll)

# Sums the rolls of 4 two-sided die and passes the value to set_roll.
master func roll_dice():
	var sum = 0
	for _i in range(4):
		sum += randi() % 2
	rpc("set_roll", sum)

# Sets the cur_roll variable and emits the dice_set signal.
remotesync func set_roll(roll):
	cur_roll = roll
	var dice = get_tree().get_nodes_in_group('dice')
	for i in range(dice.size()):
		if i < roll:
			dice[i].texture = DICE_IMGS[1]
		else:
			dice[i].texture = DICE_IMGS[0]
	# TODO do something if roll was 0
	emit_signal("dice_set")

# Switches the cur_player variable and emits the player_switched signal.
remotesync func switch_player():
	cur_player = 1 - cur_player
	set_message("%s's turn" % PLAYER_NAMES[cur_player], \
		PLAYER_COLORS[cur_player])
	emit_signal("player_switched")
	rpc("roll_dice") # only gets called on server

# Moves a token from one tile to another and emits the token_moved signal.
# Does not check move validity.
#
# @param	from_tile_i: the index of the tile's current location
#			in the current player's list of tiles
# @param	to_tile_i: the index of the tile's desired location
#			in the current player's list of tiles
remotesync func move_token(from_tile_i, to_tile_i):
	# move token
	tiles[to_tile_i].add_token(tiles[from_tile_i].pop_token())
	emit_signal("token_moved")
	
	# check for game over, switch player if applicable
	if player_tiles[cur_player][-1].size() == TOKEN_COUNT:
		emit_signal("game_over")
	elif tiles[to_tile_i].type == TileScript.TYPE_REROLL:
		rpc("roll_dice")
	else:
		rpc("switch_player")


################ UI CODE ################

# Updates the UI text field with the specified message
# and updates it's modulate color if provided, otherwise
# modulate color is set to current player's color.
#
# @param	message: a string to display in the label
# @param	color: the color to set the label
func set_message(message, color=null):
	get_node(message_label).text = message
	if not color:
		color = PLAYER_COLORS[cur_player]
	get_node(message_label).modulate = color

# Called by tile buttons when pressed.
#
# @param	caller: the tile that was pressed
func tile_pressed(caller):
	# ensure tile is owned by current player
	if cur_player in caller.players:
		var ti = tiles.find(caller)
		
		# if no tile currently selected, select the tile (if it has a token)
		if (selected_tile_i == -1) and (not caller.empty()):
			select_tile(ti)
		
		# if pressing the selected tile again, deselect it
		elif selected_tile_i == ti:
			deselect_tile(ti)
		
		# attempt a move
		elif selected_tile_i > -1:
			attempt_move(selected_tile_i, ti)

func select_tile(tile_i):
	tiles[tile_i].select()
	selected_tile_i = tile_i

func deselect_tile(tile_i):
	tiles[tile_i].deselect()
	selected_tile_i = -1
