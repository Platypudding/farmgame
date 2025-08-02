extends Node

@onready var rain_audio_player: AudioStreamPlayer = $RainAudioPlayer
@onready var rain_overlay: ColorRect = $RainOverlay
var rain_material: ShaderMaterial

func _ready():
	# Connect to Global weather signal
	Global.weather_changed.connect(_on_weather_changed)
	
	# Set up looping for the rain sound
	if rain_audio_player.stream and rain_audio_player.stream is AudioStreamWAV:
		rain_audio_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	# Load rain shader material
	rain_material = preload("res://shaders/rain_material.tres")
	
	# Set up rain overlay
	if rain_overlay:
		rain_overlay.material = rain_material
		rain_overlay.visible = false
		print("Rain overlay setup complete. Material: ", rain_material)
	else:
		print("ERROR: Rain overlay not found!")
	
	print("RainManager ready with audio player and rain shader: ", rain_audio_player, rain_overlay)
	print("Current weather: ", Global.current_weather)

func _on_weather_changed(new_weather: String):
	if new_weather == "rainy":
		print("RainManager: Starting rain effects")
		rain_audio_player.play()
		if rain_overlay:
			rain_overlay.visible = true
			print("Rain overlay made visible. Size: ", rain_overlay.size)
	else:
		print("RainManager: Stopping rain effects")
		if rain_audio_player.playing:
			rain_audio_player.stop()
		if rain_overlay:
			rain_overlay.visible = false

# Debug function to test rain manually
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			print("DEBUG: Forcing rain")
			Global.force_weather("rainy")
		elif event.keycode == KEY_S:
			print("DEBUG: Forcing sunny")
			Global.force_weather("sunny")