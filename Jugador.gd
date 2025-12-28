extends CharacterBody2D

# --- uSABLE VARIABLES ---
# @export makes a variable visible and usable
@export var speed: float = 400.0
@export var projectile_scene : PackedScene = preload("res://Proyectil.tscn")

# MUSIC RESOURCES
@export var track_1 : AudioStream = preload("res://Music/level_music1.wav")
@export var track_2 : AudioStream = preload("res://Music/level_music2.wav")

# SHOOT ANGLES
@export var angulo_tiro := 0.0        # en grados
@export var velocidad_angulo := 90.0  # grados por segundo
@export var angulo_min := -75.0
@export var angulo_max := 75.0



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
	# We can't move if the game hasn't started
	if not is_game_started:
		return

	var direction = 0
	if Input.is_key_pressed(KEY_W): direction -= 1
	if Input.is_key_pressed(KEY_S): direction += 1

	# VERTICAL MOVEMENT
	velocity.y = direction * speed
	move_and_slide()

	# To make the character unable to leave the active screen
	var screen_height = get_viewport_rect().size.y
	var half_height = $CollisionShape2D.shape.extents.y

	global_position.y = clamp(
		global_position.y,
		half_height,
		screen_height - half_height
	)
	
		# --- CONTROL DEL ÁNGULO DE TIRO ---
	var delta_angulo = 0.0
	if Input.is_key_pressed(KEY_A):
		delta_angulo += 1
	if Input.is_key_pressed(KEY_D):
		delta_angulo -= 1

	angulo_tiro += delta_angulo * velocidad_angulo * _delta
	angulo_tiro = clamp(angulo_tiro, angulo_min, angulo_max)

	# Rotamos el punto de disparo (visual)
	$PuntoDisparo.rotation_degrees = angulo_tiro


# --- 4. SHOOTING SYSTEM ---
func _on_timer_disparo_timeout():
	shoot()

func shoot():
	if is_game_started:
		var p = projectile_scene.instantiate()
		p.color_type = current_color_type

		# Posición inicial
		p.global_position = $PuntoDisparo.global_position

		# Dirección según ángulo
		var dir = Vector2.RIGHT.rotated(deg_to_rad(angulo_tiro))
		p.direction = dir   # ← el proyectil debe usar esto

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
