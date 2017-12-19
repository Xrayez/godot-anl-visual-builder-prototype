extends Control

const Function = preload("res://noise/Function.gd")

var methods = []

var selected_function = null

enum SlotType {
	SLOT_TYPE_INDEX,
	SLOT_TYPE_VALUE
}

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
	
	$add_value.connect("pressed", self, "_on_add_value_pressed")
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
	
func _on_add_value_pressed():
	var function = create_function("value", SLOT_TYPE_VALUE)
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
	
func _on_show_pressed():
	show_noise()
	
func create_function(name, type = SLOT_TYPE_INDEX):
	
	var function = Function.new()
	function.set_name(name)
	function.title = name
#	function.show_close = true
	
	match type:
		SLOT_TYPE_INDEX:
			for method in methods:
				if method["name"] == function.get_name():
					for arg in method["args"]:
						add_param(function, true, arg["name"]) # set slot as input
					add_param(function, false, "") # set last slot as output (return)
		SLOT_TYPE_VALUE:
			add_param(function, false, "value", $value.text, SLOT_TYPE_VALUE)
			
	return function

func add_function(function):
	$bench.add_child(function)
#	function.connect("close_request", self, "_on_function_close_request")
	
func add_param(function, input, arg_name, arg_value=0.0, type=SLOT_TYPE_INDEX):

	var input_color = Color(randf(), randf(), randf())
	var output_color = Color(randf(), randf(), randf())
	
	function.set_slot(function.get_child_count(), 
		input,     0, input_color,
		not input, 0, output_color
	)
	var slot
	match type:
		SLOT_TYPE_INDEX:
			slot = Label.new()
			slot.text = arg_name
		SLOT_TYPE_VALUE:
			slot = LineEdit.new()
			slot.text = str(arg_value)
	function.add_child(slot)
	
func get_connectivity(function):
	var froms = []
	
	var connections = $bench.get_connection_list()
	for connection in connections:
		var to = $bench.get_node(connection["to"])
		if to == function:
			froms.push_back( $bench.get_node(connection["from"]) )
	
	return froms
	
func evaluate_function(noise, function_name):
	
	var function = $bench.get_node(function_name)
	assert(function != null)
	var inputs = get_connectivity(function)
	var args = []
	
	for input in inputs:
		var input_name = input.get_name()
		if input_name.matchn("*value*"):
			# Raw value, not function, no need to evaluate
			var arg = float(input.get_child(0).text)
			args.push_back(arg)
		else:
			# Argument is a function, evaluate to get value
			var func_name = input.get_name()
			var placeholder_pos = func_name.rfind("@")
			if placeholder_pos >= 0:
				func_name = func_name.substr(1, placeholder_pos - 1)
			var arg = evaluate_function(noise, func_name)
			args.push_back(arg)
			
	# Instruction index evaluated
	var index = noise.callv(function.get_name(), args)
	assert(index != null)
	return index
	
func evaluate():
	var noise = AnlNoise.new()
	
	if selected_function != null:
		if selected_function.is_selected():
			# Resulting instruction index at selected function
			evaluate_function(noise, selected_function.get_name())
		
	emit_signal("function_evaluated", noise)
	