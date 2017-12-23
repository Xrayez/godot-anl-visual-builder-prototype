extends Node

var noise = AnlNoise.new() setget set_noise, get_noise

func reset_noise():
	noise = AnlNoise.new()

func set_noise(p_noise):
	noise = p_noise

func get_noise():
	return noise
	