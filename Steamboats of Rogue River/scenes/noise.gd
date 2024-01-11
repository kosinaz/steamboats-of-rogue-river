extends Node2D

var _noise = OpenSimplexNoise.new()

func _ready():
	randomize()
	# Configure the OpenSimplexNoise instance.
	_noise.seed = randi()
	_noise.octaves = 4
	_noise.period = 20.0
	_noise.persistence = 0.8

	for i in 100:
		# Prints a slowly-changing series of floating-point numbers
		# between -1.0 and 1.0.
		print(_noise.get_noise_1d(i))
