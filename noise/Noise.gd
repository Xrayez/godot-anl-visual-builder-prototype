extends Node

var noise = AnlNoise.new() setget set_noise, get_noise
var methods = [] setget , get_methods

func reset_noise():
	noise = AnlNoise.new()

func set_noise(p_noise):
	noise = p_noise

func get_noise():
	return noise
	
func retrieve_methods(class_signature = "AnlNoise"):
	if ClassDB.class_exists(class_signature):
		# Retrieve all AnlNoise methods
		methods = ClassDB.class_get_method_list(class_signature, true)
	return methods
			
func get_methods():
	return methods