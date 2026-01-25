extends Node

signal platform_jetpack_activated
signal right_horn_box_activated
signal right_horn_collected
signal cave_entered
signal jetpack_collected
signal thrust_engaged
signal thrust_not_engaged
signal player_died
signal player_respawned

# Currency/Shop signals
signal gold_collected(amount: int)
signal gold_spent(amount: int)
signal inventory_changed(item_id: String, new_count: int)
signal shop_opened
signal shop_closed

