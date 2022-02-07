extends Control

const Token = preload("res://scripts/Token.gd")
const pawn_img = preload("res://images/chess_pawn.png")
const die_imgs = [preload("res://images/dice_0.png"), preload("res://images/dice_1.png")]
const player_colors = [Color(0.10, 0.25, 0.45), Color(0.45, 0.16, 0.15)]
const player_token_count = 7

var cur_roll = 0
var cur_player = 1
var player_tokens = [[], []]
var player_tiles = [[], []]
var player_one_start_tile = null
var player_two_start_tile = null
var player_one_end_tile = null
var player_two_end_tile = null
var player_one_score = 0
var player_two_score = 0
var selected_token = null
var reroll_tiles = null
var die_nodes = []


# connects all buttons to player tile list
func load_tiles():
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
			die_nodes.append(node)


# called when the board is loaded
func _ready():
	
	# init variables
	load_tiles()
	assign_dice()
	
	player_one_start_tile = player_tiles[0][0]
	player_two_start_tile = player_tiles[1][0]
	
	player_one_end_tile = player_tiles[0][-1]
	player_two_end_tile = player_tiles[1][-1]
	
	reroll_tiles = get_tree().get_nodes_in_group("reroll_tiles")
	
	# connect button press to click function
	for btn in get_tree().get_nodes_in_group("tiles"):
		btn.connect("pressed", self, "tile_clicked", [btn])
	
	# create player tokens
	for _i in range(player_token_count):
		player_tokens[0].append(Token.new(player_one_start_tile))
		player_tokens[1].append(Token.new(player_two_start_tile))
	
	# init player token counters
	$rows/tiles/cols5/p1counter.modulate = player_colors[0]
	$rows/tiles/cols5/p2counter.modulate = player_colors[1]
	$rows/tiles/cols6/p1counter.modulate = player_colors[0]
	$rows/tiles/cols6/p2counter.modulate = player_colors[1]
	update_counters()
	
	# display the first player
	print("Player ", str(cur_player), "'s turn")
	randomize()
	roll_dice()


# called by button when pressed
func tile_clicked(tile):
	if cur_roll == 0:
		print("You rolled a 0!")
		return
	
	# did the player play on their own path?
	if tile in player_tiles[cur_player - 1]:
		
		# token is currently selected; player is trying to place tile
		if selected_token:
			place_selected_token(tile)
		
		# no token is selected; player is trying to select a token to play
		else:
			
			if tile == player_one_end_tile or tile == player_two_end_tile:
				print("Cannot move tokens off of end tile")
				return
			
			# get token on selected tile (if possible)
			selected_token = get_player_token_on_tile(tile)
			if selected_token:
				if not selected_token in player_tokens[cur_player - 1]:
					print("Not your token!")
					selected_token = null
					return
				print("Token selected")
				tile.modulate = Color.yellow
			else:
				print("No token on tile")
	
	# illegal: tile not in current player's path
	else:
		print("Not your tile!")


# return the sum of four "2-sided" dice
func roll_dice():
	var sum = 0
	for i in range(4):
		var roll = randi() % 2
		sum += roll
		die_nodes[i].texture = die_imgs[roll]
		die_nodes[i].modulate = player_colors[cur_player - 1]
	print("Player ", str(cur_player), " rolled ", sum)
	cur_roll = sum
	
	# wait a bit before switching players so user sees the roll was 0
	if cur_roll == 0:
		$ZeroRollTimer.start()


# switch player and roll dice
func switch_player():
	if cur_player == 1:
		cur_player = 2
	else:
		cur_player = 1
	#print("Player ", str(cur_player), "'s turn")
	print()
	roll_dice()


# return distance between two tiles
func get_tile_distance(from, to):
	var tile_list = player_tiles[cur_player - 1]
	
	var i1 = tile_list.find(from)
	var i2 = tile_list.find(to)
	
	return i2 - i1


# returns the player token on the specified tile (if one exists)
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
	# TODO end game stuff
	for btn in get_tree().get_nodes_in_group("tiles"):
		btn.disabled = true
	#Console.write_line("Hello world")
	print("Congrats player ", player, ", you win!")


# set button text,
func end_turn(tile_played):
	
	# move the selected token and reset tiles
	reset_tile(selected_token.get_tile())
	selected_token.set_tile(tile_played)
	
	# did token make it to the end?
	if tile_played == player_one_end_tile or tile_played == player_two_end_tile:
		#selected_token.set_tile(null)
		if cur_player == 1:
			player_one_score += 1
		else:
			player_two_score += 1
		
		# end of game
		if player_one_score == player_token_count \
		or player_two_score == player_token_count:
			win(cur_player)
			return
		
	else:
		add_pawn_child(tile_played)
	
	# deselect token
	selected_token = null
	
	# roll again if tile was reroll
	if tile_played in reroll_tiles:
		roll_dice()
	else:
		switch_player()


# if possible, places current player's token on the board
# this is where most of the game rules reside
func place_selected_token(tile):
	var has_moved = false
	
	# what token is at the tile where the player is trying to place
	# the currently selected token?
	var other_token = get_player_token_on_tile(tile)
	
	var opponent_tokens = player_tokens[1 - (cur_player - 1)]
	var opponent_start = player_one_start_tile
	if cur_player == 1:
		opponent_start = player_two_start_tile
	
	# make sure move matches roll
	var tile_distance = get_tile_distance(selected_token.get_tile(), tile)
	if tile_distance == cur_roll:
		
		# play token on empty tile
		if not other_token:
			print("Moving player piece")
			has_moved = true
		
		# knock opponent off
		elif other_token in opponent_tokens:
			
			# can only knock opponent off if not on reroll tile
			if not tile in reroll_tiles:
				print("Opponent piece captured!")
				other_token.set_tile(opponent_start)
				has_moved = true
			else:
				print("Cannot bump player off reroll tile")
		
		# illegal: one token allowed per tile
		else:
			print("One token allowed per tile")
	
	# move did not match roll
	else:
		
		# deselect token by clicking it again
		if tile_distance == 0:
				selected_token = null
				print("Token deselected")
				tile.modulate = Color.white
		
		# illegal: wrong number of tiles
		else:
			print("Move did not match roll")
	
	if has_moved:
		end_turn(tile)
		update_counters()


# returns true if this tile has a default icon
func is_special_tile(tile):
	return tile in reroll_tiles \
		or tile == player_one_start_tile or tile == player_two_start_tile \
		or tile == player_one_end_tile or tile == player_two_end_tile


# adds pawn icon as child to node
func add_pawn_child(node):
	
	# create icon node
	var texture = TextureRect.new()
	texture.name = "pawn"
	texture.texture = pawn_img
	node.add_child(texture)
	texture.modulate = player_colors[cur_player - 1]
	
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
	var start_count1 = 0
	var start_count2 = 0
	var end_count1 = 0
	var end_count2 = 0
	for token_list in player_tokens:
		for t in token_list:
			if t.get_tile() == player_one_start_tile:
				start_count1 += 1
			elif t.get_tile() == player_two_start_tile:
				start_count2 += 1
			elif t.get_tile() == player_one_end_tile:
				end_count1 += 1
			elif t.get_tile() == player_two_end_tile:
				end_count2 += 1
	$rows/tiles/cols5/p1counter/text.text = str(start_count1)
	$rows/tiles/cols5/p2counter/text.text = str(start_count2)
	$rows/tiles/cols6/p1counter/text.text = str(end_count1)
	$rows/tiles/cols6/p2counter/text.text = str(end_count2)
