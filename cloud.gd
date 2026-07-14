extends Sprite2D

var speed = randf_range(10, 30)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position.x = randf_range(-1000, 1000)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x += speed * delta
	pass
