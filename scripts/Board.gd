extends Control

const PAWN_IMG = preload('res://images/chess_pawn.png')
const DICE_IMGS = [preload('res://images/dice_0.png'), preload('res://images/dice_1.png')]
const PLAYER_COLORS = [Color(0.10, 0.25, 0.45), Color(0.45, 0.16, 0.15)]
const PLAYER_NAMES = ['Player One', 'Player Two']
const PLAYER_TOKEN_COUNT = 2

var cur_roll = null
var cur_player = 0
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
		if node.name.begins_with('die'):
			dice_nodes.append(node)


# sets the text and color of player token counters
func init_counters():
	$rows/tiles/cols5/p1counter.modulate = PLAYER_COLORS[0]
	$rows/tiles/cols5/p2counter.modulate = PLAYER_COLORS[1]
	$rows/tiles/cols6/p1counter.modulate = PLAYER_COLORS[0]
	$rows/tiles/cols6/p2counter.modulate = PLAYER_COLORS[1]
	update_counters()


# called when the board is loaded
func _ready():
	
	# init variables
	load_player_tiles()
	assign_dice()
	reroll_tiles = get_tree().get_nodes_in_group('reroll_tiles')
	
	# connect button press to click function
	for btn in get_tree().get_nodes_in_group('tiles'):
		btn.connect('pressed', self, 'tile_clicked', [btn])
	
	# create player tokens
	for i in range(2):
		for j in range(PLAYER_TOKEN_COUNT):
			var token = TextureRect.new()
			token.name = 'token%d' % j
			token.texture = PAWN_IMG
			token.modulate = PLAYER_COLORS[i]
			token.visible = false
			
			# add token to tokens list and scene
			player_tokens[i].append(token)
			player_tiles[i][0].add_child(token)
			
			# position icon in center of parent
			token.anchor_bottom = 0.5
			token.anchor_top = 0.5
			token.anchor_left = 0.5
			token.anchor_right = 0.5
			token.rect_position.x -= token.rect_size.x / 2
			token.rect_position.y -= token.rect_size.y / 2
	
	# initialize UI
	init_counters()
	set_message("%s's turn" % PLAYER_NAMES[cur_player])
	
	# roll dice (first move)
	randomize()
	rpc('roll_dice')


# called by button when pressed
# ┌────────────────┐
# │                │
# │ tile_clicked() │
# │       │        │
# │       │        │
# │       ▼        │
# │ is_valid_move()│
# │       │        │
# │       │        │
# │       ▼        │
# │ confirm_move() │
# │                │
# └────────────────┘
func tile_clicked(tile):
	# when playing online, only allow player to move if it's their turn
	if get_tree().network_peer and \
	not ((get_tree().is_network_server() and cur_player == 0) \
	or (not get_tree().is_network_server() and cur_player == 1)):
			return
	
	# only do something with a tile in the current player's path
	# when that player's roll is greater than 0
	if cur_roll > 0 and tile in player_tiles[cur_player]:
		
		# token is currently selected; player is trying to place tile
		if selected_token:
			
			# allow deselection of tokens
			if selected_token.get_parent() == tile:
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
			and selected_token in player_tokens[cur_player]:
				tile.modulate = Color.yellow


# if possible, places current player's token on the board
# this is where most of the game rules reside
func is_valid_move(player, token, to_tile):
	var result = false
	var tile_distance = get_tile_distance(token.get_parent(), to_tile, player_tiles[player])
	if tile_distance == cur_roll:
		
		# what token is at the tile where the player is trying to place
		# the currently selected token?
		var other_token = get_player_token_on_tile(to_tile)
		
		# token can be placed on empty tile
		if not other_token:
			result = true
		
		# knock opponent off if not on a re-roll tile
		elif not to_tile in reroll_tiles:
			result = other_token in player_tokens[opponent(player)] \
			or to_tile == get_end_tiles()[player]
	
	return result


