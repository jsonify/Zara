extends Node

# Signal bus for health-related events
# This signal is emitted from Damageable component

@warning_ignore("unused_signal")
signal on_health_changed(node: Node, amount_changed: int)
