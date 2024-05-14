###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name SettingsManager extends RefCounted

signal gui_scale_changed()
signal buffer_size_changed()

enum GUIScalePresets {
	GUI_SCALE_NORMAL = 1,
	GUI_SCALE_LARGE = 2,
}

const _gui_scale_factors := {
	GUIScalePresets.GUI_SCALE_NORMAL: 1.0,
	GUIScalePresets.GUI_SCALE_LARGE:  1.25,
}


# TODO: Implement persistent settings.

func set_gui_scale(preset: int) -> void:
	var value: float = _gui_scale_factors[GUIScalePresets.GUI_SCALE_NORMAL]
	if _gui_scale_factors.has(preset):
		value = _gui_scale_factors[preset]
	
	ProjectSettings.set_setting("display/window/stretch/scale", value)
	Controller.get_window().content_scale_factor = value
	
	gui_scale_changed.emit()
