extends Area3D
class_name LootPickup

var loot_type := "AMMO"
var amount := 8
var lifetime := 45.0
var spin_speed := 2.4
var bob_time := 0.0
var start_y := 0.0

func setup(type: String, value: int) -> void:
    loot_type = type
    amount = value

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    start_y = position.y

func _process(delta: float) -> void:
    bob_time += delta
    position.y = start_y + sin(bob_time * 3.0) * 0.08
    rotate_y(spin_speed * delta)
    lifetime -= delta
    if lifetime <= 0.0:
        queue_free()

func _on_body_entered(body: Node3D) -> void:
    if body.name != "Player":
        return
    var root := get_tree().current_scene
    if root and root.has_method("collect_loot"):
        root.collect_loot(loot_type, amount)
    queue_free()
