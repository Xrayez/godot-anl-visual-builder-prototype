extends ViewportContainer

var texture = ImageTexture.new()

onready var workbench = get_parent()

func _ready():
	workbench.connect("component_changed", self, "_on_component_changed")
	
func _on_component_changed(from, to):

	if from.is_connected("function_evaluated", self, "_on_function_evaluated"):
		from.disconnect("function_evaluated", self, "_on_function_evaluated")
	to.connect("function_evaluated", self, "_on_function_evaluated")

	if from.is_connected("node_selected", self, "_on_function_selected"):
		from.disconnect("node_selected", self, "_on_function_selected")
	to.connect("node_selected", self, "_on_function_selected")

func _on_function_evaluated():

	var params = _setup_image_params()
	
	# Map and show the noise image
	map(params.image_size, params.mode, params.mapping_ranges)
	show()


func _on_function_selected(function):

	var preview = workbench.get_node("params/seamless").pressed
	# if preview:


func _setup_image_params():
	var viewport_size = workbench.get_viewport().size
	# Get image size
	var image_width = int(workbench.get_node("params/width").text)
	var image_height = int(workbench.get_node("params/height").text)
	var image_size
	if image_width and image_height:
		image_size = Vector2(image_width, image_height)
	else:
		image_size = viewport_size
		
	# Get mapping mode
	var is_pressed = workbench.get_node("params/seamless").pressed
	var mode
	if is_pressed:
		mode = AnlNoise.SEAMLESS_XY
	else:
		mode = AnlNoise.SEAMLESS_NONE
		
	# Get mapping ranges
	var map_x = float(workbench.get_node("ranges/x").text)
	var map_y = float(workbench.get_node("ranges/y").text)
	var map_width = float(workbench.get_node("ranges/width").text)
	var map_height = float(workbench.get_node("ranges/height").text)
	
	var mapping_ranges
	is_pressed = workbench.get_node("params/keep_aspect").pressed
	if is_pressed:
		var ratio = float(image_size.x) / image_size.y
		mapping_ranges = Rect2(map_x, map_y, map_width * ratio, map_height)
	else:
		mapping_ranges = Rect2(map_x, map_y, map_width, map_height)

	var params = {
		image_size = image_size,
		mode = mode,
		mapping_ranges = mapping_ranges
	}
	
	return params

	
func map(image_size, mode, mapping_ranges):
	var noise = Noise.get_noise()
	texture = noise.map_to_texture(image_size, noise.get_last_index(), mode, mapping_ranges)
	
	if workbench.get_node("params/save_to_file").pressed:
		var base = workbench.get_node("filename").text
		var data = str(image_size.x) + "x" + str(image_size.y)
		var extension = ".png"
		var file_name = base + "_" + data + extension
		texture.get_data().save_png(Config.IMAGES_PATH + file_name)
	
func show():
	visible = true
	
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			visible = false
	
func _draw():
	draw_texture(texture, Vector2())
	