###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends Control

signal shifted_up()
signal shifted_down()

var octave_rows: Array[NoteMap.OctaveRow] = []

var _button_holder: ButtonHolder = null
@onready var _up_button: Button = %UpButton
@onready var _down_button: Button = %DownButton


func _ready() -> void:
	_button_holder = ButtonHolder.new(self, _up_button, _down_button)
	_button_holder.set_press_callback(_emit_hold_signal)
	_button_holder.set_button_action(_up_button, "bosca_notemap_up")
	_button_holder.set_button_action(_down_button, "bosca_notemap_down")


func _process(delta: float) -> void:
	_button_holder.process(delta)


func _shortcut_input(event: InputEvent) -> void:
	_button_holder.input(event)


func _draw() -> void:
	var available_rect := get_available_rect()
	
		# Draw background.
	var gutter_rect := Rect2(Vector2.ZERO, size)
	draw_rect(gutter_rect, get_theme_color("gutter_color", "NoteMap"))

	# Draw octave labels.
	
	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	var font_color := get_theme_color("font_color", "Label")
	var shadow_color := get_theme_color("shadow_color", "Label")
	var shadow_size := Vector2(get_theme_constant("shadow_offset_x", "Label"), get_theme_constant("shadow_offset_y", "Label"))

	for octave in octave_rows:
		var octave_string := "%d" % (octave.octave_index + 1)
		var string_size := font.get_string_size(octave_string, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size)

		var string_position := octave.label_position + Vector2(available_rect.size.x - string_size.x - 4, 0)
		var shadow_position := string_position + shadow_size

		draw_string(font, shadow_position, octave_string, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size, shadow_color)
		draw_string(font, string_position, octave_string, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size, font_color)


func get_available_rect() -> Rect2:
	var available_rect := Rect2(Vector2.ZERO, size)
	if not is_inside_tree():
		return available_rect
	
	if _up_button:
		available_rect.position.y += _up_button.size.y
		available_rect.size.y -= _up_button.size.y
	if _down_button:
		available_rect.size.y -= _down_button.size.y
	
	return available_rect


func _emit_hold_signal(hold_button: Button) -> void:
	if not hold_button:
		return
	
	if hold_button == _up_button:
		shifted_up.emit()
	elif hold_button == _down_button:
		shifted_down.emit()
