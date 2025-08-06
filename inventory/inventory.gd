extends Resource

class_name Inv

signal update

@export var slots: Array[InvSlot]

func insert(item: InvItem, amount: int):
	var itemslots = slots.filter(func(slot): return slot.item == item)
	if !itemslots.is_empty():
		itemslots[0].amount += amount

	else:
		var emptyslots = slots.filter(func(slot): return slot.item == null)
		if !emptyslots.is_empty():
			emptyslots[0].item = item
			emptyslots[0].amount += amount
			
	update.emit()

func remove(item: InvItem, amount: int) -> bool:
	var itemslots = slots.filter(func(slot): return slot.item == item)
	if !itemslots.is_empty():
		var slot = itemslots[0]
		if slot.amount >= amount:
			slot.amount -= amount
			if slot.amount <= 0:
				slot.item = null  # Clear empty slot
				slot.amount = 0
			update.emit()
			return true  # Success
		else:
			# Not enough items - remove what's available
			slot.amount = 0
			slot.item = null
			update.emit()
			return false  # Partial removal - caller should handle this
	return false  # Item not found
	
func check(item: InvItem) :
	var itemslots = slots.filter(func(slot): return slot.item == item)
	if !itemslots.is_empty():
		var results =[true, itemslots[0].amount]
		return results

	else:
		var emptyslots = slots.filter(func(slot): return slot.item == null)
		if !emptyslots.is_empty():
			var results = [false]
			return results
			
			#emptyslots[0].item = item
			#emptyslots[0].amount += amount
			#print(emptyslots[0].item.name)

			
