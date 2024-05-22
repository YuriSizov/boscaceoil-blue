###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name HelpGuideStep extends Resource

@export var title: String = "":
	set(value): title = value; changed.emit()
@export_multiline var description: String = "":
	set(value): description = value; changed.emit()

@export var ref_image: Texture2D = null:
	set(value): ref_image = value; changed.emit()
@export var ref_image_size: Vector2 = Vector2.ZERO:
	set(value): ref_image_size = value; changed.emit()
@export var ref_image_position: InfoPopup.ImagePosition = InfoPopup.ImagePosition.HIDDEN:
	set(value): ref_image_position = value; changed.emit()

@export var navigation_target: Menu.NavigationTarget = Menu.NavigationTarget.KEEP_CURRENT:
	set(value): navigation_target = value; changed.emit()
@export var node_target: HelpManager.StepNodeRef = HelpManager.StepNodeRef.NONE:
	set(value): node_target = value; changed.emit()
@export var trigger_target: HelpManager.StepTrigger = HelpManager.StepTrigger.NONE:
	set(value): trigger_target = value; changed.emit()

@export var position_anchor: Vector2 = Vector2(0.5, 0.5):
	set(value): position_anchor = value; changed.emit()
@export var position_direction: PopupManager.Direction = PopupManager.Direction.BOTTOM_RIGHT:
	set(value): position_direction = value; changed.emit()
@export var size: Vector2 = Vector2(320, 240):
	set(value): size = value; changed.emit()
