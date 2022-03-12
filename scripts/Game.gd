#         ┌────────────play local──────────────┐
#         │                                    ▼
# ┌───────┴┐           ┌────────┐   both      ┌────────┐            ┌────────┐
# │Start   ├───host&──►│Lobby   ├───players──►│Playing ├───player──►│GameOver├─┐
# └────────┘   join    └────────┘   ready     └───────┬┘   wins     └────────┘ │
#  ▲                    ▲                             │                        │
#  │                    └─────────disconnected────────┘                        │
#  │                                                                           │
#  └───────────────────────────────────────────────────────────────────────────┘


extends Node

# signals emitted on scene change
signal menu_s
signal play_s
signal host_s
signal join_s

# nodes to instantiate for scene changes
export (PackedScene) var MainMenu
export (PackedScene) var Lobby
export (PackedScene) var Game

# https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
const IP_FORMAT = '192\\.168\\.\\d+\\.\\d+'
const SERVER_PORT = 8000
const MAX_PLAYERS = 2


# add main menu on application startup
func _ready():
	main_menu()
	
	# connect network event callbacks
	get_tree().connect('network_peer_connected', self, 'player_connected')
	get_tree().connect('network_peer_disconnected', self, 'player_disconnected')
	get_tree().connect("connected_to_server", self, "connected_ok")
	get_tree().connect("connection_failed", self, "connected_fail")
	get_tree().connect("server_disconnected", self, "server_disconnected")


# add menu to tree and connect signals
func main_menu():
	emit_signal('menu_s')
	
	# dump old server
	get_tree().network_peer = null
	
	# add main menu node to tree
	var menu = MainMenu.instance()
	add_child(menu)
	
	# connect signals
	menu.get_node(menu.local_button).connect('pressed', self, 'play')
	menu.get_node(menu.host_button).connect('pressed', self, 'host')
	menu.get_node(menu.join_button).connect('pressed', self, 'join')
	connect('play_s', menu, 'queue_free')
	connect('host_s', menu, 'queue_free')
	connect('join_s', menu, 'queue_free')


# add game to tree and connect signals
func play():
	emit_signal('play_s')
	
	# add game node to tree
	var game = Game.instance()
	add_child(game)
	
	# connect signals
	game.get_node(game.menu_button).connect('pressed', self, 'main_menu')
	connect('menu_s', game, 'queue_free')


# show dialog to connect to existing game on the network
func join():
	emit_signal('join_s')
	
	# add lobby node to tree
	var lobby = Lobby.instance()
	add_child(lobby)
	
	# update UI to reflect joining
	lobby.get_node(lobby.ip_label).text = 'Enter IP to connect to:'
	
	# add signal connections
	lobby.get_node(lobby.menu_button).connect('pressed', self, 'main_menu')
	lobby.get_node(lobby.connect_button).connect('pressed', self, 'connect_to_server', [lobby])
	connect('menu_s', lobby, 'queue_free')
	connect('play_s', lobby, 'queue_free')


# join an existing game on the local network
func connect_to_server(lobby):
	var ip = lobby.get_node(lobby.ip_ledit).text
	var peer = NetworkedMultiplayerENet.new()
	var e = peer.create_client(ip, SERVER_PORT)
	if e:
		print('Could not connect to server at %s' % ip)
		peer.free()
		main_menu()
	else:
		# play() will be called by player_connected()
		get_tree().network_peer = peer


# start server and enter lobby
func host():
	emit_signal('host_s')
	
	# add lobby node to tree
	var lobby = Lobby.instance()
	add_child(lobby)
	
	# hide nodes specific to connecting to a game
	for node in get_tree().get_nodes_in_group("joining"):
		node.visible = false
	
	# connect signals
	connect('menu_s', lobby, 'queue_free')
	connect('play_s', lobby, 'queue_free')
	
	# try to create server
	var ip = init_server()
	if ip:
		lobby.get_node(lobby.ip_label).text = \
			'Server hosted at %s\nWaiting for opponent...' % ip
		lobby.get_node(lobby.menu_button).connect('pressed', self, 'main_menu')
	else:
		print('Could not create server')
		main_menu()


# create a game server and return its ip address on success or null on failure
func init_server():
	var peer = NetworkedMultiplayerENet.new()
	var e = peer.create_server(SERVER_PORT, MAX_PLAYERS)
	if e:
		print('Error: could not create server')
		get_tree().network_peer = null
		return null
	get_tree().network_peer = peer
	return get_ip()


# returns the local IPv4 that server will be hosted on or null on failure
func get_ip():
	# get all IPv4 and IPv6 for computer and search for the correct format
	var addresses = IP.get_local_addresses()
	var ip = null
	var ip_regex = RegEx.new()
	ip_regex.compile(IP_FORMAT)
	var i = 0
	while i < addresses.size():
		if ip_regex.search(addresses[i]):
			ip = addresses[i]
			break
		i += 1
	return ip


# called on server and client
func player_connected(id):
	print('Player %s connected' % str(id))
	get_tree().set_refuse_new_network_connections(true)
	play()


# called on server
func player_disconnected(id):
	get_tree().set_refuse_new_network_connections(false)
	main_menu()
	print('Player %s disconnected' % str(id))


# called on client
func connected_ok():
	print("Connected to server successfully")


# called on client
func connected_fail():
	print("Failed to connect to server")


# called on client
func server_disconnected():
	get_tree().set_refuse_new_network_connections(false)
	main_menu()
	print("Server disconnected")
