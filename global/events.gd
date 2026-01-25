extends Node

# Signal bus for game-wide events
# These signals are emitted from various scripts across the codebase

@warning_ignore("unused_signal")
signal platform_jetpack_activated
@warning_ignore("unused_signal")
signal right_horn_box_activated
@warning_ignore("unused_signal")
signal right_horn_collected
@warning_ignore("unused_signal")
signal cave_entered
@warning_ignore("unused_signal")
signal jetpack_collected
@warning_ignore("unused_signal")
signal thrust_engaged
@warning_ignore("unused_signal")
signal thrust_not_engaged
@warning_ignore("unused_signal")
signal player_died
@warning_ignore("unused_signal")
signal player_respawned

# Currency/Shop signals
@warning_ignore("unused_signal")
signal gold_collected(amount: int)
@warning_ignore("unused_signal")
signal gold_spent(amount: int)
@warning_ignore("unused_signal")
signal inventory_changed(item_id: String, new_count: int)
@warning_ignore("unused_signal")
signal shop_opened
@warning_ignore("unused_signal")
signal shop_closed
