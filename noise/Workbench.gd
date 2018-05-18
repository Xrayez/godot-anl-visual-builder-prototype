extends Control

const Component = preload("res://noise/Component.gd")

var component setget set_component, get_component
var drag_enabled = false setget set_drag_enabled, get_drag_enabled

signal component_changed()

################################################################################
# Callbacks
################################################################################
func _ready():
	# Connect to signals
	get_tree().get_root().connect("size_changed", self, "_on_size_changed")
	$functions.connect("item_selected", self, "_on_function_item_selected")
	$filename/save.connect("pressed", self, "_on_save_pressed")
	$filename/load.connect("pressed", self, "_on_load_pressed")
	$clear.connect("pressed", self, "_on_clear_pressed")
	
	var methods = Noise.retrieve_methods()
	
	$functions.add_item("Select function")
	for method in methods:
		if method["return"]["type"] == TYPE_INT:
			# Add functions that return Index (most are ints)
			$functions.add_item(method["name"])
	
	# Make new component
	component = Component.new()
	component.name = Config.DEFAULT_COMPONENT_NAME
	component.component_name = Config.DEFAULT_COMPONENT_NAME
	add_component(component)
	
	_resize_ui()
	
func _resize_ui():
	var size = get_viewport().size
	$panel.rect_size = size
	$components.rect_size = Vector2(size.x, size.y - $components.rect_position.y)
	$image.rect_size = size
	
func _on_size_changed():
	_resize_ui()
	
################################################################################
# Events
################################################################################
func _on_function_item_selected(id):
	var selected_name = $functions.get_item_text(id)
	var function = component.create_function(selected_name)
	component.add_function(function)
	component.pick_function(function)
	# Reset to title
	$functions.select(0)

func _on_save_pressed():
	var data = component.save_functions()
	var file_name = $filename.text
	if file_name.is_valid_identifier():
		component.save_data(data, file_name)

func _on_load_pressed():
	var file_name = $filename.text
	if file_name.is_valid_identifier():
		var data = component.load_data(file_name)
		component.load_functions(data)

func _on_clear_pressed():
	component.clear()

################################################################################
# Methods
################################################################################
func set_component(p_component):
	var current = $components.get_current_tab_control()
	emit_signal("component_changed", p_component, component)
	current = p_component
	
func get_component():
	var current = $components.get_current_tab_control()
	return current
	
func add_component(p_component, activate = true):
	if is_a_parent_of(component):
		return
	# Add new component
	$components.add_child(p_component)
	
	component = p_component
	# Set as current
	if activate:
		set_component(component)
	
func set_drag_enabled(is_enabled):
	drag_enabled = is_enabled
	
func get_drag_enabled():
	return drag_enabled
