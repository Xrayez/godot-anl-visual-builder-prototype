extends ViewportContainer

var texture = ImageTexture.new()

onready var workbench = get_parent()

onready var size = workbench.get_viewport().size
onready var ratio = float(size.x) / size.y

var x = 10
var y = 10

onready var mapping_ranges = Rect2(Vector2(), Vector2(x * ratio, y))

func _ready():
	workbench.connect("component_changed", self, "_on_component_changed")
	
func _on_component_changed(from, to):
	if from.is_connected("evaluated", self, "_on_evaluated"):
		from.disconnect("evaluated", self, "_on_evaluated")
	to.connect("evaluated", self, "_on_evaluated")

func _on_evaluated():
	var noise = Noise.get_noise()
	texture = noise.map_to_texture(size, noise.get_last_index(), AnlNoise.SEAMLESS_NONE, mapping_ranges)
	Noise.reset_noise()
	visible = true
	
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			visible = false
	
func _draw():
	draw_texture(texture, Vector2())
	