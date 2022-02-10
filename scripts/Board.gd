extends Control

const Token = preload("res://scripts/Token.gd")
const PAWN_IMG = preload("res://images/chess_pawn.png")
const DICE_IMGS = [preload("res://images/dice_0.png"), preload("res://images/dice_1.png")]
const PLAYER_COLORS = [Color(0.10, 0.25, 0.45), Color(0.45, 0.16, 0.15)]
const PLAYER_TOKEN_COUNT = 1

var cur_roll = 0
var cur_player = 1
var player_tokens = [[], []]
var player_tiles = [[], []]
var selected_token = null
var reroll_tiles = null
var dice_nodes = []


# connects all buttons to player tile list
func load_player_tiles():
	player_tiles[0].append($rows/tiles/cols5/btn1)
	player_tiles[0].append($rows/tiles/cols4/btn1)
	player_tiles[0].append($rows/tiles/cols3/btn1)
	player_tiles[0].append($rows/tiles/cols2/btn1)
	player_tiles[0].append($rows/tiles/cols1/btn1)
	player_tiles[0].append($rows/tiles/cols1/btn2)
	player_tiles[0].append($rows/tiles/cols2/btn2)
	player_tiles[0].append($rows/tiles/cols3/btn2)
	player_tiles[0].append($rows/tiles/cols4/btn2)
	player_tiles[0].append($rows/tiles/cols5/btn2)
	player_tiles[0].append($rows/tiles/cols6/btn2)
	player_tiles[0].append($rows/tiles/cols7/btn2)
	player_tiles[0].append($rows/tiles/cols8/btn2)
	player_tiles[0].append($rows/tiles/cols8/btn1)
	player_tiles[0].append($rows/tiles/cols7/btn1)
	player_tiles[0].append($rows/tiles/cols6/btn1)
	
	player_tiles[1].append($rows/tiles/cols5/btn3)
	player_tiles[1].append($rows/tiles/cols4/btn3)
	player_tiles[1].append($rows/tiles/cols3/btn3)
	player_tiles[1].append($rows/tiles/cols2/btn3)
	player_tiles[1].append($rows/tiles/cols1/btn3)
	player_tiles[1].append($rows/tiles/cols1/btn2)
	player_tiles[1].append($rows/tiles/cols2/btn2)
	player_tiles[1].append($rows/tiles/cols3/btn2)
	player_tiles[1].append($rows/tiles/cols4/btn2)
	player_tiles[1].append($rows/tiles/cols5/btn2)
	player_tiles[1].append($rows/tiles/cols6/btn2)
	player_tiles[1].append($rows/tiles/cols7/btn2)
	player_tiles[1].append($rows/tiles/cols8/btn2)
	player_tiles[1].append($rows/tiles/cols8/btn3)
	player_tiles[1].append($rows/tiles/cols7/btn3)
	player_tiles[1].append($rows/tiles/cols6/btn3)


# assign scene nodes to array
func assign_dice():
	for node in $rows/info.get_children():
		if node.name.begins_with("die"):
			dice_nodes.append(node)


# called when the board is loaded
func _ready():
	
	# init variables
	load_player_tiles()
	assign_dice()
	reroll_tiles = get_tree().get_nodes_in_group("reroll_tiles")
	
	# connect button press to click function
	for btn in get_tree().get_nodes_in_group("tiles"):
		btn.connect("pressed", self, "tile_clicked", [btn])
	
	# create player tokens
	for _i in range(PLAYER_TOKEN_COUNT):
		for i in range(2):
			player_tokens[i].append(Token.new(player_tiles[i][0]))
	
	# init player token counters
	$rows/tiles/cols5/p1counter.modulate = PLAYER_COLORS[0]
	$rows/tiles/cols5/p2counter.modulate = PLAYER_COLORS[1]
	$rows/tiles/cols6/p1counter.modulate = PLAYER_COLORS[0]
	$rows/tiles/cols6/p2counter.modulate = PLAYER_COLORS[1]
	update_counters()
	
	# make the first move
	randomize()
	roll_dice()
	update_player_message()


# called by button when pressed
func tile_clicked(tile):
	# only do something with a tile in the current player's path
	# when that player's roll is greater than 0
	if cur_roll > 0 and tile in player_tiles[cur_player - 1]:
		
		# token is currently selected; player is trying to place tile
		if selected_token:
			
			# allow deselection of tokens
			if selected_token.get_tile() == tile:
				tile.modulate = Color.white
				selected_token = null
			
			# move if valid
			elif is_valid_move(cur_player, selected_token, tile):
				confirm_move(tile)
		
		# no token is selected; player is trying to select a token to play
		else:
			selected_token = get_player_token_on_tile(tile)
			if selected_token \
			and not tile in get_end_tiles() \
			and selected_token in player_tokens[cur_player - 1]:
				tile.modulate = Color.yellow


# if possible, places current player's token on the board
# this is where most of the game rules reside
func is_valid_move(player, token, to_tile):
	var result = false
	var tile_distance = get_tile_distance(token.get_tile(), to_tile, player_tiles[player - 1])
	if tile_distance == cur_roll:
		
		# what token is at the tile where the player is trying to place
		# the currently selected token?
		var other_token = get_player_token_on_tile(to_tile)
		
		# token can be placed on empty tile
		if not other_token:
			result = true
		
		# knock opponent off if not on a re-roll tile
		elif other_token in player_tokens[opponent(player) - 1] \
		and not to_tile in reroll_tiles:
			result = true
	
	return result


