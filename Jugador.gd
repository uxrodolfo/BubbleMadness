extends CharacterBody2D

# --- 1. Prueba xd ---
@export var speed: float = 400.0
@export var projectile_scene : PackedScene = preload("res://Proyectil.tscn")

# MUSIC RESOURCES
@export var track_1 : AudioStream = preload("res://Music/level_music1.wav")
@export var track_2 : AudioStream = preload("res://Music/level_music2.wav")

# BUBBLE SYSTEM VISUALS
var bubble_images = [
	preload("res://Sprites/burbuja_roja.png"),
	preload("res://Sprites/burbuja_naranja.png"),
	preload("res://Sprites/burbuja_verde.png")
]
var current_color_type: int = 0
var next_color_type: int = 0

# GAME STATE
var is_game_started : bool = false

# --- 2. INITIALIZATION ---
func _ready():
	is_game_started = false
	$TimerDisparo.stop()
	
	prepare_initial_colors()
	
	# Hide visuals until GO!
	if has_node("BurbujaCargada"): $BurbujaCargada.visible = false
	if has_node("BurbujaPreview"): $BurbujaPreview.visible = false
	
	start_intro_sequence()

func prepare_initial_colors():
	current_color_type = randi() % 3
	next_color_type = randi() % 3
	update_bubble_visuals()

func update_bubble_visuals():
	if has_node("BurbujaCargada"):
		$BurbujaCargada.texture = bubble_images[current_color_type]
	if has_node("BurbujaPreview"):
		$BurbujaPreview.texture = bubble_images[next_color_type]

# --- 3. GAMEPLAY LOGIC ---
func start_intro_sequence():
	var label = get_node("%ContadorLabel")
	if label:
		label.text = "3"
		await get_tree().create_timer(1.0).timeout
		label.text = "2"
		await get_tree().create_timer(1.0).timeout
		label.text = "1"
		await get_tree().create_timer(1.0).timeout
		label.text = "GO!"
		
		pick_and_play_music() # Llama a la función de abajo
		
		await get_tree().create_timer(0.5).timeout
		label.text = "" 
		
		if has_node("BurbujaCargada"): $BurbujaCargada.visible = true
		if has_node("BurbujaPreview"): $BurbujaPreview.visible = true
		
		is_game_started = true
		$TimerDisparo.start()

func _process(_delta):
	if is_game_started and has_node("BurbujaCargada"):
		var pulse = 1.5 + sin(Time.get_ticks_msec() * 0.008) * 0.075
		$BurbujaCargada.scale = Vector2(pulse, pulse)

func _physics_process(_delta):
	# Si no ha empezado el juego, no permitimos movimiento
	if not is_game_started:
		return

	var direction = 0
	if Input.is_key_pressed(KEY_W): direction -= 1
	if Input.is_key_pressed(KEY_S): direction += 1
	
	# Aquí usamos 'speed'. Asegúrate de que no esté en 0 en el Inspector.
	velocity.y = direction * speed
	move_and_slide()

# --- 4. SHOOTING SYSTEM ---
func _on_timer_disparo_timeout():
	shoot()

func shoot():
	if is_game_started:
		var p = projectile_scene.instantiate()
		p.color_type = current_color_type 
		p.global_position = $PuntoDisparo.global_position
		get_tree().root.add_child(p)
		
		current_color_type = next_color_type
		next_color_type = randi() % 3
		update_bubble_visuals()

# --- 5. AUDIO SYSTEM (The missing piece) ---
func pick_and_play_music():
	var player = get_node_or_null("%ReproductorMusica")
	if player:
		var playlist = [track_1, track_2]
		var choice = randi() % 2
		player.stream = playlist[choice]
		player.play()
	else:
		print("Error: No se encontró el Reproductor de Música")
