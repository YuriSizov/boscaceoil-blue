###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name DeleteArea extends Label

const FADE_DURATION := 0.12

var _hovered: bool = false
var _tween: Tween = null


func _ready() -> void:
	offset_top = -size.y
	
	mouse_entered.connect(func() -> void:
		_hovered = true
		text = "DROP TO CONFIRM"
		queue_redraw()
	)
	mouse_exited.connect(func() -> void:
		_hovered = false
		text = "DELETE?"
		queue_redraw()
	)


func _draw() -> void:
	if _hovered:
		var hover_color := get_theme_color("hover_color", "DeleteArea")
		draw_rect(Rect2(Vector2.ZERO, size), hover_color)


func fade_in() -> void:
	if _tween:
		_tween.kill()
	
	_tween = get_tree().create_tween()
	_tween.tween_property(self, "offset_top", 0, FADE_DURATION)


func fade_out() -> void:
	if _tween:
		_tween.kill()
	
	_tween = get_tree().create_tween()
	_tween.tween_property(self, "offset_top", -size.y, FADE_DURATION)
