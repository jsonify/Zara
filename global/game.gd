extends Node

var player_hp = 25  # Reduced for testing (was 100)
var gold = 0
var fuel_level: float = 30.0
var jetpack = false
var dash = false
var slide = false

# Max values for upgrades
var max_player_hp = 25
var max_fuel_level: float = 30.0

# Inventory system
var inventory: Dictionary = {}  # { "item_id": count }
var purchased_upgrades: Array = []

func add_item(item_id: String, count: int = 1) -> void:
	if inventory.has(item_id):
		inventory[item_id] += count
	else:
		inventory[item_id] = count
	Events.emit_signal("inventory_changed", item_id, inventory[item_id])

func remove_item(item_id: String, count: int = 1) -> bool:
	if not has_item(item_id, count):
		return false
	inventory[item_id] -= count
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
		Events.emit_signal("inventory_changed", item_id, 0)
	else:
		Events.emit_signal("inventory_changed", item_id, inventory[item_id])
	return true

func has_item(item_id: String, count: int = 1) -> bool:
	return inventory.has(item_id) and inventory[item_id] >= count

func get_item_count(item_id: String) -> int:
	return inventory.get(item_id, 0)

func use_item(item_id: String) -> bool:
	if not has_item(item_id):
		return false

	match item_id:
		"health_potion":
			if player_hp < max_player_hp:
				player_hp = min(player_hp + 10, max_player_hp)
				remove_item(item_id)
				return true
		"fuel_canister":
			if fuel_level < max_fuel_level:
				fuel_level = min(fuel_level + 10.0, max_fuel_level)
				remove_item(item_id)
				return true
	return false

func has_upgrade(upgrade_key: String) -> bool:
	return upgrade_key in purchased_upgrades

func add_upgrade(upgrade_key: String) -> void:
	if not has_upgrade(upgrade_key):
		purchased_upgrades.append(upgrade_key)
		_apply_upgrade(upgrade_key)

func _apply_upgrade(upgrade_key: String) -> void:
	match upgrade_key:
		"max_fuel":
			max_fuel_level += 10.0


