###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Music player component responsible for producing sounds using SiON and
## composition data.
class_name MusicPlayer extends RefCounted

signal playback_started()
signal playback_tick()
signal playback_paused()
signal playback_stopped()
signal playback_bar_changed()

signal export_started()
signal export_ended()

const BEATS_PER_NOTE := 0.0625 # Beat is split into 16 intervals.
const NOTE_LENGTH := 4.0 # In 1/16ths of a beat.
const NOTE_SWING_THRESHOLD := 0.2 # In portion of NOTE_LENGTH (i.e. = 20%).
const NOTE_GRACE_PERIOD := 4

const NOTE_SWING_MIN := NOTE_SWING_THRESHOLD * NOTE_LENGTH
const NOTE_SWING_MAX := (2 - NOTE_SWING_THRESHOLD) * NOTE_LENGTH

var _driver: SiONDriver = null
var _music_playing: bool = false
var _music_exporting: bool = false
var _swing_active: bool = false
var _playing_residue: bool = false
var _exporting_callback: Callable = Callable()

## Playback step of current patterns within the active timeline bar, in notes.
## Caps a current song's pattern size.
var _pattern_time: int = -1
## Note residue tracker to make sure we don't cut off the sound during export.
var _note_residue: PackedInt32Array = PackedInt32Array()
var _note_residue_time: int = 0


# Initialization.

func initialize_driver() -> void:
	if _driver:
		printerr("MusicPlayer: Cannot initialize the driver, an instance already exists.")
		return
	
	var buffer_size := Controller.settings_manager.get_buffer_size()
	_driver = SiONDriver.create(buffer_size)
	_driver.set_beat_callback_interval(1) # In 1/16ths of a beat, can only be one of: 1, 2, 4, 8, 16.
	_driver.set_timer_interval(NOTE_LENGTH)
	
	Controller.add_child(_driver)
	print("Synthesizer driver initialized (buffer: %d)." % [ buffer_size ])


func finalize_driver() -> void:
	if not _driver:
		printerr("MusicPlayer: Cannot finalize the driver, it doesn't exist.")
		return
	
	_driver.stop()
	
	if _driver.get_parent():
		_driver.get_parent().remove_child(_driver)
	
	_driver.free()
	_driver = null


func reset_driver() -> void:
	# SiONDriver.play enables endless streaming. We use the timer callback (a.k.a. a metronome)
	# to supply the stream with new notes to play based on the composition of the current song.
	
	_driver.stop()

	update_driver_bpm()
	update_driver_effects()
	_driver.play(null, false)
	print("Synthesizer driver streaming started.")


func update_driver_buffer() -> void:
	var was_playing := false
	if is_playing():
		was_playing = true
		stop_playback()
	
	# Buffer changes require us to recreate the entire driver. This should be relatively safe,
	# although leaks on the driver side are possible (but should be fixed in GDSiON anyway).
	finalize_driver()
	initialize_driver()
	reset_driver()
	
	if was_playing:
		start_playback()


func update_driver_bpm() -> void:
	if Controller.current_song:
		_driver.set_bpm(Controller.current_song.bpm)


func update_driver_effects() -> void:
	_driver.get_effector().clear_slot_effects(0)
	
	var song := Controller.current_song
	if not song || song.global_effect_power <= 5:
		return
	
	var _effect_power := song.global_effect_power / 100.0
	match song.global_effect:
		0:
			var effect_delay := SiEffectStereoDelay.new()
			effect_delay.set_params(300.0 * _effect_power, 0.1, false, 0.25) # Feedback uses non-default value.
			_driver.get_effector().add_slot_effect(0, effect_delay);
	
		1:
			var effect_chorus := SiEffectStereoChorus.new()
			effect_chorus.set_params(20, 0.2, 4, 10 + 50.0 * _effect_power, 0.5, true)
			_driver.get_effector().add_slot_effect(0, effect_chorus);
	
		2:
			var effect_reverb := SiEffectStereoReverb.new()
			effect_reverb.set_params(0.7, 0.4 + 0.5 * _effect_power, 0.8, 0.3)
			_driver.get_effector().add_slot_effect(0, effect_reverb);
	
		3:
			var effect_distortion := SiEffectDistortion.new()
			effect_distortion.set_params(-20 - 80.0 * _effect_power, 18, 2400, 1)
			_driver.get_effector().add_slot_effect(0, effect_distortion);
	
		4:
			var effect_lowboost := SiFilterLowBoost.new()
			effect_lowboost.set_params(3000, 1, 4 + 6.0 * _effect_power)
			_driver.get_effector().add_slot_effect(0, effect_lowboost);
	
		5:
			var effect_compressor := SiEffectCompressor.new()
			effect_compressor.set_params(0.7, 50, 20, 20, -6, 0.2 + 0.6 * _effect_power)
			_driver.get_effector().add_slot_effect(0, effect_compressor);
	
		6:
			var effect_highpass := SiControllableFilterHighPass.new()
			effect_highpass.set_params_manually(1.0 * _effect_power, 0.9)
			_driver.get_effector().add_slot_effect(0, effect_highpass);


# Driver interactions.

