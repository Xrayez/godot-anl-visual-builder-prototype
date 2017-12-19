extends ViewportContainer

var texture = ImageTexture.new()
var image = Image.new()

onready var bench = get_parent()
onready var size = bench.get_viewport().size
onready var ratio = float(size.x) / size.y

var x = 10
var y = 10

onready var map_start = Vector2()
onready var map_end = Vector2(x * ratio, y)

func _ready():
	bench.connect("function_evaluated", self, "_on_function_evaluated")

func _on_function_evaluated(noise):
	image = noise.map_to_image(size, AnlNoise.SEAMLESS_NONE, noise.get_last_index(), map_start, map_end)
	visible = true
	update()
	
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			visible = false
	
func _draw():
	texture.create_from_image(image, 0)
	draw_texture(texture, Vector2())
	