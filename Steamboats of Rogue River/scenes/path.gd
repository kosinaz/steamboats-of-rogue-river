extends Path2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	print(curve)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$PathFollow2D.offset += 250 * delta
