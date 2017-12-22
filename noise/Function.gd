extends GraphNode

var name setget set_function_name, get_function_name
var component = null setget set_component, get_component

func _ready():
	resizable = false

func set_function_name(p_name):
	title = p_name
	name = p_name

func get_function_name():
	return name

func set_component(p_component):
	if p_component is GraphEdit:
		component = p_component

func get_component():
	return component

func has_component():
	return component != null

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
		id = get_name(),
		function_name = name,
		offset_x = get_offset().x,
		offset_y = get_offset().y
	}
	var parameters_data = []
	for parameter in get_children():
		var parameter_data = {
			name = parameter.name,
			type = parameter.type,
			connection_type = parameter.connection_type,
			value = parameter.value
		}
		parameters_data.push_back(parameter_data)
	function_data["parameters"] = parameters_data
	return function_data
