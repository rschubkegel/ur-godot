extends Node

# will be connected by Game.gd on scene change
# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html
export(NodePath) var ip_label
export(NodePath) var ip_ledit
export(NodePath) var connect_button
export(NodePath) var menu_button

# if IP format is valid, make connect button interactable
func ip_text_changed(new_text):
	var ip_regex = RegEx.new()
	ip_regex.compile(get_parent().IP_FORMAT)
	if ip_regex.search(new_text):
		get_node(connect_button).disabled = false
	else:
		get_node(connect_button).disabled = true
