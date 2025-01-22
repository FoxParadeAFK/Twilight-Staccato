extends Node2D
class_name ButtonManager

var button : String
var inputBufferTimer : UtilityTimer
var inputBufferTimeInMilliseconds : int

var input : bool

func _init(_button : String, _inputBufferTimeInMilliseconds : int) -> void:
	button = _button
	
	inputBufferTimeInMilliseconds = _inputBufferTimeInMilliseconds
	inputBufferTimer = UtilityTimer.new(inputBufferTimeInMilliseconds)
	inputBufferTimer.OnTimerDone.connect(ReleaseInput)
	
func Tick() -> void:
	inputBufferTimer.Tick()
	
	if (Input.is_action_just_pressed(button)):
		inputBufferTimer.StartUtilityTimer()
		input = true
		
func ReleaseInput() -> void:
	input = false
