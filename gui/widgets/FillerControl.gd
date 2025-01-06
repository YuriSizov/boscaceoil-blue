###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

# A trick control to reserve some space in a container for another control located
# in another branch of the scene tree. This can be used to, for example, make the
# first element inside of a box container to display above the second one.
extends Control

@export var paired_node: Control


func _get_minimum_size() -> Vector2:
	if not paired_node:
		return Vector2.ZERO
	
	return paired_node.get_combined_minimum_size()
