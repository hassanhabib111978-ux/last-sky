extends Node3D

# LAST SKY — first playable foundation.
# This is intentionally small and testable; production assets and systems come later.

var player: CharacterBody3D
var camera: Camera3D
var drone: CharacterBody3D
var player_health := 100.0
var drone_angle := 0.0
var speed := 5.0
var touch_move := Vector2.ZERO
var fire_button: Button
var drone_health := 60.0
var move_touch_id := -1
var aim_touch_id := -1
var joystick_center := Vector2.ZERO
var aim_sensitivity := 0.012
var camera_pitch := -14.0
var joystick_base: ColorRect
var joystick_knob: ColorRect
var fire_cooldown := 0.0
var fire_interval := 0.22
var crosshair: Label
var ammo := 12
var magazine_size := 12
var reserve_ammo := 60
var reload_time := 1.25
var reload_left := 0.0
var weapon_label: Label
var loot_count := {"AMMO": 0, "BATTERY": 0, "PARTS": 0}
var loot_label: Label
var drone_spawn_points: Array[Vector3] = []
var wave_number := 0
var wave_alive := 0
var wave_timer := 0.0
var next_wave_delay := 8.0
var wave_active := false

func _ready() -> void:
    _build_world()
    _build_player()
    # Wave spawns are the only combat enemy source; no legacy singleton drone.
    _build_hud()
    _build_mobile_controls()
    _start_next_wave()

func _build_world() -> void:
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.025, 0.035, 0.05)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.35, 0.4, 0.5)
    env.ambient_light_energy = 0.7
    environment.environment = env
    add_child(environment)

    _build_city_block()

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55, -25, 0)
    light.light_energy = 1.2
    add_child(light)

    var ground := MeshInstance3D.new()
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(80, 80)
    ground.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.07, 0.08, 0.09)
    material.roughness = 0.92
    ground.material_override = material
    add_child(ground)

func _build_city_block() -> void:
    var city := Node3D.new()
    city.name = "AbandonedCity"
    add_child(city)

    _make_building(city, Vector3(-15, 4, -18), Vector3(12, 8, 10), 2)
    _make_building(city, Vector3(16, 5, -24), Vector3(14, 10, 12), 3)
    _make_building(city, Vector3(-20, 3, 8), Vector3(10, 6, 9), 1)
    _make_building(city, Vector3(18, 4, 12), Vector3(12, 8, 10), 2)

    _make_wall(city, Vector3(-4, 1.5, -12), Vector3(12, 3, 1.2))
    _make_wall(city, Vector3(8, 1.2, 2), Vector3(1.2, 2.4, 10))
    _make_wall(city, Vector3(-11, 1.2, 18), Vector3(14, 2.4, 1.2))

    _make_cover(city, Vector3(-2, 0.7, 8), Vector3(4, 1.4, 2))
    _make_cover(city, Vector3(10, 0.7, -6), Vector3(3, 1.4, 3))
    _make_cover(city, Vector3(-10, 0.7, -2), Vector3(3, 1.4, 4))
    _make_war_ruins(city)
    _make_environment_props(city)
    _setup_gameplay_space(city)

func _make_war_ruins(parent: Node3D) -> void:
    # Visual language: contemporary Eastern-European urban war damage.
    _make_damage_facade(parent, Vector3(-15, 7.1, -13.0), Vector3(6.0, 1.8, 0.45), -11.0)
    _make_damage_facade(parent, Vector3(12.0, 8.8, -18.0), Vector3(5.5, 1.5, 0.45), 8.0)
    _make_damage_facade(parent, Vector3(-19.5, 4.8, 12.0), Vector3(4.0, 1.3, 0.4), -7.0)

    _make_cover(parent, Vector3(2, 0.65, -15), Vector3(4.5, 1.3, 1.0))
    _make_cover(parent, Vector3(14, 0.55, 7), Vector3(2.8, 1.1, 1.8))

func _make_damage_facade(parent: Node3D, pos: Vector3, size: Vector3, tilt: float) -> void:
    var slab := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    slab.mesh = mesh
    slab.position = pos
    slab.rotation_degrees.z = tilt
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.18, 0.17, 0.16)
    material.roughness = 1.0
    slab.material_override = material
    parent.add_child(slab)

