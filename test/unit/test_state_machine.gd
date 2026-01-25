extends GutTest

# =============================================================================
# Test State Classes
# =============================================================================

# Simple test state that tracks lifecycle calls
class TestState extends UnifiedState:
	var enter_count := 0
	var exit_count := 0
	var process_count := 0
	var return_state: UnifiedState = null  # State to return from state_process

	func on_enter():
		enter_count += 1

	func on_exit():
		exit_count += 1

	func state_process(_delta) -> UnifiedState:
		process_count += 1
		return return_state


# State that uses next_state property for transitions
class NextStatePropertyState extends UnifiedState:
	var target_state: UnifiedState = null
	var should_transition := false

	func state_process(_delta) -> UnifiedState:
		if should_transition and target_state:
			next_state = target_state
		return null


# State that emits interrupt signal
class InterruptingState extends UnifiedState:
	var interrupt_target: UnifiedState = null
	var should_interrupt := false

	func state_process(_delta) -> UnifiedState:
		if should_interrupt and interrupt_target:
			emit_signal("interrupt_state", interrupt_target)
			should_interrupt = false
		return null


# =============================================================================
# UnifiedState Tests
# =============================================================================

func test_unified_state_default_can_move():
	var state = UnifiedState.new()
	add_child_autofree(state)
	assert_true(state.can_move, "Default can_move should be true")


func test_unified_state_default_next_state_is_null():
	var state = UnifiedState.new()
	add_child_autofree(state)
	assert_null(state.next_state)


func test_unified_state_process_returns_null_by_default():
	var state = UnifiedState.new()
	add_child_autofree(state)
	var result = state.state_process(0.016)
	assert_null(result)


func test_unified_state_has_interrupt_signal():
	var state = UnifiedState.new()
	add_child_autofree(state)
	assert_true(state.has_signal("interrupt_state"))


# =============================================================================
# UnifiedStateMachine Tests - Setup and Initialization
# =============================================================================

var _state_machine: UnifiedStateMachine
var _state_idle: TestState
var _state_move: TestState
var _state_jump: TestState


func _create_state_machine() -> UnifiedStateMachine:
	var sm = UnifiedStateMachine.new()
	sm.name = "StateMachine"

	_state_idle = TestState.new()
	_state_idle.name = "Idle"

	_state_move = TestState.new()
	_state_move.name = "Move"

	_state_jump = TestState.new()
	_state_jump.name = "Jump"

	sm.add_child(_state_idle)
	sm.add_child(_state_move)
	sm.add_child(_state_jump)

	return sm


func test_state_machine_gathers_child_states():
	_state_machine = _create_state_machine()
	add_child_autofree(_state_machine)

	# Force _ready to process
	await get_tree().process_frame

	assert_eq(_state_machine.states.size(), 3)


func test_state_machine_get_state_by_name():
	_state_machine = _create_state_machine()
	add_child_autofree(_state_machine)
	await get_tree().process_frame

	var idle = _state_machine.get_state("Idle")
	assert_not_null(idle)
	assert_eq(idle.name, "Idle")


func test_state_machine_get_state_returns_null_for_unknown():
	_state_machine = _create_state_machine()
	add_child_autofree(_state_machine)
	await get_tree().process_frame

	var unknown = _state_machine.get_state("NonExistent")
	assert_null(unknown)


# =============================================================================
# UnifiedStateMachine Tests - State Transitions
# =============================================================================

func test_switch_state_calls_on_exit():
	_state_machine = _create_state_machine()
	_state_machine.initial_state_path = ^"Idle"
	add_child_autofree(_state_machine)
	await get_tree().process_frame

	_state_machine.switch_state(_state_move)

	assert_eq(_state_idle.exit_count, 1, "on_exit should be called on old state")


func test_switch_state_calls_on_enter():
	_state_machine = _create_state_machine()
	_state_machine.initial_state_path = ^"Idle"
	add_child_autofree(_state_machine)
	await get_tree().process_frame

	_state_machine.switch_state(_state_move)

	assert_eq(_state_move.enter_count, 1, "on_enter should be called on new state")


func test_switch_state_updates_current_state():
	_state_machine = _create_state_machine()
	_state_machine.initial_state_path = ^"Idle"
	add_child_autofree(_state_machine)
	await get_tree().process_frame

	_state_machine.switch_state(_state_move)

	assert_eq(_state_machine.current_state, _state_move)


func test_switch_state_updates_prev_state():
	_state_machine = _create_state_machine()
	_state_machine.initial_state_path = ^"Idle"
	add_child_autofree(_state_machine)
	await get_tree().process_frame

	_state_machine.switch_state(_state_move)

	assert_eq(_state_machine.prev_state, _state_idle)


func test_switch_state_clears_next_state():
	_state_machine = _create_state_machine()
	_state_machine.initial_state_path = ^"Idle"
	add_child_autofree(_state_machine)
	await get_tree().process_frame

	_state_idle.next_state = _state_move
	_state_machine.switch_state(_state_move)

	assert_null(_state_idle.next_state, "next_state should be cleared after transition")


func test_switch_state_ignores_null():
	_state_machine = _create_state_machine()
	_state_machine.initial_state_path = ^"Idle"
	add_child_autofree(_state_machine)
	await get_tree().process_frame

	_state_machine.switch_state(null)

	assert_eq(_state_machine.current_state, _state_idle, "State should not change on null")


