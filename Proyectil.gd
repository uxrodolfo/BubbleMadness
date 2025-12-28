extends Area2D

# --- CONFIGURATION ---
@export var speed: float = 300.0
@export var acceleration: float = 600.0
# SUBIMOS ESTE VALOR: 115 es ideal para burbujas grandes en diagonal
@export var detection_distance: float = 115.0 
@export var stick_offset: float = 50.0 

# --- STATE VARIABLES ---
var direction: Vector2 = Vector2.RIGHT
var color_type: int = 0
var is_stuck: bool = false

var bubble_images = [
	preload("res://Sprites/burbuja_roja.png"),
	preload("res://Sprites/burbuja_naranja.png"),
	preload("res://Sprites/burbuja_verde.png")
]

func _ready():
	if has_node("Sprite2D"):
		$Sprite2D.texture = bubble_images[color_type]
		$Sprite2D.modulate = Color.WHITE
	area_entered.connect(_on_area_entered)

func _process(delta):
	if not is_stuck:
		speed += acceleration * delta
		global_position += direction.normalized() * speed * delta
		
		# Anclaje a la derecha (Wall)
		if position.x > 1180:
			stick_bubble()

func _on_area_entered(area):
	if area.is_in_group("bubbles") and area.is_stuck and not is_stuck:
		# AJUSTE: Si chocamos en diagonal, nos pegamos un poco más
		# para compensar la distancia visual
		var distance_y = abs(global_position.y - area.global_position.y)
		
		if distance_y > 30: # Es un choque esquinado/diagonal
			global_position.x = area.global_position.x - (stick_offset * 0.7)
		else: # Es un choque más frontal
			global_position.x = area.global_position.x - stick_offset
			
		stick_bubble()

func stick_bubble():
	if is_stuck: return 
	is_stuck = true
	add_to_group("bubbles")
	check_match()

func check_match():
	var matching_bubbles = [self]
	var to_check = [self]
	
	while to_check.size() > 0:
		var current = to_check.pop_back()
		for other in get_tree().get_nodes_in_group("bubbles"):
			if other not in matching_bubbles and other.color_type == self.color_type:
				# Aquí es donde el radar de 115px salvará la conexión diagonal
				if current.global_position.distance_to(other.global_position) < detection_distance:
					matching_bubbles.append(other)
					to_check.append(other)
	
	if matching_bubbles.size() >= 3:
		for b in matching_bubbles:
			b.explode()
		call_deferred("check_for_floating_bubbles")

func check_for_floating_bubbles():
	var all_bubbles = get_tree().get_nodes_in_group("bubbles")
	var connected_to_wall = []
	var stack = []
	
	# PUNTO CRÍTICO: Asegúrate de que este número (1150) sea donde 
	# realmente están las burbujas que tocan la pared.
	for b in all_bubbles:
		if b.position.x > 1140: 
			connected_to_wall.append(b)
			stack.append(b)
	
	while stack.size() > 0:
		var current = stack.pop_back()
		for other in all_bubbles:
			if other not in connected_to_wall:
				if current.global_position.distance_to(other.global_position) < detection_distance:
					connected_to_wall.append(other)
					stack.append(other)
	
	for b in all_bubbles:
		if b not in connected_to_wall:
			b.explode()

func explode():
	queue_free()