func _make_building(parent: Node3D, pos: Vector3, size: Vector3, floors: int) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    body.name = "RuinedBuilding"
    parent.add_child(body)

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.10 + floors * 0.015, 0.105, 0.105)
    material.roughness = 0.96

    var shell := MeshInstance3D.new()
    var shell_box := BoxMesh.new()
    shell_box.size = Vector3(size.x * 0.88, size.y * 0.78, size.z * 0.9)
    shell.mesh = shell_box
    shell.position = Vector3(0, -size.y * 0.06, 0)
    shell.material_override = material
    body.add_child(shell)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = shell_box.size
    collision.shape = shape
    collision.position = shell.position
    body.add_child(collision)

    var debris_mat := StandardMaterial3D.new()
    debris_mat.albedo_color = Color(0.13, 0.12, 0.115)
    debris_mat.roughness = 1.0

    for i in range(2):
        var chunk := MeshInstance3D.new()
        var chunk_box := BoxMesh.new()
        chunk_box.size = Vector3(size.x * (0.25 + i * 0.08), size.y * 0.22, size.z * (0.35 + i * 0.05))
        chunk.mesh = chunk_box
        chunk.position = Vector3(
            (-size.x * 0.27) if i == 0 else (size.x * 0.28),
            size.y * 0.43,
            (size.z * 0.12) if i == 0 else (-size.z * 0.16)
        )
        chunk.rotation_degrees = Vector3(0, 0, -7 if i == 0 else 5)
        chunk.material_override = debris_mat
        body.add_child(chunk)

    for i in range(5):
        var rubble := MeshInstance3D.new()
        var rubble_box := BoxMesh.new()
        rubble_box.size = Vector3(0.7 + float(i % 2) * 0.5, 0.35 + float(i % 3) * 0.18, 0.6 + float(i % 2) * 0.35)
        rubble.mesh = rubble_box
        rubble.position = Vector3(
            -size.x * 0.42 + float(i) * size.x * 0.18,
            rubble_box.size.y * 0.5,
            size.z * 0.52 + sin(float(i)) * 0.45
        )
        rubble.rotation_degrees = Vector3(0, float(i) * 31.0, float(i % 2) * 9.0)
        rubble.material_override = debris_mat
        body.add_child(rubble)

    for floor_index in range(floors):
        for window_index in range(3):
            if (floor_index + window_index) % 4 == 0:
                continue
            var window_row := MeshInstance3D.new()
            var window := BoxMesh.new()
            window.size = Vector3(size.x * 0.14, 0.18, 0.05)
            window_row.mesh = window
            window_row.position = Vector3(
                -size.x * 0.28 + window_index * size.x * 0.28,
                -size.y * 0.34 + 1.35 + floor_index * 2.25,
                size.z * 0.455
            )
            var glass := StandardMaterial3D.new()
            glass.albedo_color = Color(0.025, 0.045, 0.05)
            glass.roughness = 0.75
            window_row.material_override = glass
            body.add_child(window_row)



func _setup_gameplay_space(parent: Node3D) -> void:
    # Spawn lanes keep enemies away from the player start while using the existing city cover.
    drone_spawn_points = [
        Vector3(-28, 2.8, -26),
        Vector3(27, 2.8, -27),
        Vector3(-30, 2.8, 24),
        Vector3(28, 2.8, 24),
        Vector3(0, 2.8, -30),
        Vector3(0, 2.8, 28)
    ]
    for point in drone_spawn_points:
        _make_spawn_marker(parent, point)

func _make_spawn_marker(parent: Node3D, pos: Vector3) -> void:
    var marker := MeshInstance3D.new()
    marker.name = "DroneSpawnMarker"
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.16
    mesh.bottom_radius = 0.24
    mesh.height = 0.08
    marker.mesh = mesh
    marker.position = Vector3(pos.x, 0.04, pos.z)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.16, 0.22, 0.24)
    material.roughness = 1.0
    marker.material_override = material
    parent.add_child(marker)

func _start_next_wave() -> void:
    if wave_active or not player:
        return
    wave_number += 1
    wave_active = true
    wave_timer = 0.0
    var count := mini(2 + wave_number, 5)
    for i in range(count):
        var spawn := drone_spawn_points[(wave_number + i) % drone_spawn_points.size()]
        _spawn_combat_drone(spawn)
    var status := get_node("HUD/Status") as Label
    if status:
        status.text = "WAVE %d  •  %d SCOUT DRONES" % [wave_number, count]

