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

func remove(item: InvItem, amount: int):
	var itemslots = slots.filter(func(slot): return slot.item == item)
	if !itemslots.is_empty():
		itemslots[0].amount -= amount
		
		
	else:
		var emptyslots = slots.filter(func(slot): return slot.item == null)
		if !emptyslots.is_empty():
			emptyslots[0].amount -= amount 

	update.emit()
	
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

			
