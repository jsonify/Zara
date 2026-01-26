extends GutTest

# Store original values to restore after tests
var _original_inventory: Dictionary
var _original_upgrades: Array
var _original_player_hp: int
var _original_max_player_hp: int
var _original_fuel_level: float
var _original_max_fuel_level: float
var _original_has_grenades: bool


func before_each():
	# Save original state
	_original_inventory = Game.inventory.duplicate()
	_original_upgrades = Game.purchased_upgrades.duplicate()
	_original_player_hp = Game.player_hp
	_original_max_player_hp = Game.max_player_hp
	_original_fuel_level = Game.fuel_level
	_original_max_fuel_level = Game.max_fuel_level
	_original_has_grenades = Game.has_grenades

	# Reset to clean state
	Game.inventory.clear()
	Game.purchased_upgrades.clear()
	Game.player_hp = 25
	Game.max_player_hp = 25
	Game.fuel_level = 30.0
	Game.max_fuel_level = 30.0
	Game.has_grenades = false


func after_each():
	# Restore original state
	Game.inventory = _original_inventory
	Game.purchased_upgrades = _original_upgrades
	Game.player_hp = _original_player_hp
	Game.max_player_hp = _original_max_player_hp
	Game.fuel_level = _original_fuel_level
	Game.max_fuel_level = _original_max_fuel_level
	Game.has_grenades = _original_has_grenades


# =============================================================================
# add_item tests
# =============================================================================

func test_add_item_creates_new_entry():
	Game.add_item("health_potion")
	assert_eq(Game.get_item_count("health_potion"), 1)


func test_add_item_increments_existing():
	Game.add_item("health_potion")
	Game.add_item("health_potion")
	assert_eq(Game.get_item_count("health_potion"), 2)


func test_add_item_with_count():
	Game.add_item("fuel_canister", 5)
	assert_eq(Game.get_item_count("fuel_canister"), 5)


func test_add_item_emits_signal():
	watch_signals(Events)
	Game.add_item("health_potion", 3)
	assert_signal_emitted_with_parameters(
		Events,
		"inventory_changed",
		["health_potion", 3]
	)


# =============================================================================
# remove_item tests
# =============================================================================

func test_remove_item_decrements_count():
	Game.add_item("health_potion", 3)
	Game.remove_item("health_potion")
	assert_eq(Game.get_item_count("health_potion"), 2)


func test_remove_item_returns_true_on_success():
	Game.add_item("health_potion", 2)
	var result = Game.remove_item("health_potion")
	assert_true(result)


func test_remove_item_returns_false_when_insufficient():
	Game.add_item("health_potion", 1)
	var result = Game.remove_item("health_potion", 5)
	assert_false(result)


func test_remove_item_returns_false_when_not_exists():
	var result = Game.remove_item("nonexistent_item")
	assert_false(result)


func test_remove_item_erases_when_zero():
	Game.add_item("health_potion", 1)
	Game.remove_item("health_potion")
	assert_false(Game.inventory.has("health_potion"))


func test_remove_item_emits_signal():
	Game.add_item("health_potion", 3)
	watch_signals(Events)
	Game.remove_item("health_potion", 2)
	assert_signal_emitted_with_parameters(
		Events,
		"inventory_changed",
		["health_potion", 1]
	)


func test_remove_item_emits_zero_when_erased():
	Game.add_item("health_potion", 1)
	watch_signals(Events)
	Game.remove_item("health_potion")
	assert_signal_emitted_with_parameters(
		Events,
		"inventory_changed",
		["health_potion", 0]
	)


# =============================================================================
# has_item tests
# =============================================================================

func test_has_item_returns_true_when_exists():
	Game.add_item("health_potion")
	assert_true(Game.has_item("health_potion"))


func test_has_item_returns_false_when_not_exists():
	assert_false(Game.has_item("health_potion"))


func test_has_item_checks_count():
	Game.add_item("health_potion", 3)
	assert_true(Game.has_item("health_potion", 3))
	assert_false(Game.has_item("health_potion", 4))


# =============================================================================
# get_item_count tests
# =============================================================================

func test_get_item_count_returns_zero_for_nonexistent():
	assert_eq(Game.get_item_count("nonexistent"), 0)