func _spawn_combat_drone(spawn_position: Vector3) -> void:
    var enemy := CharacterBody3D.new()
    enemy.name = "ScoutDrone_%d_%d" % [wave_number, wave_alive + 1]
    enemy.position = spawn_position
    var visual := MeshInstance3D.new()
    visual.name = "Visual"
    var sphere := SphereMesh.new()
    sphere.radius = 0.45
    sphere.height = 0.9
    visual.mesh = sphere
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.18, 0.2, 0.24)
    material.metallic = 0.8
    material.roughness = 0.28
    visual.material_override = material
    enemy.add_child(visual)

    var collision := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = 0.5
    collision.shape = shape
    enemy.add_child(collision)
    enemy.set_meta("damage_target", enemy)
    add_child(enemy)
    enemy.set_script(preload("res://scripts/drone.gd"))
    enemy.set_target(player)
    enemy.set_meta("tactical_cover", _get_tactical_cover_positions())
    enemy.connect("loot_dropped", _spawn_loot)
    enemy.connect("destroyed", _on_combat_drone_destroyed)
    wave_alive += 1

func _on_combat_drone_destroyed() -> void:
    wave_alive = maxi(wave_alive - 1, 0)
    if wave_alive == 0:
        wave_active = false
        wave_timer = next_wave_delay
        var status := get_node("HUD/Status") as Label
        if status:
            status.text = "AREA CLEAR  •  NEXT WAVE IN %ds" % int(next_wave_delay)

func _make_environment_props(parent: Node3D) -> void:
    # Low-cost static props: civilian vehicles, utility poles and concrete barriers.
    _make_abandoned_car(parent, Vector3(-6.5, 0.55, -1.5), 18.0, true)
    _make_abandoned_car(parent, Vector3(6.5, 0.55, 15.0), -24.0, false)
    _make_abandoned_car(parent, Vector3(-13.0, 0.55, 15.5), 72.0, true)

    _make_utility_pole(parent, Vector3(-2.0, 0.0, 20.0), 8.0)
    _make_utility_pole(parent, Vector3(9.0, 0.0, 20.0), 10.0)
    _make_utility_pole(parent, Vector3(21.0, 0.0, 3.0), 82.0)

    _make_barrier(parent, Vector3(3.5, 0.45, 11.0), 12.0)
    _make_barrier(parent, Vector3(-5.0, 0.45, -9.0), -8.0)
    _make_barrier(parent, Vector3(12.0, 0.45, -3.0), 88.0)

func _make_abandoned_car(parent: Node3D, pos: Vector3, yaw: float, damaged: bool) -> void:
    var body := StaticBody3D.new()
    body.name = "AbandonedCar"
    body.position = pos
    body.rotation_degrees.y = yaw
    parent.add_child(body)

    var car_mat := StandardMaterial3D.new()
    car_mat.albedo_color = Color(0.16, 0.16, 0.15) if damaged else Color(0.20, 0.22, 0.23)
    car_mat.roughness = 0.88

    var chassis := MeshInstance3D.new()
    var chassis_box := BoxMesh.new()
    chassis_box.size = Vector3(3.4, 0.7, 1.55)
    chassis.mesh = chassis_box
    chassis.position.y = 0.45
    chassis.material_override = car_mat
    body.add_child(chassis)

    var cabin := MeshInstance3D.new()
    var cabin_box := BoxMesh.new()
    cabin_box.size = Vector3(1.75, 0.72, 1.35)
    cabin.mesh = cabin_box
    cabin.position = Vector3(-0.1, 1.0, 0)
    cabin.material_override = car_mat
    body.add_child(cabin)

    var glass_mat := StandardMaterial3D.new()
    glass_mat.albedo_color = Color(0.035, 0.045, 0.05)
    glass_mat.roughness = 0.82

    for side in [-1.0, 1.0]:
        var window := MeshInstance3D.new()
        var window_box := BoxMesh.new()
        window_box.size = Vector3(1.05, 0.34, 0.04)
        window.mesh = window_box
        window.position = Vector3(-0.1, 1.02, side * 0.69)
        window.material_override = glass_mat
        body.add_child(window)

    for x in [-1.15, 1.15]:
        for z in [-0.86, 0.86]:
            var wheel := MeshInstance3D.new()
            var wheel_box := BoxMesh.new()
            wheel_box.size = Vector3(0.58, 0.62, 0.24)
            wheel.mesh = wheel_box
            wheel.position = Vector3(x, 0.38, z)
            wheel.material_override = glass_mat
            body.add_child(wheel)

    if damaged:
        var scorch := MeshInstance3D.new()
        var scorch_box := BoxMesh.new()
        scorch_box.size = Vector3(0.8, 0.05, 1.2)
        scorch.mesh = scorch_box
        scorch.position = Vector3(0.65, 0.82, 0)
        var scorch_mat := StandardMaterial3D.new()
        scorch_mat.albedo_color = Color(0.035, 0.03, 0.028)
        scorch_mat.roughness = 1.0
        scorch.material_override = scorch_mat
        body.add_child(scorch)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(3.5, 1.25, 1.65)
    collision.shape = shape
    collision.position.y = 0.65
    body.add_child(collision)

