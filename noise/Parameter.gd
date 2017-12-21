extends LineEdit

enum ParamType {
	PARAM_TYPE_VALUE,
	PARAM_TYPE_ARRAY
}
enum ConnectionType {
	CON_TYPE_OUTPUT,
	CON_TYPE_INPUT
}

var name setget , get_name
var type setget , get_type
var connection_type setget , get_connection_type

func _init(p_name, p_type = PARAM_TYPE_VALUE, p_connection_type = CON_TYPE_INPUT, p_value = null):

	var input = p_connection_type == CON_TYPE_INPUT
	var output = not input
	
	placeholder_text = str(p_name)
	if p_value: text = str(p_value)

	if input:
		editable = true
	if output:
		editable = false
#		align = ALIGN_CENTER
		
	name = p_name
	type = p_type
	connection_type = p_connection_type

func _ready():
	expand_to_text_length = true
	
func get_name():
	return name
	
func get_value():
	if not is_empty():
		return float(text)
	return null
	
func get_type():
	return type
	
func get_connection_type():
	return connection_type
	
func is_empty():
	return text.empty()
