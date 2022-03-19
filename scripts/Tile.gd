extends Button

const IMG_REROLL	= preload('res://images/dice.png')
const IMG_START		= preload('res://images/hexagon_in.png')
const IMG_END		= preload('res://images/hexagon_out.png')
const TYPE_NORMAL	= 0
const TYPE_REROLL	= 1
const TYPE_START	= 2
const TYPE_END		= 3

var players	# which players can play on this tile?
var type	# see constants above
var selected# nuff said
var _tokens	# which tokens currently occupy this tile?

# Initializes this object and reterns a reference to itself.
func init(owners, tile_type=TYPE_NORMAL):
	players = owners
	type = tile_type
	selected = false
	_tokens = []
	
	# set texture
	var texture = null
	if type == TYPE_REROLL:
		texture = IMG_REROLL
	elif type == TYPE_START:
		texture = IMG_START
	elif type == TYPE_END:
		texture = IMG_END
	$texture.texture = texture
	
	return self

# Hide current top token, add new token, and show new top token.
#
# @param	token: the new top token
func add_token(token):
	if not empty():
		top().visible = false
	_tokens.append(token)
	add_child(top())
	top().visible = true
	$texture.visible = false

# Hide current top token, pop it, show next token (if there is one)
# and return the previous top token.
#
# @return	the previous top token
func pop_token():
	var back = _tokens.pop_back()
	remove_child(back)
	back.visible = false
	if not empty():
		top().visible = true
	else:
		$texture.visible = true
	return back

# Returns a reference to the top token on this tile.
#
# @return	the top token
func top():
	return _tokens[-1]

# Returns true if this tile has no tokens on it.
#
# @return	true if this tile has no tokens on it
func empty():
	return _tokens.empty()

func size():
	return _tokens.size()

# Highlights this tile if parameter is true, otherwise unhighlights it.
#
# @param	hightlight: should this token be selected/highlighted?
func set_highlight(highlight):
	if selected:
		modulate = Color.yellow
	else:
		modulate = Color.white

func select():
	selected = true
	set_highlight(selected)

func deselect():
	selected = false
	set_highlight(selected)
