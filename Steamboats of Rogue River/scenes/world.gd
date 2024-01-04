extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Line2D.points = $Path2D.curve.get_baked_points()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Path2D/PathFollow2D.offset += 250 * delta
