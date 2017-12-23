extends Control

const Component = preload("res://noise/Component.gd")

const EXTENSION = ".nvb"

var component setget set_component, get_component
var methods = [] setget , get_methods
var drag_enabled = false setget set_drag_enabled, get_drag_enabled

signal component_changed()

################################################################################
# Callbacks
################################################################################
func _ready():
	retrieve_methods()
	
	$functions.connect("item_selected", self, "_on_function_item_selected")
	$filename/save.connect("pressed", self, "_on_save_pressed")
	$filename/load.connect("pressed", self, "_on_load_pressed")
	$clear.connect("pressed", self, "_on_clear_pressed")
	$image.rect_size = get_viewport().size
	
	# Make base component and add as a topmost child
	component = Component.new()
	set_component(component)
	add_child(component)
	move_child(component, 0)
	
	
func retrieve_methods(class_name = "AnlNoise"):
	if ClassDB.class_exists(class_name):
		# Retrieve all AnlNoise methods
		methods = ClassDB.class_get_method_list(class_name, true)
	
	$functions.add_item("Select function")
	for method in methods:
		if method["return"]["type"] == TYPE_INT:
			# Add functions that return Index
			$functions.add_item(method["name"])
			
func _on_evaluate_pressed():
	component.evaluate()
	
################################################################################
# Events
################################################################################
func _on_function_item_selected(id):
	var name = $functions.get_item_text(id)
	var function = component.create_function(name)
	component.add_function(function)
	component.pick_function(function)
	# Reset to title
	$functions.select(0)

func _on_save_pressed():
	var data = component.save_functions()
	var filename = $filename.text
	if filename.is_valid_identifier():
		component.save_data(data, filename)

func _on_load_pressed():
	var filename = $filename.text
	if filename.is_valid_identifier():
		var data = component.load_data(filename)
		component.load_functions(data)

func _on_clear_pressed():
	component.clear()

################################################################################
# Methods
################################################################################
func set_component(p_component):
	component = p_component
	emit_signal("component_changed", p_component, component)
	
func get_component():
	return component
	
func get_methods():
	return methods
	
func set_drag_enabled(is_enabled):
	drag_enabled = is_enabled
	
func get_drag_enabled():
	return drag_enabled
