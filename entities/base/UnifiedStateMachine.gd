extends Node

class_name UnifiedStateMachine

## Unified state machine that supports both transition patterns:
## - Return value from state_process()
## - Setting next_state property on current state

@export var character_path: NodePath
@export var animation_player_path: NodePath
@export var animation_tree_path: NodePath  # Optional, for AnimationTree users
@export var initial_state_path: NodePath

var _character: CharacterBody2D
var _animation_player: AnimationPlayer
var _animation_tree: AnimationTree

var states: Array[UnifiedState]
var prev_state: UnifiedState
var current_state: UnifiedState

func _ready():
	# Resolve node paths
	if character_path:
		_character = get_node(character_path) as CharacterBody2D
	if animation_player_path:
		_animation_player = get_node(animation_player_path) as AnimationPlayer
	if animation_tree_path:
		_animation_tree = get_node(animation_tree_path) as AnimationTree
	if initial_state_path:
		current_state = get_node(initial_state_path) as UnifiedState

	# Gather all child states and set them up
	for child in get_children():
		if child is UnifiedState:
			states.append(child)

			# Set up the state with references it needs
			child.character = _character
			child.animation_player = _animation_player

			if _animation_tree:
				child.playback = _animation_tree["parameters/playback"]

			# Connect interrupt signal
			child.interrupt_state.connect(_on_state_interrupt)
		else:
			push_warning("Child " + child.name + " is not a UnifiedState for UnifiedStateMachine")

	# Enter initial state
	if current_state:
		current_state.on_enter()

func _physics_process(delta):
	if current_state == null:
		return

	# Check for state transition via return value
	var returned_state = current_state.state_process(delta)
	if returned_state != null:
		switch_state(returned_state)
		return

	# Check for state transition via next_state property
	if current_state.next_state != null:
		switch_state(current_state.next_state)

func _input(event: InputEvent):
	if current_state:
		current_state.state_input(event)

func check_if_can_move() -> bool:
	return current_state != null and current_state.can_move

func switch_state(new_state: UnifiedState):
	if new_state == null:
		return

	if current_state != null:
		current_state.on_exit()
		current_state.next_state = null

	prev_state = current_state
	current_state = new_state
	current_state.on_enter()

func _on_state_interrupt(new_state: UnifiedState):
	switch_state(new_state)

## Get a state by name
func get_state(state_name: String) -> UnifiedState:
	for state in states:
		if state.name == state_name:
			return state
	return null
