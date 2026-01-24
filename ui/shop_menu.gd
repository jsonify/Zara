extends CanvasLayer

const HEALTH_POTION = preload("res://resources/shop_items/health_potion.tres")
const FUEL_CANISTER = preload("res://resources/shop_items/fuel_canister.tres")
const FUEL_TANK_UPGRADE = preload("res://resources/shop_items/fuel_tank_upgrade.tres")

@onready var panel := $Panel
@onready var gold_label := $Panel/VBoxContainer/GoldLabel
@onready var items_container := $Panel/VBoxContainer/ItemsContainer
@onready var feedback_label := $Panel/VBoxContainer/FeedbackLabel

var shop_items: Array[ShopItemResource] = []
var feedback_tween: Tween

func _ready():
	hide_menu()
	shop_items = [HEALTH_POTION, FUEL_CANISTER, FUEL_TANK_UPGRADE]

func _unhandled_input(event):
	if event.is_action_pressed("pause") and panel.visible:
		hide_menu()
		get_viewport().set_input_as_handled()

func show_menu():
	panel.visible = true
	get_tree().paused = true
	Events.emit_signal("shop_opened")
	_refresh_shop()

func hide_menu():
	panel.visible = false
	get_tree().paused = false
	Events.emit_signal("shop_closed")

func _refresh_shop():
	gold_label.text = "Gold: " + str(Game.gold)

	# Clear existing items
	for child in items_container.get_children():
		child.queue_free()

	# Add shop items
	for item in shop_items:
		# Skip already purchased upgrades
		if item.type == ShopItemResource.ItemType.UPGRADE:
			if Game.has_upgrade(item.upgrade_key):
				continue

		var item_row = _create_item_row(item)
		items_container.add_child(item_row)

func _create_item_row(item: ShopItemResource) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Item name and description
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label = Label.new()
	name_label.text = item.name
	name_label.add_theme_font_size_override("font_size", 8)
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 6)
	desc_label.modulate = Color(0.7, 0.7, 0.7)
	info_vbox.add_child(desc_label)

	row.add_child(info_vbox)

	# Price and buy button
	var price_label = Label.new()
	price_label.text = str(item.price) + "g"
	price_label.add_theme_font_size_override("font_size", 8)
	price_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(price_label)

	var buy_button = Button.new()
	buy_button.text = "Buy"
	buy_button.add_theme_font_size_override("font_size", 7)
	buy_button.pressed.connect(_on_buy_pressed.bind(item))
	row.add_child(buy_button)

	# Dim the price and disable button if player can't afford
	if Game.gold < item.price:
		price_label.modulate = Color.RED
		buy_button.disabled = true

	return row

func _on_buy_pressed(item: ShopItemResource):
	if Game.gold < item.price:
		_show_feedback("Not enough gold!", Color.RED)
		return

	Game.gold -= item.price
	Events.emit_signal("gold_spent", item.price)

	if item.type == ShopItemResource.ItemType.CONSUMABLE:
		Game.add_item(item.id)
		_show_feedback("Purchased " + item.name + "!", Color.GREEN)
	elif item.type == ShopItemResource.ItemType.UPGRADE:
		Game.add_upgrade(item.upgrade_key)
		_show_feedback("Upgrade acquired!", Color.GREEN)

	_refresh_shop()

func _show_feedback(message: String, color: Color):
	feedback_label.text = message
	feedback_label.modulate = color
	feedback_label.visible = true

	# Cancel existing tween if any
	if feedback_tween and feedback_tween.is_valid():
		feedback_tween.kill()

	# Fade out after delay
	feedback_tween = create_tween()
	feedback_tween.tween_interval(1.5)
	feedback_tween.tween_property(feedback_label, "modulate:a", 0.0, 0.5)
	feedback_tween.tween_callback(func(): feedback_label.visible = false)

func _on_close_pressed():
	hide_menu()
