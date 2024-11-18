extends Control

@onready var inv: Inv = preload("res://inventory/playerinv.tres")
@onready var slots: Array = $NinePatchRect/GridContainer.get_children()

func _ready():
	inv.update.connect(update_Slots)
	update_Slots()
	
	
func update_Slots():
	for i in range(min(inv.slots.size(), slots.size())):
		slots[i].update(inv.slots[i])
