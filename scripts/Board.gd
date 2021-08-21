extends Control

const Token = preload("res://scripts/Token.gd")

var cur_roll = 0
var cur_player = 1
var player_one_tokens = []
var player_two_tokens = []
var player_one_tiles = []
var player_two_tiles = []
var player_one_start_tile = null
var player_two_start_tile = null
var player_one_end_tile = null
var player_two_end_tile = null
var player_one_score = 0
var player_two_score = 0
var selected_token = null
var reroll_tiles = null


# connects all buttons to player tile list
func load_tiles():
	player_one_tiles.append($rows/cols5/btn1)
	player_one_tiles.append($rows/cols4/btn1)
	player_one_tiles.append($rows/cols3/btn1)
	player_one_tiles.append($rows/cols2/btn1)
	player_one_tiles.append($rows/cols1/btn1)
	player_one_tiles.append($rows/cols1/btn2)
	player_one_tiles.append($rows/cols2/btn2)
	player_one_tiles.append($rows/cols3/btn2)
	player_one_tiles.append($rows/cols4/btn2)
	player_one_tiles.append($rows/cols5/btn2)
	player_one_tiles.append($rows/cols6/btn2)
	player_one_tiles.append($rows/cols7/btn2)
	player_one_tiles.append($rows/cols8/btn2)
	player_one_tiles.append($rows/cols8/btn1)
	player_one_tiles.append($rows/cols7/btn1)
	player_one_tiles.append($rows/cols6/btn1)
	
	player_two_tiles.append($rows/cols5/btn3)
	player_two_tiles.append($rows/cols4/btn3)
	player_two_tiles.append($rows/cols3/btn3)
	player_two_tiles.append($rows/cols2/btn3)
	player_two_tiles.append($rows/cols1/btn3)
	player_two_tiles.append($rows/cols1/btn2)
	player_two_tiles.append($rows/cols2/btn2)
	player_two_tiles.append($rows/cols3/btn2)
	player_two_tiles.append($rows/cols4/btn2)
	player_two_tiles.append($rows/cols5/btn2)
	player_two_tiles.append($rows/cols6/btn2)
	player_two_tiles.append($rows/cols7/btn2)
	player_two_tiles.append($rows/cols8/btn2)
	player_two_tiles.append($rows/cols8/btn3)
	player_two_tiles.append($rows/cols7/btn3)
	player_two_tiles.append($rows/cols6/btn3)


# called when the board is loaded
func _ready():
	
	# init variables
	load_tiles()
	
	player_one_start_tile = player_one_tiles[0]
	player_two_start_tile = player_two_tiles[0]
	
	player_one_end_tile = player_one_tiles[-1]
	player_two_end_tile = player_two_tiles[-1]
	
	reroll_tiles = get_tree().get_nodes_in_group("reroll_tiles")
	
	# connect button press to click function
	for btn in get_tree().get_nodes_in_group("tiles"):
		btn.connect("pressed", self, "tile_clicked", [btn])
	
	# create player tokens
	for _i in range(7):
		player_one_tokens.append(Token.new(player_one_start_tile))
		player_two_tokens.append(Token.new(player_two_start_tile))
	
	# display the first player
	print("Player ", str(cur_player), "'s turn")
	randomize()
	roll_dice()


# called by button when pressed
func tile_clicked(tile):
	
	# did the player play on their own path?
	if (cur_player == 1 \
		and tile in player_one_tiles) \
		or (cur_player == 2 \
		and tile in player_two_tiles):
		
		# token is currently selected; player is trying to place tile
		if selected_token:
			place_selected_token(tile)
		
		# no token is selected; player is trying to select a token to play
		else:
			
			# get token on selected tile (if possible)
			selected_token = get_player_token_on_tile(tile)
			if selected_token:
				print("Token selected")
			else:
				print("No token on tile")
	
	# illegal: tile not in current player's path
	else:
		print("Not your tile!")


# return the sum of four "2-sided" dice
func roll_dice():
	var sum = 0
	for _i in range(4):
		sum += randi() % 2
	print("Player ", str(cur_player), " rolled ", sum)
	cur_roll = sum
	
	if cur_roll == 0:
		switch_player()


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
	var tile_list = player_one_tiles
	if cur_player == 2:
		tile_list = player_two_tiles
	
	var i1 = tile_list.find(from)
	var i2 = tile_list.find(to)
	
	return i2 - i1


# returns the player token on the specified tile (if one exists)
func get_player_token_on_tile(tile):
	for token in player_one_tokens:
		if token.get_tile() == tile:
			return token
	for token in player_two_tokens:
		if token.get_tile() == tile:
			return token
	return null


# resets the text of the specified button to how it was
# at the beginning of the game
func reset_tile(tile):
	if tile in reroll_tiles:
		tile.text = "R"
	elif tile == player_one_start_tile or tile == player_two_start_tile:
		tile.text = "s"
	elif tile == player_one_end_tile or tile == player_two_end_tile:
		tile.text = "e"
	else:
		tile.text = " "


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
		selected_token.set_tile(null)
		if cur_player == 1:
			player_one_score += 1
		else:
			player_two_score += 1
		
		# end of game
		if player_one_score == len(player_one_tokens) \
		or player_two_score == len(player_one_tokens):
			win(cur_player)
			return
		
	else:
		tile_played.text = str(cur_player)
	
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
	
	# what token is at the tile where the player is trying to place
	# the currently selected token?
	var other_token = get_player_token_on_tile(tile)
	
	var opponent_tokens = player_one_tokens
	var opponent_start = player_one_start_tile
	if cur_player == 1:
		opponent_tokens = player_two_tokens
		opponent_start = player_two_start_tile
	
	# make sure move matches roll
	var tile_distance = get_tile_distance(selected_token.get_tile(), tile)
	if tile_distance == cur_roll:
		
		# play token on empty tile
		if not other_token:
			print("Moving player piece")
			end_turn(tile)
		
		# knock opponent off
		elif other_token in opponent_tokens:
			
			# can only knock opponent off if not on reroll tile
			if not tile in reroll_tiles:
				print("Opponent piece captured!")
				other_token.set_tile(opponent_start)
				end_turn(tile)
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
		
		# illegal: wrong number of tiles
		else:
			print("Move did not match roll")
