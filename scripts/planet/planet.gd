extends Area2D

@onready var collision: CollisionShape2D = $CollisionShape2D

var is_in_area:bool
var target:CharacterBody2D
var to_center:Vector2
var raduis
var raduis_offset= 25

func _ready() -> void:
	var shape:CircleShape2D= collision.shape
	raduis = shape.radius

func _physics_process(delta: float) -> void:
	if is_in_area:
		target.get_gravity()
		to_center=self.global_position-target.global_position
		var force:Vector2=to_center.rotated(-PI/2)
		target.velocity= Vector2(force.x,force.y)
		
func _on_body_entered(body: Node2D) -> void:
	if body.name=="Player":
		is_in_area=true
		target=body

func _on_body_exited(body: Node2D) -> void:
	if body.name=="Player":
		is_in_area=false
