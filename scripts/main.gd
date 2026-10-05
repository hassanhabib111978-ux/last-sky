extends Node3D

# LAST SKY — first playable foundation.
# This is intentionally small and testable; production assets and systems come later.

var player: CharacterBody3D
var camera: Camera3D
var drone: MeshInstance3D
var drone_angle := 0.0
var speed := 5.0
var touch_move := Vector2.ZERO
var fire_button: Button
var drone_health := 60.0

func _ready() -> void:
    _build_world()
    _build_player()
    _build_drone()
    _build_hud()
    _build_mobile_controls()
    drone.set_script(preload("res://scripts/drone.gd"))
    drone.set_target(player)

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
    drone = MeshInstance3D.new()
    drone.name = "ScoutDrone"
    var sphere := SphereMesh.new()
    sphere.radius = 0.45
    sphere.height = 0.9
    drone.mesh = sphere
    drone.position = Vector3(0, 2.5, -8)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.18, 0.2, 0.24)
    material.metallic = 0.8
    material.roughness = 0.28
    drone.material_override = material
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
    fire_button = Button.new()
    fire_button.text = "FIRE"
    fire_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    fire_button.position = Vector2(-190, -190)
    fire_button.size = Vector2(150, 150)
    fire_button.add_theme_font_size_override("font_size", 26)
    fire_button.pressed.connect(_fire_weapon)
    get_node("HUD").add_child(fire_button)

func _fire_weapon() -> void:
    if not drone or not is_instance_valid(drone):
        return
    var to_drone := drone.global_position - camera.global_position
    if to_drone.length() <= 25.0 and camera.global_basis.z.dot(to_drone.normalized()) < -0.65:
        drone.take_damage(20.0)
        var status := get_node("HUD/Status") as Label
        if status:
            status.text = "HIT  •  DRONE HP %d" % int(drone.health)
    else:
        var status := get_node("HUD/Status") as Label
        if status:
            status.text = "SHOT MISSED"

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and event.position.x < get_viewport().size.x * 0.48 and event.position.y > get_viewport().size.y * 0.55:
            touch_move = Vector2.ZERO
        elif not event.pressed:
            touch_move = Vector2.ZERO
    elif event is InputEventScreenDrag and event.position.x < get_viewport().size.x * 0.48:
        var center := Vector2(130, get_viewport().size.y - 130)
        var offset := (event.position - center) / 86.0
        touch_move = offset.limit_length(1.0)

func _physics_process(delta: float) -> void:
    if not player:
        return
    var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    if touch_move.length() > 0.05:
        input = touch_move
    var direction := Vector3(input.x, 0, input.y)
    player.velocity.x = direction.x * speed
    player.velocity.z = direction.z * speed
    player.move_and_slide()

    drone_angle += delta * 0.7
    if drone and drone.is_inside_tree():
        drone.look_at(player.global_position + Vector3.UP * 1.0)
