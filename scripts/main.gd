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

func _ready() -> void:
    _build_world()
    _build_player()
    _build_drone()
    _build_hud()
    _build_mobile_controls()
    drone.set_script(preload("res://scripts/drone.gd"))
    drone.set_target(player)
    drone.loot_dropped.connect(_spawn_loot)

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
    camera.position = Vector3(0, 3.2, 6.5)
    camera.rotation_degrees = Vector3(-14, 0, 0)
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

