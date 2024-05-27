###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends MarginContainer

@onready var _instrument_dock: ItemDock = %InstrumentDock


func _ready() -> void:
	if not Engine.is_editor_hint():
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.INSTRUMENT_EDITOR_VIEW, get_global_rect)
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.INSTRUMENT_EDITOR_DOCK, _instrument_dock.get_global_rect_with_delete_area)
