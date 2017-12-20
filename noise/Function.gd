extends GraphNode

enum FunctionType {
	FUNCTION_TYPE_INDEX
}

var name setget set_function_name, get_function_name

func _ready():
	resizable = false
	
func set_function_name(p_name):
	title = p_name
	name = p_name
	
func get_function_name():
	return name

func add_arg(input, arg, value = null):
	
	var input_color = Color(randf(), randf(), randf())
	var output_color = Color(randf(), randf(), randf())
	
	set_slot(get_child_count(),
		input, FUNCTION_TYPE_INDEX, input_color,
		not input, FUNCTION_TYPE_INDEX, output_color
	)
	var slot
	if input:
		slot = LineEdit.new()
		slot.expand_to_text_length = true
		slot.placeholder_text = str(arg)
		if value: slot.text = str(value)
	else:
		slot = Label.new()
		slot.align = Label.ALIGN_RIGHT
		slot.text = str(arg)
	
	add_child(slot)
	
func get_arg_count():
	return get_child_count() - 1
	
func get_arg_value(idx):
	var value = float(get_child(idx).text)
	return value
		
func is_arg_empty(idx):
	return get_child(idx).text.empty()