func _make_utility_pole(parent: Node3D, pos: Vector3, yaw: float) -> void:
    var pole := Node3D.new()
    pole.name = "UtilityPole"
    pole.position = pos
    pole.rotation_degrees.y = yaw
    parent.add_child(pole)

    var wood_mat := StandardMaterial3D.new()
    wood_mat.albedo_color = Color(0.12, 0.105, 0.09)
    wood_mat.roughness = 1.0

    var post := MeshInstance3D.new()
    var post_box := BoxMesh.new()
    post_box.size = Vector3(0.24, 6.5, 0.24)
    post.mesh = post_box
    post.position.y = 3.25
    post.material_override = wood_mat
    pole.add_child(post)

    var arm := MeshInstance3D.new()
    var arm_box := BoxMesh.new()
    arm_box.size = Vector3(2.8, 0.16, 0.16)
    arm.mesh = arm_box
    arm.position = Vector3(0, 6.05, 0)
    arm.material_override = wood_mat
    pole.add_child(arm)

    var insulator_mat := StandardMaterial3D.new()
    insulator_mat.albedo_color = Color(0.28, 0.29, 0.27)
    insulator_mat.roughness = 0.7
    for x in [-1.1, 0.0, 1.1]:
        var insulator := MeshInstance3D.new()
        var cap := BoxMesh.new()
        cap.size = Vector3(0.22, 0.32, 0.22)
        insulator.mesh = cap
        insulator.position = Vector3(x, 6.28, 0)
        insulator.material_override = insulator_mat
        pole.add_child(insulator)

func _has_line_of_sight(from: Vector3, to: Vector3) -> bool:
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 1
    query.exclude = [player.get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    return hit.is_empty()

func _get_tactical_cover_positions() -> Array[Vector3]:
    return [
        Vector3(-8, 2.8, -8), Vector3(8, 2.8, -10),
        Vector3(-12, 2.8, 5), Vector3(11, 2.8, 6),
        Vector3(-2, 2.8, 15), Vector3(3, 2.8, -18)
    ]

func _make_barrier(parent: Node3D, pos: Vector3, yaw: float) -> void:
    var body := StaticBody3D.new()
    body.name = "ConcreteBarrier"
    body.position = pos
    body.rotation_degrees.y = yaw
    parent.add_child(body)

    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(3.0, 0.9, 0.65)
    mesh.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.23, 0.22, 0.20)
    material.roughness = 0.98
    mesh.material_override = material
    body.add_child(mesh)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = box.size
    collision.shape = shape
    body.add_child(collision)

func _make_wall(parent: Node3D, pos: Vector3, size: Vector3) -> void:
    _make_cover(parent, pos, size)

func _make_cover(parent: Node3D, pos: Vector3, size: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    body.name = "Cover"
    parent.add_child(body)

    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.16, 0.15, 0.14)
    material.roughness = 0.95
    mesh.material_override = material
    body.add_child(mesh)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    add_child(player)

    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.height = 1.8
    capsule.radius = 0.35
    body.mesh = capsule
    body.position.y = 0.9
    player.add_child(body)

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.height = 1.8
    shape.radius = 0.35
    collision.shape = shape
    collision.position.y = 0.9
    player.add_child(collision)

    camera = Camera3D.new()
    camera.position = Vector3(0, 1.65, 0.0)
    camera.rotation_degrees = Vector3(-6, 0, 0)
    player.add_child(camera)
    camera.current = true

