extends RigidBody3D


@export var engine_power: float = 2

var gas_input: float = 0
var steering_input: float = 0


func _process(delta: float) -> void:
	gas_input = Input.get_axis("reverse", "accelerate")
	steering_input = Input.get_axis("turn_right", "turn_left")
