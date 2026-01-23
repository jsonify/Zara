extends Node

class_name CharacterStateMachine

## State machine for enemies that uses AnimationTree
## Compatible with UnifiedState/State pattern

@export var character: CharacterBody2D
@export var animation_tree: AnimationTree
@export var current_state: State

var states: Array[State]
var prev_state: State

func _ready():
	for child in get_children():
		if child is State:
			states.append(child)

			# Set up the states with what they need to function
			child.character = character
			if animation_tree:
				child.playback = animation_tree["parameters/playback"]

			# Connect to interrupt
			child.interrupt_state.connect(on_state_interrupt_state)
		else:
			push_warning("Child " + child.name + " is not a State for CharacterStateMachine")

	# Enter initial state
	if current_state:
		current_state.on_enter()

func _physics_process(_delta):
	if current_state == null:
		return

	# Check for state transition via return value (unified pattern)
	var returned_state = current_state.state_process(_delta)
	if returned_state != null and returned_state is State:
		switch_state(returned_state as State)
		return

	# Check for state transition via next_state property (original pattern)
	if current_state.next_state != null and current_state.next_state is State:
		switch_state(current_state.next_state as State)

func check_if_can_move():
	return current_state != null and current_state.can_move

func switch_state(new_state: State):
	if new_state == null:
		return

	if current_state != null:
		current_state.on_exit()
		current_state.next_state = null

	prev_state = current_state
	current_state = new_state
	current_state.on_enter()

func _input(event: InputEvent):
	if current_state:
		current_state.state_input(event)

func on_state_interrupt_state(new_state):
	if new_state is State:
		switch_state(new_state as State)

func get_state(state_name: String) -> State:
	for state in states:
		if state.name == state_name:
			return state
	return null