# called when a move has been successfully made by current player
func confirm_move(tile_played):
	# move opponent's tokens if necessary
	for child in tile_played.get_children():
		if child in player_tokens[opponent(cur_player)]:
			tile_played.remove_child(child)
			get_start_tiles()[opponent(cur_player)].add_child(child)
			child.visible = false
	
	# reset tiles and move the selected token
	reset_tile(selected_token.get_parent())
	reset_tile(tile_played)
	selected_token.get_parent().remove_child(selected_token)
	tile_played.add_child(selected_token)
	selected_token.visible = not (tile_played in get_start_tiles() or tile_played in get_end_tiles())
	
	# deselect token, update UI
	selected_token = null
	update_counters()
	
	# game over?
	if tile_played in get_end_tiles():
		if get_end_token_count(cur_player) == PLAYER_TOKEN_COUNT:
			win(cur_player)
			return
	
	# roll again if tile was reroll
	if tile_played in reroll_tiles:
		rpc('roll_dice')
	else:
		switch_player()


# set roll variable to sum of four '2-sided' dice
master func roll_dice():
	var nums = []
	for i in range(4):
		var roll = randi() % 2
		nums.append(roll)
	
	rpc('set_roll', nums)


# sets the roll on all peers
remotesync func set_roll(nums):
	var roll = 0
	for i in range(len(nums)):
		roll += nums[i]
		dice_nodes[i].texture = DICE_IMGS[nums[i]]
		dice_nodes[i].modulate = PLAYER_COLORS[cur_player]
	cur_roll = roll
	
	# wait a bit before switching players so user sees the roll was 0
	if cur_roll == 0:
		cur_roll = -1
		set_message('Tough luck %s!' % PLAYER_NAMES[cur_player])
		$ZeroRollTimer.start()
	
	# player's turn is skipped if they have no valid moves
	elif not can_play(cur_player, cur_roll):
		cur_roll = -1
		set_message('No available moves')
		$NoMovesTimer.start()


# switch player and roll dice
remotesync func switch_player():
	cur_player = opponent(cur_player)
	set_message("%s's turn" % PLAYER_NAMES[cur_player])
	rpc('roll_dice')


# return distance between two tiles
func get_tile_distance(from, to, tile_list):
	return tile_list.find(to) - tile_list.find(from)


# returns the first player token on the specified tile (if one exists)
func get_player_token_on_tile(tile):
	var result = null
	for child in tile.get_children():
		if child.name.begins_with('token'):
			result = child
	return result


# resets the text of the specified button to how it was
# at the beginning of the game
func reset_tile(tile):
	
	# show regular icon
	if is_special_tile(tile):
		tile.get_node('TextureRect').visible = true
	
	# remove highlihgt
	tile.modulate = Color.white


# game over!
func win(player):
	for btn in get_tree().get_nodes_in_group('tiles'):
		btn.disabled = true
	set_message('%s wins!' % PLAYER_NAMES[player])


# returns true if this tile has a default icon
func is_special_tile(tile):
	return tile in reroll_tiles \
		or tile in get_start_tiles() \
		or tile in get_end_tiles()


# updates the players' pawn counters
func update_counters():
	$rows/tiles/cols5/p1counter/text.text = str(get_start_token_count(0))
	$rows/tiles/cols5/p2counter/text.text = str(get_start_token_count(1))
	$rows/tiles/cols6/p1counter/text.text = str(get_end_token_count(0))
	$rows/tiles/cols6/p2counter/text.text = str(get_end_token_count(1))


# returns the specified player's number of tokens not yet played
func get_start_token_count(player):
	return get_start_tiles()[player].get_child_count() - 1


# returns the specified player's number of tokens in the end tile
func get_end_token_count(player):
	return get_end_tiles()[player].get_child_count() - 1


# returns start tiles of both players
func get_start_tiles():
	return [player_tiles[0][0], player_tiles[1][0]]


# returns end tiles of both players
func get_end_tiles():
	return [player_tiles[0][-1], player_tiles[1][-1]]


# updates the UI text field with the specified message
# and updates it's modulate color if provided, otherwise
# modulate color is set to current player's color
func set_message(message, color=null):
	$rows/message.text = message
	if not color:
		color = PLAYER_COLORS[cur_player]
	$rows/message.modulate = color


# returns true if any token has a valid move with the current roll,
# otherwise returns false
func can_play(player, roll):
	var p = player
	for token in player_tokens[p]:
		var p_tiles = player_tiles[p]
		var to_index = p_tiles.find(token.get_parent()) + roll
		if to_index < len(p_tiles):
			var to_tile = p_tiles[to_index]
			if is_valid_move(player, token, to_tile):
				return true
	return false


# returns the opponent of the specified player
func opponent(player):
	return 1 - player