func _play_note(pattern: Pattern, instrument: Instrument, note_data: Vector3i, current_time: int) -> void:
	if note_data.x < 0 || note_data.y < 0 || note_data.y != current_time || note_data.z < 1:
		# X — note number is invalid.
		# Y — note position in the pattern is invalid or doesn't match current time.
		# Z — note length is shorter than 1 unit of length.
		return
	if not instrument.is_note_valid(note_data):
		return # Custom validation for different instrument types failed.

	# Update the filter.
	instrument.update_filter()

	# If pattern uses recorded filter values, set them directly.
	if pattern.record_filter_enabled:
		instrument.change_filter_to(pattern.cutoff_graph[current_time], pattern.resonance_graph[current_time], pattern.volume_graph[current_time])

	var note_value := instrument.get_note_value(note_data.x)
	var note_voice := instrument.get_note_voice(note_data.x)
	_driver.note_on(note_value, note_voice, note_data.z * NOTE_LENGTH)
	
	if _music_exporting:
		_note_residue.push_back(note_data.z + NOTE_GRACE_PERIOD) # Each note has a grace period to finish.


func play_note(pattern: Pattern, note_data: Vector3i) -> void:
	var song := Controller.current_song
	if not song || song.instruments.is_empty() || song.patterns.is_empty():
		return
	
	var active_instrument := song.instruments[pattern.instrument_idx]
	_play_note(pattern, active_instrument, note_data, note_data.y)


# Playback.

## Called automatically by the driver's timer.
func _playback_step() -> void:
	if not _driver || not _music_playing:
		return
	
	var song := Controller.current_song
	if not song || song.instruments.is_empty() || song.patterns.is_empty() || not song.arrangement:
		return
	
	# Prepare the next timeline bar in the arrangement.
	if _pattern_time >= song.pattern_size:
		_pattern_time = 0
		_update_swing()
		
		var timeline_looped := song.arrangement.progress_loop()
		if _music_exporting && timeline_looped:
			_playing_residue = true
		
		song.reset_playing_patterns()
		playback_bar_changed.emit()
	
	# When in the playing residue mode, we don't play new notes and just let existing ones to play out.
	if not _playing_residue:
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
				_play_note(pattern, active_instrument, pattern.notes[note_idx], _pattern_time)
	
	# Finalize the step
	_pattern_time += 1
	_update_residue()
	_update_swing()
	playback_tick.emit()


func _update_residue() -> void:
	if not _music_exporting:
		return
	
	if _playing_residue:
		_note_residue_time += 1
	
	var i := _note_residue.size() - 1
	while i >= 0:
		_note_residue[i] -= 1
		if _note_residue[i] <= 0:
			_note_residue.remove_at(i)
		
		i -= 1
	
	if _playing_residue && _note_residue.size() <= 0:
		_playing_residue = false
		_stop_exporting()


func _update_swing() -> void:
	if not _driver:
		return

	if Controller.current_song.swing == 0:
		if _swing_active:
			_driver.set_timer_interval(NOTE_LENGTH)
			_swing_active = false
		return

	_swing_active = true

	# Remapping swing setting range from -10 to 10, to 20% - 180% of NOTE_LENGTH.
	var fswing: float = NOTE_SWING_MIN + (Controller.current_song.swing + 10.0) * (NOTE_SWING_MAX - NOTE_SWING_MIN) / 20.0
	if _pattern_time % 2 == 0:
		_driver.set_timer_interval(fswing)
	else:
		_driver.set_timer_interval(2 * NOTE_LENGTH - fswing)


func is_playing() -> bool:
	return _music_playing


func get_pattern_time() -> int:
	return _pattern_time


func get_note_time_length() -> float:
	if not Controller.current_song:
		return 0.0
	
	var beat_length_in_sec := 60.0 / Controller.current_song.bpm
	return beat_length_in_sec * NOTE_LENGTH * BEATS_PER_NOTE


func start_playback() -> void:
	if _music_playing:
		return

	if _pattern_time == -1:
		_pattern_time = 0
	_music_playing = true

	_driver.timer_interval.connect(_playback_step)
	playback_started.emit()


func pause_playback() -> void:
	if not _music_playing:
		return

	_music_playing = false
	_driver.timer_interval.disconnect(_playback_step)
	playback_paused.emit()


func stop_playback() -> void:
	if _music_playing:
		_music_playing = false
		_driver.timer_interval.disconnect(_playback_step)
	
	if Controller.current_song:
		Controller.current_song.reset_arrangement()
	
	_pattern_time = -1
	playback_stopped.emit()


# Data streaming.

func start_exporting(callback: Callable) -> void:
	if _music_exporting:
		return
	
	_music_exporting = true
	_playing_residue = false
	_note_residue.clear()
	_note_residue_time = 0
	reset_driver() # Clears the output so there is no residue at the start.
	
	_exporting_callback = callback
	_driver.streaming.connect(_exporting_callback)
	_driver.set_stream_event_enabled(true)
	start_playback()
	
	export_started.emit()


func _stop_exporting() -> void:
	if not _music_exporting:
		return
	
	_music_exporting = false
	_playing_residue = false
	
	stop_playback()
	_driver.set_stream_event_enabled(false)
	_driver.streaming.disconnect(_exporting_callback)
	
	export_ended.emit()


func is_playing_residue() -> bool:
	return _playing_residue


func get_residue_time() -> int:
	return _note_residue_time
