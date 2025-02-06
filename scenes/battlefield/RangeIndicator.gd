extends Node2D

var radius: float = 0

func _init(r: float):
	radius = r

func _draw():
	# Draw filled circle with low opacity
	draw_circle(Vector2.ZERO, radius, Color(1, 0, 0, 0.2))
	
	# Draw solid circle outline
	draw_arc(Vector2.ZERO, radius, 0, 2 * PI, 64, Color(1, 0, 0, 0.8), 3.0) 