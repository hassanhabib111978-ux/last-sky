extends CharacterBody3D
class_name ScoutDrone

signal damaged(amount: float, remaining: float)
signal destroyed
signal loot_dropped(position: Vector3)

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
var role := "HUNTER"
var tactical_target := Vector3.ZERO
var tactical_timer := 0.0
var strafe_sign := 1.0
var last_player_position := Vector3.ZERO

func _ready() -> void:
    health = max_health
    motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
    base_height = global_position.y
    visual = get_node_or_null("Visual") as MeshInstance3D

func set_target(node: Node3D) -> void:
    target = node
    last_player_position = node.global_position if node else Vector3.ZERO
    var seed_value := int(abs(global_position.x * 13.0 + global_position.z * 7.0))
    role = ["HUNTER", "FLANKER", "OVERWATCH"][seed_value % 3]
    strafe_sign = -1.0 if seed_value % 2 == 0 else 1.0

func _physics_process(delta: float) -> void:
    if dead or not is_instance_valid(target):
        return

    attack_cooldown = maxf(attack_cooldown - delta, 0.0)
    tactical_timer -= delta
    if tactical_timer <= 0.0:
        tactical_timer = 1.6
        tactical_target = _choose_tactical_position()
        last_player_position = target.global_position

    var to_target := target.global_position - global_position
    var distance := to_target.length()
    var horizontal_to_player := Vector3(to_target.x, 0.0, to_target.z)
    var desired := tactical_target - global_position
    desired.y = 0.0

    # The Scout uses different positions around the city instead of always charging directly.
    if desired.length() > 0.8:
        velocity = desired.normalized() * move_speed
    else:
        velocity = Vector3.ZERO

    var desired_y := base_height + sin(Time.get_ticks_msec() * 0.004) * 0.18
    velocity.y = (desired_y - global_position.y) * 2.5
    move_and_slide()

    if horizontal_to_player.length() > 0.05:
        look_at(global_position + horizontal_to_player, Vector3.UP)

    if distance <= attack_range and attack_cooldown <= 0.0 and _has_line_of_sight():
        _attack_player()
        attack_cooldown = attack_interval

func _choose_tactical_position() -> Vector3:
    var player_pos := target.global_position
    var away := (global_position - player_pos)
    away.y = 0.0
    if away.length() < 0.1:
        away = Vector3.FORWARD
    away = away.normalized()

    var side := Vector3(-away.z, 0.0, away.x) * strafe_sign
    var role_offset := Vector3.ZERO

    if role == "HUNTER":
        # Close pressure: keep the player moving but do not collide with them.
        role_offset = away * 5.8 + side * 2.5
    elif role == "FLANKER":
        # Move to the player's side/rear, creating crossfire angles.
        role_offset = side * 8.0 + away * 2.0
    else:
        # Overwatch stays farther away and changes angle periodically.
        role_offset = away * 11.0 + side * 5.0

    var candidate := player_pos + role_offset
    # Keep tactical positions inside the playable city perimeter.
    candidate.x = clamp(candidate.x, -32.0, 32.0)
    candidate.z = clamp(candidate.z, -32.0, 32.0)
    candidate.y = base_height
    return candidate

func _has_line_of_sight() -> bool:
    if not is_instance_valid(target):
        return false
    var space_state := get_world_3d().direct_space_state
    var origin := global_position
    var target_position := target.global_position
    var query := PhysicsRayQueryParameters3D.create(origin, target_position)
    query.exclude = [self]
    var hit := space_state.intersect_ray(query)
    if hit.is_empty():
        return true
    return hit.get("collider") == target

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
    loot_dropped.emit(global_position)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.22)
    tween.tween_property(self, "rotation_degrees", rotation_degrees + Vector3(0, 420, 180), 0.32)
    tween.chain().tween_callback(queue_free)
