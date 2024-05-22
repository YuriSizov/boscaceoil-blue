###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends CanvasLayer

const FADE_BLINKS := 4
const BLINK_IN_DURATION := 0.1
const BLICK_HOLD_DURATION := 0.05
const BLINK_OUT_DURATION := 0.05

var highlight_rect_getter: Callable:
	set = set_highlight_rect_getter
var _highlight_rect_owner: Control = null

var _fade_tween: Tween = null

@onready var _indicator: Control = $HighlightIndicator


func _ready() -> void:
	_indicator.draw.connect(_draw_highlight_indicator)


func _draw_highlight_indicator() -> void:
	if not highlight_rect_getter.is_valid():
		return
	
	var highlight_color := _indicator.get_theme_color("highlight_color", "HighlightManager")
	var highlight_bevel_color := _indicator.get_theme_color("highlight_bevel_color", "HighlightManager")
	var highlight_bevel_thickness := _indicator.get_theme_constant("highlight_thickness", "HighlightManager")
	var highlight_thickness := highlight_bevel_thickness / 2.0
	
	var highlight_bevel_rect: Rect2 = highlight_rect_getter.call()
	var highlight_rect := highlight_bevel_rect.grow(-highlight_thickness / 2.0) # Unfilled rect draws its border centered.
	
	_indicator.draw_rect(highlight_bevel_rect, highlight_bevel_color, false, highlight_bevel_thickness)
	_indicator.draw_rect(highlight_rect, highlight_color, false, highlight_thickness)


func set_highlight_rect_getter(value: Callable) -> void:
	if highlight_rect_getter == value:
		return # Avoid double fading the same highlight for subsequent help steps.
	
	if _highlight_rect_owner:
		_highlight_rect_owner.resized.disconnect(update_highlight)
	
	highlight_rect_getter = value
	if highlight_rect_getter.is_valid():
		_highlight_rect_owner = highlight_rect_getter.get_object() as Control
	
	if _highlight_rect_owner:
		_highlight_rect_owner.resized.connect(update_highlight)
	
	if _fade_tween:
		_fade_tween.kill()
	
	_fade_tween = get_tree().create_tween()
	_indicator.self_modulate.a = 0.0
	
	for i in FADE_BLINKS:
		_fade_tween.tween_property(_indicator, "self_modulate:a", 1.0, BLINK_IN_DURATION).set_delay(BLICK_HOLD_DURATION)
		_fade_tween.tween_property(_indicator, "self_modulate:a", 0.0, BLINK_OUT_DURATION).set_delay(BLICK_HOLD_DURATION)
	
	_fade_tween.tween_property(_indicator, "self_modulate:a", 1.0, BLINK_IN_DURATION)


func update_highlight() -> void:
	_indicator.queue_redraw()
