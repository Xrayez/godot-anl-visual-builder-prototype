extends GraphNode

var name setget set_name, get_name

func _ready():
	resizable = false
	
func set_name(p_name):
	title = p_name
	name = p_name
	
func get_name():
	return name

func add_parameter(parameter):
	var color_input = Color(randf(), randf(), randf())
	var color_output = Color(randf(), randf(), randf())
	
	var input = parameter.get_connection_type()
	var output = not input
	
	set_slot(get_child_count(),
		input,  0, color_input,
		output, 0, color_output
	)
	add_child(parameter)
	
func get_parameter(idx):
	return get_child(idx)
	
func get_parameter_count():
	return get_child_count()
	
func save():
	var function_data = {
		name = get_name(),
		offset_x = get_offset().x,
		offset_y = get_offset().y
	}
	var parameters_data = []
	for parameter in get_children():
		var parameter_data = {
			name = parameter.get_name(),
			type = parameter.get_type(),
			connection_type = parameter.get_connection_type(),
			value = parameter.get_value()
		}
		parameters_data.push_back(parameter_data)
	function_data["parameters"] = parameters_data
	return function_data
