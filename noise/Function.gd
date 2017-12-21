extends GraphNode

enum ArgType {
	ARG_TYPE_VALUE,
	ARG_TYPE_ARRAY
}
enum ConnectionType {
	CONNECTION_INPUT,
	CONNECTION_OUTPUT
}
var name setget set_function_name, get_function_name

func _ready():
	resizable = false
	
func set_function_name(p_name):
	title = p_name
	name = p_name
	
func get_function_name():
	return name

func add_arg(arg_name, arg_type = ARG_TYPE_VALUE, connection_type = CONNECTION_INPUT, value = null):
	
	var color_input = Color(randf(), randf(), randf())
	var color_output = Color(randf(), randf(), randf())
	
	var input = connection_type == CONNECTION_INPUT
	var output = not input
	
	set_slot(get_child_count(),
		input,  0, color_input,
		output, 0, color_output
	)
	var slot
	if input:
		slot = LineEdit.new()
		slot.expand_to_text_length = true
		slot.placeholder_text = str(arg_name)
		if value: slot.text = str(value)
	elif output:
		slot = Label.new()
		slot.align = Label.ALIGN_RIGHT
		slot.text = str(arg_name)
	slot.set_meta("arg_name", arg_name)
	slot.set_meta("arg_type", arg_type)
	slot.set_meta("connection_type", connection_type)
	
	add_child(slot)
	
func get_arg_count():
	return get_child_count() - 1
	
func get_arg_value(idx):
	var arg = get_child(idx)
	if arg.get_meta("connection_type") == CONNECTION_INPUT:
		return float(arg.text)
	return null
	
func get_arg_type(idx):
	return get_child(idx).get_meta("arg_type")
	
func is_arg_empty(idx):
	return get_child(idx).text.empty()
	
func save():
	var function_data = {
		name = get_function_name(),
		offset_x = get_offset().x,
		offset_y = get_offset().y
	}
	var args_data = []
	for arg in get_children():
		var arg_data = {
			name = arg.get_meta("arg_name"),
			type = arg.get_meta("arg_type"),
			connection = arg.get_meta("connection_type")
		}
		args_data.push_back(arg_data)
	function_data["args"] = args_data
	return function_data
