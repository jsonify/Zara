extends Resource

class_name ShopItemResource

enum ItemType { CONSUMABLE, UPGRADE }

@export var id: String
@export var name: String
@export_multiline var description: String
@export var price: int
@export var type: ItemType
@export var effect_type: String  # "health", "fuel"
@export var effect_amount: float
@export var upgrade_key: String  # for upgrades: "max_fuel"
