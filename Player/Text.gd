extends Label

@export var basetextSpeed = 0.05 #number of seconds that it waits before displaying next letter
var textSpeed = basetextSpeed
var count = 0
var voice = ""


func textappear():
	
	for character in text:
		count += 1
	visible_characters = 0
	await get_tree().create_timer(0.1).timeout
	while visible_characters < count:
		Global.speaking = true
		visible_characters = visible_characters + 1
		get_node(voice).play()
		await get_tree().create_timer(textSpeed).timeout
	count = 0 
	textSpeed = basetextSpeed
	print("speedreverted")
	voice = ""
	Global.speaking = false
