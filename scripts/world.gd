extends Node3D

@export var max_bus_count = 10

# Stop status
var red_stop_occupied = false
var yellow_stop_occupied = false
var waiting_for_red_stop = false
var drop_off_point_occupied = false

# Bus tracking
var buses = []
var bus_at_red_stop = null
var bus_at_yellow_stop = null
var bus_at_drop_off = null
var yellow_spot_passed = false

# Passenger Tracking
@export var people_per_seconds = 5
@export var people_loading_per_second = 5
@export var max_people_load = 20
@export var people_loaded = 0
var people_count = 0
@onready var people_scene_5 = preload("res://scene/5person.tscn")
@onready var people_scene_10 = preload("res://scene/10person.tscn")
@onready var people_mesh_counts:Dictionary = {
    5: people_scene_5,
    10: people_scene_10
}
@onready var people_spawn_point = $PeopleSpawnPoint

@onready var bus_scene = preload("res://scene/bus_new.tscn")
var bus_count = 0

func _ready():
    add_to_group("world")
    
    for path_follow in $Path3D.get_children():
        if path_follow is PathFollow3D and path_follow.get_child_count() > 0:
            var bus = path_follow.get_child(0)
            buses.append(bus)

# Called every frame
func _process(delta):
    # Debug information
    #if OS.is_debug_build():
        #var debug_text = "Red occupied: " + str(red_stop_occupied)
        #debug_text += " Yellow occupied: " + str(yellow_stop_occupied)
        #debug_text += " Waiting for red: " + str(waiting_for_red_stop)
        #print(debug_text)
        #
        #for i in range(buses.size()):
            #var status = "moving: " + str(buses[i].moving)
            #status += ", waiting: " + str(buses[i].waiting)
            #status += ", at_red: " + str(buses[i].at_red_stop)
            #status += ", at_yellow: " + str(buses[i].at_yellow_stop)
            #if buses[i].detected_bus:
                #status += ", detects: Bus " + str(buses.find(buses[i].detected_bus))
            #print("Bus " + str(i) + ": " + status)
    
    
    
    if red_stop_occupied: 
        if $PeopleLoadingTimer.is_stopped():
            $PeopleLoadingTimer.start()
        if people_loaded >= max_people_load:
            if not $PeopleLoadingTimer.is_stopped():
                $PeopleLoadingTimer.stop()


func _load_people():
    if people_loaded < max_people_load:
        if people_count > 0 and bus_at_red_stop:
            if $Peoples.get_child(0):
                people_count -= $Peoples.get_child(0).person_count
                people_loaded += $Peoples.get_child(0).person_count
                bus_at_red_stop.people_loaded_in_current_bus += 5
                print("People count subtracted and people loaded added\n " + "people count: " + str(people_count) + " \npeople loaded: " + str(people_loaded))
                $Peoples.get_child(0).queue_free()
                people_spawn_point.global_position.x += 2
    elif people_loaded >= max_people_load:
        bus_at_red_stop.moving = true
        bus_at_red_stop.at_red_stop = false
        bus_at_red_stop = null
        red_stop_occupied = false
        people_loaded = 0
            
        check_and_move_waiting_bus()

func _on_red_stop_area_entered(area):
    if area.is_in_group("bus") and not red_stop_occupied:
        red_stop_occupied = true
        yellow_spot_passed = false
        bus_at_red_stop = area
        area.moving = false
        area.at_red_stop = true
        
        await get_tree().create_timer(3).timeout
        
        people_loaded = 0
        
        if is_instance_valid(area) and area == bus_at_red_stop:
            area.moving = true
            area.at_red_stop = false
            bus_at_red_stop = null
            red_stop_occupied = false
            
            check_and_move_waiting_bus()

func check_and_move_waiting_bus():
    if is_instance_valid(bus_at_yellow_stop) and waiting_for_red_stop and not red_stop_occupied:
        var bus_to_move = bus_at_yellow_stop
        bus_at_yellow_stop = null
        yellow_stop_occupied = false
        waiting_for_red_stop = false
        bus_to_move.moving = true
        bus_to_move.at_yellow_stop = false

func _on_yellow_stop_area_entered(area):
    if area.is_in_group("bus") and not yellow_stop_occupied:
        if red_stop_occupied or yellow_spot_passed:
            yellow_stop_occupied = true
            bus_at_yellow_stop = area
            area.moving = false
            area.at_yellow_stop = true
            waiting_for_red_stop = true
        elif not red_stop_occupied:
            yellow_spot_passed = true

func _on_red_stop_area_exited(area):
    if area.is_in_group("bus") and area == bus_at_red_stop:
        bus_at_red_stop = null
        red_stop_occupied = false
        check_and_move_waiting_bus()

func _on_yellow_stop_area_exited(area):
    if area.is_in_group("bus") and area == bus_at_yellow_stop:
        bus_at_yellow_stop = null
        yellow_stop_occupied = false
        waiting_for_red_stop = false

func _on_timer_timeout():
    if bus_count < max_bus_count:
        var bus_instance = bus_scene.instantiate()
        bus_instance.progress = 4460
        buses.append(bus_instance.get_child(0))
        $Path3D.add_child(bus_instance)
        bus_count += 1
    else:
        $Timer.stop()


func _on_people_spawn_timer_timeout():
    var people_instance = people_mesh_counts[people_per_seconds].instantiate()
    people_count += people_per_seconds
    print("People Count When Spawned: " + str(people_count))
    $PersonCount.text = str(people_count)
    people_instance.global_position = people_spawn_point.global_position
    if $Peoples.get_children():
        people_spawn_point.global_position.x = $Peoples.get_children()[$Peoples.get_children().size() - 1].global_position.x - 2
    $Peoples.add_child(people_instance)
    


func _on_drop_off_point_area_entered(area):
    drop_off_point_occupied = true
    area.moving = false
    area.people_loaded_in_current_bus = 0
    bus_at_drop_off = area
    $DropOffTimer.start()


func _on_drop_off_timer_timeout():
    bus_at_drop_off.moving = true
    drop_off_point_occupied = false
