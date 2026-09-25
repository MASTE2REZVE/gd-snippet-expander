@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"shop_buy": {
				"phrases": ["buy item", "shop buy", "purchase item", "buy from shop"],
				"code": """signal purchase_completed(item_id: String, count: int, cost: int)
signal purchase_failed(item_id: String, reason: String)

@export var buy_markup: float = 1.0

func buy_item(item: Resource, inventory: Node, count: int = 1) -> bool:
	if item == null or inventory == null:
		return false
	var item_id := str(item.get("item_id"))
	var base_price: int = int(item.get("value"))
	var unit_price: int = int(ceil(float(base_price) * buy_markup))
	var total_cost: int = unit_price * count
	if not inventory.has_item("gold", total_cost):
		purchase_failed.emit(item_id, "Not enough gold")
		return false
	if not inventory.remove_item("gold", total_cost):
		purchase_failed.emit(item_id, "Could not remove gold")
		return false
	if not inventory.add_item(item_id, count):
		# Refund on failure
		inventory.add_item("gold", total_cost)
		purchase_failed.emit(item_id, "Inventory full")
		return false
	purchase_completed.emit(item_id, count, total_cost)
	return true
""",
				"params": ["buy_markup"],
				"category": "shop",
				"subcategory": "transactions",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"buy_markup": {
						"default": 1.0,
						"range": [0.5, 3.0],
						"what": "Price multiplier when buying. 1.0 means the item's base value.",
						"typical": "1.0 fair / 1.5 typical merchant / 2.5+ rip-off",
						"increase": "More expensive to buy.",
						"decrease": "Cheaper."
					}
				},
				"details": {
					"what": "Buys an item from a shop. Checks gold, removes cost, adds item. Refunds on failure.",
					"where": "Attach to your shop manager or a shopkeeper node.",
					"before": "Inventory in group 'inventory' with add_item, remove_item, and has_item. Gold as an item called 'gold'.",
					"after": "Connect purchase_completed to update the shop UI and play a purchase sound.",
					"why_optimized": "Refund on failure means the player never loses gold for nothing. Signal-driven for UI decoupling.",
					"mistakes": "Not registering a 'gold' ItemData means the inventory silently rejects gold additions.",
					"related": ["shop_sell", "shop_pricing", "inventory_grid", "item_data"]
				}
			},
			"shop_sell": {
				"phrases": ["sell item", "shop sell", "sell to shop", "sell inventory item"],
				"code": """signal sale_completed(item_id: String, count: int, earned: int)
signal sale_failed(item_id: String, reason: String)

@export var sell_ratio: float = 0.5

func sell_item(item: Resource, inventory: Node, count: int = 1) -> bool:
	if item == null or inventory == null:
		return false
	var item_id := str(item.get("item_id"))
	if not inventory.has_item(item_id, count):
		sale_failed.emit(item_id, "Not enough items")
		return false
	var base_price: int = int(item.get("value"))
	var unit_price: int = max(1, int(float(base_price) * sell_ratio))
	var total_earned: int = unit_price * count
	if not inventory.remove_item(item_id, count):
		sale_failed.emit(item_id, "Could not remove item")
		return false
	inventory.add_item("gold", total_earned)
	sale_completed.emit(item_id, count, total_earned)
	return true
""",
				"params": ["sell_ratio"],
				"category": "shop",
				"subcategory": "transactions",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"sell_ratio": {
						"default": 0.5,
						"range": [0.1, 1.0],
						"what": "Fraction of the item's base value earned when selling.",
						"typical": "0.25 harsh / 0.5 standard / 0.75 generous",
						"increase": "Player earns more.",
						"decrease": "Player earns less — encourages keeping items."
					}
				},
				"details": {
					"what": "Sells an item to a shop. Removes the item, adds gold equal to base_value * sell_ratio * count.",
					"where": "Attach to your shop manager or a shopkeeper node.",
					"before": "Inventory with add_item, remove_item, has_item.",
					"after": "Connect sale_completed to update the shop UI. Show the earned amount as a floating text popup.",
					"why_optimized": "max(1, ...) ensures even cheap items give at least 1 gold. Prevents the frustrating zero-gold sale.",
					"mistakes": "Setting sell_ratio above buy_markup lets players profit by buying and selling in a loop. Keep sell below buy.",
					"related": ["shop_buy", "shop_pricing", "inventory_grid"]
				}
			},
			"shop_pricing": {
				"phrases": ["shop pricing", "item price", "calculate price", "price modifiers"],
				"code": """@export var reputation_discount: float = 0.0
@export var bulk_discount: float = 0.05
@export var bulk_threshold: int = 5

func get_buy_price(item: Resource, count: int = 1, reputation: int = 0) -> int:
	if item == null:
		return 0
	var base: int = int(item.get("value"))
	var unit: float = float(base)
	# Reputation discount: -1% per reputation point, capped at 40%
	var rep_mod: float = clamp(1.0 - float(reputation) * 0.01 - reputation_discount, 0.6, 1.5)
	unit *= rep_mod
	# Bulk discount
	if count >= bulk_threshold:
		unit *= (1.0 - bulk_discount)
	return int(ceil(unit * float(count)))

func get_sell_price(item: Resource, count: int = 1, reputation: int = 0) -> int:
	if item == null:
		return 0
	var base: int = int(item.get("value"))
	var unit: float = float(base) * 0.5
	var rep_mod: float = clamp(1.0 + float(reputation) * 0.01, 0.5, 1.5)
	unit *= rep_mod
	return max(1, int(unit * float(count)))

func get_buy_price_breakdown(item: Resource, count: int, reputation: int) -> Dictionary:
	return {
		"base_unit": int(item.get("value")) if item != null else 0,
		"count": count,
		"reputation": reputation,
		"final_price": get_buy_price(item, count, reputation)
	}
""",
				"params": ["reputation_discount", "bulk_discount", "bulk_threshold"],
				"category": "shop",
				"subcategory": "pricing",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"reputation_discount": {
						"default": 0.0,
						"range": [-0.5, 0.5],
						"what": "Flat multiplier modifier on prices. Negative values make items more expensive.",
						"typical": "0.0 neutral / 0.1 friendly shop / -0.1 hostile shop",
						"increase": "Cheaper for the player.",
						"decrease": "More expensive."
					},
					"bulk_discount": {
						"default": 0.05,
						"range": [0.0, 0.3],
						"what": "Discount applied when buying in bulk.",
						"typical": "0.0 no bulk / 0.05 standard / 0.15 generous",
						"increase": "Bigger bulk savings.",
						"decrease": "Smaller."
					},
					"bulk_threshold": {
						"default": 5,
						"range": [2, 50],
						"what": "Minimum count to trigger bulk discount.",
						"typical": "3 stacks of small items / 10 for materials",
						"increase": "Requires bigger purchase.",
						"decrease": "Triggers easier."
					}
				},
				"details": {
					"what": "Calculates buy and sell prices with reputation and bulk modifiers.",
					"where": "Attach to your shop manager. Call get_buy_price / get_sell_price from the shop UI.",
					"before": "None. Uses ItemData.value as the base price.",
					"after": "Track reputation per faction or per shop. Pass it in when displaying prices.",
					"why_optimized": "Pure math, no allocations. Clamped modifiers prevent extreme prices.",
					"mistakes": "Setting reputation discount and bulk discount both high lets players get items nearly free. Watch the multipliers.",
					"related": ["shop_buy", "shop_sell", "item_data", "faction_reputation"]
				}
			},
			"shop_stock": {
				"phrases": ["shop stock", "shop inventory", "merchant stock", "shop items"],
				"code": """signal stock_changed(slot_index: int, remaining: int)

@export var item_pool: Array[Resource] = []
@export var restock_interval: float = 0.0
@export var restock_amount: int = 5

var stock: Array = []

func _ready() -> void:
	for item in item_pool:
		stock.append({"item": item, "count": restock_amount})
	if restock_interval > 0.0:
		var timer := Timer.new()
		timer.wait_time = restock_interval
		timer.autostart = true
		timer.timeout.connect(_restock_all)
		add_child(timer)

func get_stock_for(item_id: String) -> int:
	for entry in stock:
		if entry.item != null and str(entry.item.get("item_id")) == item_id:
			return int(entry.count)
	return 0

func consume(item_id: String, count: int = 1) -> bool:
	for i in range(stock.size()):
		var entry: Dictionary = stock[i]
		if entry.item == null:
			continue
		if str(entry.item.get("item_id")) != item_id:
			continue
		if entry.count < count:
			return false
		entry.count = int(entry.count) - count
		stock_changed.emit(i, int(entry.count))
		return true
	return false

func _restock_all() -> void:
	for i in range(stock.size()):
		stock[i].count = restock_amount
		stock_changed.emit(i, restock_amount)

func is_infinite(item_id: String) -> bool:
	return restock_interval > 0.0
""",
				"params": ["item_pool", "restock_interval", "restock_amount"],
				"category": "shop",
				"subcategory": "stock",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"item_pool": {
						"default": [],
						"range": [],
						"what": "Array of ItemData resources this shop can sell.",
						"typical": "5-20 items depending on shop size",
						"increase": "More variety.",
						"decrease": "Specialized shop."
					},
					"restock_interval": {
						"default": 0.0,
						"range": [0.0, 3600.0],
						"what": "Seconds between restocks. Zero means the shop never restocks.",
						"typical": "0 limited stock / 60 fast / 600 in-game day",
						"increase": "Slower restock.",
						"decrease": "Faster."
					},
					"restock_amount": {
						"default": 5,
						"range": [1, 999],
						"what": "How many of each item are in stock at restock time.",
						"typical": "3 rare / 5 standard / 99 unlimited-feel",
						"increase": "More stock.",
						"decrease": "Less."
					}
				},
				"details": {
					"what": "Tracks shop inventory with per-item counts and optional restocking.",
					"where": "Attach to a shop node. Assign the item_pool in the Inspector.",
					"before": "ItemData resources for everything the shop sells.",
					"after": "Call consume(item_id, count) after a successful buy. Connect stock_changed to refresh the shop UI.",
					"why_optimized": "Linear search is fine for shops with under 100 items. restock_interval = 0 disables the Timer entirely.",
					"mistakes": "Forgetting to call consume() after a purchase means the shop never runs out.",
					"related": ["shop_buy", "item_data", "shop_pricing"]
				}
			}
		}
	}
