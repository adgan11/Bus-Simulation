extends Camera3D

@export var speed = 200

func _physics_process(delta):
    if Input.is_action_pressed("speed_up"):
        speed = 500
    else:
        speed = 200
    if Input.is_action_pressed("move_up"):
        self.global_position.z -= delta * speed
    if Input.is_action_pressed("move_down"):
        self.global_position.z += delta * speed
    if Input.is_action_pressed("move_left"):
        self.global_position.x -= delta * speed
    if Input.is_action_pressed("move_right"):
        self.global_position.x += delta * speed
    if Input.is_action_pressed("zoom_in"):
        self.global_position.y -= delta * speed
    if Input.is_action_pressed("zoom_out"):
        self.global_position.y += delta * speed
