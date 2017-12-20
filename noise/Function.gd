extends GraphNode

enum ArgType {
	ARG_TYPE_EMPTY,
	ARG_TYPE_VALUE,
	ARG_TYPE_ARRAY
}

var name setget set_function_name, get_function_name

func _ready():
	resizable = false
	
func set_function_name(p_name):
	title = p_name
	name = p_name
	
func get_function_name():
	return name

func add_arg(arg, type_input = ARG_TYPE_EMPTY, type_output = ARG_TYPE_EMPTY, value = null):
	
	var color_input = Color(randf(), randf(), randf())
	var color_output = Color(randf(), randf(), randf())
	
	var input = type_input != ARG_TYPE_EMPTY
	var output = type_output != ARG_TYPE_EMPTY
	
	set_slot(get_child_count(),
		input,  0, color_input,
		output, 0, color_output
	)
	var slot
	if input:
		slot = LineEdit.new()
		slot.expand_to_text_length = true
		slot.placeholder_text = str(arg)
		slot.set_meta("type", type_input)
		if value: slot.text = str(value)
	elif output:
		slot = Label.new()
		slot.align = Label.ALIGN_RIGHT
		slot.text = str(arg)
		slot.set_meta("type", type_output)
	
	add_child(slot)
	
func get_arg_count():
	return get_child_count() - 1
	
func get_arg_value(idx):
	var value = float(get_child(idx).text)
	return value
	
func get_arg_type(idx):
	return get_child(idx).get_meta("type")
	
func is_arg_empty(idx):
	return get_child(idx).text.empty()