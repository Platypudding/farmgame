extends Node

@onready var rain_audio_player: AudioStreamPlayer = $RainAudioPlayer

func _ready():
	# Connect to Global weather signal
	Global.weather_changed.connect(_on_weather_changed)
	
	# Set up looping for the rain sound
	if rain_audio_player.stream and rain_audio_player.stream is AudioStreamWAV:
		rain_audio_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	print("RainManager ready with audio player: ", rain_audio_player)

func _on_weather_changed(new_weather: String):
	if new_weather == "rainy":
		print("RainManager: Starting rain sound")
		rain_audio_player.play()
	else:
		print("RainManager: Stopping rain sound")
		if rain_audio_player.playing:
			rain_audio_player.stop()