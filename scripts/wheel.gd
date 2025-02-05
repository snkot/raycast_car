extends RayCast3D

@export var suspension_target: float = 0.5
@export var spring_strength: float = 20
@export var spring_damper: float = 2
@export var wheel_radius: float = 0.33
@export var is_motorized: bool = true

@export var wheel_grip: float = 2
@export var steering_angle: float = 30
@export var is_steerable: bool = false

@onready var CAR =  get_parent().get_parent()

var last_spring_length: float = 0


func _physics_process(delta: float) -> void:
	if is_colliding():
		var ray_collision = get_collision_point()
		_drag_force(ray_collision)
		_lateral_force(delta, ray_collision)
		_steering(delta)
		_suspension(delta, ray_collision)
		_acceleration(ray_collision)


func _steering(delta: float) -> void:
	if not is_steerable:
		return
	
	var steering_rotation = steering_angle * CAR.steering_input
	
	if steering_rotation != 0:
		var angle = clamp(rotation.y + steering_rotation, -steering_angle, steering_angle)
		var new_rotation = angle * delta
		rotation.y = lerp(rotation.y, new_rotation, 0.3)
	else:
		rotation.y = lerp(rotation.y, 0.0, 0.3)


func _acceleration(contact_point: Vector3) -> void:
	if not is_motorized:
		return
	
	var accel_dir = global_basis.z
	var accel_force = CAR.engine_power * CAR.gas_input
	var force_point = _get_wheel_origin(contact_point)
	
	CAR.apply_force(accel_dir * accel_force, force_point - CAR.global_position)


func _suspension(delta: float, contact_point: Vector3) -> void:
	var suspension_dir = global_basis.y
	
	var ray_origin = global_position
	var ray_distance = contact_point.distance_to(ray_origin)
	
	var spring_length = clamp(ray_distance - wheel_radius, 0, suspension_target)
	var spring_force = spring_strength * (suspension_target - spring_length)
	var spring_velocity = (last_spring_length - spring_length) / delta
	
	var damper_force = spring_damper * spring_velocity
	
	var suspension_force = basis.y * (spring_force + damper_force)
	var force_point = _get_wheel_origin(contact_point)
	
	last_spring_length = spring_length
	
	CAR.apply_force(suspension_dir * suspension_force, force_point - CAR.global_position)


## Prevent the wheel from sliding in undesire X direction
func _lateral_force(delta: float, contact_point: Vector3) -> void:
	var direction: Vector3 = global_basis.x
	var wheel_velocity: Vector3 = _get_wheel_velocity(global_position)
	var lateral_velocity = direction.dot(wheel_velocity)
	
	var desire_velocity_change: float = -lateral_velocity * wheel_grip
	var x_force = desire_velocity_change / delta
	
	CAR.apply_force(direction * x_force, contact_point - CAR.global_position)


## Simulate drag force for car body
func _drag_force(contact_point: Vector3) -> void:
	var direction: Vector3 = global_basis.z
	var wheel_velocity: Vector3 = _get_wheel_velocity(global_position)
	var drag_velocity = direction.dot(wheel_velocity) * CAR.mass / 10
	
	CAR.apply_force(-direction * drag_velocity, contact_point - CAR.global_position)


func _get_wheel_origin(contact_point: Vector3) -> Vector3:
	var origin = Vector3(contact_point.x, contact_point.y + wheel_radius, contact_point.z)
	return origin


func _get_wheel_velocity(wheel_position: Vector3) -> Vector3:
	return CAR.linear_velocity + CAR.angular_velocity.cross(wheel_position - CAR.global_position)