# called when a move has been successfully made by current player
func confirm_move(tile_played):
	var opp_token = get_player_token_on_tile(tile_played)
	if (opp_token):
		opp_token.set_tile(get_start_tiles()[opponent(cur_player) - 1])
	
	# move the selected token and reset tiles
	reset_tile(selected_token.get_tile())
	selected_token.set_tile(tile_played)
	
	# game over?
	if tile_played in get_end_tiles():
		if get_end_token_count(cur_player) == PLAYER_TOKEN_COUNT:
			win(cur_player)
			return
	else:
		add_pawn_child(tile_played)
	
	# deselect token, update UI
	selected_token = null
	update_counters()
	
	# roll again if tile was reroll
	if tile_played in reroll_tiles:
		roll_dice()
	else:
		switch_player()


# return the sum of four "2-sided" dice
func roll_dice():
	var sum = 0
	for i in range(4):
		var roll = randi() % 2
		sum += roll
		dice_nodes[i].texture = DICE_IMGS[roll]
		dice_nodes[i].modulate = PLAYER_COLORS[cur_player - 1]
	cur_roll = sum
	
	# wait a bit before switching players so user sees the roll was 0
	if cur_roll == 0:
		cur_roll = -1
		$ZeroRollTimer.start()
	
	# player's turn is skipped if they have no valid moves
	elif not can_play(cur_player, cur_roll):
		cur_roll = -1
		set_message("No available moves")
		$NoMovesTimer.start()


# switch player and roll dice
func switch_player():
	if cur_player == 1:
		cur_player = 2
	else:
		cur_player = 1
	update_player_message()
	roll_dice()


# return distance between two tiles
func get_tile_distance(from, to, tile_list):
	return tile_list.find(to) - tile_list.find(from)


# returns the first player token on the specified tile (if one exists)
func get_player_token_on_tile(tile):
	var token = null
	for token_list in player_tokens:
		for t in token_list:
			if t.get_tile() == tile:
				token = t
	return token


# resets the text of the specified button to how it was
# at the beginning of the game
func reset_tile(tile):
	
	# show regular icon
	if is_special_tile(tile):
		tile.get_child(0).visible = true
	
	# remove pawn icons
	for child in tile.get_children():
		if child.name == "pawn":
			tile.remove_child(child)
	
	# remove highlihgt
	tile.modulate = Color.white


# game over!
func win(player):
	for btn in get_tree().get_nodes_in_group("tiles"):
		btn.disabled = true
	set_message("Player %s wins!" % str(cur_player))


# returns true if this tile has a default icon
func is_special_tile(tile):
	return tile in reroll_tiles \
		or tile in get_start_tiles() \
		or tile in get_end_tiles()


# adds pawn icon as child to node
func add_pawn_child(node):
	
	# create icon node
	var texture = TextureRect.new()
	texture.name = "pawn"
	texture.texture = PAWN_IMG
	node.add_child(texture)
	texture.modulate = PLAYER_COLORS[cur_player - 1]
	
	# position icon in center of parent
	texture.anchor_bottom = 0.5
	texture.anchor_top = 0.5
	texture.anchor_left = 0.5
	texture.anchor_right = 0.5
	texture.rect_position.x -= texture.rect_size.x / 2
	texture.rect_position.y -= texture.rect_size.y / 2
	
	# hide icon if possible
	if is_special_tile(node):
		node.get_child(0).visible = false


# updates the players' pawn counters
func update_counters():
	$rows/tiles/cols5/p1counter/text.text = str(get_start_token_count(1))
	$rows/tiles/cols5/p2counter/text.text = str(get_start_token_count(2))
	$rows/tiles/cols6/p1counter/text.text = str(get_end_token_count(1))
	$rows/tiles/cols6/p2counter/text.text = str(get_end_token_count(2))


# returns the specified player's number of tokens not yet played
func get_start_token_count(player):
	var score = 0
	for t in player_tokens[player - 1]:
		if t.get_tile() == get_start_tiles()[player - 1]:
			score += 1
	return score


# returns the specified player's number of tokens in the end tile
func get_end_token_count(player):
	var score = 0
	for t in player_tokens[player - 1]:
		if t.get_tile() == get_end_tiles()[player - 1]:
			score += 1
	return score


# returns start tiles of both players
func get_start_tiles():
	return [player_tiles[0][0], player_tiles[1][0]]


# returns end tiles of both players
func get_end_tiles():
	return [player_tiles[0][-1], player_tiles[1][-1]]


# updates the message shown to player about game info
func update_player_message():
	set_message("%sst player's turn" % str(cur_player))


# updates the UI text field with the specified message
# and updates it's modulate color if provided, otherwise
# modulate color is set to current player's color
func set_message(message, color=null):
	$rows/message.text = message
	if not color:
		color = PLAYER_COLORS[cur_player - 1]
	$rows/message.modulate = color


# returns true if any token has a valid move with the current roll,
# otherwise returns false
func can_play(player, roll):
	var p = player - 1
	for token in player_tokens[p]:
		var p_tiles = player_tiles[p]
		var to_index = p_tiles.find(token.get_tile()) + roll
		if to_index < len(p_tiles):
			var to_tile = p_tiles[to_index]
			if is_valid_move(player, token, to_tile):
				return true
	return false


# returns the opponent of the specified player
func opponent(player):
	return 1 - (player - 1)
