extends Node

class_name UnifiedState

## Unified state base class that supports both transition patterns:
## - Setting next_state property (enemy pattern)
## - Returning next state from state_process (player pattern)

@export var can_move := true

var character: CharacterBody2D
var animation_player: AnimationPlayer
var playback: AnimationNodeStateMachinePlayback  # For AnimationTree users
var next_state: UnifiedState

signal interrupt_state(new_state: UnifiedState)

## Called every physics frame. Return a state to transition, or set next_state.
func state_process(_delta) -> UnifiedState:
	return null

## Called for input events
func state_input(_event: InputEvent):
	pass

## Called when entering this state
func on_enter():
	pass

## Called when exiting this state
func on_exit():
	pass

## Helper for player movement - can be overridden
func player_movement():
	if character and character is Player:
		var player := character as Player
		if player.movement_input.x > 0:
			player.velocity.x = player.SPEED
			player.last_direction = Vector2.RIGHT
		elif player.movement_input.x < 0:
			player.velocity.x = -player.SPEED
			player.last_direction = Vector2.LEFT
		else:
			player.velocity.x = 0
