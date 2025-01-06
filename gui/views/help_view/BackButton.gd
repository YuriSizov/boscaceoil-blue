###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name BackButton extends Label

signal pressed()

var _hovered: bool = false


func _ready() -> void:
	mouse_entered.connect(func() -> void:
		_hovered = true
		queue_redraw()
	)
	mouse_exited.connect(func() -> void:
		_hovered = false
		queue_redraw()
	)


func _draw() -> void:
	if _hovered:
		var hover_color := get_theme_color("hover_color")
		draw_rect(Rect2(Vector2.ZERO, size), hover_color)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()
