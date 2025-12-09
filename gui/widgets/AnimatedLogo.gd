###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends Control

const HOP_DISTANCE := 20.0
const HOP_TIME := 0.01

var _current_pattern: Pattern = null

var _tween: Tween = null
var _default_position: Vector2 = Vector2.ZERO

var _themed_logos: Dictionary = {
	BoscaColorPalette.PALETTE_BLUE   : preload("res://assets/logos/logo_blue.png"),
	BoscaColorPalette.PALETTE_PURPLE : preload("res://assets/logos/logo_purple.png"),
	BoscaColorPalette.PALETTE_RED    : preload("res://assets/logos/logo_red.png"),
	BoscaColorPalette.PALETTE_ORANGE : preload("res://assets/logos/logo_orange.png"),
	BoscaColorPalette.PALETTE_GREEN  : preload("res://assets/logos/logo_green.png"),
	BoscaColorPalette.PALETTE_CYAN   : preload("res://assets/logos/logo_cyan.png"),
	BoscaColorPalette.PALETTE_GRAY   : preload("res://assets/logos/logo_gray.png"),
}

@onready var _logo: TextureRect = $Logo


func _ready() -> void:
	if not Engine.is_editor_hint():
		_edit_current_pattern()
		
		Controller.song_loaded.connect(_edit_current_pattern)
		Controller.song_pattern_changed.connect(_edit_current_pattern)
		Controller.song_instrument_changed.connect(_handle_instrument)
		
		Controller.music_player.playback_tick.connect(_handle_beat)
		Controller.music_player.playback_stopped.connect(_handle_beat)


func _edit_current_pattern() -> void:
	if _current_pattern:
		_current_pattern.instrument_changed.disconnect(_handle_instrument)
	
	_current_pattern = Controller.get_current_pattern()
	
	if _current_pattern:
		_current_pattern.instrument_changed.connect(_handle_instrument)
	
	_handle_instrument()
	_handle_beat()


func _handle_instrument() -> void:
	if not Controller.current_song:
		return
	var current_pattern := Controller.get_current_pattern()
	if not current_pattern:
		return
	
	var instrument := Controller.current_song.instruments[current_pattern.instrument_idx]
	if _themed_logos.has(instrument.color_palette):
		_logo.texture = _themed_logos[instrument.color_palette]
	else:
		_logo.texture = _themed_logos[BoscaColorPalette.PALETTE_GRAY]


func _handle_beat() -> void:
	if not Controller.current_song:
		return
	
	if _tween:
		_tween.kill()
	
	var pattern_bar_size := Controller.current_song.bar_size
	if pattern_bar_size == 1: # Too fast for the animation.
		_logo.position = _default_position
		return
	
	var pattern_time := Controller.music_player.get_pattern_time() - 1
	if pattern_time < 0: # Playback is fully stopped.
		_logo.position = _default_position
		return
	
	var bar_time := pattern_time % pattern_bar_size
	# We only care about the first and the second note.
	if bar_time > 1:
		return
	
	_tween = get_tree().create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC)
	
	if bar_time == 0:
		_tween.tween_property(_logo, "position", _default_position - Vector2(0, HOP_DISTANCE / 2), HOP_TIME)
	elif bar_time == 1:
		_tween.tween_property(_logo, "position", _default_position + Vector2(0, HOP_DISTANCE / 2), HOP_TIME)
