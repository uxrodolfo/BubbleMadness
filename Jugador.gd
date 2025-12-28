extends CharacterBody2D

# 1. SIEMPRE LAS VARIABLES AL PRINCIPIO (Arriba de todo)
@export var velocidad = 400.0
@export var escena_proyectil : PackedScene = preload("res://Proyectil.tscn")

# Música (Asegúrate de que los nombres de archivo sean exactos)
@export var cancion_1 : AudioStream = preload("res://Music/level_music1.wav")
@export var cancion_2 : AudioStream = preload("res://Music/level_music2.wav")

var juego_iniciado : bool = false

func _ready():
	juego_iniciado = false
	$TimerDisparo.stop()
	iniciar_secuencia_inicio()

func iniciar_secuencia_inicio():
	var label = get_node("%ContadorLabel")
	if label:
		label.text = "3"
		await get_tree().create_timer(1.0).timeout
		label.text = "2"
		await get_tree().create_timer(1.0).timeout
		label.text = "1"
		await get_tree().create_timer(1.0).timeout
		label.text = "¡GO!"
		
		elegir_y_reproducir_musica()
		
		await get_tree().create_timer(0.5).timeout
		label.text = ""
		
		juego_iniciado = true
		$TimerDisparo.start()

func _physics_process(_delta):
	# Si el juego no ha arrancado, no hacemos nada
	if not juego_iniciado:
		return

	# Movimiento vertical (W/S)
	var direccion = 0
	if Input.is_key_pressed(KEY_W): direccion -= 1
	if Input.is_key_pressed(KEY_S): direccion += 1
	
	# Aquí es donde fallaba: direccion (int) * velocidad (float/int)
	velocity.y = direccion * velocidad
	move_and_slide()

func _on_timer_disparo_timeout():
	disparar()

func disparar():
	if juego_iniciado:
		var p = escena_proyectil.instantiate()
		p.tipo_color = randi() % 3
		p.global_position = $PuntoDisparo.global_position
		get_tree().root.add_child(p)

func elegir_y_reproducir_musica():
	var reproductor = get_node("%ReproductorMusica")
	if reproductor:
		var playlist = [cancion_1, cancion_2]
		var eleccion = randi() % 2
		reproductor.stream = playlist[eleccion]
		reproductor.play()
