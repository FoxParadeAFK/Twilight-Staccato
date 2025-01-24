extends CharacterBody2D 
class_name PlayerController

var animationTree : AnimationTree
var attackArea : Area2D
var horizontalInput : AxisManager
var verticalInput : ButtonManager
var attackInput : ButtonManager
var verticalCoyoteTimer : UtilityTimer
var attackAnimationCycleTimer : UtilityTimer

var currentVelocity : Vector2
var currentDelta : float
var facingDirection : int

var attackActive : bool

var currentState : int
enum states {
	Idle = 0,
	Move = 1,
	InAirEnter = 2,
	InAir = 3,
	Jump = 4,
	GroundAttackEnter = 5,
	GroundAttack = 6,
}

var amountOfJump : int = 1
var amountOfJumpsLeft : int

var amountOfAttacks : int = 2
var amountOfAttacksCounter : int

func _draw() -> void:
	pass

func _ready() -> void:
	animationTree = get_node("AnimationTree")
	attackArea = get_node("Area2D")
	
	horizontalInput = AxisManager.new("Move_Left", "Move_Right")
	verticalInput = ButtonManager.new("Jump", 170)
	attackInput = ButtonManager.new("Melee", 170)
	
	verticalCoyoteTimer = UtilityTimer.new(100)
	verticalCoyoteTimer.OnTimerDone.connect(DisableJump)
	attackAnimationCycleTimer = UtilityTimer.new(700)
	attackAnimationCycleTimer.OnTimerDone.connect(ResetAttackAnimation)
	
	facingDirection = 1
	amountOfAttacksCounter = -1
	amountOfJumpsLeft = amountOfJump

	currentState = states.Idle

func _physics_process(delta: float) -> void:
	currentVelocity = velocity
	currentDelta = delta
	
	horizontalInput.Tick()
	verticalInput.Tick()
	verticalCoyoteTimer.Tick()
	attackAnimationCycleTimer.Tick()
	attackInput.Tick()

	if (!is_on_floor()): currentVelocity += get_gravity() * currentDelta

	match currentState:
		states.Idle:
			CheckIfShouldFlip()
			IdleState()
		states.Move:
			CheckIfShouldFlip()
			MoveState()
		states.InAirEnter:
			CheckIfShouldFlip()
			InAirEnterState()
		states.InAir:
			CheckIfShouldFlip()
			InAirState()
		states.Jump:
			CheckIfShouldFlip()
			JumpState()
		states.GroundAttackEnter:
			GroundAttackEnterState()
		states.GroundAttack:
			GroundAttackState()

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
	elif (currentState == states.Idle && is_on_floor() && attackInput.input && !attackActive):
		currentState = states.GroundAttackEnter
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
	elif (currentState == states.Move && is_on_floor() && attackInput.input && !attackActive):
		currentState = states.GroundAttackEnter
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

#region GroundAttack
func GroundAttackEnterState() -> void:
	currentVelocity = Vector2(0, currentVelocity.y)
	animationTree.set("parameters/Transition/transition_request", "GroundAttack%s" % CycleAttackAnimation())
	attackAnimationCycleTimer.StartUtilityTimer()
	attackActive = true
	
	currentState = states.GroundAttack

func GroundAttackState() -> void:
	print(states.find_key(currentState))
	
	if (currentState == states.GroundAttack && !is_on_floor() && !attackActive):
		currentState = states.InAirEnter
	elif (currentState == states.GroundAttack && is_on_floor() && !attackActive):
		currentState = states.Idle

func AttackFinishTrigger() -> void: 
	attackActive = false
	
func AttackDamageTrigger() -> void:
	attackArea.visible = true
	var detectedBodies : Array[Node2D] = attackArea.get_overlapping_bodies()
	for body : Node2D in detectedBodies:
		if (body.has_method("SetHealth")): body.SetHealth(2)
	attackArea.visible = false

func ResetAttackAnimation() -> void:
	amountOfAttacksCounter = -1

func CycleAttackAnimation() -> int:
	print("qwer %s" % amountOfAttacksCounter)
	amountOfAttacksCounter += 1
	if (amountOfAttacksCounter >= amountOfAttacks): amountOfAttacksCounter = 0
	return	amountOfAttacksCounter
	
#endregion
