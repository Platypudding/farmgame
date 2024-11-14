extends Node

var day = 1
var flowers = 0
var shmoney = 0
var seeds = 5
var isTalking = false
var callYN = false
var voice
var timeline = "test"
var speaking = false 

func talking(_event):
	if !isTalking:
		Dialogic.timeline_ended.connect(_on_timeline_ended)
		isTalking = true
		Dialogic.start(timeline)
		


func _on_timeline_ended():
	Dialogic.timeline_ended.disconnect(_on_timeline_ended)
	isTalking = false
	timeline = ""
	print("talking end")

#func _on_timeline_ended():
#	Dialogic.timeline_ended.disconnect(_on_timeline_ended)
#	isTalking = false
#	get_tree().paused = false
#	timeline = ""
#	print("talking end")
