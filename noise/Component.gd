extends GraphEdit

const Function = preload("res://noise/Function.gd")
const Parameter = preload("res://noise/Parameter.gd")

var VALUE  = Parameter.PARAM_TYPE_VALUE
var ARRAY  = Parameter.PARAM_TYPE_ARRAY
var INPUT  = Parameter.CON_TYPE_INPUT
var OUTPUT = Parameter.CON_TYPE_OUTPUT

signal evaluated()

var selected = null
var drag_enabled = false
################################################################################
# Callbacks
################################################################################
func _ready():
	connect("node_selected", self, "_on_function_selected")
	connect("connection_request", self, "_on_connection_request")
	connect("disconnection_request", self, "_on_disconnection_request")
	connect("delete_nodes_request", self, "_on_delete_function_request")
	connect("gui_input", self, "_on_gui_input")

	set_right_disconnects(true)
	set_use_snap(false)
	rect_size = get_viewport().size
	
func _process(delta):
	if selected != null and drag_enabled:
		selected.set_offset(get_scroll_ofs() + get_global_mouse_position())

func _input(event):
	if event.is_action_pressed("place_function"):
		drag_enabled = false

################################################################################
# Events
################################################################################
func _on_function_selected(function):
	selected = function

func _on_connection_request( from, from_slot, to, to_slot ):
	# Disallow looped functions
	if from == to:
		return
	var connections = get_connection_list()
	for connection in connections:
		if connection["to"] == to and connection["to_port"] == to_slot:
			if get_node(to).get_parameter(to_slot).type == VALUE:
				# Port already has connection
				# Allow more connections if input type is ARRAY
				return
	connect_node(from, from_slot, to, to_slot)

func _on_disconnection_request( from, from_slot, to, to_slot ):
	disconnect_node(from, from_slot, to, to_slot)

func _on_delete_function_request():
	var functions = get_selected_functions()
	for selected in functions:
		var connections = get_connection_list()
		for connection in connections:
			var from = get_node(connection["from"])
			var to = get_node(connection["to"])
			if from == selected or to == selected:
				disconnect_node(
					connection["from"], connection["from_port"],
					connection["to"], connection["to_port"]
				)
		remove_child(selected)
		selected.queue_free()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.doubleclick:
			evaluate()

################################################################################
# Methods
################################################################################
func evaluate_function(noise, function, args = []):
	assert(function != null)

	if args.empty():
		var arg
		# Evaluate function with arguments
		for idx in function.get_parameter_count():
			var parameter = function.get_parameter(idx)
			if parameter.connection_type == INPUT:
				if parameter.is_empty():
					var params = get_function_params(function, idx)
					if params.size() == 0:
						select_function(function)
						return null
					elif parameter.type == ARRAY:
						var array_args = []
						for param in params:
							arg = evaluate_function(noise, param)
							array_args.push_back(arg)
						args.push_back(array_args)
					elif parameter.type == VALUE:
						arg = evaluate_function(noise, params[0])
						args.push_back(arg)
				else:
					arg = parameter.value.split_floats(",")
					if arg.size() > 1:
						args.push_back(arg)
					elif arg.size() == 1:
						args.push_back(arg[0])
	var index
	if function.has_component():
		# Function has sub-functions
		index = function.get_component().evaluate(args)
	else:
		# Raw function
		index = Noise.get_noise().callv(function.name, args)
	print(index)
	return index

func evaluate(args = []):
	var index
	
	if selected != null and selected.is_selected():
		# Resulting instruction index at selected function
		index = evaluate_function(Noise.get_noise(), selected, args)
		
	if index != null:
		emit_signal("evaluated")
	return index

func get_functions():
	var functions = []

	for function in get_children():
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
	set_selected(function)

func pick_function(function):
	select_function(function)
	drag_enabled = true

func create_function(name):

	var function = Function.new()
	function.name = name
	
	var methods = Noise.get_methods()

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
	add_child(function, true)

func get_function_params(function, idx):
	
	var params = []
	
	var connections = get_connection_list()
	for connection in connections:
		var to = get_node(connection["to"])
		var to_port = connection["to_port"]
		if to == function and to_port == idx:
			var param = get_node(connection["from"])
			params.push_back(param)
	
	return params
	
func clear():
	selected = null
	# Remove functions
	var functions = get_functions()
	for function in functions:
		remove_child(function)
		function.queue_free()
	# Remove connections
	for connection in get_connection_list():
		disconnect_node(
			connection["from"], connection["from_port"],
			connection["to"], connection["to_port"]
		)

func save_data(data, filename):
	var file = File.new()
	file.open(filename + Config.EXTENSION, File.WRITE)
	file.store_line(to_json(data))
	file.close()

func save_functions():
	var functions = []

	functions = get_functions()

	var functions_data = []
	for function in functions:
		functions_data.push_back(function.save())

	var connections_data = get_connection_list()

	var data = {
		functions = functions_data,
		connections = connections_data,
	}
	return data
	
func load_data(filename):
	var file = File.new()
	file.open(filename + Config.EXTENSION, File.READ)
	var data = parse_json(file.get_line())
	file.close()
	return data

func load_functions(data):
	clear()
	
	var functions_data = data["functions"]
	for f in functions_data:
		var function = Function.new()
		function.set_name(f["id"])
		function.name = f["function_name"]
		function.set_offset( Vector2(f["offset_x"], f["offset_y"]) )
		for p in f["parameters"]:
			var parameter = Parameter.new(p["name"], p["type"], p["connection_type"], p["value"])
			function.add_parameter(parameter)
		add_function(function)

	var connections_data = data["connections"]
	for c in connections_data:
		connect_node(c["from"], c["from_port"], c["to"], c["to_port"])
