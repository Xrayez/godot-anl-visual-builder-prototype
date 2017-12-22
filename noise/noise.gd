extends Control

const Function = preload("res://noise/Function.gd")
const Parameter = preload("res://noise/Parameter.gd")

var VALUE  = Parameter.PARAM_TYPE_VALUE
var ARRAY  = Parameter.PARAM_TYPE_ARRAY
var INPUT  = Parameter.CON_TYPE_INPUT
var OUTPUT = Parameter.CON_TYPE_OUTPUT

var methods = []

var selected = null
var drag_enabled = false

signal function_evaluated(noise)

func _ready():
	if ClassDB.class_exists("AnlNoise"):
		# Retrieve all AnlNoise methods
		methods = ClassDB.class_get_method_list("AnlNoise", true)

	$functions.add_item("Select function")
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
	$save.connect("pressed", self, "_on_save_pressed")
	$clear.connect("pressed", self, "_on_clear_pressed")

	$bench.set_right_disconnects(true)
	$bench.set_use_snap(false)
	$bench.rect_size = get_viewport().size

	$noise_image.rect_size = get_viewport().size

func _process(delta):
	if selected != null and drag_enabled:
		selected.set_offset(get_global_mouse_position())

func _input(event):
	if event.is_action_pressed("place_function"):
		drag_enabled = false

func _on_bench_gui_input(event):
	if event is InputEventMouseButton:
		if event.doubleclick and not $noise_image.visible:
			evaluate()

func _on_function_selected(function):
	selected = function

func _on_connection_request( from, from_slot, to, to_slot ):
	# Disallow looped functions
	if from == to:
		return

	var connections = $bench.get_connection_list()
	for connection in connections:
		if connection["to"] == to and connection["to_port"] == to_slot:
			if $bench.get_node(to).get_parameter(to_slot).get_type() == VALUE:
				# Port already has connection
				# Allow more connections if input type is ARRAY
				return

	$bench.connect_node(from, from_slot, to, to_slot)

func _on_disconnection_request( from, from_slot, to, to_slot ):
	$bench.disconnect_node(from, from_slot, to, to_slot)

func _on_delete_function_request():
	if selected != null:
		if selected.is_selected():
			var connections = $bench.get_connection_list()
			for connection in connections:
				var from = $bench.get_node(connection["from"])
				var to = $bench.get_node(connection["to"])
				if from == selected or to == selected:
					$bench.disconnect_node(
						connection["from"], connection["from_port"],
						connection["to"], connection["to_port"]
					)
			$bench.remove_child(selected)
			selected.queue_free()

func _on_function_item_selected(id):
	var name = $functions.get_item_text(id)
	var function = create_function(name)
	add_function(function)
	pick_function(function)
	# Reset to title
	$functions.select(0)

func _on_save_pressed():
	var data = save_functions()
	save_data(data)

func _on_clear_pressed():
	clear()

func clear():
	selected = null
	# Remove functions
	var functions = get_functions()
	for function in functions:
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

func get_functions():
	var functions = []

	for function in $bench.get_children():
		if function is Function:
			functions.push_back(function)

	return functions

func get_selected_functions():
	var selected = []

	var functions = get_functions()
	for function in functions:
		if function.is_selected():
			selected.push_back(function)

	return selected

func select_function(function):
	selected = function
	$bench.set_selected(function)

func pick_function(function):
	select_function(function)
	drag_enabled = true

func create_function(name):

	var function = Function.new()
	function.name = name

	for method in methods:
		if method["name"] == name:
			for arg in method["args"]:
				# Input
				if arg["type"] == TYPE_REAL_ARRAY or arg["type"] == TYPE_INT_ARRAY:
					var parameter = Parameter.new(arg["name"], ARRAY, INPUT)
					function.add_parameter(parameter)
				else:
					var parameter = Parameter.new(arg["name"], VALUE, INPUT)
					function.add_parameter(parameter)
			# Output
			var parameter = Parameter.new("index", VALUE, OUTPUT)
			function.add_parameter(parameter)

	return function

func add_function(function):
	$bench.add_child(function)

func get_function_inputs(function):

	var inputs = []

	var connections = $bench.get_connection_list()
	for connection in connections:
		var to = $bench.get_node(connection["to"])
		if to == function:
			inputs.push_back(connection)

	return inputs

func get_function_input(function, idx):

	var inputs = []

	var connections = $bench.get_connection_list()
	for connection in connections:
		var to = $bench.get_node(connection["to"])
		var to_port = connection["to_port"]
		if to == function and to_port == idx:
			var input = $bench.get_node(connection["from"])
			inputs.push_back(input)

	return inputs

func evaluate_function(noise, function, args = []):
	assert(function != null)
	
	if args.empty():
		var arg
		# Evaluate function with arguments
		for idx in function.get_parameter_count():
			var parameter = function.get_parameter(idx)
			if parameter.get_connection_type() == INPUT:
				if parameter.is_empty():
					var input_funcs = get_function_input(function, idx)
					if input_funcs.size() == 0:
						select_function(function)
						return null
					elif parameter.get_type() == ARRAY:
						var array_args = []
						for input in input_funcs:
							arg = evaluate_function(noise, input)
							array_args.push_back(arg)
						args.push_back(array_args)
					elif parameter.get_type() == VALUE:
						arg = evaluate_function(noise, input_funcs[0])
						args.push_back(arg)
				else:
					arg = parameter.get_value()
					args.push_back(arg)
	var index
	if function.has_component():
		# Function has sub-functions
		index = function.get_component().evaluate(args)
	else:
		# Raw function
		index = noise.callv(function.name, args)
	return index

func evaluate(args = []):
	var noise = AnlNoise.new()

	var index

	if selected != null and selected.is_selected():
		# Resulting instruction index at selected function
		index = evaluate_function(noise, selected, args)

	if index != null:
		emit_signal("function_evaluated", noise)
	return index
	
func save_data(data):
	var file = File.new()
	file.open("res://functions.nvb", File.WRITE)
	file.store_line(to_json(data))
	file.close()

func save_functions(selected_only = false):
	var functions = []
#	if selected_only:
#		functions = get_selected_functions()
#	else:
	functions = get_functions()

	var functions_data = []
	for function in functions:
		functions_data.push_back(function.save())

	var connections_data = $bench.get_connection_list()

	var data = {
		functions = functions_data,
		connections = connections_data,
		selected = selected
	}
	return data
	
func load_functions():
	clear()
	