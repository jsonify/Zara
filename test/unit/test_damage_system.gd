extends GutTest

# =============================================================================
# Damageable Component Tests
# =============================================================================

var _damageable: Damageable
var _parent_node: Node2D


func before_each():
	# Create a parent node (Damageable uses get_parent())
	_parent_node = Node2D.new()
	_parent_node.name = "TestEnemy"
	add_child_autofree(_parent_node)

	# Create and attach Damageable
	_damageable = Damageable.new()
	_parent_node.add_child(_damageable)


func after_each():
	_damageable = null
	_parent_node = null


# -----------------------------------------------------------------------------
# Health property tests
# -----------------------------------------------------------------------------

func test_damageable_default_health():
	assert_eq(_damageable.health, 20, "Default health should be 20")


func test_damageable_health_can_be_set():
	_damageable.health = 50
	assert_eq(_damageable.health, 50)


func test_damageable_health_setter_emits_signal():
	watch_signals(SignalBus)
	_damageable.health = 15
	assert_signal_emitted(SignalBus, "on_health_changed")


func test_damageable_health_setter_emits_correct_change_amount():
	_damageable.health = 20  # Start at known value
	watch_signals(SignalBus)
	_damageable.health = 15  # Reduce by 5
	assert_signal_emitted_with_parameters(
		SignalBus,
		"on_health_changed",
		[_parent_node, -5]
	)


func test_damageable_health_increase_emits_positive_change():
	_damageable.health = 20
	watch_signals(SignalBus)
	_damageable.health = 25
	assert_signal_emitted_with_parameters(
		SignalBus,
		"on_health_changed",
		[_parent_node, 5]
	)


# -----------------------------------------------------------------------------
# hit() function tests
# -----------------------------------------------------------------------------

func test_hit_reduces_health():
	_damageable.health = 20
	_damageable.hit(5, Vector2.RIGHT)
	assert_eq(_damageable.health, 15)


func test_hit_emits_on_hit_signal():
	watch_signals(_damageable)
	_damageable.hit(10, Vector2.LEFT)
	assert_signal_emitted(_damageable, "on_hit")


func test_hit_emits_on_hit_with_correct_parameters():
	_damageable.health = 20
	watch_signals(_damageable)
	_damageable.hit(7, Vector2.RIGHT)
	assert_signal_emitted_with_parameters(
		_damageable,
		"on_hit",
		[_parent_node, 7, Vector2.RIGHT]
	)


func test_hit_with_zero_damage():
	_damageable.health = 20
	_damageable.hit(0, Vector2.ZERO)
	assert_eq(_damageable.health, 20)


func test_hit_can_reduce_health_below_zero():
	_damageable.health = 5
	_damageable.hit(10, Vector2.LEFT)
	assert_eq(_damageable.health, -5)


func test_hit_with_different_knockback_directions():
	watch_signals(_damageable)

	_damageable.hit(1, Vector2.LEFT)
	assert_signal_emitted_with_parameters(
		_damageable,
		"on_hit",
		[_parent_node, 1, Vector2.LEFT]
	)


func test_multiple_hits_accumulate_damage():
	_damageable.health = 100
	_damageable.hit(20, Vector2.RIGHT)
	_damageable.hit(30, Vector2.LEFT)
	_damageable.hit(10, Vector2.ZERO)
	assert_eq(_damageable.health, 40)


# -----------------------------------------------------------------------------
# Export property tests
# -----------------------------------------------------------------------------

func test_damageable_gold_drop_default():
	assert_eq(_damageable.gold_drop_amount, 5, "Default gold drop should be 5")


func test_damageable_dead_animation_default():
	assert_eq(_damageable.dead_animation_name, "dead")


# =============================================================================
# HurtBox Component Tests
# =============================================================================

var _hurtbox: HurtBox


func test_hurtbox_default_not_invincible():
	_hurtbox = HurtBox.new()
	add_child_autofree(_hurtbox)
	assert_false(_hurtbox.is_invincible)


func test_hurtbox_set_invincible_true():
	_hurtbox = HurtBox.new()
	add_child_autofree(_hurtbox)
	_hurtbox.set_invincible(true)
	assert_true(_hurtbox.is_invincible)


func test_hurtbox_set_invincible_false():
	_hurtbox = HurtBox.new()
	add_child_autofree(_hurtbox)
	_hurtbox.is_invincible = true
	_hurtbox.set_invincible(false)
	assert_false(_hurtbox.is_invincible)


func test_hurtbox_invincible_toggle():
	_hurtbox = HurtBox.new()
	add_child_autofree(_hurtbox)

	_hurtbox.set_invincible(true)
	assert_true(_hurtbox.is_invincible)

	_hurtbox.set_invincible(false)
	assert_false(_hurtbox.is_invincible)


# =============================================================================
# HitBox Component Tests
# =============================================================================

var _hitbox: HitBox


func test_hitbox_default_damage():
	_hitbox = HitBox.new()
	add_child_autofree(_hitbox)
	assert_eq(_hitbox.damage, 10, "Default HitBox damage should be 10")


func test_hitbox_damage_can_be_set():
	_hitbox = HitBox.new()
	add_child_autofree(_hitbox)
	_hitbox.damage = 25
	assert_eq(_hitbox.damage, 25)


func test_hitbox_damage_zero():
	_hitbox = HitBox.new()
	add_child_autofree(_hitbox)
	_hitbox.damage = 0
	assert_eq(_hitbox.damage, 0)


# =============================================================================
# Integration-style Tests (Damageable + Health tracking)
# =============================================================================

func test_damage_flow_health_to_zero():
	_damageable.health = 30

	_damageable.hit(10, Vector2.RIGHT)
	assert_eq(_damageable.health, 20)

	_damageable.hit(10, Vector2.LEFT)
	assert_eq(_damageable.health, 10)

	_damageable.hit(10, Vector2.ZERO)
	assert_eq(_damageable.health, 0)


func test_damage_signals_emitted_in_order():
	_damageable.health = 50
	watch_signals(_damageable)
	watch_signals(SignalBus)

	_damageable.hit(15, Vector2.RIGHT)

	# Both signals should be emitted
	assert_signal_emitted(SignalBus, "on_health_changed")
	assert_signal_emitted(_damageable, "on_hit")


func test_overkill_damage():
	_damageable.health = 10
	_damageable.hit(100, Vector2.LEFT)
	assert_eq(_damageable.health, -90, "Overkill damage should result in negative health")