func _build_drone() -> void:
    drone = CharacterBody3D.new()
    drone.name = "ScoutDrone"
    drone.position = Vector3(0, 2.5, -8)

    var visual := MeshInstance3D.new()
    visual.name = "Visual"
    var sphere := SphereMesh.new()
    sphere.radius = 0.45
    sphere.height = 0.9
    visual.mesh = sphere
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.18, 0.2, 0.24)
    material.metallic = 0.8
    material.roughness = 0.28
    visual.material_override = material
    drone.add_child(visual)

    var collision := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = 0.5
    collision.shape = shape
    drone.add_child(collision)
    drone.set_meta("damage_target", drone)

    add_child(drone)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "HUD"
    add_child(layer)

    var title := Label.new()
    title.text = "LAST SKY  •  SURVIVE THE SWARM"
    title.position = Vector2(32, 24)
    title.add_theme_font_size_override("font_size", 24)
    layer.add_child(title)

    var status := Label.new()
    status.name = "Status"
    status.text = "SCOUT DRONE DETECTED"
    status.position = Vector2(32, 62)
    status.add_theme_font_size_override("font_size", 16)
    layer.add_child(status)

func _build_mobile_controls() -> void:
    var hud := get_node("HUD") as CanvasLayer

    joystick_base = ColorRect.new()
    joystick_base.color = Color(0.08, 0.10, 0.13, 0.62)
    joystick_base.position = Vector2(32, 0)
    joystick_base.size = Vector2(180, 180)
    joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(joystick_base)

    joystick_knob = ColorRect.new()
    joystick_knob.color = Color(0.72, 0.78, 0.86, 0.92)
    joystick_knob.position = Vector2(60, 60)
    joystick_knob.size = Vector2(60, 60)
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joystick_base.add_child(joystick_knob)

    fire_button = Button.new()
    fire_button.text = "FIRE"
    fire_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    fire_button.position = Vector2(-205, -205)
    fire_button.size = Vector2(160, 160)
    fire_button.add_theme_font_size_override("font_size", 28)
    fire_button.pressed.connect(_fire_weapon)
    hud.add_child(fire_button)

    crosshair = Label.new()
    crosshair.text = "+"
    crosshair.set_anchors_preset(Control.PRESET_CENTER)
    crosshair.position = Vector2(-12, -22)
    crosshair.add_theme_font_size_override("font_size", 30)
    crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(crosshair)

    weapon_label = Label.new()
    weapon_label.text = "RIFLE  12 / 60"
    weapon_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    weapon_label.position = Vector2(-240, 28)
    weapon_label.add_theme_font_size_override("font_size", 22)
    weapon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(weapon_label)

    loot_label = Label.new()
    loot_label.text = "LOOT  •  BAT 0  •  PARTS 0"
    loot_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    loot_label.position = Vector2(-360, 62)
    loot_label.add_theme_font_size_override("font_size", 16)
    loot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(loot_label)

    var aim_hint := Label.new()
    aim_hint.text = "DRAG TO AIM"
    aim_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    aim_hint.position = Vector2(-430, -78)
    aim_hint.add_theme_font_size_override("font_size", 14)
    aim_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(aim_hint)

    joystick_center = Vector2(122, get_viewport().size.y - 90)

func collect_loot(loot_type: String, amount: int) -> void:
    if loot_type == "AMMO":
        reserve_ammo += amount
    elif loot_type == "BATTERY":
        loot_count["BATTERY"] += amount
    elif loot_type == "PARTS":
        loot_count["PARTS"] += amount
    loot_count["AMMO"] += amount if loot_type == "AMMO" else 0
    _update_weapon_hud()
    _update_loot_hud()
    var status := get_node("HUD/Status") as Label
    if status:
        status.text = "LOOT COLLECTED  •  %s +%d" % [loot_type, amount]

func _spawn_loot(at_position: Vector3) -> void:
    var roll := randi_range(0, 2)
    var loot_type := ["AMMO", "BATTERY", "PARTS"][roll]
    var amount := [8, 1, 2][roll]
    var loot := Area3D.new()
    loot.name = "LootPickup"
    loot.set_script(preload("res://scripts/loot_pickup.gd"))
    loot.position = at_position + Vector3(0, 0.35, 0)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(0.42, 0.42, 0.42)
    mesh.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.12, 0.65, 0.95)
    material.emission_enabled = true
    material.emission = Color(0.04, 0.3, 0.8)
    material.emission_energy_multiplier = 1.8
    mesh.material_override = material
    loot.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(0.55, 0.55, 0.55)
    collision.shape = shape
    loot.add_child(collision)
    add_child(loot)
    loot.setup(loot_type, amount)

