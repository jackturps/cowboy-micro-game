extends Node2D

@export var parent: Node2D

const length = 150

@onready var prev_pos = position

func _draw():
	draw_circle(Vector2.ZERO, 10.0, Color.RED)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = parent.position + Vector2.RIGHT * length
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	"""
	TODO: Need to constrain after applying forces but preserve the excess
	angular momentum?
	"""
	var speed = position - prev_pos
	prev_pos = position
	
	position += speed + Game.gravity * delta * delta
	
	var parent_diff = position - parent.position
	var parent_dist = parent_diff.length()
	if parent_dist > 0.0:
		position = parent.position + parent_diff / parent_dist * length
