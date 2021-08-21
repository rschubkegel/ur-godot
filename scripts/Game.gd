extends Node

export (PackedScene) var Game

var game = null


func play_game():
	game = Game.instance()
	game.get_node("rows/actions/menu_button").connect("pressed", self, "main_menu")
	add_child(game)
	$menu.visible = false


func main_menu():
	if game:
		remove_child(game)
		game = null
	$menu.visible = true
