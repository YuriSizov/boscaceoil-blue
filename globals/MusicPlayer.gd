###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Music player component responsible for producing sounds using SiON and
## composition data.
class_name MusicPlayer extends Object

signal playback_started()
signal playback_tick()
signal playback_paused()
signal playback_stopped()

var _driver: SiONDriver = null
var _music_playing: bool = false
var _swing_active: bool = false

## Playback step of current patterns within the active timeline bar, in notes.
## Caps a current song's pattern size.
var _pattern_time: int = 0

## Driver's buffer size.
var buffer_size: int = 2048


func _init(controller: Node) -> void:
	_driver = SiONDriver.create(buffer_size)
	controller.add_child(_driver)


# Initialization.

func initialize() -> void:
	_driver.set_beat_callback_interval(1)
	_driver.set_timer_interval(1)
	print("Driver initialized.")


func reset_driver() -> void:
	# SiONDriver.play enables endless streaming. We use the timer callback (a.k.a. a metronome)
	# to supply the stream with new notes to play based on the composition of the current song.
	
	_driver.stop()

	update_driver_bpm()
	_driver.play(null, false)
	print("Driver streaming started.")


func update_driver_bpm() -> void:
	if Controller.current_song:
		_driver.set_bpm(Controller.current_song.bpm)


# Output and streaming control.

## Called automatically by the driver's timer.
func _playback_step() -> void:
	if not _driver || not _music_playing:
		return

	var song := Controller.current_song
	if song.instruments.is_empty() || song.patterns.is_empty() || not song.arrangement:
		return

	# Prepare the next timeline bar in the arrangement.
	if _pattern_time >= song.pattern_size:
		_pattern_time = 0
		_update_swing()

		song.progress_arrangement()
		song.reset_playing_patterns()

	# Play everything in the current timeline bar.
	var current_bar := song.get_current_arrangement_bar()
	for channel_idx in Arrangement.CHANNEL_NUMBER:
		var pattern_idx := current_bar[channel_idx]
		if pattern_idx < 0:
			continue # No pattern set.

		var pattern := song.patterns[pattern_idx]
		pattern.is_playing = true

		var active_instrument := song.instruments[pattern.instrument_idx]
		for note_idx in pattern.note_amount:
			var note := pattern.notes[note_idx]
			if note.x < 0 || note.y < 0 || note.y != _pattern_time || note.z < 1:
				# X — note number is invalid.
				# Y — note position in the pattern is invalid or doesn't match current time.
				# Z — note length is shorter than 1 unit of length.
				continue
			if not active_instrument.is_note_valid(note):
				continue # Custom validation for different instrument types failed.

			# Update the filter for single voice instruments and the first note of drumkit.
			if active_instrument.type == Instrument.InstrumentType.INSTRUMENT_SINGLE || (active_instrument.type == Instrument.InstrumentType.INSTRUMENT_DRUMKIT && _pattern_time == 0):
				active_instrument.update_filter()

			# If pattern uses recorded filter values, set them directly.
			if pattern.record_filter_enabled:
				active_instrument.change_filter_to(pattern.cutoff_graph[_pattern_time], pattern.resonance_graph[_pattern_time], pattern.volume_graph[_pattern_time])

			var note_value := active_instrument.get_note_value(note.x)
			var note_voice := active_instrument.get_note_voice(note.x)
			_driver.note_on(note_value, note_voice, note.z)

	# Finalize the step
	_pattern_time += 1
	_update_swing()
	playback_tick.emit()


func _update_swing() -> void:
	if not _driver:
		return

	if Controller.current_song.swing == 0:
		if _swing_active:
			_driver.set_timer_interruption(1)
			_swing_active = false
		return

	_swing_active = true

	# Swing goes from -10 to 10, F-Swing goes from 0.2 to 1.8
	var fswing: float = 0.2 + (Controller.current_song.swing + 10.0) * (1.8 - 0.2) / 20.0
	if _pattern_time % 2 == 0:
		_driver.set_timer_interruption(fswing)
	else:
		_driver.set_timer_interruption(2 - fswing)


func is_playing() -> bool:
	return _music_playing


func get_pattern_time() -> int:
	return _pattern_time


func start_playback() -> void:
	if _music_playing:
		return

	_driver.timer_interval.connect(_playback_step)
	_music_playing = true
	playback_started.emit()


func pause_playback() -> void:
	if not _music_playing:
		return

	_driver.timer_interval.disconnect(_playback_step)
	_music_playing = false
	playback_paused.emit()


func stop_playback() -> void:
	if _music_playing:
		_driver.timer_interval.disconnect(_playback_step)
		_music_playing = false
	
	_pattern_time = 0
	playback_stopped.emit()
