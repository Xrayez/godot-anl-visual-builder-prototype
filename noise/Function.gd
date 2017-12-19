extends GraphNode

var function_name setget set_function_name, get_function_name
var function_args = [] setget set_function_args, get_function_args

func _ready():
	pass
	
func set_function_name(name):
	function_name = name
	
func get_function_name():
	return function_name
	
func set_function_args(args):
	function_args = args
	
func get_function_args():
	return function_args