func test_get_item_count_returns_correct_count():
	Game.add_item("fuel_canister", 7)
	assert_eq(Game.get_item_count("fuel_canister"), 7)


# =============================================================================
# use_item tests - health potion
# =============================================================================

func test_use_health_potion_restores_hp():
	Game.player_hp = 10
	Game.add_item("health_potion")
	Game.use_item("health_potion")
	assert_eq(Game.player_hp, 20)


func test_use_health_potion_consumes_item():
	Game.player_hp = 10
	Game.add_item("health_potion")
	Game.use_item("health_potion")
	assert_eq(Game.get_item_count("health_potion"), 0)


func test_use_health_potion_caps_at_max():
	Game.player_hp = 20
	Game.max_player_hp = 25
	Game.add_item("health_potion")
	Game.use_item("health_potion")
	assert_eq(Game.player_hp, 25)


func test_use_health_potion_fails_at_full_hp():
	Game.player_hp = 25
	Game.max_player_hp = 25
	Game.add_item("health_potion")
	var result = Game.use_item("health_potion")
	assert_false(result)
	assert_eq(Game.get_item_count("health_potion"), 1, "Potion should not be consumed")


func test_use_health_potion_returns_true_on_success():
	Game.player_hp = 10
	Game.add_item("health_potion")
	var result = Game.use_item("health_potion")
	assert_true(result)


# =============================================================================
# use_item tests - fuel canister
# =============================================================================

func test_use_fuel_canister_restores_fuel():
	Game.fuel_level = 10.0
	Game.add_item("fuel_canister")
	Game.use_item("fuel_canister")
	assert_eq(Game.fuel_level, 20.0)


func test_use_fuel_canister_consumes_item():
	Game.fuel_level = 10.0
	Game.add_item("fuel_canister")
	Game.use_item("fuel_canister")
	assert_eq(Game.get_item_count("fuel_canister"), 0)


func test_use_fuel_canister_caps_at_max():
	Game.fuel_level = 25.0
	Game.max_fuel_level = 30.0
	Game.add_item("fuel_canister")
	Game.use_item("fuel_canister")
	assert_eq(Game.fuel_level, 30.0)


func test_use_fuel_canister_fails_at_full_fuel():
	Game.fuel_level = 30.0
	Game.max_fuel_level = 30.0
	Game.add_item("fuel_canister")
	var result = Game.use_item("fuel_canister")
	assert_false(result)
	assert_eq(Game.get_item_count("fuel_canister"), 1, "Canister should not be consumed")


# =============================================================================
# use_item tests - edge cases
# =============================================================================

func test_use_item_fails_without_item():
	var result = Game.use_item("health_potion")
	assert_false(result)


func test_use_unknown_item_returns_false():
	Game.add_item("mystery_item")
	var result = Game.use_item("mystery_item")
	assert_false(result)
	assert_eq(Game.get_item_count("mystery_item"), 1, "Unknown item should not be consumed")


# =============================================================================
# upgrade tests
# =============================================================================

func test_has_upgrade_returns_false_initially():
	assert_false(Game.has_upgrade("max_fuel"))


func test_add_upgrade_registers_upgrade():
	Game.add_upgrade("max_fuel")
	assert_true(Game.has_upgrade("max_fuel"))


func test_add_upgrade_applies_max_fuel():
	var initial_max = Game.max_fuel_level
	Game.add_upgrade("max_fuel")
	assert_eq(Game.max_fuel_level, initial_max + 10.0)


func test_add_upgrade_does_not_duplicate():
	Game.add_upgrade("max_fuel")
	Game.add_upgrade("max_fuel")
	assert_eq(Game.purchased_upgrades.size(), 1)


func test_add_upgrade_only_applies_once():
	var initial_max = Game.max_fuel_level
	Game.add_upgrade("max_fuel")
	Game.add_upgrade("max_fuel")
	assert_eq(Game.max_fuel_level, initial_max + 10.0)


# =============================================================================
# grenade ability tests
# =============================================================================

func test_has_grenades_default_false():
	assert_false(Game.has_grenades, "Grenades should be locked by default")


func test_has_grenades_can_be_unlocked():
	Game.has_grenades = true
	assert_true(Game.has_grenades)


func test_grenade_fuel_cost_default():
	assert_eq(Game.grenade_fuel_cost, 8.0, "Grenade fuel cost should be 8")
