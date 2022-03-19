extends CanvasItem

var player

# Initializes this object and reterns a reference to itself.
func init(owner, color):
	player = owner
	self.modulate = color
	return self
