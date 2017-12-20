extends Control

const Function = preload("res://noise/Function.gd")

var methods = []

var selected_function = null

signal function_evaluated(noise)

func _ready():
	if ClassDB.class_exists("AnlNoise"):
		# Retrieve all AnlNoise methods
		methods = ClassDB.class_get_method_list("AnlNoise", true)
		
	for method in methods:
		if method["return"]["type"] == TYPE_INT:
			# Add functions that return Index
			$functions.add_item(method["name"])
			
	$bench.connect("node_selected", self, "_on_function_selected")
	$bench.connect("connection_request", self, "_on_connection_request")
	$bench.connect("delete_nodes_request", self, "_on_delete_function_request")
	$bench.connect("disconnection_request", self, "_on_disconnection_request")
	$bench.connect("gui_input", self, "_on_bench_gui_input")
	
	$functions.connect("item_selected", self, "_on_function_item_selected")
	$clear.connect("pressed", self, "_on_clear_pressed")
	
	$bench.set_right_disconnects(true)
	
	$bench.rect_size = get_viewport().size
	$noise_image.rect_size = get_viewport().size
		
func _on_bench_gui_input(event):
	if event is InputEventMouseButton:
		if event.doubleclick and not $noise_image.visible:
			evaluate()
		
func _on_function_selected(function):
	selected_function = function
	
func _on_connection_request( from, from_slot, to, to_slot ):
	# Disallow looped functions
	if from == to:
		return
		
	var connections = $bench.get_connection_list()
	for connection in connections:
		if connection["to"] == to and connection["to_port"] == to_slot:
			# Port already has connection
			return
	
	$bench.connect_node(from, from_slot, to, to_slot)
	
func _on_disconnection_request( from, from_slot, to, to_slot ):
	$bench.disconnect_node(from, from_slot, to, to_slot)
	
func _on_delete_function_request():
	if selected_function != null:
		if selected_function.is_selected():
			var connections = $bench.get_connection_list()
			for connection in connections:
				var from = $bench.get_node(connection["from"])
				var to = $bench.get_node(connection["to"])
				if from == selected_function or to == selected_function:
					$bench.disconnect_node(
						connection["from"], connection["from_port"], 
						connection["to"], connection["to_port"]
					)
			$bench.remove_child(selected_function)
			selected_function.queue_free()

func _on_function_item_selected(id):
	var name = $functions.get_item_text(id)
	var function = create_function(name)
	add_function(function)
	
func _on_clear_pressed():
	clear()
	
func clear():
	selected_function = null
	# Remove functions
	for function in $bench.get_children():
		if function is Function:
			$bench.remove_child(function)
			function.queue_free()
	# Remove connections
	for connection in $bench.get_connection_list():
		$bench.disconnect_node(
			connection["from"], connection["from_port"],
			connection["to"], connection["to_port"]
		)
	
func _on_evaluate_pressed():
	evaluate()
	
func create_function(name):
	
	var function = Function.new()
	function.name = name
	
	for method in methods:
		if method["name"] == name:
			for arg in method["args"]:
				function.add_arg(true, arg["name"]) # set slot as input
			function.add_arg(false, "index") # set last slot as output (return)

	return function

func add_function(function):
	$bench.add_child(function)
	
func get_inputs(function):
	var inputs = []
	
	var connections = $bench.get_connection_list()
	for connection in connections:
		var to = $bench.get_node(connection["to"])
		if to == function:
			inputs.push_back(connection)
	
	return inputs
	
func get_input(function, idx):
	
	var input = null
	
	var connections = $bench.get_connection_list()
	for connection in connections:
		var to = $bench.get_node(connection["to"])
		var to_port = connection["to_port"]
		if to == function and to_port == idx:
			input = $bench.get_node(connection["from"])
			return input
	
func evaluate_function(noise, function):
	
	assert(function != null)
	
	var args = []
	var arg
	
	for idx in function.get_arg_count():
		if function.is_arg_empty(idx):
			var input_func = get_input(function, idx)
			if input_func == null:
				$bench.set_selected(input_func)
				return null
			arg = evaluate_function(noise, input_func)
		else:
			arg = function.get_arg_value(idx)
		args.push_back(arg)

	# Instruction index evaluated
	var index = noise.callv(function.name, args)
	return index
	
func evaluate():
	var noise = AnlNoise.new()
	
	var index
	
	if selected_function != null:
		if selected_function.is_selected():
			# Resulting instruction index at selected function
			index = evaluate_function(noise, selected_function)
		
	if index != null:
		emit_signal("function_evaluated", noise)
	