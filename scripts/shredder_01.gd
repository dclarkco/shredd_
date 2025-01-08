# Shreda shredder_01 | Paper shredder

extends RigidBody2D

# Constants
const MOVE_FORCE = 12000.0  # Increased force to test movement
const ROTATION_DAMPING = 0.1  # Lower damping for rotation
const GRAVITY_SCALE = 100.0  # Increased gravity scale
const RAYCAST_LENGTH = 15.0  # Length for raycasting to detect slopes
const GROUND_DETECTION_OFFSET = 10.0  # Offset from the character for raycast

# Variables
var is_in_air = false  # To track if snowboarder is in the air
var slope_normal = Vector2.UP  # Default slope normal
@onready var animated_sprite = $AnimatedSprite2D  # Reference to AnimatedSprite2D

func _integrate_forces(state: PhysicsDirectBodyState2D):
	# Get the current velocity
	var current_velocity = state.get_linear_velocity()

	# Check for ground contacts
	var contacts = state.get_contact_count()
	if (contacts >= 1):
		is_in_air = false
	elif (contacts == 0):
		is_in_air = true

	# Handle player input for movement and sprite flipping (on ground)
	var input_direction = 0
	if Input.is_action_pressed("right"):
		input_direction = 1
	elif Input.is_action_pressed("left"):
		input_direction = -1

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
			slope_normal = slope_normal.lerp(detected_normal, 0.1)  # Adjust 0.1 for smoothing

		# Apply movement force (on the ground)
		var forward_direction = Vector2.RIGHT.rotated(rotation)
		var movement_force = forward_direction * input_direction * MOVE_FORCE
		state.apply_central_force(movement_force)

	elif is_in_air:
		if input_direction != 0:
			# Apply torque for rotation in the air
			var torque = input_direction * (MOVE_FORCE / 12)
			apply_torque_impulse(torque)

	# Debug: Visualize ground contact detection and ground state
	print("Contacts: " + str(contacts) + ", Airtime?__: " + str(is_in_air))

	# Rotate the snowboarder based on velocity
	if current_velocity.length() > 1:
		var desired_rotation = current_velocity.angle()
		rotation = lerp_angle(rotation, desired_rotation, ROTATION_DAMPING)
		
func _on_head_hit_ground(body):
	if body.is_in_group("ground"):
		# Reset the snowboarder’s position when head hits the ground
		position = Vector2(-150, -10)
		rotation = 0.0
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
		print("Head hit the ground, resetting position!")
