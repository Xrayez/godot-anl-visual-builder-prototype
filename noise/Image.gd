extends ViewportContainer

var texture = ImageTexture.new()

onready var workbench = get_parent()

onready var size = workbench.get_viewport().size
onready var ratio = float(size.x) / size.y

var x = 10
var y = 10

onready var mapping_ranges = Rect2(Vector2(), Vector2(1 * ratio, 1))

func _ready():
	workbench.connect("component_changed", self, "_on_component_changed")
	
func _on_component_changed(from, to):
	if from.is_connected("function_evaluated", self, "_on_function_evaluated"):
		from.disconnect("function_evaluated", self, "_on_function_evaluated")
	to.connect("function_evaluated", self, "_on_function_evaluated")

func _on_function_evaluated():
	# Get image size
	var width = int(workbench.get_node("width").text)
	var height = int(workbench.get_node("height").text)
	var image_size
	if width and height:
		image_size = Vector2(width, height)
	else:
		image_size = workbench.get_viewport().size
		
	# Get mapping mode
	var is_pressed = workbench.get_node("seamless").pressed
	var mode
	if is_pressed:
		mode = AnlNoise.SEAMLESS_XY
	else:
		mode = AnlNoise.SEAMLESS_NONE
		
	# Map and show the noise image
	map(image_size, mode)
	show()
	
func map(image_size, mode):
	var noise = Noise.get_noise()
	texture = noise.map_to_texture(image_size, noise.get_last_index(), mode, mapping_ranges)
	
	if workbench.get_node("save_to_file").pressed:
		var base = workbench.get_node("filename").text
		var data = str(image_size.x) + "x" + str(image_size.y)
		var extension = ".png"
		var filename = base + "_" + data + extension
		texture.get_data().save_png(Config.IMAGES_PATH + filename)
	
func show():
	visible = true
	
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			visible = false
	
func _draw():
	draw_texture(texture, Vector2())
	