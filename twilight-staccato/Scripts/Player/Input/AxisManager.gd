extends Node2D
class_name AxisManager

var negativeAxis : String
var positiveAxis : String
var coordinate : int

func _init(_negativeAxis : String, _positiveAxis : String) -> void:
	negativeAxis = _negativeAxis
	positiveAxis = _positiveAxis

func Tick() -> void:
	if (Input.is_action_just_pressed(negativeAxis)): 
		coordinate = -1
	if (Input.is_action_just_pressed(positiveAxis)): 
		coordinate = 1
	if (Input.is_action_just_released(negativeAxis) || Input.is_action_just_released(positiveAxis)):
		if (Input.is_action_pressed(negativeAxis)): 
			coordinate = -1
		elif (Input.is_action_pressed(positiveAxis)): 
			coordinate = 1
		else: coordinate = 0
