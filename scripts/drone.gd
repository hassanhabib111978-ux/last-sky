extends CharacterBody3D
class_name ScoutDrone

signal damaged(amount: float, remaining: float)
signal destroyed

@export var max_health := 60.0
@export var move_speed := 2.8
@export var attack_range := 10.0
@export var stop_distance := 5.5
@export var attack_damage := 8.0
@export var attack_interval := 1.4
@export var hover_height := 2.5

var health := 60.0
var target: Node3D
var attack_cooldown := 0.0
var dead := false
var base_height := 2.5
var visual: MeshInstance3D

func _ready() -> void:
    health = max_health
    motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
    base_height = global_position.y
    visual = get_node_or_null("Visual") as MeshInstance3D

func set_target(node: Node3D) -> void:
    target = node

func _physics_process(delta: float) -> void:
    if dead or not is_instance_valid(target):
        return

    attack_cooldown = maxf(attack_cooldown - delta, 0.0)

    var to_target := target.global_position - global_position
    var distance := to_target.length()

    # Keep the Scout airborne while moving toward the player.
    var desired_y := base_height + sin(Time.get_ticks_msec() * 0.004) * 0.18
    var horizontal := Vector3(to_target.x, 0.0, to_target.z)

    if horizontal.length() > stop_distance:
        velocity = horizontal.normalized() * move_speed
    elif horizontal.length() < stop_distance - 0.8:
        velocity = -horizontal.normalized() * move_speed * 0.55
    else:
        velocity = Vector3.ZERO

    velocity.y = (desired_y - global_position.y) * 2.5
    move_and_slide()

    if horizontal.length() > 0.05:
        look_at(global_position + horizontal, Vector3.UP)

    if distance <= attack_range and attack_cooldown <= 0.0:
        _attack_player()
        attack_cooldown = attack_interval

func _attack_player() -> void:
    if target.has_method("take_damage"):
        target.take_damage(attack_damage)

func take_damage(amount: float) -> void:
    if dead:
        return
    health = maxf(health - amount, 0.0)
    damaged.emit(amount, health)
    _flash_damage()
    if health <= 0.0:
        _die()

func _flash_damage() -> void:
    if not visual:
        return
    var material := visual.material_override as StandardMaterial3D
    if material:
        material.emission_enabled = true
        material.emission = Color(1.0, 0.18, 0.08)
        material.emission_energy_multiplier = 3.0
        get_tree().create_timer(0.07).timeout.connect(_clear_damage_flash)

func _clear_damage_flash() -> void:
    if dead or not visual:
        return
    var material := visual.material_override as StandardMaterial3D
    if material:
        material.emission_enabled = false

func _die() -> void:
    dead = true
    velocity = Vector3.ZERO
    destroyed.emit()
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.22)
    tween.tween_property(self, "rotation_degrees", rotation_degrees + Vector3(0, 420, 180), 0.32)
    tween.chain().tween_callback(queue_free)
