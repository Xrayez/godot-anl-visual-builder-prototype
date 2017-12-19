extends ViewportContainer

var texture = ImageTexture.new()
var image = Image.new()

var noise = AnlNoise.new()

onready var bench = get_parent()
onready var size = bench.get_viewport().size
onready var ratio = float(size.x) / size.y

var x = 10
var y = 10

onready var map_start = Vector2()
onready var map_end = Vector2(x * ratio, y)

func _ready():
	bench.get_node("show").connect("pressed", self, "_on_show_pressed")

func _on_show_pressed():
	image = noise.map_to_image(size, AnlNoise.SEAMLESS_NONE, noise.get_last_index(), map_start, map_end)
	visible = true
	update()
	
func _input(event):
	if event.is_action_pressed("bench"):
		visible = false
	
func _draw():
	texture.create_from_image(image, 0)
	draw_texture(texture, Vector2())
	