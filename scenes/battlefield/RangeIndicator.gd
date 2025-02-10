extends Node2D

var radius: float

func _init(r: float):
	radius = r

func _draw():
	# Draw filled circle with low opacity
	draw_circle(Vector2.ZERO, radius, Color(0.3, 0.3, 1.0, 0.1))
	# Draw circle outline
	var points = 64  # More points for smoother circle
	for i in range(points):
		var angle_from = i * TAU / points
		var angle_to = (i + 1) * TAU / points
		draw_arc(Vector2.ZERO, radius, angle_from, angle_to, 1, Color(0.3, 0.3, 1.0, 0.5), 2.0) 