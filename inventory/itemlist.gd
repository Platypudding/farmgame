extends Node2D

#Below is an array of items, it can be edited in the inspector for itemlist under main. Array position for each item must match the corresponding key / value in the dictionary below.
#example: the seed item is position #0 in the array, and has a value of 0 in the dictionary.
@export var itemresources: Array[InvItem]
@export var listofitems = {
	"seed": 0,
	"flower": 1,
	"trash": 2,
	"tuna": 3,
	"catfish": 4,
	"zebrafish": 5
}

func getItem(item):
	var inputitem = listofitems[item]
	var returnitem = itemresources[inputitem]
	return returnitem
