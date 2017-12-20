extends ViewportContainer

var texture = ImageTexture.new()

onready var bench = get_parent()
onready var size = bench.get_viewport().size
onready var ratio = float(size.x) / size.y

var x = 10
var y = 10

onready var mapping_ranges = Rect2(Vector2(), Vector2(x * ratio, y))

func _ready():
	bench.connect("function_evaluated", self, "_on_function_evaluated")

func _on_function_evaluated(noise):
	texture = noise.map_to_texture(size, noise.get_last_index(), AnlNoise.SEAMLESS_NONE, mapping_ranges)
	visible = true
	update()
	
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			visible = false
	
func _draw():
	draw_texture(texture, Vector2())
	