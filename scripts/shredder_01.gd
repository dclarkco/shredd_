# shredder_01 | Paper shredder

extends RigidBody2D

# Constants
const MOVE_FORCE = 6700.0  # Increased force to test movement
const ROTATION_DAMPING = 0.1  # Lower damping for rotation
const GRAVITY_SCALE = 1.0  # Increased gravity scale
const RAYCAST_LENGTH = 1000.0  # Length for raycasting to detect slopes
const GROUND_DETECTION_OFFSET = 2.0  # Offset from the character for raycast

# Variables
var is_in_air = false  # To track if snowboarder is in the air
var was_in_air = false
var slope_normal = Vector2.UP  # Default slope normal


@onready var animated_sprite = $AnimatedSprite2D  # Reference to AnimatedSprite2D
var current_animation = ""  # Tracks the currently playing animation
var new_animation = ""     # Track animation change per physics frame
var movement_multipler = 1
var anim_frame = 0

func _ready():
	var level_name = get_tree().current_scene.name

	# Example: Configure boundaries based on level
	if level_name == "small_pipe":
		configure_camera_boundaries(Rect2(0, 0, 2000, 1000))
	elif level_name == "medium_pipe":
		configure_camera_boundaries(Rect2(0, 0, 480, 480))
	else:
		configure_camera_boundaries(Rect2(0, 0, 1280, 800))


func configure_camera_boundaries(bounds):
	$Camera2D.limit_left = bounds.position.x
	$Camera2D.limit_top = bounds.position.y
	$Camera2D.limit_right = bounds.position.x + bounds.size.x
	$Camera2D.limit_bottom = bounds.position.y + bounds.size.y
	
func _integrate_forces(state: PhysicsDirectBodyState2D):
	anim_frame = (anim_frame + 1)%120
	
	# Get the current velocity
	var current_velocity = state.get_linear_velocity()
	
	# Handle player input for movement and sprite flipping (on ground)
	var input_direction = 0
	if Input.is_action_pressed("right"):
		input_direction = 1
	elif Input.is_action_pressed("left"):
		input_direction = -1
		
	# Check for ground contacts
	var contacts = state.get_contact_count()
	if (contacts == 1):
		is_in_air = false
		new_animation = "r_butter"
	elif (contacts >=2):
		is_in_air = false
		new_animation = "idle (sliding)"
		if was_in_air:
			new_animation = "landing"
			movement_multipler = 2
		elif Input.is_action_pressed("f_grab"):
			new_animation = "r_butter"
		elif Input.is_action_pressed("r_grab"):
			new_animation = "f_butter"
		elif Input.is_action_pressed("crouch"):
			new_animation = "landing"
			movement_multipler = 1.2
	elif (contacts == 0):
		is_in_air = true

	if input_direction != 0:
		# Flip the sprite based on direction
		animated_sprite.flip_h = (input_direction == -1)

	if not is_in_air:
		# Handle raycasting for smooth terrain detection when on the ground
		var raycast_start = position
		var raycast_end = position + Vector2.DOWN * (RAYCAST_LENGTH + GROUND_DETECTION_OFFSET)  # Raycast down

		# Raycast to detect the ground and adjust slope normal
		var space_state = get_world_2d().direct_space_state
		var ray_params = PhysicsRayQueryParameters2D.new()
		ray_params.from = raycast_start
		ray_params.to = raycast_end

		var collision = space_state.intersect_ray(ray_params)
		if collision:
			var detected_normal = collision["normal"]
			# Interpolate slope normal based on raycast detection to smooth out bumps
			slope_normal = slope_normal.lerp(detected_normal, 0.67)  # Adjust 0.1 for smoothing

		# Apply movement force (on the ground)
		var forward_direction = Vector2.RIGHT.rotated(rotation)
		var movement_force = forward_direction * input_direction * MOVE_FORCE * movement_multipler
		state.apply_central_force(movement_force)
	
	elif is_in_air:
		movement_multipler = 1
		if input_direction != 0:
			# Apply torque for rotation in the air
			var torque = input_direction * (MOVE_FORCE / 6)
			apply_torque_impulse(torque)
		if Input.is_action_pressed("f_grab"):
			new_animation = "f_grab"
		elif Input.is_action_pressed("r_grab"):
			new_animation = "r_grab"
		else:
			new_animation = "airtime"
				
	# Debug: Visualize ground contact detection and ground state
	print("Contacts: " + str(contacts) + ", Airtime?__: " + str(is_in_air) + "Animation?__:" +str(current_animation), + slope_normal)

	# Rotate the snowboarder based on velocity
	if current_velocity.length() > 1:
		var desired_rotation = current_velocity.angle()
		rotation = lerp_angle(rotation, desired_rotation, ROTATION_DAMPING)
		
	if anim_frame%24 == 0:
		if new_animation != current_animation:
			current_animation = new_animation
		was_in_air = is_in_air
		$AnimatedSprite2D.play(current_animation)  # Replace with $AnimationPlayer.play(name) if using AnimationPlayer
		
		
func _on_head_hit_ground(body):
	if body.is_in_group("ground"):
		# Reset the snowboarder’s position when head hits the ground
		position = Vector2(25, 325)
		rotation = 0.0
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
		print("Head hit the ground, resetting position!")
		
## Variables (Smarter animation func) v
#var animation_buffer_timer = false  # Tracks if animation can change
#
#func _ready():
	## Connect the timer's timeout signal
	#$Timer.connect("timeout", self, "_on_animation_buffer_timeout")
#
#func _physics_process(delta):
	## Example movement logic
	#if not animation_buffer_timer:
		#if is_on_floor():
			#if velocity.x != 0:
				#change_animation("run")
			#else:
				#change_animation("idle")
		#else:
			#change_animation("jump")
#
## Change animation only if the timer allows it
#func change_animation(new_animation):
	#if $AnimationPlayer.current_animation != new_animation:
		#$AnimationPlayer.play(new_animation)
		#animation_buffer_timer = true  # Block further changes
		#$Timer.start()  # Start the buffer timer
#
## Reset the buffer when the timer times out
#func _on_animation_buffer_timeout():
	#animation_buffer_timer = false
