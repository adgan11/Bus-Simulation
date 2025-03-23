extends Area3D

@export var speed = 0.2
@export var detection_distance = 3.0

var moving = true
var waiting = false

var at_red_stop = false
var at_yellow_stop = false

var raycast_hitting = false
var detected_bus = null

@onready var path_follow = get_parent()
@onready var world = get_tree().get_first_node_in_group("world")
@onready var raycast = $RayCast3D

func _ready():
    raycast.target_position = Vector3(0, 0, -detection_distance)
    raycast.enabled = true

func _process(delta):
    update_raycast_detection()
    
    if moving and not waiting:
        path_follow.progress_ratio += speed * delta

func update_raycast_detection():
    raycast_hitting = false
    detected_bus = null
    
    if raycast.is_colliding():
        var collider = raycast.get_collider()
        if collider and collider.is_in_group("bus"):
            raycast_hitting = true
            detected_bus = collider
            if not detected_bus.moving or detected_bus.waiting or detected_bus.at_red_stop or detected_bus.at_yellow_stop:
                waiting = true
            else:
                waiting = false
    else:
        waiting = false
