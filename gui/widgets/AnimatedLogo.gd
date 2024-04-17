###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends Control

@onready var _logo: TextureRect = $Logo


func _get_minimum_size() -> Vector2:
	if not _logo:
		return Vector2.ZERO
	return _logo.get_combined_minimum_size()
