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

func _on_weather_changed(new_weather: String):
	if new_weather == "rainy":
		rain_audio_player.play()
		if rain_overlay:
			rain_overlay.visible = true
	else:
		if rain_audio_player.playing:
			rain_audio_player.stop()
		if rain_overlay:
			rain_overlay.visible = false

