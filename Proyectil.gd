extends Area2D

# --- CONFIGURACIÓN ---
@export var velocidad = 600.0
@export var distancia_deteccion = 85.0 
# NUEVA VARIABLE: Controla qué tan pegadas quedan al chocar
@export var separacion_al_pegar = 45.0 

# --- VARIABLES DE ESTADO ---
var tipo_color : int = 0 
var pegada : bool = false

var imagenes_burbujas = [
	preload("res://Sprites/burbuja_roja.png"),
	preload("res://Sprites/burbuja_naranja.png"),
	preload("res://Sprites/burbuja_verde.png")
]

func _ready():
	if has_node("Sprite2D"):
		$Sprite2D.texture = imagenes_burbujas[tipo_color]
		$Sprite2D.modulate = Color.WHITE 
	area_entered.connect(_on_area_entered)

func _process(delta):
	if not pegada:
		position.x += velocidad * delta
		if position.x > 1180:
			fijar_burbuja()

func _on_area_entered(area):
	# Si chocamos con otra burbuja que ya esté "pegada"
	if area.is_in_group("burbujas") and area.pegada and not pegada:
		# USAMOS LA NUEVA VARIABLE AQUÍ
		global_position.x = area.global_position.x - separacion_al_pegar 
		fijar_burbuja()

func fijar_burbuja():
	if pegada: return 
	pegada = true
	add_to_group("burbujas")
	comprobar_combinacion()

func comprobar_combinacion():
	var coinciden = [self]
	var por_revisar = [self]
	
	while por_revisar.size() > 0:
		var actual = por_revisar.pop_back()
		for otra in get_tree().get_nodes_in_group("burbujas"):
			if otra not in coinciden and otra.tipo_color == self.tipo_color:
				if actual.global_position.distance_to(otra.global_position) < distancia_deteccion:
					coinciden.append(otra)
					por_revisar.append(otra)
	
	if coinciden.size() >= 3:
		for b in coinciden:
			b.explotar()

func explotar():
	queue_free()