func test_initial_state_on_enter_called():
	_state_machine = _create_state_machine()
	_state_machine.initial_state_path = ^"Idle"
	add_child_autofree(_state_machine)
	await get_tree().process_frame

	assert_eq(_state_idle.enter_count, 1, "Initial state should have on_enter called")


# =============================================================================
# UnifiedStateMachine Tests - Transition via Return Value
# =============================================================================

func test_transition_via_return_value():
	_state_machine = _create_state_machine()
	_state_machine.initial_state_path = ^"Idle"
	add_child_autofree(_state_machine)
	await get_tree().process_frame

	# Set up idle to return move state
	_state_idle.return_state = _state_move

	# Manually call physics process to trigger transition
	_state_machine._physics_process(0.016)

	assert_eq(_state_machine.current_state, _state_move)


# =============================================================================
# UnifiedStateMachine Tests - Transition via next_state Property
# =============================================================================

func test_transition_via_next_state_property():
	_state_machine = UnifiedStateMachine.new()

	var state_a = NextStatePropertyState.new()
	state_a.name = "StateA"

	var state_b = TestState.new()
	state_b.name = "StateB"

	_state_machine.add_child(state_a)
	_state_machine.add_child(state_b)
	_state_machine.initial_state_path = ^"StateA"

	add_child_autofree(_state_machine)
	await get_tree().process_frame

	# Set up transition
	state_a.target_state = state_b
	state_a.should_transition = true

	# Manually call physics process to trigger transition
	_state_machine._physics_process(0.016)

	assert_eq(_state_machine.current_state, state_b)


# =============================================================================
# UnifiedStateMachine Tests - Interrupt Signal
# =============================================================================

func test_transition_via_interrupt_signal():
	_state_machine = UnifiedStateMachine.new()

	var state_a = InterruptingState.new()
	state_a.name = "StateA"

	var state_b = TestState.new()
	state_b.name = "StateB"

	_state_machine.add_child(state_a)
	_state_machine.add_child(state_b)
	_state_machine.initial_state_path = ^"StateA"

	add_child_autofree(_state_machine)
	await get_tree().process_frame

	# Set up interrupt
	state_a.interrupt_target = state_b
	state_a.should_interrupt = true

	# Manually call physics process to trigger transition
	_state_machine._physics_process(0.016)

	assert_eq(_state_machine.current_state, state_b)


# =============================================================================
# UnifiedStateMachine Tests - check_if_can_move
# =============================================================================

func test_check_if_can_move_returns_true_when_state_allows():
	_state_machine = _create_state_machine()
	_state_machine.initial_state_path = ^"Idle"
	add_child_autofree(_state_machine)
	await get_tree().process_frame

	_state_idle.can_move = true
	assert_true(_state_machine.check_if_can_move())


func test_check_if_can_move_returns_false_when_state_disallows():
	_state_machine = _create_state_machine()
	_state_machine.initial_state_path = ^"Idle"
	add_child_autofree(_state_machine)
	await get_tree().process_frame

	_state_idle.can_move = false
	assert_false(_state_machine.check_if_can_move())


func test_check_if_can_move_returns_false_with_no_state():
	_state_machine = UnifiedStateMachine.new()
	add_child_autofree(_state_machine)
	await get_tree().process_frame

	assert_false(_state_machine.check_if_can_move())


# =============================================================================
# UnifiedStateMachine Tests - Multiple Transitions
# =============================================================================

func test_multiple_state_transitions():
	_state_machine = _create_state_machine()
	_state_machine.initial_state_path = ^"Idle"
	add_child_autofree(_state_machine)
	await get_tree().process_frame

	# Idle -> Move
	_state_machine.switch_state(_state_move)
	assert_eq(_state_machine.current_state, _state_move)
	assert_eq(_state_machine.prev_state, _state_idle)

	# Move -> Jump
	_state_machine.switch_state(_state_jump)
	assert_eq(_state_machine.current_state, _state_jump)
	assert_eq(_state_machine.prev_state, _state_move)

	# Jump -> Idle
	_state_machine.switch_state(_state_idle)
	assert_eq(_state_machine.current_state, _state_idle)
	assert_eq(_state_machine.prev_state, _state_jump)


func test_lifecycle_counts_after_multiple_transitions():
	_state_machine = _create_state_machine()
	_state_machine.initial_state_path = ^"Idle"
	add_child_autofree(_state_machine)
	await get_tree().process_frame

	# Idle (entered once via initial)
	assert_eq(_state_idle.enter_count, 1)

	# Idle -> Move -> Idle
	_state_machine.switch_state(_state_move)
	_state_machine.switch_state(_state_idle)

	assert_eq(_state_idle.enter_count, 2)
	assert_eq(_state_idle.exit_count, 1)
	assert_eq(_state_move.enter_count, 1)
	assert_eq(_state_move.exit_count, 1)


# =============================================================================
# State (Backward Compatibility) Tests
# =============================================================================

func test_state_class_extends_unified_state():
	var state = State.new()
	add_child_autofree(state)
	assert_true(state is UnifiedState)


func test_state_class_works_with_state_machine():
	_state_machine = UnifiedStateMachine.new()

	var state = State.new()
	state.name = "BackwardCompatState"

	_state_machine.add_child(state)
	_state_machine.initial_state_path = ^"BackwardCompatState"

	add_child_autofree(_state_machine)
	await get_tree().process_frame

	assert_eq(_state_machine.current_state, state)
	assert_eq(_state_machine.states.size(), 1)
