###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends Control

var message: String = "PLEASE WAIT":
	set(value):
		message = value
		_update_label()

@onready var _message_label: Label = $MessageLabel


func _ready() -> void:
	var shader_material := (material as ShaderMaterial)
	shader_material.set_shader_parameter("base_color", get_theme_color("base_color", "ExportIndicator"))
	shader_material.set_shader_parameter("stripe_color", get_theme_color("stripe_color", "ExportIndicator"))
	
	_update_label()
	if not Engine.is_editor_hint():
		Controller.music_player.playback_bar_changed.connect(_switch_direction)


func _draw() -> void:
	# Gives us a canvas for the shader to do its thing.
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)


func _update_label() -> void:
	if not is_inside_tree():
		return
	
	_message_label.text = message


func _switch_direction() -> void:
	var shader_material := (material as ShaderMaterial)
	var direction_angle: float = shader_material.get_shader_parameter("angle")
	shader_material.set_shader_parameter("angle", 1.0 - direction_angle)
