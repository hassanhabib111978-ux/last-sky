extends Node3D
signal destroyed
signal health_changed(current: float, maximum: float)

@export var maximum_health := 60.0
@export var move_speed := 2.2
@export var attack_range := 12.0
var health := 60.0
var target: Node3D

func _ready() -> void:
    health = maximum_health

func set_target(value: Node3D) -> void:
    target = value

func take_damage(amount: float) -> void:
    health = maxf(health - amount, 0.0)
    health_changed.emit(health, maximum_health)
    if health <= 0.0:
        destroyed.emit()
        queue_free()

func _physics_process(delta: float) -> void:
    if not target or not is_instance_valid(target):
        return
    var target_position := target.global_position + Vector3.UP * 1.0
    if global_position.distance_to(target_position) > attack_range:
        global_position = global_position.move_toward(target_position, move_speed * delta)
    look_at(target_position, Vector3.UP)
