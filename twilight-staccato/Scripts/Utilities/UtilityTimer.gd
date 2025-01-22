extends Node
class_name UtilityTimer

var isActive : bool
var durationInMilliseconds : float
var startTimeInMilliseconds : float
var targetTimeInMilliseconds : float

signal OnTimerDone

func _init(_durationInMilliseconds : float) -> void:
	durationInMilliseconds = _durationInMilliseconds
	isActive = false
	
func StartUtilityTimer() -> void:
	startTimeInMilliseconds = Time.get_ticks_msec()
	targetTimeInMilliseconds = startTimeInMilliseconds + durationInMilliseconds
	
	isActive = true
	
func Tick() -> void:
	if (!isActive): return
	
	if (Time.get_ticks_msec() >= targetTimeInMilliseconds):
		StopUtilityTimer()
		OnTimerDone.emit()

func StopUtilityTimer() -> void:
	isActive = false
