extends CharacterBody2D 
class_name PlayerController

var animationTree : AnimationTree
var horizontalInput : AxisManager
var verticalInput : ButtonManager
var verticalCoyoteTimer : UtilityTimer

var currentVelocity : Vector2
var currentDelta : float
var facingDirection : int

var currentState : int
enum states {
	Idle = 0,
	Move = 1,
	InAirEnter = 2,
	InAir = 3,
	Jump = 4,
}

var amountOfJump : int = 1
var amountOfJumpsLeft : int

func _draw() -> void:
	pass

func _ready() -> void:
	animationTree = get_node("AnimationTree")
	horizontalInput = AxisManager.new("Move_Left", "Move_Right")
	verticalInput = ButtonManager.new("Jump", 200)
	
	verticalCoyoteTimer = UtilityTimer.new(100)
	verticalCoyoteTimer.OnTimerDone.connect(DisableJump)
	
	facingDirection = 1
	amountOfJumpsLeft = amountOfJump

	currentState = states.Idle

func _physics_process(delta: float) -> void:
	currentVelocity = velocity
	currentDelta = delta
	
	CheckIfShouldFlip()
	horizontalInput.Tick()
	verticalInput.Tick()
	verticalCoyoteTimer.Tick()

	if (!is_on_floor()): currentVelocity += get_gravity() * currentDelta

	match currentState:
		states.Idle:
			IdleState()
		states.Move:
			MoveState()
		states.InAirEnter:
			InAirEnterState()
		states.InAir:
			InAirState()
		states.Jump:
			JumpState()

	velocity = currentVelocity
	move_and_slide()
	
#region Flipping
func CheckIfShouldFlip() -> void:
	if (horizontalInput.coordinate != 0 && facingDirection != horizontalInput.coordinate): Flip()

func Flip() -> void:
	facingDirection *= -1
	rotation_degrees = 0 if facingDirection == 1 else 180
	scale.y = 1 if facingDirection == 1 else -1
#endregion

#region Idle
func IdleState() -> void:
	print(states.find_key(currentState))
	animationTree.set("parameters/Transition/transition_request", states.find_key(currentState))
	currentVelocity = Vector2(0, currentVelocity.y)
	
	amountOfJumpsLeft = amountOfJump

	if (currentState == states.Idle && !is_on_floor()): 
		currentState = states.InAirEnter
	elif (currentState == states.Idle && is_on_floor() && horizontalInput.coordinate != 0):
		currentState = states.Move
	elif (currentState == states.Idle && is_on_floor() && CanJump() && verticalInput.input):
		currentState = states.Jump
#endregion

#region Move
func MoveState() -> void:
	print(states.find_key(currentState))
	animationTree.set("parameters/Transition/transition_request", states.find_key(currentState))
	currentVelocity = Vector2(horizontalInput.coordinate * 250, currentVelocity.y)
	
	amountOfJumpsLeft = amountOfJump
	
	if (currentState == states.Move && !is_on_floor()): 
		currentState = states.InAirEnter
	elif (currentState == states.Move && is_on_floor() && horizontalInput.coordinate == 0):
		currentState = states.Idle
	elif (currentState == states.Move && is_on_floor() && CanJump() && verticalInput.input):
		currentState = states.Jump
#endregion

#region InAir
func InAirEnterState() -> void:
	verticalCoyoteTimer.StartUtilityTimer()
	
	currentState = states.InAir
	
func InAirState() -> void:
	print(states.find_key(currentState))
	animationTree.set("parameters/Transition/transition_request", states.find_key(currentState))
	currentVelocity = Vector2(horizontalInput.coordinate * 250, currentVelocity.y)
	
	var xVelocity : float = abs(sign(currentVelocity.x))
	var yVelocity : float = clamp(currentVelocity.y, -360, 100)

	animationTree.set("parameters/InAir/blend_position", Vector2(xVelocity, yVelocity))

	if (currentState == states.InAir && is_on_floor() && horizontalInput.coordinate == 0): 
		currentState = states.Idle
	elif (currentState == states.InAir && is_on_floor() && horizontalInput.coordinate != 0): 
		currentState = states.Move
	elif (currentState == states.InAir && CanJump() && verticalInput.input):
		currentState = states.Jump
#endregion

#region Jump
func JumpState() -> void:
	print(states.find_key(currentState))
	currentVelocity = Vector2(currentVelocity.x, -360)
	
	amountOfJumpsLeft -= 1
	
	verticalInput.ReleaseInput()
	
	if (currentState == states.Jump): currentState = states.InAirEnter
	
func CanJump() -> bool:
	return amountOfJumpsLeft > 0

func DisableJump() -> void:
	amountOfJumpsLeft = 0
#endregion