func take_damage(amount: float) -> void:
    player_health = maxf(player_health - amount, 0.0)
    var status := get_node("HUD/Status") as Label
    if status:
        status.text = "PLAYER HIT  •  HP %d" % int(player_health)
    if player_health <= 0.0 and player:
        player.set_physics_process(false)


func _physics_process(delta: float) -> void:
    if not wave_active and wave_timer > 0.0:
        wave_timer = maxf(wave_timer - delta, 0.0)
        if wave_timer <= 0.0:
            _start_next_wave()

    if fire_cooldown > 0.0:
        fire_cooldown = maxf(fire_cooldown - delta, 0.0)
    if reload_left > 0.0:
        reload_left = maxf(reload_left - delta, 0.0)
        if reload_left <= 0.0:
            var needed := magazine_size - ammo
            var loaded := mini(needed, reserve_ammo)
            ammo += loaded
            reserve_ammo -= loaded
            _update_weapon_hud()

    if not player or not player.is_physics_processing():
        return

    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    if input_vector == Vector2.ZERO:
        input_vector = touch_move

    var local_direction := Vector3(input_vector.x, 0.0, input_vector.y)
    var world_direction := player.global_transform.basis * local_direction
    world_direction.y = 0.0
    if world_direction.length() > 1.0:
        world_direction = world_direction.normalized()

    player.velocity.x = world_direction.x * speed
    player.velocity.z = world_direction.z * speed
    player.move_and_slide()

    if Input.is_action_pressed("fire") and fire_button == null:
        _fire_weapon()

func _start_reload() -> void:
    if reload_left > 0.0 or ammo >= magazine_size or reserve_ammo <= 0:
        return
    reload_left = reload_time
    var status := get_node("HUD/Status") as Label
    if status:
        status.text = "RELOADING..."

func _update_weapon_hud() -> void:
    if weapon_label:
        weapon_label.text = "RIFLE  %d / %d" % [ammo, reserve_ammo]

func _update_loot_hud() -> void:
    if loot_label:
        loot_label.text = "LOOT  •  BAT %d  •  PARTS %d" % [loot_count["BATTERY"], loot_count["PARTS"]]

func _fire_weapon() -> void:
    if reload_left > 0.0 or fire_cooldown > 0.0:
        return
    if ammo <= 0:
        _start_reload()
        return
    ammo -= 1
    _update_weapon_hud()
    fire_cooldown = fire_interval
    if not camera:
        return
    var from := camera.global_position
    var direction := -camera.global_basis.z
    var to := from + direction * 80.0
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [player.get_rid()]
    query.collision_mask = 1
    var result := get_world_3d().direct_space_state.intersect_ray(query)
    var status := get_node("HUD/Status") as Label
    if result and result.has("collider"):
        var collider = result["collider"]
        if collider and collider.has_meta("damage_target"):
            var target = collider.get_meta("damage_target")
            if target and is_instance_valid(target):
                target.take_damage(20.0)
                if status:
                    status.text = "HIT  •  DRONE HP %d" % int(target.health)
                return
    if status:
        status.text = "SHOT MISSED"

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < get_viewport().size.x * 0.42 and event.position.y > get_viewport().size.y * 0.55 and move_touch_id == -1:
                move_touch_id = event.index
                joystick_center = event.position
                _update_joystick(event.position)
            elif event.position.x > get_viewport().size.x * 0.42 and aim_touch_id == -1:
                aim_touch_id = event.index
        else:
            if event.index == move_touch_id:
                move_touch_id = -1
                touch_move = Vector2.ZERO
                _reset_joystick()
            if event.index == aim_touch_id:
                aim_touch_id = -1
    elif event is InputEventScreenDrag:
        if event.index == move_touch_id:
            _update_joystick(event.position)
        elif event.index == aim_touch_id:
            var delta := event.screen_relative
            player.rotate_y(-delta.x * aim_sensitivity)
            camera_pitch = clamp(camera_pitch - delta.y * aim_sensitivity, -55.0, 25.0)
            camera.rotation_degrees.x = camera_pitch

func _update_joystick(position: Vector2) -> void:
    var offset := position - joystick_center
    var max_radius := 72.0
    if offset.length() > max_radius:
        offset = offset.normalized() * max_radius
    touch_move = offset / max_radius
    if joystick_base and joystick_knob:
        joystick_knob.position = Vector2(60, 60) + offset

func _reset_joystick() -> void:
    if joystick_knob:
        joystick_knob.position = Vector2(60, 60)

